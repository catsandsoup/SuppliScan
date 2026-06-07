// HistoryView.swift
// SuppliScan — STUB (full implementation in Views layer)
// Skills to invoke when implementing: swiftui-pro, swiftui-ui-patterns, ios-accessibility

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var records: [ScanRecord]

    @Environment(NavigationRouter.self) private var router

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Scans Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Scans you save will appear here.")
                )
            } else {
                List(records) { record in
                    ScanHistoryRowView(record: record) {
                        router.navigate(to: .report(LabelAnalysis(
                            id: record.id,
                            productName: record.productName,
                            referenceStandard: ReferenceStandard(rawValue: record.referenceStandard) ?? .au,
                            demographic: .defaultAdult,
                            servingSize: ServingSize(quantity: 1, unit: .capsule),
                            nutrientAnalyses: [],
                            herbalEntries: [],
                            probioticEntries: [],
                            unresolvedLines: [],
                            flags: .empty,
                            disclaimer: LabelAnalysis.disclaimer,
                            schemaVersion: LabelAnalysis.currentSchemaVersion,
                            createdAt: record.createdAt
                        )))
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }
}
