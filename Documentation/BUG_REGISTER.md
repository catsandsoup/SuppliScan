# NutriScan — Bug Register
# Pre-emptive catalogue of known failure modes
# Sourced from: corpus analysis, iOS platform bugs (VAndrJ), general engineering bugs (testRigor)
# Purpose: Claude Code generates tests from this register. Document grows as bugs are found.

## How to Use This Document

Each entry has:
- ID: unique reference
- Severity: Clinical (wrong data) | Crash | Data loss | UX | Platform
- Test required: what test catches it
- Prevention: what code pattern prevents it

Claude Code should generate a test for every entry marked TEST_REQUIRED.
When a production bug is found, add it here first, then fix it.

---

## SEVERITY: CLINICAL — Silent Wrong Data (Highest Priority)

### BUG-C01: Double-counting elemental magnesium
Severity: Clinical
Description: Multi-form magnesium labels (e.g. Cabot Health powder) have individual
form entries each with elemental weights, PLUS a total elemental summary line.
If ReportService sums all of them, the RDI% is 2× too high.
Prevention: ReportService must skip entries where isTotalLine = true when summing.
Only entries where isTotalLine = false contribute to calculation.
The total line IS used as the canonical dose when present.
Test: Corpus fixture magnesium_powder_multiform_au.json — expect RDI% based on 400mg, not 800mg.

### BUG-C02: IU unit reaching CalculationService
Severity: Clinical
Description: If UnitConversionService is bypassed or fails silently, a NutrientEntry
with unit = .iu reaches CalculationService. 1000 IU treated as 1000mg produces
catastrophically wrong RDI% for Vitamin D (1000mg vs 25mcg is a 40,000x error).
Prevention: CalculationService must assert unit != .iu at entry and throw
calculationUnitConversionRequired if it receives one. Never silently treat IU as mg.
Test: Pass a NutrientEntry with unit = .iu directly to CalculationService.
Expect AppError.calculationUnitConversionRequired. Never expect a numeric result.

### BUG-C03: European decimal comma parsed as thousands separator
Severity: Clinical
Description: "12,5 mg" on Hair Volume label — if comma is treated as thousands
separator, result is 125mg zinc instead of 12.5mg. 10× overdose in report.
Prevention: ParserService Rule A2 — detect European locale pattern, normalise comma
to decimal point. Flag with ReviewFlag.decimalCommaNormalised.
Test: Parse "Zinc oxide 12,5 mg" → expect amount = 12.5, not 125.
Fixture: hair_volume_new_nordic_au.json.

### BUG-C04: Serving multiplier applied multiple times
Severity: Clinical
Description: If servingMultiplier is applied in ParserService AND again in
CalculationService, a 2-capsule serving becomes 4× the stated amount.
Prevention: Multiplier applied exactly once — in CalculationService only.
ParserService stores the raw label amount. NutrientEntry.servingMultiplier
is the snapshot of what was used, not a pending multiplier to apply.
Test: Create NutrientEntry with amount=300, set ServingSize.multiplier=2.
CalculationService.effectiveDose should be 600. Calling it twice should not produce 1200.

### BUG-C05: isAIInferred flag lost in transformation
Severity: Clinical
Description: FormQuality with isAIInferred=true passes through ReportService,
gets archived to Data, decoded, and isAIInferred is silently false.
Causes AI-inferred tier to display as curated in the report — clinical trust violation.
Prevention: Codable must preserve isAIInferred. No default value in decoder.
Test: Create FormQuality(isAIInferred:true), archive to Data, decode.
Expect isAIInferred == true on decoded result.

### BUG-C06: Race condition in FormQuality lookup
Severity: Clinical  
Description: FormQualityService uses TaskGroup for parallel nutrient analysis.
If two tasks simultaneously attempt curated DB lookup for same form string, and
one triggers AI inference while the other gets the curated result, the curated
result could be overwritten by the AI-inferred result.
Prevention: FormQualityService lookup is synchronous on the curated DB (no await).
AI inference is only triggered when curated lookup returns nil.
The curated path never races with the AI path for the same entry.
Test: Concurrent calls to FormQualityService.assess() for "magnesium glycinate"
from 10 tasks simultaneously. All 10 must return tier=1, isAIInferred=false.

