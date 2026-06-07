# NutriScan — Non-Functional Requirements

## Performance

### NFR-P1: OCR response time
OCR extraction must complete within 3 seconds on an iPhone 12 or newer
on a standard supplement facts panel under normal lighting conditions.

### NFR-P2: Report generation time
From confirmed nutrient list to rendered report must complete within 1 second
for products with up to 30 nutrients. AI gap-fill calls are async and must not
block report rendering — show inferred fields as loading, populate when ready.

### NFR-P3: App launch time
Cold launch to scan-ready state within 2 seconds. Reference data loads
asynchronously — app is usable before load completes, with graceful loading state.

### NFR-P4: Main thread
All network calls, file I/O, SwiftData reads/writes, and AI service calls
must be off the main thread. UI must never freeze or stutter.

### NFR-P5: Point-of-purchase speed (Value Seeker job)
Camera open → summary card visible: ≤ 8 seconds on iPhone 12 in normal lighting.
This is a hard user-facing target, not a developer goal.
Rationale: a user comparing two products at a chemist shelf will not wait longer.
Measurement: timed manually at Gate 3 acceptance testing on a physical device.
If this target is not met, OCR pipeline and report generation must be profiled
and optimised before TestFlight — not after.

---

## Reliability

### NFR-R1: Offline operation
All core functionality (scan, calculate, report, history) must work with
no network connection. AI gap-fill degrades gracefully — if no connectivity,
form quality shows "Form not in database — manual review required."

### NFR-R2: OCR failure handling
If OCR returns no usable data, present a clear error state with option to
enter nutrients manually. Never crash or show a blank screen.

### NFR-R3: Calculation determinism
Given the same inputs and reference standard, RDI% and UL% calculations
must return identical results every time. No floating point inconsistency
in displayed values — round to 1 decimal place for display.

---

## Security & Privacy

### NFR-S1: No health data leaves device
Label scan data, extracted nutrients, and report content are never transmitted
to any external server. AI gap-fill calls send only the nutrient form string —
no user, product, or health context is included in the payload.

### NFR-S2: No analytics or tracking
No third-party analytics SDK. No crash reporting service that transmits data
without explicit consent. If crash reporting is added, it must be opt-in.

### NFR-S3: No API keys in source
Any AI service API key must be stored in the Keychain, not in source code,
Info.plist, or UserDefaults.

---

## Data Integrity

### NFR-D1: Reference data immutability
Bundled JSON reference data is read-only at runtime. No code path may write
to or modify reference data files.

### NFR-D2: Curated tier precedence
If a nutrient form exists in form_quality.json, the curated tier is always used.
The AI service is never called for a nutrient form that has a curated entry.
This must be enforced in FormQualityService, not left to caller discipline.

### NFR-D3: AI inference flagging
Every nutrient form assessment that originates from AI inference must carry
isAIInferred: true in the data model. This flag must survive all data
transformations through to the report render. It must never be lost or defaulted to false.

---

## Accessibility

### NFR-A1: Dynamic Type
All text must support Dynamic Type — no hardcoded font sizes.

### NFR-A2: VoiceOver
Report table must be navigable via VoiceOver with meaningful accessibility labels.
Tier indicators (colour-coded) must have text alternatives.

---

## Maintainability

### NFR-M1: Reference data updateability
Updating NRV/UL values for a new NHMRC edition must require only a JSON file
replacement — no code changes. JSON schema must be stable.

### NFR-M2: New nutrient form addition
Adding a new form tier entry must require only a JSON edit — no code changes.

---

## Craft & Polish

### NFR-C1: Haptic feedback
Meaningful haptic feedback at key moments — not decorative.
Required moments:
- Scan completes successfully: `.notificationFeedback(.success)`
- Analysis complete (report appears): `.notificationFeedback(.success)`
- UL exceeded flag triggered: `.notificationFeedback(.warning)`
- Swipe-to-delete confirmed: `.impactFeedback(.medium)`
- Error state: `.notificationFeedback(.error)`
Implementation: `UIFeedbackGenerator` subclasses via a `HapticService`.
Never trigger haptics from a View — always via ViewModel → HapticService.

### NFR-C2: Animations
Transitions must feel intentional, not default.
Required:
- Report appears: slide up from bottom with spring, not default push
- Summary card loads: fade in after a 0.15s delay (gives content time to compute)
- Expandable row: smooth height animation, not abrupt snap
- Flag banners: slide down into view when flags exist, not instant appearance
- Tier badge: brief scale pulse on first render (draws eye to quality indicator)
All animations use SwiftUI's `.animation(.spring())` or `.transition()`.
Never use `.linear` timing for user-facing animations.
Never animate layout-affecting properties on the main thread during calculation.

### NFR-C3: Empty states are designed, not default
Every empty state has: an SF Symbol, a heading, a brief explanation, an action.
ContentUnavailableView is the correct SwiftUI component (iOS 17+).
Never show a blank screen or a plain "No data" label.

### NFR-C4: Loading states are informative
`.task {}` async operations show a skeleton or `ProgressView` while loading.
Never show a blank area where content will appear.
For ReportView specifically: summary card renders first with skeleton rows
below — report sections populate progressively as analysis completes.

### NFR-C5: Dark mode is designed, not inverted
All colours from semantic system palette — automatic dark mode compliance.
Review every screen in both light and dark mode before TestFlight.
Tier badge colours (systemGreen, systemOrange etc.) are tested in both modes.

---

## Image Capture

### NFR-I1: OCR input image downsampling
VisionKit input image must be downsampled to maximum 2000px longest edge
before passing to VNRecognizeTextRequest.
Rationale: prevents jetsam kill under memory pressure on dense label scans.
Implementation: CGImageSourceCreateThumbnailAtIndex before OCR pipeline.
Test: OCRService with full-resolution iPhone 15 Pro image — peak memory ≤ 150MB.

### NFR-I2: Glare detection and guidance
If mean OCR confidence < 0.75 on capture, show guidance before showing results:
"Some text was hard to read. Try tilting the label slightly to reduce glare."
Do not block the user — show the low-confidence result with review flags.
The user can proceed or retake.
