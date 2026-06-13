// HerbalRowView.swift
// SuppliScan
// Herbal entry row — latin name, common name, extract amount, dry equivalent. On tokens.

import SwiftUI

struct HerbalRowView: View {
    let entry: HerbalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.md) {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    Text(entry.latinName)
                        .font(.dsSubhead.italic())
                        .foregroundStyle(.ink)
                    if let common = entry.commonName {
                        Text(common)
                            .textStyle(.caption)
                            .foregroundStyle(.inkTertiary)
                    }
                }
                Spacer(minLength: Theme.Space.sm)
                if let amount = entry.extractAmount, let unit = entry.extractUnit {
                    Text("\(amount.formatted()) \(unit.rawValue)")
                        .textStyle(.dataLabel)
                        .foregroundStyle(.ink)
                } else {
                    Text("Amount unknown")
                        .textStyle(.caption)
                        .foregroundStyle(.inkTertiary)
                }
            }
            if let dryEq = entry.dryEquivalentAmount, let dryUnit = entry.dryEquivalentUnit {
                Text("Equiv. to \(dryEq.formatted()) \(dryUnit.rawValue) dry herb")
                    .textStyle(.caption)
                    .foregroundStyle(.inkSecondary)
                    .monospacedDigit()
            }
            if let std = entry.standardisation {
                Text("\(std.amount.formatted()) \(std.unit.rawValue) \(std.compound)")
                    .textStyle(.caption)
                    .foregroundStyle(.inkSecondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, Theme.Space.xs)
        .accessibilityElement(children: .combine)
    }
}
