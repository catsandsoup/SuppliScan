// ReviewEntryPresentation.swift
// SuppliScan

import Foundation

nonisolated enum ReviewEntryStatus: String, CaseIterable, Sendable {
    case confirmed
    case needsReview
    case otherLabelText

    var sectionTitle: String {
        switch self {
        case .confirmed: "Ready to Analyse"
        case .needsReview: "Needs Review"
        case .otherLabelText: "Other Label Text"
        }
    }

    var label: String {
        switch self {
        case .confirmed: "Confirmed"
        case .needsReview: "Needs review"
        case .otherLabelText: "Ignored by analysis"
        }
    }

    var systemImage: String {
        switch self {
        case .confirmed: "checkmark.circle.fill"
        case .needsReview: "questionmark.circle.fill"
        case .otherLabelText: "text.quote"
        }
    }
}

nonisolated struct ReviewEntryPresentation: Identifiable, Sendable {
    let entry: LabelEntry
    let index: Int
    let status: ReviewEntryStatus

    var id: UUID { entry.id }

    var title: String {
        switch entry {
        case .nutrient(let nutrient):
            nutrient.displayName
        case .herbal(let herbal):
            herbal.latinName
        case .probiotic(let probiotic):
            "\(probiotic.genus) \(probiotic.species)"
        case .unresolved(let rawLine):
            rawLine.text
        }
    }

    var subtitle: String? {
        switch entry {
        case .nutrient(let nutrient):
            if let form = nutrient.form, !form.isEmpty {
                "as \(form)"
            } else if nutrient.isTotalLine {
                "Total line"
            } else {
                nil
            }
        case .herbal(let herbal):
            herbal.commonName
        case .probiotic(let probiotic):
            probiotic.strain
        case .unresolved:
            status == .otherLabelText ? "Not used for nutrient analysis" : "Needs checking"
        }
    }

    var amountText: String? {
        switch entry {
        case .nutrient(let nutrient):
            guard let amount = nutrient.amount else { return nil }
            return "\(amount.formatted()) \(nutrient.unit.displayString)"
        case .herbal(let herbal):
            guard let amount = herbal.extractAmount, let unit = herbal.extractUnit else { return nil }
            return "\(amount.formatted()) \(unit.displayString)"
        case .probiotic(let probiotic):
            guard let cfu = probiotic.cfuBillions else { return nil }
            return "\(cfu.formatted()) B CFU"
        case .unresolved:
            return nil
        }
    }

    var reviewReasons: [String] {
        switch entry {
        case .nutrient(let nutrient):
            nutrient.reviewFlags.map(\.shortLabel)
        case .herbal(let herbal):
            herbal.reviewFlags.map(\.shortLabel)
        case .probiotic(let probiotic):
            probiotic.reviewFlags.map(\.shortLabel)
        case .unresolved:
            status == .otherLabelText ? ["Other label text"] : ["Check this label line"]
        }
    }

    var accessibilitySummary: String {
        [
            title,
            subtitle,
            amountText,
            status.label,
            reviewReasons.joined(separator: ", ")
        ]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: ", ")
    }
}

nonisolated enum ReviewEntryClassifier {
    static func presentations(for entries: [LabelEntry]) -> [ReviewEntryPresentation] {
        entries.enumerated().map { index, entry in
            ReviewEntryPresentation(
                entry: entry,
                index: index,
                status: status(for: entry)
            )
        }
    }

    static func status(for entry: LabelEntry) -> ReviewEntryStatus {
        switch entry {
        case .nutrient(let nutrient):
            if nutrient.amount == nil || nutrient.unit == .unknown || !nutrient.reviewFlags.isEmpty {
                return .needsReview
            }
            return .confirmed
        case .herbal(let herbal):
            return herbal.reviewFlags.isEmpty ? .confirmed : .needsReview
        case .probiotic(let probiotic):
            return probiotic.reviewFlags.isEmpty ? .confirmed : .needsReview
        case .unresolved(let rawLine):
            return isLikelyNonNutrientText(rawLine.text) ? .otherLabelText : .needsReview
        }
    }

    static func confirmed(_ entry: LabelEntry) -> LabelEntry {
        switch entry {
        case .nutrient(var nutrient):
            nutrient.reviewFlags = []
            nutrient.isManuallyEdited = true
            return .nutrient(nutrient)
        case .herbal(var herbal):
            herbal.reviewFlags = []
            herbal.isManuallyEdited = true
            return .herbal(herbal)
        case .probiotic(var probiotic):
            probiotic.reviewFlags = []
            probiotic.isManuallyEdited = true
            return .probiotic(probiotic)
        case .unresolved:
            return entry
        }
    }

    static func suggestedProductName(from entries: [LabelEntry]) -> String {
        let nutrientNames = entries.compactMap { entry -> String? in
            guard case .nutrient(let nutrient) = entry else { return nil }
            return nutrient.canonicalName
        }

        let uniqueNames = Array(NSOrderedSet(array: nutrientNames)) as? [String] ?? nutrientNames
        guard let firstName = uniqueNames.first else { return "Supplement analysis" }

        if uniqueNames.count == 1 {
            return "\(firstName) supplement"
        }

        return "\(firstName) + \(uniqueNames.count - 1) more"
    }

    private static func isLikelyNonNutrientText(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let claimKeywords = [
            "supports",
            "support",
            "maintains",
            "maintenance",
            "manufactured",
            "recommended use",
            "warnings",
            "take ",
            "do not exceed",
            "imported",
            "distributed",
            "health",
            "skin",
            "hair",
            "teeth",
            "nails",
            "store below",
            "lot no",
            "expiry"
        ]

        if claimKeywords.contains(where: { lowercased.localizedStandardContains($0) }) {
            return true
        }

        let hasDose = lowercased.range(
            of: #"\d+(?:[.,]\d+)?\s*(mg|mcg|µg|ug|g|iu|cfu)\b"#,
            options: .regularExpression
        ) != nil

        return !hasDose && lowercased.split(separator: " ").count >= 3
    }
}
