// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Musee",
    platforms: [
        .macOS(.v26), .iOS(.v26), .tvOS(.v26), .visionOS(.v26), .watchOS(.v26),
    ],
    products: [
        .library(name: "MuseeCore", targets: ["MuseeCore"]),
        .library(name: "MuseeDomain", targets: ["MuseeDomain"]),
        .library(name: "MuseeCAS", targets: ["MuseeCAS"]),
        .library(name: "MuseeBundle", targets: ["MuseeBundle"]),
        .library(name: "MuseeMuseum", targets: ["MuseeMuseum"]),
        .library(name: "MuseeMetadata", targets: ["MuseeMetadata"]),
        .library(name: "MuseeSearch", targets: ["MuseeSearch"]),
        .library(name: "MuseeVision", targets: ["MuseeVision"]),
        .executable(name: "musee", targets: ["MuseeCLI"]),
        .executable(name: "MuseeGUI", targets: ["MuseeGUI"]),
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
        .executableTarget(
            name: "MuseeGUI",
            dependencies: [
                "MuseeCore",
                "MuseeDomain",
                "MuseeMuseum",
                "MuseeSearch",
                "MuseeVision",
            ]
        ),
        .executableTarget(
            name: "MuseeCLI",
            dependencies: [
                "MuseeMuseum",
                "MuseeMetadata",
            ]
        ),
        .testTarget(
            name: "MuseeTests",
            dependencies: [
                "MuseeMuseum",
                "MuseeMetadata",
                "MuseeSearch",
                "MuseeVision",
            ]
        ),
    ]
)
