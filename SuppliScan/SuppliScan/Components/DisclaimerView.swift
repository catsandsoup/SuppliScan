// DisclaimerView.swift
// SuppliScan
// Disclaimer text at the bottom of every analysis screen. Never omit.

import SwiftUI

struct DisclaimerView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .padding(.top, 8)
    }
}
