import Testing
@testable import ClawdCore

@Suite("Lector de sprites")
struct SpriteParserTests {
    // Numeración de líneas: 1 comentario, 2 fps, 3 repetir, 4 ancla, 5 paleta, 6 vacía,
    // 7 "--- cuadro 1", 8 "O.", 9 ".K", 10 "--- cuadro 2", 11 "KO", 12 "..".
    let valido = """
    # comentario
    fps: 4
    repetir: no
    ancla: 1,2
    paleta: O=#D97757 K=#1A1A1A80

    --- cuadro 1
    O.
    .K
    --- cuadro 2
    KO
    ..
    """

    @Test("Lee un sprite válido")
    func leeValido() throws {
        let anim = try SpriteParser.parse(valido, name: "prueba")
        #expect(anim.name == "prueba")
        #expect(anim.fps == 4)
        #expect(anim.loops == false)
        #expect(anim.anchor == GridPoint(x: 1, y: 2))
        #expect(anim.frames.count == 2)
        #expect(anim.width == 2 && anim.height == 2)
        #expect(anim.frames[0].pixel(x: 0, y: 0) == RGBA(r: 0xD9, g: 0x77, b: 0x57))
        #expect(anim.frames[0].pixel(x: 1, y: 0) == nil)
        #expect(anim.frames[0].pixel(x: 1, y: 1) == RGBA(r: 0x1A, g: 0x1A, b: 0x1A, a: 0x80))
    }

    @Test("Falta fps → error en la línea 1")
    func faltaFPS() {
        let texto = valido.replacingOccurrences(of: "fps: 4\n", with: "")
        expectError(texto, line: 1, contains: "fps")
    }

    @Test("Símbolo fuera de la paleta → error en su línea")
    func simboloDesconocido() {
        let texto = valido.replacingOccurrences(of: ".K", with: ".X")
        expectError(texto, line: 9, contains: "'X'")
    }

    @Test("Filas de distinto ancho → error en la fila")
    func anchoDistinto() {
        let texto = valido.replacingOccurrences(of: "KO\n", with: "KOO\n")
        expectError(texto, line: 11, contains: "mide 3")
    }

    @Test("Cuadros de distinta altura → error en el cuadro")
    func alturaDistinta() {
        expectError(valido + "\nKO", line: 10, contains: "filas")
    }

    @Test("Ancla fuera del cuadro → error en la línea del ancla")
    func anclaFuera() {
        let texto = valido.replacingOccurrences(of: "ancla: 1,2", with: "ancla: 5,2")
        expectError(texto, line: 4, contains: "ancla")
    }

    @Test("Clave desconocida → error")
    func claveDesconocida() {
        let texto = valido.replacingOccurrences(of: "repetir: no", with: "velocidad: 3")
        expectError(texto, line: 3, contains: "velocidad")
    }

    @Test("Símbolo reservado en la paleta → error")
    func simboloReservado() {
        let texto = valido.replacingOccurrences(of: "O=#D97757", with: "#=#D97757")
        expectError(texto, line: 5, contains: "reservado")
    }

    @Test("Índice de cuadro: repite o se queda en el último")
    func indiceDeCuadro() {
        let repite = AnimationInfo(width: 1, height: 1, anchor: GridPoint(x: 0, y: 0), fps: 2, frameCount: 3, loops: true)
        #expect(repite.frameIndex(at: 0) == 0)
        #expect(repite.frameIndex(at: 0.6) == 1)
        #expect(repite.frameIndex(at: 1.6) == 0)
        #expect(repite.duration == 1.5)
        let unaVez = AnimationInfo(width: 1, height: 1, anchor: GridPoint(x: 0, y: 0), fps: 2, frameCount: 3, loops: false)
        #expect(unaVez.frameIndex(at: 10) == 2)
    }

    private func expectError(
        _ text: String, line: Int, contains fragment: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        do {
            _ = try SpriteParser.parse(text, name: "prueba")
            Issue.record("Se esperaba un error", sourceLocation: sourceLocation)
        } catch let error as SpriteParseError {
            #expect(error.line == line, "mensaje: \(error.message)", sourceLocation: sourceLocation)
            #expect(error.message.contains(fragment), "mensaje: \(error.message)", sourceLocation: sourceLocation)
        } catch {
            Issue.record("Error inesperado: \(error)", sourceLocation: sourceLocation)
        }
    }
}
