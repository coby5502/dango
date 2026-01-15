import Foundation

// MARK: - UpdateWordUseCase

public protocol UpdateWordUseCase: Sendable {
    func execute(_ word: Word) async throws -> Word
}

public final class UpdateWordUseCaseImpl: UpdateWordUseCase, @unchecked Sendable {
    private let wordRepository: WordRepository
    
    public init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
    }
    
    public func execute(_ word: Word) async throws -> Word {
        guard try await wordRepository.fetch(by: word.id) != nil else {
            throw WordError.notFound
        }
        
        var updated = word
        updated.updatedAt = Date()
        return try await wordRepository.update(updated)
    }
}
