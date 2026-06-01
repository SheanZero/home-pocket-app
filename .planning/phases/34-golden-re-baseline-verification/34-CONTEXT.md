# Phase 34: Golden Re-baseline & Verification - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v1.5「文案与配色统一」milestone by regenerating **all** golden/visual baselines to the ratified ADR-018「Teal Clarity」palette, confirming the full test suite is green, and running a final terminology + color-literal audit that proves zero residual debt.

This is the fourth and final link of v1.5:
- Phase 31 (done): terminology rename — `daily`/`joy`/`shared` symbols.
- Phase 32 (done): palette selection → ADR-018 (ratified, every role's light+dark hex).
- Phase 33 (done): `ThemeExtension<AppPalette>` token system + literal consolidation + **full app-wide dark-mode rollout** (D-07 pulled THEME-V2-02 forward).
- **Phase 34 (this phase):** golden re-baseline (light + dark) + full-suite green + final audit (COLOR-04).

**Current state (scouted, code = source of truth):**
- Golden infra is **native `matchesGoldenFile`** — NO `golden_toolkit`/`alchemist` dependency. 12 golden test files, 52 committed master PNGs under `*/goldens/`. `test/golden/failures/` is already populated, i.e. the Phase 33 palette change has the goldens currently mismatching (expected — that is what this phase re-baselines).
- **Dark coverage gap:** only **5 of 12** golden test files iterate dark (`home_hero_card`, `daily_vs_joy_card`, `per_category_breakdown_card`, `smart_keyboard`, `voice_input_screen_mic_button`). The other **7 are light-only**: `list_day_group_header`, `amount_display`, `list_sort_filter_bar`, `list_category_filter_sheet`, `list_calendar_header`, `list_transaction_tile`, `list_empty_state`.
- 315 `*_test.dart` files total — "full suite green" spans far more than goldens.
- `home-pocket-palette.pen` currently shows **modified** in `git status` (the known-lagging design binary).

**Scope note:** D-07 from Phase 33 explicitly expanded Phase 34's golden re-baseline "to a full dark-mode golden set in addition to light." This phase honors that by closing the 7-file dark gap (D-01), not merely refreshing existing goldens.
</domain>

<decisions>
## Implementation Decisions

### Dark Golden Coverage (Dark 覆盖)
- **D-01:** **Close the D-07 gap.** Add dark variants to the **7 light-only** golden test files so all 12 golden test files cover **both light and dark**. **Chosen over** "regenerate existing goldens only" (would leave the `list_*` daily-use surfaces with no dark protection) and "broader new coverage for untested dark screens" (would overflow the milestone-closing scope).
- **D-01b:** **New dark variants match light's per-locale coverage** — not the existing ja-only representative convention. Where a light golden is per-locale (e.g. `list_transaction_tile` has en/ja/zh), its dark counterpart is also generated per-locale. The user chose thoroughness over minimal golden count.

### Diff Verification Rigor (Diff 验证)
- **D-02:** **Per-golden diff review before committing the re-baseline.** Run the golden suite **without** `--update-goldens` first so `failures/` generates `isolatedDiff`/`maskedDiff`/before-after PNGs. Each delta must be attributable to (a) the ADR-018 palette change, (b) D-04 re-hued decorative tokens, or (c) the D-05 teal→gold hero gradient. **Chosen over** "spot-check key screens only" and "full trust-and-regenerate." Note: this is NOT a zero-diff check — D-04/D-05 deltas are *intended*.
- **D-02b:** **Claude judges autonomously, no human UAT checkpoint.** Claude reads the diff PNGs, classifies each, and decides whether to `--update-goldens` that golden on its own. No human gate for diffs classified as pure-palette. (Bounded by D-04 below — see "Autonomy boundary".)

### Audit Breadth & .pen (审计广度)
- **D-03a:** **Comprehensive audit, not just the two ROADMAP greps.** Beyond the success-criteria greps, also sweep for **old-palette hex literals** (e.g. coral `E85A4F`, daily blue `5A9CC8`, joy green `47B88A`, and the other retired coral/olive/terracotta values) anywhere outside `lib/core/theme/`, AND extend the terminology + hex sweep into `test/` and `docs/`. Guards against "uses the new token but the old hex was left behind" and stale values copied into fixtures/design docs. **Chosen over** "strictly the two standard greps only." ⚠ Planner: legitimate palette hex *lives* in `lib/core/theme/` by design (D-03 of Phase 33) — the literal grep intentionally excludes that dir; the broader sweep must not flag core/theme's own token definitions.
- **D-03b:** **Attempt to sync `home-pocket-palette.pen` to ADR-018 — best-effort.** Use Pencil MCP to update the lagging `.pen` to match ADR-018's final hex. **KNOWN CONSTRAINT (project memory):** this environment's Pencil MCP cannot flush to disk. So this is best-effort: if the MCP confirms it cannot persist, **fall back to marking the .pen reconciliation as deferred** — do NOT block milestone close on it. ADR-018 remains authoritative over the `.pen` regardless.

### Regression Protocol (回归协议)
- **D-04:** **Non-palette deltas halt and report — never silent-update.** Any golden delta that Claude classifies as NOT attributable to palette/D-04/D-05 (a suspected real Phase-33 regression: layout shift, mis-applied dark color, broken contrast) must **stop the re-baseline for that golden and be surfaced to the user as a Phase-33 defect** for adjudication. Such a golden is NOT auto-`--update`d. **Chosen over** "fix minor cosmetic issues inline" and "treat all diffs as palette and update." Preserves golden's purpose of catching visual regressions; aligns with the milestone's "zero residual debt" close.

### Autonomy boundary (D-02b ⊕ D-04)
The two decisions jointly define Claude's autonomy during re-baseline:
- Delta judged **pure palette / D-04 / D-05** → Claude `--update-goldens` autonomously, no gate.
- Delta judged **suspected regression** → Claude **halts and reports**, no auto-update.

### Claude's Discretion
- Golden device sizes, truncation tolerances, and the exact wrapper used to add dark variants (reuse the `ThemeMode.dark` loop pattern already in `daily_vs_joy_card_golden_test.dart` / `home_hero_card_golden_test.dart`) — planner/executor territory.
- The exact list of retired hex values to grep for in the D-03a broad sweep (derive from Phase 33's OLD palette inventory in `app_colors.dart` git history / ADR-018's "supersedes" notes).
- Sequencing: regenerate → review → audit ordering, and how to batch the diff review.
- Coverage-gate handling (≥70% global must stay green) — mechanical.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The Locked Palette (THE source of truth for every hex / diff attribution)
- `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md` — **MUST read.** Scheme D「Teal Clarity」, ratified 2026-06-01. The逐角色 light+dark Hex 表 is the ground truth every golden diff is checked against (D-02). Also lists what it supersedes (old coral palette) — feeds the D-03a old-hex sweep.
- `home-pocket-palette.pen` — the lagging design binary (D-03b best-effort sync target). ADR-018 wins on any disagreement.

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` — **COLOR-04** (golden/visual baselines regenerated to new palette and passing, diffs confirmed as intended, full suite green). THEME-V2-02 absorbed into Phase 33 per D-07 (full dark golden set is the downstream consequence landing here).
- `.planning/ROADMAP.md` §"Phase 34" — goal + 3 success criteria: (1) all goldens regenerated, `flutter test` 0 failures / 0 golden mismatches, diffs confirm palette is the only delta; (2) `grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb` = 0 AND `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/` = 0; (3) `flutter analyze` 0 issues, coverage ≥70% global green.

### Upstream Phase Context (what created the diffs being re-baselined)
- `.planning/phases/33-color-token-system-consolidation/33-CONTEXT.md` — **MUST read.** D-01/D-02 full `ThemeExtension` migration, D-03/D-04 decorative re-hue (these hex changes WILL appear in golden diffs — intended), D-05 hero gradient teal→gold (intended diff), D-07 full dark rollout (the reason dark coverage expands here).
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — canonical 日常/悦己/ときめき/Daily/Joy vocabulary; the terminology-audit (D-03a) checks nothing stale (生存/灵魂/Soul) survives.
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §5 — anti-gamification 100%-behavior contract; constrains how the joy/hero goldens should read (悦己 gold is not a celebration affordance).

### Current Code (re-baseline source + inventory)
- `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme_colors.dart`, `lib/core/theme/app_theme.dart` — the Phase-33 `ThemeExtension<AppPalette>` token system that all goldens now render through; the legitimate home of palette hex (excluded from the literal grep).
- `test/golden/` (12 test files + `goldens/` masters + `failures/`) and `test/widget/features/accounting/presentation/{screens,widgets}/*_golden_test.dart` — the golden suite to re-baseline. Dark-iterating exemplars to copy for D-01: `test/golden/daily_vs_joy_card_golden_test.dart`, `test/golden/home_hero_card_golden_test.dart`, `test/golden/per_category_breakdown_card_golden_test.dart`.
- The 7 light-only files needing dark variants (D-01): `test/golden/list_day_group_header_golden_test.dart`, `amount_display_golden_test.dart`, `list_sort_filter_bar_golden_test.dart`, `list_category_filter_sheet_golden_test.dart`, `list_calendar_header_golden_test.dart`, `list_transaction_tile_golden_test.dart`, `list_empty_state_golden_test.dart`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Native golden harness** — no new dependency needed. The `_wrap({themeMode})` + `ThemeMode.dark` loop in `daily_vs_joy_card_golden_test.dart` is the copy-paste template for adding dark variants to the 7 light-only files (D-01).
- `failures/` artifacts (`*_isolatedDiff.png`, `*_maskedDiff.png`, `*_masterImage.png`, `*_testImage.png`) are auto-generated by the native comparator on mismatch — these ARE the inputs to the D-02 per-golden review (Claude reads them).

### Established Patterns
- Existing dark goldens use **ja single-locale** representative coverage; D-01b deliberately departs from this for the new variants (per-locale to match light).
- `flutter analyze` 0-issues + `build_runner` clean-diff (AUDIT-10) are hard gates carried from prior phases; coverage ≥70% global is the standing gate (success criterion 3).

### Integration Points
- Re-baseline runs `flutter test --update-goldens` (selectively, per D-02b) against the Phase-33 token output — every golden screen × light/dark × locale renders through `ThemeExtension<AppPalette>`.
- The D-03a broad sweep is grep-only (no code change) except where it surfaces a genuine stale-hit to fix.
- `.pen` sync (D-03b) touches only the design binary via Pencil MCP, isolated from the code/golden re-baseline.

</code_context>

<specifics>
## Specific Ideas

- Diff review is attribution-based, not zero-diff: intended deltas are ADR-018 palette + D-04 decorative re-hue + D-05 hero gradient (teal `#1C7A86` → gold `#F0A81E`). Anything else = halt-and-report (D-04).
- Old-palette hex to hunt in the D-03a sweep includes coral `#E85A4F`, daily blue `#5A9CC8`, joy green `#47B88A` and the rest of the retired coral/olive/terracotta set (full list from `app_colors.dart` git history).
- `.pen` reconciliation is explicitly best-effort and non-blocking (D-03b) given the known MCP-can't-flush constraint.

</specifics>

<deferred>
## Deferred Ideas

- **Broader new dark-golden coverage for screens that have NO golden today** — considered under "Dark golden coverage" and declined for this phase (would overflow milestone close). If full-screen dark golden coverage is wanted, it belongs in a future theming/QA phase.
- **`.pen` authoritative sync** — if Pencil MCP truly cannot persist (D-03b fallback), proper `.pen`↔ADR-018 reconciliation is deferred to whenever a working Pencil flush path exists; not a v1.5 blocker.
- **Migrating off native goldens to `golden_toolkit`/`alchemist`** — out of scope; the native harness is sufficient for this re-baseline.

None of the above were scope-creep redirects during discussion — the discussion stayed within the verification/re-baseline domain.

</deferred>

---

*Phase: 34-Golden Re-baseline & Verification*
*Context gathered: 2026-06-01*
