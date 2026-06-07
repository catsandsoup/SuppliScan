// UnresolvedLineView.swift
// SuppliScan
// Raw OCR line that could not be analysed — shown in Details tab.

import SwiftUI

struct UnresolvedLineView: View {
    let line: RawLine

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(Color(.systemYellow))
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text(line.text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text("Could not be analysed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color(.systemYellow).opacity(0.08))
    }
}
