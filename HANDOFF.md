# SuppliScan — Agent Handoff Document
# Generated: June 2026
# From: Session building Layers 1–4

---

## Skill Status — READ THIS FIRST

**The 58 Swift skills are NOT currently installed.** They were installed in a
previous session but did not persist. Before writing any code, the user needs
to reinstall them. See CLAUDE.md § Skills for the install path.

### How skills work in the Claude Mac app
- Skills appear as slash commands (e.g. `/swift-concurrency-pro`)
- They CANNOT be invoked programmatically from agent code via the `Skill` tool
- The user must type `/skill-name` in the chat BEFORE asking the agent to write code
- After skill files are copied to the skills directory, Claude Code needs a restart

### The right workflow for each coding session
1. User reinstalls skills (or confirms they're already installed)
2. User types `/swift-architecture-skill` → then asks agent to design services
3. User types `/swift-concurrency-pro` → then asks agent to write async services
4. User types `/swiftui-pro` → then asks agent to write Views
5. etc.

---

## What Was Built (Layers 1–4)

### Summary
1,646 lines of Swift across 34 files. All builds succeed. No third-party frameworks.

### Layer 1 — Models (18 files)
All in `SuppliScan/SuppliScan/SuppliScan/Models/`:

| File | Description |
|---|---|
| `AppError.swift` | LocalizedError enum with all error cases from ERROR_STATES.md |
| `Demographic.swift` | Flat struct with BiologicalSex enum, `Demographic.all` static array |
| `FormQuality.swift` | FormQuality struct + FormTier enum (Int 1-4, Comparable) |
| `HerbalEntry.swift` | HerbalEntry + HerbalStandardisation struct + ExtractType enum |
| `LabelAnalysis.swift` | Top-level report struct — nonisolated statics for SE-0411 |
| `LabelEntry.swift` | Discriminated union enum — Hashable by id only |
| `LoadingState.swift` | LoadingState<T: Sendable> enum |
| `NutrientAnalysis.swift` | Per-nutrient analysis result struct |
| `NutrientEntry.swift` | Core nutrient model with Optional amount |
| `NutrientUnit.swift` | Unit enum — .iu is parser-stage only |
| `ProbioticEntry.swift` | Probiotic strain struct |
| `RDIReference.swift` | RDI reference value struct |
| `RawLine.swift` | Unresolved OCR line + UserResolution enum |
| `ReferenceStandard.swift` | AU/US/EU enum |
| `ReferenceType.swift` | rdi/ear/ai enum |
| `ReportFlags.swift` | Report-level flags struct with `.empty` and `hasAnyFlags` |
| `ReviewFlag.swift` | Parser warning enum (14 cases) |
| `ServingSize.swift` | Serving size struct with computed multiplier + ServingUnit enum |
| `ULReference.swift` | Upper limit reference value struct |

### Layer 2 — Persistence (2 files)
All in `SuppliScan/SuppliScan/SuppliScan/Persistence/`:

| File | Description |
|---|---|
| `SuppliScanSchema.swift` | VersionedSchema, ScanRecord @Model, SuppliScanMigrationPlan |
| `PersistenceService.swift` | actor — save, fetchAll, fetchAnalysis, delete, deleteAll |

### Layer 3 — Navigation (2 files)
All in `SuppliScan/SuppliScan/SuppliScan/Navigation/`:

| File | Description |
|---|---|
| `AppDestination.swift` | Hashable enum — .scan, .review, .report, .history |
| `NavigationRouter.swift` | @Observable @MainActor — navigate, pop, popToRoot |

### Layer 4 — App Entry + Stubs (9 files)

| File | Path | Description |
|---|---|---|
| `SuppliScanApp.swift` | App root | @main with ModelContainer, NavigationRouter, AppDependencies |
| `AppDependencies.swift` | App/ | @Observable @MainActor holding PersistenceService |
| `HomeView.swift` | Features/Home/ | Full impl: NavigationStack, scan button, history preview, routing |
| `ScanView.swift` | Features/Scan/ | Stub — ContentUnavailableView placeholder |
| `ReviewView.swift` | Features/Review/ | Stub — accepts [LabelEntry] + ServingSize? |
| `ReportView.swift` | Features/Report/ | Stub — accepts LabelAnalysis |
| `HistoryView.swift` | Features/History/ | @Query ScanRecord, ScanHistoryRowView list |
| `SettingsView.swift` | Features/Settings/ | @AppStorage for standard + demographic |
| `ScanHistoryRowView.swift` | Components/ | Reusable row component |

### Layer 5 — Reference Data (JSON files only, no Swift services yet)
In `SuppliScan/SuppliScan/SuppliScan/Resources/ReferenceData/`:

| File | Status |
|---|---|
| `aliases.json` | ✅ Created — 32 nutrient aliases |
| `form_quality.json` | ✅ Created — 38 form quality entries for key nutrients |
| `nrv_au.json` | 🔲 NOT created |
| `nrv_us.json` | 🔲 NOT created |
| `nrv_eu.json` | 🔲 NOT created |

### Utilities (2 files)
| File | Description |
|---|---|
| `Logger+SuppliScan.swift` | OSLog loggers for 9 categories |
| `Bundle+ReferenceData.swift` | Typed JSON accessors |

---

## ⚠️ Skill-Review Audit — Files Written Without Skill Validation

All Layer 1–4 code was written without skill invocation (skills unavailable).
The next agent should audit these in skill priority order before continuing.

### Audit Pass 1 — Architecture & API Design
**Skill:** `/swift-architecture-skill` + `/swift-api-design-guidelines-skill`
**Files to review:**
- `Models/LabelEntry.swift` — discriminated union design
- `Models/LabelAnalysis.swift` — nonisolated static pattern for SE-0411
- `Models/ReportFlags.swift` — struct design, computed property coverage
- `Models/NutrientEntry.swift` — Optional amount semantics
- `Models/HerbalEntry.swift` — ExtractType enum completeness
- `Navigation/AppDestination.swift` — Hashable conformance, associated values
- `Navigation/NavigationRouter.swift` — API surface, NavigationPath usage
- `App/AppDependencies.swift` — DI pattern, @Observable @MainActor correctness

### Audit Pass 2 — Swift Concurrency
**Skill:** `/swift-concurrency-pro` + `/swift-concurrency-expert`
**Files to review:**
- `Persistence/PersistenceService.swift` — actor isolation, ModelContext confinement
- `SuppliScanApp.swift` — MainActor.assumeIsolated usage in init()
- `Models/LabelAnalysis.swift` — Sendable conformance, nonisolated statics
- `Models/LoadingState.swift` — Sendable constraint on T

### Audit Pass 3 — SwiftData
**Skill:** `/swiftdata-pro` + `/swiftdata-expert-skill`
**Files to review:**
- `Persistence/SuppliScanSchema.swift` — VersionedSchema, @Model init, migration plan
- `Persistence/PersistenceService.swift` — ModelContext usage, #Predicate queries
- `SuppliScanApp.swift` — ModelContainer init, fallback pattern
- `Features/History/HistoryView.swift` — @Query usage correctness

### Audit Pass 4 — SwiftUI
**Skill:** `/swiftui-pro` + `/swiftui-ui-patterns`
**Files to review:**
- `Features/Home/HomeView.swift` — full implementation, navigationDestination, modifiers
- `Features/History/HistoryView.swift` — @Query + list rendering
- `Features/Settings/SettingsView.swift` — @AppStorage pattern
- `Components/ScanHistoryRowView.swift` — reusable component correctness

### Audit Pass 5 — Accessibility
**Skill:** `/swiftui-accessibility-auditor`
**Files to review:**
- `Features/Home/HomeView.swift`
- `Components/ScanHistoryRowView.swift`

### Audit Pass 6 — Code Quality
**Skill:** `/ios-code-audit`
**Run on all files above after other audits are complete.**

---

## What To Build Next — Layer 5 Services

Build in this order (lower items depend on higher):

### Batch A — Foundation (no async dependencies)
1. **`UnitConversionService.swift`** — `enum UnitConversionService` (no init, static methods)
   - Invoke `/swift-architecture-skill` + `/swift-api-design-guidelines-skill` first
   - Input: NutrientEntry with .iu unit → Output: NutrientEntry with .mcg/.mg
   - Conversion table: Vitamin D (0.025 mcg/IU), Vitamin A (0.3 mcg/IU retinol), Vitamin E (0.67 mg/IU natural, 0.45 synthetic)
   - Other nutrients: flag `.iuConversionInvalid`, do NOT convert
   - If form ambiguous for Vit E: use synthetic (conservative), flag `.iuConversionAssumed`
   - See PARSER_SPEC.md § Unit Conversion Table for exact rules

2. **`ParserService.swift`** + **`ParseResult.swift`**
   - Invoke `/swift-api-design-guidelines-skill` first
   - Synchronous. Input: raw OCR String → Output: ParseResult(entries: [LabelEntry], extractedServing: ServingSize?)
   - Must implement all rules P1–P10, A1–A5, U1–U2 from PARSER_SPEC.md
   - Must call UnitConversionService for any .iu entries before returning
   - See PARSER_SPEC.md for complete rule set + edge cases table
   - Parser must NEVER silently drop a line — return RawLine if unclassifiable

3. **`nrv_au.json`** — NHMRC NRVs (AU) — see JSON schema in DATA_SCHEMA.md
   - Demographics needed: adult_male_19_50, adult_female_19_50, adult_male_51_70,
     adult_female_51_70, adult_male_70plus, adult_female_70plus,
     pregnant_female_19_50, lactating_female_19_50
   - Nutrients: Vitamins A/C/D/E/K, B1/B2/B3/B5/B6/B7/B9/B12,
     Calcium/Magnesium/Zinc/Iron/Iodine/Selenium/Copper/Manganese/Chromium/
     Molybdenum/Phosphorus/Potassium/Sodium
   - JSON schema: See DATA_SCHEMA.md § Bundled JSON Schemas

4. **`nrv_us.json`** — NIH/FDA DRIs (US) — same schema, different values
5. **`nrv_eu.json`** — EFSA NRVs (EU) — same schema, different values

6. **`ReferenceDataService.swift`**
   - Invoke `/swift-concurrency-pro` + `/swift-architecture-skill` first
   - `actor ReferenceDataService` — loads all 3 NRV files + aliases at startup
   - Internal: NRVDataFile, NRVNutrientEntry, NRVDemographicEntry Codable structs
   - Public API:
     - `func load() async throws`
     - `func nrvEntry(for nutrient: String, standard: ReferenceStandard, demographic: Demographic) -> NRVEntry?`
     - `func aliases() -> [String: String]` (variant → canonical mapping)
   - After load(), all queries synchronous on in-memory data

### Batch B — Calculation (depends on Batch A)
7. **`CalculationService.swift`**
   - Invoke `/swift-api-design-guidelines-skill` + `/swift-concurrency-pro` first
   - `enum CalculationService` (stateless, static methods)
   - Input: NutrientEntry + NRVEntry + ServingSize → NutrientAnalysis
   - MUST: `precondition(entry.unit != .iu, "CalculationService received .iu unit")` at entry
   - effectiveDose = entry.amount * servingSize.multiplier (applied exactly once here)
   - rdiPercent = (effectiveDose / rdi.value) * 100
   - ulPercent = (effectiveDose / ul.value) * 100
   - Both rdiPercent and ulPercent are nil when reference is nil — never 0

### Batch C — AI & Form Quality (depends on Batch B)
8. **`AIService.swift`**
   - Invoke `/swift-security-expert` + `/swift-concurrency-pro` first
   - `struct AIService` — no stored state, async throws
   - 10 second timeout using `Task { try await service.call() }.value` with timeout
   - Sends ONLY: nutrient name + form string — no user, product, or health data
   - Returns `AIFormResult?` (nil on any failure — never throws to caller)
   - API key from Keychain only — never hardcoded or in UserDefaults
   - See ARCHITECTURE.md § AI Integration Point

9. **`FormQualityService.swift`**
   - Invoke `/swift-concurrency-pro` first
   - `struct FormQualityService` — async, init(curated: [FormQualityEntry], aiService: AIService?)
   - Curated lookup (sync) → if miss AND aiService != nil → AIService call (async)
   - `isAIInferred = true` ONLY on AIService result — never on curated result
   - `isAIInferred = false` default — never set true in curated path
   - Returns `.tier2` with note "Form quality data unavailable" if AI also unavailable

### Batch D — Report & Export (depends on Batch C)
10. **`ReportService.swift`**
    - Invoke `/swift-concurrency-pro` + `/swift-architecture-skill` first
    - `struct ReportService` — async, coordinates all above services
    - Uses `withThrowingTaskGroup` for parallel per-nutrient analysis
    - Total line handling: if isTotalLine=true, use for calc, skip sub-entries with same canonicalName
    - Sets `LabelAnalysis.disclaimer` from `LabelAnalysis.disclaimer` static
    - Sets `LabelAnalysis.schemaVersion` to `LabelAnalysis.currentSchemaVersion`
    - Herbal + Probiotic entries passed through unchanged (no NRV calc)
    - See ARCHITECTURE.md § Data Flow and CONCURRENCY.md § ReportService

11. **`OCRService.swift`**
    - Invoke `/swift-concurrency-pro` first
    - `struct OCRService` — async throws
    - VisionKit: VNRecognizeTextRequest + VNImageRequestHandler
    - Off-main-actor — runs on background thread via VisionKit
    - Downsample input image to 2000px max (see BUG_REGISTER.md)
    - Returns raw text string (one string per page/frame)
    - Throws `.ocrNoTextFound` or `.ocrLowConfidence(recognisedText:)` on quality issues

12. **`ExportService.swift`**
    - Invoke `/swift-concurrency-pro` first
    - `struct ExportService` — async throws
    - PDFKit: PDFDocument composition
    - Returns Data (not URL) — caller hands to ShareLink
    - Throws `.exportPDFGenerationFailed` on failure

---

## Key Rules Reminder For Next Agent

### Clinical Safety (non-negotiable)
- IU conversion table is HARDCODED in PARSER_SPEC.md — no AI, no approximation
- CalculationService MUST use `precondition(unit != .iu)` — crash before wrong calc
- ServingMultiplier applied ONCE in CalculationService — nowhere else
- `isAIInferred` must survive Codable round-trip (it's a stored Bool, not computed)
- `LabelAnalysis.disclaimer` MUST appear on every report
- `schemaVersion` MUST be set on every LabelAnalysis and ScanRecord write

### Swift 6 Patterns
- All static stored props on non-actor types: use `nonisolated` (SE-0411)
- Never use typographic/curly quotes inside string literals — breaks compiler
- No DispatchQueue, no Task.sleep(nanoseconds:) — use Task.sleep(for:)
- Never force-unwrap entry.amount — it's Optional by design

### SwiftData
- No `@Attribute(.unique)` on ScanRecord
- No `@Environment(\.modelContext)` for writes
- Explicit ModelContext.save() — never rely on autosave

---

## Known Remaining Warnings (2)

In `LabelAnalysis.swift` lines 55 and 61:
```
warning: main actor-isolated conformance of 'LabelAnalysis' to 'Decodable'/'Encodable'
cannot be used in nonisolated context
```

Build still succeeds. Root cause: The Codable conformance synthesis may be pulling in
a @MainActor property somewhere in the chain. Investigate with `/swift-concurrency-expert`
before it becomes a blocker.

---

## Project File Paths (Quick Reference)

```
/Users/montygiovenco/Documents/GitHub/SuppliScan/
├── CLAUDE.md                    ← Auto-read by Claude Code
├── AGENTS.md                    ← Coding rules + full skill table
├── MASTER.md                    ← Project brief
├── ARCHITECTURE.md              ← Service graph
├── DATA_SCHEMA.md               ← All Swift types — start here
├── CONCURRENCY.md               ← Async patterns
├── PARSER_SPEC.md               ← Parser rules + IU conversion table
├── ERROR_STATES.md              ← Error handling per service
├── BUG_REGISTER.md              ← Known iOS bugs to avoid
├── TEST_CORPUS.md               ← Test fixture guide
└── SuppliScan/SuppliScan/SuppliScan/
    ├── Models/                  ← 18 model files (Layer 1)
    ├── Persistence/             ← 2 files (Layer 2)
    ├── Navigation/              ← 2 files (Layer 3)
    ├── App/                     ← AppDependencies.swift
    ├── Features/                ← Stub views (Layer 4)
    │   ├── Home/
    │   ├── Scan/
    │   ├── Review/
    │   ├── Report/
    │   ├── History/
    │   └── Settings/
    ├── Components/              ← ScanHistoryRowView.swift
    ├── Services/                ← EMPTY — Layer 5 target
    ├── Resources/ReferenceData/ ← aliases.json, form_quality.json
    │   nrv_au.json (MISSING)
    │   nrv_us.json (MISSING)
    │   nrv_eu.json (MISSING)
    ├── Utilities/               ← Logger+SuppliScan, Bundle+ReferenceData
    └── SuppliScanApp.swift
```

---

## Build Command (for verification after any change)

```
xcodebuild -scheme SuppliScan \
  -destination "platform=iOS Simulator,id=D9D19D7C-ADD2-4200-9CDB-52418C68E6B7" \
  -project /Users/montygiovenco/Documents/GitHub/SuppliScan/SuppliScan/SuppliScan.xcodeproj \
  build 2>&1 | tail -5
```

Last verified build: ✅ BUILD SUCCEEDED (Layer 1–4 complete, no services yet)
