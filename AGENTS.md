# SuppliScan — Codex Auto-Read File

This file is loaded automatically by Codex at session start.
Read this before touching code, then read the project docs listed below.

---

## What This Project Is

**SuppliScan** — A native iOS 26 app for scanning supplement labels via OCR
and generating clinical reports for healthcare practitioners.
Stack: Swift 6.2 · SwiftUI · SwiftData · VisionKit · PDFKit · iOS 26.0+ · iPhone only

Role: act as a senior iOS engineer. Build for clinical correctness, Apple HIG
quality, Swift 6.2 strict concurrency, and App Review readiness. Do not add
third-party frameworks without asking.

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

Keep `/Users/monty/.codex/SKILL_INDEX.md` current. Before implementation work,
infer the task domain from the repo docs, file paths, imported frameworks, and
the user request. Load the matching write skill without waiting for the user to
name it. After writing code, run the matching audit or review skill.

Use the global skill locations first:

- `/Users/monty/.codex/skills/`
- `/Users/monty/.agents/skills/`

### Read BEFORE writing code in each domain

| Domain | Read this file first |
|---|---|
| Any service or architecture decision | `/Users/monty/.codex/skills/swift-architecture-skill/SKILL.md` |
| SwiftUI architecture decision | `/Users/monty/.codex/skills/axiom-swiftui-architecture/SKILL.md` |
| Any async service, actor, TaskGroup | `/Users/monty/.codex/skills/swift-concurrency-pro/SKILL.md` |
| Sendable, data race, actor isolation | `/Users/monty/.codex/skills/swift-concurrency-expert/SKILL.md` |
| Any public API, type signature, enum | `/Users/monty/.codex/skills/swift-api-design-guidelines-skill/SKILL.md` |
| Any SwiftUI View or component | `/Users/monty/.codex/skills/swiftui-pro/SKILL.md` |
| SwiftUI layout / UI patterns | `/Users/monty/.codex/skills/swiftui-ui-patterns/SKILL.md` |
| SwiftUI performance | `/Users/monty/.codex/skills/swiftui-performance-audit/SKILL.md` |
| Any @Model, ModelContainer, migration | `/Users/monty/.agents/skills/swiftdata-pro/SKILL.md` |
| SwiftData audit | `/Users/monty/.codex/skills/axiom-audit-swiftdata/SKILL.md` |
| Any test file | `/Users/monty/.codex/skills/swift-testing-pro/SKILL.md` |
| Number/date formatting for display | `/Users/monty/.codex/skills/swift-format-style/SKILL.md` |
| Any security / Keychain / network | `/Users/monty/.codex/skills/swift-security-expert/SKILL.md` |
| Accessibility on any view | `/Users/monty/.codex/skills/swiftui-accessibility-auditor/SKILL.md` |
| HIG / Liquid Glass review | `/Users/monty/.agents/skills/hig-macos/SKILL.md` and `/Users/monty/.codex/skills/axiom-liquid-glass/SKILL.md` |
| Code review before commit | `/Users/monty/.codex/skills/ios-code-audit/SKILL.md` |
| iOS Simulator interaction | `/Users/monty/.codex/skills/ios-simulator-skill/SKILL.md` |
| Docs, summaries, commits, comments | `/Users/monty/.codex/skills/stop-slop/SKILL.md` |

---

## Current Build State

**Layer 1–4: COMPLETE. BUILD SUCCEEDED.**

| Layer | Status | Files |
|---|---|---|
| 1 — Models | ✅ Complete | 18 Swift model files in Models/ |
| 2 — Persistence | ✅ Complete | SuppliScanSchema.swift, PersistenceService.swift |
| 3 — Navigation | ✅ Complete | AppDestination.swift, NavigationRouter.swift |
| 4 — App entry + stubs | ✅ Complete | SuppliScanApp.swift, AppDependencies.swift, 5 stub views |
| 5 — Services | ⚠️ Not started (JSON data files created) | TBD |
| 6 — Full Views | 🔲 Not started | TBD |
| 7 — Components | 🔲 Not started | TBD |
| 8 — Tests | 🔲 Not started | TBD |

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
- The app uses SwiftData as its persistence API. Do not add direct Core Data
  APIs (`NSManagedObject`, `NSPersistentContainer`, `.xcdatamodeld`) unless the
  user explicitly approves a persistence migration.
