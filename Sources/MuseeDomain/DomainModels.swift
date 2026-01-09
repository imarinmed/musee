import Foundation
import MuseeCore

public enum Platform: String, Codable, Sendable {
    case instagram
    case tiktok
    case twitter
    case youtube
    case onlyfans
    case website
    case local
}

public struct PlatformHandle: Hashable, Codable, Sendable {
    public let platform: Platform
    public let handle: String

    public init(platform: Platform, handle: String) {
        self.platform = platform
        self.handle = handle
    }
}

public struct Person: Hashable, Codable, Sendable {
    public let id: StableID
    public var displayName: String
    public var aliases: Set<String>
    public var handles: Set<PlatformHandle>
    public var tags: Set<Tag>

    public init(
        id: StableID,
        displayName: String,
        aliases: Set<String> = [],
        handles: Set<PlatformHandle> = [],
        tags: Set<Tag> = []
    ) {
        self.id = id
        self.displayName = displayName
        self.aliases = aliases
        self.handles = handles
        self.tags = tags
    }
}

public struct Tag: Hashable, Codable, Sendable {
    public enum Namespace: String, Codable, Sendable {
        case user
        case system
        case wing
        case source
    }

    public let namespace: Namespace
    public let value: String

    public init(namespace: Namespace = .user, value: String) {
        self.namespace = namespace
        self.value = value
    }
}

public enum MediaKind: String, Codable, Sendable {
    case image
    case video
    case audio
    case unknown
}

public struct MediaAsset: Hashable, Codable, Sendable, Identifiable {
    public let id: StableID
    public let sha256: String
    public let kind: MediaKind
    public let originalFilename: String?
    public let originalSourceURL: URL?
    public let capturedAt: PartialDate?

    public init(
        id: StableID,
        sha256: String,
        kind: MediaKind,
        originalFilename: String? = nil,
        originalSourceURL: URL? = nil,
        capturedAt: PartialDate? = nil
    ) {
        self.id = id
        self.sha256 = sha256
        self.kind = kind
        self.originalFilename = originalFilename
        self.originalSourceURL = originalSourceURL
        self.capturedAt = capturedAt
    }
}

public enum ClaimProperty: String, Codable, Sendable {
    case height
    case weight
    case bust
    case waist
    case hips
    case hairStyle
    case hairColor
    case relationship
    case similarity
    case eross
    case note
}

public enum ClaimValue: Hashable, Codable, Sendable {
    case string(String)
    case number(Double)
    case person(StableID)
    case media(StableID)

    private enum CodingKeys: String, CodingKey {
        case type
        case string
        case number
        case person
        case media
    }

    private enum ValueType: String, Codable {
        case string
        case number
        case person
        case media
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .string(value):
            try container.encode(ValueType.string, forKey: .type)
            try container.encode(value, forKey: .string)
        case let .number(value):
            try container.encode(ValueType.number, forKey: .type)
            try container.encode(value, forKey: .number)
        case let .person(value):
            try container.encode(ValueType.person, forKey: .type)
            try container.encode(value, forKey: .person)
        case let .media(value):
            try container.encode(ValueType.media, forKey: .type)
            try container.encode(value, forKey: .media)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ValueType.self, forKey: .type)
        switch type {
        case .string:
            self = try .string(container.decode(String.self, forKey: .string))
        case .number:
            self = try .number(container.decode(Double.self, forKey: .number))
        case .person:
            self = try .person(container.decode(StableID.self, forKey: .person))
        case .media:
            self = try .media(container.decode(StableID.self, forKey: .media))
        }
    }
}

public enum ConfidenceLevel: String, Codable, Sendable {
    case verified
    case high
    case medium
    case low
    case unverified
}

public enum ClaimRank: String, Codable, Sendable {
    case preferred
    case normal
    case deprecated
}

public struct ClaimReference: Hashable, Codable, Sendable {
    public enum ReferenceType: String, Codable, Sendable {
        case webpage
        case publication
        case database
        case media
        case user
        case system
    }

    public let type: ReferenceType
    public let url: URL?
    public let title: String?
    public let retrievedAt: Date?
    public let locator: String?

    public init(type: ReferenceType, url: URL?, title: String?, retrievedAt: Date?, locator: String? = nil) {
        self.type = type
        self.url = url
        self.title = title
        self.retrievedAt = retrievedAt
        self.locator = locator
    }
}

public struct BiographicalClaim: Hashable, Codable, Sendable {
    public let id: StableID
    public let subject: StableID
    public let property: ClaimProperty
    public let value: ClaimValue

    public let confidence: ConfidenceLevel
    public let rank: ClaimRank
    public let validAt: PartialDate?

    public let references: [ClaimReference]
    public let tags: Set<Tag>
    public let note: String?

    public init(
        id: StableID,
        subject: StableID,
        property: ClaimProperty,
        value: ClaimValue,
        confidence: ConfidenceLevel = .unverified,
        rank: ClaimRank = .normal,
        validAt: PartialDate? = nil,
        references: [ClaimReference] = [],
        tags: Set<Tag> = [],
        note: String? = nil
    ) {
        self.id = id
        self.subject = subject
        self.property = property
        self.value = value
        self.confidence = confidence
        self.rank = rank
        self.validAt = validAt
        self.references = references
        self.tags = tags
        self.note = note
    }
}

public struct RelationshipEdge: Hashable, Codable, Sendable {
    public enum EdgeType: String, Codable, Sendable {
        case knows
        case collaborated
        case resembles
        case inspiredBy
        case seenTogether
    }

    public let from: StableID
    public let to: StableID
    public let type: EdgeType
    public let evidence: [ClaimReference]
    public let validAt: PartialDate?

    public init(from: StableID, to: StableID, type: EdgeType, evidence: [ClaimReference] = [], validAt: PartialDate? = nil) {
        self.from = from
        self.to = to
        self.type = type
        self.evidence = evidence
        self.validAt = validAt
    }
}
