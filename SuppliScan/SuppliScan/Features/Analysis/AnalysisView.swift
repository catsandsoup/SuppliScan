// AnalysisView.swift
// SuppliScan
// Primary deliverable screen — renders a LabelAnalysis in full on the design system.
// Custom header + snapshot + segmented internal tabs (Summary/Nutrients/Details/Interactions).
// Disclaimer shown on every tab per clinical rules. Logic/navigation unchanged.

import SwiftUI

struct AnalysisView: View {
    let analysis: LabelAnalysis

    @Environment(NavigationRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activeTab: AnalysisTab = .nutrients
    @State private var ulWarningTriggered = false

    /// Bottom inset so scrolling content clears the floating glass tab bar.
    static let tabBarClearance: CGFloat = 96

    var body: some View {
        VStack(spacing: 0) {
            header
            ClinicalSnapshotView(analysis: analysis)
                .padding(.horizontal, Theme.Space.screen)
                .padding(.bottom, Theme.Space.md)
            internalTabBar
                .padding(.horizontal, Theme.Space.screen)
                .padding(.bottom, Theme.Space.sm)
            tabContent
        }
        .screenBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: analysis.shareText,
                    subject: Text(analysis.productName.isEmpty ? "SuppliScan Analysis" : analysis.productName)
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: Theme.Icon.md, weight: .semibold))
                        .foregroundStyle(.brand)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.warning, trigger: ulWarningTriggered)
        .sensoryFeedback(.selection, trigger: activeTab)
        .onAppear {
            if !analysis.flags.nutrientsAboveUL.isEmpty {
                ulWarningTriggered = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("Analysis")
                .textStyle(.eyebrow)
                .foregroundStyle(.brand)
            Text(analysis.displayTitle)
                .textStyle(.display)
                .foregroundStyle(.ink)
                .lineLimit(2)
            Text(metaLine)
                .textStyle(.subhead)
                .foregroundStyle(.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, Theme.Space.xs)
        .padding(.bottom, Theme.Space.lg)
    }

    private var metaLine: String {
        let qty = analysis.servingSize.selectedQuantity
        let unit = analysis.servingSize.unit.pluralised(for: qty)
        return "\(qty.formatted()) \(unit) · \(analysis.referenceStandard.rawValue) · \(analysis.demographic.displayName)"
    }

    // MARK: - Internal tab bar

    private var internalTabBar: some View {
        SegmentedPicker(options: visibleTabs, selection: $activeTab) { $0.rawValue }
    }

    private var visibleTabs: [AnalysisTab] {
        AnalysisTab.allCases.filter { tab in
            tab == .interactions ? analysis.flags.hasAnyInteractions : true
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
        .animation(reduceMotion ? nil : .dsPrimary, value: activeTab)
    }
}

// MARK: - AnalysisTab

enum AnalysisTab: String, CaseIterable, Identifiable, Hashable {
    case summary = "Summary"
    case nutrients = "Nutrients"
    case details = "Details"
    case interactions = "Interactions"

    var id: String { rawValue }
}

// MARK: - Clinical Snapshot

private struct ClinicalSnapshotView: View {
    let analysis: LabelAnalysis

    private var highestRDIAnalysis: NutrientAnalysis? {
        analysis.nutrientAnalyses
            .filter { $0.rdiPercent != nil }
            .max { ($0.rdiPercent ?? 0) < ($1.rdiPercent ?? 0) }
    }

    private var interactionCount: Int {
        analysis.flags.nutrientInteractions.count + analysis.flags.medicationInteractions.count
    }

    private var ulText: String {
        if !analysis.flags.nutrientsAboveUL.isEmpty { "Above UL" }
        else if !analysis.flags.nutrientsAtUL.isEmpty { "Near UL" }
        else { "Within UL" }
    }

    private var ulColor: Color {
        if !analysis.flags.nutrientsAboveUL.isEmpty { return Theme.Palette.tier4 }
        if !analysis.flags.nutrientsAtUL.isEmpty { return Theme.Palette.tier3 }
        return Theme.Palette.tier1
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.md) {
            SnapshotItem(
                title: "Peak RDI",
                value: highestRDIAnalysis?.rdiPercentString ?? "—",
                color: highestRDIAnalysis?.rdiColor ?? Theme.Palette.inkTertiary
            )
            snapshotDivider
            SnapshotItem(title: "Safety", value: ulText, color: ulColor)
            snapshotDivider
            SnapshotItem(
                title: "Interactions",
                value: interactionCount == 0 ? "None" : interactionCount.formatted(),
                color: interactionCount == 0 ? Theme.Palette.tier1 : Theme.Palette.tier3
            )
        }
        .padding(Theme.Space.lg)
        .dsSurface()
        .accessibilityElement(children: .combine)
    }

    private var snapshotDivider: some View {
        Rectangle()
            .fill(.hairline)
            .frame(width: 1, height: 34)
    }
}

