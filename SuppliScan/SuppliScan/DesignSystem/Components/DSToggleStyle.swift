//  DSToggleStyle.swift
//  SuppliScan — Design System: custom toggle. Keeps Toggle's binding/accessibility,
//  swaps the chrome for a brand-tinted track with a spring knob.

import SwiftUI

struct DSToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Theme.Space.lg) {
            configuration.label
                .textStyle(.body)
                .foregroundStyle(.ink)
            Spacer(minLength: Theme.Space.md)
            track(isOn: configuration.isOn)
        }
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.dsSnappy) { configuration.isOn.toggle() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(configuration.isOn ? [.isButton, .isSelected] : .isButton)
    }

    private func track(isOn: Bool) -> some View {
        Capsule()
            .fill(isOn ? Color.brand : Color.surfaceSunken)
            .overlay(isOn ? nil : Capsule().strokeBorder(.hairlineStrong, lineWidth: 1))
            .frame(width: 52, height: 32)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .padding(3)
                    .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
            }
            .animation(.dsSnappy, value: isOn)
    }
}

extension ToggleStyle where Self == DSToggleStyle {
    static var ds: DSToggleStyle { .init() }
}
