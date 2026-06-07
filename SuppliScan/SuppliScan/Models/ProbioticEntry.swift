// ProbioticEntry.swift
// SuppliScan
//
// A probiotic strain entry from a supplement label.
// Measured in CFU (colony forming units), not mass.
// No NRV data. No form quality tier in v1.
//
// cfuBillions is Optional — nil if the label shows a total-only entry
// without breaking down individual strain counts.

import Foundation

struct ProbioticEntry: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var genus: String        // e.g. "Lactobacillus"
    var species: String      // e.g. "rhamnosus"
    var strain: String?      // e.g. "GG", "Lr-32"
    var cfuBillions: Double? // nil if total-only label
    var isTotalLine: Bool    // true if this is the "96 Billion CFU" header line
    var reviewFlags: [ReviewFlag]
    var isManuallyEdited: Bool

    init(
        id: UUID = UUID(),
        genus: String,
        species: String,
        strain: String? = nil,
        cfuBillions: Double? = nil,
        isTotalLine: Bool = false,
        reviewFlags: [ReviewFlag] = [],
        isManuallyEdited: Bool = false
    ) {
        self.id = id
        self.genus = genus
        self.species = species
        self.strain = strain
        self.cfuBillions = cfuBillions
        self.isTotalLine = isTotalLine
        self.reviewFlags = reviewFlags
        self.isManuallyEdited = isManuallyEdited
    }
}

extension ProbioticEntry {
    /// Full scientific name for display: "Lactobacillus rhamnosus GG"
    var scientificName: String {
        var name = "\(genus) \(species)"
        if let strain { name += " \(strain)" }
        return name
    }
}
