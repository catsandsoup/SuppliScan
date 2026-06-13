// LabelReconstructionEvaluator.swift
// SuppliScan
//
// Deterministic quality scoring for supplement-label reconstruction. This keeps
// OCR/parser work measurable against known difficult labels.

import Foundation

nonisolated struct LabelReconstructionEvaluator: Sendable {
    func evaluate(_ result: ParseResult, against benchmark: LabelReconstructionBenchmark) -> LabelReconstructionScore {
        let expected = benchmark.expectedEntries
        let observed = result.entries.compactMap(ReconstructedFact.init(entry:))

        var unmatchedObserved = observed
        var matched: [ReconstructedFact] = []
        var missing: [ReconstructedFact] = []

        for expectedFact in expected {
            if let index = unmatchedObserved.firstIndex(where: { $0.matches(expectedFact) }) {
                matched.append(expectedFact)
                unmatchedObserved.remove(at: index)
            } else {
                missing.append(expectedFact)
            }
        }

        let precision = observed.isEmpty ? 0 : Double(matched.count) / Double(observed.count)
        let recall = expected.isEmpty ? 0 : Double(matched.count) / Double(expected.count)
        let f1 = precision + recall == 0 ? 0 : 2 * precision * recall / (precision + recall)

        return LabelReconstructionScore(
            expectedCount: expected.count,
            observedCount: observed.count,
            matchedCount: matched.count,
            missing: missing,
            unexpected: unmatchedObserved,
            unresolvedLineCount: result.entries.filter {
                if case .unresolved = $0 { return true }
                return false
            }.count,
            flaggedEntryCount: result.entries.filter(\.hasReviewFlags).count,
            precision: precision,
            recall: recall,
            f1: f1
        )
    }
}

nonisolated struct LabelReconstructionBenchmark: Hashable, Sendable {
    let name: String
    let expectedEntries: [ReconstructedFact]

    init(name: String, expectedEntries: [ReconstructedFact]) {
        self.name = name
        self.expectedEntries = expectedEntries
    }
}

nonisolated struct LabelReconstructionScore: Hashable, Sendable {
    let expectedCount: Int
    let observedCount: Int
    let matchedCount: Int
    let missing: [ReconstructedFact]
    let unexpected: [ReconstructedFact]
    let unresolvedLineCount: Int
    let flaggedEntryCount: Int
    let precision: Double
    let recall: Double
    let f1: Double

    var isComplete: Bool {
        missing.isEmpty && unexpected.isEmpty && unresolvedLineCount == 0
    }
}

nonisolated struct ReconstructedFact: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case nutrient
        case herbal
        case probiotic
    }

    let kind: Kind
    let name: String
    let amount: Double?
    let unit: String?
    let form: String?
    let secondaryAmount: Double?
    let secondaryUnit: String?
    let marker: String?

    init(
        kind: Kind,
        name: String,
        amount: Double? = nil,
        unit: String? = nil,
        form: String? = nil,
        secondaryAmount: Double? = nil,
        secondaryUnit: String? = nil,
        marker: String? = nil
    ) {
        self.kind = kind
        self.name = name
        self.amount = amount
        self.unit = unit
        self.form = form
        self.secondaryAmount = secondaryAmount
        self.secondaryUnit = secondaryUnit
        self.marker = marker
    }

    init?(entry: LabelEntry) {
        switch entry {
        case .nutrient(let nutrient):
            self.init(
                kind: .nutrient,
                name: nutrient.canonicalName,
                amount: nutrient.amount,
                unit: nutrient.unit.rawValue,
                form: nutrient.form,
                secondaryAmount: nutrient.compoundAmount,
                secondaryUnit: nutrient.compoundUnit?.rawValue,
                marker: nutrient.isTotalLine ? "total" : nil
            )
        case .herbal(let herbal):
            self.init(
                kind: .herbal,
                name: herbal.latinName,
                amount: herbal.extractAmount,
                unit: herbal.extractUnit?.rawValue,
                form: herbal.extractType.rawValue,
                secondaryAmount: herbal.standardisation?.amount ?? herbal.dryEquivalentAmount,
                secondaryUnit: herbal.standardisation?.unit.rawValue ?? herbal.dryEquivalentUnit?.rawValue,
                marker: herbal.standardisation?.compound
            )
        case .probiotic(let probiotic):
            self.init(
                kind: .probiotic,
                name: "\(probiotic.genus) \(probiotic.species)",
                amount: probiotic.cfuBillions,
                unit: "billion CFU",
                form: probiotic.strain,
                marker: probiotic.isTotalLine ? "total" : nil
            )
        case .unresolved:
            return nil
        }
    }

    func matches(_ expected: ReconstructedFact) -> Bool {
        kind == expected.kind
            && normalized(name) == normalized(expected.name)
            && matchesText(form, expected.form)
            && matchesText(marker, expected.marker)
            && matchesText(unit, expected.unit)
            && matchesAmount(amount, expected.amount)
            && matchesAmount(secondaryAmount, expected.secondaryAmount)
    }

    private func matchesText(_ observed: String?, _ expected: String?) -> Bool {
        guard let expected else {
            return true
        }
        return normalized(observed ?? "") == normalized(expected)
    }

    private func matchesAmount(_ observed: Double?, _ expected: Double?) -> Bool {
        guard let expected else {
            return true
        }
        guard let observed else {
            return false
        }
        return abs(observed - expected) <= max(0.01, abs(expected) * 0.01)
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
