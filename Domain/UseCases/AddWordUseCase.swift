import Foundation

// MARK: - AddWordUseCase

public protocol AddWordUseCase: Sendable {
    func execute(_ word: Word, duplicatePolicy: DuplicateHandlingPolicy) async throws -> Word
}

public final class AddWordUseCaseImpl: AddWordUseCase, @unchecked Sendable {
    private let wordRepository: WordRepository
    
    public init(wordRepository: WordRepository) {
        self.wordRepository = wordRepository
    }
    
    public func execute(_ word: Word, duplicatePolicy: DuplicateHandlingPolicy) async throws -> Word {
        // 중복 체크
        if let existing = try await wordRepository.findDuplicate(jpText: word.jpText) {
            switch duplicatePolicy {
            case .update:
                var updated = existing
                updated.reading = word.reading ?? existing.reading
                updated.meaning = word.meaning
                updated.updatedAt = Date()
                return try await wordRepository.update(updated)
                
            case .addNew:
                // 새로 추가 (jpText는 동일하지만 다른 ID로)
                return try await wordRepository.add(word)
                
            case .ask:
                throw WordError.duplicateFound(existing)
            }
        }
        
        return try await wordRepository.add(word)
    }
}

// MARK: - WordError

public enum WordError: LocalizedError, Equatable {
    case duplicateFound(Word)
    case notFound
    case invalidInput(String)
    case repositoryError(String)
    
    public var errorDescription: String? {
        switch self {
        case .duplicateFound:
            return "중복된 단어가 있습니다."
        case .notFound:
            return "단어를 찾을 수 없습니다."
        case .invalidInput(let message):
            return "입력 오류: \(message)"
        case .repositoryError(let message):
            return "저장소 오류: \(message)"
        }
    }
}
