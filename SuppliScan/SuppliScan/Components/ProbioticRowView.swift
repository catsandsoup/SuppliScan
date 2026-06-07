// ProbioticRowView.swift
// SuppliScan
// Probiotic strain row — genus species (italic), strain code, CFU.

import SwiftUI

struct ProbioticRowView: View {
    let entry: ProbioticEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.genus) \(entry.species)")
                    .font(.subheadline.italic())
                if let strain = entry.strain {
                    Text(strain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let cfu = entry.cfuBillions {
                Text("\(cfu.formatted()) B CFU")
                    .font(.subheadline)
            } else {
                Text("CFU unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
