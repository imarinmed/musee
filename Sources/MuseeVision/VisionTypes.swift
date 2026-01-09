import Foundation
import MuseeCore
import MuseeDomain
import CoreGraphics

/// Vision features extracted from an image.
public struct VisionFeatures: Codable, Sendable {
    public let faces: [FaceFeatures]
    public let poses: [PoseFeatures]
    public let hash: PerceptualHash
    public let extractedAt: Date

    public init(faces: [FaceFeatures], poses: [PoseFeatures], hash: PerceptualHash, extractedAt: Date) {
        self.faces = faces
        self.poses = poses
        self.hash = hash
        self.extractedAt = extractedAt
    }
}

/// Face detection results.
public struct FaceFeatures: Codable, Sendable {
    public let boundingBox: CGRect
    public let landmarks: [String: CGPoint]

    public init(boundingBox: CGRect, landmarks: [String: CGPoint]) {
        self.boundingBox = boundingBox
        self.landmarks = landmarks
    }
}

/// Pose detection results.
public struct PoseFeatures: Codable, Sendable {
    public let joints: [String: CGPoint]
    public let confidence: Float

    public init(joints: [String: CGPoint], confidence: Float) {
        self.joints = joints
        self.confidence = confidence
    }
}

/// Perceptual hash for image similarity.
public struct PerceptualHash: Codable, Sendable {
    public let aHash: UInt64  // Average hash
    public let dHash: UInt64  // Difference hash

    public init(aHash: UInt64, dHash: UInt64) {
        self.aHash = aHash
        self.dHash = dHash
    }
}

/// Auto-generated tags from image classification.
public struct AutoTags: Codable, Sendable {
    public let tags: [Tag]
    public let extractedAt: Date

    public init(tags: [Tag], extractedAt: Date) {
        self.tags = tags
        self.extractedAt = extractedAt
    }
}

/// Beauty analysis features.
public struct BeautyFeatures: Codable, Sendable {
    public let facialRatios: FacialRatios
    public let bodyRatios: BodyRatios
    public let symmetry: SymmetryScores
    public let skinAnalysis: SkinAnalysis
    public let eyeAnalysis: EyeAnalysis
    public let noseAnalysis: NoseAnalysis
    public let mouthAnalysis: MouthAnalysis
    public let facialStructure: FacialStructure
    public let features: FeatureScores

    public init(
        facialRatios: FacialRatios,
        bodyRatios: BodyRatios,
        symmetry: SymmetryScores,
        skinAnalysis: SkinAnalysis,
        eyeAnalysis: EyeAnalysis,
        noseAnalysis: NoseAnalysis,
        mouthAnalysis: MouthAnalysis,
        facialStructure: FacialStructure,
        features: FeatureScores
    ) {
        self.facialRatios = facialRatios
        self.bodyRatios = bodyRatios
        self.symmetry = symmetry
        self.skinAnalysis = skinAnalysis
        self.eyeAnalysis = eyeAnalysis
        self.noseAnalysis = noseAnalysis
        self.mouthAnalysis = mouthAnalysis
        self.facialStructure = facialStructure
        self.features = features
    }
}

/// Skin quality and texture analysis.
public struct SkinAnalysis: Codable, Sendable {
    public let texture: Double      // 0-1, smoothness (lower wrinkles/pores better)
    public let tone: Double         // 0-1, evenness
    public let radiance: Double     // 0-1, glow/brightness
    public let color: SkinColor     // Undertone analysis
    public let blemishes: Int       // Count of detected blemishes
    public let overallQuality: Double // 0-1

    public init(texture: Double, tone: Double, radiance: Double, color: SkinColor, blemishes: Int, overallQuality: Double) {
        self.texture = texture
        self.tone = tone
        self.radiance = radiance
        self.color = color
        self.blemishes = blemishes
        self.overallQuality = overallQuality
    }
}

/// Skin color analysis.
public struct SkinColor: Codable, Sendable {
    public let undertone: Undertone  // Warm, cool, neutral
    public let brightness: Double    // 0-1
    public let saturation: Double    // 0-1

