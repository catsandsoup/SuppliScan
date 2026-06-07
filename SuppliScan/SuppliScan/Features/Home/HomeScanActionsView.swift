// HomeScanActionsView.swift
// SuppliScan

import SwiftUI

struct HomeScanActionsView: View {
    let scan: () -> Void
    let enterManually: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: scan) {
                Label("Scan Label", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Starts a camera scan of a supplement label.")

            Button("Enter Manually", action: enterManually)
                .buttonStyle(.borderless)
                .accessibilityHint("Creates a report from manually entered label information.")
        }
        .frame(maxWidth: 360)
    }
}
