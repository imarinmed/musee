import Foundation
import MuseeCore
import MuseeDomain

public enum MuseeBundleSpec {
    public static let bundleExtension = "musee"
    public static let manifestFilename = "manifest.json"

    public static let objectsDirectory = "Objects"
    public static let metadataDirectory = "Metadata"
    public static let attachmentsDirectory = "Attachments"
}

public struct MuseeManifest: Codable, Sendable {
    public struct BundleInfo: Codable, Sendable {
        public let formatVersion: String
        public let createdAt: Date
        public let app: String

        public init(formatVersion: String, createdAt: Date, app: String) {
            self.formatVersion = formatVersion
            self.createdAt = createdAt
            self.app = app
        }
    }

    public let bundle: BundleInfo

    public let person: Person
    public let tags: [Tag]

    public let assets: [MediaAsset]
    public let claims: [BiographicalClaim]
    public let relationships: [RelationshipEdge]

    public init(bundle: BundleInfo, person: Person, tags: [Tag], assets: [MediaAsset], claims: [BiographicalClaim], relationships: [RelationshipEdge]) {
        self.bundle = bundle
        self.person = person
        self.tags = tags
        self.assets = assets
        self.claims = claims
        self.relationships = relationships
    }
}
