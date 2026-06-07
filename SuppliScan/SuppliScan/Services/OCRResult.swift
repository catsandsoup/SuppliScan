// OCRResult.swift
// SuppliScan

import Foundation

/// A normalized text region in Vision's lower-left coordinate space.
nonisolated struct OCRTextRegion: Hashable, Sendable {
    let minX: Double
    let minY: Double
    let width: Double
    let height: Double

    var maxY: Double { minY + height }

    init(minX: Double, minY: Double, width: Double, height: Double) {
        self.minX = minX
        self.minY = minY
        self.width = width
        self.height = height
    }
}

/// One recognized OCR line plus the confidence reported by Vision.
nonisolated struct OCRRecognizedLine: Hashable, Sendable {
    let text: String
    let confidence: Float
    let region: OCRTextRegion

    init(text: String, confidence: Float, region: OCRTextRegion) {
        self.text = text
        self.confidence = confidence
        self.region = region
    }
}

/// OCR text output and confidence metadata for user review.
nonisolated struct OCRResult: Hashable, Sendable {
    static let lowConfidenceThreshold: Float = 0.72

    let rawText: String
    let lines: [OCRRecognizedLine]

    var averageConfidence: Float {
        guard !lines.isEmpty else { return 0 }
        let total = lines.reduce(Float.zero) { $0 + $1.confidence }
        return total / Float(lines.count)
    }

    var hasLowConfidenceText: Bool {
        averageConfidence < Self.lowConfidenceThreshold
    }

    init(lines: [OCRRecognizedLine]) {
        let orderedLines = Self.ordered(lines)
        self.lines = orderedLines
        self.rawText = orderedLines.map(\.text).joined(separator: "\n")
    }

    private static func ordered(_ lines: [OCRRecognizedLine]) -> [OCRRecognizedLine] {
        lines.sorted { lhs, rhs in
            if abs(lhs.region.maxY - rhs.region.maxY) > 0.02 {
                return lhs.region.maxY > rhs.region.maxY
            }
            return lhs.region.minX < rhs.region.minX
        }
    }
}
