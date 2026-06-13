//  DSTextFieldStyle.swift
//  SuppliScan — Design System: text field chrome (sunken well + hairline).
//  Focus-ring handling lives in DSField where a FocusState is available.

import SwiftUI

struct DSTextFieldStyle: TextFieldStyle {
    // swiftlint:disable:next identifier_name
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textStyle(.body)
            .foregroundStyle(.ink)
            .padding(.horizontal, Theme.Space.lg)
            .frame(minHeight: 48)
            .background(.surfaceSunken, in: Theme.roundedRect(Theme.Radius.sm))
            .overlay(Theme.roundedRect(Theme.Radius.sm).strokeBorder(.hairline, lineWidth: 1))
    }
}

extension TextFieldStyle where Self == DSTextFieldStyle {
    static var ds: DSTextFieldStyle { .init() }
}

/// A labelled text field with an animated brand focus ring.
struct DSField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .textStyle(.body)
            .foregroundStyle(.ink)
            .focused($focused)
            .padding(.horizontal, Theme.Space.lg)
            .frame(minHeight: 48)
            .background(.surfaceSunken, in: Theme.roundedRect(Theme.Radius.sm))
            .overlay {
                Theme.roundedRect(Theme.Radius.sm)
                    .strokeBorder(focused ? Color.brand : Theme.Palette.hairline,
                                  lineWidth: focused ? 1.5 : 1)
            }
            .animation(.dsSnappy, value: focused)
    }
}
