// Logger+SuppliScan.swift
// SuppliScan
//
// Centralised OSLog loggers for the app.
// Use these instead of print() in all production code.
// Never log user health data — log only error type, service name, timestamp.
//
// Logger is Sendable — static let constants are implicitly nonisolated per SE-0411.

import OSLog

nonisolated extension Logger {
    private static let subsystem = "montygiovenco.SuppliScan"

    static let suppliScan  = Logger(subsystem: subsystem, category: "general")
    static let ocr         = Logger(subsystem: subsystem, category: "ocr")
    static let parser      = Logger(subsystem: subsystem, category: "parser")
    static let calculation = Logger(subsystem: subsystem, category: "calculation")
    static let formQuality = Logger(subsystem: subsystem, category: "formQuality")
    static let ai          = Logger(subsystem: subsystem, category: "ai")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let export      = Logger(subsystem: subsystem, category: "export")
    static let navigation  = Logger(subsystem: subsystem, category: "navigation")
}
