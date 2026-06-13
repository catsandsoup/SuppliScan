// AppDestinationView.swift
// SuppliScan

import SwiftUI

struct AppDestinationView: View {
    let destination: AppDestination

    var body: some View {
        switch destination {
        case .scan:
            ScanView()
        case .review(let entries, let serving):
            ReviewView(entries: entries, extractedServing: serving)
        case .analysis(let analysis):
            AnalysisView(analysis: analysis)
        case .nutrientDetail(let analysis):
            NutrientDetailView(analysis: analysis)
        case .formsAndPotency(let analyses):
            FormsAndPotencyView(analyses: analyses)
        case .history:
            HistoryView()
        case .libraryEntry(let entry):
            LibraryEntryDetailView(entry: entry)
        }
    }
}
