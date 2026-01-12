//
//  MuseePlatform.swift
//  MuseePlatform
//
//  Platform abstraction protocols for museum applications.
//  Defines common interfaces that platform-specific implementations fulfill.
//
//  Usage:
//  ```
//  import MuseePlatform
//
//  // Platform-specific implementations handle the details
//  let picker = PlatformImagePicker()
//  ```
//

import Foundation

/// Protocol for image picker functionality across platforms
public protocol ImagePicker {
    func pickImage(completion: @escaping (Data?) -> Void)
}

/// Protocol for file operations
public protocol FileManager {
    func saveFile(data: Data, filename: String, completion: @escaping (URL?) -> Void)
    func loadFile(url: URL, completion: @escaping (Data?) -> Void)
}

/// Protocol for sharing content
public protocol ContentSharer {
    func share(data: Data, filename: String)
}

/// Protocol for notifications
public protocol NotificationCenter {
    func schedule(title: String, body: String, at date: Date)
}

/// Protocol for haptic feedback
public protocol HapticEngine {
    func success()
    func error()
    func warning()
}

/// Protocol for camera access
public protocol CameraController {
    func capturePhoto(completion: @escaping (Data?) -> Void)
}

/// Type-erased platform-specific implementations
public struct PlatformImagePicker {
    private let implementation: ImagePicker

    public init() {
        #if canImport(AppKit)
        implementation = MacOSImagePicker()
        #elseif canImport(UIKit)
        implementation = iOSImagePicker()
        #else
        implementation = StubImagePicker()
        #endif
    }

    public func pickImage(completion: @escaping (Data?) -> Void) {
        implementation.pickImage(completion: completion)
    }
}

// Stub implementations for unsupported platforms
private struct StubImagePicker: ImagePicker {
    func pickImage(completion: @escaping (Data?) -> Void) {
        completion(nil)
    }
}

#if canImport(AppKit)
private struct MacOSImagePicker: ImagePicker {
    func pickImage(completion: @escaping (Data?) -> Void) {
        // Implementation would use NSOpenPanel
        completion(nil)
    }
}
#endif

#if canImport(UIKit)
private struct iOSImagePicker: ImagePicker {
    func pickImage(completion: @escaping (Data?) -> Void) {
        // Implementation would use PHPickerViewController
        completion(nil)
    }
}
#endif