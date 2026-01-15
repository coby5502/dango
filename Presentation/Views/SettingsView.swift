import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - SettingsView

public struct SettingsView: View {
    @ObservedObject public var persistenceController: PersistenceController
    private let csvImportUseCase: CSVImportUseCase
    private let csvExportUseCase: CSVExportUseCase
    private let fetchWordsUseCase: FetchWordsUseCase
    private let dictionaryCache: DictionaryCache
    
    @State private var showImportPanel = false
    @State private var showExportPanel = false
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var importResult: ImportResult?
    @State private var showImportResult = false
    @State private var showCacheClearConfirm = false
    @State private var errorMessage: String?
    @State private var showError = false
    @AppStorage("autofillEnabled") private var autofillEnabled: Bool = true
    
    public init(
        persistenceController: PersistenceController,
        csvImportUseCase: CSVImportUseCase,
        csvExportUseCase: CSVExportUseCase,
        fetchWordsUseCase: FetchWordsUseCase,
        dictionaryCache: DictionaryCache
    ) {
        self.persistenceController = persistenceController
        self.csvImportUseCase = csvImportUseCase
        self.csvExportUseCase = csvExportUseCase
        self.fetchWordsUseCase = fetchWordsUseCase
        self.dictionaryCache = dictionaryCache
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // iCloud 동기화
                SettingsSection(title: "iCloud 동기화") {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("동기화 상태")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(syncStatusColor)
                                        .frame(width: 7, height: 7)
                                    
                                    Text(syncStatusText)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.primary)
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                persistenceController.retryCloudKitSync()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("재시도")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.accentColor)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                    }
                }
                
                // 데이터 관리
                SettingsSection(title: "데이터 관리") {
                    VStack(spacing: 10) {
                        SettingsButton(
                            icon: "square.and.arrow.down",
                            title: "CSV 가져오기",
                            subtitle: "파일에서 단어 가져오기",
                            isDisabled: isImporting
                        ) {
                            showImportPanel = true
                        }
                        
                        Divider()
                        
                        SettingsButton(
                            icon: "square.and.arrow.up",
                            title: "CSV 내보내기",
                            subtitle: "모든 단어를 파일로 저장",
                            isDisabled: isExporting
                        ) {
                            Task {
                                await exportCSV()
                            }
                        }
                        
                        Divider()
                        
                        SettingsButton(
                            icon: "trash",
                            title: "캐시 삭제",
                            subtitle: "자동 채움 캐시 초기화",
                            isDestructive: true
                        ) {
                            showCacheClearConfirm = true
                        }
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                    }
                }
                
                // 자동 채움
                SettingsSection(title: "자동 채움") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("자동 채움 활성화")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            Text("일본어 입력 시 자동으로 읽기와 뜻을 채웁니다")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $autofillEnabled)
                            .labelsHidden()
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("설정")
        .fileImporter(
            isPresented: $showImportPanel,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await handleImport(result: result)
            }
        }
        .alert("가져오기 결과", isPresented: $showImportResult) {
            Button("확인", role: .cancel) {}
        } message: {
            if let result = importResult {
                Text("가져옴: \(result.imported)개\n업데이트: \(result.updated)개\n건너뜀: \(result.skipped)개\(result.errors.isEmpty ? "" : "\n오류: \(result.errors.count)개")")
            }
        }
        .confirmationDialog("캐시 삭제", isPresented: $showCacheClearConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                Task {
                    await clearCache()
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("사전 자동 채움 캐시를 삭제하시겠습니까?")
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다")
        }
    }
    
    private var syncStatusText: String {
        switch persistenceController.syncStatus {
        case .synced: return "동기화됨"
        case .syncing: return "동기화 중..."
        case .offline: return "오프라인"
        case .needSignIn: return "로그인 필요"
        case .error(let message): return "오류: \(message)"
        }
    }
    
    private var syncStatusColor: Color {
        switch persistenceController.syncStatus {
        case .synced: return .green
        case .syncing: return .blue
        case .offline, .needSignIn, .error: return .red
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) async {
        isImporting = true
        defer { isImporting = false }
        
        do {
            let urls = try result.get()
            guard let url = urls.first else {
                errorMessage = "파일을 선택해주세요"
                showError = true
                return
            }
            
            // 파일 읽기
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "파일 접근 권한이 없습니다"
                showError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let data = try Data(contentsOf: url)
            let importResult = try await csvImportUseCase.execute(
                csvData: data,
                duplicatePolicy: .ask // 기본값: 묻기 (나중에 설정으로 변경 가능)
            )
            
            self.importResult = importResult
            showImportResult = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func exportCSV() async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            // 모든 단어 가져오기
            let words = try await fetchWordsUseCase.execute()
            
            // CSV 데이터 생성
            let csvData = try await csvExportUseCase.execute(words: words)
            
            // 파일 저장 패널 표시
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.commaSeparatedText]
            savePanel.nameFieldStringValue = "dango_export.csv"
            
            guard await savePanel.begin() == .OK, let url = savePanel.url else {
                return
            }
            
            // 파일 저장
            try csvData.write(to: url)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func clearCache() async {
        await dictionaryCache.clear()
    }
}

// MARK: - SettingsSection

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            content()
        }
    }
}

// MARK: - SettingsButton

private struct SettingsButton: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDisabled: Bool = false
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isDestructive ? .red : .accentColor)
                    .frame(width: 30, height: 30)
                    .background {
                        RoundedRectangle(cornerRadius: 7)
                            .fill((isDestructive ? Color.red : Color.accentColor).opacity(0.1))
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDestructive ? .red : .primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
