// LibrarySpotlightIndexer.swift
// SuppliScan
//
// Donates Library entries to Spotlight so a system search for "magnesium" surfaces a
// result that deep-links into the Library. Uses App Intents' IndexedEntity bridge.

import AppIntents
import CoreSpotlight
import OSLog

enum LibrarySpotlightIndexer {
    static func index(_ catalog: LibraryCatalog) async {
        let entities = catalog.entries.map(LibraryEntryEntity.init)
        guard !entities.isEmpty else { return }
        do {
            try await CSSearchableIndex.default().indexAppEntities(entities)
        } catch {
            Logger.suppliScan.error("Spotlight indexing failed: \(error.localizedDescription)")
        }
    }
}
