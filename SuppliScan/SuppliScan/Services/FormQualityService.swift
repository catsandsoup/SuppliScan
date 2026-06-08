// FormQualityService.swift
// SuppliScan
//
// Actor-isolated loader for curated form quality data.
// Loads form_quality.json on load() and provides fuzzy nutrient+form matching.
// isAIInferred is always false for results from this service.

import Foundation

actor FormQualityService {
    private var entries: [FormEntry] = []

    func load() async throws {
        let file = try Bundle.main.referenceData(named: "form_quality", as: FormQualityFile.self)
        entries = file.forms.compactMap { raw in
            guard let tier = FormTier(rawValue: raw.tier) else { return nil }
            return FormEntry(
                nutrientNormalized: normalize(raw.nutrient),
                formNormalized: normalize(raw.form),
                tier: tier,
                rationale: raw.rationale,
                references: raw.references
            )
        }
    }

    /// Returns curated form quality for a given canonical nutrient name and form string.
    /// Returns nil if no curated entry matches — caller may fall back to AI inference.
    func quality(for nutrientName: String, form: String) -> FormQuality? {
        let normalizedNutrient = normalize(nutrientName)
        let normalizedForm = normalize(form)

        let nutrientEntries = entries.filter { $0.nutrientNormalized == normalizedNutrient }
        guard !nutrientEntries.isEmpty else { return nil }

        let match = nutrientEntries.first { entry in
            normalizedForm.contains(entry.formNormalized) ||
            entry.formNormalized.contains(normalizedForm)
        }

        guard let match else { return nil }

        return FormQuality(
            tier: match.tier,
            rationale: match.rationale,
            isAIInferred: false,
            confidence: nil,
            references: match.references
        )
    }

    // MARK: - Private

    private struct FormEntry {
        let nutrientNormalized: String
        let formNormalized: String
        let tier: FormTier
        let rationale: String
        let references: [String]
    }

    private func normalize(_ string: String) -> String {
        string
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - JSON Decodable types

nonisolated private struct FormQualityFile: Decodable {
    let forms: [RawFormEntry]

    nonisolated struct RawFormEntry: Decodable {
        let nutrient: String
        let form: String
        let tier: Int
        let rationale: String
        let references: [String]
    }
}
