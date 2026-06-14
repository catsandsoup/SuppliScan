// LabelReconstructionCorpusTests.swift
// SuppliScanTests

import Foundation
import Testing
@testable import SuppliScan

struct LabelReconstructionCorpusTests {

    @Test func trainingFixturesReconstructExpectedFacts() throws {
        let parser = try ParserService.makeDefault()
        let fixtures = try TrainingCorpus.loadFixtures()

        #expect(fixtures.count >= 6)

        for fixture in fixtures {
            let expectedFacts = fixture.expectedFacts
            let benchmark = LabelReconstructionBenchmark(
                name: fixture.name,
                expectedEntries: expectedFacts
            )
            let result = parser.parse(fixture.reconstructionInput)
            let score = LabelReconstructionEvaluator().evaluate(result, against: benchmark)

            #expect(expectedFacts.isEmpty == false, "\(fixture.fileName) must define expected reconstruction facts.")
            #expect(score.missing.isEmpty, "\(fixture.fileName) missing: \(score.missing)")
            #expect(score.unexpected.isEmpty, "\(fixture.fileName) unexpected: \(score.unexpected)")
            #expect(score.unresolvedLineCount == 0, "\(fixture.fileName) unresolved lines: \(fixture.reconstructionInput)")
            #expect(score.recall == 1, "\(fixture.fileName) recall: \(score.recall)")
            #expect(score.precision == 1, "\(fixture.fileName) precision: \(score.precision)")
        }
    }

    @Test func seleniumKeyLinesPreserveSeparatedFormQualifier() throws {
        let parser = try ParserService.makeDefault()
        let fixture = try TrainingCorpus.loadFixture(named: "selenium_150mcg_au.json")
        let rawText = try #require(fixture.keyLinesText)

        let result = parser.parse(rawText)
        let benchmark = LabelReconstructionBenchmark(
            name: fixture.name,
            expectedEntries: fixture.expectedFacts
        )
        let score = LabelReconstructionEvaluator().evaluate(result, against: benchmark)

        #expect(score.missing.isEmpty, "Separated Selenium form qualifier was lost: \(score.missing)")
        #expect(score.unresolvedLineCount == 0)
    }

    @Test func hairVolumeActualOCRRowsReconstructExpectedFacts() throws {
        let parser = try ParserService.makeDefault()
        let fixture = try TrainingCorpus.loadFixture(named: "hair_volume_new_nordic_au.json")
        let rawText = """
            EACH TABLET CONTAINS
            Dry fruit extract 300 mg equivalent to dry fruit 1500 mg
            Malus domestica (apple)
            Dried seed extract 250 mg equivalent to dry seed 1250 mg
            Panicum miliaceum (millet)
            Equisetum arvense (horsetail)
            (standardised to contain silicon 14 mg)
            Dried stem extract 200 mg equivalent to dry stem 1000 mg
            Methionine Cysteine 50 mg
            60 mg
            Calcium Pantothenate
            Zinc oxide
            Equivalent to pantothenate 30 mg
            32,6 mg
            Equivalent to zinc 10 mg 12,5 mg
            Cupric sulfate monohydrate
            Biotin
            0,48 mg
            Equivalent to copper 1 mg 4 mg
            1300 25 44 03
            """
        let result = parser.parse(rawText)
        let benchmark = LabelReconstructionBenchmark(
            name: fixture.name,
            expectedEntries: fixture.expectedFacts
        )
        let score = LabelReconstructionEvaluator().evaluate(result, against: benchmark)
        let diagnostics = """
        Observed: \(result.entries)
        Decisions: \(parser.debugDecisions(for: rawText))
        """

        #expect(score.missing.isEmpty, "Actual OCR rows missing: \(score.missing)\n\(diagnostics)")
        #expect(score.unexpected.isEmpty, "Actual OCR rows unexpected: \(score.unexpected)\n\(diagnostics)")
        #expect(score.unresolvedLineCount == 0, "Actual OCR rows left unresolved.\n\(diagnostics)")
        #expect(score.recall == 1)
        #expect(score.precision == 1)
    }
}

private enum TrainingCorpus {
    static func loadFixtures() throws -> [LoadedTrainingFixture] {
        try fixtureURLs().map(loadFixture(at:))
    }

    static func loadFixture(named fileName: String) throws -> LoadedTrainingFixture {
        try loadFixture(at: corpusRoot.appending(path: fileName))
    }

    private static func loadFixture(at url: URL) throws -> LoadedTrainingFixture {
        let data = try Data(contentsOf: url)
        let fixture = try JSONDecoder().decode(TrainingLabelFixture.self, from: data)
        return LoadedTrainingFixture(fileName: url.lastPathComponent, fixture: fixture)
    }

    private static func fixtureURLs() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: corpusRoot,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static var corpusRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "TrainingData")
    }
}

private struct LoadedTrainingFixture: Sendable {
    let fileName: String
    let fixture: TrainingLabelFixture

