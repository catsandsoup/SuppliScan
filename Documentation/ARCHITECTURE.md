# NutriScan — Architecture Document
# Skills for this document: `swift-architecture-skill`, `swift-api-design-guidelines-skill`
# Invoke `swift-architecture-skill` before adding new services or changing the service graph.
# Invoke `swift-api-design-guidelines-skill` when designing any new public API or type.
# v2 — Updated for LabelEntry discriminated union and serving size

## Pattern
MVVM with a dedicated Service layer. SwiftUI views bind to ViewModels.
ViewModels coordinate Services. Services own all business logic.
Views own zero business logic.

```
View → ViewModel → Service → Data Layer
                ↓
          AI Service (form gap-fill only)
```

---

## Layer Definitions

### Views (SwiftUI)
- Render state from ViewModel
- Emit user actions to ViewModel
- No direct service calls, no calculations
- Files: ScanView, ReviewView, ReportView, HistoryView, SettingsView

### ViewModels (@Observable, @MainActor)
- Own view state
- Coordinate service calls
- Transform service output into display models
- One ViewModel per major screen
- Files: ScanViewModel, ReviewViewModel, ReportViewModel, HistoryViewModel

### Services
- Own all business logic
- Stateless where possible
- Injected via initialiser
- See service table below

### Data Layer
- SwiftData for scan history persistence
- Bundled JSON for reference data (NRVs, ULs, form quality, aliases)
- No remote database in v1

---

## Service Responsibilities

| Service | Input | Output | Notes |
|---|---|---|---|
| OCRService | CGImage | String (raw text) | VisionKit, async, off-main |
| ParserService | String | [LabelEntry] | Deterministic, synchronous |
| ReferenceDataService | nutrient name + standard + demographic | NRVEntry? | Read-only after launch |
| UnitConversionService | NutrientEntry (.iu) | NutrientEntry (.mcg/.mg) | Deterministic, synchronous |
| CalculationService | NutrientEntry + NRVEntry + ServingSize | NutrientAnalysis | Deterministic, synchronous |
| FormQualityService | name + form string | FormQuality | Curated lookup → AI fallback |
| AIService | name + form string | AIFormResult? | Network, async, optional |
| ReportService | [LabelEntry] + standard + demographic + serving | LabelAnalysis | Coordinates all above |
| PersistenceService | LabelAnalysis | ScanRecord | SwiftData actor |
| ExportService | LabelAnalysis | Data (PDF) | PDFKit, async |

**UnitConversionService is new** — extracted from ParserService to make
IU conversion testable in isolation. ParserService calls it; CalculationService
never receives a .iu unit.

---

## Data Flow: Scan to Report

```
1.  ScanViewModel → OCRService → raw String
2.  ScanViewModel → ParserService → [LabelEntry]
    └─ ParserService → UnitConversionService (for any .iu entries)
3.  User reviews [LabelEntry] in ReviewView
    └─ Sets ServingSize (extracted by ParserService, editable by user)
    └─ Corrects any flagged entries
    └─ Resolves any RawLine entries or dismisses them
4.  ReportViewModel receives confirmed [LabelEntry] + ServingSize
5.  ReportViewModel → ReportService.generate(entries:serving:standard:demographic:)
    └─ For each NutrientEntry where !isTotalLine:
        a. ReferenceDataService → NRVEntry?
        b. CalculationService → NutrientAnalysis (using effectiveDose)
        c. FormQualityService → FormQuality
           └─ if form miss → AIService → AIFormResult? → FormQuality(isAIInferred:true)
    └─ HerbalEntries passed through (no NRV calc)
    └─ ProbioticEntries passed through (no NRV calc)
    └─ RawLines passed through as unresolvedLines
    └─ ReportService assembles → LabelAnalysis
6.  ReportViewModel.loadingState = .loaded(labelAnalysis)
7.  ReportView renders LabelAnalysis
```

### Total Line Handling
When NutrientEntries include a total line (isTotalLine = true):
- Total line IS used for RDI/UL calculation
- Sub-entries with the same canonicalName are NOT used for calculation
- All entries shown in detail view for transparency
- Enforced in ReportService, not left to caller

---

## AI Integration Point

Unchanged: AI called only in FormQualityService when form string is absent
from curated form_quality.json.

What changes with LabelEntry: FormQualityService is only called for
NutrientEntry and HerbalEntry cases. ProbioticEntry has no form quality.
RawLine has no form quality until the user resolves it to a typed entry.

---

## State Ownership (Updated)

| State | Owner |
|---|---|
| Camera/scan session state | ScanViewModel |
| Raw OCR text | ScanViewModel |
| [LabelEntry] pre-confirm | ScanViewModel |
| [LabelEntry] post-confirm | ReviewViewModel |
| ServingSize (extracted) | ReviewViewModel |
| ServingSize (user-selected) | ReviewViewModel |
| Selected reference standard | @AppStorage (Settings) |
| Selected demographic | @AppStorage (Settings) |
| LabelAnalysis (current report) | ReportViewModel |
| Scan history list | HistoryViewModel |

---

## Serving Size in the Data Flow

ServingSize is extracted by ParserService from label text ("Each capsule contains",
"Per 5g serve", etc.) and attached to the ReviewViewModel state.

The user confirms or adjusts serving in ReviewView before analysis.

ServingSize.multiplier is applied in CalculationService:
    effectiveDose = entry.amount * servingSize.multiplier

The multiplier is applied once, in CalculationService only.
It is never applied in ParserService, ReportService, or anywhere else.
NutrientEntry.servingMultiplier stores the snapshot used at calculation time.

---

## Bundled Reference Data Structure

```
/Resources/ReferenceData/
├── nrv_au.json       ← NHMRC NRVs + ULs + IU conversion factors
├── nrv_us.json       ← NIH/FDA DRIs + ULs
├── nrv_eu.json       ← EFSA NRVs + ULs
├── form_quality.json ← Curated nutrient form tiers
└── aliases.json      ← Canonical name alias table (separate for independent updates)
```

---

## Navigation

NavigationStack with programmatic routing via NavigationRouter.
No hardcoded NavigationLink destinations in views.
See UI_SPEC.md for full screen map.

---

## Dependency Injection

Services instantiated in AppDependencies.swift at app entry point.
Injected via environment or initialiser.
No service locator. No global singletons except ReferenceDataService (read-only).
