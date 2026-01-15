import SwiftUI

// MARK: - WordEditorView

public struct WordEditorView: View {
    @StateObject private var viewModel: WordEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var duplicatePolicy: DuplicateHandlingPolicy = .ask
    @State private var showDuplicateAlert = false
    @State private var duplicateWord: Word?
    
    public init(viewModel: WordEditorViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 일본어 입력
                VStack(alignment: .leading, spacing: 6) {
                    Text("일본어")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    TextField("단어를 입력하세요", text: $viewModel.jpText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .medium))
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                        }
                        .onChange(of: viewModel.jpText) { _, newValue in
                            viewModel.onJpTextChanged(newValue)
                        }
                }
                
                // 읽기 입력
                VStack(alignment: .leading, spacing: 6) {
                    Text("읽기")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    TextField("읽는 방법 (선택사항)", text: $viewModel.reading)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .regular))
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                        }
                }
                
                // 뜻 입력
                VStack(alignment: .leading, spacing: 6) {
                    Text("뜻")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    TextField("의미를 입력하세요", text: $viewModel.meaning, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .regular))
                        .lineLimit(3...10)
                        .padding(14)
                        .frame(minHeight: 90, alignment: .topLeading)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                        }
                }
                
                // 자동 채움 상태 표시
                if viewModel.autoFillStatus != .none {
                    HStack(spacing: 8) {
                        if viewModel.autoFillStatus == .fetching {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: viewModel.autoFillStatus == .filled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundStyle(viewModel.autoFillStatus == .filled ? .green : .orange)
                        }
                        
                        Text(viewModel.autoFillMessage ?? (viewModel.autoFillStatus == .fetching ? "자동 채움 중..." : "자동 채움 완료"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(viewModel.isEditing ? "단어 편집" : "새 단어")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    Task {
                        await saveWord()
                    }
                }
                .font(.system(size: 15, weight: .semibold))
            }
        }
        .alert("중복된 단어", isPresented: $showDuplicateAlert) {
            Button("업데이트") {
                duplicatePolicy = .update
                Task {
                    await saveWord()
                }
            }
            Button("새로 추가") {
                duplicatePolicy = .addNew
                Task {
                    await saveWord()
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            if let duplicate = duplicateWord {
                Text("'\(duplicate.jpText)'가 이미 존재합니다.")
            }
        }
    }
    
    private func saveWord() async {
        do {
            _ = try await viewModel.save(duplicatePolicy: duplicatePolicy)
            dismiss()
        } catch WordError.duplicateFound(let word) {
            duplicateWord = word
            if duplicatePolicy == .ask {
                showDuplicateAlert = true
            }
        } catch {
            // 에러 처리
        }
    }
}

