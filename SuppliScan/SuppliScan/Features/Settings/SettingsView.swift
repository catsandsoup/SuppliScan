// SettingsView.swift
// SuppliScan
//
// App-level preferences. Custom card layout (no Form/Section) on the design system.
// All @AppStorage bindings and the destructive delete flow are preserved unchanged.

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultStandard") private var defaultStandard: ReferenceStandard = .au
    @AppStorage("defaultDemographicKey") private var defaultDemographicKey: String = Demographic.defaultAdult.key
    @AppStorage("showOCRConfidence") private var showOCRConfidence = true
    @AppStorage("requireReviewBeforeAnalysis") private var requireReviewBeforeAnalysis = true
    @Environment(AppDependencies.self) private var dependencies

    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.section) {
                SectionHeader(eyebrow: "Preferences", title: "Settings")
                    .padding(.top, Theme.Space.sm)

                referenceStandardCard
                profileCard
                reviewCard
                dataCard
                aboutCard
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.sm)
            .padding(.bottom, 110) // clear the floating tab bar
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Cards

    private var referenceStandardCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            eyebrow("Reference Standard")
            StandardPickerView(selection: $defaultStandard)
            caption("Used to calculate RDI and upper-limit percentages.")
        }
        .dsCard()
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            eyebrow("Default Profile")
            HStack {
                Text("Demographic")
                    .textStyle(.body)
                    .foregroundStyle(.ink)
                Spacer(minLength: Theme.Space.md)
                DemographicPickerView(selectedKey: $defaultDemographicKey)
            }
            caption("Adjusts reference values for age and sex.")
        }
        .dsCard()
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("Review & OCR")
                .padding(.bottom, Theme.Space.sm)
            Toggle("Show OCR confidence", isOn: $showOCRConfidence)
                .toggleStyle(.ds)
                .padding(.vertical, Theme.Space.md)
            HairlineDivider()
            Toggle("Require review before analysis", isOn: $requireReviewBeforeAnalysis)
                .toggleStyle(.ds)
                .padding(.vertical, Theme.Space.md)
            caption("Control the review step and what's shown before analysis.")
                .padding(.top, Theme.Space.sm)
        }
        .dsCard()
    }

    private var dataCard: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack(spacing: Theme.Space.md) {
                Image(systemName: "trash")
                    .font(.system(size: Theme.Icon.sm, weight: .semibold))
                Text("Delete All Scans")
                    .textStyle(.body)
                Spacer()
            }
            .foregroundStyle(Theme.Palette.tier4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .dsCard()
        .confirmationDialog(
            "Delete all saved scans?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                Task { try? await dependencies.persistence.deleteAll() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes every saved scan. This can't be undone.")
        }
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow("About")
                .padding(.bottom, Theme.Space.sm)
            keyValue("Version", Bundle.main.appVersionString)
            HairlineDivider().padding(.vertical, Theme.Space.xs)
            keyValue("NRV sources", "NHMRC 2006 (rev. 2017) · NIH/FDA · EFSA")
            HairlineDivider().padding(.vertical, Theme.Space.xs)
            keyValue("Clinical use", "Practitioner reference")
            HairlineDivider().padding(.vertical, Theme.Space.sm)
            Text(LabelAnalysis.disclaimer)
                .textStyle(.caption)
                .foregroundStyle(.inkTertiary)
        }
        .dsCard()
    }

    // MARK: - Helpers

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .textStyle(.eyebrow)
            .foregroundStyle(.inkTertiary)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .textStyle(.caption)
            .foregroundStyle(.inkTertiary)
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key)
                .textStyle(.body)
                .foregroundStyle(.inkSecondary)
            Spacer(minLength: Theme.Space.lg)
            Text(value)
                .textStyle(.callout)
                .foregroundStyle(.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, Theme.Space.sm)
    }
}

private extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
