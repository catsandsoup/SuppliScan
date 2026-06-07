// AppDestination.swift
// SuppliScan
//
// All push-navigation destinations in the app.
// NavigationRouter appends these to its NavigationPath.
// Views use navigationDestination(for: AppDestination.self) at the root.
//
// Hashable via id-based equality on associated value types —
// safe for NavigationPath without deep value comparison.

import Foundation

enum AppDestination: Hashable, Sendable {
    case scan
    case review(entries: [LabelEntry], serving: ServingSize?)
    case report(LabelAnalysis)
    case history
}
