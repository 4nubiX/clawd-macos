import AppKit

// Punto de entrada. Política "accessory": sin icono en el Dock (el .app también lo marca con LSUIElement).
let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.setActivationPolicy(.accessory)
application.run()
