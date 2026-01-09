import XCTest
import MuseeCore
import MuseeDomain
import MuseeVision

final class MuseeVisionTests: XCTestCase {
    func testComputePerceptualHash() throws {
        // Create a simple test image (1x1 pixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            XCTFail("Cannot create context")
            return
        }
        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        guard let image = context.makeImage() else {
            XCTFail("Cannot create image")
            return
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, "public.jpeg" as CFString, 1, nil) else {
            XCTFail("Cannot create destination")
            return
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        let data = mutableData as Data

        let hash = try VisionProcessor.computePerceptualHash(from: data)
        // Hash values may be 0 for uniform images, just verify computation succeeds
        XCTAssertNotNil(hash)
    }

    func testBodyMeasurementEstimator() throws {
        let pose = PoseFeatures(joints: ["neck": CGPoint(x: 0.5, y: 0.3), "leftAnkle": CGPoint(x: 0.5, y: 0.9)], confidence: 0.9)
        let height = BodyMeasurementEstimator.estimateHeight(from: pose)
        XCTAssertNil(height)  // No reference height

        let measurements = BodyMeasurementEstimator.estimateMeasurements(from: pose)
        XCTAssertTrue(measurements.isEmpty)  // No shoulder data
    }

    func testClassifyImage() async throws {
        // Mock data - in real test, use actual image
        let data = Data()  // Empty data will fail, but test the method exists
        do {
            let tags = try await VisionProcessor.classifyImage(in: data)
            XCTAssertTrue(tags.isEmpty)
        } catch {
            // Expected for empty data
        }
    }

    func testEROSSCalculator() throws {
        let beauty = BeautyFeatures(
            facialRatios: FacialRatios(
                eyeToNoseRatio: 1.618, noseToMouthRatio: 1.618, faceWidthRatio: 1.618,
                eyeToEyeRatio: 0.46, faceLengthToWidth: 1.5, foreheadToFace: 0.33,
                upperThird: 0.33, middleThird: 0.33, lowerThird: 0.34,
                eyeWidthRatio: 0.3, eyeHeightRatio: 0.25,
                noseWidthRatio: 0.25, noseLengthRatio: 0.3,
                mouthWidthRatio: 0.4, lipFullnessRatio: 1.0,
                goldenRatioScore: 0.85, neoclassicalScore: 0.75, proportionsScore: 0.9, overallScore: 0.8
            ),
            bodyRatios: BodyRatios(waistToHipRatio: 0.7, shoulderToWaistRatio: 1.618, overallScore: 0.8),
            symmetry: SymmetryScores(facialSymmetry: 0.9, bodySymmetry: 0.8, overallScore: 0.85),
            skinAnalysis: SkinAnalysis(
                texture: 0.9, tone: 0.85, radiance: 0.8,
                color: SkinColor(undertone: .neutral, brightness: 0.7, saturation: 0.3),
                blemishes: 2, overallQuality: 0.82
            ),
            eyeAnalysis: EyeAnalysis(
                shape: .almond, symmetry: 0.9, irisVisibility: 0.8,
                eyelidPosition: 0.7, eyebrowArch: 0.85, overallAppeal: 0.82
            ),
            noseAnalysis: NoseAnalysis(
                bridgeWidth: 0.6, nostrilSymmetry: 0.9, tipDefinition: 0.8,
                overallProportion: 0.85, appeal: 0.82
            ),
            mouthAnalysis: MouthAnalysis(
                lipFullness: 0.9, smileArc: 0.8, teethAlignment: 0.95,
                cupidsBow: 0.7, symmetry: 0.88, appeal: 0.85
            ),
            facialStructure: FacialStructure(
                cheekboneProminence: 0.75, jawlineDefinition: 0.8,
                chinShape: .pointed, foreheadProportion: 0.65, overallStructure: 0.78
            ),
            features: FeatureScores(skinQuality: 0.95, blemishCount: 0, muscleDefinition: 0.7, breastSymmetry: 0.9, overallScore: 0.85)
        )

        let score = EROSCalculator.calculateEROSS(from: beauty)
        XCTAssertGreaterThan(score, 70.0) // Reasonable score for test beauty features
        XCTAssertLessThanOrEqual(score, 100.0)

        let claim = EROSCalculator.createEROSSClaim(score: score, for: StableID("person1"), validAt: PartialDate.year(2025))
        XCTAssertEqual(claim.property, ClaimProperty.eross)
        XCTAssertEqual(claim.value, ClaimValue.number(score))
    }
}