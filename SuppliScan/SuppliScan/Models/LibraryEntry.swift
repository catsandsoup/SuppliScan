// LibraryEntry.swift
// SuppliScan
//
// Presentation models for the Library (reference encyclopedia). Built by LibraryCatalog
// from supplement_knowledge.json + form_quality.json — purely source-backed. No fabricated
// clinical claims: forms carry curated bioavailability tiers + PMIDs, roles come from the
// curated `outcomes` field, active compounds and dosing come straight from the database.

import Foundation

/// One encyclopedia entry: a nutrient, botanical or probiotic with its forms, roles,
/// dosing context, clinical notes and cited sources.
nonisolated struct LibraryEntry: Identifiable, Hashable, Sendable {
    let canonicalName: String
    let category: SupplementKnowledgeCategory
    let aliases: [String]
    /// Curated roles / marketed uses (e.g. "bone", "muscle", "hair and nail marketing context").
    let roles: [String]
    /// Active constituents (e.g. horsetail → silicon, silica, orthosilicic acid).
    let activeCompounds: [String]
    /// Forms, ranked best→worst where curated quality exists, unranked forms last.
    let forms: [LibraryForm]
    let doseContexts: [SupplementDoseContext]
    let clinicalNotes: [SupplementClinicalNote]
    let sources: [SupplementKnowledgeSource]

    var id: String { canonicalName }

    /// Best curated bioavailability tier present, for a compact list-row hint.
    var bestTier: FormTier? { forms.compactMap(\.tier).min() }

    /// Whether any form carries a curated quality tier.
    var hasRankedForms: Bool { forms.contains { $0.tier != nil } }

    /// Short consumer-facing summary for list rows.
    var summary: String {
        if !roles.isEmpty {
            return roles.prefix(3).map(\.sentenceCased).joined(separator: " · ")
        }
        if !activeCompounds.isEmpty {
            return "Source of " + activeCompounds.prefix(2).joined(separator: ", ")
        }
        return category.displayName
    }
}

/// A single supplement form. `tier` is non-nil only when curated bioavailability data exists.
nonisolated struct LibraryForm: Identifiable, Hashable, Sendable {
    let name: String
    let tier: FormTier?
    let rationale: String?
    let references: [String]

    var id: String { name }
    var isRanked: Bool { tier != nil }
}

// MARK: - Category display

nonisolated extension SupplementKnowledgeCategory {
    var displayName: String {
        switch self {
        case .vitamin:      "Vitamin"
        case .mineral:      "Mineral"
        case .aminoAcid:    "Amino Acid"
        case .fattyAcid:    "Fatty Acid"
        case .botanical:    "Botanical"
        case .probiotic:    "Probiotic"
        case .bioflavonoid: "Bioflavonoid"
        case .other:        "Other"
        }
    }

    var pluralName: String {
        switch self {
        case .vitamin:      "Vitamins"
        case .mineral:      "Minerals"
        case .aminoAcid:    "Amino Acids"
        case .fattyAcid:    "Fatty Acids"
        case .botanical:    "Botanicals"
        case .probiotic:    "Probiotics"
        case .bioflavonoid: "Bioflavonoids"
        case .other:        "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .vitamin:      "pills.fill"
        case .mineral:      "circle.hexagongrid.fill"
        case .aminoAcid:    "link"
        case .fattyAcid:    "drop.fill"
        case .botanical:    "leaf.fill"
        case .probiotic:    "allergens.fill"
        case .bioflavonoid: "camera.macro"
        case .other:        "sparkles"
        }
    }

    /// Stable display order for sectioning the catalog.
    var sortRank: Int {
        switch self {
        case .vitamin:      0
        case .mineral:      1
        case .botanical:    2
        case .probiotic:    3
        case .fattyAcid:    4
        case .aminoAcid:    5
        case .bioflavonoid: 6
        case .other:        7
        }
    }
}

// MARK: - String helpers

nonisolated extension String {
    /// Sentence case: capitalise only the first character, leave the rest as authored
    /// (preserves curated hedges like "hair and nail marketing context").
    var sentenceCased: String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
