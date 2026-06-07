// FormQuality.swift
// SuppliScan
//
// Assessment of a nutrient form's bioavailability and clinical quality.
// Sourced from the curated form_quality.json (isAIInferred = false)
// or inferred by AIService when the form is absent from the DB (isAIInferred = true).
//
// RULE: isAIInferred MUST default to false. Only AIService sets it true.
// This flag must survive all data transformations including Codable round-trip.

import Foundation

struct FormQuality: Codable, Hashable, Sendable {
    let tier: FormTier
    let rationale: String
    let isAIInferred: Bool      // MUST default to false — only AIService sets true
    let confidence: Double?     // only present when isAIInferred = true
    let references: [String]    // PMIDs or citations — empty for AI-inferred results
}

// MARK: - FormTier

enum FormTier: Int, Codable, Hashable, CaseIterable, Comparable, Sendable {
    case tier1 = 1   // High bioavailability, well-evidenced
    case tier2 = 2   // Moderate bioavailability, commonly used
    case tier3 = 3   // Low bioavailability, cheap filler forms
    case tier4 = 4   // Synthetic or potentially problematic

    public static func < (lhs: FormTier, rhs: FormTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension FormTier {
    var displayLabel: String {
        switch self {
        case .tier1: "T1"
        case .tier2: "T2"
        case .tier3: "T3"
        case .tier4: "T4"
        }
    }

    var fullLabel: String {
        switch self {
        case .tier1: "Tier 1 — High Bioavailability"
        case .tier2: "Tier 2 — Moderate Bioavailability"
        case .tier3: "Tier 3 — Low Bioavailability"
        case .tier4: "Tier 4 — Synthetic / Potentially Problematic"
        }
    }
}
