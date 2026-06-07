// RawLine.swift
// SuppliScan
//
// A label line that ParserService could not classify into any typed entry.
// Surfaced in ReviewView with a yellow highlight for manual resolution.
// NEVER silently dropped — every unresolved line must be visible to the user.
//
// userResolution is set when the user manually classifies the line in ReviewView
// (converts to a typed entry or explicitly dismisses it).

import Foundation

struct RawLine: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let text: String            // exact OCR text — never modified
    let lineNumber: Int         // position in OCR output for ordering
    var userResolution: UserResolution?

    init(
        id: UUID = UUID(),
        text: String,
        lineNumber: Int,
        userResolution: UserResolution? = nil
    ) {
        self.id = id
        self.text = text
        self.lineNumber = lineNumber
        self.userResolution = userResolution
    }
}

// MARK: - UserResolution

enum UserResolution: Codable, Hashable, Sendable {
    case convertedToNutrient(NutrientEntry)
    case convertedToHerbal(HerbalEntry)
    case convertedToProbiotic(ProbioticEntry)
    case dismissed    // user confirmed this line should be ignored
}
