// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Clawd",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "clawd-preview", targets: ["ClawdPreview"]),
    ],
    targets: [
        // El cerebro: lógica pura, sin AppKit, 100 % testeable.
        .target(name: "ClawdCore"),
        // Herramienta de línea de comandos: hoja PNG con todas las animaciones.
        .executableTarget(name: "ClawdPreview", dependencies: ["ClawdCore"]),
        .testTarget(name: "ClawdCoreTests", dependencies: ["ClawdCore"]),
    ]
)
