import SwiftUI

// MARK: - ContentView

public struct ContentView: View {
    @State private var sidebarSelection: SidebarView.SidebarItem? = .allWords
    @State private var selectedWord: Word?
    @State private var showWordEditor = false
    @State private var editingWord: Word?
    
    // ViewModels (DI에서 주입받아야 함)
    private let wordListViewModel: WordListViewModel
    private let wordDetailViewModel: WordDetailViewModel
    private let wordEditorViewModel: WordEditorViewModel
    
    public init(
        wordListViewModel: WordListViewModel,
        wordDetailViewModel: WordDetailViewModel,
        wordEditorViewModel: WordEditorViewModel
    ) {
        self.wordListViewModel = wordListViewModel
        self.wordDetailViewModel = wordDetailViewModel
        self.wordEditorViewModel = wordEditorViewModel
    }
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(selection: $sidebarSelection)
        } content: {
            Group {
                switch sidebarSelection {
                case .allWords:
                    WordListView(
                        viewModel: wordListViewModel,
                        selectedWord: $selectedWord,
                        onAddWord: {
                            editingWord = nil
                            showWordEditor = true
                        }
                    )
                    .onAppear {
                        wordListViewModel.applyFilter(WordFilter())
                    }
                case .favorites:
                    WordListView(
                        viewModel: wordListViewModel,
                        selectedWord: $selectedWord,
                        onAddWord: {
                            editingWord = nil
                            showWordEditor = true
                        }
                    )
                    .onAppear {
                        wordListViewModel.applyFilter(WordFilter(isFavorite: true))
                    }
                case .trash:
                    TrashView(
                        viewModel: wordListViewModel,
                        selectedWord: $selectedWord,
                        restoreWordUseCase: DIContainer.shared.restoreWordUseCase,
                        permanentlyDeleteWordUseCase: DIContainer.shared.permanentlyDeleteWordUseCase
                    )
                case .settings:
                    SettingsView(
                        persistenceController: DIContainer.shared.persistenceController,
                        csvImportUseCase: DIContainer.shared.csvImportUseCase,
                        csvExportUseCase: DIContainer.shared.csvExportUseCase,
                        fetchWordsUseCase: DIContainer.shared.fetchWordsUseCase,
                        dictionaryCache: DIContainer.shared.dictionaryCache
                    )
                case .none:
                    ContentUnavailableView(
                        "항목을 선택하세요",
                        systemImage: "sidebar.left"
                    )
                }
            }
        } detail: {
            if sidebarSelection == .allWords || sidebarSelection == .favorites {
                if let word = selectedWord {
                    WordDetailView(
                        viewModel: wordDetailViewModel,
                        onEdit: { word in
                            editingWord = word
                            showWordEditor = true
                        },
                        onDeleted: {
                            selectedWord = nil
                            Task {
                                await wordListViewModel.loadWords()
                            }
                        },
                        onFavoriteToggled: {
                            Task {
                                await wordListViewModel.loadWords()
                            }
                        }
                    )
                    .task {
                        await wordDetailViewModel.loadWord(id: word.id)
                    }
                } else {
                    ContentUnavailableView(
                        "단어를 선택하세요",
                        systemImage: "book.closed",
                        description: Text("목록에서 단어를 선택하면 상세 정보를 볼 수 있습니다")
                    )
                }
            } else {
                ContentUnavailableView(
                    "상세 정보",
                    systemImage: "info.circle"
                )
            }
        }
        .sheet(isPresented: $showWordEditor, onDismiss: {
            // 단어 추가/편집 후 목록 새로고침
            Task {
                await wordListViewModel.loadWords()
            }
        }) {
            NavigationStack {
                WordEditorView(viewModel: wordEditorViewModel)
                    .onAppear {
                        if let word = editingWord {
                            wordEditorViewModel.loadWord(word)
                        } else {
                            wordEditorViewModel.reset()
                        }
                    }
            }
        }
        .onChange(of: sidebarSelection) { _, newValue in
            // 사이드바 변경 시 필터 재적용
            if newValue == .favorites {
                wordListViewModel.applyFilter(WordFilter(isFavorite: true))
            } else if newValue == .allWords {
                wordListViewModel.applyFilter(WordFilter())
            }
        }
        .onChange(of: selectedWord) { _, newValue in
            if let word = newValue {
                Task {
                    await wordDetailViewModel.loadWord(id: word.id)
                }
            }
        }
    }
}
