// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BadeKit",
    // macOS only so `swift test` runs on the host; the app ships iOS-only.
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Detection", targets: ["Detection"]),
    ],
    targets: [
        .target(name: "Core"),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .target(name: "Detection", dependencies: ["Core"]),
        .testTarget(name: "DetectionTests", dependencies: ["Detection", "Core"]),
        .target(name: "TestSupport", dependencies: ["Core"]),
        .testTarget(name: "GoldenTests", dependencies: ["TestSupport", "Core"]),
    ]
)
