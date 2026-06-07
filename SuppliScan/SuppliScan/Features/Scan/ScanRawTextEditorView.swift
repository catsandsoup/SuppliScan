// ScanRawTextEditorView.swift
// SuppliScan

import SwiftUI

struct ScanRawTextEditorView: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recognized Text")
                .font(.headline)

            TextEditor(text: $text)
                .frame(minHeight: 240)
                .padding(8)
                .background(.background.secondary, in: .rect(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.separator, lineWidth: 1)
                }
                .accessibilityLabel("Recognized label text")
        }
    }
}
