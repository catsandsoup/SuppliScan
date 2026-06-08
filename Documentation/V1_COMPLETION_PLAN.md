# SuppliScan V1 Completion Plan

Last updated: 2026-06-08

---

## Session Progress Log

### 2026-06-08 — Reference Data Sourcing

**What was done:**

1. **Official NHMRC PDF obtained and saved to the repository.**
   Path: `Documentation/nrv_au_nhmrc_2006_v1.2_sep2017.pdf` (2.1 MB)
   Title: *Nutrient Reference Values for Australia and New Zealand Including Recommended Dietary Intakes, 2006, Version 1.2, Updated September 2017*
   Published by: NHMRC + NZ Ministry of Health. ISBN 1864962437.
   This is the authoritative AU NRV source. All AU numeric data in `nrv_au.json` must trace here.

2. **All adult AU NRV summary tables read directly from the PDF.**
   Tables 5–9 (pages 282–291) were read and all values transcribed. These cover:
   - Table 5 (p282–283): Thiamin, Riboflavin, Niacin, B6, B12, Folate, Pantothenic Acid, Biotin
   - Table 6 (p284–285): Vitamin A, C, D, E, K, Choline
   - Table 7 (p286–287): Calcium, Phosphorus, Zinc, Iron
   - Table 8 (p288–289): Magnesium, Iodine, Selenium, Molybdenum
   - Table 9 (p290–291): Copper, Chromium, Manganese, Fluoride, Sodium, Potassium
   All 10 adult demographics: adult male/female 19–50, 51–70, 70+; adolescent 14–18; pregnant; lactating.

3. **NASEM DRI vitamins table read (partial).** Vitamins data visible: Biotin, Choline, Folate, Niacin, Pantothenic Acid. Mineral DRI tables still needed from official NIH ODS source.

4. **Handoff document created:** `Documentation/HANDOFF_REFERENCE_DATA.md`
   Contains complete transcribed NRV tables, JSON schema reference, ordered implementation steps, and all critical rules. A fresh window can write `nrv_au.json` from this document without re-reading the PDF.

**What was NOT done (next session must complete):**
- `nrv_au.json` not yet written (data ready in HANDOFF_REFERENCE_DATA.md)
- `nrv_us.json` not yet written (partial data available; minerals still needed from NIH ODS)
- `nrv_eu.json` not yet written (stub needed to prevent ReferenceDataService crash)
- `interactions.json` not yet written
- `ReferenceDataService.load()` crash fix not yet applied
- `ReportService.swift`, `FormQualityService.swift`, `InteractionService.swift` not yet written
- `ReviewViewModel.requestAnalysis()` still calls `LabelAnalysis.placeholder(...)` — not ReportService
- Auto-analyse on ReviewView appear not yet implemented
- Auto-tab-switch (RootTabView) not yet removed
- "Nutrient Analysis Pending" developer state views not yet removed

---

## Product Vision

**The hero moment:** Point the camera at a supplement bottle. Within 3 seconds see a plain-English verdict and traffic-light score — "Good form, adequate dose, no concerns" or "⚠ Selenium 133% of UL." Tap for the full clinical breakdown. No "Import Photo," no "Analyse" button, no empty pending screens.

This is a **label-analysis app**, not a supplement-tracking app. There is no daily stack log, no "taken today" count, no reminder schedule, no dose-logging. Features from the Apple Award brief that assume a tracking model (daily widget showing "3 of 7 taken," Siri "log my supplements," Watch tap-to-log, Dynamic Island reminder pill) belong to a different product. Do not build them until the data model supports a tracked stack concept. The features that do transfer: live camera scan as the hero, HealthKit nutrient write after analysis, exportable PDF to share with a GP.

**Apple Award target:** The path to a Design Award is: live scan that works better than anything else on the App Store, real clinical data that catches overlaps users can't see (the selenium-across-two-products example), and craft that makes every interaction feel considered. That is v2+. V1 must simply work.

---

## User Archetypes (from Journey Map — nutriscan_user_journey_map.svg)

Four archetypes. The current app serves none of them fully.

