// AnalysisView.swift
// SuppliScan
// Primary deliverable screen — renders a LabelAnalysis in full.
// Four internal tabs: Summary, Nutrients, Details, Interactions.
// Disclaimer shown on every tab per clinical rules.

import SwiftUI

struct AnalysisView: View {
    let analysis: LabelAnalysis

    @Environment(NavigationRouter.self) private var router
    @State private var activeTab: AnalysisTab = .summary
    @State private var ulWarningTriggered = false

    var body: some View {
        VStack(spacing: 0) {
            productHeader
            internalTabBar
            tabContent
        }
        .navigationTitle(analysis.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: analysis.shareText,
                    subject: Text(analysis.productName.isEmpty ? "SuppliScan Analysis" : analysis.productName)
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sensoryFeedback(.warning, trigger: ulWarningTriggered)
        .sensoryFeedback(.selection, trigger: activeTab)
        .onAppear {
            if !analysis.flags.nutrientsAboveUL.isEmpty {
                ulWarningTriggered = true
            }
        }
    }

    // MARK: - Product header

    private var productHeader: some View {
        Text("\(analysis.servingSize.selectedQuantity.formatted()) \(analysis.servingSize.unit.pluralised(for: analysis.servingSize.selectedQuantity)) · \(analysis.referenceStandard.rawValue) · \(analysis.demographic.displayName)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }

    // MARK: - Internal tab bar

    @ViewBuilder
    private var internalTabBar: some View {
        Picker("Analysis Section", selection: $activeTab) {
            ForEach(visibleTabs) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        Divider()
    }

    private var visibleTabs: [AnalysisTab] {
        AnalysisTab.allCases.filter { tab in
            if tab == .interactions {
                return analysis.flags.hasAnyInteractions
            }
            return true
        }
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
            InteractionsTabView(analysis: analysis)
                .tag(AnalysisTab.interactions)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.22), value: activeTab)
    }
}

// MARK: - AnalysisTab

enum AnalysisTab: String, CaseIterable, Identifiable {
    case summary = "Summary"
    case nutrients = "Nutrients"
    case details = "Details"
    case interactions = "Interactions"

    var id: String { rawValue }
}

// MARK: - Summary Tab

private struct SummaryTabView: View {
    let analysis: LabelAnalysis
    @State private var appeared = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ReportSummaryCardView(analysis: analysis)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.40, dampingFraction: 0.80), value: appeared)

                if analysis.flags.hasAnyFlags {
                    FlagBannerView(flags: analysis.flags)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(response: 0.40, dampingFraction: 0.80).delay(0.07), value: appeared)
                }

                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("Analysis based on \(analysis.servingSize.selectedQuantity.formatted()) \(analysis.servingSize.unit.pluralised(for: analysis.servingSize.selectedQuantity))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.40, dampingFraction: 0.80).delay(0.14), value: appeared)

                DisclaimerView(text: analysis.disclaimer)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.20), value: appeared)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

// MARK: - Nutrients Tab

private struct NutrientsTabView: View {
    let analysis: LabelAnalysis
    let router: NavigationRouter

    @State private var filter: NutrientCategory = .all
    @State private var rowTapCount = 0

    private var filteredAnalyses: [NutrientAnalysis] {
        analysis.nutrientAnalyses.filter { filter.matches($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            NutrientFilterBar(selection: $filter)
            Divider()

            if analysis.nutrientAnalyses.isEmpty {
                ContentUnavailableView(
                    "No Nutrients Found",
                    systemImage: "text.badge.xmark",
                    description: Text("No nutrients were identified in this label.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredAnalyses.enumerated()), id: \.element.id) { index, nutrientAnalysis in
                            NutrientAnalysisRowView(analysis: nutrientAnalysis, index: index)
                                .padding(.horizontal, 16)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    rowTapCount += 1
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
                .sensoryFeedback(.selection, trigger: rowTapCount)
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

                if analysis.hasHerbals {
                    ReportSectionHeader("Herbal Extracts")
                    ForEach(analysis.herbalEntries, id: \.id) { HerbalRowView(entry: $0) }
                }

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

// MARK: - Interactions Tab

private struct InteractionsTabView: View {
    let analysis: LabelAnalysis

    private var flags: ReportFlags { analysis.flags }

    private var interactingNames: Set<String> {
        Set(flags.nutrientInteractions.flatMap { $0.participants })
    }

    private var noInteractionNutrients: [NutrientAnalysis] {
        analysis.nutrientAnalyses.filter { !interactingNames.contains($0.entry.canonicalName) }
    }

    private var totalInteractionCount: Int {
        flags.nutrientInteractions.count + flags.medicationInteractions.count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {

                // Found interactions
                if totalInteractionCount > 0 {
                    InteractionSectionHeader(
                        title: "Potential Interactions Found",
                        count: totalInteractionCount,
                        icon: "exclamationmark.triangle.fill",
                        color: AppTheme.Color.warning
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    ForEach(flags.nutrientInteractions) { interaction in
                        InteractionRowView(
                            participants: interaction.participants,
                            severity: interaction.severity,
                            effect: interaction.effect,
                            recommendation: interaction.recommendation
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }

                    ForEach(flags.medicationInteractions) { interaction in
                        InteractionRowView(
                            participants: [interaction.nutrient, interaction.medicationClass],
                            severity: interaction.severity,
                            effect: interaction.effect,
                            recommendation: interaction.recommendation
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }
                }

                // No-interaction nutrients
                if !noInteractionNutrients.isEmpty {
                    InteractionSectionHeader(
                        title: "No Known Interactions",
                        count: noInteractionNutrients.count,
                        icon: "checkmark.circle.fill",
                        color: AppTheme.Color.success
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, totalInteractionCount > 0 ? 16 : 16)
                    .padding(.bottom, 8)

                    ForEach(noInteractionNutrients) { nutrient in
                        NoInteractionRowView(analysis: nutrient)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                }

                DisclaimerView(
                    text: "Interactions listed are based on published clinical evidence. Individual responses vary. Always consult a healthcare professional before adjusting supplement or medication regimens."
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Interaction section header

private struct InteractionSectionHeader: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.subheadline)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(color, in: Capsule())
        }
    }
}

// MARK: - Interaction row (with participant avatars)

private struct InteractionRowView: View {
    let participants: [String]
    let severity: InteractionSeverity
    let effect: String
    let recommendation: String

    private var severityColor: Color {
        switch severity {
        case .low:      AppTheme.Color.success
        case .moderate: AppTheme.Color.warning
        case .high:     AppTheme.Color.critical
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                participantAvatars
                Spacer()
                Text(severity.displayLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(severityColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.12), in: Capsule())
            }

            Text(effect)
                .font(.subheadline)
                .foregroundStyle(.primary)

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text(recommendation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var participantAvatars: some View {
        HStack(spacing: -8) {
            ForEach(participants.prefix(3), id: \.self) { name in
                NutrientAvatarView(canonicalName: name, size: 32)
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
            }
        }
        if participants.count > 1 {
            Image(systemName: "plus")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.leading, 12)
        }
        Text(participants.joined(separator: " + "))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
    }
}

// MARK: - No-interaction row

private struct NoInteractionRowView: View {
    let analysis: NutrientAnalysis

    var body: some View {
        HStack(spacing: 12) {
            NutrientAvatarView(canonicalName: analysis.entry.canonicalName, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.entry.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text("No known interactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.Color.success.opacity(0.70))
                .font(.subheadline)
        }
        .padding(.vertical, 4)
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
