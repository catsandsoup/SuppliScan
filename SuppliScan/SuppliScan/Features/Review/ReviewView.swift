// ReviewView.swift
// SuppliScan
// User confirms or corrects OCR output before analysis.
// Analysis auto-triggers on appear. Edit button gives access to corrections.
// Navigation: pushes AnalysisView within the Scan stack (Option A — no tab switch).

import SwiftUI

struct ReviewView: View {
    let entries: [LabelEntry]
    let extractedServing: ServingSize?

    @Environment(AppDependencies.self) private var dependencies
    @Environment(NavigationRouter.self) private var router
    @Environment(AnalysisStore.self) private var analysisStore

    @State private var viewModel: ReviewViewModel
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var successGenerator = UINotificationFeedbackGenerator()

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
        .onAppear {
            impactGenerator.prepare()
            successGenerator.prepare()
            viewModel.configure(
                analyseAction: { entries, serving, standard, demographic in
                    try await dependencies.reportService.generateReport(
                        entries: entries,
                        servingSize: serving,
                        productName: nil,
                        standard: standard,
                        demographic: demographic
                    )
                },
                persistAction: { analysis, standard, demographic in
                    let name = analysis.productName.isEmpty ? "Supplement" : analysis.productName
                    try? await dependencies.persistence.save(
                        analysis: analysis,
                        productName: name,
                        standard: standard,
                        demographic: demographic
                    )
                }
            )
            viewModel.requestAnalysisIfNeeded()
        }
        .onChange(of: viewModel.pendingAnalysis) { _, _ in
            guard let analysis = viewModel.consumePendingAnalysis() else { return }
            successGenerator.notificationOccurred(.success)
            analysisStore.currentAnalysis = analysis
            router.navigate(to: .analysis(analysis))
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !viewModel.entries.isEmpty {
                    LabelRecognisedBannerView(standard: viewModel.selectedStandard)
                }

                SupplementFactsCardView(
                    entries: $viewModel.entries,
                    serving: viewModel.servingSize,
                    isEditing: viewModel.isEditing,
                    onDelete: viewModel.delete(at:)
                )
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            ServingSizeSelectorView(serving: $viewModel.servingSize)
            StandardPickerView(selection: $viewModel.selectedStandard)
            DemographicPickerView(selectedKey: $viewModel.selectedDemographicKey)
            analyseButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(Color(.systemBackground))
    }

    private var analyseButton: some View {
        Button {
            impactGenerator.impactOccurred()
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
        .controlSize(.large)
        .disabled(!viewModel.hasConfirmedEntries || viewModel.isAnalysing)
        .animation(.spring(response: 0.3), value: viewModel.isAnalysing)
        .accessibilityHint("Analyse the scanned label entries")
    }
}
