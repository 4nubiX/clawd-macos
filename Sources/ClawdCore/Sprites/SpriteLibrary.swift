import Foundation

/// Un archivo de sprite que no se pudo cargar (o que falta).
public struct SpriteLoadFailure: Equatable, Sendable, CustomStringConvertible {
    public let file: String
    public let message: String

    public init(file: String, message: String) {
        self.file = file
        self.message = message
    }

    public var description: String { "\(file): \(message)" }
}

/// Todas las animaciones cargadas, más los errores encontrados.
/// Nunca truena: un sprite roto se reporta y la app sigue con los demás.
public struct SpriteLibrary: Sendable {
    public let animations: [String: Animation]
    public let failures: [SpriteLoadFailure]

    public init(animations: [String: Animation], failures: [SpriteLoadFailure]) {
        self.animations = animations
        self.failures = failures
    }

    /// Medidas de todas las animaciones, para el cerebro.
    public var infos: [String: AnimationInfo] { animations.mapValues(\.info) }

    /// La animación pedida o, si falta, `idle`, para que nunca se caiga la app por un sprite.
    public func animationOrIdle(_ name: String) -> Animation? {
        animations[name] ?? animations[AnimationName.idle]
    }
}

/// De dónde salen las animaciones. Hoy: archivos `.txt`. Mañana: spritesheets PNG (spec §5.6).
public protocol SpriteSource {
    func load() -> SpriteLibrary
}

/// Lee todos los `.txt` de una carpeta. Un archivo roto no detiene la carga de los demás.
public struct TextSpriteSource: SpriteSource {
    public let directory: URL
    public let requiredNames: [String]

    public init(directory: URL, requiredNames: [String] = AnimationName.all) {
        self.directory = directory
        self.requiredNames = requiredNames
    }

    public func load() -> SpriteLibrary {
        let files: [URL]
        do {
            files = try FileManager.default
                .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "txt" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            let failure = SpriteLoadFailure(
                file: directory.path, message: "no se pudo leer la carpeta: \(error.localizedDescription)")
            return SpriteLibrary(animations: [:], failures: [failure])
        }

        var animations: [String: Animation] = [:]
        var failures: [SpriteLoadFailure] = []
        for file in files {
            let name = file.deletingPathExtension().lastPathComponent
            do {
                let text = try String(contentsOf: file, encoding: .utf8)
                animations[name] = try SpriteParser.parse(text, name: name)
            } catch let error as SpriteParseError {
                failures.append(SpriteLoadFailure(file: file.lastPathComponent, message: error.description))
            } catch {
                failures.append(SpriteLoadFailure(file: file.lastPathComponent, message: error.localizedDescription))
            }
        }

        for name in requiredNames where animations[name] == nil {
            let fileName = "\(name).txt"
            if !failures.contains(where: { $0.file == fileName }) {
                failures.append(SpriteLoadFailure(file: fileName, message: "falta esta animación obligatoria"))
            }
        }
        return SpriteLibrary(animations: animations, failures: failures)
    }
}
