// HomeRecentScansSectionView.swift
// SuppliScan
// Recent reports list with a "See all" affordance.

import SwiftUI

struct HomeRecentScansSectionView: View {
    let records: [ScanRecordSummary]
    let loadingRecordID: UUID?
    let open: (UUID) -> Void
    let seeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionHeader(title: "Recent") {
                Button(action: seeAll) {
                    Text("See all")
                        .textStyle(.subhead)
                        .foregroundStyle(.brand)
                }
                .buttonStyle(.plain)
            }

            LazyVStack(spacing: 0) {
                ForEach(records) { record in
                    ScanHistoryRowView(
                        record: record,
                        isLoading: loadingRecordID == record.id
                    ) {
                        open(record.id)
                    }

                    if record.id != records.last?.id {
                        HairlineDivider(leadingInset: Theme.Space.lg)
                    }
                }
            }
            .dsSurface()
        }
    }
}
