import Foundation
import MuseeCore
import MuseeDomain

public struct CASReference: Hashable, Codable, Sendable {
    public let sha256: String
    public let relativePath: String
    public let sizeBytes: Int

    public init(sha256: String, relativePath: String, sizeBytes: Int) {
        self.sha256 = sha256
        self.relativePath = relativePath
        self.sizeBytes = sizeBytes
    }
}

public struct ContentAddressedStore {
    public let rootURL: URL
    public let objectsDirectoryName: String

    public init(rootURL: URL, objectsDirectoryName: String = "Objects") {
        self.rootURL = rootURL
        self.objectsDirectoryName = objectsDirectoryName
    }

    public func objectURL(forSHA256 sha256: String) throws -> URL {
        guard sha256.count >= 4 else {
            throw MuseeError.invalidArgument("sha256 too short")
        }
        let prefix = String(sha256.prefix(2))
        let subprefix = String(sha256.dropFirst(2).prefix(2))
        return rootURL
            .appendingPathComponent(objectsDirectoryName, isDirectory: true)
            .appendingPathComponent(prefix, isDirectory: true)
            .appendingPathComponent(subprefix, isDirectory: true)
            .appendingPathComponent(sha256, isDirectory: false)
    }

    public func contains(sha256: String) -> Bool {
        guard let url = try? objectURL(forSHA256: sha256) else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }

    @discardableResult
    public func store(data: Data, sha256: String) throws -> CASReference {
        let url = try objectURL(forSHA256: sha256)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        if !FileManager.default.fileExists(atPath: url.path) {
            try data.write(to: url, options: [.atomic])
        }

        let rel = url.path.replacingOccurrences(of: rootURL.path + "/", with: "")
        return CASReference(sha256: sha256, relativePath: rel, sizeBytes: data.count)
    }

    @discardableResult
    public func ingestFile(at fileURL: URL) throws -> CASReference {
        let data = try Data(contentsOf: fileURL)
        let sha = Hasher.sha256Hex(data: data)
        return try store(data: data, sha256: sha)
    }

    public func load(sha256: String) throws -> Data {
        let url = try objectURL(forSHA256: sha256)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw MuseeError.notFound("object \(sha256)")
        }
        return try Data(contentsOf: url)
    }
}
