import SwiftUI

// MARK: - WordDetailView

public struct WordDetailView: View {
    @StateObject private var viewModel: WordDetailViewModel
    public var onEdit: (Word) -> Void
    public var onDeleted: () -> Void
    public var onFavoriteToggled: (() -> Void)?
    
    public init(
        viewModel: WordDetailViewModel,
        onEdit: @escaping (Word) -> Void,
        onDeleted: @escaping () -> Void,
        onFavoriteToggled: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onEdit = onEdit
        self.onDeleted = onDeleted
        self.onFavoriteToggled = onFavoriteToggled
    }
    
    public var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let word = viewModel.word {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 헤더 카드
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(word.jpText)
                                    .font(.system(size: 36, weight: .bold, design: .default))
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        await viewModel.toggleFavorite()
                                        onFavoriteToggled?()
                                    }
                                }) {
                                    Image(systemName: word.isFavorite ? "star.fill" : "star")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(word.isFavorite ? .yellow : .secondary)
                                        .frame(width: 36, height: 36)
                                        .background {
                                            Circle()
                                                .fill(.quaternary)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if let reading = word.reading, !reading.isEmpty {
                                Text(reading)
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(NSColor.controlBackgroundColor))
                        }
                        
                        // 뜻 섹션
                        VStack(alignment: .leading, spacing: 10) {
                            Text("뜻")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            Text(word.meaning)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.primary)
                                .lineSpacing(5)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(NSColor.controlBackgroundColor))
                                }
                        }
                        
                        // 액션 버튼
                        HStack(spacing: 12) {
                            Button {
                                onEdit(word)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("편집")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.accentColor)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            if word.isDeleted {
                                Button {
                                    Task {
                                        await viewModel.restoreWord()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.uturn.backward")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("복원")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.green)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    Task {
                                        await viewModel.permanentlyDeleteWord()
                                        onDeleted()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("영구 삭제")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.red)
                                    }
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    Task {
                                        await viewModel.deleteWord()
                                        onDeleted()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("삭제")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.red)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                }
                .glassmorphism(material: .contentBackground)
            } else {
                ContentUnavailableView(
                    "단어를 선택하세요",
                    systemImage: "book.closed"
                )
            }
        }
    }
}
