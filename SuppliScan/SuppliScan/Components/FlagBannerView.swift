// FlagBannerView.swift
// SuppliScan
// Conditional flag banners shown in AnalysisView Summary tab.
// One banner per flag type, system semantic colours only.

import SwiftUI

struct FlagBannerView: View {
    let flags: ReportFlags

    var body: some View {
        VStack(spacing: 8) {
            if !flags.nutrientsAboveUL.isEmpty {
                FlagRow(
                    icon: "exclamationmark.triangle.fill",
                    color: Color(.systemRed),
                    message: "\(flags.nutrientsAboveUL.count) nutrient\(flags.nutrientsAboveUL.count == 1 ? "" : "s") exceed the Tolerable Upper Intake Level"
                )
            }
            if !flags.nutrientsAtUL.isEmpty {
                FlagRow(
                    icon: "exclamationmark.circle.fill",
                    color: Color(.systemOrange),
                    message: "\(flags.nutrientsAtUL.count) nutrient\(flags.nutrientsAtUL.count == 1 ? "" : "s") approaching the Upper Intake Level"
                )
            }
            if !flags.lowBioavailabilityForms.isEmpty {
                FlagRow(
                    icon: "arrow.down.circle.fill",
                    color: Color(.systemOrange),
                    message: "\(flags.lowBioavailabilityForms.count) nutrient\(flags.lowBioavailabilityForms.count == 1 ? "" : "s") use low-bioavailability forms"
                )
            }
            if !flags.aiInferredForms.isEmpty {
                FlagRow(
                    icon: "sparkles",
                    color: Color.purple,
                    message: "\(flags.aiInferredForms.count) form quality rating\(flags.aiInferredForms.count == 1 ? "" : "s") are AI-inferred"
                )
            }
            if !flags.unresolvedEntries.isEmpty {
                FlagRow(
                    icon: "questionmark.circle.fill",
                    color: Color(.systemYellow),
                    message: "\(flags.unresolvedEntries.count) label line\(flags.unresolvedEntries.count == 1 ? "" : "s") could not be analysed"
                )
            }
            if !flags.nutrientInteractions.isEmpty {
                FlagRow(
                    icon: "arrow.left.arrow.right.circle.fill",
                    color: Color(.systemBlue),
                    message: "\(flags.nutrientInteractions.count) nutrient interaction\(flags.nutrientInteractions.count == 1 ? "" : "s") detected — see Interactions tab"
                )
            }
            if !flags.medicationInteractions.isEmpty {
                FlagRow(
                    icon: "pills.fill",
                    color: Color(.systemRed),
                    message: "\(flags.medicationInteractions.count) potential medication interaction\(flags.medicationInteractions.count == 1 ? "" : "s") — consult your prescriber"
                )
            }
        }
    }
}

private struct FlagRow: View {
    let icon: String
    let color: Color
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.subheadline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}
