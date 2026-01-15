import XCTest
@testable import Domain

// MARK: - MockWordRepository

final class MockWordRepository: WordRepository {
    var words: [Word] = []
    var shouldThrowError: Error?
    
    func fetchAll() async throws -> [Word] {
        if let error = shouldThrowError { throw error }
        return words
    }
    
    func fetch(by id: UUID) async throws -> Word? {
        if let error = shouldThrowError { throw error }
        return words.first { $0.id == id }
    }
    
    func search(query: String, filter: WordFilter?, sortOrder: WordSortOrder) async throws -> [Word] {
        if let error = shouldThrowError { throw error }
        return words.filter { $0.jpText.contains(query) }
    }
    
    func add(_ word: Word) async throws -> Word {
        if let error = shouldThrowError { throw error }
        words.append(word)
        return word
    }
    
    func update(_ word: Word) async throws -> Word {
        if let error = shouldThrowError { throw error }
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index] = word
        }
        return word
    }
    
    func delete(_ word: Word) async throws {
        if let error = shouldThrowError { throw error }
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index].deletedAt = Date()
        }
    }
    
    func restore(_ word: Word) async throws {
        if let error = shouldThrowError { throw error }
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index].deletedAt = nil
        }
    }
    
    func permanentlyDelete(_ word: Word) async throws {
        if let error = shouldThrowError { throw error }
        words.removeAll { $0.id == word.id }
    }
    
    func findDuplicate(jpText: String) async throws -> Word? {
        if let error = shouldThrowError { throw error }
        return words.first { $0.jpText == jpText && $0.deletedAt == nil }
    }
}

// MARK: - AddWordUseCaseTests

final class AddWordUseCaseTests: XCTestCase {
    var repository: MockWordRepository!
    var useCase: AddWordUseCase!
    
    override func setUp() {
        super.setUp()
        repository = MockWordRepository()
        useCase = AddWordUseCaseImpl(wordRepository: repository)
    }
    
    override func tearDown() {
        repository = nil
        useCase = nil
        super.tearDown()
    }
    
    func testAddNewWord() async throws {
        // Given
        let word = Word(
            jpText: "テスト",
            meaning: "테스트"
        )
        
        // When
        let result = try await useCase.execute(word, duplicatePolicy: .addNew)
        
        // Then
        XCTAssertEqual(result.jpText, "テスト")
        XCTAssertEqual(result.meaning, "테스트")
        XCTAssertEqual(repository.words.count, 1)
    }
    
    func testAddWordWithDuplicatePolicyUpdate() async throws {
        // Given
        let existingWord = Word(
            jpText: "テスト",
            meaning: "기존 뜻",
            reading: "てすと"
        )
        repository.words.append(existingWord)
        
        let newWord = Word(
            jpText: "テスト",
            meaning: "새 뜻",
            reading: "てすと"
        )
        
        // When
        let result = try await useCase.execute(newWord, duplicatePolicy: .update)
        
        // Then
        XCTAssertEqual(repository.words.count, 1)
        XCTAssertEqual(result.meaning, "새 뜻")
        XCTAssertNotNil(result.updatedAt)
    }
    
    func testAddWordWithDuplicatePolicyAddNew() async throws {
        // Given
        let existingWord = Word(
            jpText: "テスト",
            meaning: "기존 뜻"
        )
        repository.words.append(existingWord)
        
        let newWord = Word(
            jpText: "テスト",
            meaning: "새 뜻"
        )
        
        // When
        let result = try await useCase.execute(newWord, duplicatePolicy: .addNew)
        
        // Then
        XCTAssertEqual(repository.words.count, 2)
        XCTAssertEqual(result.meaning, "새 뜻")
    }
    
    func testAddWordWithDuplicatePolicyAsk() async throws {
        // Given
        let existingWord = Word(
            jpText: "テスト",
            meaning: "기존 뜻"
        )
        repository.words.append(existingWord)
        
        let newWord = Word(
            jpText: "テスト",
            meaning: "새 뜻"
        )
        
        // When/Then
        do {
            _ = try await useCase.execute(newWord, duplicatePolicy: .ask)
            XCTFail("Should throw duplicateFound error")
        } catch WordError.duplicateFound(let word) {
            XCTAssertEqual(word.jpText, "テスト")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
