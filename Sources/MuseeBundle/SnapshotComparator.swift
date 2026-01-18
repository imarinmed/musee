import Foundation
import MuseeBundle

/// Engine for comparing muse snapshots and generating evolution insights
public class SnapshotComparator {
    
    /// Result of comparing two snapshots
    public struct ComparisonResult: Sendable {
        public let beforeSnapshot: MuseeTemporal.MuseSnapshot
        public let afterSnapshot: MuseeTemporal.MuseSnapshot
        
        public let changes: [DetectedChange]
        public let summary: ComparisonSummary
        public let confidence: Double
        
        public init(before: MuseeTemporal.MuseSnapshot, after: MuseeTemporal.MuseSnapshot, changes: [DetectedChange], summary: ComparisonSummary, confidence: Double) {
            self.beforeSnapshot = before
            self.afterSnapshot = after
            self.changes = changes
            self.summary = summary
            self.confidence = confidence
        }
        
        public var timeDifference: TimeInterval {
            afterSnapshot.timestamp.timeIntervalSince(beforeSnapshot.timestamp)
        }
        
        public var hasSignificantChanges: Bool {
            changes.contains { $0.significance > 0.7 }
        }
    }
    
    /// Detected change between snapshots
    public struct DetectedChange: Sendable {
        public enum ChangeType: Sendable {
            case physical
            case lifestyle
            case content
            case metadata
        }
        
        public let type: ChangeType
        public let field: String
        public let beforeValue: String?
        public let afterValue: String?
        public let significance: Double // 0.0 to 1.0
        public let description: String
        public let evidence: [String]
        
        public init(type: ChangeType, field: String, beforeValue: String?, afterValue: String?, significance: Double, description: String, evidence: [String]) {
            self.type = type
            self.field = field
            self.beforeValue = beforeValue
            self.afterValue = afterValue
            self.significance = significance
            self.description = description
            self.evidence = evidence
        }
    }
    
    /// Summary of changes between snapshots
    public struct ComparisonSummary: Sendable {
        public let totalChanges: Int
        public let significantChanges: Int
        public let physicalChanges: Int
        public let lifestyleChanges: Int
        public let contentChanges: Int
        public let metadataChanges: Int
        public let overallChangeMagnitude: Double // 0.0 to 1.0
        public let changeVelocity: Double // changes per day
        
        public init(
            totalChanges: Int,
            significantChanges: Int,
            physicalChanges: Int,
            lifestyleChanges: Int,
            contentChanges: Int,
            metadataChanges: Int,
            overallChangeMagnitude: Double,
            changeVelocity: Double
        ) {
            self.totalChanges = totalChanges
            self.significantChanges = significantChanges
            self.physicalChanges = physicalChanges
            self.lifestyleChanges = lifestyleChanges
            self.contentChanges = contentChanges
            self.metadataChanges = metadataChanges
            self.overallChangeMagnitude = overallChangeMagnitude
            self.changeVelocity = changeVelocity
        }
        
        public var hasMajorTransformation: Bool {
            overallChangeMagnitude > 0.8 || significantChanges > 3
        }
        
        public var changeRateDescription: String {
            switch changeVelocity {
            case 0..<0.1: return "Minimal change over time"
            case 0.1..<0.5: return "Gradual evolution"
            case 0.5..<1.0: return "Moderate transformation"
            case 1.0..<2.0: return "Rapid change"
            default: return "Dramatic transformation"
            }
        }
    }
    
    private let changeDetector: ChangeDetectionEngine
    
    public init(changeDetector: ChangeDetectionEngine) {
        self.changeDetector = changeDetector
    }

    public convenience init() {
        self.init(changeDetector: ChangeDetectionEngine())
    }
    
