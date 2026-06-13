// SupplementFactsCardView.swift
// SuppliScan
// OCR-reproduced supplement facts card — a faithful label facsimile, on design tokens.

import SwiftUI

struct SupplementFactsCardView: View {
    @Binding var entries: [LabelEntry]
    let serving: ServingSize
    let isEditing: Bool
    @Binding var selectedEntryID: UUID?
    let onConfirm: (UUID) -> Void
    let onDelete: (UUID) -> Void

    /// Non-nutrient label text (warnings, marketing, lot numbers) is collapsed by default
    /// so it never buries the actual facts.
    @State private var showOtherText = false

    private var presentations: [ReviewEntryPresentation] {
        ReviewEntryClassifier.presentations(for: entries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Supplement Facts")
                .font(.system(.title2, design: .default, weight: .heavy))
                .foregroundStyle(.ink)
                .padding(.bottom, Theme.Space.xs)

            Text("Serving Size: \(serving.selectedQuantity.formatted()) \(serving.unit.pluralised(for: serving.selectedQuantity))")
                .textStyle(.subhead)
                .foregroundStyle(.ink)
            Text("Servings Per Container: —")
                .textStyle(.caption)
                .foregroundStyle(.inkTertiary)

            Rectangle()
                .frame(height: 5)
                .foregroundStyle(.ink)
                .padding(.vertical, Theme.Space.sm)

            HStack {
                Text("Amount Per Serving")
                    .textStyle(.caption)
                    .foregroundStyle(.inkSecondary)
                Spacer()
                Text("%DV")
                    .textStyle(.caption)
                    .foregroundStyle(.inkSecondary)
            }
            .padding(.bottom, Theme.Space.xs)

            HairlineDivider()

            ForEach(ReviewEntryStatus.allCases, id: \.self) { status in
                let rows = presentations.filter { $0.status == status }
                if !rows.isEmpty {
                    if status == .otherLabelText {
                        Button {
                            withAnimation(.dsSnappy) { showOtherText.toggle() }
                        } label: {
                            ReviewSectionHeader(status: status, count: rows.count, isExpanded: showOtherText)
                                .padding(.top, Theme.Space.lg)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(showOtherText ? "Collapse other label text" : "Expand other label text")

                        if showOtherText {
                            ForEach(rows) { presentation in
                                row(for: presentation)
                            }
                        }
                    } else {
                        ReviewSectionHeader(status: status, count: rows.count)
                            .padding(.top, status == .confirmed ? Theme.Space.sm : Theme.Space.lg)

                        ForEach(rows) { presentation in
                            row(for: presentation)
                        }
                    }
                }
            }
        }
        .padding(Theme.Space.lg)
        .background(.surfaceRaised, in: Theme.roundedRect(Theme.Radius.card))
        .overlay(Theme.roundedRect(Theme.Radius.card).strokeBorder(.hairline, lineWidth: 1))
        .elevation(.card)
        .padding(.horizontal, Theme.Space.screen)
        .sheet(item: selectedPresentationBinding) { presentation in
            ReviewEntryDetailSheet(
                presentation: presentation,
                onConfirm: { onConfirm(presentation.id) },
                onDelete: { onDelete(presentation.id) }
            )
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func row(for presentation: ReviewEntryPresentation) -> some View {
        ReviewEntryRowView(
            presentation: presentation,
            isEditing: isEditing,
            onOpenDetails: { selectedEntryID = presentation.id },
            onConfirm: { onConfirm(presentation.id) },
            onDelete: { onDelete(presentation.id) }
        )
        HairlineDivider()
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
    var isExpanded: Bool? = nil

    var body: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: status.systemImage)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(status.sectionTitle)
                .textStyle(.eyebrow)
                .foregroundStyle(.inkTertiary)
            Spacer()
            Text(count.formatted())
                .textStyle(.dataLabel)
                .foregroundStyle(.inkSecondary)
            if let isExpanded {
                Image(systemName: "chevron.down")
                    .font(.system(size: Theme.Icon.xs, weight: .semibold))
                    .foregroundStyle(.inkTertiary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var color: Color {
        switch status {
        case .confirmed: Theme.Palette.tier1
        case .needsReview: Theme.Palette.tier3
        case .otherLabelText: Theme.Palette.inkTertiary
        }
    }
}
