import Foundation
import Testing
@testable import ClawdCore

@Suite("Zonas calientes")
struct HotZoneTrackerTests {
    let corner = ZoneKey(screenID: 1, zone: .corner)
    let floor = ZoneKey(screenID: 1, zone: .floor)

    func tracker() -> HotZoneTracker { HotZoneTracker(threshold: 3, window: 180, cooldown: 600) }

    /// `#expect` no acepta llamadas `mutating` adentro, así que las envolvemos.
    func scare(_ tracker: inout HotZoneTracker, _ key: ZoneKey, at time: TimeInterval) -> Bool {
        tracker.registerScare(key, at: time)
    }

    @Test("3 sustos en poco tiempo → zona caliente")
    func caliente() {
        var hot = tracker()
        #expect(!scare(&hot, corner, at: 0))
        #expect(!scare(&hot, corner, at: 10))
        #expect(scare(&hot, corner, at: 20))
        #expect(hot.isHot(corner, at: 100))
    }

    @Test("Sustos muy separados no cuentan")
    func separados() {
        var hot = tracker()
        #expect(!scare(&hot, corner, at: 0))
        #expect(!scare(&hot, corner, at: 200))
        #expect(!scare(&hot, corner, at: 400))
        #expect(!hot.isHot(corner, at: 401))
    }

    @Test("Se enfría después de 600 s")
    func seEnfria() {
        var hot = tracker()
        for time in [0.0, 10, 20] { _ = hot.registerScare(corner, at: time) }
        #expect(hot.isHot(corner, at: 619))
        #expect(!hot.isHot(corner, at: 621))
    }

    @Test("Cada zona lleva su propia cuenta")
    func independientes() {
        var hot = tracker()
        for time in [0.0, 10, 20] { _ = hot.registerScare(corner, at: time) }
        #expect(!hot.isHot(floor, at: 30))
    }
}
