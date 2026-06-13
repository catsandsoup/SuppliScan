// LibraryAvatarView.swift
// SuppliScan
// Category monogram for Library rows/headers. Brand-tinted (on-thesis: one brand colour),
// category conveyed by SF Symbol — never by introducing new hues.

import SwiftUI

struct LibraryAvatarView: View {
    let category: SupplementKnowledgeCategory
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().fill(.brandMuted)
            Image(systemName: category.symbolName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.brand)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
