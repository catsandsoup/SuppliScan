// DisclaimerView.swift
// SuppliScan
// Disclaimer at the bottom of every analysis screen. Never omit (clinical rule).

import SwiftUI

struct DisclaimerView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.md) {
            Capsule()
                .fill(.brand.opacity(0.45))
                .frame(width: 3)
            Text(text)
                .textStyle(.caption)
                .foregroundStyle(.inkTertiary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Space.sm)
    }
}
