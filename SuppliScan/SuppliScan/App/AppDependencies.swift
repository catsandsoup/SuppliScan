// AppDependencies.swift
// SuppliScan
//
// Service instantiation and dependency injection container.
// Created once at app launch in SuppliScanApp.init().
// Injected into the view hierarchy via .environment.
//
// No service locator. No global singletons except NavigationRouter
// (which must be @Observable for SwiftUI binding).

import SwiftData
import Foundation

/// Holds all service instances for the app.
/// Passed down via SwiftUI environment from the root.
@Observable
@MainActor
final class AppDependencies {
    let persistence: PersistenceService
    let ocrService: OCRService
    let parserService: ParserService

    // Services are instantiated here and injected where needed.
    // ViewModels receive services via their initialiser.

    init(container: ModelContainer) {
        self.persistence = PersistenceService(container: container)
        self.ocrService = OCRService()
        self.parserService = (try? ParserService.makeDefault()) ?? ParserService()
    }
}
