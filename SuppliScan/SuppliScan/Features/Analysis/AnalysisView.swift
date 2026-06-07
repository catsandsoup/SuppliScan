// AnalysisView.swift
// SuppliScan
// Primary deliverable screen — renders a LabelAnalysis in full.
// Three internal tabs: Summary, Nutrients, Details.
// Disclaimer shown on every tab per clinical rules.

import SwiftUI

struct AnalysisView: View {
    let analysis: LabelAnalysis

    @Environment(NavigationRouter.self) private var router
    @State private var activeTab: AnalysisTab = .summary
    @State private var warningGenerator = UINotificationFeedbackGenerator()

    var body: some View {
        VStack(spacing: 0) {
            productHeader
            internalTabBar
            tabContent
        }
        .navigationTitle(analysis.productName.isEmpty ? "Analysis" : analysis.productName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Share", systemImage: "square.and.arrow.up") { }
                    .disabled(true) // Re-enable when ExportService is wired
            }
        }
        .onAppear {
            warningGenerator.prepare()
            if !analysis.flags.nutrientsAboveUL.isEmpty {
                warningGenerator.notificationOccurred(.warning)
            }
        }
    }

    // MARK: - Product header

    private var productHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(analysis.productName.isEmpty ? "Supplement Analysis" : analysis.productName)
                .font(.headline)
                .lineLimit(1)
            Text("Analysis for \(analysis.servingSize.selectedQuantity.formatted()) \(analysis.servingSize.unit.pluralised(for: analysis.servingSize.selectedQuantity)) · \(analysis.referenceStandard.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Internal tab bar

    @ViewBuilder
    private var internalTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AnalysisTab.allCases) { tab in
                    FilterChip(
                        label: tab.rawValue,
                        isSelected: activeTab == tab
                    ) {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring(response: 0.3)) {
                            activeTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        Divider()
    }

    // MARK: - Tab content

    private var tabContent: some View {
        TabView(selection: $activeTab) {
            SummaryTabView(analysis: analysis)
                .tag(AnalysisTab.summary)
            NutrientsTabView(analysis: analysis, router: router)
                .tag(AnalysisTab.nutrients)
            DetailsTabView(analysis: analysis, router: router)
                .tag(AnalysisTab.details)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

// MARK: - AnalysisTab

enum AnalysisTab: String, CaseIterable, Identifiable {
    case summary = "Summary"
    case nutrients = "Nutrients"
    case details = "Details"

    var id: String { rawValue }
}

// MARK: - Summary Tab

private struct SummaryTabView: View {
    let analysis: LabelAnalysis

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if analysis.nutrientAnalyses.isEmpty {
                    ContentUnavailableView(
                        "Nutrient Analysis Pending",
                        systemImage: "arrow.clockwise",
                        description: Text("Analysis will appear here once the report service is connected.")
                    )
                    .padding(.top, 40)
                } else {
                    ReportSummaryCardView(analysis: analysis)
                }

                if analysis.flags.hasAnyFlags {
                    FlagBannerView(flags: analysis.flags)
                }

                // Serving context
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("Analysis based on \(analysis.servingSize.selectedQuantity.formatted()) \(analysis.servingSize.unit.pluralised(for: analysis.servingSize.selectedQuantity))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                DisclaimerView(text: analysis.disclaimer)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Nutrients Tab

private struct NutrientsTabView: View {
    let analysis: LabelAnalysis
    let router: NavigationRouter

    @State private var filter: NutrientCategory = .all

    private var filteredAnalyses: [NutrientAnalysis] {
        analysis.nutrientAnalyses.filter { filter.matches($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            NutrientFilterBar(selection: $filter)
            Divider()

            if analysis.nutrientAnalyses.isEmpty {
                ContentUnavailableView(
                    "Nutrient Analysis Pending",
                    systemImage: "arrow.clockwise",
                    description: Text("Analysis will appear here once the report service is connected.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredAnalyses.enumerated()), id: \.element.id) { index, nutrientAnalysis in
                            NutrientAnalysisRowView(analysis: nutrientAnalysis, index: index)
                                .padding(.horizontal, 16)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    router.navigate(to: .nutrientDetail(nutrientAnalysis))
                                }
                            Divider()
                                .padding(.leading, 16)
                        }

                        NutrientFootnoteView()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                }
            }
        }
    }
}

// MARK: - Details Tab

private struct DetailsTabView: View {
    let analysis: LabelAnalysis
    let router: NavigationRouter

    private var withFormQuality: [NutrientAnalysis] {
        analysis.nutrientAnalyses.filter { $0.formQuality != nil }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Forms & Potency link
                if !withFormQuality.isEmpty {
                    Button {
                        router.navigate(to: .formsAndPotency(withFormQuality))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Forms & Potency")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(withFormQuality.count) nutrient\(withFormQuality.count == 1 ? "" : "s") assessed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                // Herbal section
                if analysis.hasHerbals {
                    ReportSectionHeader("Herbal Extracts")
                    ForEach(analysis.herbalEntries, id: \.id) { HerbalRowView(entry: $0) }
                }

                // Probiotic section
                if analysis.hasProbiotics {
                    ReportSectionHeader("Probiotics")
                    if let total = analysis.totalCFUBillions {
                        Text("\(total.formatted()) Billion CFU total")
                            .font(.title2.bold())
                    }
                    ForEach(analysis.probioticEntries.filter { !$0.isTotalLine }, id: \.id) {
                        ProbioticRowView(entry: $0)
                    }
                    Text("No NRV reference values established for probiotic strains.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Unresolved section
                if analysis.hasUnresolved {
                    ReportSectionHeader("Could Not Be Analysed")
                    ForEach(analysis.unresolvedLines, id: \.id) { UnresolvedLineView(line: $0) }
                }

                DisclaimerView(text: analysis.disclaimer)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Footnote

private struct NutrientFootnoteView: View {
    var body: some View {
        Text("RDI = Recommended Dietary Intake  ·  UL = Tolerable Upper Intake Level")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
