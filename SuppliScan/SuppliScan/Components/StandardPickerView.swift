// StandardPickerView.swift
// SuppliScan
// AU/US/EU reference-standard selector — reused in ReviewView and SettingsView.
// Custom sliding-pill segmented control (design system), not a stock Picker.

import SwiftUI

struct StandardPickerView: View {
    @Binding var selection: ReferenceStandard

    var body: some View {
        SegmentedPicker(options: ReferenceStandard.allCases, selection: $selection) {
            $0.rawValue
        }
        .accessibilityLabel("Reference standard for nutritional values")
    }
}
