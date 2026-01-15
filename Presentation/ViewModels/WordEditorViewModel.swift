import Foundation
import SwiftUI

// MARK: - WordEditorViewModel

@MainActor
public final class WordEditorViewModel: ObservableObject {
    @Published public var jpText: String = ""
    @Published public var reading: String = ""
    @Published public var meaning: String = ""
    
    // AutoFill
    @Published public var autoFillStatus: AutoFillState = .none
    @Published public var autoFillResult: DictionaryResult?
    // 자동 적용: 후보 패널을 띄우지 않음
    @Published public var autoFillMessage: String?
    @Published public var autoFillProviderUsed: String?
    @Published public var autoFillConfidence: Double?
    @Published public var autoFillLastFetchedAt: Date?
    
    // Editing
    public var editingWord: Word?
    public var isEditing: Bool { editingWord != nil }
    
    private let addWordUseCase: AddWordUseCase
    private let updateWordUseCase: UpdateWordUseCase
    private let autofillWordUseCase: AutofillWordUseCase
    
    private var autofillTask: Task<Void, Never>?
    private let debounceDelay: TimeInterval = 0.4
    
    public init(
        addWordUseCase: AddWordUseCase,
        updateWordUseCase: UpdateWordUseCase,
        autofillWordUseCase: AutofillWordUseCase
    ) {
        self.addWordUseCase = addWordUseCase
        self.updateWordUseCase = updateWordUseCase
        self.autofillWordUseCase = autofillWordUseCase
    }
    
    public func loadWord(_ word: Word) {
        editingWord = word
        jpText = word.jpText
        reading = word.reading ?? ""
        meaning = word.meaning
    }
    
    public func reset() {
        editingWord = nil
        jpText = ""
        reading = ""
        meaning = ""
        autoFillStatus = .none
        autoFillResult = nil
        autoFillMessage = nil
        autoFillProviderUsed = nil
        autoFillConfidence = nil
        autoFillLastFetchedAt = nil
        autofillTask?.cancel()
    }
    
    public func onJpTextChanged(_ text: String) {
        let previousJpText = jpText
        jpText = text
        
        // 편집 모드가 아니고 비어있지 않으면 자동 채움 실행
        if !isEditing && !text.isEmpty {
            // jpText가 완전히 바뀌었으면 (이전 값과 다르면) 기존 값 초기화 후 새로 채움
            if previousJpText != text && !previousJpText.isEmpty {
                reading = ""
                meaning = ""
            }
            triggerAutofill()
        }
    }
    
    private func triggerAutofill() {
        autofillTask?.cancel()
        
        autofillTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            await performAutofill()
        }
    }
    
    public func retryAutofill() async {
        autofillTask?.cancel()
        await performAutofill()
    }
    
    private func performAutofill() async {
        let term = jpText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        
        autoFillStatus = .fetching
        autoFillMessage = nil
        autoFillProviderUsed = nil
        autoFillConfidence = nil
        autoFillLastFetchedAt = nil
        
        do {
            let result = try await autofillWordUseCase.execute(jpText: term)
            autoFillLastFetchedAt = Date()
            autoFillProviderUsed = String(describing: type(of: autofillWordUseCase))
            
            guard let result else {
                autoFillResult = nil
                autoFillStatus = .failed
                autoFillMessage = "결과가 없습니다. 수동 입력을 계속할 수 있어요."
                return
            }
            
            autoFillResult = result
            autoFillConfidence = result.confidence
            
            let hasReading = (result.reading?.isEmpty == false)
            let hasMeanings = !result.meanings.isEmpty
            
            if !hasReading && !hasMeanings {
                autoFillStatus = .failed
                autoFillMessage = "결과가 없습니다. 수동 입력을 계속할 수 있어요."
                return
            }
            
            autoFillStatus = (hasReading && hasMeanings) ? .filled : .partial
            autoFillMessage = nil
            
            // 자동 적용: 새로 입력할 때는 항상 덮어쓰기
            if let r = result.reading?.trimmingCharacters(in: .whitespacesAndNewlines), !r.isEmpty {
                reading = r
            }
            
            // 뜻 여러 개를 줄바꿈으로 합쳐서 저장
            if !result.meanings.isEmpty {
                let allMeanings = result.meanings
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !allMeanings.isEmpty {
                    meaning = allMeanings.joined(separator: "\n")
                }
            }
        } catch {
            autoFillResult = nil
            autoFillStatus = .failed
            autoFillMessage = "자동 채움에 실패했어요. 네트워크 없이도 수동 입력은 계속할 수 있어요."
        }
    }
    
    public func save(duplicatePolicy: DuplicateHandlingPolicy) async throws -> Word {
        guard !jpText.isEmpty, !meaning.isEmpty else {
            throw WordError.invalidInput("일본어와 대표 뜻은 필수입니다.")
        }
        
        let word = Word(
            id: editingWord?.id ?? UUID(),
            jpText: jpText,
            reading: reading.isEmpty ? nil : reading,
            meaning: meaning,
            isFavorite: editingWord?.isFavorite ?? false,
            createdAt: editingWord?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        if isEditing {
            return try await updateWordUseCase.execute(word)
        } else {
            return try await addWordUseCase.execute(word, duplicatePolicy: duplicatePolicy)
        }
    }
    
}
