// DemographicPickerView.swift
// SuppliScan
// Menu picker for demographic — reused in ReviewView and SettingsView.

import SwiftUI

struct DemographicPickerView: View {
    @Binding var selectedKey: String

    private var selectedDemographic: Demographic {
        Demographic.all.first { $0.key == selectedKey } ?? .defaultAdult
    }

    var body: some View {
        Picker("Profile", selection: $selectedKey) {
            ForEach(Demographic.all, id: \.key) { demographic in
                Text(demographic.displayName).tag(demographic.key)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Demographic profile for reference values")
    }
}
