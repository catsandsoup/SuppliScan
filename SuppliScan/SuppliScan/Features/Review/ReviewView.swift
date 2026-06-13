// ReviewView.swift
// SuppliScan
// User confirms or corrects OCR output before analysis. Design-system styled.
// Pushed within the Scan stack; pushes AnalysisView on analyse. All ViewModel
// wiring, edit mode, feedback, and navigation preserved.

import SwiftUI

struct ReviewView: View {
    let entries: [LabelEntry]
    let extractedServing: ServingSize?

    @Environment(AppDependencies.self) private var dependencies: AppDependencies?
    @Environment(NavigationRouter.self) private var router

    @State private var viewModel: ReviewViewModel
    @State private var analyseButtonTapped = false
    @State private var analysisSucceeded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(entries: [LabelEntry], extractedServing: ServingSize?) {
        self.entries = entries
        self.extractedServing = extractedServing
        _viewModel = State(initialValue: ReviewViewModel(entries: entries, extractedServing: extractedServing))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            scrollContent
            bottomBar
        }
        .background(Theme.Palette.surface.ignoresSafeArea())
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.Palette.brand)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.isEditing ? "Done" : "Edit") {
                    withAnimation(.dsSnappy) {
                        viewModel.isEditing.toggle()
                    }
                }
                .accessibilityHint(viewModel.isEditing ? "Exit edit mode" : "Enter edit mode to modify entries")
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: analyseButtonTapped)
        .sensoryFeedback(.success, trigger: analysisSucceeded)
        .onAppear {
            guard let dependencies else { return }
            viewModel.configure(
                analyseAction: { entries, serving, standard, demographic, productName in
                    try await dependencies.reportService.generateReport(
                        entries: entries,
                        servingSize: serving,
                        productName: productName.isEmpty ? nil : productName,
                        standard: standard,
                        demographic: demographic
                    )
                },
                persistAction: { analysis, standard, demographic in
                    try? await dependencies.persistence.save(
                        analysis: analysis,
                        productName: analysis.productName,
                        standard: standard,
                        demographic: demographic
                    )
                }
            )
        }
        .onChange(of: viewModel.pendingAnalysis) { _, _ in
            guard let analysis = viewModel.consumePendingAnalysis() else { return }
            analysisSucceeded = true
            router.navigate(to: .analysis(analysis))
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: Theme.Space.lg) {
                productNameField

                if !viewModel.entries.isEmpty {
                    ReviewSummaryBannerView(entries: viewModel.entries, standard: viewModel.selectedStandard)
                        .padding(.horizontal, Theme.Space.screen)
                }

                SupplementFactsCardView(
                    entries: $viewModel.entries,
                    serving: viewModel.servingSize,
                    isEditing: viewModel.isEditing,
                    selectedEntryID: $viewModel.selectedEntryID,
                    onConfirm: viewModel.confirm(entryID:),
                    onDelete: viewModel.delete(entryID:)
                )
            }
            .padding(.top, Theme.Space.md)
            .padding(.bottom, Theme.Space.lg)
        }
        .scrollIndicators(.hidden)
    }

    private var productNameField: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text("Product name")
                .textStyle(.eyebrow)
                .foregroundStyle(.inkTertiary)
            TextField("e.g. Magnesium Glycinate 400mg", text: $viewModel.productName)
                .textFieldStyle(.ds)
                .submitLabel(.done)
                .autocorrectionDisabled()
            if viewModel.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Will save as \(viewModel.suggestedProductName)")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
            }
        }
        .padding(.horizontal, Theme.Space.screen)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: Theme.Space.md) {
            ServingSizeSelectorView(serving: $viewModel.servingSize)
            StandardPickerView(selection: $viewModel.selectedStandard)
            HStack {
                Text("Profile")
                    .textStyle(.subhead)
                    .foregroundStyle(.inkSecondary)
                Spacer(minLength: Theme.Space.md)
                DemographicPickerView(selectedKey: $viewModel.selectedDemographicKey)
            }
            if viewModel.blockingReviewCount > 0 {
                Label(
                    viewModel.blockingReviewCount == 1 ? "1 row needs review" : "\(viewModel.blockingReviewCount) rows need review",
                    systemImage: "questionmark.circle.fill"
                )
                .textStyle(.caption)
                .foregroundStyle(Theme.Palette.tier3)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            analyseButton
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, Theme.Space.lg)
        .padding(.bottom, Theme.Space.lg)
        .background(
            Theme.Palette.surfaceRaised
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) { HairlineDivider() }
        )
    }

    private var analyseButton: some View {
        Button {
            analyseButtonTapped.toggle()
            viewModel.requestAnalysis()
        } label: {
            DSLoadingLabel(
                title: viewModel.pendingAnalysis == nil ? "Analyse" : "Re-analyse",
                isLoading: viewModel.isAnalysing
            )
        }
        .buttonStyle(.dsPrimary)
        .disabled(!viewModel.hasConfirmedEntries || viewModel.isAnalysing)
        .animation(reduceMotion ? nil : .dsSnappy, value: viewModel.isAnalysing)
        .accessibilityHint("Analyse the scanned label entries")
    }
}
