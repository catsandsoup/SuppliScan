// HistoryView.swift
// SuppliScan
// Searchable list of past reports with swipe-to-delete. Design-system styled:
// List/searchable/EditButton/onDelete mechanics preserved; content is carded cells on
// the warm surface with custom empty states.

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
                HistoryEmptyState(
                    icon: "clock.arrow.circlepath",
                    title: "No reports yet",
                    message: "Scan a supplement label to start building your history."
                )
            } else if filteredRecords.isEmpty && !searchText.isEmpty {
                HistoryEmptyState(
                    icon: "magnifyingglass",
                    title: "No matches",
                    message: "No saved reports match “\(searchText)”."
                )
            } else {
                List {
                    ForEach(filteredRecords) { record in
                        HistoryRecordRowView(
                            record: record,
                            isLoading: viewModel.loadingRecordID == record.id
                        ) {
                            viewModel.openRecord(id: record.id)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(
                            top: Theme.Space.xs, leading: Theme.Space.screen,
                            bottom: Theme.Space.xs, trailing: Theme.Space.screen
                        ))
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
                .scrollContentBackground(.hidden)
                .contentMargins(.top, Theme.Space.sm, for: .scrollContent)
                .contentMargins(.bottom, 96, for: .scrollContent)
            }
        }
        .background(Theme.Palette.surface.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .searchToolbarBehavior(.minimize)
        .tint(Theme.Palette.brand)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !records.isEmpty { EditButton() }
            }
        }
        .alert(
            "Couldn’t Load Report",
            isPresented: $viewModel.isShowingLoadError
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The saved report could not be opened.")
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

// MARK: - Row

private struct HistoryRecordRowView: View {
    let record: HistoryRecordPresentation
    var isLoading = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Space.md) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(record.title)
                        .textStyle(.headline)
                        .foregroundStyle(.ink)
                        .lineLimit(1)

                    Text("\(record.referenceStandard) · \(record.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .textStyle(.caption)
                        .foregroundStyle(.inkTertiary)

                    if !record.statusBadges.isEmpty {
                        HStack(spacing: Theme.Space.xs) {
                            badges
                        }
                        .padding(.top, Theme.Space.xxs)
                    }
                }

                Spacer(minLength: Theme.Space.sm)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.brand)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: Theme.Icon.xs, weight: .semibold))
                        .foregroundStyle(.inkFaint)
                        .accessibilityHidden(true)
                }
            }
            .dsCard()
            .contentShape(.rect)
        }
        .buttonStyle(.pressable)
        .disabled(isLoading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens the saved report")
    }

    @ViewBuilder
    private var badges: some View {
        ForEach(record.statusBadges, id: \.self) { badge in
            Text(badge)
                .textStyle(.caption)
                .padding(.horizontal, Theme.Space.sm)
                .padding(.vertical, Theme.Space.xxs)
                .background(badgeColor(for: badge).opacity(0.14), in: Capsule())
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
        case "Above UL": Theme.Palette.tier4
        case "Needs review", "Interactions": Theme.Palette.tier3
        case "Verified": Theme.Palette.tier1
        default: Theme.Palette.inkTertiary
        }
    }
}

// MARK: - Empty state

private struct HistoryEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.Space.lg) {
            ZStack {
                Circle()
                    .fill(.brandMuted)
                    .frame(width: 84, height: 84)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.brand)
            }
            VStack(spacing: Theme.Space.sm) {
                Text(title)
                    .textStyle(.title)
                    .foregroundStyle(.ink)
                Text(message)
                    .textStyle(.callout)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Space.screen)
    }
}
