// AnalysisRootView.swift
// SuppliScan
// Root of the Analysis tab. Shows the most recent persisted LabelAnalysis from SwiftData.
// Reads directly via @Query — always reflects the last saved scan, independent of
// the in-flight Scan tab workflow state.

import SwiftUI
import SwiftData

struct AnalysisRootView: View {
    @Query(sort: \ScanRecord.createdAt, order: .reverse) private var records: [ScanRecord]

    var body: some View {
        if let analysis = latestAnalysis {
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

    private var latestAnalysis: LabelAnalysis? {
        guard let record = records.first, !record.reportData.isEmpty else { return nil }
        return try? LabelAnalysis.decode(from: record.reportData)
    }
}
