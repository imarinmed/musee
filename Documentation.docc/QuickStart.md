# Quick Start

## Creating Your First Museum

```swift
import MuseeMuseum

// Create a new museum
let museumURL = URL(fileURLWithPath: "/path/to/my.museum")
let wings = [
    MuseumIndex.Wing(id: StableID("photos"), name: "Photos", description: "Photo collection"),
    MuseumIndex.Wing(id: StableID("videos"), name: "Videos", description: "Video collection")
]

let library = try MuseumLibrary.createNew(at: museumURL, wings: wings)

// Install a bundle
let bundle = MuseeBundle(bundleURL: URL(fileURLWithPath: "/path/to/bundle.musee"))
try library.install(bundle: bundle, intoWing: wings[0].id)
```

## Analyzing Beauty with EROSS

```swift
import MuseeVision

// Extract vision features
let imageData = Data() // Your image data
let features = try await VisionProcessor.extractFeatures(from: imageData)

// Calculate beauty score
let beauty = VisionProcessor.analyzeBeauty(from: features)
let erossScore = EROSCalculator.calculateEROSS(from: beauty)

// Create claim
let claim = EROSCalculator.createEROSSClaim(score: erossScore, for: personID, validAt: date)
```