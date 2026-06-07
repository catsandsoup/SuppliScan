// ScanStatusView.swift
// SuppliScan

import SwiftUI

struct ScanStatusView: View {
    let loadingState: LoadingState<OCRResult>
    let reviewWarning: AppError?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch loadingState {
            case .idle:
                Label("Ready for label text", systemImage: "text.viewfinder")
                    .foregroundStyle(.secondary)
            case .loading:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Reading label text")
                }
                .foregroundStyle(.secondary)
            case .loaded(let result):
                Label(
                    "OCR confidence \(result.averageConfidence.formatted(.percent.precision(.fractionLength(0))))",
                    systemImage: result.hasLowConfidenceText ? "exclamationmark.triangle" : "checkmark.circle"
                )
                .foregroundStyle(result.hasLowConfidenceText ? .orange : .green)
            case .failed(let error):
                Label(error.errorDescription ?? "Scan failed", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }

            if let warning = reviewWarning?.errorDescription {
                Text(warning)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
