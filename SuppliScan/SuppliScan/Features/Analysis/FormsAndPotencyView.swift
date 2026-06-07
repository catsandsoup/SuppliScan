// FormsAndPotencyView.swift
// SuppliScan
// List of NutrientAnalyses with form quality data.
// Shows bioavailability tier, form name, and rationale.

import SwiftUI

struct FormsAndPotencyView: View {
    let analyses: [NutrientAnalysis]

    @Environment(NavigationRouter.self) private var router

    private var analysesWithQuality: [NutrientAnalysis] {
        analyses.filter { $0.formQuality != nil }
    }

    var body: some View {
        List {
            ForEach(analysesWithQuality) { analysis in
                FormPotencyRowView(analysis: analysis)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UISelectionFeedbackGenerator().selectionChanged()
                        router.navigate(to: .nutrientDetail(analysis))
                    }
            }

            Section {
                Text("Potency is based on absorption and bioavailability evidence from published research.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Forms & Potency")
        .navigationBarTitleDisplayMode(.inline)
    }
}
