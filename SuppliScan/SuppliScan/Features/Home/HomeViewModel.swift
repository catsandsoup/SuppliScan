// HomeViewModel.swift
// SuppliScan
//
// Presentation state for HomeView. The view renders this state and forwards
// user actions; persistence loading stays out of the SwiftUI view body.

import Foundation

@MainActor
@Observable
final class HomeViewModel {
    typealias ReportFetcher = @Sendable (UUID) async throws -> LabelAnalysis?

    private(set) var loadingRecordID: UUID?
    private(set) var pendingDestination: AppDestination?
    var isShowingLoadError = false

    @ObservationIgnored private var fetchReport: ReportFetcher?
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    func configure(fetchReport: @escaping ReportFetcher) {
        self.fetchReport = fetchReport
    }

    func recentRecords(from records: [ScanRecord]) -> [ScanRecordSummary] {
        records.prefix(3).map(ScanRecordSummary.init)
    }

    func openRecord(id: UUID) {
        guard let fetchReport else {
            isShowingLoadError = true
            return
        }

        loadTask?.cancel()
        loadingRecordID = id
        isShowingLoadError = false
        pendingDestination = nil

        loadTask = Task { @MainActor [fetchReport] in
            do {
                let analysis = try await fetchReport(id)
                try Task.checkCancellation()

                if let analysis {
                    pendingDestination = .report(analysis)
                } else {
                    isShowingLoadError = true
                }
            } catch is CancellationError {
                // A newer row tap superseded this request.
            } catch {
                isShowingLoadError = true
            }

            if loadingRecordID == id {
                loadingRecordID = nil
            }
        }
    }

    func consumePendingDestination() -> AppDestination? {
        defer { pendingDestination = nil }
        return pendingDestination
    }
}
