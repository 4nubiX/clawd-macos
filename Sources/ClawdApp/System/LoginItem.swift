import AppKit
import ServiceManagement

enum LoginItemError: LocalizedError {
    case noExecutable
    case notInstalled

    var errorDescription: String? {
        switch self {
        case .noExecutable: "No se encontró el ejecutable de Clawd."
        case .notInstalled: "Para abrir Clawd al iniciar sesión, primero instálalo con `make install` y ábrelo desde Aplicaciones."
        }
    }
}

/// "Abrir al iniciar sesión". Primero intenta SMAppService (lo moderno); si macOS lo
/// rechaza (pasa con apps firmadas localmente), usa un LaunchAgent como plan B (spec §7.2).
@MainActor
enum LoginItem {
    static let agentLabel = "com.4nubix.clawd"

    static var agentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(agentLabel).plist")
    }

    static var isEnabled: Bool {
        let status = SMAppService.mainApp.status
        return status == .enabled || status == .requiresApproval || FileManager.default.fileExists(atPath: agentURL.path)
    }

    /// Registrado, pero esperando que lo apruebes en Ajustes del Sistema.
    static var needsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            // Solo desde /Applications: si no, al iniciar sesión se abriría una copia vieja (p. ej. la de build/).
            guard Bundle.main.bundleURL.path.hasPrefix("/Applications/") else { throw LoginItemError.notInstalled }
            do {
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .requiresApproval {
                    // macOS pide confirmarlo en Ajustes; lo abrimos para el usuario.
                    SMAppService.openSystemSettingsLoginItems()
                }
                Log.app.info("Inicio de sesión activado con SMAppService")
            } catch {
                let status = SMAppService.mainApp.status
                if status == .enabled || status == .requiresApproval {
                    // Ya estaba registrado: no duplicamos el mecanismo con un LaunchAgent.
                    Log.app.notice("SMAppService ya estaba registrado (\(error.localizedDescription, privacy: .public)); no escribo LaunchAgent")
                    return
                }
                Log.app.notice("SMAppService falló (\(error.localizedDescription, privacy: .public)); uso LaunchAgent")
                try writeLaunchAgent()
            }
        } else {
            let status = SMAppService.mainApp.status
            if status == .enabled || status == .requiresApproval { try SMAppService.mainApp.unregister() }
            if FileManager.default.fileExists(atPath: agentURL.path) { try FileManager.default.removeItem(at: agentURL) }
            Log.app.info("Inicio de sesión desactivado")
        }
    }

    private static func writeLaunchAgent() throws {
        guard let executable = Bundle.main.executableURL else { throw LoginItemError.noExecutable }
        let plist: [String: Any] = [
            "Label": agentLabel,
            "ProgramArguments": [executable.path],
            "RunAtLoad": true,
            "ProcessType": "Interactive",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try FileManager.default.createDirectory(at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: agentURL, options: .atomic)
        Log.app.info("LaunchAgent escrito en \(agentURL.path, privacy: .public)")
    }
}
