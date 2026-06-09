// HistoryViewModel.swift
// SuppliScan
//
// Presentation state for saved-report loading in HistoryView.

import Foundation

nonisolated struct HistoryRecordPresentation: Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    let title: String
    let referenceStandard: String
    let statusBadges: [String]
    let searchText: String

    init(record: ScanRecord) {
        let decoded = try? LabelAnalysis.decode(from: record.reportData)
        let productName = record.productName.trimmingCharacters(in: .whitespacesAndNewlines)
        let decodedName = decoded?.productName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fallback = decoded?.nutrientAnalyses.first?.entry.canonicalName

        self.id = record.id
        self.createdAt = record.createdAt
        self.title = if !productName.isEmpty {
            productName
        } else if !decodedName.isEmpty {
            decodedName
        } else if let fallback {
            "\(fallback) supplement"
        } else {
            "Supplement analysis"
        }
        self.referenceStandard = record.referenceStandard
        self.statusBadges = Self.badges(for: decoded)
        self.searchText = ([title, referenceStandard] + statusBadges + Self.nutrientNames(from: decoded))
            .joined(separator: " ")
    }

    private static func badges(for analysis: LabelAnalysis?) -> [String] {
        guard let analysis else { return ["Saved"] }

        var badges: [String] = []
        if !analysis.flags.nutrientsAboveUL.isEmpty {
            badges.append("Above UL")
        }
        if analysis.hasUnresolved {
            badges.append("Needs review")
        }
        if analysis.flags.hasAnyInteractions {
            badges.append("Interactions")
        }
        if badges.isEmpty {
            badges.append("Verified")
        }
        return badges
    }

    private static func nutrientNames(from analysis: LabelAnalysis?) -> [String] {
        analysis?.nutrientAnalyses.map(\.entry.canonicalName) ?? []
    }
}

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

    func presentations(from records: [ScanRecord], searchText: String) -> [HistoryRecordPresentation] {
        let presentations = records.map(HistoryRecordPresentation.init)
        guard !searchText.isEmpty else { return presentations }
        return presentations.filter { $0.searchText.localizedStandardContains(searchText) }
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
