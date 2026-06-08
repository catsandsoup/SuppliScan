// NutrientAnalysisRowView.swift
// SuppliScan
// Nutrient row: large bold RDI% on the right, name + form + dose on the left,
// animated progress bar below, UL context as small caption.

import SwiftUI

struct NutrientAnalysisRowView: View {
    let analysis: NutrientAnalysis
    let index: Int

    @State private var appeared = false

    private var rdiPercent: Double { analysis.rdiPercent ?? 0 }
    private var rdiColor: Color { analysis.rdiColor }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                nutrientInfo
                Spacer(minLength: 8)
                rdiDisplay
            }
            .padding(.top, 14)

            progressBar
                .padding(.top, 10)

            ulCaption
                .padding(.top, 5)
                .padding(.bottom, 14)
        }
        .onAppear { appeared = true }
    }

    // MARK: - Left column

    private var nutrientInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(analysis.entry.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            if let form = analysis.entry.form {
                Text("as \(form)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(analysis.doseString)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Right column — large RDI%

    private var rdiDisplay: some View {
        VStack(alignment: .trailing, spacing: 1) {
            if analysis.rdiPercent != nil {
                Text(analysis.rdiPercentString)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(rdiColor)
                    .monospacedDigit()
                Text("RDI")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(rdiColor.opacity(0.70))
            } else {
                Text("—")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(rdiColor.opacity(0.12))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(rdiColor)
                    .frame(
                        width: appeared ? geo.size.width * min(rdiPercent, 1.0) : 0,
                        height: 6
                    )
                    .animation(
                        .easeOut(duration: 0.55).delay(Double(index) * 0.06),
                        value: appeared
                    )
            }
        }
        .frame(height: 6)
    }

    // MARK: - UL caption

    @ViewBuilder
    private var ulCaption: some View {
        if let ulStr = analysis.ulPercentString, let ulRef = analysis.ulReferenceString {
            Text("UL: \(ulRef) · \(ulStr) of upper limit")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        } else if let ulStr = analysis.ulPercentString {
            Text("\(ulStr) of upper limit")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        } else if let badges = formBadges, !badges.isEmpty {
            HStack(spacing: 4) {
                ForEach(badges, id: \.self) { badge in
                    TierBadgeView(tier: badge)
                }
            }
        }
    }

    private var formBadges: [FormTier]? {
        guard let quality = analysis.formQuality else { return nil }
        return [quality.tier]
    }
}
