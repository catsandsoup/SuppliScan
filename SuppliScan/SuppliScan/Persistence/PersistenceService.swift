// PersistenceService.swift
// SuppliScan
//
// All SwiftData writes and deletes go through this actor.
// Views NEVER touch ModelContext directly for writes.
// @Query in Views is the only acceptable read-only exception.
//
// autosaveEnabled = false — all saves are explicit.
// Never pass ModelContext or PersistentModel instances across the actor boundary.
// Returns only Sendable value types to callers.

import SwiftData
import Foundation
import OSLog

actor PersistenceService {
    private let modelContext: ModelContext

    init(container: ModelContainer) {
        self.modelContext = ModelContext(container)
        self.modelContext.autosaveEnabled = false
    }

    // MARK: - Save

    func save(
        analysis: LabelAnalysis,
        productName: String,
        standard: ReferenceStandard,
        demographic: Demographic
    ) async throws {
        let data = try analysis.encoded()
        let record = ScanRecord()
        record.id = analysis.id
        record.createdAt = analysis.createdAt
        record.productName = productName
        record.referenceStandard = standard.rawValue
        record.demographicKey = demographic.key
        record.reportData = data
        record.schemaVersion = LabelAnalysis.currentSchemaVersion

        // Uniqueness enforced at insert time (no @Attribute(.unique))
        try delete(id: analysis.id)
        modelContext.insert(record)
        try modelContext.save()
        Logger.suppliScan.info("PersistenceService: saved scan '\(productName)'")
    }

    // MARK: - Fetch

    func fetchAll() throws -> [ScanRecordSummary] {
        let descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(ScanRecordSummary.init)
    }

    func fetchAnalysis(id: UUID) throws -> LabelAnalysis? {
        var descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate<ScanRecord> { record in
                record.id == id
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else { return nil }
        return try LabelAnalysis.decode(from: record.reportData)
    }

    // MARK: - Delete

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate<ScanRecord> { record in
                record.id == id
            }
        )
        let records = try modelContext.fetch(descriptor)
        records.forEach { modelContext.delete($0) }
        if !records.isEmpty {
            try modelContext.save()
        }
    }

    func deleteAll() throws {
        try modelContext.delete(model: ScanRecord.self)
        try modelContext.save()
        Logger.suppliScan.info("PersistenceService: deleted all scan records")
    }
}
