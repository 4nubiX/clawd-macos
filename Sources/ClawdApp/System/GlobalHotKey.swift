import AppKit
import Carbon.HIToolbox

/// Atajo de teclado global con la API de Carbon. A diferencia de escuchar todas
/// las teclas, esto NO requiere permiso de Accesibilidad.
@MainActor
final class GlobalHotKey {
    private static var actions: [UInt32: @MainActor () -> Void] = [:]
    private static var handlerInstalled = false
    private var hotKeyRef: EventHotKeyRef?

    /// `nil` si macOS no deja registrar el atajo (por ejemplo, si otra app ya lo usa).
    init?(keyCode: UInt32, modifiers: UInt32, id: UInt32, action: @escaping @MainActor () -> Void) {
        guard GlobalHotKey.installHandlerIfNeeded() else { return nil }
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C_5744), id: id)   // 'CLWD'
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        guard status == noErr else {
            Log.app.error("RegisterEventHotKey falló con código \(status)")
            return nil
        }
        GlobalHotKey.actions[id] = action
    }

    private static func installHandlerIfNeeded() -> Bool {
        if handlerInstalled { return true }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            let result = GetEventParameter(
                event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            guard result == noErr else { return result }
            let id = hotKeyID.id
            // Carbon entrega los atajos en el hilo principal.
            MainActor.assumeIsolated { GlobalHotKey.actions[id]?() }
            return noErr
        }, 1, &eventType, nil, nil)
        guard status == noErr else {
            Log.app.error("InstallEventHandler falló con código \(status)")
            return false
        }
        handlerInstalled = true
        return true
    }
}
