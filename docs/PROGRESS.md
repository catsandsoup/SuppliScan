# SuppliScan Redesign — Progress & Resume Handoff

> **This file is the single resume point.** A fresh session should read, in order:
> `docs/PROGRESS.md` (this) → `docs/DESIGN_SYSTEM.md` → `docs/DESIGN_AUDIT.md`, then
> `git log` on branch `redesign/premium-ui`. Everything substantive is committed — clearing
> context loses nothing.

Branch: `redesign/premium-ui` (off `main`). Goal: ADA-calibre premium UI/UX transformation
with **zero** changes to functionality, data models, or business logic.

---

## How to resume in one paragraph
We are mid-Phase-3 of a 4-phase redesign. The design system (`DesignTokens.swift`, namespace
`Theme`) and a custom component kit are built and committed. The **Liquid Glass tab bar** and
**Settings** screen are redesigned and **verified in the simulator (light+dark)**. The legacy
`AppTheme` colours are now bridged to the new palette. A DEBUG sample-data seed exists so the
**Analysis** report can be verified. **Next: redesign the Analysis report screen** (the hero),
then Review / Scan / History, then custom transitions + Metal shader + app icon, then a full
simulator verification pass. Build is green throughout; verify after every change.

---

## Status by phase
| Phase | State | Commit |
|---|---|---|
| 1 — Audit (`docs/DESIGN_AUDIT.md`) | ✅ done | `a421cbe` |
| 2 — Design system (`DesignTokens.swift`, `docs/DESIGN_SYSTEM.md`) | ✅ done | `ecb383e` |
| 3a — Core component kit | ✅ done | `6ea4372` |
| 3 — Liquid Glass tab bar + Settings (verified L/D) | ✅ done | `6b2741e` |
| 3 — AppTheme→palette bridge + DEBUG sample seed | ✅ done | (this checkpoint) |
| 3b — **Analysis report redesign (HERO)** | ⏭️ **NEXT** | — |
| 3c — Review, Scan, History, NutrientDetail | ⛒ pending | — |
| 3d — Custom transitions, Metal shader, content tint, **app icon** | ⛒ pending | — |
| 4 — Simulator verification loop (idb/ffmpeg/PIL) | ◑ tooling ready | — |

Native task list (TaskCreate IDs 1–7) mirrors this; update as you go.

---

## Design language (built — see DESIGN_SYSTEM.md for full reasoning)
Thesis: **"clinical confidence with tactile craft."** Namespace `Theme` in
`SuppliScan/SuppliScan/DesignSystem/DesignTokens.swift`:
- **Colour** `Theme.Palette` — warm dynamic surfaces, near-mono ink, ONE jade-green brand
  (`#0C7C68`/`#2FD6B6`), tier spectrum (`tier1..4`,`aiInferred`) as the only other colour, all
  light/dark + high-contrast. Ergonomic `.foregroundStyle(.brand)` / `Color.brand`.
- **Type** SF Pro prose (Dynamic-Type scalable) + **monospaced digits** for data; `.textStyle(.hero/.display/.title/.headline/.body/.callout/.subhead/.caption/.eyebrow/.stat/.dataBody)`.
- **`Theme.Space`** (4-pt grid; `.screen`=20, `.section`=28), **`Theme.Radius`** (continuous;
  `.card`=22), **`Theme.roundedRect(_)`**, **`Theme.Icon`**, **`elevation(.card/.raised/.floating)`**
  (colour-scheme adaptive), **`Animation.dsPrimary/dsSnappy/dsBouncy/dsGentle/dsMicro`** + `dsFade`.
- **Glass** `glassAction()/glassControl()` — iOS 26 Liquid Glass, **functional layer only**.

## Component kit (built — `DesignSystem/Components/`)
`dsCard()/dsSurface()/screenBackground()`, `HairlineDivider`, `DSButtonStyle`
(`.dsPrimary/.dsSecondary/.dsTertiary/.dsDestructive`) + `DSLoadingLabel`, `SectionHeader`
(eyebrow+title+trailing), `DSToggleStyle` (`.ds`), `SegmentedPicker` (sliding pill),
`DSTextFieldStyle`(`.ds`)+`DSField` (focus ring), `GlassTabBar`.

---

## VISUAL TARGET (from user's ChatGPT mockups, 2026-06-13)
The user shared mockups that match this system. Use **Image #2 "What You'll See"** as the
concrete target for the report screens:
- **Results/Analysis:** product thumb + name + "VERIFIED" → big hero verdict → **T1/T2/T3/T4
  tier-count chips** → "KEY INSIGHTS" cards (coverage, watch N nutrients, AI-inferred) →
  nutrient breakdown. Clean, card-based, data-forward.
