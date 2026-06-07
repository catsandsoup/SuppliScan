// ReviewViewModel.swift
// SuppliScan

import SwiftUI

@Observable
@MainActor
final class ReviewViewModel {
    var entries: [LabelEntry]
    var servingSize: ServingSize
    var selectedStandard: ReferenceStandard = .au
    var selectedDemographicKey: String = Demographic.defaultAdult.key
    var isEditing = false
    var pendingAnalysis: LabelAnalysis?

    init(entries: [LabelEntry], extractedServing: ServingSize?) {
        self.entries = entries
        self.servingSize = extractedServing ?? ServingSize(quantity: 1, unit: .capsule)
    }

    var hasConfirmedEntries: Bool { !entries.isEmpty }

    func requestAnalysis() {
        pendingAnalysis = LabelAnalysis.placeholder(
            entries: entries,
            serving: servingSize,
            standard: selectedStandard
        )
    }

    func consumePendingAnalysis() -> LabelAnalysis? {
        defer { pendingAnalysis = nil }
        return pendingAnalysis
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
    }
}
