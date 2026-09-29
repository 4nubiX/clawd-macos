import CoreGraphics
import Foundation
import Testing
@testable import ClawdCore

@Suite("Rasterizador")
struct FrameRasterizerTests {
    @Test("Cada pixel del sprite se vuelve un bloque de pixelScale × pixelScale")
    func escala() throws {
        let rojo = RGBA(r: 255, g: 0, b: 0)
        let frame = SpriteFrame(width: 2, height: 1, pixels: [rojo, nil])
        let image = try #require(FrameRasterizer.image(from: frame, pixelScale: 3))
        #expect(image.width == 6 && image.height == 3)

        let cfData = try #require(image.dataProvider?.data)
        let bytes = [UInt8](cfData as Data)
        #expect(Array(bytes[0..<4]) == [255, 0, 0, 255])   // arriba a la izquierda: rojo opaco
        let columna5 = 5 * 4                                 // fila 0, columna 5: transparente
        #expect(bytes[columna5 + 3] == 0)
    }
}