private struct SnapshotItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(title)
                .textStyle(.eyebrow)
                .foregroundStyle(.inkTertiary)
            Text(value)
                .textStyle(.stat)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Summary Tab

private struct SummaryTabView: View {
    let analysis: LabelAnalysis
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Space.lg) {
                ReportSummaryCardView(analysis: analysis)
                    .modifier(EntranceModifier(appeared: appeared, index: 0, reduceMotion: reduceMotion))

                if analysis.flags.hasAnyFlags {
                    FlagBannerView(flags: analysis.flags)
                        .modifier(EntranceModifier(appeared: appeared, index: 1, reduceMotion: reduceMotion))
                }

                HStack(spacing: Theme.Space.xs) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.inkTertiary)
                        .font(.system(size: Theme.Icon.xs, weight: .semibold))
                    Text("Analysis based on \(analysis.servingSize.selectedQuantity.formatted()) \(analysis.servingSize.unit.pluralised(for: analysis.servingSize.selectedQuantity))")
                        .textStyle(.caption)
                        .foregroundStyle(.inkTertiary)
                }
                .modifier(EntranceModifier(appeared: appeared, index: 2, reduceMotion: reduceMotion))

                DisclaimerView(text: analysis.disclaimer)
                    .modifier(EntranceModifier(appeared: appeared, index: 3, reduceMotion: reduceMotion))
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.sm)
            .padding(.bottom, AnalysisView.tabBarClearance)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            if reduceMotion { appeared = true } else { withAnimation { appeared = true } }
        }
    }
}

/// Staggered fade+rise entrance.
private struct EntranceModifier: ViewModifier {
    let appeared: Bool
    let index: Int
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(reduceMotion ? nil : .dsGentle.delay(Double(index) * Theme.Motion.stagger), value: appeared)
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
                            Button {
                                rowTapCount += 1
                                router.navigate(to: .nutrientDetail(nutrientAnalysis))
                            } label: {
                                HStack(spacing: Theme.Space.sm) {
                                    NutrientAnalysisRowView(analysis: nutrientAnalysis, index: index)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: Theme.Icon.xs, weight: .semibold))
                                        .foregroundStyle(.inkFaint)
                                }
                                .padding(.horizontal, Theme.Space.lg)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Shows nutrient detail")

                            if nutrientAnalysis.id != filteredAnalyses.last?.id {
                                HairlineDivider(leadingInset: Theme.Space.lg)
                            }
                        }
                    }
                    .dsSurface()
                    .padding(.horizontal, Theme.Space.screen)

                    NutrientFootnoteView()
                        .padding(.horizontal, Theme.Space.screen)
                        .padding(.vertical, Theme.Space.lg)
                        .padding(.bottom, AnalysisView.tabBarClearance)
                }
                .scrollIndicators(.hidden)
                .sensoryFeedback(.selection, trigger: rowTapCount)
            }
        }
    }
}

// MARK: - Details Tab

