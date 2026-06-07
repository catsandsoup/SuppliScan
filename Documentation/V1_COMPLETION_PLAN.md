# SuppliScan V1 Completion Plan

Last updated: 2026-06-07

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

Desired outcome: the app captures supplement labels and produces reliable raw text with reviewable confidence failures.

Steps:

1. Build camera/photo input behind a native SwiftUI screen.
2. Use Vision for OCR text recognition; use VisionKit only where it adds capture UX.
3. Add camera permission copy that explains label scanning, not health tracking.
4. Downsample images to max 2000 px before OCR.
5. Support multi-line ingredient panels, supplement facts panels, and labels split across photo frames.
6. Return raw text plus confidence metadata.
7. Throw or surface `.ocrNoTextFound` and `.ocrLowConfidence(recognisedText:)`.
8. Add a review path for users to correct OCR before calculation.

Acceptance criteria:

- Simulator or device flow reaches scan screen without placeholder UI.
- OCR service has deterministic unit tests for low-confidence, no-text, and multiline joining.
- Real label fixture tests cover the corpus in `Documentation/TEST_CORPUS.md`.
- OCR output never goes straight to calculation without review when confidence is low.

## Phase 3 — Parser And Clinical Logic

Desired outcome: raw OCR text becomes typed entries without silent guesses.

Steps:

1. Complete `ParserService` against every rule in `Documentation/PARSER_SPEC.md`.
2. Add support for herbal entries, probiotic entries, raw unresolved lines, total lines, continuation lines, and sub-entry handling.
3. Keep IU conversion inside parser/unit conversion boundaries.
4. Ensure `CalculationService` receives no `.iu` values and applies serving multiplier exactly once.
5. Build `FormQualityService` from curated form data before adding any AI fallback.
6. Add AI fallback only for form-quality gaps, sending only nutrient name and form string.
7. Preserve `isAIInferred` through Codable round trips and reports.

Acceptance criteria:

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

Screens to finish:

- Home: themed empty state, recent scans, settings access, scan/manual entry.
- Scan: camera/photo import, permission states, OCR progress, retry.
- Review: editable parsed entries, serving-size editor, unresolved-line resolution, region/demographic picker.
- Report: clinical summary, RDI/UL sections, form-quality section, flags, disclaimer, export/share.
- History: search/filter, saved report open, delete with confirmation.
- Settings: reference standard, demographic, privacy, disclaimer, source versions.

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
