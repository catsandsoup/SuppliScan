// SuppliScanApp.swift
// SuppliScan
//
// @main entry point. Creates ModelContainer with versioned schema and
// migration plan. Falls back to an in-memory container on init failure —
// never crashes. Injects NavigationRouter and AppDependencies into the
// environment at the root.
//
// DO NOT inject modelContainer here for View use via .modelContainer().
// PersistenceService owns the write context. @Query in HistoryView and
// HomeView uses the separate view context injected by .modelContainer().

import SwiftUI
import SwiftData
import OSLog

@main
struct SuppliScanApp: App {
    private let container: ModelContainer
    private let dependencies: AppDependencies

    init() {
        let built = Self.makeContainer()
        self.container = built

        // AppDependencies must be created on MainActor but init() is non-isolated.
        // Use MainActor.assumeIsolated — safe here because App.init() is called
        // on the main thread before any async work begins.
        self.dependencies = MainActor.assumeIsolated {
            AppDependencies(container: built)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(dependencies)
                .task {
                    #if DEBUG
                    seedSampleDataIfRequested()
                    #endif
                    await dependencies.load()
                }
        }
        // Inject for @Query reads in Views (HistoryView, HomeView)
        .modelContainer(container)
    }

    #if DEBUG
    /// Seeds one sample scan for simulator verification when launched with `-seedSample`.
    /// No-op unless the argument is present and the store is empty. Never in release builds.
    @MainActor
    private func seedSampleDataIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-seedSample") else { return }
        let context = container.mainContext
        let existing = (try? context.fetchCount(FetchDescriptor<ScanRecord>())) ?? 0
        guard existing == 0 else { return }
        let analysis = SampleData.analysis
        guard let data = try? analysis.encoded() else { return }
        let record = ScanRecord(
            id: analysis.id,
            createdAt: analysis.createdAt,
            productName: analysis.productName,
            referenceStandard: analysis.referenceStandard.rawValue,
            demographicKey: analysis.demographic.key,
            reportData: data,
            schemaVersion: LabelAnalysis.currentSchemaVersion
        )
        context.insert(record)
        try? context.save()
    }
    #endif

    // MARK: - Container Init

    private static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: ScanRecord.self,
                migrationPlan: SuppliScanMigrationPlan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            // Container init failed — log and fall back to in-memory.
            // App remains functional; scan history will not persist this session.
            Logger.persistence.critical("ModelContainer init failed: \(error.localizedDescription) — falling back to in-memory container")
            do {
                return try ModelContainer(
                    for: ScanRecord.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                // In-memory fallback also failed — unrecoverable.
                // This should never happen and indicates a fundamental SDK issue.
                Logger.persistence.critical("In-memory ModelContainer fallback also failed: \(error.localizedDescription)")
                fatalError("Cannot create ModelContainer: \(error)")
            }
        }
    }
}
