// ScanHistoryRowView.swift
// SuppliScan
//
// Reusable row for a saved report in HomeView and HistoryView. Design-system styled.
// Tapping calls onTap — navigation owned by the parent.

import SwiftUI

struct ScanHistoryRowView: View {
    let record: ScanRecordSummary
    var isLoading = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Space.md) {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    Text(record.productName.isEmpty ? "Unnamed product" : record.productName)
                        .textStyle(.headline)
                        .foregroundStyle(.ink)
                        .lineLimit(1)
                    HStack(spacing: Theme.Space.sm) {
                        Text(record.referenceStandard)
                            .foregroundStyle(.inkTertiary)
                        Text("·")
                            .foregroundStyle(.inkFaint)
                        Text(record.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.inkTertiary)
                    }
                    .textStyle(.caption)
                }
                Spacer(minLength: Theme.Space.sm)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.brand)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: Theme.Icon.xs, weight: .semibold))
                        .foregroundStyle(.inkFaint)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.vertical, Theme.Space.md)
            .contentShape(.rect)
        }
        .buttonStyle(.pressable)
        .disabled(isLoading)
        .accessibilityHint("Opens the saved report.")
    }
}