    /// Compare two snapshots and generate detailed comparison
    public func compareSnapshots(_ before: MuseeTemporal.MuseSnapshot, _ after: MuseeTemporal.MuseSnapshot) async -> ComparisonResult {
        let detectedChanges = changeDetector.detectChanges(between: before, and: after)
        
        // Convert detected changes to our format
        let changes = detectedChanges.map { change in
            DetectedChange(
                type: mapChangeType(change.type),
                field: change.evidence.first ?? "unknown",
                beforeValue: nil, // Would need more detailed tracking
                afterValue: nil,
                significance: change.confidence,
                description: change.description,
                evidence: change.evidence
            )
        }
        
        // Generate summary
        let summary = generateSummary(changes: changes, timeDiff: after.timestamp.timeIntervalSince(before.timestamp))
        
        let confidence = calculateComparisonConfidence(before: before, after: after, changes: changes)
        
        return ComparisonResult(
            before: before,
            after: after,
            changes: changes,
            summary: summary,
            confidence: confidence
        )
    }
    
    /// Generate evolution timeline comparison report
    public func generateEvolutionReport(for timeline: MuseeTemporal.EvolutionTimeline) async -> EvolutionReport {
        guard timeline.snapshots.count >= 2 else {
            return EvolutionReport.empty
        }
        
        var comparisons: [ComparisonResult] = []
        let snapshots = timeline.snapshots.sorted { $0.timestamp < $1.timestamp }
        
        // Compare consecutive snapshots
        for i in 1..<snapshots.count {
            let comparison = await compareSnapshots(snapshots[i-1], snapshots[i])
            comparisons.append(comparison)
        }
        
        // Generate overall evolution insights
        let totalChanges = comparisons.reduce(0) { $0 + $1.changes.count }
        let significantChanges = comparisons.reduce(0) { $0 + $1.changes.filter { $0.significance > 0.7 }.count }
        let totalTimeSpan = snapshots.last!.timestamp.timeIntervalSince(snapshots.first!.timestamp)
        
        let overallMagnitude = comparisons.isEmpty ? 0.0 : comparisons.map { $0.summary.overallChangeMagnitude }.reduce(0, +) / Double(comparisons.count)
        let averageVelocity = totalTimeSpan > 0 ? Double(totalChanges) / (totalTimeSpan / (24 * 60 * 60)) : 0.0
        
        let keyTransformations = identifyKeyTransformations(comparisons)
        let evolutionPattern = analyzeEvolutionPattern(comparisons)
        
        return EvolutionReport(
            comparisons: comparisons,
            totalChanges: totalChanges,
            significantChanges: significantChanges,
            timeSpan: totalTimeSpan,
            overallMagnitude: overallMagnitude,
            averageChangeVelocity: averageVelocity,
            keyTransformations: keyTransformations,
            evolutionPattern: evolutionPattern
        )
    }
    
    private func mapChangeType(_ changeType: MuseeTemporal.ChangeEvent.ChangeType) -> DetectedChange.ChangeType {
        switch changeType {
        case .physicalAppearance, .health: return .physical
        case .career, .lifestyle: return .lifestyle
        case .other: return .content
        @unknown default: return .metadata
        }
    }
    
    private func generateSummary(changes: [DetectedChange], timeDiff: TimeInterval) -> ComparisonSummary {
        let totalChanges = changes.count
        let significantChanges = changes.filter { $0.significance > 0.7 }.count
        
        let physicalChanges = changes.filter { $0.type == .physical }.count
        let lifestyleChanges = changes.filter { $0.type == .lifestyle }.count
        let contentChanges = changes.filter { $0.type == .content }.count
        let metadataChanges = changes.filter { $0.type == .metadata }.count
        
        // Calculate overall magnitude based on significance and number of changes
        let weightedMagnitude = changes.reduce(0.0) { $0 + $1.significance } / max(1.0, Double(changes.count))
        let overallChangeMagnitude = min(1.0, weightedMagnitude * Double(changes.count) / 10.0)
        
        // Changes per day
        let days = timeDiff / (24 * 60 * 60)
        let changeVelocity = days > 0 ? Double(totalChanges) / days : 0.0
        
        return ComparisonSummary(
            totalChanges: totalChanges,
            significantChanges: significantChanges,
            physicalChanges: physicalChanges,
            lifestyleChanges: lifestyleChanges,
            contentChanges: contentChanges,
            metadataChanges: metadataChanges,
            overallChangeMagnitude: overallChangeMagnitude,
            changeVelocity: changeVelocity
        )
    }
    
