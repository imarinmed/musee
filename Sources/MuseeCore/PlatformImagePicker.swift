import Foundation
import SwiftUI

// MARK: - Platform-Agnostic Image Picker Protocol

@MainActor
public protocol ImagePickerDelegate: AnyObject {
    func imagePickerDidSelectImage(_ image: PlatformImage, url: URL)
    func imagePickerDidCancel()
}

// MARK: - Image Picker Configuration

public struct ImagePickerConfiguration {
    public var allowedTypes: [String] = ["png", "jpg", "jpeg", "heic"]
    public var allowsMultipleSelection: Bool = false
    public var title: String = "Select Image"
    
    public init(allowedTypes: [String] = ["png", "jpg", "jpeg", "heic"],
                allowsMultipleSelection: Bool = false,
                title: String = "Select Image") {
        self.allowedTypes = allowedTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.title = title
    }
}

#if canImport(UIKit)
import UIKit
import PhotosUI
#endif

@MainActor
public class PlatformImagePicker: NSObject {
    
    public weak var delegate: ImagePickerDelegate?
    private var configuration: ImagePickerConfiguration
    
    #if canImport(UIKit)
    private var picker: UIImagePickerController?
    private var phpicker: PHPickerViewController?
    #endif
    
    public init(configuration: ImagePickerConfiguration = .init()) {
        self.configuration = configuration
        super.init()
    }
    
    public func present() {
        #if canImport(AppKit)
        presentMacOSImagePicker()
        #elseif canImport(UIKit)
        presentiOSImagePicker()
        #endif
    }
    
    // MARK: - macOS Implementation
    
    #if canImport(AppKit)
    @MainActor
    private func presentMacOSImagePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = configuration.allowedTypes.map { UTType(filenameExtension: $0, conformingTo: .image) }.compactMap { $0 }
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = configuration.allowsMultipleSelection
        panel.title = configuration.title
        panel.prompt = "Select"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = PlatformImage.from(url: url) {
                delegate?.imagePickerDidSelectImage(image, url: url)
            }
        } else {
            delegate?.imagePickerDidCancel()
        }
    }
    #endif
    
    // MARK: - iOS Implementation
    
    #if canImport(UIKit)
    @MainActor
    private func presentiOSImagePicker() {
        if #available(iOS 14.0, *) {
            presentPHPicker()
        } else {
            presentLegacyImagePicker()
        }
    }
    
    @available(iOS 14.0, *)
    @MainActor
    private func presentPHPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = configuration.allowsMultipleSelection ? 0 : 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        self.phpicker = picker
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(picker, animated: true)
        }
    }
    
    @MainActor
    private func presentLegacyImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        self.picker = picker
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(picker, animated: true)
        }
    }
}
#endif

// MARK: - PHPickerViewController Delegate

#if canImport(UIKit)
@available(iOS 14.0, *)
extension PlatformImagePicker: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else {
            delegate?.imagePickerDidCancel()
            return
        }
        
        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let uiImage = object as? UIImage, let url = self?.createTempURL(for: uiImage) {
                    self?.delegate?.imagePickerDidSelectImage(uiImage, url: url)
                } else {
                    self?.delegate?.imagePickerDidCancel()
                }
            }
        } else {
            delegate?.imagePickerDidCancel()
        }
    }
    
    private func createTempURL(for image: UIImage) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "image_\(Date().timeIntervalSince1970).png"
        let url = tempDir.appendingPathComponent(filename)
        
        if let data = image.pngData() {
            try? data.write(to: url)
        }
        
        return url
    }
}

// MARK: - UIImagePickerController Delegate

extension PlatformImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage,
           let url = info[.imageURL] as? URL {
            delegate?.imagePickerDidSelectImage(image, url: url)
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        delegate?.imagePickerDidCancel()
    }
}
#endif

// MARK: - SwiftUI Wrapper

@MainActor
public struct ImagePickerView: View {
    public let configuration: ImagePickerConfiguration
    public var onImageSelected: (PlatformImage, URL) -> Void
    public var onCancelled: () -> Void
    
    public init(configuration: ImagePickerConfiguration = .init(),
                onImageSelected: @escaping (PlatformImage, URL) -> Void,
                onCancelled: @escaping () -> Void) {
        self.configuration = configuration
        self.onImageSelected = onImageSelected
        self.onCancelled = onCancelled
    }
    
    public var body: some View {
        EmptyView()
            .onAppear {
                presentPicker()
            }
    }
    
    @MainActor
    private func presentPicker() {
        let picker = PlatformImagePicker(configuration: configuration)
        let delegate = ImagePickerDelegateWrapper(
            onImageSelected: onImageSelected,
            onCancelled: onCancelled
        )
        picker.delegate = delegate
        picker.present()
    }
    
    private class ImagePickerDelegateWrapper: NSObject, ImagePickerDelegate {
        let onImageSelected: (PlatformImage, URL) -> Void
        let onCancelled: () -> Void
        
        init(onImageSelected: @escaping (PlatformImage, URL) -> Void,
             onCancelled: @escaping () -> Void) {
            self.onImageSelected = onImageSelected
            self.onCancelled = onCancelled
        }
        
        func imagePickerDidSelectImage(_ image: PlatformImage, url: URL) {
            onImageSelected(image, url)
        }
        
        func imagePickerDidCancel() {
            onCancelled()
        }
    }
}
