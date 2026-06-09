# NutriScan — Parser Specification
# ParserService: Raw OCR text → [LabelEntry]
# Skills for this document: `swift-api-design-guidelines-skill`, `ios-code-audit`, `swift-testing-pro`
# Invoke `ios-code-audit` after writing ParserService or UnitConversionService.
# Invoke `swift-testing-pro` when writing parser tests — this is the highest-risk service.

## Overview

ParserService receives raw text strings from OCRService and produces structured
NutrientEntry values. This is the highest-risk service for silent data quality
failures — a wrong parse produces a wrong RDI%, with no error and no warning.

ParserService is deterministic and synchronous. No AI involvement. No network calls.
If a line cannot be parsed with confidence, it is returned as an unresolved entry
for user review — never silently dropped and never silently guessed.

---

## Label Format Context

Australian supplement labels follow TGA labelling requirements.
US labels follow the FDA Supplement Facts panel format.
EU labels follow Regulation 1169/2011.

All three formats share the same logical structure:
  [Nutrient name] [form qualifier] [amount] [unit]

Variations are in syntax, not in semantics.

---

## Parsing Rules — Nutrient Name Extraction

### Rule P1: Base name before parenthetical
The nutrient name is the text before any parenthetical qualifier.

```
Input:  "Zinc (as zinc citrate) 15mg"
Output: name="Zinc", form="zinc citrate", amount=15, unit=.mg
```

### Rule P2: "as" qualifier pattern
Parenthetical containing "as" → form qualifier.
Strip outer parentheses. Strip leading "as ".

```
Input:  "Magnesium (as magnesium glycinate) 300mg"
Output: name="Magnesium", form="magnesium glycinate", amount=300, unit=.mg

Input:  "Iron (as ferrous bisglycinate) 18mg"
Output: name="Iron", form="ferrous bisglycinate", amount=18, unit=.mg
```

### Rule P3: "from" qualifier pattern
Parenthetical containing "from" → form qualifier, same treatment as "as".

```
Input:  "Calcium (from calcium carbonate) 500mg"
Output: name="Calcium", form="calcium carbonate", amount=500, unit=.mg
```

### Rule P4: Elemental qualifier
"elemental" appearing after amount → strip qualifier, amount is already elemental.

```
Input:  "Magnesium 300mg elemental"
Output: name="Magnesium", form=nil, amount=300, unit=.mg
```

### Rule P5: Colon-separated format (EU common)
Nutrient name followed by colon, then amount+unit.

```
Input:  "Vitamin C: 500mg"
Output: name="Vitamin C", form=nil, amount=500, unit=.mg
```

### Rule P6: Dual-unit lines — take first value
Some labels show both IU and metric: "Vitamin D3 1000IU (25mcg)"
Take the first stated value and unit. Flag for user review if values conflict.

```
Input:  "Vitamin D3 1000IU (25mcg)"
Output: name="Vitamin D3", form=nil, amount=1000, unit=.iu
         review_flag="dual_unit — confirm preference"
```

### Rule P7: Percentage-only lines — skip
Lines containing only "%" (e.g. "%RDI 83%") are not nutrient entries.
Skip silently.

### Rule P8: Header lines — skip
Lines matching known header patterns are skipped:
- "Supplement Facts", "Nutrition Information", "Active Ingredients"
- "Amount per serve", "Amount per serving", "Amount per capsule"
- "Amount per tablet", "% Daily Value", "% RDI", "% NRV"
- Lines containing only numbers (serving size rows)

### Rule P9: Proprietary blend lines — partial parse
Lines containing "Blend", "Complex", "Matrix", "Proprietary" with no individual
amounts → extract blend name as a single entry with amount=nil, flag for user review.

```
Input:  "Antioxidant Complex 200mg (Grape Seed Extract, Green Tea Extract)"
Output: name="Antioxidant Complex", form=nil, amount=200, unit=.mg
         review_flag="blend — individual amounts unknown"
```

### Rule P10: Normalise name capitalisation
Nutrient names are title-cased for display but stored lowercase for matching
against the reference data aliases list.

