// LibraryEntryDetailView.swift
// SuppliScan
//
// Encyclopedia detail: roles, forms ranked by bioavailability evidence, active compounds,
// typical dosing, clinical notes, and cited federal sources. Everything is source-backed —
// no fabricated per-form clinical claims. Dual audience: clinicians get evidence + citations,
// consumers get plain-language roles and clear form guidance.

import SwiftUI

struct LibraryEntryDetailView: View {
    let entry: LibraryEntry

    private var rankedForms: [LibraryForm] { entry.forms.filter { $0.tier != nil } }
    private var otherForms: [LibraryForm] { entry.forms.filter { $0.tier == nil } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                header

                if !entry.roles.isEmpty {
                    rolesSection
                }
                if !entry.forms.isEmpty {
                    formsSection
                }
                if !entry.activeCompounds.isEmpty {
                    activeCompoundsSection
                }
                if !entry.doseContexts.isEmpty {
                    dosingSection
                }
                if !entry.clinicalNotes.isEmpty {
                    notesSection
                }
                if !entry.sources.isEmpty {
                    sourcesSection
                }

                DisclaimerView(text: Self.disclaimer)

                Spacer(minLength: Theme.Space.xl)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.top, Theme.Space.md)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .navigationTitle(entry.canonicalName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: Theme.Space.md) {
            LibraryAvatarView(category: entry.category, size: 56)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(entry.category.displayName.uppercased())
                    .textStyle(.eyebrow)
                    .foregroundStyle(.brand)
                Text(entry.canonicalName)
                    .textStyle(.title)
                    .foregroundStyle(.ink)
                    .lineLimit(2)
                if !entry.aliases.isEmpty {
                    Text("Also: \(entry.aliases.joined(separator: ", "))")
                        .textStyle(.caption)
                        .foregroundStyle(.inkTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Roles

    private var rolesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionHeader(title: "Roles & Uses")
            VStack(alignment: .leading, spacing: Theme.Space.sm) {
                Text(entry.roles.map(\.sentenceCased).joined(separator: "  ·  "))
                    .textStyle(.body)
                    .foregroundStyle(.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("General physiological roles and marketed uses — not a personalised clinical recommendation.")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
            }
            .dsCard()
        }
    }

    // MARK: - Forms

    private var formsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionHeader(
                eyebrow: rankedForms.isEmpty ? nil : "Best evidence first",
                title: rankedForms.isEmpty ? "Common Forms" : "Forms by Quality"
            )
            VStack(spacing: 0) {
                ForEach(Array(entry.forms.enumerated()), id: \.element.id) { index, form in
                    LibraryFormRow(form: form)
                    if index < entry.forms.count - 1 {
                        HairlineDivider()
                    }
                }
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.vertical, Theme.Space.xs)
            .dsSurface()

            if !rankedForms.isEmpty {
                Text("Quality tiers reflect absorption and bioavailability evidence. Higher tiers are generally better utilised, but the right form depends on the individual.")
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Active compounds

    private var activeCompoundsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionHeader(title: "Active Compounds")
            Text(entry.activeCompounds.map(\.sentenceCased).joined(separator: "  ·  "))
                .textStyle(.body)
                .foregroundStyle(.ink)
                .fixedSize(horizontal: false, vertical: true)
                .dsCard()
        }
    }

    // MARK: - Dosing

    private var dosingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionHeader(title: "Typical Dosing Context")
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                ForEach(Array(entry.doseContexts.enumerated()), id: \.offset) { _, dose in
                    DoseContextRow(dose: dose)
                }
            }
            .dsCard()
        }
    }

    // MARK: - Clinical notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionHeader(title: "Clinical Notes")
            VStack(alignment: .leading, spacing: Theme.Space.lg) {
                ForEach(Array(entry.clinicalNotes.enumerated()), id: \.offset) { _, note in
                    VStack(alignment: .leading, spacing: Theme.Space.xs) {
                        HStack(spacing: Theme.Space.sm) {
                            Text(note.topic.sentenceCased)
                                .textStyle(.subhead)
                                .foregroundStyle(.ink)
                            Spacer(minLength: Theme.Space.sm)
                            EvidenceBadge(raw: note.evidenceLevel)
                        }
                        Text(note.text)
                            .textStyle(.callout)
                            .foregroundStyle(.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .dsCard()
        }
    }

    // MARK: - Sources

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            SectionHeader(title: "Sources")
            VStack(spacing: 0) {
                ForEach(Array(entry.sources.enumerated()), id: \.element.id) { index, source in
                    Link(destination: source.url) {
                        HStack(alignment: .top, spacing: Theme.Space.md) {
                            Image(systemName: "text.book.closed.fill")
                                .font(.system(size: Theme.Icon.sm, weight: .semibold))
                                .foregroundStyle(.brand)
                                .padding(.top, 1)
                            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                                Text(source.title)
                                    .textStyle(.subhead)
                                    .foregroundStyle(.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(Self.formatType(source.sourceType))
                                    .textStyle(.caption)
                                    .foregroundStyle(.inkTertiary)
                            }
                            Spacer(minLength: Theme.Space.sm)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: Theme.Icon.xs, weight: .semibold))
                                .foregroundStyle(.inkFaint)
                                .padding(.top, 2)
                        }
                        .padding(.vertical, Theme.Space.md)
                        .contentShape(.rect)
                    }
                    .accessibilityHint("Opens source in browser")

                    if index < entry.sources.count - 1 {
                        HairlineDivider()
                    }
                }
            }
            .padding(.horizontal, Theme.Space.lg)
            .dsSurface()
        }
    }

    // MARK: - Helpers

    private static let disclaimer = "Educational reference only. Not medical advice, a diagnosis, or a treatment recommendation. Always consult a qualified healthcare professional before starting, stopping, or changing any supplement."

    static func formatType(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").sentenceCased
    }
}

