// ReviewView.swift
// SuppliScan
// User confirms or corrects OCR output before analysis.
// Analysis triggers on tap. Edit button gives access to corrections.
// Navigation: pushes AnalysisView within the Scan stack (back button returns to ReviewView).

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
            Divider()
            bottomBar
        }
        .navigationTitle("Review Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.isEditing ? "Done" : "Edit") {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.isEditing.toggle()
                    }
                }
                .accessibilityHint(viewModel.isEditing ? "Exit edit mode" : "Enter edit mode to modify entries")
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: analyseButtonTapped)
        .sensoryFeedback(.success, trigger: analysisSucceeded)
        .onAppear {
            guard let dependencies else {
                print("[SuppliScan] DIAGNOSTIC: ReviewView AppDependencies missing from environment")
                return
            }
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
            VStack(spacing: 16) {
                productNameField

                if !viewModel.entries.isEmpty {
                    LabelRecognisedBannerView(standard: viewModel.selectedStandard)
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
            .padding(.vertical, 16)
        }
    }

    private var productNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Product Name")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("e.g. Magnesium Glycinate 400mg", text: $viewModel.productName)
                .font(.subheadline)
                .submitLabel(.done)
                .autocorrectionDisabled()
            if viewModel.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Will save as \(viewModel.suggestedProductName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            ServingSizeSelectorView(serving: $viewModel.servingSize)
            StandardPickerView(selection: $viewModel.selectedStandard)
            DemographicPickerView(selectedKey: $viewModel.selectedDemographicKey)
            if viewModel.blockingReviewCount > 0 {
                Label("\(viewModel.blockingReviewCount) row\(viewModel.blockingReviewCount == 1 ? "" : "s") need review", systemImage: "questionmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Color.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            analyseButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(Color(.systemBackground))
    }

    private var analyseButton: some View {
        Button {
            analyseButtonTapped.toggle()
            viewModel.requestAnalysis()
        } label: {
            if viewModel.isAnalysing {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("Analysing…")
                }
                .frame(maxWidth: .infinity)
            } else {
                Text(viewModel.pendingAnalysis == nil ? "Analyse" : "Re-Analyse")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.extraLarge)
        .disabled(!viewModel.hasConfirmedEntries || viewModel.isAnalysing)
        .animation(reduceMotion ? nil : .spring(response: 0.3), value: viewModel.isAnalysing)
        .accessibilityHint("Analyse the scanned label entries")
    }
}
