// ReportView.swift
// SuppliScan — STUB (full implementation in Views layer)
// Skills to invoke when implementing: swiftui-pro, swiftui-ui-patterns,
//   swiftui-accessibility-auditor, writing-for-interfaces

import SwiftUI

struct ReportView: View {
    let analysis: LabelAnalysis

    var body: some View {
        ContentUnavailableView(
            "Report Coming Soon",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Clinical report rendering will be implemented in the next layer.")
        )
        .navigationTitle(analysis.productName.isEmpty ? "Report" : analysis.productName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
