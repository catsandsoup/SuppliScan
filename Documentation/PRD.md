# NutriScan — Product Requirements Document
# v2 — Updated for mixed-content labels, serving size, extended scope

## Problem
Practitioners assessing supplement quality currently cross-reference labels manually
against NRV tables and form quality literature. This takes significant time per product
and introduces transcription error. No existing tool combines OCR, reference standards,
form quality, and serving size-adjusted calculations in a single clinical workflow.

## Target Users

### Primary: Practitioners and Clinicians
Nutritionists, naturopaths, integrative GPs, dietitians.
Users understand nutrient terminology. Full data always shown. Nothing simplified.

### Secondary: Educated Consumers
Health-conscious individuals with working nutrition knowledge.
Needs a clear report they can act on without a practitioner present.


---

## Jobs-to-Be-Done

Four distinct user jobs exist across the user base. v1 is built for Job 1 and Job 2.
Job 3 is served by the dual-layer report UI. Job 4 is served by the report summary card.

**Job 1 — The Stack Builder (primary)**
"I want to understand exactly what's in this product and whether it's any good."
Measures success by: opening a scan, reading the report, making a clinical decision.
Speed matters. Clinical detail matters. No hand-holding needed.

**Job 2 — The Safety-Checker (primary)**
"I need to know if this stack is safe for my patient / myself."
Measures success by: an exportable report they can share with a GP or specialist.
Single-product UL analysis is v1. Multi-product stack is v2.

**Job 3 — The Value Seeker (secondary)**
"Should I buy this $60 product or the $15 one next to it?"
Measures success by: a useful verdict in under 10 seconds, at point of purchase.
Speed is the primary constraint. The summary card is what serves this job.

**Job 4 — The Overwhelmed Beginner (tertiary)**
"I've been told to take this. Is it safe? Am I taking the right amount?"
Measures success by: a plain-English answer they can act on.
Served by the summary card and recommendations section. No separate UI mode.

---

## Core User Flow

1. User opens app → taps Scan
2. Camera activates → user frames supplement label
3. OCR extracts label entries (nutrients, herbals, probiotics, unresolved lines)
4. User reviews extracted data, corrects errors, sets serving size
5. User selects reference standard (AU / US / EU) and demographic
6. App generates clinical report
7. User can save, export as PDF, or share report

---

## Features — v1

### F1: Label Scanning
- VisionKit OCR scans supplement label
- Classifies extracted lines into: nutrient entries, herbal entries,
  probiotic entries, unresolved lines
- Extracts per-entry: name, form, amount, unit
- IU units converted to mcg/mg during extraction (unit-specific conversion table)
- User can manually correct any extracted field in ReviewView
- Supports portrait and landscape label orientations
- Image quality guidance: viewfinder overlay, low-confidence warning with
  "Try tilting label to reduce glare" instruction

### F2: Serving Size Selection
- Parser extracts stated serving size from label (e.g. "per capsule",
  "per 2 tablets", "per 5g teaspoon")
- ReviewView shows serving size selector before analysis
- For variable-dosing products (e.g. 1–3 tablets), selector shows the full range
- User selects their actual serving quantity
- All amounts in the report reflect the selected serving
- Report clearly states serving size used
- Default: the label's stated serving size

### F3: Reference Standard Selection
- Toggle between AU (NHMRC NRVs), US (NIH/FDA DRIs), EU (EFSA NRVs)
- Default is AU
- Selection persists per scan session
- User can switch standard post-scan and report recalculates without re-scanning

### F4: RDI% and UL% Calculation (nutrients only)
- Per nutrient: calculates % of RDI (or EAR/AI where RDI not established)
- Per nutrient: calculates % of UL where UL exists
- Where no UL established: report states "No UL established"
- Where no RDI/EAR/AI: report states "No reference data"
- Calculations are deterministic, on-device, never AI-generated
- All calculations use effective dose (amount × serving multiplier)
- Demographic selector: age band + sex (default adult male 19–50)

### F5: Nutrient Form Quality Assessment (nutrients and herbals)
- Each nutrient form assessed against curated quality tiers:
  - Tier 1: High bioavailability, well-evidenced
  - Tier 2: Moderate bioavailability, commonly used
  - Tier 3: Low bioavailability, cheap filler forms
  - Tier 4: Synthetic or potentially problematic
- Where form absent from curated DB: AI inference fills gap with confidence flag
- AI-inferred tier visually distinguished from curated tier throughout report
- Herbal extracts: form quality assessed on extract type and standardisation level

### F6: Clinical Report
Full report per product scan:


**Report Summary Card** (first element, above all sections):
A single scannable card providing an immediate clinical assessment.
Uses clinical language — not traffic lights or scores.
Content:
- Overall form quality: High / Mixed / Poor (based on worst tier present)
- Dose adequacy: Adequate / Sub-therapeutic / Above UL
- UL status: Within range / At limit / Exceeds limit
- One-line clinical note: the single most important fact about this product
Example: "Form quality: High · Dose: 95% RDI · UL: Within range
  Magnesium glycinate at a clinically meaningful dose."