| Archetype | Core job | Minimum viable | Current |
|---|---|---|---|
| Overwhelmed Beginner | "Is this magnesium good?" | Plain-English verdict in ≤5s | ❌ "Pending" |
| Stack Builder | "Am I over on selenium across my stack?" | Cross-product total vs UL | ❌ No stack |
| Safety-Checker | "Is this safe while pregnant?" | UL check + exportable report | ❌ No UL data |
| Value Seeker | At-shelf, two bottles in hand | Live scan + form quality in 10s | ❌ No camera |

**Key design tension (from journey map):** Clinician wants raw data, no friction. Users need plain English + context. Answer: dual-layer UI — verdict + traffic light as the default, clinical detail on tap.

---

## Screenshot Audit — Critical Bugs (2026-06-07)

Screenshots taken on device. Five "why" problems observed.

### Why is there no live scan?
The Scan tab is a static grey box with "Import a supplement label photo." There is no live camera feed. Every use case that happens in real time — standing in a shop comparing two bottles — is blocked. The app cannot be used as described.
**Root cause:** `ScanView` only implements photo library import. No `AVCaptureSession` or live `VNRecognizeTextRequest`.
**Fix:** Replace the grey box with a live camera preview. Keep photo import as secondary. See revised Phase 2.

### Why do I have to click Analyse?
ReviewView has an "Analyse" button that users must deliberately tap. For most users the review step adds no value — they just want the result.
**Root cause:** The Review step was designed as a clinical correction gate. For most users it should be transparent. The Analyse button exists because ReportService isn't wired — it's a developer placeholder that leaked into the product.
**Fix:** Auto-analyse on appearance of ReviewView. Show a brief loading state. Surface the edit option for users who want to correct entries before the result is shown.

### Why do pages automatically change?
After tapping Analyse, the app silently switches to the Analysis tab. Users have no idea why they're on a different screen.
**Root cause:** `AnalysisStore.currentAnalysis` triggers `selectedTab = .analysis` in RootTabView. This is the cross-tab mechanism from the previous session — it was an architectural placeholder, not a validated UX decision.
**Fix proposal (decide before implementing):** Option A — push AnalysisView within the Scan tab's NavigationStack (Scan → Review → Analysis stays in the Scan stack, no tab switch). Option B — keep the tab switch but add an explicit transition (animate the tab bar, show a brief "Analysis ready" banner). Option A is simpler for the user. The current approach is the worst of both worlds.

### Why is there a Pending page?
The Analysis screen shows "Nutrient Analysis Pending — Analysis will appear here once the report service is connected." This is a developer note shown to users.
**Root cause:** Phase 1 (reference data) and Phase 4 (ReportService) are not built. The placeholder passes through to the UI.
**Fix:** Phases 1 + 4 must be completed. The "Pending" content unavailable view must never appear in a release build — gate the whole flow behind a feature flag or simply don't ship until it works.

### Why is the OCR output garbage?
The Review screen on a real Cabot Health magnesium label shows:
- "Taurine" → Needs review (separate row from "1000mg" → Needs review)
- "element", "manies", "tot" → Needs review (OCR word fragments)
- "Also contains malic acid, acacia, stevia..." → Needs review (allergen fine-print)
- "(providing Magnesium" → parsed as an ingredient rather than a sub-entry line

The label actually reads (two-column format):
```
Taurine                              1000mg
Magnesium amino acid chelate         1750mg
  (providing elemental magnesium 350mg)
Magnesium ascorbate                   210mg
  (providing elemental magnesium  13mg)
Zinc (as amino acid chelate)            5mg
```

**Root cause diagnosis (from screenshots, verify against actual OCR output):** The parser is marked "done and tested" but fails on every real label. The likely explanation is that the test fixtures were hand-crafted strings, not actual Vision framework output. Real Vision output for a two-column label returns the name token and the amount token as separate observations with X-position data — left-column tokens (nutrient names) and right-column tokens (amounts) are not on the same line in the raw Vision output. A text-line heuristic that expects "Taurine 1000mg" on one line will never see that string.

Additionally:
- Serving size description line ("Each level metric teaspoon (5g dose) contains:") is being parsed as an ingredient
- Fine-print / allergen disclaimer text at the bottom of the label is being OCR'd and surfaced as unresolved entries
- "1400-5" (product code from label background) is being captured

**Fix (implemented):** Two-column merging pre-pass added to `ParserService.mergedTwoColumnLines()`. Consecutive name-only + amount-only lines are merged before parsing. Real-device testing required to validate against additional label formats.

