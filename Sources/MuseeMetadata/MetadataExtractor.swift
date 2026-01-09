import AVFoundation
import Foundation
import ImageIO
import MuseeCore
import MuseeDomain

/// Protocol for extracting metadata from media files.
public protocol MetadataExtractor {
    /// The media kinds this extractor supports.
    var supportedKinds: Set<MediaKind> { get }

    /// Extract metadata from the given file URL.
    /// - Parameter fileURL: The URL of the media file.
    /// - Returns: Extracted metadata as a dictionary, or nil if extraction fails.
    func extractMetadata(from fileURL: URL) async throws -> [String: Any]?
}

/// Implementation for extracting EXIF/IPTC metadata from images using ImageIO.
public struct ImageMetadataExtractor: MetadataExtractor {
    public let supportedKinds: Set<MediaKind> = [.image]

    public func extractMetadata(from fileURL: URL) async throws -> [String: Any]? {
        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil as CFDictionary?) else {
            return nil
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil as CFDictionary?) as? [String: Any] else {
            return nil
        }

        return properties
    }
}

/// Implementation for extracting metadata from videos using AVFoundation.
public struct VideoMetadataExtractor: MetadataExtractor {
    public let supportedKinds: Set<MediaKind> = [.video]

    public func extractMetadata(from fileURL: URL) async throws -> [String: Any]? {
        let asset = AVAsset(url: fileURL)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)

        var result: [String: Any] = [:]
        result["duration"] = duration.seconds
        result["videoTracks"] = tracks.count

        for item in asset.metadata {
            if let key = item.commonKey?.rawValue {
                result[key] = item.value
            }
        }

        return result
    }
}

/// Implementation for extracting metadata from audio files using AVFoundation.
public struct AudioMetadataExtractor: MetadataExtractor {
    public let supportedKinds: Set<MediaKind> = [.audio]

    public func extractMetadata(from fileURL: URL) async throws -> [String: Any]? {
        let asset = AVAsset(url: fileURL)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .audio)

        var result: [String: Any] = [:]
        result["duration"] = duration.seconds
        result["audioTracks"] = tracks.count

        for item in asset.metadata {
            if let key = item.commonKey?.rawValue {
                result[key] = item.value
            }
        }

        return result
    }
}

/// Composite extractor that tries multiple extractors based on file type.
public struct CompositeMetadataExtractor {
    private let extractors: [MetadataExtractor]

    public init() {
        self.extractors = [
            ImageMetadataExtractor(),
            VideoMetadataExtractor(),
            AudioMetadataExtractor(),
        ]
    }

    public func extractMetadata(from fileURL: URL, kind: MediaKind) async throws -> [String: Any]? {
        for extractor in extractors {
            if extractor.supportedKinds.contains(kind) {
                return try await extractor.extractMetadata(from: fileURL)
            }
        }
        return nil
    }
}