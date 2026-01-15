import SwiftUI

// MARK: - TrashView

public struct TrashView: View {
    @StateObject private var viewModel: WordListViewModel
    @Binding public var selectedWord: Word?
    private let restoreWordUseCase: RestoreWordUseCase
    private let permanentlyDeleteWordUseCase: PermanentlyDeleteWordUseCase
    @State private var errorMessage: String?
    @State private var showError = false
    
    public init(
        viewModel: WordListViewModel,
        selectedWord: Binding<Word?>,
        restoreWordUseCase: RestoreWordUseCase,
        permanentlyDeleteWordUseCase: PermanentlyDeleteWordUseCase
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._selectedWord = selectedWord
        self.restoreWordUseCase = restoreWordUseCase
        self.permanentlyDeleteWordUseCase = permanentlyDeleteWordUseCase
    }
    
    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.words.isEmpty {
                ContentUnavailableView(
                    "휴지통이 비어있습니다",
                    systemImage: "trash.fill",
                    description: Text("삭제된 단어가 없습니다")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.words) { word in
                            TrashWordCard(
                                word: word,
                                isSelected: selectedWord?.id == word.id,
                                onRestore: {
                                    Task {
                                        await restoreWord(word)
                                    }
                                },
                                onPermanentlyDelete: {
                                    Task {
                                        await permanentlyDeleteWord(word)
                                    }
                                }
                            )
                            .onTapGesture {
                                selectedWord = word
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("휴지통")
        .task {
            viewModel.applyFilter(WordFilter(showDeleted: true))
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다")
        }
    }
    
    private func restoreWord(_ word: Word) async {
        do {
            _ = try await restoreWordUseCase.execute(word)
            // 목록 새로고침
            await viewModel.loadWords()
            // 선택 해제
            if selectedWord?.id == word.id {
                selectedWord = nil
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func permanentlyDeleteWord(_ word: Word) async {
        do {
            try await permanentlyDeleteWordUseCase.execute(word)
            // 목록 새로고침
            await viewModel.loadWords()
            // 선택 해제
            if selectedWord?.id == word.id {
                selectedWord = nil
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - TrashWordCard

private struct TrashWordCard: View {
    let word: Word
    let isSelected: Bool
    let onRestore: () -> Void
    let onPermanentlyDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.jpText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    if let reading = word.reading, !reading.isEmpty {
                        Text(reading)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(word.meaning)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    onRestore()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background {
                            Circle()
                                .fill(.green)
                        }
                }
                .buttonStyle(.plain)
                
                Button {
                    onPermanentlyDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background {
                            Circle()
                                .fill(.red)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
                }
        }
        .contentShape(Rectangle())
    }
}
