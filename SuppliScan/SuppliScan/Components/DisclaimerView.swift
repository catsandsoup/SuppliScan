// DisclaimerView.swift
// SuppliScan
// Disclaimer text at the bottom of every analysis screen. Never omit.

import SwiftUI

struct DisclaimerView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 2)
                .clipShape(Capsule())
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.top, 8)
    }
}
