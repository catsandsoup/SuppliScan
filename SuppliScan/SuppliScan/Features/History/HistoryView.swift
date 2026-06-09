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

    private var filteredRecords: [HistoryRecordPresentation] {
        viewModel.presentations(from: records, searchText: searchText)
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
                        HistoryRecordRowView(
                            record: record,
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
        .searchToolbarBehavior(.minimize)
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

private struct HistoryRecordRowView: View {
    let record: HistoryRecordPresentation
    var isLoading = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(record.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(record.referenceStandard) · \(record.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !record.statusBadges.isEmpty {
                        HStack(spacing: 6) {
                            badges
                        }
                    }
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 6)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens the saved clinical report")
    }

    @ViewBuilder
    private var badges: some View {
        ForEach(record.statusBadges, id: \.self) { badge in
            Text(badge)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(badgeColor(for: badge).opacity(0.12), in: Capsule())
                .foregroundStyle(badgeColor(for: badge))
        }
    }

    private var accessibilityLabel: String {
        let badges = record.statusBadges.joined(separator: ", ")
        return badges.isEmpty
            ? "\(record.title), \(record.referenceStandard)"
            : "\(record.title), \(record.referenceStandard), \(badges)"
    }

    private func badgeColor(for badge: String) -> Color {
        switch badge {
        case "Above UL": AppTheme.Color.critical
        case "Needs review", "Interactions": AppTheme.Color.warning
        case "Verified": AppTheme.Color.success
        default: .secondary
        }
    }
}
