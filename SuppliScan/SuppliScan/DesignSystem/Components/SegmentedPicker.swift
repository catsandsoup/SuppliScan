//  SegmentedPicker.swift
//  SuppliScan — Design System: custom segmented control with a sliding selection pill.
//  Replaces stock `.segmented` Picker. Drives a Binding like any picker.

import SwiftUI

struct SegmentedPicker<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let label: (Value) -> String

    @Namespace private var ns

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Text(label(option))
                    .textStyle(.subhead)
                    .foregroundStyle(isSelected ? .ink : .inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background {
                        if isSelected {
                            Theme.roundedRect(Theme.Radius.sm)
                                .fill(.surfaceRaised)
                                .elevation(.card)
                                .matchedGeometryEffect(id: "segment", in: ns)
                        }
                    }
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.dsSnappy) { selection = option }
                    }
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(Theme.Space.xs)
        .background(.surfaceSunken, in: Theme.roundedRect(Theme.Radius.md))
        .sensoryFeedback(.selection, trigger: selection)
    }
}
