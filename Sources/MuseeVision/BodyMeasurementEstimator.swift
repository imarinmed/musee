import Foundation
import MuseeCore
import MuseeDomain

/// Estimates body measurements from pose landmarks.
public struct BodyMeasurementEstimator {
    /// Estimate height from pose joints.
    /// Note: This is a simplified estimation; real implementation would use reference objects or known camera parameters.
    public static func estimateHeight(from pose: PoseFeatures, referenceHeightCm: Double? = nil) -> Double? {
        guard let neck = pose.joints["neck"], let leftAnkle = pose.joints["leftAnkle"] else {
            return nil
        }

        let pixelDistance = abs(neck.y - leftAnkle.y)
        if pixelDistance == 0 { return nil }

        if let referenceHeight = referenceHeightCm {
            return referenceHeight
        }

        return nil // Cannot estimate absolute height without reference
    }

    /// Estimate bust/waist/hips from pose.
    public static func estimateMeasurements(from pose: PoseFeatures) -> [String: Double] {
        var measurements: [String: Double] = [:]

        if let leftShoulder = pose.joints["leftShoulder"], let rightShoulder = pose.joints["rightShoulder"] {
            measurements["shoulderWidth"] = abs(leftShoulder.x - rightShoulder.x) * 100.0
        }

        return measurements
    }

    /// Create a BiographicalClaim from estimated measurements.
    public static func createMeasurementClaims(
        from pose: PoseFeatures,
        for personId: StableID,
        validAt: PartialDate
    ) -> [BiographicalClaim] {
        var claims: [BiographicalClaim] = []

        if let height = estimateHeight(from: pose) {
            claims.append(BiographicalClaim(
                id: StableID(UUID().uuidString),
                subject: personId,
                property: .height,
                value: .number(height),
                confidence: .low,
                validAt: validAt,
                references: [ClaimReference(
                    type: .user,
                    url: nil,
                    title: "Vision pose estimation",
                    retrievedAt: Date()
                )]
            ))
        }

        for (key, value) in estimateMeasurements(from: pose) {
            if let property = ClaimProperty(rawValue: key) {
                claims.append(BiographicalClaim(
                    id: StableID(UUID().uuidString),
                    subject: personId,
                    property: property,
                    value: .number(value),
                    confidence: .low,
                    validAt: validAt,
                    references: [ClaimReference(
                        type: .system,
                        url: nil,
                        title: "Vision pose estimation",
                        retrievedAt: Date()
                    )]
                ))
            }
        }

        return claims
    }
}