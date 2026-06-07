// NutrientCategory.swift
// SuppliScan

import Foundation

nonisolated enum NutrientCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case vitamins = "Vitamins"
    case minerals = "Minerals"
    case other = "Other"

    var id: String { rawValue }

    func matches(_ analysis: NutrientAnalysis) -> Bool {
        switch self {
        case .all: true
        case .vitamins: analysis.entry.canonicalName.localizedCaseInsensitiveContains("vitamin")
        case .minerals: Self.mineralNames.contains(analysis.entry.canonicalName)
        case .other:
            !analysis.entry.canonicalName.localizedCaseInsensitiveContains("vitamin")
                && !Self.mineralNames.contains(analysis.entry.canonicalName)
        }
    }

    private static let mineralNames: Set<String> = [
        "Calcium", "Magnesium", "Iron", "Zinc", "Copper", "Manganese",
        "Selenium", "Chromium", "Molybdenum", "Iodine", "Potassium",
        "Phosphorus", "Sodium", "Chloride", "Boron", "Silicon",
        "Vanadium", "Nickel", "Fluoride"
    ]
}