### BUG-C07: nil amount silently treated as zero
Severity: Clinical
Description: NutrientEntry.amount is Optional<Double>. If any code path
force-unwraps or nil-coalesces to 0.0, a nutrient with unknown amount
produces an RDI% of 0% — which looks like zero dose rather than "unknown".
Prevention: CalculationService must check amount != nil before calculation.
If nil, return NutrientAnalysis with rdiPercent=nil, not rdiPercent=0.
Test: Pass NutrientEntry with amount=nil to CalculationService.
Expect rdiPercent == nil, not 0.

### BUG-C08: Wrong RDI used for Iron (sex-dependent)
Severity: Clinical
Description: AU iron RDI is 8mg for adult males, 18mg for adult females.
If demographic is not applied to the lookup, all users get 8mg RDI
and female users see 133% where they should see 300%.
Prevention: ReferenceDataService lookup must include demographic key.
Test: Iron 24mg, standard AU, demographic adult_female_19_50 → expect RDI% ≈ 133.
Test: Iron 24mg, standard AU, demographic adult_male_19_50 → expect RDI% = 300.

---

## SEVERITY: CRASH

### BUG-K01: SwiftData delete crash
Description: Deleting a SwiftData model object directly from a @Query result
in a List crashes after animation completes. Documented Apple bug.
Prevention: All deletes go through PersistenceService.delete(id:).
Never call modelContext.delete() from a View or ViewModel directly.
Test: PersistenceServiceTests — save a record, delete it via PersistenceService,
verify it is absent on next fetch. No crash expected.

### BUG-K02: ForEach Binding crash on last element deletion
Description: Using ForEach with the Binding variant of init, removing the last
element crashes after animation. Documented iOS bug.
Prevention: ReviewView uses ForEach over [LabelEntry] via non-Binding init.
Mutations (delete, edit) go through ReviewViewModel, not direct binding.
Test: ReviewView with one entry — delete it. Expect empty state, not crash.

### BUG-K03: VisionKit memory pressure jetsam kill
Description: VNRecognizeTextRequest on a full-resolution iPhone image allocates
80–120MB temporarily. Under memory pressure, OS kills the app.
Prevention: OCRService must downsample input image to max 2000px longest edge
before passing to VisionKit. Use CGImageSourceCreateThumbnailAtIndex.
Test: OCRService with a 4032×3024px image (typical iPhone full-res).
Monitor peak memory allocation — must stay below 150MB during OCR.

### BUG-K04: NavigationStack searchable path clear
Description: Clearing NavigationPath while .searchable is active does not
navigate back. Documented iOS bug.
Prevention: HistoryViewModel.clearSearch() must set searchText = "" before
clearing NavigationPath. Test: programmatically clear path with search active.

### BUG-K05: Swift 6 + UNUserNotificationCenter closure crash
Description: Closure-based UNUserNotificationCenter.requestAuthorization
crashes in Swift 6 mode. Not used in v1 — add to constraints if notifications added.
Prevention: Use async/await variant if notifications are ever added.

### BUG-K06: ReportService TaskGroup + MainActor boundary
Description: If a TaskGroup child task in ReportService accidentally captures
a @MainActor-isolated type and then performs async work, Swift 6 strict
concurrency may allow this to compile but crash at runtime in some configurations.
Prevention: ReportService is not @MainActor. All types it works with are
value types (structs) or actors. No ViewModels passed into ReportService.
Test: Run ReportService.generate() from a background thread. No crash or
actor isolation error expected.

---

## SEVERITY: DATA INTEGRITY

### BUG-D01: LabelAnalysis Codable round-trip field loss
Description: If a new field is added to LabelAnalysis, NutrientEntry, or
FormQuality without a CodingKey or default value, old archived records will
fail to decode — or decode with zeroed/nil fields silently.
Prevention: schemaVersion field in LabelAnalysis. Any schema change increments
version. Decoder checks version and applies migration if needed.
Test: Archive a LabelAnalysis, add a hypothetical new field to the struct,
attempt decode. Expect either successful migration or graceful failure with
AppError.persistenceLoadFailed — never silent nil fields.

