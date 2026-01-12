//
//  MuseeKit.swift
//  MuseeKit
//
//  Main facade for the Musee framework.
//  Provides unified access to museum functionality across all platforms.
//
//  Usage:
//  ```
//  import MuseeKit
//
//  let museum = MuseumLibrary()
//  let search = FacetedSearchQuery()
//  ```
//

// MARK: - Core Domain Types
@_exported import MuseeCore
@_exported import MuseeDomain

// MARK: - Storage & Persistence
@_exported import MuseeCAS
@_exported import MuseeBundle

// MARK: - Museum Organization
@_exported import MuseeMuseum

// MARK: - Metadata & Analysis
@_exported import MuseeMetadata
@_exported import MuseeVision

// MARK: - Search & Discovery
@_exported import MuseeSearch

/// The main MuseeKit facade providing high-level APIs for museum applications.
///
/// This is the primary entry point for building museum experiences.
/// For platform-specific UI components, also import the appropriate platform module:
/// - `MuseeUI` for shared SwiftUI components
/// - `MuseePlatformMac` for macOS-specific functionality
public enum MuseeKit {
    /// Version information for the MuseeKit framework
    public static let version = "1.0.0"

    /// Initialize the framework with default settings.
    /// This sets up any global state needed by the framework.
    public static func initialize() {
        // Framework initialization logic can go here
        // Currently, MuseeKit is stateless and initialization-free
    }
}