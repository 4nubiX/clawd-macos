import CoreGraphics
import Foundation

/// Zonas de la pantalla para llevar la cuenta de sustos.
public enum Zone: String, Sendable {
    case floor, wall, corner
}

public struct ZoneKey: Hashable, Sendable {
    public let screenID: UInt32
    public let zone: Zone

    public init(screenID: UInt32, zone: Zone) {
        self.screenID = screenID
        self.zone = zone
    }
}
