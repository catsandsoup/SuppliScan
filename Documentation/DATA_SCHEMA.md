# NutriScan — Data Schema
# v2 — Updated to support mixed-content labels (nutrients + herbals + probiotics)
# and serving size, bug-register-informed type safety
# Skills for this document: `swift-api-design-guidelines-skill`, `swift-format-style`
# READ THIS FILE FIRST before writing any model, service, or persistence code.
# Invoke `swift-api-design-guidelines-skill` when adding or changing any type.

---

## Core Design Decisions

### LabelEntry — Discriminated Union (Breaking Change from v1 Schema)

The original schema modelled all label entries as NutrientEntry.
The corpus proved this is wrong: labels contain four distinct entry types
that cannot be coerced into one model without losing clinical meaning.

```swift
enum LabelEntry: Identifiable, Codable {
    case nutrient(NutrientEntry)
    case herbal(HerbalEntry)
    case probiotic(ProbioticEntry)
    case unresolved(RawLine)

    var id: UUID {
        switch self {
        case .nutrient(let e):    return e.id
        case .herbal(let e):      return e.id
        case .probiotic(let e):   return e.id
        case .unresolved(let e):  return e.id
        }
    }
}
```

ParserService returns [LabelEntry].
ReviewView renders each case with its appropriate editor.
ReportService handles each case with its appropriate analysis path.
A product may contain any combination of all four types simultaneously.

---

## Entry Types

### NutrientEntry
A single nutrient with a quantified amount and potential NRV reference.
IU units must be converted before this type is created — CalculationService
never receives .iu unit. Conversion happens in ParserService.

```swift
struct NutrientEntry: Identifiable, Codable {
    let id: UUID
    var canonicalName: String       // matched via alias table, e.g. "Vitamin D"
    var displayName: String         // as it appeared on label, e.g. "Cholecalciferol"
    var form: String?               // e.g. "magnesium glycinate"
    var amount: Double?             // nil if OCR could not extract — never default to 0
    var unit: NutrientUnit          // .mg | .mcg | .g — never .iu after ParserService
    var isElemental: Bool           // true if amount is elemental weight
    var compoundAmount: Double?     // original compound weight if elemental was extracted
    var compoundUnit: NutrientUnit? // unit of the compound form
    var isTotalLine: Bool           // true if this is a summary total, not an individual form
    var reviewFlags: [ReviewFlag]   // parser-generated warnings for ReviewView
    var isManuallyEdited: Bool      // true if user corrected any field in ReviewView
    var servingMultiplier: Double   // default 1.0 — adjusted by serving size selector
}
```

### HerbalEntry
A herbal or botanical extract. No NRV data. May have standardisation data.

```swift
struct HerbalEntry: Identifiable, Codable {
    let id: UUID
    var latinName: String           // e.g. "Silybum marianum"
    var commonName: String?         // e.g. "St Mary's Thistle"
    var extractType: ExtractType    // .dryConcExtract | .softConcentrate | .driedHerb
    var extractAmount: Double?
    var extractUnit: NutrientUnit?
    var dryEquivalentAmount: Double? // the "equivalent to dry" value
    var dryEquivalentUnit: NutrientUnit?
    var standardisation: HerbalStandardisation?
    var reviewFlags: [ReviewFlag]
    var isManuallyEdited: Bool
    var servingMultiplier: Double
}

struct HerbalStandardisation: Codable {
    var compound: String            // e.g. "flavanolignans", "fatty acids", "silicon"
    var calculatedAs: String?       // e.g. "silybin"
    var amount: Double
    var unit: NutrientUnit
}

enum ExtractType: String, Codable {
    case dryConcExtract             // AU TGA standard dry concentrate
    case softConcentrate            // lipid-based soft extract (e.g. saw palmetto)
    case driedHerb                  // whole dried herb powder
    case tincture                   // liquid extract
    case unknown
}
```

### ProbioticEntry
A probiotic strain. Measured in CFU, not mass. No NRV data.

```swift
struct ProbioticEntry: Identifiable, Codable {
    let id: UUID
    var genus: String               // e.g. "Lactobacillus"
    var species: String             // e.g. "rhamnosus"
    var strain: String?             // e.g. "GG", "Lr-32"
    var cfuBillions: Double?        // nil if total-only label
    var isTotalLine: Bool           // true if this is the "96 Billion CFU" header line
    var reviewFlags: [ReviewFlag]
    var isManuallyEdited: Bool
}
```

### RawLine
A label line that ParserService could not classify. Surfaced in ReviewView
for manual resolution. Never silently dropped.

```swift
struct RawLine: Identifiable, Codable {
    let id: UUID
    let text: String                // exact OCR text
    let lineNumber: Int             // position in OCR output
    var userResolution: UserResolution? // set when user manually classifies
}

enum UserResolution: Codable {
    case convertedToNutrient(NutrientEntry)
    case convertedToHerbal(HerbalEntry)
    case convertedToProbiotic(ProbioticEntry)
    case dismissed                  // user confirmed this line should be ignored
}
```

---

## Supporting Types

### NutrientUnit

