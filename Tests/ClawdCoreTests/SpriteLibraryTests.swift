import Foundation
import Testing
@testable import ClawdCore

@Suite("Biblioteca de sprites")
struct SpriteLibraryTests {
    @Test("Carga los válidos y reporta los rotos sin tronar")
    func cargaTolerante() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("clawd-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let bueno = "fps: 1\nrepetir: si\nancla: 0,1\npaleta: O=#FFFFFF\n--- cuadro\nO\n"
        try bueno.write(to: dir.appendingPathComponent("idle.txt"), atomically: true, encoding: .utf8)
        try "fps: 1\n".write(to: dir.appendingPathComponent("roto.txt"), atomically: true, encoding: .utf8)

        let library = TextSpriteSource(directory: dir, requiredNames: ["idle", "caminar"]).load()
        #expect(library.animations.keys.sorted() == ["idle"])
        #expect(library.failures.contains { $0.file == "roto.txt" })
        #expect(library.failures.contains { $0.file == "caminar.txt" && $0.message.contains("obligatoria") })
        #expect(library.animationOrIdle("no-existe")?.name == "idle")
        #expect(library.infos["idle"]?.frameCount == 1)
    }

    @Test("Carpeta inexistente → un solo error claro")
    func carpetaInexistente() {
        let library = TextSpriteSource(directory: URL(fileURLWithPath: "/no/existe/clawd")).load()
        #expect(library.animations.isEmpty)
        #expect(library.failures.count == 1)
    }
}