- SwiftData sits on Core Data internally, so Core Data audits may be used as a
  lower-level safety check. The primary persistence audit is still
  `swiftdata-pro` + `swiftdata-expert-skill`.
- The app target uses default MainActor isolation. Pure value types, Codable
  models, deterministic services, and utility extensions that run outside UI
  must opt out with `nonisolated`. SwiftUI Views and ViewModels stay MainActor.
- `CalculationService` MUST assert `unit != .iu` — throw if it receives one
- `ServingMultiplier` applied exactly once, in CalculationService only
- `isAIInferred = true` only set by AIService — never by curated lookup
- `LabelAnalysis.disclaimer` on every report — no code path may omit it
- `LabelAnalysis.schemaVersion` set on every write
- `amount: Double?` is Optional — nil means unknown, never coerce to 0.0
- Never use `@Attribute(.unique)` on ScanRecord — CloudKit compatibility
- All SwiftData writes via PersistenceService actor — never from Views
- Herbal, Probiotic, Nutrient, RawLine — all four LabelEntry cases must be handled
- Use MVVM at the SwiftUI screen boundary. Use Clean Architecture-style service
  and data boundaries underneath. Use MVI-style explicit state only for complex
  screens that need state/action discipline.
- Use native SwiftUI controls and system semantic colors. Recompile/run on iOS
  26 before judging Liquid Glass. Do not add custom glass/material backgrounds
  to content rows or cards.
- Test with `ios-simulator-skill` when visual, accessibility, navigation, or
  launch proof matters. Prefer accessibility-tree navigation when IDB is
  installed; otherwise use `simctl` screenshots and Xcode test logs.

---

## Swift Rules

- Use async/await APIs over closure-based APIs whenever Apple provides both.
- Prefer modern Swift and Foundation APIs: `URL.documentsDirectory`,
  `appending(path:)`, and `String.replacing(_:with:)`.
- Use FormatStyle for display and parsing. Do not add `DateFormatter`,
  `NumberFormatter`, `MeasurementFormatter`, or `String(format:)`.
- Use `localizedStandardContains()` for user-facing text search.
- Avoid force unwraps and force `try` unless the failure is unrecoverable and
  documented at the call site.

---

## SwiftUI Rules

- Use native SwiftUI controls, `NavigationStack`, and `navigationDestination(for:)`.
- Own shared observable state with `@State`; pass it with `@Bindable` or
  `@Environment`.
- Place screen logic in testable ViewModels or services.
- Use `foregroundStyle()`, `clipShape(.rect(cornerRadius:))`, the `Tab` API,
  `.scrollIndicators(.hidden)`, and modern scroll-position APIs.
- Use `Button` for taps. Use `onTapGesture()` only when location or tap count is
  part of the interaction.
- Use `Task.sleep(for:)`, not `Task.sleep(nanoseconds:)`.
- Do not use `UIScreen.main.bounds`.
- Avoid `AnyView`, hard-coded font sizes, UIKit colors, and old UIKit rendering
  APIs. Prefer Dynamic Type and `ImageRenderer`.
- Break large views into new `View` structs, not computed view properties.
- Use accessible image buttons: include text with `Button(_:systemImage:action:)`
  or an explicit accessibility label.
- Avoid `GeometryReader` when `containerRelativeFrame()` or `visualEffect()` can
  solve the layout.

---

## Project Hygiene

- Use feature folders for screens and keep one primary type per Swift file.
- Write unit tests for core logic. Add UI tests only when unit tests cannot cover
  the behavior.
- Do not commit secrets or API keys.
- If string catalogs are introduced, add user-facing strings through
  `Localizable.xcstrings` with stable symbol keys.
- If Xcode MCP is configured, prefer it for API documentation lookup, build
  execution, build logs, previews, issues, and Xcode project edits.

---

## Bundle ID
`montygiovenco.SuppliScan`

## Target
iOS 26.0+, Swift 6.2, iPhone only, no third-party frameworks
