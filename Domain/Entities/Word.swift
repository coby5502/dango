import Foundation

// MARK: - Word Entity

public struct Word: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: UUID
    public var jpText: String
    public var reading: String?
    /// 사용자에게 보이는 “뜻” (대표 뜻)
    public var meaning: String
    public var sourceType: SourceType?
    public var sourceText: String?
    public var sourceLink: String?
    public var isFavorite: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    
    // AutoFill fields
    public var autoFill: AutoFillStatus
    
    public init(
        id: UUID = UUID(),
        jpText: String,
        reading: String? = nil,
        meaning: String,
        sourceType: SourceType? = nil,
        sourceText: String? = nil,
        sourceLink: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        autoFill: AutoFillStatus = AutoFillStatus(status: .none)
    ) {
        self.id = id
        self.jpText = jpText
        self.reading = reading
        self.meaning = meaning
        self.sourceType = sourceType
        self.sourceText = sourceText
        self.sourceLink = sourceLink
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.autoFill = autoFill
    }
    
    public var isDeleted: Bool {
        deletedAt != nil
    }
}

// MARK: - Supporting Types

public enum SourceType: String, Codable, CaseIterable, Sendable {
    case book
    case article
    case video
    case conversation
    case other
}

public struct AutoFillStatus: Equatable, Hashable, Codable, Sendable {
    public var status: AutoFillState
    public var providerUsed: String?
    public var confidence: Double?
    public var lastFetchedAt: Date?
    // Note: rawPayload는 Equatable이 아니므로 제외
    // 필요시 별도로 처리
    
    public init(
        status: AutoFillState = .none,
        providerUsed: String? = nil,
        confidence: Double? = nil,
        lastFetchedAt: Date? = nil
    ) {
        self.status = status
        self.providerUsed = providerUsed
        self.confidence = confidence
        self.lastFetchedAt = lastFetchedAt
    }
    
    // Codable support
    enum CodingKeys: String, CodingKey {
        case status, providerUsed, confidence, lastFetchedAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(AutoFillState.self, forKey: .status)
        providerUsed = try container.decodeIfPresent(String.self, forKey: .providerUsed)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        lastFetchedAt = try container.decodeIfPresent(Date.self, forKey: .lastFetchedAt)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(providerUsed, forKey: .providerUsed)
        try container.encodeIfPresent(confidence, forKey: .confidence)
        try container.encodeIfPresent(lastFetchedAt, forKey: .lastFetchedAt)
    }
}

public enum AutoFillState: String, Codable, Sendable {
    case none
    case fetching
    case filled
    case partial
    case failed
}

// MARK: - Duplicate Handling Policy

public enum DuplicateHandlingPolicy: String, Codable, CaseIterable, Sendable {
    case update = "update"           // 기존 업데이트
    case addNew = "addNew"           // 새로 추가
    case ask = "ask"                 // 묻기
}

// MARK: - Sort Order

public enum WordSortOrder: String, Codable, CaseIterable, Sendable {
    case newest = "newest"           // 최신순
    case japanese = "japanese"       // 일본어순
}

// MARK: - Filter Criteria

public struct WordFilter: Equatable, Sendable {
    public var sourceType: SourceType?
    public var isFavorite: Bool?
    public var showDeleted: Bool? // true면 삭제된 것만, false면 삭제되지 않은 것만, nil이면 모두
    
    public init(
        sourceType: SourceType? = nil,
        isFavorite: Bool? = nil,
        showDeleted: Bool? = nil
    ) {
        self.sourceType = sourceType
        self.isFavorite = isFavorite
        self.showDeleted = showDeleted
    }
}
