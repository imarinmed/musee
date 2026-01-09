# Beauty Analysis Guide

This guide walks you through performing comprehensive beauty analysis with Musee's EROSS system, from basic scoring to advanced longitudinal tracking.

## Overview

Musee's beauty analysis combines computer vision with mathematical beauty principles to provide objective attractiveness assessments. The system analyzes facial features, body proportions, symmetry, and skin quality to generate an EROSS score from 0-100.

## Prerequisites

- Musee framework installed
- Media assets (images/videos) of the person to analyze
- Basic understanding of Swift concurrency

## Basic Beauty Analysis

### 1. Set Up Vision Processing

```swift
import MuseeVision

// Initialize vision processor (automatic in most cases)
let processor = VisionProcessor()
```

### 2. Extract Vision Features

```swift
// Load image data
let imageData = try Data(contentsOf: imageURL)

// Extract comprehensive vision features
let visionFeatures = try await VisionProcessor.extractFeatures(from: imageData)

// Features include:
// - Face landmarks (68 points)
// - Body pose keypoints
// - Perceptual hash for similarity
```

### 3. Analyze Beauty Features

```swift
// Perform comprehensive beauty analysis
let beautyFeatures = VisionProcessor.analyzeBeauty(from: visionFeatures)

// Access detailed analysis components
let facialRatios = beautyFeatures.facialRatios
let skinAnalysis = beautyFeatures.skinAnalysis
let eyeAnalysis = beautyFeatures.eyeAnalysis
let symmetry = beautyFeatures.symmetry
```

### 4. Calculate EROSS Score

```swift
// Generate final beauty score
let erossScore = EROSCalculator.calculateEROSS(from: beautyFeatures)

// Score ranges from 0-100
// 90-100: Exceptional beauty
// 80-89: Outstanding attractiveness
// 70-79: Noticeably attractive
// 60-69: Average attractiveness
// 50-59: Below average
// <50: Requires significant improvement
```

## Understanding EROSS Components

### Facial Ratios (15% of score)

Facial proportions based on golden ratio and neoclassical canons:

```swift
// Access detailed facial metrics
let faceRatios = beautyFeatures.facialRatios

print("Golden Ratio Score: \(faceRatios.goldenRatioScore)")
print("Eye-to-Nose Ratio: \(faceRatios.eyeToNoseRatio)")
print("Face Length/Width: \(faceRatios.faceLengthToWidth)")

// Ideal ratios:
// - Face length:width ≈ 1.5:1 or 1.618:1
// - Eye spacing ≈ 0.46 × face width
// - Facial thirds ≈ equal distribution
```

### Skin Analysis (10% of score)

Comprehensive skin quality assessment:

```swift
let skin = beautyFeatures.skinAnalysis

print("Skin Texture: \(skin.texture)")      // 0-1 (smoothness)
print("Skin Tone: \(skin.tone)")           // 0-1 (evenness)
print("Radiance: \(skin.radiance)")        // 0-1 (glow)
print("Blemishes: \(skin.blemishes)")      // Count
print("Undertone: \(skin.color.undertone)") // warm/cool/neutral
```

### Eye Analysis (5% of score)

Eye feature and symmetry assessment:

```swift
let eyes = beautyFeatures.eyeAnalysis

print("Eye Shape: \(eyes.shape)")           // almond, round, etc.
print("Symmetry: \(eyes.symmetry)")         // 0-1
print("Iris Visibility: \(eyes.irisVisibility)") // 0-1
print("Eyebrow Arch: \(eyes.eyebrowArch)") // 0-1
```

### Feature-Specific Analysis

```swift
// Nose analysis
let nose = beautyFeatures.noseAnalysis
print("Bridge Width: \(nose.bridgeWidth)")
print("Nostril Symmetry: \(nose.nostrilSymmetry)")

// Mouth analysis
let mouth = beautyFeatures.mouthAnalysis
print("Lip Fullness: \(mouth.lipFullness)")
print("Smile Arc: \(mouth.smileArc)")

// Facial structure
let structure = beautyFeatures.facialStructure
print("Jawline Definition: \(structure.jawlineDefinition)")
print("Chin Shape: \(structure.chinShape)")
```

## Advanced Analysis Techniques

### Batch Processing Multiple Images

```swift
func analyzeBeautyEvolution(images: [URL]) async throws -> [Double] {
    var scores: [Double] = []

    for imageURL in images {
        let data = try Data(contentsOf: imageURL)
        let features = try await VisionProcessor.extractFeatures(from: data)
        let beauty = VisionProcessor.analyzeBeauty(from: features)
        let score = EROSCalculator.calculateEROSS(from: beauty)
        scores.append(score)
    }

    return scores
}
```

### Comparative Analysis

