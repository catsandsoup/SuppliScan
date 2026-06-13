// LibraryCatalog.swift
// SuppliScan
//
// Builds the Library encyclopedia by merging two source-backed reference files:
//   • supplement_knowledge.json — entries (roles, active compounds, dosing, notes, sources)
//   • form_quality.json         — per-form bioavailability tiers + rationale + PMIDs
//
// The merge is the only "new" data work, and it invents nothing: it joins curated forms to
// curated quality on nutrient name, and resolves source IDs to citations. Loaded once.

import Foundation

nonisolated struct LibraryCatalog: Sendable {
    let entries: [LibraryEntry]

    static let empty = LibraryCatalog(entries: [])

    /// Load + merge both reference files. Throws only if the knowledge file is missing.
    static func load(bundle: Bundle = .main) throws -> LibraryCatalog {
        let knowledge = try bundle.referenceData(
            named: "supplement_knowledge",
            as: SupplementKnowledgeDatabase.self
        )
        let formFile = (try? bundle.referenceData(
            named: "form_quality",
            as: LibraryFormQualityFile.self
        )) ?? LibraryFormQualityFile(forms: [])

        let formsByNutrient = Dictionary(grouping: formFile.forms) {
            SupplementKnowledgeService.normalizedKey($0.nutrient)
        }
        // First source wins on duplicate IDs.
        var sourcesByID: [String: SupplementKnowledgeSource] = [:]
        for source in knowledge.sources where sourcesByID[source.id] == nil {
            sourcesByID[source.id] = source
        }

        let entries = knowledge.entries
            .map { entry -> LibraryEntry in
                let qualityRows = formsByNutrient[SupplementKnowledgeService.normalizedKey(entry.canonicalName)] ?? []
                let forms = mergeForms(knowledgeForms: entry.forms, qualityRows: qualityRows)
                let sources = resolveSources(for: entry, using: sourcesByID)
                return LibraryEntry(
                    canonicalName: entry.canonicalName,
                    category: entry.category,
                    aliases: entry.aliases,
                    roles: entry.outcomes,
                    activeCompounds: entry.activeCompounds,
                    forms: forms,
                    doseContexts: entry.doseContexts,
                    clinicalNotes: entry.clinicalNotes,
                    sources: sources
                )
            }
            .sorted {
                ($0.category.sortRank, $0.canonicalName.localizedLowercase)
                    < ($1.category.sortRank, $1.canonicalName.localizedLowercase)
            }

        return LibraryCatalog(entries: entries)
    }

    // MARK: - Merge

    /// Curated quality rows first (best tier → worst), then any remaining knowledge-only forms.
    private static func mergeForms(
        knowledgeForms: [String],
        qualityRows: [LibraryFormQualityRow]
    ) -> [LibraryForm] {
        let ranked: [LibraryForm] = qualityRows
            .compactMap { row in
                guard let tier = FormTier(rawValue: row.tier) else { return nil }
                return LibraryForm(name: row.form, tier: tier, rationale: row.rationale, references: row.references)
            }
            .sorted {
                ($0.tier?.rawValue ?? 99, $0.name) < ($1.tier?.rawValue ?? 99, $1.name)
            }

        let rankedNormalized = ranked.map { SupplementKnowledgeService.normalizedKey($0.name) }
        let unranked: [LibraryForm] = knowledgeForms.compactMap { formName in
            let normalized = SupplementKnowledgeService.normalizedKey(formName)
            let alreadyCovered = rankedNormalized.contains {
                $0.contains(normalized) || normalized.contains($0)
            }
            guard !alreadyCovered else { return nil }
            return LibraryForm(name: formName, tier: nil, rationale: nil, references: [])
        }

        return ranked + unranked
    }

    /// Unique, order-preserving sources referenced by the entry, its dosing and its notes.
    private static func resolveSources(
        for entry: SupplementKnowledgeEntry,
        using sourcesByID: [String: SupplementKnowledgeSource]
    ) -> [SupplementKnowledgeSource] {
        var ids: [String] = entry.sourceIDs
        ids += entry.doseContexts.flatMap(\.sourceIDs)
        ids += entry.clinicalNotes.flatMap(\.sourceIDs)

        var seen = Set<String>()
        return ids.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return sourcesByID[id]
        }
    }
}

// MARK: - form_quality.json decoding (Library-local shape)

nonisolated private struct LibraryFormQualityFile: Decodable {
    let forms: [LibraryFormQualityRow]
}

nonisolated private struct LibraryFormQualityRow: Decodable {
    let nutrient: String
    let form: String
    let tier: Int
    let rationale: String
    let references: [String]
}
