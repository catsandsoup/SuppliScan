// LabelAnalysis.swift
// SuppliScan
//
// Top-level output of ReportService. The primary deliverable of a scan.
// Contains all entry analyses for the three typed entry types plus
// unresolved lines.
//
// schemaVersion MUST be set on every write (use LabelAnalysis.currentSchemaVersion).
// disclaimer MUST be set by ReportService — no code path may omit it.
//
// Archived to Data and stored in ScanRecord.reportData via PersistenceService.

import Foundation

nonisolated struct LabelAnalysis: Identifiable, Codable, Sendable {
    let id: UUID
    let productName: String
    let referenceStandard: ReferenceStandard
    let demographic: Demographic
    let servingSize: ServingSize
    let nutrientAnalyses: [NutrientAnalysis]
    let herbalEntries: [HerbalEntry]        // passed through — no NRV calculation
    let probioticEntries: [ProbioticEntry]  // passed through — no NRV calculation
    let unresolvedLines: [RawLine]          // lines the user did not resolve
    let flags: ReportFlags
    let disclaimer: String                  // always set by ReportService
    let schemaVersion: Int                  // always set to currentSchemaVersion
    let createdAt: Date
}

// MARK: - Hashable (id-based for NavigationPath)

nonisolated extension LabelAnalysis: Hashable {
    static func == (lhs: LabelAnalysis, rhs: LabelAnalysis) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Schema Versioning

nonisolated extension LabelAnalysis {
    nonisolated static let currentSchemaVersion = 1

    nonisolated static let disclaimer = """
        This report is for practitioner reference only. It does not constitute \
        medical advice or therapeutic recommendation. Always exercise independent \
        clinical judgment.
        """

    /// Called by PersistenceService on load. Guards against future Codable
    /// migration failures when schemaVersion is bumped.
    nonisolated static func decode(from data: Data) throws -> LabelAnalysis {
        let analysis = try JSONDecoder().decode(LabelAnalysis.self, from: data)
        // Future: if analysis.schemaVersion < currentSchemaVersion, migrate here
        return analysis
    }

    nonisolated func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

// MARK: - Convenience

nonisolated extension LabelAnalysis {
    var hasNutrients: Bool { !nutrientAnalyses.isEmpty }
    var hasHerbals: Bool { !herbalEntries.isEmpty }
    var hasProbiotics: Bool { !probioticEntries.isEmpty }
    var hasUnresolved: Bool { !unresolvedLines.isEmpty }

    var displayTitle: String {
        productName.isEmpty ? "Analysis" : productName
    }

    /// Rich text summary for share sheet (Notes, Mail, Reminders, etc.).
    var shareText: String {
        let name = productName.isEmpty ? "Supplement" : productName
        let serving = "\(servingSize.selectedQuantity.formatted()) \(servingSize.unit.pluralised(for: servingSize.selectedQuantity))"
        let nutrientCount = nutrientAnalyses.count
        var lines: [String] = [
            "\(name) — SuppliScan analysis",
            "\(referenceStandard.rawValue) standard · \(serving) · \(demographic.displayName)",
            "",
            "\(nutrientCount) nutrient\(nutrientCount == 1 ? "" : "s") identified",
        ]
        if !flags.nutrientsAboveUL.isEmpty {
            let count = flags.nutrientsAboveUL.count
            lines.append("⚠️ \(count) nutrient\(count == 1 ? "" : "s") above the Tolerable Upper Intake Level")
        }
        if !flags.nutrientInteractions.isEmpty || !flags.medicationInteractions.isEmpty {
            let count = flags.nutrientInteractions.count + flags.medicationInteractions.count
            lines.append("\(count) potential interaction\(count == 1 ? "" : "s") flagged")
        }

        let highlights = nutrientAnalyses
            .filter { $0.rdiPercent != nil }
            .sorted { ($0.rdiPercent ?? 0) > ($1.rdiPercent ?? 0) }
            .prefix(5)
        if !highlights.isEmpty {
            lines.append("")
            lines.append("Highlights (% of RDI):")
            for nutrient in highlights {
                let percent = Int((nutrient.rdiPercent ?? 0).rounded())
                lines.append("• \(nutrient.entry.displayName): \(percent)%")
            }
        }

        lines.append("")
        lines.append(disclaimer)
        return lines.joined(separator: "\n")
    }

    /// Total CFU across all probiotic entries (excluding total lines).
    var totalCFUBillions: Double? {
        let strains = probioticEntries.filter { !$0.isTotalLine }
        let cfus = strains.compactMap(\.cfuBillions)
        guard !cfus.isEmpty else { return nil }
        return cfus.reduce(0, +)
    }
}
