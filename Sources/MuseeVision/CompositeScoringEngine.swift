import Foundation
import MuseeCore
import MuseeDomain
import MuseeVision
import MuseeScraper
import MuseeBundle

/// Advanced trend analysis result
public struct TrendAnalysisResult: Sendable {
    public let direction: TrendDirection
    public let slope: Double  // Rate of change per time period
    public let volatility: Double  // Standard deviation of scores
    public let consistencyScore: Double  // 0.0 to 1.0, higher = more consistent
    public let movingAverage: [Double]  // Smoothed trend line
    public let predictions: [Prediction]  // Future score predictions
    public let anomalies: [Anomaly]  // Detected unusual score changes
    public let confidence: Double  // Overall confidence in analysis

    public enum TrendDirection: Sendable {
        case improving
        case declining
        case stable
    }
}

/// Prediction for future EROSS score
public struct Prediction: Sendable {
    public let timestamp: Date
    public let value: Double  // Predicted score (0.0 to 1.0)
    public let confidence: Double  // Prediction confidence (0.0 to 1.0)
}

/// Detected anomaly in score history
public struct Anomaly: Sendable {
    public let timestamp: Date
    public let value: Double  // Actual score value
    public let expectedValue: Double  // Expected score based on trend
    public let deviation: Double  // Magnitude of deviation
    public let type: AnomalyType

    public enum AnomalyType: Sendable {
        case peak  // Score significantly higher than expected
        case valley  // Score significantly lower than expected
    }
}

/// Comprehensive EROSS composite scoring engine
public class CompositeScoringEngine {
    
    /// Scoring components that contribute to final EROSS score
    public enum ScoringComponent: String, CaseIterable, Sendable {
        case facialBeauty = "facial_beauty"
        case bodyProportion = "body_proportion"
        case skinQuality = "skin_quality"
        case symmetry = "symmetry"
        case contentQuality = "content_quality"
        case socialEngagement = "social_engagement"
        case consistency = "consistency"
        case uniqueness = "uniqueness"
    }
    
    /// Configuration for scoring weights
    public struct ScoringWeights: Sendable {
        public let facialBeauty: Double      // 0.25
        public let bodyProportion: Double    // 0.20
        public let skinQuality: Double       // 0.15
        public let symmetry: Double          // 0.15
        public let contentQuality: Double    // 0.10
        public let socialEngagement: Double  // 0.08
        public let consistency: Double       // 0.05
        public let uniqueness: Double        // 0.02
        
        public static let standard = ScoringWeights(
            facialBeauty: 0.25,
            bodyProportion: 0.20,
            skinQuality: 0.15,
            symmetry: 0.15,
            contentQuality: 0.10,
            socialEngagement: 0.08,
            consistency: 0.05,
            uniqueness: 0.02
        )
        
        public var total: Double {
            facialBeauty + bodyProportion + skinQuality + symmetry +
            contentQuality + socialEngagement + consistency + uniqueness
        }
        
        public func validate() throws {
            guard abs(total - 1.0) < 0.001 else {
                throw MuseeError.invalidArgument("Scoring weights must sum to 1.0, got \(total)")
            }
        }
    }
    
    /// Composite score result with component breakdown
    public struct CompositeScore: Sendable {
        public let overallScore: Double
        public let components: [ScoringComponent: ComponentScore]
        public let confidence: Double
        public let calculatedAt: Date
        
        public struct ComponentScore: Sendable {
            public let score: Double  // 0.0 to 1.0
            public let weight: Double
            public let confidence: Double
            
            public var weightedScore: Double {
                score * weight
            }
        }
        
        public init(overallScore: Double, components: [ScoringComponent: ComponentScore], confidence: Double, calculatedAt: Date = Date()) {
            self.overallScore = overallScore
            self.components = components
            self.confidence = confidence
            self.calculatedAt = calculatedAt
        }
    }
    
    private let weights: ScoringWeights
    private let visionCalculator: EROSCalculator.Type
    
    public init(weights: ScoringWeights = .standard, visionCalculator: EROSCalculator.Type = EROSCalculator.self) {
        self.weights = weights
        self.visionCalculator = visionCalculator
    }
    
