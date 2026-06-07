// NutrientAnalysisRowView.swift
// SuppliScan
// Full nutrient row with RDI%, dose, progress bar, UL context, and tier/AI badges.

import SwiftUI

struct NutrientAnalysisRowView: View {
    let analysis: NutrientAnalysis
    let index: Int

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(analysis.entry.displayName)
                    .font(.headline)
                Spacer()
                Text(analysis.rdiPercentString)
                    .font(.headline)
                    .foregroundStyle(analysis.rdiColor)
            }

            if let form = analysis.entry.form {
                Text("as \(form)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(analysis.doseString)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: appeared ? min(analysis.rdiPercent ?? 0, 1.0) : 0)
                .tint(analysis.rdiColor)
                .animation(
                    .easeOut(duration: 0.6).delay(Double(index) * 0.08),
                    value: appeared
                )

            if let ulStr = analysis.ulPercentString {
                Text("UL: \(ulStr) of upper limit")
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            HStack(spacing: 6) {
                if let quality = analysis.formQuality {
                    TierBadgeView(tier: quality.tier)
                    if quality.isAIInferred {
                        AIInferredBadgeView()
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            appeared = true
        }
    }
}
