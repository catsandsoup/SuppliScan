# NutriScan — UI Specification
# Mapped to Apple HIG (iOS) and SwiftUI Best Practices
# Skills for this document: `swiftui-pro`, `swiftui-ui-patterns`, `swiftui-design-principles`,
#   `swiftui-liquid-glass`, `swiftui-accessibility-auditor`, `writing-for-interfaces`
# Invoke `swiftui-pro` before writing any screen. Invoke `swiftui-liquid-glass` for iOS 26 surfaces.
# Invoke `swiftui-accessibility-auditor` after completing each screen.

## Design Language

### Principle
Clean and clinical. Every element earns its place.
Whitespace is structural, not decorative. Hierarchy is visible at a glance.
The app looks like a tool a clinician trusts, not a consumer wellness product.

### Colour
- Background: system background (.background) — adapts to light/dark automatically
- Secondary surfaces: secondary system background (.secondarySystemBackground)
- Primary text: label (.primary)
- Secondary text: secondaryLabel (.secondary)
- Accent: single system blue — used only for interactive elements and primary actions
- Tier indicators (the only semantic colour in the app):
  - Tier 1: systemGreen
  - Tier 2: systemYellow
  - Tier 3: systemOrange
  - Tier 4: systemRed
  - AI-inferred: systemPurple (always combined with text label, never colour alone)
- No custom hex colours. All colours from the system semantic palette.
  Rationale: automatic dark mode, accessibility contrast compliance, system coherence.

### Typography
- All fonts via `.font()` modifier with system styles — never hardcoded sizes
- Hierarchy in use:
  - `.largeTitle` — screen titles only (used sparingly)
  - `.title2` — section headers within report
  - `.headline` — nutrient names in report table
  - `.body` — primary content, rationale text
  - `.subheadline` — secondary labels, units, citations
  - `.caption` — disclaimer, AI-inferred labels, footnotes
- No custom fonts. System font (SF Pro) throughout.
  Rationale: Dynamic Type support, no font loading, full HIG compliance.

### Spacing
- Use system spacing values: 8, 12, 16, 20, 24pt
- Generous vertical padding between report sections — clinical readability
- No elements touching screen edges — minimum 16pt horizontal margin
- List rows: minimum 44pt tap target height (HIG requirement)

### Icons
- SF Symbols exclusively. No third-party icon libraries.
- Weight matches surrounding text weight
- Symbols are supplementary — never the sole communicator of meaning

---

## Screen Inventory

### 1. HomeView
**Purpose:** Entry point. Single action.

**Layout:**
- Navigation bar: app name left, settings gear right
- Centre: large scan button (`.prominent` button style, full width minus margins)
- Below button: "or enter manually" secondary link (`.borderless` button)
- Bottom: recent scans list (last 3, tappable) with "See all" trailing link

**HIG notes:**
- Large tap target on primary action — clinician may be using app one-handed
- Recent scans gives immediate re-access without navigating to history
- No hero imagery, no marketing copy — this is a tool

**SwiftUI implementation notes:**
- `NavigationStack` root view
- Recent scans driven by `@Query` from SwiftData — live, no manual refresh
- Scan button navigates programmatically via `NavigationRouter`

---

### 2. ScanView
**Purpose:** Camera + OCR. Capture the label.

**Layout:**
- Full-screen camera preview (no navigation bar overlay)
- Overlay: thin rectangular viewfinder guide (not a hard crop — guidance only)
- Bottom sheet (half-height): "Scanning..." → transitions to extracted list on completion
- Cancel button top-left (always visible)

**HIG notes:**
- Full-screen camera is standard iOS pattern (Camera app, Document Scanner)
- Bottom sheet keeps controls in thumb reach
- Viewfinder guide sets user expectation without constraining capture

**SwiftUI implementation notes:**
- Camera via `UIViewRepresentable` wrapping `AVCaptureSession`
- VisionKit `VNRecognizeTextRequest` processes captured frame
- Bottom sheet via `.sheet(isPresented:)` with `presentationDetents([.medium, .large])`
- Loading state shown via `ProgressView` inside sheet during OCR processing
- OCR runs on background thread — sheet shows `.medium` detent with spinner,
  expands to `.large` when results ready

