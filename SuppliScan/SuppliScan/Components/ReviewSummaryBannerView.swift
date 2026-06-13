// ReviewSummaryBannerView.swift
// SuppliScan
// Orientation banner at the top of ReviewView: tells the user at a glance how the OCR
// extraction broke down — how many items are ready, how many need a look, how much was
// non-nutrient label text — before they read the facts card. Replaces the older
// "Label recognised" banner with something that actually summarises the result.

import SwiftUI

struct ReviewSummaryBannerView: View {
    let entries: [LabelEntry]
    let standard: ReferenceStandard

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    private var presentations: [ReviewEntryPresentation] {
        ReviewEntryClassifier.presentations(for: entries)
    }
    private var readyCount: Int { presentations.filter { $0.status == .confirmed }.count }
    private var reviewCount: Int { presentations.filter { $0.status == .needsReview }.count }
    private var ignoredCount: Int { presentations.filter { $0.status == .otherLabelText }.count }
    private var recognisedCount: Int { readyCount + reviewCount }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack(spacing: Theme.Space.md) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: Theme.Icon.md, weight: .semibold))
                    .foregroundStyle(.brand)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recognisedCount == 1 ? "1 item recognised" : "\(recognisedCount) items recognised")
                        .textStyle(.subhead)
                        .foregroundStyle(.ink)
                    Text("\(standard.rawValue) reference standard")
                        .textStyle(.caption)
                        .foregroundStyle(.inkTertiary)
                }
                Spacer(minLength: 0)
            }

            if !pills.isEmpty {
                HStack(spacing: Theme.Space.sm) {
                    ForEach(pills, id: \.label) { pill in
                        CountPill(count: pill.count, label: pill.label, color: pill.color, icon: pill.icon)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .dsCard()
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            guard !reduceMotion else { isVisible = true; return }
            withAnimation(.dsGentle) { isVisible = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private struct Pill { let count: Int; let label: String; let color: Color; let icon: String }

    private var pills: [Pill] {
        var result: [Pill] = []
        if readyCount > 0 {
            result.append(Pill(count: readyCount, label: "ready", color: Theme.Palette.tier1, icon: "checkmark.circle.fill"))
        }
        if reviewCount > 0 {
            result.append(Pill(count: reviewCount, label: "to review", color: Theme.Palette.tier3, icon: "questionmark.circle.fill"))
        }
        if ignoredCount > 0 {
            result.append(Pill(count: ignoredCount, label: "other text", color: Theme.Palette.inkTertiary, icon: "text.quote"))
        }
        return result
    }

    private var accessibilitySummary: String {
        var parts = ["\(recognisedCount) items recognised"]
        if reviewCount > 0 { parts.append("\(reviewCount) need review") }
        if ignoredCount > 0 { parts.append("\(ignoredCount) other label text") }
        return parts.joined(separator: ", ")
    }
}

private struct CountPill: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            Image(systemName: icon)
                .font(.system(size: Theme.Icon.xs, weight: .semibold))
            Text("\(count)")
                .textStyle(.dataLabel)
            Text(label)
                .textStyle(.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, Theme.Space.sm)
        .padding(.vertical, Theme.Space.xs)
        .background(color.opacity(0.12), in: Capsule())
    }
}
