// FlagBannerView.swift
// SuppliScan
// Conditional flag banners shown in AnalysisView Summary tab.
// One banner per flag type, system semantic colours only.

import SwiftUI

struct FlagBannerView: View {
    let flags: ReportFlags

    private struct FlagItem: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let message: String
    }

    private var flagItems: [FlagItem] {
        var items: [FlagItem] = []
        if !flags.nutrientsAboveUL.isEmpty {
            let count = flags.nutrientsAboveUL.count
            items.append(FlagItem(
                icon: "exclamationmark.triangle.fill",
                color: AppTheme.Color.critical,
                message: "\(count) nutrient\(count == 1 ? "" : "s") \(count == 1 ? "exceeds" : "exceed") the Tolerable Upper Intake Level"
            ))
        }
        if !flags.nutrientsAtUL.isEmpty {
            let count = flags.nutrientsAtUL.count
            items.append(FlagItem(
                icon: "exclamationmark.circle.fill",
                color: AppTheme.Color.warning,
                message: "\(count) nutrient\(count == 1 ? "" : "s") \(count == 1 ? "is" : "are") approaching the Upper Intake Level"
            ))
        }
        if !flags.lowBioavailabilityForms.isEmpty {
            let count = flags.lowBioavailabilityForms.count
            items.append(FlagItem(
                icon: "arrow.down.circle.fill",
                color: AppTheme.Color.warning,
                message: "\(count) nutrient\(count == 1 ? "" : "s") \(count == 1 ? "uses" : "use") low-bioavailability forms"
            ))
        }
        if !flags.aiInferredForms.isEmpty {
            let count = flags.aiInferredForms.count
            items.append(FlagItem(
                icon: "sparkles",
                color: .purple,
                message: "\(count) form quality rating\(count == 1 ? "" : "s") \(count == 1 ? "needs" : "need") source review"
            ))
        }
        if !flags.unresolvedEntries.isEmpty {
            items.append(FlagItem(
                icon: "questionmark.circle.fill",
                color: AppTheme.Color.unresolved,
                message: "\(flags.unresolvedEntries.count) label line\(flags.unresolvedEntries.count == 1 ? "" : "s") could not be analysed"
            ))
        }
        if !flags.nutrientInteractions.isEmpty {
            items.append(FlagItem(
                icon: "arrow.left.arrow.right.circle.fill",
                color: .blue,
                message: "\(flags.nutrientInteractions.count) nutrient interaction\(flags.nutrientInteractions.count == 1 ? "" : "s") detected — see Interactions tab"
            ))
        }
        if !flags.medicationInteractions.isEmpty {
            items.append(FlagItem(
                icon: "pills.fill",
                color: AppTheme.Color.critical,
                message: "\(flags.medicationInteractions.count) potential medication interaction\(flags.medicationInteractions.count == 1 ? "" : "s") — consult your prescriber"
            ))
        }
        return items
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(flagItems.enumerated()), id: \.element.id) { index, item in
                FlagRow(icon: item.icon, color: item.color, message: item.message, index: index)
            }
        }
    }
}

private struct FlagRow: View {
    let icon: String
    let color: Color
    let message: String
    let index: Int

    @State private var appeared = false

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
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 5)
        .onAppear {
            let delay = Double(min(index, 6)) * 0.06
            withAnimation(.spring(response: 0.40, dampingFraction: 0.80).delay(delay)) {
                appeared = true
            }
        }
    }
}