---

### 3. ReviewView
**Purpose:** User confirms or corrects OCR output before analysis.

**Layout:**
- Navigation bar: "Review" title, "Analyse" primary button trailing (`.borderedProminent`)
- Serving size selector: stepper showing extracted serving, editable
  (e.g. "1 capsule ▲▼" — extracted from label, user can adjust)
- Reference standard picker: segmented control (AU / US / EU) pinned below serving
- Demographic selector: compact menu below segmented control
- List of extracted entries — each case rendered differently:
  - `NutrientEntry`: name | amount | unit — all tappable to edit inline
  - `HerbalEntry`: latin name + common name | extract amount — tappable to edit
  - `ProbioticEntry`: genus/species | strain | CFU — tappable to edit
  - `RawLine`: yellow highlight + "Needs review" label — tap to classify or dismiss
- "Add entry manually" button at list bottom
- Review flags shown inline per row (small badge, tappable for explanation)

**HIG notes:**
- Serving size selector is the first interactive element — most impactful setting
- Segmented control for 3 options is correct HIG pattern
- Inline editing preferred over modal sheets for simple corrections
- "Analyse" button disabled until at least one nutrient or herbal entry confirmed
- Destructive row actions (delete) via swipe — standard iOS list pattern
- RawLine rows visually distinct (systemYellow background tint) — not hidden

**SwiftUI implementation notes:**
- `List` with `ForEach` over `[LabelEntry]` — switch on enum case for row view
- `ReviewEntryRowView` handles all four LabelEntry cases
- Serving size: `Stepper` for integer quantities, `.menu` Picker for unit
- Segmented control: `Picker` with `.segmented` style
- Demographic: `Picker` with `.menu` style
- Inline editing: `.textFieldStyle` in list row, focus state managed explicitly
- Swipe-to-delete: `.onDelete` on ForEach — mutations through ReviewViewModel
- "Analyse" button: `.disabled(viewModel.hasNoConfirmedEntries)`
- RawLine row: tap opens `.sheet` with classification options
  (Convert to Nutrient / Convert to Herbal / Dismiss)

---

### 4. ReportView
**Purpose:** The primary deliverable. Full clinical analysis.

**Layout — complete scroll order:**

```
┌─ Navigation bar ──────────────────────────────────┐
│  [← Back]  Product Name              [Share PDF]  │
└───────────────────────────────────────────────────┘
┌─ Meta header card (sticky) ───────────────────────┐
│  Product name · Date · AU · Adult Male 19–50       │
│  Serving: 1 capsule                                │
└───────────────────────────────────────────────────┘
┌─ Summary card (always present) ───────────────────┐
│  SUMMARY                                          │
│  Form quality: High  Dose: 95% RDI  UL: Safe     │
│  ─────────────────────────────────────────────── │
│  Magnesium glycinate at a clinically meaningful   │
│  dose. Well-evidenced form.                       │
└───────────────────────────────────────────────────┘
┌─ Flag banners (conditional — only if flags exist) ┐
│  🔴 Selenium exceeds UL (200mcg / 150mcg)        │
│  🟠 2 nutrients in low-bioavailability forms      │
│  🟣 1 AI-inferred form assessment — review        │
└───────────────────────────────────────────────────┘
┌─ Nutrient section (if nutrient entries exist) ────┐
│  NUTRIENTS                                        │
│  Nutrient | Dose | RDI% | UL% | Form | Tier      │
│  ─────────────────────────────────────────────── │
│  [rows — expandable inline]                       │
└───────────────────────────────────────────────────┘
┌─ Herbal section (if herbal entries exist) ────────┐
│  HERBAL EXTRACTS                                  │
│  Name | Extract | Dry equiv | Standardisation     │
│  ─────────────────────────────────────────────── │
│  [rows — expandable inline]                       │
└───────────────────────────────────────────────────┘
┌─ Probiotic section (if probiotic entries exist) ──┐
│  PROBIOTICS                     96 Billion CFU    │
│  No NRV data for probiotic strains                │
│  Strain | Code | CFU                              │
│  ─────────────────────────────────────────────── │
│  [rows]                                           │
└───────────────────────────────────────────────────┘
┌─ Unresolved section (if unresolved lines exist) ──┐
│  ⚠️ COULD NOT BE ANALYSED                         │
│  [raw OCR text — manual review required]          │
└───────────────────────────────────────────────────┘
┌─ Recommendations ─────────────────────────────────┐
│  Plain clinical language, descriptive not         │
│  prescriptive. Grouped by: dose concerns,         │
│  form concerns, missing data.                     │
└───────────────────────────────────────────────────┘
┌─ Disclaimer (always present, always last) ────────┐
│  This report is for practitioner reference only…  │
└───────────────────────────────────────────────────┘
```

