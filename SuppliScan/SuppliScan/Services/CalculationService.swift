// CalculationService.swift
// SuppliScan
//
// Applies serving size and compares nutrient doses against loaded NRV data.

import Foundation

nonisolated enum CalculationService {
    /// Calculates dose and reference percentages for a single nutrient entry.
    static func analysis(
        for entry: NutrientEntry,
        reference: NRVEntry?,
        servingSize: ServingSize,
        formQuality: FormQuality? = nil
    ) throws -> NutrientAnalysis {
        guard entry.unit != .iu else {
            throw AppError.calculationUnitConversionRequired(
                nutrient: entry.displayName,
                unit: entry.unit.displayString
            )
        }

        guard NutrientUnit.calculationUnits.contains(entry.unit) else {
            throw AppError.calculationUnsupportedUnit(
                nutrient: entry.displayName,
                unit: entry.unit.displayString
            )
        }

        let effectiveDose = entry.amount.map { $0 * servingSize.multiplier }

        var calculatedEntry = entry
        calculatedEntry.servingMultiplier = servingSize.multiplier
        if servingSize.multiplier != 1 {
            calculatedEntry.reviewFlags = appended(.servingMultiplied, to: calculatedEntry.reviewFlags)
        }

        return NutrientAnalysis(
            entry: calculatedEntry,
            rdiPercent: percent(effectiveDose, of: reference?.rdi?.value),
            ulPercent: percent(effectiveDose, of: reference?.ul?.value),
            rdiReference: reference?.rdi,
            ulReference: reference?.ul,
            formQuality: formQuality,
            effectiveDose: effectiveDose,
            effectiveDoseUnit: entry.unit
        )
    }

    private static func percent(_ dose: Double?, of referenceValue: Double?) -> Double? {
        guard let dose, let referenceValue, referenceValue > 0 else { return nil }
        return dose / referenceValue * 100
    }

    private static func appended(_ flag: ReviewFlag, to flags: [ReviewFlag]) -> [ReviewFlag] {
        flags.contains(flag) ? flags : flags + [flag]
    }
}
