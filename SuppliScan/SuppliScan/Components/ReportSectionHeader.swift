// ReportSectionHeader.swift
// SuppliScan
// Section title used in scroll contexts (Details tab) instead of List Section headers.

import SwiftUI

struct ReportSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .textStyle(.title)
            .foregroundStyle(.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Theme.Space.sm)
    }
}