**Summary card detail:**
- `ReportSummaryCardView` — standalone component, never inlined
- Three status fields: Form quality | Dose | UL status
- Form quality computed from worst tier across all nutrient entries:
  - High = all Tier 1-2 (or no tier data)
  - Mixed = mix of Tier 1-2 and Tier 3
  - Poor = any Tier 4, or majority Tier 3
- Dose adequacy computed from primary macronutrient or named active ingredient:
  - Adequate = RDI% 80–200%
  - Sub-therapeutic = RDI% < 80%
  - Above UL = UL% > 100%
  - No data = no NRV reference
- Clinical note: one sentence. Generated by ReportService, not AI.
  Follows templates: "[form] at [dose context]" or "[flag] — [brief reason]"
- Status fields use `.headline` weight text, no colour coding
  (colour is reserved for tier indicators only)
- Clinical note uses `.body` style, `.secondary` colour

**Nutrient table detail:**
- Column headers: Nutrient | Dose | RDI% | UL% | Form | Tier
- Rows grouped: nutrients with NRV data first, then nutrients without
- Tier cell: coloured dot (systemGreen/Yellow/Orange/Red) + "T1" abbreviation
  + form name truncated. Dot is decorative — "T1" is the accessible label.
- AI-inferred rows: systemPurple dot + "AI" badge — `AIInferredBadgeView`
- Tapping row expands: rationale text + citations + full form name
- isTotalLine=true rows: shown with "Total" prefix, slightly indented sub-entries
  below with "included above" note — not used in RDI% sum

**Herbal section detail:**
- Shows only if LabelAnalysis.herbalEntries is non-empty
- Per row: common name (bold) + Latin name (italic, .caption)
- Extract type + amount + dry equivalent on second line
- Standardisation shown if present: "Standardised to [compound] [amount]"
- Form quality tier shown if assessable

**Probiotic section detail:**
- Shows only if LabelAnalysis.probioticEntries is non-empty
- Total CFU shown prominently in section header
- Per row: genus + species (italic) + strain code + CFU
- "No NRV data available for probiotic strains" shown as section footer note
- No tier badges — probiotics have no form quality tier in v1

**HIG notes:**
- Summary card answers the immediate question before the user reads anything
- Flag banners use colour + icon + text — never colour alone
- Sections hidden when empty — probiotic section absent on non-probiotic products
- Share button in nav bar is the standard iOS export pattern
- Disclaimer visually subdued (.caption, .secondary) but always present

**SwiftUI implementation notes:**
- `ScrollView` + `LazyVStack` — not `List` for the full report body
  (List adds unwanted separators between heterogeneous sections)
- Section headers: plain `Text` with `.title2` + custom divider — not `Section`
- Expandable rows: `@State var expandedID: UUID?` in ReportViewModel
  conditional content with `.transition(.opacity.combined(with: .move(edge: .top)))`
- Flag banners: conditional via `if !flags.nutrientsAboveUL.isEmpty`
- Share button: `ShareLink` with PDF `transferable` — no custom sheet
- Summary card: `ReportSummaryCardView` — separate file, separate struct
- AI badge: `AIInferredBadgeView` — separate file, never inlined
- `AppDestination` enum: replace `ReportModel` with `LabelAnalysis`

