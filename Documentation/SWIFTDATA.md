# NutriScan — SwiftData Design
# Skills for this document: `swiftdata-pro`, `swiftdata-expert-skill`
# Invoke `swiftdata-pro` before writing any @Model, ModelContainer, or PersistenceService code.
# Invoke `swiftdata-expert-skill` for migration plans, CloudKit compatibility, complex predicates.

## Decision Record

**Chosen: SwiftData**
Rationale: Modern API, @Observable integration, Swift-native. Instability risk
accepted — v1 scope is simple (one entity, no relationships, no complex queries).
The blast radius of SwiftData issues is contained.

**Known risks and mitigations:**

| Risk | Mitigation |
|---|---|
| SwiftData bugs in edge cases | `PersistenceService` actor isolates all SwiftData code — swap to CoreData behind the same interface if required |
| `ModelContext` threading issues | Never use `@Environment(\.modelContext)` in Views — all context access through `PersistenceService` actor |
| Migration complexity | Schema is minimal at v1 — migration risk is low. Schema versioning from day one. |
| iCloud sync instability | No CloudKit sync in v1 — eliminates the primary SwiftData instability vector |

---

## Schema

### ScanRecord
The only persistent entity in v1.

```swift
@Model
final class ScanRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var productName: String
    var referenceStandard: String      // "AU" | "US" | "EU"
    var demographicKey: String         // e.g. "adult_male_19_50"
    var reportData: Data               // archived ReportModel

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        productName: String,
        referenceStandard: String,
        demographicKey: String,
        reportData: Data
    ) {
        self.id = id
        self.createdAt = createdAt
        self.productName = productName
        self.referenceStandard = referenceStandard
        self.demographicKey = demographicKey
        self.reportData = reportData
    }
}
```

**Why `reportData: Data` and not normalised relationships?**
`ReportModel` contains complex nested types (`[NutrientAnalysis]`, `FormQuality`,
flags). Normalising this into SwiftData relationships in v1 adds schema complexity
and migration surface area with no query benefit — the report is always loaded whole.
`ReportModel` is `Codable` — archive to `Data`, unarchive on load.
Normalise in v2 only if query performance requires it.

---

## Schema Versioning — From Day One

Even with one entity, version the schema from the first line of code.
This makes future migrations possible without data loss.

```swift
enum NutriScanSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ScanRecord.self] }

    @Model
    final class ScanRecord {
        // ... as above
    }
}

typealias ScanRecord = NutriScanSchemaV1.ScanRecord

struct NutriScanMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [NutriScanSchemaV1.self]
    }
    static var stages: [MigrationStage] { [] }
}
```

**Adding v2 later (example — adding practitioner notes field):**

```swift
enum NutriScanSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    @Model
    final class ScanRecord {
        // all v1 fields +
        var practitionerNotes: String?
    }
}

// Migration stage — lightweight (new optional field, no data transform needed)
static var stages: [MigrationStage] {
    [MigrationStage.lightweight(
        fromVersion: NutriScanSchemaV1.self,
        toVersion: NutriScanSchemaV2.self
    )]
}
```

---

## ModelContainer Setup

Configured once at app entry point. Not in a View.

```swift
@main
struct NutriScanApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: ScanRecord.self,
                migrationPlan: NutriScanMigrationPlan.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            // If container fails to initialise, app cannot persist data.
            // Log the error. Fall back to in-memory container for session use.
            // Never crash on container init failure.
            container = try! ModelContainer(
                for: ScanRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                // DO NOT inject modelContainer here into environment for View use
                // PersistenceService owns the context — see below
        }
    }
}
```

---

## Context Ownership

**Rule: Views never touch ModelContext directly.**

The standard SwiftUI pattern `@Environment(\.modelContext)` and `@Query` in Views
is intentionally avoided. Reason: it binds persistence to the view layer, makes
testing impossible, and bypasses the actor isolation in `PersistenceService`.

`@Query` is the one exception — it is acceptable in `HistoryView` and `HomeView`
for read-only display of `ScanRecord` lists, because it is read-only and
SwiftUI manages the context lifecycle safely for this use case.

```swift
// ACCEPTABLE — read-only display query in View
struct HistoryView: View {
    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var records: [ScanRecord]
}

// NOT ACCEPTABLE — direct context mutation in View
struct SomeView: View {
    @Environment(\.modelContext) private var context

    func save() {
        context.insert(record)  // ← never do this
    }
}
```

All writes and deletes go through `PersistenceService`.

---

## PersistenceService Implementation

```swift
actor PersistenceService {
    private let modelContext: ModelContext

    init(container: ModelContainer) {
        // Create a new context for this actor — not the view context
        self.modelContext = ModelContext(container)
        self.modelContext.autosaveEnabled = false  // explicit saves only
    }

    func save(report: ReportModel, productName: String,
              standard: ReferenceStandard, demographic: Demographic) async throws {
        let data = try JSONEncoder().encode(report)
        let record = ScanRecord(
            productName: productName,
            referenceStandard: standard.rawValue,
            demographicKey: demographic.key,
            reportData: data
        )
        modelContext.insert(record)
        try modelContext.save()
    }

    func fetchAll() async throws -> [ScanRecord] {
        let descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate { $0.id == id }
        )
        let records = try modelContext.fetch(descriptor)
        records.forEach { modelContext.delete($0) }
        try modelContext.save()
    }

    func deleteAll() async throws {
        try modelContext.delete(model: ScanRecord.self)
        try modelContext.save()
    }
}
```

---

## Testing SwiftData

Use in-memory container for all tests — no disk I/O, no state between tests.

```swift
func makeTestContainer() throws -> ModelContainer {
    try ModelContainer(
        for: ScanRecord.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}
```

`PersistenceService` is an actor injected by initialiser — swap real container
for test container. No mocking framework needed.

---

## What the AI Must Never Do

- Never use `@Environment(\.modelContext)` to write or delete — read-only `@Query` only
- Never create `ModelContext` instances outside `PersistenceService`
- Never call `modelContext.save()` outside `PersistenceService`
- Never add relationships to `ScanRecord` without a versioned migration stage
- Never store `PersistentModel` instances across actor boundaries
- Never use `autosaveEnabled = true` — all saves are explicit
