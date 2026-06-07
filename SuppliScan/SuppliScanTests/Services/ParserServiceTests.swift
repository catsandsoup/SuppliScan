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
}