private struct DetailsTabView: View {
    let analysis: LabelAnalysis
    let router: NavigationRouter
    @State private var rowTapCount = 0

    private var withFormQuality: [NutrientAnalysis] {
        analysis.nutrientAnalyses.filter { $0.formQuality != nil }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Space.lg) {
                if !withFormQuality.isEmpty {
                    ReportSectionHeader("Forms & Potency")

                    LazyVStack(spacing: 0) {
                        ForEach(withFormQuality) { nutrientAnalysis in
                            Button {
                                rowTapCount += 1
                                router.navigate(to: .nutrientDetail(nutrientAnalysis))
                            } label: {
                                HStack(spacing: Theme.Space.sm) {
                                    FormPotencyRowView(analysis: nutrientAnalysis)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: Theme.Icon.xs, weight: .semibold))
                                        .foregroundStyle(.inkFaint)
                                }
                                .padding(.horizontal, Theme.Space.lg)
                                .padding(.vertical, Theme.Space.sm)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Shows nutrient detail")

                            if nutrientAnalysis.id != withFormQuality.last?.id {
                                HairlineDivider(leadingInset: 64)
                            }
                        }
                    }
                    .dsSurface()

                    Text("Potency reflects absorption and bioavailability evidence from published research.")
                        .textStyle(.caption)
                        .foregroundStyle(.inkTertiary)
                }

                if analysis.hasHerbals {
                    ReportSectionHeader("Herbal Extracts")
                    VStack(alignment: .leading, spacing: Theme.Space.md) {
                        ForEach(analysis.herbalEntries, id: \.id) { HerbalRowView(entry: $0) }
                    }
                    .dsCard()
                }

                if analysis.hasProbiotics {
                    ReportSectionHeader("Probiotics")
                    VStack(alignment: .leading, spacing: Theme.Space.md) {
                        if let total = analysis.totalCFUBillions {
                            Text("\(total.formatted()) Billion CFU total")
                                .textStyle(.title)
                                .foregroundStyle(.ink)
                                .monospacedDigit()
                        }
                        ForEach(analysis.probioticEntries.filter { !$0.isTotalLine }, id: \.id) {
                            ProbioticRowView(entry: $0)
                        }
                        Text("No NRV reference values established for probiotic strains.")
                            .textStyle(.caption)
                            .foregroundStyle(.inkTertiary)
                    }
                    .dsCard()
                }

                if analysis.hasUnresolved {
                    ReportSectionHeader("Could Not Be Analysed")
                    VStack(alignment: .leading, spacing: Theme.Space.sm) {
                        ForEach(analysis.unresolvedLines, id: \.id) { UnresolvedLineView(line: $0) }
                    }
                }

                DisclaimerView(text: analysis.disclaimer)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.sm)
            .padding(.bottom, AnalysisView.tabBarClearance)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: rowTapCount)
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
            LazyVStack(alignment: .leading, spacing: Theme.Space.md) {
                if totalInteractionCount > 0 {
                    InteractionSectionHeader(
                        title: "Potential Interactions",
                        count: totalInteractionCount,
                        icon: "exclamationmark.triangle.fill",
                        color: Theme.Palette.tier3
                    )

                    ForEach(flags.nutrientInteractions) { interaction in
                        InteractionRowView(
                            participants: interaction.participants,
                            severity: interaction.severity,
                            effect: interaction.effect,
                            recommendation: interaction.recommendation
                        )
                    }

                    ForEach(flags.medicationInteractions) { interaction in
                        InteractionRowView(
                            participants: [interaction.nutrient, interaction.medicationClass],
                            severity: interaction.severity,
                            effect: interaction.effect,
                            recommendation: interaction.recommendation
                        )
                    }
                }

                if !noInteractionNutrients.isEmpty {
                    InteractionSectionHeader(
                        title: "No Known Interactions",
                        count: noInteractionNutrients.count,
                        icon: "checkmark.circle.fill",
                        color: Theme.Palette.tier1
                    )
                    .padding(.top, totalInteractionCount > 0 ? Theme.Space.sm : 0)

                    VStack(spacing: 0) {
                        ForEach(Array(noInteractionNutrients.enumerated()), id: \.element.id) { index, nutrient in
                            NoInteractionRowView(analysis: nutrient)
                                .padding(.horizontal, Theme.Space.lg)
                            if nutrient.id != noInteractionNutrients.last?.id {
                                HairlineDivider(leadingInset: 60)
                            }
                        }
                    }
                    .dsSurface()
                }

                DisclaimerView(
                    text: "Interactions listed are based on published clinical evidence. Individual responses vary. Always consult a healthcare professional before adjusting supplement or medication regimens."
                )
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.sm)
            .padding(.bottom, AnalysisView.tabBarClearance)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Interaction section header

