// AnalysisShareContent.swift
// SuppliScan
//
// Multi-representation share payload. Image-forward channels (iMessage, social) get the
// rendered summary card; text channels (Notes, Mail, Reminders) get the rich text summary.
// One tap on Share, the right thing for every destination.

import SwiftUI

struct AnalysisShareContent: Transferable {
    let image: Image
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        // Image first → rich channels render the branded card.
        ProxyRepresentation(exporting: \.image)
        // Text fallback → Notes/Mail/etc. get the structured summary.
        ProxyRepresentation(exporting: \.text)
    }
}

@MainActor
enum AnalysisShareRenderer {
    /// Render the summary card to a shareable Image at 3× for crisp delivery. Nil on failure.
    static func renderCard(for analysis: LabelAnalysis) -> Image? {
        let renderer = ImageRenderer(content: ShareSummaryCardView(analysis: analysis))
        renderer.scale = 3
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}
