import CoreGraphics
import Foundation
import Testing
@testable import ClawdCore

@Suite("Modo fantasma")
struct GhostControllerTests {
    func update(_ ghost: inout GhostController, _ distance: CGFloat, at time: TimeInterval, option: Bool = false) -> GhostTransition {
        ghost.update(distance: distance, optionPressed: option, now: time, enterDistance: 40, exitDistance: 80, exitDelay: 1)
    }

    @Test("Entra a 40 pt o menos")
    func entra() {
        var ghost = GhostController()
        #expect(update(&ghost, 41, at: 0) == .none)
        #expect(update(&ghost, 40, at: 0.1) == .entered)
        #expect(ghost.isGhost)
    }

    @Test("Entre 40 y 80 pt se queda fantasma (no parpadea)")
    func zonaIntermedia() {
        var ghost = GhostController()
        _ = update(&ghost, 30, at: 0)
        #expect(update(&ghost, 60, at: 5) == .none)
        #expect(ghost.isGhost)
    }

    @Test("Sale solo tras 1 s seguido a más de 80 pt")
    func sale() {
        var ghost = GhostController()
        _ = update(&ghost, 30, at: 0)
        #expect(update(&ghost, 100, at: 0.1) == .none)
        #expect(update(&ghost, 100, at: 0.9) == .none)
        #expect(update(&ghost, 100, at: 1.2) == .exited)
        #expect(!ghost.isGhost)
    }

    @Test("Si el mouse regresa, el reloj se reinicia")
    func relojSeReinicia() {
        var ghost = GhostController()
        _ = update(&ghost, 30, at: 0)
        _ = update(&ghost, 100, at: 0.1)
        _ = update(&ghost, 60, at: 0.5)
        #expect(update(&ghost, 100, at: 1.2) == .none)
        #expect(update(&ghost, 100, at: 2.3) == .exited)
    }

    @Test("Con ⌥ presionado sale al instante y no vuelve a entrar")
    func conOption() {
        var ghost = GhostController()
        _ = update(&ghost, 10, at: 0)
        #expect(update(&ghost, 10, at: 1, option: true) == .exited)
        #expect(update(&ghost, 10, at: 2, option: true) == .none)
        #expect(!ghost.isGhost)
    }
}
