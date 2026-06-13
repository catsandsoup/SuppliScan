# RESUME — read this FIRST after any context compaction/clear

**Job:** redesign SuppliScan's UI to Apple-Design-Award quality **without breaking any logic,
data model, or behaviour.** Mid Phase 3. Branch `redesign/premium-ui`. Everything is committed
except what's under **IN-FLIGHT** below. Do **not** code from memory — use the exact API names here.

---

## P0 — MUST KNOW / DO NOT BREAK
- **SourceKit lies.** Cross-file diagnostics like "Cannot find 'Theme'/'textStyle' in scope" are
  STALE indexing noise. **Only `xcodebuild` is truth.** Never "fix" code based on those.
- **Build (the only verification of compile):**
  ```bash
  xcodebuild -project SuppliScan/SuppliScan.xcodeproj -scheme SuppliScan -configuration Debug \
    -destination 'id=3190AB00-06F7-497C-9DD7-B6EDBD169707' -derivedDataPath /tmp/suppliscan_dd build \
    > /tmp/b.log 2>&1; grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" /tmp/b.log | sort -u
  ```
- **Commit after EVERY file/unit that compiles.** Never leave large uncommitted work — that is the
  only thing compaction can strand. `git add <specific files>` (never `-A`: user has intentional
  `Current States Debug/.../debug-ocr/*` deletions that are NOT ours — leave them).
- **Hard rules (CLAUDE.md / AGENTS.md):** `@MainActor @Observable` view models; no
  ObservableObject/@Published; no `DispatchQueue`; every report keeps `disclaimer` +
  `schemaVersion`; `amount: Double?` stays optional; handle all 4 `LabelEntry` cases
  (Nutrient/Herbal/Probiotic/RawLine); all SwiftData writes via `PersistenceService`; tier colour
  **never** the sole carrier of meaning (pair with text).
- **Scope:** presentation only. Don't touch ViewModels, @Query wiring, camera/OCR, persistence.

## IN-FLIGHT TASK (keep this section current)
- **Phase 3b — redesign the Analysis report.** Reachable: Analysis tab (`AnalysisRootView` → latest
  ScanRecord) AND pushed from History/Review.
- **Done & committed:** design system, component kit, Liquid Glass tab bar, Settings (verified L/D),
  AppTheme→palette bridge, DEBUG `-seedSample`.
- **In progress (files being restyled to tokens — check `git status`):** `Components/FilterChip.swift`,
  `Components/ReportSummaryCardView.swift` (→ honest verdict + tier counts), `Components/NutrientAnalysisRowView.swift`,
  `Components/FlagBannerView.swift`, `Components/ReportSectionHeader.swift`, `Components/DisclaimerView.swift`,
  `Features/Analysis/AnalysisView.swift` (scaffold: header + snapshot + SegmentedPicker tabs).
- **After Analysis:** `Features/Analysis/NutrientDetailView.swift` (mockup: RDI ring + About + Details),
  then Review, Scan refine, History (Phase 3c); then transitions/shader/app-icon (3d); then sim pass (4).
- **Verify Analysis:** `xcrun simctl uninstall <udid> montygiovenco.SuppliScan` (clears store) → install
  → `xcrun simctl launch <udid> montygiovenco.SuppliScan -seedSample -startTab analysis` → screenshot → Read it.

---

## P1 — DESIGN SYSTEM API (use these EXACT names — file: `DesignSystem/DesignTokens.swift`, namespace `Theme`)
- **Colour** — `Theme.Palette.X` and `.foregroundStyle(.X)`/`Color.X`/`.fill(.X)`:
  `surface surfaceRaised surfaceSunken surfaceOverlay ink inkSecondary inkTertiary inkFaint brand
  brandPressed brandMuted onBrand hairline hairlineStrong` + `Theme.Palette.tier1..tier4`,
  `Theme.Palette.aiInferred`, `Theme.Palette.scrim`. (Tier/aiInferred are Palette-only, not on `.foregroundStyle(.)`.)
- **Type** — `.textStyle(_)`: `.display .title .headline .body .callout .subhead .caption .eyebrow`
  (prose, Dynamic-Type), `.hero .stat .dataBody .dataLabel` (monospaced digits). Sets font+tracking+case.
- **Space** — `Theme.Space.`: `xxs(2) xs(4) sm(8) md(12) lg(16) xl(24) xxl(32) xxxl(48) screen(20) section(28)`.
- **Radius** — `Theme.Radius.`: `xs(8) sm(12) md(16) card(22) lg(28) pill`. Shape: `Theme.roundedRect(r)` (continuous).
- **Elevation** — `.elevation(.card/.raised/.floating/.none)` (adapts to colour scheme).
- **Motion** — `Animation.`: `dsPrimary(.42/.82) dsSnappy(.30/.80) dsBouncy(.48/.66) dsGentle(.58/.92)
  dsMicro(.22/.86) dsFade dsFadeQuick`; `Theme.Motion.stagger == 0.05`.
