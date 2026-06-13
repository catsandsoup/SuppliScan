// LibraryEntryEntity.swift
// SuppliScan
//
// App Intents representation of a Library encyclopedia entry. Enables Siri, the Shortcuts
// app, and Spotlight ("look up magnesium") to deep-link straight into the Library.
// The catalog is bundle-derived, so the query loads it independently of AppDependencies.

import AppIntents
import CoreSpotlight

struct LibraryEntryEntity: AppEntity, IndexedEntity {
    let id: String          // canonical name — stable identifier
    let name: String
    let categoryName: String
    let summary: String

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Supplement")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(categoryName)"
        )
    }

    /// Spotlight metadata so the entry is searchable system-wide.
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = name
        attributes.contentDescription = summary
        attributes.keywords = [categoryName, "supplement", "nutrient", "SuppliScan"]
        return attributes
    }

    static let defaultQuery = LibraryEntryEntityQuery()
}

extension LibraryEntryEntity {
    init(_ entry: LibraryEntry) {
        self.id = entry.id
        self.name = entry.canonicalName
        self.categoryName = entry.category.displayName
        self.summary = entry.summary
    }
}

// MARK: - Query

struct LibraryEntryEntityQuery: EntityQuery, EntityStringQuery {
    @MainActor
    private func allEntities() -> [LibraryEntryEntity] {
        let catalog = (try? LibraryCatalog.load()) ?? .empty
        return catalog.entries.map(LibraryEntryEntity.init)
    }

    @MainActor
    func entities(for identifiers: [String]) async throws -> [LibraryEntryEntity] {
        let wanted = Set(identifiers)
        return allEntities().filter { wanted.contains($0.id) }
    }

    @MainActor
    func entities(matching string: String) async throws -> [LibraryEntryEntity] {
        let needle = string.lowercased()
        guard !needle.isEmpty else { return allEntities() }
        return allEntities().filter {
            $0.name.lowercased().contains(needle) || $0.summary.lowercased().contains(needle)
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [LibraryEntryEntity] {
        allEntities()
    }
}