// MARK: - Form row

private struct LibraryFormRow: View {
    let form: LibraryForm

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.md) {
            tierGlyph
                .frame(width: 28)
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                HStack(spacing: Theme.Space.sm) {
                    Text(form.name.capitalized)
                        .textStyle(.subhead)
                        .foregroundStyle(.ink)
                    Spacer(minLength: Theme.Space.sm)
                    if let tier = form.tier {
                        TierBadgeView(tier: tier)
                    }
                }
                if let rationale = form.rationale {
                    Text(rationale)
                        .textStyle(.caption)
                        .foregroundStyle(.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !form.references.isEmpty {
                    HStack(spacing: Theme.Space.xs) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: Theme.Icon.xs, weight: .semibold))
                            .foregroundStyle(.inkTertiary)
                        Text(form.references.joined(separator: " · "))
                            .textStyle(.caption)
                            .foregroundStyle(.inkTertiary)
                    }
                    .padding(.top, Theme.Space.xxs)
                }
            }
        }
        .padding(.vertical, Theme.Space.md)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var tierGlyph: some View {
        if let tier = form.tier {
            Text(tier.displayLabel)
                .font(.dsCaption.weight(.bold))
                .foregroundStyle(tier.badgeColor)
                .frame(width: 28, height: 28)
                .background(tier.badgeColor.opacity(0.14), in: Circle())
        } else {
            Circle()
                .fill(.surfaceSunken)
                .frame(width: 28, height: 28)
                .overlay(Circle().strokeBorder(.hairline, lineWidth: 1))
        }
    }
}

// MARK: - Dose context row

private struct DoseContextRow: View {
    let dose: SupplementDoseContext

    private var amountText: String? {
        switch (dose.lowerBound, dose.upperBound) {
        case let (lower?, upper?): return "\(lower.formatted())–\(upper.formatted()) \(dose.unit)"
        case let (nil, upper?):    return "≤ \(upper.formatted()) \(dose.unit)"
        case let (lower?, nil):    return "≥ \(lower.formatted()) \(dose.unit)"
        case (nil, nil):           return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                Text(dose.context.sentenceCased)
                    .textStyle(.subhead)
                    .foregroundStyle(.ink)
                Spacer(minLength: Theme.Space.sm)
                if let amountText {
                    Text(amountText)
                        .textStyle(.dataLabel)
                        .foregroundStyle(.brand)
                        .monospacedDigit()
                }
            }
            if let population = dose.population {
                Text(population.sentenceCased)
                    .textStyle(.caption)
                    .foregroundStyle(.inkTertiary)
            }
            Text(dose.interpretation)
                .textStyle(.callout)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            EvidenceBadge(raw: dose.evidenceLevel)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Evidence badge

private struct EvidenceBadge: View {
    let raw: String

    var body: some View {
        Text(raw.replacingOccurrences(of: "_", with: " ").sentenceCased)
            .font(.dsCaption.weight(.medium))
            .foregroundStyle(.inkSecondary)
            .padding(.horizontal, Theme.Space.sm)
            .padding(.vertical, Theme.Space.xxs)
            .background(.surfaceSunken, in: Capsule())
            .overlay(Capsule().strokeBorder(.hairline, lineWidth: 1))
            .accessibilityLabel("Evidence level: \(raw.replacingOccurrences(of: "_", with: " "))")
    }
}
