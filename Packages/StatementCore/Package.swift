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
    ]
)
