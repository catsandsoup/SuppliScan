// SupplementKnowledgeService.swift
// SuppliScan
//
// Source-backed supplement knowledge used for OCR hints and parser verification.
// This is not a recommendation engine; it never creates label facts that OCR did
// not observe.

import Foundation

nonisolated struct SupplementKnowledgeService: Sendable {
    let database: SupplementKnowledgeDatabase

    static func load(bundle: Bundle = .main) throws -> SupplementKnowledgeService {
        let database = try bundle.referenceData(named: "supplement_knowledge", as: SupplementKnowledgeDatabase.self)
        return SupplementKnowledgeService(database: database)
    }

    var ocrCustomWords: [String] {
        database.ocrCustomWords
    }

    var botanicalCanonicalByVariant: [String: String] {
        database.entries.reduce(into: [:]) { result, entry in
            guard entry.category == .botanical else { return }
            result[Self.normalizedKey(entry.canonicalName)] = entry.canonicalName
            for variant in entry.aliases {
                result[Self.normalizedKey(variant)] = entry.canonicalName
            }
        }
    }

    var categoryByCanonical: [String: SupplementKnowledgeCategory] {
        database.entries.reduce(into: [:]) { result, entry in
            result[Self.normalizedKey(entry.canonicalName)] = entry.category
        }
    }

    func entry(canonicalName: String) -> SupplementKnowledgeEntry? {
        database.entries.first {
            Self.normalizedKey($0.canonicalName) == Self.normalizedKey(canonicalName)
        }
    }

    static func normalizedKey(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

nonisolated struct SupplementKnowledgeDatabase: Decodable, Hashable, Sendable {
    let version: String
    let sourceNote: String
    let entries: [SupplementKnowledgeEntry]
    let sources: [SupplementKnowledgeSource]

    enum CodingKeys: String, CodingKey {
        case version
        case sourceNote = "source_note"
        case entries
        case sources
    }

    var ocrCustomWords: [String] {
        var words: [String] = []
        for entry in entries {
            words.append(entry.canonicalName)
            words.append(contentsOf: entry.aliases)
            words.append(contentsOf: entry.forms)
            words.append(contentsOf: entry.activeCompounds)
            words.append(contentsOf: entry.ocrTerms)
            words.append(contentsOf: entry.outcomes)
        }

        return Array(Set(words.map(Self.cleanVocabularyTerm).filter { !$0.isEmpty })).sorted()
    }

    private static func cleanVocabularyTerm(_ value: String) -> String {
        value
            .precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: #"[\n\r\t]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

nonisolated struct SupplementKnowledgeEntry: Decodable, Hashable, Sendable {
    let canonicalName: String
    let category: SupplementKnowledgeCategory
    let aliases: [String]
    let forms: [String]
    let activeCompounds: [String]
    let ocrTerms: [String]
    let outcomes: [String]
    let doseContexts: [SupplementDoseContext]
    let clinicalNotes: [SupplementClinicalNote]
    let sourceIDs: [String]

    enum CodingKeys: String, CodingKey {
        case canonicalName = "canonical_name"
        case category
        case aliases
        case forms
        case activeCompounds = "active_compounds"
        case ocrTerms = "ocr_terms"
        case outcomes
        case doseContexts = "dose_contexts"
        case clinicalNotes = "clinical_notes"
        case sourceIDs = "source_ids"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        canonicalName = try container.decode(String.self, forKey: .canonicalName)
        category = try container.decode(SupplementKnowledgeCategory.self, forKey: .category)
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        forms = try container.decodeIfPresent([String].self, forKey: .forms) ?? []
        activeCompounds = try container.decodeIfPresent([String].self, forKey: .activeCompounds) ?? []
        ocrTerms = try container.decodeIfPresent([String].self, forKey: .ocrTerms) ?? []
        outcomes = try container.decodeIfPresent([String].self, forKey: .outcomes) ?? []
        doseContexts = try container.decodeIfPresent([SupplementDoseContext].self, forKey: .doseContexts) ?? []
        clinicalNotes = try container.decodeIfPresent([SupplementClinicalNote].self, forKey: .clinicalNotes) ?? []
        sourceIDs = try container.decodeIfPresent([String].self, forKey: .sourceIDs) ?? []
    }
}

nonisolated enum SupplementKnowledgeCategory: String, Decodable, Hashable, Sendable {
    case vitamin
    case mineral
    case aminoAcid = "amino_acid"
    case fattyAcid = "fatty_acid"
    case botanical
    case probiotic
    case bioflavonoid
    case other
}

nonisolated struct SupplementDoseContext: Decodable, Hashable, Sendable {
    let context: String
    let lowerBound: Double?
    let upperBound: Double?
    let unit: String
    let population: String?
    let interpretation: String
    let evidenceLevel: String
    let sourceIDs: [String]

    enum CodingKeys: String, CodingKey {
        case context
        case lowerBound = "lower_bound"
        case upperBound = "upper_bound"
        case unit
        case population
        case interpretation
        case evidenceLevel = "evidence_level"
        case sourceIDs = "source_ids"
    }
}

nonisolated struct SupplementClinicalNote: Decodable, Hashable, Sendable {
    let topic: String
    let text: String
    let evidenceLevel: String
    let sourceIDs: [String]

    enum CodingKeys: String, CodingKey {
        case topic
        case text
        case evidenceLevel = "evidence_level"
        case sourceIDs = "source_ids"
    }
}

nonisolated struct SupplementKnowledgeSource: Decodable, Hashable, Sendable {
    let id: String
    let title: String
    let url: URL
    let sourceType: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case sourceType = "source_type"
    }
}
