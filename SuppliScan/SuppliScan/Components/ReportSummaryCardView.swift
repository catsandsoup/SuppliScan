// ReportSummaryCardView.swift
// SuppliScan
// Summary card: form quality, dose adequacy, UL status.

import SwiftUI

struct ReportSummaryCardView: View {
    let analysis: LabelAnalysis

    private var worstTier: FormTier? {
        analysis.nutrientAnalyses.compactMap(\.formQuality?.tier).max()
    }

    private var primaryRDI: String? {
        guard let first = analysis.nutrientAnalyses.first(where: { $0.rdiPercent != nil }) else { return nil }
        return first.rdiPercentString
    }

    private var anyAboveUL: Bool {
        !analysis.flags.nutrientsAboveUL.isEmpty
    }

    private var nutrientCount: Int {
        Set(analysis.nutrientAnalyses.map(\.entry.canonicalName)).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Summary")
                .font(.headline)

            Divider()

            SummaryRow(icon: "number.circle.fill", label: "Nutrients") {
                Text("\(nutrientCount) identified").font(.subheadline).foregroundStyle(.secondary)
            }

            if let tier = worstTier {
                SummaryRow(icon: "sparkle", label: "Form Quality") {
                    TierBadgeView(tier: tier)
                }
            }

            if let rdi = primaryRDI {
                SummaryRow(icon: "chart.bar.fill", label: "Dose Adequacy") {
                    Text(rdi).font(.subheadline).foregroundStyle(.secondary)
                }
            }

            SummaryRow(
                icon: anyAboveUL ? "exclamationmark.triangle.fill" : "checkmark.shield.fill",
                label: "UL Status",
                iconColor: anyAboveUL ? AppTheme.Color.critical : AppTheme.Color.success
            ) {
                Text(anyAboveUL ? "Above UL — review doses" : "All within safe limits")
                    .font(.subheadline)
                    .foregroundStyle(anyAboveUL ? AppTheme.Color.critical : AppTheme.Color.success)
            }

            if analysis.flags.hasAnyInteractions {
                SummaryRow(
                    icon: "arrow.left.arrow.right.circle.fill",
                    label: "Interactions",
                    iconColor: Color(.systemOrange)
                ) {
                    Text("\(analysis.flags.nutrientInteractions.count + analysis.flags.medicationInteractions.count) detected")
                        .font(.subheadline)
                        .foregroundStyle(Color(.systemOrange))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SummaryRow<Detail: View>: View {
    let icon: String
    let label: String
    var iconColor: Color = .accentColor
    @ViewBuilder let detail: () -> Detail

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.subheadline)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minWidth: 90, alignment: .leading)
            Spacer()
            detail()
        }
    }
}
