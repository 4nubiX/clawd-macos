import Foundation

/// Lo que Clawd "quiere" hacer a continuación.
public enum Intention: String, CaseIterable, Sendable {
    case idle, lookAround, wander, cook, goToCorner, stroll, goHome, sit, hammock, climbDown, jumpDown
}

/// Lo que el planeador necesita saber para decidir.
struct PlannerContext: Equatable {
    var place: Place
    var onHomeScreen: Bool
    var hasOtherScreens: Bool
    var cornerIsHot: Bool
    var floorIsHot: Bool
}

/// Elige la siguiente actividad al azar pero con pesos, sin repetir la anterior
/// y respetando los tiempos de espera de las actividades especiales.
struct ActivityPlanner {
    let cooldowns: [Intention: TimeInterval]
    private(set) var lastIntention: Intention?
    private var availableAt: [Intention: TimeInterval] = [:]

    init(cooldowns: [Intention: TimeInterval]) {
        self.cooldowns = cooldowns
    }

    func weights(for context: PlannerContext) -> [(Intention, Double)] {
        switch context.place {
        case .floor:
            // Si lo espantan mucho en el piso, deja de quedarse quieto ahí.
            let calm: Double = context.floorIsHot ? 0 : 1
            var list: [(Intention, Double)] = [
                (.idle, 3 * calm),
                (.lookAround, 2 * calm),
                (.wander, 3),
                (.cook, 1 * calm),
                (.goToCorner, context.cornerIsHot ? 0 : 4),
            ]
            if !context.onHomeScreen {
                list.append((.goHome, 8))
            } else if context.hasOtherScreens {
                list.append((.stroll, 1))
            }
            return list
        case .corner:
            return context.cornerIsHot
                ? [(.climbDown, 1), (.jumpDown, 1)]
                : [(.sit, 4), (.hammock, 2), (.climbDown, 1), (.jumpDown, 1)]
        case .hammock:
            return context.cornerIsHot ? [(.jumpDown, 1)] : [(.sit, 2), (.jumpDown, 1)]
        case .wall, .air:
            return []
        }
    }

    mutating func choose(_ context: PlannerContext, random: inout any RandomSource, now: TimeInterval) -> Intention {
        var options = weights(for: context).filter { $0.1 > 0 && (availableAt[$0.0] ?? 0) <= now }
        let fresh = options.filter { $0.0 != lastIntention }
        if !fresh.isEmpty { options = fresh }
        guard let lastOption = options.last else { return fallback(for: context.place) }

        let total = options.reduce(0) { $0 + $1.1 }
        var roll = random.nextUnit() * total
        var picked = lastOption.0
        for (intention, weight) in options {
            if roll < weight {
                picked = intention
                break
            }
            roll -= weight
        }

        lastIntention = picked
        if let cooldown = cooldowns[picked] { availableAt[picked] = now + cooldown }
        return picked
    }

    func fallback(for place: Place) -> Intention {
        switch place {
        case .corner: .climbDown
        case .hammock: .jumpDown
        default: .idle
        }
    }
}
