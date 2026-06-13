// ReviewEntryRowView.swift
// SuppliScan
// Switches on LabelEntry case, editable when isEditing is true.
// All four cases handled — never silent.

import SwiftUI

struct ReviewEntryRowView: View {
    let presentation: ReviewEntryPresentation
    let isEditing: Bool
    let onOpenDetails: () -> Void
    let onConfirm: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Space.md) {
            Image(systemName: presentation.status.systemImage)
                .font(.system(size: Theme.Icon.sm, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(presentation.title)
                    .textStyle(.subhead)
                    .foregroundStyle(.ink)
                if let subtitle = presentation.subtitle {
                    Text(subtitle)
                        .textStyle(.caption)
                        .foregroundStyle(.inkTertiary)
                }
                if !presentation.reviewReasons.isEmpty {
                    Text(presentation.reviewReasons.joined(separator: " · "))
                        .textStyle(.caption)
                        .foregroundStyle(statusColor)
                }
            }

            Spacer(minLength: Theme.Space.sm)

            if let amount = presentation.amountText {
                Text(amount)
                    .textStyle(.dataLabel)
                    .foregroundStyle(.inkSecondary)
            }

            if isEditing {
                Button("Delete Entry", systemImage: "trash", role: .destructive, action: onDelete)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Delete entry")
            } else if presentation.status == .needsReview {
                Button("Review", systemImage: "slider.horizontal.3", action: onOpenDetails)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Review row")
            } else if presentation.status == .otherLabelText {
                Button("Ignore Label Text", systemImage: "eye.slash", action: onDelete)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Ignore label text")
            }
        }
        .padding(.vertical, 8)
        .opacity(isEditing ? 0.86 : 1.0)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.accessibilitySummary)
        .accessibilityHint(accessibilityHint)
        .accessibilityActions {
            if presentation.status == .needsReview {
                Button("Confirm Row", action: onConfirm)
            }
            Button("Show Details", action: onOpenDetails)
            Button("Delete Row", role: .destructive, action: onDelete)
        }
    }

    private var statusColor: Color {
        switch presentation.status {
        case .confirmed: Theme.Palette.tier1
        case .needsReview: Theme.Palette.tier3
        case .otherLabelText: Theme.Palette.inkTertiary
        }
    }

    private var accessibilityHint: String {
        switch presentation.status {
        case .confirmed: "Included in analysis"
        case .needsReview: "Open details to verify or confirm this row"
        case .otherLabelText: "Not included in analysis"
        }
    }
}

struct ReviewEntryDetailSheet: View {
    let presentation: ReviewEntryPresentation
    let onConfirm: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Parsed Interpretation") {
                    LabeledContent("Status", value: presentation.status.label)
                    LabeledContent("Name", value: presentation.title)
                    if let subtitle = presentation.subtitle {
                        LabeledContent("Detail", value: subtitle)
                    }
                    LabeledContent("Amount", value: presentation.amountText ?? "Not found")
                }

                if !presentation.reviewReasons.isEmpty {
                    Section("Needs Checking") {
                        ForEach(presentation.reviewReasons, id: \.self) { reason in
                            Label(reason, systemImage: "flag.fill")
                                .foregroundStyle(AppTheme.Color.warning)
                        }
                    }
                }

                Section {
                    if presentation.status == .needsReview {
                        Button("Confirm Row", systemImage: "checkmark.circle", action: confirmAndDismiss)
                    }
                    Button("Remove From Analysis", systemImage: "eye.slash", role: .destructive, action: deleteAndDismiss)
                }
            }
            .navigationTitle("Review Row")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", role: .cancel) { dismiss() }
                }
            }
        }
    }

    private func confirmAndDismiss() {
        onConfirm()
        dismiss()
    }

    private func deleteAndDismiss() {
        onDelete()
        dismiss()
    }
}

extension ReviewFlag {
    var explanation: String {
        switch self {
        case .amountNotFound: "No numeric amount could be extracted for this entry."
        case .unitUnknown: "The unit for this entry was not recognised."
        case .dualUnit: "Both IU and metric units were present. The metric value was used."
        case .rangeAmount: "A dose range was shown. Check the amount before analysis."
        case .traceAmount: "The label shows a trace amount. Check whether this should count toward the total."
        case .subOneAmount: "The amount is below 1. Check the label before analysis."
        case .extractEquivalent: "The label shows a separate active amount. Check that the chosen amount is correct."
        case .proprietaryBlend: "Individual amounts within this blend are unknown."
        case .totalLineAmbiguous: "This appears to be a total line. Confirm it replaces sub-entries."
        case .iuConversionAssumed: "Check the Vitamin E form before relying on this amount."
        case .iuConversionInvalid: "IU is not a valid unit for this nutrient."
        case .decimalCommaNormalised: "Check the decimal placement against the label."
        case .servingMultiplied: "Amount adjusted by the selected serving size."
        case .canonicalNameInferred: "Check the nutrient name against the label."
        case .unitUnexpected: "The unit is unusual for this nutrient. Please verify."
        case .unitImplausible: "The unit is clinically unlikely for this nutrient. Please verify."
        case .ocrUncertain: "OCR evidence for this row was weak or reconstructed."
        case .ocrConflict: "Multiple OCR passes disagreed. Check this row against the label."
        case .ocrSinglePassEvidence: "Only one OCR pass supported this row. Please verify."
        }
    }
}
