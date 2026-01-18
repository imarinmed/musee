// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Musee",
    platforms: [
        .macOS(.v26), .iOS(.v26), .tvOS(.v26), .visionOS(.v26), .watchOS(.v26),
    ],
    products: [
        // Core modules (internal building blocks)
        .library(name: "MuseeCore", targets: ["MuseeCore"]),
        .library(name: "MuseeDomain", targets: ["MuseeDomain"]),
        .library(name: "MuseeCAS", targets: ["MuseeCAS"]),
        .library(name: "MuseeBundle", targets: ["MuseeBundle"]),
        .library(name: "MuseeMuseum", targets: ["MuseeMuseum"]),
        .library(name: "MuseeMetadata", targets: ["MuseeMetadata"]),
        .library(name: "MuseeSearch", targets: ["MuseeSearch"]),
        .library(name: "MuseeVision", targets: ["MuseeVision"]),
        .library(name: "MuseeScraper", targets: ["MuseeScraper"]),
        .library(name: "MuseeUI", targets: ["MuseeUI"]),

        // Public facade
        .library(name: "MuseeKit", targets: ["MuseeKit"]),

        // Platform abstraction layer
        .library(name: "MuseePlatform", targets: ["MuseePlatform"]),
        .library(name: "MuseePlatformMac", targets: ["MuseePlatformMac"]),

        // Executables
        .executable(name: "musee", targets: ["MuseeCLI"]),
        .executable(name: "MuseeGUI", targets: ["MuseeGUI"]),
        .executable(name: "MuseeMac", targets: ["MuseeMac"]),
        .executable(name: "MuseeiOS", targets: ["MuseeiOS"]),
    ],
    targets: [
        .target(
            name: "MuseeCore"
        ),
        .target(
            name: "MuseeDomain",
            dependencies: [
                "MuseeCore",
            ]
        ),
        .target(
            name: "MuseeCAS",
            dependencies: [
                "MuseeCore",
                "MuseeDomain",
            ]
        ),
        .target(
            name: "MuseeBundle",
            dependencies: [
                "MuseeCore",
                "MuseeDomain",
                "MuseeCAS",
            ]
        ),
        .target(
            name: "MuseeMuseum",
            dependencies: [
                "MuseeCore",
                "MuseeDomain",
                "MuseeBundle",
            ]
        ),
        .target(
            name: "MuseeMetadata",
            dependencies: [
                "MuseeCore",
                "MuseeDomain",
            ]
        ),
        .target(
            name: "MuseeSearch",
            dependencies: [
                "MuseeCore",
                "MuseeDomain",
                "MuseeMuseum",
            ]
        ),
        .target(
            name: "MuseeVision",
            dependencies: [
                "MuseeCore",
                "MuseeDomain",
                "MuseeMetadata",
            ]
        ),
        .target(
            name: "MuseeScraper",
            dependencies: [
                "MuseeCore",
                "MuseeDomain"
            ]
        ),
        // New facade library
        .target(
            name: "MuseeKit",
            dependencies: [
                "MuseeCore",
                "MuseeDomain",
                "MuseeCAS",
                "MuseeBundle",
                "MuseeMuseum",
                "MuseeMetadata",
                "MuseeSearch",
                "MuseeVision",
                "MuseeScraper",
            ]
        ),

        // UI components library
        .target(
            name: "MuseeUI",
            dependencies: [
                "MuseeKit",
            ]
        ),

        // Platform abstraction protocols
        .target(
            name: "MuseePlatform"
        ),

        // macOS platform implementation
        .target(
            name: "MuseePlatformMac",
            dependencies: [
                "MuseePlatform",
            ]
        ),

        .executableTarget(
            name: "MuseeGUI",
            dependencies: [
                "MuseeUI",
            ]
        ),
        .executableTarget(
            name: "MuseeMac",
            dependencies: [
                "MuseeUI",
                "MuseePlatformMac",
            ]
        ),
        .executableTarget(
            name: "MuseeiOS",
            dependencies: [
                "MuseeUI",
                "MuseePlatform",
            ]
        ),
        .executableTarget(
            name: "MuseeCLI",
            dependencies: [
                "MuseeKit", // CLI can use the full facade
            ]
        ),
        .testTarget(
            name: "MuseeTests",
            dependencies: [
                "MuseeKit", // Test the full facade
            ]
        ),

        // Test targets for new modules
        .testTarget(
            name: "MuseeUITests",
            dependencies: [
                "MuseeUI",
            ],
            path: "Tests/MuseeUITests"
        ),

        .testTarget(
            name: "MuseePlatformMacTests",
            dependencies: [
                "MuseePlatformMac",
            ],
            path: "Tests/MuseePlatformMacTests"
        ),
    ]
)