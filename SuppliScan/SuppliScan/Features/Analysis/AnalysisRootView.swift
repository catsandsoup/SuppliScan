// AnalysisRootView.swift
// SuppliScan
// Root of the Analysis tab. Shows the most recent LabelAnalysis from AnalysisStore,
// or an empty state when no analysis has been performed yet.

import SwiftUI

struct AnalysisRootView: View {
    @Environment(AnalysisStore.self) private var analysisStore

    var body: some View {
        if let analysis = analysisStore.currentAnalysis {
            AnalysisView(analysis: analysis)
        } else {
            ContentUnavailableView(
                "No Analysis Yet",
                systemImage: "chart.bar.doc.horizontal",
                description: Text("Scan a supplement label to see a clinical analysis here.")
            )
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
