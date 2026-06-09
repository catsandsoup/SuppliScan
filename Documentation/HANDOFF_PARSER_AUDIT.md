# Parser Audit Handoff — Next Session Pick-Up
# Created: 2026-06-09
# Context: Multi-session OCR audit of all training data supplements

---

## What Was Accomplished

Two sessions of OCR/parser work are complete. Build is green. See `V1_COMPLETION_PLAN.md`
§ "2026-06-09" for the full log. Summary:

1. **ReviewView auto-skip bug** — fixed. Users now see Review screen before analysis runs.
2. **Probiotic 96B label** — "EACH VEGETARIAN CAPSULE CONTAINS: 96 BILLION CFU" was being
   parsed as a probiotic entry. Fixed by making section headers always-skip.
3. **Abbreviated genera** — "L. rhamnosus 18.0 Billion" now parsed. New `abbreviatedProbioticName`.
4. **CFU without suffix** — "18.0 Billion" (no "CFU") now matched. cfuMatch fallback added.
5. **Selenium "(as Selenomethionine)"** — was failing isEquivalentContinuation regex. Fixed
   `as\s+\w` → `as\s+\w+` so word boundary lands at end of full form name.
6. **NAC "provides" pattern** — Pattern 5 added for "1 level scoop provides 1g N-Acetyl-Cysteine".
7. **Herbal parsing** — `herbalEntry(from:)` added. Hair Volume herbs (Malus domestica,
   Panicum miliaceum, Equisetum arvense) now parse as `LabelEntry.herbal` instead of junk nutrients.
8. **Aliases expanded** — B2 active forms, B9 Levomefolate/5-MTHF variants, Copper cupric sulfate.
9. **Skip noise** — standardisation notes, EU/AU address fragments, allergen disclaimers all skip.

---

## What Needs To Happen Next

### Priority 1 — Live Simulator Testing (Blocked on Simulator Access)

The audit was done as logic analysis against training JSON files. **None of the fixes
have been tested by actually scanning a supplement in the simulator.**

Steps to do this:
```bash
# Boot iPhone 17 Pro simulator
xcrun simctl boot "iPhone 17 Pro"
open -a Simulator

# Build and install
xcodebuild -scheme SuppliScan -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build

# The training images are already in the simulator photo library from the previous session.
# If not, add them:
xcrun simctl addmedia "iPhone 17 Pro" /Users/monty/Documents/GitHub/SuppliScan/TrainingData/IMG_1131.jpeg
xcrun simctl addmedia "iPhone 17 Pro" /Users/monty/Documents/GitHub/SuppliScan/TrainingData/IMG_1136.jpeg
# ... etc for all images
```

For each supplement, scan it from the photo library and screenshot the Review screen and
Analysis screen. Compare against expected entries in the JSON files in `TrainingData/`.

### Priority 2 — Missing Training JSON Files

8 of 14 labels have no JSON reference (expected output not documented):
- `IMG_1133` — Saw Palmetto 3500 (herbal, soft concentrate)
- `IMG_1134` — Vitamin C 1g + Zinc + Bioflavonoids
- `IMG_1135` — Chlorella tablets (FSANZ food panel)
- `IMG_1137` — Astaxanthin 12mg (herbal extract equivalent)
- `IMG_1138` — Omega-3 Fish Oil (EPA/DHA sub-entries)
- `IMG_1139` — Vitamin D3 1000IU (IU→mcg conversion)
- `IMG_1140` — Quercetin Complex (variable dosing)
- `IMG_1142` — Probiotic 60B CFU + Herbal

For each, scan the image in the simulator, note what the app actually produces,
compare against expected, and fix any discrepancies.

Also 5 "User attachment" images exist:
- `User attachment.png`, `User attachment (1).png` through `(5).png`
These are from the user's real supplements. Test these too.

### Priority 3 — Herbal Standardisation Merge

Currently "standardised to contain silicon 14mg" on a separate OCR line is skipped.
The silicon content from Equisetum arvense (Hair Volume label) will not appear anywhere.

Fix: extend `mergedContinuationLines` to merge "standardised to contain X Ymg" lines
into the preceding herbal line, and parse the standardisation from the merged line.

The `HerbalEntry` already has a `standardisation: HerbalStandardisation?` field ready.
The parser's `herbalEntry` function already parses standardisation — it just needs the
data to be on the same line.

Implementation approach:
```swift
// In mergedContinuationLines, after the existing isPureContinuationLine check,
// add: if the current line was classified as herbal AND the next line starts with
// "standardised to" or "calc. as", merge them.
```

