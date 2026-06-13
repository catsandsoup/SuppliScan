# SuppliScan — Design System (Phase 2)

> The reasoned companion to `Sources → SuppliScan/SuppliScan/DesignSystem/DesignTokens.swift`.
> Every decision below is justified against *this* app's purpose and users, not generic
> "clean minimalism." Benchmarks: **Apple Wallet, Flighty, Linear, Craft, Arc Search,
> Apple Invites.**

---

## 0. Thesis — "clinical confidence with tactile craft"

SuppliScan is a clinical instrument used in two opposite emotional moments: a practitioner
making a fast decision, and an anxious beginner wanting a trustworthy verdict. The design
must feel **precise, quiet, and data-forward** like a medical device, while having the
**depth, motion, and tactility** that make a premium app feel alive and reassuring.

This rules out the two easy directions:
- **Not** playful wellness (gradient soup, mascots) — it would destroy clinical trust.
- **Not** austere developer-tool minimalism (the app's current state) — trustworthy but
  forgettable, and it flattens the dual-layer hierarchy the product needs.

The system below is the disciplined middle: a near-monochrome ink palette on warm
surfaces, one signature jade-green, the tier spectrum as the only other colour, and a
single coherent motion language. Restraint everywhere so the **data** and the **verdict**
are the heroes — with craft in the details (springs, glass chrome, choreographed reveals)
that you feel but never notice.

---

## 1. Colour system

### Reasoning
The product's own `UI_SPEC.md` mandated "system colours only." That guaranteed dark-mode
and contrast correctness but produced a generic Settings-app look and **zero identity**.
The new brief explicitly authorises custom colour. So the system introduces exactly **one**
brand colour and otherwise stays near-monochrome — the Linear discipline. Colour is
*scarce*, which makes the one place it appears (a verdict, an action) meaningful.

Why **jade-green** as the brand: it nods to the green of the original six-colour Apple
logo referenced in `CLAUDE.md`, reads as "health/vitality" without tipping into wellness
kitsch, and is far enough from the tier-green that the two never collide semantically
(brand = identity/interaction; tier-green = "this nutrient is fine"). It is defined as a
deep jade in light mode and a brighter mint in dark mode so it stays legible and lively on
both surfaces.

Why **warm** surfaces (#F6F5F2, not pure #FFFFFF): pure white reads as a form/spreadsheet.
A hair of warmth (Craft, Invites) makes long clinical reading calmer and lets pure-white
**cards** lift off the background as tactile objects (Wallet passes).

### Tokens (`Theme.Palette`, all dynamic light/dark + high-contrast branch)
| Role | Token | Light | Dark |
|---|---|---|---|
| App background | `surface` | `#F6F5F2` warm off-white | `#0B0B0C` near-black |
| Cards / sheets | `surfaceRaised` | `#FFFFFF` | `#171719` |
| Wells / fields | `surfaceSunken` | `#EDEBE6` | `#060607` |
| Overlays | `surfaceOverlay` | `#FFFFFF` | `#202023` |
| Primary text | `ink` | `#16181C` | `#F4F4F5` |
| Secondary text | `inkSecondary` | `#5B6068` | `#A6A7AD` |
| Captions / units | `inkTertiary` | `#8B909A` | `#6C6D74` |
| Placeholder / disabled | `inkFaint` | `#B6BAC2` | `#46474D` |
| **Brand** | `brand` | `#0C7C68` | `#2FD6B6` |
| Brand pressed | `brandPressed` | `#0A6657` | `#27B89C` |
| Brand tinted fill | `brandMuted` | jade @12% | mint @16% |
| On-brand text | `onBrand` | `#FFFFFF` | `#05140F` |
| Hairline | `hairline` | ink @8% | white @10% |

### Tier safety spectrum (the ONLY other semantic colour)
Refined, slightly desaturated vs the stock `.system*` colours for a more clinical read,
with high-contrast variants. **Never the sole carrier of meaning** — always paired with a
text label (`T1`–`T4`, "Within range", etc.), satisfying the existing accessibility rule
and colour-blind users.

| Tier | Meaning | Light | Dark |
|---|---|---|---|
| `tier1` | high / safe | `#1F9D57` | `#44D17E` |
| `tier2` | caution-low | `#BE8400` amber* | `#F0B73D` |
| `tier3` | caution-high | `#D2692A` | `#FF9F5A` |
| `tier4` | critical | `#CC463B` | `#FF6B5E` |
| `aiInferred` | AI-inferred | `#6E56CF` violet | `#AB9CF2` |

\* deliberately amber, not pure system yellow — yellow fails contrast on white and looks
unclinical.

**Rule:** no other hues anywhere. Nutrient avatar hues (inherited from `AppTheme`) are the
one sanctioned exception — they're identity chips for individual nutrients, not status, and
will be retuned to sit within this palette's saturation range during migration.

---

## 2. Typography system

### Typeface decision — SF Pro (text) + monospaced **digits** for data
- **Prose: SF Pro, proportional.** Not SF Rounded (reads consumer/playful — wrong for a
  clinical tool), not a monospaced typeface for letters (reads developer-tool — explicitly
  on the "avoid" list), not New York serif (editorial, but undermines instrument
  precision). SF Pro is neutral, precise, and gives free Dynamic Type + optical sizing.
- **Data: SF Pro with `.monospacedDigit()`.** The whole product is numbers — RDI%, UL%, mg,
  CFU, dates. Monospaced *digits* give Flighty/Linear-grade tabular alignment (columns of
  figures line up, values don't jitter when animating) **without** the techy feel of a
  monospaced typeface. This is the key typographic move and the reason data tables will
  feel "instrument-grade."

### Scale (named; prose styles scale with Dynamic Type)
| Token | Base style | Weight | Tracking | Use |
|---|---|---|---|---|
| `display` | largeTitle | semibold | −0.5 | screen heroes (Home wordmark, product name) |
| `title` | title2 | semibold | −0.3 | card / section titles |
| `headline` | headline | semibold | −0.2 | row primary (nutrient name) |
| `body` | body | regular | 0 | content, rationale |
| `callout` | callout | regular | 0 | secondary content |
| `subhead` | subheadline | medium | 0 | labels |
| `caption` | caption | regular | 0 | captions, units |
| `eyebrow` | caption2 | semibold | +0.8 | UPPERCASE section eyebrows |
| `hero` | 46pt fixed | light | −1.0 | the **one** big number per screen · mono digits |
| `stat` | 24pt fixed | regular | −0.4 | secondary stats · mono digits |
| `dataBody` | body | regular | 0 | inline data · mono digits |

### Hierarchy rules
- **One `hero` number per screen, maximum.** Big + *light* weight = confident, not heavy
  (the design-principles rule: elegance comes from large-but-light, not large-and-bold).
- Weights restrained to **light / regular / medium / semibold**. No bold/heavy/black —
  semibold is the top of the ladder. Hierarchy comes from size + colour + space, not weight
  escalation.
- `eyebrow` is the only uppercase style; it labels sections like a clinical form field
  without a heavy `Section` header.
- Apply via `.textStyle(.headline)` (sets font + tracking + case in one call).

### Dynamic Type
Prose styles are built on semantic `Font.TextStyle`s → they scale automatically. The two
fixed "data hero" sizes (`hero`, `stat`) are clamped at their call sites
(`.dynamicTypeSize(...DynamicTypeSize.accessibility1)`) so a giant accessibility size can't
break a hero-number layout while everything else still scales. Verified in Phase 4.

---

## 3. Spacing & layout

- **Base grid: 4 pt.** Allowed steps: 2, 4, 8, 12, 16, 20, 24, 32, 48 (`Theme.Space`).
  The audit found drift (5, 6, 10, 14, 70) once code left the old `AppTheme.Spacing`;
  every migrated screen snaps to this grid.
- **Screen horizontal margin: 20 pt** (`Space.screen`). Generous and editorial (Linear),
  more breathing room than the iOS-default 16. Nothing touches the screen edge.
- **Section rhythm: 28 pt** (`Space.section`) between major report sections — clinical
  readability, whitespace as structure.
- **Card internal padding: 16–20 pt.** Never the 4-pt-vertical cramping the audit flagged.
- **Min tap target: 44 pt** everywhere (HIG), enforced on custom controls.
- No max content width (iPhone-only app).

---

## 4. Component language

- **Corner radius: 22 pt continuous** for content cards (`Radius.card`) — larger and
  squircle-smooth, the Wallet/Craft "object" feel, deliberately bigger than the system
  10-pt grouped-list radius we're moving away from. Smaller controls use 12–16 pt; pills
  use full-capsule. **Only continuous corners** (`Theme.roundedRect`).
- **Buttons** (custom `ButtonStyle`, built Phase 3a): height 52 (primary) / 44 (secondary);
  16-pt horizontal padding; `.headline` label; states — default, pressed (scale 0.97 +
  `brandPressed`, `dsMicro` spring), disabled (`inkFaint` on `surfaceSunken`), loading
  (inline custom indicator, label fades, width held). Primary = brand fill + `onBrand`;
  secondary = `brandMuted` fill + `brand` text; tertiary = text-only.
- **Cards / cells:** `surfaceRaised` fill, 22-pt continuous, `hairline` 1-px stroke
  (the stroke does the "edge definition" work in dark mode where shadows vanish),
  `elevation(.card)` in light mode. No gradients on standard cards.
- **Inputs:** `surfaceSunken` fill, 14-pt radius, `hairline` stroke that animates to
  `brand` on focus; `inkFaint` placeholder; 44-pt min height.
- **Navigation bar:** stock bar **hidden**; replaced by a compact custom header (eyebrow +
  display title + trailing action) that scrolls with content, plus a Liquid-Glass floating
  back affordance where needed. No `.navigationTitle` chrome.
- **Tab bar:** custom **Liquid-Glass** floating bar (functional layer) — see §6.

### Critical rule — *restyle stock mechanics, don't rebuild them*
"Zero stock aesthetics" must not regress functionality (swipe-to-delete, `.searchable`,
edit mode, VoiceOver, keyboard avoidance). So: keep the stock *mechanism*, make it
*invisible as stock*. `List` → `.listStyle(.plain)` + `.listRowBackground(.clear)` +
hidden separators + custom row cells + custom `.swipeActions`. `Toggle`/`Picker` → custom
`ToggleStyle`/segmented control that still drive the same bindings. This is a system-level
rule, not a per-screen choice, so the redesign never drifts into reimplementing UIKit.

---

## 5. Surface & material system

- **Backgrounds are flat tinted colour**, layered in three levels (sunken → surface →
  raised → overlay). Flat, not blurred, for the **content** layer — blur on content reduces
  legibility, which is unacceptable for clinical data (and violates the iOS 26 Liquid-Glass
  HIG rule that glass is a functional-layer material only).
- **Glass is reserved for chrome** (tab bar, floating scan action, transient overlays) —
  §6.
- **Content-derived colour (Wallet/Music move):** scan-history rows and the report header
  tint subtly from the scanned product's **dominant nutrient** (via the existing
  `AppTheme.nutrientAvatarBackground` mapping, retuned). This gives each scan a quiet
  identity without a photo, and ties the report visually to its subject. Implemented as a
  low-alpha wash behind the header, never strong enough to fight the data. (Phase 3d.)
- **Shadow philosophy:** subtle ambient elevation in **light** mode (`elevation(.card/.raised/.floating)`);
  in **dark** mode shadows are near-invisible, so depth comes from lighter surface fills +
  hairline borders. The `elevation` modifier adapts automatically by colour scheme.

---

## 6. Liquid Glass (iOS 26, functional layer only)

Native `.glassEffect(_:in:)` / `GlassEffectContainer` / `glassEffectID` — not hand-rolled
blur stacks. Per Apple HIG, glass belongs to the **functional** layer and never to content.
Applications in SuppliScan:
- **Custom tab bar** — a floating glass pill; the selected tab morphs via `glassEffectID`
  inside a `GlassEffectContainer`.
- **Floating scan action** — brand-tinted interactive glass (`glassAction`), the app's
  signature control.
- **Transient overlays** — toasts, the OCR "reading…" badge, the back affordance.
Centralised tint/shape in `DesignTokens` (`glassAction`, `glassControl`) so glass reads
consistently. Content cards stay solid.

---

## 7. Iconography

- **SF Symbols only.** Weight **matched to adjacent type** (`.medium` default, `.semibold`
  for emphasis) so icons sit on the same visual weight as their label — the audit found all
  symbols at default weight, flat against semibold text.
- **Hierarchical / palette rendering** for the few "hero" symbols (scan, tier shield) to
  add depth; monochrome elsewhere for restraint.
- Sizes from `Theme.Icon` (xs 12 → xl 40), one size per context. Symbols are always
  supplementary to text, never the sole communicator (clinical + a11y rule).

---

## 8. Motion language

One spring vocabulary (`Animation.ds*`), specific response/damping — never the opaque
`.bouncy`/`.smooth` presets, so the whole app moves with one physical character.

| Spring | response | damping | Use |
|---|---|---|---|
| `dsPrimary` | 0.42 | 0.82 | navigation, sheets, large spatial moves — settled, no overshoot |
| `dsSnappy` | 0.30 | 0.80 | buttons, toggles, selection — crisp |
| `dsBouncy` | 0.48 | 0.66 | emphasis (scan capture, success) — a touch of overshoot/life |
| `dsGentle` | 0.58 | 0.92 | content entrances / reveals — smooth, no overshoot |
| `dsMicro` | 0.22 | 0.86 | press states, chips |

- **Durations** (fades only): `dsFadeQuick` 0.18, `dsFade` 0.26.
- **Curves:** entrance = ease-out, exit = ease-in, state = ease-in-out.
- **Stagger:** 0.05 s step for sequential entrances (`Theme.Motion.stagger`) — the report's
  cards/flags cascade in.
- **Hero/spatial transitions:** `matchedGeometryEffect` for elements that appear in two
  contexts (nutrient avatar: row → detail header; scan thumb → review). Where a stock
  navigation animation can't carry the moment (scan→report reveal), a bespoke transition /
  Metal shader (§9) is used.
- Honour **Reduce Motion**: springs collapse to a quick cross-dissolve; no parallax.

---

## 9. Metal / GPU effects (justified, gated)

Custom MSL is a *delighter*, not the foundation — the premium feel stands on Liquid Glass,
`MeshGradient`, `Canvas`, and the spring system above. Shaders are added only where they
**meaningfully** improve a moment, and only after verifying they render on the target
simulator (Metal toolchain installed Phase 2; render-verification gated into Phase 3d/4):
- **Scan → report reveal:** a brief refraction/"develop" transition as the analysed report
  resolves — the one signature, memorable moment (Arc Search's choreographed unfold).
- **Generative report-header wash:** a slow `MeshGradient` (no Metal needed) tinted by the
  product's dominant nutrient; optional shader shimmer on success.
- **Empty/loading states:** lightweight `colorEffect` shimmer instead of a stock spinner.
Heavy/gratuitous effects are explicitly rejected — clinical trust first.

---

## 10. What this replaces / preserves
- **Replaces:** `UI_SPEC.md` §Design Language (system-colours-only, Form/List aesthetic).
- **Preserves:** `UI_SPEC.md` information architecture (scroll order, section contents,
  dual-layer hierarchy), all data models, business logic, and the `CLAUDE.md` hard rules
  (disclaimer/schemaVersion always; `amount` optional; all four `LabelEntry` cases; writes
  via `PersistenceService`; `@MainActor` `@Observable` view models; tier colour never alone).
- **Migration:** legacy `AppTheme` stays compiling until each screen moves to `Theme`;
  removed once unreferenced.
