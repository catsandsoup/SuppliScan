// AIInferredBadgeView.swift
// SuppliScan
// Purple dot + "AI" text — shown when formQuality.isAIInferred is true.

import SwiftUI

struct AIInferredBadgeView: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.purple)
                .frame(width: 6, height: 6)
            Text("AI")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.purple)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.purple.opacity(0.12), in: Capsule())
    }
}
