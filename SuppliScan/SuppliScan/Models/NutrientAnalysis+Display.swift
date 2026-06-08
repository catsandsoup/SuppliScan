// NutrientAnalysis+Display.swift
// SuppliScan
// Display helpers for NutrientAnalysis — colour, formatted strings.
// Used by NutrientAnalysisRowView, NutrientDetailView, and FormsAndPotencyView.

import SwiftUI

extension NutrientAnalysis {
    // Safety colour: red if above UL, orange if approaching UL, green otherwise.
    var rdiColor: Color {
        if let ul = ulPercent, ul > 1.0 { return AppTheme.Color.rdiDanger }
        if let rdi = rdiPercent, rdi >= 0.8, let ul = ulPercent, ul > 0.9 { return AppTheme.Color.rdiWarning }
        if rdiPercent != nil { return AppTheme.Color.rdiSafe }
        return AppTheme.Color.rdiNoData
    }

    var rdiPercentString: String {
        guard let rdi = rdiPercent else { return "—" }
        let pct = Int((rdi * 100).rounded())
        return "\(pct)%"
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
