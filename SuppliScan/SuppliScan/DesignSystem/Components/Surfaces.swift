//  Surfaces.swift
//  SuppliScan — Design System components: surfaces, cards, dividers.

import SwiftUI

extension View {
    /// Premium content card: raised surface, continuous corners, hairline edge,
    /// colour-scheme-adaptive elevation. The standard container for report content.
    func dsCard(
        padding: CGFloat = Theme.Space.lg,
        radius: CGFloat = Theme.Radius.card,
        elevation: Theme.Elevation = .card
    ) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.surfaceRaised, in: Theme.roundedRect(radius))
            .overlay(Theme.roundedRect(radius).strokeBorder(.hairline, lineWidth: 1))
            .elevation(elevation)
    }

    /// Surface treatment without padding (for cards that manage their own insets,
    /// e.g. rows with full-bleed dividers).
    func dsSurface(
        radius: CGFloat = Theme.Radius.card,
        elevation: Theme.Elevation = .card
    ) -> some View {
        self
            .background(.surfaceRaised, in: Theme.roundedRect(radius))
            .overlay(Theme.roundedRect(radius).strokeBorder(.hairline, lineWidth: 1))
            .elevation(elevation)
    }

    /// Full-bleed warm app background.
    func screenBackground() -> some View {
        background(Theme.Palette.surface.ignoresSafeArea())
    }
}

/// 1-px hairline rule — replaces the system `Divider()`.
struct HairlineDivider: View {
    var leadingInset: CGFloat = 0
    var body: some View {
        Rectangle()
            .fill(.hairline)
            .frame(height: 1)
            .padding(.leading, leadingInset)
            .accessibilityHidden(true)
    }
}