### BUG-D02: Reference data JSON silent empty load
Description: If nrv_au.json is malformed or has encoding issues, JSONDecoder
throws. If the error is swallowed, ReferenceDataService initialises with
zero nutrients. Every subsequent lookup returns nil — report shows
"No reference data" for every nutrient with no error shown.
Prevention: ReferenceDataService.load() must verify nutrient count > 0 after
loading each JSON. If count == 0, throw referenceDataLoadFailed.
Zero-nutrient JSON is never a valid state.
Test: Pass malformed JSON to ReferenceDataService.load(). Expect
AppError.referenceDataLoadFailed, not a silently empty service.

### BUG-D03: Off-by-one in RDI% display rounding
Description: Double arithmetic: 45mg RDI, 500mg dose → 1111.111...
If any intermediate step uses integer division or truncation, result is 1111.1
instead of 1111.1% — difference is small but clinical tools must be exact.
Prevention: All arithmetic uses Double throughout. Rounding to 1 decimal
place happens only at the display formatting layer, never in CalculationService.
Test: CalculationService with amount=500, rdi=45 → expect 1111.1 (not 1111 or 1111.11).

### BUG-D04: ServingMultiplier snapshot mismatch
Description: If user changes serving size after the report is generated but
before it is saved, the saved report may reflect a different serving than shown.
Prevention: LabelAnalysis is immutable after generation. Changing serving size
requires re-generating the report, not mutating the existing one.
The ReportViewModel must invalidate and regenerate when serving changes.
Test: Generate report with serving=1, change serving to 2, verify that a new
LabelAnalysis is generated rather than mutating the existing one.

---

## SEVERITY: UX / PLATFORM BUGS

### BUG-U01: .searchable + .refreshable memory leak
Description: Combining .searchable and .refreshable on the same ScrollView/List
causes a memory leak on iOS 18. Documented Apple bug.
Prevention: HistoryView uses .searchable. Never add .refreshable to the same view.
If pull-to-refresh is needed, implement it in a parent container.

### BUG-U02: onAppear / .task double-fire on NavigationStack replacement
Description: If a NavigationStack view is replaced by another view, .onAppear,
.onDisappear, and .task fire again on return. Can cause ReportViewModel to
reload and overwrite user state.
Prevention: ReportViewModel.loadReport() guarded by hasLoaded flag.
Use .task(id: reportID) so the task only re-fires when the ID changes,
not on every appearance.
Test: Navigate from ReportView to another view and back. loadReport() must
not be called a second time (verify via call count on mock service).

### BUG-U03: Button tap fires after scroll in sheet
Description: ScanView bottom sheet — if user scrolls the extracted entry list
and touch ends over a button, the button action fires. Documented iOS bug.
Prevention: Action buttons (Cancel, Confirm) placed outside the scrollable area
of the sheet. Confirm button is in the navigation bar area, not in the list.

### BUG-U04: Alert button tint inheritance
Description: If .tint(.blue) is applied at NavigationStack level, alert
.default and .cancel buttons are recoloured. Documented iOS bug.
Prevention: Do not apply .tint at NavigationStack level. Apply tint to
specific interactive elements only.

### BUG-U05: Sheet presentationDetents ignored on quick reopen
Description: If ScanView sheet is dismissed and immediately re-presented
(user cancels and retries quickly), .presentationDetents are ignored and
sheet opens full-screen. Documented iOS bug.
Prevention: Debounce the scan trigger — minimum 0.3s between sheet dismissal
and re-presentation. Implement in ScanViewModel.

---

## SEVERITY: INPUT EDGE CASES

