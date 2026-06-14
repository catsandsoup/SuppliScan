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

nonisolated enum OCRLineQualityFlag: String, Hashable, Sendable {
    case lowConfidence
    case lowConfidenceAccepted
    case singlePassEvidence
    case conflictingCandidates
    case reconstructedFromMultipleFragments
}

/// One recognized OCR line plus the evidence metadata reported by Vision.
nonisolated struct OCRRecognizedLine: Sendable {
    let text: String
    let confidence: Float
    let region: OCRTextRegion
    let sourceLineCount: Int
    let sourceID: String
    let sourcePassIDs: [String]
    let supportCount: Int
    let qualityFlags: Set<OCRLineQualityFlag>
#if DEBUG
    /// Runner-up candidates from Vision topCandidates(3). Empty in release builds.
    let alternatives: [OCRAlternativeCandidate]
#endif

    init(
        text: String,
        confidence: Float,
        region: OCRTextRegion,
        sourceLineCount: Int = 1,
        sourceID: String = "input",
        sourcePassIDs: [String]? = nil,
        supportCount: Int = 1,
        qualityFlags: Set<OCRLineQualityFlag> = []
    ) {
        self.text = text
        self.confidence = confidence
        self.region = region
        self.sourceLineCount = sourceLineCount
        self.sourceID = sourceID
        self.sourcePassIDs = sourcePassIDs ?? [sourceID]
        self.supportCount = supportCount
        self.qualityFlags = qualityFlags
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
        sourceID: String = "input",
        sourcePassIDs: [String]? = nil,
        supportCount: Int = 1,
        qualityFlags: Set<OCRLineQualityFlag> = [],
        alternatives: [OCRAlternativeCandidate]
    ) {
        self.text = text
        self.confidence = confidence
        self.region = region
        self.sourceLineCount = sourceLineCount
        self.sourceID = sourceID
        self.sourcePassIDs = sourcePassIDs ?? [sourceID]
        self.supportCount = supportCount
        self.qualityFlags = qualityFlags
        self.alternatives = alternatives
    }
#endif

    func addingQualityFlags(_ flags: Set<OCRLineQualityFlag>) -> OCRRecognizedLine {
        var mergedFlags = qualityFlags
        mergedFlags.formUnion(flags)

#if DEBUG
        return OCRRecognizedLine(
            text: text,
            confidence: confidence,
            region: region,
            sourceLineCount: sourceLineCount,
            sourceID: sourceID,
            sourcePassIDs: sourcePassIDs,
            supportCount: supportCount,
            qualityFlags: mergedFlags,
            alternatives: alternatives
        )
#else
        return OCRRecognizedLine(
            text: text,
            confidence: confidence,
            region: region,
            sourceLineCount: sourceLineCount,
            sourceID: sourceID,
            sourcePassIDs: sourcePassIDs,
            supportCount: supportCount,
            qualityFlags: mergedFlags
        )
#endif
    }
}

