# SuppliScan — UI Mockup Analysis
# Source: Three mockup images (light-mode marketing · dark-mode detail · revised design), June 2026
# Purpose: Map every visible component to a SwiftUI primitive, its data source,
#          and planned micro-interactions. Authoritative before any screen is built.
# Related docs: UI_SPEC.md, DATA_SCHEMA.md, ARCHITECTURE.md
# Skills required: swiftui-expert-skill, swiftui-pro, swiftui-ui-patterns

---

## ERRATA — Read Before Any Other Section

This document was written during a design analysis session and then vetted against
the actual codebase and V1 completion plan. The following corrections supersede
any conflicting content below.

| Section | Original claim | Correction |
|---|---|---|
| §2 QualityScore model | Add `QualityScore` to `LabelAnalysis`; include potency/forms/purity/synergy/value sub-scores | **Drop entirely for v1.** Purity and Value cannot be derived from a label scan. Synergy requires `InteractionService` which is v2. Potency and Forms are already expressed by the existing summary card. No composite score in v1. |
| §2 NutrientInteraction | Listed as v1 scope | **v2.** `InteractionService` and `interactions.json` do not exist. Build the data model in `DATA_SCHEMA.md` so the schema is ready, but do not build the service or screen in v1. |
| §5 AnalysisView internal tabs | Summary · Nutrients · Interactions · Details | **3 tabs only in v1:** Summary · Nutrients · Details. Interactions tab added when `InteractionService` lands in v2. A visible empty tab reads as unfinished in a clinical tool. |
| §8 NutrientDetailView ADI row | Shows ADI progress bar and "Well within range" | **Not v1-ready.** No ADI model or reference data exists in any NRV JSON. Remove ADI from the detail view until schema and data work is complete. |
| §8 NutrientDetailView "View Research" | `FormQuality.referenceURL` + "View Research" button | **Defer.** `FormQuality.references` is `[String]` (PMIDs). A real research link requires service and schema work at the same sourcing standard as Phase 1. Drop `bullets` and `referenceURL` additions from `FormQuality` for v1. |
| §12 NutrientIconView gradient icons | Circular gradient icons recommended | **Do not use.** Conflicts with V1 design direction: "Do not add decorative custom glass cards. Use clinical visual hierarchy." Use SF Symbols with semantic system colours only. |
| §15 Haptics — UL exceeded | Card shake | **Drop card shake.** Too arcade for clinical UI. Warning tint + icon is sufficient. |
| §15 Haptics — product saved | Heart fill animation | **Not heart.** Heart implies favourites. Use checkmark confirmation. |
| §15 Haptics — interaction found | Haptic per discovered interaction | **Animate section count appearing.** Do not fire one haptic per interaction if many appear at once. |
| §16 Animation inventory | No mention of Reduce Motion | **All pulse, morph, expansion, and slide animations must check `@Environment(\\.accessibilityReduceMotion)` and skip or substitute a cross-fade.** |
| Throughout | `NavigationLink` used directly | **Router-owned navigation only.** All navigation goes through `NavigationRouter.navigate(to:)`. Direct `NavigationLink` bypasses the router. |
| Throughout | OCR results described as `@Query<ScanResult>` | **No `ScanResult` model exists.** OCR/parse output is `[LabelEntry]` owned by `ScanViewModel` or `ReviewViewModel`. `ScanRecord` is the only `@Model`. SwiftData stores the final `LabelAnalysis` only. |

**Design direction confirmed:** The dark-mode mockup (image 2) is the closest to production-ready for the actual app. It presents as a practitioner tool, matches the V1 flow (Scan → Review → Analysis → Forms → History), avoids V2 surfaces, and has the right clinical density. Light mockup = App Store / onboarding only. Third mockup = visual reference for specific components, but too much of it is V2 or marketing.

**Implementation rule:** Use semantic SwiftUI system colours throughout (`Color(.systemBackground)`, `.secondary`, `.green`, `.orange` etc). No hardcoded hex or custom gradients. Reduce card corner radius and shadow to feel native iOS 26 rather than custom-styled.

---

## 0. Architecture Flag — Tab Bar Structure

All three mockups use a bottom **TabView**, not a `NavigationStack` rooted at `HomeView`.
The current UI_SPEC.md navigation section describes `NavigationStack` — this must be updated.

**Mockup 3 (most refined) shows:** Home · Scan · Compare · Profile  
**Mockups 1–2 show:** Scan · Analysis · History · Settings

**Recommended synthesis for v1:**

| Tab | Icon | Rationale |
|---|---|---|
| Home | `house.fill` | Entry + most recent scan summary (from mockup 3) |
| Scan | `camera.viewfinder` | Direct scan launch |
| History | `clock.arrow.circlepath` | Past scans (from mockups 1–2; "Compare" is v2) |
| Settings | `gearshape` | Profile/preferences |

"Compare" is v2 scope. "Library" (mockup 3, scan screen tab bar) is v2 scope.
Each tab gets its own `NavigationStack` with an independent path.

**Required before building any screen:** Update `UI_SPEC.md` navigation + `AppDestination`.

---

## 1. New Screens Across All Three Mockups

| Screen | Status | Notes |
|---|---|---|
| `ScanView` | ✅ In spec | Minor refinements from mockup 3 |
| `ReviewView` | ✅ In spec | Card-style OCR display confirmed |
| `AnalysisView` (with internal tabs) | 🔄 Replaces `ReportView` | Internal tab bar: Summary · Nutrients · Interactions · Details |
| `NutrientDetailView` | ⚠️ New | Drill-down — not in current spec |
| `FormsAndPotencyView` | ⚠️ New | Separate from analysis list |
| `InteractionsView` | ⚠️ New | Synergy + conflicts, not in current spec |
| `CompareView` | 🔲 v2 | Score-based comparison, two `ScanRecord`s |
| `HomeView` (summary) | ⚠️ New | Shows quality score card of last scan |

