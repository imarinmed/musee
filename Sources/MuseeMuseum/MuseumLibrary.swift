import Foundation
import MuseeBundle
import MuseeCore
import CryptoKit

public struct MuseumLibrary {
    public let museumURL: URL

    public init(museumURL: URL) {
        self.museumURL = museumURL
    }

    public var indexURL: URL {
        museumURL.appendingPathComponent(MuseumSpec.indexFilename)
    }

    public var wingsRootURL: URL {
        museumURL.appendingPathComponent(MuseumSpec.wingsDirectory, isDirectory: true)
    }

    public func readIndex() throws -> MuseumIndex {
        let data = try Data(contentsOf: indexURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MuseumIndex.self, from: data)
    }

    public func writeIndex(_ index: MuseumIndex) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(index)
        try data.write(to: indexURL, options: [.atomic])
    }

    public static func createNew(at museumURL: URL, wings: [MuseumIndex.Wing]) throws -> MuseumLibrary {
        try FileManager.default.createDirectory(at: museumURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: museumURL.appendingPathComponent(MuseumSpec.wingsDirectory, isDirectory: true), withIntermediateDirectories: true)

        let library = MuseumLibrary(museumURL: museumURL)
        let index = MuseumIndex(formatVersion: MuseeCore.currentFormatVersion, createdAt: Date(), wings: wings)
        try library.writeIndex(index)

        for wing in wings {
            let wingURL = library.wingsRootURL.appendingPathComponent(wing.id.rawValue, isDirectory: true)
            try FileManager.default.createDirectory(at: wingURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: wingURL.appendingPathComponent(MuseumSpec.exhibitsDirectory, isDirectory: true), withIntermediateDirectories: true)
        }

        return library
    }

    public func wingURL(id: StableID) -> URL {
        wingsRootURL.appendingPathComponent(id.rawValue, isDirectory: true)
    }

    public func exhibitsURL(wingID: StableID) -> URL {
        wingURL(id: wingID).appendingPathComponent(MuseumSpec.exhibitsDirectory, isDirectory: true)
    }

    public func install(bundle: MuseeBundle, intoWing wingID: StableID) throws -> URL {
        let dest = exhibitsURL(wingID: wingID).appendingPathComponent(bundle.bundleURL.lastPathComponent, isDirectory: true)
        if FileManager.default.fileExists(atPath: dest.path) {
            throw MuseeError.invalidArgument("Exhibit already exists: \(dest.lastPathComponent)")
        }
        try FileManager.default.copyItem(at: bundle.bundleURL, to: dest)
        return dest
    }

    public func listExhibits(wingID: StableID) throws -> [URL] {
        let dir = exhibitsURL(wingID: wingID)
        guard FileManager.default.fileExists(atPath: dir.path) else {
            return []
        }
        return try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == MuseeBundleSpec.bundleExtension }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Backup the museum to an encrypted file.
    public func backup(to backupURL: URL, key: SymmetricKey) throws {
        let data = try Data(contentsOf: museumURL, options: .mappedIfSafe)
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let encryptedData = sealedBox.combined else {
            throw MuseeError.processingFailed("Failed to create encrypted data")
        }
        try encryptedData.write(to: backupURL, options: [.atomic])
    }

    /// Restore the museum from an encrypted backup.
    public func restore(from backupURL: URL, key: SymmetricKey, to museumURL: URL) throws {
        let encryptedData = try Data(contentsOf: backupURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let data = try AES.GCM.open(sealedBox, using: key)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try FileManager.default.moveItem(at: tempURL, to: museumURL)
    }
}
