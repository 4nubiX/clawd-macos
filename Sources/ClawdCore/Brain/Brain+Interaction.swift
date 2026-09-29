import CoreGraphics
import Foundation

extension Brain {
    /// ⌥ + arrastrar: lo cargas; al soltarlo cae en la pantalla más cercana.
    func handleDrag(_ world: WorldSnapshot, scale: Int) {
        guard var current = state else { return }
        if let anchor = world.dragAnchor {
            if current.activity != .carried {
                current.activity = .carried
                current.elapsed = 0
                current.duration = .infinity
                current.place = .air
                current.targetX = nil
                current.targetY = nil
            }
            current.position = anchor
            if let nearest = Geometry.nearestScreen(to: anchor, in: world.screens) { current.screenID = nearest.id }
            state = current
            return
        }
        guard current.activity == .carried,
              let screen = Geometry.nearestScreen(to: current.position, in: world.screens)
        else { return }
        let range = floorRange(on: screen, animation: AnimationName.fall, scale: scale)
        current.screenID = screen.id
        current.position = CGPoint(
            x: clamp(current.position.x, range),
            y: min(max(current.position.y, screen.visibleFrame.minY), screen.visibleFrame.maxY))
        current.activity = .fall
        current.elapsed = 0
        current.fallSpeed = 0
        state = current
    }

    /// Fantasma con histéresis. Al volverse fantasma cuenta un susto y se hace a un lado.
    func handleGhost(_ world: WorldSnapshot, scale: Int) {
        guard let current = state else { return }
        let distance = Geometry.distance(from: world.mouse, to: currentFrameRect(scale: scale))
        let transition = ghost.update(
            distance: distance, optionPressed: world.optionPressed, now: now,
            enterDistance: config.ghostEnterDistance, exitDistance: config.ghostExitDistance,
            exitDelay: config.ghostExitDelay)
        guard transition == .entered, current.activity != .carried else { return }
        let key = zoneKey(for: current)
        if hotZones.registerScare(key, at: now) { onEvent?(.zoneBecameHot(key)) }
        startDodge(world, scale: scale)
    }

    /// Hacerse a un lado para no estorbar.
    func startDodge(_ world: WorldSnapshot, scale: Int) {
        guard var current = state, let screen = screenWith(current.screenID, in: world.screens) else { return }
        switch (current.place, current.activity) {
        case (.floor, .idle), (.floor, .lookAround), (.floor, .cook), (.floor, .wave), (.floor, .land):
            // Brinquito y luego camina alejándose del mouse (o hacia el otro lado si no hay espacio).
            let body = CGFloat(info(AnimationName.idle).width * scale)
            let range = floorRange(on: screen, animation: AnimationName.walk, scale: scale)
            let away: CGFloat = world.mouse.x < current.position.x ? 1 : -1
            var target = clamp(current.position.x + away * config.dodgeDistanceInBodies * body, range)
            if abs(target - current.position.x) < body {
                target = clamp(current.position.x - away * config.dodgeDistanceInBodies * body, range)
            }
            current.targetX = target
            current.arrival = .rest
            current.activity = .dodge
            current.elapsed = 0
            current.duration = info(AnimationName.dodge).duration
            state = current
        case (.corner, .sit), (.corner, .wave), (.hammock, .hammock):
            // Arriba no hay a dónde hacerse: se baja. Si la esquina ya está caliente, de un salto.
            if hotZones.isHot(zoneKey(for: current), at: now) {
                startFall(scale: scale, screens: world.screens)
            } else {
                beginClimbDown(on: screen, scale: scale)
            }
        default:
            // Caminando, trepando, cayendo o dormido: ya se mueve, o no aplica.
            break
        }
    }

    /// ⌥ click: en el piso saluda; en otro lado se baja y saluda al aterrizar.
    func handleClick(_ world: WorldSnapshot, scale: Int) {
        guard var current = state, current.activity != .carried else { return }
        switch current.place {
        case .floor where current.activity == .land:
            current.waveAfterLanding = true
            state = current
        case .floor:
            current.activity = .wave
            current.elapsed = 0
            current.duration = config.waveDuration
            current.targetX = nil
            current.facingLeft = world.mouse.x < current.position.x
            state = current
        case .air:
            current.waveAfterLanding = true
            state = current
        case .wall, .corner, .hammock:
            startFall(scale: scale, screens: world.screens)
            state?.waveAfterLanding = true
        }
    }

    /// Dormir por inactividad (o "Dormir ahora") y despertar al volver.
    func handleSleep(_ world: WorldSnapshot) {
        guard let current = state else { return }
        let wantsSleep = !world.needsAttention
            && (world.settings.forceSleep || world.idleSeconds >= world.settings.sleepAfter)

        if current.activity == .sleep {
            guard !wantsSleep else { return }
            switch current.place {
            case .corner: begin(.sit, duration: randomDuration(.sit))
            case .hammock: begin(.hammock, duration: randomDuration(.hammock))
            default: begin(.idle, duration: randomDuration(.idle))
            }
            return
        }

        let restfulActivities: Set<Activity> = [.idle, .lookAround, .cook, .sit, .hammock]
        let restfulPlaces: Set<Place> = [.floor, .corner, .hammock]
        if wantsSleep, restfulActivities.contains(current.activity), restfulPlaces.contains(current.place) {
            begin(.sleep)
        }
    }
}
