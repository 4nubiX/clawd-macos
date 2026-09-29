import ClawdCore
import Foundation

enum SpriteLoader {
    /// Dónde buscar los sprites, en orden: dentro del .app, en `CLAWD_SPRITES_DIR`,
    /// o en el repo (cuando corres con `make dev`).
    static func spritesDirectory() -> URL {
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("Sprites"),
           FileManager.default.fileExists(atPath: bundled.path) {
            return bundled
        }
        if let custom = ProcessInfo.processInfo.environment["CLAWD_SPRITES_DIR"] {
            return URL(fileURLWithPath: custom)
        }
        // Sources/ClawdApp/SpriteLoader.swift → raíz del repo → Resources/Sprites
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/Sprites")
    }

    static func load() -> SpriteLibrary {
        let directory = spritesDirectory()
        Log.sprites.info("Cargando sprites de \(directory.path, privacy: .public)")
        return TextSpriteSource(directory: directory).load()
    }
}
