import ClawdCore
import Foundation

/// Preferencias de Clawd. Las persistentes van en UserDefaults y sobreviven a reinicios.
@MainActor
final class SettingsStore {
    private enum Key {
        static let size = "tamano"
        static let hideWhenSharing = "ocultarAlCompartir"
        static let sleepAfter = "dormirTrasSegundos"
    }

    private let defaults: UserDefaults
    /// Se llama cada vez que algo cambia, para que la ventana se actualice.
    var onChange: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.size: PetSize.medium.rawValue,
            Key.hideWhenSharing: true,
            Key.sleepAfter: 300.0,
        ])
    }

    var size: PetSize {
        get { PetSize(rawValue: defaults.integer(forKey: Key.size)) ?? .medium }
        set {
            defaults.set(newValue.rawValue, forKey: Key.size)
            onChange?()
        }
    }

    var hideWhenSharing: Bool {
        get { defaults.bool(forKey: Key.hideWhenSharing) }
        set {
            defaults.set(newValue, forKey: Key.hideWhenSharing)
            onChange?()
        }
    }

    var sleepAfter: TimeInterval { defaults.double(forKey: Key.sleepAfter) }

    // Estos dos NO se guardan: al reiniciar, Clawd arranca visible y despierto.
    var isHidden = false { didSet { onChange?() } }
    var forceSleep = false { didSet { onChange?() } }

    var petSettings: PetSettings {
        PetSettings(scale: size.rawValue, sleepAfter: sleepAfter, forceSleep: forceSleep)
    }
}
