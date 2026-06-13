// HomeEmptyStateView.swift
// SuppliScan
// First-run empty state — answers "nothing to analyse yet" with a clear invitation.

import SwiftUI

struct HomeEmptyStateView: View {
    var body: some View {
        VStack(spacing: Theme.Space.lg) {
            ZStack {
                Circle()
                    .fill(.brandMuted)
                    .frame(width: 84, height: 84)
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.brand)
            }

            VStack(spacing: Theme.Space.sm) {
                Text("No reports yet")
                    .textStyle(.title)
                    .foregroundStyle(.ink)
                Text("Scan your first supplement label to generate a clinical report. It will appear here for quick access.")
                    .textStyle(.callout)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Space.xxl)
        .accessibilityElement(children: .combine)
    }
}
