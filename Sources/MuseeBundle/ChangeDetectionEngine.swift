import Foundation
import MuseeDomain

/// Engine for detecting changes in muse evolution
public class ChangeDetectionEngine {
    
    /// Detected change with confidence score
    public struct DetectedChange: Sendable {
        public let type: MuseeTemporal.ChangeEvent.ChangeType
        public let description: String
        public let confidence: Double
        public let evidence: [String]
        public let timestamp: Date
        
        public init(type: MuseeTemporal.ChangeEvent.ChangeType, description: String, confidence: Double, evidence: [String], timestamp: Date = Date()) {
            self.type = type
            self.description = description
            self.confidence = confidence
            self.evidence = evidence
            self.timestamp = timestamp
        }
    }
    
    /// Analyze two snapshots and detect changes
    public func detectChanges(between oldSnapshot: MuseeTemporal.MuseSnapshot, and newSnapshot: MuseeTemporal.MuseSnapshot) -> [DetectedChange] {
        var changes: [DetectedChange] = []
        
        // Detect physical appearance changes
        changes.append(contentsOf: detectPhysicalChanges(old: oldSnapshot, new: newSnapshot))
        
        // Detect lifestyle changes
        changes.append(contentsOf: detectLifestyleChanges(old: oldSnapshot, new: newSnapshot))
        
        // Detect content changes
        changes.append(contentsOf: detectContentChanges(old: oldSnapshot, new: newSnapshot))
        
        return changes.filter { $0.confidence >= 0.3 } // Filter out low-confidence changes
    }
    
    private func detectPhysicalChanges(old: MuseeTemporal.MuseSnapshot, new: MuseeTemporal.MuseSnapshot) -> [DetectedChange] {
        var changes: [DetectedChange] = []
        
        // Compare biographical claims for physical changes
        let physicalProperties: Set<ClaimProperty> = [.height, .weight, .bust, .waist, .hips, .hairStyle, .hairColor]
        let oldPhysicalClaims = old.claims.filter { physicalProperties.contains($0.property) }
        let newPhysicalClaims = new.claims.filter { physicalProperties.contains($0.property) }
        
        // Simple example: detect if height or weight changed significantly
        let oldHeight = extractMeasurement(from: oldPhysicalClaims, property: .height)
        let newHeight = extractMeasurement(from: newPhysicalClaims, property: .height)

        if let oldH = oldHeight, let newH = newHeight, abs(newH - oldH) > 5.0 { // 5cm difference
            let change = DetectedChange(
                type: .physicalAppearance,
                description: "Height changed from \(oldH)cm to \(newH)cm",
                confidence: 0.9,
                evidence: ["Height measurement in biographical claims"],
                timestamp: new.timestamp
            )
            changes.append(change)
        }
        
        // Detect cosmetic changes from metadata
        if let oldMeta = old.metadata["cosmetic_procedures"], let newMeta = new.metadata["cosmetic_procedures"] {
            if oldMeta != newMeta {
                let change = DetectedChange(
                    type: .physicalAppearance,
                    description: "Cosmetic procedures updated: \(newMeta)",
                    confidence: 0.8,
                    evidence: ["Cosmetic procedures metadata changed"],
                    timestamp: new.timestamp
                )
                changes.append(change)
            }
        }
        
        return changes
    }
    
    private func detectLifestyleChanges(old: MuseeTemporal.MuseSnapshot, new: MuseeTemporal.MuseSnapshot) -> [DetectedChange] {
        var changes: [DetectedChange] = []
        
        // Compare lifestyle-related claims
        let lifestyleProperties: Set<ClaimProperty> = [.relationship]
        let oldLifestyleClaims = old.claims.filter { lifestyleProperties.contains($0.property) }
        let newLifestyleClaims = new.claims.filter { lifestyleProperties.contains($0.property) }
        
        // Detect relationship changes
        let oldRelationships = oldLifestyleClaims.filter { $0.property == .relationship }
        let newRelationships = newLifestyleClaims.filter { $0.property == .relationship }
        
        if oldRelationships.count != newRelationships.count ||
           !oldRelationships.elementsEqual(newRelationships, by: { $0.value == $1.value }) {
            let change = DetectedChange(
                type: .relationships,
                description: "Relationship information updated",
                confidence: 0.7,
                evidence: ["Relationship claims changed between snapshots"],
                timestamp: new.timestamp
            )
            changes.append(change)
        }
        
        return changes
    }
    
    private func detectContentChanges(old: MuseeTemporal.MuseSnapshot, new: MuseeTemporal.MuseSnapshot) -> [DetectedChange] {
        var changes: [DetectedChange] = []
        
        // Compare asset counts
        if old.assets.count != new.assets.count {
            let change = DetectedChange(
                type: .other,
                description: "Content library size changed from \(old.assets.count) to \(new.assets.count) items",
                confidence: 0.6,
                evidence: ["Asset count difference"],
                timestamp: new.timestamp
            )
            changes.append(change)
        }
        
        return changes
    }
    
    private func extractMeasurement(from claims: [BiographicalClaim], property: ClaimProperty) -> Double? {
        for claim in claims {
            if claim.property == property, case let .number(value) = claim.value {
                return value
            }
        }
        return nil
    }
}

/// Automated change event logger
public class ChangeEventLogger {
    private let bundleManager: TemporalBundleManager
    
    public init(bundleManager: TemporalBundleManager) {
        self.bundleManager = bundleManager
    }
    
    /// Analyze recent snapshots and log detected changes
    public func analyzeAndLogChanges() async throws {
        guard let timeline = try bundleManager.evolutionTimeline(),
              timeline.snapshots.count >= 2 else {
            return // Need at least 2 snapshots
        }
        
        let engine = ChangeDetectionEngine()
        let snapshots = timeline.snapshots.sorted { $0.timestamp < $1.timestamp }
        
        // Analyze consecutive snapshot pairs
        for i in 1..<snapshots.count {
            let oldSnapshot = snapshots[i-1]
            let newSnapshot = snapshots[i]
            
            let changes = engine.detectChanges(between: oldSnapshot, and: newSnapshot)
            
            for change in changes {
                let event = MuseeTemporal.ChangeEvent(
                    id: UUID().uuidString,
                    timestamp: change.timestamp,
                    type: change.type,
                    description: change.description,
                    confidence: change.confidence,
                    sourceURLs: [], // Could be populated from scraping sources
                    metadata: ["evidence": change.evidence.joined(separator: "; ")]
                )
                
                try bundleManager.addChangeEvent(event)
            }
        }
    }
}