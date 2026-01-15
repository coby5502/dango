import Foundation

// MARK: - CSVImportUseCase

public protocol CSVImportUseCase: Sendable {
    func execute(csvData: Data, duplicatePolicy: DuplicateHandlingPolicy) async throws -> ImportResult
}

public struct ImportResult: Equatable, Sendable {
    public var imported: Int
    public var updated: Int
    public var skipped: Int
    public var errors: [String]
    
    public init(imported: Int = 0, updated: Int = 0, skipped: Int = 0, errors: [String] = []) {
        self.imported = imported
        self.updated = updated
        self.skipped = skipped
        self.errors = errors
    }
}

public final class CSVImportUseCaseImpl: CSVImportUseCase, @unchecked Sendable {
    private let wordRepository: WordRepository
    private let addWordUseCase: AddWordUseCase
    
    public init(
        wordRepository: WordRepository,
        addWordUseCase: AddWordUseCase
    ) {
        self.wordRepository = wordRepository
        self.addWordUseCase = addWordUseCase
    }
    
    public func execute(csvData: Data, duplicatePolicy: DuplicateHandlingPolicy) async throws -> ImportResult {
        guard let csvString = String(data: csvData, encoding: .utf8) else {
            throw ImportExportError.invalidEncoding
        }
        
        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard lines.count > 1 else {
            throw ImportExportError.emptyFile
        }
        
        // 헤더 파싱 (현재는 사용하지 않음)
        _ = lines[0].components(separatedBy: ",")
        
        var result = ImportResult()
        
        // 데이터 행 처리
        for (index, line) in lines.dropFirst().enumerated() {
            let columns = parseCSVLine(line)
            
            guard columns.count >= 3 else {
                result.errors.append("행 \(index + 2): 필수 컬럼 부족")
                result.skipped += 1
                continue
            }
            
            do {
                let jpText = columns[0].trimmingCharacters(in: .whitespaces)
                guard !jpText.isEmpty else {
                    result.errors.append("행 \(index + 2): jpText가 비어있음")
                    result.skipped += 1
                    continue
                }
                
                let reading = columns.count > 1 && !columns[1].isEmpty ? columns[1].trimmingCharacters(in: .whitespaces) : nil
                let meaning = columns[2].trimmingCharacters(in: .whitespaces)
                
                guard !meaning.isEmpty else {
                    result.errors.append("행 \(index + 2): 뜻이 비어있음")
                    result.skipped += 1
                    continue
                }
                
                let word = Word(
                    jpText: jpText,
                    reading: reading,
                    meaning: meaning
                )
                
                let existing = try await wordRepository.findDuplicate(jpText: jpText)
                if existing != nil && duplicatePolicy == .update {
                    var updated = existing!
                    updated.reading = reading ?? updated.reading
                    updated.meaning = meaning
                    updated.updatedAt = Date()
                    _ = try await wordRepository.update(updated)
                    result.updated += 1
                } else if existing == nil || duplicatePolicy == .addNew {
                    _ = try await addWordUseCase.execute(word, duplicatePolicy: duplicatePolicy)
                    result.imported += 1
                } else {
                    result.skipped += 1
                }
            } catch {
                result.errors.append("행 \(index + 2): \(error.localizedDescription)")
                result.skipped += 1
            }
        }
        
        return result
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }
}

// MARK: - CSVExportUseCase

public protocol CSVExportUseCase: Sendable {
    func execute(words: [Word]) async throws -> Data
}

public final class CSVExportUseCaseImpl: CSVExportUseCase, @unchecked Sendable {
    public init() {}
    
    public func execute(words: [Word]) async throws -> Data {
        var csvLines: [String] = []
        
        // 헤더
        csvLines.append("jpText,reading,meaning")
        
        // 데이터
        for word in words {
            let jpText = escapeCSV(word.jpText)
            let reading = escapeCSV(word.reading ?? "")
            let meaning = escapeCSV(word.meaning)
            
            csvLines.append("\(jpText),\(reading),\(meaning)")
        }
        
        let csvString = csvLines.joined(separator: "\n")
        guard let data = csvString.data(using: .utf8) else {
            throw ImportExportError.encodingFailed
        }
        
        return data
    }
    
    private func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return text
    }
}

// MARK: - ImportExportError

public enum ImportExportError: LocalizedError {
    case invalidEncoding
    case emptyFile
    case encodingFailed
    case fileNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "CSV 파일 인코딩 오류"
        case .emptyFile:
            return "빈 파일입니다"
        case .encodingFailed:
            return "CSV 인코딩 실패"
        case .fileNotFound:
            return "파일을 찾을 수 없습니다"
        }
    }
}
