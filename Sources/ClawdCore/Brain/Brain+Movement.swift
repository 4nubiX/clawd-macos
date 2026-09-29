import CoreGraphics
import Foundation

extension Brain {
    // MARK: - Avanzar la actividad actual

    func advance(dt: TimeInterval, world: WorldSnapshot, scale: Int) {
        guard let current = state else { return }
        state?.elapsed += dt
        switch current.activity {
        case .walk: stepWalk(dt: dt, world: world, scale: scale)
        case .climbUp, .climbDown: stepClimb(dt: dt, world: world, scale: scale)
        case .fall: stepFall(dt: dt, world: world, scale: scale)
        case .carried, .sleep: break
        default:
            if let updated = state, updated.elapsed >= updated.duration {
                finishTimedActivity(world, scale: scale)
            }
        }
    }

    func stepWalk(dt: TimeInterval, world: WorldSnapshot, scale: Int) {
        guard var current = state, let target = current.targetX else {
            chooseNext(world, scale: scale)
            return
        }
        let step = config.walkSpeedPerScale * CGFloat(scale) * CGFloat(dt)
        let dx = target - current.position.x
        if abs(dx) <= step {
            current.position.x = target
            state = current
            arrive(world, scale: scale)
        } else {
            current.position.x += dx > 0 ? step : -step
            current.facingLeft = dx < 0
            state = current
        }
    }

    func stepClimb(dt: TimeInterval, world: WorldSnapshot, scale: Int) {
        guard var current = state, let target = current.targetY else {
            chooseNext(world, scale: scale)
            return
        }
        let step = config.climbSpeedPerScale * CGFloat(scale) * CGFloat(dt)
        let dy = target - current.position.y
        if abs(dy) <= step {
            current.position.y = target
            state = current
            arrive(world, scale: scale)
        } else {
            current.position.y += dy > 0 ? step : -step
            state = current
        }
    }

    func stepFall(dt: TimeInterval, world: WorldSnapshot, scale: Int) {
        guard var current = state, let screen = screenWith(current.screenID, in: world.screens) else { return }
        current.fallSpeed = min(current.fallSpeed + config.gravity * CGFloat(dt), config.maxFallSpeed)
        current.position.y -= current.fallSpeed * CGFloat(dt)
        let floorY = screen.visibleFrame.minY
        if current.position.y <= floorY {
            current.position.y = floorY
            current.position.x = clamp(current.position.x, floorRange(on: screen, animation: AnimationName.walk, scale: scale))
            current.place = .floor
            current.fallSpeed = 0
            current.activity = .land
            current.elapsed = 0
            current.duration = info(AnimationName.land).duration
        }
        state = current
    }

    func finishTimedActivity(_ world: WorldSnapshot, scale: Int) {
        guard var current = state else { return }
        switch current.activity {
        case .land where current.waveAfterLanding:
            current.waveAfterLanding = false
            current.activity = .wave
            current.elapsed = 0
            current.duration = config.waveDuration
            current.facingLeft = world.mouse.x < current.position.x
            state = current
        case .dodge where current.targetX != nil:
            // Después del brinquito, camina a su nuevo lugar.
            current.activity = .walk
            current.elapsed = 0
            current.duration = .infinity
            current.arrival = .rest
            state = current
        default:
            chooseNext(world, scale: scale)
        }
    }

    // MARK: - Llegar a un destino

    func arrive(_ world: WorldSnapshot, scale: Int) {
        guard let current = state, let screen = screenWith(current.screenID, in: world.screens) else { return }
        let arrival = current.arrival
        state?.targetX = nil
        state?.targetY = nil
        state?.arrival = .rest

        switch arrival {
        case .rest:
            begin(.idle, duration: randomDuration(.idle))
        case .startCooking:
            state?.facingLeft = false
            begin(.cook, duration: randomDuration(.cook))
        case .climbWall:
            beginClimbUp(on: screen, scale: scale)
        case .sitInCorner:
            state?.place = .corner
            state?.position = cornerPosition(on: screen)
            state?.facingLeft = false
            begin(.sit, duration: randomDuration(.sit))
        case .standOnFloor:
            state?.place = .floor
            state?.position = CGPoint(
                x: floorRange(on: screen, animation: AnimationName.walk, scale: scale).upperBound,
                y: screen.visibleFrame.minY)
            state?.facingLeft = true
            begin(.idle, duration: randomDuration(.idle))
        case .cross(toScreen: let destinationID):
            guard let destination = screenWith(destinationID, in: world.screens) else {
                begin(.idle, duration: randomDuration(.idle))
                return
            }
            state?.screenID = destination.id
            if current.position.y > destination.visibleFrame.minY + 0.5 {
                // El piso del otro monitor está más abajo: se deja caer.
                state?.place = .air
                state?.fallSpeed = 0
                begin(.fall)
            } else {
                begin(.idle, duration: randomDuration(.idle))
            }
        }
    }

    func beginClimbUp(on screen: ScreenInfo, scale: Int) {
        let range = wallRange(on: screen, scale: scale)
        state?.place = .wall
        state?.position = CGPoint(x: screen.visibleFrame.maxX, y: range.lowerBound)
        state?.targetY = range.upperBound
        state?.arrival = .sitInCorner
        state?.facingLeft = false
        begin(.climbUp)
    }

    func beginClimbDown(on screen: ScreenInfo, scale: Int) {
        let range = wallRange(on: screen, scale: scale)
        state?.place = .wall
        state?.position = CGPoint(x: screen.visibleFrame.maxX, y: range.upperBound)
        state?.targetY = range.lowerBound
        state?.arrival = .standOnFloor
        state?.facingLeft = false
        begin(.climbDown)
    }

