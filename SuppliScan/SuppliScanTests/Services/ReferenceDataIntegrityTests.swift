// ReferenceDataIntegrityTests.swift
// SuppliScanTests
//
// Data-integrity tests for bundled clinical reference files. These do not judge
// clinical truth; they guard against broken JSON, missing citations, dangling
// source IDs, and enum drift that would silently weaken the app's reference layer.

import Foundation
import Testing
@testable import SuppliScan

struct ReferenceDataIntegrityTests {

    @Test func supplementKnowledgeHasResolvableSources() throws {
        let knowledge = try SupplementKnowledgeService.load()
        let sourceIDs = Set(knowledge.database.sources.map(\.id))

        #expect(knowledge.database.entries.count >= 50)
        #expect(sourceIDs.count >= 40)

        for entry in knowledge.database.entries {
            #expect(entry.sourceIDs.isEmpty == false, "\(entry.canonicalName) must cite at least one source.")
            expectSourceIDs(entry.sourceIDs, existIn: sourceIDs, owner: entry.canonicalName)

            for doseContext in entry.doseContexts {
                #expect(doseContext.sourceIDs.isEmpty == false, "\(entry.canonicalName) dose context '\(doseContext.context)' must cite sources.")
                expectSourceIDs(doseContext.sourceIDs, existIn: sourceIDs, owner: "\(entry.canonicalName) dose context")
            }

            for note in entry.clinicalNotes {
                #expect(note.sourceIDs.isEmpty == false, "\(entry.canonicalName) note '\(note.topic)' must cite sources.")
                expectSourceIDs(note.sourceIDs, existIn: sourceIDs, owner: "\(entry.canonicalName) clinical note")
            }
        }
    }

    @Test func supplementKnowledgeCoversEveryAustralianNRVNutrient() throws {
        let knowledge = try SupplementKnowledgeService.load()
        let knowledgeNames = Set(knowledge.database.entries.map(\.canonicalName))
        let referenceData = try Bundle.main.referenceData(named: "nrv_au", as: NRVDataFile.self)

        for nutrient in referenceData.nutrients {
            #expect(knowledgeNames.contains(nutrient.name), "\(nutrient.name) must have a Library knowledge entry.")
        }
    }

    @Test func formQualityRowsAreTieredAndCited() throws {
        let file = try Bundle.main.referenceData(named: "form_quality", as: FormQualityIntegrityFile.self)

        #expect(file.forms.count >= 50)

        for row in file.forms {
            #expect((1...4).contains(row.tier), "\(row.nutrient) / \(row.form) uses an invalid tier.")
            #expect(row.rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            #expect(row.references.isEmpty == false, "\(row.nutrient) / \(row.form) must cite at least one reference.")
            #expect(row.references.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false })
        }
    }

    @Test func interactionsUseKnownSeveritiesAndCitations() throws {
        let file = try Bundle.main.referenceData(named: "interactions", as: InteractionIntegrityFile.self)

        #expect(file.nutrientInteractions.count >= 5)
        #expect(file.medicationInteractions.count >= 10)

        for row in file.nutrientInteractions {
            #expect(InteractionSeverity(rawValue: row.severity) != nil, "\(row.participants.joined(separator: " + ")) uses an invalid severity.")
            #expect(row.participants.count >= 2)
            #expect(row.references.isEmpty == false, "\(row.participants.joined(separator: " + ")) must cite at least one reference.")
        }

        for row in file.medicationInteractions {
            #expect(InteractionSeverity(rawValue: row.severity) != nil, "\(row.nutrient) / \(row.medicationClass) uses an invalid severity.")
            #expect(row.nutrient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            #expect(row.medicationClass.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            #expect(row.references.isEmpty == false, "\(row.nutrient) / \(row.medicationClass) must cite at least one reference.")
        }
    }

    @Test func knowledgeTextDoesNotUseTherapeuticCertaintyLanguage() throws {
        let knowledge = try SupplementKnowledgeService.load()
        let bannedPhrases = [
            "cures ",
            "cure for",
            "guaranteed",
            "proven to treat",
            "works for",
            "100%"
        ]

        for entry in knowledge.database.entries {
            let text = ([entry.canonicalName] + entry.outcomes + entry.doseContexts.map(\.interpretation) + entry.clinicalNotes.map(\.text))
                .joined(separator: " ")
                .lowercased()

            for phrase in bannedPhrases {
                #expect(text.contains(phrase) == false, "\(entry.canonicalName) contains over-certain phrase '\(phrase)'.")
            }
        }
    }

    @Test func botanicalAndProbioticTextIsPatientFacing() throws {
        let knowledge = try SupplementKnowledgeService.load()
        let entries = knowledge.database.entries.filter {
            $0.category == .botanical || $0.category == .probiotic
        }
        let botanicalCount = entries.filter { $0.category == .botanical }.count
        let probioticCount = entries.filter { $0.category == .probiotic }.count
        let bannedPhrases = [
            "admin",
            "developer",
            "todo",
            "scaffold",
            "label-review context",
            "marketing context",
            "not established",
            "record ",
            "use caution language",
            "do not"
        ]

        #expect(botanicalCount >= 22)
        #expect(probioticCount >= 17)

        for entry in entries {
            let text = ([entry.canonicalName] + entry.outcomes + entry.doseContexts.map(\.interpretation) + entry.clinicalNotes.map(\.text))
                .joined(separator: " ")
                .lowercased()

            for phrase in bannedPhrases {
                #expect(text.contains(phrase) == false, "\(entry.canonicalName) contains internal wording '\(phrase)'.")
            }
        }
    }

    private func expectSourceIDs(_ ids: [String], existIn sourceIDs: Set<String>, owner: String) {
        for id in ids {
            #expect(sourceIDs.contains(id), "\(owner) references missing source ID '\(id)'.")
        }
    }
}

private struct FormQualityIntegrityFile: Decodable {
    let forms: [FormQualityIntegrityRow]
}

private struct FormQualityIntegrityRow: Decodable {
    let nutrient: String
    let form: String
    let tier: Int
    let rationale: String
    let references: [String]
}

private struct InteractionIntegrityFile: Decodable {
    let nutrientInteractions: [NutrientInteractionIntegrityRow]
    let medicationInteractions: [MedicationInteractionIntegrityRow]

    enum CodingKeys: String, CodingKey {
        case nutrientInteractions = "nutrient_interactions"
        case medicationInteractions = "medication_interactions"
    }
}

private struct NutrientInteractionIntegrityRow: Decodable {
    let participants: [String]
    let severity: String
    let references: [String]
}

private struct MedicationInteractionIntegrityRow: Decodable {
    let nutrient: String
    let medicationClass: String
    let severity: String
    let references: [String]

    enum CodingKeys: String, CodingKey {
        case nutrient
        case medicationClass = "medication_class"
        case severity
        case references
    }
}
