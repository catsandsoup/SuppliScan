// NutrientDetailView.swift
// SuppliScan
// Deep-dive drill-down from the Nutrients tab.
// Shows RDI% KPI, dose scale, UL info, form quality assessment.
// No ADI row — no ADI data in v1 NRV JSONs.

import SwiftUI

struct NutrientDetailView: View {
    let analysis: NutrientAnalysis

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Nutrient heading
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.entry.displayName)
                        .font(.title2.bold())
                    if let form = analysis.entry.form {
                        Text("as \(form)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // RDI KPI — dominant number
                if let rdi = analysis.rdiPercent {
                    VStack(alignment: .leading, spacing: 4) {
                        Text((rdi / 100).formatted(.percent.precision(.fractionLength(0))))
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(analysis.rdiColor)
                            .contentTransition(.numericText())
                        Text("of Recommended Dietary Intake")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    RDIProgressBar(rdiPercent: rdi, appeared: appeared)
                }

                // Stats table
                NutrientStatTable(rows: statRows)

                // Form quality
                if let quality = analysis.formQuality {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Form Quality")
                            .font(.headline)
                        HStack {
                            Text(analysis.entry.form ?? "Unknown form")
                                .font(.body)
                            Spacer()
                            TierBadgeView(tier: quality.tier)
                        }
                        Text(quality.rationale)
                            .font(.body)
                            .foregroundStyle(.secondary)
                        if quality.isAIInferred {
                            AIInferredBadgeView()
                        }
                    }
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .navigationTitle(analysis.entry.canonicalName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.50, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }

    private var statRows: [NutrientStatTable.StatRow] {
        [
            .init(label: "Amount per serving", value: analysis.doseString),
            .init(label: "RDI", value: analysis.rdiReferenceString ?? "Not established"),
            .init(label: "% of RDI", value: analysis.rdiPercentString),
            .init(label: "UL", value: analysis.ulReferenceString ?? "Not established"),
            .init(label: "% of UL", value: analysis.ulPercentString ?? "—"),
        ]
    }
}

// MARK: - RDI Zone Progress Bar

private struct RDIProgressBar: View {
    let rdiPercent: Double
    let appeared: Bool

    // Scale: 0 – 150% RDI rendered across full width
    private let maxScale: Double = 150

    // Zone boundaries as fractions of maxScale
    private var greenEnd: Double  { 100 / maxScale }   // 0.667
    private var yellowEnd: Double { 125 / maxScale }   // 0.833
    private var rdiTick: Double   { 100 / maxScale }

    private var fillFraction: Double {
        appeared ? min(rdiPercent / maxScale, 1.0) : 0
    }

    private var fillColor: Color {
        if rdiPercent > 125 { return AppTheme.Color.critical }
        if rdiPercent > 100 { return AppTheme.Color.warning }
        return AppTheme.Color.success
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    // Zone background bands
                    HStack(spacing: 0) {
                        AppTheme.Color.success.opacity(0.10)
                            .frame(width: w * greenEnd)
                        AppTheme.Color.warning.opacity(0.10)
                            .frame(width: w * (yellowEnd - greenEnd))
                        AppTheme.Color.critical.opacity(0.10)
                            .frame(width: w * (1 - yellowEnd))
                    }
                    .clipShape(Capsule())
                    .frame(height: 8)

                    // Animated fill
                    Capsule()
                        .fill(fillColor)
                        .frame(width: w * fillFraction, height: 8)
                        .animation(.spring(response: 0.70, dampingFraction: 0.75), value: fillFraction)

                    // 100% RDI tick mark
                    Rectangle()
                        .fill(.background)
                        .frame(width: 2, height: 14)
                        .offset(x: w * rdiTick - 1)
                }
            }
            .frame(height: 14)

            // Zone labels — positioned absolutely so "RDI" aligns with the tick
            GeometryReader { labelGeo in
                let w = labelGeo.size.width
                ZStack(alignment: .topLeading) {
                    Text("0")
                        .position(x: 4, y: 7)
                    Text("RDI")
                        .position(x: w * rdiTick, y: 7)
                    Text("150%")
                        .position(x: w - 10, y: 7)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .frame(height: 14)
        }
    }
}
