// HerbalEntry.swift
// SuppliScan
//
// A herbal or botanical extract entry from a supplement label.
// No NRV data applies. Form quality assessed on extract type
// and standardisation level.
//
// servingMultiplier applied by CalculationService when used for
// form quality assessment context — matches NutrientEntry behaviour.

import Foundation

nonisolated struct HerbalEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var latinName: String              // e.g. "Silybum marianum"
    var commonName: String?            // e.g. "St Mary's Thistle"
    var extractType: ExtractType
    var extractAmount: Double?
    var extractUnit: NutrientUnit?
    var dryEquivalentAmount: Double?   // the "equivalent to dry" value
    var dryEquivalentUnit: NutrientUnit?
    var standardisation: HerbalStandardisation?
    var reviewFlags: [ReviewFlag]
    var isManuallyEdited: Bool
    var servingMultiplier: Double      // default 1.0

    init(
        id: UUID = UUID(),
        latinName: String,
        commonName: String? = nil,
        extractType: ExtractType = .unknown,
        extractAmount: Double? = nil,
        extractUnit: NutrientUnit? = nil,
        dryEquivalentAmount: Double? = nil,
        dryEquivalentUnit: NutrientUnit? = nil,
        standardisation: HerbalStandardisation? = nil,
        reviewFlags: [ReviewFlag] = [],
        isManuallyEdited: Bool = false,
        servingMultiplier: Double = 1.0
    ) {
        self.id = id
        self.latinName = latinName
        self.commonName = commonName
        self.extractType = extractType
        self.extractAmount = extractAmount
        self.extractUnit = extractUnit
        self.dryEquivalentAmount = dryEquivalentAmount
        self.dryEquivalentUnit = dryEquivalentUnit
        self.standardisation = standardisation
        self.reviewFlags = reviewFlags
        self.isManuallyEdited = isManuallyEdited
        self.servingMultiplier = servingMultiplier
    }
}

// MARK: - HerbalStandardisation

nonisolated struct HerbalStandardisation: Codable, Hashable, Sendable {
    var compound: String     // e.g. "flavanolignans", "fatty acids", "silicon"
    var calculatedAs: String? // e.g. "silybin"
    var amount: Double
    var unit: NutrientUnit
}

// MARK: - ExtractType

nonisolated enum ExtractType: String, Codable, Hashable, CaseIterable, Sendable {
    case dryConcExtract   // AU TGA standard dry concentrate
    case softConcentrate  // lipid-based soft extract (e.g. saw palmetto)
    case driedHerb        // whole dried herb powder
    case tincture         // liquid extract
    case unknown
}

extension ExtractType {
    var displayName: String {
        switch self {
        case .dryConcExtract:  "Dry Concentrated Extract"
        case .softConcentrate: "Soft Concentrate"
        case .driedHerb:       "Dried Herb"
        case .tincture:        "Tincture"
        case .unknown:         "Unknown"
        }
    }
}
