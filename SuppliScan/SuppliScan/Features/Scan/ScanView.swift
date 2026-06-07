// ScanView.swift
// SuppliScan

import PhotosUI
import SwiftUI

struct ScanView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(AppDependencies.self) private var dependencies

    @State private var viewModel = ScanViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScanPhotoImportView(selectedPhotoItem: $selectedPhotoItem)
                ScanStatusView(
                    loadingState: viewModel.loadingState,
                    reviewWarning: viewModel.reviewWarning
                )
                ScanRawTextEditorView(text: $viewModel.rawText)

                HStack(spacing: 12) {
                    Button("Parse Text", systemImage: "text.magnifyingglass") {
                        viewModel.parseEditedText()
                    }
                    .buttonStyle(.bordered)

                    Button("Review Entries", systemImage: "list.clipboard") {
                        viewModel.navigateToReview()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Scan Label")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(
                ocrService: dependencies.ocrService,
                parser: dependencies.parserService
            )
        }
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else { return }

            do {
                guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                    throw AppError.unknown(description: "Selected photo could not be loaded.")
                }
                viewModel.processPhotoData(data)
            } catch {
                viewModel.handlePhotoImportFailure(error)
            }
        }
        .onChange(of: viewModel.pendingDestination) {
            guard let destination = viewModel.consumePendingDestination() else { return }
            router.navigate(to: destination)
        }
        .alert(
            "Scan Failed",
            isPresented: $viewModel.isShowingError
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.loadingState.error?.errorDescription ?? "The label could not be scanned.")
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}
