import Foundation

// MARK: - WordRepository Protocol

public protocol WordRepository: Sendable {
    func fetchAll() async throws -> [Word]
    func fetch(by id: UUID) async throws -> Word?
    func search(query: String, filter: WordFilter?, sortOrder: WordSortOrder) async throws -> [Word]
    func add(_ word: Word) async throws -> Word
    func update(_ word: Word) async throws -> Word
    func delete(_ word: Word) async throws
    func restore(_ word: Word) async throws
    func permanentlyDelete(_ word: Word) async throws
    func findDuplicate(jpText: String) async throws -> Word?
}
