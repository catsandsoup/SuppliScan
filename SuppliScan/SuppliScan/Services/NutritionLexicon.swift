// NutritionLexicon.swift
// SuppliScan
//
// Bundled domain vocabulary for OCR hints and parser canonicalization.
// This is terminology support only; clinical reference values stay in NRV data.

import Foundation

nonisolated struct NutritionLexicon: Decodable, Hashable, Sendable {
    let version: String
    let sourceNote: String
    let entries: [NutritionLexiconEntry]

    enum CodingKeys: String, CodingKey {
        case version
        case sourceNote = "source_note"
        case entries
    }

    static func load(bundle: Bundle = .main) throws -> NutritionLexicon {
        try bundle.referenceData(named: "nutrition_lexicon", as: NutritionLexicon.self)
    }

    var ocrCustomWords: [String] {
        let words = entries.flatMap { entry in
            [entry.canonical]
                + entry.aliases
                + entry.forms
                + entry.labelPhrases
                + entry.commonOCRCorrections
        }

        return Array(Set(words.map(Self.cleanVocabularyTerm).filter { !$0.isEmpty })).sorted()
    }

    var aliasesByVariant: [String: String] {
        entries.reduce(into: [:]) { result, entry in
            result[Self.normalizedKey(entry.canonical)] = entry.canonical
            for variant in entry.aliases + entry.forms {
                result[Self.normalizedKey(variant)] = entry.canonical
            }
        }
    }

    var formsByVariant: [String: String] {
        entries.reduce(into: [:]) { result, entry in
            for form in entry.forms {
                result[Self.normalizedKey(form)] = form
            }
        }
    }

    var semanticProfilesByCanonical: [String: NutritionSemanticProfile] {
        entries.reduce(into: [:]) { result, entry in
            result[Self.normalizedKey(entry.canonical)] = NutritionSemanticProfile(
                canonical: entry.canonical,
                acceptedUnits: Set(entry.acceptedUnits),
                suspiciousUnits: Set(entry.suspiciousUnits)
            )
        }
    }

    var botanicalAliasesByVariant: [String: String] {
        entries.reduce(into: [:]) { result, entry in
            guard entry.category == .botanical else { return }
            result[Self.normalizedKey(entry.canonical)] = entry.canonical
            for variant in entry.aliases {
                result[Self.normalizedKey(variant)] = entry.canonical
            }
        }
    }

    private static func cleanVocabularyTerm(_ value: String) -> String {
        value
            .precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: #"[\n\r\t]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedKey(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

nonisolated struct NutritionLexiconEntry: Decodable, Hashable, Sendable {
    let canonical: String
    let category: NutritionLexiconCategory
    let aliases: [String]
    let forms: [String]
    let labelPhrases: [String]
    let commonOCRCorrections: [String]
    let acceptedUnits: [NutrientUnit]
    let suspiciousUnits: [NutrientUnit]
    let source: String

    enum CodingKeys: String, CodingKey {
        case canonical
        case category
        case aliases
        case forms
        case labelPhrases = "label_phrases"
        case commonOCRCorrections = "common_ocr_corrections"
        case acceptedUnits = "accepted_units"
        case suspiciousUnits = "suspicious_units"
        case source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        canonical = try container.decode(String.self, forKey: .canonical)
        category = try container.decode(NutritionLexiconCategory.self, forKey: .category)
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        forms = try container.decodeIfPresent([String].self, forKey: .forms) ?? []
        labelPhrases = try container.decodeIfPresent([String].self, forKey: .labelPhrases) ?? []
        commonOCRCorrections = try container.decodeIfPresent([String].self, forKey: .commonOCRCorrections) ?? []
        acceptedUnits = try container.decodeIfPresent([NutrientUnit].self, forKey: .acceptedUnits) ?? []
        suspiciousUnits = try container.decodeIfPresent([NutrientUnit].self, forKey: .suspiciousUnits) ?? []
        source = try container.decode(String.self, forKey: .source)
    }
}

nonisolated struct NutritionSemanticProfile: Hashable, Sendable {
    let canonical: String
    let acceptedUnits: Set<NutrientUnit>
    let suspiciousUnits: Set<NutrientUnit>
}

nonisolated enum NutritionLexiconCategory: String, Decodable, Hashable, Sendable {
    case vitamin
    case mineral
    case aminoAcid = "amino_acid"
    case fattyAcid = "fatty_acid"
    case botanical
    case probiotic
    case bioflavonoid
    case other
}
