// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BadeKit",
    // macOS only so `swift test` runs on the host; the app ships iOS-only.
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Core", targets: ["Core"])
    ],
    targets: [
        .target(name: "Core"),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)
