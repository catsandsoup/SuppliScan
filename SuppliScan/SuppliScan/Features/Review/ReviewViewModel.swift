// ReviewViewModel.swift
// SuppliScan

import SwiftUI
import OSLog

@Observable
@MainActor
final class ReviewViewModel {
    var entries: [LabelEntry]
    var productName: String = ""
    var servingSize: ServingSize
    var selectedStandard: ReferenceStandard
    var selectedDemographicKey: String
    var isEditing = false
    var pendingAnalysis: LabelAnalysis?
    var isAnalysing = false
    var analysisError: Error?
    var selectedEntryID: UUID?

    typealias AnalyseAction = @Sendable ([LabelEntry], ServingSize, ReferenceStandard, Demographic, String) async throws -> LabelAnalysis
    typealias PersistAction = @Sendable (LabelAnalysis, ReferenceStandard, Demographic) async -> Void

    @ObservationIgnored private var analyseAction: AnalyseAction?
    @ObservationIgnored private var persistAction: PersistAction?
    @ObservationIgnored private var analysisTask: Task<Void, Never>?
    @ObservationIgnored private var persistedAnalysisIDs: Set<UUID> = []

    init(entries: [LabelEntry], extractedServing: ServingSize?) {
        self.entries = entries
        self.servingSize = extractedServing ?? ServingSize(quantity: 1, unit: .capsule)

        // Read stored defaults (written by SettingsView via @AppStorage)
        let storedStandard = UserDefaults.standard.string(forKey: "defaultStandard") ?? "AU"
        self.selectedStandard = ReferenceStandard(rawValue: storedStandard) ?? .au
        self.selectedDemographicKey = UserDefaults.standard.string(forKey: "defaultDemographicKey")
            ?? Demographic.defaultAdult.key

        Self.logReviewFlags(entries, context: "initial-review")
    }

    var hasConfirmedEntries: Bool {
        !entries.filter { ReviewEntryClassifier.status(for: $0) != .otherLabelText }.isEmpty
    }

    var presentations: [ReviewEntryPresentation] {
        ReviewEntryClassifier.presentations(for: entries)
    }

    var blockingReviewCount: Int {
        presentations.count { $0.status == .needsReview }
    }

    var suggestedProductName: String {
        ReviewEntryClassifier.suggestedProductName(from: entries)
    }

    var effectiveProductName: String {
        let trimmed = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? suggestedProductName : trimmed
    }

    func configure(analyseAction: @escaping AnalyseAction, persistAction: @escaping PersistAction) {
        self.analyseAction = analyseAction
        self.persistAction = persistAction
    }

    func requestAnalysis() {
        guard hasConfirmedEntries, let analyseAction else { return }

        analysisTask?.cancel()
        isAnalysing = true
        analysisError = nil

        let capturedEntries = entries.filter { ReviewEntryClassifier.status(for: $0) != .otherLabelText }
        Self.logReviewFlags(capturedEntries, context: "analysis-request")
        let capturedProductName = effectiveProductName
        let capturedServing = servingSize
        let capturedStandard = selectedStandard
        let demographic = Demographic.all.first { $0.key == selectedDemographicKey } ?? .defaultAdult

        analysisTask = Task { @MainActor [weak self, analyseAction] in
            defer { self?.isAnalysing = false }
            do {
                let analysis = try await analyseAction(capturedEntries, capturedServing, capturedStandard, demographic, capturedProductName)
                self?.pendingAnalysis = analysis
                // Persist in a sibling Task — failures don't block navigation
                if self?.markAnalysisForPersistence(analysis.id) == true {
                    let persist = self?.persistAction
                    Task { await persist?(analysis, capturedStandard, demographic) }
                }
            } catch {
                self?.analysisError = error
            }
        }
    }

    private func markAnalysisForPersistence(_ id: UUID) -> Bool {
        guard !persistedAnalysisIDs.contains(id) else { return false }
        persistedAnalysisIDs.insert(id)
        return true
    }

    func consumePendingAnalysis() -> LabelAnalysis? {
        defer { pendingAnalysis = nil }
        return pendingAnalysis
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }

    func delete(entryID: UUID) {
        entries.removeAll { $0.id == entryID }
        if selectedEntryID == entryID {
            selectedEntryID = nil
        }
    }

    func confirm(entryID: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
        entries[index] = ReviewEntryClassifier.confirmed(entries[index])
        selectedEntryID = nil
    }

    func presentation(for id: UUID?) -> ReviewEntryPresentation? {
        guard let id else { return nil }
        return presentations.first { $0.id == id }
    }

    private static func logReviewFlags(_ entries: [LabelEntry], context: String) {
        for entry in entries where !entry.reviewFlags.isEmpty {
            let flags = entry.reviewFlags.map(\.rawValue).joined(separator: ",")
            Logger.parser.debug("Review flags context=\(context, privacy: .public) entryID=\(entry.id.uuidString, privacy: .public) flags=\(flags, privacy: .public)")
        }
    }
}
