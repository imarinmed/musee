import Foundation
import MuseeBundle

/// Efficient storage manager for temporal muse data
public class TemporalStorageManager {
    
    private let bundle: MuseeBundle
    private let fileManager: FileManager
    
    // Directory structure for temporal data
    private var temporalRootURL: URL {
        bundle.bundleURL.appendingPathComponent("Temporal", isDirectory: true)
    }
    
    private var snapshotsURL: URL {
        temporalRootURL.appendingPathComponent("Snapshots", isDirectory: true)
    }
    
    private var timelineURL: URL {
        temporalRootURL.appendingPathComponent("timeline.json")
    }
    
    private var erossHistoryURL: URL {
        temporalRootURL.appendingPathComponent("eross_history.json")
    }
    
    public init(bundle: MuseeBundle) {
        self.bundle = bundle
        self.fileManager = FileManager.default
    }
    
    /// Initialize temporal storage structure
    public func initializeStorage() throws {
        try fileManager.createDirectory(at: temporalRootURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: snapshotsURL, withIntermediateDirectories: true)
        
        // Initialize empty timeline if it doesn't exist
        if !fileManager.fileExists(atPath: timelineURL.path) {
            let emptyTimeline = MuseeTemporal.EvolutionTimeline(snapshots: [], changeEvents: [])
            try saveTimeline(emptyTimeline)
        }
        
        // Initialize empty EROSS history if it doesn't exist
        if !fileManager.fileExists(atPath: erossHistoryURL.path) {
            let emptyHistory = MuseeTemporal.EROSSHistory(scores: [])
            try saveEROSSHistory(emptyHistory)
        }
    }
    
    /// Store a new snapshot efficiently
    public func storeSnapshot(_ snapshot: MuseeTemporal.MuseSnapshot) throws {
        let snapshotID = snapshotID(for: snapshot.timestamp)
        let snapshotURL = snapshotsURL.appendingPathComponent("\(snapshotID).json")
        
        // Check if snapshot already exists (avoid duplicates)
        if fileManager.fileExists(atPath: snapshotURL.path) {
            return // Snapshot already stored
        }
        
        // Encode and save snapshot
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: [.atomic])
        
        // Update timeline
        var timeline = try loadTimeline()
        timeline = timeline.addingSnapshot(snapshot)
        try saveTimeline(timeline)
        
