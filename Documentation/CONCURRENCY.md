# NutriScan — Concurrency & Threading Design

## Model

Swift Structured Concurrency throughout. No GCD (`DispatchQueue`) calls.
No `OperationQueue`. No `DispatchQueue.main.async` wrappers.
Use `async/await`, `Task`, `actor`, and `MainActor` exclusively.

Rationale: Swift 6 concurrency model is the forward path. GCD is legacy.
Structured concurrency makes threading explicit, compiler-checked, and auditable.

---

## Threading Rules

### Rule 1: Main actor owns all UI state
Every `@Observable` ViewModel is `@MainActor`.
No ViewModel property is mutated from a background thread.

```swift
@MainActor
@Observable
class ReportViewModel {
    var report: ReportModel?
    var isLoading: Bool = false
    var error: AppError?
}
```

### Rule 2: Services are not actors by default
Services are structs or classes with no shared mutable state.
They receive inputs and return outputs — no internal state to protect.
They can be called from any context.

Exception: `PersistenceService` is an actor (see below).

### Rule 3: All async work is explicit
No fire-and-forget. Every `Task` created in a ViewModel is stored and
cancellable. ViewModels cancel active tasks on `deinit` or on new request.

```swift
@MainActor
@Observable
class ScanViewModel {
    private var scanTask: Task<Void, Never>?

    func startAnalysis(entries: [NutrientEntry]) {
        scanTask?.cancel()
        scanTask = Task {
            isLoading = true
            defer { isLoading = false }
            // async work here
        }
    }
}
```

### Rule 4: Heavy work runs off main actor explicitly
OCR processing, AI service calls, and PDF generation are off-main.
ViewModels call these services with `await` — Swift moves execution
off main actor automatically when the callee is not `@MainActor`.

```swift
// In ScanViewModel (@MainActor)
func processFrame(_ image: CGImage) async {
    isLoading = true
    // OCRService.extract is not @MainActor — runs off main automatically
    let entries = await ocrService.extract(from: image)
    // Back on MainActor here — safe to mutate state
    self.extractedEntries = entries
    isLoading = false
}
```

---

## Per-Service Concurrency Design

### OCRService
- `async` function — VisionKit request runs on background thread
- Returns `[NutrientEntry]` to caller
- No internal state — safe to call from any context

```swift
struct OCRService {
    func extract(from image: CGImage) async throws -> [NutrientEntry]
}
```

### ParserService
- Synchronous — pure text transformation, no I/O
- Fast enough to run on main thread if needed, but called from background context
- No `async` needed

```swift
struct ParserService {
    func parse(_ rawText: String) -> [NutrientEntry]
}
```

### ReferenceDataService
- Loads JSON at app launch — `async` init or explicit `load()` async method
- After load, all queries are synchronous reads on an immutable in-memory structure
- `@MainActor` not needed — read-only after init

```swift
actor ReferenceDataService {
    private var data: ReferenceData?

    func load() async throws {
        // reads bundled JSON off main thread
        data = try await Task.detached { ... }.value
    }

    func nrv(for nutrient: String, standard: ReferenceStandard,
             demographic: Demographic) -> NRVEntry?
}
```

### CalculationService
- Synchronous — pure arithmetic
- No `async` needed
- Can run anywhere

```swift
struct CalculationService {
    func calculate(entry: NutrientEntry, nrv: NRVEntry) -> NutrientCalculation
}
```

### FormQualityService
- `async` — may call AIService which is async
- Checks curated DB first (synchronous) — only goes async if miss

```swift
struct FormQualityService {
    func assess(nutrient: String, form: String) async -> FormQuality
    // sync path: curated lookup → returns immediately
    // async path: curated miss → awaits AIService
}
```

### AIService
- `async throws` — network call
- Called only from FormQualityService
- Timeout: 10 seconds. On timeout or error: returns nil, FormQualityService
  returns degraded result with isAIInferred = false, note = "Unavailable"

```swift
struct AIService {
    func inferFormQuality(nutrient: String, form: String) async throws -> AIFormResult?
}
```

### ReportService
- `async` — coordinates multiple service calls
- Runs entirely off main actor
- Returns completed `ReportModel` to ViewModel

```swift
struct ReportService {
    func generate(
        entries: [NutrientEntry],
        standard: ReferenceStandard,
        demographic: Demographic
    ) async throws -> ReportModel
}
```

**Internal concurrency — parallel nutrient analysis:**
Each nutrient can be analysed independently. Use `TaskGroup` for parallelism:

```swift
func generate(...) async throws -> ReportModel {
    var analyses: [NutrientAnalysis] = []

    try await withThrowingTaskGroup(of: NutrientAnalysis.self) { group in
        for entry in entries {
            group.addTask {
                // RDI/UL calc + form quality per nutrient — parallel
                let nrv = referenceService.nrv(for: entry.name, ...)
                let calc = calculationService.calculate(entry: entry, nrv: nrv)
                let form = await formQualityService.assess(
                    nutrient: entry.name, form: entry.form ?? ""
                )
                return NutrientAnalysis(entry: entry, calculation: calc, formQuality: form)
            }
        }
        for try await analysis in group {
            analyses.append(analysis)
        }
    }
    return ReportService.assemble(analyses: analyses, ...)
}
```

This means a 20-nutrient product runs all 20 assessments concurrently,
including any AI calls. Report generation time is bounded by the slowest
single nutrient, not the sum of all nutrients.

### PersistenceService
- `actor` — SwiftData `ModelContext` is not `Sendable`, must be confined
- All reads and writes go through this actor
- Returns `Sendable` value types to callers — never returns `ModelContext` or
  `PersistentModel` instances across the actor boundary

```swift
actor PersistenceService {
    private let modelContext: ModelContext

    func save(report: ReportModel) async throws
    func fetchAll() async throws -> [ScanRecord]
    func delete(id: UUID) async throws
}
```

### ExportService (PDF)
- `async` — PDFKit rendering is off main thread
- Returns `Data` to ViewModel, which hands to `ShareLink`

```swift
struct ExportService {
    func generatePDF(from report: ReportModel) async throws -> Data
}
```

---

## Loading State Pattern

Every async ViewModel operation follows this pattern — no exceptions:

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(AppError)
}
```

Views switch on `loadingState` — never check `isLoading` Bool + optional result
separately. This eliminates the impossible state where `isLoading = false`
and `result = nil` with no error.

---

## Cancellation

- Tasks stored as properties, cancelled on new request or view disappearance
- Use `.task {}` view modifier for tasks tied to view lifecycle —
  SwiftUI cancels these automatically on view disappearance
- Long-running tasks (AI calls) check `Task.isCancelled` at natural checkpoints

```swift
// Preferred for view-lifecycle-bound async work
.task {
    await viewModel.loadReport()
}
// SwiftUI cancels this task when the view disappears — no manual cleanup needed
```

---

## What the AI Must Never Do

- Never use `DispatchQueue` anywhere in this project
- Never mutate `@Observable` ViewModel state from outside `@MainActor`
- Never call `AIService` directly from a ViewModel — only via `FormQualityService`
- Never create an unstructured `Task` in a View — use `.task {}` modifier
- Never make `PersistenceService` a struct — it must be an actor
- Never pass `ModelContext` or `PersistentModel` across actor boundaries
