import CoreGraphics

/// Una pantalla, en coordenadas globales de macOS (origen abajo a la izquierda).
public struct ScreenInfo: Equatable, Sendable {
    public let id: UInt32
    /// Marco completo de la pantalla.
    public let frame: CGRect
    /// Área útil: sin la barra de menú ni el Dock. Clawd vive aquí.
    public let visibleFrame: CGRect

    public init(id: UInt32, frame: CGRect, visibleFrame: CGRect) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
    }

    public var area: CGFloat { visibleFrame.width * visibleFrame.height }
}

/// Cómo pasar de una pantalla a otra.
public enum Crossing: Equatable, Sendable {
    /// Caminando por el piso hasta la orilla `edgeX`, en dirección +1 (derecha) o -1 (izquierda).
    case walk(edgeX: CGFloat, direction: CGFloat)
    /// No hay camino por el piso: aparece cayendo desde arriba en la otra pantalla.
    case dropIn
}

public enum Geometry {
    /// Rectángulo que ocupa una animación dibujada con su ancla en `anchorPosition`.
    public static func frameRect(anchorPosition: CGPoint, info: AnimationInfo, scale: Int, facingLeft: Bool) -> CGRect {
        let s = CGFloat(scale)
        // Si mira a la izquierda el sprite se refleja, y el ancla con él.
        let anchorX = CGFloat(facingLeft ? info.width - info.anchor.x : info.anchor.x)
        let width = CGFloat(info.width) * s
        let height = CGFloat(info.height) * s
        // El ancla se mide desde arriba: el borde superior queda anchor.y pixeles por encima.
        let top = anchorPosition.y + CGFloat(info.anchor.y) * s
        return CGRect(x: anchorPosition.x - anchorX * s, y: top - height, width: width, height: height)
    }

    /// Dónde debe ir el ancla del sprite "cargado" para que el cursor siga agarrando
    /// el mismo punto relativo del sprite que tenía antes (así no salta al levantarlo).
    public static func carriedAnchor(grabbing point: CGPoint, in previousRect: CGRect, carriedInfo: AnimationInfo, scale: Int) -> CGPoint {
        let s = CGFloat(scale)
        let width = CGFloat(carriedInfo.width) * s
        let height = CGFloat(carriedInfo.height) * s
        // Posición relativa (0…1) del punto agarrado dentro del sprite anterior.
        let u = previousRect.width > 0 ? min(max((point.x - previousRect.minX) / previousRect.width, 0), 1) : 0.5
        let v = previousRect.height > 0 ? min(max((point.y - previousRect.minY) / previousRect.height, 0), 1) : 0.5
        let minX = point.x - u * width
        let minY = point.y - v * height
        return CGPoint(
            x: minX + CGFloat(carriedInfo.anchor.x) * s,
            y: minY + height - CGFloat(carriedInfo.anchor.y) * s)
    }

    /// Distancia más corta de un punto a un rectángulo (0 si está adentro).
    public static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// La "casa" de Clawd: la pantalla con más área útil. En empate, la de menor id (determinista).
    public static func homeScreen(in screens: [ScreenInfo]) -> ScreenInfo? {
        screens.max { a, b in
            a.area != b.area ? a.area < b.area : a.id > b.id
        }
    }

    /// La pantalla que contiene el punto o, si ninguna lo contiene, la más cercana.
    public static func nearestScreen(to point: CGPoint, in screens: [ScreenInfo]) -> ScreenInfo? {
        if let containing = screens.first(where: { $0.frame.contains(point) }) { return containing }
        return screens.min { distance(from: point, to: $0.frame) < distance(from: point, to: $1.frame) }
    }

    /// ¿Se puede ir caminando de `origin` a `destination`? Solo si se tocan por un costado
    /// y el piso de origen queda a una altura que existe en el destino (se puede caer, no subir).
    public static func crossing(from origin: ScreenInfo, to destination: ScreenInfo) -> Crossing {
        let tolerance: CGFloat = 1
        let originFloor = origin.visibleFrame.minY
        let reachable = originFloor >= destination.visibleFrame.minY && originFloor < destination.visibleFrame.maxY
        guard reachable else { return .dropIn }
        if abs(origin.frame.maxX - destination.frame.minX) <= tolerance {
            return .walk(edgeX: origin.frame.maxX, direction: 1)
        }
        if abs(origin.frame.minX - destination.frame.maxX) <= tolerance {
            return .walk(edgeX: origin.frame.minX, direction: -1)
        }
        return .dropIn
    }

    /// ¿El punto cae sobre un pixel opaco del cuadro dibujado en `frameRect`?
    /// Así el ⌥ click solo cuenta sobre Clawd y no sobre el espacio vacío de su cuadro.
    public static func isOpaquePixel(frame: SpriteFrame, frameRect: CGRect, point: CGPoint, facingLeft: Bool) -> Bool {
        guard frameRect.contains(point), frameRect.width > 0, frameRect.height > 0 else { return false }
        let u = (point.x - frameRect.minX) / frameRect.width
        let vFromTop = (frameRect.maxY - point.y) / frameRect.height
        var x = min(Int(u * CGFloat(frame.width)), frame.width - 1)
        let y = min(Int(vFromTop * CGFloat(frame.height)), frame.height - 1)
        if facingLeft { x = frame.width - 1 - x }
        return frame.pixel(x: x, y: y) != nil
    }
}
