// ReviewViewModel.swift
// SuppliScan

import SwiftUI

@Observable
@MainActor
final class ReviewViewModel {
    var entries: [LabelEntry]
    var servingSize: ServingSize
    var selectedStandard: ReferenceStandard
    var selectedDemographicKey: String
    var isEditing = false
    var pendingAnalysis: LabelAnalysis?
    var isAnalysing = false
    var analysisError: Error?

    typealias AnalyseAction = @Sendable ([LabelEntry], ServingSize, ReferenceStandard, Demographic) async throws -> LabelAnalysis
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
    }

    var hasConfirmedEntries: Bool { !entries.isEmpty }

    func configure(analyseAction: @escaping AnalyseAction, persistAction: @escaping PersistAction) {
        self.analyseAction = analyseAction
        self.persistAction = persistAction
    }

    func requestAnalysis() {
        guard hasConfirmedEntries, let analyseAction else { return }

        analysisTask?.cancel()
        isAnalysing = true
        analysisError = nil

        let capturedEntries = entries
        let capturedServing = servingSize
        let capturedStandard = selectedStandard
        let demographic = Demographic.all.first { $0.key == selectedDemographicKey } ?? .defaultAdult

        analysisTask = Task { @MainActor [weak self, analyseAction] in
            defer { self?.isAnalysing = false }
            do {
                let analysis = try await analyseAction(capturedEntries, capturedServing, capturedStandard, demographic)
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
}
