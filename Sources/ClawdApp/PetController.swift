import AppKit
import ClawdCore

/// Une el cerebro con la ventana: en cada tick arma la "foto" del mundo, le pregunta
/// al cerebro qué hacer y actualiza la ventana.
@MainActor
final class PetController {
    private let library: SpriteLibrary
    private let images: FrameImageCache
    private let brain: Brain
    private let settings: SettingsStore
    private let window = PetWindow()
    private let view = PetView(frame: .zero)
    private let events = SystemEvents()

    private var screens: [ScreenInfo] = []
    private var timer: Timer?
    private var currentFPS: Double = 0
    private var lastTickTime = ProcessInfo.processInfo.systemUptime
    private var pauseReasons: Set<String> = []
    private var lastRender: PetRenderState?

    // Interacción con ⌥ (click y arrastre).
    private var pendingClick = false
    private var mouseDownLocation: CGPoint?
    private var dragAnchor: CGPoint?
    private var dragOffset = CGVector.zero

    init(library: SpriteLibrary, settings: SettingsStore) {
        self.library = library
        self.images = FrameImageCache(library: library)
        self.brain = Brain(infos: library.infos, random: SystemRandom())
        self.settings = settings

        brain.onEvent = { event in
            Log.brain.notice("\(String(describing: event), privacy: .public)")
        }
        window.contentView = view
        view.onMouseDown = { [weak self] in self?.mouseDown() }
        view.onMouseDragged = { [weak self] in self?.mouseDragged() }
        view.onMouseUp = { [weak self] in self?.mouseUp() }
        settings.onChange = { [weak self] in self?.refreshRunState() }
    }

    func start() {
        screens = ScreenReader.current()
        events.onScreensChanged = { [weak self] in self?.refreshScreens() }
        events.onPause = { [weak self] reason, paused in self?.setPaused(paused, reason: reason) }
        events.start()
        refreshRunState()
    }

    func toggleHidden() {
        settings.isHidden.toggle()
    }

    // MARK: - Estado de ejecución

    private func refreshScreens() {
        screens = ScreenReader.current()
        Log.system.info("Pantallas actualizadas: \(self.screens.count)")
    }

    private func setPaused(_ paused: Bool, reason: String) {
        if paused { pauseReasons.insert(reason) } else { pauseReasons.remove(reason) }
        Log.system.info("Pausa '\(reason, privacy: .public)': \(paused)")
        refreshRunState()
    }

    /// Aplica ajustes y decide si el bucle corre o se detiene (escondido o en pausa).
    private func refreshRunState() {
        window.sharingType = settings.hideWhenSharing ? .none : .readOnly
        if settings.isHidden || !pauseReasons.isEmpty {
            cancelGesture()
            window.orderOut(nil)
            schedule(fps: 0)
        } else {
            schedule(fps: 30)
        }
    }

    // MARK: - Bucle

    /// Frecuencia adaptativa: 30 fps moviéndose, 12 quieto, 2 dormido, 0 en pausa.
    private func schedule(fps: Double) {
        guard fps != currentFPS else { return }
        currentFPS = fps
        timer?.invalidate()
        timer = nil
        guard fps > 0 else { return }
        let newTimer = Timer(timeInterval: 1 / fps, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // .common: sigue corriendo mientras arrastras o abres un menú.
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func tick() {
        let time = ProcessInfo.processInfo.systemUptime
        let delta = time - lastTickTime
        lastTickTime = time

        let snapshot = WorldSnapshot(
            screens: screens,
            mouse: InputSampler.mouseLocation,
            optionPressed: InputSampler.optionPressed,
            clicked: pendingClick,
            dragAnchor: dragAnchor,
            idleSeconds: InputSampler.idleSeconds,
            deltaTime: delta,
            settings: settings.petSettings,
            needsAttention: false)
        pendingClick = false

        guard let render = brain.tick(snapshot) else {
            cancelGesture()
            window.orderOut(nil)
            return
        }
        apply(render, mouse: snapshot.mouse)
        // Con ⌥ presionado va a 30 fps para que el hit-test del ratón responda al instante.
        let fps: Double = (render.isMoving || dragAnchor != nil || snapshot.optionPressed) ? 30 : (render.isSleeping ? 2 : 12)
        schedule(fps: fps)
    }

    private func apply(_ render: PetRenderState, mouse: CGPoint) {
        lastRender = render
        guard let image = images.image(animation: render.animation, frame: render.frameIndex) else {
            Log.sprites.error("No hay imagen para \(render.animation, privacy: .public)")
            return
        }
        view.image = image
        view.mirrored = render.facingLeft
        if window.frame != render.frameRect { window.setFrame(render.frameRect, display: true) }
        window.alphaValue = render.opacity
        let overClawd = render.acceptsClicks && isOverOpaquePixel(render, mouse: mouse)
        window.ignoresMouseEvents = !(dragAnchor != nil || mouseDownLocation != nil || overClawd)
        if !window.isVisible { window.orderFrontRegardless() }
    }

    private func isOverOpaquePixel(_ render: PetRenderState, mouse: CGPoint) -> Bool {
        guard let animation = library.animationOrIdle(render.animation) else { return false }
        let frame = animation.frames[min(render.frameIndex, animation.frames.count - 1)]
        return Geometry.isOpaquePixel(frame: frame, frameRect: render.frameRect, point: mouse, facingLeft: render.facingLeft)
    }

    // MARK: - ⌥ click y ⌥ arrastrar

    /// Si se interrumpe un gesto (pausa, escondido o sin pantallas), se descarta para que Clawd no quede "cargado".
    private func cancelGesture() {
        dragAnchor = nil
        mouseDownLocation = nil
        pendingClick = false
    }

    private func mouseDown() {
        mouseDownLocation = NSEvent.mouseLocation
    }

    private func mouseDragged() {
        let mouse = NSEvent.mouseLocation
        if dragAnchor == nil {
            // Solo cuenta como arrastre si te moviste más de 3 pt (si no, es un click).
            guard let start = mouseDownLocation,
                  hypot(mouse.x - start.x, mouse.y - start.y) > 3,
                  let previousRect = lastRender?.frameRect
            else { return }
            // Mientras lo cargas se dibuja `caer`, cuya ancla no coincide con la de la animación
            // anterior (sentado, hamaca, trepar…). Calculamos el ancla de `caer` de modo que el
            // cursor siga agarrando el mismo punto relativo del sprite y no salte al levantarlo.
            // `caer` tiene el ancla centrada en x, así que hacia dónde mire no cambia el resultado.
            let carriedInfo = library.infos[AnimationName.fall] ?? .fallback
            let anchor = Geometry.carriedAnchor(grabbing: start, in: previousRect, carriedInfo: carriedInfo, scale: settings.size.rawValue)
            dragOffset = CGVector(dx: anchor.x - start.x, dy: anchor.y - start.y)
            schedule(fps: 30)
        }
        dragAnchor = CGPoint(x: mouse.x + dragOffset.dx, y: mouse.y + dragOffset.dy)
    }

    private func mouseUp() {
        if dragAnchor == nil, mouseDownLocation != nil { pendingClick = true }
        dragAnchor = nil
        mouseDownLocation = nil
    }
}
