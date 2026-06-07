# NutriScan — Test Corpus Guide
# Skills for this document: `swift-testing-pro`, `swift-testing-expert`
# Invoke `swift-testing-pro` when writing any new test suite.
# Invoke `swift-testing-expert` for parameterised corpus-driven tests.

## What This Is

The test corpus is the ground-truth dataset for OCR accuracy and parser
correctness testing. It consists of:

1. Real supplement label images (PNG) → OCR accuracy tests
2. Expected parser output JSON → ParserService unit tests
3. Novel form strings → FormQualityService AI inference tests

Tests in NutriScanTests/ reference these fixtures directly.
The corpus grows over time — start with the seed set below and expand.

---

## Directory Structure

```
NutriScanTests/TestFixtures/
│
├── Labels/                         ← Raw label images for OCR tests
│   ├── [product_descriptor].png
│   └── README.md                   ← Photo instructions
│
├── ParsedLabels/                   ← Expected ParserService output
│   ├── [product_descriptor].json   ← Matches corresponding .png name
│   └── schema.md                   ← JSON schema documentation
│
└── FormQuality/
    ├── novel_forms.json             ← Form strings not in curated DB
    └── expected_tiers.json          ← Expected AI inference output
```

---

## Label Image Corpus

### How to Photograph Labels

**Equipment:** iPhone camera (the same device the app targets).

**Lighting:** Vary deliberately across the corpus:
- Good natural light (target: most accurate)
- Indoor overhead light
- Slightly dim (kitchen/bathroom cabinet)

**Angle:** Vary:
- Flat on (ideal)
- Slight 15° tilt
- Curved label on cylindrical bottle

**Distance:** Frame so the supplement facts panel fills 70%+ of the frame.

**What to capture per product:**
1. The full supplement facts / nutrition information panel
2. Include the product name if visible on same face

### Target Corpus — Seed Set (Build Before First OCR Test)

Aim for 15–20 images covering this variety:

| Category | Target count | Notes |
|---|---|---|
| Single-nutrient (e.g. Magnesium only) | 2–3 | Simple parse, good baseline |
| Multivitamin (10–20 nutrients) | 3–4 | Dense table, AU format |
| Multivitamin (US Supplement Facts) | 2–3 | US panel layout |
| B-complex | 2 | Multiple B vitamins, mcg units |
| Fat-soluble vitamins (A, D, E, K) | 2 | IU units — critical for conversion tests |
| Mineral complex | 2 | Various forms (oxide, citrate, glycinate) |
| Fish oil / omega-3 | 1 | Sub-nutrients (EPA, DHA) |
| Poor lighting | 2 | Stress-test OCR |
| Curved bottle label | 2 | Distortion test |

### File Naming Convention

```
[category]_[nutrients]_[condition].png

Examples:
magnesium_glycinate_good_light.png
multivitamin_au_format_overhead.png
vitamin_d_iu_curved_bottle.png
b_complex_dim_light.png
```

---

## Expected Output JSON Schema

Each `.png` in Labels/ has a matching `.json` in ParsedLabels/.
The JSON defines the ground-truth expected parser output for that image.

```json
{
  "source_image": "magnesium_glycinate_good_light.png",
  "expected_entries": [
    {
      "name": "Magnesium",
      "canonical_name": "Magnesium",
      "form": "magnesium glycinate",
      "amount": 300,
      "unit": "mg",
      "is_manually_edited": false,
      "review_flags": []
    }
  ],
  "expected_unresolved": [],
  "notes": "Clean single-nutrient label, no edge cases"
}
```

For labels with expected review flags:
```json
{
  "source_image": "vitamin_d_iu_curved_bottle.png",
  "expected_entries": [
    {
      "name": "Vitamin D3",
      "canonical_name": "Vitamin D",
      "form": null,
      "amount": 1000,
      "unit": "iu",
      "converted_amount": 25,
      "converted_unit": "mcg",
      "review_flags": ["dual_unit"]
    }
  ],
  "expected_unresolved": [],
  "notes": "IU conversion test case — must produce 25mcg"
}
```

