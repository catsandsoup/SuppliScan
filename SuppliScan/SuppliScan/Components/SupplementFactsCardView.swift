// SupplementFactsCardView.swift
// SuppliScan
// OCR-reproduced supplement facts card — faithful label recreation in ReviewView.

import SwiftUI

struct SupplementFactsCardView: View {
    @Binding var entries: [LabelEntry]
    let serving: ServingSize
    let isEditing: Bool
    let onDelete: (IndexSet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Supplement Facts")
                .font(.system(.title2, design: .default, weight: .black))
                .padding(.bottom, 4)

            Text("Serving Size: \(serving.selectedQuantity.formatted()) \(serving.unit.pluralised(for: serving.selectedQuantity))")
                .font(.subheadline)
            Text("Servings Per Container: —")
                .font(.caption)
                .foregroundStyle(.secondary)

            Rectangle()
                .frame(height: 6)
                .foregroundStyle(Color(.label))
                .padding(.vertical, 8)

            // Column headers
            HStack {
                Text("Amount Per Serving")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("%DV")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            Divider()

            // Entry rows
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                ReviewEntryRowView(entry: entry, index: index, isEditing: isEditing) { updated in
                    entries[index] = updated
                }
                Divider()
            }
            .onDelete(perform: onDelete)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(.label).opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}
