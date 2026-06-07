# NutriScan — Release Testing Plan
# What to test at each version gate, how to test it, and what pass looks like
# Claude Code generates tests from BUG_REGISTER.md and TEST_SPEC.md.
# This document covers integration, acceptance, and manual testing per release.

---

## Testing Philosophy

Unit tests (from BUG_REGISTER.md + TEST_SPEC.md) run on every commit via CI.
Integration tests run before every TestFlight build.
Manual acceptance tests run before every App Store submission.

Swift Testing (@Test, #expect) for all unit and integration tests.
XCTest for UI tests where Swift Testing cannot reach (camera, sheets, haptics).
Manual testing for anything requiring physical device + real labels.

---

## V1 TESTING GATES

### Gate 1: Core Services (Pre-UI, automated)
Run before any UI is built. All must pass before ViewModels are written.

#### Parser accuracy (from corpus)
For each fixture in TestFixtures/ParsedLabels/:
- Load expected JSON
- Pass corresponding label text to ParserService
- Assert every field in expected_entries matches actual output
- Assert review_flags match expected flags
- Assert no expected_entries are missing
- Assert no unexpected entries are added

Corpus fixtures to run:
- selenium_150mcg_au (single nutrient, as-qualifier)
- magnesium_powder_multiform_au (multi-form elemental, total line)
- hair_volume_new_nordic_au (EU decimal comma, herbal+nutrient)
- vitamin_d3_1000iu_au (IU conversion)
- vitamin_c_1g_zinc_bioflavonoids_au (total summary line)
- iron_ferrochel_b_vitamins_au (trademark stripping, active B vitamins)
- probiotic_96b_cfu_multistrain_au (CFU classification, no nutrients)
- saw_palmetto_3500_au (herbal only classification)
- chlorella_tablets_au (food nutrition panel format)

Pass criteria: 100% field match on all fixtures with zero unexpected entries.

#### Unit conversion accuracy
All conversions from PARSER_SPEC.md unit conversion table:
- Vitamin D: 1000 IU → 25 mcg ✓
- Vitamin D: 40 IU → 1 mcg ✓
- Vitamin E natural (d-alpha): 100 IU → 67 mg ✓
- Vitamin E synthetic (dl-alpha): 100 IU → 45 mg ✓
- Vitamin A retinol: 1000 IU → 300 mcg RAE ✓
- Iron IU → AppError.calculationUnsupportedUnit (IU invalid for iron) ✓
- Any .iu reaching CalculationService → AppError.calculationUnitConversionRequired ✓

#### Calculation accuracy (BUG register test cases)
- BUG-C01: Magnesium multi-form — expect 400mg total, not 800mg (double-count)
- BUG-C03: Decimal comma — "12,5 mg" → 12.5mg not 125mg
- BUG-C04: Serving multiplier — applied once only, not twice
- BUG-C07: nil amount — returns rdiPercent=nil not rdiPercent=0
- BUG-C08: Iron sex-dependent — female 24mg → 133% RDI, male → 300% RDI
- BUG-D03: Rounding — 500mg / 45mg RDI → 1111.1%, not 1111%

#### FormQuality integrity
- TC-FORM-01: Curated hit returns isAIInferred=false
- TC-FORM-03: Miss triggers AI, returns isAIInferred=true
- TC-FORM-04: Hit never calls AIService (verify via mock spy)
- TC-FORM-05: Offline returns graceful degradation, not crash
- BUG-C05: isAIInferred=true survives Codable round-trip

#### Persistence
- TC-PERSIST-01: Save → fetch → compare LabelAnalysis fields
- TC-PERSIST-02: Delete removes record, no orphaned data
- TC-PERSIST-03: Reopen produces identical report
- BUG-D02: Malformed JSON → AppError.referenceDataLoadFailed (not silent empty)
- BUG-K01: Delete via PersistenceService, not direct modelContext

---

### Gate 2: Integration (Services + ViewModels, automated)

#### Full pipeline: OCR text → LabelAnalysis
Inject raw OCR strings from corpus (bypass camera) into full pipeline.
For each corpus fixture:
1. Parse raw text → [LabelEntry]
2. Apply serving size (default from fixture)
3. Run ReportService.generate()
4. Assert LabelAnalysis matches expected_clinical_notes in fixture JSON

Critical pipeline assertions:
- No NutrientEntry with unit == .iu at CalculationService boundary
- All isTotalLine=true entries excluded from summation
- ServingMultiplier applied exactly once
- LabelAnalysis.schemaVersion == LabelAnalysis.currentSchemaVersion

#### Error propagation
- OCR returns empty string → LoadingState.failed(.parserNoNutrientsExtracted)
- AI service times out → FormQuality with nil tier, "unavailable" note
- PersistenceService fails on save → report still shown, save-failed toast
- Reference data 0 nutrients → LoadingState.failed(.referenceDataLoadFailed)

---

### Gate 3: UI Acceptance (Manual, on physical device)

#### Scan flow
1. Scan selenium_150mcg label (IMG_1143) in good lighting
   - Pass: product name extracted, 150mcg shown, form "selenomethionine"
   - Pass: RDI% ≈ 250%, UL% ≈ 37.5% (AU adult male default)
   - Pass: Summary card shows "High" form quality

2. Scan magnesium powder label (IMG_1131) in good lighting
   - Pass: 4 magnesium forms detected, total elemental = 400mg
   - Pass: Single RDI calculation using 400mg, not 800mg
   - Pass: Summary card shows "Mixed" (amino acid chelate + phosphate)
   - Pass: UL flag shown (400mg > 350mg AU supplemental UL)

3. Scan hair_volume label (IMG_1144) — European format
   - Pass: Zinc shown as 10mg (not 125mg — decimal comma test)
   - Pass: ReviewFlag.decimalCommaNormalised shown for zinc row
   - Pass: Biotin shown as 0.48mg (480mcg — sub-1mg test)

4. Scan vitamin_d3 label (IMG_1139)
   - Pass: 25mcg shown (not 1000IU — conversion test)
   - Pass: RDI% ≈ 500% (AU AI = 5mcg adult)

5. Scan probiotic label (IMG_1136)
   - Pass: Probiotic section shown, not nutrient section
   - Pass: 15 strains listed with CFU
   - Pass: "No NRV data available" shown
   - Pass: No RDI% attempted

6. Scan saw_palmetto label (IMG_1133)
   - Pass: Herbal section shown, not nutrient section
   - Pass: Extract type, dry equivalent, fatty acid standardisation all shown

#### Speed test (NFR-P: point-of-purchase)
Timer: camera open → summary card visible
Target: ≤ 8 seconds on iPhone 12 or newer in good lighting
Test label: any single-nutrient label (fastest parse)
Fail criteria: > 10 seconds

#### Review flow
1. Long-press any OCR row → edit mode → change amount → confirm
   - Pass: corrected value used in report, not original OCR value
   - Pass: ReviewFlag.manuallyEdited shown in report detail

2. Delete a row → verify entry removed from analysis
   - Pass: entry absent from report
   - Pass: no crash (BUG-K02 — last element deletion)

3. Serving size selector
   - Pass: changing serving changes all RDI% values proportionally
   - Pass: serving size stated in report header

4. Add nutrient manually (no scan)
   - Pass: manually entered nutrient appears in report
   - Pass: no crash on empty string or very long string (BUG-I01)

#### Report view
1. All sections present: summary card, flags (when applicable), nutrient table,
   herbal section (when applicable), probiotic section (when applicable),
   recommendations, disclaimer
2. Tap a nutrient row → rationale text expands → tap again → collapses
3. Tier badge: colour + text + form name (never colour alone — BUG-U04 accessibility)
4. Export PDF → share sheet → verify PDF contains all sections including disclaimer
5. AI-inferred tier rows: purple badge visible, "AI-inferred — review recommended"

#### Accessibility
1. Enable VoiceOver → scan a label → navigate report with VoiceOver only
   - Pass: every row announced with nutrient name, dose, RDI%, tier
   - Pass: tier badges announced as text ("Tier 1 — High bioavailability"), not colour
2. Set largest text size (Accessibility Inspector) → verify no text truncates or overlaps
3. Enable high contrast → verify tier colours remain distinguishable

#### History
1. Save 3 scans → History shows 3 entries in reverse chronological order
2. Search "selenium" → only selenium scan shown
3. Swipe delete one → entry gone, app does not crash
4. Tap entry → report reopens identically

#### Edge cases (manual)
1. Scan non-supplement label (food product) → review shows partial parse → user dismisses all → empty report with clear message
2. Scan in dim lighting → OCR low confidence → "Try tilting label to reduce glare" shown
3. Scan curved bottle (chlorella IMG_1135) → verify partial extraction shown with review flags, not crash
4. Background + return → verify no data loss, no doubled lifecycle calls (BUG-U02)
5. Dismiss sheet quickly + reopen → sheet opens at correct detent (BUG-U05)

---

## V2 TESTING GATES

### Stack Analysis (F9)
Unit tests:
- StackCalculationService: 150mcg + 50mcg selenium → total 200mcg
- UL comparison: 200mcg > 150mcg AU UL → StackFlag.ulExceeded
- Multiple nutrients: sum each nutrient across all stack products independently
- Products with different standards in same stack → error or forced standard unification

Integration tests:
- Create stack with selenium_150mcg + st_marys_thistle fixtures
- Assert selenium total = 200mcg
- Assert stack UL flag fires for selenium
- Assert other nutrients (taurine, etc.) correctly summed

Acceptance test:
- Scan both selenium products in the app
- Add both to a Stack
- Stack Report shows selenium 200mcg / 150mcg UL = 133% — red flag
- Individual reports unchanged

### Interaction Checking (F10)
Acceptance test (before clinical review):
- Warfarin + Vitamin K: any Vitamin K product → interaction flag
- Statin + CoQ10: any statin (user-declared) + CoQ10 product → synergy flag
- Biotin high dose + lab tests: biotin > 300mcg → lab interference warning

Critical: Every interaction flag text must be reviewed by a clinician before
TestFlight. Do not ship interaction warnings that are clinically incorrect.

---

## V3 TESTING GATES

### HealthKit (F17)
- After scan with Vitamin D → Apple Health Nutrients → Vitamin D shows NutriScan as source
- After scan → verify no data written without user permission
- After scan → verify label amounts written, not RDI% or other derived values
- HealthKit entitlement present in target capabilities
- Privacy usage string present in Info.plist

### Widget (F18)
Requires tracking layer to exist before testing.
If tracking is not added, widget cannot be tested.

### Spotlight (F22)
- Scan magnesium product → exit app → Spotlight search "magnesium" → NutriScan result appears
- Tap result → opens app to that scan's report
- Delete scan → Spotlight result removed

---

## Regression Protocol

When any production bug is reported:
1. Add it to BUG_REGISTER.md with severity and test requirement
2. Write the failing test FIRST (it should fail with the bug present)
3. Fix the bug
4. Verify the test now passes
5. Add to the relevant Gate above so it runs on every future release

This is the standard: every bug that ships once must have a test that catches it forever.

---

## Performance Baselines (Record Per Release)

Measure on iPhone 12 (minimum supported device) and record:

| Metric | v1 Target | Actual v1 | v2 Target |
|---|---|---|---|
| OCR → summary card | ≤ 8s | TBD | ≤ 6s |
| Report generation (30 nutrients) | ≤ 1s | TBD | ≤ 1s |
| Cold launch → scan ready | ≤ 2s | TBD | ≤ 2s |
| PDF export | ≤ 3s | TBD | ≤ 3s |
| Peak memory (OCR) | ≤ 150MB | TBD | ≤ 150MB |

Record actual values during Gate 3 testing. If any metric exceeds target,
fix before TestFlight — not after.
