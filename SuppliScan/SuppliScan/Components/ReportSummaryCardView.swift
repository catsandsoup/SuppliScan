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

            SummaryRow(
                icon: "number.circle.fill",
                label: "Nutrients",
                detail: { AnyView(Text("\(nutrientCount) identified").font(.subheadline).foregroundStyle(.secondary)) }
            )

            if let tier = worstTier {
                SummaryRow(
                    icon: "sparkle",
                    label: "Form Quality",
                    detail: { AnyView(TierBadgeView(tier: tier)) }
                )
            }

            if let rdi = primaryRDI {
                SummaryRow(
                    icon: "chart.bar.fill",
                    label: "Dose Adequacy",
                    detail: { AnyView(Text(rdi).font(.subheadline).foregroundStyle(.secondary)) }
                )
            }

            SummaryRow(
                icon: anyAboveUL ? "exclamationmark.triangle.fill" : "checkmark.shield.fill",
                label: "UL Status",
                detail: {
                    AnyView(
                        Text(anyAboveUL ? "Above UL — review doses" : "All within safe limits")
                            .font(.subheadline)
                            .foregroundStyle(anyAboveUL ? Color(.systemRed) : Color(.systemGreen))
                    )
                },
                iconColor: anyAboveUL ? Color(.systemRed) : Color(.systemGreen)
            )

            if analysis.flags.hasAnyInteractions {
                SummaryRow(
                    icon: "arrow.left.arrow.right.circle.fill",
                    label: "Interactions",
                    detail: {
                        AnyView(
                            Text("\(analysis.flags.nutrientInteractions.count + analysis.flags.medicationInteractions.count) detected")
                                .font(.subheadline)
                                .foregroundStyle(Color(.systemOrange))
                        )
                    },
                    iconColor: Color(.systemOrange)
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SummaryRow<Detail: View>: View {
    let icon: String
    let label: String
    let detail: () -> Detail
    var iconColor: Color = .accentColor

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
