// CalculationServiceTests.swift
// SuppliScanTests

import Testing
@testable import SuppliScan

struct CalculationServiceTests {
    @Test func appliesServingMultiplierExactlyOnce() throws {
        let entry = NutrientEntry(
            canonicalName: "Magnesium",
            displayName: "Magnesium",
            amount: 100,
            unit: .mg
        )
        let reference = NRVEntry(
            rdi: RDIReference(
                standard: .au,
                demographic: Demographic.defaultAdult.key,
                value: 400,
                unit: .mg,
                referenceType: .rdi,
                source: "Test"
            ),
            ul: ULReference(
                standard: .au,
                demographic: Demographic.defaultAdult.key,
                value: 350,
                unit: .mg,
                note: nil,
                source: "Test"
            )
        )

        let analysis = try CalculationService.analysis(
            for: entry,
            reference: reference,
            servingSize: ServingSize(quantity: 1, unit: .capsule, selectedQuantity: 2)
        )

        #expect(analysis.effectiveDose == 200)
        #expect(analysis.rdiPercent == 50)
        let expectedULPercent = 200.0 / 350.0 * 100.0
        let actualULPercent = try #require(analysis.ulPercent)
        #expect(abs(actualULPercent - expectedULPercent) < 0.000001)
        #expect(analysis.entry.servingMultiplier == 2)
        #expect(analysis.entry.reviewFlags.contains(.servingMultiplied))
    }

    @Test func throwsWhenInternationalUnitsReachCalculation() {
        let entry = NutrientEntry(
            canonicalName: "Vitamin D",
            displayName: "Vitamin D",
            amount: 1000,
            unit: .iu
        )

        #expect(throws: AppError.self) {
            _ = try CalculationService.analysis(
                for: entry,
                reference: nil,
                servingSize: ServingSize(quantity: 1, unit: .capsule)
            )
        }
    }

    @Test func preservesNilWhenReferenceDataIsMissing() throws {
        let entry = NutrientEntry(
            canonicalName: "Coenzyme Q10",
            displayName: "CoQ10",
            amount: 100,
            unit: .mg
        )

        let analysis = try CalculationService.analysis(
            for: entry,
            reference: nil,
            servingSize: ServingSize(quantity: 1, unit: .capsule)
        )

        #expect(analysis.rdiPercent == nil)
        #expect(analysis.ulPercent == nil)
        #expect(analysis.effectiveDose == 100)
    }
}
