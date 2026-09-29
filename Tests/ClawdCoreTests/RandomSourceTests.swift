import Testing
@testable import ClawdCore

@Suite("Aleatoriedad")
struct RandomSourceTests {
    @Test("La misma semilla da la misma secuencia")
    func mismaSemilla() {
        var a = SeededRandom(seed: 123)
        var b = SeededRandom(seed: 123)
        let secuenciaA = (0..<100).map { _ in a.nextUnit() }
        let secuenciaB = (0..<100).map { _ in b.nextUnit() }
        #expect(secuenciaA == secuenciaB)
    }

    @Test("Los valores siempre están en [0, 1)")
    func rango() {
        var r = SeededRandom(seed: 7)
        let valores = (0..<10_000).map { _ in r.nextUnit() }
        #expect(valores.allSatisfy { $0 >= 0 && $0 < 1 })
    }

    @Test("next(in:) respeta el rango")
    func rangoCerrado() {
        var r = SeededRandom(seed: 9)
        let valores = (0..<1_000).map { _ in r.next(in: 20...120) }
        #expect(valores.allSatisfy { (20...120).contains($0) })
    }
}
