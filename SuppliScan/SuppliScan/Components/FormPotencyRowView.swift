// FormPotencyRowView.swift
// SuppliScan
// Nutrient row with coloured monogram avatar, bioavailability tier label, and rationale.

import SwiftUI

struct FormPotencyRowView: View {
    let analysis: NutrientAnalysis

    @ViewBuilder
    var body: some View {
        if let quality = analysis.formQuality {
            content(quality: quality, canonicalName: analysis.entry.canonicalName)
        }
    }

    private func content(quality: FormQuality, canonicalName: String) -> some View {
        HStack(alignment: .center, spacing: Theme.Space.md) {
            NutrientAvatarView(canonicalName: canonicalName)

            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(analysis.entry.displayName)
                    .textStyle(.headline)
                    .foregroundStyle(.ink)

                Text(quality.tier.potencyLabel)
                    .textStyle(.caption)
                    .foregroundStyle(quality.tier.badgeColor)

                Text(quality.rationale)
                    .textStyle(.caption)
                    .foregroundStyle(.inkSecondary)
                    .lineLimit(2)

                if quality.isAIInferred {
                    AIInferredBadgeView()
                }
            }

            Spacer(minLength: Theme.Space.sm)

            TierBadgeView(tier: quality.tier)
        }
        .padding(.vertical, Theme.Space.sm)
    }
}

// MARK: - NutrientAvatarView

struct NutrientAvatarView: View {
    let canonicalName: String
    var size: CGFloat = 48

    private var abbreviation: String {
        AppTheme.Color.nutrientAbbreviation(for: canonicalName)
    }

    private var bgColor: Color {
        AppTheme.Color.nutrientAvatarBackground(for: canonicalName)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: size, height: size)
            Text(abbreviation)
                .font(.system(size: size * 0.34, weight: .semibold))
                .minimumScaleFactor(0.65)
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}
