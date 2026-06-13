# Deferred Tasks — explicitly requested, intentionally delayed to last

These are user-requested but flagged "NOT URGENT / can be delayed to last." Do them AFTER
the headline work (Library, OCR-display overhaul, App Intents) is shipped & green.

## D1. Share experience overhaul (premium)  — requested 2026-06-14
Current: `AnalysisView` uses `ShareLink(item: analysis.shareText)` (plain text).
Goal: make sharing genuinely valuable for BOTH the empathetic **sender** AND a **recipient who
wants actionable value** — across iMessage, Notes, Email, and social.
Design considerations to work through:
- Include the **scan image**? (rich link / image + text). Render a branded summary card image?
- What info maximises value: product name, key nutrients, %RDI peaks, UL/safety flags,
  interactions, form-quality highlights, the disclaimer, an App Store/handoff link.
- **Multiple nutrients** — summarise without a wall of text; lead with the headline (e.g.
  "12 nutrients · 2 above UL · 1 interaction"), then a tidy list. Truncate gracefully.
- Different channels want different payloads (social = image-forward; email = full text;
  Notes = structured; iMessage = rich preview). Consider a custom `Transferable` /
  `ShareLink` with multiple representations, or a rendered `ImageRenderer` summary card.
- Keep clinical honesty + always include the disclaimer.

## D2. Privacy / entitlements hygiene — requested 2026-06-14
"The app does not need location etc — request only what we need, and Xcode/Info.plist must
reflect this with reasons."
- Audit Info.plist usage-description keys: KEEP camera (NSCameraUsageDescription) + photo
  library (NSPhotoLibraryUsageDescription) — both used by ScanView. REMOVE/never-add
  location, contacts, mic, calendars, motion, etc.
- Ensure each present key has a clear, honest reason string.
- Confirm no capabilities/entitlements requested beyond what's used.

## D3. Ongoing (every task, not a final step)
- Monitor performance / lag (frame analysis on transitions), inspect for crashes.
- Use skills: swift-testing-expert (tests), swift-architecture-skill (structure),
  subagent-driven-development where a plan benefits from it.

## Also queued (from the original brief, after the above)
- Phase 3d signature motion: MeshGradient "Analyzing label…" processing state, scan→report
  transition polish, matchedGeometry nutrient row→detail. (Metal shaders DEFERRED.)
- Real app icon (capsule + scan-arc concept).
- Timeboxed: scan the TrainingData photos end-to-end, compare parsed/report display.
