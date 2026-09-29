import ClawdCore
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Genera una hoja con todas las animaciones, cuadro por cuadro, con el ancla marcada
// en rojo. Sirve para revisar el pixel art sin correr la app.
// Uso: clawd-preview <carpeta-de-sprites> <salida.png>

func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(code)
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else { fail("Uso: clawd-preview <carpeta-de-sprites> <salida.png>", code: 64) }

let library = TextSpriteSource(directory: URL(fileURLWithPath: arguments[1])).load()
for failure in library.failures {
    FileHandle.standardError.write(Data("⚠️  \(failure.description)\n".utf8))
}
guard !library.animations.isEmpty else { fail("No se cargó ninguna animación.") }

let pixel = 6          // cada pixel del sprite mide 6 px en la hoja
let gap = 12
let labelHeight = 22
let margin = 16
let animations = library.animations.keys.sorted().compactMap { library.animations[$0] }

let sheetWidth = margin * 2 + (animations.map { $0.frames.count * ($0.width * pixel + gap) }.max() ?? 0)
let sheetHeight = margin * 2 + animations.reduce(0) { $0 + labelHeight + $1.height * pixel + gap }

guard
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
    let context = CGContext(
        data: nil, width: sheetWidth, height: sheetHeight, bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
else { fail("No se pudo crear el lienzo.") }

// Fondo tipo papel, como Claude FM.
context.setFillColor(CGColor(red: 0.94, green: 0.92, blue: 0.89, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: sheetWidth, height: sheetHeight))
context.interpolationQuality = .none

let font = CTFontCreateWithName("Menlo" as CFString, 13, nil)
// CoreGraphics tiene el origen abajo, así que vamos de arriba hacia abajo restando.
var top = sheetHeight - margin
for animation in animations {
    let label = "\(animation.name) · \(animation.frames.count) cuadros · \(Int(animation.fps)) fps · \(animation.loops ? "repite" : "una vez")"
    let text = NSAttributedString(string: label, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
    context.textPosition = CGPoint(x: margin, y: top - 15)
    CTLineDraw(CTLineCreateWithAttributedString(text), context)
    top -= labelHeight

    let frameWidth = animation.width * pixel
    let frameHeight = animation.height * pixel
    for (index, frame) in animation.frames.enumerated() {
        let rect = CGRect(x: margin + index * (frameWidth + gap), y: top - frameHeight, width: frameWidth, height: frameHeight)
        context.setStrokeColor(CGColor(gray: 0.7, alpha: 1))
        context.stroke(rect.insetBy(dx: -0.5, dy: -0.5))
        if let image = FrameRasterizer.image(from: frame) {
            context.draw(image, in: rect)
        }
        // Ancla: puntito rojo (y del ancla se mide desde arriba).
        let anchorX = rect.minX + CGFloat(animation.anchor.x * pixel)
        let anchorY = rect.maxY - CGFloat(animation.anchor.y * pixel)
        context.setFillColor(CGColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1))
        context.fillEllipse(in: CGRect(x: anchorX - 3, y: anchorY - 3, width: 6, height: 6))
    }
    top -= frameHeight + gap
}

guard
    let sheet = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: arguments[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fail("No se pudo preparar el archivo de salida.") }
CGImageDestinationAddImage(destination, sheet, nil)
guard CGImageDestinationFinalize(destination) else { fail("No se pudo escribir \(arguments[2]).") }
print("Vista previa guardada en \(arguments[2])")
