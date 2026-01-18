import Foundation

/// AI-powered transformation detection engine
public class TransformationDetector {
    
    /// Types of transformations that can be detected
    public enum TransformationType: String, Sendable {
        case surgical = "surgical"
        case cosmetic = "cosmetic"
        case fitness = "fitness"
        case aging = "aging"
        case weightChange = "weight_change"
        case hairChange = "hair_change"
        case makeupChange = "makeup_change"
        case lightingChange = "lighting_change"
        case unknown = "unknown"
    }
    
    /// Detected transformation with evidence
    public struct DetectedTransformation: Sendable {
        public let type: TransformationType
        public let confidence: Double  // 0.0 to 1.0
        public let description: String
        public let evidence: [String]
        public let timeRange: (start: Date, end: Date)
        public let beforeSnapshot: MuseeTemporal.MuseSnapshot?
        public let afterSnapshot: MuseeTemporal.MuseSnapshot?
        
        public init(type: TransformationType, confidence: Double, description: String, evidence: [String], timeRange: ClosedRange<Date], beforeSnapshot: MuseeTemporal.MuseSnapshot?, afterSnapshot: MuseeTemporal.MuseSnapshot?) {
            self.type = type
            self.confidence = confidence
            self.description = description
            self.evidence = evidence
            self.timeRange = timeRange
            self.beforeSnapshot = beforeSnapshot
            self.afterSnapshot = afterSnapshot
        }
    }
    
    private let changeDetector: ChangeDetectionEngine
    
    public init(changeDetector: ChangeDetectionEngine) {
        self.changeDetector = changeDetector
    }

    public convenience init() {
        self.init(changeDetector: ChangeDetectionEngine())
    }
    
    /// Analyze timeline for transformations
    public func detectTransformations(in timeline: MuseeTemporal.EvolutionTimeline) async -> [DetectedTransformation] {
        var transformations: [DetectedTransformation] = []
        
        // Analyze consecutive snapshots for changes
        let snapshots = timeline.snapshots.sorted { $0.timestamp < $1.timestamp }
        
        for i in 1..<snapshots.count {
            let before = snapshots[i-1]
            let after = snapshots[i]
            
            if let transformation = await analyzeTransformation(from: before, to: after) {
                transformations.append(transformation)
            }
        }
        
        // Look for multi-snapshot patterns (gradual changes)
        transformations.append(contentsOf: await detectGradualChanges(in: snapshots))
        
        return transformations.sorted { $0.timeRange.0 < $1.timeRange.0 }
    }
    
    private func analyzeTransformation(from before: MuseeTemporal.MuseSnapshot, to after: MuseeTemporal.MuseSnapshot) async -> DetectedTransformation? {
        // Use change detector to identify changes
        let changes = changeDetector.detectChanges(between: before, and: after)
        
        // Filter for significant physical changes
        let significantChanges = changes.filter { $0.confidence > 0.7 && isPhysicalChange($0.type) }
        
        guard !significantChanges.isEmpty else { return nil }
        
        // Determine transformation type based on change patterns
            let transformationType = classifyTransformation(significantChanges)
            let confidence = significantChanges.map { $0.confidence }.reduce(0, +) / Double(significantChanges.count)
            let evidence = significantChanges.flatMap { $0.evidence }

            let description = generateTransformationDescription(transformationType, changes: significantChanges)
        
        return DetectedTransformation(
            type: transformationType,
            confidence: confidence,
            description: description,
            evidence: evidence,
            timeRange: before.timestamp...after.timestamp,
            beforeSnapshot: before,
            afterSnapshot: after
        )
    }
    
    private func detectGradualChanges(in snapshots: [MuseeTemporal.MuseSnapshot]) async -> [DetectedTransformation] {
        var transformations: [DetectedTransformation] = []
        
        // Look for fitness transformations (gradual muscle gain/loss)
        if let fitnessChange = await detectFitnessTransformation(snapshots) {
            transformations.append(fitnessChange)
        }
        
        // Look for aging changes (gradual over long periods)
        if let agingChange = await detectAgingTransformation(snapshots) {
            transformations.append(agingChange)
        }
        
        // Look for gradual cosmetic changes
        if let cosmeticChange = await detectGradualCosmeticChanges(snapshots) {
            transformations.append(cosmeticChange)
        }
        
        return transformations
    }
    
    private func isPhysicalChange(_ changeType: MuseeTemporal.ChangeEvent.ChangeType) -> Bool {
        switch changeType {
        case .physicalAppearance, .health:
            return true
        default:
            return false
        }
    }
    
    private func classifyTransformation(_ changes: [ChangeDetectionEngine.DetectedChange]) -> TransformationType {
        // Analyze change patterns to classify transformation type
        
        let hasHeightChange = changes.contains { $0.evidence.contains(where: { $0.contains("height") }) }
        let hasWeightChange = changes.contains { $0.evidence.contains(where: { $0.contains("muscle") || $0.contains("body") }) }
        let hasFacialChange = changes.contains { $0.evidence.contains(where: { $0.contains("facial") || $0.contains("nose") || $0.contains("mouth") }) }
        let hasCosmeticChange = changes.contains { $0.evidence.contains(where: { $0.contains("cosmetic") }) }
        
        // Surgical changes are typically abrupt and significant
        if hasFacialChange && changes.first?.confidence ?? 0 > 0.9 {
            return .surgical
        }

        // Cosmetic changes are less invasive
        if hasCosmeticChange {
            return .cosmetic
        }

        // Significant body changes over short time might be fitness-related
        if hasWeightChange || hasHeightChange {
            return .fitness
        }
        
        return .unknown
    }
    
    private func generateTransformationDescription(_ type: TransformationType, changes: [ChangeDetectionEngine.DetectedChange]) -> String {
        let changeDescriptions = changes.map { $0.description }.joined(separator: ", ")
        
        switch type {
        case .surgical:
            return "Surgical transformation detected: \(changeDescriptions)"
        case .cosmetic:
            return "Cosmetic enhancement: \(changeDescriptions)"
        case .fitness:
            return "Fitness transformation: \(changeDescriptions)"
        case .aging:
            return "Natural aging changes: \(changeDescriptions)"
        case .weightChange:
            return "Weight change: \(changeDescriptions)"
        case .hairChange:
            return "Hair styling changes: \(changeDescriptions)"
        case .makeupChange:
            return "Makeup technique changes: \(changeDescriptions)"
        case .lightingChange:
            return "Lighting/studio changes: \(changeDescriptions)"
        case .unknown:
            return "Unclassified transformation: \(changeDescriptions)"
        }
    }
    
    private func detectFitnessTransformation(_ snapshots: [MuseeTemporal.MuseSnapshot]) async -> DetectedTransformation? {
        guard snapshots.count >= 3 else { return nil }
        
        // Look for gradual increase in muscle definition over time
        var muscleScores: [(Date, Double)] = []

        for snapshot in snapshots {
            if let muscleScoreStr = snapshot.metadata["muscle_definition"], let muscleScore = Double(muscleScoreStr) {
                muscleScores.append((snapshot.timestamp, muscleScore))
            }
        }
        
        guard muscleScores.count >= 3 else { return nil }
        
        // Check for consistent upward trend
        let sortedScores = muscleScores.sorted { $0.0 < $1.0 }
        let firstScore = sortedScores.first!.1
        let lastScore = sortedScores.last!.1
        
        if lastScore > firstScore + 0.2 { // At least 20% improvement
            let timeRange = sortedScores.first!.0...sortedScores.last!.0
            
            return DetectedTransformation(
                type: TransformationType.fitness,
                confidence: 0.75,
                description: "Gradual fitness improvement detected over \(sortedScores.count) snapshots",
                evidence: ["Muscle definition increased from \(firstScore) to \(lastScore)"],
                timeRange: timeRange,
                beforeSnapshot: snapshots.first,
                afterSnapshot: snapshots.last
            )
        }
        
        return nil
    }
    
    private func detectAgingTransformation(_ snapshots: [MuseeTemporal.MuseSnapshot]) async -> DetectedTransformation? {
        guard snapshots.count >= 2 else { return nil }
        
        let timeSpan = snapshots.last!.timestamp.timeIntervalSince(snapshots.first!.timestamp)
        let years = timeSpan / (365 * 24 * 60 * 60)
        
        // Only consider aging if span is at least 1 year
        guard years >= 1 else { return nil }
        
        // Look for subtle skin changes that indicate aging
        let skinChanges = snapshots.compactMap { snapshot -> (Date, Double)? in
            if let skinQualityStr = snapshot.metadata["skin_quality"], let skinQuality = Double(skinQualityStr) {
                return (snapshot.timestamp, skinQuality)
            }
            return nil
        }
        
        if skinChanges.count >= 2 {
            let firstQuality = skinChanges.first!.1
            let lastQuality = skinChanges.last!.1
            
            if lastQuality < firstQuality - 0.1 { // Significant skin quality decline
                let timeRange = snapshots.first!.timestamp...snapshots.last!.timestamp
                
                return DetectedTransformation(
                    type: TransformationType.aging,
                    confidence: 0.65,
                    description: "Natural aging detected over \(String(format: "%.1f", years)) years",
                    evidence: ["Skin quality decreased from \(firstQuality) to \(lastQuality)"],
                    timeRange: timeRange,
                    beforeSnapshot: snapshots.first,
                    afterSnapshot: snapshots.last
                )
            }
        }
        
        return nil
    }
    
    private func detectGradualCosmeticChanges(_ snapshots: [MuseeTemporal.MuseSnapshot]) async -> DetectedTransformation? {
        // Look for gradual changes in makeup or cosmetic procedures
        var cosmeticChanges: [(Date, String)] = []

        for snapshot in snapshots {
            if let cosmetic = snapshot.metadata["cosmetic_procedures"] {
                cosmeticChanges.append((snapshot.timestamp, cosmetic))
            }
        }
        
        if cosmeticChanges.count >= 2 {
            let uniqueProcedures = Set(cosmeticChanges.map { $0.1 })
            
            if uniqueProcedures.count > 1 { // Different procedures over time
                let timeRange = cosmeticChanges.first!.0...cosmeticChanges.last!.0
                
                return DetectedTransformation(
                    type: TransformationType.cosmetic,
                    confidence: 0.70,
                    description: "Gradual cosmetic changes detected over time",
                    evidence: ["Procedures changed: \(uniqueProcedures.joined(separator: " → "))"],
                    timeRange: timeRange,
                    beforeSnapshot: snapshots.first,
                    afterSnapshot: snapshots.last
                )
            }
        }
        
        return nil
    }
}