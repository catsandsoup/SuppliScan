// NutritionLexiconTests.swift
// SuppliScanTests

import Foundation
import Testing
@testable import SuppliScan

struct NutritionLexiconTests {
    @Test func loadsBundledNutritionLexiconForOCRVocabulary() throws {
        let lexicon = try NutritionLexicon.load()
        let vocabulary = lexicon.ocrCustomWords
        let normalizedVocabulary = Set(vocabulary.map { $0.lowercased() })

        #expect(lexicon.entries.count >= 31)
        #expect(normalizedVocabulary.contains("magnesium glycinate dihydrate"))
        #expect(normalizedVocabulary.contains("levomefolic acid"))
        #expect(normalizedVocabulary.contains("billion cfu"))
        #expect(normalizedVocabulary.contains("standardised to contain silicon"))
        #expect(normalizedVocabulary.contains("chromium picolinate"))
        #expect(normalizedVocabulary.contains("potassium iodide"))
        #expect(normalizedVocabulary.contains("selenium-enriched yeast"))
        #expect(normalizedVocabulary.contains("mcg dfe"))
    }

    @Test func lexiconProvidesParserAliases() throws {
        let lexicon = try NutritionLexicon.load()
        let aliases = lexicon.aliasesByVariant

        #expect(aliases["ribofiavin"] == "Vitamin B2")
        #expect(aliases["colecalcife"] == "Vitamin D")
        #expect(aliases["quercetin dihydrate"] == "Quercetin")
        #expect(aliases["citrus bioflavonoids extract"] == "Citrus Bioflavonoids")
        #expect(aliases["alpha gpc"] == "Choline")
        #expect(aliases["gtf chromium"] == "Chromium")
        #expect(aliases["sodium iodide"] == "Iodine")
        #expect(aliases["p 5 p"] == "Vitamin B6")
    }

    @Test func lexiconProvidesFormAndUnitSemanticProfiles() throws {
        let lexicon = try NutritionLexicon.load()
        let forms = lexicon.formsByVariant
        let profiles = lexicon.semanticProfilesByCanonical

        #expect(forms["cholecalciferol"] == "cholecalciferol")
        #expect(forms["p 5 p"] == "p-5-p")

        let vitaminB12 = try #require(profiles["vitamin b12"])
        #expect(vitaminB12.acceptedUnits == [.mcg])
        #expect(vitaminB12.suspiciousUnits.contains(.mg))

        let magnesium = try #require(profiles["magnesium"])
        #expect(magnesium.acceptedUnits == [.mg])
        #expect(magnesium.suspiciousUnits.contains(.mcg))
    }

    @Test func lexiconCoversEveryAustralianNRVNutrient() throws {
        let lexicon = try NutritionLexicon.load()
        let canonicalNames = Set(lexicon.entries.map(\.canonical))
        let referenceData = try Bundle.main.referenceData(named: "nrv_au", as: NRVDataFile.self)

        for nutrient in referenceData.nutrients {
            #expect(canonicalNames.contains(nutrient.name))
        }
    }

    @Test func parserDefaultIngestsLexiconAliases() throws {
        let parser = try ParserService.makeDefault()
        let result = parser.parse("""
            Each tablet contains:
            Quercetin dihydrate 500mg
            Colecalcife 25 micrograms
            Ribofiavin 10mg
            """)

        let nutrients = result.entries.compactMap(\.asNutrient)

        #expect(nutrients.contains { $0.canonicalName == "Quercetin" && $0.amount == 500 })
        #expect(nutrients.contains { $0.canonicalName == "Vitamin D" && $0.amount == 25 && $0.unit == .mcg })
        #expect(nutrients.contains { $0.canonicalName == "Vitamin B2" })
    }

    @Test func supplementKnowledgeLoadsSourceBackedOCRVocabularyAndBotanicals() throws {
        let knowledge = try SupplementKnowledgeService.load()
        let words = Set(knowledge.ocrCustomWords.map { $0.lowercased() })

        #expect(words.contains("magnesium glycinate"))
        #expect(words.contains("standardised to contain silicon"))
        #expect(words.contains("billion cfu"))
        #expect(knowledge.botanicalCanonicalByVariant["horsetail"] == "Equisetum arvense")
        #expect(knowledge.entry(canonicalName: "Magnesium")?.doseContexts.isEmpty == false)
        #expect(knowledge.database.sources.contains { $0.id == "ods_probiotics_hp" })
    }
}
