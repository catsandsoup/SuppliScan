// LabelRecognisedBannerView.swift
// SuppliScan
// Success banner shown at the top of ReviewView once OCR recognises a label.

import SwiftUI

struct LabelRecognisedBannerView: View {
    let standard: ReferenceStandard
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: Theme.Space.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Palette.tier1)
                .font(.system(size: Theme.Icon.md, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text("Label recognised")
                    .textStyle(.subhead)
                    .foregroundStyle(.ink)
                Text("\(standard.rawValue) reference standard")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, Theme.Space.md)
        .background(Theme.Palette.tier1.opacity(0.10), in: Theme.roundedRect(Theme.Radius.md))
        .overlay(Theme.roundedRect(Theme.Radius.md).strokeBorder(Theme.Palette.tier1.opacity(0.18), lineWidth: 1))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            guard !reduceMotion else { isVisible = true; return }
            withAnimation(.dsGentle) { isVisible = true }
        }
    }
}
