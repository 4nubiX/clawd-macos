import CoreGraphics
import Foundation
import Testing
@testable import ClawdCore

// MARK: - Ayudantes

func makeBrain(seed: UInt64 = 42) -> Brain {
    Brain(infos: testInfos, random: SeededRandom(seed: seed))
}

func world(
    _ screens: [ScreenInfo] = [laptop, external],
    mouse: CGPoint = CGPoint(x: -9_999, y: -9_999),
    option: Bool = false,
    clicked: Bool = false,
    drag: CGPoint? = nil,
    idle: TimeInterval = 0,
    dt: TimeInterval = 1.0 / 30
) -> WorldSnapshot {
    WorldSnapshot(
        screens: screens, mouse: mouse, optionPressed: option, clicked: clicked,
        dragAnchor: drag, idleSeconds: idle, deltaTime: dt)
}

/// Avanza el cerebro `seconds` segundos con la misma "foto" del mundo.
@discardableResult
func run(_ brain: Brain, _ snapshot: WorldSnapshot, seconds: Double) -> PetRenderState? {
    var last: PetRenderState?
    for _ in 0..<Int((seconds / snapshot.deltaTime).rounded()) {
        last = brain.tick(snapshot)
    }
    return last
}

/// Clawd quieto en el piso del monitor externo, con una actividad larga para que no se mueva solo.
func floorState(x: CGFloat = 2_500, activity: Activity = .idle) -> PetState {
    PetState(screenID: external.id, place: .floor, position: CGPoint(x: x, y: 0), activity: activity, duration: 100)
}

func isRelocation(_ event: BrainEvent) -> Bool {
    if case .relocated = event { return true }
    return false
}

func isWatchdog(_ event: BrainEvent) -> Bool {
    if case .watchdogReset = event { return true }
    return false
}

// MARK: - Tests

@Suite("Cerebro")
struct BrainTests {
    @Test("Al arrancar aparece cayendo en la pantalla más grande")
    func arranque() throws {
        let brain = makeBrain()
        let render = try #require(brain.tick(world()))
        let state = try #require(brain.state)
        #expect(state.screenID == external.id)
        #expect(state.place == .air)
        #expect(state.activity == .fall)
        #expect(render.animation == AnimationName.fall)
    }

    @Test("Sin pantallas no dibuja nada")
    func sinPantallas() {
        #expect(makeBrain().tick(world([])) == nil)
    }

    @Test("Cae y aterriza en el piso")
    func aterriza() throws {
        let brain = makeBrain()
        run(brain, world(), seconds: 3)
        let state = try #require(brain.state)
        #expect(state.place == .floor)
        #expect(state.position.y == external.visibleFrame.minY)
    }

    @Test("Un delta enorme (la Mac despertando) se limita a 0.1 s")
    func deltaLimitado() throws {
        let brain = makeBrain()
        brain.tick(world())
        brain.tick(world(dt: 3_600))
        let state = try #require(brain.state)
        // Primer tick: 1/30 s. Segundo tick: 3600 s recortados a 0.1 s.
        #expect(state.fallSpeed <= 1_400 * (1.0 / 30 + 0.1) + 0.001)
        #expect(state.place == .air)
    }

    @Test("Si desconectas su monitor, se muda al que quede")
    func monitorDesconectado() throws {
        let brain = makeBrain()
        var events: [BrainEvent] = []
        brain.onEvent = { events.append($0) }
        brain.tick(world())
        brain.tick(world([laptop]))
        let state = try #require(brain.state)
        #expect(state.screenID == laptop.id)
        #expect(state.activity == .fall)
        #expect(events.filter(isRelocation).count == 2)   // al arrancar + al desconectar
    }

    @Test("Mouse cerca → fantasma y se hace a un lado")
    func fantasma() throws {
        let brain = makeBrain()
        brain.forceState(floorState())
        let first = try #require(brain.tick(world()))
        let mouse = CGPoint(x: first.frameRect.minX - 20, y: first.frameRect.midY)
        let near = try #require(brain.tick(world(mouse: mouse)))
        #expect(near.acceptsClicks == false)
        #expect(brain.state?.activity == .dodge)
        let later = try #require(run(brain, world(mouse: mouse), seconds: 0.3))
        #expect(abs(later.opacity - 0.3) < 0.01)
    }