---

## 2. New Data Models Required

These must be added to `DATA_SCHEMA.md` before building the affected screens.

### QualityScore
Aggregate score shown prominently on the Analysis summary screen.

```swift
struct QualityScore: Codable {
    let overall: Int           // 0–100
    let potency: Int           // average RDI% achievement across nutrients with NRVs
    let forms: Int             // weighted FormTier score (T1=100, T2=75, T3=40, T4=0)
    let purity: Int            // penalty for nutrients above UL (100 = none above UL)
    let synergy: Int           // score based on positive interactions present
    let grade: QualityGrade

    enum QualityGrade: String, Codable {
        case excellent         // 85–100
        case good              // 70–84
        case fair              // 50–69
        case poor              // < 50
    }
}
```

`QualityScore` is computed by `ReportService` and stored inside `LabelAnalysis`.
Never computed in a View or ViewModel.

### NutrientInteraction (extended)
Mockup 3 shows *both* positive synergies and negative conflicts in one screen,
separated by a segmented control.

```swift
struct NutrientInteraction: Identifiable, Codable {
    let id: UUID
    let nutrientA: String           // canonical name
    let nutrientB: String           // canonical name
    let type: InteractionType
    let severity: InteractionSeverity
    let description: String
    let mechanismNote: String?
    let referenceURL: URL?

    enum InteractionType: String, Codable {
        case synergy                // positive — nutrients work better together
        case conflict               // negative — one reduces other's absorption/effect
    }

    enum InteractionSeverity: String, Codable {
        // Synergy types
        case excellent              // well-evidenced, clinically meaningful
        case good                   // moderate supporting evidence
        // Conflict types
        case monitor                // worth being aware of
        case caution                // dose-dependent concern
        case avoid                  // should not combine
        case none                   // informational only
    }
}
```

`interactions.json` is a new bundled reference file (same pattern as `form_quality.json`).
A new stateless `InteractionService` loads it and filters to nutrients present in the scan.

### LabelAnalysis — additions
Add to `LabelAnalysis`:

```swift
struct LabelAnalysis: Identifiable, Codable {
    // ... existing fields ...
    let qualityScore: QualityScore              // new
    let interactions: [NutrientInteraction]     // new — replaces future call to InteractionService
    let summaryMeetsNeeds: MeetsNeedsMetrics    // new
}

struct MeetsNeedsMetrics: Codable {
    let averageRDIPercent: Double   // average across nutrients with RDI data
    let maxULPercent: Double        // highest UL% across all nutrients
    let maxADIPercent: Double       // highest ADI% across all nutrients
}
```

---

## 3. Screen: ScanView

### Visual Components (synthesised from all three mockups)

| Element | Detail |
|---|---|
| Flash/torch | Lightning bolt icon, top-left (mockup 3 only) |
| Navigation | Title "Scan Label" centre; ? help icon top-right; dismiss/back top-left |
| Camera preview | Full-screen, real supplement bottle visible |
| Viewfinder overlay | Rounded-rect with corner bracket guides (not a hard crop) |
| Guidance text | "Align the supplement facts panel within the frame" — below finder |
| "Label detected" banner | Green checkmark + "Label detected" — animates in at bottom of viewfinder when VisionKit recognises a text region (mockup 3) |
| Region picker | Segmented: AU · US (default) · EU — centre-bottom |
| Capture button | Large circle, bottom-centre |
| Gallery button | Photo stack icon, bottom-left |

### SwiftUI Component Map

```
ScanView
├── CameraPreviewView              UIViewRepresentable / AVCaptureSession
├── ViewfinderOverlayView
│   ├── RoundedRectangle           stroke, cornerRadius 12, lineWidth 2.5, .white
│   ├── CornerBracketShape ×4      custom Shape at each corner, 24pt legs
│   ├── Text("Align the supplement facts panel within the frame")
│   │   .font(.subheadline) .foregroundStyle(.white)
│   └── LabelDetectedBannerView    conditional, slides up from bottom of finder rect
│       ├── Image(systemName: "checkmark.circle.fill") .foregroundStyle(.green)
│       └── Text("Label detected")  .font(.subheadline.weight(.semibold))
├── HStack (bottom controls, above safe area)
│   ├── Button { showGallery = true }
│   │   Image(systemName: "photo.on.rectangle")
│   ├── Picker(selection: $standard) { ... }    .pickerStyle(.segmented)
│   └── CaptureButton              Button { vm.captureFrame() }
│       ├── Circle fill .white, size 72
│       └── Circle stroke .white.opacity(0.35), size 80
└── Toolbar overlays
    ├── TorchButton                Button { vm.toggleTorch() }
    │   Image(systemName: vm.torchOn ? "bolt.fill" : "bolt.slash")
    └── HelpButton                 Button { showHelp = true }
        Image(systemName: "questionmark.circle")
```

**State owned by `ScanViewModel`:**
- `var isLabelDetected: Bool` — set by `VNRecognizeTextRequest` confidence threshold
- `var torchOn: Bool`
- `var captureState: LoadingState<[LabelEntry]>`

### Micro-Interactions

