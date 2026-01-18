import Foundation
import MuseeCore
import MuseeDomain

/// Temporal data structures for muse evolution tracking
public enum MuseeTemporal {
    
    /// A snapshot of muse data at a specific point in time
    public struct MuseSnapshot: Codable, Sendable {
        public let timestamp: Date
        public let person: Person
        public let assets: [MediaAsset]
        public let claims: [BiographicalClaim]
        public let metadata: [String: String]
        
        public init(timestamp: Date, person: Person, assets: [MediaAsset], claims: [BiographicalClaim], metadata: [String: String]) {
            self.timestamp = timestamp
            self.person = person
            self.assets = assets
            self.claims = claims
            self.metadata = metadata
        }
    }
    
    /// Represents a significant change event in muse evolution
    public struct ChangeEvent: Codable, Sendable {
        public enum ChangeType: String, Codable, Sendable {
            case physicalAppearance = "physical_appearance"
            case lifestyle = "lifestyle"
            case career = "career"
            case health = "health"
            case relationships = "relationships"
            case other = "other"
        }
        
        public let id: String
        public let timestamp: Date
        public let type: ChangeType
        public let description: String
        public let confidence: Double // 0.0 to 1.0
        public let sourceURLs: [URL]
        public let metadata: [String: String]
        
        public init(id: String, timestamp: Date, type: ChangeType, description: String, confidence: Double, sourceURLs: [URL], metadata: [String: String]) {
            self.id = id
            self.timestamp = timestamp
            self.type = type
            self.description = description
            self.confidence = confidence
            self.sourceURLs = sourceURLs
            self.metadata = metadata
        }
    }
    
    /// Evolution timeline for a muse
    public struct EvolutionTimeline: Codable, Sendable {
        public let snapshots: [MuseSnapshot]
        public let changeEvents: [ChangeEvent]
        public let createdAt: Date
        public let lastUpdated: Date
        
        public init(snapshots: [MuseSnapshot], changeEvents: [ChangeEvent], createdAt: Date = Date(), lastUpdated: Date = Date()) {
            self.snapshots = snapshots
            self.changeEvents = changeEvents
            self.createdAt = createdAt
            self.lastUpdated = lastUpdated
        }
        
        /// Add a new snapshot
        public func addingSnapshot(_ snapshot: MuseSnapshot) -> EvolutionTimeline {
            var newSnapshots = snapshots
            newSnapshots.append(snapshot)
            newSnapshots.sort { $0.timestamp < $1.timestamp }
            
            return EvolutionTimeline(
                snapshots: newSnapshots,
                changeEvents: changeEvents,
                createdAt: createdAt,
                lastUpdated: Date()
            )
        }
        
        /// Add a change event
        public func addingChangeEvent(_ event: ChangeEvent) -> EvolutionTimeline {
            var newEvents = changeEvents
            newEvents.append(event)
            newEvents.sort { $0.timestamp < $1.timestamp }
            
            return EvolutionTimeline(
                snapshots: snapshots,
                changeEvents: newEvents,
                createdAt: createdAt,
                lastUpdated: Date()
            )
        }
        
        /// Get snapshots within date range
        public func snapshots(in range: ClosedRange<Date>) -> [MuseSnapshot] {
            snapshots.filter { range.contains($0.timestamp) }
        }
        
        /// Get change events within date range
        public func changeEvents(in range: ClosedRange<Date>) -> [ChangeEvent] {
            changeEvents.filter { range.contains($0.timestamp) }
        }
    }
    
    /// EROSS score evolution over time
    public struct EROSSHistory: Codable, Sendable {
        public struct ScoreEntry: Codable, Sendable {
            public let timestamp: Date
            public let score: Double
            public let components: [String: Double] // e.g., ["facial": 0.85, "body": 0.92]
            public let confidence: Double
            public let source: String
            
            public init(timestamp: Date, score: Double, components: [String: Double], confidence: Double, source: String) {
                self.timestamp = timestamp
                self.score = score
                self.components = components
                self.confidence = confidence
                self.source = source
            }
        }
        
        public let scores: [ScoreEntry]
        
        public init(scores: [ScoreEntry]) {
            self.scores = scores.sorted { $0.timestamp < $1.timestamp }
        }
        
        /// Get latest score
        public var latestScore: ScoreEntry? {
            scores.last
        }
        
        /// Get score trend over time
        public func scoreTrend(from startDate: Date, to endDate: Date) -> [ScoreEntry] {
            scores.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
        }
        
        /// Calculate average score change rate
        public func averageChangeRate(days: Int = 30) -> Double? {
            guard scores.count >= 2 else { return nil }
            
            let calendar = Calendar.current
            var totalChange = 0.0
            var count = 0
            
            for i in 1..<scores.count {
                let previous = scores[i-1]
                let current = scores[i]
                
                if let daysDiff = calendar.dateComponents([.day], from: previous.timestamp, to: current.timestamp).day,
                   daysDiff <= days {
                    totalChange += current.score - previous.score
                    count += 1
                }
            }
            
            return count > 0 ? totalChange / Double(count) : nil
        }
    }
}