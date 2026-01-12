import Foundation
import MuseeCore
import MuseeDomain
import MuseeMuseum

/// Service for loading and managing museum data.
public class DataLoadingService {
    private let museumLibrary: MuseumLibrary?

    public init(museumLibrary: MuseumLibrary? = nil) {
        self.museumLibrary = museumLibrary
    }

    /// Loads demo museum data for development and testing.
    /// - Returns: Array of demo museum wings
    public func loadDemoWings() -> [MuseumIndex.Wing] {
        [
            MuseumIndex.Wing(id: StableID("fitness"), name: "Fitness Journey", description: "Evolution from amateur to professional athlete"),
            MuseumIndex.Wing(id: StableID("singers"), name: "Singers", description: "Music artists and performers"),
            MuseumIndex.Wing(id: StableID("actors"), name: "Actors", description: "Film and theater performers")
        ]
    }

    /// Loads demo assets for development and testing.
    /// - Returns: Array of demo media assets
    public func loadDemoAssets() -> [MediaAsset] {
        [
            MediaAsset(id: StableID("asset1"), sha256: "demo1", kind: .image, originalFilename: "photo1.jpg"),
            MediaAsset(id: StableID("asset2"), sha256: "demo2", kind: .image, originalFilename: "photo2.jpg"),
            MediaAsset(id: StableID("asset3"), sha256: "demo3", kind: .video, originalFilename: "video1.mp4")
        ]
    }
}
