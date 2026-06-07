# NutriScan — Error States Specification

## Design Principle

Every error has:
1. A typed Swift error enum case
2. A user-facing message in xcstrings
3. A defined recovery action
4. A defined visual presentation

No error is handled by crashing, showing a blank screen, or printing to console in production.
No error is silently swallowed.

---

## AppError — Top-Level Error Type

```swift
enum AppError: LocalizedError {
    // OCR
    case ocrNoTextFound
    case ocrLowConfidence(recognisedText: String)
    case ocrCameraPermissionDenied

    // Parser
    case parserNoNutrientsExtracted
    case parserPartialExtraction(unresolved: [RawLine])

    // Reference Data
    case referenceDataLoadFailed
    case referenceDataNutrientNotFound(name: String)

    // Calculation
    case calculationUnitConversionRequired(nutrient: String, unit: String)
    case calculationUnsupportedUnit(nutrient: String, unit: String)

    // Form Quality
    case formQualityAIUnavailable
    case formQualityAIResponseInvalid

    // AI Service
    case aiServiceNetworkUnavailable
    case aiServiceTimeout
    case aiServiceRateLimited
    case aiServiceResponseMalformed

    // Persistence
    case persistenceSaveFailed(underlying: Error)
    case persistenceLoadFailed(underlying: Error)
    case persistenceContainerInitFailed

    // Export
    case exportPDFGenerationFailed
    case exportShareFailed

    // General
    case unknown(underlying: Error)
}
```

---

## Per-Service Error Handling

### OCRService

| Error | Cause | User message | Recovery |
|---|---|---|---|
| `ocrNoTextFound` | Image captured but VisionKit returns no text | "No text found on label. Try better lighting or hold the camera steadier." | Retry button → back to ScanView |
| `ocrLowConfidence` | Text found but confidence below threshold | "Some text was hard to read. Please review and correct the extracted nutrients." | Proceed to ReviewView with pre-flagged fields |
| `ocrCameraPermissionDenied` | Camera permission not granted | "Camera access is needed to scan labels. Enable it in Settings." | Button → opens iOS Settings |

**Confidence threshold:** VisionKit returns per-character confidence.
Threshold for "low confidence" flag: mean word confidence < 0.85.
Do not reject — surface the extraction with review flags.
Never crash or show empty state on low confidence.

---

### ParserService

| Error | Cause | User message | Recovery |
|---|---|---|---|
| `parserNoNutrientsExtracted` | OCR text present but no nutrient lines found | "Couldn't identify any nutrients. This might not be a supplement facts panel." | Manual entry option |
| `parserPartialExtraction` | Some lines parsed, some unresolved | No error shown — ReviewView presents unresolved lines highlighted for manual correction | User corrects inline |

**Partial extraction is not an error state presented to the user.**
It is a normal operating condition. Unresolved lines appear in ReviewView
with a yellow highlight and "Needs review" label. The Analyse button
is enabled once at least one nutrient is confirmed — not blocked on full resolution.

---

### ReferenceDataService

| Error | Cause | User message | Recovery |
|---|---|---|---|
| `referenceDataLoadFailed` | Bundled JSON missing or corrupt | "Reference data failed to load. Please reinstall the app." | App remains open but scan/analyse disabled with inline notice |
| `referenceDataNutrientNotFound` | Nutrient name not in reference DB after alias lookup | Silent — report shows "No reference data" for that nutrient row | No user action needed; displayed inline |

**referenceDataLoadFailed is a catastrophic error.** It should not occur in
production (data is bundled). Log it. Disable analysis features gracefully
with a banner — do not crash.

**referenceDataNutrientNotFound is expected and common** (novel compounds, branded
ingredients, proprietary blends). Handle inline in the report, not as an error state.

---

### CalculationService

| Error | Cause | User message | Recovery |
|---|---|---|---|
| `calculationUnitConversionRequired` | IU unit reached CalculationService (should have been converted in ParserService) | Internal error — log and show "Calculation error" inline for that nutrient row | Surfaces in report as "–" with tooltip |
| `calculationUnsupportedUnit` | .unknown unit in NutrientEntry | Inline in report: "Unit not supported — manual calculation required" | User can tap to edit unit |

CalculationService errors are per-nutrient, not per-report.
A calculation error on one nutrient does not block the rest of the report.

---

### FormQualityService / AIService

| Error | Cause | User message | Recovery |
|---|---|---|---|
| `formQualityAIUnavailable` | Network offline | Inline in tier cell: "AI lookup unavailable — manual review" | No recovery needed; offline graceful degradation |
| `formQualityAITimeout` | AI API call exceeds 10s | Same as unavailable | No recovery needed |
| `formQualityAIRateLimited` | API rate limit hit | Same as unavailable | Retry on next scan |
| `formQualityAIResponseMalformed` | Unparseable AI response | Same as unavailable | Log the raw response for debugging |

**All AI service errors degrade to the same display state:**
`isAIInferred = false`, tier = nil, cell shows "Form not in database — manual review required"
in subdued text. Purple "AI" badge is NOT shown — only shown for successful inferences.

AI errors are never presented as error dialogs. They are inline degradation only.

---

### PersistenceService

| Error | Cause | User message | Recovery |
|---|---|---|---|
| `persistenceContainerInitFailed` | SwiftData container fails on launch | Silent fallback to in-memory container. Banner: "History unavailable — storage error. Scans won't be saved this session." | App remains functional; saving disabled |
| `persistenceSaveFailed` | Save throws after report generation | Toast: "Report couldn't be saved. It's still available this session." | Report remains in memory; user can export PDF immediately |
| `persistenceLoadFailed` | Fetch throws on history load | Inline in HistoryView: "History couldn't be loaded. Try closing and reopening." | Retry button in HistoryView empty state |

Persistence failures must never block report generation or viewing.
The report is always shown; saving is secondary.

---

### ExportService

| Error | Cause | User message | Recovery |
|---|---|---|---|
| `exportPDFGenerationFailed` | PDFKit rendering throws | Toast: "PDF couldn't be created. Try again." | Retry via share button |
| `exportShareFailed` | ShareLink / system share sheet fails | Toast: "Sharing failed. Try again." | Retry |

---

## Error Presentation Patterns

### Toast (transient, non-blocking)
For: save failures, export failures.
Duration: 3 seconds. No user action required.
Position: bottom of screen, above tab bar.
SwiftUI: custom overlay via `.overlay` on root view, driven by @Observable error state.

### Inline degradation (in-report)
For: nutrient-level errors (unit unknown, reference not found, AI unavailable).
Presentation: "–" or subdued explanatory text in the relevant cell.
No modal, no toast. User can proceed.

### Full-screen empty state (blocking, recoverable)
For: OCR no text found, parser no nutrients extracted.
Presentation: ContentUnavailableView with icon, message, action button.

### Banner (persistent, dismissible)
For: reference data load failure, persistence container failure.
Position: below navigation bar.
Persists until session ends. Not dismissible if it affects core functionality.

### Settings redirect
For: camera permission denied only.
Button opens app Settings via UIApplication.openSettingsURLString.

---

## Error Logging

All errors logged via os.Logger (not print()).
Never log user health data — log only error type, service name, and timestamp.

```swift
import OSLog

extension Logger {
    static let nutriscan = Logger(subsystem: "com.yourname.nutriscan", category: "errors")
}

// Usage
Logger.nutriscan.error("PersistenceService save failed: \(error.localizedDescription)")
```

Never log in release builds beyond os.Logger — no third-party crash/analytics SDK
that transmits data without explicit user consent.
