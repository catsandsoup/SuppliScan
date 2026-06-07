// ReportFlags.swift
// SuppliScan
//
// Aggregated flags for a complete label analysis.
// Used to drive the conditional flag banners in ReportView.
// Empty arrays mean no flags of that type — sections are hidden when empty.

import Foundation

nonisolated struct ReportFlags: Codable, Sendable {
    let nutrientsAboveUL: [NutrientAnalysis]       // UL% > 100
    let nutrientsAtUL: [NutrientAnalysis]          // UL% 90–100 (within 10% of UL)
    let lowBioavailabilityForms: [NutrientAnalysis] // tier3 or tier4
    let aiInferredForms: [NutrientAnalysis]        // isAIInferred = true
    let unresolvedEntries: [RawLine]               // lines user did not resolve
    let servingSizeAdjusted: Bool                  // true if multiplier != 1.0
}

nonisolated extension ReportFlags {
    static let empty = ReportFlags(
        nutrientsAboveUL: [],
        nutrientsAtUL: [],
        lowBioavailabilityForms: [],
        aiInferredForms: [],
        unresolvedEntries: [],
        servingSizeAdjusted: false
    )

    var hasAnyFlags: Bool {
        !nutrientsAboveUL.isEmpty
            || !nutrientsAtUL.isEmpty
            || !lowBioavailabilityForms.isEmpty
            || !aiInferredForms.isEmpty
            || !unresolvedEntries.isEmpty
            || servingSizeAdjusted
    }
}
