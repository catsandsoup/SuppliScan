# NutriScan — Master Project Brief

## What This Is
A native iOS 26 app for practitioners and clinicians (and educated consumers) to
scan supplement labels via OCR, then generate a full clinical report covering
RDI%, UL%, nutrient form quality, and serving-size-adjusted dosing.
Supports mixed-content labels: nutrients, herbal extracts, and probiotics in one scan.

## Stack
Swift 6.2 · SwiftUI · SwiftData · VisionKit · PDFKit · iOS 26.0+ · iPhone only

## Current State
Pre-development. Document stack complete. Architecture decided. Ready for v1 build.

## Active Sprint
v1: single product scan → full clinical report. Multi-product stack deferred to v2.

## Agent Session Instructions
Before writing any code:
1. Read AGENTS.md (auto-read by Claude Code) and the relevant /docs/ file
2. Use apple-docs-mcp or DocumentationSearch to verify any uncertain API
3. After writing code, run checklist in /docs/AI_ANTIPATTERNS.md
4. Flag violations before presenting output
5. Build after every substantive change to confirm compilation

## Document Index
- AGENTS.md                     ← Auto-read by Claude Code / Xcode agent
- docs/PRODUCT_VISION.md        ← Full feature roadmap v1→v3, Jobs-to-be-Done
- docs/PRD.md                   ← v1 features, user flows, edge cases, scope
- docs/RELEASE_TESTING.md       ← What to test per version, how, pass criteria
- docs/ARCHITECTURE.md          ← MVVM + service layer, data flow, serving size
- docs/DATA_SCHEMA.md           ← All Swift types — START HERE for any model work
- docs/CONCURRENCY.md           ← async/await, actor, TaskGroup design
- docs/SWIFTDATA.md             ← Persistence, schema versioning
- docs/UI_SPEC.md               ← Screen-by-screen HIG mapping, summary card
- docs/CONSTRAINTS.md           ← Hard decisions, regulatory boundaries
- docs/NFR.md                   ← Non-functional requirements, craft, performance
- docs/PARSER_SPEC.md           ← OCR parsing rules, unit conversion table
- docs/ERROR_STATES.md          ← Error handling per service
- docs/BUG_REGISTER.md          ← Known failure modes — generate tests from this
- docs/PROJECT_STRUCTURE.md     ← Xcode folder and target layout
- docs/LOCALISATION.md          ← xcstrings strategy
- docs/TEST_SPEC.md             ← Unit test specifications
- docs/TEST_CORPUS.md           ← Test fixture structure and corpus guide
- docs/AI_ANTIPATTERNS.md       ← Known AI mistakes checklist
- docs/MCP_TOOLING.md           ← MCP servers and agent skills
- docs/CORPUS_INDEX.md          ← 14 real label fixtures with expected parser output

## Core Type: LabelEntry (Read Before Any Model or Service Work)
The fundamental unit of a parsed label is LabelEntry — a discriminated union:

    enum LabelEntry {
        case nutrient(NutrientEntry)    // has NRV data potential
        case herbal(HerbalEntry)        // extract/dry equivalent, no NRV
        case probiotic(ProbioticEntry)  // CFU-based, no NRV
        case unresolved(RawLine)        // parser could not classify
    }

A single scan can return all four types. All services and views must handle all cases.
NutrientEntry.amount is Optional<Double> — nil means unknown, not zero. Never coerce.

## Never Violate Without Discussion

### Clinical Accuracy
- RDI/UL calculations are deterministic, on-device, never AI-generated
- IU conversions use fixed table in PARSER_SPEC.md — no AI, no approximation
- UnitConversionService converts all .iu before CalculationService is called
- CalculationService must assert unit != .iu and throw if it receives one
- ServingMultiplier applied exactly once — in CalculationService only
- Total/summary lines (isTotalLine=true) never summed alongside sub-entries
- isAIInferred=true must survive all transformations including Codable round-trip
- LabelAnalysis.schemaVersion must be set on every write
- No therapeutic claims anywhere — descriptive language only
- Disclaimer on every report — no code path may omit it

### Data & Privacy
- All reference data bundled on-device — no remote calls for core logic
- No user health data leaves the device
- AI gap-fill sends only form string — no user, product, or health context
- Reference standard togglable — never assumed
- API keys in Keychain only

### Architecture
- Swift-only. No third-party frameworks. SF Symbols. System colours.
- Views own zero business logic — all logic in Services
- All @Observable ViewModels are @MainActor
- No DispatchQueue — structured concurrency only
- @Environment(\.modelContext) read-only (@Query) in Views
- All SwiftData writes via PersistenceService actor
- NavigationRouter owns all navigation
- All @Model classes are final

### iOS Platform Bugs to Avoid (see BUG_REGISTER.md)
- Never delete SwiftData records from View — use PersistenceService.delete(id:)
- Never use ForEach Binding init for deletable lists
- Never combine .searchable + .refreshable on same List/ScrollView (iOS 18 leak)
- Never apply .tint at NavigationStack level (alert button tint bug)
- Debounce sheet re-presentation (0.3s minimum)
- Downsample OCR input images to 2000px max before VisionKit

### UI
- All fonts via Dynamic Type styles — no hardcoded sizes
- All colours from system semantic palette — no custom hex values
- Minimum 44pt tap target on all interactive elements
- Tier indicators use colour + text — never colour alone
- All user-facing strings via xcstrings symbol keys
