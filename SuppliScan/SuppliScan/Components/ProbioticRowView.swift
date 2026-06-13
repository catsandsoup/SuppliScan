// ProbioticRowView.swift
// SuppliScan
// Probiotic strain row — genus species (italic), strain code, CFU. On tokens.

import SwiftUI

struct ProbioticRowView: View {
    let entry: ProbioticEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.md) {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text("\(entry.genus) \(entry.species)")
                    .font(.dsSubhead.italic())
                    .foregroundStyle(.ink)
                if let strain = entry.strain {
                    Text(strain)
                        .textStyle(.caption)
                        .foregroundStyle(.inkTertiary)
                }
            }
            Spacer(minLength: Theme.Space.sm)
            if let cfu = entry.cfuBillions {
                Text("\(cfu.formatted()) B CFU")
                    .textStyle(.dataLabel)
                    .foregroundStyle(.ink)
            } else {
                Text("CFU unknown")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
            }
        }
        .padding(.vertical, Theme.Space.xs)
        .accessibilityElement(children: .combine)
    }
}
