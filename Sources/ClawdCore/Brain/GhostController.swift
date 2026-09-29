import CoreGraphics
import Foundation

enum GhostTransition: Equatable {
    case none, entered, exited
}

/// Decide si Clawd está en modo fantasma (semitransparente y los clicks lo atraviesan).
/// Usa histéresis, como un termostato: entra cerca y sale solo cuando llevas un rato lejos,
/// para que no parpadee si el mouse se queda justo en el límite.
struct GhostController {
    private(set) var isGhost = false
    /// Desde cuándo el mouse está lejos sin interrupción (nil = no está lejos).
    private var farSince: TimeInterval?

    mutating func update(
        distance: CGFloat, optionPressed: Bool, now: TimeInterval,
        enterDistance: CGFloat, exitDistance: CGFloat, exitDelay: TimeInterval
    ) -> GhostTransition {
        // Con ⌥ quieres interactuar con él: nunca fantasma.
        if optionPressed {
            farSince = nil
            if isGhost {
                isGhost = false
                return .exited
            }
            return .none
        }

        if !isGhost {
            guard distance <= enterDistance else { return .none }
            isGhost = true
            farSince = nil
            return .entered
        }

        guard distance > exitDistance else {
            farSince = nil
            return .none
        }
        let since = farSince ?? now
        farSince = since
        if now - since >= exitDelay {
            isGhost = false
            farSince = nil
            return .exited
        }
        return .none
    }
}