| Trigger | Interaction |
|---|---|
| View appears | Overlay fades in `.easeIn(duration: 0.3)` |
| VisionKit detects label | `LabelDetectedBannerView` slides up `.move(edge: .bottom)` + `.opacity`, 0.4 s `.spring()`; `UINotificationFeedbackGenerator(.success)` |
| Capture tap | Button scale 0.85 → 1.0 `.spring(dampingFraction: 0.6)`; `UIImpactFeedbackGenerator(.medium)` |
| OCR succeeds | Viewfinder corners briefly animate green (colour transition 0.4 s); navigates to ReviewView |
| OCR fails | Viewfinder shakes ±6pt, 3 cycles using `keyframeAnimator`; `UINotificationFeedbackGenerator(.error)` |
| Torch toggle | Icon crossfades `.transition(.opacity)` 0.15 s |

---

## 4. Screen: ReviewView ("Review Scan")

### Visual Components

| Element | Detail |
|---|---|
| Nav bar | Back arrow · "Review Scan" · "Edit" (blue, trailing) |
| Label-recognised banner | Green checkmark + "Label recognized" + "US Label" |
| Supplement Facts card | Faithful OCR reproduction — white elevated card, full label layout |
| Nutrient table rows | Name left, amount + unit centre, %DV right — matches real label typography |
| Other Ingredients section | Below divider, smaller text |
| CTA button | "Analyze" — blue, full-width, fixed above safe area bottom |

### SwiftUI Component Map

```
ReviewView
├── .navigationTitle("Review Scan")
├── .toolbar { ToolbarItem(.topBarTrailing) { editButton } }
├── ScrollView(.vertical)
│   └── LazyVStack(spacing: 0)
│       ├── LabelRecognisedBannerView
│       │   ├── Image(systemName: "checkmark.circle.fill") .foregroundStyle(.green)
│       │   ├── Text("Label recognized")    .font(.headline)
│       │   └── Text("\(standard.rawValue) Label")  .font(.subheadline) .foregroundStyle(.secondary)
│       └── SupplementFactsCardView
│           ├── Text("Supplement Facts")    .font(.system(.title2, design: .default, weight: .black))
│           ├── ServingInfoView             serving size + servings per container
│           ├── Divider() (heavy)
│           ├── HStack { Text("Amount Per Serving"); Spacer(); Text("%DV") }  .font(.caption)
│           ├── ForEach(vm.entries) { ReviewEntryRowView(entry:, isEditing:) }
│           ├── Divider()
│           └── OtherIngredientsView(text: vm.otherIngredients)
└── Button("Analyze") { vm.confirmAndAnalyze() }
    .buttonStyle(.borderedProminent) .controlSize(.large)
    .frame(maxWidth: .infinity) .padding(.horizontal, 16)
    .disabled(vm.hasNoConfirmedEntries)
```

`ReviewEntryRowView` switches on `LabelEntry`:
```swift
switch entry {
case .nutrient(let n):    NutrientReviewRow(entry: n, isEditing: isEditing)
case .herbal(let h):      HerbalReviewRow(entry: h, isEditing: isEditing)
case .probiotic(let p):   ProbioticReviewRow(entry: p, isEditing: isEditing)
case .unresolved(let r):  RawLineReviewRow(line: r)   // systemYellow tint background
}
```

**Data source:** `ReviewViewModel.entries: [LabelEntry]`, `ReviewViewModel.servingSize: ServingSize`

### Micro-Interactions

| Trigger | Interaction |
|---|---|
| Banner appears | Slides up `.move(edge: .bottom)` + `.opacity`, 0.5 s `.spring()` |
| Edit mode activates | Text fields fade in per row, 0.03 s stagger (`delay: Double(index) * 0.03`) |
| Field focused | Border animates to `.accentColor` (0.2 s); `UISelectionFeedbackGenerator` |
| Flag badge tap | `.sheet` with `.presentationDetents([.fraction(0.35)])` — brief explanation |
| Swipe to delete | `UIImpactFeedbackGenerator(.light)` at swipe threshold |
| Analyse button enables | Opacity 0.4 → 1.0, scale 0.97 → 1.0, `.spring(response: 0.3)` |
| Analyse tapped | Label replaced by `ProgressView` while `vm.confirmAndAnalyze()` runs |

---

## 5. Screen: AnalysisView (replaces ReportView)

Mockup 3 shows the most complete version: a product header + internal four-tab layout.
This replaces the single-scroll `ReportView` from `UI_SPEC.md`.

### Visual Components

| Element | Detail |
|---|---|
| Nav bar | Back · "Analysis" · share icon |
| Product header | Small bottle thumbnail + product name bold + `QualityGrade` badge |
| Internal tab bar | Summary · Nutrients · Interactions · Details (pill-style segmented tabs) |
| **Summary tab** | Quality score gauge · Meets Your Needs cards · Top Nutrients list |
| **Nutrients tab** | Full `[NutrientAnalysis]` list with filter chips (All/Vitamins/Minerals/Other) |
| **Interactions tab** | `InteractionsView` content embedded |
| **Details tab** | Herbal, probiotic, unresolved entries + disclaimer |

### SwiftUI Component Map — AnalysisView shell

```
AnalysisView(analysis: LabelAnalysis)
├── .navigationTitle("Analysis")
├── .toolbar { ShareLink(item: vm.pdfTransferable) }
├── ProductHeaderView(analysis: analysis)
│   ├── SupplementThumbnailView(record: record)   44×44 rounded rect
│   ├── Text(analysis.productName)  .font(.headline)
│   └── QualityGradeBadgeView(grade: analysis.qualityScore.grade)
├── AnalysisInternalTabBar(selection: $activeTab)   ← custom pill tabs
└── TabView(selection: $activeTab)  .tabViewStyle(.page(indexDisplayMode: .never))
    ├── SummaryTabView(analysis: analysis)    .tag(AnalysisTab.summary)
    ├── NutrientsTabView(analysis: analysis)  .tag(AnalysisTab.nutrients)
    ├── InteractionsTabView(analysis: analysis) .tag(AnalysisTab.interactions)
    └── DetailsTabView(analysis: analysis)    .tag(AnalysisTab.details)
```

