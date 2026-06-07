// HistoryView.swift
// SuppliScan — STUB (full implementation in Views layer)
// Skills to invoke when implementing: swiftui-pro, swiftui-ui-patterns, ios-accessibility

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var records: [ScanRecord]

    @Environment(NavigationRouter.self) private var router
    @Environment(AppDependencies.self) private var dependencies

    @State private var viewModel = HistoryViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Scans Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Scans you save will appear here.")
                )
            } else {
                List(viewModel.summaries(from: records)) { record in
                    ScanHistoryRowView(
                        record: record,
                        isLoading: viewModel.loadingRecordID == record.id
                    ) {
                        viewModel.openRecord(id: record.id)
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .alert(
            "Couldn’t Load Report",
            isPresented: $viewModel.isShowingLoadError
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The saved scan could not be opened.")
        }
        .onAppear {
            viewModel.configure { [dependencies] id in
                try await dependencies.persistence.fetchAnalysis(id: id)
            }
        }
        .onChange(of: viewModel.pendingDestination) {
            guard let destination = viewModel.consumePendingDestination() else { return }
            router.navigate(to: destination)
        }
    }
}
