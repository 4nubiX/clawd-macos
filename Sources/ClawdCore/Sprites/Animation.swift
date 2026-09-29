import Foundation

/// Color RGBA de 8 bits por canal.
public struct RGBA: Equatable, Hashable, Sendable {
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8
    public let a: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

/// Punto en la cuadrícula de un sprite. Ojo: `y` se mide desde ARRIBA,
/// igual que como se escriben las filas en el archivo de texto.
public struct GridPoint: Equatable, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

/// Un cuadro de animación. Los pixeles van fila por fila, de arriba hacia abajo.
/// `nil` significa transparente.
public struct SpriteFrame: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let pixels: [RGBA?]

    public init(width: Int, height: Int, pixels: [RGBA?]) {
        precondition(pixels.count == width * height, "El cuadro debe tener width × height pixeles")
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    /// Color del pixel, o `nil` si es transparente o está fuera del cuadro.
    public func pixel(x: Int, y: Int) -> RGBA? {
        guard x >= 0, x < width, y >= 0, y < height else { return nil }
        return pixels[y * width + x]
    }
}

/// Lo que el cerebro necesita saber de una animación, sin cargar los pixeles.
public struct AnimationInfo: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let anchor: GridPoint
    public let fps: Double
    public let frameCount: Int
    public let loops: Bool

    public init(width: Int, height: Int, anchor: GridPoint, fps: Double, frameCount: Int, loops: Bool) {
        self.width = width
        self.height = height
        self.anchor = anchor
        self.fps = fps
        self.frameCount = frameCount
        self.loops = loops
    }

    /// Duración de una pasada completa, en segundos.
    public var duration: TimeInterval { Double(frameCount) / fps }

    /// Qué cuadro toca mostrar después de `time` segundos de animación.
    public func frameIndex(at time: TimeInterval) -> Int {
        let raw = Int((max(time, 0) * fps).rounded(.down))
        return loops ? raw % frameCount : min(raw, frameCount - 1)
    }

    /// Respaldo por si falta una animación: del tamaño del cuerpo base de Clawd.
    public static let fallback = AnimationInfo(
        width: 16, height: 9, anchor: GridPoint(x: 8, y: 9), fps: 1, frameCount: 1, loops: true)
}

/// Una animación completa, lista para dibujarse.
public struct Animation: Equatable, Sendable {
    public let name: String
    public let fps: Double
    public let loops: Bool
    public let anchor: GridPoint
    public let frames: [SpriteFrame]

    public init(name: String, fps: Double, loops: Bool, anchor: GridPoint, frames: [SpriteFrame]) {
        precondition(!frames.isEmpty, "Una animación necesita al menos un cuadro")
        self.name = name
        self.fps = fps
        self.loops = loops
        self.anchor = anchor
        self.frames = frames
    }

    public var width: Int { frames[0].width }
    public var height: Int { frames[0].height }

    public var info: AnimationInfo {
        AnimationInfo(width: width, height: height, anchor: anchor, fps: fps, frameCount: frames.count, loops: loops)
    }
}

/// Nombres de las animaciones que la app necesita (= nombre del archivo sin `.txt`).
public enum AnimationName {
    public static let idle = "idle"
    public static let walk = "caminar"
    public static let lookAround = "mirar"
    public static let climb = "trepar"
    public static let sit = "sentado"
    public static let hammock = "hamaca"
    public static let fall = "caer"
    public static let land = "aterrizar"
    public static let wave = "saludar"
    public static let dodge = "esquivar"
    public static let sleepFloor = "dormir"
    public static let sleepShelf = "dormir-repisa"
    public static let sleepHammock = "dormir-hamaca"
    public static let cook = "cocinar"

    public static let all: [String] = [
        idle, walk, lookAround, climb, sit, hammock, fall, land,
        wave, dodge, sleepFloor, sleepShelf, sleepHammock, cook,
    ]
}
