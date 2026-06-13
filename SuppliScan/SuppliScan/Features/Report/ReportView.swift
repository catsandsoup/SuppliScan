// ReportView.swift
// SuppliScan — STUB (full implementation in Views layer)
// Skills to invoke when implementing: swiftui-pro, swiftui-ui-patterns,
//   swiftui-accessibility-auditor, writing-for-interfaces

import SwiftUI

struct ReportView: View {
    let analysis: LabelAnalysis

    var body: some View {
        ContentUnavailableView(
            "Report Unavailable",
            systemImage: "doc.text.magnifyingglass",
            description: Text("This report can't be displayed yet. Open the scan from your history to view its analysis.")
        )
        .navigationTitle(analysis.productName.isEmpty ? "Report" : analysis.productName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
