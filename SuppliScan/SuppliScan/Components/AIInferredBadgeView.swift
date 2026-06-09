// AIInferredBadgeView.swift
// SuppliScan
// Purple dot + estimate text shown when form quality needs source review.

import SwiftUI

struct AIInferredBadgeView: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.purple)
                .frame(width: 6, height: 6)
            Text("Estimate")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.purple)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.purple.opacity(0.12), in: Capsule())
    }
}
