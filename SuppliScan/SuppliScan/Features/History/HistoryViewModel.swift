// HistoryViewModel.swift
// SuppliScan
//
// Presentation state for saved-report loading in HistoryView.

import Foundation

@MainActor
@Observable
final class HistoryViewModel {
    typealias ReportFetcher = @Sendable (UUID) async throws -> LabelAnalysis?

    private(set) var loadingRecordID: UUID?
    private(set) var pendingDestination: AppDestination?
    var isShowingLoadError = false

    @ObservationIgnored private var fetchReport: ReportFetcher?
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    func configure(fetchReport: @escaping ReportFetcher) {
        self.fetchReport = fetchReport
    }

    func summaries(from records: [ScanRecord]) -> [ScanRecordSummary] {
        records.map(ScanRecordSummary.init)
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
                    pendingDestination = .analysis(analysis)
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
