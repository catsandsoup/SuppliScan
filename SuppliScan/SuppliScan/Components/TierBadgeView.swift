// TierBadgeView.swift
// SuppliScan
// FormTier coloured badge for nutrient row badges and form potency cards.

import SwiftUI

struct TierBadgeView: View {
    let tier: FormTier

    var body: some View {
        Text(tier.badgeLabel)
            .font(.dsCaption.weight(.semibold))
            .padding(.horizontal, Theme.Space.sm)
            .padding(.vertical, Theme.Space.xs)
            .background(tier.badgeColor.opacity(0.14), in: Capsule())
            .foregroundStyle(tier.badgeColor)
    }
}

extension FormTier {
    /// Short label used in compact nutrient row badges.
    var badgeLabel: String {
        switch self {
        case .tier1: "High"
        case .tier2: "Moderate"
        case .tier3: "Low"
        case .tier4: "Avoid"
        }
    }

    /// Descriptive label used in Forms & Potency cards.
    var potencyLabel: String {
        switch self {
        case .tier1: "Highly Bioavailable"
        case .tier2: "Moderate Bioavailability"
        case .tier3: "Low Bioavailability"
        case .tier4: "Poor Form — Avoid"
        }
    }

    var badgeColor: Color {
        switch self {
        case .tier1: Theme.Palette.tier1
        case .tier2: Theme.Palette.tier2
        case .tier3: Theme.Palette.tier3
        case .tier4: Theme.Palette.tier4
        }
    }
}
