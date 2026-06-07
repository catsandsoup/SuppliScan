// ServingSizeSelectorView.swift
// SuppliScan
// Stepper for serving quantity + Picker for unit — used in ReviewView bottom bar.

import SwiftUI

struct ServingSizeSelectorView: View {
    @Binding var serving: ServingSize

    var body: some View {
        HStack(spacing: 12) {
            Text("Serving:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Stepper(
                "\(serving.selectedQuantity.formatted()) \(serving.unit.pluralised(for: serving.selectedQuantity))",
                value: $serving.selectedQuantity,
                in: 0.5...10,
                step: 0.5
            )
            .font(.subheadline)
            Spacer()
            Picker("Unit", selection: $serving.unit) {
                ForEach(ServingUnit.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            .pickerStyle(.menu)
            .font(.subheadline)
        }
    }
}
