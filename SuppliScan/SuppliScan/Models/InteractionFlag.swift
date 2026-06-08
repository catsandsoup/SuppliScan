// InteractionFlag.swift
// SuppliScan
//
// A detected interaction between two or more nutrients in the analysed label.
// Sourced from interactions.json by InteractionService.

import Foundation

nonisolated struct InteractionFlag: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let participants: [String]
    let severity: InteractionSeverity
    let effect: String
    let recommendation: String
    let references: [String]

    init(
        id: UUID = UUID(),
        participants: [String],
        severity: InteractionSeverity,
        effect: String,
        recommendation: String,
        references: [String]
    ) {
        self.id = id
        self.participants = participants
        self.severity = severity
        self.effect = effect
        self.recommendation = recommendation
        self.references = references
    }
}

nonisolated struct MedicationInteractionFlag: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let nutrient: String
    let medicationClass: String
    let severity: InteractionSeverity
    let effect: String
    let recommendation: String
    let references: [String]

    init(
        id: UUID = UUID(),
        nutrient: String,
        medicationClass: String,
        severity: InteractionSeverity,
        effect: String,
        recommendation: String,
        references: [String]
    ) {
        self.id = id
        self.nutrient = nutrient
        self.medicationClass = medicationClass
        self.severity = severity
        self.effect = effect
        self.recommendation = recommendation
        self.references = references
    }
}

nonisolated enum InteractionSeverity: String, Codable, Hashable, CaseIterable, Sendable {
    case low
    case moderate
    case high

    var displayLabel: String {
        switch self {
        case .low:      "Low"
        case .moderate: "Moderate"
        case .high:     "High"
        }
    }
}
