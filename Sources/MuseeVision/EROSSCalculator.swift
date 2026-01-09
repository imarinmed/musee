import Foundation
import MuseeCore
import MuseeDomain

/// Calculates EROSS beauty score from beauty features.
public struct EROSCalculator {
    /// Calculate EROSS score (0-100) from beauty features.
    public static func calculateEROSS(from beauty: BeautyFeatures) -> Double {
        // Facial components (40% total)
        let facialRatiosScore = beauty.facialRatios.overallScore * 0.15  // Proportions
        let skinQualityScore = beauty.skinAnalysis.overallQuality * 0.1  // Skin health
        let eyeAppealScore = beauty.eyeAnalysis.overallAppeal * 0.05    // Eye features
        let noseAppealScore = beauty.noseAnalysis.appeal * 0.04          // Nose harmony
        let mouthAppealScore = beauty.mouthAnalysis.appeal * 0.04        // Mouth aesthetics
        let structureScore = beauty.facialStructure.overallStructure * 0.02 // Bone structure

        // Body components (25% total)
        let bodyScore = beauty.bodyRatios.overallScore * 0.2
        let muscleScore = beauty.features.muscleDefinition * 0.05

        // Symmetry components (20% total)
        let facialSymmetryScore = beauty.symmetry.facialSymmetry * 0.12
        let bodySymmetryScore = beauty.symmetry.bodySymmetry * 0.06
        let eyeSymmetryScore = beauty.eyeAnalysis.symmetry * 0.01
        let noseSymmetryScore = beauty.noseAnalysis.nostrilSymmetry * 0.005
        let mouthSymmetryScore = beauty.mouthAnalysis.symmetry * 0.005

        // Quality components (15% total)
        let blemishPenalty = min(0.05, Double(beauty.skinAnalysis.blemishes) * 0.01)  // Max 5% penalty
        let radianceBonus = beauty.skinAnalysis.radiance * 0.05  // Up to 5% bonus
        let toneBonus = beauty.skinAnalysis.tone * 0.05          // Up to 5% bonus

        let rawScore = facialRatiosScore + skinQualityScore + eyeAppealScore +
                      noseAppealScore + mouthAppealScore + structureScore +
                      bodyScore + muscleScore +
                      facialSymmetryScore + bodySymmetryScore + eyeSymmetryScore +
                      noseSymmetryScore + mouthSymmetryScore +
                      radianceBonus + toneBonus - blemishPenalty

        // Scale to 0-100 and clamp
        return max(0, min(100, rawScore * 100))
    }

    /// Create EROSS claim for a person.
    public static func createEROSSClaim(
        score: Double,
        for personId: StableID,
        validAt: PartialDate
    ) -> BiographicalClaim {
        BiographicalClaim(
            id: StableID(UUID().uuidString),
            subject: personId,
            property: .eross,
            value: .number(score),
            confidence: .medium,
            validAt: validAt,
            references: [ClaimReference(
                type: .system,
                url: nil,
                title: "EROSS beauty score calculation",
                retrievedAt: Date()
            )]
        )
    }
}