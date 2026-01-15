import CoreData
import CloudKit

// MARK: - PersistenceController

@MainActor
public final class PersistenceController: ObservableObject, @unchecked Sendable {
    public static let shared = PersistenceController()
    
    // NOTE:
    // - Repositories create background contexts off the main actor.
    // - NSPersistentContainer 자체는 thread-safe하게 context를 생성/관리할 수 있으므로
    //   nonisolated(unsafe)로 노출하고, 변경(swap)은 MainActor에서만 수행한다.
    nonisolated(unsafe) public private(set) var container: NSPersistentContainer
    
    @Published public var syncStatus: CloudKitSyncStatus = .synced
    @Published public private(set) var isStoreLoaded: Bool = false
    private let cloudKitContainerIdentifier: String? = "iCloud.dango"
    
    public init(inMemory: Bool = false) {
        // 1) CloudKit 지원 컨테이너로 먼저 시도 (실패해도 앱은 로컬로 계속 동작해야 함: offline-first)
        let cloudContainer = NSPersistentCloudKitContainer(name: "DangoModel")
        Self.configureStoreDescriptions(
            for: cloudContainer,
            inMemory: inMemory,
            cloudKitContainerIdentifier: cloudKitContainerIdentifier
        )
        
        // 2) 로컬-only 컨테이너 (fallback)
        let localContainer = NSPersistentContainer(name: "DangoModel")
        Self.configureStoreDescriptions(
            for: localContainer,
            inMemory: inMemory,
            cloudKitContainerIdentifier: nil
        )
        
        // 기본은 CloudKit 컨테이너로 시작
        self.container = cloudContainer
        
        // IMPORTANT (offline-first):
        // init 시점에 스토어 로드를 끝내고 나서 Repository가 background context를 만들게 한다.
        // (안 그러면 "no stores loaded" 경고가 발생)
        if let error = Self.loadStoresBlocking(container: cloudContainer) {
            // CloudKit 실패 → 로컬-only로 폴백
            self.syncStatus = .error(Self.prettyPersistentStoreError(error))
            self.container = localContainer
            
            if let _ = Self.loadStoresBlocking(container: localContainer) {
                // 최후의 폴백: in-memory
                let inMemoryContainer = NSPersistentContainer(name: "DangoModel")
                Self.configureStoreDescriptions(for: inMemoryContainer, inMemory: true, cloudKitContainerIdentifier: nil)
                self.container = inMemoryContainer
                
                if let memError = Self.loadStoresBlocking(container: inMemoryContainer) {
                    assertionFailure("Core Data failed to load (even in-memory): \(memError)")
                }
                
                self.syncStatus = .offline
            } else {
                self.syncStatus = .offline
            }
        }
        
        self.configureContexts()
        self.isStoreLoaded = true
        self.setupCloudKitObservers()
    }

    // (swapToLocalContainer는 init에서 동기 폴백으로 대체)

    private func configureContexts() {
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    }

    nonisolated private static func configureStoreDescriptions(
        for container: NSPersistentContainer,
        inMemory: Bool,
        cloudKitContainerIdentifier: String?
    ) {
        let description = container.persistentStoreDescriptions.first
        if inMemory {
            description?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        if
            let ckContainerId = cloudKitContainerIdentifier,
            let cloudContainer = container as? NSPersistentCloudKitContainer
        {
            cloudContainer.persistentStoreDescriptions.first?.cloudKitContainerOptions =
                NSPersistentCloudKitContainerOptions(containerIdentifier: ckContainerId)
        }
    }

    nonisolated private static func loadStoresBlocking(container: NSPersistentContainer) -> Error? {
        let semaphore = DispatchSemaphore(value: 0)
        var capturedError: Error?
        
        container.loadPersistentStores { _, error in
            capturedError = error
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 10) // 10초 타임아웃(너무 오래 멈추지 않게)
        return capturedError
    }

    nonisolated private static func prettyPersistentStoreError(_ error: Error) -> String {
        let nsError = error as NSError
        if let detailed = nsError.userInfo[NSDetailedErrorsKey] as? [NSError], !detailed.isEmpty {
            return detailed.map { "\($0.domain)(\($0.code)): \($0.localizedDescription)" }.joined(separator: " | ")
        }
        return "\(nsError.domain)(\(nsError.code)): \(nsError.localizedDescription)"
    }
    
    // MARK: - CloudKit Sync Status
    
    public enum CloudKitSyncStatus: Equatable {
        case synced
        case syncing
        case offline
        case needSignIn
        case error(String)
    }
    
    private func setupCloudKitObservers() {
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.syncStatus = .syncing
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.syncStatus = .synced
            }
        }
        
        // CloudKit 계정 상태 확인
        checkCloudKitAccountStatus()
    }
    
    private func checkCloudKitAccountStatus() {
        guard let cloudKitContainerIdentifier else {
            self.syncStatus = .offline
            return
        }
        
        let container = CKContainer(identifier: cloudKitContainerIdentifier)
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                guard let self else { return }
                if let error = error {
                    self.syncStatus = .error(error.localizedDescription)
                    return
                }
                
                switch status {
                case .available:
                    self.syncStatus = .synced
                case .noAccount:
                    self.syncStatus = .needSignIn
                case .restricted:
                    self.syncStatus = .offline
                case .couldNotDetermine:
                    self.syncStatus = .offline
                case .temporarilyUnavailable:
                    self.syncStatus = .offline
                @unknown default:
                    self.syncStatus = .offline
                }
            }
        }
    }
    
    public func retryCloudKitSync() {
        checkCloudKitAccountStatus()
    }
    
    // MARK: - Context Helpers
    
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    nonisolated public func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
    
    public func save() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }
}
