// RootTabView.swift
// SuppliScan
//
// App root — custom 4-tab container with a floating Liquid-Glass tab bar.
// Each tab owns an independent NavigationRouter + NavigationStack, kept alive across
// tab switches (state preserved) and cross-faded. Replaces the stock TabView chrome
// without changing navigation behaviour.

import SwiftUI

@MainActor
struct RootTabView: View {
    @Environment(AppDependencies.self) private var dependencies

    @State private var selectedTab: AppTab = .initial
    @State private var scanRouter = NavigationRouter()
    @State private var analysisRouter = NavigationRouter()
    @State private var historyRouter = NavigationRouter()

    enum AppTab: Hashable {
        case scan, analysis, history, settings

        /// Default selected tab. DEBUG builds honour a `-startTab <name>` launch argument
        /// so the simulator can open directly to any tab for verification. No effect in release.
        static var initial: AppTab {
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-startTab"), i + 1 < args.count {
                switch args[i + 1] {
                case "analysis": return .analysis
                case "history":  return .history
                case "settings": return .settings
                default:         return .scan
                }
            }
            #endif
            return .scan
        }
    }

    private let items: [GlassTabBarItem<AppTab>] = [
        .init(tab: .scan,     title: "Scan",     icon: "camera.viewfinder"),
        .init(tab: .analysis, title: "Analysis", icon: "chart.bar.doc.horizontal"),
        .init(tab: .history,  title: "History",  icon: "clock.arrow.circlepath"),
        .init(tab: .settings, title: "Settings", icon: "gearshape")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Palette.surface.ignoresSafeArea()

            ZStack {
                tabContainer(.scan) { scanTab }
                tabContainer(.analysis) { analysisTab }
                tabContainer(.history) { historyTab }
                tabContainer(.settings) { settingsTab }
            }

            GlassTabBar(items: items, selection: $selectedTab)
                .padding(.horizontal, Theme.Space.xl)
                .padding(.bottom, Theme.Space.xs)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    @ViewBuilder
    private func tabContainer<Content: View>(
        _ tab: AppTab,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        let isActive = selectedTab == tab
        content()
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
            .accessibilityHidden(!isActive)
            .zIndex(isActive ? 1 : 0)
            .animation(.dsFade, value: selectedTab)
    }

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