```
"VITAMIN C" → stored "vitamin c", displayed "Vitamin C"
"vitamin b12" → stored "vitamin b12", displayed "Vitamin B12"
```

---

## Parsing Rules — Amount Extraction

### Rule A1: Amount immediately before unit
The numeric value immediately preceding a unit string is the amount.

### Rule A2: Decimal and comma handling
Accept both "300.5mg" and "300,5mg" (European decimal comma).
Normalise to decimal point before parsing.

### Rule A3: Range amounts — take lower bound
"100-200mg" → amount=100, review_flag="range stated — lower bound used"

### Rule A4: "trace" and "<1" amounts
"trace" → amount=0, review_flag="trace amount"
"<1mg" → amount=0.5, review_flag="sub-1 amount — set to 0.5 for calculation"

### Rule A5: Missing amount
If no numeric amount can be extracted, amount=nil.
Entry is returned with review_flag="amount not found — manual entry required".
Never silently set amount=0 for a missing value.

---

## Parsing Rules — Unit Extraction

### Rule U1: Unit string matching (case-insensitive)

| Label text | Normalised unit |
|---|---|
| mg, MG | .mg |
| mcg, μg, ug, µg, MCG | .mcg |
| g, G | .g |
| IU, iu, I.U. | .iu |
| mg NE, mg RE, mg RAE | .mg (with qualifier flag) |
| mg DFE | .mg (with qualifier flag) |

### Rule U2: Unknown units
If unit string is not in the table above, return unit=.unknown with the raw
unit string preserved. Flag for user review. Never coerce to a known unit.

---

## Unit Conversion Table
# These are the ONLY IU conversions permitted. Do not derive others.
# Source: WHO/pharmacopoeial standards. Hardcoded — not AI-generated.

### Vitamin D (all forms: D2, D3, cholecalciferol, ergocalciferol)
- 1 IU = 0.025 mcg
- 1 mcg = 40 IU
- Conversion applies regardless of D2 vs D3 form

### Vitamin A
- Retinol: 1 IU = 0.3 mcg retinol = 0.3 mcg RAE
- Beta-carotene (from food): 1 IU = 0.6 mcg beta-carotene = 0.05 mcg RAE
- Beta-carotene (supplemental): 1 IU = 0.3 mcg RAE
- WARNING: AU NRVs use mcg RAE. If label states IU, must determine form before
  converting. If form is ambiguous, flag for user review — do not assume.

### Vitamin E
- Natural (d-alpha-tocopherol): 1 IU = 0.67 mg alpha-tocopherol
- Synthetic (dl-alpha-tocopherol): 1 IU = 0.45 mg alpha-tocopherol
- If form cannot be determined from label, use synthetic conversion (conservative).
- Flag when synthetic conversion is assumed.

### Vitamin C, B vitamins, minerals
- No IU form exists for these nutrients.
- If OCR extracts IU for one of these, flag as parse_error="IU not valid for [nutrient]".
- Do not attempt conversion. Return for user review.

### Implementation rule
IU conversion happens in ParserService during unit normalisation, before
CalculationService receives the entry. CalculationService never receives .iu units —
all IU must be converted to mcg or mg before the service boundary.

---

## Ambiguity Resolution Hierarchy

When a line is ambiguous, apply in order:
1. Apply the most specific matching rule
2. If still ambiguous, flag for user review — never guess silently
3. If completely unparseable, return as raw_text entry for manual entry

**The parser must never produce a confident wrong answer.**
A flagged uncertain answer is always preferable to a silent wrong one.

---

## Herbal Entry Parsing

### Rule H1: Latin binomial detection
A line that contains a recognised herbal extract keyword ("extract", "concentrate",
"tincture", "dried herb", "dry herb") AND starts with a Latin binomial (capitalised
genus + lowercase species) is classified as a `HerbalEntry`, not a `NutrientEntry`.

```
Input:  "Silybum marianum (St Mary's Thistle) dry concentrate 4000mg"
Output: HerbalEntry(latinName="Silybum marianum", commonName="St Mary's Thistle",
                    extractType=.dryConcExtract, extractAmount=4000, extractUnit=.mg)
```

