# SuppliScan — Design Audit (Phase 1)

> Author: redesign pass · Date: 2026-06-13
> Scope: complete UI/UX audit ahead of a premium redesign. No logic, data models, or
> business rules are changed. This is the basis for `DESIGN_SYSTEM.md`.

---

## 1. Current state of UI quality

**Verdict: functionally complete, visually generic. ~4/10 craft.**

The app works end-to-end and the interaction scaffolding is better than average — there
are already physics-based spring animations, sensory haptics on the shutter, a custom
Canvas viewfinder, and staggered entrance animations on the report. But ~70% of the
surface area is **stock SwiftUI chrome**: `Form`, `List`, `.segmented`/`.menu` Picker,
`.borderedProminent` buttons, system `Toggle`, `.alert`/`.confirmationDialog`,
`ContentUnavailableView`, and a near-total reliance on system semantic colors
(`.systemGreen`, `.systemIndigo`, `.systemBackground`). The result reads as a competent
**Settings-app / developer-tool aesthetic** — precisely the look the redesign brief says
to avoid.

The existing `Documentation/UI_SPEC.md` is the *source* of this look: it mandates
"system colours only, no custom hex, `Form` for settings, system fonts, clean and
clinical." That was a deliberate, defensible v1 choice. **The new brief explicitly
overrides it** — premium, design-forward, custom components, liquid-glass feel, custom
Metal shaders, benchmarked against Linear / Flighty / Arc Search / Craft / Apple Wallet /
Apple Invites. This audit and the new design system supersede `UI_SPEC.md` §Design
Language. Where the two conflict, the new system wins; where `UI_SPEC.md` defines
*information architecture* (scroll order, what each section contains, hierarchy intent),
it remains authoritative.

### What's already good (keep the spirit, restyle the surface)
- **ScanView** has genuine craft: a `Canvas`-drawn viewfinder with a pulsing animation,
  a custom two-circle shutter with spring scale + haptics, a gradient scrim. This is the
  one screen that already feels designed. Refine, don't replace.
- **Animation vocabulary** exists: springs in the 0.25–0.70 response range, staggered
  delays (0.05s increments), opacity+offset entrances. It's ad-hoc (values scattered per
  file) but the instinct is right. The design system will *centralize* these into named
  springs so the whole app moves with one voice.
- **`AppTheme`** already centralizes spacing (4/8/12/16/24/32) and nutrient avatar
  colors. Good bones — the new `DesignTokens` will absorb and extend it.
- **Component decomposition** is clean: rows, badges, and cards are already standalone
  files with data-in/callbacks-out. Restyling is mostly local.

### What drags it down
- **Color**: everything is a system color. No brand identity, no signature. The empty
  `AccentColor.colorset` means interactive blue is literally iOS default blue.
- **Surfaces**: flat `secondarySystemBackground` rectangles. No considered elevation,
  material, or depth language. One ad-hoc shadow on `SupplementFactsCardView`.
- **Typography**: pure system text styles, hierarchy by size only, no weight/tracking
  discipline, no numeric/monospaced treatment for the data (RDI%, CFU, mg) that is the
  app's whole point.
- **The report (AnalysisView)** — the product's hero deliverable — is a flat 4-tab
  `Picker` over `List`/`Divider` sections. The most important screen looks the most
  generic.
- **Spacing drift**: stray non-grid values (5, 6, 10, 14, 20, 70) leak in once you leave
  `AppTheme.Spacing`.

---

## 2. What the app's purpose implies about its ideal aesthetic

SuppliScan is a **clinical-grade tool** used in two emotionally opposite moments
(from `PRODUCT_VISION.md`):

1. A **practitioner** reading a report to make a clinical decision in <90s (Job 1/2).
2. An **overwhelmed beginner** who needs a calm, trustworthy verdict (Job 4), and a
   **value-seeker** standing in a chemist needing a verdict in seconds (Job 3).

This rules out two tempting-but-wrong directions:
- **Not** playful wellness (gradients-everywhere, mascots, confetti). It would destroy
  the clinical trust the product is built on.
- **Not** austere developer-tool minimalism (the current state). It's trustworthy but
  forgettable, and it buries the dual-layer hierarchy the product needs.

