// HomeEmptyStateView.swift
// SuppliScan

import SwiftUI

struct HomeEmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            "No Saved Scans",
            systemImage: "doc.text.viewfinder",
            description: Text("Scan a supplement label or enter one manually to create a clinical report.")
        )
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.top, 24)
    }
}