    /// Calculate comprehensive EROSS score from all available data
    public func calculateCompositeScore(
        beautyFeatures: BeautyFeatures?,
        socialData: MuseeScraper.SocialMediaData?,
        contentQuality: ContentQualityMetrics?,
        historicalScores: [MuseeTemporal.EROSSHistory.ScoreEntry] = []
    ) async throws -> CompositeScore {
        
        try weights.validate()
        
        var components: [ScoringComponent: CompositeScore.ComponentScore] = [:]
        var totalWeightedScore = 0.0
        var totalConfidence = 0.0
        var componentCount = 0
        
        // Facial beauty from Vision analysis
        if let beauty = beautyFeatures {
            let visionScore = visionCalculator.calculateEROSS(from: beauty) / 100.0 // Normalize to 0-1
            let confidence = calculateVisionConfidence(beauty)
            
            components[.facialBeauty] = .init(
                score: visionScore,
                weight: weights.facialBeauty,
                confidence: confidence
            )
            
            totalWeightedScore += visionScore * weights.facialBeauty
            totalConfidence += confidence
            componentCount += 1
        }
        
        // Body proportion analysis
        if let bodyRatios = beautyFeatures?.bodyRatios {
            let bodyScore = bodyRatios.overallScore
            let confidence = 0.85 // Body analysis is reliable
            
            components[.bodyProportion] = .init(
                score: bodyScore,
                weight: weights.bodyProportion,
                confidence: confidence
            )
            
            totalWeightedScore += bodyScore * weights.bodyProportion
            totalConfidence += confidence
            componentCount += 1
        }
        
        // Skin quality
        if let skinAnalysis = beautyFeatures?.skinAnalysis {
            let skinScore = (skinAnalysis.overallQuality + skinAnalysis.radiance + skinAnalysis.tone) / 3.0
            let confidence = 0.80 // Skin analysis is moderately reliable
            
            components[.skinQuality] = .init(
                score: skinScore,
                weight: weights.skinQuality,
                confidence: confidence
            )
            
            totalWeightedScore += skinScore * weights.skinQuality
            totalConfidence += confidence
            componentCount += 1
        }
        
        // Symmetry
        if let symmetry = beautyFeatures?.symmetry {
            let symmetryScore = (symmetry.facialSymmetry + symmetry.bodySymmetry) / 2.0
            let confidence = 0.90 // Symmetry analysis is highly reliable
            
            components[.symmetry] = .init(
                score: symmetryScore,
                weight: weights.symmetry,
                confidence: confidence
            )
            
            totalWeightedScore += symmetryScore * weights.symmetry
            totalConfidence += confidence
            componentCount += 1
        }
        
        // Content quality assessment
        if let content = contentQuality {
            let qualityScore = calculateContentQualityScore(content)
            let confidence = 0.75 // Content analysis is subjective
            
            components[.contentQuality] = .init(
                score: qualityScore,
                weight: weights.contentQuality,
                confidence: confidence
            )
            
            totalWeightedScore += qualityScore * weights.contentQuality
            totalConfidence += confidence
            componentCount += 1
        }
        
        // Social engagement metrics
        if let social = socialData {
            let engagementScore = calculateSocialEngagementScore(social)
            let confidence = 0.70 // Social metrics can be manipulated
            
            components[.socialEngagement] = .init(
                score: engagementScore,
                weight: weights.socialEngagement,
                confidence: confidence
            )
            
            totalWeightedScore += engagementScore * weights.socialEngagement
            totalConfidence += confidence
            componentCount += 1
        }
        
        // Consistency across time
        if !historicalScores.isEmpty {
            let consistencyScore = calculateConsistencyScore(historicalScores)
            let confidence = 0.65 // Historical analysis has some uncertainty
            
            components[.consistency] = .init(
                score: consistencyScore,
                weight: weights.consistency,
                confidence: confidence
            )
            
            totalWeightedScore += consistencyScore * weights.consistency
            totalConfidence += confidence
            componentCount += 1
        }
        
        // Uniqueness factor (inverse of similarity to others)
        let uniquenessScore = calculateUniquenessScore(beautyFeatures, socialData)
        let confidence = 0.60 // Uniqueness is hard to quantify
        
        components[.uniqueness] = .init(
            score: uniquenessScore,
            weight: weights.uniqueness,
            confidence: confidence
        )
        
        totalWeightedScore += uniquenessScore * weights.uniqueness
        totalConfidence += confidence
        componentCount += 1
        
        // Calculate overall confidence as average of component confidences
        let overallConfidence = componentCount > 0 ? totalConfidence / Double(componentCount) : 0.0
        
        return CompositeScore(
            overallScore: totalWeightedScore,
            components: components,
            confidence: overallConfidence
        )
    }
    
    private func calculateVisionConfidence(_ beauty: BeautyFeatures) -> Double {
        // Higher confidence for complete feature detection
        var confidence = 0.5 // Base confidence

        if beauty.facialRatios.eyeToNoseRatio > 0 { confidence += 0.1 }
        if beauty.eyeAnalysis.symmetry > 0 { confidence += 0.1 }
        if beauty.noseAnalysis.bridgeWidth > 0 { confidence += 0.1 }
        if beauty.mouthAnalysis.appeal > 0 { confidence += 0.1 }
        if beauty.bodyRatios.overallScore > 0 { confidence += 0.1 }

        return min(0.95, confidence) // Cap at 95%
    }
    
    private func calculateContentQualityScore(_ content: ContentQualityMetrics) -> Double {
        // Composite content quality score
        let resolution = min(1.0, Double(content.resolution) / 4000.0) // 4K baseline
        let composition = content.compositionScore
        let lighting = content.lightingScore
        let focus = content.focusScore
        
        return (resolution * 0.3 + composition * 0.3 + lighting * 0.2 + focus * 0.2)
    }
    
