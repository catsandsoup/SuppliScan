// ReviewView.swift
// SuppliScan — STUB (full implementation in Views layer)
// Skills to invoke when implementing: swiftui-pro, swiftui-ui-patterns, ios-accessibility

import SwiftUI

struct ReviewView: View {
    let entries: [LabelEntry]
    let extractedServing: ServingSize?

    @Environment(NavigationRouter.self) private var router

    var body: some View {
        ContentUnavailableView(
            "Review Coming Soon",
            systemImage: "list.clipboard",
            description: Text("Entry review will be implemented in the next layer.")
        )
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }
}
