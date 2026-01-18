import Foundation

/// Trend direction enumeration
public enum TrendDirection: Sendable {
    case improving
    case declining
    case stable
}

/// Comparison significance enumeration
public enum ComparisonSignificance: Sendable {
    case minimal
    case moderate
    case significant
    case major
}

/// Milestone type enumeration
public enum MilestoneType: Sendable {
    case peakScore
    case significantImprovement
    case consistency
}

/// Correlation strength enumeration
public enum CorrelationStrength: Sendable {
    case weak
    case moderate
    case strong
}

/// Trend analysis results
public struct ScoreTrendAnalysis: Sendable {
    public let currentScore: Double
    public let trendDirection: TrendDirection
    public let trendMagnitude: Double
    public let prediction: Double?
    public let confidence: Double
}

/// Period comparison results
public struct ScorePeriodComparison: Sendable {
    public let period1Average: Double
    public let period2Average: Double
    public let difference: Double
    public let percentChange: Double
    public let significance: ComparisonSignificance
    public let period1SampleSize: Int
    public let period2SampleSize: Int
}

/// Score milestones
public struct ScoreMilestone: Sendable {
    public let type: MilestoneType
    public let score: Double
    public let timestamp: Date
    public let description: String
}

/// Score-event correlations
public struct ScoreEventCorrelation: Sendable {
    public let event: MuseeTemporal.ChangeEvent
    public let scoreChange: Double
    public let correlationStrength: CorrelationStrength
    public let sampleSize: Int
}

/// Comprehensive EROSS score evolution report
public struct EROSSScoreEvolutionReport: Sendable {
    public let timeline: MuseeTemporal.EvolutionTimeline
    public let scoreHistory: MuseeTemporal.EROSSHistory
    public let trendAnalysis: ScoreTrendAnalysis
    public let milestones: [ScoreMilestone]
    public let scoreEventCorrelations: [ScoreEventCorrelation]
    public let insights: [String]
    public let generatedAt: Date

    public var summary: String {
        let scoreRange = scoreHistory.scores.map { $0.score }
        let minScore = scoreRange.min() ?? 0.0
        let maxScore = scoreRange.max() ?? 0.0
        let avgScore = scoreRange.reduce(0, +) / Double(scoreRange.count)

        return """
        EROSS Score Evolution Report
        Period: \(timeline.snapshots.first?.timestamp.formatted() ?? "Unknown") - \(timeline.snapshots.last?.timestamp.formatted() ?? "Unknown")
        Score Range: \(String(format: "%.2f", minScore)) - \(String(format: "%.2f", maxScore))
        Average Score: \(String(format: "%.2f", avgScore))
        Current Trend: \(trendAnalysis.trendDirection)
        Key Milestones: \(milestones.count)
        Significant Correlations: \(scoreEventCorrelations.filter { $0.correlationStrength != .weak }.count)
        """
    }
}

/// Manager for versioned EROSS score tracking and temporal analysis
public class EROSSHistoryManager {
    
    private let storageManager: TemporalStorageManager
    
    public init(storageManager: TemporalStorageManager) {
        self.storageManager = storageManager
    }
    
    /// Record a new EROSS score for a snapshot
    public func recordScore(
        score: Double,
        components: [String: Double] = [:],
        for snapshot: MuseeTemporal.MuseSnapshot,
        source: String = "analysis"
    ) async throws {
        let confidence = calculateScoreConfidence(components: components)
        
        let scoreEntry = MuseeTemporal.EROSSHistory.ScoreEntry(
            timestamp: snapshot.timestamp,
            score: score,
            components: components,
            confidence: confidence,
            source: source
        )
        
        try storageManager.storeEROSSScore(scoreEntry)
    }
    
    /// Get EROSS score history for a bundle
    public func getScoreHistory(for bundle: MuseeBundle) throws -> MuseeTemporal.EROSSHistory? {
        let manifest = try bundle.readManifest()
        return manifest.erossHistory
    }
    
    /// Calculate score trends and predictions
    public func analyzeScoreTrends(history: MuseeTemporal.EROSSHistory) -> ScoreTrendAnalysis {
        let scores = history.scores.sorted { $0.timestamp < $1.timestamp }
        
        guard scores.count >= 2 else {
            return ScoreTrendAnalysis(
                currentScore: scores.last?.score ?? 0.0,
                trendDirection: .stable,
                trendMagnitude: 0.0,
                prediction: nil,
                confidence: 0.0
            )
        }
        
        let currentScore = scores.last!.score
        let previousScore = scores.dropLast().last!.score
        
        // Calculate trend
        let trendDirection: TrendDirection
        let trendMagnitude: Double
        
        if currentScore > previousScore + 0.05 { // 5% improvement
            trendDirection = .improving
            trendMagnitude = (currentScore - previousScore) / previousScore
        } else if currentScore < previousScore - 0.05 { // 5% decline
            trendDirection = .declining
            trendMagnitude = (previousScore - currentScore) / previousScore
        } else {
            trendDirection = .stable
            trendMagnitude = abs(currentScore - previousScore) / previousScore
        }
        
        // Simple linear prediction for next score
        let prediction = predictNextScore(scores: scores)
        
        // Calculate confidence based on data consistency
        let confidence = calculateTrendConfidence(scores: scores)
        
        return ScoreTrendAnalysis(
            currentScore: currentScore,
            trendDirection: trendDirection,
            trendMagnitude: trendMagnitude,
            prediction: prediction,
            confidence: confidence
        )
    }
    
