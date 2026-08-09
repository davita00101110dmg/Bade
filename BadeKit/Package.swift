// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BadeKit",
    // macOS only so `swift test` runs on the host; the app ships iOS-only.
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Detection", targets: ["Detection"]),
        .library(name: "Catalog", targets: ["Catalog"]),
        .library(name: "Ingestion", targets: ["Ingestion"]),
        .library(name: "Normalization", targets: ["Normalization"]),
    ],
    targets: [
        .target(name: "Core"),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .target(name: "Detection", dependencies: ["Core"]),
        .testTarget(name: "DetectionTests", dependencies: ["Detection", "Core"]),
        .target(name: "Ingestion", dependencies: ["Core"]),
        .testTarget(name: "IngestionTests", dependencies: ["Ingestion", "Core"]),
        .target(name: "Normalization", dependencies: ["Core"]),
        .testTarget(name: "NormalizationTests", dependencies: ["Normalization", "Core"]),
        .target(name: "Catalog", dependencies: ["Core"]),
        .testTarget(name: "CatalogTests", dependencies: ["Catalog", "Detection", "Core"]),
        .testTarget(
            name: "PipelineTests",
            dependencies: ["Ingestion", "Normalization", "Detection", "Catalog", "Core"]),
        .target(name: "TestSupport", dependencies: ["Core"]),
        .testTarget(name: "GoldenTests", dependencies: ["TestSupport", "Core"]),
    ]
)
