// HomeViewModelTests.swift
// SuppliScanTests

import Foundation
import Testing
@testable import SuppliScan

@MainActor
struct HomeViewModelTests {
    @Test func opensReportWhenSavedAnalysisLoads() async {
        let expectedID = UUID()
        let viewModel = HomeViewModel()
        viewModel.configure { id in
            #expect(id == expectedID)
            return sampleAnalysis(id: id)
        }

        viewModel.openRecord(id: expectedID)
        await Task.yield()

        guard case .report(let analysis)? = viewModel.consumePendingDestination() else {
            Issue.record("Expected report destination")
            return
        }

        #expect(analysis.id == expectedID)
        #expect(viewModel.loadingRecordID == nil)
    }

    @Test func showsLoadErrorWhenReportIsMissing() async {
        let viewModel = HomeViewModel()
        viewModel.configure { _ in nil }

        viewModel.openRecord(id: UUID())
        await Task.yield()

        #expect(viewModel.isShowingLoadError)
        #expect(viewModel.consumePendingDestination() == nil)
    }
}

private func sampleAnalysis(id: UUID = UUID()) -> LabelAnalysis {
    LabelAnalysis(
        id: id,
        productName: "Test Supplement",
        referenceStandard: .au,
        demographic: .defaultAdult,
        servingSize: ServingSize(quantity: 1, unit: .capsule),
        nutrientAnalyses: [],
        herbalEntries: [],
        probioticEntries: [],
        unresolvedLines: [],
        flags: .empty,
        disclaimer: LabelAnalysis.disclaimer,
        schemaVersion: LabelAnalysis.currentSchemaVersion,
        createdAt: Date()
    )
}
