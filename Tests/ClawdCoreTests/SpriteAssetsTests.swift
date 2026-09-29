import Foundation
import Testing
@testable import ClawdCore

@Suite("Sprites del repo")
struct SpriteAssetsTests {
    /// Tests/ClawdCoreTests/SpriteAssetsTests.swift → raíz del repo → Resources/Sprites
    static let spritesDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Resources/Sprites")

    @Test("Todos los sprites del repo son válidos y están completos")
    func validos() {
        let library = TextSpriteSource(directory: Self.spritesDirectory).load()
        #expect(library.failures.isEmpty, "\(library.failures)")
        #expect(Set(library.animations.keys) == Set(AnimationName.all))
    }

    @Test("Las medidas coinciden con las que usan los tests del cerebro")
    func medidas() {
        let library = TextSpriteSource(directory: Self.spritesDirectory).load()
        for name in AnimationName.all {
            #expect(library.infos[name] == testInfos[name], "\(name)")
        }
    }
}
