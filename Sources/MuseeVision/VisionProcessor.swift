import Foundation
import MuseeCore
import MuseeDomain
import Vision
import CoreGraphics
import CoreImage
/// Processes images using Vision framework.
public struct VisionProcessor {
    /// Extract comprehensive vision features from image data.
    public static func extractFeatures(from imageData: Data) async -> Result<VisionFeatures, MuseeError> {
        do {
            async let faces = detectFaces(in: imageData)
            async let poses = detectPoses(in: imageData)
            async let hash = computePerceptualHash(from: imageData)

            let faceFeatures = try await faces
            let poseFeatures = try await poses
            let perceptualHash = try await hash

            let features = VisionFeatures(
                faces: faceFeatures,
                poses: poseFeatures,
                hash: perceptualHash,
                extractedAt: Date()
            )

            return .success(features)
        } catch let error as MuseeError {
            return .failure(error)
        } catch {
            return .failure(.visionProcessingFailed("Failed to extract vision features: \(error.localizedDescription)"))
        }
    }

    /// Detect faces and landmarks in an image.
    private static func detectFaces(in imageData: Data) async throws -> [FaceFeatures] {
        let imageRequestHandler = VNImageRequestHandler(data: imageData, options: [:])

        let faceRequest = VNDetectFaceLandmarksRequest()
        try imageRequestHandler.perform([faceRequest])

        return faceRequest.results?.compactMap { result -> FaceFeatures? in
            guard let landmarks = result.landmarks else { return nil }

            var landmarkPoints: [String: CGPoint] = [:]
            if let leftEye = landmarks.leftEye {
                landmarkPoints["leftEye"] = leftEye.normalizedPoints.first ?? .zero
            }
            if let rightEye = landmarks.rightEye {
                landmarkPoints["rightEye"] = rightEye.normalizedPoints.first ?? .zero
            }
            if let nose = landmarks.nose {
                landmarkPoints["nose"] = nose.normalizedPoints.first ?? .zero
            }

            return FaceFeatures(boundingBox: result.boundingBox, landmarks: landmarkPoints)
        } ?? []
    }

    /// Detect human poses in an image.
    public static func detectPoses(in imageData: Data) async throws -> [PoseFeatures] {
        let imageRequestHandler = VNImageRequestHandler(data: imageData, options: [:])

        let poseRequest = VNDetectHumanBodyPoseRequest()
        try imageRequestHandler.perform([poseRequest])

        return poseRequest.results?.compactMap { result in
            var joints: [String: CGPoint] = [:]

            try? result.recognizedPoints(.all).forEach { key, point in
                if point.confidence > 0.5 {
                    joints[String(describing: key)] = point.location
                }
            }

            return PoseFeatures(joints: joints, confidence: result.confidence)
        } ?? []
    }



    /// Analyze beauty features from vision data.
    public static func analyzeBeauty(from features: VisionFeatures) -> BeautyFeatures {
        let facialRatios = analyzeFacialRatios(from: features.faces)
        let bodyRatios = analyzeBodyRatios(from: features.poses)
        let symmetry = analyzeSymmetry(from: features.faces, poses: features.poses)
        let skinAnalysis = analyzeSkin(from: features)  // Placeholder
        let eyeAnalysis = analyzeEyes(from: features.faces)
        let noseAnalysis = analyzeNose(from: features.faces)
        let mouthAnalysis = analyzeMouth(from: features.faces)
        let facialStructure = analyzeFacialStructure(from: features.faces)
        let featureScores = analyzeFeatures(from: features)

        return BeautyFeatures(
            facialRatios: facialRatios,
            bodyRatios: bodyRatios,
            symmetry: symmetry,
            skinAnalysis: skinAnalysis,
            eyeAnalysis: eyeAnalysis,
            noseAnalysis: noseAnalysis,
            mouthAnalysis: mouthAnalysis,
            facialStructure: facialStructure,
            features: featureScores
        )
    }

