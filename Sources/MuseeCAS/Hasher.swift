import CryptoKit
import Foundation
import MuseeCore

public enum Hasher {
    public static func sha256Hex(data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public static func sha256Hex(fileURL: URL) throws -> String {
        let data = try Data(contentsOf: fileURL)
        return sha256Hex(data: data)
    }
}
