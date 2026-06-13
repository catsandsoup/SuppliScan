// ShareSummaryCardView.swift
// SuppliScan
//
// A premium, self-contained summary card rendered to an image (ImageRenderer) for sharing.
// This is the share "moment": when someone sends their scan over iMessage or posts it, the
// recipient gets an at-a-glance, branded, honest summary — not a wall of text. Fixed size,
// explicit light styling (no @Environment dependence) so it renders identically everywhere.

import SwiftUI

struct ShareSummaryCardView: View {
    let analysis: LabelAnalysis

    static let renderWidth: CGFloat = 360

    private var metaLine: String {
        let qty = analysis.servingSize.selectedQuantity
        let unit = analysis.servingSize.unit.pluralised(for: qty)
        return "\(analysis.referenceStandard.rawValue) · \(qty.formatted()) \(unit) · \(analysis.demographic.displayName)"
    }

    private var topNutrients: [NutrientAnalysis] {
        analysis.nutrientAnalyses
            .filter { $0.rdiPercent != nil }
            .sorted { ($0.rdiPercent ?? 0) > ($1.rdiPercent ?? 0) }
            .prefix(4)
            .map { $0 }
    }

    private var peakRDI: String {
        analysis.nutrientAnalyses.compactMap(\.rdiPercent).max().map { "\(Int($0.rounded()))%" } ?? "—"
    }

    private var safety: (text: String, color: Color) {
        if !analysis.flags.nutrientsAboveUL.isEmpty { return ("Above UL", Theme.Palette.tier4) }
        if !analysis.flags.nutrientsAtUL.isEmpty { return ("Near UL", Theme.Palette.tier3) }
        return ("Within UL", Theme.Palette.tier1)
    }

    private var interactionCount: Int {
        analysis.flags.nutrientInteractions.count + analysis.flags.medicationInteractions.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            bodyContent
            footer
        }
        .frame(width: Self.renderWidth)
        .background(Theme.Palette.surfaceRaised)
        .environment(\.colorScheme, .light)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            Text("SUPPLISCAN")
                .font(.system(size: 15, weight: .heavy))
                .tracking(2)
                .foregroundStyle(.white)
            Spacer()
            Text("LABEL ANALYSIS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.vertical, Theme.Space.lg)
        .background(
            LinearGradient(
                colors: [Theme.Palette.brand, Theme.Palette.brandPressed],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
    }

    private func body(content: some View) -> some View { content }

    // MARK: - Body

    private var bodyContent: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(analysis.displayTitle)
                    .font(.system(.title2, design: .default).weight(.bold))
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(2)
                Text(metaLine)
                    .font(.system(.footnote))
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }

            HStack(spacing: Theme.Space.sm) {
                statTile(value: "\(analysis.nutrientAnalyses.count)", label: "Nutrients", color: Theme.Palette.ink)
                statTile(value: peakRDI, label: "Peak RDI", color: Theme.Palette.brand)
                statTile(value: safety.text, label: "Safety", color: safety.color)
            }

            if !topNutrients.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Space.sm) {
                    ForEach(topNutrients) { nutrient in
                        nutrientRow(nutrient)
                    }
                }
            }

            if interactionCount > 0 {
                HStack(spacing: Theme.Space.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Palette.tier3)
                    Text("\(interactionCount) potential interaction\(interactionCount == 1 ? "" : "s") flagged")
                        .font(.system(.caption).weight(.medium))
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
            }
        }
        .padding(Theme.Space.xl)
    }

    private func statTile(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 19, weight: .semibold).monospacedDigit())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Theme.Palette.inkTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, Theme.Space.sm)
        .background(Theme.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }

    private func nutrientRow(_ nutrient: NutrientAnalysis) -> some View {
        let fraction = min((nutrient.rdiPercent ?? 0) / 100, 1.0)
        return HStack(spacing: Theme.Space.md) {
            Text(nutrient.entry.displayName)
                .font(.system(.subheadline).weight(.medium))
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(nutrient.rdiColor.opacity(0.15)).frame(height: 6)
                    Capsule().fill(nutrient.rdiColor).frame(width: geo.size.width * fraction, height: 6)
                }
            }
            .frame(height: 6)
            Text(nutrient.rdiPercentString)
                .font(.system(.caption).weight(.semibold).monospacedDigit())
                .foregroundStyle(nutrient.rdiColor)
                .frame(width: 48, alignment: .trailing)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Theme.Space.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Palette.inkTertiary)
            Text("Read on-device · Educational only, not medical advice")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Palette.inkTertiary)
            Spacer(minLength: Theme.Space.sm)
            Text("SuppliScan")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.Palette.brand)
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.vertical, Theme.Space.md)
        .background(Theme.Palette.surfaceSunken)
    }
}
