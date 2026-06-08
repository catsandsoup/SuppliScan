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

                    ProgressView(value: appeared ? min(rdi / 100.0, 1.5) / 1.5 : 0)
                        .tint(analysis.rdiColor)
                        .animation(.easeOut(duration: 0.6), value: appeared)
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
            withAnimation {
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
