import CoreGraphics
import Foundation

extension Brain {
    /// Se asegura de que Clawd esté en una pantalla que existe y en una posición válida.
    func validatePlacement(_ screens: [ScreenInfo], scale: Int) {
        guard let current = state else {
            if let home = Geometry.homeScreen(in: screens) { dropIn(onto: home, scale: scale) }
            lastScreens = screens
            onEvent?(.relocated(reason: "inicio"))
            return
        }
        guard let screen = screenWith(current.screenID, in: screens) else {
            if let home = Geometry.homeScreen(in: screens) { dropIn(onto: home, scale: scale) }
            lastScreens = screens
            onEvent?(.relocated(reason: "la pantalla \(current.screenID) ya no existe"))
            return
        }
        if screens != lastScreens {
            lastScreens = screens
            snap(to: screen, scale: scale)
        }
        // Red de seguridad: el ancla debe estar dentro de alguna pantalla (salvo si lo cargas).
        if let state, state.activity != .carried {
            let inside = screens.contains { $0.frame.insetBy(dx: -1, dy: -1).contains(state.position) }
            if !inside, let home = Geometry.homeScreen(in: screens) {
                dropIn(onto: home, scale: scale)
                onEvent?(.relocated(reason: "quedó fuera de pantalla en \(state.position)"))
            }
        }
    }

    /// Reacomoda a Clawd cuando cambian las medidas de su pantalla (resolución, Dock, etc.).
    func snap(to screen: ScreenInfo, scale: Int) {
        guard var current = state else { return }
        switch current.place {
        case .floor:
            let range = floorRange(on: screen, animation: AnimationName.walk, scale: scale)
            current.position = CGPoint(x: clamp(current.position.x, range), y: screen.visibleFrame.minY)
            if current.activity == .walk {
                // El destino pudo quedar fuera; mejor quedarse quieto y volver a decidir.
                current.activity = .idle
                current.elapsed = 0
                current.duration = randomDuration(.idle)
                current.targetX = nil
                current.arrival = .rest
            }
        case .wall:
            let range = wallRange(on: screen, scale: scale)
            current.position = CGPoint(x: screen.visibleFrame.maxX, y: clamp(current.position.y, range))
            if current.activity == .climbUp { current.targetY = range.upperBound }
            if current.activity == .climbDown { current.targetY = range.lowerBound }
        case .corner:
            current.position = cornerPosition(on: screen)
        case .hammock:
            current.position = hammockPosition(on: screen, scale: scale)
        case .air:
            current.position.x = clamp(current.position.x, floorRange(on: screen, animation: AnimationName.fall, scale: scale))
        }
        state = current
    }

    /// Aparece cayendo desde arriba, del lado derecho (su lado favorito) de la pantalla.
    func dropIn(onto screen: ScreenInfo, scale: Int) {
        let body = info(AnimationName.idle)
        let range = floorRange(on: screen, animation: AnimationName.fall, scale: scale)
        let x = clamp(screen.visibleFrame.maxX - 4 * CGFloat(body.width * scale), range)
        let y = max(screen.visibleFrame.maxY - CGFloat(body.height * scale), screen.visibleFrame.minY)
        state = PetState(screenID: screen.id, place: .air, position: CGPoint(x: x, y: y), activity: .fall)
    }

    /// Empieza a caer desde donde está dibujado ahora (esquina, hamaca o pared).
    func startFall(scale: Int, screens: [ScreenInfo]) {
        guard var current = state, let screen = screenWith(current.screenID, in: screens) else { return }
        let rect = currentFrameRect(scale: scale)
        let range = floorRange(on: screen, animation: AnimationName.fall, scale: scale)
        current.place = .air
        current.position = CGPoint(x: clamp(rect.midX, range), y: max(rect.minY, screen.visibleFrame.minY))
        current.activity = .fall
        current.elapsed = 0
        current.duration = .infinity
        current.fallSpeed = 0
        current.targetX = nil
        current.targetY = nil
        current.arrival = .rest
        current.waveAfterLanding = false
        state = current
    }
}
