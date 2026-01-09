import Foundation
import MuseeCAS
import MuseeCore
import MuseeDomain

public struct MuseeBundle {
    public let bundleURL: URL

    public init(bundleURL: URL) {
        self.bundleURL = bundleURL
    }

    public var manifestURL: URL {
        bundleURL.appendingPathComponent(MuseeBundleSpec.manifestFilename)
    }

    public var objectsRootURL: URL {
        bundleURL.appendingPathComponent(MuseeBundleSpec.objectsDirectory, isDirectory: true)
    }

    public func readManifest() throws -> MuseeManifest {
        let data = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MuseeManifest.self, from: data)
    }

    public func writeManifest(_ manifest: MuseeManifest) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(manifest)
        try data.write(to: manifestURL, options: [.atomic])
    }

    public func validate() throws {
        let manifest = try readManifest()
        guard manifest.bundle.formatVersion == MuseeCore.currentFormatVersion else {
            throw MuseeError.invalidFormat("Unsupported format version \(manifest.bundle.formatVersion)")
        }

        let cas = ContentAddressedStore(rootURL: bundleURL, objectsDirectoryName: MuseeBundleSpec.objectsDirectory)
        for asset in manifest.assets where !cas.contains(sha256: asset.sha256) {
            throw MuseeError.notFound("Missing object for asset sha256=\(asset.sha256)")
        }
    }

    public static func createNew(at bundleURL: URL, manifest: MuseeManifest, mediaFilesBySHA256: [String: URL]) throws -> MuseeBundle {
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: bundleURL.appendingPathComponent(MuseeBundleSpec.objectsDirectory, isDirectory: true), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: bundleURL.appendingPathComponent(MuseeBundleSpec.metadataDirectory, isDirectory: true), withIntermediateDirectories: true)

        let bundle = MuseeBundle(bundleURL: bundleURL)
        try bundle.writeManifest(manifest)

        let cas = ContentAddressedStore(rootURL: bundle.bundleURL, objectsDirectoryName: MuseeBundleSpec.objectsDirectory)
        for (sha, fileURL) in mediaFilesBySHA256 {
            let data = try Data(contentsOf: fileURL)
            _ = try cas.store(data: data, sha256: sha)
        }

        try bundle.validate()
        return bundle
    }
}