    public enum Undertone: String, Codable, Sendable {
        case warm, cool, neutral
    }

    public init(undertone: Undertone, brightness: Double, saturation: Double) {
        self.undertone = undertone
        self.brightness = brightness
        self.saturation = saturation
    }
}

/// Eye feature analysis.
public struct EyeAnalysis: Codable, Sendable {
    public let shape: EyeShape       // Almond, round, etc.
    public let symmetry: Double      // 0-1, left-right balance
    public let irisVisibility: Double // 0-1, how visible irises are
    public let eyelidPosition: Double // 0-1, hooded vs prominent
    public let eyebrowArch: Double   // 0-1, arch quality
    public let overallAppeal: Double // 0-1

    public enum EyeShape: String, Codable, Sendable {
        case almond, round, monolid, hooded
    }

    public init(shape: EyeShape, symmetry: Double, irisVisibility: Double, eyelidPosition: Double, eyebrowArch: Double, overallAppeal: Double) {
        self.shape = shape
        self.symmetry = symmetry
        self.irisVisibility = irisVisibility
        self.eyelidPosition = eyelidPosition
        self.eyebrowArch = eyebrowArch
        self.overallAppeal = overallAppeal
    }
}

/// Nose feature analysis.
public struct NoseAnalysis: Codable, Sendable {
    public let bridgeWidth: Double   // 0-1, relative width
    public let nostrilSymmetry: Double // 0-1
    public let tipDefinition: Double // 0-1, refinement
    public let overallProportion: Double // 0-1, fit to face
    public let appeal: Double        // 0-1

    public init(bridgeWidth: Double, nostrilSymmetry: Double, tipDefinition: Double, overallProportion: Double, appeal: Double) {
        self.bridgeWidth = bridgeWidth
        self.nostrilSymmetry = nostrilSymmetry
        self.tipDefinition = tipDefinition
        self.overallProportion = overallProportion
        self.appeal = appeal
    }
}

/// Mouth feature analysis.
public struct MouthAnalysis: Codable, Sendable {
    public let lipFullness: Double   // 0-1, plumpness
    public let smileArc: Double      // 0-1, curve quality
    public let teethAlignment: Double // 0-1, straightness
    public let cupidsBow: Double     // 0-1, definition
    public let symmetry: Double      // 0-1, left-right balance
    public let appeal: Double        // 0-1

    public init(lipFullness: Double, smileArc: Double, teethAlignment: Double, cupidsBow: Double, symmetry: Double, appeal: Double) {
        self.lipFullness = lipFullness
        self.smileArc = smileArc
        self.teethAlignment = teethAlignment
        self.cupidsBow = cupidsBow
        self.symmetry = symmetry
        self.appeal = appeal
    }
}

/// Facial structure analysis.
public struct FacialStructure: Codable, Sendable {
    public let cheekboneProminence: Double // 0-1, definition
    public let jawlineDefinition: Double   // 0-1, sharpness
    public let chinShape: ChinShape        // Shape type
    public let foreheadProportion: Double  // 0-1, balance
    public let overallStructure: Double    // 0-1, bone structure appeal

    public enum ChinShape: String, Codable, Sendable {
        case pointed, square, round, cleft
    }

    public init(cheekboneProminence: Double, jawlineDefinition: Double, chinShape: ChinShape, foreheadProportion: Double, overallStructure: Double) {
        self.cheekboneProminence = cheekboneProminence
        self.jawlineDefinition = jawlineDefinition
        self.chinShape = chinShape
        self.foreheadProportion = foreheadProportion
        self.overallStructure = overallStructure
    }
}

/// Facial ratio scores based on multiple beauty metrics.
public struct FacialRatios: Codable, Sendable {
    // Golden ratio metrics
    public let eyeToNoseRatio: Double
    public let noseToMouthRatio: Double
    public let faceWidthRatio: Double

    // Neoclassical canons
    public let eyeToEyeRatio: Double        // Interocular distance
    public let faceLengthToWidth: Double    // Overall face proportion
    public let foreheadToFace: Double       // Upper third proportion

    // Facial thirds
    public let upperThird: Double           // Hairline to eyebrows
    public let middleThird: Double          // Eyebrows to nose
    public let lowerThird: Double           // Nose to chin

