// ScanRecordSummary.swift
// SuppliScan
//
// Sendable projection of ScanRecord for actor-boundary reads.
// SwiftData model instances stay inside their owning ModelContext.

import Foundation

nonisolated struct ScanRecordSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    let productName: String
    let referenceStandard: String
    let demographicKey: String
    let schemaVersion: Int
}

nonisolated extension ScanRecordSummary {
    init(record: ScanRecord) {
        self.init(
            id: record.id,
            createdAt: record.createdAt,
            productName: record.productName,
            referenceStandard: record.referenceStandard,
            demographicKey: record.demographicKey,
            schemaVersion: record.schemaVersion
        )
    }
}
