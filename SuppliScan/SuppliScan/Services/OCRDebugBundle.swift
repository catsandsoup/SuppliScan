#if DEBUG
// OCRDebugBundle.swift
// SuppliScan — DEBUG only
//
// Full pipeline snapshot written to Documents/debug-ocr/<scanID>/bundle.json.
// Lets you trace: image → Vision observations → merged rows → parser decisions → entries.
// Never compiled into Release builds.

import Foundation

// MARK: - Observation types

struct OCRDebugObservation: Encodable {
    let text: String
    let confidence: Float
    let boundingBox: OCRDebugBBox
    let alternatives: [OCRDebugCandidate]
}

struct OCRDebugBBox: Encodable {
    let minX: Double
    let minY: Double
    let width: Double
    let height: Double
}

struct OCRDebugCandidate: Encodable {
    let text: String
    let confidence: Float
}

// MARK: - Merged row

struct OCRDebugMergedRow: Encodable {
    let text: String
    let confidence: Float
    let mergedFromCount: Int
}

// MARK: - Parser decision

struct OCRDebugParserDecision: Encodable {
    let rawRow: String
    let decision: String    // "nutrient" | "probiotic" | "unresolved" | "rejected" | "serving" | "skipped"
    let reason: String
    let extractedName: String?
    let amount: Double?
    let unit: String?
}

// MARK: - Bundle

struct OCRDebugBundle: Encodable {
    let scanID: String
    let capturedAt: String  // ISO 8601
    let rawText: String
    let rawObservations: [OCRDebugObservation]
    let mergedRows: [OCRDebugMergedRow]
    let parserDecisions: [OCRDebugParserDecision]
}

// MARK: - Writer

enum OCRDebugWriter {
    static func write(_ bundle: OCRDebugBundle) {
        guard
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }

        let dir = docs.appendingPathComponent("debug-ocr/\(bundle.scanID)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(bundle) else { return }
        let url = dir.appendingPathComponent("bundle.json")
        try? data.write(to: url)

        print("[SuppliScan DEBUG] OCR bundle written to: \(url.path)")
    }
}
#endif
