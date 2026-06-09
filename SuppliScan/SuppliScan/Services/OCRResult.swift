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
nonisolated struct OCRRecognizedLine: Sendable {
    let text: String
    let confidence: Float
    let region: OCRTextRegion
    let sourceLineCount: Int
#if DEBUG
    /// Runner-up candidates from Vision topCandidates(3). Empty in release builds.
    let alternatives: [OCRAlternativeCandidate]
#endif

    init(text: String, confidence: Float, region: OCRTextRegion, sourceLineCount: Int = 1) {
        self.text = text
        self.confidence = confidence
        self.region = region
        self.sourceLineCount = sourceLineCount
#if DEBUG
        self.alternatives = []
#endif
    }

#if DEBUG
    init(
        text: String,
        confidence: Float,
        region: OCRTextRegion,
        sourceLineCount: Int = 1,
        alternatives: [OCRAlternativeCandidate]
    ) {
        self.text = text
        self.confidence = confidence
        self.region = region
        self.sourceLineCount = sourceLineCount
        self.alternatives = alternatives
    }
#endif
}

nonisolated extension OCRRecognizedLine: Hashable {
    static func == (lhs: OCRRecognizedLine, rhs: OCRRecognizedLine) -> Bool {
        lhs.text == rhs.text
            && lhs.confidence == rhs.confidence
            && lhs.region == rhs.region
            && lhs.sourceLineCount == rhs.sourceLineCount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(confidence)
        hasher.combine(region)
        hasher.combine(sourceLineCount)
    }
}

#if DEBUG
nonisolated struct OCRAlternativeCandidate: Hashable, Sendable {
    let text: String
    let confidence: Float
}
#endif

nonisolated struct OCRQualityReport: Hashable, Sendable {
    let recognizedLineCount: Int
    let parseReadyLineCount: Int
    let rejectedLowConfidenceLineCount: Int
    let averageConfidence: Float
    let hasLowConfidenceText: Bool
    let hasSupplementLabelSignals: Bool
}

