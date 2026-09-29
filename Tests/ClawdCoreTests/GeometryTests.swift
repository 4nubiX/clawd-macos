import CoreGraphics
import Testing
@testable import ClawdCore

@Suite("Geometría")
struct GeometryTests {
    let body = info(16, 9, anchor: (8, 9), fps: 1, frames: 1, loops: true)

    @Test("El rectángulo sale del ancla y la escala")
    func rectangulo() {
        let rect = Geometry.frameRect(anchorPosition: CGPoint(x: 100, y: 50), info: body, scale: 5, facingLeft: false)
        #expect(rect == CGRect(x: 60, y: 50, width: 80, height: 45))
    }

    @Test("Mirando a la izquierda se refleja el ancla")
    func espejo() {
        let cook = info(24, 14, anchor: (8, 14), fps: 1, frames: 1, loops: true)
        let rect = Geometry.frameRect(anchorPosition: CGPoint(x: 100, y: 0), info: cook, scale: 2, facingLeft: true)
        #expect(rect.minX == 100 - CGFloat(24 - 8) * 2)
    }

    @Test("Ancla arriba (hamaca): el sprite cuelga hacia abajo")
    func anclaArriba() {
        let hammock = info(24, 12, anchor: (12, 0), fps: 1, frames: 1, loops: true)
        let rect = Geometry.frameRect(anchorPosition: CGPoint(x: 500, y: 1000), info: hammock, scale: 5, facingLeft: false)
        #expect(rect == CGRect(x: 440, y: 940, width: 120, height: 60))
    }

    @Test("Distancia de un punto a un rectángulo")
    func distancia() {
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        #expect(Geometry.distance(from: CGPoint(x: 5, y: 5), to: rect) == 0)
        #expect(Geometry.distance(from: CGPoint(x: 40, y: 5), to: rect) == 30)
        #expect(Geometry.distance(from: CGPoint(x: 13, y: 14), to: rect) == 5)
    }

    @Test("La casa es la pantalla con más área útil")
    func casa() {
        #expect(Geometry.homeScreen(in: [laptop, external])?.id == external.id)
        #expect(Geometry.homeScreen(in: []) == nil)
    }

    @Test("En empate de área, la casa es la de menor id")
    func casaEmpate() {
        let a = ScreenInfo(id: 5, frame: CGRect(x: 0, y: 0, width: 100, height: 100), visibleFrame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let b = ScreenInfo(id: 2, frame: CGRect(x: 100, y: 0, width: 100, height: 100), visibleFrame: CGRect(x: 100, y: 0, width: 100, height: 100))
        #expect(Geometry.homeScreen(in: [a, b])?.id == 2)
        #expect(Geometry.homeScreen(in: [b, a])?.id == 2)
    }

    @Test("Cruza caminando entre pantallas pegadas")
    func cruceCaminando() {
        #expect(Geometry.crossing(from: laptop, to: external) == .walk(edgeX: 1512, direction: 1))
        #expect(Geometry.crossing(from: external, to: laptop) == .walk(edgeX: 1512, direction: -1))
    }

    @Test("Si el piso del destino queda más arriba, aparece cayendo")
    func pisoMasAlto() {
        let high = ScreenInfo(
            id: 3, frame: CGRect(x: 3432, y: 200, width: 1000, height: 800),
            visibleFrame: CGRect(x: 3432, y: 200, width: 1000, height: 775))
        #expect(Geometry.crossing(from: external, to: high) == .dropIn)
    }

    @Test("Pantallas que no se tocan → aparece cayendo")
    func separadas() {
        let far = ScreenInfo(
            id: 4, frame: CGRect(x: 5000, y: 0, width: 800, height: 600),
            visibleFrame: CGRect(x: 5000, y: 0, width: 800, height: 575))
        #expect(Geometry.crossing(from: external, to: far) == .dropIn)
    }

    @Test("Pantalla más cercana a un punto")
    func masCercana() {
        #expect(Geometry.nearestScreen(to: CGPoint(x: 2000, y: 500), in: [laptop, external])?.id == external.id)
        #expect(Geometry.nearestScreen(to: CGPoint(x: -50, y: 10), in: [laptop, external])?.id == laptop.id)
    }

    @Test("Solo cuenta el click sobre pixeles opacos")
    func pixelOpaco() {
        let frame = SpriteFrame(width: 2, height: 1, pixels: [RGBA(r: 1, g: 1, b: 1), nil])
        let rect = CGRect(x: 0, y: 0, width: 20, height: 10)
        #expect(Geometry.isOpaquePixel(frame: frame, frameRect: rect, point: CGPoint(x: 5, y: 5), facingLeft: false))
        #expect(!Geometry.isOpaquePixel(frame: frame, frameRect: rect, point: CGPoint(x: 15, y: 5), facingLeft: false))
        #expect(!Geometry.isOpaquePixel(frame: frame, frameRect: rect, point: CGPoint(x: 5, y: 5), facingLeft: true))
        #expect(!Geometry.isOpaquePixel(frame: frame, frameRect: rect, point: CGPoint(x: 50, y: 5), facingLeft: false))
    }
}
