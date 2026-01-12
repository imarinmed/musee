# MuseeKit

MuseeKit is a comprehensive Swift framework for building museum applications across all Apple platforms. It provides a unified API for beauty analysis, museum organization, and cross-platform UI components.

## Features

- **Multi-platform support**: iOS, macOS, tvOS, watchOS, visionOS
- **Beauty analysis**: AI-powered facial feature analysis using Vision framework
- **Museum organization**: Hierarchical storage with wings, exhibits, and bundles
- **Content-addressed storage**: Immutable asset storage with SHA-256 hashing
- **Cross-platform UI**: Shared SwiftUI components with platform-specific adaptations
- **Search & discovery**: Advanced faceted search across museum collections

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourorg/MuseeKit.git", from: "1.0.0")
]
```

Or add to your Xcode project:
1. File → Add Packages...
2. Enter `https://github.com/yourorg/MuseeKit.git`
3. Select the version you want

## Usage

### Basic Setup

```swift
import MuseeKit

// Initialize the framework
MuseeKit.initialize()

// Create a museum library
let library = MuseumLibrary()

// Load a museum from disk
let museum = try await library.loadMuseum(from: url)
```

### Beauty Analysis

```swift
import MuseeKit

let analyzer = BeautyAnalyzer()

// Analyze an image
let results = try await analyzer.analyze(imageData: imageData)
// Results include EROSS score, facial landmarks, etc.
```

### SwiftUI Components

```swift
import MuseeUI

struct MyView: View {
    var body: some View {
        MuseumCard {
            VStack {
                Text("Beautiful Artwork")
                MuseumLoadingView()
            }
        }
        .glassBackground() // macOS glass effect
    }
}
```

## Platform-Specific Features

```swift
import MuseePlatformMac

// macOS-specific image picker
let picker = PlatformImagePicker()
picker.pickImage { data in
    // Handle selected image
}
```

## Architecture

MuseeKit follows a modular architecture:

- **MuseeKit**: Main facade with unified imports
- **MuseeCore**: Fundamental types and error handling
- **MuseeDomain**: Core business models (Person, MediaAsset, etc.)
- **MuseeCAS**: Content-addressed storage
- **MuseeBundle**: Bundle format for museum data
- **MuseeMuseum**: Museum organization and management
- **MuseeMetadata**: Metadata extraction and processing
- **MuseeVision**: Computer vision and beauty analysis
- **MuseeSearch**: Search and discovery functionality
- **MuseeUI**: Shared SwiftUI components
- **MuseePlatform**: Platform abstraction protocols
- **MuseePlatformMac**: macOS-specific implementations

## Requirements

- Swift 6.0+
- Xcode 16.0+
- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+ / visionOS 1.0+

## Documentation

Full API documentation is available in DocC format. Open `Musee.doccarchive` in Xcode or view online.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MuseeKit is available under the MIT license. See LICENSE for details.