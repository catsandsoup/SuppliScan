# NutriScan — Project Structure

## Xcode Project Layout

```
NutriScan/
├── AGENTS.md                          ← Agent instructions (project root)
├── MASTER.md                          ← Session context
├── docs/                              ← All specification documents
│
├── NutriScan.xcodeproj
│
├── NutriScan/                         ← Main app target
│   ├── App/
│   │   ├── NutriScanApp.swift         ← @main entry point, container init
│   │   └── AppDependencies.swift      ← Service instantiation + DI
│   │
│   ├── Features/
│   │   ├── Scan/
│   │   │   ├── ScanView.swift
│   │   │   └── ScanViewModel.swift
│   │   ├── Review/
│   │   │   ├── ReviewView.swift
│   │   │   └── ReviewViewModel.swift
│   │   ├── Report/
│   │   │   ├── ReportView.swift
│   │   │   └── ReportViewModel.swift
│   │   ├── History/
│   │   │   ├── HistoryView.swift
│   │   │   └── HistoryViewModel.swift
│   │   └── Settings/
│   │       └── SettingsView.swift
│   │
│   ├── Components/                    ← Reusable View components
│   │   ├── NutrientRowView.swift
│   │   ├── TierBadgeView.swift
│   │   ├── AIInferredBadgeView.swift
│   │   ├── FlagBannerView.swift
│   │   ├── ScanHistoryRowView.swift
│   │   ├── EmptyStateView.swift
│   │   ├── DemographicPickerView.swift
│   │   ├── StandardPickerView.swift
│   │   └── ErrorToastView.swift
│   │
│   ├── Services/
│   │   ├── OCRService.swift
│   │   ├── ParserService.swift
│   │   ├── ReferenceDataService.swift
│   │   ├── CalculationService.swift
│   │   ├── FormQualityService.swift
│   │   ├── AIService.swift
│   │   ├── ReportService.swift
│   │   ├── PersistenceService.swift
│   │   └── ExportService.swift
│   │
│   ├── Models/
│   │   ├── NutrientEntry.swift
│   │   ├── NutrientAnalysis.swift
│   │   ├── ReportModel.swift
│   │   ├── FormQuality.swift
│   │   ├── ReferenceStandard.swift
│   │   ├── Demographic.swift
│   │   ├── AppError.swift
│   │   └── LoadingState.swift
│   │
│   ├── Persistence/
│   │   ├── NutriScanSchema.swift      ← Versioned SwiftData schema
│   │   └── ScanRecord.swift           ← @Model class
│   │
│   ├── Navigation/
│   │   ├── NavigationRouter.swift
│   │   └── AppDestination.swift
│   │
│   ├── Resources/
│   │   ├── ReferenceData/
│   │   │   ├── nrv_au.json
│   │   │   ├── nrv_us.json
│   │   │   ├── nrv_eu.json
│   │   │   ├── form_quality.json
│   │   │   └── aliases.json
│   │   ├── Assets.xcassets
│   │   └── Localizable.xcstrings
│   │
│   └── Utilities/
│       ├── Logger+NutriScan.swift
│       └── Bundle+ReferenceData.swift
│
└── NutriScanTests/                    ← Test target (Swift Testing)
    ├── Services/
    │   ├── ParserServiceTests.swift
    │   ├── CalculationServiceTests.swift
    │   ├── FormQualityServiceTests.swift
    │   ├── ReferenceDataServiceTests.swift
    │   ├── ReportServiceTests.swift
    │   └── PersistenceServiceTests.swift
    ├── Models/
    │   └── UnitConversionTests.swift
    ├── Helpers/
    │   ├── TestContainer.swift        ← In-memory SwiftData container
    │   └── MockAIService.swift        ← AIService mock for FormQuality tests
    └── TestFixtures/
        ├── Labels/                    ← Label image corpus (PNG)
        ├── ParsedLabels/              ← Expected parser output (JSON)
        └── FormQuality/               ← Novel form strings + expected tiers
```

---

## Target Configuration

### Main Target: NutriScan
- Bundle ID: `com.[yourname].nutriscan`
- Deployment target: iOS 26.0
- Swift version: 6.2
- Supported destinations: iPhone only
- Main actor isolation: enabled (new project default in Swift 6.2)

### Test Target: NutriScanTests
- Host application: NutriScan
- Swift Testing framework: enabled (not XCTest — project uses Swift Testing)
- Test plan: NutriScan.xctestplan

---

## Swift Package Dependencies

None at project start. All functionality via Apple frameworks:
- SwiftUI
- SwiftData
- VisionKit
- PDFKit
- OSLog
- Foundation

If a dependency is needed later, it is added via Swift Package Manager only.
No CocoaPods. No Carthage.

---

## Build Settings

### Debug
- SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG
- DEBUG_INFORMATION_FORMAT: dwarf-with-dsym

### Release
- SWIFT_ACTIVE_COMPILATION_CONDITIONS: (empty)
- ENABLE_TESTABILITY: NO
- SWIFT_OPTIMIZATION_LEVEL: -O

### Both
- SWIFT_STRICT_CONCURRENCY: complete
- SWIFT_VERSION: 6.2
- IPHONEOS_DEPLOYMENT_TARGET: 26.0
- TARGETED_DEVICE_FAMILY: 1 (iPhone only)

---

## File Naming Conventions

- Views: `[Feature]View.swift` — e.g. `ReportView.swift`
- ViewModels: `[Feature]ViewModel.swift` — e.g. `ReportViewModel.swift`
- Services: `[Name]Service.swift` — e.g. `CalculationService.swift`
- Models: descriptive noun — e.g. `NutrientEntry.swift`, `AppError.swift`
- Tests: `[TestedType]Tests.swift` — e.g. `ParserServiceTests.swift`
- One type per file, always.

---

## What the AI Must Not Do

- Never create a flat structure with all files at the root level
- Never place multiple types in one file
- Never add a Pods/ directory or Podfile
- Never add a Cartfile
- Never add Package.swift to the main target (it's an Xcode project, not a package)
- Never add a UITests target unless explicitly requested
- Never target below iOS 26.0