**AnalysisInternalTabBar** — horizontal pill row, not `TabView`'s built-in tab items:
```swift
enum AnalysisTab: String, CaseIterable {
    case summary = "Summary"
    case nutrients = "Nutrients"
    case interactions = "Interactions"
    case details = "Details"
}
```
Renders as a `ScrollView(.horizontal)` of `FilterChip` views (same component as nutrient filter),
drives a `TabView(selection:)` set to `.page(indexDisplayMode: .never)` for swipe support.

---

## 6. AnalysisView — Summary Tab

### Visual Components (mockup 3)

| Element | Detail |
|---|---|
| Overall Quality Score | Circular gauge — large number "92" centre, "Excellent" below, ring fill proportional |
| Quality checklist | Right of gauge: Potency ✓, Forms ✓ Excellent, Purity ✓, Synergy ✓ Optimized |
| "Meets Your Needs" | Three equal-width cards: RDI avg% · UL max% · ADI max% |
| "Top Nutrients" | List of top 4 by RDI%, name + % + short progress bar |

### SwiftUI Component Map

```
SummaryTabView(analysis: LabelAnalysis)
└── ScrollView
    └── VStack(spacing: 20)
        ├── OverallQualityScoreView(score: analysis.qualityScore)
        │   └── HStack(spacing: 20)
        │       ├── QualityGaugeView(score: score.overall, grade: score.grade)
        │       │   └── ZStack
        │       │       ├── Circle stroke background (.tertiarySystemFill, lineWidth 12)
        │       │       ├── Circle stroke foreground (grade.color, lineWidth 12,
        │       │       │   trim from 0 to score/100, .lineCap .round)
        │       │       │   ← animated with .animation(.spring(duration:0.8), value: score.overall)
        │       │       ├── Text("\(score.overall)")   .font(.system(size: 44, weight: .bold))
        │       │       └── Text(score.grade.rawValue)  .font(.caption)
        │       └── QualityChecklistView(score: score)
        │           └── VStack(alignment: .leading, spacing: 8)
        │               ├── QualityCheckRow("Potency", .excellent)
        │               ├── QualityCheckRow("Forms", .excellent)
        │               ├── QualityCheckRow("Purity", .good)
        │               └── QualityCheckRow("Synergy", .excellent, label: "Optimized")
        ├── MeetsYourNeedsView(metrics: analysis.summaryMeetsNeeds)
        │   └── HStack(spacing: 12)
        │       ├── MetricCard("RDI", value: metrics.averageRDIPercent, suffix: "% Average")
        │       ├── MetricCard("UL",  value: metrics.maxULPercent,      suffix: "% Max Used")
        │       └── MetricCard("ADI", value: metrics.maxADIPercent,     suffix: "% Max Used")
        └── TopNutrientsView(analyses: analysis.nutrientAnalyses)
            └── VStack(spacing: 0)
                ├── SectionHeader("Top Nutrients")
                └── ForEach(top4) { analysis in
                    TopNutrientRow(analysis: analysis)
                        .onTapGesture { router.navigate(to: .nutrientDetail(analysis)) }
                    }
```

**MetricCard** — equal-width card with large number, label, suffix:
```swift
struct MetricCard: View {
    let label: String
    let value: Double
    let suffix: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(formatted(value)).font(.title2.bold()).foregroundStyle(accentFor(value))
            Text(suffix).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.secondarySystemBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

### Micro-Interactions

| Trigger | Interaction |
|---|---|
| Tab selected (Summary) | Gauge ring animates from 0 to `score.overall` (`.spring(duration: 0.8)`) |
| Gauge animating | Score number counts up (using `animatableData` via `@Animatable` or `TimelineView`) |
| Checklist items appear | Stagger-fade in (0.05 s delay each) after gauge completes |
| Metric cards appear | Scale from 0.95 + opacity 0 → 1 (0.1 s delay after checklist) |
| Top nutrient row tap | `UISelectionFeedbackGenerator`; row highlight then navigate |

---

## 7. AnalysisView — Nutrients Tab

### Visual Components

| Element | Detail |
|---|---|
| Filter chips | All · Vitamins · Minerals · Other (horizontal scroll, pill/capsule style) |
| Nutrient rows | Name + form in parentheses · dose + IU equivalent · RDI% right-aligned green · progress bar · UL info |
| Progress bar colours | Green = safe; orange = approaching UL; red = above UL |
| Footnote | RDI / UL / ADI definitions |

### SwiftUI Component Map

```
NutrientsTabView(analysis: LabelAnalysis)
├── NutrientFilterBar(selection: $filter)
│   └── ScrollView(.horizontal, showsIndicators: false)
│       └── HStack(spacing: 8) { ForEach(NutrientCategory.allCases) { FilterChip(...) } }
└── ScrollView
    └── LazyVStack(spacing: 0)
        ├── ForEach(vm.filteredAnalyses) { analysis in
        │   NutrientAnalysisRowView(analysis: analysis)
        │       .onTapGesture { router.navigate(to: .nutrientDetail(analysis)) }
        │   Divider()
        │   }
        └── NutrientFootnoteView()