    // Eye-specific metrics
    public let eyeWidthRatio: Double        // Eye width to face width
    public let eyeHeightRatio: Double       // Eye height proportion

    // Nose metrics
    public let noseWidthRatio: Double       // Nose width to interocular
    public let noseLengthRatio: Double      // Nose length to face length

    // Mouth metrics
    public let mouthWidthRatio: Double      // Mouth width to face width
    public let lipFullnessRatio: Double     // Upper to lower lip

    // Overall scores
    public let goldenRatioScore: Double     // 0-1, golden ratio compliance
    public let neoclassicalScore: Double    // 0-1, neoclassical canons
    public let proportionsScore: Double     // 0-1, facial thirds balance
    public let overallScore: Double         // 0-1, combined harmony score

    public init(
        eyeToNoseRatio: Double,
        noseToMouthRatio: Double,
        faceWidthRatio: Double,
        eyeToEyeRatio: Double,
        faceLengthToWidth: Double,
        foreheadToFace: Double,
        upperThird: Double,
        middleThird: Double,
        lowerThird: Double,
        eyeWidthRatio: Double,
        eyeHeightRatio: Double,
        noseWidthRatio: Double,
        noseLengthRatio: Double,
        mouthWidthRatio: Double,
        lipFullnessRatio: Double,
        goldenRatioScore: Double,
        neoclassicalScore: Double,
        proportionsScore: Double,
        overallScore: Double
    ) {
        self.eyeToNoseRatio = eyeToNoseRatio
        self.noseToMouthRatio = noseToMouthRatio
        self.faceWidthRatio = faceWidthRatio
        self.eyeToEyeRatio = eyeToEyeRatio
        self.faceLengthToWidth = faceLengthToWidth
        self.foreheadToFace = foreheadToFace
        self.upperThird = upperThird
        self.middleThird = middleThird
        self.lowerThird = lowerThird
        self.eyeWidthRatio = eyeWidthRatio
        self.eyeHeightRatio = eyeHeightRatio
        self.noseWidthRatio = noseWidthRatio
        self.noseLengthRatio = noseLengthRatio
        self.mouthWidthRatio = mouthWidthRatio
        self.lipFullnessRatio = lipFullnessRatio
        self.goldenRatioScore = goldenRatioScore
        self.neoclassicalScore = neoclassicalScore
        self.proportionsScore = proportionsScore
        self.overallScore = overallScore
    }
}

/// Body proportion ratios.
public struct BodyRatios: Codable, Sendable {
    public let waistToHipRatio: Double?
    public let shoulderToWaistRatio: Double?
    public let overallScore: Double  // 0-1

    public init(waistToHipRatio: Double?, shoulderToWaistRatio: Double?, overallScore: Double) {
        self.waistToHipRatio = waistToHipRatio
        self.shoulderToWaistRatio = shoulderToWaistRatio
        self.overallScore = overallScore
    }
}

/// Symmetry analysis scores.
public struct SymmetryScores: Codable, Sendable {
    public let facialSymmetry: Double  // 0-1
    public let bodySymmetry: Double  // 0-1
    public let overallScore: Double  // 0-1

    public init(facialSymmetry: Double, bodySymmetry: Double, overallScore: Double) {
        self.facialSymmetry = facialSymmetry
        self.bodySymmetry = bodySymmetry
        self.overallScore = overallScore
    }
}

/// Feature quality scores.
public struct FeatureScores: Codable, Sendable {
    public let skinQuality: Double  // 0-1
    public let blemishCount: Int
    public let muscleDefinition: Double  // 0-1
    public let breastSymmetry: Double?  // 0-1, nil if not applicable
    public let overallScore: Double  // 0-1

    public init(skinQuality: Double, blemishCount: Int, muscleDefinition: Double, breastSymmetry: Double?, overallScore: Double) {
        self.skinQuality = skinQuality
        self.blemishCount = blemishCount
        self.muscleDefinition = muscleDefinition
        self.breastSymmetry = breastSymmetry
        self.overallScore = overallScore
    }
}