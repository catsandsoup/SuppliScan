// SettingsView.swift
// SuppliScan

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultStandard") private var defaultStandard: ReferenceStandard = .au
    @AppStorage("defaultDemographicKey") private var defaultDemographicKey: String = Demographic.defaultAdult.key
    @Environment(AppDependencies.self) private var dependencies

    @State private var showDeleteConfirm = false

    var body: some View {
        Form {
            Section("Default Reference Standard") {
                StandardPickerView(selection: $defaultStandard)
            }

            Section("Default Profile") {
                DemographicPickerView(selectedKey: $defaultDemographicKey)
            }

            Section("Data") {
                Button("Delete All Scans", role: .destructive) {
                    showDeleteConfirm = true
                }
                .confirmationDialog(
                    "Delete all saved scans?",
                    isPresented: $showDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Delete All", role: .destructive) {
                        Task {
                            try? await dependencies.persistence.deleteAll()
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.appVersionString)
                LabeledContent("Reference Data", value: "NHMRC 2023 · NIH/FDA · EFSA")
                Text(LabelAnalysis.disclaimer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
