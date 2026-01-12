# MuseeKit Cross-Platform Implementation Guide

## Overview

MuseeKit now supports multiple Apple platforms (macOS, iOS, tvOS, visionOS, watchOS) using platform-agnostic abstractions. This guide explains how to use the cross-platform patterns we've implemented.

---

## What We've Done

### 1. Created Platform Abstractions in `MuseeCore`

#### Platform-agnostic Types
- **`PlatformImage`** - Unified image type (NSImage on macOS, UIImage on iOS)
- **`PlatformImagePicker`** - Image selection (NSOpenPanel on macOS, UIImagePickerController on iOS)
- **`PlatformVisualEffectView`** - Glass/blur effects (NSVisualEffectView on macOS, UIVisualEffectView on iOS)

### 2. Files Added

```
museekit/Sources/MuseeCore/
├── PlatformImage.swift          # Image type abstraction + extensions
├── PlatformImagePicker.swift     # Image picker abstraction + SwiftUI wrapper
└── PlatformVisualEffect.swift    # Visual effects abstraction + view modifiers
```

### 3. Refactored Code

**Before:**
```swift
// MuseeMacApp.swift - macOS-specific
@State private var selectedImage: NSImage?

let panel = NSOpenPanel()
panel.runModal()
selectedImage = NSImage(contentsOf: url)

// VisualEffectBlur - macOS-only
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    // macOS implementation only
}
```

**After:**
```swift
// Platform-agnostic
@State private var selectedImage: PlatformImage?
@State private var showImagePicker = false

Button("Select Image") { showImagePicker = true }
    .sheet(isPresented: $showImagePicker) {
        ImagePickerView { image, url in
            selectedImage = image
            analyzeImage(at: url)
        } onCancelled: { }
    }

// Visual effects
.glassBackground()     // Uses platform-appropriate blur
.glassSidebar()        // Platform-appropriate material
.glassCard()           // Glass morphism card effect
```

---

## Usage Examples

### 1. Using PlatformImage

```swift
import MuseeCore

// Load image from data
let imageData = try Data(contentsOf: url)
let image = PlatformImage.from(data: imageData)

// Load image from URL
let image = PlatformImage.from(url: url)

// Display in SwiftUI
Image(platformImage: image)
    .resizable()
    .scaledToFit()

// Convert to data
let pngData = image.pngData()
let jpegData = image.jpegData(compressionQuality: 0.9)

// Resize
let resized = image.resized(to: CGSize(width: 200, height: 200))
```

### 2. Using PlatformImagePicker

```swift
import SwiftUI
import MuseeCore

struct MyView: View {
    @State private var selectedImage: PlatformImage?
    @State private var showImagePicker = false
    
    var body: some View {
        Button("Select Image") {
            showImagePicker = true
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                configuration: .init(
                    allowedTypes: ["png", "jpg", "jpeg", "heic"],
                    allowsMultipleSelection: false
                )
            ) { image, url in
                selectedImage = image
                showImagePicker = false
            } onCancelled: {
                showImagePicker = false
            }
        }
        
        if let image = selectedImage {
            Image(platformImage: image)
                .resizable()
                .scaledToFit()
        }
    }
}
```

### 3. Using Platform Visual Effects

```swift
import SwiftUI
import MuseeCore

struct GlassCardView: View {
    var body: some View {
        VStack {
            Text("Content")
        }
        .glassCard()  // Applies glass morphism
        .padding()
        .glassBackground()  // Full background blur
    }
}

struct SidebarView: View {
    var body: some View {
        List {
            // Items
        }
        .glassSidebar()  // Sidebar material
    }
}
```

---

## Platform-Specific Files

### MuseeMac (macOS)
- Uses `NavigationSplitView` for master-detail
- Uses `WindowGroup` for multiple windows
- Uses `.glassSidebar()` and `.glassBackground()` modifiers

### MuseeiOS (iOS)
- Uses `TabView` for navigation
- Camera integration for live beauty analysis
- Same glass effects work automatically

### MuseeGUI (Cross-platform)
- Uses shared components from MuseeCore
- Works on both macOS and iOS

---

## Benefits

### 1. Code Reusability
- Write once, use on multiple platforms
- Shared ViewModels and business logic
- Unified API surface

### 2. Type Safety
- Compile-time platform checks
- Platform-specific extensions are isolated
- No runtime crashes from wrong API usage

### 3. Maintainability
- Changes to business logic propagate automatically
- Platform-specific code is isolated
- Easy to add new platforms

### 4. Performance
- No abstractions that hurt performance
- Direct platform API usage under the hood
- Compile-time optimizations

---

## Migrating Existing Code

### Step 1: Replace NSImage with PlatformImage

```swift
// Before
import AppKit
@State private var image: NSImage?

// After
import MuseeCore
@State private var image: PlatformImage?
```