- **Nutrient Detail:** big circular **RDI ring** (e.g. "125% of RDI"), About card, Details
  rows (RDI / Your value / % of RDI / Source).
- **Processing state:** calm generative green **MeshGradient bloom** + "Analyzing label…",
  **no spinner** → Phase 3d loading state.
- **App icon:** capsule + dashed scan-arc mark in jade/black. Candidate source images in
  `~/Downloads/` (filenames start `iphone app logo_ ... .jpg`). AppIcon is currently EMPTY
  (default) — wire one in via PIL (resize to 1024², no alpha) → `Assets.xcassets/AppIcon.appiconset`.

⚠️ **Clinical-honesty guardrail (do NOT violate):** the mockup shows "Overall RDI Score 82%".
Do **not** fabricate an averaged RDI score — averaging RDI% is meaningless (B12 is 20,833% in
the sample). Keep the mockup's *layout* but use an HONEST hero: Form Quality verdict
(High/Mixed/Poor from worst tier), real tier counts, real flags, or "X of Y nutrients in
80–200% RDI". This protects the clinical trust the product depends on.

---

## NEXT TASK — redesign the Analysis report (Phase 3b)
**Reachable as:** Analysis-tab root (`AnalysisRootView` → latest `ScanRecord`) AND pushed from
History/Review. Verify with the seed (below).

**Files (presentation only — preserve all data/router/flag logic):**
- `Features/Analysis/AnalysisView.swift` (592 lines) — scaffold + inline `ClinicalSnapshotView`,
  `SummaryTabView`, `NutrientsTabView`, `DetailsTabView`, `InteractionsTabView`, interaction rows.
- `Components/ReportSummaryCardView.swift` — make this the hero summary (verdict + tier chips +
  key-insight rows).
- `Components/NutrientAnalysisRowView.swift` — restyle row (big mono RDI%, progress bar→tokens).
- `Components/FlagBannerView.swift`, `Components/NutrientFilterBar.swift` + `FilterChip.swift`,
  `Components/TierBadgeView.swift`, `Components/DisclaimerView.swift`, `ReportSectionHeader.swift`,
  `Components/FormPotencyRowView.swift`, `Herbal/Probiotic/UnresolvedLineView` — restyle to tokens.

**Approach:**
1. Header: hide/transparent system nav bar background, keep system **Back** (pushed) + `ShareLink`;
   add in-content header — eyebrow + big product title (`displayTitle`) + meta line
   (serving · standard · demographic).
2. Hero summary card (`ReportSummaryCardView`): Form-Quality verdict (tier-coloured) + one-line
   clinical note + tier-count chips (T1..T4) + key-insight rows (UL status, low-bioavailability
   count, AI-inferred count, interactions). Tokens + `dsCard()`.
3. Internal tabs: replace segmented `Picker` with `SegmentedPicker(options: visibleTabs, ...)`;
   keep the paged `TabView` content (swipe), `Animation.dsPrimary`.
4. Replace `Color(.systemBackground)`/`secondarySystemBackground` → `dsCard`/tokens;
   `Divider()` → `HairlineDivider`; `.font(...)` → `.textStyle(...)`. (AppTheme tier colours are
   already bridged, so existing `rdiColor`/`TierBadgeView` now use the new palette.)
5. Honour Reduce Motion (already wired via `reduceMotion`).
6. Clamp Dynamic Type on hero numbers (`.dynamicTypeSize(...DynamicTypeSize.accessibility1)`).

Then **NutrientDetailView** (mockup: RDI ring + About + Details); add `matchedGeometryEffect`
on the nutrient avatar (row→detail header) in Phase 3d.

---

