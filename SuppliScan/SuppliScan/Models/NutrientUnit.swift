// NutrientUnit.swift
// SuppliScan
//
// Normalised unit of measurement for a nutrient or herbal entry.
// .iu is ONLY valid at parser stage. UnitConversionService converts all
// .iu to .mg or .mcg before CalculationService is called.
// CalculationService must assert unit != .iu and throw if it receives one.

import Foundation

enum NutrientUnit: String, Codable, Hashable, CaseIterable, Sendable {
    case mg
    case mcg
    case g
    case iu      // Parser-stage only — must not reach CalculationService
    case unknown // OCR extracted an unrecognised unit string — preserved for review
}

extension NutrientUnit {
    /// Units that CalculationService accepts. .iu must be converted first.
    static var calculationUnits: Set<NutrientUnit> { [.mg, .mcg, .g] }

    /// Human-readable display string for report and review UI.
    var displayString: String {
        switch self {
        case .mg:      "mg"
        case .mcg:     "mcg"
        case .g:       "g"
        case .iu:      "IU"
        case .unknown: "?"
        }
    }
}
