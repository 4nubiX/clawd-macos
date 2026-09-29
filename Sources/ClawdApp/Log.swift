import os

/// Loggers de Clawd. Se ven en Console.app filtrando por "Clawd" o por el subsistema.
enum Log {
    static let subsystem = "com.4nubix.clawd"
    static let app = Logger(subsystem: subsystem, category: "app")
    static let brain = Logger(subsystem: subsystem, category: "cerebro")
    static let sprites = Logger(subsystem: subsystem, category: "sprites")
    static let system = Logger(subsystem: subsystem, category: "sistema")
}
