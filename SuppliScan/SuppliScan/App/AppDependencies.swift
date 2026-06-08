// AppDependencies.swift
// SuppliScan
//
// Service instantiation and dependency injection container.
// Created once at app launch in SuppliScanApp.init().
// Injected into the view hierarchy via .environment.
//
// Call load() from SuppliScanApp once the WindowGroup body is ready.
// No service locator. No global singletons except NavigationRouter.

import SwiftData
import Foundation
import OSLog

/// Holds all service instances for the app.
/// Passed down via SwiftUI environment from the root.
@Observable
@MainActor
final class AppDependencies {
    let persistence: PersistenceService
    let ocrService: OCRService
    let parserService: ParserService
    let referenceDataService: ReferenceDataService
    let formQualityService: FormQualityService
    let interactionService: InteractionService
    let reportService: ReportService

    init(container: ModelContainer) {
        self.persistence = PersistenceService(container: container)
        self.ocrService = OCRService()
        self.parserService = (try? ParserService.makeDefault()) ?? ParserService()

        let ref = ReferenceDataService()
        let form = FormQualityService()
        let inter = InteractionService()
        self.referenceDataService = ref
        self.formQualityService = form
        self.interactionService = inter
        self.reportService = ReportService(
            referenceDataService: ref,
            formQualityService: form,
            interactionService: inter
        )
    }

    /// Load all bundled reference data. Call once from SuppliScanApp on appear.
    /// Failures are logged and skipped — the app remains functional without reference data.
    func load() async {
        do {
            try await referenceDataService.load()
        } catch {
            Logger.suppliScan.error("AppDependencies: referenceDataService.load failed: \(error)")
        }
        do {
            try await formQualityService.load()
        } catch {
            Logger.suppliScan.error("AppDependencies: formQualityService.load failed: \(error)")
        }
        do {
            try await interactionService.load()
        } catch {
            Logger.suppliScan.error("AppDependencies: interactionService.load failed: \(error)")
        }
    }
}
