import Foundation

// MARK: - DictionaryResult

public struct DictionaryResult: Equatable, Sendable {
    public var reading: String?
    public var meanings: [String]
    public var examples: [ExamplePair]
    public var confidence: Double
    
    public struct ExamplePair: Equatable, Sendable {
        public var jp: String
        public var ko: String
        
        public init(jp: String, ko: String) {
            self.jp = jp
            self.ko = ko
        }
    }
    
    public init(
        reading: String? = nil,
        meanings: [String] = [],
        examples: [ExamplePair] = [],
        confidence: Double = 0.0
    ) {
        self.reading = reading
        self.meanings = meanings
        self.examples = examples
        self.confidence = confidence
    }
    
    // Convenience initializer for tuple-based examples
    public init(
        reading: String? = nil,
        meanings: [String] = [],
        examplesTuples: [(jp: String, ko: String)] = [],
        confidence: Double = 0.0
    ) {
        self.reading = reading
        self.meanings = meanings
        self.examples = examplesTuples.map { ExamplePair(jp: $0.jp, ko: $0.ko) }
        self.confidence = confidence
    }
}

// MARK: - DictionaryProvider Protocol

public protocol DictionaryProvider: Sendable {
    func search(term: String) async throws -> DictionaryResult?
}

// MARK: - TranslationProvider Protocol (Optional)

public protocol TranslationProvider: Sendable {
    func translate(text: String, from: String, to: String) async throws -> String
}

public extension TranslationProvider {
    /// 기본 구현: 순차 번역 (rate-limit 안전). 필요시 Data 레이어에서 최적화 가능.
    func translateMany(texts: [String], from: String, to: String) async throws -> [String] {
        var out: [String] = []
        out.reserveCapacity(texts.count)
        for t in texts {
            out.append(try await translate(text: t, from: from, to: to))
        }
        return out
    }
}

// MARK: - KanjiProvider Protocol (Optional)

public struct KanjiInfo: Equatable, Sendable {
    public var character: String
    public var readings: [String]
    public var meanings: [String]
    public var strokeCount: Int?
    
    public init(
        character: String,
        readings: [String] = [],
        meanings: [String] = [],
        strokeCount: Int? = nil
    ) {
        self.character = character
        self.readings = readings
        self.meanings = meanings
        self.strokeCount = strokeCount
    }
}

public protocol KanjiProvider: Sendable {
    func lookup(character: String) async throws -> KanjiInfo?
}
