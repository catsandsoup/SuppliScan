# SuppliScan — Claude Code Auto-Read File

This file is loaded automatically by Claude Code at session start.
Read this before touching any code. Then read AGENTS.md for full rules.

---

## What This Project Is

**SuppliScan** — A native iOS 26 app for scanning supplement labels via OCR
and generating clinical reports for healthcare practitioners.
Stack: Swift 6.2 · SwiftUI · SwiftData · VisionKit · PDFKit · iOS 26.0+ · iPhone only

---

## Read These First (Every Session)

1. `AGENTS.md` — full coding rules, SwiftUI/SwiftData/Concurrency constraints, skill table
2. `MASTER.md` — project brief, clinical accuracy rules, data flow overview
3. `DATA_SCHEMA.md` — all Swift types — START HERE for any model or service work
4. `ARCHITECTURE.md` — service graph, data flow, dependency rules
5. `CONCURRENCY.md` — async/await, actor, TaskGroup design
6. `PARSER_SPEC.md` — OCR parsing rules, IU conversion table (hardcoded — no AI)

Full doc index is in MASTER.md.

---

## Skills — Auto-Read Before Writing Code

70 Swift/iOS skills are globally installed. **Before writing code in any domain below,
use the `Read` tool to load the corresponding SKILL.md and follow its guidance.**
No user action needed — Claude Code reads them automatically.

### Skills base directory
```
/Users/montygiovenco/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/987dc791-29de-48c2-bcdb-fbe07a2f37db/d3d9148d-84d8-47a2-95d6-367844f6e89b/skills/
```
(referred to below as `$SKILLS/`)

### Read BEFORE writing code in each domain

| Domain | Read this file first |
|---|---|
| Any service or architectural decision | `$SKILLS/swift-architecture-skill/SKILL.md` |
| Any async service, actor, TaskGroup | `$SKILLS/swift-concurrency-pro/SKILL.md` |
| Sendable, data race, actor isolation | `$SKILLS/swift-concurrency-expert/SKILL.md` |
| Any public API, type signature, enum | `$SKILLS/swift-api-design-guidelines-skill/SKILL.md` |
| Any SwiftUI View or component | `$SKILLS/swiftui-pro/SKILL.md` |
| SwiftUI layout / UI patterns | `$SKILLS/swiftui-ui-patterns/SKILL.md` |
| SwiftUI performance | `$SKILLS/swiftui-performance-audit/SKILL.md` |
| Any @Model, ModelContainer, migration | `$SKILLS/swiftdata-pro/SKILL.md` |
| Any test file | `$SKILLS/swift-testing-pro/SKILL.md` |
| Number/date formatting for display | `$SKILLS/swift-format-style/SKILL.md` |
| Any security / Keychain / network | `$SKILLS/swift-security-expert/SKILL.md` |
| Accessibility on any view | `$SKILLS/swiftui-accessibility-auditor/SKILL.md` |
| Code review before commit | `$SKILLS/ios-code-audit/SKILL.md` |
| iOS Simulator interaction | `$SKILLS/ios-simulator-skill/SKILL.md` |

All 70 installed skills are listed in AGENTS.md § Installed Skills Reference.

---

## Current Build State

**BUILD SUCCEEDED. Parser hardened against real-world OCR. Services not yet wired.**

| Layer | Status | Notes |
|---|---|---|
| 1 — Models | ✅ Complete | 18 Swift model files in Models/ |
| 2 — Persistence | ✅ Complete | SuppliScanSchema.swift, PersistenceService.swift |
| 3 — Navigation | ✅ Complete | AppDestination.swift, NavigationRouter.swift |
| 4 — App entry + UI shell | ✅ Complete | All Views, ViewModels, Components built |
| 5 — ParserService | ✅ Hardened | Two-column merge, herbal detection, probiotic abbreviations, isEquivalentContinuation fixed |
| 6 — Reference Data JSON | ⚠️ Not written | Data sourced in HANDOFF_REFERENCE_DATA.md — needs nrv_au.json |
| 7 — ReportService | ❌ Not started | Uses LabelAnalysis.placeholder — shows "Pending" UI |
| 8 — FormQualityService | ❌ Not started | |
| 9 — Tests | ⚠️ Partial | Parser tests use hand-crafted strings; no real Vision output fixtures |

## Next Session — Pick Up From

Read `Documentation/HANDOFF_PARSER_AUDIT.md` for exact remaining parser work.
Read `Documentation/HANDOFF_REFERENCE_DATA.md` for Phase 1 reference data (nrv_au.json).

**Highest immediate value: write nrv_au.json from HANDOFF_REFERENCE_DATA.md.**
This unblocks ReportService → AnalysisView → the app showing real clinical data.

---

## ⚠️ Skill-Review Required — All Layer 1–4 Files

ALL code in Layers 1–4 was written without skill validation (skills were not available).
The next agent MUST audit these files with the relevant skills before continuing.

See `HANDOFF.md` for the exact per-file audit checklist.

---

## Critical Rules (Never Violate)

- `@Observable` ViewModels must be `@MainActor`
- Never use ObservableObject / @Published / @StateObject / @EnvironmentObject
- No DispatchQueue anywhere — structured concurrency only
- `CalculationService` MUST assert `unit != .iu` — throw if it receives one
- `ServingMultiplier` applied exactly once, in CalculationService only
- `isAIInferred = true` only set by AIService — never by curated lookup
- `LabelAnalysis.disclaimer` on every report — no code path may omit it
- `LabelAnalysis.schemaVersion` set on every write
- `amount: Double?` is Optional — nil means unknown, never coerce to 0.0
- Never use `@Attribute(.unique)` on ScanRecord — CloudKit compatibility
- All SwiftData writes via PersistenceService actor — never from Views
- Herbal, Probiotic, Nutrient, RawLine — all four LabelEntry cases must be handled

---

## Bundle ID
`montygiovenco.SuppliScan`

## Target
iOS 26.0+, Swift 6.2, iPhone only, no third-party frameworks
