// ReportFlags.swift
// SuppliScan
//
// Aggregated flags for a complete label analysis.
// Used to drive the conditional flag banners in ReportView.
// Empty arrays mean no flags of that type — sections are hidden when empty.
//
// Custom Codable implementation ensures forward/backward compatibility:
// interaction fields default to [] when absent from legacy JSON.

import Foundation

nonisolated struct ReportFlags: Sendable {
    let nutrientsAboveUL: [NutrientAnalysis]
    let nutrientsAtUL: [NutrientAnalysis]
    let lowBioavailabilityForms: [NutrientAnalysis]
    let aiInferredForms: [NutrientAnalysis]
    let unresolvedEntries: [RawLine]
    let servingSizeAdjusted: Bool
    let nutrientInteractions: [InteractionFlag]
    let medicationInteractions: [MedicationInteractionFlag]
}

// MARK: - Codable (custom to handle missing interaction fields in old records)

nonisolated extension ReportFlags: Codable {
    private enum CodingKeys: String, CodingKey {
        case nutrientsAboveUL, nutrientsAtUL, lowBioavailabilityForms, aiInferredForms
        case unresolvedEntries, servingSizeAdjusted
        case nutrientInteractions, medicationInteractions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nutrientsAboveUL        = try c.decode([NutrientAnalysis].self, forKey: .nutrientsAboveUL)
        nutrientsAtUL           = try c.decode([NutrientAnalysis].self, forKey: .nutrientsAtUL)
        lowBioavailabilityForms = try c.decode([NutrientAnalysis].self, forKey: .lowBioavailabilityForms)
        aiInferredForms         = try c.decode([NutrientAnalysis].self, forKey: .aiInferredForms)
        unresolvedEntries       = try c.decode([RawLine].self, forKey: .unresolvedEntries)
        servingSizeAdjusted     = try c.decode(Bool.self, forKey: .servingSizeAdjusted)
        nutrientInteractions    = (try? c.decode([InteractionFlag].self, forKey: .nutrientInteractions)) ?? []
        medicationInteractions  = (try? c.decode([MedicationInteractionFlag].self, forKey: .medicationInteractions)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(nutrientsAboveUL, forKey: .nutrientsAboveUL)
        try c.encode(nutrientsAtUL, forKey: .nutrientsAtUL)
        try c.encode(lowBioavailabilityForms, forKey: .lowBioavailabilityForms)
        try c.encode(aiInferredForms, forKey: .aiInferredForms)
        try c.encode(unresolvedEntries, forKey: .unresolvedEntries)
        try c.encode(servingSizeAdjusted, forKey: .servingSizeAdjusted)
        try c.encode(nutrientInteractions, forKey: .nutrientInteractions)
        try c.encode(medicationInteractions, forKey: .medicationInteractions)
    }
}

// MARK: - Convenience

nonisolated extension ReportFlags {
    static let empty = ReportFlags(
        nutrientsAboveUL: [],
        nutrientsAtUL: [],
        lowBioavailabilityForms: [],
        aiInferredForms: [],
        unresolvedEntries: [],
        servingSizeAdjusted: false,
        nutrientInteractions: [],
        medicationInteractions: []
    )

    var hasAnyFlags: Bool {
        !nutrientsAboveUL.isEmpty
            || !nutrientsAtUL.isEmpty
            || !lowBioavailabilityForms.isEmpty
            || !aiInferredForms.isEmpty
            || !unresolvedEntries.isEmpty
            || servingSizeAdjusted
            || !nutrientInteractions.isEmpty
            || !medicationInteractions.isEmpty
    }

    var hasAnyInteractions: Bool {
        !nutrientInteractions.isEmpty || !medicationInteractions.isEmpty
    }
}
