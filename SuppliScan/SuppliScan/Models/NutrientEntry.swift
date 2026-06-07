// NutrientEntry.swift
// SuppliScan
//
// A single quantified nutrient from a supplement label.
// amount is Optional<Double> — nil means the amount could not be extracted.
// Never coerce nil to 0.0. 0.0 and nil mean different things clinically.
//
// After ParserService: unit is never .iu — UnitConversionService converts all IU.
// CalculationService asserts unit != .iu and throws if it receives one.
//
// servingMultiplier defaults to 1.0 at parse time. CalculationService
// applies it exactly once to produce effectiveDose. Never apply elsewhere.

import Foundation

nonisolated struct NutrientEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var canonicalName: String        // matched via alias table, e.g. "Vitamin D"
    var displayName: String          // as it appeared on label, e.g. "Cholecalciferol"
    var form: String?                // e.g. "magnesium glycinate"
    var amount: Double?              // nil if OCR could not extract — NEVER default to 0
    var unit: NutrientUnit           // .mg | .mcg | .g — never .iu after ParserService
    var isElemental: Bool            // true if amount is elemental weight
    var compoundAmount: Double?      // original compound weight if elemental was extracted
    var compoundUnit: NutrientUnit?  // unit of the compound form
    var isTotalLine: Bool            // true if this is a summary total, not an individual form
    var reviewFlags: [ReviewFlag]    // parser-generated warnings for ReviewView
    var isManuallyEdited: Bool       // true if user corrected any field in ReviewView
    var servingMultiplier: Double    // default 1.0 — applied once by CalculationService only

    init(
        id: UUID = UUID(),
        canonicalName: String,
        displayName: String,
        form: String? = nil,
        amount: Double? = nil,
        unit: NutrientUnit,
        isElemental: Bool = false,
        compoundAmount: Double? = nil,
        compoundUnit: NutrientUnit? = nil,
        isTotalLine: Bool = false,
        reviewFlags: [ReviewFlag] = [],
        isManuallyEdited: Bool = false,
        servingMultiplier: Double = 1.0
    ) {
        self.id = id
        self.canonicalName = canonicalName
        self.displayName = displayName
        self.form = form
        self.amount = amount
        self.unit = unit
        self.isElemental = isElemental
        self.compoundAmount = compoundAmount
        self.compoundUnit = compoundUnit
        self.isTotalLine = isTotalLine
        self.reviewFlags = reviewFlags
        self.isManuallyEdited = isManuallyEdited
        self.servingMultiplier = servingMultiplier
    }
}