```swift
func compareBeauty(person1Images: [URL], person2Images: [URL]) async throws -> ComparisonResult {
    let person1Scores = try await analyzeBeautyEvolution(images: person1Images)
    let person2Scores = try await analyzeBeautyEvolution(images: person2Images)

    let avg1 = person1Scores.reduce(0, +) / Double(person1Scores.count)
    let avg2 = person2Scores.reduce(0, +) / Double(person2Scores.count)

    return ComparisonResult(
        person1Average: avg1,
        person2Average: avg2,
        difference: avg1 - avg2
    )
}
```

## Longitudinal Beauty Tracking

### Recording Historical Scores

```swift
func recordBeautyOverTime(
    personID: StableID,
    imageURL: URL,
    captureDate: PartialDate
) async throws {
    let data = try Data(contentsOf: imageURL)
    let features = try await VisionProcessor.extractFeatures(from: data)
    let beauty = VisionProcessor.analyzeBeauty(from: features)
    let score = EROSCalculator.calculateEROSS(from: beauty)

    // Create historical claim
    let claim = EROSCalculator.createEROSSClaim(
        score: score,
        for: personID,
        validAt: captureDate
    )

    // Store in museum
    try await museum.storeClaim(claim)
}
```

### Analyzing Beauty Trends

```swift
func analyzeBeautyTrends(personID: StableID) async throws -> BeautyTrends {
    let claims = try await museum.getEROSSClaims(for: personID)

    let scores = claims.sorted { $0.validAt < $1.validAt }
                      .map { ($0.validAt, $0.value.numberValue!) }

    // Calculate trend
    let trend = calculateLinearTrend(scores)

    // Find peaks and valleys
    let peaks = findPeaks(in: scores)
    let valleys = findValleys(in: scores)

    return BeautyTrends(
        currentScore: scores.last?.1 ?? 0,
        trend: trend,
        peaks: peaks,
        valleys: valleys,
        scoreHistory: scores
    )
}
```

## Cultural Adaptations

### Ethnicity-Specific Analysis

```swift
func adaptBeautyStandards(for ethnicity: Ethnicity) -> BeautyStandards {
    switch ethnicity {
    case .caucasian:
        return BeautyStandards(
            idealFaceRatio: 1.618,
            idealEyeSpacing: 0.46,
            skinTonePreference: .neutral
        )
    case .eastAsian:
        return BeautyStandards(
            idealFaceRatio: 1.5,
            idealEyeSpacing: 0.45,
            skinTonePreference: .fair
        )
    case .southAsian:
        return BeautyStandards(
            idealFaceRatio: 1.55,
            idealEyeSpacing: 0.47,
            skinTonePreference: .warm
        )
    }
}
```

## Best Practices

### Image Quality Requirements

- **Resolution**: Minimum 512x512 pixels
- **Lighting**: Even, front-facing illumination
- **Pose**: Neutral expression, direct gaze
- **Angle**: Front-facing (±15° tolerance)
- **Occlusion**: Clear view of facial features

### Interpreting Results

- **Consistency**: Compare scores within similar conditions
- **Context**: Consider age, health, and environmental factors
- **Trends**: Focus on longitudinal changes rather than absolute values
- **Limitations**: AI analysis supplements, doesn't replace, human judgment

### Performance Optimization

```swift
// Cache analysis results
let cache = NSCache<NSString, BeautyFeatures>()

func cachedBeautyAnalysis(for imageData: Data) async throws -> BeautyFeatures {
    let key = NSString(string: SHA256.hash(data: imageData).description)

    if let cached = cache.object(forKey: key) {
        return cached
    }

    let features = try await VisionProcessor.extractFeatures(from: imageData)
    let beauty = VisionProcessor.analyzeBeauty(from: features)

    cache.setObject(beauty, forKey: key)
    return beauty
}
```

## Troubleshooting

### Common Issues

**Low Face Detection Confidence**
- Ensure adequate lighting
- Check image resolution
- Verify face is clearly visible

**Inconsistent Scores**
- Compare images taken under similar conditions
- Account for makeup, hairstyle changes
- Consider time of day and health factors

**Poor Symmetry Scores**
- Check for image distortion
- Ensure neutral facial expression
- Verify camera was level

### Advanced Debugging

```swift
// Enable detailed logging
VisionProcessor.enableDebugLogging = true

// Inspect individual components
let beauty = VisionProcessor.analyzeBeauty(from: features)
print("Facial Ratios Score: \(beauty.facialRatios.overallScore)")
print("Symmetry Score: \(beauty.symmetry.overallScore)")
print("Skin Quality: \(beauty.skinAnalysis.overallQuality)")

// Validate landmark detection
if features.faces.isEmpty {
    print("No faces detected - check image quality")
}
```

This guide provides a comprehensive foundation for implementing beauty analysis with Musee's EROSS system. The framework is designed to be extensible, allowing for custom beauty standards and additional analysis components as research advances.