---

## Redesigned Interaction Model (Proposal)

This is a proposed flow, not a final decision. Validate before implementing.

**Target experience:**
```
Open app → live camera already running (like a QR scanner)
Point at label → corners pulse green when structured text detected
Tap shutter button (or auto-capture after 1.5s stable)
  ↓ [1-3 second analysis]
Result screen (within Scan stack — no tab switch):

  ┌─────────────────────────────────┐
  │ Magnesium Complex · Cabot Health│
  │ ●●●○  Good quality blend        │
  │ 400mg elemental · 57% of RDI   │
  │ [View Full Analysis]            │
  └─────────────────────────────────┘
  Scroll ↓ for full clinical detail
```

**Changes from current flow:**
- Grey import box → live camera viewfinder (always on in Scan tab)
- "Review Required" title → parsed product name or editable placeholder
- Mandatory Review + Analyse button → auto-analyse; Edit available but not required
- Auto-tab-switch to Analysis → push result screen within Scan stack
- "Nutrient Analysis Pending" → only shows real data or an honest "scanning..." loading state

**Dual-layer result screen:**
- Layer 1 (default): traffic-light score + one-sentence verdict + primary metric (e.g. "57% of RDI for Magnesium")
- Layer 2 (tap "Full Analysis"): the current AnalysisView with Summary/Nutrients/Details tabs

---

## Apple Platform Integrations — Post-v1 Roadmap

These are **not v1**. Do not build until the core analysis loop is correct and tested on real labels.

| Integration | Relevance to this app | Target |
|---|---|---|
| HealthKit nutrient write | Write Magnesium, Vitamin D, Zinc, etc. to Apple Health after scan | v2 

**Not applicable to this app (tracking model required):**
- "3 of 7 supplements taken today" widget — requires daily dose log, not in data model
- "Hey Siri, log my morning supplements" — requires regimen, not in scope
- Reminder/notification for missed doses — different product category

---

## Apple Design Award Pillars — v1 Target vs Current

| Pillar | v1 minimum needed | Current state |
|---|---|---|
| Originality | Live scan that outperforms competitors, real NRV verdict | ❌ Photo import + Pending |
| Inclusivity | Full VoiceOver, all Dynamic Type sizes, Reduce Motion respected | ⚠️ Unverified |
| Delight | Every tap has intentional haptic, progress bars animate, scan feels magical | ❌ Barebones |
| Innovation | Catches what users can't see (selenium overlap example) | ❌ Nothing computed |
| Impact | User can share a real report with their GP | ❌ No data, no export |

---

## Current Truth

- Persistence API is SwiftData. No direct Core Data stack or `.xcdatamodeld` exists.
- `ScanRecord` is the only `@Model`, included in `SuppliScanSchemaV1`.
- SwiftData writes go through `PersistenceService`; views use `@Query` for read-only live lists.
- Unit tests pass for current service/view-model slice: parser, IU conversion, calculation, and Home view-model loading.
- Current UI test can pass, but the iOS 26.5 simulator sometimes fails to install or launch the test runner with CoreSimulator invalid-device-state / Mach `-308`.
- OCR, full review flow, full report UI, PDF export, official AU/US/EU reference data, and production clinical-report orchestration remain incomplete.

## Operating Rules

Use the project skill routing before each implementation slice:

- Architecture: `swift-architecture-skill`, plus `axiom-swiftui-architecture` for SwiftUI boundaries.
- SwiftUI: `swiftui-pro`, then audit with HIG, `axiom-liquid-glass`, `axiom-audit-swiftui-layout`, `axiom-audit-swiftui-nav`, and accessibility skills.
- SwiftData: `swiftdata-pro` or `axiom-swiftdata`, then `axiom-audit-swiftdata`.
- Concurrency: `swift-concurrency-pro` or `axiom-swift-concurrency`, then `axiom-audit-concurrency`.
- Tests: `swift-testing-pro`, then `axiom-audit-testing`.
- OCR/camera/privacy: use camera/privacy/security audit skills after edits.
- Docs, summaries, handoffs, and commits: use `stop-slop`.

Do not mark V1 complete until all acceptance criteria below pass on the current checkout.

## Phase 0 — Stabilize The Base

Desired outcome: the current branch has a known-good baseline.

Steps:

