import CoreGraphics
import Foundation

/// Zonas de la pantalla para llevar la cuenta de sustos.
public enum Zone: String, Sendable {
    case floor, wall, corner
}

public struct ZoneKey: Hashable, Sendable {
    public let screenID: UInt32
    public let zone: Zone

    public init(screenID: UInt32, zone: Zone) {
        self.screenID = screenID
        self.zone = zone
    }
}

/// Lugar físico donde está Clawd.
public enum Place: String, Equatable, Sendable {
    case floor, wall, corner, hammock, air
}

/// Lo que Clawd está haciendo.
public enum Activity: String, Equatable, Hashable, Sendable, CaseIterable {
    case idle, walk, lookAround, cook, sleep, climbUp, climbDown, sit, hammock, fall, land, wave, dodge, carried
}

/// Qué hacer al terminar de caminar o trepar.
public enum Arrival: Equatable, Sendable {
    case rest
    case climbWall
    case sitInCorner
    case standOnFloor
    case startCooking
    case cross(toScreen: UInt32)
}

/// Tamaños disponibles: cuántos puntos mide cada pixel del sprite.
public enum PetSize: Int, CaseIterable, Sendable {
    case small = 3, medium = 5, large = 8
}

/// Ajustes del usuario que afectan el comportamiento.
public struct PetSettings: Equatable, Sendable {
    public var scale: Int
    public var sleepAfter: TimeInterval
    public var forceSleep: Bool

    public init(scale: Int = PetSize.medium.rawValue, sleepAfter: TimeInterval = 300, forceSleep: Bool = false) {
        self.scale = scale
        self.sleepAfter = sleepAfter
        self.forceSleep = forceSleep
    }
}

/// La "foto" del mundo que el cuerpo (ClawdApp) le pasa al cerebro en cada tick.
public struct WorldSnapshot: Sendable {
    public var screens: [ScreenInfo]
    public var mouse: CGPoint
    public var optionPressed: Bool
    /// Hubo un ⌥ click (sin arrastre) desde el tick anterior.
    public var clicked: Bool
    /// Mientras lo cargas con ⌥ + arrastrar: dónde debe quedar su ancla.
    public var dragAnchor: CGPoint?
    public var idleSeconds: TimeInterval
    public var deltaTime: TimeInterval
    public var settings: PetSettings
    /// Reservado para la Fase 2 ("Claude necesita tu atención"). En la Fase 1 siempre es false.
    public var needsAttention: Bool

    public init(
        screens: [ScreenInfo],
        mouse: CGPoint = CGPoint(x: -10_000, y: -10_000),
        optionPressed: Bool = false,
        clicked: Bool = false,
        dragAnchor: CGPoint? = nil,
        idleSeconds: TimeInterval = 0,
        deltaTime: TimeInterval = 1.0 / 30,
        settings: PetSettings = PetSettings(),
        needsAttention: Bool = false
    ) {
        self.screens = screens
        self.mouse = mouse
        self.optionPressed = optionPressed
        self.clicked = clicked
        self.dragAnchor = dragAnchor
        self.idleSeconds = idleSeconds
        self.deltaTime = deltaTime
        self.settings = settings
        self.needsAttention = needsAttention
    }
}

/// Estado interno de Clawd.
public struct PetState: Equatable, Sendable {
    public var screenID: UInt32
    public var place: Place
    /// Posición del ancla del sprite, en coordenadas globales.
    public var position: CGPoint
    public var facingLeft: Bool
    public var activity: Activity
    /// Segundos desde que empezó la actividad (también es el reloj de la animación).
    public var elapsed: TimeInterval
    /// Cuándo termina la actividad (.infinity = hasta llegar o aterrizar).
    public var duration: TimeInterval
    public var targetX: CGFloat?
    public var targetY: CGFloat?
    public var arrival: Arrival
    public var fallSpeed: CGFloat
    public var waveAfterLanding: Bool

    public init(
        screenID: UInt32, place: Place, position: CGPoint, facingLeft: Bool = false,
        activity: Activity, elapsed: TimeInterval = 0, duration: TimeInterval = .infinity,
        targetX: CGFloat? = nil, targetY: CGFloat? = nil, arrival: Arrival = .rest,
        fallSpeed: CGFloat = 0, waveAfterLanding: Bool = false
    ) {
        self.screenID = screenID
        self.place = place
        self.position = position
        self.facingLeft = facingLeft
        self.activity = activity
        self.elapsed = elapsed
        self.duration = duration
        self.targetX = targetX
        self.targetY = targetY
        self.arrival = arrival
        self.fallSpeed = fallSpeed
        self.waveAfterLanding = waveAfterLanding
    }
}

/// Lo que el cerebro le responde al cuerpo: cómo dibujar a Clawd en este tick.
public struct PetRenderState: Equatable, Sendable {
    public let animation: String
    public let frameIndex: Int
    public let anchorPosition: CGPoint
    public let frameRect: CGRect
    public let facingLeft: Bool
    public let opacity: Double
    /// La ventana debe aceptar clicks (⌥ sobre Clawd, o mientras lo cargas).
    public let acceptsClicks: Bool
    /// Para la frecuencia adaptativa: 30 fps si se mueve.
    public let isMoving: Bool
    public let isSleeping: Bool
}

/// Avisos del cerebro para el log.
public enum BrainEvent: Equatable, Sendable {
    case relocated(reason: String)
    case watchdogReset(activity: Activity, elapsed: TimeInterval)
    case zoneBecameHot(ZoneKey)
}
