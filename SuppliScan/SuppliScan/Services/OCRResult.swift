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
        let orderedLines = Self.orderedAndMerged(lines)
        self.lines = orderedLines
        self.rawText = orderedLines.map(\.text).joined(separator: "\n")
    }

    private static func orderedAndMerged(_ lines: [OCRRecognizedLine]) -> [OCRRecognizedLine] {
        let sorted = lines.sorted { lhs, rhs in
            if abs(lhs.region.maxY - rhs.region.maxY) > 0.018 {
                lhs.region.maxY > rhs.region.maxY
            } else {
                lhs.region.minX < rhs.region.minX
            }
        }

        var rows: [[OCRRecognizedLine]] = []
        for line in sorted {
            if let lastIndex = rows.indices.last,
               let anchor = rows[lastIndex].first,
               abs(anchor.region.maxY - line.region.maxY) <= 0.018 {
                rows[lastIndex].append(line)
            } else {
                rows.append([line])
            }
        }

        return rows.flatMap { row in
            let orderedRow = row.sorted { $0.region.minX < $1.region.minX }
            guard orderedRow.count > 1, orderedRow.contains(where: isAmountOrLeaderFragment) else {
                return orderedRow
            }

            return [mergedRow(orderedRow)]
        }
    }

    private static func isAmountOrLeaderFragment(_ line: OCRRecognizedLine) -> Bool {
        let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.range(
            of: #"(?i)(?:<\s*)?\d+(?:[\.,]\d+)?\s*((?:billion|million)\s+cfu|cfu|mg|mcg|μg|µg|ug|g|iu)\b"#,
            options: .regularExpression
        ) != nil {
            return true
        }
        return text.allSatisfy { $0 == "." || $0 == "·" || $0 == "•" || $0.isWhitespace }
    }

    private static func mergedRow(_ row: [OCRRecognizedLine]) -> OCRRecognizedLine {
        let text = row
            .map(\.text)
            .map { $0.replacingOccurrences(of: #"^[.\s·•]+|[.\s·•]+$"#, with: "", options: .regularExpression) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let minX = row.map(\.region.minX).min() ?? 0
        let minY = row.map(\.region.minY).min() ?? 0
        let maxX = row.map { $0.region.minX + $0.region.width }.max() ?? minX
        let maxY = row.map { $0.region.minY + $0.region.height }.max() ?? minY
        let confidence = row.reduce(Float.zero) { $0 + $1.confidence } / Float(row.count)

        return OCRRecognizedLine(
            text: text,
            confidence: confidence,
            region: OCRTextRegion(
                minX: minX,
                minY: minY,
                width: maxX - minX,
                height: maxY - minY
            )
        )
    }
}
