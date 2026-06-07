// NutrientAnalysis+Display.swift
// SuppliScan
// Display helpers for NutrientAnalysis — colour, formatted strings.
// Used by NutrientAnalysisRowView, NutrientDetailView, and FormsAndPotencyView.

import SwiftUI

extension NutrientAnalysis {
    // Safety colour: red if above UL, orange if approaching, green otherwise, secondary if no data.
    var rdiColor: Color {
        if let ul = ulPercent, ul > 1.0 { return Color(.systemRed) }
        if let rdi = rdiPercent, rdi >= 0.8, let ul = ulPercent, ul > 0.9 { return Color(.systemOrange) }
        if rdiPercent != nil { return Color(.systemGreen) }
        return Color(.secondaryLabel)
    }

    var rdiPercentString: String {
        guard let rdi = rdiPercent else { return "No RDI data" }
        return rdi.formatted(.percent.precision(.fractionLength(0)))
    }

    var ulPercentString: String? {
        guard let ul = ulPercent else { return nil }
        return ul.formatted(.percent.precision(.fractionLength(0)))
    }

    var doseString: String {
        if let dose = effectiveDose, let unit = effectiveDoseUnit {
            return "\(dose.formatted()) \(unit.rawValue)"
        }
        if let amount = entry.amount {
            return "\(amount.formatted()) \(entry.unit.rawValue)"
        }
        return "Unknown amount"
    }

    var rdiReferenceString: String? {
        guard let ref = rdiReference else { return nil }
        return "\(ref.value.formatted()) \(ref.unit.rawValue)"
    }

    var ulReferenceString: String? {
        guard let ref = ulReference else { return nil }
        return "\(ref.value.formatted()) \(ref.unit.rawValue)"
    }
}
