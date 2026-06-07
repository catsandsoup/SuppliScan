// ReviewView.swift
// SuppliScan
// User confirms or corrects OCR output before analysis.
// The only place ServingSize is adjusted and entries are edited.

import SwiftUI

struct ReviewView: View {
    let entries: [LabelEntry]
    let extractedServing: ServingSize?

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
        }
        .onChange(of: viewModel.pendingAnalysis) { _, newValue in
            guard let analysis = viewModel.consumePendingAnalysis() else { return }
            successGenerator.notificationOccurred(.success)
            analysisStore.currentAnalysis = analysis
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
            Text("Analyse")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.hasConfirmedEntries)
        .opacity(viewModel.hasConfirmedEntries ? 1.0 : 0.4)
        .scaleEffect(viewModel.hasConfirmedEntries ? 1.0 : 0.97)
        .animation(.spring(response: 0.3), value: viewModel.hasConfirmedEntries)
        .accessibilityHint("Analyse the scanned label entries")
    }
}
