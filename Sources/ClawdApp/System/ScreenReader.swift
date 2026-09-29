import AppKit
import ClawdCore

@MainActor
enum ScreenReader {
    /// Las pantallas actuales con su marco y su área útil (sin barra de menú ni Dock).
    static func current() -> [ScreenInfo] {
        NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                Log.system.error("Una pantalla no tiene NSScreenNumber; se ignora")
                return nil
            }
            return ScreenInfo(id: number.uint32Value, frame: screen.frame, visibleFrame: screen.visibleFrame)
        }
    }
}