### Step 2: Replace NSOpenPanel with PlatformImagePicker

```swift
// Before
let panel = NSOpenPanel()
panel.allowedFileTypes = ["png", "jpg"]
if panel.runModal() == .OK {
    let image = NSImage(contentsOf: panel.url)
}

// After
.sheet(isPresented: $showPicker) {
    ImagePickerView { image, url in
        // Handle selection
    } onCancelled: { }
}
```

### Step 3: Replace VisualEffectBlur with platform-agnostic modifiers

```swift
// Before
.background(VisualEffectBlur(material: .sidebar))

// After
.glassSidebar()
```

---

## Testing Cross-Platform Code

### Unit Tests
```swift
import XCTest
@testable import MuseeCore

final class PlatformImageTests: XCTestCase {
    func testImageFromData() {
        let imageData = Data() // Your test data
        let image = PlatformImage.from(data: imageData)
        XCTAssertNotNil(image)
    }
}
```

### Platform-Specific Tests
```swift
#if canImport(AppKit)
@testable import AppKit

final class MacOSTests: XCTestCase {
    func testNSImageExtension() {
        let image = NSImage(size: NSSize(width: 100, height: 100))
        let resized = image.resized(to: CGSize(width: 50, height: 50))
        XCTAssertEqual(resized?.size, NSSize(width: 50, height: 50))
    }
}
#endif
```

---

## Next Steps for MuseeKit

### 1. Complete the Migration
- [ ] Replace all remaining `NSImage` with `PlatformImage`
- [ ] Replace all remaining `NSOpenPanel` with `PlatformImagePicker`
- [ ] Replace all remaining `VisualEffectBlur` with platform-agnostic modifiers

### 2. Add More Platform Abstractions
Consider adding:
- **PlatformFileBrowser** - For file/directory selection
- **PlatformNotifications** - For notifications across platforms
- **PlatformSharing** - For share sheet functionality
- **PlatformCamera** - For camera access (iOS/macOS camera app)

### 3. Optimize for Specific Platforms
- macOS: Multi-window support, toolbar, menu bar integration
- iOS: Tab-based navigation, camera integration, haptic feedback
- visionOS: Spatial UI, 3D interactions, hand tracking
- watchOS: Complications, quick actions, glanceable UI

### 4. Add visionOS Support
```swift
#if os(visionOS)
// Use spatial UI patterns
struct VisionOSSpecificView: View {
    var body: some View {
        ZStack {
            // 3D scene
            RealityView { content in
                // Add 3D content
            }
        }
        .glassBackground()
    }
}
#endif
```

### 5. Add Platform-Specific Features
```swift
// macOS-specific
#if os(macOS)
import AppKit

extension View {
    func onWindowClose(perform action: @escaping () -> Void) -> some View {
        // macOS window handling
    }
}
#endif

// iOS-specific
#if os(iOS)
import UIKit

extension View {
    func withHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) -> some View {
        // iOS haptic feedback
    }
}
#endif
```

---

## Architecture Pattern

We used the **Protocol + Conditional Compilation** pattern:

1. **Define Protocol** (Platform-agnostic)
   ```swift
   protocol ImagePickerDelegate: AnyObject {
       func imagePickerDidSelectImage(_ image: PlatformImage, url: URL)
   }
   ```

2. **Typealias to Platform Type** (Conditional)
   ```swift
   #if canImport(AppKit)
   import AppKit
   public typealias PlatformImage = NSImage
   #elseif canImport(UIKit)
   import UIKit
   public typealias PlatformImage = UIImage
   #endif
   ```

3. **Extend Platform Type** (Conditional)
   ```swift
   #if canImport(AppKit)
   public extension NSImage {
       func pngData() -> Data? {
           // macOS implementation
       }
   }
   #endif
   ```

4. **Create SwiftUI Wrapper** (Platform-agnostic)
   ```swift
   public struct ImagePickerView: View {
       // Uses PlatformImagePicker internally
       // Works on all platforms
   }
   ```

---

## Resources

### Official Documentation
- [Swift.org - Conditional Compilation](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html#ID553)
- [SwiftUI - AppKit/UIKit Integration](https://developer.apple.com/documentation/swiftui)
- [Apple - Building Multiplatform Apps](https://developer.apple.com/documentation/Xcode/building-a-multi-platform-app)

### Real-World Examples
- [Realm Swift - Cross-Platform Storage](https://github.com/realm/realm-swift)
- [Square Valet - Secure Storage](https://github.com/square/Valet)

---

## Contact

For questions or issues, refer to this guide and the source code in:
- `museekit/Sources/MuseeCore/PlatformImage.swift`
- `museekit/Sources/MuseeCore/PlatformImagePicker.swift`
- `museekit/Sources/MuseeCore/PlatformVisualEffect.swift`

---

*Last Updated: January 12, 2026*