    /// Compare EROSS scores between two time periods
    public func compareScorePeriods(
        history: MuseeTemporal.EROSSHistory,
        period1: ClosedRange<Date>,
        period2: ClosedRange<Date>
    ) -> ScorePeriodComparison {
        
        let scores1 = history.scores.filter { period1.contains($0.timestamp) }
        let scores2 = history.scores.filter { period2.contains($0.timestamp) }
        
        let avgScore1 = scores1.isEmpty ? 0.0 : scores1.map { $0.score }.reduce(0, +) / Double(scores1.count)
        let avgScore2 = scores2.isEmpty ? 0.0 : scores2.map { $0.score }.reduce(0, +) / Double(scores2.count)
        
        let difference = avgScore2 - avgScore1
        let percentChange = avgScore1 > 0 ? (difference / avgScore1) * 100.0 : 0.0
        
        let significance: ComparisonSignificance
        if abs(percentChange) < 1.0 {
            significance = .minimal
        } else if abs(percentChange) < 5.0 {
            significance = .moderate
        } else if abs(percentChange) < 10.0 {
            significance = .significant
        } else {
            significance = .major
        }
        
        return ScorePeriodComparison(
            period1Average: avgScore1,
            period2Average: avgScore2,
            difference: difference,
            percentChange: percentChange,
            significance: significance,
            period1SampleSize: scores1.count,
            period2SampleSize: scores2.count
        )
    }
    
