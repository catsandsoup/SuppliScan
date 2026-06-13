// SettingsView.swift
// SuppliScan

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultStandard") private var defaultStandard: ReferenceStandard = .au
    @AppStorage("defaultDemographicKey") private var defaultDemographicKey: String = Demographic.defaultAdult.key
    @AppStorage("showOCRConfidence") private var showOCRConfidence = true
    @AppStorage("requireReviewBeforeAnalysis") private var requireReviewBeforeAnalysis = true
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

            Section {
                Toggle("Show OCR confidence", isOn: $showOCRConfidence)
                Toggle("Require review before analysis", isOn: $requireReviewBeforeAnalysis)
            } header: {
                Text("Review & OCR")
            } footer: {
                Text("Control the review step and what's shown before analysis.")
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
                LabeledContent("NRV sources", value: "NHMRC 2006 (rev. 2017) · NIH/FDA · EFSA")
                LabeledContent("Clinical use", value: "Practitioner reference")
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
