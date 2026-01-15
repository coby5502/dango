import Foundation

// MARK: - HTTP Abstraction (SOLID)

public protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public final class URLSessionHTTPClient: HTTPClient, @unchecked Sendable {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, http)
    }
}

// MARK: - Real Provider (Jisho API)
// Note:
// - 무료 공개 API: https://jisho.org/api/v1/search/words?keyword=...
// - 예문은 제공하지 않아서 meanings/reading 위주로 채움
// TODO: 네이버/국내 사전 API를 붙일 땐 DictionaryProvider 구현체만 교체하면 됨

public final class JishoDictionaryProvider: DictionaryProvider, @unchecked Sendable {
    private let http: HTTPClient
    private let cache: DictionaryCache
    private let fallback: DictionaryProvider
    private let translator: TranslationProvider?
    
    public init(http: HTTPClient, cache: DictionaryCache, fallback: DictionaryProvider, translator: TranslationProvider? = nil) {
        self.http = http
        self.cache = cache
        self.fallback = fallback
        self.translator = translator
    }
    
    public func search(term: String) async throws -> DictionaryResult? {
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return nil }
        
        // 캐시 확인
        if let cached = await cache.get(term: term) {
            return cached
        }
        
        do {
            let result = try await fetchFromJisho(term: term)
            if let result {
                await cache.set(term: term, result: result)
            }
            return result
        } catch {
            // 네트워크/파싱 실패 시 오프라인 fallback (UX 블로킹 금지)
            let fallbackResult = try await fallback.search(term: term)
            if let fallbackResult {
                await cache.set(term: term, result: fallbackResult)
            }
            return fallbackResult
        }
    }
    
    private func fetchFromJisho(term: String) async throws -> DictionaryResult? {
        var components = URLComponents(string: "https://jisho.org/api/v1/search/words")!
        components.queryItems = [URLQueryItem(name: "keyword", value: term)]
        let url = components.url!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, http) = try await http.data(for: request)
        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(JishoResponse.self, from: data)
        guard let first = decoded.data.first else { return nil }
        
        // reading
        let reading = first.japanese.first?.reading
        
        // meanings
        // 1) Jisho는 영문 정의를 제공
        let englishMeanings: [String] = first.senses
            .prefix(8)
            .map { $0.english_definitions.joined(separator: "; ") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // 2) 가능한 경우 한글로 번역해서 반환 (업무용 UX: 한글 뜻 우선)
        let meanings: [String]
        if let translator, !englishMeanings.isEmpty {
            meanings = try await translator.translateMany(texts: englishMeanings, from: "en", to: "ko")
        } else {
            meanings = englishMeanings
        }
        
        // examples: Jisho API는 예문을 제공하지 않음
        let examples: [DictionaryResult.ExamplePair] = []
        
        return DictionaryResult(
            reading: reading,
            meanings: meanings,
            examples: examples,
            confidence: meanings.isEmpty ? 0.6 : 0.9
        )
    }
}

// MARK: - Translation

public final class GoogleTranslateProvider: TranslationProvider, @unchecked Sendable {
    private let http: HTTPClient
    
    public init(http: HTTPClient) {
        self.http = http
    }
    
    public func translate(text: String, from: String, to: String) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        // Unofficial endpoint (no key). Works for many cases; keep as best-effort.
        // https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ko&dt=t&q=...
        var components = URLComponents(string: "https://translate.googleapis.com/translate_a/single")!
        components.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: from),
            URLQueryItem(name: "tl", value: to),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "q", value: trimmed)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, httpResponse) = try await http.data(for: request)
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Response is a nested array. We parse loosely.
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard
            let root = json as? [Any],
            let firstArray = root.first as? [Any]
        else {
            return trimmed
        }
        
        let pieces: [String] = firstArray.compactMap { item in
            guard let arr = item as? [Any], let translated = arr.first as? String else { return nil }
            return translated
        }
        
        let joined = pieces.joined()
        return joined.isEmpty ? trimmed : joined
    }
    
    // Batch helper: avoid blasting too many requests
    public func translateMany(texts: [String], from: String, to: String) async throws -> [String] {
        var results: [String] = []
        results.reserveCapacity(texts.count)
        for t in texts {
            // NOTE: sequential to be gentle; can be parallelized later with rate limiting
            let translated = try await translate(text: t, from: from, to: to)
            results.append(translated)
        }
        return results
    }
}

// MARK: - Offline Fallback (Mock)

public final class MockDictionaryProvider: DictionaryProvider, @unchecked Sendable {
    private let cache: DictionaryCache
    
    public init(cache: DictionaryCache) {
        self.cache = cache
    }
    
    public func search(term: String) async throws -> DictionaryResult? {
        if let cached = await cache.get(term: term) { return cached }
        
        // 데모/오프라인 fallback 데이터
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15초
        let result = generateMockResult(for: term)
        await cache.set(term: term, result: result)
        return result
    }
    
    private func generateMockResult(for term: String) -> DictionaryResult {
        let meanings = ["(offline) \(term) - meaning 1", "(offline) \(term) - meaning 2"]
        let examplePairs = [
            DictionaryResult.ExamplePair(jp: "\(term)の例文です。", ko: "\(term)의 예문입니다."),
            DictionaryResult.ExamplePair(jp: "これは\(term)です。", ko: "이것은 \(term)입니다.")
        ]
        let reading = estimateReading(for: term)
        
        return DictionaryResult(
            reading: reading,
            meanings: meanings,
            examples: examplePairs,
            confidence: 0.4
        )
    }
    
    private func estimateReading(for term: String) -> String? {
        if term.allSatisfy({ $0.isHiragana || $0.isKatakana }) { return term }
        return nil
    }
}

// MARK: - Jisho Models

private struct JishoResponse: Decodable {
    let data: [JishoEntry]
}

private struct JishoEntry: Decodable {
    let japanese: [JishoJapanese]
    let senses: [JishoSense]
}

private struct JishoJapanese: Decodable {
    let reading: String?
    let word: String?
}

private struct JishoSense: Decodable {
    let english_definitions: [String]
    let parts_of_speech: [String]?
}

// MARK: - Character Extensions

private extension Character {
    var isHiragana: Bool { "\u{3040}"..."\u{309F}" ~= self }
    var isKatakana: Bool { "\u{30A0}"..."\u{30FF}" ~= self }
}

// MARK: - DictionaryCache

public actor DictionaryCache {
    private var cache: [String: (result: DictionaryResult, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 30 * 24 * 60 * 60 // 30일
    
    public init() {}
    
    public func get(term: String) -> DictionaryResult? {
        guard let entry = cache[term] else { return nil }
        
        // TTL 체크
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            cache.removeValue(forKey: term)
            return nil
        }
        
        return entry.result
    }
    
    public func set(term: String, result: DictionaryResult) {
        cache[term] = (result: result, timestamp: Date())
    }
    
    public func clear() {
        cache.removeAll()
    }
    
    public func remove(term: String) {
        cache.removeValue(forKey: term)
    }
}
