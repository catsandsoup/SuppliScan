// LibraryView.swift
// SuppliScan
//
// The Library tab — a browsable, source-backed reference encyclopedia of nutrients,
// botanicals and probiotics. Search + category filter, pinned above a sectioned list.
// Built entirely on curated data (LibraryCatalog); nothing here is fabricated.

import SwiftUI

struct LibraryView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(NavigationRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var searchText = ""
    @State private var filter: LibraryCategoryFilter = .all
    @State private var rowTapCount = 0

    /// Bottom inset so the list clears the floating glass tab bar.
    private static let tabBarClearance: CGFloat = 96

    private var catalog: [LibraryEntry] { dependencies.libraryCatalog.entries }

    private var filtered: [LibraryEntry] {
        let needle = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return catalog.filter { entry in
            filter.matches(entry.category) && Self.matches(entry, needle: needle)
        }
    }

    private var sections: [(category: SupplementKnowledgeCategory, entries: [LibraryEntry])] {
        Dictionary(grouping: filtered, by: \.category)
            .sorted { $0.key.sortRank < $1.key.sortRank }
            .map { (category: $0.key, entries: $0.value) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchField
                .padding(.horizontal, Theme.Space.screen)
                .padding(.bottom, Theme.Space.md)
            filterBar
                .padding(.bottom, Theme.Space.sm)
            list
        }
        .screenBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: rowTapCount)
        .sensoryFeedback(.selection, trigger: filter)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("Reference")
                .textStyle(.eyebrow)
                .foregroundStyle(.brand)
            Text("Library")
                .textStyle(.display)
                .foregroundStyle(.ink)
            Text("\(catalog.count) nutrients, botanicals & probiotics — with forms ranked by evidence.")
                .textStyle(.subhead)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, Theme.Space.xs)
        .padding(.bottom, Theme.Space.lg)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Theme.Icon.sm, weight: .semibold))
                .foregroundStyle(.inkTertiary)
            TextField("Search nutrients, forms, uses", text: $searchText)
                .textStyle(.body)
                .foregroundStyle(.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Theme.Icon.sm))
                        .foregroundStyle(.inkTertiary)
                }
                .accessibilityLabel("Clear search")
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.Space.lg)
        .frame(minHeight: 48)
        .background(.surfaceSunken, in: Theme.roundedRect(Theme.Radius.sm))
        .overlay(Theme.roundedRect(Theme.Radius.sm).strokeBorder(.hairline, lineWidth: 1))
        .animation(.dsMicro, value: searchText.isEmpty)
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Space.sm) {
                ForEach(LibraryCategoryFilter.allCases) { option in
                    FilterChip(
                        label: option.title,
                        isSelected: filter == option
                    ) {
                        withAnimation(.dsSnappy) { filter = option }
                    }
                }
            }
            .padding(.horizontal, Theme.Space.screen)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if filtered.isEmpty {
            ContentUnavailableView {
                Label("No matches", systemImage: "magnifyingglass")
            } description: {
                Text("Try a different name, form, or use — like “magnesium”, “glycinate”, or “sleep”.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Space.xl, pinnedViews: []) {
                    ForEach(sections, id: \.category) { section in
                        VStack(alignment: .leading, spacing: Theme.Space.sm) {
                            SectionHeader(title: section.category.pluralName)
                                .padding(.horizontal, Theme.Space.screen)

                            LazyVStack(spacing: 0) {
                                ForEach(section.entries) { entry in
                                    Button {
                                        rowTapCount += 1
                                        router.navigate(to: .libraryEntry(entry))
                                    } label: {
                                        LibraryRowView(entry: entry)
                                    }
                                    .buttonStyle(.plain)

                                    if entry.id != section.entries.last?.id {
                                        HairlineDivider(leadingInset: 68)
                                    }
                                }
                            }
                            .dsSurface()
                            .padding(.horizontal, Theme.Space.screen)
                        }
                    }
                }
                .padding(.top, Theme.Space.sm)
                .padding(.bottom, Self.tabBarClearance)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    // MARK: - Search matching

    private static func matches(_ entry: LibraryEntry, needle: String) -> Bool {
        guard !needle.isEmpty else { return true }
        if entry.canonicalName.lowercased().contains(needle) { return true }
        if entry.aliases.contains(where: { $0.lowercased().contains(needle) }) { return true }
        if entry.forms.contains(where: { $0.name.lowercased().contains(needle) }) { return true }
        if entry.activeCompounds.contains(where: { $0.lowercased().contains(needle) }) { return true }
        if entry.roles.contains(where: { $0.lowercased().contains(needle) }) { return true }
        return false
    }
}

// MARK: - Category filter

nonisolated enum LibraryCategoryFilter: String, CaseIterable, Identifiable, Hashable {
    case all, vitamins, minerals, botanicals, probiotics, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:        "All"
        case .vitamins:   "Vitamins"
        case .minerals:   "Minerals"
        case .botanicals: "Botanicals"
        case .probiotics: "Probiotics"
        case .other:      "Other"
        }
    }

    func matches(_ category: SupplementKnowledgeCategory) -> Bool {
        switch self {
        case .all:        true
        case .vitamins:   category == .vitamin
        case .minerals:   category == .mineral
        case .botanicals: category == .botanical
        case .probiotics: category == .probiotic
        case .other:      [.fattyAcid, .aminoAcid, .bioflavonoid, .other].contains(category)
        }
    }
}

// MARK: - Row

private struct LibraryRowView: View {
    let entry: LibraryEntry

    var body: some View {
        HStack(spacing: Theme.Space.md) {
            LibraryAvatarView(category: entry.category)

            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(entry.canonicalName)
                    .textStyle(.headline)
                    .foregroundStyle(.ink)
                Text(entry.summary)
                    .textStyle(.caption)
                    .foregroundStyle(.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Theme.Space.sm)

            if let tier = entry.bestTier {
                TierBadgeView(tier: tier)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: Theme.Icon.xs, weight: .semibold))
                .foregroundStyle(.inkFaint)
        }
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, Theme.Space.md)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(entry.canonicalName) reference")
    }
}