Herbal detection runs BEFORE nutrient detection. If the line starts with a capitalised
word that is a known nutrient prefix (Calcium, Magnesium, Zinc, Riboflavin, etc.) it is
NOT treated as herbal, even if it contains the word "extract".

### Rule H2: Dry/fresh equivalent
When a herbal line is followed by an equivalence continuation line (starting with
"equiv.", "equivalent"), the two lines are merged by `mergedContinuationLines`.
The first amount in the merged line becomes `extractAmount`; the amount after the
"equiv." keyword becomes `dryEquivalentAmount`.

```
Input (merged): "Malus domestica fruit dry extract 300mg equiv. to fresh fruit 1500mg"
Output: extractAmount=300mg, dryEquivalentAmount=1500mg
```

### Rule H3: Standardisation lines are skipped
Lines beginning with "standardised to", "standardized to", "calc. as", "calculated as"
are skipped by `shouldSkip`. They are not passed to herbal or nutrient parsing.
Standardisation data is captured by the herbal entry when it is on the same merged line
(unusual in practice — most AU labels put it on a separate line).

---

## Two-Column OCR Merging (Real-Device Handling)

### Rule M1: Name-only + amount-only merge
Vision returns two-column supplement tables as spatially-separated observations.
The left column (nutrient names) and right column (amounts) become separate lines.
`mergedTwoColumnLines` merges consecutive pairs where:
- The first line has no recognisable amount ("name-only")
- The second line is just an amount, OR starts with an equivalence keyword

```
Input:  ["Taurine", "1000mg"]
Output: ["Taurine 1000mg"]
```

### Rule M2: Continuation line merge
`mergedContinuationLines` merges a line that has an amount with its following
equivalence continuation line (starting with "providing", "equiv.", "as", "from")
when that continuation line is "pure" (no embedded compound name after the closing paren).

```
Input:  ["Magnesium amino acid chelate 1750mg", "(providing elemental magnesium 350mg)"]
Output: ["Magnesium amino acid chelate 1750mg (providing elemental magnesium 350mg)"]
```

### Rule M3: isEquivalentContinuation matching
A line is an equivalent continuation if it starts with (optional open-paren, optional
whitespace) followed by: "providing", "equiv.", "equivalent to", "as WORD", "from WORD".
The "as" and "from" patterns require a full word after them (pattern: `as\s+\w+`, not
`as\s+\w` which breaks on multi-char form names like "Selenomethionine").

---

## Section Header Skip Rules

Section headers are skipped unconditionally, even when they contain amount-like text.
This prevents "EACH VEGETARIAN CAPSULE CONTAINS: 96 BILLION CFU" from being parsed
as a probiotic entry.

Skipped headers:
- "each tablet contains", "each capsule contains", "each dose contains"
- "each vegetarian capsule", "each veg capsule", "each softgel contains"
- "each softcap contains", "each sachet contains", "each scoop contains"

---

## Known Edge Cases (Corpus to be Expanded)

These are documented from domain knowledge. Test fixtures required for each.

| Edge case | Expected behaviour |
|---|---|
| "Vit. C 500mg" | Abbreviation — match via alias table |
| "B12 (Methylcobalamin) 1000mcg" | B12 → Vitamin B12, form=methylcobalamin |
| "CoQ10 100mg" | CoQ10 → Coenzyme Q10 via alias |
| "Folate (as L-5-MTHF) 400mcg" | form=L-5-methyltetrahydrofolate |
| "Iodine (from kelp) 150mcg" | form=kelp (not a quality tier — flag) |
| "Zinc 15mg (elemental)" | elemental in parens — same as Rule P4 |
| "Chromium (GTF) 200mcg" | form=GTF chromium |
| "Fish Oil 1000mg (EPA 180mg, DHA 120mg)" | outer entry + sub-entries |
| "Selenium (as selenomethionine) 200μg" | μg = mcg — Rule U1 |
| "Vitamin K2 (MK-7) 100mcg" | form=MK-7 (menaquinone-7) |
| "5-HTP 100mg" | name=5-HTP — no alias needed, exact match |
| "N-Acetyl Cysteine 600mg" | NAC alias — match via alias table |
| Multi-line ingredient (OCR splits one entry across two lines) | Join continuation lines |

