// FormsAndPotencyView.swift
// SuppliScan
// Standalone list of NutrientAnalyses with curated form-quality data, ranked best → worst.
// Carded design-system scroll (not a system List).

import SwiftUI

struct FormsAndPotencyView: View {
    let analyses: [NutrientAnalysis]

    @Environment(NavigationRouter.self) private var router
    @State private var rowTapCount = 0

    /// Only nutrients with curated form quality, best (Tier 1) first.
    private var ranked: [NutrientAnalysis] {
        analyses
            .filter { $0.formQuality != nil }
            .sorted { ($0.formQuality?.tier ?? .tier4) < ($1.formQuality?.tier ?? .tier4) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                if ranked.isEmpty {
                    ContentUnavailableView(
                        "No Form Data",
                        systemImage: "questionmark.text.page",
                        description: Text("None of the scanned entries have curated bioavailability data.")
                    )
                    .padding(.top, Theme.Space.xxxl)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(ranked) { analysis in
                            Button {
                                rowTapCount += 1
                                router.navigate(to: .nutrientDetail(analysis))
                            } label: {
                                HStack(spacing: Theme.Space.sm) {
                                    FormPotencyRowView(analysis: analysis)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: Theme.Icon.xs, weight: .semibold))
                                        .foregroundStyle(.inkFaint)
                                }
                                .padding(.horizontal, Theme.Space.lg)
                                .padding(.vertical, Theme.Space.xs)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Shows nutrient detail")

                            if analysis.id != ranked.last?.id {
                                HairlineDivider(leadingInset: 64)
                            }
                        }
                    }
                    .dsSurface()

                    Text("Potency reflects absorption and bioavailability evidence from published research. It does not account for individual needs — always consult a healthcare professional.")
                        .textStyle(.caption)
                        .foregroundStyle(.inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.md)
            .padding(.bottom, Theme.Space.xxl)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .navigationTitle("Forms & Potency")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: rowTapCount)
    }
}
