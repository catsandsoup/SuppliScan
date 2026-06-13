// OCRPanelReconstructor.swift
// SuppliScan

import Foundation

nonisolated enum OCRPanelSection: String, Hashable, Sendable {
    case factsPanel
    case activeIngredients
    case serving
    case ingredientLikeOutsidePanel
    case otherIngredients
    case directions
    case warnings
    case marketing
    case company
    case unknown
}

nonisolated struct OCRPanelRow: Hashable, Sendable {
    let line: OCRRecognizedLine
    let section: OCRPanelSection
    let score: Int
    let reasons: [String]
}

nonisolated struct OCRPanelReconstruction: Hashable, Sendable {
    let rows: [OCRPanelRow]
    let parserLines: [OCRRecognizedLine]
    let excludedLines: [OCRRecognizedLine]
    let primaryPanelLineCount: Int
    let panelConfidence: Float
    let hasExplicitPanelHeading: Bool
    let hasAmbiguousPanelBoundary: Bool

    var parserText: String {
        parserLines.map(\.text).joined(separator: "\n")
    }
}

nonisolated struct OCRPanelReconstructor: Sendable {
    func reconstruct(from lines: [OCRRecognizedLine]) -> OCRPanelReconstruction {
        guard !lines.isEmpty else {
            return OCRPanelReconstruction(
                rows: [],
                parserLines: [],
                excludedLines: [],
                primaryPanelLineCount: 0,
                panelConfidence: 0,
                hasExplicitPanelHeading: false,
                hasAmbiguousPanelBoundary: true
            )
        }

        let classified = lines.enumerated().map { index, line in
            classifiedRow(for: line, index: index)
        }

        guard let window = primaryPanelWindow(in: classified) else {
            return fallbackReconstruction(from: classified)
        }

        let windowIndexes = Set(window)
        var parserIndexes = Set<Int>()
        for index in window {
            let row = classified[index]
            if row.isParserCandidate || row.isPanelHeading || row.section == .serving {
                parserIndexes.insert(index)
            }
        }

        let outsideIngredientIndexes = classified.indices.filter { index in
            !windowIndexes.contains(index)
                && classified[index].isIngredientLike
                && !classified[index].isHardStop
        }
        for index in outsideIngredientIndexes {
            parserIndexes.insert(index)
        }

        if parserIndexes.isEmpty {
            return fallbackReconstruction(from: classified)
        }

        let rows = classified.map { row in
            let section: OCRPanelSection
            if outsideIngredientIndexes.contains(row.index) {
                section = .ingredientLikeOutsidePanel
            } else {
                section = row.section
            }
            return OCRPanelRow(
                line: row.line,
                section: section,
                score: row.score,
                reasons: row.reasons.sorted()
            )
        }

        let parserLines = parserIndexes.sorted().map { classified[$0].line }
        let excludedLines = classified.indices
            .filter { !parserIndexes.contains($0) }
            .map { classified[$0].line }
        let hasExplicitPanelHeading = classified[window].contains(where: \.isPanelHeading)
        let ingredientCount = parserIndexes.filter { classified[$0].isIngredientLike }.count
        let hasServingEvidence = parserIndexes.contains { classified[$0].section == .serving }
        let hasAmbiguousBoundary = !hasExplicitPanelHeading
            || !outsideIngredientIndexes.isEmpty
            || ingredientCount == 0
            || window.count <= 1

        return OCRPanelReconstruction(
            rows: rows,
            parserLines: parserLines,
            excludedLines: excludedLines,
            primaryPanelLineCount: window.count,
            panelConfidence: confidence(
                hasExplicitHeading: hasExplicitPanelHeading,
                ingredientCount: ingredientCount,
                hasServingEvidence: hasServingEvidence,
                outsideIngredientCount: outsideIngredientIndexes.count,
                primaryPanelLineCount: window.count
            ),
            hasExplicitPanelHeading: hasExplicitPanelHeading,
            hasAmbiguousPanelBoundary: hasAmbiguousBoundary
        )
    }

    private func fallbackReconstruction(from rows: [ClassifiedPanelRow]) -> OCRPanelReconstruction {
        OCRPanelReconstruction(
            rows: rows.map {
                OCRPanelRow(
                    line: $0.line,
                    section: $0.section,
                    score: $0.score,
                    reasons: $0.reasons.sorted()
                )
            },
            parserLines: rows.map(\.line),
            excludedLines: [],
            primaryPanelLineCount: 0,
            panelConfidence: 0,
            hasExplicitPanelHeading: false,
            hasAmbiguousPanelBoundary: true
        )
    }

    private func primaryPanelWindow(in rows: [ClassifiedPanelRow]) -> Range<Int>? {
        if let headingIndex = rows.firstIndex(where: \.isPanelHeading) {
            return headingWindow(startingAt: headingIndex, in: rows)
        }

        return densestIngredientWindow(in: rows)
    }

    private func headingWindow(startingAt headingIndex: Int, in rows: [ClassifiedPanelRow]) -> Range<Int> {
        var endIndex = rows.endIndex
        var seenPanelEvidence = false

        for index in rows.indices where index > headingIndex {
            let row = rows[index]
            if row.isIngredientLike || row.section == .serving {
                seenPanelEvidence = true
            }
            if seenPanelEvidence, row.isHardStop {
                endIndex = index
                break
            }
        }

        return headingIndex..<max(headingIndex + 1, endIndex)
    }

    private func densestIngredientWindow(in rows: [ClassifiedPanelRow]) -> Range<Int>? {
        var bestRange: Range<Int>?
        var bestScore = 0
        var startIndex: Int?
        var runningScore = 0

        func closeRun(at endIndex: Int) {
            guard let start = startIndex else { return }
            let range = start..<endIndex
            if runningScore > bestScore || (runningScore == bestScore && range.count > (bestRange?.count ?? 0)) {
                bestScore = runningScore
                bestRange = range
            }
            startIndex = nil
            runningScore = 0
        }

        for index in rows.indices {
            let row = rows[index]
            if row.isIngredientLike || row.section == .serving {
                if startIndex == nil {
                    startIndex = index
                }
                runningScore += max(1, row.score)
            } else if row.section == .unknown, startIndex != nil {
                runningScore += 1
            } else {
                closeRun(at: index)
            }
        }

        closeRun(at: rows.endIndex)

        guard let bestRange, bestScore >= 4 else {
            return nil
        }
        return bestRange
    }

    private func classifiedRow(for line: OCRRecognizedLine, index: Int) -> ClassifiedPanelRow {
        let lower = normalized(line.text)
        var score = 0
        var reasons: Set<String> = []

        if containsPanelHeading(lower) {
            score += 6
            reasons.insert("panel-heading")
        }
        if containsServingHeading(lower) {
            score += 3
            reasons.insert("serving-heading")
        }
        if containsSupplementAmount(lower) {
            score += 3
            reasons.insert("supplement-amount")
        }
        if containsDomainKeyword(lower) {
            score += 2
            reasons.insert("domain-keyword")
        }
        if containsProbioticSignal(lower) {
            score += 3
            reasons.insert("probiotic-signal")
        }
        if containsBotanicalSignal(lower) {
            score += 2
            reasons.insert("botanical-signal")
        }

        let hardStop = hardStopSection(for: lower)
        if hardStop != nil {
            score -= 5
            reasons.insert("section-stop")
        }
        if containsMarketingSignal(lower) {
            score -= 2
            reasons.insert("marketing-signal")
        }

        let ingredientLike = isIngredientLike(lower)
        let section: OCRPanelSection
        if containsPanelHeading(lower) {
            section = .factsPanel
        } else if containsServingHeading(lower) {
            section = .serving
        } else if let hardStop {
            section = hardStop
        } else if ingredientLike {
            section = .activeIngredients
        } else if containsMarketingSignal(lower) {
            section = .marketing
        } else {
            section = .unknown
        }

        return ClassifiedPanelRow(
            index: index,
            line: line,
            section: section,
            score: score,
            reasons: Array(reasons),
            isIngredientLike: ingredientLike,
            isPanelHeading: containsPanelHeading(lower),
            isHardStop: hardStop != nil
        )
    }

    private func confidence(
        hasExplicitHeading: Bool,
        ingredientCount: Int,
        hasServingEvidence: Bool,
        outsideIngredientCount: Int,
        primaryPanelLineCount: Int
    ) -> Float {
        var score: Float = hasExplicitHeading ? 0.45 : 0.25
        if ingredientCount >= 3 {
            score += 0.30
        } else if ingredientCount >= 1 {
            score += 0.18
        }
        if hasServingEvidence {
            score += 0.08
        }
        if primaryPanelLineCount >= 4 {
            score += 0.07
        }
        if outsideIngredientCount > 0 {
            score -= min(0.18, Float(outsideIngredientCount) * 0.06)
        }
        return min(1, max(0, score))
    }

    private func isIngredientLike(_ text: String) -> Bool {
        if containsProbioticSignal(text) {
            return true
        }

        guard containsSupplementAmount(text) else {
            return false
        }

        return containsDomainKeyword(text)
            || containsBotanicalSignal(text)
            || containsEquivalentSignal(text)
            || looksLikeLatinBinomial(text)
    }

    private func containsPanelHeading(_ text: String) -> Bool {
        containsAny(
            text,
            [
                "supplement facts",
                "nutrition facts",
                "nutrition information",
                "active ingredients",
                "amount per serving",
                "amount per serve",
                "each tablet contains",
                "each capsule contains",
                "each softgel contains",
                "each dose contains",
                "each scoop contains",
                "per daily dose"
            ]
        )
    }

    private func containsServingHeading(_ text: String) -> Bool {
        containsAny(
            text,
            [
                "serving size",
                "servings per container",
                "amount per serving",
                "amount per serve",
                "each tablet contains",
                "each capsule contains",
                "each dose contains"
            ]
        )
    }

    private func hardStopSection(for text: String) -> OCRPanelSection? {
        if containsAny(text, ["directions", "suggested use", "recommended use", "how to use"]) {
            return .directions
        }
        if containsAny(text, ["warning", "caution", "contraindication", "keep out of reach", "do not use"]) {
            return .warnings
        }
        if containsAny(text, ["other ingredients", "inactive ingredients", "excipients"]) {
            return .otherIngredients
        }
        if containsAny(
            text,
            [
                "distributed by",
                "manufactured by",
                "made in",
                "health direction pty",
                "pty ltd",
                "www.",
                ".com",
                "batch",
                "lot ",
                "best before",
                "expiry",
                "expires"
            ]
        ) {
            return .company
        }
        return nil
    }

    private func containsMarketingSignal(_ text: String) -> Bool {
        containsAny(
            text,
            [
                "clinically researched",
                "practitioner",
                "premium",
                "high strength",
                "advanced formula",
                "supports",
                "gluten free",
                "vegan",
                "natural",
                "no artificial",
                "third party tested",
                "money back"
            ]
        )
    }

    private func containsSupplementAmount(_ text: String) -> Bool {
        text.range(
            of: #"(?i)(?:<\s*)?\b\d+(?:[\.,]\d+)?\s*(?:billion\s+cfu|million\s+cfu|cfu|mg|mcg|micrograms?|ug|g|iu)\b"#,
            options: .regularExpression
        ) != nil
    }

    private func containsDomainKeyword(_ text: String) -> Bool {
        containsAny(
            text,
            [
                "vitamin",
                "magnesium",
                "zinc",
                "calcium",
                "selenium",
                "folate",
                "biotin",
                "iron",
                "iodine",
                "chromium",
                "molybdenum",
                "taurine",
                "quercetin",
                "inositol",
                "choline",
                "omega",
                "dha",
                "epa",
                "coq10",
                "ubiquinol",
                "ashwagandha",
                "turmeric",
                "curcumin",
                "milk thistle",
                "silybin",
                "horsetail",
                "equisetum",
                "extract",
                "standardised",
                "standardized",
                "elemental",
                "equiv"
            ]
        )
    }

    private func containsBotanicalSignal(_ text: String) -> Bool {
        containsAny(
            text,
            [
                "extract",
                "herb",
                "root",
                "leaf",
                "stem",
                "fruit",
                "seed",
                "rhizome",
                "flower",
                "standardised",
                "standardized",
                "equivalent to dry",
                "dry herb",
                "dry root",
                "dry stem",
                "withania",
                "curcuma",
                "silybum",
                "equisetum",
                "bacopa",
                "gingko",
                "ginkgo"
            ]
        )
    }

    private func containsProbioticSignal(_ text: String) -> Bool {
        containsAny(
            text,
            [
                "cfu",
                "lactobacillus",
                "bifidobacterium",
                "bacillus",
                "saccharomyces",
                "streptococcus",
                "lacticaseibacillus",
                "lactiplantibacillus"
            ]
        )
    }

    private func containsEquivalentSignal(_ text: String) -> Bool {
        containsAny(text, ["equiv", "equivalent", "providing", "elemental", "standardised", "standardized"])
    }

    private func looksLikeLatinBinomial(_ text: String) -> Bool {
        text.range(
            of: #"\b[a-z][a-z]{3,}\s+[a-z][a-z]{3,}\b"#,
            options: .regularExpression
        ) != nil
    }

    private func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private func normalized(_ text: String) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "μ", with: "mc")
            .replacingOccurrences(of: "µ", with: "mc")
    }
}

private nonisolated struct ClassifiedPanelRow {
    let index: Int
    let line: OCRRecognizedLine
    let section: OCRPanelSection
    let score: Int
    let reasons: [String]
    let isIngredientLike: Bool
    let isPanelHeading: Bool
    let isHardStop: Bool

    var isParserCandidate: Bool {
        switch section {
        case .factsPanel, .activeIngredients, .serving, .ingredientLikeOutsidePanel:
            true
        case .unknown:
            isIngredientLike
        case .otherIngredients, .directions, .warnings, .marketing, .company:
            false
        }
    }
}