NutrientAnalysisRowView(analysis: NutrientAnalysis)
└── VStack(alignment: .leading, spacing: 4)
    ├── HStack
    │   ├── Text(displayName)           .font(.headline)
    │   └── Text(rdiPercentString)      .font(.headline) .foregroundStyle(rdiColor)
    ├── Text(doseString)                .font(.subheadline) .foregroundStyle(.secondary)
    ├── ProgressView(value: clampedRDI) .tint(rdiColor)
    └── Text(ulString)                  .font(.caption) .foregroundStyle(.secondary)
```

**`NutrientCategory` enum (new — add to models):**
```swift
enum NutrientCategory: String, CaseIterable, Identifiable {
    case all = "All", vitamins = "Vitamins", minerals = "Minerals", other = "Other"
    var id: String { rawValue }
}
```

### Micro-Interactions

| Trigger | Interaction |
|---|---|
| Tab selected (Nutrients) | Progress bars animate 0 → value, `.easeOut(duration: 0.6)`, 0.08 s stagger per row |
| Filter chip tap | `.spring(response: 0.25)` on chip; list refilters with `.animation(.default)` |
| Above-UL row | Red progress bar + pulsing border: `repeatForever(autoreverses: true)` opacity 0.4→1.0 |
| Row tap | Row flashes `.systemGray5` (0.15 s); navigate to `NutrientDetailView` |

---

## 8. Screen: NutrientDetailView *(New)*

### Visual Components (mockups 2 + 3)

| Element | Detail |
|---|---|
| Nav bar | Back · nutrient name · bookmark icon (top-right) |
| Nutrient heading | Full name e.g. "Vitamin D3 (as Cholecalciferol)" — `.title2.bold()` |
| RDI% KPI | Very large "1000% RDI" in green — the dominant number on screen |
| Dose scale | Progress bar with dose marker + "RDI: 10 mcg" endpoint label |
| UL section | "UL (Tolerable Upper Intake Level)" · "25% of UL" · "Safe ✓" · progress bar |
| ADI section | "ADI (Acceptable Daily Intake)" · "50% of ADI" · "Well within range ✓" · progress bar |
| Form Quality | Form name badge (e.g. "Cholecalciferol (D3)") + potency badge + subtext |
| "Why this form is good" | Bulleted list with ↑ icon, evidence-backed points |
| View Research | Outlined button, full-width |
| Interactions link | "View Interactions >" disclosure row (if interactions exist for this nutrient) |

### SwiftUI Component Map

```
NutrientDetailView(analysis: NutrientAnalysis, allInteractions: [NutrientInteraction])
├── .navigationTitle(analysis.entry.canonicalName)
├── .toolbar { BookmarkButton(analysisID: analysis.id) }
└── ScrollView
    └── VStack(alignment: .leading, spacing: 24)
        ├── NutrientNameHeadingView
        │   └── Text(analysis.entry.displayName)  .font(.title2.bold())
        ├── RDIKPIView(rdiPercent: analysis.rdiPercent)
        │   └── HStack(alignment: .firstTextBaseline, spacing: 4)
        │       ├── Text(rdiPercentString)    .font(.system(size: 52, weight: .bold)) .foregroundStyle(.green)
        │       └── Text("RDI")              .font(.title3) .foregroundStyle(.secondary)
        ├── DoseScaleView(analysis: analysis)
        │   ── ProgressView(value: min(rdiPercent ?? 0, 2.0) / 2.0)  — scale is 0–200%
        │   ── scale labels: "0", dose point, "RDI: \(rdiValue)"
        ├── NutrientStatSection("UL (Tolerable Upper Intake Level)", percent: analysis.ulPercent,
        │   label: ulSafetyLabel, color: ulColor)
        ├── NutrientStatSection("ADI (Acceptable Daily Intake)", percent: analysis.adiPercent,
        │   label: adiLabel, color: .blue)
        ├── FormQualitySectionView(formQuality: analysis.entry.formQuality)
        │   ├── HStack { FormBadge(text: formName); PotencyBadgeView(tier: tier) }
        │   └── Text(rationale)  .font(.body) .foregroundStyle(.secondary)
        ├── WhyThisFormIsGoodView(bullets: formQuality.bullets)
        │   └── VStack(alignment: .leading) { ForEach(bullets) { BulletRow($0) } }
        ├── if let url = formQuality.referenceURL {
        │       Button("View Research") { open(url) }
        │           .buttonStyle(.bordered) .frame(maxWidth: .infinity)
        │   }
        └── if hasInteractions {
                NavigationLink(value: AppDestination.interactions(relevantInteractions)) {
                    HStack {
                        Text("Interactions")
                        Spacer()
                        Image(systemName: "chevron.right") .foregroundStyle(.secondary)
                    }
                }
            }
