import Foundation
import SwiftUI

// MARK: - WordDetailViewModel

@MainActor
public final class WordDetailViewModel: ObservableObject {
    @Published public var word: Word?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let wordRepository: WordRepository
    private let toggleFavoriteUseCase: ToggleFavoriteUseCase
    private let deleteWordUseCase: DeleteWordUseCase
    private let restoreWordUseCase: RestoreWordUseCase
    private let permanentlyDeleteWordUseCase: PermanentlyDeleteWordUseCase
    
    public init(
        wordRepository: WordRepository,
        toggleFavoriteUseCase: ToggleFavoriteUseCase,
        deleteWordUseCase: DeleteWordUseCase,
        restoreWordUseCase: RestoreWordUseCase,
        permanentlyDeleteWordUseCase: PermanentlyDeleteWordUseCase
    ) {
        self.wordRepository = wordRepository
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.deleteWordUseCase = deleteWordUseCase
        self.restoreWordUseCase = restoreWordUseCase
        self.permanentlyDeleteWordUseCase = permanentlyDeleteWordUseCase
    }
    
    public func loadWord(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            word = try await wordRepository.fetch(by: id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func toggleFavorite() async {
        guard let word = word else { return }
        
        do {
            self.word = try await toggleFavoriteUseCase.execute(word)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func deleteWord() async {
        guard let word = word else { return }
        
        do {
            try await deleteWordUseCase.execute(word)
            self.word = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func restoreWord() async {
        guard let word = word else { return }
        
        do {
            self.word = try await restoreWordUseCase.execute(word)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func permanentlyDeleteWord() async {
        guard let word = word else { return }
        
        do {
            try await permanentlyDeleteWordUseCase.execute(word)
            self.word = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
