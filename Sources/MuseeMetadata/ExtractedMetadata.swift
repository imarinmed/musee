import Foundation
import MuseeCore
import MuseeDomain

/// Entity for storing extracted metadata as immutable snapshots.
public struct ExtractedMetadata: Codable, Sendable {
    public let mediaAssetId: StableID
    public let extractedAt: Date
    public let extractorVersion: String
    public let rawMetadataJSON: Data

    public init(mediaAssetId: StableID, extractedAt: Date, extractorVersion: String, rawMetadata: [String: Any]) throws {
        self.mediaAssetId = mediaAssetId
        self.extractedAt = extractedAt
        self.extractorVersion = extractorVersion
        self.rawMetadataJSON = try JSONSerialization.data(withJSONObject: rawMetadata, options: [])
    }

    public var rawMetadata: [String: Any] {
        get throws {
            try JSONSerialization.jsonObject(with: rawMetadataJSON, options: []) as? [String: Any] ?? [:]
        }
    }
}