    private static func analyzeFacialRatios(from faces: [FaceFeatures]) -> FacialRatios {
        guard let face = faces.first else {
            return FacialRatios(
                eyeToNoseRatio: 0, noseToMouthRatio: 0, faceWidthRatio: 0,
                eyeToEyeRatio: 0, faceLengthToWidth: 0, foreheadToFace: 0,
                upperThird: 0, middleThird: 0, lowerThird: 0,
                eyeWidthRatio: 0, eyeHeightRatio: 0,
                noseWidthRatio: 0, noseLengthRatio: 0,
                mouthWidthRatio: 0, lipFullnessRatio: 0,
                goldenRatioScore: 0, neoclassicalScore: 0, proportionsScore: 0, overallScore: 0
            )
        }

        // Calculate distances from landmarks (placeholder implementation)
        let landmarks = face.landmarks

        // Golden ratio metrics
        let eyeToNose = distance(landmarks["leftEye"] ?? .zero, landmarks["nose"] ?? .zero)
        let noseToMouth = distance(landmarks["nose"] ?? .zero, landmarks["mouth"] ?? .zero)
        let faceWidth = abs((landmarks["leftTemple"]?.x ?? 0) - (landmarks["rightTemple"]?.x ?? 0))

        // Neoclassical metrics
        let eyeToEye = distance(landmarks["leftEye"] ?? .zero, landmarks["rightEye"] ?? .zero)
        let faceLength = distance(landmarks["forehead"] ?? .zero, landmarks["chin"] ?? .zero)
        let foreheadHeight = distance(landmarks["forehead"] ?? .zero, landmarks["leftEyebrow"] ?? .zero)

        // Facial thirds
        let upperThird = distance(landmarks["forehead"] ?? .zero, landmarks["leftEyebrow"] ?? .zero)
        let middleThird = distance(landmarks["leftEyebrow"] ?? .zero, landmarks["nose"] ?? .zero)
        let lowerThird = distance(landmarks["nose"] ?? .zero, landmarks["chin"] ?? .zero)

        // Feature ratios (placeholders)
        let eyeWidth = distance(landmarks["leftEyeCorner"] ?? .zero, landmarks["rightEyeCorner"] ?? .zero)
        let eyeHeight = abs((landmarks["leftEye"]?.y ?? 0) - (landmarks["leftEyelid"]?.y ?? 0))
        let noseWidth = distance(landmarks["leftNostril"] ?? .zero, landmarks["rightNostril"] ?? .zero)
        let noseLength = distance(landmarks["noseBridge"] ?? .zero, landmarks["noseTip"] ?? .zero)
        let mouthWidth = distance(landmarks["leftMouth"] ?? .zero, landmarks["rightMouth"] ?? .zero)
        let upperLip = abs((landmarks["upperLip"]?.y ?? 0) - (landmarks["mouth"]?.y ?? 0))
        let lowerLip = abs((landmarks["lowerLip"]?.y ?? 0) - (landmarks["mouth"]?.y ?? 0))

        // Calculate ratios
        let phi: Double = 1.618
        let eyeToNoseRatio = eyeToNose > 0 ? noseToMouth / eyeToNose : 0
        let noseToMouthRatio = eyeToNose > 0 ? noseToMouth / eyeToNose : 0  // Simplified
        let faceWidthRatio = faceLength > 0 ? faceWidth / faceLength : 0

        let eyeToEyeRatio = faceWidth > 0 ? eyeToEye / faceWidth : 0
        let faceLengthToWidth = faceWidth > 0 ? faceLength / faceWidth : 0
        let foreheadToFace = faceLength > 0 ? foreheadHeight / faceLength : 0

        let totalThirds = upperThird + middleThird + lowerThird
        let upperThirdRatio = totalThirds > 0 ? upperThird / totalThirds : 0
        let middleThirdRatio = totalThirds > 0 ? middleThird / totalThirds : 0
        let lowerThirdRatio = totalThirds > 0 ? lowerThird / totalThirds : 0

        let eyeWidthRatio = faceWidth > 0 ? eyeWidth / faceWidth : 0
        let eyeHeightRatio = eyeWidth > 0 ? eyeHeight / eyeWidth : 0
        let noseWidthRatio = eyeToEye > 0 ? noseWidth / eyeToEye : 0
        let noseLengthRatio = faceLength > 0 ? noseLength / faceLength : 0
        let mouthWidthRatio = faceWidth > 0 ? mouthWidth / faceWidth : 0
        let lipFullnessRatio = lowerLip > 0 ? upperLip / lowerLip : 0

        // Calculate scores
        let goldenRatioScore = calculateGoldenRatioScore([
            eyeToNoseRatio, noseToMouthRatio, faceWidthRatio
        ])

        let neoclassicalScore = calculateNeoclassicalScore([
            eyeToEyeRatio, faceLengthToWidth, foreheadToFace
        ])

        let proportionsScore = calculateProportionsScore([
            upperThirdRatio, middleThirdRatio, lowerThirdRatio
        ])

        let overallScore = (goldenRatioScore * 0.4 + neoclassicalScore * 0.3 + proportionsScore * 0.3)

        return FacialRatios(
            eyeToNoseRatio: eyeToNoseRatio,
            noseToMouthRatio: noseToMouthRatio,
            faceWidthRatio: faceWidthRatio,
            eyeToEyeRatio: eyeToEyeRatio,
            faceLengthToWidth: faceLengthToWidth,
            foreheadToFace: foreheadToFace,
            upperThird: upperThirdRatio,
            middleThird: middleThirdRatio,
            lowerThird: lowerThirdRatio,
            eyeWidthRatio: eyeWidthRatio,
            eyeHeightRatio: eyeHeightRatio,
            noseWidthRatio: noseWidthRatio,
            noseLengthRatio: noseLengthRatio,
            mouthWidthRatio: mouthWidthRatio,
            lipFullnessRatio: lipFullnessRatio,
            goldenRatioScore: goldenRatioScore,
            neoclassicalScore: neoclassicalScore,
            proportionsScore: proportionsScore,
            overallScore: overallScore
        )
    }

