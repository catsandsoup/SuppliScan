// InteractionService.swift
// SuppliScan
//
// Actor-isolated loader for curated interaction data.
// Loads interactions.json on load() and detects interactions among a list of
// nutrient canonical names.

import Foundation

actor InteractionService {
    private var nutrientInteractions: [NutrientInteractionData] = []
    private var medicationInteractionData: [MedicationInteractionData] = []

    func load() async throws {
        let file = try Bundle.main.referenceData(named: "interactions", as: InteractionsFile.self)
        nutrientInteractions = file.nutrientInteractions
        medicationInteractionData = file.medicationInteractions
    }

    /// Returns interactions detected among the given canonical nutrient names.
    func interactions(for nutrients: [String]) -> [InteractionFlag] {
        let normalizedNames = Set(nutrients.map { normalize($0) })
        return nutrientInteractions.compactMap { data in
            let normalizedParticipants = data.participants.map { normalize($0) }
            guard normalizedParticipants.allSatisfy({ normalizedNames.contains($0) }) else { return nil }
            guard let severity = InteractionSeverity(rawValue: data.severity) else { return nil }
            return InteractionFlag(
                participants: data.participants,
                severity: severity,
                effect: data.effect,
                recommendation: data.recommendation,
                references: data.references
            )
        }
    }

    /// Returns medication interaction warnings for the given canonical nutrient names.
    /// These are always shown when a matching nutrient is present — not filtered by detected medications.
    func medicationInteractions(for nutrients: [String]) -> [MedicationInteractionFlag] {
        let normalizedNames = Set(nutrients.map { normalize($0) })
        return medicationInteractionData.compactMap { data in
            guard normalizedNames.contains(normalize(data.nutrient)) else { return nil }
            guard let severity = InteractionSeverity(rawValue: data.severity) else { return nil }
            return MedicationInteractionFlag(
                nutrient: data.nutrient,
                medicationClass: data.medicationClass,
                severity: severity,
                effect: data.effect,
                recommendation: data.recommendation,
                references: data.references
            )
        }
    }

    private func normalize(_ string: String) -> String {
        string
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - JSON Decodable types

nonisolated private struct InteractionsFile: Decodable {
    let version: Int
    let nutrientInteractions: [NutrientInteractionData]
    let medicationInteractions: [MedicationInteractionData]

    enum CodingKeys: String, CodingKey {
        case version
        case nutrientInteractions = "nutrient_interactions"
        case medicationInteractions = "medication_interactions"
    }
}

nonisolated private struct NutrientInteractionData: Decodable {
    let participants: [String]
    let severity: String
    let effect: String
    let recommendation: String
    let references: [String]
}

nonisolated private struct MedicationInteractionData: Decodable {
    let nutrient: String
    let medicationClass: String
    let severity: String
    let effect: String
    let recommendation: String
    let references: [String]

    enum CodingKeys: String, CodingKey {
        case nutrient
        case medicationClass = "medication_class"
        case severity
        case effect
        case recommendation
        case references
    }
}
