import CoreGraphics
import Foundation

/// Todos los números que definen el comportamiento de Clawd, en un solo lugar.
public struct BrainConfig: Sendable {
    public var maxDeltaTime: TimeInterval = 0.1
    /// Velocidades en pt/s por unidad de escala (mediano = 5 → caminar a 40 pt/s).
    public var walkSpeedPerScale: CGFloat = 8
    public var climbSpeedPerScale: CGFloat = 6
    public var gravity: CGFloat = 1_400
    public var maxFallSpeed: CGFloat = 900

    public var ghostEnterDistance: CGFloat = 40
    public var ghostExitDistance: CGFloat = 80
    public var ghostExitDelay: TimeInterval = 1
    public var ghostOpacity: Double = 0.3
    public var fadeDuration: TimeInterval = 0.15
    /// Tras interactuar con Clawd (⌥ presionado o cargándolo), durante este tiempo
    /// el mouse encima no cuenta como susto: estabas jugando con él, no espantándolo.
    public var interactionGrace: TimeInterval = 1

    public var hotZoneScares = 3
    public var hotZoneWindow: TimeInterval = 180
    public var hotZoneCooldown: TimeInterval = 600

    /// Qué tan lejos se hace a un lado al esquivar, en anchos de cuerpo.
    public var dodgeDistanceInBodies: CGFloat = 4
    public var waveDuration: TimeInterval = 1.6

    /// Rangos de duración de las actividades con reloj.
    public var durations: [Activity: ClosedRange<Double>] = [
        .idle: 3...8, .lookAround: 2.5...4, .cook: 12...18, .sit: 20...120, .hammock: 20...90,
    ]

    /// Duración máxima antes de que actúe el perro guardián. Sin entrada = sin límite.
    public var maxDurations: [Activity: TimeInterval] = [
        .idle: 30, .lookAround: 30, .walk: 300, .climbUp: 150, .climbDown: 150, .fall: 15,
        .land: 3, .wave: 10, .dodge: 5, .cook: 40, .sit: 200, .hammock: 150,
    ]

    /// Tiempo de espera antes de repetir intenciones especiales.
    public var cooldowns: [Intention: TimeInterval] = [.cook: 600, .hammock: 300, .stroll: 300]

    public init() {}
}
