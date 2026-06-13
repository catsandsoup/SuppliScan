//  DSButtonStyle.swift
//  SuppliScan — Design System: custom button styles.
//  States: default · pressed (scale + darken, dsMicro) · disabled (sunken + faint).
//  Loading is a content concern — see DSLoadingLabel.

import SwiftUI

enum DSButtonKind { case primary, secondary, tertiary, destructive }

struct DSButtonStyle: ButtonStyle {
    var kind: DSButtonKind = .primary

    func makeBody(configuration: Configuration) -> some View {
        DSButtonStyleBody(kind: kind, configuration: configuration)
    }

    private struct DSButtonStyleBody: View {
        let kind: DSButtonKind
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let pressed = configuration.isPressed
            configuration.label
                .textStyle(.headline)
                .foregroundStyle(foreground)
                .frame(maxWidth: maxWidth, minHeight: minHeight)
                .padding(.horizontal, Theme.Space.lg)
                .background(background(pressed: pressed), in: Theme.roundedRect(Theme.Radius.md))
                .overlay {
                    if showsBorder {
                        Theme.roundedRect(Theme.Radius.md).strokeBorder(.hairline, lineWidth: 1)
                    }
                }
                .scaleEffect(pressed ? 0.97 : 1)
                .opacity(pressed && kind != .primary ? 0.7 : 1)
                .animation(.dsMicro, value: pressed)
                .contentShape(.rect)
        }

        private var foreground: Color {
            guard isEnabled else { return .inkFaint }
            switch kind {
            case .primary:     return .onBrand
            case .secondary:   return .brand
            case .tertiary:    return .brand
            case .destructive: return Theme.Palette.tier4
            }
        }

        private func background(pressed: Bool) -> Color {
            guard isEnabled else { return .surfaceSunken }
            switch kind {
            case .primary:     return pressed ? .brandPressed : .brand
            case .secondary:   return .brandMuted
            case .tertiary:    return .clear
            case .destructive: return Theme.Palette.tier4.opacity(0.12)
            }
        }

        private var showsBorder: Bool { kind == .secondary }
        private var minHeight: CGFloat { kind == .tertiary ? 44 : 52 }
        private var maxWidth: CGFloat? { kind == .tertiary ? nil : .infinity }
    }
}

extension ButtonStyle where Self == DSButtonStyle {
    static var dsPrimary: DSButtonStyle { .init(kind: .primary) }
    static var dsSecondary: DSButtonStyle { .init(kind: .secondary) }
    static var dsTertiary: DSButtonStyle { .init(kind: .tertiary) }
    static var dsDestructive: DSButtonStyle { .init(kind: .destructive) }
}

/// Label that swaps to an inline progress indicator while loading, holding width
/// so the button doesn't resize. Use inside a Button's label.
struct DSLoadingLabel: View {
    let title: String
    var systemImage: String? = nil
    let isLoading: Bool

    var body: some View {
        ZStack {
            HStack(spacing: Theme.Space.sm) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: Theme.Icon.sm, weight: .semibold))
                }
                Text(title)
            }
            .opacity(isLoading ? 0 : 1)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(.onBrand)
            }
        }
        .animation(.dsFadeQuick, value: isLoading)
    }
}
