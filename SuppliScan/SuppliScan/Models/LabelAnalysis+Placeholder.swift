// LabelAnalysis+Placeholder.swift
// SuppliScan
//
// Placeholder factory used by ReviewViewModel before ReportService is wired.
// Lets the full UI chain work end-to-end: Review → Analysis → NutrientDetail.

import Foundation

extension LabelAnalysis {
    static func placeholder(
        entries: [LabelEntry],
        serving: ServingSize?,
        standard: ReferenceStandard
    ) -> LabelAnalysis {
        let resolvedServing = serving ?? ServingSize(quantity: 1, unit: .capsule)
        return LabelAnalysis(
            id: UUID(),
            productName: "Review Required",
            referenceStandard: standard,
            demographic: .defaultAdult,
            servingSize: resolvedServing,
            nutrientAnalyses: [],
            herbalEntries: entries.compactMap(\.asHerbal),
            probioticEntries: entries.compactMap(\.asProbiotic),
            unresolvedLines: entries.compactMap(\.asRawLine),
            flags: .empty,
            disclaimer: LabelAnalysis.disclaimer,
            schemaVersion: LabelAnalysis.currentSchemaVersion,
            createdAt: Date()
        )
    }
}