### Priority 4 — Phase 1 Reference Data (nrv_au.json)

This is the single largest functional gap. `ReportService` calls `ReferenceDataService`
which needs `nrv_au.json` to return any RDI/UL values. Without it, every report shows
"No NRV data" for everything.

The data is ready in `Documentation/HANDOFF_REFERENCE_DATA.md`. That document has all
values transcribed from the NHMRC 2006 PDF. A fresh window can write `nrv_au.json`
from that document without re-reading the PDF.

### Priority 5 — Parser Tests Against Real Vision Output

The existing parser tests use hand-crafted strings. Real Vision output for two-column
labels returns separate observations — confirmed by real-device scanning. The merging
logic was added to handle this, but it has never been tested with *actual* Vision output.

Add a snapshot test:
1. Capture `VNRecognizedTextObservation` output from 3-4 real labels
2. Save the raw text as fixtures in `SuppliScanTests/Fixtures/`
3. Write `ParserServiceTests` that parse each fixture and compare to expected entries

---

## Known Remaining Parser Gaps

| Issue | Impact | Fix needed |
|---|---|---|
| Astaxanthin: "equiv. to X astaxanthin" from Haematococcus pluvialis | Herbal entry will be created but the active compound astaxanthin may not be captured | Add astaxanthin as a standalone HerbalEntry or nutrient case |
| Omega-3 sub-entries: "EPA 180mg" inside "(EPA 180mg DHA 120mg)" | Sub-entries not yet parsed — the outer "Fish Oil 1000mg" is captured, sub-entries dropped | Not critical for v1 if Fish Oil total dose is captured |
| Chlorella FSANZ food panel: per-100g column | Food panel format completely different from TGA supplement format | May need separate food panel parser branch |
| Vitamin D3 1000IU → 25mcg | IU conversion exists in UnitConversionService but needs integration test | Write test from training JSON |
| Herbal standardisation on separate line | Silicon from Equisetum lost | See Priority 3 above |
| "Quatrefolic" trademark stripping | Levomefolate glucosamine (Quatrefolic) — trademark in parens should be stripped | extractNameAndForm already handles parens; test needed |

---

## Files Changed This Session

```
SuppliScan/SuppliScan/Services/ParserService.swift
  - isEquivalentContinuation: as\s+\w → as\s+\w+ (word boundary fix)
  - herbalEntry(from:) added (Latin binomial + extract keyword detection)
  - Parse loop: probiotic → herbal → nutrient → unresolved
  - shouldSkip: standardised/standardized to, calc. as, calculated as
  - debugDecisions: herbal case added

SuppliScan/SuppliScan/Resources/ReferenceData/aliases.json
  - Vitamin B2: active phosphorylated form names added
  - Vitamin B6: pyridoxal 5-phosphate monohydrate added
  - Vitamin B9: Levomefolate/5-MTHF variants added
  - Copper: Cupric sulfate variants added

Documentation/PARSER_SPEC.md
  - Herbal entry rules (H1, H2, H3) added
  - Two-column OCR merging rules (M1, M2, M3) documented
  - Section header skip rules documented

Documentation/V1_COMPLETION_PLAN.md
  - 2026-06-09 session log added

Documentation/HANDOFF_PARSER_AUDIT.md (this file)
  - Created
```

Previous session also changed (committed separately):
```
SuppliScan/SuppliScan/Features/Review/ReviewView.swift
  - Removed requestAnalysisIfNeeded() from onAppear

SuppliScan/SuppliScan/Features/Review/ReviewViewModel.swift
  - Removed requestAnalysisIfNeeded() and hasRequestedInitialAnalysis

ParserService.swift (many changes from Session A — see git log)
```

---

## Test Command

```bash
xcodebuild -scheme SuppliScan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build 2>&1 | grep -E "error:|BUILD"
```

Expected: `** BUILD SUCCEEDED **`

---

## Highest-Risk Item

The `herbalEntry` function uses a simple pattern: Latin binomial + herbal keyword.
This **will generate false positives** on any nutrient compound line that:
1. Starts with a two-word capitalised name (first word ≥ 3 chars, second word lowercase)
2. AND contains "extract" or "concentrate" anywhere in the line

Example false positive risk: "Calcium citrate extract 500mg" — but "Calcium" is in
`knownNutrientPrefixes` so this is guarded. The guard list covers common nutrients
but may need expanding as new labels are tested.

If false positives appear in simulator testing, expand `knownNutrientPrefixes` in
`herbalEntry`. Do NOT relax the extract-keyword requirement — that is the primary guard.
