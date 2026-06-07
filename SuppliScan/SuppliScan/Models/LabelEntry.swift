// LabelEntry.swift
// SuppliScan
//
// The fundamental unit of a parsed supplement label.
// A single scan can return all four cases simultaneously.
// All services and views MUST handle all four cases — no partial handling.
//
// Hashable conformance is based on id only — used by NavigationPath
// via AppDestination.review(entries:) and AppDestination.report(_:).

import Foundation

enum LabelEntry: Identifiable, Codable, Sendable {
    case nutrient(NutrientEntry)
    case herbal(HerbalEntry)
    case probiotic(ProbioticEntry)
    case unresolved(RawLine)

    var id: UUID {
        switch self {
        case .nutrient(let e):   e.id
        case .herbal(let e):     e.id
        case .probiotic(let e):  e.id
        case .unresolved(let e): e.id
        }
    }
}

// MARK: - Hashable (id-based for NavigationPath performance)

extension LabelEntry: Hashable {
    static func == (lhs: LabelEntry, rhs: LabelEntry) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Convenience accessors

extension LabelEntry {
    var asNutrient: NutrientEntry? {
        if case .nutrient(let e) = self { return e }
        return nil
    }
    var asHerbal: HerbalEntry? {
        if case .herbal(let e) = self { return e }
        return nil
    }
    var asProbiotic: ProbioticEntry? {
        if case .probiotic(let e) = self { return e }
        return nil
    }
    var asRawLine: RawLine? {
        if case .unresolved(let e) = self { return e }
        return nil
    }

    var reviewFlags: [ReviewFlag] {
        switch self {
        case .nutrient(let e):   e.reviewFlags
        case .herbal(let e):     e.reviewFlags
        case .probiotic(let e):  e.reviewFlags
        case .unresolved:        []
        }
    }

    var hasReviewFlags: Bool { !reviewFlags.isEmpty }

    var isManuallyEdited: Bool {
        switch self {
        case .nutrient(let e):   e.isManuallyEdited
        case .herbal(let e):     e.isManuallyEdited
        case .probiotic(let e):  e.isManuallyEdited
        case .unresolved:        false
        }
    }
}