- **Icon** — `Theme.Icon.`: `xs(12) sm(16) md(20) lg(28) xl(40)` (use as SF Symbol `.font(.system(size:weight:))`).
- **Components** (`DesignSystem/Components/`): `.dsCard(padding:radius:elevation:)`, `.dsSurface(radius:elevation:)`,
  `.screenBackground()`, `HairlineDivider(leadingInset:)`, `.buttonStyle(.dsPrimary/.dsSecondary/.dsTertiary/.dsDestructive)`,
  `DSLoadingLabel(title:systemImage:isLoading:)`, `SectionHeader(eyebrow:title:){ trailing }`,
  `.toggleStyle(.ds)`, `SegmentedPicker(options:selection:){ label }`, `.textFieldStyle(.ds)` / `DSField(placeholder:text:)`,
  `GlassTabBar(items:selection:)`, `.glassAction(in:)` / `.glassControl(in:)`.
- **Legacy bridge:** `AppTheme.Color.tier1..4 / rdiSafe/Warning/Danger / success/warning/critical/unresolved`
  now point at `Theme.Palette` — existing call sites already look correct; migrate opportunistically.

## P1 — SIM / VERIFY (exact)
```bash
UDID=3190AB00-06F7-497C-9DD7-B6EDBD169707   # iPhone 17 Pro · iOS 26.0.1 (booted). MUST use id=, OS is 26.0.1 not 26.0
APP=/tmp/suppliscan_dd/Build/Products/Debug-iphonesimulator/SuppliScan.app ; BID=montygiovenco.SuppliScan
xcrun simctl install "$UDID" "$APP"
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryLevel 100 --batteryState charged --cellularBars 4 --wifiBars 3
xcrun simctl ui "$UDID" appearance light          # or dark (after switching, take a 2nd screenshot — 1st is the transition dim)
xcrun simctl terminate "$UDID" "$BID" 2>/dev/null
xcrun simctl launch "$UDID" "$BID" -startTab analysis -seedSample   # -startTab scan|analysis|history|settings (DEBUG); -seedSample seeds when store empty (DEBUG)
xcrun simctl io "$UDID" screenshot --type=png /tmp/s.png            # then Read /tmp/s.png
# Re-seed after data change: xcrun simctl uninstall "$UDID" "$BID"  (seed only runs when store empty)
```
- Tooling ready: `ffmpeg`/`ffprobe`; venv `/tmp/ssvenv` (Pillow 11.3 + fb-idb). idb companion flaky — prefer
  `-startTab`/`-seedSample` + `simctl` for verification. Metal toolchain installed (`.metal` compiles); shader
  *rendering* on this x86_64 sim still UNVERIFIED — gate first shader behind a screenshot. Liquid Glass DOES render.

---

## P2 — REDESIGN STATUS
| Screen | State |
|---|---|
| Tab bar (GlassTabBar) | ✅ done, verified L/D |
| Settings | ✅ done, verified L/D |
| **Analysis report** | 🛠️ in progress (this task) |
| NutrientDetail | ⛒ next (RDI ring per mockup) |
| Review | ⛒ |
| Scan | ⛒ (already decent; refine + tokens + capture→review transition) |
| History | ⛒ (Wallet-style cells; keep .searchable/swipe/edit) |
| Home | ⏸️ ORPHANED in nav graph (no refs outside Features/Home/) — IA change is a product call; left as-is |

## P2 — VISUAL TARGET + CLINICAL-HONESTY GUARDRAIL
- Target = user's ChatGPT mockups (2026-06-13): Results screen = product header → hero verdict →
  **T1/T2/T3/T4 tier-count chips** → "Key Insights" cards; Nutrient Detail = big **RDI ring** + About + Details;
  Processing = calm `MeshGradient` bloom + "Analyzing label…", **no spinner**.
- ⚠️ **DO NOT fabricate an "Overall RDI Score %".** Averaging RDI% is meaningless (B12 sample = 20,833%).
  Hero must be HONEST: Form-Quality verdict (High = worst tier ≤2, Mixed = tier3, Poor = tier4), real tier
  counts, real flags. This protects clinical trust — the product's whole value.

## P3 — LATER / NICE-TO-HAVE
- **App icon** (currently EMPTY default): capsule + dashed scan-arc mark, source JPGs in `~/Downloads/`
  (`iphone app logo_…jpg`). Resize to 1024² (no alpha) via `/tmp/ssvenv/bin/python` + PIL → `Assets.xcassets/AppIcon.appiconset`.
- **Metal shader** for scan→report reveal + MeshGradient processing bloom (Phase 3d; verify render first).
- **Content-derived tint** (Wallet/Music): retune `AppTheme.nutrientAvatarBackground` into palette range, wash report header by dominant nutrient.
- **matchedGeometryEffect** nutrient avatar row→detail header.
- Docs: `docs/DESIGN_SYSTEM.md` (reasoning), `docs/DESIGN_AUDIT.md` (audit), `docs/PROGRESS.md` (narrative).
