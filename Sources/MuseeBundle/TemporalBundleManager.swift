import Foundation

/// Temporal bundle management utilities
public class TemporalBundleManager {
    private let bundle: MuseeBundle
    
    public init(bundle: MuseeBundle) {
        self.bundle = bundle
    }
    
    /// Add a new evolution snapshot
    public func addSnapshot(_ snapshot: MuseeTemporal.MuseSnapshot) throws {
        let manifest = try bundle.readManifest()
        
        let timeline = manifest.evolutionTimeline ?? MuseeTemporal.EvolutionTimeline(snapshots: [], changeEvents: [])
        let updatedTimeline = timeline.addingSnapshot(snapshot)
        
        let updatedManifest = MuseeManifest(
            bundle: manifest.bundle,
            person: manifest.person,
            tags: manifest.tags,
            assets: manifest.assets,
            claims: manifest.claims,
            relationships: manifest.relationships,
            evolutionTimeline: updatedTimeline,
            erossHistory: manifest.erossHistory
        )
        
        try bundle.writeManifest(updatedManifest)
    }
    
    /// Add a change event
    public func addChangeEvent(_ event: MuseeTemporal.ChangeEvent) throws {
        let manifest = try bundle.readManifest()
        
        let timeline = manifest.evolutionTimeline ?? MuseeTemporal.EvolutionTimeline(snapshots: [], changeEvents: [])
        let updatedTimeline = timeline.addingChangeEvent(event)
        
        let updatedManifest = MuseeManifest(
            bundle: manifest.bundle,
            person: manifest.person,
            tags: manifest.tags,
            assets: manifest.assets,
            claims: manifest.claims,
            relationships: manifest.relationships,
            evolutionTimeline: updatedTimeline,
            erossHistory: manifest.erossHistory
        )
        
        try bundle.writeManifest(updatedManifest)
    }
    
    /// Add EROSS score entry
    public func addEROSSScore(_ score: MuseeTemporal.EROSSHistory.ScoreEntry) throws {
        let manifest = try bundle.readManifest()
        
        let history = manifest.erossHistory ?? MuseeTemporal.EROSSHistory(scores: [])
        let updatedScores = history.scores + [score]
        let updatedHistory = MuseeTemporal.EROSSHistory(scores: updatedScores)
        
        let updatedManifest = MuseeManifest(
            bundle: manifest.bundle,
            person: manifest.person,
            tags: manifest.tags,
            assets: manifest.assets,
            claims: manifest.claims,
            relationships: manifest.relationships,
            evolutionTimeline: manifest.evolutionTimeline,
            erossHistory: updatedHistory
        )
        
        try bundle.writeManifest(updatedManifest)
    }
    
    /// Get evolution timeline
    public func evolutionTimeline() throws -> MuseeTemporal.EvolutionTimeline? {
        let manifest = try bundle.readManifest()
        return manifest.evolutionTimeline
    }
    
    /// Get EROSS history
    public func erossHistory() throws -> MuseeTemporal.EROSSHistory? {
        let manifest = try bundle.readManifest()
        return manifest.erossHistory
    }
    
    /// Query snapshots within date range
    public func snapshots(in range: ClosedRange<Date>) throws -> [MuseeTemporal.MuseSnapshot] {
        guard let timeline = try evolutionTimeline() else { return [] }
        return timeline.snapshots(in: range)
    }
    
    /// Query change events within date range
    public func changeEvents(in range: ClosedRange<Date>) throws -> [MuseeTemporal.ChangeEvent] {
        guard let timeline = try evolutionTimeline() else { return [] }
        return timeline.changeEvents(in: range)
    }
}