/// OCR text output and confidence metadata for user review.
nonisolated struct OCRResult: Hashable, Sendable {
    static let lowConfidenceThreshold: Float = 0.72
    static let parseConfidenceThreshold: Float = 0.50

    let rawText: String
    let allRecognizedText: String
    let lines: [OCRRecognizedLine]
    let recognizedLines: [OCRRecognizedLine]
    let rejectedLines: [OCRRecognizedLine]
    let quality: OCRQualityReport

    var averageConfidence: Float {
        quality.averageConfidence
    }

    var hasLowConfidenceText: Bool {
        quality.hasLowConfidenceText
    }

    var hasSupplementLabelSignals: Bool {
        quality.hasSupplementLabelSignals
    }

    init(lines: [OCRRecognizedLine]) {
        let recognizedLines = Self.ordered(lines)
        let parseReadyLines = recognizedLines.filter { $0.confidence >= Self.parseConfidenceThreshold }
        let orderedLines = Self.orderedAndMerged(parseReadyLines)
        let rejectedLines = recognizedLines.filter { $0.confidence < Self.parseConfidenceThreshold }
        let averageConfidence = Self.averageConfidence(for: recognizedLines)
        let hasLowConfidenceText = averageConfidence < Self.lowConfidenceThreshold
            || recognizedLines.contains { $0.confidence < Self.lowConfidenceThreshold }
        let hasSupplementLabelSignals = Self.hasSupplementLabelSignals(in: orderedLines)

        self.recognizedLines = recognizedLines
        self.rejectedLines = rejectedLines
        self.lines = orderedLines
        self.rawText = orderedLines.map(\.text).joined(separator: "\n")
        self.allRecognizedText = recognizedLines.map(\.text).joined(separator: "\n")
        self.quality = OCRQualityReport(
            recognizedLineCount: recognizedLines.count,
            parseReadyLineCount: orderedLines.count,
            rejectedLowConfidenceLineCount: rejectedLines.count,
            averageConfidence: averageConfidence,
            hasLowConfidenceText: hasLowConfidenceText,
            hasSupplementLabelSignals: hasSupplementLabelSignals
        )
    }

    private static func ordered(_ lines: [OCRRecognizedLine]) -> [OCRRecognizedLine] {
        lines.sorted { lhs, rhs in
            if abs(lhs.region.maxY - rhs.region.maxY) > 0.018 {
                lhs.region.maxY > rhs.region.maxY
            } else {
                lhs.region.minX < rhs.region.minX
            }
        }
    }

    private static func orderedAndMerged(_ lines: [OCRRecognizedLine]) -> [OCRRecognizedLine] {
        let sorted = ordered(lines)

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

            return splitRowIntoParserRows(orderedRow).map(mergedRow)
        }
    }

    private static func isAmountOrLeaderFragment(_ line: OCRRecognizedLine) -> Bool {
        let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.range(
            of: #"(?i)(?:<\s*)?\d+(?:[\.,]\d+)?\s*((?:billion|million)\s+cfu|cfu|mg|mcg|micrograms?|μg|µg|ug|g|iu)\b"#,
            options: .regularExpression
        ) != nil {
            return true
        }
        return text.allSatisfy { $0 == "." || $0 == "·" || $0 == "•" || $0.isWhitespace }
    }

    private static func containsSupplementAmount(_ text: String) -> Bool {
        text.range(
            of: #"(?i)\b\d+(?:[\.,]\d+)?\s*((?:billion|million)\s+cfu|cfu|mg|mcg|micrograms?|μg|µg|ug|g|iu)\b"#,
            options: .regularExpression
        ) != nil
    }

    private static func hasSupplementLabelSignals(in lines: [OCRRecognizedLine]) -> Bool {
        let joined = lines.map(\.text).joined(separator: " ")
        let lower = joined.lowercased()
        var score = lines.reduce(0) { partial, line in
            partial + (containsSupplementAmount(line.text) ? 1 : 0)
        }

        let labelKeywords = [
            "supplement facts", "nutrition information", "active ingredients",
            "amount per serving", "amount per serve", "each tablet contains",
            "each capsule contains", "each dose contains", "contains:"
        ]
        if labelKeywords.contains(where: { lower.contains($0) }) {
            score += 2
        }

        let domainKeywords = [
            "vitamin", "magnesium", "zinc", "calcium", "selenium", "folate",
            "probiotic", "lactobacillus", "bifidobacterium", "taurine", "quercetin"
        ]
        if domainKeywords.contains(where: { lower.contains($0) }) {
            score += 1
        }

        return score >= 2
    }

    private static func averageConfidence(for lines: [OCRRecognizedLine]) -> Float {
        guard !lines.isEmpty else { return 0 }
        let total = lines.reduce(Float.zero) { $0 + $1.confidence }
        return total / Float(lines.count)
    }

    private static func splitRowIntoParserRows(_ orderedRow: [OCRRecognizedLine]) -> [[OCRRecognizedLine]] {
        let nameIndexes = orderedRow.indices.filter { !isAmountOrLeaderFragment(orderedRow[$0]) }
        let amountIndexes = orderedRow.indices.filter { isAmountOrLeaderFragment(orderedRow[$0]) }

        guard nameIndexes.count > 1, amountIndexes.count > 1 else {
            return [orderedRow]
        }

        var segments: [[OCRRecognizedLine]] = []
        for (position, nameIndex) in nameIndexes.enumerated() {
            let nextNameIndex = position + 1 < nameIndexes.count ? nameIndexes[position + 1] : orderedRow.endIndex
            let segment = orderedRow[nameIndex..<nextNameIndex].filter { line in
                !line.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if !segment.isEmpty {
                segments.append(Array(segment))
            }
        }

        return segments.isEmpty ? [orderedRow] : segments
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
            ),
            sourceLineCount: row.reduce(0) { $0 + $1.sourceLineCount }
        )
    }
}
