// HomeRecentScansSectionView.swift
// SuppliScan

import SwiftUI

struct HomeRecentScansSectionView: View {
    let records: [ScanRecordSummary]
    let loadingRecordID: UUID?
    let open: (UUID) -> Void
    let seeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Scans")
                    .font(.headline)
                Spacer()
                Button("See All", action: seeAll)
                    .font(.subheadline)
            }

            VStack(spacing: 0) {
                ForEach(records) { record in
                    ScanHistoryRowView(
                        record: record,
                        isLoading: loadingRecordID == record.id
                    ) {
                        open(record.id)
                    }

                    if record.id != records.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}
