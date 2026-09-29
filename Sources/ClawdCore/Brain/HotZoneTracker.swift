import Foundation

/// Lleva la cuenta de cuántas veces espantas a Clawd en cada zona.
/// Si lo espantas `threshold` veces dentro de `window` segundos, la zona se vuelve
/// "caliente" durante `cooldown` segundos y Clawd la evita.
struct HotZoneTracker {
    let threshold: Int
    let window: TimeInterval
    let cooldown: TimeInterval

    private var scares: [ZoneKey: [TimeInterval]] = [:]
    private var hotUntil: [ZoneKey: TimeInterval] = [:]

    init(threshold: Int, window: TimeInterval, cooldown: TimeInterval) {
        self.threshold = threshold
        self.window = window
        self.cooldown = cooldown
    }

    /// Registra un susto. Devuelve `true` si la zona se acaba de volver caliente.
    mutating func registerScare(_ key: ZoneKey, at now: TimeInterval) -> Bool {
        var recent = (scares[key] ?? []).filter { now - $0 <= window }
        recent.append(now)
        guard recent.count >= threshold else {
            scares[key] = recent
            return false
        }
        let wasHot = isHot(key, at: now)
        scares[key] = []
        hotUntil[key] = now + cooldown
        return !wasHot
    }

    func isHot(_ key: ZoneKey, at now: TimeInterval) -> Bool {
        (hotUntil[key] ?? -.infinity) > now
    }
}
