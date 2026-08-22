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
        .library(name: "FX", targets: ["FX"]),
        .library(name: "Notifications", targets: ["Notifications"]),
        .library(name: "Purchases", targets: ["Purchases"]),
        .library(name: "Widgets", targets: ["Widgets"]),
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
        .target(name: "DesignSystem", dependencies: ["Localization"]),
        .target(name: "Localization", resources: [.process("Localizable.xcstrings")]),
        .testTarget(name: "LocalizationTests", dependencies: ["Localization"]),
        .target(
            name: "Welcome", dependencies: ["DesignSystem", "Localization"],
            path: "Sources/Features/Welcome"),
        .target(
            name: "Import", dependencies: ["Core", "DesignSystem", "Localization"],
            path: "Sources/Features/Import"),
        .target(
            name: "Subscriptions", dependencies: ["Core", "DesignSystem", "Localization"],
            path: "Sources/Features/Subscriptions"),
        .testTarget(name: "SubscriptionsTests", dependencies: ["Subscriptions", "Core"]),
        .target(
            name: "Upcoming", dependencies: ["Core", "DesignSystem", "Localization"],
            path: "Sources/Features/Upcoming"),
        .testTarget(name: "UpcomingTests", dependencies: ["Upcoming", "Core"]),
        .target(
            name: "Settings", dependencies: ["Core", "DesignSystem", "Localization"],
            path: "Sources/Features/Settings"),
        .testTarget(name: "SettingsTests", dependencies: ["Settings", "Core"]),
        // §11's snapshot pass. iOS-only inside; on macOS the whole file compiles away.
        .testTarget(
            name: "SnapshotTests",
            dependencies: [
                "Core", "DesignSystem", "Localization", "Subscriptions", "Upcoming", "Settings",
                "Welcome",
            ]),
        .target(
            name: "Pipeline",
            dependencies: ["Core", "Ingestion", "Normalization", "Detection", "Catalog"]),
        .testTarget(name: "ImportTests", dependencies: ["Import", "Core"]),
        .target(
            name: "AppRoot",
            dependencies: [
                "Core", "DesignSystem", "Localization", "Welcome", "Import", "Subscriptions",
                "Pipeline", "Persistence", "Catalog", "Upcoming", "Settings", "FX", "Notifications",
                "Purchases", "Widgets",
            ],
            path: "Sources/App"),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .target(name: "Persistence", dependencies: ["Core"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence", "Core"]),
        .target(name: "FX", dependencies: ["Core"]),
        .testTarget(name: "FXTests", dependencies: ["FX", "Core"]),
        .target(name: "Notifications", dependencies: ["Core", "Localization"]),
        .testTarget(name: "NotificationsTests", dependencies: ["Notifications", "Core"]),
        .target(name: "Purchases", dependencies: ["Core"]),
        .target(name: "Widgets", dependencies: ["Core", "DesignSystem", "Localization"]),
        .testTarget(name: "WidgetsTests", dependencies: ["Widgets", "Core"]),
        .target(name: "Catalog", dependencies: ["Core"]),
        .testTarget(name: "CatalogTests", dependencies: ["Catalog", "Detection", "Core"]),
        .testTarget(
            name: "PipelineTests",
            dependencies: [
                "Pipeline", "Ingestion", "Normalization", "Detection", "Catalog", "Core",
                "TestSupport",
            ]),
        .target(name: "TestSupport", dependencies: ["Core"]),
        .testTarget(name: "GoldenTests", dependencies: ["TestSupport", "Core"]),
    ]
)
