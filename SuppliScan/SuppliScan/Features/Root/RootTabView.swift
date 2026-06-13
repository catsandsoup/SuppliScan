// RootTabView.swift
// SuppliScan
//
// App root — custom 4-tab container with a floating Liquid-Glass tab bar.
// Home (front door) · Scan (camera) · History · Settings. The clinical report
// (AnalysisView) is a pushed destination reached from Home/History/Review — not a tab,
// because there is nothing to analyse until something has been scanned.
// Each tab owns an independent NavigationRouter + NavigationStack, kept alive across
// tab switches (state preserved) and cross-faded.

import SwiftUI

@MainActor
struct RootTabView: View {
    @Environment(AppDependencies.self) private var dependencies

    @State private var selectedTab: AppTab = .initial
    @State private var homeRouter = NavigationRouter()
    @State private var scanRouter = NavigationRouter()
    @State private var historyRouter = NavigationRouter()

    enum AppTab: Hashable {
        case home, scan, history, settings

        /// Default selected tab. DEBUG builds honour a `-startTab <name>` launch argument
        /// so the simulator can open directly to any tab for verification. No effect in release.
        static var initial: AppTab {
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-startTab"), i + 1 < args.count {
                switch args[i + 1] {
                case "scan":     return .scan
                case "history":  return .history
                case "settings": return .settings
                default:         return .home
                }
            }
            #endif
            return .home
        }
    }

    private let items: [GlassTabBarItem<AppTab>] = [
        .init(tab: .home,     title: "Home",     icon: "house"),
        .init(tab: .scan,     title: "Scan",     icon: "camera.viewfinder"),
        .init(tab: .history,  title: "History",  icon: "clock.arrow.circlepath"),
        .init(tab: .settings, title: "Settings", icon: "gearshape")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Palette.surface.ignoresSafeArea()

            ZStack {
                tabContainer(.home) { homeTab }
                tabContainer(.scan) { scanTab }
                tabContainer(.history) { historyTab }
                tabContainer(.settings) { settingsTab }
            }

            GlassTabBar(items: items, selection: $selectedTab)
                .padding(.horizontal, Theme.Space.xl)
                .padding(.bottom, Theme.Space.xs)
                .offset(y: tabBarVisible ? 0 : 160)
                .opacity(tabBarVisible ? 1 : 0)
                .animation(.dsPrimary, value: tabBarVisible)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }

    /// The tab bar hides while the active tab has pushed a detail screen (report, review,
    /// nutrient detail) — standard iOS behaviour, and it frees the bottom for action bars.
    private var tabBarVisible: Bool {
        switch selectedTab {
        case .home:     return homeRouter.path.isEmpty
        case .scan:     return scanRouter.path.isEmpty
        case .history:  return historyRouter.path.isEmpty
        case .settings: return true
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

    private var homeTab: some View {
        NavigationStack(path: Bindable(homeRouter).path) {
            HomeView()
                .navigationDestination(for: AppDestination.self) { dest in
                    AppDestinationView(destination: dest)
                }
        }
        .environment(homeRouter)
    }

    private var scanTab: some View {
        NavigationStack(path: Bindable(scanRouter).path) {
            ScanView()
                .navigationDestination(for: AppDestination.self) { dest in
                    AppDestinationView(destination: dest)
                }
        }
        .environment(scanRouter)
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
