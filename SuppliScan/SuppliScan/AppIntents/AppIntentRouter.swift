// AppIntentRouter.swift
// SuppliScan
//
// Bridge between App Intents (Siri / Shortcuts / Spotlight) and in-app navigation.
// App Intents run outside the SwiftUI hierarchy and cannot touch navigation directly,
// so they post a request here and RootTabView observes it and performs the navigation.
// This is the single sanctioned global beyond NavigationRouter — App Intents fundamentally
// require a process-wide bridge.

import Foundation
import Observation

@MainActor
@Observable
final class AppIntentRouter {
    static let shared = AppIntentRouter()
    private init() {}

    /// A pending navigation request from an App Intent / Shortcut / Spotlight result.
    /// RootTabView consumes this (sets it back to nil) once handled.
    var request: AppIntentRequest?
}

enum AppIntentRequest: Equatable, Sendable {
    case scan
    case libraryEntry(id: String)
}
