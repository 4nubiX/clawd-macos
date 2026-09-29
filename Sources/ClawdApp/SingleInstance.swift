import AppKit

enum SingleInstance {
    /// `true` si no hay otra copia de Clawd corriendo con el mismo bundle id.
    @MainActor
    static func isOnlyInstance() -> Bool {
        // Con `swift run` no hay bundle id: no aplica.
        guard let bundleID = Bundle.main.bundleIdentifier else { return true }
        let myPID = ProcessInfo.processInfo.processIdentifier
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .allSatisfy { $0.processIdentifier == myPID }
    }
}