```swift
enum NutrientUnit: String, Codable, CaseIterable {
    case mg
    case mcg
    case g
    case iu         // ONLY valid during OCR extraction — must not reach CalculationService
    case unknown    // OCR extracted an unrecognised unit string

    // Units that CalculationService accepts
    static var calculationUnits: Set<NutrientUnit> { [.mg, .mcg, .g] }
}
```

### ReviewFlag
Parser-generated warnings surfaced to the user in ReviewView.
Non-blocking — user can proceed without resolving flags.

```swift
enum ReviewFlag: String, Codable {
    case amountNotFound             // no numeric amount could be extracted
    case unitUnknown                // unit string not in NutrientUnit table
    case dualUnit                   // both IU and metric present on label
    case rangeAmount                // "100-200mg" — lower bound used
    case traceAmount                // "trace" — set to 0
    case subOneAmount               // "<1mg" — set to 0.5
    case extractEquivalent          // label shows both extract and active amounts
    case proprietaryBlend           // individual amounts within blend unknown
    case totalLineAmbiguous         // "TOTAL X" line — confirm it supersedes sub-entries
    case iuConversionAssumed        // Vitamin E: synthetic form assumed for conversion
    case iuConversionInvalid        // IU stated for nutrient where IU is not valid
    case decimalCommaNormalised     // European "12,5" normalised to "12.5"
    case servingMultiplied          // amount adjusted by serving size multiplier
    case canonicalNameInferred      // name matched via alias, not exact match
}
```

### ServingSize
Captures how the label states serving information.
Feeds the serving size selector in ReviewView.

```swift
struct ServingSize: Codable {
    var quantity: Double            // e.g. 1, 2, 5
    var unit: ServingUnit           // .capsule | .tablet | .teaspoon | .gram | .ml
    var quantityOptions: [Double]   // e.g. [1, 2, 3] for variable dosing products
    var selectedQuantity: Double    // user-selected serving, default = quantity

    // Multiplier applied to all entry amounts for calculation
    var multiplier: Double { selectedQuantity / quantity }
}

enum ServingUnit: String, Codable {
    case capsule, tablet, teaspoon, tablespoon, gram, ml, sachet, scoop, unknown
}
```

---

## Analysis Types

### LabelAnalysis
Top-level output of ReportService. Contains all entry analyses
regardless of type. Replaces the old [NutrientAnalysis]-only model.

```swift
struct LabelAnalysis: Identifiable, Codable {
    let id: UUID
    let productName: String
    let referenceStandard: ReferenceStandard
    let demographic: Demographic
    let servingSize: ServingSize
    let nutrientAnalyses: [NutrientAnalysis]
    let herbalEntries: [HerbalEntry]        // passed through — no NRV calculation
    let probioticEntries: [ProbioticEntry]  // passed through — no NRV calculation
    let unresolvedLines: [RawLine]          // lines user did not resolve
    let flags: ReportFlags
    let disclaimer: String                  // always set by ReportService
    let schemaVersion: Int                  // for Codable migration — always set to current
}
```

### NutrientAnalysis
Unchanged in structure, updated to reference LabelEntry instead of NutrientEntry directly.

```swift
struct NutrientAnalysis: Identifiable, Codable {
    let id: UUID
    let entry: NutrientEntry
    let rdiPercent: Double?         // nil if no RDI established
    let ulPercent: Double?          // nil if no UL established
    let rdiReference: RDIReference?
    let ulReference: ULReference?
    let formQuality: FormQuality?
    let effectiveDose: Double?      // entry.amount * servingMultiplier
    let effectiveDoseUnit: NutrientUnit?
}
```

### FormQuality

```swift
struct FormQuality: Codable {
    let tier: FormTier
    let rationale: String
    let isAIInferred: Bool          // MUST default to false — set true only by AIService
    let confidence: Double?         // only present when isAIInferred = true
    let references: [String]        // PMIDs or citations — empty for AI-inferred
}

enum FormTier: Int, Codable, CaseIterable {
    case tier1 = 1  // High bioavailability, well-evidenced
    case tier2 = 2  // Moderate bioavailability, commonly used
    case tier3 = 3  // Low bioavailability, cheap filler forms
    case tier4 = 4  // Synthetic or potentially problematic
}
```

### ReportFlags

```swift
struct ReportFlags: Codable {
    let nutrientsAboveUL: [NutrientAnalysis]
    let nutrientsAtUL: [NutrientAnalysis]           // within 10% of UL
    let lowBioavailabilityForms: [NutrientAnalysis] // tier3 or tier4
    let aiInferredForms: [NutrientAnalysis]
    let unresolvedEntries: [RawLine]                // user-unresolved OCR lines
    let servingSizeAdjusted: Bool                   // true if multiplier != 1.0
}
```

### RDIReference / ULReference