        // Update bundle manifest
        try updateBundleManifest(with: timeline)
    }
    
    /// Store multiple snapshots efficiently with deduplication
    public func storeSnapshots(_ snapshots: [MuseeTemporal.MuseSnapshot]) throws {
        for snapshot in snapshots {
            try storeSnapshot(snapshot)
        }
    }
    
    /// Store a change event
    public func storeChangeEvent(_ event: MuseeTemporal.ChangeEvent) throws {
        var timeline = try loadTimeline()
        timeline = timeline.addingChangeEvent(event)
        try saveTimeline(timeline)
        
        // Update bundle manifest
        try updateBundleManifest(with: timeline)
    }
    
    /// Store EROSS score entry
    public func storeEROSSScore(_ score: MuseeTemporal.EROSSHistory.ScoreEntry) throws {
        var history = try loadEROSSHistory()
        let updatedScores = history.scores + [score]
        let updatedHistory = MuseeTemporal.EROSSHistory(scores: updatedScores)
        
        try saveEROSSHistory(updatedHistory)
        
        // Update bundle manifest
        try updateBundleManifest(withEROSSHistory: updatedHistory)
    }
    
    /// Load evolution timeline
    public func loadTimeline() throws -> MuseeTemporal.EvolutionTimeline {
        let data = try Data(contentsOf: timelineURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MuseeTemporal.EvolutionTimeline.self, from: data)
    }
    
    /// Load EROSS history
    public func loadEROSSHistory() throws -> MuseeTemporal.EROSSHistory {
        let data = try Data(contentsOf: erossHistoryURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MuseeTemporal.EROSSHistory.self, from: data)
    }
    
    /// Query snapshots within date range
    public func snapshots(in range: ClosedRange<Date>) throws -> [MuseeTemporal.MuseSnapshot] {
        let timeline = try loadTimeline()
        return timeline.snapshots(in: range)
    }
    
    /// Query change events within date range
    public func changeEvents(in range: ClosedRange<Date>) throws -> [MuseeTemporal.ChangeEvent] {
        let timeline = try loadTimeline()
        return timeline.changeEvents(in: range)
    }
    
    /// Get latest snapshot
    public func latestSnapshot() throws -> MuseeTemporal.MuseSnapshot? {
        let timeline = try loadTimeline()
        return timeline.snapshots.max { $0.timestamp < $1.timestamp }
    }
    
    /// Get snapshots between two dates (inclusive)
    public func snapshots(between startDate: Date, and endDate: Date) throws -> [MuseeTemporal.MuseSnapshot] {
        let range = startDate...endDate
        return try snapshots(in: range)
    }
    
    /// Get change events of specific type
    public func changeEvents(ofType type: MuseeTemporal.ChangeEvent.ChangeType) throws -> [MuseeTemporal.ChangeEvent] {
        let timeline = try loadTimeline()
        return timeline.changeEvents.filter { $0.type == type }
    }
    
    /// Compact storage by removing redundant data (future enhancement)
    public func compactStorage() throws {
        // TODO: Implement storage compaction
        // - Remove duplicate snapshots
        // - Merge similar change events
        // - Optimize file storage
    }
    
    /// Get storage statistics
    public func storageStats() throws -> StorageStats {
        let timeline = try loadTimeline()
        let history = try loadEROSSHistory()
        
        let snapshotFiles = try fileManager.contentsOfDirectory(at: snapshotsURL, includingPropertiesForKeys: [.fileSizeKey])
        let totalSnapshotSize = snapshotFiles.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + size
        }
        
        return StorageStats(
            snapshotCount: timeline.snapshots.count,
            changeEventCount: timeline.changeEvents.count,
            erossScoreCount: history.scores.count,
            totalStorageSize: totalSnapshotSize,
            lastUpdated: timeline.lastUpdated
        )
    }
    
    // MARK: - Private Methods
    
    private func snapshotID(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "-")
    }
    
    private func saveTimeline(_ timeline: MuseeTemporal.EvolutionTimeline) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(timeline)
        try data.write(to: timelineURL, options: [.atomic])
    }
    
    private func saveEROSSHistory(_ history: MuseeTemporal.EROSSHistory) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(history)
        try data.write(to: erossHistoryURL, options: [.atomic])
    }
    
    private func updateBundleManifest(with timeline: MuseeTemporal.EvolutionTimeline) throws {
        let manifest = try bundle.readManifest()
        let updatedManifest = MuseeManifest(
            bundle: manifest.bundle,
            person: manifest.person,
            tags: manifest.tags,
            assets: manifest.assets,
            claims: manifest.claims,
            relationships: manifest.relationships,
            evolutionTimeline: timeline,
            erossHistory: manifest.erossHistory
        )
        try bundle.writeManifest(updatedManifest)
    }

    private func updateBundleManifest(withEROSSHistory history: MuseeTemporal.EROSSHistory) throws {
        let manifest = try bundle.readManifest()
        let updatedManifest = MuseeManifest(
            bundle: manifest.bundle,
            person: manifest.person,
            tags: manifest.tags,
            assets: manifest.assets,
            claims: manifest.claims,
            relationships: manifest.relationships,
            evolutionTimeline: manifest.evolutionTimeline,
            erossHistory: history
        )
        try bundle.writeManifest(updatedManifest)
    }
}

/// Storage statistics
public struct StorageStats: Sendable {
    public let snapshotCount: Int
    public let changeEventCount: Int
    public let erossScoreCount: Int
    public let totalStorageSize: Int // bytes
    public let lastUpdated: Date
    
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalStorageSize))
    }
}