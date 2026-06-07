// Demographic.swift
// SuppliScan
//
// Demographic descriptor used to select the correct NRV/UL row
// from the reference data JSON. The `key` value must match exactly
// the "group" keys in nrv_au.json / nrv_us.json / nrv_eu.json.
// Default: adult_male_19_50 (matches SWIFTDATA.md example).

import Foundation

nonisolated struct Demographic: Codable, Hashable, Sendable {
    let key: String            // e.g. "adult_male_19_50" — must match JSON group keys
    let displayName: String    // e.g. "Adult Male 19–50"
    let ageMin: Int
    let ageMax: Int?           // nil for open-ended groups (e.g. 70+)
    let sex: BiologicalSex
    let isPregnant: Bool
    let isLactating: Bool
}

nonisolated extension Demographic {
    static let defaultAdult = Demographic(
        key: "adult_male_19_50",
        displayName: "Adult Male 19–50",
        ageMin: 19,
        ageMax: 50,
        sex: .male,
        isPregnant: false,
        isLactating: false
    )

    /// All standard demographics available in the picker.
    static let all: [Demographic] = [
        .defaultAdult,
        Demographic(key: "adult_female_19_50", displayName: "Adult Female 19–50",
                    ageMin: 19, ageMax: 50, sex: .female, isPregnant: false, isLactating: false),
        Demographic(key: "adult_male_51_70", displayName: "Adult Male 51–70",
                    ageMin: 51, ageMax: 70, sex: .male, isPregnant: false, isLactating: false),
        Demographic(key: "adult_female_51_70", displayName: "Adult Female 51–70",
                    ageMin: 51, ageMax: 70, sex: .female, isPregnant: false, isLactating: false),
        Demographic(key: "adult_male_70plus", displayName: "Adult Male 70+",
                    ageMin: 70, ageMax: nil, sex: .male, isPregnant: false, isLactating: false),
        Demographic(key: "adult_female_70plus", displayName: "Adult Female 70+",
                    ageMin: 70, ageMax: nil, sex: .female, isPregnant: false, isLactating: false),
        Demographic(key: "adolescent_male_14_18", displayName: "Adolescent Male 14–18",
                    ageMin: 14, ageMax: 18, sex: .male, isPregnant: false, isLactating: false),
        Demographic(key: "adolescent_female_14_18", displayName: "Adolescent Female 14–18",
                    ageMin: 14, ageMax: 18, sex: .female, isPregnant: false, isLactating: false),
        Demographic(key: "pregnant_female_19_50", displayName: "Pregnant",
                    ageMin: 14, ageMax: 50, sex: .female, isPregnant: true, isLactating: false),
        Demographic(key: "lactating_female_19_50", displayName: "Lactating",
                    ageMin: 14, ageMax: 50, sex: .female, isPregnant: false, isLactating: true),
    ]
}

// MARK: - BiologicalSex
// Nested conceptually but in own file per one-type-per-file rule would require
// its own file. Kept here as it is only used by Demographic.

nonisolated enum BiologicalSex: String, Codable, Hashable, CaseIterable, Sendable {
    case male
    case female
    case notSpecified
}
