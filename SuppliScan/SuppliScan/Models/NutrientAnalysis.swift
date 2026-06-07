// NutrientAnalysis.swift
// SuppliScan
//
// The result of analysing a single NutrientEntry against the reference data.
// Produced by CalculationService, coordinated by ReportService.
//
// rdiPercent and ulPercent are nil when no reference data exists for the
// nutrient + standard + demographic combination — never default to 0.
// This nil state is displayed as "No reference data" in the report.

import Foundation

nonisolated struct NutrientAnalysis: Identifiable, Codable, Sendable {
    let id: UUID
    let entry: NutrientEntry
    let rdiPercent: Double?          // nil if no RDI established for this nutrient
    let ulPercent: Double?           // nil if no UL established
    let rdiReference: RDIReference?  // nil if no reference found
    let ulReference: ULReference?    // nil if no UL found
    let formQuality: FormQuality?    // nil if form is absent or could not be assessed
    let effectiveDose: Double?       // entry.amount * servingMultiplier
    let effectiveDoseUnit: NutrientUnit?

    init(
        id: UUID = UUID(),
        entry: NutrientEntry,
        rdiPercent: Double? = nil,
        ulPercent: Double? = nil,
        rdiReference: RDIReference? = nil,
        ulReference: ULReference? = nil,
        formQuality: FormQuality? = nil,
        effectiveDose: Double? = nil,
        effectiveDoseUnit: NutrientUnit? = nil
    ) {
        self.id = id
        self.entry = entry
        self.rdiPercent = rdiPercent
        self.ulPercent = ulPercent
        self.rdiReference = rdiReference
        self.ulReference = ulReference
        self.formQuality = formQuality
        self.effectiveDose = effectiveDose
        self.effectiveDoseUnit = effectiveDoseUnit
    }
}

// MARK: - Hashable (id-based)

nonisolated extension NutrientAnalysis: Hashable {
    static func == (lhs: NutrientAnalysis, rhs: NutrientAnalysis) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
