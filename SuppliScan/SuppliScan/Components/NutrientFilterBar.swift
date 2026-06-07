// NutrientFilterBar.swift
// SuppliScan
// Horizontal scroll of FilterChip for All/Vitamins/Minerals/Other.

import SwiftUI

struct NutrientFilterBar: View {
    @Binding var selection: NutrientCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NutrientCategory.allCases) { category in
                    FilterChip(
                        label: category.rawValue,
                        isSelected: selection == category
                    ) {
                        UISelectionFeedbackGenerator().selectionChanged()
                        selection = category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
