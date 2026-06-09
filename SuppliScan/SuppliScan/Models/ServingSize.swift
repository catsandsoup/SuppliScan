// ServingSize.swift
// SuppliScan
//
// Captures how the label states serving information and the user's
// selected serving quantity.
//
// multiplier is a computed property — it is the ratio of the
// user-selected serving to the label's stated serving.
// CalculationService applies this multiplier exactly once.

import Foundation

nonisolated struct ServingSize: Codable, Hashable, Sendable {
    var quantity: Double           // label's stated serving, e.g. 1, 2, 5
    var unit: ServingUnit
    var quantityOptions: [Double]  // available options, e.g. [1, 2, 3] for variable dosing
    var selectedQuantity: Double   // user-selected serving, defaults to quantity

    /// Ratio applied to all entry amounts. CalculationService applies this once only.
    var multiplier: Double {
        guard quantity > 0 else { return 1.0 }
        return selectedQuantity / quantity
    }

    init(
        quantity: Double,
        unit: ServingUnit,
        quantityOptions: [Double]? = nil,
        selectedQuantity: Double? = nil
    ) {
        self.quantity = quantity
        self.unit = unit
        self.quantityOptions = quantityOptions ?? [quantity]
        self.selectedQuantity = selectedQuantity ?? quantity
    }
}

// MARK: - ServingUnit

nonisolated enum ServingUnit: String, Codable, Hashable, CaseIterable, Sendable {
    case capsule
    case tablet
    case teaspoon
    case tablespoon
    case gram
    case ml
    case sachet
    case scoop
    case unknown
}

nonisolated extension ServingUnit {
    var displayName: String {
        switch self {
        case .capsule:    "capsule"
        case .tablet:     "tablet"
        case .teaspoon:   "teaspoon"
        case .tablespoon: "tablespoon"
        case .gram:       "g"
        case .ml:         "ml"
        case .sachet:     "sachet"
        case .scoop:      "scoop"
        case .unknown:    "serving"
        }
    }

    func pluralised(for quantity: Double) -> String {
        switch self {
        case .gram, .ml, .unknown:
            displayName
        case .capsule, .tablet, .teaspoon, .tablespoon, .sachet, .scoop:
            quantity == 1 ? displayName : "\(displayName)s"
        }
    }
}
