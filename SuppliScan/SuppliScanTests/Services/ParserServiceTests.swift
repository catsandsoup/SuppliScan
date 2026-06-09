// ParserServiceTests.swift
// SuppliScanTests

import Testing
@testable import SuppliScan

struct ParserServiceTests {
    @Test func parsesParentheticalFormAndAmount() {
        let parser = ParserService(aliasesByVariant: ["Magnesium": "Magnesium"])
        let result = parser.parse("Magnesium (as magnesium glycinate) 300mg")

        guard case .nutrient(let entry)? = result.entries.first else {
            Issue.record("Expected nutrient entry")
            return
        }

        #expect(entry.canonicalName == "Magnesium")
        #expect(entry.form == "magnesium glycinate")
        #expect(entry.amount == 300)
        #expect(entry.unit == .mg)
    }

    @Test func convertsVitaminDInternationalUnitsDuringParsing() {
        let parser = ParserService(aliasesByVariant: ["Vitamin D3": "Vitamin D"])
        let result = parser.parse("Vitamin D3 1000IU (25mcg)")

        guard case .nutrient(let entry)? = result.entries.first else {
            Issue.record("Expected nutrient entry")
            return
        }

        #expect(entry.canonicalName == "Vitamin D")
        #expect(entry.amount == 25)
        #expect(entry.unit == .mcg)
        #expect(entry.reviewFlags.contains(.dualUnit))
    }

    @Test func parsesFullWordMicrogramsAsMcg() throws {
        let parser = ParserService(aliasesByVariant: ["Levomefolic acid": "Vitamin B9"])
        let result = parser.parse("Levomefolic acid 200 micrograms")

        guard case .nutrient(let entry)? = result.entries.first else {
            Issue.record("Expected nutrient entry")
            return
        }

        #expect(entry.canonicalName == "Vitamin B9")
        #expect(entry.amount == 200)
        #expect(entry.unit == .mcg)
    }

    @Test func preservesAliasFormWhenVariantNamesParentNutrientForm() throws {
        let parser = try ParserService.makeDefault()
        let result = parser.parse("""
            P-5-P 10mg
            Cholecalciferol 25mcg
            """)

        let nutrients = nutrientEntries(in: result)

        let vitaminB6 = try #require(nutrients.first { $0.canonicalName == "Vitamin B6" })
        #expect(vitaminB6.displayName == "P-5-P")
        #expect(vitaminB6.form == "p-5-p")
        #expect(vitaminB6.amount == 10)
        #expect(vitaminB6.unit == .mg)

        let vitaminD = try #require(nutrients.first { $0.canonicalName == "Vitamin D" })
        #expect(vitaminD.displayName == "Cholecalciferol")
        #expect(vitaminD.form == "cholecalciferol")
        #expect(vitaminD.amount == 25)
        #expect(vitaminD.unit == .mcg)
    }

    @Test func flagsImplausibleCompendiumUnitsForReview() throws {
        let parser = try ParserService.makeDefault()
        let result = parser.parse("""
            Vitamin B12 500mg
            Selenium 200mg
            Magnesium 400mcg
            """)

        let nutrients = nutrientEntries(in: result)

        let b12 = try #require(nutrients.first { $0.canonicalName == "Vitamin B12" })
        #expect(b12.reviewFlags.contains(.unitImplausible))

        let selenium = try #require(nutrients.first { $0.canonicalName == "Selenium" })
        #expect(selenium.reviewFlags.contains(.unitImplausible))

        let magnesium = try #require(nutrients.first { $0.canonicalName == "Magnesium" })
        #expect(magnesium.reviewFlags.contains(.unitImplausible))
    }

