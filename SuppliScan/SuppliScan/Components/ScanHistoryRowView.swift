// ScanHistoryRowView.swift
// SuppliScan
//
// Reusable row for displaying a ScanRecord in HomeView and HistoryView.
// Tapping calls the onTap closure — navigation owned by the parent view.

import SwiftUI

struct ScanHistoryRowView: View {
    let record: ScanRecord
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.productName.isEmpty ? "Unnamed Product" : record.productName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: 8) {
                        Text(record.referenceStandard)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(record.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
