import CoreGraphics
import Foundation

/// Convierte cuadros de sprite en imágenes de CoreGraphics.
public enum FrameRasterizer {
    /// `pixelScale` = cuántos pixeles reales mide cada pixel del sprite (1 = tamaño original).
    public static func image(from frame: SpriteFrame, pixelScale: Int = 1) -> CGImage? {
        let scale = max(pixelScale, 1)
        let width = frame.width * scale
        let height = frame.height * scale
        var bytes = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<frame.height {
            for x in 0..<frame.width {
                guard let color = frame.pixel(x: x, y: y) else { continue }
                // CoreGraphics espera alfa premultiplicado.
                let alpha = UInt16(color.a)
                let r = UInt8(UInt16(color.r) * alpha / 255)
                let g = UInt8(UInt16(color.g) * alpha / 255)
                let b = UInt8(UInt16(color.b) * alpha / 255)
                for dy in 0..<scale {
                    for dx in 0..<scale {
                        let index = ((y * scale + dy) * width + (x * scale + dx)) * 4
                        bytes[index] = r
                        bytes[index + 1] = g
                        bytes[index + 2] = b
                        bytes[index + 3] = color.a
                    }
                }
            }
        }

        guard
            let provider = CGDataProvider(data: Data(bytes) as CFData),
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        else { return nil }
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}
