// ReferenceType.swift
// SuppliScan
//
// The type of nutritional reference value used for a given nutrient
// and demographic. Used by RDIReference to describe what the reference
// value represents (RDI, EAR, or AI).

import Foundation

enum ReferenceType: String, Codable, Hashable, CaseIterable, Sendable {
    case rdi  // Recommended Dietary Intake — the primary reference value
    case ear  // Estimated Average Requirement — used when RDI not established
    case ai   // Adequate Intake — used when insufficient evidence for RDI or EAR
}

extension ReferenceType {
    var abbreviation: String { rawValue.uppercased() }

    var displayName: String {
        switch self {
        case .rdi: "RDI"
        case .ear: "EAR"
        case .ai:  "AI"
        }
    }

    var fullName: String {
        switch self {
        case .rdi: "Recommended Dietary Intake"
        case .ear: "Estimated Average Requirement"
        case .ai:  "Adequate Intake"
        }
    }
}
