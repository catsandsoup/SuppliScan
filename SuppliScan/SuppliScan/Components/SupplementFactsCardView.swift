// SupplementFactsCardView.swift
// SuppliScan
// OCR-reproduced supplement facts card — faithful label recreation in ReviewView.

import SwiftUI

struct SupplementFactsCardView: View {
    @Binding var entries: [LabelEntry]
    let serving: ServingSize
    let isEditing: Bool
    @Binding var selectedEntryID: UUID?
    let onConfirm: (UUID) -> Void
    let onDelete: (UUID) -> Void

    private var presentations: [ReviewEntryPresentation] {
        ReviewEntryClassifier.presentations(for: entries)
    }

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

            ForEach(ReviewEntryStatus.allCases, id: \.self) { status in
                let rows = presentations.filter { $0.status == status }
                if !rows.isEmpty {
                    ReviewSectionHeader(status: status, count: rows.count)
                        .padding(.top, status == .confirmed ? 8 : 14)

                    ForEach(rows) { presentation in
                        ReviewEntryRowView(
                            presentation: presentation,
                            isEditing: isEditing,
                            onOpenDetails: { selectedEntryID = presentation.id },
                            onConfirm: { onConfirm(presentation.id) },
                            onDelete: { onDelete(presentation.id) }
                        )
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color(.label).opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .sheet(item: selectedPresentationBinding) { presentation in
            ReviewEntryDetailSheet(
                presentation: presentation,
                onConfirm: { onConfirm(presentation.id) },
                onDelete: { onDelete(presentation.id) }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var selectedPresentationBinding: Binding<ReviewEntryPresentation?> {
        Binding {
            presentations.first { $0.id == selectedEntryID }
        } set: { newValue in
            selectedEntryID = newValue?.id
        }
    }
}

private struct ReviewSectionHeader: View {
    let status: ReviewEntryStatus
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.systemImage)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(status.sectionTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(count.formatted())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var color: Color {
        switch status {
        case .confirmed: AppTheme.Color.success
        case .needsReview: AppTheme.Color.warning
        case .otherLabelText: .secondary
        }
    }
}
