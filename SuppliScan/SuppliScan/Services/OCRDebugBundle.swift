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
    let sourceID: String
    let sourcePassIDs: [String]
    let supportCount: Int
    let qualityFlags: [String]
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
    let sourcePassIDs: [String]
    let supportCount: Int
    let qualityFlags: [String]
}

// MARK: - OCR quality

struct OCRDebugQuality: Encodable {
    let recognizedLineCount: Int
    let parseReadyLineCount: Int
    let rejectedLowConfidenceLineCount: Int
    let recognitionPassCount: Int
    let supportedLineCount: Int
    let singlePassLineCount: Int
    let conflictingLineCount: Int
    let uncertainLineCount: Int
    let averageSupportCount: Float
    let averageConfidence: Float
    let hasLowConfidenceText: Bool
    let hasSupplementLabelSignals: Bool
    let imageQuality: OCRDebugImageQuality?
    let panelConfidence: Float
    let primaryPanelLineCount: Int
    let excludedNonPanelLineCount: Int
    let hasAmbiguousPanelBoundary: Bool
}

struct OCRDebugImageQuality: Encodable {
    let pixelWidth: Int
    let pixelHeight: Int
    let sampledPixelCount: Int
    let meanLuminance: Double
    let luminanceStandardDeviation: Double
    let darkPixelRatio: Double
    let brightPixelRatio: Double
    let clippedHighlightRatio: Double
    let sharpnessScore: Double
    let issues: [String]
    let isRiskyForOCR: Bool

    init(report: OCRImageQualityReport) {
        self.pixelWidth = report.pixelWidth
        self.pixelHeight = report.pixelHeight
        self.sampledPixelCount = report.sampledPixelCount
        self.meanLuminance = report.meanLuminance
        self.luminanceStandardDeviation = report.luminanceStandardDeviation
        self.darkPixelRatio = report.darkPixelRatio
        self.brightPixelRatio = report.brightPixelRatio
        self.clippedHighlightRatio = report.clippedHighlightRatio
        self.sharpnessScore = report.sharpnessScore
        self.issues = report.issues.map(\.rawValue).sorted()
        self.isRiskyForOCR = report.isRiskyForOCR
    }
}

// MARK: - Panel reconstruction

struct OCRDebugPanelRow: Encodable {
    let text: String
    let section: String
    let score: Int
    let reasons: [String]
    let parserCandidate: Bool
}

struct OCRDebugPanelReconstruction: Encodable {
    let parserText: String
    let panelConfidence: Float
    let primaryPanelLineCount: Int
    let excludedNonPanelLineCount: Int
    let hasExplicitPanelHeading: Bool
    let hasAmbiguousPanelBoundary: Bool
    let rows: [OCRDebugPanelRow]

    init(reconstruction: OCRPanelReconstruction) {
        self.parserText = reconstruction.parserText
        self.panelConfidence = reconstruction.panelConfidence
        self.primaryPanelLineCount = reconstruction.primaryPanelLineCount
        self.excludedNonPanelLineCount = reconstruction.excludedLines.count
        self.hasExplicitPanelHeading = reconstruction.hasExplicitPanelHeading
        self.hasAmbiguousPanelBoundary = reconstruction.hasAmbiguousPanelBoundary
        self.rows = reconstruction.rows.map { row in
            OCRDebugPanelRow(
                text: row.line.text,
                section: row.section.rawValue,
                score: row.score,
                reasons: row.reasons,
                parserCandidate: reconstruction.parserLines.contains(row.line)
            )
        }
    }
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
    let allRecognizedText: String
    let quality: OCRDebugQuality
    let panelReconstruction: OCRDebugPanelReconstruction
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