1. Fix or record the iOS 26.5 simulator runner instability.
2. Keep the unit suite green.
3. Keep the Home launch smoke test, but treat Mach `-308` as simulator infrastructure when the app builds and direct `simctl launch` works.
4. Capture screenshots to stable paths under `/tmp` or `Artifacts/`, not disappearing `/var/folders` attachment paths.
5. Update `HANDOFF.md` or supersede it with this file in future handoffs.

Acceptance criteria:

- `xcodebuild test ... -only-testing:SuppliScanTests` succeeds.
- Direct `xcrun simctl launch booted montygiovenco.SuppliScan` succeeds.
- Fresh screenshot shows the current app, not the Simulator home screen.
- `rg` confirms no direct Core Data APIs, no `DispatchQueue`, no `ObservableObject`, no `@Published`, no `@StateObject`, and no `@EnvironmentObject`.

## Phase 1 — Official Reference Data

Desired outcome: bundled AU, US, and EU nutrient reference data is accurate, sourced, and test-covered.

Steps:

1. Pull AU NRVs from official NHMRC / Australian Government sources.
2. Pull US values from official NIH ODS, NASEM DRI tables, and FDA Daily Value sources where the app needs label-context values.
3. Pull EU values from EFSA / European Commission official sources.
4. Record source URL, source title, access date, nutrient, demographic, unit, RDI/AI/EAR type, UL, and caveats.
5. Do not use blogs, AI summaries, supplement stores, or copied tables without official traceability.
6. Use Browser or Chrome only to reach official source pages and PDFs when the data cannot be fetched by a stable public URL or script.
7. Add `nrv_au.json`, `nrv_us.json`, and `nrv_eu.json` with schema validation tests.
8. Add tests for demographic fallback, missing UL, missing RDI, unit mismatch, and source preservation.

Acceptance criteria:

- Every bundled numeric reference has an official source string.
- JSON decodes through `ReferenceDataService`.
- Tests prove at least one adult, pregnancy, lactation, older adult, and sex-specific lookup per region.
- Missing data stays nil, never `0`.

## Phase 2 — OCR Pipeline

Desired outcome: the app captures supplement labels via live camera and produces reliable raw text with reviewable confidence failures.

### Critical issue (from screenshots)
The current ScanView is a static grey box with photo-library import only. There is no live camera. This blocks the primary use case ("point at a label in a shop") and is the first thing a user notices.

Steps:

1. **Replace the grey import box view entirely with modern iOS  live camera viewfinder.** Use `AVCaptureSession` with a `AVCaptureVideoPreviewLayer` embedded in a SwiftUI view. This should be the default state of the Scan tab — always on, like a QR scanner. Photo library import stays as a secondary option (small button below the viewfinder).
2. Add animated corners (pulse green when a rectangular region with dense text is detected) to signal "label detected."
3. On shutter tap (or 1.5-second stable-detection auto-capture), freeze frame and run `VNRecognizeTextRequest` on the captured `CVPixelBuffer`.
4. **Return raw `VNRecognizedTextObservation` array, not just strings.** The bounding-box geometry (`boundingBox`) is critical for the Phase 3 parser to reconstruct the two-column table structure. Do not reduce observations to strings before handing to the parser.
5. Use Vision for OCR text recognition; use VisionKit only where it adds capture UX.
6. Add camera permission copy that explains label scanning, not health tracking.
7. Downsample still images to max 2000 px before OCR; live preview can run at native resolution.
8. Support multi-line ingredient panels, supplement facts panels, and labels split across photo frames.
9. Throw or surface `.ocrNoTextFound` and `.ocrLowConfidence(recognisedText:)`.

Acceptance criteria:

- Scan tab opens directly to live camera preview (not a grey box or import button).
- OCR service returns `[VNRecognizedTextObservation]` with bounding-box data preserved, not just `[String]`.
- OCR service has deterministic unit tests for low-confidence, no-text, and multiline joining.
- Real label fixture tests cover the corpus in `Documentation/TEST_CORPUS.md`.
- OCR output never goes straight to calculation without review when confidence is low.

## Phase 3 — Parser And Clinical Logic

Desired outcome: raw OCR text becomes typed entries without silent guesses.