    private func calculateComparisonConfidence(before: MuseeTemporal.MuseSnapshot, after: MuseeTemporal.MuseSnapshot, changes: [DetectedChange]) -> Double {
        // Base confidence from data completeness
        var confidence = 0.5
        
        // Higher confidence if both snapshots have comprehensive data
        if !before.claims.isEmpty { confidence += 0.1 }
        if !after.claims.isEmpty { confidence += 0.1 }
        if !before.assets.isEmpty { confidence += 0.1 }
        if !after.assets.isEmpty { confidence += 0.1 }
        
        // Higher confidence for significant changes
        if changes.contains(where: { $0.significance > 0.8 }) { confidence += 0.1 }
        
        // Lower confidence for very short time spans (might be noise)
        let timeDiff = after.timestamp.timeIntervalSince(before.timestamp)
        if timeDiff < 24 * 60 * 60 { confidence -= 0.1 } // Less than 1 day
        
        return max(0.0, min(1.0, confidence))
    }
    
    private func identifyKeyTransformations(_ comparisons: [ComparisonResult]) -> [String] {
        var transformations: [String] = []
        
        // Look for major physical transformations
        let physicalTransformations = comparisons.filter { $0.summary.physicalChanges > 0 && $0.summary.overallChangeMagnitude > 0.6 }
        if !physicalTransformations.isEmpty {
            transformations.append("Major physical transformation detected")
        }
        
        // Look for career/lifestyle changes
        let lifestyleTransformations = comparisons.filter { $0.summary.lifestyleChanges > 0 }
        if !lifestyleTransformations.isEmpty {
            transformations.append("Lifestyle or career changes identified")
        }
        
        // Look for rapid transformations
        let rapidChanges = comparisons.filter { $0.summary.changeVelocity > 1.0 }
        if !rapidChanges.isEmpty {
            transformations.append("Rapid transformation period observed")
        }
        
        return transformations
    }
    
    private func analyzeEvolutionPattern(_ comparisons: [ComparisonResult]) -> String {
        guard !comparisons.isEmpty else { return "Insufficient data for pattern analysis" }
        
        let velocities = comparisons.map { $0.summary.changeVelocity }
        let averageVelocity = velocities.reduce(0, +) / Double(velocities.count)
        
        if averageVelocity < 0.1 {
            return "Stable with minimal changes"
        } else if averageVelocity < 0.5 {
            return "Gradual evolution over time"
        } else if averageVelocity < 1.0 {
            return "Moderate transformation pace"
        } else {
            return "Active transformation period"
        }
    }
}

/// Comprehensive evolution report
public struct EvolutionReport: Sendable {
    public let comparisons: [SnapshotComparator.ComparisonResult]
    public let totalChanges: Int
    public let significantChanges: Int
    public let timeSpan: TimeInterval
    public let overallMagnitude: Double
    public let averageChangeVelocity: Double
    public let keyTransformations: [String]
    public let evolutionPattern: String
    
    public static let empty = EvolutionReport(
        comparisons: [],
        totalChanges: 0,
        significantChanges: 0,
        timeSpan: 0,
        overallMagnitude: 0,
        averageChangeVelocity: 0,
        keyTransformations: [],
        evolutionPattern: "No data available"
    )
    
    public var formattedTimeSpan: String {
        let days = Int(timeSpan / (24 * 60 * 60))
        if days < 30 {
            return "\(days) days"
        } else if days < 365 {
            let months = days / 30
            return "\(months) months"
        } else {
            let years = days / 365
            return "\(years) years"
        }
    }
    
    public var transformationIntensity: String {
        switch overallMagnitude {
        case 0..<0.3: return "Minimal"
        case 0.3..<0.6: return "Moderate"
        case 0.6..<0.8: return "Significant"
        default: return "Major"
        }
    }
}