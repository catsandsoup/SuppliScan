//  SectionHeader.swift
//  SuppliScan — Design System: section header with optional eyebrow + trailing action.
//  Replaces stock `Section` headers and the old ReportSectionHeader.

import SwiftUI

struct SectionHeader<Trailing: View>: View {
    var eyebrow: String? = nil
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                if let eyebrow {
                    Text(eyebrow)
                        .textStyle(.eyebrow)
                        .foregroundStyle(.inkTertiary)
                }
                Text(title)
                    .textStyle(.title)
                    .foregroundStyle(.ink)
            }
            Spacer(minLength: Theme.Space.md)
            trailing()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(eyebrow: String? = nil, title: String) {
        self.eyebrow = eyebrow
        self.title = title
        self.trailing = { EmptyView() }
    }
}
