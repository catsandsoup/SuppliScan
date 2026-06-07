// TierBadgeView.swift
// SuppliScan
// FormTier coloured badge: T1 High (green), T2 Moderate (yellow), T3 Low (orange), T4 Avoid (red).

import SwiftUI

struct TierBadgeView: View {
    let tier: FormTier

    var body: some View {
        Text(tier.badgeLabel)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tier.badgeColor.opacity(0.15), in: Capsule())
            .foregroundStyle(tier.badgeColor)
    }
}

extension FormTier {
    var badgeLabel: String {
        switch self {
        case .tier1: "High"
        case .tier2: "Moderate"
        case .tier3: "Low"
        case .tier4: "Avoid"
        }
    }

    var badgeColor: Color {
        switch self {
        case .tier1: .green
        case .tier2: .yellow
        case .tier3: .orange
        case .tier4: .red
        }
    }
}
