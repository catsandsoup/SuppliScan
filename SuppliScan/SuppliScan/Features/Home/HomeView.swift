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
import OSLog

struct HomeView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(AppDependencies.self) private var dependencies
    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var recentRecords: [ScanRecord]

    @State private var showSettings = false

    private var recentThree: [ScanRecord] {
        Array(recentRecords.prefix(3))
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ScrollView {
                VStack(spacing: 24) {
                    scanButton
                    if !recentThree.isEmpty {
                        recentScansSection
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
                destinationView(for: destination)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        VStack(spacing: 12) {
            Button("Scan Label", systemImage: "camera.viewfinder") {
                router.navigate(to: .scan)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)

            Button("Enter Manually") {
                router.navigate(to: .review(entries: [], serving: nil))
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Recent Scans

    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Scans")
                    .font(.headline)
                Spacer()
                Button("See All") {
                    router.navigate(to: .history)
                }
                .font(.subheadline)
            }
            ForEach(recentThree) { record in
                ScanHistoryRowView(record: record) {
                    loadAndNavigate(record: record)
                }
            }
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .scan:
            ScanView()
        case .review(let entries, let serving):
            ReviewView(entries: entries, extractedServing: serving)
        case .report(let analysis):
            ReportView(analysis: analysis)
        case .history:
            HistoryView()
        }
    }

    // MARK: - Actions

    private func loadAndNavigate(record: ScanRecord) {
        Task {
            do {
                let analysis = try await dependencies.persistence.fetchAnalysis(id: record.id)
                guard let analysis else { return }
                router.navigate(to: .report(analysis))
            } catch {
                Logger.navigation.error("Failed to load report: \(error.localizedDescription)")
            }
        }
    }
}
