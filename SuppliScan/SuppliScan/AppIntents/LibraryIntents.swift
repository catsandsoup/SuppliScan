// LibraryIntents.swift
// SuppliScan
//
// App Intents exposed to Siri, Shortcuts, and Spotlight. Each opens the app and posts a
// navigation request to AppIntentRouter, which RootTabView consumes.

import AppIntents

/// "Look up magnesium in SuppliScan" → opens the Library entry.
struct OpenLibraryEntryIntent: AppIntent {
    static let title: LocalizedStringResource = "Look Up Supplement"
    static let description = IntentDescription(
        "Open a nutrient, botanical, or probiotic in the SuppliScan Library."
    )
    static let openAppWhenRun = true

    @Parameter(title: "Supplement")
    var entry: LibraryEntryEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppIntentRouter.shared.request = .libraryEntry(id: entry.id)
        return .result()
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Look up \(\.$entry)")
    }
}

/// "Scan a label with SuppliScan" → opens the scanner.
struct ScanLabelIntent: AppIntent {
    static let title: LocalizedStringResource = "Scan a Supplement Label"
    static let description = IntentDescription(
        "Open SuppliScan's scanner to capture a supplement label."
    )
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppIntentRouter.shared.request = .scan
        return .result()
    }
}
