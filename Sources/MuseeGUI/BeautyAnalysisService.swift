import Foundation
import MuseeCore
import MuseeDomain
import MuseeVision

/// Service for coordinating beauty analysis operations.
public actor BeautyAnalysisService {
    private let visionProcessor: VisionProcessor.Type

    public init(visionProcessor: VisionProcessor.Type = VisionProcessor.self) {
        self.visionProcessor = visionProcessor
    }

    /// Performs complete beauty analysis on image data.
    /// - Parameter imageData: Raw image data to analyze
    /// - Returns: Result containing beauty analysis results or error
    public func analyzeBeauty(from imageData: Data) async -> Result<BeautyFeatures, MuseeError> {
        // Extract vision features
        let featuresResult = await visionProcessor.extractFeatures(from: imageData)

        switch featuresResult {
        case .success(let features):
            // Perform beauty analysis
            let beautyFeatures = visionProcessor.analyzeBeauty(from: features)
            return .success(beautyFeatures)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Calculates EROSS score from beauty features.
    /// - Parameter beauty: Analyzed beauty features
    /// - Returns: EROSS score between 0-100
    public nonisolated func calculateEROSS(from beauty: BeautyFeatures) -> Double {
        EROSCalculator.calculateEROSS(from: beauty)
    }
}