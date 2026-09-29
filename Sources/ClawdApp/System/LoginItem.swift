import AppKit
import ServiceManagement

enum LoginItemError: LocalizedError {
    case noExecutable

    var errorDescription: String? {
        switch self {
        case .noExecutable: "No se encontró el ejecutable de Clawd."
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
        SMAppService.mainApp.status == .enabled || FileManager.default.fileExists(atPath: agentURL.path)
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            do {
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .requiresApproval {
                    // macOS pide confirmarlo en Ajustes; lo abrimos para el usuario.
                    SMAppService.openSystemSettingsLoginItems()
                }
                Log.app.info("Inicio de sesión activado con SMAppService")
            } catch {
                Log.app.notice("SMAppService falló (\(error.localizedDescription, privacy: .public)); uso LaunchAgent")
                try writeLaunchAgent()
            }
        } else {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
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
