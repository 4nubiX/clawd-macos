// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Clawd",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Clawd", targets: ["ClawdApp"]),
        .executable(name: "clawd-preview", targets: ["ClawdPreview"]),
    ],
    targets: [
        // El cerebro: lógica pura, sin AppKit, 100 % testeable.
        .target(name: "ClawdCore"),
        // El cuerpo: ventana, mouse, barra de menú. Todo lo que toca macOS.
        .executableTarget(name: "ClawdApp", dependencies: ["ClawdCore"]),
        // Herramienta de línea de comandos: hoja PNG con todas las animaciones.
        .executableTarget(name: "ClawdPreview", dependencies: ["ClawdCore"]),
        .testTarget(name: "ClawdCoreTests", dependencies: ["ClawdCore"]),
    ]
)