    @Test("Con ⌥ presionado no se vuelve fantasma y acepta el click")
    func conOption() throws {
        let brain = makeBrain()
        brain.forceState(floorState())
        let first = try #require(brain.tick(world()))
        let center = CGPoint(x: first.frameRect.midX, y: first.frameRect.midY)
        let render = try #require(brain.tick(world(mouse: center, option: true)))
        #expect(render.acceptsClicks)
        #expect(render.opacity == 1)
        #expect(brain.state?.activity == .idle)
    }

    @Test("⌥ click en el piso → saluda")
    func saludo() {
        let brain = makeBrain()
        brain.forceState(floorState())
        brain.tick(world(clicked: true))
        #expect(brain.state?.activity == .wave)
    }

    @Test("⌥ click en la esquina → se baja y saluda")
    func saludoDesdeLaEsquina() {
        let brain = makeBrain()
        let corner = CGPoint(x: external.visibleFrame.maxX, y: external.visibleFrame.maxY)
        brain.forceState(PetState(screenID: external.id, place: .corner, position: corner, activity: .sit, duration: 100))
        brain.tick(world(clicked: true))
        #expect(brain.state?.activity == .fall)
        run(brain, world(), seconds: 2.5)
        #expect(brain.state?.activity == .wave)
    }

    @Test("⌥ arrastrar lo carga; al soltarlo cae")
    func arrastre() {
        let brain = makeBrain()
        brain.forceState(floorState())
        brain.tick(world(drag: CGPoint(x: 3_000, y: 600)))
        #expect(brain.state?.activity == .carried)
        #expect(brain.state?.position == CGPoint(x: 3_000, y: 600))
        brain.tick(world())
        #expect(brain.state?.activity == .fall)
    }

    @Test("Se duerme por inactividad y despierta al volver")
    func dormir() {
        let brain = makeBrain()
        brain.forceState(floorState())
        brain.tick(world(idle: 400))
        #expect(brain.state?.activity == .sleep)
        brain.tick(world(idle: 0))
        #expect(brain.state?.activity == .idle)
    }

    @Test("Dormido en la hamaca usa el sprite de la hamaca")
    func dormirEnHamaca() throws {
        let brain = makeBrain()
        let hook = CGPoint(x: external.visibleFrame.maxX - 60, y: external.visibleFrame.maxY)
        brain.forceState(PetState(screenID: external.id, place: .hammock, position: hook, activity: .hammock, duration: 100))
        let render = try #require(brain.tick(world(idle: 400)))
        #expect(render.animation == AnimationName.sleepHammock)
        #expect(render.isSleeping)
    }

    @Test("El perro guardián rescata estados atorados")
    func perroGuardian() {
        let brain = makeBrain()
        var events: [BrainEvent] = []
        brain.onEvent = { events.append($0) }
        var stuck = floorState()
        stuck.place = .wall
        stuck.activity = .climbUp
        stuck.elapsed = 1_000
        stuck.duration = .infinity
        stuck.position = CGPoint(x: external.visibleFrame.maxX, y: 300)
        stuck.targetY = 900
        brain.forceState(stuck)
        brain.tick(world())
        #expect(brain.state?.activity == .idle)
        #expect(brain.state?.place == .floor)
        #expect(events.contains(where: isWatchdog))
    }

    @Test("Simulación de 20 min: nunca se sale de las pantallas ni se atora")
    func simulacionLarga() throws {
        let brain = makeBrain(seed: 2026)
        var events: [BrainEvent] = []
        brain.onEvent = { events.append($0) }
        var dice = SeededRandom(seed: 99)
        var mouse = CGPoint(x: 0, y: 0)

        for step in 0..<12_000 {   // 20 minutos en pasos de 0.1 s
            // En el minuto 10 desconectas el monitor externo y lo reconectas en el 11.
            let screens = (step / 600 == 10) ? [laptop] : [laptop, external]
            if dice.nextUnit() < 0.05 {
                mouse = CGPoint(x: dice.next(in: 0...3_432), y: dice.next(in: 0...1_080))
            }
            let click = dice.nextUnit() < 0.002
            let render = try #require(brain.tick(world(screens, mouse: mouse, option: click, clicked: click, dt: 0.1)))
            let inside = screens.contains { $0.frame.insetBy(dx: -2, dy: -2).contains(render.anchorPosition) }
            if !inside {
                let activity = brain.state.map { $0.activity.rawValue } ?? "sin estado"
                Issue.record("paso \(step): \(render.anchorPosition) quedó fuera (\(activity))")
                break
            }
        }
        #expect(!events.contains(where: isWatchdog), "\(events.filter(isWatchdog))")
    }
}
