// ULReference.swift
// SuppliScan
//
// An upper limit (UL) reference entry from the NRV database.
// nil for nutrients where no UL has been established.
// Some ULs apply to supplemental intake only — the note field captures this.

import Foundation

nonisolated struct ULReference: Codable, Hashable, Sendable {
    let standard: ReferenceStandard
    let demographic: String   // group key, e.g. "adult_male_19_50"
    let value: Double
    let unit: NutrientUnit
    let note: String?         // e.g. "applies to supplemental magnesium only"
    let source: String
}