    func walk(to x: CGFloat, arrival: Arrival) {
        guard let current = state else { return }
        state?.targetX = x
        state?.arrival = arrival
        state?.facingLeft = x < current.position.x
        begin(.walk)
    }

    /// Ir a otra pantalla: caminando si se tocan, o apareciendo desde arriba si no.
    func travel(from origin: ScreenInfo, to destination: ScreenInfo, scale: Int) {
        switch Geometry.crossing(from: origin, to: destination) {
        case .walk(let edgeX, let direction):
            // Camina hasta quedar completamente del otro lado de la orilla.
            let extent = CGFloat(info(AnimationName.walk).width * scale)
            walk(to: edgeX + direction * extent, arrival: .cross(toScreen: destination.id))
        case .dropIn:
            dropIn(onto: destination, scale: scale)
        }
    }

    // MARK: - Elegir lo siguiente

    func chooseNext(_ world: WorldSnapshot, scale: Int) {
        guard let current = state, let screen = screenWith(current.screenID, in: world.screens) else { return }
        let home = Geometry.homeScreen(in: world.screens)
        let context = PlannerContext(
            place: current.place,
            onHomeScreen: home?.id == current.screenID,
            hasOtherScreens: world.screens.count > 1,
            cornerIsHot: hotZones.isHot(ZoneKey(screenID: current.screenID, zone: .corner), at: now),
            floorIsHot: hotZones.isHot(ZoneKey(screenID: current.screenID, zone: .floor), at: now))
        let intention = planner.choose(context, random: &random, now: now)
        apply(intention, on: screen, world: world, scale: scale)
    }

    func apply(_ intention: Intention, on screen: ScreenInfo, world: WorldSnapshot, scale: Int) {
        guard let current = state else { return }
        switch intention {
        case .idle:
            begin(.idle, duration: randomDuration(.idle))
        case .lookAround:
            begin(.lookAround, duration: randomDuration(.lookAround))
        case .wander:
            walk(to: randomX(in: floorRange(on: screen, animation: AnimationName.walk, scale: scale)), arrival: .rest)
        case .cook:
            // La sartén sale a la derecha: primero se acomoda donde quepa.
            let x = clamp(current.position.x, floorRange(on: screen, animation: AnimationName.cook, scale: scale))
            if abs(x - current.position.x) < 0.5 {
                state?.facingLeft = false
                begin(.cook, duration: randomDuration(.cook))
            } else {
                walk(to: x, arrival: .startCooking)
            }
        case .goToCorner:
            walk(to: floorRange(on: screen, animation: AnimationName.walk, scale: scale).upperBound, arrival: .climbWall)
        case .stroll:
            let others = world.screens.filter { $0.id != screen.id }
            guard !others.isEmpty else {
                begin(.idle, duration: randomDuration(.idle))
                return
            }
            let index = min(Int(random.nextUnit() * Double(others.count)), others.count - 1)
            travel(from: screen, to: others[index], scale: scale)
        case .goHome:
            guard let home = Geometry.homeScreen(in: world.screens), home.id != screen.id else {
                begin(.idle, duration: randomDuration(.idle))
                return
            }
            travel(from: screen, to: home, scale: scale)
        case .sit:
            state?.place = .corner
            state?.position = cornerPosition(on: screen)
            begin(.sit, duration: randomDuration(.sit))
        case .hammock:
            state?.place = .hammock
            state?.position = hammockPosition(on: screen, scale: scale)
            begin(.hammock, duration: randomDuration(.hammock))
        case .climbDown:
            beginClimbDown(on: screen, scale: scale)
        case .jumpDown:
            startFall(scale: scale, screens: world.screens)
        }
    }

    // MARK: - Perro guardián, opacidad y render

    /// Si una actividad se pasa de su duración máxima, algo salió mal: de vuelta a idle en el piso.
    func runWatchdog(_ screens: [ScreenInfo], scale: Int) {
        guard let current = state, let limit = config.maxDurations[current.activity], current.elapsed > limit else { return }
        onEvent?(.watchdogReset(activity: current.activity, elapsed: current.elapsed))
        guard let screen = screenWith(current.screenID, in: screens) ?? Geometry.homeScreen(in: screens) else { return }
        let range = floorRange(on: screen, animation: AnimationName.walk, scale: scale)
        state = PetState(
            screenID: screen.id, place: .floor,
            position: CGPoint(x: clamp(current.position.x, range), y: screen.visibleFrame.minY),
            activity: .idle, duration: randomDuration(.idle))
    }

    /// Fundido suave hacia la opacidad objetivo (fantasma o normal).
    func updateOpacity(dt: TimeInterval) {
        let target = ghost.isGhost ? config.ghostOpacity : 1
        let step = (1 - config.ghostOpacity) / config.fadeDuration * dt
        opacity = opacity < target ? min(opacity + step, target) : max(opacity - step, target)
    }

    func render(_ world: WorldSnapshot, scale: Int) -> PetRenderState? {
        guard let current = state else { return nil }
        let name = Brain.animationName(for: current.activity, place: current.place)
        let animationInfo = info(name)
        let facingLeft = effectiveFacingLeft(current)
        let rect = Geometry.frameRect(anchorPosition: current.position, info: animationInfo, scale: scale, facingLeft: facingLeft)
        let moving: Set<Activity> = [.walk, .climbUp, .climbDown, .fall, .carried, .dodge]
        return PetRenderState(
            animation: name,
            frameIndex: animationInfo.frameIndex(at: current.elapsed),
            anchorPosition: current.position,
            frameRect: rect,
            facingLeft: facingLeft,
            opacity: opacity,
            acceptsClicks: current.activity == .carried || (world.optionPressed && rect.contains(world.mouse)),
            isMoving: moving.contains(current.activity),
            isSleeping: current.activity == .sleep)
    }
}
