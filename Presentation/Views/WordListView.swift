import SwiftUI

// MARK: - WordListView

public struct WordListView: View {
    @StateObject private var viewModel: WordListViewModel
    @Binding public var selectedWord: Word?
    public var onAddWord: () -> Void
    
    public init(
        viewModel: WordListViewModel,
        selectedWord: Binding<Word?>,
        onAddWord: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._selectedWord = selectedWord
        self.onAddWord = onAddWord
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 검색 및 필터 바
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                    
                    TextField("검색", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .onChange(of: viewModel.searchText) { _, _ in
                            Task {
                                await viewModel.loadWords()
                            }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                }
                
                Menu {
                    Picker("정렬", selection: $viewModel.sortOrder) {
                        ForEach(WordSortOrder.allCases, id: \.self) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                    .onChange(of: viewModel.sortOrder) { _, _ in
                        Task {
                            await viewModel.loadWords()
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(.quaternary)
                        }
                }
                .buttonStyle(.plain)
                
                Button(action: onAddWord) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.accentColor)
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            // 단어 목록
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.words.isEmpty {
                ContentUnavailableView(
                    "단어가 없습니다",
                    systemImage: "book.closed",
                    description: Text("새 단어를 추가해보세요")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.words) { word in
                            WordRowCard(word: word, isSelected: selectedWord?.id == word.id)
                                .onTapGesture {
                                    selectedWord = word
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .glassmorphism(material: .contentBackground)
            }
        }
        .task {
            await viewModel.loadWords()
        }
    }
}

// MARK: - WordRowCard

private struct WordRowCard: View {
    let word: Word
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.jpText)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundStyle(.primary)
                    
                    if let reading = word.reading, !reading.isEmpty {
                        Text(reading)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    
                    if word.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.yellow)
                    }
                }
                
                Text(word.meaning)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
                }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - WordSortOrder Extension

extension WordSortOrder {
    var displayName: String {
        switch self {
        case .newest: return "최신순"
        case .japanese: return "일본어순"
        }
    }
}
