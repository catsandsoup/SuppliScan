// FlagBannerView.swift
// SuppliScan
// Conditional flag banners shown in the Analysis Summary tab. One banner per flag type.
// Restyled to the design system; tier/aiInferred colours, never colour alone (icon + text).

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
                color: Theme.Palette.tier4,
                message: "\(count) nutrient\(count == 1 ? "" : "s") \(count == 1 ? "exceeds" : "exceed") the Tolerable Upper Intake Level"
            ))
        }
        if !flags.nutrientsAtUL.isEmpty {
            let count = flags.nutrientsAtUL.count
            items.append(FlagItem(
                icon: "exclamationmark.circle.fill",
                color: Theme.Palette.tier3,
                message: "\(count) nutrient\(count == 1 ? "" : "s") \(count == 1 ? "is" : "are") approaching the Upper Intake Level"
            ))
        }
        if !flags.lowBioavailabilityForms.isEmpty {
            let count = flags.lowBioavailabilityForms.count
            items.append(FlagItem(
                icon: "arrow.down.circle.fill",
                color: Theme.Palette.tier3,
                message: "\(count) nutrient\(count == 1 ? "" : "s") \(count == 1 ? "uses" : "use") low-bioavailability forms"
            ))
        }
        if !flags.aiInferredForms.isEmpty {
            let count = flags.aiInferredForms.count
            items.append(FlagItem(
                icon: "sparkles",
                color: Theme.Palette.aiInferred,
                message: "\(count) form quality rating\(count == 1 ? "" : "s") \(count == 1 ? "needs" : "need") source review"
            ))
        }
        if !flags.unresolvedEntries.isEmpty {
            items.append(FlagItem(
                icon: "questionmark.circle.fill",
                color: Theme.Palette.tier2,
                message: "\(flags.unresolvedEntries.count) label line\(flags.unresolvedEntries.count == 1 ? "" : "s") could not be analysed"
            ))
        }
        if !flags.nutrientInteractions.isEmpty {
            items.append(FlagItem(
                icon: "arrow.left.arrow.right.circle.fill",
                color: Theme.Palette.tier2,
                message: "\(flags.nutrientInteractions.count) nutrient interaction\(flags.nutrientInteractions.count == 1 ? "" : "s") detected — see Interactions tab"
            ))
        }
        if !flags.medicationInteractions.isEmpty {
            items.append(FlagItem(
                icon: "pills.fill",
                color: Theme.Palette.tier4,
                message: "\(flags.medicationInteractions.count) potential medication interaction\(flags.medicationInteractions.count == 1 ? "" : "s") — consult your prescriber"
            ))
        }
        return items
    }

    var body: some View {
        VStack(spacing: Theme.Space.sm) {
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.md) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: Theme.Icon.sm, weight: .semibold))
            Text(message)
                .textStyle(.subhead)
                .foregroundStyle(.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, Theme.Space.md)
        .background(color.opacity(0.10), in: Theme.roundedRect(Theme.Radius.md))
        .overlay(Theme.roundedRect(Theme.Radius.md).strokeBorder(color.opacity(0.18), lineWidth: 1))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 6)
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            let delay = Double(min(index, 6)) * Theme.Motion.stagger
            withAnimation(.dsGentle.delay(delay)) { appeared = true }
        }
    }
}
