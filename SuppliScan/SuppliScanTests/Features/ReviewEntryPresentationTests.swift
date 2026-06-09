// ReviewEntryPresentationTests.swift
// SuppliScanTests

import Testing
@testable import SuppliScan

struct ReviewEntryPresentationTests {
    @Test func servingUnitsDoNotInventPluralAbbreviations() {
        #expect(ServingUnit.gram.pluralised(for: 5) == "g")
        #expect(ServingUnit.ml.pluralised(for: 5) == "ml")
        #expect(ServingUnit.capsule.pluralised(for: 2) == "capsules")
        #expect(ServingUnit.capsule.pluralised(for: 1) == "capsule")
    }

    @Test func nutrientMissingAmountRequiresReview() {
        let entry = LabelEntry.nutrient(NutrientEntry(
            canonicalName: "Magnesium",
            displayName: "Magnesium",
            amount: nil,
            unit: .mg
        ))

        #expect(ReviewEntryClassifier.status(for: entry) == .needsReview)
    }

    @Test func marketingTextIsIgnoredByAnalysis() {
        let entry = LabelEntry.unresolved(RawLine(
            text: "Supports healthy muscles and nervous system function",
            lineNumber: 1
        ))

        #expect(ReviewEntryClassifier.status(for: entry) == .otherLabelText)
    }

    @Test func unresolvedDoseTextStillRequiresReview() {
        let entry = LabelEntry.unresolved(RawLine(
            text: "Magnesium 150 mg",
            lineNumber: 1
        ))

        #expect(ReviewEntryClassifier.status(for: entry) == .needsReview)
    }

    @Test func confirmedEntryClearsReviewFlagsAndMarksManualEdit() throws {
        let entry = LabelEntry.nutrient(NutrientEntry(
            canonicalName: "Vitamin E",
            displayName: "Vitamin E",
            amount: 15,
            unit: .mg,
            reviewFlags: [.iuConversionAssumed]
        ))

        let confirmed = ReviewEntryClassifier.confirmed(entry)
        guard case .nutrient(let nutrient) = confirmed else {
            Issue.record("Expected nutrient entry")
            return
        }

        #expect(nutrient.reviewFlags.isEmpty)
        #expect(nutrient.isManuallyEdited)
    }

    @Test func reviewReasonsDoNotExposeParserVocabulary() throws {
        let entry = LabelEntry.nutrient(NutrientEntry(
            canonicalName: "Magnesium",
            displayName: "Magnesium",
            amount: 350,
            unit: .mg,
            reviewFlags: [.extractEquivalent, .canonicalNameInferred]
        ))

        let presentation = try #require(ReviewEntryClassifier.presentations(for: [entry]).first)
        let reasons = presentation.reviewReasons.joined(separator: " ").lowercased()

        #expect(!reasons.contains("alias"))
        #expect(!reasons.contains("parser"))
        #expect(!reasons.contains("canonical"))
        #expect(!reasons.contains("equivalent"))
        #expect(!reasons.contains("inferred"))
    }
}
