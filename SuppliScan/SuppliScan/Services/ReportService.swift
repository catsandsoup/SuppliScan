// ReportService.swift
// SuppliScan
//
// Orchestrates the full analysis pipeline for a parsed label.
// Entry point: generateReport(). Handles all four LabelEntry cases.
//
// Rules (from CLAUDE.md — never violate):
// - disclaimer set on every report
// - schemaVersion set on every report
// - isAIInferred never set here — only AIService may set it true
// - ServingMultiplier applied exactly once inside CalculationService
// - CalculationService receives no .iu values — UnitConversionService runs first

import Foundation
import OSLog

actor ReportService {
    private let referenceDataService: ReferenceDataService
    private let formQualityService: FormQualityService
    private let interactionService: InteractionService

    init(
        referenceDataService: ReferenceDataService,
        formQualityService: FormQualityService,
        interactionService: InteractionService
    ) {
        self.referenceDataService = referenceDataService
        self.formQualityService = formQualityService
        self.interactionService = interactionService
    }

    func generateReport(
        entries: [LabelEntry],
        servingSize: ServingSize,
        productName: String?,
        standard: ReferenceStandard,
        demographic: Demographic
    ) async throws -> LabelAnalysis {
        var nutrientAnalyses: [NutrientAnalysis] = []
        var herbalEntries: [HerbalEntry] = []
        var probioticEntries: [ProbioticEntry] = []
        var unresolvedLines: [RawLine] = []

        let reportEntries = calculationEntries(from: entries)

        for entry in reportEntries {
            switch entry {
            case .nutrient(let raw):
                let analysis = await analyseNutrient(
                    raw,
                    servingSize: servingSize,
                    standard: standard,
                    demographic: demographic
                )
                nutrientAnalyses.append(analysis)

            case .herbal(let herbal):
                herbalEntries.append(herbal)

            case .probiotic(let probiotic):
                probioticEntries.append(probiotic)

            case .unresolved(let line):
                unresolvedLines.append(line)
            }
        }

        let interactableNames = nutrientAnalyses
            .map(\.entry.canonicalName)

        let interactions = await interactionService.interactions(for: interactableNames)
        let medicationInteractions = await interactionService.medicationInteractions(for: interactableNames)

        let flags = buildFlags(
            nutrientAnalyses: nutrientAnalyses,
            unresolvedLines: unresolvedLines,
            servingSize: servingSize,
            interactions: interactions,
            medicationInteractions: medicationInteractions
        )

        return LabelAnalysis(
            id: UUID(),
            productName: productName ?? "",
            referenceStandard: standard,
            demographic: demographic,
            servingSize: servingSize,
            nutrientAnalyses: nutrientAnalyses,
            herbalEntries: herbalEntries,
            probioticEntries: probioticEntries,
            unresolvedLines: unresolvedLines,
            flags: flags,
            disclaimer: LabelAnalysis.disclaimer,
            schemaVersion: LabelAnalysis.currentSchemaVersion,
            createdAt: Date()
        )
    }

    // MARK: - Private

    private func calculationEntries(from entries: [LabelEntry]) -> [LabelEntry] {
        let nutrientEntries = entries.compactMap { entry -> NutrientEntry? in
            if case .nutrient(let nutrient) = entry { return nutrient }
            return nil
        }

        let nutrientsWithTotals = Set(
            nutrientEntries
                .filter(\.isTotalLine)
                .map { normalizedKey($0.canonicalName) }
        )

        return entries.filter { entry in
            guard case .nutrient(let nutrient) = entry else { return true }
            if nutrientsWithTotals.contains(normalizedKey(nutrient.canonicalName)) {
                return nutrient.isTotalLine
            }
            return true
        }
    }

    private func analyseNutrient(
        _ entry: NutrientEntry,
        servingSize: ServingSize,
        standard: ReferenceStandard,
        demographic: Demographic
    ) async -> NutrientAnalysis {
        // Convert IU → calculable unit before reaching CalculationService.
        let converted = UnitConversionService.convertIfNeeded(entry)

        // Reference data lookup.
        let nrvEntry = await referenceDataService.nrvEntry(
            for: converted.canonicalName,
            standard: standard,
            demographic: demographic
        )

        // Form quality lookup using form string or display name as fallback.
        let formString = converted.form ?? converted.displayName
        let formQuality = await formQualityService.quality(
            for: converted.canonicalName,
            form: formString
        )

        do {
            return try CalculationService.analysis(
                for: converted,
                reference: nrvEntry,
                servingSize: servingSize,
                formQuality: formQuality
            )
        } catch {
            // Unit could not be converted (e.g. unsupported IU nutrient).
            // Include in analyses with nil percentages so the user sees the entry.
            Logger.suppliScan.warning("ReportService: calculation failed for \(entry.displayName): \(error)")
            return NutrientAnalysis(entry: converted, formQuality: formQuality)
        }
    }

    private func buildFlags(
        nutrientAnalyses: [NutrientAnalysis],
        unresolvedLines: [RawLine],
        servingSize: ServingSize,
        interactions: [InteractionFlag],
        medicationInteractions: [MedicationInteractionFlag]
    ) -> ReportFlags {
        ReportFlags(
            nutrientsAboveUL: nutrientAnalyses.filter { ($0.ulPercent ?? 0) > 1.0 },
            nutrientsAtUL: nutrientAnalyses.filter {
                guard let ul = $0.ulPercent else { return false }
                return ul >= 0.9 && ul <= 1.0
            },
            lowBioavailabilityForms: nutrientAnalyses.filter {
                guard let tier = $0.formQuality?.tier else { return false }
                return tier >= .tier3
            },
            aiInferredForms: nutrientAnalyses.filter { $0.formQuality?.isAIInferred == true },
            unresolvedEntries: unresolvedLines,
            servingSizeAdjusted: servingSize.multiplier != 1.0,
            nutrientInteractions: interactions,
            medicationInteractions: medicationInteractions
        )
    }

    private func normalizedKey(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
