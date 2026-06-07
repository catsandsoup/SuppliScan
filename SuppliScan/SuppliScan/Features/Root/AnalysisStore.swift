// AnalysisStore.swift
// SuppliScan
//
// Lightweight transient store for the current analysis result.
// Written by ReviewView after analysis is requested.
// Read by AnalysisRootView (Analysis tab root).
// Never persisted — use PersistenceService for long-term storage.

import Foundation

@Observable
@MainActor
final class AnalysisStore {
    var currentAnalysis: LabelAnalysis?
}