nonisolated extension OCRRecognizedLine: Hashable {
    static func == (lhs: OCRRecognizedLine, rhs: OCRRecognizedLine) -> Bool {
        lhs.text == rhs.text
            && lhs.confidence == rhs.confidence
            && lhs.region == rhs.region
            && lhs.sourceLineCount == rhs.sourceLineCount
            && lhs.sourceID == rhs.sourceID
            && lhs.sourcePassIDs == rhs.sourcePassIDs
            && lhs.supportCount == rhs.supportCount
            && lhs.qualityFlags == rhs.qualityFlags
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(confidence)
        hasher.combine(region)
        hasher.combine(sourceLineCount)
        hasher.combine(sourceID)
        hasher.combine(sourcePassIDs)
        hasher.combine(supportCount)
        hasher.combine(qualityFlags)
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
    let recognitionPassCount: Int
    let supportedLineCount: Int
    let singlePassLineCount: Int
    let conflictingLineCount: Int
    let uncertainLineCount: Int
    let averageSupportCount: Float
    let averageConfidence: Float
    let hasLowConfidenceText: Bool
    let hasSupplementLabelSignals: Bool
    let imageQuality: OCRImageQualityReport?
    let panelConfidence: Float
    let primaryPanelLineCount: Int
    let excludedNonPanelLineCount: Int
    let hasAmbiguousPanelBoundary: Bool
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
    let panelReconstruction: OCRPanelReconstruction
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

    init(lines: [OCRRecognizedLine], imageQuality: OCRImageQualityReport? = nil) {
        let recognizedLines = Self.ordered(Self.reconciled(lines))
        let parseReadyLines = recognizedLines.compactMap(Self.parseReadyLine)
        let orderedLines = Self.orderedAndMerged(parseReadyLines)
        let panelReconstruction = OCRPanelReconstructor().reconstruct(from: orderedLines)
        let parserLines = panelReconstruction.parserLines
        let rejectedLines = recognizedLines.filter { Self.parseReadyLine($0) == nil }
        let averageConfidence = Self.averageConfidence(for: recognizedLines)
        let recognitionPassIDs = Set(recognizedLines.flatMap(\.sourcePassIDs))
        let supportedLineCount = recognizedLines.filter { $0.supportCount > 1 }.count
        let singlePassLineCount = recognizedLines.filter { $0.supportCount <= 1 }.count
        let conflictingLineCount = recognizedLines.filter { $0.qualityFlags.contains(.conflictingCandidates) }.count
        let uncertainLineCount = recognizedLines.filter {
            !$0.qualityFlags.isEmpty || $0.confidence < Self.lowConfidenceThreshold
        }.count
        let averageSupportCount = Self.averageSupportCount(for: recognizedLines)
        let hasLowConfidenceText = averageConfidence < Self.lowConfidenceThreshold
            || recognizedLines.contains { $0.confidence < Self.lowConfidenceThreshold }
            || recognizedLines.contains { $0.qualityFlags.contains(.conflictingCandidates) }
            || recognizedLines.contains { $0.qualityFlags.contains(.lowConfidenceAccepted) }
            || panelReconstruction.hasAmbiguousPanelBoundary
            || imageQuality?.isRiskyForOCR == true
        let hasSupplementLabelSignals = Self.hasSupplementLabelSignals(in: parserLines)

        self.recognizedLines = recognizedLines
        self.rejectedLines = rejectedLines
        self.lines = parserLines
        self.rawText = panelReconstruction.parserText
        self.allRecognizedText = recognizedLines.map(\.text).joined(separator: "\n")
        self.panelReconstruction = panelReconstruction
        self.quality = OCRQualityReport(
            recognizedLineCount: recognizedLines.count,
            parseReadyLineCount: parserLines.count,
            rejectedLowConfidenceLineCount: rejectedLines.count,
            recognitionPassCount: recognitionPassIDs.count,
            supportedLineCount: supportedLineCount,
            singlePassLineCount: singlePassLineCount,
            conflictingLineCount: conflictingLineCount,
            uncertainLineCount: uncertainLineCount,
            averageSupportCount: averageSupportCount,
            averageConfidence: averageConfidence,
            hasLowConfidenceText: hasLowConfidenceText,
            hasSupplementLabelSignals: hasSupplementLabelSignals,
            imageQuality: imageQuality,
            panelConfidence: panelReconstruction.panelConfidence,
            primaryPanelLineCount: panelReconstruction.primaryPanelLineCount,
            excludedNonPanelLineCount: panelReconstruction.excludedLines.count,
            hasAmbiguousPanelBoundary: panelReconstruction.hasAmbiguousPanelBoundary
        )
    }

    private static func reconciled(_ lines: [OCRRecognizedLine]) -> [OCRRecognizedLine] {
        var clusters: [[OCRRecognizedLine]] = []

        for line in ordered(lines).filter({ !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            if let index = clusters.firstIndex(where: { shouldCluster(line, with: $0) }) {
                clusters[index].append(line)
            } else {
                clusters.append([line])
            }
        }

        return clusters.map(reconciledCluster)
    }

    private static func shouldCluster(_ line: OCRRecognizedLine, with cluster: [OCRRecognizedLine]) -> Bool {
        cluster.contains { existing in
            let yClose = abs(line.region.maxY - existing.region.maxY) <= 0.024
            let sameText = normalizedText(line.text) == normalizedText(existing.text)
            if sameText {
                return yClose || horizontalOverlapRatio(line.region, existing.region) >= 0.5
            }

            guard yClose, horizontalOverlapRatio(line.region, existing.region) >= 0.45 else {
                return false
            }

            let similarity = tokenSimilarity(line.text, existing.text)
            if similarity >= 0.72 {
                return true
            }

            if leadingNameToken(line.text) == leadingNameToken(existing.text),
               leadingNameToken(line.text) != nil,
               containsSupplementAmount(line.text),
               containsSupplementAmount(existing.text),
               similarity >= 0.30 {
                return true
            }

            if amountUnitSignature(line.text) == amountUnitSignature(existing.text),
               amountUnitSignature(line.text) != nil,
               similarity >= 0.50 {
                return true
            }

            if let lineCommonName = parentheticalCommonName(line.text),
               lineCommonName == parentheticalCommonName(existing.text),
               amountMagnitudeSignature(line.text) == amountMagnitudeSignature(existing.text),
               amountMagnitudeSignature(line.text) != nil,
               similarity >= 0.35 {
                return true
            }

            return false
        }
    }

    private static func reconciledCluster(_ cluster: [OCRRecognizedLine]) -> OCRRecognizedLine {
        guard cluster.count > 1 else {
            let line = cluster[0]
            var flags = line.qualityFlags
            if line.confidence < lowConfidenceThreshold {
                flags.insert(.lowConfidence)
            }
            if line.sourcePassIDs.count <= 1 {
                flags.insert(.singlePassEvidence)
            }
            return line.addingQualityFlags(flags)
        }

        let best = cluster.max { candidateScore($0) < candidateScore($1) } ?? cluster[0]
        let passIDs = Array(Set(cluster.flatMap(\.sourcePassIDs))).sorted()
        let sourceIDs = Array(Set(cluster.map(\.sourceID))).sorted()
        let normalizedTexts = Set(cluster.map { normalizedText($0.text) }.filter { !$0.isEmpty })
        let finalConfidence = cluster.map(\.confidence).max() ?? best.confidence
        var flags = cluster.reduce(into: Set<OCRLineQualityFlag>()) { result, line in
            result.formUnion(line.qualityFlags)
        }
        flags.remove(.lowConfidence)
        flags.remove(.lowConfidenceAccepted)
        if passIDs.count <= 1 {
            flags.insert(.singlePassEvidence)
        }
        if finalConfidence < lowConfidenceThreshold {
            flags.insert(.lowConfidence)
        }
        if normalizedTexts.count > 1 {
            flags.insert(.conflictingCandidates)
        }

#if DEBUG
        return OCRRecognizedLine(
            text: best.text,
            confidence: finalConfidence,
            region: unionRegion(for: cluster),
            sourceLineCount: cluster.reduce(0) { $0 + $1.sourceLineCount },
            sourceID: sourceIDs.joined(separator: "+"),
            sourcePassIDs: passIDs,
            supportCount: max(passIDs.count, cluster.count),
            qualityFlags: flags,
            alternatives: best.alternatives
        )
#else
        return OCRRecognizedLine(
            text: best.text,
            confidence: finalConfidence,
            region: unionRegion(for: cluster),
            sourceLineCount: cluster.reduce(0) { $0 + $1.sourceLineCount },
            sourceID: sourceIDs.joined(separator: "+"),
            sourcePassIDs: passIDs,
            supportCount: max(passIDs.count, cluster.count),
            qualityFlags: flags
        )
#endif
    }

    private static func parseReadyLine(_ line: OCRRecognizedLine) -> OCRRecognizedLine? {
        if line.confidence >= parseConfidenceThreshold {
            return line.confidence < lowConfidenceThreshold
                ? line.addingQualityFlags([.lowConfidence])
                : line
        }

        guard line.supportCount >= 2,
              containsSupplementAmount(line.text) || containsDomainKeyword(line.text)
        else {
            return nil
        }

        return line.addingQualityFlags([.lowConfidence, .lowConfidenceAccepted])
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
            guard orderedRow.count > 1 else {
                return orderedRow
            }

            let splitRows = splitRowIntoParserRows(orderedRow)
            guard splitRows.count > 1 || orderedRow.contains(where: isAmountOrLeaderFragment) else {
                return orderedRow
            }

            return splitRows.map(mergedRow)
        }
    }

    private static func isAmountOrLeaderFragment(_ line: OCRRecognizedLine) -> Bool {
        let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.range(
            of: #"(?i)^(?:<\s*)?\d+(?:[\.,]\d+)?\s*((?:billion|million)\s+cfu|cfu|mg|mcg|micrograms?|μg|µg|ug|g|iu)\s*$"#,
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
            "probiotic", "lactobacillus", "bifidobacterium", "bacillus",
            "saccharomyces", "taurine", "quercetin", "horsetail", "equisetum",
            "extract", "standardised", "standardized", "elemental"
        ]
        if domainKeywords.contains(where: { lower.contains($0) }) {
            score += 1
        }

        return score >= 2
    }

    private static func containsDomainKeyword(_ text: String) -> Bool {
        let lower = text.lowercased()
        let keywords = [
            "vitamin", "magnesium", "zinc", "calcium", "selenium", "folate",
            "probiotic", "lactobacillus", "bifidobacterium", "bacillus",
            "saccharomyces", "taurine", "quercetin", "horsetail", "equisetum",
            "extract", "standardised", "standardized", "elemental"
        ]
        return keywords.contains { lower.contains($0) }
    }

    private static func candidateScore(_ line: OCRRecognizedLine) -> Double {
        var score = Double(line.confidence)
        score += Double(line.supportCount) * 0.08
        if containsSupplementAmount(line.text) { score += 0.10 }
        if containsDomainKeyword(line.text) { score += 0.05 }
        if line.qualityFlags.contains(.conflictingCandidates) { score -= 0.08 }
        return score
    }

    private static func horizontalOverlapRatio(_ lhs: OCRTextRegion, _ rhs: OCRTextRegion) -> Double {
        let lhsMaxX = lhs.minX + lhs.width
        let rhsMaxX = rhs.minX + rhs.width
        let overlap = max(0, min(lhsMaxX, rhsMaxX) - max(lhs.minX, rhs.minX))
        let smallerWidth = max(0.0001, min(lhs.width, rhs.width))
        return overlap / smallerWidth
    }

    private static func tokenSimilarity(_ lhs: String, _ rhs: String) -> Double {
        let lhsTokens = Set(normalizedText(lhs).split(separator: " ").map(String.init))
        let rhsTokens = Set(normalizedText(rhs).split(separator: " ").map(String.init))
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else { return 0 }
        let intersection = lhsTokens.intersection(rhsTokens).count
        let union = lhsTokens.union(rhsTokens).count
        return Double(intersection) / Double(union)
    }

    private static func normalizedText(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "μ", with: "mc")
            .replacingOccurrences(of: "µ", with: "mc")
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func amountUnitSignature(_ text: String) -> String? {
        guard let match = text.range(
            of: #"(?i)(?:<\s*)?\d+(?:[\.,]\d+)?\s*((?:billion|million)\s+cfu|cfu|mg|mcg|micrograms?|μg|µg|ug|g|iu)\b"#,
            options: .regularExpression
        ) else {
            return nil
        }
        return normalizedText(String(text[match]))
    }

    private static func leadingNameToken(_ text: String) -> String? {
        normalizedText(text)
            .split(separator: " ")
            .first
            .map(String.init)
    }

    private static func unionRegion(for lines: [OCRRecognizedLine]) -> OCRTextRegion {
        let minX = lines.map(\.region.minX).min() ?? 0
        let minY = lines.map(\.region.minY).min() ?? 0
        let maxX = lines.map { $0.region.minX + $0.region.width }.max() ?? minX
        let maxY = lines.map { $0.region.minY + $0.region.height }.max() ?? minY

        return OCRTextRegion(
            minX: minX,
            minY: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }

    private static func averageConfidence(for lines: [OCRRecognizedLine]) -> Float {
        guard !lines.isEmpty else { return 0 }
        let total = lines.reduce(Float.zero) { $0 + $1.confidence }
        return total / Float(lines.count)
    }

    private static func averageSupportCount(for lines: [OCRRecognizedLine]) -> Float {
        guard !lines.isEmpty else { return 0 }
        let total = lines.reduce(0) { $0 + $1.supportCount }
        return Float(total) / Float(lines.count)
    }

    private static func splitRowIntoParserRows(_ orderedRow: [OCRRecognizedLine]) -> [[OCRRecognizedLine]] {
        let nameIndexes = orderedRow.indices.filter { !isAmountOrLeaderFragment(orderedRow[$0]) }
        let amountIndexes = orderedRow.indices.filter { isAmountOrLeaderFragment(orderedRow[$0]) }
        let independentNameIndexes = nameIndexes.filter {
            isLikelyIndependentIngredientStart(orderedRow[$0].text)
        }
        let hasAmountEvidence = !amountIndexes.isEmpty
            || independentNameIndexes.contains { containsSupplementAmount(orderedRow[$0].text) }

        guard independentNameIndexes.count > 1, hasAmountEvidence else {
            return [orderedRow]
        }

        var segments: [[OCRRecognizedLine]] = []
        for (position, nameIndex) in independentNameIndexes.enumerated() {
            let nextNameIndex = position + 1 < independentNameIndexes.count
                ? independentNameIndexes[position + 1]
                : orderedRow.endIndex
            let segment = orderedRow[nameIndex..<nextNameIndex].filter { line in
                !line.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if !segment.isEmpty {
                segments.append(Array(segment))
            }
        }

        return segments.isEmpty ? [orderedRow] : segments
    }

    private static func isLikelyIndependentIngredientStart(_ text: String) -> Bool {
        if looksLikeLatinBinomialStart(text) {
            return true
        }

        let normalized = normalizedText(text)
        guard !normalized.isEmpty else { return false }

        let prefixes = [
            "vitamin", "magnesium", "zinc", "calcium", "selenium", "iron",
            "iodine", "chromium", "manganese", "copper", "molybdenum",
            "phosphorus", "potassium", "sodium", "boron", "silica", "silicon",
            "taurine", "glycine", "inositol", "choline", "quercetin", "rutin",
            "rutoside", "hesperidin", "coenzyme", "coq10", "ubiquinol",
            "n acetyl", "nac", "acetyl", "omega", "epa", "dha", "fish oil",
            "krill oil", "astaxanthin", "lutein", "lycopene", "biotin",
            "folate", "folic", "thiamine", "riboflavin", "niacin",
            "pantothenic", "pyridoxine", "methylcobalamin", "cyanocobalamin",
            "ascorbic", "retinol", "beta carotene", "citrus",
            "lactobacillus", "bifidobacterium", "bacillus", "saccharomyces",
            "streptococcus", "lactococcus", "lacticaseibacillus",
            "lactiplantibacillus", "silybum", "withania", "curcuma",
            "equisetum", "bacopa", "ginkgo", "gingko", "echinacea",
            "horsetail", "milk thistle", "saw palmetto", "ashwagandha",
            "turmeric"
        ]

        return prefixes.contains { prefix in
            normalized == prefix || normalized.hasPrefix(prefix + " ")
        }
    }

    private static func looksLikeLatinBinomialStart(_ text: String) -> Bool {
        text.range(
            of: #"^\s*[A-Z][a-z]{2,}\s+[a-z][a-z-]{2,}\b"#,
            options: .regularExpression
        ) != nil
    }

    private static func parentheticalCommonName(_ text: String) -> String? {
        guard let match = text.range(
            of: #"\([A-Za-z][A-Za-z\s-]{2,}\)"#,
            options: .regularExpression
        ) else {
            return nil
        }

        return normalizedText(String(text[match]))
    }

    private static func amountMagnitudeSignature(_ text: String) -> String? {
        guard let match = text.range(
            of: #"(?i)(?:<\s*)?\d+(?:[\.,]\d+)?\s*(?:billion\s+cfu|million\s+cfu|cfu|mg|mcg|mc|micrograms?|μg|µg|ug|g|iu)\b"#,
            options: .regularExpression
        ) else {
            return nil
        }

        return String(text[match])
            .replacingOccurrences(
                of: #"(?i)[^\d\.,]+"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(of: ",", with: ".")
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
        var qualityFlags = row.reduce(into: Set<OCRLineQualityFlag>()) { result, line in
            result.formUnion(line.qualityFlags)
        }
        if row.count > 1 {
            qualityFlags.insert(.reconstructedFromMultipleFragments)
        }
        let passIDs = Array(Set(row.flatMap(\.sourcePassIDs))).sorted()
        let sourceIDs = Array(Set(row.map(\.sourceID))).sorted()

#if DEBUG
        return OCRRecognizedLine(
            text: text,
            confidence: confidence,
            region: OCRTextRegion(
                minX: minX,
                minY: minY,
                width: maxX - minX,
                height: maxY - minY
            ),
            sourceLineCount: row.reduce(0) { $0 + $1.sourceLineCount },
            sourceID: sourceIDs.joined(separator: "+"),
            sourcePassIDs: passIDs,
            supportCount: max(passIDs.count, row.map(\.supportCount).max() ?? 1),
            qualityFlags: qualityFlags,
            alternatives: row.first?.alternatives ?? []
        )
#else
        return OCRRecognizedLine(
            text: text,
            confidence: confidence,
            region: OCRTextRegion(
                minX: minX,
                minY: minY,
                width: maxX - minX,
                height: maxY - minY
            ),
            sourceLineCount: row.reduce(0) { $0 + $1.sourceLineCount },
            sourceID: sourceIDs.joined(separator: "+"),
            sourcePassIDs: passIDs,
            supportCount: max(passIDs.count, row.map(\.supportCount).max() ?? 1),
            qualityFlags: qualityFlags
        )
#endif
    }
}
