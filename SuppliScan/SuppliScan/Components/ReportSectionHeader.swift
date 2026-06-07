// ReportSectionHeader.swift
// SuppliScan
// Section title + Divider — used in scroll contexts instead of List Section headers.

import SwiftUI

struct ReportSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Divider()
        }
        .padding(.bottom, 4)
    }
}
