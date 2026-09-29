// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Clawd",
    platforms: [.macOS(.v14)],
    targets: [
        // El cerebro: lógica pura, sin AppKit, 100 % testeable.
        .target(name: "ClawdCore"),
        .testTarget(name: "ClawdCoreTests", dependencies: ["ClawdCore"]),
    ]
)
