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
        case .report(let analysis):
            ReportView(analysis: analysis)
        case .history:
            HistoryView()
        }
    }
}
