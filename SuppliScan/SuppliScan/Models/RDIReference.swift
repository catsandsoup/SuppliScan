// RDIReference.swift
// SuppliScan
//
// A reference value entry from the NRV database for a given nutrient,
// standard, and demographic. Populated by ReferenceDataService from
// the bundled nrv_*.json files.

import Foundation

nonisolated struct RDIReference: Codable, Hashable, Sendable {
    let standard: ReferenceStandard
    let demographic: String      // group key, e.g. "adult_male_19_50"
    let value: Double
    let unit: NutrientUnit
    let referenceType: ReferenceType  // .rdi | .ear | .ai
    let source: String           // e.g. "NHMRC 2023"
}
