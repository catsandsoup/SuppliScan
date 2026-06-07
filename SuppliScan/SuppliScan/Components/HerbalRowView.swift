// HerbalRowView.swift
// SuppliScan
// Herbal entry row — latin name, extract type, amount, dry equivalent.

import SwiftUI

struct HerbalRowView: View {
    let entry: HerbalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.latinName)
                        .font(.subheadline.italic())
                    if let common = entry.commonName {
                        Text(common)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let amount = entry.extractAmount, let unit = entry.extractUnit {
                    Text("\(amount.formatted()) \(unit.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                } else {
                    Text("Amount unknown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let dryEq = entry.dryEquivalentAmount, let dryUnit = entry.dryEquivalentUnit {
                Text("Equiv. to \(dryEq.formatted()) \(dryUnit.rawValue) dry herb")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let std = entry.standardisation {
                Text("\(std.amount.formatted()) \(std.unit.rawValue) \(std.compound)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
