import CoreGraphics
import Foundation

extension Brain {
    /// Medidas de una animación; si falta, las de idle; si también falta, las del cuerpo base.
    func info(_ name: String) -> AnimationInfo {
        infos[name] ?? infos[AnimationName.idle] ?? .fallback
    }

    /// Qué sprite corresponde a cada actividad según el lugar.
    static func animationName(for activity: Activity, place: Place) -> String {
        switch activity {
        case .idle: AnimationName.idle
        case .walk: AnimationName.walk
        case .lookAround: AnimationName.lookAround
        case .cook: AnimationName.cook
        case .climbUp, .climbDown: AnimationName.climb
        case .sit: AnimationName.sit
        case .hammock: AnimationName.hammock
        case .fall, .carried: AnimationName.fall
        case .land: AnimationName.land
        case .wave: AnimationName.wave
        case .dodge: AnimationName.dodge
        case .sleep:
            switch place {
            case .corner: AnimationName.sleepShelf
            case .hammock: AnimationName.sleepHammock
            default: AnimationName.sleepFloor
            }
        }
    }

    func screenWith(_ id: UInt32, in screens: [ScreenInfo]) -> ScreenInfo? {
        screens.first { $0.id == id }
    }

    func clamp(_ value: CGFloat, _ range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(value, range.lowerBound), range.upperBound)
    }

    /// Rango de x válido en el piso para que la animación no se salga de la pantalla,
    /// mire hacia donde mire (por eso usa la mitad más ancha del sprite).
    func floorRange(on screen: ScreenInfo, animation: String, scale: Int) -> ClosedRange<CGFloat> {
        let animationInfo = info(animation)
        let extent = CGFloat(max(animationInfo.anchor.x, animationInfo.width - animationInfo.anchor.x) * scale)
        let low = screen.visibleFrame.minX + extent
        let high = screen.visibleFrame.maxX - extent
        return low <= high ? low...high : screen.visibleFrame.midX...screen.visibleFrame.midX
    }

    /// Rango de y válido trepando por la pared derecha.
    func wallRange(on screen: ScreenInfo, scale: Int) -> ClosedRange<CGFloat> {
        let climb = info(AnimationName.climb)
        let low = screen.visibleFrame.minY + CGFloat((climb.height - climb.anchor.y) * scale)
        let high = screen.visibleFrame.maxY - CGFloat(climb.anchor.y * scale)
        return low <= high ? low...high : low...low
    }

    func cornerPosition(on screen: ScreenInfo) -> CGPoint {
        CGPoint(x: screen.visibleFrame.maxX, y: screen.visibleFrame.maxY)
    }

    /// La hamaca cuelga del techo, pegada a la pared derecha.
    func hammockPosition(on screen: ScreenInfo, scale: Int) -> CGPoint {
        let hammock = info(AnimationName.hammock)
        return CGPoint(
            x: screen.visibleFrame.maxX - CGFloat((hammock.width - hammock.anchor.x) * scale),
            y: screen.visibleFrame.maxY)
    }

    /// En la pared, la esquina y la hamaca el sprite nunca se refleja.
    func effectiveFacingLeft(_ state: PetState) -> Bool {
        (state.place == .floor || state.place == .air) ? state.facingLeft : false
    }

    func currentFrameRect(scale: Int) -> CGRect {
        guard let state else { return .null }
        let name = Brain.animationName(for: state.activity, place: state.place)
        return Geometry.frameRect(
            anchorPosition: state.position, info: info(name), scale: scale, facingLeft: effectiveFacingLeft(state))
    }

    func zoneKey(for state: PetState) -> ZoneKey {
        let zone: Zone = switch state.place {
        case .floor, .air: .floor
        case .wall: .wall
        case .corner, .hammock: .corner
        }
        return ZoneKey(screenID: state.screenID, zone: zone)
    }

    func randomDuration(_ activity: Activity) -> TimeInterval {
        guard let range = config.durations[activity] else { return .infinity }
        return random.next(in: range)
    }

    func randomX(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat(random.next(in: Double(range.lowerBound)...Double(range.upperBound)))
    }

    /// Cambia de actividad y reinicia el reloj de la animación.
    func begin(_ activity: Activity, duration: TimeInterval = .infinity) {
        state?.activity = activity
        state?.elapsed = 0
        state?.duration = duration
    }
}
