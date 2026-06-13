//  GlassTabBar.swift
//  SuppliScan — Design System: floating Liquid-Glass tab bar (functional layer).
//  A glass pill with a brand-tinted selection lozenge that slides via matchedGeometry.

import SwiftUI

struct GlassTabBarItem<Tab: Hashable>: Identifiable {
    let tab: Tab
    let title: String
    let icon: String
    var id: Tab { tab }
}

struct GlassTabBar<Tab: Hashable>: View {
    let items: [GlassTabBarItem<Tab>]
    @Binding var selection: Tab

    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: Theme.Space.sm) {
            HStack(spacing: Theme.Space.xs) {
                ForEach(items) { item in
                    segment(for: item)
                }
            }
            .padding(Theme.Space.xs)
        }
        .glassEffect(.regular.interactive(), in: Capsule())
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func segment(for item: GlassTabBarItem<Tab>) -> some View {
        let isSelected = item.tab == selection
        return Button {
            withAnimation(.dsSnappy) { selection = item.tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.system(size: Theme.Icon.md, weight: isSelected ? .semibold : .regular))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(item.title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Color.brand : Color.inkSecondary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.brandMuted)
                        .matchedGeometryEffect(id: "tabPill", in: ns)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
