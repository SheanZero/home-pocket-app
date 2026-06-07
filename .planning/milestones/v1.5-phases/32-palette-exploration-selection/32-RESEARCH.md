# Phase 32: Palette Exploration & Selection - Research

**Researched:** 2026-06-01
**Domain:** Color-system design exploration + Pencil (.pen) mockup production + ADR authoring (NO production code)
**Confidence:** HIGH (constraints, semantic-role taxonomy, reference mining, ADR mechanics) / MEDIUM (Pencil MCP exact workflow — tool not directly callable from this agent context, see Open Questions)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 Brand anchor:** Keep coral primary `#E85A4F` (or a recognizably coral hue) present in ALL 4–5 schemes as a brand-memory point. Everything else (background, ledger accents, auxiliary, semantic) IS explorable, including cooler/more-neutral variants. The middle path — not "primary can change", not "Wa-Modern variations only".
- **D-02 Dual-ledger contrast:** 日常 (Daily) and 悦己 (Joy) accents MUST read as a clear visual contrast (Daily = calm/cool/neutral; Joy = warm/bright) — NOT analogous like the current blue↔green. Tasteful, no garish clash. **Hard pass/fail dimension for every scheme.**
- **D-03 No Joy celebration:** Joy is visually distinct/warmer but schemes MUST NOT introduce celebration-style affordances (glow, pulse, sparkle, milestone color-pop). Consistent with ADR-016 §5 100%-behavior contract (ambient state only, no discrete event). `joy_celebration_overlay` is NOT a license to amplify.
- **D-06 Reference sources:** Mine VoltAgent/awesome-design-md brand DESIGN.md set AND dual-ledger family-finance context. No brand bias pre-locked — weigh cool-minimal AND warm-neutral against the 家庭财务 + 双轨 + 和风 context. (PALETTE-01.)
- **D-07 Pencil deliverable:** Each of 4–5 schemes rendered across THREE screens (home hero, transaction list, analytics) in BOTH light and dark. Each scheme defines primary + 日常/悦己 accents + surface + semantic roles.
- **D-08 Selection output:** Selection allows one scheme outright OR a named hybrid. Selected palette + final hex for EVERY semantic role recorded in **ADR-018**.

