# NutriScan — Product Vision & Feature Roadmap
# Everything the app could be, versioned and prioritised

---

## Vision Statement

NutriScan is the clinical-grade supplement intelligence tool that practitioners
trust and educated consumers actually understand. It catches what no human catches
— the selenium that appears in two products simultaneously, the magnesium oxide
that looks impressive on the label and absorbs poorly in the body, the Vitamin D
dose that sounds large and isn't.

The long-term goal: App of the Year calibre. The path there is shipping a focused,
excellent v1 and earning the right to expand.

---

## User Jobs-to-Be-Done

Understanding these shapes every design decision. The primary user is clinical,
but four distinct jobs exist across the user base.

### Job 1: The Stack Builder (Primary — practitioner / educated consumer)
"I want to understand exactly what's in this product and whether it's any good."
Already owns supplements. Wants clinical detail fast.
Success: Opens a scan, reads the report, makes a clinical decision. Under 90 seconds.
This is the v1 primary job. Everything else is secondary to doing this perfectly.

### Job 2: The Safety-Checker (Primary — practitioner / carer)
"I need to know if this stack is safe for my patient / myself."
Multiple products. Wants cumulative dose vs UL, and interaction flags.
Success: Exports a report and shares it with a GP or specialist.
This is partially v1 (single product UL), fully v2 (multi-product stack).

### Job 3: The Value Seeker (Secondary — consumer at point of purchase)
"Should I buy this $60 product or the $15 one next to it?"
Standing in a chemist. Wants a verdict in seconds, not a clinical table.
Success: Scans both, gets a meaningful comparison, makes a decision at the shelf.
Speed is the primary NFR for this job. Dual-layer UI (summary + detail) serves this.
This job is served by v1 architecture; the comparison feature is v2.

### Job 4: The Overwhelmed Beginner (Tertiary — consumer)
"I've been told to take this. Is it safe? Am I taking the right amount?"
No nutrition knowledge. Needs plain English and a clear verdict.
Success: Gets a reassuring or cautionary answer they can act on.
This job is served by the dual-layer report UI in v1. No dumbing down — just hierarchy.

---

## Full Feature Set — All Versions

### ── V1: CLINICAL CORE ──────────────────────────────────────────

#### F1: Label Scanning ✓ IN SPEC
OCR via VisionKit. Mixed-content labels (nutrients + herbals + probiotics).
IU conversion. Serving size extraction. Low-confidence guidance.

#### F2: Serving Size Selection ✓ IN SPEC
Per-serving vs per-container. Variable dose selector. Multiplier applied once.

#### F3: Reference Standard Toggle ✓ IN SPEC
AU / US / EU. Recalculates without re-scan.

#### F4: RDI% / UL% Calculation ✓ IN SPEC
Deterministic. On-device. Demographic-adjusted. EAR/AI fallback.

#### F5: Form Quality Assessment ✓ IN SPEC
4-tier curated system. AI gap-fill with visual distinction.

#### F6: Clinical Report ✓ IN SPEC
Full table. Flags. Expandable rows. PDF export. Disclaimer.

#### F6a: Report Summary Card ← NEW FOR V1
Single scannable card at the top of every report before the detail table.
Clinical language, not traffic lights. Serves both Job 1 and Job 4.

Content:
- Overall form quality: "High / Mixed / Poor" based on worst tier in product
- Dose adequacy: "Adequate / Sub-therapeutic / Above UL" based on primary nutrients
- UL status: "Within range / At limit / Exceeds limit"
- One-line clinical note: the single most important thing about this product

Example:
┌─────────────────────────────────────────────────┐
│ SUMMARY                                         │
│ Form quality: High  Dose: 95% RDI  UL: Safe    │
│ Magnesium glycinate — well-evidenced form at    │
│ a clinically meaningful dose.                   │
└─────────────────────────────────────────────────┘

This is not simplification. It is information hierarchy.
The full table is still immediately below it.

#### F7: Scan History ✓ IN SPEC
Local save, reopen, delete. No cloud.

#### F8: Point-of-Purchase Speed ← NEW NFR FOR V1
The Value Seeker scans two products at the chemist's shelf.
OCR → summary card visible: ≤ 8 seconds from camera open.
This is an NFR, not a feature — it constrains how OCR and report generation are built.

---

### ── V2: STACK INTELLIGENCE ─────────────────────────────────────

#### F9: Multi-Product Stack Analysis
The selenium example: 150mcg (product A) + 50mcg (product B) = 200mcg vs 150mcg UL.
Requires: a Stack data model, multiple scans grouped as a set, cumulative calculation
engine, and a Stack Report that overlays individual product reports.

Data model additions needed:
- Stack entity (SwiftData @Model)
- Stack contains [ScanRecord] references
- CumulativeNutrientTotal: per-nutrient sum across stack
- StackFlags: UL violations at stack level, not product level

UI additions:
- StackView: shows all scans in the current stack
- StackReport: cumulative table with per-product breakdown
- "Add to Stack" action on individual reports

Testing: The selenium corpus fixtures (selenium_150mcg_au.json +
st_marys_thistle_taurine_selenium_au.json) provide the exact test case.
Expected: stack selenium total = 200mcg, UL = 150mcg (AU adult),
flag as UL_exceeded at stack level.

#### F10: Drug-Supplement Interaction Checking
Requires: a curated interaction database (drug × nutrient pairs with severity).
Scope: common interactions only (warfarin/Vit K, statins/CoQ10, thyroid/calcium, etc.)
The corpus already has 8 drug interaction flags ready for this database.

