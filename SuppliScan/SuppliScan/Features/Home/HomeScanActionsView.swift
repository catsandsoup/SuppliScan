// HomeScanActionsView.swift
// SuppliScan
// Hero scan action card + secondary manual entry.

import SwiftUI

struct HomeScanActionsView: View {
    let scan: () -> Void
    let enterManually: () -> Void

    var body: some View {
        VStack(spacing: Theme.Space.md) {
            Button(action: scan) {
                HStack(spacing: Theme.Space.md) {
                    ZStack {
                        Circle()
                            .fill(.onBrand.opacity(0.18))
                            .frame(width: 48, height: 48)
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.onBrand)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan a label")
                            .textStyle(.headline)
                            .foregroundStyle(.onBrand)
                        Text("Point at the supplement facts panel")
                            .textStyle(.caption)
                            .foregroundStyle(Theme.Palette.onBrand.opacity(0.85))
                    }
                    Spacer(minLength: Theme.Space.sm)
                    Image(systemName: "arrow.right")
                        .font(.system(size: Theme.Icon.sm, weight: .semibold))
                        .foregroundStyle(Theme.Palette.onBrand.opacity(0.9))
                }
                .padding(Theme.Space.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.brand, in: Theme.roundedRect(Theme.Radius.card))
                .elevation(.card)
            }
            .buttonStyle(.pressable)
            .accessibilityHint("Starts a camera scan of a supplement label.")

            Button("Enter manually", action: enterManually)
                .buttonStyle(.dsTertiary)
                .accessibilityHint("Creates a report from manually entered label information.")
        }
    }
}
