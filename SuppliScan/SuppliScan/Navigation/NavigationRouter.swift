// NavigationRouter.swift
// SuppliScan
//
// Owns all navigation state. Injected at the root via .environment.
// Views call router.navigate(to:) — no view has direct knowledge of any other view.
// Single NavigationStack at app root — never nest NavigationStacks.

import SwiftUI

@Observable
@MainActor
final class NavigationRouter {
    var path = NavigationPath()

    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
