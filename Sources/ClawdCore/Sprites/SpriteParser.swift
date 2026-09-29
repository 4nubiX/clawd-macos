import Foundation

/// Error al leer un archivo de sprite, con la línea exacta del problema.
public struct SpriteParseError: Error, Equatable, CustomStringConvertible {
    public let line: Int
    public let message: String

    public init(line: Int, message: String) {
        self.line = line
        self.message = message
    }

    public var description: String { "línea \(line): \(message)" }
}

/// Convierte el formato de texto de sprites (spec §5.1) en una `Animation`.
public enum SpriteParser {
    /// Símbolos que no pueden usarse en la paleta.
    static let reservedSymbols: Set<Character> = [".", "#", "-"]

    public static func parse(_ text: String, name: String) throws -> Animation {
        var fps: Double?
        var loops: Bool?
        var anchor: GridPoint?
        var anchorLine = 1
        var palette: [Character: RGBA] = [:]
        // Cada cuadro guarda la línea donde empieza y sus filas (con número de línea).
        var frames: [(startLine: Int, rows: [(line: Int, text: String)])] = []

        // isNewline también parte "\r\n" (archivos con fin de línea de Windows).
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        for (index, rawLine) in lines.enumerated() {
            let lineNumber = index + 1
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") { continue }

            if line.hasPrefix("---") {
                frames.append((startLine: lineNumber, rows: []))
                continue
            }
            if !frames.isEmpty {
                frames[frames.count - 1].rows.append((line: lineNumber, text: line))
                continue
            }

            // Encabezado: "clave: valor"
            guard let colon = line.firstIndex(of: ":") else {
                throw SpriteParseError(line: lineNumber, message: "se esperaba 'clave: valor' o una línea '---'")
            }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)

            switch key {
            case "fps":
                guard let parsed = Double(value), parsed > 0 else {
                    throw SpriteParseError(line: lineNumber, message: "fps debe ser un número mayor que 0")
                }
                fps = parsed
            case "repetir":
                switch value.lowercased() {
                case "si", "sí": loops = true
                case "no": loops = false
                default: throw SpriteParseError(line: lineNumber, message: "repetir debe ser 'si' o 'no'")
                }
            case "ancla":
                let parts = value.split(separator: ",").map { Int($0.trimmingCharacters(in: .whitespaces)) }
                guard parts.count == 2, let x = parts[0], let y = parts[1] else {
                    throw SpriteParseError(line: lineNumber, message: "ancla debe ser 'x,y' con números enteros")
                }
                anchor = GridPoint(x: x, y: y)
                anchorLine = lineNumber
            case "paleta":
                for entry in value.split(separator: " ") {
                    let pieces = entry.split(separator: "=", maxSplits: 1)
                    guard pieces.count == 2, pieces[0].count == 1, let symbol = pieces[0].first else {
                        throw SpriteParseError(line: lineNumber, message: "entrada de paleta inválida '\(entry)', se espera 'X=#RRGGBB'")
                    }
                    guard !reservedSymbols.contains(symbol) else {
                        throw SpriteParseError(line: lineNumber, message: "el símbolo '\(symbol)' está reservado")
                    }
                    guard let color = parseHexColor(String(pieces[1])) else {
                        throw SpriteParseError(line: lineNumber, message: "color inválido '\(pieces[1])'")
                    }
                    palette[symbol] = color
                }
            default:
                throw SpriteParseError(line: lineNumber, message: "clave desconocida '\(key)'")
            }
        }

        guard let fps else { throw SpriteParseError(line: 1, message: "falta 'fps'") }
        guard let loops else { throw SpriteParseError(line: 1, message: "falta 'repetir'") }
        guard let anchor else { throw SpriteParseError(line: 1, message: "falta 'ancla'") }
        guard !frames.isEmpty else {
            throw SpriteParseError(line: lines.count, message: "no hay ningún cuadro (líneas '---')")
        }

        var parsedFrames: [SpriteFrame] = []
        var expectedWidth: Int?
        var expectedHeight: Int?
        for frame in frames {
            guard let firstRow = frame.rows.first else {
                throw SpriteParseError(line: frame.startLine, message: "cuadro vacío")
            }
            let width = expectedWidth ?? firstRow.text.count
            var pixels: [RGBA?] = []
            for row in frame.rows {
                guard row.text.count == width else {
                    throw SpriteParseError(line: row.line, message: "la fila mide \(row.text.count) y debería medir \(width)")
                }
                for (column, symbol) in row.text.enumerated() {
                    if symbol == "." {
                        pixels.append(nil)
                        continue
                    }
                    guard let color = palette[symbol] else {
                        throw SpriteParseError(line: row.line, message: "el símbolo '\(symbol)' (columna \(column + 1)) no está en la paleta")
                    }
                    pixels.append(color)
                }
            }
            let height = frame.rows.count
            if let expectedHeight, height != expectedHeight {
                throw SpriteParseError(line: frame.startLine, message: "el cuadro mide \(height) filas y debería medir \(expectedHeight)")
            }
            expectedWidth = width
            expectedHeight = height
            parsedFrames.append(SpriteFrame(width: width, height: height, pixels: pixels))
        }

        let width = expectedWidth ?? 0
        let height = expectedHeight ?? 0
        guard (0...width).contains(anchor.x), (0...height).contains(anchor.y) else {
            throw SpriteParseError(line: anchorLine, message: "el ancla (\(anchor.x),\(anchor.y)) queda fuera del cuadro de \(width)×\(height)")
        }
        return Animation(name: name, fps: fps, loops: loops, anchor: anchor, frames: parsedFrames)
    }

    /// "#RRGGBB" o "#RRGGBBAA" → RGBA.
    static func parseHexColor(_ text: String) -> RGBA? {
        guard text.hasPrefix("#") else { return nil }
        let hex = text.dropFirst()
        guard hex.count == 6 || hex.count == 8, let value = UInt32(hex, radix: 16) else { return nil }
        if hex.count == 6 {
            return RGBA(r: UInt8((value >> 16) & 0xFF), g: UInt8((value >> 8) & 0xFF), b: UInt8(value & 0xFF))
        }
        return RGBA(
            r: UInt8((value >> 24) & 0xFF), g: UInt8((value >> 16) & 0xFF),
            b: UInt8((value >> 8) & 0xFF), a: UInt8(value & 0xFF))
    }
}