    private func calculateSocialEngagementScore(_ social: MuseeScraper.SocialMediaData) -> Double {
        // Normalize engagement metrics
        let followerScore = min(1.0, Double(social.followerCount ?? 0) / 1000000.0) // 1M follower baseline
        let postCount = Double(social.posts.count)
        let postScore = min(1.0, postCount / 100.0) // 100 posts baseline
        
        return (followerScore * 0.6 + postScore * 0.4)
    }
    




    private func calculateLinearRegression(_ scores: [MuseeTemporal.EROSSHistory.ScoreEntry]) -> (slope: Double, intercept: Double) {
        let n = Double(scores.count)
        let xValues = (0..<scores.count).map { Double($0) }
        let yValues = scores.map { $0.score }

        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map(*).reduce(0, +)
        let sumXX = xValues.map { $0 * $0 }.reduce(0, +)

        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n

        return (slope, intercept)
    }

    private func calculateMovingAverage(_ values: [Double], window: Int) -> [Double] {
        guard window > 0 && values.count >= window else { return [] }

        var averages: [Double] = []
        for i in 0...(values.count - window) {
            let slice = values[i..<(i + window)]
            let average = slice.reduce(0, +) / Double(window)
            averages.append(average)
        }
        return averages
    }

    private func detectAnomalies(_ scores: [MuseeTemporal.EROSSHistory.ScoreEntry], mean: Double, stdDev: Double) -> [Anomaly] {
        let threshold = 2.0 * stdDev // 2 standard deviations
        var anomalies: [Anomaly] = []

        for score in scores {
            let deviation = abs(score.score - mean)
            if deviation > threshold {
                let type: Anomaly.AnomalyType = score.score > mean ? .peak : .valley
                anomalies.append(Anomaly(
                    timestamp: score.timestamp,
                    value: score.score,
                    expectedValue: mean,
                    deviation: deviation,
                    type: type
                ))
            }
        }

        return anomalies
    }

    private func generatePredictions(_ scores: [MuseeTemporal.EROSSHistory.ScoreEntry], slope: Double, intercept: Double) -> [Prediction] {
        guard scores.count >= 3 else { return [] }

        var predictions: [Prediction] = []
        let lastTimestamp = scores.last!.timestamp

        // Generate predictions for next 3 time periods
        for periodsAhead in 1...3 {
            let x = Double(scores.count + periodsAhead - 1)
            let predictedValue = slope * x + intercept
            let clampedValue = max(0.0, min(1.0, predictedValue)) // Clamp to valid range

            // Estimate confidence decreasing with distance
            let confidence = max(0.1, 1.0 - Double(periodsAhead) * 0.2)

            let predictionDate = lastTimestamp.addingTimeInterval(Double(periodsAhead) * 30 * 24 * 60 * 60) // ~30 days per period

            predictions.append(Prediction(
                timestamp: predictionDate,
                value: clampedValue,
                confidence: confidence
            ))
        }

        return predictions
    }

    private func calculateUniquenessScore(_ beauty: BeautyFeatures?, _ social: MuseeScraper.SocialMediaData?) -> Double {
        // Simplified uniqueness calculation
        // In a real implementation, this would compare against a database of known muses
        var uniqueness = 0.5 // Base uniqueness

        if let beauty = beauty {
            // Unique facial features increase uniqueness
            if beauty.facialRatios.goldenRatioScore < 0.8 { uniqueness += 0.1 } // Less "perfect" = more unique
            if beauty.eyeAnalysis.overallAppeal < 0.7 { uniqueness += 0.05 }
        }

        if let social = social {
            // Unique content increases uniqueness
            if social.posts.count < 50 { uniqueness += 0.1 } // Smaller catalogs can be more curated
            if social.mediaURLs.count > social.posts.count { uniqueness += 0.05 } // More media variety
        }

        return min(1.0, uniqueness)
    }

    private func calculateConsistencyScore(_ historical: [MuseeTemporal.EROSSHistory.ScoreEntry]) -> Double {
        guard historical.count >= 2 else { return 0.5 }

        // Calculate score stability over time
        let scores = historical.map { $0.score }
        let count = Double(scores.count)
        let mean = scores.reduce(0, +) / count
        let squaredDiffs = scores.map { ($0 - mean) * ($0 - mean) }
        let variance = squaredDiffs.reduce(0, +) / count
        let stdDev = sqrt(variance)

        // Lower standard deviation = higher consistency
        let consistency = max(0.0, 1.0 - (stdDev / 20.0))

        return consistency
    }
}

/// Content quality assessment metrics
public struct ContentQualityMetrics: Sendable {
    public let resolution: Int       // pixels (width * height)
    public let compositionScore: Double  // 0.0 to 1.0
    public let lightingScore: Double    // 0.0 to 1.0
    public let focusScore: Double       // 0.0 to 1.0
    public let overallQuality: Double   // 0.0 to 1.0
    
    public init(resolution: Int, compositionScore: Double, lightingScore: Double, focusScore: Double, overallQuality: Double) {
        self.resolution = resolution
        self.compositionScore = compositionScore
        self.lightingScore = lightingScore
        self.focusScore = focusScore
        self.overallQuality = overallQuality
    }
}