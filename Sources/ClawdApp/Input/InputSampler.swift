import AppKit
import CoreGraphics

/// Lee el mouse, el teclado y la inactividad. Nada de esto requiere permisos de macOS.
@MainActor
enum InputSampler {
    static var mouseLocation: CGPoint { NSEvent.mouseLocation }

    static var optionPressed: Bool { NSEvent.modifierFlags.contains(.option) }

    /// Segundos desde la última vez que tocaste el mouse o el teclado.
    static var idleSeconds: TimeInterval {
        // UInt32.max = kCGAnyInputEventType ("cualquier evento de entrada").
        guard let anyInput = CGEventType(rawValue: UInt32.max) else { return 0 }
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }
}
