import CoreGraphics
import Foundation

/// El cerebro de Clawd: recibe una "foto" del mundo en cada tick y decide dónde está,
/// qué hace y cómo se dibuja. No sabe nada de ventanas; eso es trabajo de ClawdApp.
///
/// Las propiedades son `internal` (no `private`) porque la lógica está repartida en
/// varias extensiones (`Brain+*.swift`), una por responsabilidad.
public final class Brain {
    public internal(set) var state: PetState?
    /// Avisos para el log: reubicaciones, perro guardián, zonas calientes.
    public var onEvent: ((BrainEvent) -> Void)?

    let infos: [String: AnimationInfo]
    let config: BrainConfig
    var random: any RandomSource
    var planner: ActivityPlanner
    var ghost = GhostController()
    var hotZones: HotZoneTracker
    /// Reloj interno (suma de deltas): hace al cerebro determinista en los tests.
    var now: TimeInterval = 0
    var opacity: Double = 1
    var lastScreens: [ScreenInfo] = []

    public init(infos: [String: AnimationInfo], random: any RandomSource, config: BrainConfig = BrainConfig()) {
        self.infos = infos
        self.random = random
        self.config = config
        self.planner = ActivityPlanner(cooldowns: config.cooldowns)
        self.hotZones = HotZoneTracker(
            threshold: config.hotZoneScares, window: config.hotZoneWindow, cooldown: config.hotZoneCooldown)
    }

    @discardableResult
    public func tick(_ world: WorldSnapshot) -> PetRenderState? {
        // Si la Mac estuvo dormida, no queremos que Clawd salga disparado.
        let dt = min(max(world.deltaTime, 0), config.maxDeltaTime)
        now += dt
        guard !world.screens.isEmpty else { return nil }
        let scale = max(world.settings.scale, 1)

        validatePlacement(world.screens, scale: scale)
        handleDrag(world, scale: scale)
        handleGhost(world, scale: scale)
        if world.clicked { handleClick(world, scale: scale) }
        handleSleep(world)
        advance(dt: dt, world: world, scale: scale)
        runWatchdog(world.screens, scale: scale)
        updateOpacity(dt: dt)
        return render(world, scale: scale)
    }

    /// Solo para tests: fuerza un estado concreto.
    func forceState(_ newState: PetState) {
        state = newState
    }
}
