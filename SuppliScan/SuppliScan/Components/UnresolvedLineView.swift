// UnresolvedLineView.swift
// SuppliScan
// Raw OCR line that could not be analysed — shown in the Details tab. Self-contained token row.

import SwiftUI

struct UnresolvedLineView: View {
    let line: RawLine

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.sm) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: Theme.Icon.sm, weight: .semibold))
                .foregroundStyle(.inkTertiary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(line.text)
                    .textStyle(.subhead)
                    .foregroundStyle(.ink)
                Text("Could not be analysed")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.surfaceSunken, in: Theme.roundedRect(Theme.Radius.sm))
        .accessibilityElement(children: .combine)
    }
}