This is not simplification — it is information hierarchy.
The full clinical table is immediately below it.

**Header section:**
- Product name, scan date, reference standard, demographic, serving size used

**Nutrient table** (for each NutrientEntry):
- Nutrient name | Effective dose | Unit | RDI% | UL% | Form | Tier | Notes
- Rows grouped by: nutrients with NRV data, then nutrients without NRV data
- Expandable rows: tap to see form rationale and reference citations

**Herbal section** (for each HerbalEntry, if present):
- Common name | Latin name | Extract type | Amount | Dry equivalent | Standardisation
- Form quality assessment (extract type and standardisation tier)

**Probiotic section** (for each ProbioticEntry, if present):
- Strain table: genus/species | strain code | CFU
- Total CFU shown prominently
- Note: "No NRV data available for probiotic strains"

**Unresolved entries** (for each RawLine not resolved in ReviewView):
- Listed with original OCR text
- Note: "Could not be analysed — manual review required"

**Flag summary** (only shown when flags exist):
- Nutrients above UL (red banner)
- Nutrients at UL (within 10% — amber banner)
- Low bioavailability forms (orange banner)
- AI-inferred form assessments (purple banner — review recommended)
- Serving size adjustment applied (blue banner, if multiplier ≠ 1.0)

**Recommendations section:**
- Plain clinical language, descriptive not prescriptive
- Grouped by: dose concerns, form concerns, missing data

**Disclaimer:**
- Always present, always last
- "This report is for practitioner reference only. It does not constitute
  medical advice or therapeutic recommendation. Always exercise independent
  clinical judgment."

Report is exportable as PDF and saveable to local history.

### F7: Scan History
- All scans saved locally with timestamp, product name, standard used, demographic
- User can re-open any prior report
- User can delete individual scans
- No cloud sync in v1

---

## Edge Case Handling

### Mixed-content labels (nutrients + herbals + probiotics)
Supported. Each entry type rendered in its appropriate report section.
A single scan can contain all three types simultaneously (e.g. greens powder).

### Probiotic-only labels
Supported. Probiotic section shown. Nutrient and herbal sections hidden.
RDI% analysis not attempted.

### Herbal-only labels (no nutritional panel)
Supported. Herbal section shown. Nutrient section hidden.
No RDI% calculation. Form quality assessed on extract type.

### Nutrients with no NRV data (e.g. quercetin, CoQ10, taurine)
Supported. Dose shown. "No reference data" in RDI% column.
Form quality still assessed if form is extractable.

### Total/summary lines (e.g. "TOTAL ASCORBIC ACID 1g")
Total line used for RDI calculation. Individual sub-entries shown in detail
but flagged as not used for calculation. User must confirm in ReviewView.

### Elemental vs compound amounts
Elemental amount always used for calculation.
Compound amount shown in detail view.
Both shown when both are present on the label.

---

## What This App Does NOT Do

- Does not diagnose any condition
- Does not recommend any supplement for any condition
- Does not replace clinical judgement
- Does not provide personalised health advice
- Does not connect to the internet for core functionality
- Does not sync data to cloud in v1
- Does not look up products by barcode (v2)
- Does not check for drug-supplement interactions (v2)
- Does not analyse multiple products simultaneously (v2)

---

## Deferred to v2
- Multi-product stack analysis — cumulative UL tracking across products
  (the selenium 150mcg + 50mcg = 200mcg catch — requires Stack data model)
- Competing absorption warnings (calcium/magnesium, iron/calcium, zinc/copper)
- Synergistic nutrient flags (D3/K2, iron/Vitamin C, B6/B12/folate)
- Drug-supplement interaction checking (requires clinical DB + legal review)
- Product comparison mode (side-by-side two scans)
- User demographic profiles (save presets)
- Barcode scan + product database (blocked by ARTG gap — no public AU API)
- Practitioner notes field per report
- iCloud sync

## Deferred to v3
- HealthKit nutrient write (post-scan)
- WidgetKit home/lock screen widget (requires tracking layer decision first)
- Siri Shortcuts
- Apple Watch companion (requires tracking layer)
- Live Activities / Dynamic Island (requires tracking layer)
- Spotlight search indexing of scan history

## Deferred — Requires Strategic Decision First
- Supplement tracking / logging (is NutriScan an analysis tool or a tracking tool?)
  This decision gates: Widget, Watch, Siri, Live Activities, HealthKit logging
  Without resolving it, building any of those features is premature.

## Not Planned (Regulatory Boundary)
- AI-powered supplement recommendations (therapeutic claims — TGA SaMD review needed)
- Diagnostic functionality of any kind
- Integration with patient records systems
