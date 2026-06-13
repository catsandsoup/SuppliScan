# SuppliScan Redesign — Progress

Branch: `redesign/premium-ui` · Started 2026-06-13 · Goal: ADA-calibre premium UI/UX
transformation, no functional/data/logic changes.

## Status by phase
| Phase | State | Notes |
|---|---|---|
| 1 — Audit | ✅ done · committed | `docs/DESIGN_AUDIT.md` |
| 2 — Design system | ✅ done · committing | `DesignTokens.swift` + `docs/DESIGN_SYSTEM.md`, build green |
| 3a — Core components | ⏳ next | custom Button/Toggle/segmented/card/field/tab bar/header |
| 3b — Analysis (hero screen) | ⛒ pending | full vertical slice + sim verify before replicating |
| 3c — Home/Scan/Review/History/Settings | ⛒ pending | |
| 3d — Transitions / shaders / theming | ⛒ pending | matchedGeometry, scan→report reveal, content tint |
| 4 — Sim verification loop | ⛒ pending | idb + ffmpeg + PIL frame analysis |

## Working approach (per advisor)
**Go vertical, not horizontal.** tokens → core components → Analysis built AND verified
end-to-end in sim → then replicate the pattern to the other screens. One fully-realised,
verified slice beats 14 half-touched screens.

## Key decisions (made autonomously, per "don't ask" directive)
1. **Override `UI_SPEC.md` §Design Language**; preserve its information architecture. The
   old spec's "system colours only / Form / List" is the source of the generic look the
   brief says to escape.
2. **One brand colour** — clinical jade-green (nods to the green Apple-logo motif). Tier
   spectrum is the only other semantic colour; colour stays scarce.
3. **SF Pro prose + monospaced *digits* for data** — instrument-grade tabular figures
   without the developer-tool feel of a monospaced typeface.
4. **`DesignTokens.swift` lives in the app source tree** (`SuppliScan/SuppliScan/DesignSystem/`),
   not a top-level `Sources/` — the Xcode project uses synchronised folder groups rooted at
   the app folder, so only files under it compile. Same intent, correct location.
5. **Restyle stock mechanics, don't rebuild them** — system rule so functionality
   (swipe/search/edit/VoiceOver/keyboard) is never regressed.
6. **Glass = native iOS 26 Liquid Glass, functional layer only.** Content stays solid.

## Environment / tooling
- Xcode 26.3 (17C529); **Intel Mac — simulators are x86_64.**
- Build: `xcodebuild -project SuppliScan/SuppliScan.xcodeproj -scheme SuppliScan -configuration Debug -destination 'id=3190AB00-06F7-497C-9DD7-B6EDBD169707' -derivedDataPath /tmp/suppliscan_dd build`
- Sim: **iPhone 17 Pro · iOS 26.0.1** · UDID `3190AB00-06F7-497C-9DD7-B6EDBD169707` (booted).
  Note OS is `26.0.1` not `26.0` — destination must use `id=`, not `name+OS`.
- Metal toolchain: **installed** Phase 2 (`xcodebuild -downloadComponent MetalToolchain`,
  704 MB). `.metal` files now compile.
- `ffmpeg`/`ffprobe`: present. `brew`: present.

## Open gates / to-resolve
- **Shader render verification** — toolchain compiles MSL, but whether `colorEffect`/
  `layerEffect` actually *render* on this x86_64 26.0.1 simulator is UNVERIFIED. Gate: build
  the first real shader (Phase 3d) behind a screenshot check; fallback = verify on the
  connected device ("Monty's iPhone") and/or lean on `MeshGradient` + Liquid Glass (no
  Metal). Do not ship a shader-dependent transition without this check.
- **Phase 4 tooling** — `idb`/`idb_companion` not installed (`brew install idb-companion`
  + `pip install fb-idb`); Python `PIL` missing (`pip3 install Pillow`, likely in a venv —
  system python is externally managed). Install when Phase 4 starts.
- **Content-derived theming** — retune `AppTheme.nutrientAvatarBackground` hues into the new
  palette's saturation range when wiring header tint (Phase 3d).

## Decisions needing user review
- None blocking. The design direction is documented in `DESIGN_SYSTEM.md`; flagging now so
  the user can redirect before Phase 3 implementation hardens it if they wish.
