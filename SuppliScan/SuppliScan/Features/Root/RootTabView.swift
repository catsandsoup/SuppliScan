// RootTabView.swift
// SuppliScan
//
// App root — 4-tab container.
// Each tab owns an independent NavigationRouter and NavigationStack.
// Analysis results push within the Scan tab's stack (Option A navigation).
// The Analysis tab shows AnalysisRootView which reads AnalysisStore.

import SwiftUI

@MainActor
struct RootTabView: View {
    @Environment(AppDependencies.self) private var dependencies

    @State private var selectedTab: AppTab = .scan
    @State private var scanRouter = NavigationRouter()
    @State private var analysisRouter = NavigationRouter()
    @State private var historyRouter = NavigationRouter()
    @State private var analysisStore = AnalysisStore()

    enum AppTab {
        case scan, analysis, history, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Scan", systemImage: "camera.viewfinder", value: AppTab.scan) {
                scanTab
            }
            Tab("Analysis", systemImage: "chart.bar.doc.horizontal", value: AppTab.analysis) {
                analysisTab
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                historyTab
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                settingsTab
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(analysisStore)
        #if DEBUG
        .onAppear { injectSeedDataIfNeeded() }
        #endif
    }

    #if DEBUG
    private func injectSeedDataIfNeeded() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--uitest-supplement-seed") else { return }
        analysisStore.currentAnalysis = SampleData.analysis
        selectedTab = .analysis
        if args.contains("--screen=nutrient-detail") {
            if let first = SampleData.analysis.nutrientAnalyses.first {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(200))
                    analysisRouter.navigate(to: .nutrientDetail(first))
                }
            }
        }
    }
    #endif

    // MARK: - Tabs

    private var scanTab: some View {
        NavigationStack(path: Bindable(scanRouter).path) {
            ScanView()
                .navigationDestination(for: AppDestination.self) { dest in
                    AppDestinationView(destination: dest)
                }
        }
        .environment(scanRouter)
    }

    private var analysisTab: some View {
        NavigationStack(path: Bindable(analysisRouter).path) {
            AnalysisRootView()
                .navigationDestination(for: AppDestination.self) { dest in
                    AppDestinationView(destination: dest)
                }
        }
        .environment(analysisRouter)
    }

    private var historyTab: some View {
        NavigationStack(path: Bindable(historyRouter).path) {
            HistoryView()
                .navigationDestination(for: AppDestination.self) { dest in
                    AppDestinationView(destination: dest)
                }
        }
        .environment(historyRouter)
    }

    private var settingsTab: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