```

**`FormQuality` additions required:**
```swift
struct FormQuality: Codable {
    // ... existing fields ...
    let bullets: [String]          // "Why this form is good" bullet points — new
    let referenceURL: URL?         // "View Research" link — new
}
```

### Micro-Interactions

| Trigger | Interaction |
|---|---|
| Screen appears | RDI% KPI counts up from 0 using `animatableData`, `.spring(duration: 0.6)` |
| Dose scale bar | Animates from 0 with `.easeOut(duration: 0.5)`, 0.2 s delay |
| UL/ADI bars | Stagger-animate 0.1 s after dose bar |
| "View Research" tap | `UIImpactFeedbackGenerator(.light)`; opens `SFSafariViewController` |
| Bookmark tap | Star fill animation (empty → filled, scale 1.0 → 1.4 → 1.0); `UIImpactFeedbackGenerator(.light)` |

---

## 9. Screen: InteractionsView *(New)*

### Visual Components (all three mockups — mockup 3 most complete)

| Element | Detail |
|---|---|
| Nav bar | Back · "Interactions" · bookmark icon |
| Segmented control | "Nutrient Synergy" · "Potential Conflicts" (drives visible section) |
| **Synergy section** | "Positive Synergy" header · rows: pair name + severity badge (Excellent/Good) + description |
| **Conflicts section** | rows: pair name + severity badge (Monitor/Caution) + description |
| "Takeaway" box | Highlighted card summarising overall interaction profile |
| Footer | "Always consult a healthcare professional..." |

### SwiftUI Component Map

```
InteractionsView(interactions: [NutrientInteraction])
├── .navigationTitle("Interactions")
├── .toolbar { BookmarkButton() }
├── Picker(selection: $mode) { ... }    .pickerStyle(.segmented)
│   // "Nutrient Synergy" | "Potential Conflicts"
└── ScrollView
    └── LazyVStack(spacing: 0)
        // Mode: .synergy
        ├── if mode == .synergy {
        │   Section("Positive Synergy") {
        │   ForEach(synergies) { InteractionRowView(interaction: $0) }
        │   }
        │   }
        // Mode: .conflicts
        ├── if mode == .conflicts {
        │   Section("Potential Interactions") {
        │   ForEach(conflicts) { InteractionRowView(interaction: $0) }
        │   }
        │   Section {
        │   Text("No significant interactions detected for remaining nutrients")
        │   Text("Always consult a healthcare professional...")
        │       .font(.caption) .foregroundStyle(.secondary)
        │   }
        │   }
        └── TakeawayCardView(interactions: interactions)
            ├── Image(systemName: "lightbulb.fill") .foregroundStyle(.yellow)
            ├── Text("Takeaway")  .font(.headline)
            └── Text(takeawaySummary)  .font(.body)

InteractionRowView(interaction: NutrientInteraction)
└── HStack(alignment: .top, spacing: 12)
    ├── InteractionIconPairView(a: interaction.nutrientA, b: interaction.nutrientB)
    │   ── two NutrientIconView at 28pt, second offset by (8, 8)
    └── VStack(alignment: .leading, spacing: 4)
        ├── HStack {
        │   Text("\(interaction.nutrientA) + \(interaction.nutrientB)")  .font(.headline)
        │   Spacer()
        │   InteractionSeverityBadge(severity: interaction.severity)
        │   }
        └── Text(interaction.description)  .font(.body) .foregroundStyle(.secondary)
```

**`InteractionSeverityBadge` colour mapping:**

| Severity | Label | Colour |
|---|---|---|
| `.excellent` | Excellent | `.green` |
| `.good` | Good | `.teal` |
| `.monitor` | Monitor | `.orange` |
| `.caution` | Caution | `.red` |

### Micro-Interactions

| Trigger | Interaction |
|---|---|
| Mode switch (Synergy ↔ Conflicts) | `.spring(response: 0.3)` on segmented control; list rows crossfade `.transition(.opacity)` |
| Screen appears with conflicts | `UINotificationFeedbackGenerator(.warning)` — once, on appear |
| Screen appears synergy-only | No haptic — positive information |
| Row tap | `UISelectionFeedbackGenerator`; navigate to `NutrientDetailView` |
| Takeaway card appears | Slides up `.move(edge: .bottom)` + `.opacity`, 0.3 s delay after rows |

---

## 10. Screen: HistoryView

### Visual Components (mockup 2 dark)

| Element | Detail |
|---|---|
| Nav bar | Back · "History" · `EditButton()` |
| Search bar | `.searchable` below nav bar |
| List rows | Small thumbnail (44 pt) + product name bold + label type secondary + date caption |
| Swipe to delete | Standard iOS swipe action |
| Empty state | `ContentUnavailableView` — icon + message + action |

### SwiftUI Component Map

```
HistoryView
├── .navigationTitle("History")
├── .toolbar { EditButton() }
├── .searchable(text: $searchText, placement: .navigationBarDrawer)
└── List {
    if filteredRecords.isEmpty && !searchText.isEmpty {
        ContentUnavailableView.search(text: searchText)
    } else if records.isEmpty {
        ContentUnavailableView("No Scans Yet",
            systemImage: "camera.viewfinder",
            description: Text("Scan a supplement label to get started"))
    } else {
        ForEach(filteredRecords) { record in
            NavigationLink(value: AppDestination.analysis(record.decodedAnalysis)) {
                ScanHistoryRowView(record: record)
            }
        }
        .onDelete { vm.delete(offsets: $0) }
    }
}

ScanHistoryRowView(record: ScanRecord)
└── HStack(spacing: 12)
    ├── SupplementThumbnailView()     // captured image or SF Symbol fallback
    │   ── RoundedRectangle cornerRadius 8, 44×44
    └── VStack(alignment: .leading, spacing: 2)
        ├── Text(record.productName)          .font(.headline)
        ├── Text(record.referenceStandard + " Label")  .font(.subheadline) .foregroundStyle(.secondary)
        └── Text(record.createdAt, style: .date)  .font(.caption) .foregroundStyle(.secondary)
