import Foundation

// MARK: - AutofillWordUseCase

public protocol AutofillWordUseCase: Sendable {
    func execute(jpText: String) async throws -> DictionaryResult?
}

public final class AutofillWordUseCaseImpl: AutofillWordUseCase, @unchecked Sendable {
    private let dictionaryProvider: DictionaryProvider
    
    public init(dictionaryProvider: DictionaryProvider) {
        self.dictionaryProvider = dictionaryProvider
    }
    
    public func execute(jpText: String) async throws -> DictionaryResult? {
        guard !jpText.isEmpty else { return nil }
        
        return try await dictionaryProvider.search(term: jpText)
    }
}
