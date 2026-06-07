// ReferenceDataService.swift
// SuppliScan
//
// Actor-isolated loader for bundled clinical reference data.

import Foundation

actor ReferenceDataService {
    private let bundle: Bundle
    private var entriesByStandard: [ReferenceStandard: [String: NRVNutrientEntry]] = [:]
    private var aliasesByVariant: [String: String] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// Loads all bundled NRV files and aliases into memory.
    func load() async throws {
        var loadedEntries: [ReferenceStandard: [String: NRVNutrientEntry]] = [:]

        for standard in ReferenceStandard.allCases {
            let file = try bundle.referenceData(named: standard.jsonFileName, as: NRVDataFile.self)
            loadedEntries[standard] = Dictionary(
                uniqueKeysWithValues: file.nutrients.map { (Self.normalizedKey($0.name), $0) }
            )
        }

        let aliasFile = try bundle.referenceData(named: "aliases", as: ReferenceAliasDataFile.self)
        var aliases: [String: String] = [:]
        for alias in aliasFile.aliases {
            aliases[Self.normalizedKey(alias.canonical)] = alias.canonical
            for variant in alias.variants {
                aliases[Self.normalizedKey(variant)] = alias.canonical
            }
        }

        entriesByStandard = loadedEntries
        aliasesByVariant = aliases
    }

    /// Returns reference data for a nutrient, standard, and demographic.
    func nrvEntry(
        for nutrient: String,
        standard: ReferenceStandard,
        demographic: Demographic
    ) -> NRVEntry? {
        guard let nutrientEntry = entriesByStandard[standard]?[Self.normalizedKey(canonicalName(for: nutrient))],
              let demographicEntry = nutrientEntry.demographics.first(where: { $0.group == demographic.key })
        else {
            return nil
        }

        let source = nutrientEntry.source ?? standard.displayName
        let rdiValue = demographicEntry.rdi ?? demographicEntry.ear ?? demographicEntry.ai
        let rdiReference = rdiValue.map {
            RDIReference(
                standard: standard,
                demographic: demographic.key,
                value: $0,
                unit: nutrientEntry.calculationUnit,
                referenceType: demographicEntry.referenceType,
                source: source
            )
        }
        let ulReference = demographicEntry.ul.map {
            ULReference(
                standard: standard,
                demographic: demographic.key,
                value: $0,
                unit: nutrientEntry.calculationUnit,
                note: demographicEntry.ulNote,
                source: source
            )
        }

        return NRVEntry(rdi: rdiReference, ul: ulReference)
    }

    /// Returns the loaded alias map as variant-to-canonical display names.
    func aliases() -> [String: String] {
        aliasesByVariant
    }

    private func canonicalName(for nutrient: String) -> String {
        aliasesByVariant[Self.normalizedKey(nutrient)] ?? nutrient
    }

    private static func normalizedKey(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

nonisolated struct NRVEntry: Hashable, Sendable {
    let rdi: RDIReference?
    let ul: ULReference?
}

nonisolated struct NRVDataFile: Decodable, Sendable {
    let standard: ReferenceStandard
    let edition: String
    let source: String
    let nutrients: [NRVNutrientEntry]
}

nonisolated struct NRVNutrientEntry: Decodable, Hashable, Sendable {
    let name: String
    let aliases: [String]
    let calculationUnit: NutrientUnit
    let source: String?
    let demographics: [NRVDemographicEntry]

    enum CodingKeys: String, CodingKey {
        case name
        case aliases
        case calculationUnit = "calculation_unit"
        case source
        case demographics
    }
}

nonisolated struct NRVDemographicEntry: Decodable, Hashable, Sendable {
    let group: String
    let rdi: Double?
    let ear: Double?
    let ai: Double?
    let ul: Double?
    let ulNote: String?
    let referenceType: ReferenceType

    enum CodingKeys: String, CodingKey {
        case group
        case rdi
        case ear
        case ai
        case ul
        case ulNote = "ul_note"
        case referenceType = "reference_type"
    }
}

nonisolated private struct ReferenceAliasDataFile: Decodable {
    let aliases: [ReferenceAliasEntry]
}

nonisolated private struct ReferenceAliasEntry: Decodable {
    let canonical: String
    let variants: [String]
}
