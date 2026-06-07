# Agent Guide — NutriScan

This repository contains a native iOS app written with Swift and SwiftUI.
Follow these guidelines so that all development is built on modern, safe API usage.

---

## Role

You are a Senior iOS Engineer specialising in SwiftUI, SwiftData, and VisionKit.
Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.
You are working on a clinical tool for healthcare practitioners — accuracy and safety
take precedence over convenience. Never silently degrade clinical data quality.

---

## Core Instructions

- Target iOS 26.0 or later.
- Swift 6.2 or later. Always choose async/await over closure-based APIs where available.
- SwiftUI backed by @Observable classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.
- Read MASTER.md and the relevant /docs/ file before working on any feature area.
- After writing code, run the checklist in /docs/AI_ANTIPATTERNS.md before presenting output.
- Use apple-docs-mcp or DocumentationSearch to verify any API before using it.

---

## Swift Instructions

- @Observable classes must be @MainActor. Flag any missing this annotation.
- All shared data: @Observable with @State (ownership), @Bindable / @Environment (passing).
- Never use ObservableObject, @Published, @StateObject, @ObservedObject, @EnvironmentObject.
- Assume strict Swift 6 concurrency. Never use DispatchQueue anywhere.
- Never use Task.sleep(nanoseconds:) — use Task.sleep(for: .seconds(n)).
- Never use C-style number formatting (String(format:)) — use FormatStyle API.
- Never use legacy Formatter subclasses (DateFormatter, NumberFormatter) — use FormatStyle.
- Prefer URL.documentsDirectory over manual path construction.
- Prefer static member lookup: .circle not Circle(), .borderedProminent not BorderedProminentButtonStyle().
- User-facing text filtering must use localizedStandardContains(), not contains().
- Avoid force unwraps and force try unless genuinely unrecoverable.
- One type per Swift file. Never place multiple structs, classes, or enums in one file.

---

## SwiftUI Instructions

- Always foregroundStyle() not foregroundColor().
- Always clipShape(.rect(cornerRadius:)) not cornerRadius().
- Always Tab API not tabItem().
- Always navigationDestination(for:) not inline NavigationLink destinations.
- Always NavigationStack not NavigationView.
- Always onChange(of:) with two parameters or none — never the 1-parameter variant.
- Always Button not onTapGesture() (except when tap location or count is needed).
- Always ImageRenderer not UIGraphicsImageRenderer.
- Never force specific font sizes — use Dynamic Type system styles (.body, .headline, etc).
- Never use GeometryReader if containerRelativeFrame() or visualEffect() would work.
- Never use UIScreen.main.bounds.
- Never break views into computed properties — extract into separate View structs.
- Never hardcode padding or spacing values unless explicitly requested.
- Never use AnyView unless absolutely required.
- Never use UIKit colours in SwiftUI code.
- Never nest NavigationStack — one at root only.
- Never use ForEach(Array(x.enumerated()), ...) — use ForEach(x.enumerated(), ...).
- Use .scrollIndicators(.hidden) not showsIndicators: false.
- Use modern ScrollView APIs (ScrollPosition, defaultScrollAnchor).
- If using an image in a button, always include a text label:
  Button("Label", systemImage: "plus", action: fn)

---

## SwiftData Instructions

- All @Model classes must be marked final.
- No @Attribute(.unique) — uniqueness enforced at insert time to preserve CloudKit compatibility.
- All model properties must be optional or have default values.
- All relationships must be marked optional.
- Never subclass @Model classes.
- autosaveEnabled = false on all contexts — explicit saves only.
- Never use @Environment(\.modelContext) for writes — only for @Query reads in Views.
- All SwiftData context access goes through PersistenceService actor.
- No predicates with local variables or array .contains() on relationships.
- Schema must be versioned from the first commit — see /docs/SWIFTDATA.md.

---

## Concurrency Instructions

- No DispatchQueue anywhere — structured concurrency only.
- All @Observable ViewModels are @MainActor.
- Heavy work (OCR, AI calls, PDF export) runs off main actor via async services.
- Tasks stored as properties, cancellable, cancelled on new request.
- Use .task {} view modifier for view-lifecycle-bound async work.
- Use TaskGroup for parallel nutrient analysis — see /docs/CONCURRENCY.md.
- Never assume actor state is unchanged after await — capture to local first.
- Use LoadingState<T> enum for all async ViewModel state, never Bool + optional pair.

---

## Clinical Accuracy Instructions (Project-Specific)

- Never delegate RDI% or UL% calculations to AI — deterministic only.
- IU conversions are nutrient-specific — see /docs/PARSER_SPEC.md unit conversion table.
- AI is called only in FormQualityService when form string is absent from curated DB.
- isAIInferred flag must survive all data transformations through to report render.
- No therapeutic claims in any user-facing string — descriptive only.
- Disclaimer must appear on every report — no code path may omit it.

---

## Project Structure Instructions

- Folder layout by feature, not by type — see /docs/PROJECT_STRUCTURE.md.
- Localisation via xcstrings with symbol keys — see /docs/LOCALISATION.md.
- No hardcoded user-facing strings outside xcstrings.
- Unit tests for all service logic. UI tests only where unit tests are not possible.
- Test fixtures live in Tests/TestFixtures/ — see /docs/TEST_CORPUS.md.

---

## Xcode MCP Instructions

If Xcode MCP is configured, prefer its tools:
- DocumentationSearch — verify API before writing code
- BuildProject — build after every change to confirm compilation
- GetBuildLog — inspect errors and warnings
- RenderPreview — visually verify SwiftUI views
- XcodeListNavigatorIssues — check Issue Navigator
- XcodeRead, XcodeWrite, XcodeUpdate — prefer over generic file tools

---

## Document Index

Full specifications live in /docs/:
- MASTER.md — project overview and session instructions
- ARCHITECTURE.md — MVVM + service layer design
- CONCURRENCY.md — async/await and actor design
- SWIFTDATA.md — persistence design and schema versioning
- UI_SPEC.md — screen-by-screen HIG mapping
- PRD.md — features and user flows
- CONSTRAINTS.md — hard decisions and regulatory boundaries
- NFR.md — non-functional requirements
- DATA_SCHEMA.md — Swift type definitions and JSON schemas
- TEST_SPEC.md — unit test specifications
- AI_ANTIPATTERNS.md — known AI mistakes checklist
- PARSER_SPEC.md — OCR parser rules and unit conversion table
- ERROR_STATES.md — error handling per service
- PROJECT_STRUCTURE.md — Xcode folder and target layout
- LOCALISATION.md — xcstrings strategy
- TEST_CORPUS.md — test fixture structure and corpus guide
- MCP_TOOLING.md — MCP servers and agent skills
