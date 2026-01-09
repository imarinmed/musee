import Foundation
import MuseeCore
import MuseeDomain

/// Handles reading and writing XMP sidecar files for metadata interoperability.
public struct XMPSidecar {
    private static let xmpExtension = "xmp"

    /// Read XMP data from a sidecar file.
    public static func read(fromSidecarFor fileURL: URL) throws -> Data? {
        let sidecarURL = sidecarURL(for: fileURL)
        return try? Data(contentsOf: sidecarURL)
    }

    /// Write XMP data to a sidecar file.
    public static func write(_ data: Data, toSidecarFor fileURL: URL) throws {
        let sidecarURL = sidecarURL(for: fileURL)
        try data.write(to: sidecarURL, options: [.atomic])
    }

    /// Get the sidecar URL for a given media file URL.
    public static func sidecarURL(for fileURL: URL) -> URL {
        fileURL.deletingPathExtension().appendingPathExtension(xmpExtension)
    }

    /// Check if a sidecar file exists for the given media file.
    public static func sidecarExists(for fileURL: URL) -> Bool {
        let sidecarURL = sidecarURL(for: fileURL)
        return FileManager.default.fileExists(atPath: sidecarURL.path)
    }
}