// SettingsView.swift
// SuppliScan — STUB (full implementation in Views layer)
// Skills to invoke when implementing: swiftui-pro, writing-for-interfaces

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultStandard") private var defaultStandard: String = ReferenceStandard.au.rawValue
    @AppStorage("defaultDemographicKey") private var defaultDemographicKey: String = Demographic.defaultAdult.key

    var body: some View {
        NavigationStack {
            Form {
                Section("Default Reference Standard") {
                    Picker("Standard", selection: $defaultStandard) {
                        ForEach(ReferenceStandard.allCases, id: \.rawValue) { standard in
                            Text(standard.displayName).tag(standard.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersionString)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
