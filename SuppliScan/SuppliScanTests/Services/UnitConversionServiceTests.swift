// UnitConversionServiceTests.swift
// SuppliScanTests

import Testing
@testable import SuppliScan

struct UnitConversionServiceTests {
    @Test func convertsVitaminDInternationalUnitsToMicrograms() {
        let converted = UnitConversionService.convertIfNeeded(
            entry(canonicalName: "Vitamin D", displayName: "Vitamin D3", amount: 1000, unit: .iu)
        )

        #expect(converted.amount == 25)
        #expect(converted.unit == .mcg)
        #expect(converted.reviewFlags.contains(.iuConversionInvalid) == false)
    }

    @Test func convertsNaturalVitaminEInternationalUnitsToMilligrams() {
        let converted = UnitConversionService.convertIfNeeded(
            entry(
                canonicalName: "Vitamin E",
                displayName: "Vitamin E",
                form: "d-alpha-tocopherol",
                amount: 100,
                unit: .iu
            )
        )

        #expect(converted.amount == 67)
        #expect(converted.unit == .mg)
        #expect(converted.reviewFlags.contains(.iuConversionAssumed) == false)
    }

    @Test func convertsSyntheticVitaminEInternationalUnitsToMilligrams() {
        let converted = UnitConversionService.convertIfNeeded(
            entry(
                canonicalName: "Vitamin E",
                displayName: "Vitamin E",
                form: "dl-alpha-tocopherol",
                amount: 100,
                unit: .iu
            )
        )

        #expect(converted.amount == 45)
        #expect(converted.unit == .mg)
        #expect(converted.reviewFlags.contains(.iuConversionAssumed) == false)
    }

    @Test func assumesSyntheticVitaminEWhenFormIsAmbiguous() {
        let converted = UnitConversionService.convertIfNeeded(
            entry(canonicalName: "Vitamin E", displayName: "Vitamin E", amount: 100, unit: .iu)
        )

        #expect(converted.amount == 45)
        #expect(converted.unit == .mg)
        #expect(converted.reviewFlags.contains(.iuConversionAssumed))
    }

    @Test func convertsRetinolVitaminAInternationalUnitsToMicrograms() {
        let converted = UnitConversionService.convertIfNeeded(
            entry(
                canonicalName: "Vitamin A",
                displayName: "Vitamin A",
                form: "retinol",
                amount: 1000,
                unit: .iu
            )
        )

        #expect(converted.amount == 300)
        #expect(converted.unit == .mcg)
    }

    @Test func flagsInvalidInternationalUnitsWithoutConverting() {
        let converted = UnitConversionService.convertIfNeeded(
            entry(canonicalName: "Iron", displayName: "Iron", amount: 10, unit: .iu)
        )

        #expect(converted.amount == 10)
        #expect(converted.unit == .iu)
        #expect(converted.reviewFlags.contains(.iuConversionInvalid))
    }

    private func entry(
        canonicalName: String,
        displayName: String,
        form: String? = nil,
        amount: Double?,
        unit: NutrientUnit
    ) -> NutrientEntry {
        NutrientEntry(
            canonicalName: canonicalName,
            displayName: displayName,
            form: form,
            amount: amount,
            unit: unit
        )
    }
}