### Critical issue (from screenshots) — real-label parsing is completely broken
The parser is marked "done and tested" but fails on every real label tested. The test fixtures are apparently hand-crafted strings, not actual Vision output. On a Cabot Health magnesium label:
- "Taurine" and "1000mg" appear as separate unresolved rows instead of one paired entry
- "Magnesium amino acid chelate" and "1750mg" — same failure
- "(providing Magnesium" appears as an ingredient row
- "element", "manies", "tot" appear as unresolved (OCR fragments of "elemental", possibly "companies", "total")
- "Also contains malic acid, acacia, stevia..." and full allergen disclaimer text appear as unresolved rows

**Root cause (confirmed):** Vision returns two-column supplement fact tables as spatially-separated observations. `ParserService.mergedTwoColumnLines()` now merges consecutive name-only + amount-only lines before parsing. Test on real device labels and extend heuristics if needed.

Additional fixes needed regardless:
- **Serving size line detection:** The line "Each level metric teaspoon (5g dose) contains:" must be recognized as the serving descriptor and not passed to entry parsing. Add heuristics: contains "contains:", follows a standalone weight "Xg", or is the first dense-text line.
- **Parenthetical providing-lines:** "(providing elemental magnesium 350mg)" should be tagged as a `.subEntry(of: parentNutrient)`, not a standalone entry.
- **Fine-print / allergen disclaimer filtering:** Text blocks starting with "Also contains", "Contains no", "Free of", "Does not contain" are ingredient lists or allergen statements. Strip or tag as non-nutrient before entry parsing.
- **Short-fragment filtering:** Single words or fragments under ~4 characters that don't match any known nutrient name should be dropped or aggregated, not surfaced as unresolved entries.
- **Product code / label artifact filtering:** Alphanumeric strings like "1400-5" that match a product-code pattern (digits-digits) should be suppressed.

Steps:

1. **Inspect real Vision output first.** Add a debug dump that prints `VNRecognizedTextObservation` bounding boxes from a real label before any parsing. Record in `Documentation/TEST_CORPUS.md`.
2. Fix ingredient/amount pairing based on findings from step 1.
3. Add serving-size line detection (filter before entry parsing).
4. Add parenthetical providing-line recognition → `.subEntry`.
5. Add fine-print / disclaimer filtering.
6. Add short-fragment and product-code suppression.
7. Complete `ParserService` against every rule in `Documentation/PARSER_SPEC.md`.
8. Add support for herbal entries, probiotic entries, raw unresolved lines, total lines, continuation lines, and sub-entry handling.
9. Keep IU conversion inside parser/unit conversion boundaries.
10. Ensure `CalculationService` receives no `.iu` values and applies serving multiplier exactly once.
11. Build `FormQualityService` from curated form data before adding any AI fallback.
12. Add AI fallback only for form-quality gaps, sending only nutrient name and form string.
13. Preserve `isAIInferred` through Codable round trips and reports.

Acceptance criteria:

- Parser is tested against actual Vision output captured from a real label (not hand-crafted strings).
- The Cabot Health magnesium label produces correct paired entries (Taurine 1000mg, Magnesium amino acid chelate 1750mg, Zinc 5mg) with no unresolved rows for those nutrients.
- Allergen / fine-print text does not appear in the unresolved entries list.
- OCR fragments under the minimum name length threshold do not appear as unresolved entries.
- Parser corpus tests cover nutrients, herbs, probiotics, blends, totals, ranges, trace, sub-one, decimal comma, unknown units, and unresolved raw lines.
- Calculation tests cover RDI%, UL%, nil reference data, missing amount, unsupported unit, and serving multipliers.
- No AI path can alter RDI/UL, amount, serving, unit, or official reference values.

## Phase 4 — Report Service

Desired outcome: one scan produces a complete `LabelAnalysis`.

Steps:

1. Implement `ReportService` as the orchestration boundary.
2. Load reference data once, then reuse in memory.
3. Use structured concurrency for per-entry analysis.
4. Handle all `LabelEntry` cases: nutrient, herbal, probiotic, unresolved.
5. Apply total-line logic so totals are not summed with sub-entries.
6. Set `LabelAnalysis.disclaimer` and `LabelAnalysis.currentSchemaVersion` on every report.
7. Persist completed analyses through `PersistenceService`.

Acceptance criteria:

- Integration tests create a full `LabelAnalysis` from fixture OCR text.
- Disclaimer is present in every generated report.
- Schema version is set on every persisted report.
- Unresolved entries survive into report flags and review UI.

