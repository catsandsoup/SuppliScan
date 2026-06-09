# OCR Nutrition Recognition Program

## Objective

SuppliScan should treat OCR as an evidence pipeline, not as a single text string.
The app needs to preserve what Vision saw, derive parser-safe text, validate the
nutrition meaning, and surface uncertainty before clinical calculations.

## Current Findings

The debug corpus shows these failure classes:

- Low-confidence hallucinated text entering parsing.
- Marketing and directions panels being treated as ingredient panels.
- Multi-column rows being collapsed into one sentence.
- Amount-only columns separating from ingredient names.
- Full label panels being read as one long paragraph.
- Full-word units such as `micrograms` falling through unit parsing.
- Botanical/probiotic/nutrient rows requiring different parse paths.
- True total lines and OCR-corrupted total lines needing different treatment.
- Debug bundles mixing raw Vision observations with merged parser rows.

## Apple Vision Direction

Keep the custom AVFoundation camera. Do not replace the scan experience with
`VNDocumentCameraViewController` as the default flow.

Use Vision as interchangeable OCR backends:

- `VNRecognizeTextRequest` for current still-image OCR.
- Vision `customWords` from the bundled nutrition lexicon.
- Language correction enabled for final still-image OCR, backed by the nutrition
  vocabulary. Disable only for code-like fields after corpus evidence.
- Accurate recognition for final capture.
- Pinned text-recognition request revision. Change only after regression-corpus
  comparison.
- Tuned `minimumTextHeight`, with test evidence before changing it.
- iOS 26 `RecognizeDocumentsRequest` as an experimental backend for table and
  paragraph structure, not as a UI replacement.
- Lens-smudge and image-quality checks as a later capture-quality gate.
- Region-of-interest scanning for live guidance or user-selected label panels.
  This should reduce marketing-text noise and OCR workload without replacing the
  camera.

## Data Architecture

Add a first-class bundled nutrition lexicon separate from NRV, form quality, and
aliases.

The lexicon should provide:

- Canonical nutrient or ingredient name.
- Category: vitamin, mineral, amino acid, botanical, probiotic, fatty acid, other.
- OCR words and phrases for `customWords`.
- Aliases and label spellings for parser canonicalization.
- Form terms for form extraction and form-quality matching.
- Common OCR confusions from real debug bundles.
- Source notes and version.

Do not put clinical dose limits in the OCR lexicon. Dose reference data belongs
in NRV/UL files with explicit official sources.

## Compendium Decision

SuppliScan needs a supplement terminology compendium, but OCR should consume
only the recognition-safe slice of it.

Use one researched compendium model with separate fields:

- OCR vocabulary: names, spellings, forms, label phrases, OCR confusions, unit
  spellings.
- Parser aliases: variant-to-canonical mappings.
- Form extraction: commercially sold forms such as citrate, glycinate,
  methylfolate, cyanocobalamin, MK-7, and selenomethionine.
- Unit grammar: `mg`, `mcg`, `ug`, `µg`, `g`, `IU`, `%DV`, `%RDI`, CFU, billion
  CFU, DFE, RAE, alpha-tocopherol equivalents, and elemental mineral phrasing.
- Clinical references: RDI/AI/EAR/UL, demographic scope, source, edition, and
  nutrient-specific conversion rules.

Only the first slice should feed Vision `customWords`. The parser may use the
alias and form fields. Calculation and clinical review must use the sourced
reference files, not OCR vocabulary.

Authoritative source priority:

1. Australian NRV and TGA terminology for Australian app behavior.
2. NIH ODS fact sheets for vitamin/mineral names and supplement forms.
3. FDA/EU label rules for international label vocabulary and units.
4. Real debug bundles for OCR confusions and product-specific phrases.
5. Commercial labels only as discovery evidence, never as clinical authority.

## Pipeline Design

1. Capture
   - Keep custom camera.
   - Add capture-quality gates: blur, smudge, glare, crop/label coverage.
   - Store debug image metadata, not health/user context.

2. OCR
   - Run OCR off main actor.
   - Preserve all observations and confidence.
   - Produce parser-safe rows by confidence, geometry, and label signals.
   - Use lexicon vocabulary for custom words.

3. Segmentation
   - Prefer panel-like regions and rows with amount/unit signals.
   - Split visual rows with multiple name/amount pairs.
   - Keep continuation rows attached to their parent ingredient.
   - Keep raw rejected observations in DEBUG bundles.

