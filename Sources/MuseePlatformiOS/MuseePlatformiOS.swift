import UIKit
import PhotosUI
import MuseePlatform

/// iOS-specific image picker using PHPickerViewController
public struct iOSImagePicker: ImagePicker {
    public init() {}

    public func pickImage(completion: @escaping (Data?) -> Void) {
        let configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        let delegate = ImagePickerDelegate(completion: completion)
        picker.delegate = delegate
        // Present the picker
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

/// iOS-specific file manager
public struct iOSFileManager: PlatformFileManager {
    public init() {}
    public func saveFile(data: Data, filename: String, completion: @escaping (URL?) -> Void) {
        // For iOS, saving files typically uses share sheet or document picker
        // For simplicity, save to documents directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            completion(fileURL)
        } catch {
            completion(nil)
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

/// iOS-specific content sharer using UIActivityViewController
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

/// iOS-specific notification center
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

/// iOS-specific haptic engine
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

/// iOS-specific camera controller
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