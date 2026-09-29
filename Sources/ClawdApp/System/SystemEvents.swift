import AppKit

/// Escucha los eventos del sistema que afectan a Clawd: cambios de pantallas,
/// sueño de la Mac, pantallas dormidas y bloqueo de sesión.
@MainActor
final class SystemEvents {
    var onScreensChanged: (() -> Void)?
    /// (motivo, pausar): cada motivo se lleva por separado para no reanudar antes de tiempo.
    var onPause: ((String, Bool) -> Void)?

    private var tokens: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    func start() {
        observe(NotificationCenter.default, NSApplication.didChangeScreenParametersNotification) {
            $0.onScreensChanged?()
        }
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.willSleepNotification) { $0.onPause?("sueño", true) }
        observe(workspace, NSWorkspace.didWakeNotification) {
            $0.onScreensChanged?()
            $0.onPause?("sueño", false)
        }
        observe(workspace, NSWorkspace.screensDidSleepNotification) { $0.onPause?("pantallas", true) }
        observe(workspace, NSWorkspace.screensDidWakeNotification) { $0.onPause?("pantallas", false) }
        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Notification.Name("com.apple.screenIsLocked")) { $0.onPause?("bloqueo", true) }
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked")) { $0.onPause?("bloqueo", false) }
    }

    private func observe(
        _ center: NotificationCenter, _ name: Notification.Name,
        _ handler: @escaping @MainActor (SystemEvents) -> Void
    ) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            // queue: .main garantiza que ya estamos en el hilo principal.
            MainActor.assumeIsolated {
                guard let self else { return }
                handler(self)
            }
        }
        tokens.append((center: center, token: token))
    }
}
