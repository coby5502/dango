import Foundation

// MARK: - DeleteWordUseCase (Soft Delete)

public protocol DeleteWordUseCase: Sendable {
    func execute(_ word: Word) async throws
}

public final class DeleteWordUseCaseImpl: DeleteWordUseCase, @unchecked Sendable {
    private let wordRepository: WordRepository
    
    public init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
    }
    
    public func execute(_ word: Word) async throws {
        var deleted = word
        deleted.deletedAt = Date()
        deleted.updatedAt = Date()
        _ = try await wordRepository.update(deleted)
    }
}

// MARK: - RestoreWordUseCase

public protocol RestoreWordUseCase: Sendable {
    func execute(_ word: Word) async throws -> Word
}

public final class RestoreWordUseCaseImpl: RestoreWordUseCase, @unchecked Sendable {
    private let wordRepository: WordRepository
    
    public init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
    }
    
    public func execute(_ word: Word) async throws -> Word {
        var restored = word
        restored.deletedAt = nil
        restored.updatedAt = Date()
        return try await wordRepository.update(restored)
    }
}

// MARK: - PermanentlyDeleteWordUseCase

public protocol PermanentlyDeleteWordUseCase: Sendable {
    func execute(_ word: Word) async throws
}

public final class PermanentlyDeleteWordUseCaseImpl: PermanentlyDeleteWordUseCase, @unchecked Sendable {
    private let wordRepository: WordRepository
    
    public init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
    }
    
    public func execute(_ word: Word) async throws {
        try await wordRepository.permanentlyDelete(word)
    }
}