    @Test func treatsCitrusBioflavonoidsExtractAsNutrientLikeAliasNotHerbal() throws {
        let parser = ParserService(aliasesByVariant: [
            "Citrus Bioflavonoids": "Citrus Bioflavonoids",
            "Citrus Bioflavonoids Extract": "Citrus Bioflavonoids"
        ])
        let result = parser.parse("Citrus bioflavonoids extract 50mg")

        #expect(result.entries.contains { entry in
            if case .herbal = entry { return true }
            return false
        } == false)

        guard case .nutrient(let entry)? = result.entries.first else {
            Issue.record("Expected nutrient-like alias entry")
            return
        }

        #expect(entry.canonicalName == "Citrus Bioflavonoids")
        #expect(entry.amount == 50)
        #expect(entry.unit == .mg)
    }

    @Test func keepsUnparseableLinesForManualReview() {
        let parser = ParserService()
        let result = parser.parse("Clinically researched formula")

        guard case .unresolved(let line)? = result.entries.first else {
            Issue.record("Expected unresolved raw line")
            return
        }

        #expect(line.text == "Clinically researched formula")
        #expect(line.lineNumber == 1)
    }

    @Test func parsesServingSize() {
        let parser = ParserService()
        let result = parser.parse("Amount per serving 2 capsules")

        #expect(result.extractedServing?.quantity == 2)
        #expect(result.extractedServing?.unit == .capsule)
        #expect(result.entries.isEmpty)
    }

    @Test func parsesVitaminCLabelWithoutDirectionsOrCompoundDoubleCountRows() throws {
        let parser = ParserService(aliasesByVariant: [
            "Ascorbic Acid": "Vitamin C",
            "Vitamin C": "Vitamin C",
            "Zinc": "Zinc"
        ])
        let result = parser.parse("""
            Directions for use:
            Adults And Children Over
            12 years - Take 1 tablet, one to three times a day, with food
            Each tablet contains:
            Calcium ascorbate dihydrate
            605.3mg
            equiv. Ascorbic Acid as vitamin C
            500 mg
            Sodium ascorbate
            562.4mg
            equiv. Ascorbic Acid (VITAMIN C)
            500mg
            TOTAL ASCORBIC ACID (VITAMIN C) 1g
            Citrus Bioflavonoids Extract.
            50mg
            Zinc amino acid chelate equiv. Zinc
            5mg
            """)

        let nutrients = nutrientEntries(in: result)
        #expect(nutrients.contains { $0.displayName == "Adults And Children Over" } == false)
        #expect(nutrients.contains { $0.displayName == "Tablet" } == false)

        let vitaminCEntries = nutrients.filter { $0.canonicalName == "Vitamin C" }
        #expect(vitaminCEntries.count == 3)
        #expect(vitaminCEntries.contains { $0.amount == 500 && $0.compoundAmount == 605.3 })
        #expect(vitaminCEntries.contains { $0.amount == 500 && $0.compoundAmount == 562.4 })

        let totalVitaminC = try #require(vitaminCEntries.first { $0.isTotalLine })
        #expect(totalVitaminC.amount == 1)
        #expect(totalVitaminC.unit == .g)
        #expect(totalVitaminC.reviewFlags.contains(.totalLineAmbiguous))

        let zinc = try #require(nutrients.first { $0.canonicalName == "Zinc" })
        #expect(zinc.amount == 5)
        #expect(zinc.unit == .mg)
        #expect(zinc.form == "amino acid chelate")
    }

    @Test func parsesMagnesiumPowderCompoundElementalRows() throws {
        let parser = ParserService(aliasesByVariant: [
            "Magnesium": "Magnesium",
            "Zinc": "Zinc"
        ])
        let result = parser.parse("""
            Level Metric Teaspoon (
            5 g
            Taurine
            1,000 mg
            Magnesium Amino Acid Chelate
            1,750 mg
            (providing Magnesium
            350 mg
            Magnesium Ascorbate
            210 mg
            (providing Magnesium
            13 mg
            Magnesium Glycinate Dihydrate
            104 mg
            (providing Magnesium
            12.2 mg
            TOTAL ELEMENTAL MAGNESIUM
            400mg
            Zinc (as amino acid chelate)
            5mg
            """)

        #expect(result.extractedServing?.quantity == 5)
        #expect(result.extractedServing?.unit == .gram)

        let nutrients = nutrientEntries(in: result)
        #expect(nutrients.contains { $0.displayName == "Level Metric Teaspoon" } == false)
        #expect(nutrients.contains { $0.displayName == "Providing Magnesium" } == false)

        let taurine = try #require(nutrients.first { $0.canonicalName == "Taurine" })
        #expect(taurine.amount == 1000)

        let magnesiumForms = nutrients.filter { $0.canonicalName == "Magnesium" && !$0.isTotalLine }
        #expect(magnesiumForms.count == 3)
        #expect(magnesiumForms.contains { $0.form == "amino acid chelate" && $0.amount == 350 && $0.compoundAmount == 1750 })
        #expect(magnesiumForms.contains { $0.form == "ascorbate" && $0.amount == 13 && $0.compoundAmount == 210 })
        #expect(magnesiumForms.contains { $0.form == "glycinate dihydrate" && $0.amount == 12.2 && $0.compoundAmount == 104 })

        let totalMagnesium = try #require(nutrients.first { $0.canonicalName == "Magnesium" && $0.isTotalLine })
        #expect(totalMagnesium.amount == 400)
        #expect(totalMagnesium.unit == .mg)

        let zinc = try #require(nutrients.first { $0.canonicalName == "Zinc" })
        #expect(zinc.amount == 5)
        #expect(zinc.form == "amino acid chelate")
    }

    @Test func mergesContinuationWhenCompoundAndElementalRowsPreMerged() throws {
        // When OCR delivers both amounts on the same line (already merged into the row),
        // mergedContinuationLines must still absorb the "(providing..." row into the
        // compound entry — preserving the 350 mg elemental dose, not discarding it.
        let parser = ParserService(aliasesByVariant: ["Magnesium": "Magnesium"])
        let result = parser.parse("""
            Magnesium Amino Acid Chelate 1750 mg
            (providing Magnesium 350 mg
            """)

        let nutrients = nutrientEntries(in: result)
        // The "(providing" row must not escape as a standalone nutrient.
        #expect(nutrients.contains { $0.displayName.hasPrefix("(") } == false)
        #expect(nutrients.contains { $0.displayName.lowercased().contains("providing") } == false)
        // The elemental dose (350 mg) must survive in the compound entry.
        let magnesium = try #require(nutrients.first { $0.canonicalName == "Magnesium" })
        #expect(magnesium.amount == 350)
        #expect(magnesium.compoundAmount == 1750)
    }

    @Test func rejectsCompanyAddressRows() {
        let parser = ParserService()
        let result = parser.parse("""
            Health Direction Pty Ltd 5/
            Vitamin C 500 mg
            """)

        let nutrients = nutrientEntries(in: result)
        #expect(nutrients.contains { $0.displayName.lowercased().contains("pty") } == false)
        #expect(nutrients.count == 1)
    }

    @Test func parsesRealOCRMagnesiumLabelFourForms() throws {
        // Exact rawText from debug bundle FC1673B2 / E00BA1B6 — two real iPhone scans.
        // Vision OCR emits compound names and their (providing...) rows as separate observations.
        // Phosphate pentahydrate is a fourth form not in the simplified test above.
        // "f elemental magnesium 400mg" is an OCR artifact of "TOTAL ELEMENTAL MAGNESIUM 400mg"
        // and must be rejected (no phantom 400mg Magnesium entry in the report).
        let parser = ParserService(aliasesByVariant: [
            "Magnesium": "Magnesium",
            "Taurine": "Taurine",
            "Zinc": "Zinc"
        ])
        let rawText = """
            Each level metric teaspoon (5g dose) contains:
            Taurine 1000mg
            Magnesium amino acid chelate
            (providing elemental magnesium 350mg) 1750mg
            Magnesium ascorbate
            (providing elemental magnesium 13mg) 210mg
            (providing elemental magnesium 12.2mg) Magnesium glycinate dihydrate 104mg
            Magnesium phosphate pentahydrate
            (providing elemental magnesium 24.8mg) 120mg
            elemice
            manee
            f elemental magnesium 400mg
            Zinc (as amino acid chelate) 5mg
            Rso contains malic acid, acacia, stevia, natural lemon flavour and
            yeast, artificial colours or flavours. Contains sulfites and galactose.
            Health Direction Pty Ltd
            """
        let result = parser.parse(rawText)

        #expect(result.extractedServing?.quantity == 5)
        #expect(result.extractedServing?.unit == .gram)

        let nutrients = nutrientEntries(in: result)

        let taurine = try #require(nutrients.first { $0.canonicalName == "Taurine" })
        #expect(taurine.amount == 1000)

        // Four elemental forms — each with compound amount preserved
        let magForms = nutrients.filter { $0.canonicalName == "Magnesium" && !$0.isTotalLine }
        #expect(magForms.count == 4)
        #expect(magForms.contains { $0.form == "amino acid chelate" && $0.amount == 350 && $0.compoundAmount == 1750 })
        #expect(magForms.contains { $0.form == "ascorbate" && $0.amount == 13 && $0.compoundAmount == 210 })
        #expect(magForms.contains { $0.form == "glycinate dihydrate" && $0.amount == 12.2 && $0.compoundAmount == 104 })
        #expect(magForms.contains { $0.form == "phosphate pentahydrate" && $0.amount == 24.8 && $0.compoundAmount == 120 })

        // OCR artifact "f elemental magnesium 400mg" must be rejected — no phantom total
        #expect(nutrients.filter { $0.canonicalName == "Magnesium" && $0.isTotalLine }.isEmpty)
        #expect(nutrients.contains { $0.displayName.lowercased().hasPrefix("f ") } == false)

        let zinc = try #require(nutrients.first { $0.canonicalName == "Zinc" })
        #expect(zinc.amount == 5)
        #expect(zinc.form == "amino acid chelate")
    }

    @Test func parsesProbioticStrainRowsAsProbioticEntries() throws {
        let parser = ParserService()
        let result = parser.parse("""
            Each capsule contains:
            Bifidobacterium lactis BL-04 32 billion CFU
            Lactobacillus rhamnosus GG 6 billion CFU
            Lactobacillus brevis Lbr-35 250 million CFU
            Contains sulfites.
            """)

        let probiotics = probioticEntries(in: result)
        #expect(probiotics.count == 3)

        let lactis = try #require(probiotics.first { $0.genus == "Bifidobacterium" && $0.species == "lactis" })
        #expect(lactis.strain == "BL-04")
        #expect(lactis.cfuBillions == 32)

        let rhamnosus = try #require(probiotics.first { $0.genus == "Lactobacillus" && $0.species == "rhamnosus" })
        #expect(rhamnosus.strain == "GG")
        #expect(rhamnosus.cfuBillions == 6)

        let brevis = try #require(probiotics.first { $0.genus == "Lactobacillus" && $0.species == "brevis" })
        #expect(brevis.strain == "Lbr-35")
        #expect(brevis.cfuBillions == 0.25)
    }
}

private func nutrientEntries(in result: ParseResult) -> [NutrientEntry] {
    result.entries.compactMap { entry in
        if case .nutrient(let nutrient) = entry { return nutrient }
        return nil
    }
}

private func probioticEntries(in result: ParseResult) -> [ProbioticEntry] {
    result.entries.compactMap { entry in
        if case .probiotic(let probiotic) = entry { return probiotic }
        return nil
    }
}
