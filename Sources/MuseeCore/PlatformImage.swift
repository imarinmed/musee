import Foundation
import SwiftUI

// MARK: - Platform-Agnostic Image Abstraction

#if canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#endif

// MARK: - PlatformImage Extensions

public extension PlatformImage {
    /// Initialize from data (works on both platforms)
    static func from(data: Data) -> PlatformImage? {
        #if canImport(AppKit)
        return NSImage(data: data)
        #elseif canImport(UIKit)
        return UIImage(data: data)
        #endif
    }
    
    /// Initialize from URL
    static func from(url: URL) -> PlatformImage? {
        #if canImport(AppKit)
        return NSImage(contentsOf: url)
        #elseif canImport(UIKit)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
        #endif
    }
    
    /// Convert image to PNG data
    func pngData() -> Data? {
        #if canImport(AppKit)
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #elseif canImport(UIKit)
        return self.pngData()
        #endif
    }
    
    /// Convert image to JPEG data
    func jpegData(compressionQuality: CGFloat = 0.9) -> Data? {
        #if canImport(AppKit)
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #elseif canImport(UIKit)
        return self.jpegData(compressionQuality: compressionQuality)
        #endif
    }
    
    /// Resize image to target size
    func resized(to size: CGSize) -> PlatformImage? {
        #if canImport(AppKit)
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: size))
        resizedImage.unlockFocus()
        return resizedImage
        #elseif canImport(UIKit)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
        #endif
    }
}

// MARK: - SwiftUI Image Compatibility

extension Image {
    /// Create SwiftUI Image from PlatformImage
    init(platformImage: PlatformImage) {
        #if canImport(AppKit)
        self.init(nsImage: platformImage)
        #elseif canImport(UIKit)
        self.init(uiImage: platformImage)
        #endif
    }
}

// MARK: - Platform-Specific Extensions

#if canImport(AppKit)
public extension NSImage {
    var cgImage: CGImage? {
        self.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    func size(in size: CGSize) -> CGSize {
        let aspectRatio = self.size.width / self.size.height
        if size.width / size.height > aspectRatio {
            let width = size.height * aspectRatio
            return CGSize(width: width, height: size.height)
        } else {
            let height = size.width / aspectRatio
            return CGSize(width: size.width, height: height)
        }
    }
}
#endif
