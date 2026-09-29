import AppKit
import ClawdCore

/// Icono de Clawd en la barra de menú y su menú.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let controller: PetController
    private let settings: SettingsStore
    /// Si el atajo ⌃⌥⌘C no se pudo registrar, el menú no debe anunciarlo.
    private let hotKeyAvailable: Bool

    init(controller: PetController, settings: SettingsStore, library: SpriteLibrary, hotKeyAvailable: Bool) {
        self.controller = controller
        self.settings = settings
        self.hotKeyAvailable = hotKeyAvailable
        super.init()

        if let idle = library.animations[AnimationName.idle],
           let cgImage = FrameRasterizer.image(from: idle.frames[0], pixelScale: 2) {
            // 2 pixeles por pixel del sprite, mostrado a 1 pt: nítido en pantallas Retina.
            statusItem.button?.image = NSImage(cgImage: cgImage, size: NSSize(width: idle.width, height: idle.height))
        } else {
            statusItem.button?.title = "Clawd"
        }
        statusItem.button?.toolTip = "Clawd"
        menu.delegate = self
        statusItem.menu = menu
    }

    /// Se reconstruye cada vez que se abre, para que las palomitas estén al día.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let sizeMenu = NSMenu()
        for (size, title) in [(PetSize.small, "Chico"), (.medium, "Mediano"), (.large, "Grande")] {
            let item = NSMenuItem(title: title, action: #selector(selectSize(_:)), keyEquivalent: "")
            item.target = self
            item.tag = size.rawValue
            item.state = settings.size == size ? .on : .off
            sizeMenu.addItem(item)
        }
        let sizeItem = NSMenuItem(title: "Tamaño", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        let hotKeyHint = hotKeyAvailable ? " (⌃⌥⌘C)" : " (atajo no disponible)"
        menu.addItem(item((settings.isHidden ? "Mostrar a Clawd" : "Esconder a Clawd") + hotKeyHint, #selector(toggleHidden)))
        menu.addItem(item(settings.forceSleep ? "Despertar" : "Dormir ahora", #selector(toggleSleep)))
        menu.addItem(.separator())
        menu.addItem(item("Ocultar al compartir pantalla", #selector(toggleHideWhenSharing), on: settings.hideWhenSharing))
        menu.addItem(item("Abrir al iniciar sesión" + (LoginItem.needsApproval ? " (pendiente de aprobar en Ajustes)" : ""), #selector(toggleLaunchAtLogin), on: LoginItem.isEnabled))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Salir de Clawd", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func item(_ title: String, _ action: Selector, on: Bool? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        if let on { item.state = on ? .on : .off }
        return item
    }

    @objc private func selectSize(_ sender: NSMenuItem) {
        guard let size = PetSize(rawValue: sender.tag) else { return }
        settings.size = size
    }

    @objc private func toggleHidden() { controller.toggleHidden() }

    @objc private func toggleSleep() { settings.forceSleep.toggle() }

    @objc private func toggleHideWhenSharing() { settings.hideWhenSharing.toggle() }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LoginItem.setEnabled(!LoginItem.isEnabled)
        } catch {
            Log.app.error("No se pudo cambiar 'Abrir al iniciar sesión': \(error.localizedDescription, privacy: .public)")
            let alert = NSAlert()
            alert.messageText = "No se pudo cambiar \"Abrir al iniciar sesión\""
            alert.informativeText = error.localizedDescription
            // Clawd es una app accesoria: sin esto la alerta podría quedar detrás de otras ventanas.
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}
