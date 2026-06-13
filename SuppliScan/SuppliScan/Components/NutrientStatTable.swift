// NutrientStatTable.swift
// SuppliScan
// Two-column reference rows for NutrientDetailView — label + value, on the design system.

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
                HStack(spacing: Theme.Space.md) {
                    Text(row.label)
                        .textStyle(.subhead)
                        .foregroundStyle(.inkSecondary)
                    Spacer(minLength: Theme.Space.sm)
                    Text(row.value)
                        .textStyle(.dataLabel)
                        .foregroundStyle(.ink)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, Theme.Space.md)
                .accessibilityElement(children: .combine)

                if index < rows.count - 1 {
                    HairlineDivider()
                }
            }
        }
        .padding(.horizontal, Theme.Space.lg)
        .dsSurface()
    }
}