---

## Novel Form Strings for AI Inference Tests

`FormQuality/novel_forms.json` — form strings deliberately absent from
the curated form_quality.json database.

Your domain knowledge assigns the expected tier.
These test that AIService returns plausible tiers and that
isAIInferred is correctly set to true.

```json
{
  "novel_forms": [
    {
      "nutrient": "Magnesium",
      "form_string": "magnesium orotate",
      "expected_tier": 1,
      "rationale": "Orotate salt — good bioavailability, used in cardiac contexts",
      "notes": "Not in curated DB — should trigger AI inference"
    },
    {
      "nutrient": "Zinc",
      "form_string": "zinc acetate",
      "expected_tier": 2,
      "rationale": "Moderate bioavailability, less studied than glycinate",
      "notes": "Novel form"
    },
    {
      "nutrient": "Iron",
      "form_string": "iron proteinate",
      "expected_tier": 2,
      "rationale": "Protein-chelated, moderate bioavailability",
      "notes": "Novel form"
    },
    {
      "nutrient": "Calcium",
      "form_string": "calcium hydroxyapatite",
      "expected_tier": 2,
      "rationale": "Bone-derived form, moderate absorption",
      "notes": "Novel form"
    },
    {
      "nutrient": "Vitamin B6",
      "form_string": "pyridoxamine",
      "expected_tier": 1,
      "rationale": "Active form, superior to pyridoxine HCl",
      "notes": "Novel form"
    }
  ]
}
```

Seed with 15–20 examples. Expand as the curated DB grows.

---

## How Tests Use the Corpus

### OCR Accuracy Tests (ParserServiceTests.swift)

```swift
@Test("Parser extracts magnesium glycinate correctly")
func testMagnesiumGlycinateLabel() async throws {
    let image = try loadTestImage("magnesium_glycinate_good_light")
    let rawText = try await OCRService().extract(from: image)
    let entries = ParserService().parse(rawText)
    let expected = try loadExpectedOutput("magnesium_glycinate_good_light")

    #expect(entries.count == expected.expected_entries.count)
    #expect(entries[0].name == "Magnesium")
    #expect(entries[0].form == "magnesium glycinate")
    #expect(entries[0].amount == 300)
    #expect(entries[0].unit == .mg)
}
```

### Parser Rule Tests (no images needed)

```swift
@Test("Rule P2: as-qualifier extraction")
func testAsQualifierParsing() {
    let input = "Zinc (as zinc citrate) 15mg"
    let entries = ParserService().parse(input)

    #expect(entries.count == 1)
    #expect(entries[0].name == "Zinc")
    #expect(entries[0].form == "zinc citrate")
    #expect(entries[0].amount == 15)
    #expect(entries[0].unit == .mg)
}
```

### Unit Conversion Tests

```swift
@Test("Vitamin D IU to mcg conversion")
func testVitaminDConversion() {
    let entry = NutrientEntry(name: "Vitamin D3", form: nil, amount: 1000, unit: .iu)
    let converted = ParserService().normaliseUnits(entry)

    #expect(converted.amount == 25)
    #expect(converted.unit == .mcg)
}

@Test("Vitamin E natural form IU conversion")
func testVitaminENaturalConversion() {
    let entry = NutrientEntry(name: "Vitamin E", form: "d-alpha-tocopherol", amount: 100, unit: .iu)
    let converted = ParserService().normaliseUnits(entry)

    #expect(converted.amount == 67)  // 100 × 0.67
    #expect(converted.unit == .mg)
}
```

---

## Growing the Corpus

Add images and expected JSON as you encounter new label formats in the wild.
When a bug is found in production (wrong parse), add a fixture that reproduces
it and a test that catches it — then fix the parser. This prevents regressions.

Corpus growth checkpoints:
- Before v1 TestFlight: minimum 15 label images with expected output
- Before v1 App Store: minimum 25 label images, all 3 standards represented
- Ongoing: any bug report generates a new fixture
