// UnitConversionService.swift
// SuppliScan
//
// Deterministic parser-stage unit conversion. These are the only IU
// conversions allowed by PARSER_SPEC.md.

import Foundation

nonisolated enum UnitConversionService {
    static func convertIfNeeded(_ entry: NutrientEntry) -> NutrientEntry {
        guard entry.unit == .iu else { return entry }

        let nutrientName = searchableText(for: entry)
        guard let amount = entry.amount else {
            return convertedEntry(entry, amount: nil, unit: targetUnit(for: nutrientName))
        }

        if isVitaminD(nutrientName) {
            return convertedEntry(entry, amount: amount * 0.025, unit: .mcg)
        }

        if isVitaminA(nutrientName) {
            return convertVitaminA(entry, amount: amount)
        }

        if isVitaminE(nutrientName) {
            return convertVitaminE(entry, amount: amount)
        }

        return flaggedAsInvalid(entry)
    }

    private static func convertVitaminA(_ entry: NutrientEntry, amount: Double) -> NutrientEntry {
        let formText = searchableFormText(for: entry)

        if formText.contains("retinol") || formText.contains("retinyl") {
            return convertedEntry(entry, amount: amount * 0.3, unit: .mcg)
        }

        if formText.contains("beta-carotene") || formText.contains("beta carotene") {
            return convertedEntry(entry, amount: amount * 0.3, unit: .mcg)
        }

        return flaggedAsInvalid(entry)
    }

    private static func convertVitaminE(_ entry: NutrientEntry, amount: Double) -> NutrientEntry {
        let formText = searchableFormText(for: entry)

        if formText.contains("d-alpha") || formText.contains("natural") {
            return convertedEntry(entry, amount: amount * 0.67, unit: .mg)
        }

        if formText.contains("dl-alpha") || formText.contains("synthetic") {
            return convertedEntry(entry, amount: amount * 0.45, unit: .mg)
        }

        var converted = convertedEntry(entry, amount: amount * 0.45, unit: .mg)
        converted.reviewFlags = appended(.iuConversionAssumed, to: converted.reviewFlags)
        return converted
    }

    private static func convertedEntry(
        _ entry: NutrientEntry,
        amount: Double?,
        unit: NutrientUnit
    ) -> NutrientEntry {
        var converted = entry
        converted.amount = amount
        converted.unit = unit
        return converted
    }

    private static func flaggedAsInvalid(_ entry: NutrientEntry) -> NutrientEntry {
        var flagged = entry
        flagged.reviewFlags = appended(.iuConversionInvalid, to: flagged.reviewFlags)
        return flagged
    }

    private static func appended(_ flag: ReviewFlag, to flags: [ReviewFlag]) -> [ReviewFlag] {
        flags.contains(flag) ? flags : flags + [flag]
    }

    private static func targetUnit(for nutrientName: String) -> NutrientUnit {
        if isVitaminE(nutrientName) { return .mg }
        if isVitaminA(nutrientName) || isVitaminD(nutrientName) { return .mcg }
        return .iu
    }

    private static func searchableText(for entry: NutrientEntry) -> String {
        [entry.canonicalName, entry.displayName, entry.form ?? ""]
            .joined(separator: " ")
            .lowercased()
    }

    private static func searchableFormText(for entry: NutrientEntry) -> String {
        [entry.displayName, entry.form ?? ""]
            .joined(separator: " ")
            .lowercased()
    }

    private static func isVitaminA(_ text: String) -> Bool {
        text.contains("vitamin a") || text.contains("retinol") || text.contains("beta-carotene")
            || text.contains("beta carotene")
    }

    private static func isVitaminD(_ text: String) -> Bool {
        text.contains("vitamin d") || text.contains("cholecalciferol") || text.contains("ergocalciferol")
    }

    private static func isVitaminE(_ text: String) -> Bool {
        text.contains("vitamin e") || text.contains("tocopherol") || text.contains("tocotrienol")
    }
}
