// HistoryView.swift
// SuppliScan
// Searchable list of past scans with swipe-to-delete.

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var records: [ScanRecord]

    @Environment(NavigationRouter.self) private var router
    @Environment(AppDependencies.self) private var dependencies

    @State private var viewModel = HistoryViewModel()
    @State private var searchText = ""
    @State private var deleteCount = 0

    private var filteredRecords: [ScanRecord] {
        searchText.isEmpty ? records
            : records.filter { $0.productName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Scans Yet",
                    systemImage: "camera.viewfinder",
                    description: Text("Scan a supplement label to get started.")
                )
            } else if filteredRecords.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    ForEach(filteredRecords) { record in
                        ScanHistoryRowView(
                            record: ScanRecordSummary(record: record),
                            isLoading: viewModel.loadingRecordID == record.id
                        ) {
                            viewModel.openRecord(id: record.id)
                        }
                    }
                    .onDelete { offsets in
                        deleteCount += 1
                        let idsToDelete = offsets.map { filteredRecords[$0].id }
                        Task {
                            for id in idsToDelete {
                                try? await dependencies.persistence.delete(id: id)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !records.isEmpty { EditButton() }
            }
        }
        .alert(
            "Couldn't Load Report",
            isPresented: $viewModel.isShowingLoadError
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The saved scan could not be opened.")
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: deleteCount)
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
