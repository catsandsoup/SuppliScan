// StandardPickerView.swift
// SuppliScan
// Segmented AU/US/EU picker — reused in ReviewView and SettingsView.

import SwiftUI

struct StandardPickerView: View {
    @Binding var selection: ReferenceStandard

    var body: some View {
        Picker("Reference Standard", selection: $selection) {
            ForEach(ReferenceStandard.allCases, id: \.self) {
                Text($0.rawValue).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Reference standard for nutritional values")
    }
}
