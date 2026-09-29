import ClawdCore
import CoreGraphics

/// Convierte cada cuadro en imagen una sola vez, al arrancar. Dibujar después sale casi gratis.
@MainActor
final class FrameImageCache {
    private var images: [String: [CGImage]] = [:]

    init(library: SpriteLibrary) {
        for (name, animation) in library.animations {
            let frames = animation.frames.compactMap { FrameRasterizer.image(from: $0) }
            if frames.count != animation.frames.count {
                Log.sprites.error("No se pudieron rasterizar todos los cuadros de \(name, privacy: .public)")
            }
            images[name] = frames
        }
    }

    /// La imagen del cuadro pedido; si la animación falta, cae a idle (igual que el cerebro).
    func image(animation: String, frame: Int) -> CGImage? {
        guard let frames = images[animation] ?? images[AnimationName.idle], !frames.isEmpty else { return nil }
        return frames[min(max(frame, 0), frames.count - 1)]
    }
}
