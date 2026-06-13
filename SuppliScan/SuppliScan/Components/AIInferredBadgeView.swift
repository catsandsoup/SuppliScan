// AIInferredBadgeView.swift
// SuppliScan
// Purple dot + estimate text shown when form quality needs source review.

import SwiftUI

struct AIInferredBadgeView: View {
    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            Circle()
                .fill(Theme.Palette.aiInferred)
                .frame(width: 6, height: 6)
            Text("Estimate")
                .textStyle(.caption)
                .foregroundStyle(Theme.Palette.aiInferred)
        }
        .padding(.horizontal, Theme.Space.sm)
        .padding(.vertical, Theme.Space.xxs)
        .background(Theme.Palette.aiInferred.opacity(0.14), in: Capsule())
    }
}