## Phase 5 — V1 SwiftUI Product Flow

Desired outcome: the app feels like a finished iOS 26 clinical utility, not a stub collection.

### Status: UI shell complete. Services not yet wired.

**Architecture changes (done):**
- `AppDestination` — renamed `.report` → `.analysis`, added `.nutrientDetail(NutrientAnalysis)`, `.formsAndPotency([NutrientAnalysis])`
- `RootTabView` — 4-tab root (Scan · Analysis · History · Settings). Each tab owns its own `NavigationRouter` instance. `AnalysisStore` drives automatic tab switch after analyse.
- `SuppliScanApp` — uses `RootTabView()` as root. No global `NavigationRouter`.
- `AnalysisStore` — `@Observable @MainActor` holding `currentAnalysis: LabelAnalysis?`. Written by ReviewView; watched by RootTabView.

**New model files (done):**
- `LabelAnalysis+Placeholder.swift` — `LabelAnalysis.placeholder(entries:serving:standard:)` factory
- `NutrientCategory.swift` — `all | vitamins | minerals | other` with `matches(_ analysis:)` predicate
- `NutrientAnalysis+Display.swift` — `rdiColor`, `rdiPercentString`, `ulPercentString`, `doseString`, `rdiReferenceString`, `ulReferenceString`

**Screens (done):**
- `ReviewView` + `ReviewViewModel` — full implementation: SupplementFactsCard, serving selector, standard/demographic pickers, Analyse button
- `AnalysisView` — 3 internal tabs (Summary · Nutrients · Details) using FilterChip + paged TabView
- `NutrientDetailView` — RDI KPI, stats table, form quality section
- `FormsAndPotencyView` — List of nutrients with form quality, tap to NutrientDetail
- `HistoryView` — search, swipe-delete, EditButton, empty state
- `SettingsView` — default standard/demographic, delete-all with confirmation, about/disclaimer

**Components (done — all in `Components/`):**
FilterChip · TierBadgeView · AIInferredBadgeView · FlagBannerView · ReportSummaryCardView · ReportSectionHeader · NutrientAnalysisRowView · NutrientFilterBar · ReviewEntryRowView · LabelRecognisedBannerView · SupplementFactsCardView · ServingSizeSelectorView · StandardPickerView · DemographicPickerView · HerbalRowView · ProbioticRowView · UnresolvedLineView · DisclaimerView · NutrientStatTable · FormPotencyRowView

**Remaining items before Phase 5 acceptance criteria pass:**

**Interaction design fixes (do these first — they address the "why" questions from user testing):**

1. **Remove auto-tab-switch to Analysis** — `AnalysisStore.currentAnalysis` triggers `selectedTab = .analysis` in `RootTabView`. This is jarring and confusing. Decision required: push `AnalysisView` within the Scan tab's `NavigationStack` (Option A, preferred) OR keep tab switch but add an animated transition with a "Analysis ready" banner (Option B). Current behaviour (silent switch) is neither. Implement Option A unless deliberately choosing B.
2. **Remove manual "Analyse" button friction** — `ReviewView` should auto-trigger analysis on appear (with a loading state) rather than requiring a button tap. The Analyse button becomes an "Edit entries first" gate only for users who actively want to review. Most users scan → get result, no button required.
3. **Remove "Nutrient Analysis Pending" exposed developer state** — the `ContentUnavailableView` that shows "Analysis will appear here once the report service is connected" must never be visible in a release build. Gate behind an `#if DEBUG` flag or remove the view entirely until Phase 4 is wired. The empty summary card is acceptable as a loading state; the developer note is not.
4. **Replace "Review Required" product name** — `LabelAnalysis.placeholder` uses "Review Required" as the product name. Parser should attempt to extract a product name from the label (first prominent text block above the ingredient panel). If extraction fails, use "Unnamed Product" and allow inline tap-to-edit.
5. **AppStorage defaults wiring** — `ReviewViewModel.selectedStandard` and `.selectedDemographicKey` start hardcoded (shows "US" even when Settings is set to AU). Add `.onAppear` that reads `@AppStorage("defaultStandard")` and `@AppStorage("defaultDemographicKey")` and applies them.

**Functionality fixes:**