```swift
struct RDIReference: Codable {
    let standard: ReferenceStandard
    let demographic: String         // group key, e.g. "adult_male_19_50"
    let value: Double
    let unit: NutrientUnit
    let referenceType: ReferenceType // .rdi | .ear | .ai
    let source: String              // e.g. "NHMRC 2023"
}

struct ULReference: Codable {
    let standard: ReferenceStandard
    let demographic: String
    let value: Double
    let unit: NutrientUnit
    let note: String?               // e.g. "applies to supplemental only"
    let source: String
}

enum ReferenceType: String, Codable {
    case rdi    // Recommended Dietary Intake
    case ear    // Estimated Average Requirement
    case ai     // Adequate Intake (where RDI not established)
}
```

### Demographic

```swift
struct Demographic: Codable, Equatable {
    let key: String                 // e.g. "adult_male_19_50" — matches JSON keys
    let displayName: String         // e.g. "Adult Male 19–50"
    let ageMin: Int
    let ageMax: Int?                // nil for open-ended (e.g. "70+")
    let sex: BiologicalSex
    let isPregnant: Bool
    let isLactating: Bool

    static let defaultAdult = Demographic(
        key: "adult_male_19_50",
        displayName: "Adult Male 19–50",
        ageMin: 19, ageMax: 50,
        sex: .male,
        isPregnant: false,
        isLactating: false
    )
}

enum BiologicalSex: String, Codable {
    case male, female, notSpecified
}
```

### ReferenceStandard

```swift
enum ReferenceStandard: String, Codable, CaseIterable {
    case au = "AU"      // NHMRC NRVs
    case us = "US"      // NIH/FDA DRIs
    case eu = "EU"      // EFSA NRVs
}
```

### LoadingState
Used by all ViewModels for async operations.
Eliminates the impossible state of isLoading=false + result=nil + error=nil.

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(AppError)
}
```

---

## Persistence Schema

### ScanRecord (SwiftData @Model)
Unchanged from SWIFTDATA.md except schemaVersion is now mandatory.

```swift
@Model
final class ScanRecord {
    @Attribute(.unique) var id: UUID  // Note: remove if CloudKit added in v2
    var createdAt: Date
    var productName: String
    var referenceStandard: String
    var demographicKey: String
    var reportData: Data              // archived LabelAnalysis (not ReportModel — updated)
    var schemaVersion: Int            // always set to current schema version on write
}
```

### LabelAnalysis Codable Versioning
schemaVersion guards against future Codable migration failures.

```swift
extension LabelAnalysis {
    static let currentSchemaVersion = 1

    // Called by PersistenceService on load
    static func decode(from data: Data) throws -> LabelAnalysis {
        let analysis = try JSONDecoder().decode(LabelAnalysis.self, from: data)
        // Future: if analysis.schemaVersion < currentSchemaVersion, migrate
        return analysis
    }
}
```

---

## Bundled JSON Schemas

### nrv_au.json / nrv_us.json / nrv_eu.json
Updated to include all reference type variants.

```json
{
  "standard": "AU",
  "edition": "2023",
  "source": "NHMRC Nutrient Reference Values for Australia and New Zealand",
  "nutrients": [
    {
      "name": "Magnesium",
      "aliases": ["magnesium", "mg elemental", "mag"],
      "calculation_unit": "mg",
      "demographics": [
        {
          "group": "adult_male_19_50",
          "rdi": 420,
          "ear": 350,
          "ai": null,
          "ul": 350,
          "ul_note": "UL applies to supplemental magnesium only",
          "reference_type": "rdi"
        }
      ]
    },
    {
      "name": "Vitamin D",
      "aliases": ["vitamin d", "vitamin d3", "vitamin d2", "cholecalciferol",
                  "colecalciferol", "ergocalciferol"],
      "calculation_unit": "mcg",
      "iu_conversion": {
        "factor": 0.025,
        "note": "1 IU = 0.025 mcg, applies to both D2 and D3"
      },
      "demographics": [
        {
          "group": "adult_male_19_50",
          "rdi": null,
          "ear": null,
          "ai": 5,
          "ul": 80,
          "reference_type": "ai"
        }
      ]
    }
  ]
}
```

### aliases.json
Standalone alias table — loaded by ParserService for canonical name matching.
Separate from NRV JSON so it can be updated without touching reference values.

```json
{
  "version": "1.0",
  "aliases": [
    {
      "canonical": "Vitamin D",
      "variants": ["Vit D", "Vitamin D3", "Vitamin D2",
                   "Cholecalciferol", "Colecalciferol", "Ergocalciferol",
                   "D3", "D2"]
    },
    {
      "canonical": "Vitamin B12",
      "variants": ["B12", "Cobalamin", "Methylcobalamin", "Mecobalamin",
                   "Cyanocobalamin", "Adenosylcobalamin", "Hydroxocobalamin"]
    }
  ]
}
```

---

## What the AI Must Never Do With These Types

- Never create NutrientEntry with unit = .iu — IU conversion is ParserService's job
- Never set amount = 0.0 when amount should be nil — 0 and nil mean different things
- Never set isAIInferred = false on a FormQuality returned by AIService
- Never omit schemaVersion when creating LabelAnalysis or ScanRecord
- Never sum nutrient entries where isTotalLine = true alongside the sub-entries
- Never apply servingMultiplier more than once — it lives in the entry, not in calculation
- Never force-unwrap entry.amount — it is Optional for a reason