---

## Alias Table (Seed — Expand with Corpus)

The alias table maps OCR-extracted variant names to canonical names used in
nrv_au.json / nrv_us.json / nrv_eu.json.

```json
{
  "aliases": [
    { "canonical": "Vitamin A", "variants": ["Vit A", "Retinol", "Beta-carotene", "β-carotene"] },
    { "canonical": "Vitamin C", "variants": ["Vit C", "Vit. C", "Ascorbic Acid", "L-Ascorbic Acid"] },
    { "canonical": "Vitamin D", "variants": ["Vit D", "Vitamin D3", "Vitamin D2", "Cholecalciferol", "Ergocalciferol"] },
    { "canonical": "Vitamin E", "variants": ["Vit E", "Tocopherol", "d-alpha-Tocopherol", "dl-alpha-Tocopherol"] },
    { "canonical": "Vitamin K", "variants": ["Vit K", "Vitamin K1", "Vitamin K2", "Phylloquinone", "Menaquinone", "MK-4", "MK-7"] },
    { "canonical": "Vitamin B1", "variants": ["Thiamine", "Thiamin"] },
    { "canonical": "Vitamin B2", "variants": ["Riboflavin"] },
    { "canonical": "Vitamin B3", "variants": ["Niacin", "Nicotinamide", "Nicotinic Acid", "Niacinamide"] },
    { "canonical": "Vitamin B5", "variants": ["Pantothenic Acid", "Calcium Pantothenate", "D-Pantothenic Acid"] },
    { "canonical": "Vitamin B6", "variants": ["Pyridoxine", "Pyridoxal-5-Phosphate", "P5P", "Pyridoxine HCl"] },
    { "canonical": "Vitamin B7", "variants": ["Biotin", "d-Biotin"] },
    { "canonical": "Vitamin B9", "variants": ["Folate", "Folic Acid", "L-5-MTHF", "Methylfolate", "Folinic Acid", "L-Methylfolate"] },
    { "canonical": "Vitamin B12", "variants": ["B12", "Cobalamin", "Methylcobalamin", "Cyanocobalamin", "Adenosylcobalamin", "Hydroxocobalamin"] },
    { "canonical": "Calcium", "variants": ["Ca", "Calcium Carbonate", "Calcium Citrate", "Calcium Phosphate"] },
    { "canonical": "Magnesium", "variants": ["Mg", "Mag"] },
    { "canonical": "Zinc", "variants": ["Zn"] },
    { "canonical": "Iron", "variants": ["Fe"] },
    { "canonical": "Iodine", "variants": ["I", "Potassium Iodide"] },
    { "canonical": "Selenium", "variants": ["Se"] },
    { "canonical": "Chromium", "variants": ["Cr"] },
    { "canonical": "Manganese", "variants": ["Mn"] },
    { "canonical": "Copper", "variants": ["Cu"] },
    { "canonical": "Molybdenum", "variants": ["Mo"] },
    { "canonical": "Phosphorus", "variants": ["P", "Phosphate"] },
    { "canonical": "Potassium", "variants": ["K"] },
    { "canonical": "Sodium", "variants": ["Na"] },
    { "canonical": "Coenzyme Q10", "variants": ["CoQ10", "Ubiquinone", "Ubiquinol"] },
    { "canonical": "N-Acetyl Cysteine", "variants": ["NAC", "N-Acetylcysteine"] },
    { "canonical": "Alpha Lipoic Acid", "variants": ["ALA", "Lipoic Acid", "Thioctic Acid"] }
  ]
}
```

---

## What the AI Must Never Do in ParserService

- Never guess an amount when it cannot be found — always return nil with a flag
- Never assume an unknown unit maps to a known one — return .unknown
- Never perform IU conversions for nutrients where IU is invalid
- Never silently drop a line that fails to parse — return it as raw_text
- Never use AI inference inside ParserService — deterministic rules only
- Never assume "elemental" weight equals the compound weight
