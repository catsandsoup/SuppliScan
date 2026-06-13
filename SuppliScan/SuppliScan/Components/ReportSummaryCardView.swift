// ReportSummaryCardView.swift
// SuppliScan
// Hero summary: an honest Form-Quality verdict (not a fabricated aggregate score),
// a one-line clinical note, and the tier distribution. Dose/UL live on the snapshot.

import SwiftUI

struct ReportSummaryCardView: View {
    let analysis: LabelAnalysis

    private var tiers: [FormTier] {
        analysis.nutrientAnalyses.compactMap(\.formQuality?.tier)
    }

    private var worstTier: FormTier? { tiers.max() }

    private var anyAboveUL: Bool { !analysis.flags.nutrientsAboveUL.isEmpty }

    private var verdict: (word: String, color: Color) {
        guard let worst = worstTier else { return ("Unrated", Theme.Palette.inkTertiary) }
        switch worst {
        case .tier1, .tier2: return ("High", Theme.Palette.tier1)
        case .tier3:         return ("Mixed", Theme.Palette.tier3)
        case .tier4:         return ("Poor", Theme.Palette.tier4)
        }
    }

    private var clinicalNote: String {
        if anyAboveUL {
            return "One or more nutrients exceed the tolerable upper limit — review doses before use."
        }
        switch worstTier {
        case .tier4: return "Contains a poorly-bioavailable or synthetic form."
        case .tier3: return "Mostly well-formed, with at least one low-bioavailability nutrient."
        case .tier1, .tier2: return "Well-evidenced forms at clinically meaningful doses."
        case nil: return "No form-quality data is available for these entries."
        }
    }

    private func count(of tier: FormTier) -> Int { tiers.filter { $0 == tier }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            Text("Form Quality")
                .textStyle(.eyebrow)
                .foregroundStyle(.inkTertiary)

            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                Text(verdict.word)
                    .textStyle(.display)
                    .foregroundStyle(verdict.color)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                Text("across \(tiers.count) rated")
                    .textStyle(.subhead)
                    .foregroundStyle(.inkTertiary)
            }

            Text(clinicalNote)
                .textStyle(.callout)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !tiers.isEmpty {
                HairlineDivider()
                    .padding(.vertical, Theme.Space.xs)
                HStack(spacing: Theme.Space.lg) {
                    ForEach(FormTier.allCases, id: \.self) { tier in
                        tierCount(tier)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .dsCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Form quality \(verdict.word). \(clinicalNote)")
    }

    private func tierCount(_ tier: FormTier) -> some View {
        let c = count(of: tier)
        return HStack(spacing: Theme.Space.xs) {
            Circle()
                .fill(tier.badgeColor)
                .frame(width: 8, height: 8)
                .opacity(c > 0 ? 1 : 0.35)
            Text(tier.displayLabel)
                .textStyle(.caption)
                .foregroundStyle(.inkTertiary)
            Text("\(c)")
                .textStyle(.dataLabel)
                .foregroundStyle(c > 0 ? Color.ink : Color.inkFaint)
        }
    }
}
