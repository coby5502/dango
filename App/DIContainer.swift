import Foundation

// MARK: - DIContainer

@MainActor
public final class DIContainer {
    public static let shared = DIContainer()
    
    // MARK: - Persistence
    public let persistenceController: PersistenceController
    
    // MARK: - Repositories
    public let wordRepository: WordRepository
    
    // MARK: - Providers
    public let dictionaryProvider: DictionaryProvider
    public let dictionaryCache: DictionaryCache
    
    // MARK: - UseCases
    public let addWordUseCase: AddWordUseCase
    public let updateWordUseCase: UpdateWordUseCase
    public let deleteWordUseCase: DeleteWordUseCase
    public let restoreWordUseCase: RestoreWordUseCase
    public let permanentlyDeleteWordUseCase: PermanentlyDeleteWordUseCase
    public let searchWordsUseCase: SearchWordsUseCase
    public let fetchWordsUseCase: FetchWordsUseCase
    public let toggleFavoriteUseCase: ToggleFavoriteUseCase
    public let autofillWordUseCase: AutofillWordUseCase
    public let csvImportUseCase: CSVImportUseCase
    public let csvExportUseCase: CSVExportUseCase
    
    // MARK: - ViewModels
    public lazy var wordListViewModel: WordListViewModel = {
        WordListViewModel(
            searchWordsUseCase: searchWordsUseCase,
            fetchWordsUseCase: fetchWordsUseCase
        )
    }()
    
    public lazy var wordDetailViewModel: WordDetailViewModel = {
        WordDetailViewModel(
            wordRepository: wordRepository,
            toggleFavoriteUseCase: toggleFavoriteUseCase,
            deleteWordUseCase: deleteWordUseCase,
            restoreWordUseCase: restoreWordUseCase,
            permanentlyDeleteWordUseCase: permanentlyDeleteWordUseCase
        )
    }()
    
    public lazy var wordEditorViewModel: WordEditorViewModel = {
        WordEditorViewModel(
            addWordUseCase: addWordUseCase,
            updateWordUseCase: updateWordUseCase,
            autofillWordUseCase: autofillWordUseCase
        )
    }()
    
    // MARK: - Initialization
    
    private init() {
        // Persistence
        persistenceController = PersistenceController()
        
        // Cache
        dictionaryCache = DictionaryCache()
        
        // Providers
        let offlineFallbackProvider = MockDictionaryProvider(cache: dictionaryCache)
        let httpClient = URLSessionHTTPClient()
        let translator = GoogleTranslateProvider(http: httpClient)
        dictionaryProvider = JishoDictionaryProvider(
            http: httpClient,
            cache: dictionaryCache,
            fallback: offlineFallbackProvider,
            translator: translator
        )
        
        // Repositories
        wordRepository = CoreDataWordRepository(persistenceController: persistenceController)
        
        // UseCases
        addWordUseCase = AddWordUseCaseImpl(wordRepository: wordRepository)
        updateWordUseCase = UpdateWordUseCaseImpl(wordRepository: wordRepository)
        deleteWordUseCase = DeleteWordUseCaseImpl(wordRepository: wordRepository)
        restoreWordUseCase = RestoreWordUseCaseImpl(wordRepository: wordRepository)
        permanentlyDeleteWordUseCase = PermanentlyDeleteWordUseCaseImpl(wordRepository: wordRepository)
        searchWordsUseCase = SearchWordsUseCaseImpl(wordRepository: wordRepository)
        fetchWordsUseCase = FetchWordsUseCaseImpl(wordRepository: wordRepository)
        toggleFavoriteUseCase = ToggleFavoriteUseCaseImpl(wordRepository: wordRepository)
        autofillWordUseCase = AutofillWordUseCaseImpl(dictionaryProvider: dictionaryProvider)
        csvImportUseCase = CSVImportUseCaseImpl(
            wordRepository: wordRepository,
            addWordUseCase: addWordUseCase
        )
        csvExportUseCase = CSVExportUseCaseImpl()
    }
}
