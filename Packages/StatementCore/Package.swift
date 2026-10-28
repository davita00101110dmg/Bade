// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StatementCore",
    // Platforms only matter on Apple hosts; on Linux the package builds as plain Foundation code.
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "StatementCore", targets: ["StatementCore"]),
    ],
    targets: [
        .target(name: "StatementCore"),
        // One test target per area, as in BadeKit, so each file keeps its own helpers unchanged.
        .testTarget(name: "ModelsTests", dependencies: ["StatementCore"]),
        .testTarget(name: "IngestionTests", dependencies: ["StatementCore"]),
        .testTarget(name: "NormalizationTests", dependencies: ["StatementCore"]),
        .testTarget(name: "CatalogTests", dependencies: ["StatementCore"]),
        .testTarget(name: "DetectionTests", dependencies: ["StatementCore"]),
        .testTarget(name: "PipelineTests", dependencies: ["StatementCore"]),
    ]
)
