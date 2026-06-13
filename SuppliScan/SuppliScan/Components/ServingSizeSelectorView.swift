// ServingSizeSelectorView.swift
// SuppliScan
// Custom serving-quantity stepper + unit menu. Drives the same ServingSize binding.

import SwiftUI

struct ServingSizeSelectorView: View {
    @Binding var serving: ServingSize

    var body: some View {
        HStack(spacing: Theme.Space.md) {
            Text("Serving")
                .textStyle(.subhead)
                .foregroundStyle(.inkSecondary)

            Spacer(minLength: Theme.Space.sm)

            // Quantity stepper
            HStack(spacing: Theme.Space.sm) {
                stepButton("minus", enabled: serving.selectedQuantity > 0.5) { adjust(-0.5) }
                Text(serving.selectedQuantity.formatted())
                    .textStyle(.dataLabel)
                    .foregroundStyle(.ink)
                    .frame(minWidth: 30)
                    .monospacedDigit()
                stepButton("plus", enabled: serving.selectedQuantity < 10) { adjust(0.5) }
            }
            .padding(.vertical, Theme.Space.xs)
            .padding(.horizontal, Theme.Space.sm)
            .background(.surfaceSunken, in: Capsule())

            // Unit menu
            Menu {
                ForEach(ServingUnit.allCases, id: \.self) { unit in
                    Button {
                        serving.unit = unit
                    } label: {
                        if unit == serving.unit {
                            Label(unit.displayName, systemImage: "checkmark")
                        } else {
                            Text(unit.displayName)
                        }
                    }
                }
            } label: {
                HStack(spacing: Theme.Space.xs) {
                    Text(serving.unit.pluralised(for: serving.selectedQuantity))
                        .textStyle(.subhead)
                        .foregroundStyle(.brand)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: Theme.Icon.xs, weight: .semibold))
                        .foregroundStyle(.brand)
                }
                .padding(.vertical, Theme.Space.sm)
                .padding(.horizontal, Theme.Space.md)
                .background(.brandMuted, in: Capsule())
            }
            .accessibilityLabel("Serving unit")
        }
    }

    private func stepButton(_ symbol: String, enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "\(symbol).circle.fill")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(enabled ? Color.brand : Color.inkFaint)
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.pressable)
        .disabled(!enabled)
        .accessibilityLabel(symbol == "minus" ? "Decrease serving" : "Increase serving")
    }

    private func adjust(_ delta: Double) {
        let next = (serving.selectedQuantity + delta).rounded(toNearest: 0.5)
        serving.selectedQuantity = min(10, max(0.5, next))
    }
}

private extension Double {
    func rounded(toNearest step: Double) -> Double {
        (self / step).rounded() * step
    }
}
