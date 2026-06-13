// HomeView.swift
// SuppliScan
//
// Front door. Editorial headline, hero scan action, and recent reports (or a first-run
// empty state). Hosted by RootTabView's home NavigationStack — the report is a pushed
// destination, never a standing screen. Logic (router, @Query, viewModel) unchanged.

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(AppDependencies.self) private var dependencies
    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var recentRecords: [ScanRecord]

    @State private var viewModel = HomeViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            let recentSummaries = viewModel.recentRecords(from: recentRecords)

            VStack(alignment: .leading, spacing: Theme.Space.section) {
                header

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
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.sm)
            .padding(.bottom, 110) // clear the floating tab bar
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .alert(
            "Couldn’t Load Report",
            isPresented: $viewModel.isShowingLoadError
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The saved report could not be opened.")
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

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text("SuppliScan")
                .textStyle(.eyebrow)
                .foregroundStyle(.brand)
            Text("Know exactly\nwhat's inside.")
                .textStyle(.display)
                .foregroundStyle(.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Space.sm)
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
