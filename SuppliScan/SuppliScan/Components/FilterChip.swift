// FilterChip.swift
// SuppliScan
// Pill-shaped selection chip — used in NutrientFilterBar. Design-system styled.

import SwiftUI

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .textStyle(.subhead)
                .foregroundStyle(isSelected ? Color.onBrand : Color.inkSecondary)
                .padding(.horizontal, Theme.Space.md)
                .padding(.vertical, Theme.Space.sm)
                .background(isSelected ? Color.brand : Color.surfaceSunken, in: Capsule())
        }
        .buttonStyle(.plain)
        .animation(.dsSnappy, value: isSelected)
    }
}
