// ScanView.swift
// SuppliScan — STUB (full implementation in Views layer)
// Skills to invoke when implementing: swiftui-pro, swiftui-liquid-glass, ios-accessibility

import SwiftUI

struct ScanView: View {
    @Environment(NavigationRouter.self) private var router

    var body: some View {
        ContentUnavailableView(
            "Scanner Coming Soon",
            systemImage: "camera.viewfinder",
            description: Text("OCR scanning will be implemented in the next layer.")
        )
        .navigationTitle("Scan Label")
        .navigationBarTitleDisplayMode(.inline)
    }
}