### Claude's Discretion
- **D-04 Warm-coexistence axis (UNLOCKED):** Coral-primary (warm) vs Joy-accent (warm) tension is an exploration axis. The 4–5 schemes MUST span genuinely different resolutions, e.g.: (a) coral demoted to pure action color (FAB/CTA only) + Joy in a separate warm family (gold/amber/orange); (b) Joy as a coral-family bright tint distinguished by lightness/saturation not hue; (c) other planner-devised resolutions.
- **D-05 Daily-tone axis (UNLOCKED):** "日常偏冷静中性" spans two ends the scheme set must cover: (a) continued cool blue/teal (continuity with `#5A9CC8`); OR (b) true neutral gray/slate (makes Joy's warmth pop hardest).
- **Number of schemes:** target 4–5; at least 4 *genuinely distinct* directions required. Planner decides 4 vs 5.
- **Accessibility floor:** apply WCAG default to every palette — body/label text ≥ 4.5:1, large text/UI ≥ 3:1. Flag any role that cannot meet it.
- **No mid-exploration coarse-screen checkpoint** — produce all 4–5 and present together for single final selection (unless planner finds a strong reason to stage).
- **Pencil mechanics** (one `.pen` doc vs several, frame layout, side-by-side arrangement) are planner/executor's call — no `.pen` file exists yet, create fresh.

### Deferred Ideas (OUT OF SCOPE)
- **THEME-V2-01** Runtime theming / user-selectable accent palettes — v1.5 picks exactly ONE palette.
- **THEME-V2-02** Full dark-mode rollout beyond profile screens — dark mockups are for evaluation only, NOT a v1.5 ship commitment.
- **Typography / spacing / component redesign** — out of scope. If mined references surface type/layout ideas, capture but do not act.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PALETTE-01 | Mine brand DESIGN.md (VoltAgent/awesome-design-md) + dual-ledger family-finance context → synthesize candidate directions (mood, primary, dual-ledger accents) with rationale | §Reference Mining (verified hex from 7 brands) + §Candidate Directions (5 synthesized directions, each naming primary/Daily/Joy/surface stance + D-04/D-05 position + lineage) |
| PALETTE-02 | 4–5 distinct full color-scheme proposals — each defining primary + 日常/悦己 accents + surface + semantic — rendered as Pencil mockups of home hero / transaction list / analytics for side-by-side comparison | §Semantic-Role Taxonomy (complete role list) + §Pencil Workflow (doc/frame structure, variables, rendering 3×2 per scheme) + §Candidate Directions |
| PALETTE-03 | User reviews schemes, selects one (or named hybrid); decision + final hex recorded as ADR | §ADR-018 Structure (sections, hex-per-role table, append-only + INDEX update) + §Validation Architecture (human-selection checkpoint) |
</phase_requirements>

## Summary

This phase produces **zero production code**. Its three deliverables are (1) a written synthesis of mined design references into ≥4 distinct candidate palette directions, (2) 4–5 full color-scheme proposals rendered as Pencil mockups across 3 screens × light/dark each, and (3) an accepted ADR-018 recording the user-selected palette with exact hex per semantic role. The phase ENDS at a hard human-selection checkpoint (PALETTE-03) — execution must pause for user approval before Phase 33.

Three findings de-risk planning. First, **the VoltAgent reference repo is fully accessible and contains exact hex tokens** at `https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/{slug}/DESIGN.md` — verified for claude, notion, stripe, wise, revolut, coinbase, airbnb. Crucially, **Claude's own brand system is the strongest lineage match**: warm cream canvas `#faf9f5` + coral primary `#cc785c` + a deliberately separated warm accent-amber `#e8a55a` and cool accent-teal `#5db8a6` — this is almost exactly the D-04(a)/D-04(b) resolution space pre-validated by a shipping brand. Second, **the complete semantic-role taxonomy is already enumerated in `app_colors.dart` + the UI-SPEC completeness matrix** — a scheme is "complete" iff it answers ~30 roles per mode, and these roles already carry the Phase-31-renamed symbol names (`daily`, `joy`, `dailyLight`, `joyLight`, `joyRoiBg`, `joyFullnessBg`) that ADR-018 must name-match so Phase 33 consumes them directly. Third, **coral-as-action-only (D-04 resolution a) is already partly how the code uses coral** (FAB gradient, action gradient, input-active border, recording gradient) — lowering Phase-33 risk for schemes that lean that way.

The single highest-uncertainty area is **Pencil MCP mechanics**. The `pencil` MCP server is available to the main agent (tools: `open_document`, `batch_design`, `batch_get`, `get_guidelines`, `get_variables`, `set_variables`, `get_screenshot`, `snapshot_layout`, `find_empty_space_on_canvas`, `export_nodes`), but these tools are NOT callable from this research sub-agent context. The executor (main agent) must call `get_guidelines` FIRST before any design work to learn the document's node/property conventions — this is mandatory and non-skippable.

**Primary recommendation:** Plan 4 schemes (one per the four corners of the D-04 × D-05 axis matrix) with an optional 5th hybrid-friendly "neutral-slate + amber-Joy" direction. Use a SINGLE `.pen` document with one top-level frame group per scheme, each group holding 6 screen frames (3 screens × light/dark) laid out in a 2-row × 3-column grid, so all schemes compare side-by-side on one canvas. Define each scheme's palette as a Pencil variable set (light + dark collection) so the 6 frames per scheme reference variables, not raw hex — making the 4–5 schemes cheap to render and the final hex trivially exportable into ADR-018 via `get_variables`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Reference mining + direction synthesis | Research/Design artifact (Markdown) | — | PALETTE-01 is a written-synthesis deliverable, no runtime tier |
| Color-scheme mockups | Pencil `.pen` design file | — | PALETTE-02 lives entirely in the design tool; no Flutter/`lib/` involvement |
| Palette decision record | ADR (`docs/arch/03-adr/`) | INDEX doc | PALETTE-03 is an architecture-decision artifact governed by `.claude/rules/arch.md` |
| Accessibility verification | Research/plan-time computation (contrast ratios) | — | WCAG floor is checked at design time, not enforced by any running tier this phase |
| Hand-off to Phase 33 | ADR-018 hex table + selected `.pen` scheme | `lib/core/theme/` (Phase 33 consumer) | This phase writes the contract; Phase 33's theme layer is the consumer, untouched here |

**No production-code tier is touched this phase.** Any task that proposes editing `lib/`, tokens, or goldens is out of scope (CONTEXT §Phase Boundary; UI-SPEC "ZERO production code").

## Standard Stack

This phase installs **no packages** and writes **no code**. The "stack" is the toolset used to produce the three artifacts:

| Tool | Purpose | Why Standard | Provenance |
|------|---------|--------------|-----------|
| Pencil MCP (`pencil` server) | Author the `.pen` mockups (PALETTE-02) | Already the project's mockup tool — existing design-system.md cites `untitled.pen` as source; MCP server is live | [VERIFIED: MCP server instructions present in this session] |
| VoltAgent/awesome-design-md (GitHub) | Reference mining source (PALETTE-01) | Named explicitly in D-06 / REQUIREMENTS PALETTE-01 | [VERIFIED: raw.githubusercontent.com returns 200 for `design-md/{slug}/DESIGN.md`] |
| Markdown (ADR-018) | Decision record (PALETTE-03) | Project ADR convention `.claude/rules/arch.md` | [VERIFIED: ADR-017 exists, follows this format] |
| Contrast-ratio computation | WCAG accessibility floor | WCAG 2.1 AA is the discretion default | [CITED: w3.org WCAG 2.1 SC 1.4.3/1.4.11] |

**No `npm install` / `pip install` / `cargo` — Package Legitimacy Audit is N/A (see below).**

## Package Legitimacy Audit

**Not applicable.** This phase installs zero external packages (no Node/Python/Rust dependencies, no shadcn registries — confirmed in UI-SPEC §Registry Safety: "Flutter app — no shadcn, no component registries"). No slopcheck run required. The only external resource fetched is the VoltAgent GitHub repo (read-only reference data, not an installed dependency).

## Reference Mining (PALETTE-01) — VERIFIED hex from brand DESIGN.md files

**Repo:** `https://github.com/VoltAgent/awesome-design-md` (72+ brands; released 2026-03-31). [CITED: github.com/VoltAgent/awesome-design-md]
**Raw access pattern (VERIFIED working):** `https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/{slug}/DESIGN.md`
**File structure:** each brand folder holds `DESIGN.md` (YAML-ish `colors:` block with `semantic-name: "#hex"`), `preview.html`, `preview-dark.html`.

The executor should re-fetch these during execution (data may evolve), but the following are **verified as of 2026-06-01**:

### Most-relevant brands (warm-anchored / fintech / family-finance lineage)

| Brand | Primary | Canvas / surface | Warm accent | Cool accent | Semantic (success/warn/error) | Relevance to Home Pocket |
|-------|---------|------------------|-------------|-------------|-------------------------------|--------------------------|
| **Claude** | `#cc785c` coral-terracotta | `#faf9f5` cream / `#f5f0e8` soft / `#efe9de` card | `accent-amber #e8a55a` | `accent-teal #5db8a6` | `#5db872` / `#d4a017` / `#c64545` | **STRONGEST match** — warm cream + coral + SEPARATED warm-amber & cool-teal is exactly the D-04/D-05 resolution space. on-primary `#ffffff`. |
| **Wise** | `#9fe870` lime | `#ffffff` / `#e8ebe6` sage-soft | `accent-orange #ffc091` | `accent-cyan #38c8ff` | `positive #2ead4b` / `warning #ffd11a` / `negative #d03238` | Fintech with a full semantic family + sage-neutral surface — good semantic-role reference. |
| **Coinbase** | `#0052ff` blue | `#ffffff` / `#f7f7f7` | `accent-yellow #f4b000` | (primary is the cool) | `semantic-up #05b169` / — / `semantic-down #cf202f` | Disciplined "single voltage" + finance up/down semantic pairing. |
| **Airbnb** | `#ff385c` rausch | `#ffffff` / `#f7f7f7` / `#f2f2f2` | (primary is warm) | `legal-link #428bff` | `error-text #c13515` | Warm single-accent marketplace; pill/rounded human feel — closest "consumer warmth" tone. |
| **Notion** | `#5645d4` purple | `#ffffff` / `#f6f5f4` soft / `charcoal #37352f` | `brand-orange #dd5b00`, peach/rose card tints | `brand-teal #2a9d99`, sky tint | `brand-green #1aae39` / `yellow #f5d75e` / — | Warm-neutral surface + colorful pastel card-tint system → great `*Light` tint reference (peach `#ffe8d4`, mint `#d9f3e1`, sky `#dcecfa`). |
| **Stripe** | `#533afd` indigo | `#ffffff` / `#f6f9fc` soft / `#f5e9d4` cream | — | `ruby #ea2261`, `magenta #f96bee` | — | Tabular-figure money type discipline; cool-minimal end of the spectrum. |
| **Revolut** | `#494fdf` cobalt-violet | `#ffffff` / `#000000` dark / `#f4f4f4` | `accent-brown #936d62` | `accent-teal #00a87e`, `blue-link #376cd5` | `warning #ec7e00` / `danger #e23b4a` | Black-canvas fintech; widest semantic accent palette (good dark-mode reference). |

> **Linear** and **Starbucks** raw files returned empty via this path (different internal structure or moved); not blocking — the 7 brands above span cool-minimal → warm-neutral → warm-consumer fully. [ASSUMED] Linear's cool-minimal/purple direction is well-represented by Stripe/Notion already.

### Mining synthesis (the PALETTE-01 directions)

Cross-cutting patterns from the mined set, weighed against the **家庭财务 + 双轨 + 和风** context:

1. **Warm-cream + coral is a validated, distinctive anchor** (Claude). It is precisely Home Pocket's existing identity — confirming D-01's coral anchor is on-trend, not legacy debt.
2. **Separating a warm accent from a cool accent is a shipping pattern** (Claude amber+teal; Wise orange+cyan; Notion orange+teal). This directly enables D-02's dual-ledger contrast: Daily = the cool member, Joy = the warm member.
3. **Pastel tint systems** (Notion card-tints, Claude surface-cream ladder) are the standard way to derive `*Light` tag backgrounds — informs every scheme's `dailyLight`/`joyLight`/`oliveLight` derivation.
4. **Finance brands keep a disciplined single-voltage primary** (Coinbase, Airbnb) — supports D-04(a)'s "coral as pure action color".
5. **Full success/warning/error/info families are standard in fintech** (Wise, Revolut, Claude) — the project currently LACKS these (overloads olive/coral); every scheme must now define them (net-new, feeds Phase 33).

## Candidate Directions (PALETTE-01 deliverable skeleton — ≥4 distinct)

Each direction names a **primary stance, Daily stance, Joy stance, surface/neutral stance**, plus its D-04 and D-05 position and mined lineage. These are the synthesis the executor expands into the written PALETTE-01 doc and then renders as schemes. **All keep coral present (D-01).** Hex values below are *starting anchors* the executor refines for contrast — not final.

| # | Scheme name (stable, descriptive — per UI-SPEC copy contract) | D-04 resolution | D-05 Daily tone | Primary | Daily | Joy | Surface/neutral | Lineage |
|---|---------|-----------------|-----------------|---------|-------|-----|-----------------|---------|
| **A** | **Coral-Action + Amber-Joy** | (a) coral demoted to pure action color (FAB/CTA/active-tab only, not a ledger semantic); Joy in a separate warm family (amber/gold) | (a) cool blue/teal Daily (continuity w/ `#5A9CC8`) | coral `#E85A4F` | cool blue/teal ~`#5A9CC8`→`#4E91C0` | amber/gold ~`#E8A55A` (Claude accent-amber) | warm ivory `#FCFBF9` | **Claude** (amber+teal separation) |
| **B** | **Slate-Daily + Coral-Tint-Joy** | (b) Joy as a coral-family bright tint distinguished from primary by lightness/saturation, NOT hue | (b) true neutral gray/slate Daily (Joy warmth pops hardest) | coral `#E85A4F` (action) | neutral slate ~`#64748D` (Stripe ink-mute / Coinbase muted) | warm coral-tint ~`#F2845F` lighter/brighter than primary | cooler off-white ~`#FBFAF8` | **Coinbase/Stripe** neutrals + **Claude** warm tint |
| **C** | **Warm-Neutral Calm (Notion-lineage)** | (a) coral as action; Joy = warm terracotta-orange; Daily = warm-neutral taupe | (b) warm neutral (taupe/greige), not cool | coral `#E85A4F` | warm-neutral taupe ~`#8E8B82` (Claude muted-soft) | terracotta-orange ~`#DD5B00` (Notion brand-orange, desaturated) | warm cream `#FAF9F5` (Claude canvas) | **Notion + Claude** warm-neutral |
| **D** | **Cool-Minimal Contrast (fintech-lineage)** | (b) Joy = bright warm gold; Daily = cool teal; coral retained as small action voltage | (a) cool teal Daily (strong cool↔warm split) | coral `#E85A4F` (small) | cool teal ~`#2A9D99`/`#5DB8A6` (Notion/Claude teal) | bright gold/amber ~`#F4B000` (Coinbase yellow) | crisp near-white `#FFFFFF`/`#F6F9FC` (Stripe soft) | **Stripe/Coinbase/Wise** |
| **E** *(optional 5th — strong hybrid seed)* | **Sage-Neutral + Honey-Joy** | (a) coral action; Joy = honey/amber; Daily = desaturated sage-green-gray (reads neutral but keeps a whisper of the old green) | (b) neutral-leaning sage | coral `#E85A4F` | sage-neutral ~`#8A9178` (reuse existing olive family, shifted to Daily) | honey ~`#E8A55A` | sage-tinted ivory ~`#FBFBF8`/`#E8EBE6` (Wise canvas-soft) | **Wise + Claude** |

> **Distinctness check (Success Criterion #1 ≥4 distinct):** A/B/C/D occupy the four corners of the D-04 (resolution a vs b) × D-05 (cool vs neutral Daily) matrix — genuinely distinct moods. E is a hybrid-friendly bridge. Planner picks 4 (A,B,C,D) or 5 (add E).

## Semantic-Role Taxonomy (PALETTE-02 completeness contract)

A scheme is **incomplete** (must be flagged) if any role is unanswered for either light OR dark. Role names match the **already-renamed Phase-31 `AppColors` symbols** — schemes name roles by THESE, never a parallel naming. Source: `lib/core/theme/app_colors.dart` (`AppColors` + `AppColorsDark`) + UI-SPEC completeness matrix.

### Light (`AppColors`) — required roles

| Group | Roles (exact symbol names) | Current value (anchor) |
|-------|----------------------------|------------------------|
| Backgrounds | `background`, `backgroundWarm`(=background), `card`, `backgroundMuted`, `backgroundSubtle`, `backgroundDivider` | `#FCFBF9`, `#FFFFFF`, `#F5F4F2`, `#FCFBF9`, `#F0F0F0` |
| Text | `textPrimary`, `textSecondary`, `textTertiary` | `#1E2432`, `#ABABAB`, `#C4C4C4` |
| Borders | `borderDefault`, `borderDivider`, `borderList`, `borderInputActive` | `#EFEFEF`, `#F5F4F2`, `#E8E8E8`, `#E85A4F` |
| Primary (coral anchor) | `accentPrimary`, `accentPrimaryLight`, `accentPrimaryBorder`, `fabGradientStart`, `fabGradientEnd` (+ aliases `actionGradientStart/End`, `actionShadow`) | `#E85A4F`, `#FEF5F4`, `#F5D5D2`, `#F08070`, `#E85A4F` |
| Recording state | `recordingGradientStart`, `recordingGradientEnd` | `#E05050`, `#C03030` |
| 日常 Daily | `daily`, `dailyLight` | `#5A9CC8`, `#E8F0F8` |
| 悦己 Joy | `joy`, `joyLight` (+ alias `tagGreen`=joyLight) | `#47B88A`, `#E5F5ED` |
| Olive (trends/ROI) | `olive`, `oliveLight`, `oliveBorder` | `#8A9178`, `#F0FAF4`, `#C8E6D5` |
| Shared (group mode) | `shared`, `sharedLight`, `sharedBorder`, `sharedChevron` | `#D4845A`, `#FFF0E0`, `#F0DCC8`, `#D4B89A` |
| Best-Joy strip | `surfaceCream`, `surfaceCreamBorder`, `textMutedGold`, `satisfactionPillBg`, `satisfactionPillRose` | `#FFFDF8`, `#F2E4C9`, `#B39A71`, `#FFF1F1`, `#D45F65` |
| Shadows | `fabShadow`, `navShadow` | `#35E85A4F`, `#08000000` |
| **Semantic (NET-NEW)** | `success`, `warning`, `error`, `info` | **none today — overloads olive/coral; each scheme MUST define** |

### Dark (`AppColorsDark`) — required roles

| Group | Roles | Current value |
|-------|-------|---------------|
| Backgrounds | `background`, `card`, `backgroundMuted`, `backgroundSubtle`, `backgroundDivider` | `#1A1D27`, `#252836`, `#353845`, `#1E2130`, `#353845` |
| Text | `textPrimary`, `textSecondary`, `textTertiary` | `#F0F0F2`, `#6B6E7A`, `#6B6E7A` |
| Borders | `borderDefault`, `borderDivider`, `borderList` | `#353845` (all) |
| Tag tints | `tagBlue`(Daily), `tagGreen`(Joy), `tagOrange`(Shared) | `#1E2D3D`, `#1E3028`, `#3D2D1E` |
| Joy card | `joyFullnessBg`, `joyFullnessBorder`, `joyRoiBg`, `joyRoiBorder` | `#3D2525`, `#5A3535`, `#1E3028`, `#2D4D3A` |
| Family badge | `familyBadgeBg` | `#3D2525` |
| Recording | `recordingGradientStart`, `recordingGradientEnd` | `#E07070`, `#B04040` |
| Nav shadow | `navShadow` | `#20000000` |
| **Semantic (NET-NEW)** | `success`, `warning`, `error`, `info` (dark variants) | **none today — each scheme MUST define** |

> **~30 light + ~22 dark roles per scheme.** The completeness matrix in UI-SPEC §Color collapses these into 9 groups for checker scoring. The dark-tag-tint pattern (a very dark, slightly-hue-shifted background of the accent) is how every scheme derives `tagBlue`/`tagGreen`/`tagOrange` for dark — Daily/Joy/Shared tints follow the accent hue.

## Pencil Workflow (PALETTE-02 production — highest-uncertainty area)

> **⚠️ The `pencil` MCP tools are available to the MAIN agent (executor) but NOT callable from this research sub-agent (upstream tool-restriction bug strips MCP tools from sub-agents).** The workflow below is reconstructed from the MCP server's documented tool list + tool semantics. The executor MUST validate it against live `get_guidelines` output before relying on specifics. Flagged MEDIUM confidence.

### Mandatory first step (non-skippable)
1. **`get_guidelines`** FIRST — before any `batch_design`. This returns the document's node-type / property conventions the executor must follow exactly (per MCP server instructions: "Follow each tool's input schema exactly"). Skipping this is the #1 Pencil failure mode.
2. **`open_document`** to create/open the fresh `.pen` (none exists yet). [ASSUMED] open_document creates if absent; confirm via guidelines.
3. **`get_variables`** to inspect any seeded variable collections; **`set_variables`** to define each scheme's palette.

### Recommended document structure (planner's call per D-07 discretion — this is the recommended shape)

**Single `.pen` document, one canvas, schemes laid out side-by-side:**

```
home-pocket-palette.pen  (one document)
├── Scheme A "Coral-Action + Amber-Joy"   (frame-group / section)
│   ├── A · home-hero · light      A · home-hero · dark
│   ├── A · txn-list · light       A · txn-list · dark
│   └── A · analytics · light      A · analytics · dark
├── Scheme B "Slate-Daily + Coral-Tint-Joy"   (6 frames, same grid)
├── Scheme C "Warm-Neutral Calm"              (6 frames)
├── Scheme D "Cool-Minimal Contrast"          (6 frames)
└── [Scheme E "Sage-Neutral + Honey-Joy"]     (6 frames, optional)
```

- **Why one document, not 4–5:** the selection step (PALETTE-03) demands side-by-side comparison "so schemes compare directly at selection time" (UI-SPEC copy contract). One canvas with all schemes is the cleanest comparison surface and one `get_screenshot` can capture a row.
- **Grid:** per scheme, 2 rows (light top / dark bottom) × 3 columns (home-hero, txn-list, analytics) = 6 frames. Use `find_empty_space_on_canvas` to place each scheme-group without overlap.
- **Frame width 402px** (design-system.md screen width), reuse existing Wa-Modern geometry verbatim (UI-SPEC: color-only delta).
- **Frame captions:** `{scheme name} · {screen} · {light|dark}` (UI-SPEC copy contract — unambiguous labels).

### Palette as variables (the efficiency lever)
- Define each scheme's palette as a **Pencil variable collection** (`set_variables`) — e.g. a light collection and dark collection per scheme, keyed by the `AppColors` symbol names (`accentPrimary`, `daily`, `joy`, `success`, …).
- **Frames reference variables, not raw hex.** This makes (a) rendering 6 frames per scheme fast (build the screen once, swap variable bindings), (b) the final hex export trivial — `get_variables` on the selected scheme yields the exact ADR-018 hex table. [ASSUMED — confirm Pencil supports variable-bound fills via guidelines.]

### Rendering efficiency (4–5 schemes × 6 frames = 24–30 frames)
- **Build a template once:** author the 3 screen layouts (home-hero, txn-list, analytics) for Scheme A light, get them right, then `batch_design` to duplicate + re-bind variables for the other 5 frames (dark + other schemes). Reuse geometry verbatim — only fills/variable bindings change.
- **`batch_design`** is the bulk-create/mutate tool — use it to create many frames in one call rather than one-at-a-time.
- **`get_screenshot`** after each scheme to visually verify before moving on (catch contrast/legibility issues early).
- **`snapshot_layout`** to verify structural integrity if a frame looks wrong.
- **`export_nodes`** at the end to produce shareable PNGs of each scheme for the selection prompt (and for the eventual PR / worklog).

### Three representative screens (content to mock — geometry frozen, color varies)
From design-system.md §10 standard structure. Each must surface the load-bearing color roles:
1. **Home hero:** status bar + month header + overview card (amount `headline-lg` 30px, trend badge) + ledger comparison rows (日常 row = `daily`, 悦己 row = `joy`, [group] 花の row = `shared`) + Soul Fullness card (satisfaction tile coral-tint, ROI tile olive-tint) + bottom nav (active tab = coral fill, FAB = coral gradient). **Exercises:** primary, daily, joy, olive, shared, surfaces, text.
2. **Transaction list:** transaction rows with ledger-type tags (生/灵 → 日常/悦己 tints), amounts colored per ledger, dividers. **Exercises:** daily/joy/shared accents + their `*Light` tints + borderList.
3. **Analytics:** Σ joy_contribution KPI, trend visualization (olive trends), per-category breakdown. **Exercises:** olive, joy, semantic roles, text hierarchy. **D-03 guard:** NO celebration affordance on the joy KPI — ambient color state only.

## Accessibility Floor (WCAG verification per scheme)

Apply to EVERY scheme; flag any role that cannot meet it (an un-fixable failure on a load-bearing role is a **selection-disqualifier**, annotate in synthesis). [CITED: WCAG 2.1 SC 1.4.3 normal text 4.5:1, SC 1.4.11 non-text/UI 3:1.]

| Pairing | Min contrast | How to verify |
|---------|-------------|---------------|
| Body/label text on its surface (`textPrimary`/`textSecondary` on `background`/`card`) | **≥ 4.5:1** | Compute relative-luminance ratio per WCAG formula |
| Large text (≥18px bold / ≥24px) & UI affordances/borders | **≥ 3:1** | e.g. `borderInputActive` coral vs card |
| Ledger accent amount text on card (`daily`/`joy`/`shared` on `card`) | **≥ 4.5:1** | amounts read as data — the hardest constraint; bright Joy must stay legible on white |
| Coral CTA fill vs white icon/label (`accentPrimary` vs `#FFFFFF`) | **≥ 3:1** | `#E85A4F` on white ≈ 3.3:1 — verify each scheme's primary |

**Verification method (research-time, no automated test framework):** compute contrast ratios via the WCAG relative-luminance formula. The executor can do this inline (formula is deterministic) or use an offline calculator. **Known risk:** bright/light Joy hues (gold/amber `#E8A55A`, `#F4B000`) on white card frequently FAIL the 4.5:1 amount-text floor — a scheme using a light gold for `joy` amounts must darken the *text* variant (e.g. amber text `#B86700`-range like Wise's warning-deep) while keeping the light tint for backgrounds. Flag this explicitly per scheme.

> **Contrast spot-checks (anchors, informational — executor must recompute finals):** `#E85A4F` on `#FFFFFF` ≈ 3.3:1 (passes UI 3:1, FAILS 4.5:1 body — fine, coral is an affordance not body text). `#1E2432` on `#FCFBF9` ≈ 14:1 (passes). `#47B88A` on `#FFFFFF` ≈ 2.0:1 — the CURRENT joy green already FAILS 4.5:1 as amount text, confirming the dual-ledger amounts need darker accent text variants in the new palette. [ASSUMED — approximate; recompute exact ratios at execution.]

## ADR-018 Structure (PALETTE-03 deliverable)

**Number:** ADR-018 (current max = ADR-017, verified `ls docs/arch/03-adr/`). [VERIFIED: directory listing]
**Title:** "Palette Selection — v1.5" (UI-SPEC copy contract).
**File:** `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md` (PascalCase per `.claude/rules/arch.md`).

### Required sections (model on ADR-017's structure — VERIFIED headers)
ADR-017 uses: 文档头部 (编号/版本/日期/状态/决策者/影响范围/相关ADR) → 📋 状态 → 🎯 背景 (Context) → 🔍 考虑的方案 (Considered Options) → ✅ 决策 (Decision) → 📋 后果 (Consequences) → 🗓️ 实施计划 → 🔗 引用 → 📝 变更历史. ADR-018 mirrors this:

1. **Header block:** 编号 ADR-018, 版本 1.0, 创建/更新日期, **状态: ✅ 已接受 (Accepted — on user confirmation)**, 决策者 (project owner + Claude), 影响范围 (v1.5 palette → Phase 33 token system), 相关 ADR (ADR-016 §5 anti-gamification constraint; ADR-017 vocab; ADR-015 design lineage).
2. **背景 (Context):** the dual-ledger color problem; D-01..D-08 constraints; why a palette decision is needed before Phase 33.
3. **考虑的方案 (Considered Options):** the 4–5 schemes — for EACH: name, mood, mined lineage, D-04/D-05 resolution, accessibility flags. The rejected schemes + *why rejected* (UI-SPEC: "records the rejected alternatives + why").
4. **决策 (Decision):** selected scheme name OR named hybrid (D-08, e.g. "Scheme B's Joy + Scheme D's Daily"). **The complete hex-per-role table** for BOTH light and dark, keyed by the exact `AppColors`/`AppColorsDark` symbol names from the taxonomy above — this IS the Phase 33 contract.
5. **后果 (Consequences):** 正面/负面/中立 — what Phase 33 inherits; the net-new success/warning/error/info family; any contrast tradeoffs accepted.
6. **实施计划:** points to Phase 33 (token system) + Phase 34 (golden re-baseline).
7. **引用:** CONTEXT.md, UI-SPEC, the `.pen` file, mined references.

### Append-only + INDEX rules (CRITICAL — project-specific)
- **`.claude/rules/arch.md` append-only rule:** once an ADR is "✅ 已接受", it enters append-only mode — later context appends as `## Update YYYY-MM-DD: <topic>`, never modifies the ratified body. **Implication for this phase:** set status to 已接受 ONLY at the user-confirmation checkpoint, not before. The draft can be edited freely until ratified.
- **Update `docs/arch/03-adr/ADR-000_INDEX.md`:** add an ADR-018 entry following the verified format (lines 513–524 for ADR-017): `### [ADR-018: …](./ADR-018_….md)` + **状态** + **日期** + **影响范围** + **相关 ADR** + **核心决策** bullets. Also add ADR-018 to the review-cadence table near line 600.
- **Cross-link ADR-016:** ADR-018 must cite ADR-016 §5's 100%-behavior contract as the binding constraint on D-03 (Joy is distinct, not celebratory). Consider a one-line append pointer in ADR-016 (per the arch append-only convention) noting ADR-018 operationalizes its color guidance — *planner's call whether ADR-016 needs the pointer since it's still 📝 草稿/Proposed, not yet ratified.*

## Common Pitfalls

### Pitfall 1: Skipping `get_guidelines` before designing in Pencil
**What goes wrong:** `batch_design` calls fail or produce malformed nodes because the executor guessed property names/structure.
**Why:** `.pen` is encrypted and has its own node conventions; the MCP server explicitly says follow each tool's schema exactly.
**Avoid:** Call `get_guidelines` as the literal first Pencil action. Plan must sequence it before any `batch_design`.
**Warning signs:** tool errors on first design call; nodes that don't render in `get_screenshot`.

### Pitfall 2: Joy accent too light → fails 4.5:1 amount-text contrast
**What goes wrong:** "Joy = warm/bright" (D-02) pushes toward light gold/amber; bright golds on white card fail the ≥4.5:1 amount floor.
**Why:** light warm hues have high luminance; amount text is normal-size data text needing 4.5:1.
**Avoid:** split each warm accent into a **light tint (background/tags)** and a **darker text/amount variant** (Wise pattern: `warning #ffd11a` light + `warning-deep #b86700` text). Verify the amount-text variant, not the tint.
**Warning signs:** the current `joy #47B88A` already fails 4.5:1 on white as amount text — confirms the new palette needs darker accent-text variants.

### Pitfall 3: Drifting into D-03-violating celebration affordances
**What goes wrong:** rendering the analytics joy KPI with glow/sparkle/milestone color-pop to make Joy "feel special".
**Why:** D-02 wants Joy *warm/bright*; easy to over-interpret as celebratory.
**Avoid:** Joy is distinct via **steady hue/lightness only**. ADR-016 §5 bans glow/pulse/sparkle/toast/haptic/milestone events. Mockups show ambient state, never a discrete celebration moment.
**Warning signs:** any frame with a burst, badge "unlocked", animated-looking glow, or >100% number.

### Pitfall 4: Inventing parallel role names instead of the Phase-31 symbols
**What goes wrong:** ADR-018 names roles `survivalAccent`/`soulColor`/`dailyBlue` etc. → Phase 33 can't map them.
**Why:** researcher unaware Phase 31 already renamed symbols to `daily`/`joy`/`dailyLight`/`joyLight`/`joyRoiBg`/`joyFullnessBg`.
**Avoid:** name every role by the exact existing `AppColors`/`AppColorsDark` symbol (taxonomy above). ADR-018's hex table keys = those symbols verbatim.
**Warning signs:** any "survival"/"soul" token, or a new naming scheme not in `app_colors.dart`.

### Pitfall 5: Setting ADR-018 status to 已接受 before the user selects
**What goes wrong:** ADR locked to append-only before the human checkpoint; can't edit the decision.
**Why:** arch append-only rule triggers at 已接受.
**Avoid:** keep status 草稿/Proposed through draft; flip to ✅ 已接受 ONLY at the PALETTE-03 confirmation. Plan must place the status-flip task AFTER the human checkpoint.

### Pitfall 6: Forgetting dark mode for some roles
**What goes wrong:** scheme answers light fully but leaves dark tints/semantic blank → checker flags incomplete.
**Why:** dark is "exploratory/forward-looking" (THEME-V2-02 defers full dark) so easy to under-invest.
**Avoid:** D-07 REQUIRES both light and dark for all 6 frames per scheme; every role group needs a dark answer (tints follow accent hue; net-new semantic needs dark variants).

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Deriving `*Light` tag-tint backgrounds | Eyeball/guess tints | Notion card-tint ladder (peach `#ffe8d4`, mint `#d9f3e1`, sky `#dcecfa`) + Claude surface-cream ladder as reference templates | Shipping pastel systems already solved tint luminance |
| Dual warm/cool accent separation | Invent from scratch | Claude amber `#e8a55a` + teal `#5db8a6` pairing as the D-04/D-05 template | Pre-validated warm-anchor + separated accents |
| success/warning/error/info family | Pick arbitrary | Wise (`#2ead4b`/`#ffd11a`/`#d03238`) or Claude (`#5db872`/`#d4a017`/`#c64545`) semantic families | Fintech-tested, accessible semantic hues |
| Contrast checking | Skip it | WCAG relative-luminance formula per pairing | Deterministic, prevents Phase-33 rework |
| Pencil node structure | Guess `.pen` internals | `get_guidelines` + variable-bound fills | Encrypted format with strict schema |

**Key insight:** the mined brand DESIGN.md set is a library of *solved* palette problems — the executor's job is selection + adaptation to the dual-ledger context, not invention.

## Validation Architecture

> **Nyquist validation is ENABLED, but this is a design/artifact phase with NO automated test framework.** Validation is **artifact-existence + human-selection-checkpoint** based, not pytest/flutter-test based. There is no code to test. The plan's verification steps assert artifact properties, and the phase gate is a human selection.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | **None** — no production code, no `flutter test` involvement this phase. Validation = artifact checks + human checkpoint. |
| Config file | n/a |
| Quick run command | n/a (artifact inspection: `ls`, `get_variables`, `get_screenshot`, grep on synthesis/ADR docs) |
| Full suite command | n/a |

### Phase Requirements → Validation Map (artifact + checkpoint based)
| Req ID | Behavior | Validation type | Concrete check |
|--------|----------|-----------------|----------------|
| PALETTE-01 | ≥4 distinct directions synthesized w/ rationale + lineage | Artifact existence + content | Synthesis doc exists; contains ≥4 named directions; each names primary/Daily/Joy/surface stance + D-04/D-05 position + mined lineage |
| PALETTE-02 | Exactly 4–5 schemes × 3 screens × light+dark, each answering every semantic role | Artifact existence + completeness | `.pen` has 4–5 scheme groups; each = 6 frames; `get_variables`/`get_screenshot` confirm every role in taxonomy answered both modes; WCAG floor checked per scheme (flags recorded) |
| PALETTE-03 | User selects one/hybrid; recorded in accepted ADR-018 w/ hex per role | **Human checkpoint** + artifact | `checkpoint:human-verify` BEFORE ADR ratification; ADR-018 exists, status ✅ 已接受, complete hex-per-role table (light+dark) keyed by `AppColors` symbols; ADR-000_INDEX updated |

### Validation gates (replaces test sampling)
- **Per-scheme (during PALETTE-02):** `get_screenshot` visual check + WCAG contrast computation on load-bearing pairings; flag failures inline.
- **Pre-selection gate:** all 4–5 schemes complete (every role, both modes) + accessibility flags documented → ready to present.
- **Phase gate (PALETTE-03):** **HARD human-selection checkpoint** — plan execution PAUSES; user picks one scheme or names a hybrid. ADR-018 status flips to 已接受 ONLY after this. No Phase 33 hand-off before approval.

### Wave 0 Gaps
- [ ] `.pen` file does not exist yet — created fresh in this phase (first Pencil task: `get_guidelines` → `open_document`).
- [ ] No semantic `success/warning/error/info` family exists in current palette — each scheme defines it net-new (feeds Phase 33).
- [ ] No contrast-verification artifact exists — executor computes WCAG ratios per scheme inline (no tooling install).
- *(No test-framework gaps — this phase has no automated tests by nature.)*

## Project Constraints (from CLAUDE.md / .claude/rules)

- **ADR numbering + append-only (`.claude/rules/arch.md`):** ADR-018 = next sequential (max is 017, VERIFIED). Append-only after 已接受. Must update `ADR-000_INDEX.md`. Status flip only at user confirmation.
- **No `lib/` changes:** CLAUDE.md architecture rules (Thin Feature, layer deps, crypto, i18n, Drift, Riverpod) are all irrelevant THIS phase — zero code. Any task touching `lib/` is out of scope.
- **Worklog rule (`.claude/rules/worklog.md`):** on completing this phase's tasks, generate `docs/worklog/YYYYMMDD_HHMM_palette_selection.md`. (Mandatory per project rule.)
- **Commit convention:** `docs(arch): add ADR-018 …` / `docs(32): …` (type: docs, since no code). `commit_docs: true` in config → research/plan/ADR are committed.
- **Git branching:** `branching_strategy: none` — work on `main` (current branch). No phase branch.

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| Analogous dual-ledger (blue `#5A9CC8` ↔ green `#47B88A`) | Clear warm/cool contrast (Daily cool/neutral ↔ Joy warm/bright) | This phase (D-02) | Strengthens "two books different" semantic |
| Overloaded olive/coral for status | Dedicated success/warning/error/info family | This phase (net-new) | Implementable semantic tokens for Phase 33 |
| Single-accent coral as ledger semantic AND action | Several schemes demote coral to pure action color (D-04a) | This phase exploration | Already partly how code uses coral → low Phase-33 risk |
| Figma/JSON design handoff | Plain-text DESIGN.md for AI agents (VoltAgent) | 2026-03-31 (repo release) | Reference mining is grep-able plain text |

**Deprecated/stale:**
- Project-memory "sky-blue primary `#8AB8DA`" — **STALE**; coral `#E85A4F` is the actual primary (CONTEXT D-01 note; verified in `app_colors.dart`).
- design-system.md uses old vocab "Survival/Soul/生存/灵魂" in prose — superseded by Phase 31's 日常/悦己/Daily/Joy. Schemes/ADR use NEW vocab.

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | Pencil `open_document` creates a `.pen` if absent | Pencil Workflow | LOW — executor confirms via `get_guidelines`; worst case an explicit create step |
| A2 | Pencil supports variable-bound fills (palette as variables, frames reference them) | Pencil Workflow | MEDIUM — if not, executor binds hex directly (more verbose, still works); affects efficiency not feasibility |
| A3 | Contrast spot-check ratios (`#E85A4F`/white ≈3.3:1, `#47B88A`/white ≈2.0:1) | Accessibility | LOW — approximate; executor recomputes exact ratios; direction (Joy green fails amount-text 4.5:1) is robust |
| A4 | Linear/Starbucks raw paths empty ⇒ their direction covered by Stripe/Notion | Reference Mining | LOW — 7 mined brands already span the full cool→warm spectrum |
| A5 | Candidate-direction starting hex (amber `#E8A55A`, slate `#64748D`, teal `#2A9D99`, etc.) | Candidate Directions | MEDIUM — these are *anchors* to refine for contrast, not final values; final hex is set at design time + ADR-018 |
| A6 | ADR-016 may need a one-line append pointer to ADR-018 | ADR-018 Structure | LOW — ADR-016 still 📝 Proposed (not ratified); planner's call |

## Open Questions

1. **Exact Pencil node/property schema for color fills and frames.**
   - Known: tool set (`get_guidelines`, `batch_design`, `set_variables`, etc.) and that `.pen` is encrypted with strict conventions.
   - Unclear: the precise node structure, whether fills bind to variables, exact `batch_design` payload shape — because the MCP tools are NOT callable from this research sub-agent.
   - Recommendation: **executor (main agent) calls `get_guidelines` FIRST**; the plan must make this the literal first Pencil task and treat the workflow here as a starting hypothesis to validate.

2. **4 vs 5 schemes.**
   - Known: ≥4 distinct directions required; A/B/C/D span the D-04×D-05 corners; E is a hybrid-friendly bridge.
   - Recommendation: planner picks based on whether E adds a genuinely distinct mood vs noise; default to 4 (A,B,C,D) for a tighter selection, add E only if the slate↔sage distinction reads as meaningfully different.

3. **Whether the home-hero mockup uses Solo or Group mode (or both).**
   - Known: Group mode adds the `shared` ledger row + family badge + group bar (exercises more color roles); Solo omits them.
   - Recommendation: render **Group mode** for home-hero (exercises `shared` family, maximizing role coverage) and Solo is acceptable for txn-list/analytics. Planner's call; document in plan.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `pencil` MCP server | PALETTE-02 mockups | ✓ (main agent) | — | None — core deliverable; if down, phase blocks on PALETTE-02 |
| GitHub raw (VoltAgent repo) | PALETTE-01 mining | ✓ | — | Already-mined hex in this doc suffices if offline |
| `docs/arch/03-adr/` + INDEX | PALETTE-03 ADR | ✓ | — | n/a |
| Contrast computation | Accessibility floor | ✓ (inline formula) | — | Offline WCAG calculator |

**Missing dependencies with no fallback:** none blocking at plan time. **Note:** Pencil MCP availability is confirmed for the main agent but unverifiable from this sub-agent — executor should `get_guidelines` early to fail fast if the server is misconfigured.

## Sources

### Primary (HIGH confidence)
- `lib/core/theme/app_colors.dart` — semantic-role taxonomy (source of truth), verified read
- `.planning/phases/32-palette-exploration-selection/32-CONTEXT.md` + `32-UI-SPEC.md` — D-01..D-08, completeness matrix, accessibility floor
- `.planning/phases/31-terminology-rename/31-CONTEXT.md` §D-11/D-12 — renamed color symbols
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — ADR section structure (verified headers); `ADR-000_INDEX.md` entry format
- `docs/arch/03-adr/ADR-016` §5 — anti-gamification 100%-behavior contract
- `.claude/rules/arch.md` — ADR numbering + append-only + INDEX rules
- MCP server instructions (this session) — Pencil tool list + "follow schema exactly"
- `raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/{claude,notion,stripe,wise,revolut,coinbase,airbnb}/DESIGN.md` — VERIFIED exact hex tokens (curl 200)

### Secondary (MEDIUM confidence)
- github.com/VoltAgent/awesome-design-md README — repo structure, 72+ brands
- WCAG 2.1 SC 1.4.3 / 1.4.11 — contrast thresholds

### Tertiary (LOW confidence)
- Pencil exact node/variable workflow — reconstructed from tool semantics, NOT directly executed (sub-agent can't call pencil tools); flagged for executor validation

## Metadata

**Confidence breakdown:**
- User constraints / scope: HIGH — copied verbatim from CONTEXT + UI-SPEC
- Semantic-role taxonomy: HIGH — read directly from `app_colors.dart` + UI-SPEC matrix
- Reference mining / candidate directions: HIGH — exact hex verified from 7 brand files
- ADR-018 structure: HIGH — modeled on verified ADR-017 + arch rules
- Accessibility floor: MEDIUM — method certain, spot-check ratios approximate
- Pencil workflow: MEDIUM — tool list certain, exact mechanics reconstructed (sub-agent can't call pencil tools; executor must `get_guidelines` first)

**Research date:** 2026-06-01
**Valid until:** 2026-07-01 (stable — design references + project constraints don't move fast; Pencil mechanics confirm at execution)

## RESEARCH COMPLETE

**Phase:** 32 - Palette Exploration & Selection
**Confidence:** HIGH (scope, taxonomy, mining, ADR) / MEDIUM (Pencil exact mechanics)

### Key Findings
- **VoltAgent repo is fully mineable** at `raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/{slug}/DESIGN.md`; exact hex verified for 7 brands. **Claude's own system (cream `#faf9f5` + coral `#cc785c` + separated amber `#e8a55a` / teal `#5db8a6`) is the strongest lineage match** and pre-validates the D-04/D-05 resolution space.
- **Complete semantic-role taxonomy enumerated** (~30 light + ~22 dark roles) keyed to the already-renamed Phase-31 symbols (`daily`, `joy`, `dailyLight`, `joyLight`, `joyRoiBg`, `joyFullnessBg`) so ADR-018 hex names match what Phase 33 consumes. **success/warning/error/info is net-new** — every scheme must define it.
- **5 candidate directions synthesized** (A Coral-Action+Amber-Joy / B Slate-Daily+Coral-Tint-Joy / C Warm-Neutral Calm / D Cool-Minimal Contrast / E Sage-Neutral+Honey-Joy) spanning the four D-04×D-05 corners — ≥4 distinct satisfied.
- **Pencil workflow recommended:** single `.pen`, one scheme-group per scheme (6 frames = 3 screens × light/dark in a 2×3 grid), palette as variable collections → cheap rendering + trivial hex export. **`get_guidelines` MUST be the first Pencil call** (sub-agent can't validate this — flagged).
- **ADR-018 = next sequential** (max 017 verified); append-only ⇒ status flips to 已接受 ONLY at the human checkpoint; `ADR-000_INDEX.md` must be updated.

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard "stack" (tools) | HIGH | Pencil + GitHub + ADR all verified present |
| Reference mining | HIGH | Exact hex curl-verified from 7 brand files |
| Semantic taxonomy | HIGH | Read directly from source-of-truth code |
| ADR mechanics | HIGH | Modeled on verified ADR-017 + arch rules |
| Pencil exact workflow | MEDIUM | Tools uncallable from sub-agent; executor must `get_guidelines` first |

### Open Questions
- Exact Pencil node/variable schema (executor validates via `get_guidelines`).
- 4 vs 5 schemes (planner's call; default 4).
- Solo vs Group mode for home-hero mockup (recommend Group for max role coverage).

### Ready for Planning
Research complete. File: `.planning/phases/32-palette-exploration-selection/32-RESEARCH.md`. Planner can now create PLAN.md (note: human-selection checkpoint at PALETTE-03; ADR status-flip task must come AFTER it).
