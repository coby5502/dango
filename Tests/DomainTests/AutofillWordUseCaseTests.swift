import XCTest
@testable import Domain

// MARK: - MockDictionaryProvider

final class MockDictionaryProvider: DictionaryProvider {
    var results: [String: DictionaryResult] = [:]
    var shouldThrowError: Error?
    var delay: TimeInterval = 0
    
    func search(term: String) async throws -> DictionaryResult? {
        if let error = shouldThrowError {
            throw error
        }
        
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        return results[term]
    }
}

// MARK: - AutofillWordUseCaseTests

final class AutofillWordUseCaseTests: XCTestCase {
    var provider: MockDictionaryProvider!
    var useCase: AutofillWordUseCase!
    
    override func setUp() {
        super.setUp()
        provider = MockDictionaryProvider()
        useCase = AutofillWordUseCaseImpl(dictionaryProvider: provider)
    }
    
    override func tearDown() {
        provider = nil
        useCase = nil
        super.tearDown()
    }
    
    func testAutofillWithResult() async throws {
        // Given
        let term = "テスト"
        let expectedResult = DictionaryResult(
            reading: "てすと",
            meanings: ["테스트", "시험"],
            examples: [
                (jp: "これはテストです。", ko: "이것은 테스트입니다.")
            ],
            confidence: 0.9
        )
        provider.results[term] = expectedResult
        
        // When
        let result = try await useCase.execute(jpText: term)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.reading, "てすと")
        XCTAssertEqual(result?.meanings.count, 2)
        XCTAssertEqual(result?.examples.count, 1)
        XCTAssertEqual(result?.confidence, 0.9)
    }
    
    func testAutofillWithNoResult() async throws {
        // Given
        let term = "존재하지않는단어"
        
        // When
        let result = try await useCase.execute(jpText: term)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testAutofillWithEmptyString() async throws {
        // Given
        let term = ""
        
        // When
        let result = try await useCase.execute(jpText: term)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testAutofillWithProviderError() async throws {
        // Given
        let term = "テスト"
        provider.shouldThrowError = NSError(domain: "TestError", code: 1)
        
        // When/Then
        do {
            _ = try await useCase.execute(jpText: term)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testAutofillWithPartialResult() async throws {
        // Given
        let term = "テスト"
        let partialResult = DictionaryResult(
            reading: "てすと",
            meanings: [],
            examples: [],
            confidence: 0.5
        )
        provider.results[term] = partialResult
        
        // When
        let result = try await useCase.execute(jpText: term)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.reading, "てすと")
        XCTAssertTrue(result?.meanings.isEmpty ?? false)
        XCTAssertTrue(result?.examples.isEmpty ?? false)
    }
}
