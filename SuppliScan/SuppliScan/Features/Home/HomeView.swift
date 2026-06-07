// HomeView.swift
// SuppliScan
//
// Entry point. Single primary action (Scan).
// Recent scans list for immediate re-access.
// Settings via sheet — never pushed.
//
// HIG: large tap target on primary action, recent context without
// requiring navigation to History. No hero imagery, no marketing copy.

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(AppDependencies.self) private var dependencies
    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var recentRecords: [ScanRecord]

    @State private var viewModel = HomeViewModel()
    @State private var showSettings = false

    var body: some View {
        @Bindable var router = router
        @Bindable var viewModel = viewModel

        NavigationStack(path: $router.path) {
            ScrollView {
                let recentSummaries = viewModel.recentRecords(from: recentRecords)

                VStack(spacing: 24) {
                    HomeScanActionsView(
                        scan: startScan,
                        enterManually: enterManually
                    )

                    if recentSummaries.isEmpty {
                        HomeEmptyStateView()
                    } else {
                        HomeRecentScansSectionView(
                            records: recentSummaries,
                            loadingRecordID: viewModel.loadingRecordID,
                            open: viewModel.openRecord(id:),
                            seeAll: showHistory
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            .navigationTitle("SuppliScan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        showSettings = true
                    }
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                AppDestinationView(destination: destination)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
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

    // MARK: - Actions

    private func startScan() {
        router.navigate(to: .scan)
    }

    private func enterManually() {
        router.navigate(to: .review(entries: [], serving: nil))
    }

    private func showHistory() {
        router.navigate(to: .history)
    }

}
