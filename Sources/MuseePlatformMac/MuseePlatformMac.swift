//
//  MuseePlatformMac.swift
//  MuseePlatformMac
//
//  macOS-specific implementations of platform abstractions.
//  Provides concrete implementations for macOS APIs.
//
//  Usage:
//  ```
//  import MuseePlatformMac
//
//  // macOS-specific functionality
//  let window = BlurWindow()
//  ```
//

import SwiftUI
import AppKit
import MuseePlatform

/// macOS-specific image picker using NSOpenPanel
public struct MacOSImagePicker: ImagePicker {
    public init() {}

    public func pickImage(completion: @escaping (Data?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "gif", "tiff", "bmp"]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let data = try Data(contentsOf: url)
                    completion(data)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
}

/// macOS-specific file manager
public struct MacOSFileManager: MuseePlatform.PlatformFileManager {
    public init() {}

    public func saveFile(data: Data, filename: String, completion: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "gif", "tiff", "bmp"]
        panel.nameFieldStringValue = filename

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try data.write(to: url)
                    completion(url)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    public func loadFile(url: URL, completion: @escaping (Data?) -> Void) {
        do {
            let data = try Data(contentsOf: url)
            completion(data)
        } catch {
            completion(nil)
        }
    }
}

/// macOS-specific content sharer using NSSharingService
public struct MacOSContentSharer: PlatformContentSharer {
    public init() {}

    public func share(data: Data, filename: String) {
        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL)
            let sharingService = NSSharingService(named: .composeEmail)
            sharingService?.perform(withItems: [tempURL])
        } catch {
            // Handle error
        }
    }
}

/// macOS-specific notification center
public struct MacOSNotificationCenter: PlatformNotificationCenter {
    public init() {}

    public func schedule(title: String, body: String, at date: Date) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.deliveryDate = date
        NSUserNotificationCenter.default.scheduleNotification(notification)
    }
}

/// macOS-specific haptic engine (limited support)
public struct MacOSHapticEngine: PlatformHapticEngine {
    public init() {}

    public func success() {
        NSSound(named: "Tink")?.play()
    }

    public func error() {
        NSSound(named: "Basso")?.play()
    }

    public func warning() {
        NSSound(named: "Funk")?.play()
    }
}

/// macOS-specific camera controller
public struct MacOSCameraController: PlatformCameraController {
    public init() {}

    public func capturePhoto(completion: @escaping (Data?) -> Void) {
        // macOS camera access is more complex, would require AVFoundation
        // For now, return nil
        completion(nil)
    }
}

/// macOS-specific window with blur effects
public struct BlurWindow: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

/// SwiftUI modifier for macOS glass effects
public extension View {
    func glassSidebar() -> some View {
        self.background(BlurWindow())
    }

    func glassBackground() -> some View {
        self.background(BlurWindow())
    }

    func glassCard() -> some View {
        self.background(BlurWindow())
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}