## Build / run / verify commands
```bash
# BUILD (always verify after edits; SourceKit cross-file "Cannot find Theme/…" diagnostics are
# STALE — only xcodebuild is authoritative)
xcodebuild -project SuppliScan/SuppliScan.xcodeproj -scheme SuppliScan -configuration Debug \
  -destination 'id=3190AB00-06F7-497C-9DD7-B6EDBD169707' -derivedDataPath /tmp/suppliscan_dd build

UDID=3190AB00-06F7-497C-9DD7-B6EDBD169707          # iPhone 17 Pro · iOS 26.0.1 (booted)
APP=/tmp/suppliscan_dd/Build/Products/Debug-iphonesimulator/SuppliScan.app
BID=montygiovenco.SuppliScan

xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryLevel 100 --batteryState charged --cellularBars 4 --wifiBars 3
xcrun simctl ui "$UDID" appearance light          # or: dark
# Launch directly to a tab (DEBUG -startTab) and seed the sample report (DEBUG -seedSample):
xcrun simctl terminate "$UDID" "$BID" 2>/dev/null
xcrun simctl launch "$UDID" "$BID" -startTab analysis -seedSample
xcrun simctl io "$UDID" screenshot --type=png /tmp/shot.png   # then Read /tmp/shot.png
# Re-seed after schema/data change: uninstall first (seed only runs when store is empty):
xcrun simctl uninstall "$UDID" "$BID"
```
- **`-startTab`** values: `scan` (default) | `analysis` | `history` | `settings` (DEBUG only).
- **`-seedSample`** inserts `SampleData.analysis` ("Advanced Multivitamin Pro": 5 nutrients,
  Zinc above UL, Magnesium low-bioavailability, 1 nutrient + 1 medication interaction) when the
  store is empty (DEBUG only). Both are no-ops in release.
- Dark-mode screenshot tip: after `appearance dark`, the first frame is the transition dim —
  take a **second** screenshot for the settled frame.

## Phase 4 tooling (ready)
- `ffmpeg`/`ffprobe`: installed. Record: `xcrun simctl io "$UDID" recordVideo /tmp/x.mov` (run in
  background; stop by killing the process).
- Python venv `/tmp/ssvenv` has **Pillow 11.3** (frame diffing) and **fb-idb**. Use
  `/tmp/ssvenv/bin/python`.
- **idb caveat:** `brew install --cask companion` ran (exit 0) but `idb_companion` path/fb-idb on
  Python 3.9 was flaky. **Preferred driving = deterministic `-startTab`/`-seedSample` launch args +
  `simctl` screenshots + `appearance` toggling** (no idb needed for static verification). Only
  pursue idb for true tap/swipe/gesture timing if needed; verify it on one tap first.
- Metal toolchain: **installed** (`xcrun -f metal` resolves). `.metal` files compile. ⚠️ Shader
  *rendering* on this x86_64 sim still UNVERIFIED — gate the first real shader behind a screenshot
  check; fallback = device ("Monty's iPhone") or lean on `MeshGradient` + Liquid Glass (no Metal).
  Liquid Glass itself IS confirmed rendering (tab bar screenshot).

## Environment
- Xcode 26.3 (17C529); **Intel Mac → x86_64 simulators.**
- Sim OS is `26.0.1` not `26.0` — destinations MUST use `id=<udid>`, not `name+OS`.

---

## Key decisions (autonomous, per "don't ask" directive)
1. Override `UI_SPEC.md` §Design Language; preserve its information architecture.
2. One brand jade-green; tier spectrum the only other colour; colour stays scarce.
3. SF Pro prose + monospaced digits for data (not a monospaced typeface).
4. `DesignTokens.swift` lives in the app source tree (synchronised folder group), not top-level
   `Sources/`.
5. Restyle stock mechanics, don't rebuild them (List/Toggle/searchable/swipe stay functional).
6. Glass = native iOS 26 Liquid Glass, functional layer only; content stays solid.
7. Custom tab bar hosts 4 NavigationStacks in a ZStack (state preserved, cross-faded).

## Things flagged for user (non-blocking)
- **`HomeView` is orphaned** (no refs outside `Features/Home/`); the live IA is 4 tabs
  (Scan/Analysis/History/Settings), no Home. The mockup imagines a Home/dashboard + a different
  tab set (Home/History/Scan/Reports/Profile) — **resurrecting/restructuring IA is a product
  decision**, deliberately NOT done. Current redesign keeps the existing 4-tab IA.
- `writing-for-interfaces` applied 4 build-verified copy fixes in Phase 1 (committed).
- `nrv_us.json`/`nrv_eu.json` are stubs but Settings advertises "NIH/FDA · EFSA" (pre-existing).

## Hard rules preserved (CLAUDE.md / AGENTS.md — never violate)
`@MainActor @Observable` view models (no ObservableObject); no `DispatchQueue`; every report keeps
`disclaimer` + `schemaVersion`; `amount: Double?` optional; all four `LabelEntry` cases handled;
all SwiftData writes via `PersistenceService`; tier colour never the sole carrier of meaning.
