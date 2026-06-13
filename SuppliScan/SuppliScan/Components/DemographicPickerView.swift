// DemographicPickerView.swift
// SuppliScan
// Demographic selector — reused in ReviewView and SettingsView.
// Custom trigger over a native Menu (keeps the menu mechanic, restyles the affordance).

import SwiftUI

struct DemographicPickerView: View {
    @Binding var selectedKey: String

    private var selectedDemographic: Demographic {
        Demographic.all.first { $0.key == selectedKey } ?? .defaultAdult
    }

    var body: some View {
        Menu {
            ForEach(Demographic.all, id: \.key) { demographic in
                Button {
                    selectedKey = demographic.key
                } label: {
                    if demographic.key == selectedKey {
                        Label(demographic.displayName, systemImage: "checkmark")
                    } else {
                        Text(demographic.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: Theme.Space.sm) {
                Text(selectedDemographic.displayName)
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
        .accessibilityLabel("Demographic profile for reference values")
    }
}