4. Parsing
   - Deterministic only.
   - Resolve names through lexicon and aliases.
   - Return unresolved entries instead of guessing.
   - Preserve total rows, flagged, for ReportService selection.

5. Validation
   - Validate units against nutrient type.
   - Validate dose plausibility as review flags, not silent correction.
   - Validate form terms against curated form data.
   - Record source/provenance for NRV, UL, form quality, and future dose rules.

6. Evaluation
   - Promote debug bundles into fixtures.
   - Store expected OCR rows and expected parsed entries.
   - Track precision, recall, unresolved rate, false nutrient rate, and total-line
     handling.

## Milestones

### M1: Evidence-Safe OCR

- Parser-safe text separate from all recognized text.
- Low-confidence rejection.
- Supplement-label signal gate.
- Debug quality report.
- Regression tests for known failure classes.

### M2: Lexicon Foundation

- Bundled `nutrition_lexicon.json`.
- `NutritionLexicon` loader.
- Feed lexicon terms to Vision `customWords`.
- Merge lexicon aliases into `ParserService.makeDefault()`.

### M3: Corpus Harness

- Convert debug bundles into test fixtures.
- Add expected outputs per product/panel.
- Add a command/test that reports OCR/parser quality metrics.
- Compare OCR options by metrics before changing request revision,
  `minimumTextHeight`, language correction, or backend.

### M4: Document/Table Backend Experiment

- Add an OCR backend protocol implementation using `RecognizeDocumentsRequest`
  when available.
- Compare output against `VNRecognizeTextRequest` on the same corpus.
- Use it only if tests prove better row/table reconstruction.
- Extract table rows, cells, paragraphs, and measurement/unit detections as
  evidence; do not feed unvalidated document transcripts straight into parsing.

### M5: Clinical Validation Expansion

- Add dose plausibility data with source fields.
- Add nutrient-specific unit validity.
- Add provenance display and persistence for reference data used in a report.

## Implemented Semantic Compendium Slice

`nutrition_lexicon.json` now carries the first structured compendium fields:

- `accepted_units`: label units expected for the canonical nutrient.
- `suspicious_units`: units that should be surfaced for review instead of
  silently accepted.
- `forms`: variants that should be preserved as nutrient forms when the label
  names the form directly, such as `P-5-P` or `cholecalciferol`.

Parser behavior:

- A form alias can canonicalize to the parent nutrient while preserving the form.
- A parsed nutrient whose unit conflicts with the compendium receives a review
  flag.
- The flag is advisory. The parser does not auto-correct `mg` to `mcg`, because
  clinical correction without user confirmation is unsafe.

This is the correct first compendium use case. Vision OCR still receives only
label-safe custom words. Serum units, lab markers, prescription-only metabolites,
and broad clinical prose should stay out of `customWords` unless real label
fixtures prove they improve recognition.

## Apple Research Notes

Apple's current Vision guidance supports this architecture:

- Vision OCR runs on-device, which fits SuppliScan's privacy and clinical-data
  boundary.
- `VNRecognizeTextRequest` / `RecognizeTextRequest` remains the right current
  still-image text extraction path.
- For final captured images, use accurate recognition. Fast recognition is for
  live camera guidance where frame rate matters.
- Region of interest is an Apple-recommended way to crop Vision processing to
  the relevant subject, reducing surrounding noise and improving performance.
- Language correction can help normal words but can harm serial/code-like
  strings. Supplement labels are mostly natural language plus units, so it is
  enabled here and guarded by the nutrition lexicon and parser validation.
- `RecognizeDocumentsRequest` is valuable for structured tables, paragraphs, and
  measurement/unit detection, but it should be evaluated as an OCR backend
  experiment. It should not take over the camera UI.
- `DetectLensSmudgeRequest` and `CalculateImageAestheticScoresRequest` can help
  create an image-quality gate, but low smudge confidence alone does not prove a
  label photo is readable.
- Apple's modern Vision APIs use async/await and fit Swift 6 concurrency. Moving
  from the `VN` API to the new request types is a compatibility project, not an
  emergency rewrite.

## Training Answer

Apple Vision text recognition is not trained in-app with a custom nutrition
model. The app can improve recognition by supplying a large domain vocabulary,
improving image quality, choosing better Vision requests, and correcting OCR
with deterministic, auditable post-processing.

If custom ML is later justified, it should be a separate Core ML model for label
panel detection or OCR correction, trained on consented/generated label images
and evaluated against the fixture corpus. It should not replace deterministic
clinical calculation.
