// NutrientStatTable.swift
// SuppliScan
// Two-column stat rows for NutrientDetailView — label + value.

import SwiftUI

struct NutrientStatTable: View {
    let rows: [StatRow]

    struct StatRow {
        let label: String
        let value: String
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text(row.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(row.value)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                if index < rows.count - 1 {
                    Divider()
                }
            }
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 1)
    }
}
