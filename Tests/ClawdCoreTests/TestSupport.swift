import CoreGraphics
@testable import ClawdCore

/// Medidas de las animaciones, iguales a las de `Resources/Sprites`.
/// `SpriteAssetsTests` verifica que no se desincronicen.
let testInfos: [String: AnimationInfo] = [
    AnimationName.idle: info(16, 9, anchor: (8, 9), fps: 3, frames: 6, loops: true),
    AnimationName.walk: info(16, 9, anchor: (8, 9), fps: 8, frames: 4, loops: true),
    AnimationName.lookAround: info(16, 9, anchor: (8, 9), fps: 2, frames: 4, loops: true),
    AnimationName.climb: info(9, 16, anchor: (9, 8), fps: 6, frames: 2, loops: true),
    AnimationName.sit: info(18, 11, anchor: (18, 0), fps: 3, frames: 6, loops: true),
    AnimationName.hammock: info(24, 12, anchor: (12, 0), fps: 3, frames: 4, loops: true),
    AnimationName.fall: info(16, 9, anchor: (8, 9), fps: 8, frames: 2, loops: true),
    AnimationName.land: info(16, 9, anchor: (8, 9), fps: 6, frames: 3, loops: false),
    AnimationName.wave: info(16, 9, anchor: (8, 9), fps: 6, frames: 2, loops: true),
    AnimationName.dodge: info(16, 12, anchor: (8, 12), fps: 10, frames: 5, loops: false),
    AnimationName.sleepFloor: info(18, 10, anchor: (8, 10), fps: 1, frames: 2, loops: true),
    AnimationName.sleepShelf: info(18, 11, anchor: (18, 0), fps: 1, frames: 2, loops: true),
    AnimationName.sleepHammock: info(24, 12, anchor: (12, 0), fps: 1, frames: 2, loops: true),
    AnimationName.cook: info(24, 14, anchor: (8, 14), fps: 8, frames: 8, loops: true),
]

func info(_ width: Int, _ height: Int, anchor: (Int, Int), fps: Double, frames: Int, loops: Bool) -> AnimationInfo {
    AnimationInfo(
        width: width, height: height, anchor: GridPoint(x: anchor.0, y: anchor.1),
        fps: fps, frameCount: frames, loops: loops)
}

/// El setup real de Santiago: MacBook (principal) a la izquierda y monitor 1080p a la derecha.
let laptop = ScreenInfo(
    id: 1, frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
    visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 945))
let external = ScreenInfo(
    id: 2, frame: CGRect(x: 1512, y: 0, width: 1920, height: 1080),
    visibleFrame: CGRect(x: 1512, y: 0, width: 1920, height: 1055))
