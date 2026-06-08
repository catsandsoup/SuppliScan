// FormPotencyRowView.swift
// SuppliScan
// Nutrient row with colored circular avatar, bioavailability tier label, and rationale.

import SwiftUI

struct FormPotencyRowView: View {
    let analysis: NutrientAnalysis

    var body: some View {
        guard let quality = analysis.formQuality else { return AnyView(EmptyView()) }
        let name = analysis.entry.canonicalName
        return AnyView(content(quality: quality, canonicalName: name))
    }

    private func content(quality: FormQuality, canonicalName: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            NutrientAvatarView(canonicalName: canonicalName)

            VStack(alignment: .leading, spacing: 5) {
                Text(analysis.entry.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(quality.tier.potencyLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(quality.tier.badgeColor)

                Text(quality.rationale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if quality.isAIInferred {
                    AIInferredBadgeView()
                }
            }

            Spacer(minLength: 0)

            TierBadgeView(tier: quality.tier)
        }
        .padding(.vertical, 8)
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

    private var fontSize: CGFloat {
        switch abbreviation.count {
        case 1:    return 20
        case 2:    return 16
        case 3:    return 13
        default:   return 11
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: size, height: size)
            Text(abbreviation)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