    var name: String {
        fixture.productName
    }

    var expectedFacts: [ReconstructedFact] {
        fixture.expectedFacts
    }

    var reconstructionInput: String {
        fixture.reconstructionRows.joined(separator: "\n")
    }

    var keyLinesText: String? {
        guard fixture.labelTextKeyLines.isEmpty == false else { return nil }
        return fixture.labelTextKeyLines.joined(separator: "\n")
    }
}

private struct TrainingLabelFixture: Decodable, Sendable {
    let productName: String
    let expectedEntries: [ExpectedNutrientRow]
    let expectedEntriesPerServing: [ExpectedNutrientRow]
    let expectedNutrientEntries: [ExpectedNutrientRow]
    let expectedHerbalEntries: [ExpectedHerbalRow]
    let strainsPresent: [ExpectedProbioticStrain]
    let totalCFUBillions: Double?
    let labelTextKeyLines: [String]

    var expectedFacts: [ReconstructedFact] {
        let nutrients = allNutrientRows.compactMap(\.fact)
        let herbs = expectedHerbalEntries.compactMap(\.fact)
        let totalProbioticFacts = totalCFUBillions.map {
            ReconstructedFact(
                kind: .probiotic,
                name: "Total probiotics",
                amount: $0,
                unit: "billion CFU",
                marker: "total"
            )
        }.map { [$0] } ?? []
        let strains = strainsPresent.map(\.fact)
        return nutrients + herbs + totalProbioticFacts + strains
    }

    var reconstructionRows: [String] {
        var rows = allNutrientRows.compactMap(\.reconstructionLine)
        rows.append(contentsOf: expectedHerbalEntries.compactMap(\.reconstructionLine))
        if let totalCFUBillions {
            rows.append("Total probiotics \(amountText(totalCFUBillions)) billion CFU")
        }
        rows.append(contentsOf: strainsPresent.map(\.reconstructionLine))
        return rows
    }

    private var allNutrientRows: [ExpectedNutrientRow] {
        expectedEntries + expectedEntriesPerServing + expectedNutrientEntries
    }

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case expectedEntries = "expected_entries"
        case expectedEntriesPerServing = "expected_entries_per_serving"
        case expectedNutrientEntries = "expected_nutrient_entries"
        case expectedHerbalEntries = "expected_herbal_entries"
        case strainsPresent = "strains_present"
        case totalCFUBillions = "total_cfu_billions"
        case labelTextKeyLines = "label_text_key_lines"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productName = try container.decodeIfPresent(String.self, forKey: .productName) ?? "Unnamed label"
        expectedEntries = try container.decodeIfPresent([ExpectedNutrientRow].self, forKey: .expectedEntries) ?? []
        expectedEntriesPerServing = try container.decodeIfPresent([ExpectedNutrientRow].self, forKey: .expectedEntriesPerServing) ?? []
        expectedNutrientEntries = try container.decodeIfPresent([ExpectedNutrientRow].self, forKey: .expectedNutrientEntries) ?? []
        expectedHerbalEntries = try container.decodeIfPresent([ExpectedHerbalRow].self, forKey: .expectedHerbalEntries) ?? []
        strainsPresent = try container.decodeIfPresent([ExpectedProbioticStrain].self, forKey: .strainsPresent) ?? []
        totalCFUBillions = try container.decodeIfPresent(Double.self, forKey: .totalCFUBillions)
        labelTextKeyLines = try container.decodeIfPresent([String].self, forKey: .labelTextKeyLines) ?? []
    }
}

private struct ExpectedNutrientRow: Decodable, Sendable {
    let name: String
    let canonicalName: String
    let form: String?
    let amount: Double?
    let amountMcg: Double?
    let unit: String?
    let compoundAmount: Double?
    let compoundUnit: String?
    let elementalAmount: Double?
    let elementalUnit: String?
    let decimalCommaOnLabel: Bool

    var fact: ReconstructedFact? {
        guard let amount = primaryAmount, let unit = primaryUnit else { return nil }
        return ReconstructedFact(
            kind: .nutrient,
            name: canonicalName,
            amount: amount,
            unit: unit,
            form: form,
            secondaryAmount: compoundAmount,
            secondaryUnit: compoundUnit
        )
    }

    var reconstructionLine: String? {
        guard let amount = primaryAmount, let unit = primaryUnit else { return nil }
        let activeAmount = amountText(amount, decimalComma: decimalCommaOnLabel)

        if let compoundAmount, let compoundUnit {
            return "\(compoundLabelName) \(amountText(compoundAmount, decimalComma: decimalCommaOnLabel))\(compoundUnit) equivalent to \(canonicalName) \(activeAmount)\(unit)"
        }

        if let form {
            return "\(canonicalName) (as \(form)) \(activeAmount)\(unit)"
        }

        return "\(canonicalName) \(activeAmount)\(unit)"
    }

    private var primaryAmount: Double? {
        amount ?? elementalAmount ?? amountMcg
    }

