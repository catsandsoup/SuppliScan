// FormPotencyRowView.swift
// SuppliScan
// SF Symbol icon + nutrient name + tier badge + rationale — used in FormsAndPotencyView.

import SwiftUI

struct FormPotencyRowView: View {
    let analysis: NutrientAnalysis

    var body: some View {
        guard let quality = analysis.formQuality else { return AnyView(EmptyView()) }
        return AnyView(
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: nutrientSymbol(for: analysis.entry.canonicalName))
                    .font(.title2)
                    .foregroundStyle(nutrientColor(for: quality.tier))
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(analysis.entry.displayName)
                            .font(.headline)
                        Spacer()
                        TierBadgeView(tier: quality.tier)
                    }
                    Text(quality.rationale)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                    if quality.isAIInferred {
                        AIInferredBadgeView()
                    }
                }
            }
            .padding(.vertical, 4)
        )
    }
}

private func nutrientSymbol(for name: String) -> String {
    switch name.lowercased() {
    case let n where n.contains("vitamin d"): return "sun.max"
    case let n where n.contains("vitamin k"): return "leaf"
    case let n where n.contains("vitamin c"): return "c.circle"
    case let n where n.contains("vitamin b"): return "b.circle"
    case let n where n.contains("vitamin a"): return "eye"
    case let n where n.contains("vitamin e"): return "e.circle"
    case "magnesium": return "circle.hexagongrid"
    case "zinc": return "atom"
    case "iron": return "drop"
    case "calcium": return "circle.dotted"
    case "omega", "dha", "epa": return "drop.fill"
    default: return "pill"
    }
}

private func nutrientColor(for tier: FormTier) -> Color {
    switch tier {
    case .tier1: .green
    case .tier2: .yellow
    case .tier3: .orange
    case .tier4: .red
    }
}