    /// Get score milestones and achievements
    public func getScoreMilestones(history: MuseeTemporal.EROSSHistory) -> [ScoreMilestone] {
        let scores = history.scores.sorted { $0.timestamp < $1.timestamp }
        var milestones: [ScoreMilestone] = []
        
        // Peak score milestone
        if let peakScore = scores.max(by: { $0.score < $1.score }) {
            milestones.append(ScoreMilestone(
                type: .peakScore,
                score: peakScore.score,
                timestamp: peakScore.timestamp,
                description: "Peak EROSS score of \(String(format: "%.1f", peakScore.score))"
            ))
        }
        
        // Score improvement milestones
        var previousScore: Double?
        for scoreEntry in scores {
            if let prev = previousScore, scoreEntry.score > prev + 0.1 { // 10% improvement
                milestones.append(ScoreMilestone(
                    type: .significantImprovement,
                    score: scoreEntry.score,
                    timestamp: scoreEntry.timestamp,
                    description: "Significant improvement from \(String(format: "%.1f", prev)) to \(String(format: "%.1f", scoreEntry.score))"
                ))
            }
            previousScore = scoreEntry.score
        }
        
        // Consistency milestone (stable high scores)
        let highScores = scores.filter { $0.score >= 0.8 }
        if highScores.count >= 3 {
            let avgHighScore = highScores.map { $0.score }.reduce(0, +) / Double(highScores.count)
            milestones.append(ScoreMilestone(
                type: .consistency,
                score: avgHighScore,
                timestamp: highScores.last!.timestamp,
                description: "Consistent high scores (\(highScores.count) scores ≥ 0.8)"
            ))
        }
        
        return milestones.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Generate comprehensive score evolution report
    public func generateEvolutionReport(
        timeline: MuseeTemporal.EvolutionTimeline,
        history: MuseeTemporal.EROSSHistory
    ) -> EROSSScoreEvolutionReport {
        
        let trendAnalysis = analyzeScoreTrends(history: history)
        let milestones = getScoreMilestones(history: history)
        
        // Calculate score correlations with timeline events
        let scoreEventCorrelations = analyzeScoreEventCorrelations(timeline: timeline, history: history)
        
        // Generate insights
        let insights = generateEvolutionInsights(
            trend: trendAnalysis,
            milestones: milestones,
            correlations: scoreEventCorrelations
        )
        
        return EROSSScoreEvolutionReport(
            timeline: timeline,
            scoreHistory: history,
            trendAnalysis: trendAnalysis,
            milestones: milestones,
            scoreEventCorrelations: scoreEventCorrelations,
            insights: insights,
            generatedAt: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateScoreConfidence(components: [String: Double]) -> Double {
        // Higher confidence with more component data
        let componentCount = Double(components.count)
        let baseConfidence = min(0.9, 0.5 + (componentCount * 0.1)) // Up to 90% with 4+ components
        
        // Reduce confidence for extreme values (potential errors)
        let hasExtremeValues = components.values.contains { $0 < 0.0 || $0 > 1.0 }
        let finalConfidence = hasExtremeValues ? baseConfidence * 0.8 : baseConfidence
        
        return finalConfidence
    }
    
    private func predictNextScore(scores: [MuseeTemporal.EROSSHistory.ScoreEntry]) -> Double? {
        guard scores.count >= 3 else { return nil }
        
        // Simple linear regression for prediction
        let n = Double(scores.count)
        let sumX = (0..<scores.count).reduce(0.0) { $0 + Double($1) }
        let sumY = scores.reduce(0.0) { $0 + $1.score }
        let sumXY = scores.enumerated().reduce(0.0) { $0 + Double($1.offset) * $1.element.score }
        let sumXX = (0..<scores.count).reduce(0.0) { $0 + Double($1 * $1) }
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // Predict next point
        let nextX = Double(scores.count)
        let prediction = slope * nextX + intercept
        
        // Clamp to valid range
        return max(0.0, min(1.0, prediction))
    }
    
    private func calculateTrendConfidence(scores: [MuseeTemporal.EROSSHistory.ScoreEntry]) -> Double {
        guard scores.count >= 2 else { return 0.0 }
        
        // Calculate coefficient of variation (lower = more consistent = higher confidence)
        let scoreValues = scores.map { $0.score }
        let mean = scoreValues.reduce(0, +) / Double(scoreValues.count)
        let variance = scoreValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(scoreValues.count)
        let stdDev = sqrt(variance)
        
        let coefficientOfVariation = mean > 0 ? stdDev / mean : 1.0
        
        // Convert to confidence (lower variation = higher confidence)
        return max(0.0, min(1.0, 1.0 - coefficientOfVariation))
    }
    
    private func analyzeScoreEventCorrelations(
        timeline: MuseeTemporal.EvolutionTimeline,
        history: MuseeTemporal.EROSSHistory
    ) -> [ScoreEventCorrelation] {
        
        var correlations: [ScoreEventCorrelation] = []
        
        for event in timeline.changeEvents {
            // Find scores within 30 days of the event
            let eventWindow = (event.timestamp.addingTimeInterval(-30*24*60*60))...(event.timestamp.addingTimeInterval(30*24*60*60))
            let nearbyScores = history.scores.filter { eventWindow.contains($0.timestamp) }
            
            if nearbyScores.count >= 2 {
                let beforeScores = nearbyScores.filter { $0.timestamp < event.timestamp }
                let afterScores = nearbyScores.filter { $0.timestamp > event.timestamp }
                
                if !beforeScores.isEmpty && !afterScores.isEmpty {
                    let avgBefore = beforeScores.map { $0.score }.reduce(0, +) / Double(beforeScores.count)
                    let avgAfter = afterScores.map { $0.score }.reduce(0, +) / Double(afterScores.count)
                    
                    let change = avgAfter - avgBefore
                    let correlationStrength: CorrelationStrength
                    
                    if abs(change) > 0.1 {
                        correlationStrength = .strong
                    } else if abs(change) > 0.05 {
                        correlationStrength = .moderate
                    } else {
                        correlationStrength = .weak
                    }
                    
                    correlations.append(ScoreEventCorrelation(
                        event: event,
                        scoreChange: change,
                        correlationStrength: correlationStrength,
                        sampleSize: nearbyScores.count
                    ))
                }
            }
        }
        
        return correlations
    }
    
    private func generateEvolutionInsights(
        trend: ScoreTrendAnalysis,
        milestones: [ScoreMilestone],
        correlations: [ScoreEventCorrelation]
    ) -> [String] {
        
        var insights: [String] = []
        
        // Trend insights
        switch trend.trendDirection {
        case .improving:
            insights.append("EROSS scores are trending upward with \(String(format: "%.1f%%", trend.trendMagnitude * 100)) average improvement")
        case .declining:
            insights.append("EROSS scores are trending downward with \(String(format: "%.1f%%", trend.trendMagnitude * 100)) average decline")
        case .stable:
            insights.append("EROSS scores have remained stable with minimal variation")
        }
        
        // Milestone insights
        if let peakMilestone = milestones.first(where: { $0.type == .peakScore }) {
            insights.append("Peak EROSS score of \(String(format: "%.1f", peakMilestone.score)) achieved")
        }
        
        if milestones.contains(where: { $0.type == .consistency }) {
            insights.append("Demonstrates consistent high beauty standards over time")
        }
        
        // Correlation insights
        let strongCorrelations = correlations.filter { $0.correlationStrength == .strong }
        if !strongCorrelations.isEmpty {
            insights.append("\(strongCorrelations.count) significant changes correlate with EROSS score fluctuations")
        }
        
        return insights
    }
}


