// LibraryCatalogTests.swift
// SuppliScanTests
//
// Unit tests for the Library's only genuinely new logic: merging curated forms with
// bioavailability tiers, and the presentation derivations on LibraryEntry. Pure and
// deterministic — no bundle, no DB, no simulator.

import Testing
@testable import SuppliScan

struct LibraryCatalogTests {

    // MARK: - Helpers

    private func makeEntry(
        roles: [String] = [],
        activeCompounds: [String] = [],
        forms: [LibraryForm] = [],
        category: SupplementKnowledgeCategory = .mineral
    ) -> LibraryEntry {
        LibraryEntry(
            canonicalName: "Test",
            category: category,
            aliases: [],
            roles: roles,
            activeCompounds: activeCompounds,
            forms: forms,
            doseContexts: [],
            clinicalNotes: [],
            sources: []
        )
    }

    // MARK: - mergeForms

    @Test func mergeRanksByTierThenAppendsUnrankedKnowledgeForms() {
        let quality = [
            LibraryFormQualityRow(nutrient: "Magnesium", form: "magnesium oxide", tier: 3, rationale: "low", references: []),
            LibraryFormQualityRow(nutrient: "Magnesium", form: "magnesium glycinate", tier: 1, rationale: "chelate", references: ["PMID:1"]),
            LibraryFormQualityRow(nutrient: "Magnesium", form: "magnesium citrate", tier: 2, rationale: "soluble", references: []),
        ]
        // "magnesium glycinate" is already curated; "magnesium taurate" is knowledge-only.
        let knowledge = ["magnesium glycinate", "magnesium taurate"]

        let result = LibraryCatalog.mergeForms(knowledgeForms: knowledge, qualityRows: quality)

        #expect(result.map(\.tier) == [.tier1, .tier2, .tier3, nil])
        #expect(result.map(\.name) == [
            "magnesium glycinate", "magnesium citrate", "magnesium oxide", "magnesium taurate"
        ])
    }

    @Test func mergeDoesNotDuplicateAFormCoveredByCuratedQuality() {
        let quality = [
            LibraryFormQualityRow(nutrient: "Zinc", form: "zinc picolinate", tier: 1, rationale: "good", references: []),
        ]
        // "picolinate" is a substring of the curated "zinc picolinate" → must be deduped.
        let knowledge = ["picolinate", "zinc oxide"]

        let result = LibraryCatalog.mergeForms(knowledgeForms: knowledge, qualityRows: quality)

        #expect(result.count == 2)
        #expect(result.filter { $0.name.lowercased().contains("picolinate") }.count == 1)
        #expect(result.last?.name == "zinc oxide")
        #expect(result.last?.tier == nil)
    }

    @Test func mergePreservesReferencesAndRationaleOnRankedForms() {
        let quality = [
            LibraryFormQualityRow(nutrient: "Iron", form: "ferrous bisglycinate", tier: 1, rationale: "chelated", references: ["PMID:12589194"]),
        ]
        let result = LibraryCatalog.mergeForms(knowledgeForms: [], qualityRows: quality)

        #expect(result.count == 1)
        #expect(result[0].rationale == "chelated")
        #expect(result[0].references == ["PMID:12589194"])
        #expect(result[0].isRanked)
    }

    @Test func mergeWithNoQualityYieldsOnlyUnrankedForms() {
        let result = LibraryCatalog.mergeForms(
            knowledgeForms: ["dried stem extract", "horsetail extract"],
            qualityRows: []
        )
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.tier == nil })
    }

    // MARK: - LibraryEntry derivations

    @Test func bestTierIsTheLowestTierNumberAcrossForms() {
        let entry = makeEntry(forms: [
            LibraryForm(name: "a", tier: .tier3, rationale: nil, references: []),
            LibraryForm(name: "b", tier: .tier1, rationale: nil, references: []),
            LibraryForm(name: "c", tier: nil, rationale: nil, references: []),
        ])
        #expect(entry.bestTier == .tier1)
        #expect(entry.hasRankedForms)
    }

    @Test func noRankedFormsMeansNilBestTier() {
        let entry = makeEntry(forms: [LibraryForm(name: "a", tier: nil, rationale: nil, references: [])])
        #expect(entry.bestTier == nil)
        #expect(entry.hasRankedForms == false)
    }

    @Test func summaryPrefersRolesThenCompoundsThenCategory() {
        #expect(makeEntry(roles: ["bone", "muscle"]).summary == "Bone · Muscle")
        #expect(makeEntry(activeCompounds: ["silicon", "silica"]).summary == "Source of silicon, silica")
        #expect(makeEntry(category: .botanical).summary == "Botanical")
    }

    @Test func summaryCapsRolesAtThree() {
        let entry = makeEntry(roles: ["a", "b", "c", "d", "e"])
        #expect(entry.summary == "A · B · C")
    }

    // MARK: - String + category helpers

    @Test func sentenceCasedCapitalisesOnlyFirstCharacterPreservingHedges() {
        #expect("hair and nail marketing context".sentenceCased == "Hair and nail marketing context")
        #expect("bone".sentenceCased == "Bone")
        #expect("".sentenceCased == "")
    }

    @Test func categoryFilterMatchingGroupsOtherCategories() {
        #expect(LibraryCategoryFilter.all.matches(.vitamin))
        #expect(LibraryCategoryFilter.vitamins.matches(.vitamin))
        #expect(LibraryCategoryFilter.vitamins.matches(.mineral) == false)
        #expect(LibraryCategoryFilter.other.matches(.fattyAcid))
        #expect(LibraryCategoryFilter.other.matches(.bioflavonoid))
        #expect(LibraryCategoryFilter.other.matches(.vitamin) == false)
    }

    @Test func categorySortRankOrdersVitaminsMineralsBotanicalsProbiotics() {
        #expect(SupplementKnowledgeCategory.vitamin.sortRank < SupplementKnowledgeCategory.mineral.sortRank)
        #expect(SupplementKnowledgeCategory.mineral.sortRank < SupplementKnowledgeCategory.botanical.sortRank)
        #expect(SupplementKnowledgeCategory.botanical.sortRank < SupplementKnowledgeCategory.probiotic.sortRank)
    }
}
