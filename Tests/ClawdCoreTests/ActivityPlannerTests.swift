import Foundation
import Testing
@testable import ClawdCore

@Suite("Planeador de actividades")
struct ActivityPlannerTests {
    let floorHome = PlannerContext(
        place: .floor, onHomeScreen: true, hasOtherScreens: false, cornerIsHot: false, floorIsHot: false)

    @Test("Nunca repite la misma intención dos veces seguidas")
    func sinRepetir() {
        var planner = ActivityPlanner(cooldowns: [:])
        var random: any RandomSource = FixedRandom([0])
        #expect(planner.choose(floorHome, random: &random, now: 0) == .idle)
        #expect(planner.choose(floorHome, random: &random, now: 1) == .lookAround)
    }

    @Test("La elección respeta los pesos (no solo el primer valor)")
    func eleccionConPesos() {
        // Piso en casa: idle 3, lookAround 2, wander 3, cook 1, goToCorner 4 → total 13.
        var alFinal = ActivityPlanner(cooldowns: [:])
        var casiUno: any RandomSource = FixedRandom([0.99])
        #expect(alFinal.choose(floorHome, random: &casiUno, now: 0) == .goToCorner)

        var justoDespuesDeIdle = ActivityPlanner(cooldowns: [:])
        var tresTreceavos: any RandomSource = FixedRandom([3.0 / 13 + 0.001])
        #expect(justoDespuesDeIdle.choose(floorHome, random: &tresTreceavos, now: 0) == .lookAround)
    }

    @Test("Respeta los tiempos de espera (cocinar no sale seguido)")
    func tiempoDeEspera() {
        var planner = ActivityPlanner(cooldowns: [.cook: 600])
        var random: any RandomSource = SeededRandom(seed: 1)
        var cooked: [TimeInterval] = []
        for second in 0..<2_000 {
            let now = TimeInterval(second)
            if planner.choose(floorHome, random: &random, now: now) == .cook { cooked.append(now) }
        }
        #expect(cooked.count >= 2, "sin al menos dos, el test no verifica el tiempo de espera")
        for (a, b) in zip(cooked, cooked.dropFirst()) {
            #expect(b - a >= 600)
        }
    }

    @Test("Esquina caliente: no va hacia allá ni se sienta ahí")
    func esquinaCaliente() {
        let planner = ActivityPlanner(cooldowns: [:])
        var context = floorHome
        context.cornerIsHot = true
        #expect(planner.weights(for: context).first { $0.0 == .goToCorner }?.1 == 0)
        context.place = .corner
        #expect(!planner.weights(for: context).contains { $0.0 == .sit })
    }

    @Test("Fuera de casa, casi siempre quiere regresar")
    func regresarACasa() {
        var context = floorHome
        context.onHomeScreen = false
        context.hasOtherScreens = true
        let weights = ActivityPlanner(cooldowns: [:]).weights(for: context)
        #expect(weights.contains { $0.0 == .goHome && $0.1 == 8 })
        #expect(!weights.contains { $0.0 == .stroll })
    }

    @Test("En casa y con otra pantalla, a veces se pasea")
    func pasear() {
        var context = floorHome
        context.hasOtherScreens = true
        #expect(ActivityPlanner(cooldowns: [:]).weights(for: context).contains { $0.0 == .stroll && $0.1 == 1 })
    }

    @Test("Piso caliente: solo opciones para moverse")
    func pisoCaliente() {
        var context = floorHome
        context.floorIsHot = true
        let calm = ActivityPlanner(cooldowns: [:]).weights(for: context)
            .filter { [Intention.idle, .lookAround, .cook].contains($0.0) }
        #expect(calm.allSatisfy { $0.1 == 0 })
    }

    @Test("Sin opciones, usa el respaldo de cada lugar")
    func respaldo() {
        var planner = ActivityPlanner(cooldowns: [:])
        var random: any RandomSource = FixedRandom([0])
        var context = floorHome
        context.place = .wall
        #expect(planner.choose(context, random: &random, now: 0) == .idle)
    }
}
