import Foundation
import MuseeCore

public enum MuseumSpec {
    public static let museumExtension = "museum"
    public static let indexFilename = "museum.json"

    public static let wingsDirectory = "Wings"
    public static let exhibitsDirectory = "Exhibits"
}

public struct MuseumIndex: Codable, Sendable {
    public struct Wing: Codable, Sendable, Hashable, Identifiable {
        public let id: StableID
        public let name: String
        public let description: String?
        public let categories: [String]  // Custom categories/folders
        public let sharedWith: [String]?  // User IDs or emails for sharing

        public init(id: StableID, name: String, description: String?, categories: [String] = [], sharedWith: [String]? = nil) {
            self.id = id
            self.name = name
            self.description = description
            self.categories = categories
            self.sharedWith = sharedWith
        }
    }

    public let formatVersion: String
    public let createdAt: Date

    public let wings: [Wing]

    public init(formatVersion: String, createdAt: Date, wings: [Wing]) {
        self.formatVersion = formatVersion
        self.createdAt = createdAt
        self.wings = wings
    }
}
