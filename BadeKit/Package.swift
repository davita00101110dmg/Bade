// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BadeKit",
    defaultLocalization: "en",
    // macOS exists only so `swift test` runs on the host in ~0.5s; Bade ships iOS-only.
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Detection", targets: ["Detection"]),
        .library(name: "Catalog", targets: ["Catalog"]),
        .library(name: "Ingestion", targets: ["Ingestion"]),
        .library(name: "Normalization", targets: ["Normalization"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "AppRoot", targets: ["AppRoot"]),
        .library(name: "Pipeline", targets: ["Pipeline"]),
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
        .target(name: "DesignSystem"),
        .target(name: "Localization", resources: [.process("Localizable.xcstrings")]),
        .testTarget(name: "LocalizationTests", dependencies: ["Localization"]),
        .target(
            name: "Welcome", dependencies: ["DesignSystem", "Localization"],
            path: "Sources/Features/Welcome"),
        .target(
            name: "Import", dependencies: ["Core", "DesignSystem", "Localization"],
            path: "Sources/Features/Import"),
        .target(
            name: "Pipeline",
            dependencies: ["Core", "Ingestion", "Normalization", "Detection", "Catalog"]),
        .testTarget(name: "ImportTests", dependencies: ["Import", "Core"]),
        .target(
            name: "AppRoot",
            dependencies: [
                "Core", "DesignSystem", "Localization", "Welcome", "Import", "Pipeline",
                "Persistence",
            ],
            path: "Sources/App"),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .target(name: "Persistence", dependencies: ["Core"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence", "Core"]),
        .target(name: "Catalog", dependencies: ["Core"]),
        .testTarget(name: "CatalogTests", dependencies: ["Catalog", "Detection", "Core"]),
        .testTarget(
            name: "PipelineTests",
            dependencies: ["Pipeline", "Ingestion", "Normalization", "Detection", "Catalog", "Core"]),
        .target(name: "TestSupport", dependencies: ["Core"]),
        .testTarget(name: "GoldenTests", dependencies: ["TestSupport", "Core"]),
    ]
)
