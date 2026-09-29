import AppKit

/// Dibuja el cuadro actual escalado sin suavizado (pixel art nítido).
@MainActor
final class PetView: NSView {
    var image: CGImage? {
        didSet { needsDisplay = true }
    }
    var mirrored = false {
        didSet { if oldValue != mirrored { needsDisplay = true } }
    }
    var onMouseDown: (() -> Void)?
    var onMouseDragged: (() -> Void)?
    var onMouseUp: (() -> Void)?

    // El click funciona aunque la ventana no esté activa.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let image, let context = NSGraphicsContext.current?.cgContext else { return }
        context.clear(bounds)
        context.interpolationQuality = .none
        if mirrored {
            context.translateBy(x: bounds.width, y: 0)
            context.scaleBy(x: -1, y: 1)
        }
        context.draw(image, in: bounds)
    }

    override func mouseDown(with event: NSEvent) { onMouseDown?() }
    override func mouseDragged(with event: NSEvent) { onMouseDragged?() }
    override func mouseUp(with event: NSEvent) { onMouseUp?() }
}
