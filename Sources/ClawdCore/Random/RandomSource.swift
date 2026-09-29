/// Fuente de números aleatorios inyectable: en la app es azar de verdad y en los
/// tests usa una semilla fija, para que el comportamiento sea repetible.
public protocol RandomSource {
    /// Devuelve un número en el rango [0, 1).
    mutating func nextUnit() -> Double
}

extension RandomSource {
    /// Número aleatorio dentro de un rango cerrado.
    public mutating func next(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextUnit() * (range.upperBound - range.lowerBound)
    }
}

/// Generador SplitMix64: simple, rápido y determinista con la misma semilla.
public struct SeededRandom: RandomSource {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func nextUnit() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z = z ^ (z >> 31)
        // 53 bits = la precisión completa de un Double.
        return Double(z >> 11) / Double(UInt64(1) << 53)
    }
}

/// Azar real del sistema, para la app.
public struct SystemRandom: RandomSource {
    public init() {}

    public mutating func nextUnit() -> Double {
        Double.random(in: 0..<1)
    }
}