    private static func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }

    private static func calculateGoldenRatioScore(_ ratios: [Double]) -> Double {
        let phi: Double = 1.618
        let deviations = ratios.map { abs($0 - phi) / phi }
        let averageDeviation = deviations.reduce(0, +) / Double(deviations.count)
        return max(0, min(1, 1 - averageDeviation))
    }

    private static func calculateNeoclassicalScore(_ ratios: [Double]) -> Double {
        // Ideal neoclassical ratios (simplified)
        let ideals = [0.46, 1.5, 0.33]  // eye-to-eye/face-width, face-length/width, forehead/face
        let deviations = zip(ratios, ideals).map { abs($0 - $1) / $1 }
        let averageDeviation = deviations.reduce(0, +) / Double(deviations.count)
        return max(0, min(1, 1 - averageDeviation))
    }

    private static func calculateProportionsScore(_ thirds: [Double]) -> Double {
        let ideal = 1.0 / 3.0  // Each third should be 1/3
        let deviations = thirds.map { abs($0 - ideal) / ideal }
        let averageDeviation = deviations.reduce(0, +) / Double(deviations.count)
        return max(0, min(1, 1 - averageDeviation))
    }

    private static func analyzeBodyRatios(from poses: [PoseFeatures]) -> BodyRatios {
        guard let pose = poses.first else {
            return BodyRatios(waistToHipRatio: nil, shoulderToWaistRatio: nil, overallScore: 0)
        }

        // Placeholder calculations
        let waistHip: Double? = nil  // Need waist/hip joints
        let shoulderWaist: Double? = nil  // Need shoulder/waist

        let score = 0.5  // Placeholder

        return BodyRatios(waistToHipRatio: waistHip, shoulderToWaistRatio: shoulderWaist, overallScore: score)
    }

    private static func analyzeSymmetry(from faces: [FaceFeatures], poses: [PoseFeatures]) -> SymmetryScores {
        // Placeholder symmetry analysis
        let facialSym = 0.8  // Compare left-right face features
        let bodySym = 0.7  // Compare left-right body poses
        let overall = (facialSym + bodySym) / 2

        return SymmetryScores(facialSymmetry: facialSym, bodySymmetry: bodySym, overallScore: overall)
    }

    private static func analyzeSkin(from features: VisionFeatures) -> SkinAnalysis {
        // Placeholder skin analysis
        let texture = 0.8  // Would analyze wrinkles, pores
        let tone = 0.9     // Would analyze color evenness
        let radiance = 0.7 // Would analyze brightness/glow
        let color = SkinColor(undertone: .neutral, brightness: 0.6, saturation: 0.3)
        let blemishes = 2   // Would detect acne, scars
        let overall = (texture + tone + radiance) / 3

        return SkinAnalysis(
            texture: texture,
            tone: tone,
            radiance: radiance,
            color: color,
            blemishes: blemishes,
            overallQuality: overall
        )
    }

    private static func analyzeEyes(from faces: [FaceFeatures]) -> EyeAnalysis {
        guard let face = faces.first else {
            return EyeAnalysis(shape: .almond, symmetry: 0, irisVisibility: 0, eyelidPosition: 0, eyebrowArch: 0, overallAppeal: 0)
        }

        // Placeholder eye analysis
        let shape: EyeAnalysis.EyeShape = .almond
        let symmetry = 0.8  // Would compare left/right eye features
        let irisVisibility = 0.7
        let eyelidPosition = 0.6
        let eyebrowArch = 0.9
        let overall = (symmetry + irisVisibility + eyelidPosition + eyebrowArch) / 4

        return EyeAnalysis(
            shape: shape,
            symmetry: symmetry,
            irisVisibility: irisVisibility,
            eyelidPosition: eyelidPosition,
            eyebrowArch: eyebrowArch,
            overallAppeal: overall
        )
    }

    private static func analyzeNose(from faces: [FaceFeatures]) -> NoseAnalysis {
        guard let face = faces.first else {
            return NoseAnalysis(bridgeWidth: 0, nostrilSymmetry: 0, tipDefinition: 0, overallProportion: 0, appeal: 0)
        }

        // Placeholder nose analysis
        let bridgeWidth = 0.5
        let nostrilSymmetry = 0.9
        let tipDefinition = 0.7
        let overallProportion = 0.8
        let appeal = (bridgeWidth + nostrilSymmetry + tipDefinition + overallProportion) / 4

        return NoseAnalysis(
            bridgeWidth: bridgeWidth,
            nostrilSymmetry: nostrilSymmetry,
            tipDefinition: tipDefinition,
            overallProportion: overallProportion,
            appeal: appeal
        )
    }

    private static func analyzeMouth(from faces: [FaceFeatures]) -> MouthAnalysis {
        guard let face = faces.first else {
            return MouthAnalysis(lipFullness: 0, smileArc: 0, teethAlignment: 0, cupidsBow: 0, symmetry: 0, appeal: 0)
        }

        // Placeholder mouth analysis
        let lipFullness = 0.8
        let smileArc = 0.7
        let teethAlignment = 0.9
        let cupidsBow = 0.6
        let symmetry = 0.8
        let appeal = (lipFullness + smileArc + teethAlignment + cupidsBow + symmetry) / 5

        return MouthAnalysis(
            lipFullness: lipFullness,
            smileArc: smileArc,
            teethAlignment: teethAlignment,
            cupidsBow: cupidsBow,
            symmetry: symmetry,
            appeal: appeal
        )
    }

    private static func analyzeFacialStructure(from faces: [FaceFeatures]) -> FacialStructure {
        guard let face = faces.first else {
            return FacialStructure(cheekboneProminence: 0, jawlineDefinition: 0, chinShape: .round, foreheadProportion: 0, overallStructure: 0)
        }

        // Placeholder facial structure analysis
        let cheekboneProminence = 0.7
        let jawlineDefinition = 0.8
        let chinShape: FacialStructure.ChinShape = .pointed
        let foreheadProportion = 0.6
        let overall = (cheekboneProminence + jawlineDefinition + foreheadProportion) / 3

        return FacialStructure(
            cheekboneProminence: cheekboneProminence,
            jawlineDefinition: jawlineDefinition,
            chinShape: chinShape,
            foreheadProportion: foreheadProportion,
            overallStructure: overall
        )
    }

    private static func analyzeFeatures(from features: VisionFeatures) -> FeatureScores {
        let skinAnalysis = analyzeSkin(from: features)
        let blemishCount = skinAnalysis.blemishes
        let muscleDef = 0.6
        let breastSym: Double? = nil
        let overall = (skinAnalysis.overallQuality + muscleDef) / 2

        return FeatureScores(
            skinQuality: skinAnalysis.overallQuality,
            blemishCount: blemishCount,
            muscleDefinition: muscleDef,
            breastSymmetry: breastSym,
            overallScore: overall
        )
    }

    /// Classify image and generate auto-tags.
    public static func classifyImage(in imageData: Data) async throws -> [Tag] {
        let imageRequestHandler = VNImageRequestHandler(data: imageData, options: [:])

        let classificationRequest = VNClassifyImageRequest()
        classificationRequest.revision = VNClassifyImageRequestRevision1
        try imageRequestHandler.perform([classificationRequest])

        return classificationRequest.results?.compactMap { result -> Tag? in
            guard result.confidence > 0.8 else { return nil }  // Only high confidence

            // Parse identifier to create tags
            let identifier = result.identifier
            let tagValue = parseClassificationIdentifier(identifier)
            guard !tagValue.isEmpty else { return nil }

            return Tag(namespace: .system, value: tagValue)
        } ?? []
    }

    private static func parseClassificationIdentifier(_ identifier: String) -> String {
        // Simple parsing: e.g., "dress" -> "clothing:dress", "blond hair" -> "hair:blonde"
        let lower = identifier.lowercased()

        if lower.contains("dress") || lower.contains("shirt") || lower.contains("pants") {
            return "clothing:\(lower.replacingOccurrences(of: " ", with: "-"))"
        } else if lower.contains("hair") {
            if lower.contains("blond") { return "hair:blonde" }
            else if lower.contains("brunette") || lower.contains("brown") { return "hair:brown" }
            else if lower.contains("red") { return "hair:red" }
            else if lower.contains("black") { return "hair:black" }
            else { return "hair:\(lower.replacingOccurrences(of: " hair", with: ""))" }
        } else if lower.contains("accessory") || lower.contains("hat") || lower.contains("glasses") {
            return "accessory:\(lower.replacingOccurrences(of: " ", with: "-"))"
        }

        return ""  // Skip unknown
    }

    /// Compute perceptual hash for image similarity.
    public static func computePerceptualHash(from imageData: Data) throws -> PerceptualHash {
        guard let image = CGImage.from(data: imageData) else {
            throw MuseeError.invalidData("Cannot create CGImage from data")
        }

        let aHash = try computeAHash(for: image)
        let dHash = try computeDHash(for: image)

        return PerceptualHash(aHash: aHash, dHash: dHash)
    }

    private static func computeAHash(for image: CGImage) throws -> UInt64 {
        let resized = try image.resized(to: CGSize(width: 8, height: 8))
        guard let context = CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 8, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            throw MuseeError.processingFailed("Cannot create grayscale context")
        }
        context.draw(resized, in: CGRect(x: 0, y: 0, width: 8, height: 8))

        guard let data = context.data else {
            throw MuseeError.processingFailed("Cannot get image data")
        }

        let pixels = UnsafeBufferPointer<UInt8>(start: data.assumingMemoryBound(to: UInt8.self), count: 64)
        let sum = pixels.reduce(0, { $0 + Int($1) })
        let average = sum / 64

        var hash: UInt64 = 0
        for (index, pixel) in pixels.enumerated() {
            if pixel >= average {
                hash |= (1 << index)
            }
        }

        return hash
    }

    private static func computeDHash(for image: CGImage) throws -> UInt64 {
        let resized = try image.resized(to: CGSize(width: 9, height: 8))
        guard let context = CGContext(data: nil, width: 9, height: 8, bitsPerComponent: 8, bytesPerRow: 9, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            throw MuseeError.processingFailed("Cannot create grayscale context")
        }
        context.draw(resized, in: CGRect(x: 0, y: 0, width: 9, height: 8))

        guard let data = context.data else {
            throw MuseeError.processingFailed("Cannot get image data")
        }

        let pixels = UnsafeBufferPointer<UInt8>(start: data.assumingMemoryBound(to: UInt8.self), count: 72)

        var hash: UInt64 = 0
        for row in 0..<8 {
            for col in 0..<8 {
                let left = pixels[row * 9 + col]
                let right = pixels[row * 9 + col + 1]
                if left > right {
                    hash |= (1 << (row * 8 + col))
                }
            }
        }

        return hash
    }
}

extension CGImage {
    static func from(data: Data) -> CGImage? {
        guard let dataProvider = CGDataProvider(data: data as CFData),
              let image = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            return nil
        }
        return image
    }

    func resized(to size: CGSize) throws -> CGImage {
        guard let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            throw MuseeError.processingFailed("Cannot create resize context")
        }
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(origin: .zero, size: size))

        guard let resized = context.makeImage() else {
            throw MuseeError.processingFailed("Cannot create resized image")
        }

        return resized
    }
}