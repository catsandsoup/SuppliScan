# Finish Premium UI Redesign + Verification — Implementation Plan

**Goal:** Migrate every remaining screen/component off the legacy `AppTheme`/system-Form style onto the `Theme` design system, then run a full verification pass (build + simulator light/dark + accessibility + frame analysis), BEFORE building the new Library feature.

**Architecture:** Pure UI/UX transformation on top of unchanged models, services, navigation and business logic. The authority is `DesignTokens.swift` (`Theme.*`) and the already-redesigned `AnalysisView.swift` (gold-standard reference for surfaces, motion, spacing, type).

**Tech Stack:** SwiftUI · iOS 26 · Swift 6.2 · `Theme` design tokens · Liquid Glass (chrome only).

**User decisions (already made):**
- "finish the ui tasks and testing first" — UI + verification precede the Library/OCR/QOL adventure.
- "don't ask questions… surprise me" — execute autonomously, commit per chunk.
- Build is confirmed GREEN at HEAD (`9a74495`); compaction did not destroy quality.
- Hold the clinical-honesty line: never fabricate per-form clinical claims; serve only curated/source-backed data.

---

## Audit — what is still on the legacy style (verified by reading the files)

| File | Legacy smells found |
|---|---|
| `Features/Analysis/NutrientDetailView.swift` | `.title2.bold()`, `design: .rounded` (violates SF-Pro thesis), `AppTheme.Color.*`, `Divider()`, `.foregroundStyle(.secondary)`, raw `largeTitle` KPI |
| `Features/Analysis/FormsAndPotencyView.swift` | raw `List`, `Section`, `.secondary` — Settings-app aesthetic |
| `Components/NutrientStatTable.swift` | `Color(.secondarySystemBackground)`, radius 10, `Divider()`, `.subheadline/.secondary` |
| `Components/TierBadgeView.swift` | `AppTheme.Color.tier*` (works via bridge, migrate for purity) |
| `Components/FormPotencyRowView.swift` | `.subheadline/.caption/.secondary`, `fontDesign(.rounded)` avatar |
| `Components/NutrientAnalysisRowView.swift` | (audit) progress bar scale + chevron consistency |
| `Components/HerbalRowView.swift`, `ProbioticRowView.swift`, `UnresolvedLineView.swift` | (audit) likely legacy fonts/colors |
| `Features/Scan/ScanView.swift` | (audit) viewfinder chrome + token integration |
| `Features/Report/ReportView.swift` | (audit) confirm on Theme |

---

### Task 1: Redesign `NutrientDetailView` — premium RDI gauge + honest dose/UL scale
**Files:** rewrite `Features/Analysis/NutrientDetailView.swift`; migrate `Components/NutrientStatTable.swift`.
**Design:** `screenBackground()` + `ScrollView`. Editorial header (display title + "as {form}" subhead). Hero = radial RDI gauge (270° arc, fills `min(pct,100)/100`, center shows true % in `.dsHero` monospacedDigit with `.contentTransition(.numericText())`, `rdiColor`; "Exceeds RDI" chip when >100; graceful "No RDI established" when `rdiPercent == nil`). Below: honest linear **dose · RDI · UL** reference scale (carries the UL safety nuance the ring can't). Then migrated stat card, then form-quality card (tier `fullLabel` + rationale + PMID chips + AI-inferred badge). Respect `accessibilityReduceMotion`.
**Verify:** build green; nutrient detail renders for a seeded nutrient with RDI, one without RDI, one >100% RDI; VoiceOver reads gauge value.

### Task 2: Redesign `FormsAndPotencyView` + `FormPotencyRowView` + `TierBadgeView`
**Files:** rewrite `FormsAndPotencyView.swift` (List→carded `dsSurface` scroll, sorted best→worst tier); migrate `FormPotencyRowView.swift`, `TierBadgeView.swift` to `Theme`.
**Verify:** build green; list shows tier-sorted forms with rationale; tap pushes detail.

### Task 3: Migrate Details-tab row components to `Theme`
**Files:** `HerbalRowView.swift`, `ProbioticRowView.swift`, `UnresolvedLineView.swift`, `NutrientAnalysisRowView.swift` — fonts→`textStyle`, colors→`Theme.Palette`, spacing→`Theme.Space`, unify the RDI bar to one 0–150% scale, ensure tappable rows are consistent.
**Verify:** build green; Details tab + Nutrients tab render correctly light + dark.

### Task 4: Refine `ScanView`
**Files:** `Features/Scan/ScanView.swift` (+ any scan subviews).
**Design:** viewfinder chrome on glass/tokens, brand capture affordance, clear guidance copy, graceful permission-denied state. Do not touch VisionKit pipeline.
**Verify:** build green; scan screen renders; simulator shows viewfinder chrome.

### Task 5: Phase 3d cheap, high-value motion (DEFER Metal)
**Files:** processing/"Analyzing label…" state (MeshGradient, no spinner); scan→report transition polish; `matchedGeometryEffect` nutrient row→detail if cheap. Metal shaders DEFERRED (low marginal value, toolchain risk).
**Verify:** build green; frame analysis of the processing + push transitions (smooth, no stalls).

### Task 6: Verification pass
- `xcodebuild … build` green (gate after every task).
- Simulator: seed sample, screenshot every screen light + dark.
- Accessibility: Dynamic Type (xxxL), VoiceOver labels, Reduce Motion honored.
- Frame analysis (ffmpeg + PIL) of tab switches, push/pop, processing state.
- `ios-code-audit` / `swiftui-pro` pass over changed files.
- (Timeboxed) scan a couple of training photos, eyeball the parsed/report display.

---

## Then (separate, after UI+testing): Library feature, OCR-display data overhaul, App Intents, QOL.
These are tracked separately and begin only once Tasks 1–6 are committed and green.
