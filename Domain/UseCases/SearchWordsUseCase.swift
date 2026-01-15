import Foundation

// MARK: - SearchWordsUseCase

public protocol SearchWordsUseCase: Sendable {
    func execute(query: String, filter: WordFilter?, sortOrder: WordSortOrder) async throws -> [Word]
}

public final class SearchWordsUseCaseImpl: SearchWordsUseCase, @unchecked Sendable {
    private let wordRepository: WordRepository
    
    public init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
    }
    
    public func execute(query: String, filter: WordFilter?, sortOrder: WordSortOrder) async throws -> [Word] {
        return try await wordRepository.search(query: query, filter: filter, sortOrder: sortOrder)
    }
}

// MARK: - FetchWordsUseCase

public protocol FetchWordsUseCase: Sendable {
    func execute() async throws -> [Word]
}

public final class FetchWordsUseCaseImpl: FetchWordsUseCase, @unchecked Sendable {
    private let wordRepository: WordRepository
    
    public init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
    }
    
    public func execute() async throws -> [Word] {
        return try await wordRepository.fetchAll()
    }
}

// MARK: - ToggleFavoriteUseCase

public protocol ToggleFavoriteUseCase: Sendable {
    func execute(_ word: Word) async throws -> Word
}

public final class ToggleFavoriteUseCaseImpl: ToggleFavoriteUseCase, @unchecked Sendable {
    private let wordRepository: WordRepository
    
    public init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
    }
    
    public func execute(_ word: Word) async throws -> Word {
        var updated = word
        updated.isFavorite.toggle()
        updated.updatedAt = Date()
        return try await wordRepository.update(updated)
    }
}