```

**Data source:**
```swift
@Query(sort: \ScanRecord.createdAt, order: .reverse) private var records: [ScanRecord]
var filteredRecords: [ScanRecord] {
    searchText.isEmpty ? records
        : records.filter { $0.productName.localizedCaseInsensitiveContains(searchText) }
}
```

### Micro-Interactions

| Trigger | Interaction |
|---|---|
| New scan saved | Row slides in from trailing `.move(edge: .trailing).combined(with: .opacity)` |
| Delete swipe | `UIImpactFeedbackGenerator(.medium)` at threshold |
| Search active | List animates filter with `.animation(.default)` |

---

## 11. Screen: CompareView *(v2 — documented for reference)*

### Visual Components (mockup 3, bottom-left)

| Element | Detail |
|---|---|
| Header | Two product columns — thumbnail + name + date |
| Quality scores | Large "92/100" (green) vs "67/100" (secondary) |
| Comparison bars | Potency · Forms · Purity · Value — dual horizontal bars per category |
| Bar colours | Taller bar: `.green`; shorter bar: `.systemGray` |

### Architecture Notes (v2)

- Requires multi-select mode in `HistoryView` to pick two `ScanRecord`s
- `CompareViewModel` holds two `LabelAnalysis` and diffs by `NutrientAnalysis.entry.canonicalName`
- `QualityScore` dimensions (potency, forms, purity, synergy) map directly to the four bar categories
- `CompareView` uses `Grid` for aligned column layout
- Do not build in v1

---

## 12. NutrientIconView — Reusable Component

Circular gradient icons appear on FormsAndPotency, Interactions, NutrientDetail.
Single implementation; two sizes: 48 pt (list rows), 64 pt (detail header).

```swift
struct NutrientIconView: View {
    let canonicalName: String
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle().fill(gradient(for: canonicalName))
            Image(systemName: symbol(for: canonicalName))
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}
```

| Canonical Name | SF Symbol | Gradient stop A → B |
|---|---|---|
| Vitamin D | `sun.max.fill` | `.yellow` → `.orange` |
| Vitamin K | `leaf.fill` | `.green` → `.teal` |
| Magnesium | `atom` | `.blue` → Color(white: 0.35) |
| Zinc | `circle.grid.cross.fill` | `.cyan` → `.blue` |
| Boron | `b.circle.fill` | `.orange` → `.red` |
| Calcium | `circle.dotted` | `.gray` → Color(.systemGray2) |
| Omega / DHA / EPA | `drop.fill` | `.blue` → `.indigo` |
| Default | `pill.fill` | `.accentColor` → `.purple` |

All gradients use system colours only — no hex values.

---

## 13. Tab Bar (Final Recommendation)

```swift
TabView(selection: $selectedTab) {
    HomeTab()
        .tabItem { Label("Home",     systemImage: "house.fill") }
        .tag(Tab.home)
    ScanTab()
        .tabItem { Label("Scan",     systemImage: "camera.viewfinder") }
        .tag(Tab.scan)
    HistoryTab()
        .tabItem { Label("History",  systemImage: "clock.arrow.circlepath") }
        .tag(Tab.history)
    SettingsTab()
        .tabItem { Label("Settings", systemImage: "gearshape") }
        .tag(Tab.settings)
}
```

After a successful scan → `selectedTab = .home` and `HomeTab` shows the new `AnalysisView`.
`AnalysisView` persists the most recent `LabelAnalysis` in `AnalysisViewModel` (not re-fetched on tab switch).
Analysis tab badge: `ReportFlags.nutrientsAboveUL.count` shown via `.badge()`.

---

## 14. Component Library — Complete List (Updated UI_SPEC.md table)

| Component | Screen(s) | Notes |
|---|---|---|
| `LabelRecognisedBannerView` | ReviewView | Green checkmark + standard label |
| `LabelDetectedBannerView` | ScanView | Animated, appears over viewfinder |
| `SupplementFactsCardView` | ReviewView | OCR reproduction card |
| `ReviewEntryRowView` | ReviewView | Switches on LabelEntry case |
| `OverallQualityScoreView` | Analysis > Summary | Gauge + checklist |
| `QualityGaugeView` | OverallQualityScoreView | Circular ring chart |
| `QualityChecklistView` | OverallQualityScoreView | Potency/Forms/Purity/Synergy rows |
| `MetricCard` | Analysis > Summary | RDI/UL/ADI average boxes |
| `TopNutrientRow` | Analysis > Summary | Simplified name + % + bar |
| `NutrientFilterBar` | Analysis > Nutrients | All/Vitamins/Minerals/Other chips |
| `FilterChip` | NutrientFilterBar, AnalysisInternalTabBar | Reused everywhere |
| `NutrientAnalysisRowView` | Analysis > Nutrients | Full row with bar |
| `AnalysisInternalTabBar` | AnalysisView | Summary/Nutrients/Interactions/Details |
| `RDIKPIView` | NutrientDetailView | Large 52pt RDI% number |
| `DoseScaleView` | NutrientDetailView | Scale bar with RDI marker |
| `NutrientStatSection` | NutrientDetailView | UL + ADI rows with bar + safety label |
| `FormQualitySectionView` | NutrientDetailView | Form badge + potency + rationale |
| `WhyThisFormIsGoodView` | NutrientDetailView | Bulleted evidence list |
| `NutrientIconView` | FormsAndPotency, Interactions, Detail | Circular gradient icon, 2 sizes |
| `PotencyBadgeView` | FormsAndPotency, NutrientDetail | High/Moderate/Low pill |
| `FormPotencyRowView` | FormsAndPotency | Icon + name + badge + rationale |
| `InteractionRowView` | InteractionsView | Pair icon + name + severity + desc |
| `InteractionSeverityBadge` | InteractionRowView | Excellent/Good/Monitor/Caution |
| `InteractionIconPairView` | InteractionRowView | Two overlapping NutrientIconView |
| `TakeawayCardView` | InteractionsView | Lightbulb + summary text |
| `ScanHistoryRowView` | HistoryView | Thumbnail + name + date |
| `SupplementThumbnailView` | HistoryView, AnalysisView header | Image or SF Symbol fallback |
| `QualityGradeBadgeView` | AnalysisView header | "High Quality" / "Good" pill |
| `BookmarkButton` | NutrientDetailView, InteractionsView | Star fill toggle |
| `TierBadgeView` | NutrientRowView | T1/T2/T3/T4 coloured dot |
| `AIInferredBadgeView` | NutrientRowView | Purple dot + "AI" |
| `FlagBannerView` | Analysis > Details | Conditional flag banners |
| `EmptyStateView` | HistoryView | Icon + message + action button |
| `ErrorToastView` | Root overlay | Transient error toast |
| `DemographicPickerView` | ReviewView, SettingsView | Age/sex picker |
| `StandardPickerView` | ReviewView, SettingsView | AU/US/EU segmented |
| `ServingSizeSelectorView` | ReviewView | Quantity stepper |

---

## 15. Global Haptic Strategy

| Event | Generator | Style |
|---|---|---|
| Primary action (capture, analyse, confirm) | `UIImpactFeedbackGenerator` | `.medium` |
| Selection / navigation | `UISelectionFeedbackGenerator` | — |
| Label detected (OCR) | `UINotificationFeedbackGenerator` | `.success` |
| Interaction conflict found | `UINotificationFeedbackGenerator` | `.warning` |
| OCR failure | `UINotificationFeedbackGenerator` | `.error` |
| Delete, destructive action | `UIImpactFeedbackGenerator` | `.medium` |
| Bookmark toggle | `UIImpactFeedbackGenerator` | `.light` |

All generators `.prepare()` in `onAppear`. Stored as `@State private var generator`.

---

## 16. Global Animation Inventory

| Animation | Used For | Spec |
|---|---|---|
| Progress bars on appear | All screens | `.easeOut(duration: 0.6)`, 0.08 s stagger per row |
| Quality gauge ring | Summary tab appear | `.spring(duration: 0.8)` on `trim(from:to:)` |
| Score count-up | QualityGaugeView | `animatableData`, same spring |
| Filter chip selection | All filter bars | `.spring(response: 0.25, dampingFraction: 0.75)` |
| Row stagger fade-in | List screens | `.opacity` + `delay(Double(i) * 0.06)` `.easeOut(0.3)` |
| Icon scale-in | NutrientDetailView, FormsAndPotency | `.spring(response: 0.4, dampingFraction: 0.65)` from 0.7 |
| Label detected banner | ScanView | `.move(edge:.bottom)` + `.opacity`, `.spring()` 0.4 s |
| Viewfinder success | ScanView OCR OK | Corners → green, `.easeInOut(0.4)` |
| Viewfinder failure shake | ScanView OCR fail | `keyframeAnimator` ±6pt, 3 cycles, 0.06 s each |
| Above-UL pulse | Nutrients tab row border | `.easeInOut(1.0).repeatForever(autoreverses:true)` opacity 0.4→1.0 |
| Tab switch (internal) | AnalysisInternalTabBar | `.spring(response: 0.3)` on chip; `TabView` swipe is system |
| Takeaway card | InteractionsView | `.move(edge:.bottom)` + `.opacity`, 0.3 s delay |
| Bookmark fill | NutrientDetailView | Scale 1.0 → 1.4 → 1.0 `.spring(dampingFraction: 0.5)` |

All `.animation(_:value:)` calls include the `value:` parameter — no bare `.animation(_:)`.

---

## 17. AppDestination — Updated Enum

```swift
enum AppDestination: Hashable {
    case scan
    case review(entries: [LabelEntry], serving: ServingSize)
    case analysis(LabelAnalysis)
    case nutrientDetail(NutrientAnalysis)
    case formsAndPotency([NutrientAnalysis])
    case interactions([NutrientInteraction])
    case history
    case settings
    // v2 only:
    // case compare(LabelAnalysis, LabelAnalysis)
}
```

---

## 18. Build Readiness Assessment

| Screen / Component | Ready? | Blocker |
|---|---|---|
| ScanView | ✅ | None |
| ReviewView + SupplementFactsCardView | ✅ | None |
| AnalysisView shell + internal tabs | ✅ | `AnalysisTab` enum, `FilterChip` |
| Summary tab (gauge, metrics, top nutrients) | ⚠️ | `QualityScore` model + `ReportService` scoring logic |
| Nutrients tab + filter chips | ✅ | `NutrientCategory` enum |
| NutrientDetailView | ⚠️ | `FormQuality.bullets` + `FormQuality.referenceURL` additions |
| FormsAndPotencyView | ✅ | `FormTier` display extensions |
| InteractionsView | ⚠️ | `NutrientInteraction` model + `interactions.json` + `InteractionService` |
| HistoryView | ✅ | None |
| NutrientIconView | ✅ | Build first (used everywhere) |
| CompareView | 🔲 v2 | Defer |
| TabView root | ✅ | Update UI_SPEC.md nav section first |

### Recommended Build Order

1. **Data first:** Add `QualityScore`, `NutrientInteraction`, `MeetsNeedsMetrics` to `DATA_SCHEMA.md`; extend `LabelAnalysis`; create `interactions.json`; implement `InteractionService`; extend `ReportService` to compute `QualityScore`
2. **Shared atoms:** `NutrientIconView` · `FilterChip` · `PotencyBadgeView` · `TierBadgeView`
3. **Capture path:** `ScanView` → `ReviewView`
4. **Analysis shell:** `AnalysisView` tab container → Summary tab → Nutrients tab
5. **Drill-downs:** `NutrientDetailView` → `FormsAndPotencyView` → `InteractionsView`
6. **History:** `HistoryView` + `ScanHistoryRowView`
7. **Settings + root TabView**
8. **Polish:** Haptics pass · animation audit · accessibility pass (invoke `swiftui-accessibility-auditor` skill)
