// NutrientAnalysisRowView.swift
// SuppliScan
// Nutrient row: name + form + dose on the left, large monospaced RDI% on the right,
// a token progress bar, and UL context. Restyled to the design system.

import SwiftUI

struct NutrientAnalysisRowView: View {
    let analysis: NutrientAnalysis
    let index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var rdiPercent: Double { analysis.rdiPercent ?? 0 }
    private var rdiColor: Color { analysis.rdiColor }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack(alignment: .top, spacing: Theme.Space.md) {
                nutrientInfo
                Spacer(minLength: Theme.Space.sm)
                rdiDisplay
            }
            progressBar
            ulCaption
        }
        .padding(.vertical, Theme.Space.md)
        .contentShape(.rect)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            let delay = Double(min(index, 8)) * Theme.Motion.stagger
            withAnimation(.dsGentle.delay(delay)) { appeared = true }
        }
    }

    private var nutrientInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text(analysis.entry.displayName)
                .textStyle(.headline)
                .foregroundStyle(.ink)
            if let form = analysis.entry.form {
                Text("as \(form)")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
            }
            Text(analysis.doseString)
                .textStyle(.caption)
                .foregroundStyle(.inkSecondary)
                .monospacedDigit()
        }
    }

    private var rdiDisplay: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if analysis.rdiPercent != nil {
                Text(analysis.rdiPercentString)
                    .textStyle(.stat)
                    .foregroundStyle(rdiColor)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                Text("of RDI")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
            } else {
                Text("—")
                    .textStyle(.stat)
                    .foregroundStyle(.inkTertiary)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(rdiColor.opacity(0.14))
                    .frame(height: 6)
                Capsule()
                    .fill(rdiColor)
                    .frame(
                        width: appeared ? geo.size.width * min(rdiPercent / 100.0, 1.0) : 0,
                        height: 6
                    )
                    .animation(
                        reduceMotion ? nil : .dsGentle.delay(Double(min(index, 8)) * Theme.Motion.stagger),
                        value: appeared
                    )
            }
        }
        .frame(height: 6)
    }

    @ViewBuilder
    private var ulCaption: some View {
        if let ulStr = analysis.ulPercentString, let ulRef = analysis.ulReferenceString {
            Text("UL \(ulRef) · \(ulStr) of upper limit")
                .textStyle(.caption)
                .foregroundStyle(.inkTertiary)
                .monospacedDigit()
        } else if let ulStr = analysis.ulPercentString {
            Text("\(ulStr) of upper limit")
                .textStyle(.caption)
                .foregroundStyle(.inkTertiary)
                .monospacedDigit()
        } else if let quality = analysis.formQuality {
            TierBadgeView(tier: quality.tier)
        }
    }
}