    private var primaryUnit: String? {
        unit ?? elementalUnit ?? (amountMcg == nil ? nil : "mcg")
    }

    private var compoundLabelName: String {
        guard let form else { return name }
        let nameKey = normalizedKey(name)
        let formKey = normalizedKey(form)
        if nameKey.contains(formKey) {
            return name
        }
        return "\(canonicalName) \(form)"
    }

    enum CodingKeys: String, CodingKey {
        case name
        case canonicalName = "canonical_name"
        case form
        case amount
        case amountMcg = "amount_mcg"
        case unit
        case compoundAmount = "compound_amount"
        case compoundUnit = "compound_unit"
        case elementalAmount = "elemental_amount"
        case elementalUnit = "elemental_unit"
        case decimalCommaOnLabel = "decimal_comma_on_label"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        canonicalName = try container.decodeIfPresent(String.self, forKey: .canonicalName) ?? name
        form = try container.decodeIfPresent(String.self, forKey: .form)
        amount = try container.decodeIfPresent(Double.self, forKey: .amount)
        amountMcg = try container.decodeIfPresent(Double.self, forKey: .amountMcg)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        compoundAmount = try container.decodeIfPresent(Double.self, forKey: .compoundAmount)
        compoundUnit = try container.decodeIfPresent(String.self, forKey: .compoundUnit)
        elementalAmount = try container.decodeIfPresent(Double.self, forKey: .elementalAmount)
        elementalUnit = try container.decodeIfPresent(String.self, forKey: .elementalUnit)
        decimalCommaOnLabel = try container.decodeIfPresent(Bool.self, forKey: .decimalCommaOnLabel) ?? false
    }
}

private struct ExpectedHerbalRow: Decodable, Sendable {
    let name: String
    let commonName: String?
    let form: String?
    let extractAmount: Double?
    let extractUnit: String?
    let dryEquivalentAmount: Double?
    let dryEquivalentUnit: String?
    let standardisation: ExpectedStandardisation?

    var fact: ReconstructedFact? {
        guard let extractAmount, let extractUnit else { return nil }
        return ReconstructedFact(
            kind: .herbal,
            name: name,
            amount: extractAmount,
            unit: extractUnit,
            form: extractType.rawValue,
            secondaryAmount: standardisation?.amount ?? dryEquivalentAmount,
            secondaryUnit: standardisation?.unit ?? dryEquivalentUnit,
            marker: standardisation?.compound
        )
    }

    var reconstructionLine: String? {
        guard let extractAmount, let extractUnit else { return nil }
        var row = name
        if let commonName {
            row += " (\(commonName))"
        }
        row += " \(form ?? "extract") \(amountText(extractAmount))\(extractUnit)"

        if let dryEquivalentAmount, let dryEquivalentUnit {
            row += " equivalent to dry herb \(amountText(dryEquivalentAmount))\(dryEquivalentUnit)"
        }
        if let standardisation {
            row += " standardised to contain \(standardisation.compound) \(amountText(standardisation.amount))\(standardisation.unit)"
        }
        return row
    }

    private var extractType: ExtractType {
        let lower = (form ?? "").lowercased()
        if lower.contains("soft") {
            return .softConcentrate
        }
        if lower.contains("dried herb") || lower.contains("powder") {
            return .driedHerb
        }
        if lower.contains("extract") || lower.contains("concentrate") {
            return .dryConcExtract
        }
        return .unknown
    }

    enum CodingKeys: String, CodingKey {
        case name
        case commonName = "common_name"
        case form
        case extractAmount = "extract_amount"
        case extractUnit = "extract_unit"
        case dryEquivalentAmount = "dry_equivalent_amount"
        case dryEquivalentUnit = "dry_equivalent_unit"
        case standardisation
    }
}

private struct ExpectedStandardisation: Decodable, Sendable {
    let compound: String
    let amount: Double
    let unit: String
}

private struct ExpectedProbioticStrain: Decodable, Sendable {
    let genus: String
    let species: String
    let strain: String?
    let cfuBillions: Double

    var fact: ReconstructedFact {
        ReconstructedFact(
            kind: .probiotic,
            name: "\(genus) \(species)",
            amount: cfuBillions,
            unit: "billion CFU",
            form: strain
        )
    }

    var reconstructionLine: String {
        [
            genus,
            species,
            strain,
            amountText(cfuBillions),
            "billion CFU",
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }

    enum CodingKeys: String, CodingKey {
        case genus
        case species
        case strain
        case cfuBillions = "cfu_billions"
    }
}

private func amountText(_ amount: Double, decimalComma: Bool = false) -> String {
    var text = String(amount)
    if text.hasSuffix(".0") {
        text.removeLast(2)
    }
    return decimalComma ? text.replacingOccurrences(of: ".", with: ",") : text
}

private func normalizedKey(_ value: String) -> String {
    value
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        .lowercased()
        .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
