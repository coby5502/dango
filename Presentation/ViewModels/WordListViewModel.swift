import Foundation
import SwiftUI

// MARK: - WordListViewModel

@MainActor
public final class WordListViewModel: ObservableObject {
    @Published public var words: [Word] = []
    @Published public var searchText: String = ""
    @Published public var sortOrder: WordSortOrder = .newest
    @Published public var filter: WordFilter = WordFilter()
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let searchWordsUseCase: SearchWordsUseCase
    private let fetchWordsUseCase: FetchWordsUseCase
    
    public init(
        searchWordsUseCase: SearchWordsUseCase,
        fetchWordsUseCase: FetchWordsUseCase
    ) {
        self.searchWordsUseCase = searchWordsUseCase
        self.fetchWordsUseCase = fetchWordsUseCase
    }
    
    public func loadWords() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 필터가 있거나 검색어가 있으면 항상 searchWordsUseCase 사용 (필터 적용)
            // 필터가 없고 검색어도 없으면 fetchWordsUseCase 사용
            if filter.isFavorite != nil || filter.sourceType != nil || filter.showDeleted != nil || !searchText.isEmpty {
                words = try await searchWordsUseCase.execute(
                    query: searchText,
                    filter: filter,
                    sortOrder: sortOrder
                )
            } else {
                words = try await fetchWordsUseCase.execute()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func applyFilter(_ newFilter: WordFilter) {
        filter = newFilter
        Task {
            await loadWords()
        }
    }
    
    public func setSortOrder(_ order: WordSortOrder) {
        sortOrder = order
        Task {
            await loadWords()
        }
    }
}