---

### 5. HistoryView
**Purpose:** Browse and reopen prior scans.

**Layout:**
- Navigation bar: "History" title, edit button trailing (enables multi-delete)
- Search bar (`.searchable` modifier) — filters by product name
- List of scan records: product name | date | standard used
- Swipe-to-delete per row
- Empty state: icon + "No scans yet" + "Scan a label" button

**HIG notes:**
- `.searchable` is the correct HIG pattern — appears below nav bar on scroll
- Edit mode for bulk delete — standard iOS pattern, don't build custom
- Empty state must be informative and actionable, not just a blank list

**SwiftUI implementation notes:**
- `@Query` with `SortDescriptor(\ScanRecord.createdAt, order: .reverse)`
- `.searchable(text: $searchText)` on NavigationStack
- Filter applied as predicate on `@Query` or via `.filter` on results
- `EditButton()` in toolbar — SwiftUI handles edit mode state natively
- Empty state: `ContentUnavailableView` (iOS 17+) — use it, it's the HIG solution

---

### 6. SettingsView
**Purpose:** App-level preferences.

**Layout:**
- `Form` (standard settings appearance)
- Section: Default Reference Standard (Picker)
- Section: Default Demographic (Picker)
- Section: About (app version, disclaimer, data sources)
- Section: Data (delete all history — destructive, confirmation required)

**HIG notes:**
- `Form` in a settings context is correct — matches system Settings appearance
- Destructive action (delete all) requires `.confirmationDialog` — never immediate
- No toggle switches unless a genuine boolean preference exists

**SwiftUI implementation notes:**
- `@AppStorage` for default standard and demographic — persists automatically
- `.confirmationDialog` for delete all — role `.destructive` on confirm button
- Version number from `Bundle.main.infoDictionary`

---

## Navigation Architecture

```
NavigationStack (root: HomeView)
├── ScanView (push)
│   └── ReviewView (push)
│       └── ReportView (push)
├── HistoryView (push)
│   └── ReportView (push, read-only)
└── SettingsView (sheet from HomeView)
```

**NavigationRouter:**
```swift
@Observable
class NavigationRouter {
    var path = NavigationPath()

    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

enum AppDestination: Hashable {
    case scan
    case review(entries: [LabelEntry])
    case report(LabelAnalysis)
    case history
    case settings
}
```

Router injected via `.environment` at app root.
Views call `router.navigate(to:)` — no view knows about any other view directly.

---

## Component Library (reusable Views)

These must be built as standalone components, not inlined:

| Component | Used In | Notes |
|---|---|---|
| `ReportSummaryCardView` | ReportView | Summary card — form quality, dose, UL status, clinical note |
| `NutrientRowView` | ReportView | Expandable nutrient table row |
| `HerbalRowView` | ReportView | Herbal extract row with standardisation |
| `ProbioticRowView` | ReportView | Strain + CFU row |
| `TierBadgeView` | ReportView, NutrientRowView | Coloured dot + T1/T2/T3/T4 text |
| `AIInferredBadgeView` | ReportView, NutrientRowView | Purple dot + "AI" text |
| `FlagBannerView` | ReportView | Conditional flag banners |
| `ReportSectionHeaderView` | ReportView | Section title + divider |
| `ScanHistoryRowView` | HomeView, HistoryView | Product name + date + standard |
| `EmptyStateView` | HistoryView | Icon + message + action button |
| `DemographicPickerView` | ReviewView, SettingsView | Age/sex picker |
| `StandardPickerView` | ReviewView, SettingsView | AU/US/EU segmented control |
| `ServingSizeSelectorView` | ReviewView | Quantity stepper or slider |
| `ReviewEntryRowView` | ReviewView | Editable LabelEntry row (all four cases) |
| `ErrorToastView` | Root overlay | Transient error toast |

No business logic inside any component. Data in via parameters. Actions out via callbacks or bindings.
