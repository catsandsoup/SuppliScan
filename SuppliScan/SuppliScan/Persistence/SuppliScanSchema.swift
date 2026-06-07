// SuppliScanSchema.swift
// SuppliScan
//
// Versioned SwiftData schema. Versioned from day one so future migrations
// are possible without data loss.
//
// RULES (from AGENTS.md):
// - All @Model classes must be final
// - No @Attribute(.unique) — uniqueness enforced at insert time (CloudKit compat)
// - All model properties have default values
// - autosaveEnabled = false on all contexts — see PersistenceService
// - Never subclass @Model classes

import SwiftData
import Foundation

enum SuppliScanSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ScanRecord.self] }

    @Model
    final class ScanRecord {
        var id: UUID = UUID()
        var createdAt: Date = Date()
        var productName: String = ""
        var referenceStandard: String = "AU"
        var demographicKey: String = "adult_male_19_50"
        var reportData: Data = Data()   // archived LabelAnalysis via JSONEncoder
        var schemaVersion: Int = 1      // always set to LabelAnalysis.currentSchemaVersion

        init(
            id: UUID = UUID(),
            createdAt: Date = Date(),
            productName: String = "",
            referenceStandard: String = "AU",
            demographicKey: String = "adult_male_19_50",
            reportData: Data = Data(),
            schemaVersion: Int = 1
        ) {
            self.id = id
            self.createdAt = createdAt
            self.productName = productName
            self.referenceStandard = referenceStandard
            self.demographicKey = demographicKey
            self.reportData = reportData
            self.schemaVersion = schemaVersion
        }
    }
}

// MARK: - Type alias for convenience

typealias ScanRecord = SuppliScanSchemaV1.ScanRecord

// MARK: - Migration Plan

struct SuppliScanMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SuppliScanSchemaV1.self]
    }
    static var stages: [MigrationStage] { [] }
}
