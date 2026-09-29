import AppKit
import Carbon.HIToolbox
import ClawdCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var petController: PetController?
    private var menuBarController: MenuBarController?
    private var hideHotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard SingleInstance.isOnlyInstance() else {
            Log.app.notice("Ya hay un Clawd corriendo; esta copia se cierra.")
            NSApp.terminate(nil)
            return
        }

        let library = SpriteLoader.load()
        for failure in library.failures {
            Log.sprites.error("Sprite con problemas: \(failure.description, privacy: .public)")
        }
        guard library.animations[AnimationName.idle] != nil else {
            let alert = NSAlert()
            alert.messageText = "Clawd no encontró sus sprites"
            alert.informativeText = "Falta la animación 'idle'. Revisa el log en Console.app (filtra por \"Clawd\")."
            alert.runModal()
            NSApp.terminate(nil)
            return
        }

        let settings = SettingsStore()
        let controller = PetController(library: library, settings: settings)
        petController = controller

        // ⌃⌥⌘C: esconder o mostrar a Clawd al instante (plan B garantizado para videollamadas).
        hideHotKey = GlobalHotKey(
            keyCode: UInt32(kVK_ANSI_C), modifiers: UInt32(cmdKey | optionKey | controlKey), id: 1
        ) { [weak controller] in
            controller?.toggleHidden()
        }
        if hideHotKey == nil { Log.app.error("No se pudo registrar el atajo ⌃⌥⌘C") }

        menuBarController = MenuBarController(controller: controller, settings: settings, library: library, hotKeyAvailable: hideHotKey != nil)

        controller.start()
        Log.app.info("Clawd arrancó con \(library.animations.count) animaciones")
    }
}
