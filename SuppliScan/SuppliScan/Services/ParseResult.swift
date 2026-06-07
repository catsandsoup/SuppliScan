// ParseResult.swift
// SuppliScan

import Foundation

/// Structured output from deterministic OCR parsing.
nonisolated struct ParseResult: Hashable, Sendable {
    let entries: [LabelEntry]
    let extractedServing: ServingSize?
}
