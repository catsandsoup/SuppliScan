// SuppliScanShortcuts.swift
// SuppliScan
//
// Surfaces the app's intents to Siri and the Shortcuts app with spoken phrases, and makes
// the intents discoverable without any user setup.

import AppIntents

struct SuppliScanShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanLabelIntent(),
            phrases: [
                "Scan a label with \(.applicationName)",
                "Scan a supplement with \(.applicationName)",
                "New scan in \(.applicationName)"
            ],
            shortTitle: "Scan Label",
            systemImageName: "camera.viewfinder"
        )
        AppShortcut(
            intent: OpenLibraryEntryIntent(),
            phrases: [
                "Look up \(\.$entry) in \(.applicationName)",
                "Open \(\.$entry) in \(.applicationName)",
                "Show \(\.$entry) in \(.applicationName)"
            ],
            shortTitle: "Look Up Supplement",
            systemImageName: "books.vertical"
        )
    }
}
