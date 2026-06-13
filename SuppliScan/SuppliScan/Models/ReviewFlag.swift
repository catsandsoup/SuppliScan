// ReviewFlag.swift
// SuppliScan
//
// Parser-generated warnings attached to extracted label entries.
// Surfaced to the user in ReviewView as inline badges.
// Non-blocking — user can proceed without resolving all flags.
// Never silently suppressed.

import Foundation

nonisolated enum ReviewFlag: String, Codable, Hashable, CaseIterable, Sendable {
    case amountNotFound          // no numeric amount could be extracted
    case unitUnknown             // unit string not in NutrientUnit table
    case dualUnit                // both IU and metric present on label
    case rangeAmount             // "100–200mg" — lower bound used
    case traceAmount             // "trace" — set to 0
    case subOneAmount            // "<1mg" — set to 0.5
    case extractEquivalent       // label shows both extract and active amounts
    case proprietaryBlend        // individual amounts within blend unknown
    case totalLineAmbiguous      // "TOTAL X" line — confirm it supersedes sub-entries
    case iuConversionAssumed     // Vitamin E: synthetic form assumed for conversion
    case iuConversionInvalid     // IU stated for nutrient where IU is not valid
    case decimalCommaNormalised  // European "12,5" normalised to "12.5"
    case servingMultiplied       // amount adjusted by serving size multiplier
    case canonicalNameInferred   // name matched via alias, not exact match
    case unitUnexpected          // unit is unusual for the canonical nutrient
    case unitImplausible         // unit is clinically unlikely for the canonical nutrient
    case ocrUncertain            // OCR evidence was weak or reconstructed
    case ocrConflict             // multiple OCR passes disagreed
    case ocrSinglePassEvidence   // only one recognition pass supported this row
}

nonisolated extension ReviewFlag {
    /// Short user-facing label for the ReviewView badge.
    var shortLabel: String {
        switch self {
        case .amountNotFound:         "Amount missing"
        case .unitUnknown:            "Unknown unit"
        case .dualUnit:               "Dual unit"
        case .rangeAmount:            "Range — lower used"
        case .traceAmount:            "Trace amount"
        case .subOneAmount:           "<1 — set to 0.5"
        case .extractEquivalent:      "Active amount listed"
        case .proprietaryBlend:       "Blend — amounts unknown"
        case .totalLineAmbiguous:     "Confirm total line"
        case .iuConversionAssumed:    "IU conversion assumed"
        case .iuConversionInvalid:    "IU invalid for this nutrient"
        case .decimalCommaNormalised: "Decimal comma normalised"
        case .servingMultiplied:      "Serving adjusted"
        case .canonicalNameInferred:  "Name needs check"
        case .unitUnexpected:         "Unit needs review"
        case .unitImplausible:        "Unit likely wrong"
        case .ocrUncertain:           "OCR uncertain"
        case .ocrConflict:            "OCR conflict"
        case .ocrSinglePassEvidence:  "Single OCR pass"
        }
    }
}
