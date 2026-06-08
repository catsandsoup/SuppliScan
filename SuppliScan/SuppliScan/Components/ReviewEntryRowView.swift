// ReviewEntryRowView.swift
// SuppliScan
// Switches on LabelEntry case, editable when isEditing is true.
// All four cases handled — never silent.

import SwiftUI

struct ReviewEntryRowView: View {
    let entry: LabelEntry
    let index: Int
    let isEditing: Bool
    let onUpdate: (LabelEntry) -> Void

    @State private var showFlagSheet = false
    @State private var selectedFlag: ReviewFlag?

    var body: some View {
        Group {
            switch entry {
            case .nutrient(let n):
                NutrientReviewRow(
                    entry: n,
                    index: index,
                    isEditing: isEditing,
                    onFlagTap: { flag in
                        selectedFlag = flag
                        showFlagSheet = true
                    }
                )
            case .herbal(let h):
                HerbalReviewRow(entry: h, isEditing: isEditing)
            case .probiotic(let p):
                ProbioticReviewRow(entry: p, isEditing: isEditing)
            case .unresolved(let r):
                UnresolvedReviewRow(line: r)
            }
        }
        .sheet(isPresented: $showFlagSheet) {
            if let flag = selectedFlag {
                FlagExplanationSheet(flag: flag)
                    .presentationDetents([.fraction(0.35)])
            }
        }
    }
}

// MARK: - Nutrient Row

private struct NutrientReviewRow: View {
    let entry: NutrientEntry
    let index: Int
    let isEditing: Bool
    let onFlagTap: (ReviewFlag) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.subheadline)
                if let form = entry.form {
                    Text("as \(form)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()

            if let amount = entry.amount {
                Text("\(amount.formatted()) \(entry.unit.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }

            // Flag badges
            ForEach(entry.reviewFlags, id: \.self) { flag in
                Button {
                    onFlagTap(flag)
                } label: {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.Color.warning)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .opacity(isEditing ? 0.8 : 1.0)
        .animation(.easeOut(duration: 0.2).delay(Double(index) * 0.03), value: isEditing)
    }
}

// MARK: - Herbal Row

private struct HerbalReviewRow: View {
    let entry: HerbalEntry
    let isEditing: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.latinName)
                    .font(.subheadline.italic())
                if let common = entry.commonName {
                    Text(common)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let amount = entry.extractAmount, let unit = entry.extractUnit {
                Text("\(amount.formatted()) \(unit.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Probiotic Row

private struct ProbioticReviewRow: View {
    let entry: ProbioticEntry
    let isEditing: Bool

    var body: some View {
        HStack {
            Text("\(entry.genus) \(entry.species)")
                .font(.subheadline.italic())
            Spacer()
            if let cfu = entry.cfuBillions {
                Text("\(cfu.formatted()) B CFU")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Unresolved Row

private struct UnresolvedReviewRow: View {
    let line: RawLine

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(AppTheme.Color.unresolved)
            Text(line.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Text("Needs review")
                .font(.caption)
                .foregroundStyle(AppTheme.Color.unresolved)
        }
        .padding(.vertical, 8)
        .listRowBackground(AppTheme.Color.unresolved.opacity(0.12))
    }
}

// MARK: - Flag Explanation Sheet

private struct FlagExplanationSheet: View {
    let flag: ReviewFlag
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundStyle(AppTheme.Color.warning)
                Text("Review Note")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.subheadline)
            }
            .padding(.top, 8)

            Text(flag.explanation)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

extension ReviewFlag {
    var explanation: String {
        switch self {
        case .amountNotFound: "No numeric amount could be extracted for this entry."
        case .unitUnknown: "The unit for this entry was not recognised."
        case .dualUnit: "Both IU and metric units were present. The metric value was used."
        case .rangeAmount: "A range was detected (e.g. 100–200 mg). The lower bound was used."
        case .traceAmount: "A trace amount was indicated. The value has been set to 0."
        case .subOneAmount: "An amount less than 1 was indicated. The value has been set to 0.5."
        case .extractEquivalent: "Both extract and active amounts were shown. Please verify."
        case .proprietaryBlend: "Individual amounts within this blend are unknown."
        case .totalLineAmbiguous: "This appears to be a total line. Confirm it replaces sub-entries."
        case .iuConversionAssumed: "Vitamin E: synthetic form assumed for IU conversion."
        case .iuConversionInvalid: "IU is not a valid unit for this nutrient."
        case .decimalCommaNormalised: "A European decimal comma was normalised (e.g. 12,5 → 12.5)."
        case .servingMultiplied: "Amount adjusted by the selected serving size."
        case .canonicalNameInferred: "Name matched via alias — not an exact match."
        }
    }
}