6. **SupplementFactsCardView edit-mode delete** — `.onDelete` on ForEach inside VStack doesn't work (SwiftUI requires List). Replace with per-row destructive Button shown when `isEditing = true`. Keep card styling.
7. **Wire ReportService** (Phase 4 prerequisite) — `ReviewViewModel.requestAnalysis()` creates a placeholder with empty `nutrientAnalyses`. Expected until Phase 4 is done. This is the single largest functional gap — the entire app feels broken until real analysis data flows.
8. **Wire PersistenceService.save** — completed analyses are not yet saved to SwiftData. Add `dependencies.persistence.save(...)` call after analysis is generated.
9. **Dead code cleanup** — `Features/Report/ReportView.swift` is unreferenced (replaced by AnalysisView). `Features/Home/` files compile but are no longer root. Remove when confident.

**Polish (do last, after functionality works):**

10. **Accessibility pass** — add missing `accessibilityLabel` / `accessibilityHint` on interactive controls. Run VoiceOver.
11. **Haptics pass** — verify all generators call `.prepare()` in `onAppear` and are stored as `@State`.
12. **Animation reduce-motion** — verify `ReviewEntryRowView` and `NutrientAnalysisRowView` stagger respect `@Environment(\.accessibilityReduceMotion)`.
13. **Dual-layer result screen** — once real analysis data flows, add a hero verdict card at the top of `AnalysisView`: traffic-light score + one-sentence summary + primary metric. Full clinical detail remains below the fold. This is the "plain English first, clinical detail on tap" pattern from the journey map.

Design direction:

- Use native SwiftUI controls and system semantic colors.
- Let iOS 26 standard controls adopt Liquid Glass through the system.
- Do not add decorative custom glass cards.
- Use clinical visual hierarchy: calm, dense enough to scan, no marketing hero.
- Use color plus text/icons for risk and tier indicators.
- Keep all tap targets at least 44 pt.
- Support Dynamic Type, Reduce Motion, Increase Contrast, and VoiceOver.

Acceptance criteria:

- No placeholder `ContentUnavailableView` remains for implemented V1 screens.
- UI tests cover launch, scan/manual path, review to report, save to history, reopen report, export entry point, and delete confirmation.
- Screenshots pass visual inspection on iPhone 17 Pro and one smaller iPhone simulator.
- SwiftUI layout audit finds no critical/high issues.
- Accessibility audit finds no missing labels on interactive controls.

## Phase 6 — Export And Sharing

Desired outcome: practitioners can export a useful report without privacy leakage.

Steps:

1. Build `ExportService` with PDFKit.
2. Include report title, source standard, demographic, date, entries, RDI/UL values, flags, sources, and disclaimer.
3. Return `Data` to the caller and share through native share UI.
4. Add failure handling for PDF generation.

Acceptance criteria:

- PDF export test proves a non-empty PDF with expected clinical sections.
- UI exposes export from Report only after analysis exists.
- No temporary export file persists longer than needed.

## Phase 7 — Persistence And Migration Hardening

Desired outcome: saved scans are durable and migration-ready.

Steps:

1. Add CRUD tests for `PersistenceService` with in-memory `ModelContainer`.
2. Test duplicate save replacement by `LabelAnalysis.id`.
3. Test delete and delete-all paths.
4. Rehearse migration with a v1 store before any schema change.
5. Decide whether `reportData` should use external storage after measuring report size.

Acceptance criteria:

- Persistence tests prove save, fetch, replace, delete, and decode failure handling.
- SwiftData audit has no critical/high issues.
- Core Data audit confirms no direct Core Data stack unless explicitly approved.

## Phase 8 — V1 Release Gate

Desired outcome: V1 is genuinely ready before V2 work starts.

Gate checklist:

- All unit, integration, and UI smoke tests pass or have documented simulator-only failure with direct app proof.
- All official data sources are recorded and reproducible.
- OCR works on real fixture images.
- Parser handles every fixture without silent drops.
- Report generation handles every `LabelEntry` case.
- Home, Scan, Review, Report, History, and Settings are complete.
- HIG/Liquid Glass review passes.
- Accessibility review passes.
- SwiftData, concurrency, security/privacy, and test audits pass.
- App contains no therapeutic claims beyond descriptive supplement-label analysis.
- V1 handoff lists exact commands, screenshots, remaining risks, and source-data provenance.