The right target is **"clinical confidence with tactile craft"** — the feeling of a
premium medical instrument or a Wallet pass: precise, quiet, data-forward, with depth and
motion that make it feel *alive and reassuring* rather than decorated. Specifically:

| Benchmark | What we take from it |
|---|---|
| **Apple Wallet** | Tactile, trustworthy "object in hand" surfaces; content-derived color; the card *is* the hero. Our report and scan-history rows should feel like passes. |
| **Flighty** | Gorgeous **data density** — big confident numbers, beautiful timelines, status that's legible at a glance. Our RDI%/UL/dose data deserves this. |
| **Linear** | Precision, restraint, speed, a tight monochrome-plus-one-accent palette, perfect spacing rhythm. Our type and spacing discipline. |
| **Craft** | Warmth inside structure; soft depth; delightful micro-motion that never feels gratuitous. Our empty states, transitions, and "feel." |
| **Arc Search** | Memorable, choreographed transitions (the "browse for me" unfold). Our scan→review→report flow should have one signature, memorable transition. |
| **Apple Invites** | Editorial confidence, full-bleed color moments, a sense of occasion. Our report header / summary moment. |

**Implication for the system:** a near-monochrome ink palette on warm off-white / true
dark surfaces, **one signature brand color** (a clinical teal/green that nods to the
green Apple-logo motif in `CLAUDE.md`), the tier safety spectrum as the *only* other
semantic color, SF Pro for text + **SF Mono / rounded for the data**, a real elevation
system, and one coherent spring-driven motion language. Color must never be the sole
carrier of clinical meaning (accessibility + the existing "never colour alone" rule).

---

## 3. Screens ranked by work needed

| Rank | Screen | Current | Effort | Why |
|---|---|---|---|---|
| 1 | **AnalysisView** (report) | Flat 4-tab Picker over List/Divider. The hero, looks generic. | ★★★★★ | Highest product value; dual-layer hierarchy; custom tabs, hero summary, card system, choreographed entrance. |
| 2 | **ReviewView** | Settings-form-like; stock TextField/Stepper/Pickers. | ★★★★ | First "premium" touchpoint after scan; needs card layout + custom inputs + inline-edit delight. |
| 3 | **SettingsView** | Pure stock `Form`. | ★★★ | The most generic screen. Must escape Settings aesthetic entirely. |
| 4 | **HistoryView** | Stock `List` + `.searchable` + `EditButton`. | ★★★ | Wallet-style pass cells, custom search, custom swipe actions. |
| 5 | **HomeView** | Centered CTA + recent list; nav `.large` title. | ★★★ | The front door — must set the tone in the first second; signature scan CTA. |
| — | **ScanView** | Already premium (custom viewfinder/shutter). | ★★ | Refine + integrate tokens + signature capture→review transition. |
| — | **NutrientDetailView** | Has custom RDI bar + stat table. | ★★ | Restyle to system; hero nutrient avatar + matchedGeometry from row. |

---

## 4. Inventory of stock defaults to replace

Catalogued across the UI layer (see component table below for per-file detail).

- **Containers**: `Form` (Settings), `List`/`Section`/`.searchable` (History, FormsAndPotency,
  Review entries), `ContentUnavailableView` (Home/History/Analysis empty states).
- **Controls**: `.borderedProminent` / `.borderless` / `.plain` Buttons (no custom
  `ButtonStyle`), `Toggle` (stock), `Picker` `.segmented` (Standard) and `.menu`
  (Demographic, serving unit), `Stepper` (serving qty), `TextField` (product name).
- **Navigation/chrome**: stock `TabView`/`Tab`, `.navigationTitle` (`.large` and
  `.inline`), default toolbar buttons, `EditButton()`.
- **Modals**: `.alert` (errors, ×3), `.confirmationDialog` (delete all),
  `.sheet` + `.presentationDetents` (review entry detail).
- **Color**: system semantic colors throughout; empty `AccentColor`; `.tint(.accentColor)`
  / default tint on `FilterChip` and toggles.
