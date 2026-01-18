import Foundation

#if canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
#endif

#if canImport(UIKit)
import UIKit
import PhotosUI
#endif

/// Protocol for image picker functionality across platforms
public protocol ImagePicker {
    @MainActor func pickImage(completion: @escaping (Data?) -> Void)
}

/// Protocol for file operations
public protocol PlatformFileManager {
    @MainActor func saveFile(data: Data, filename: String, completion: @escaping (URL?) -> Void)
    @MainActor func loadFile(url: URL, completion: @escaping (Data?) -> Void)
}

/// Protocol for sharing content
public protocol PlatformContentSharer {
    func share(data: Data, filename: String)
}

/// Protocol for notifications
public protocol PlatformNotificationCenter {
    func schedule(title: String, body: String, at date: Date)
}

/// Protocol for haptic feedback
public protocol PlatformHapticEngine {
    func success()
    func error()
    func warning()
}

/// Protocol for camera access
public protocol PlatformCameraController {
    func capturePhoto(completion: @escaping (Data?) -> Void)
}

// Private platform-specific implementations
private struct StubImagePicker: ImagePicker {
    func pickImage(completion: @escaping (Data?) -> Void) {
        completion(nil)
    }
}

#if canImport(AppKit)
private struct MacOSImagePicker: ImagePicker {
    @MainActor func pickImage(completion: @escaping (Data?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.image]
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
#endif

#if canImport(UIKit)
private struct iOSImagePicker: ImagePicker {
    func pickImage(completion: @escaping (Data?) -> Void) {
        let configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        let delegate = ImagePickerDelegate(completion: completion)
        picker.delegate = delegate
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(picker, animated: true)
        } else {
            completion(nil)
        }
    }
}

private class ImagePickerDelegate: NSObject, PHPickerViewControllerDelegate {
    let completion: (Data?) -> Void
    init(completion: @escaping (Data?) -> Void) {
        self.completion = completion
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else {
            completion(nil)
            return
        }
        result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
            if let image = object as? UIImage, let data = image.pngData() {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
}
#endif

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

    @MainActor public func pickImage(completion: @escaping (Data?) -> Void) {
        implementation.pickImage(completion: completion)
    }
}

#if canImport(AppKit)
public struct MacOSFileManager: PlatformFileManager {
    public init() {}
    @MainActor public func saveFile(data: Data, filename: String, completion: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.image]
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
    @MainActor public func loadFile(url: URL, completion: @escaping (Data?) -> Void) {
        do {
            let data = try Data(contentsOf: url)
            completion(data)
        } catch {
            completion(nil)
        }
    }
}

public struct MacOSContentSharer: PlatformContentSharer {
    public init() {}
    public func share(data: Data, filename: String) {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(filename)
        do {
            try data.write(to: tempURL)
            let sharingService = NSSharingService(named: NSSharingService.Name.composeEmail)
            sharingService?.perform(withItems: [tempURL])
        } catch {
            // Handle error
        }
    }
}

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

public struct MacOSCameraController: PlatformCameraController {
    public init() {}
    public func capturePhoto(completion: @escaping (Data?) -> Void) {
        // macOS camera access requires AVFoundation, not implemented
        completion(nil)
    }
}
#endif

#if canImport(UIKit)
public struct iOSFileManager: PlatformFileManager {
    public init() {}
    public func saveFile(data: Data, filename: String, completion: @escaping (URL?) -> Void) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            completion(fileURL)
        } catch {
            completion(nil)
        }
    }
    @MainActor public func loadFile(url: URL, completion: @escaping (Data?) -> Void) {
        do {
            let data = try Data(contentsOf: url)
            completion(data)
        } catch {
            completion(nil)
        }
    }
}

public struct iOSContentSharer: PlatformContentSharer {
    public init() {}
    public func share(data: Data, filename: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            // Handle error
        }
    }
}

public struct iOSNotificationCenter: PlatformNotificationCenter {
    public init() {}
    public func schedule(title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

public struct iOSHapticEngine: PlatformHapticEngine {
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    public init() {
        feedbackGenerator.prepare()
    }
    public func success() {
        feedbackGenerator.notificationOccurred(.success)
    }
    public func error() {
        feedbackGenerator.notificationOccurred(.error)
    }
    public func warning() {
        feedbackGenerator.notificationOccurred(.warning)
    }
}

public struct iOSCameraController: PlatformCameraController {
    public init() {}
    public func capturePhoto(completion: @escaping (Data?) -> Void) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = CameraDelegate(completion: completion)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(picker, animated: true)
            } else {
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
}

private class CameraDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let completion: (Data?) -> Void
    init(completion: @escaping (Data?) -> Void) {
        self.completion = completion
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage, let data = image.pngData() {
            completion(data)
        } else {
            completion(nil)
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        completion(nil)
    }
}
#endif