private struct InteractionSectionHeader: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: Theme.Icon.sm, weight: .semibold))
            Text(title)
                .textStyle(.headline)
                .foregroundStyle(.ink)
            Spacer()
            Text("\(count)")
                .textStyle(.dataLabel)
                .foregroundStyle(color)
                .padding(.horizontal, Theme.Space.sm)
                .padding(.vertical, Theme.Space.xxs)
                .background(color.opacity(0.14), in: Capsule())
        }
    }
}

// MARK: - Interaction row

private struct InteractionRowView: View {
    let participants: [String]
    let severity: InteractionSeverity
    let effect: String
    let recommendation: String

    private var severityColor: Color {
        switch severity {
        case .low:      Theme.Palette.tier1
        case .moderate: Theme.Palette.tier3
        case .high:     Theme.Palette.tier4
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack(spacing: Theme.Space.sm) {
                participantAvatars
                Spacer()
                Text(severity.displayLabel)
                    .textStyle(.dataLabel)
                    .foregroundStyle(severityColor)
                    .padding(.horizontal, Theme.Space.sm)
                    .padding(.vertical, Theme.Space.xxs)
                    .background(severityColor.opacity(0.14), in: Capsule())
            }

            Text(effect)
                .textStyle(.subhead)
                .foregroundStyle(.ink)

            HStack(alignment: .top, spacing: Theme.Space.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: Theme.Icon.xs, weight: .semibold))
                    .foregroundStyle(Theme.Palette.tier2)
                Text(recommendation)
                    .textStyle(.caption)
                    .foregroundStyle(.inkSecondary)
            }
        }
        .dsCard()
    }

    @ViewBuilder
    private var participantAvatars: some View {
        HStack(spacing: -8) {
            ForEach(participants.prefix(3), id: \.self) { name in
                NutrientAvatarView(canonicalName: name, size: 32)
                    .overlay(Circle().strokeBorder(Theme.Palette.surfaceRaised, lineWidth: 2))
            }
        }
        Text(participants.joined(separator: " + "))
            .textStyle(.subhead)
            .foregroundStyle(.ink)
            .lineLimit(1)
            .padding(.leading, Theme.Space.xs)
    }
}

// MARK: - No-interaction row

private struct NoInteractionRowView: View {
    let analysis: NutrientAnalysis

    var body: some View {
        HStack(spacing: Theme.Space.md) {
            NutrientAvatarView(canonicalName: analysis.entry.canonicalName, size: 36)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(analysis.entry.displayName)
                    .textStyle(.subhead)
                    .foregroundStyle(.ink)
                Text("No known interactions")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Palette.tier1.opacity(0.7))
                .font(.system(size: Theme.Icon.sm, weight: .semibold))
        }
        .padding(.vertical, Theme.Space.md)
    }
}

// MARK: - Footnote

private struct NutrientFootnoteView: View {
    var body: some View {
        Text("RDI = Recommended Dietary Intake  ·  UL = Tolerable Upper Intake Level")
            .textStyle(.caption)
            .foregroundStyle(.inkTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