- **Indicators**: `ProgressView()` spinners (Scan OCR, Review analyze button).
- **Transitions**: all motion is opacity+offset; **no** `matchedGeometryEffect`, **no**
  explicit `.transition`, stock push/pop and sheet animations everywhere.
- **Surfaces**: `secondarySystemBackground` flat fills; a single ad-hoc shadow; one
  `.ultraThinMaterial` badge; one `LinearGradient` scrim.

### SF Symbols in use (≈32, all default weight/scale)
`camera.viewfinder`, `chart.bar.doc.horizontal`, `clock.arrow.circlepath`, `gearshape`,
`doc.text.magnifyingglass`, `doc.text.viewfinder`, `checkmark.circle(.fill)`, `chevron.right`,
`flag.fill`, `info.circle`, `lightbulb.fill`, `photo.on.rectangle`, `plus`, `sparkle(s)`,
`questionmark.circle(.fill)`, `slider.horizontal.3`, `square.and.arrow.up`, `text.badge.xmark`,
`trash`, `camera.slash`, `eye.slash`, `number.circle.fill`, `exclamationmark.triangle.fill`,
`exclamationmark.circle.fill`, `checkmark.shield.fill`, `arrow.left.arrow.right.circle.fill`,
`pills.fill`, `arrow.down.circle.fill`. → New system: weight matched to type, consistent
scale per context, a small set promoted to "hero" treatment.

---

## 5. What to keep vs replace

### Keep logic, restyle surface (DO NOT touch data/state wiring)
`HomeView` (@Query, router), `ScanView` (camera/OCR/permissions), `ReviewView`
(ReviewViewModel, entry confirm, analyze orchestration), `AnalysisView` (tab state,
flag generation), `NutrientDetailView` (formatting/animation state), `HistoryView`
(@Query, delete, search filter), `SettingsView` (@AppStorage/persistence),
`RootTabView`/`AnalysisRootView` (@Query, routing), `SupplementFactsCardView`,
`ReviewEntryRowView`, `FlagBannerView` (flag logic), `NutrientAvatarView` (lookup).

### Presentation-only (safe to fully rewrite)
`HomeEmptyStateView`, `HomeScanActionsView`, `HomeRecentScansSectionView`,
`FormsAndPotencyView`, `ScanHistoryRowView`, `FormPotencyRowView`,
`NutrientAnalysisRowView`, `ReportSummaryCardView`, `HerbalRowView`, `ProbioticRowView`,
`UnresolvedLineView`, `AIInferredBadgeView`, `LabelRecognisedBannerView`,
`DisclaimerView`, `ReportSectionHeader`, `NutrientStatTable`, `FilterChip` (polish),
`TierBadgeView`, `ServingSizeSelectorView`, `StandardPickerView`, `DemographicPickerView`.

### Hard constraints carried from CLAUDE.md / AGENTS.md (never violate)
- `@Observable` view models stay `@MainActor`; no ObservableObject/@Published.
- No `DispatchQueue`; structured concurrency only.
- Every report keeps `disclaimer` + `schemaVersion`; `amount: Double?` stays optional.
- All four `LabelEntry` cases (Nutrient/Herbal/Probiotic/RawLine) handled everywhere.
- All SwiftData writes via `PersistenceService`; never from Views.
- Tier colors remain semantic and **never the sole** carrier of meaning (pair with text).

---

## 6. Decision log (resolved without asking, per brief)

1. **Override `UI_SPEC.md` §Design Language** with the new premium system; preserve its
   information architecture. Documented here so the conflict is explicit, not silent.
2. **`DesignTokens.swift` location**: `SuppliScan/SuppliScan/DesignSystem/DesignTokens.swift`,
   not a top-level `Sources/` — the Xcode project uses synchronized folder groups rooted
   at the app folder, so only files under it compile into the target. Same intent as the
   brief, correct location for this project.
3. **Brand color introduced** (a clinical teal-green) — this contradicts the old "no
   custom hex" rule, which the new brief explicitly authorizes. Light/dark variants,
   WCAG-checked, paired with text wherever it carries meaning.
4. **Scope realism**: redesign proceeds highest-value-first (Analysis → Review → Home →
   Scan → History → Settings). Each screen ships compiling + verified before the next.
