import Foundation
import CoreData

// MARK: - CoreDataWordRepository

public final class CoreDataWordRepository: WordRepository, @unchecked Sendable {
    private let persistenceController: PersistenceController
    
    public init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }
    
    public func fetchAll() async throws -> [Word] {
        try await withCheckedThrowingContinuation { continuation in
            let context = persistenceController.newBackgroundContext()
            context.perform {
                do {
                    let request = NSFetchRequest<WordEntity>(entityName: "WordEntity")
                    request.predicate = NSPredicate(format: "deletedAt == nil")
                    let entities = try context.fetch(request)
                    let words = entities.map { WordMapper.toDomain($0) }
                    continuation.resume(returning: words)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func fetch(by id: UUID) async throws -> Word? {
        try await withCheckedThrowingContinuation { continuation in
            let context = persistenceController.newBackgroundContext()
            context.perform {
                do {
                    let request = NSFetchRequest<WordEntity>(entityName: "WordEntity")
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    request.fetchLimit = 1
                    let entities = try context.fetch(request)
                    if let entity = entities.first {
                        continuation.resume(returning: WordMapper.toDomain(entity))
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func search(query: String, filter: WordFilter?, sortOrder: WordSortOrder) async throws -> [Word] {
        try await withCheckedThrowingContinuation { continuation in
            let context = persistenceController.newBackgroundContext()
            context.perform {
                do {
                    let request = NSFetchRequest<WordEntity>(entityName: "WordEntity")
                    
                    var predicates: [NSPredicate] = []
                    
                    // 삭제 필터
                    if let showDeleted = filter?.showDeleted {
                        if showDeleted {
                            predicates.append(NSPredicate(format: "deletedAt != nil"))
                        } else {
                            predicates.append(NSPredicate(format: "deletedAt == nil"))
                        }
                    } else {
                        // 기본: 삭제되지 않은 것만
                        predicates.append(NSPredicate(format: "deletedAt == nil"))
                    }
                    
                    // 검색어 조건
                    if !query.isEmpty {
                        let searchPredicate = NSPredicate(
                            format: "jpText CONTAINS[cd] %@ OR reading CONTAINS[cd] %@ OR primaryMeaning CONTAINS[cd] %@",
                            query, query, query
                        )
                        predicates.append(searchPredicate)
                    }
                    
                    // 필터 조건
                    if let filter = filter {
                        if let isFavorite = filter.isFavorite {
                            predicates.append(NSPredicate(format: "isFavorite == %@", NSNumber(value: isFavorite)))
                        }
                        if let sourceType = filter.sourceType {
                            predicates.append(NSPredicate(format: "sourceType == %@", sourceType.rawValue))
                        }
                    }
                    
                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                    
                    // 정렬
                    switch sortOrder {
                    case .newest:
                        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                    case .japanese:
                        request.sortDescriptors = [NSSortDescriptor(key: "jpText", ascending: true)]
                    }
                    
                    let entities = try context.fetch(request)
                    let words = entities.map { WordMapper.toDomain($0) }
                    continuation.resume(returning: words)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func add(_ word: Word) async throws -> Word {
        try await withCheckedThrowingContinuation { continuation in
            let context = persistenceController.newBackgroundContext()
            context.perform {
                do {
                    let entity = WordMapper.toManagedObject(word, context: context)
                    
                    try context.save()
                    
                    // 다시 로드하여 반환
                    if let savedEntity = try? context.existingObject(with: entity.objectID) as? WordEntity {
                        continuation.resume(returning: WordMapper.toDomain(savedEntity))
                    } else {
                        continuation.resume(returning: word)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func update(_ word: Word) async throws -> Word {
        try await withCheckedThrowingContinuation { continuation in
            let context = persistenceController.newBackgroundContext()
            context.perform {
                do {
                    let request = NSFetchRequest<WordEntity>(entityName: "WordEntity")
                    request.predicate = NSPredicate(format: "id == %@", word.id as CVarArg)
                    request.fetchLimit = 1
                    let entities = try context.fetch(request)
                    
                    guard let entity = entities.first else {
                        continuation.resume(throwing: WordError.notFound)
                        return
                    }
                    
                    WordMapper.update(entity, with: word, context: context)
                    
                    try context.save()
                    
                    // 다시 로드하여 반환
                    if let savedEntity = try? context.existingObject(with: entity.objectID) as? WordEntity {
                        continuation.resume(returning: WordMapper.toDomain(savedEntity))
                    } else {
                        continuation.resume(returning: word)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func delete(_ word: Word) async throws {
        var deleted = word
        deleted.deletedAt = Date()
        deleted.updatedAt = Date()
        _ = try await update(deleted)
    }
    
    public func restore(_ word: Word) async throws {
        var restored = word
        restored.deletedAt = nil
        restored.updatedAt = Date()
        _ = try await update(restored)
    }
    
    public func permanentlyDelete(_ word: Word) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let context = persistenceController.newBackgroundContext()
            context.perform {
                do {
                    let request = NSFetchRequest<WordEntity>(entityName: "WordEntity")
                    request.predicate = NSPredicate(format: "id == %@", word.id as CVarArg)
                    request.fetchLimit = 1
                    let entities = try context.fetch(request)
                    
                    if let entity = entities.first {
                        context.delete(entity)
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func findDuplicate(jpText: String) async throws -> Word? {
        try await withCheckedThrowingContinuation { continuation in
            let context = persistenceController.newBackgroundContext()
            context.perform {
                do {
                    let request = NSFetchRequest<WordEntity>(entityName: "WordEntity")
                    request.predicate = NSPredicate(format: "jpText == %@ AND deletedAt == nil", jpText)
                    request.fetchLimit = 1
                    let entities = try context.fetch(request)
                    if let entity = entities.first {
                        continuation.resume(returning: WordMapper.toDomain(entity))
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