This is genuinely complex. It requires:
- A clinical review process for the interaction database
- Legal review of how interactions are communicated
- TGA/regulatory review of whether this constitutes medical advice

Do not build this without legal and clinical input on the language.

#### F11: Competing Absorption Warnings
Calcium + magnesium at high doses compete. Iron + calcium compete.
Zinc + copper compete (long-term high zinc depletes copper).
Requires: interaction rules between nutrients, not between drugs and nutrients.
Simpler than F10 but needs the same data model foundation as F9.

#### F12: Synergistic Nutrient Flags
D3 + K2 (bone mineralisation). Iron + Vitamin C (absorption enhancement).
B6 + B12 + folate (methylation cycle). Positive flags, not warnings.
Lower regulatory risk than F10/F11.

#### F13: Barcode Scan with Product Database
Currently blocked by ARTG gap (no public AU barcode → ingredients API).
Build path: crowdsource from scans over time, or partner with manufacturers.
When implemented: barcode is a shortcut past OCR for known products, not a replacement.

#### F14: Practitioner Notes
Free-text notes field per report. Exportable with report PDF.
Simple feature, deferred only because v1 focus is core analysis.

#### F15: User Demographic Profiles
Save and name demographic presets ("My patients 50–70F", "Myself").
Eliminates repetitive demographic selection on every scan.

#### F16: Comparison Mode
Side-by-side comparison of two scans: same product different brands, or same
nutrient different products. The Value Seeker's primary use case made explicit.

---

### ── V3: APPLE PLATFORM INTEGRATION ─────────────────────────────

This version is about earning App Store featuring consideration.
None of this belongs in v1 or v2. Build the core first.

#### F17: HealthKit Sync
Write nutrient data to Apple Health after each scan.
Nutrients: Vitamin C, D, B12, Magnesium, Zinc, Iron, Omega-3 (EPA/DHA).
Requires: HealthKit entitlement, privacy strings, user permission flow.
HKQuantityType mapping for each nutrient.
Write only — never read health data in v1 HealthKit integration.

Clinical note: HealthKit writes represent label amounts, not confirmed intake.
This distinction must be clear in the UI and in the HealthKit metadata.

Testing: After scan, open Apple Health → Nutrients. Verify correct values appear
with NutriScan as the source. Verify no data written without explicit user approval.

#### F18: WidgetKit — Home Screen Widget
"3 of 7 supplements taken today" style.
Requires: a logging / tracking model (did the user take this today?).
Note: NutriScan v1 is an analysis tool, not a tracking tool. This widget implies
adding a supplement tracking layer that doesn't currently exist.
Do not add tracking in v3 without first deciding if NutriScan stays analysis-only
or expands to tracking. This is a product strategy decision, not an engineering one.

#### F19: Siri Shortcuts
"Log my morning supplements" — requires the tracking layer from F18.
"Scan a supplement" — opens app to ScanView directly.
The second shortcut is v3-viable without tracking. The first requires F18 first.

#### F20: Apple Watch Companion
Tap to log from wrist — requires tracking layer.
View today's stack from wrist — requires tracking layer.
Depends entirely on whether tracking is added in F18.

#### F21: Live Activities / Dynamic Island
Reminder that a supplement dose is due.
Requires tracking layer and notification infrastructure.

#### F22: Spotlight Search
Index scan history in Spotlight. "Magnesium" → shows all scans containing magnesium.
This is achievable without the tracking layer.
CoreSpotlight integration on ScanRecord save.

---

### ── FUTURE / STRETCH ────────────────────────────────────────────

#### F23: Practitioner Dashboard (Web or Mac)
Aggregate reports across multiple patients. Not a mobile feature.
Would require a backend — fundamentally changes the privacy model.
Only relevant if NutriScan grows into a practice management tool.

#### F24: Supplement Database / Product Registry
A crowdsourced or licensed database of AU supplement products indexed by barcode.
Enables F13 at scale. Requires significant ongoing curation.

#### F25: AI-Powered Recommendation Engine
"Based on this product's gaps, consider..." — active recommendations.
Currently blocked by regulatory boundary (therapeutic claims).
Requires TGA classification review before building.

---

## App of the Year Requirements (Reference)

Apple's design award pillars with NutriScan's current status:

| Pillar | Requirement | v1 Status | When Addressed |
|---|---|---|---|
| Delight | Hero feature that reviewers haven't seen done this well | ✓ Mixed-content OCR + clinical analysis | v1 |
| Innovation | Genuinely new capability | ✓ Cross-product selenium catch concept | v2 (stack analysis) |
| Inclusivity | Full VoiceOver, Dynamic Type, high contrast | Specified in NFR | v1 (must verify) |
| Craft | Physics-based animations, haptics, design consistency | Not yet specified | v1 polish pass |
| Deep Apple Integration | HealthKit, Widget, Watch, Siri | None | v3 |
| Impact | Measurable user benefit, exportable reports | ✓ PDF export, clinical report | v1 |
| Ratings | 4.7+ with substantial reviews | Requires users | Post-launch |

The honest path to featuring: ship an exceptional v1, gather real users,
iterate to v2 (stack analysis is the story Apple loves), then invest in v3
platform integration as the bid for featuring.

Trying to build all of this in v1 produces a mediocre version of everything
instead of an excellent version of the core.