### BUG-I01: Non-printable characters in OCR output
Description: Real labels may produce emojis, trademark symbols (®, ™),
zero-width spaces, invisible unicode characters, or broken UTF-8 sequences
from low-quality OCR. These can cause string matching to fail or crash.
Prevention: ParserService sanitises raw OCR text before rule application.
Strip non-printable characters. Normalise unicode (NFC). Handle RTL markers.
Test: Pass OCR text containing ® ™ \u200B \uFEFF to ParserService.
Expect clean output with these characters stripped, not a crash.

### BUG-I02: Empty OCR string
Description: If VisionKit returns an empty string (low confidence, no text),
ParserService receives "". Must return [] not crash.
Test: ParserService.parse("") → expect [].

### BUG-I03: Single-entry label
Description: A label with exactly one nutrient. ForEach deletion of the last
element. ReviewView empty state handling.
Test: Parse label with one entry → delete it in ReviewView → verify empty state.

### BUG-I04: 30+ nutrient label performance
Description: A dense multivitamin with 30+ entries. LazyVStack in ReportView
must render smoothly. TaskGroup in ReportService creates 30+ concurrent tasks.
Prevention: LazyVStack (not VStack) in ReportView for nutrient list.
Test: Report generation with 30 nutrient entries. Expect < 2s total generation time.

### BUG-I05: Amount larger than Double can represent
Description: Malformed label or OCR error produces "99999999999999mg".
Double can represent this but it is not a valid supplement dose.
Prevention: ParserService validates amount range: 0 < amount ≤ 100,000mg (100g).
Anything outside this range returns ReviewFlag.amountNotFound and amount=nil.
Test: Parse "Magnesium 99999999mg" → expect amount=nil, reviewFlags=[.amountNotFound].

---

## FIXED BUGS (2026-06-09 OCR Audit)

### BUG-F01: ReviewView auto-skip (FIXED)
Severity: UX
Description: ReviewView.onAppear called requestAnalysisIfNeeded() which triggered
analysis immediately. onChange(of: pendingAnalysis) then navigated to AnalysisView
before the user could review OCR output. Users could never see or correct the Review screen.
Fix: Removed requestAnalysisIfNeeded() from onAppear. Users tap "Analyse" deliberately.
Files: ReviewView.swift, ReviewViewModel.swift

### BUG-F02: Section header parsed as probiotic (FIXED)
Severity: Clinical (wrong entry type)
Description: "EACH VEGETARIAN CAPSULE CONTAINS: 96 BILLION CFU" was skipped only
when no amountMatch was found. The fallback amountMatch regex matched "96 BILLION"
as "96 unknown unit", causing amountMatch != nil and bypassing the skip.
Fix: ingredientSectionHeaders check is now unconditional (no amountMatch guard).
Files: ParserService.swift

### BUG-F03: isEquivalentContinuation regex word-boundary error (FIXED)
Severity: Data quality (merger fails, form info lost)
Description: Pattern `as\s+\w\b` failed on "(as Selenomethionine)" because \b requires
a word boundary after single \w char, but "S" is followed by "e" — no boundary.
"(as Selenomethionine)" was not merged with "Selenium 150mcg", losing form data.
Fix: Changed to `as\s+\w+` (match full first word of form name).
Files: ParserService.swift

### BUG-F04: Botanical Latin names parsed as junk nutrients (FIXED)
Severity: Data quality (entry type wrong)
Description: Herbal entries (Malus domestica, Equisetum arvense, Silybum marianum etc.)
were being parsed as NutrientEntry with unrecognised canonical names like
"Malus Domestica Dry". No herbal parsing existed.
Fix: Added herbalEntry(from:) with Latin binomial + extract keyword detection.
Parse loop now tries herbal before nutrient.
Files: ParserService.swift

---

## ARTG / Barcode Limitation (Known Infrastructure Gap)

BUG-ARTG01: No public AU supplement barcode → ingredients API
Description: TGA ARTG records contain product identity but not ingredient lists.
Barcode → ingredients lookup is not possible without a licensed or self-built database.
This is not a code bug — it is an infrastructure gap that cannot be fixed in v1.
Impact: Barcode scanning cannot replace OCR for ingredient extraction in v1.
Resolution: Deferred to v2. Options: crowdsource from scans, partner with manufacturers,
or license a supplement ingredient database.
