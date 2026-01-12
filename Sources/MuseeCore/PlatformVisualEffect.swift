import Foundation
import SwiftUI

// MARK: - Platform-Agnostic Visual Effect Material

public enum VisualEffectMaterial: String, CaseIterable {
    case sidebar
    case menu
    case header
    case popover
    case hud
    case fullScreen
    case toolTip
    case contentBackground
    case underWindowBackground
    case windowBackground
    
    #if canImport(AppKit)
    @available(macOS 10.14, *)
    var nsMaterial: NSVisualEffectView.Material {
        switch self {
        case .sidebar: return .sidebar
        case .menu: return .menu
        case .header: return .headerView
        case .popover: return .popover
        case .hud: return .hudWindow
        case .fullScreen: return .fullScreenUI
        case .toolTip: return .toolTip
        case .contentBackground: return .contentBackground
        case .underWindowBackground: return .underWindowBackground
        case .windowBackground: return .windowBackground
        }
    }
    #endif
    
    #if canImport(UIKit)
    @available(iOS 13.0, *)
    var uiMaterial: UIBlurEffect.Style {
        switch self {
        case .sidebar, .menu: return .systemMaterial
        case .header: return .systemThinMaterial
        case .popover: return .systemMaterial
        case .hud: return .systemThickMaterial
        case .fullScreen: return .systemChromeMaterial
        case .toolTip: return .systemUltraThinMaterial
        case .contentBackground: return .systemMaterial
        case .underWindowBackground: return .systemMaterial
        case .windowBackground: return .systemMaterial
        }
    }
    #endif
}

// MARK: - Blending Mode

public enum VisualEffectBlendingMode {
    case withinWindow
    case behindWindow
}

// MARK: - Platform Visual Effect View

public struct PlatformVisualEffectView: View {
    public let material: VisualEffectMaterial
    public let blendingMode: VisualEffectBlendingMode
    public let opacity: Double
    
    public init(
        material: VisualEffectMaterial = .sidebar,
        blendingMode: VisualEffectBlendingMode = .withinWindow,
        opacity: Double = 1.0
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.opacity = opacity
    }
    
    public var body: some View {
        #if canImport(AppKit)
        MacOSSafariBlur(
            material: material,
            blendingMode: blendingMode,
            opacity: opacity
        )
        #elseif canImport(UIKit)
        iOSVisualEffectView(
            material: material,
            blendingMode: blendingMode,
            opacity: opacity
        )
        #endif
    }
}

// MARK: - macOS Implementation

#if canImport(AppKit)
import AppKit

@available(macOS 10.14, *)
struct MacOSSafariBlur: NSViewRepresentable {
    let material: VisualEffectMaterial
    let blendingMode: VisualEffectBlendingMode
    let opacity: Double
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        updateNSView(view, context: context)
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material.nsMaterial
        nsView.blendingMode = {
            switch blendingMode {
            case .withinWindow: return .withinWindow
            case .behindWindow: return .behindWindow
            }
        }()
        nsView.state = .active
        nsView.alphaValue = opacity
    }
}
#endif

// MARK: - iOS Implementation

#if canImport(UIKit)
import UIKit

@available(iOS 13.0, *)
struct iOSVisualEffectView: UIViewRepresentable {
    let material: VisualEffectMaterial
    let blendingMode: VisualEffectBlendingMode
    let opacity: Double
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        updateUIView(view, context: context)
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: material.uiMaterial)
        uiView.alpha = opacity
    }
}
#endif

// MARK: - Convenience View Modifiers

public extension View {
    /// Apply a glass blur effect
    func glassBlur(material: VisualEffectMaterial = .sidebar,
                   blendingMode: VisualEffectBlendingMode = .withinWindow,
                   opacity: Double = 1.0) -> some View {
        self.background(
            PlatformVisualEffectView(
                material: material,
                blendingMode: blendingMode,
                opacity: opacity
            )
        )
    }
    
    /// Apply a glass sidebar effect
    func glassSidebar(opacity: Double = 0.9) -> some View {
        self.glassBlur(material: .sidebar, blendingMode: .withinWindow, opacity: opacity)
    }
    
    /// Apply a glass background effect
    func glassBackground(material: VisualEffectMaterial = .sidebar,
                         opacity: Double = 0.8) -> some View {
        self.glassBlur(material: material, opacity: opacity)
    }
    
    /// Apply a glass card effect
    func glassCard(opacity: Double = 0.9) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(opacity)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
