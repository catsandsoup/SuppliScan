// NutrientDetailView.swift
// SuppliScan
// Deep-dive drill-down from the Nutrients / Forms tabs.
// Premium radial RDI gauge (adequacy) + honest UL safety read + stat table + form quality.
// On the Theme design system. Logic unchanged — pure presentation.
// No ADI row — no ADI data in v1 NRV JSONs. No fabricated unit math.

import SwiftUI

struct NutrientDetailView: View {
    let analysis: NutrientAnalysis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                header

                // Hero: RDI adequacy gauge + UL safety read.
                heroBlock

                // Reference figures.
                NutrientStatTable(rows: statRows)

                // Form quality (curated, source-backed; absent for botanicals/probiotics).
                if let quality = analysis.formQuality {
                    formQualityCard(quality)
                }

                Spacer(minLength: Theme.Space.xxl)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.md)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .navigationTitle(analysis.entry.canonicalName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.dsGentle) { appeared = true }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(categoryEyebrow)
                .textStyle(.eyebrow)
                .foregroundStyle(.brand)
            Text(analysis.entry.displayName)
                .textStyle(.display)
                .foregroundStyle(.ink)
                .lineLimit(2)
            if let form = analysis.entry.form, !form.isEmpty {
                Text("as \(form)")
                    .textStyle(.subhead)
                    .foregroundStyle(.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryEyebrow: String {
        analysis.entry.isTotalLine ? "Total line" : "Nutrient"
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroBlock: some View {
        VStack(spacing: Theme.Space.lg) {
            if let rdi = analysis.rdiPercent {
                RDIGaugeView(
                    percent: rdi,
                    color: analysis.rdiColor,
                    appeared: appeared,
                    reduceMotion: reduceMotion
                )
            } else {
                noRDIHero
            }
            SafetyReadView(
                ulPercent: analysis.ulPercent,
                ulReference: analysis.ulReferenceString
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Space.xl)
        .dsCard(padding: Theme.Space.lg)
    }

    private var noRDIHero: some View {
        VStack(spacing: Theme.Space.sm) {
            Text(analysis.doseString)
                .font(.dsHero)
                .foregroundStyle(.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("per serving")
                .textStyle(.subhead)
                .foregroundStyle(.inkSecondary)
            Text("No Recommended Dietary Intake established")
                .textStyle(.caption)
                .foregroundStyle(.inkTertiary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Form quality

    private func formQualityCard(_ quality: FormQuality) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack(spacing: Theme.Space.sm) {
                Text("Form Quality")
                    .textStyle(.headline)
                    .foregroundStyle(.ink)
                Spacer()
                TierBadgeView(tier: quality.tier)
            }

            Text(quality.tier.fullLabel)
                .textStyle(.subhead)
                .foregroundStyle(quality.tier.tierColor)

            Text(quality.rationale)
                .textStyle(.callout)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if quality.isAIInferred {
                AIInferredBadgeView()
            } else if !quality.references.isEmpty {
                citationRow(quality.references)
            }
        }
        .dsCard()
    }

    private func citationRow(_ references: [String]) -> some View {
        HStack(spacing: Theme.Space.xs) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: Theme.Icon.xs, weight: .semibold))
                .foregroundStyle(.inkTertiary)
            Text(references.joined(separator: " · "))
                .textStyle(.caption)
                .foregroundStyle(.inkTertiary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Evidence: \(references.joined(separator: ", "))")
    }

    private var statRows: [NutrientStatTable.StatRow] {
        [
            .init(label: "Amount per serving", value: analysis.doseString),
            .init(label: "Recommended Intake", value: analysis.rdiReferenceString ?? "Not established"),
            .init(label: "% of RDI", value: analysis.rdiPercentString),
            .init(label: "Upper Limit", value: analysis.ulReferenceString ?? "Not established"),
            .init(label: "% of UL", value: analysis.ulPercentString ?? "—"),
        ]
    }
}

// MARK: - Tier colour bridge

private extension FormTier {
    var tierColor: Color {
        switch self {
        case .tier1: Theme.Palette.tier1
        case .tier2: Theme.Palette.tier2
        case .tier3: Theme.Palette.tier3
        case .tier4: Theme.Palette.tier4
        }
    }
}

// MARK: - RDI radial gauge
//
// A 270° arc (gap at the bottom). The coloured progress fills proportional to
// min(percent, 100)/100, while the centre prints the TRUE percentage — so a value
// above 100% reads honestly as a full ring plus an "Exceeds RDI" chip.

private struct RDIGaugeView: View {
    let percent: Double
    let color: Color
    let appeared: Bool
    let reduceMotion: Bool

    private let sweep: Double = 0.75            // 270° of the circle
    private let lineWidth: CGFloat = 14
    private let diameter: CGFloat = 196

    private var fraction: Double { min(percent, 100) / 100 }
    private var trimEnd: Double { (appeared ? fraction : 0) * sweep }
    private var exceeds: Bool { percent > 100 }

    var body: some View {
        ZStack {
            // 270° track, gap centred at the bottom.
            Circle()
                .trim(from: 0, to: sweep)
                .stroke(.surfaceSunken, style: .init(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))

            // Coloured progress, same geometry.
            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(color, style: .init(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
                .animation(reduceMotion ? nil : .spring(response: 0.85, dampingFraction: 0.82), value: trimEnd)

            centerLabel
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(percent.rounded())) percent of recommended dietary intake")
    }

    private var centerLabel: some View {
        VStack(spacing: Theme.Space.xxs) {
            Text("\(Int(percent.rounded()))%")
                .font(.dsHero)
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("of RDI")
                .textStyle(.eyebrow)
                .foregroundStyle(.inkTertiary)
            if exceeds {
                Text("Exceeds RDI")
                    .textStyle(.caption)
                    .foregroundStyle(color)
                    .padding(.horizontal, Theme.Space.sm)
                    .padding(.vertical, Theme.Space.xxs)
                    .background(color.opacity(0.14), in: Capsule())
                    .padding(.top, Theme.Space.xxs)
            }
        }
    }
}

// MARK: - UL safety read
//
// Honest safety signal derived only from the model's ulPercent — no unit math.

private struct SafetyReadView: View {
    let ulPercent: Double?
    let ulReference: String?

    private var label: String {
        guard let ul = ulPercent else { return "No Upper Limit established" }
        if ul > 100 { return "Above Upper Limit" }
        if ul >= 90 { return "Approaching Upper Limit" }
        return "Within safe Upper Limit"
    }

    private var color: Color {
        guard let ul = ulPercent else { return Theme.Palette.inkTertiary }
        if ul > 100 { return Theme.Palette.tier4 }
        if ul >= 90 { return Theme.Palette.tier3 }
        return Theme.Palette.tier1
    }

    private var icon: String {
        guard let ul = ulPercent else { return "minus.circle" }
        if ul > 100 { return "exclamationmark.triangle.fill" }
        if ul >= 90 { return "exclamationmark.circle.fill" }
        return "checkmark.shield.fill"
    }

    var body: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: icon)
                .font(.system(size: Theme.Icon.sm, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .textStyle(.subhead)
                .foregroundStyle(.ink)
            if let ulReference {
                Spacer(minLength: Theme.Space.sm)
                Text("UL \(ulReference)")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, Theme.Space.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.10), in: Theme.roundedRect(Theme.Radius.sm))
        .accessibilityElement(children: .combine)
    }
}
