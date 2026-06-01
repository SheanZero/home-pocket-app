# Phase 33: Color Token System & Consolidation - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Encode the **ADR-018「Teal Clarity」palette** (青色 primary `#0E9AA7`; 日常 teal-navy `#1C7A86`; 悦己 gold `#F0A81E`; explicit success/warning/error/info family) as the single source of truth in the theme layer (`lib/core/theme/`), replace the **61** hardcoded `Color(0x…)` literals in `lib/features/`, and apply the correct 日常/悦己 ledger accents uniformly across all surfaces. The palette hex is **already locked by ADR-018** — this phase decides *how* to encode and migrate, not *which* colors.

This is the third link of v1.5「文案与配色统一」:
- Phase 31 (done): terminology rename — `daily`/`joy`/`shared` symbols already renamed.
- Phase 32 (done): palette selection → ADR-018 (ratified, every role's light+dark hex).
- **Phase 33 (this phase):** token system + literal consolidation + uniform application (COLOR-01/02/03).
- Phase 34 (downstream): regenerate golden baselines to the new palette (COLOR-04).

**⚠ SCOPE EXPANDED BEYOND ADR-018's "minimal, no-rework" framing.** Two user decisions in this discussion deliberately grow the phase well past a hex-swap:
1. **Full migration to Flutter `ThemeExtension`** (not just swapping hex in the existing static-const classes).
2. **Full dark-mode rollout** — pulls **THEME-V2-02** (previously deferred to a future milestone) forward into Phase 33.

Both are intentional and confirmed. Downstream agents (researcher, planner, verifier) must size the phase accordingly and NOT treat it as a conservative literal-replacement pass.

**Current state (code = source of truth):**
- `lib/core/theme/app_colors.dart` (117 LOC): `AppColors` (light, static const) + `AppColorsDark` (dark, static const) — still the OLD coral palette (coral `#E85A4F`, daily blue `#5A9CC8`, joy green `#47B88A`, olive gray-green, shared terracotta).
- `lib/core/theme/app_theme_colors.dart`: `AppThemeColors` extension on `BuildContext` — `context.wm*` getters resolve light/dark by `Theme.of(this).brightness`. Dark currently used profile-scoped only.
- 61 `Color(0x…)` literals across `lib/features/` (0 in application/shared); 58 more inside `lib/core/theme/` itself.

</domain>

<decisions>
## Implementation Decisions

### Token Structure (Token 结构)
- **D-01:** **Full migration to a Flutter `ThemeExtension<AppPalette>`.** ALL color references — the existing `AppColors.*` static refs, the `context.wm*` extension getters, AND ADR-018's new roles — resolve via `Theme.of(context).extension<AppPalette>()`. Light + dark instances of the extension carry the full ADR-018 hex tables. This integrates with Material `ThemeData`/`ColorScheme` idiomatically. **Chosen over** "same static-const pattern as today" and "static-const + sub-class grouping." This is the larger refactor; the user accepted it explicitly.
- **D-02:** **Full migration boundary — every call site changes.** Not a partial "new roles only" or "theme-dependent only" migration. Every `AppColors.daily` / `context.wmCard` style reference is rewritten to read from the `ThemeExtension`. Pairs naturally with Phase 34's full golden re-baseline. (Planner decides whether the `AppColors`/`AppColorsDark` static classes survive as internal raw-hex sources feeding the two extension instances, or are deleted — implementation detail.)
- **New roles to add (from ADR-018):** amount-text variants `dailyText`/`joyText`/`sharedText` (differ light vs dark) + explicit `success`/`warning`/`error`/`info` family. These flow through the same `ThemeExtension`.
- **Residual cleanup absorbed here:** `app_theme_colors.dart` still has old-terminology getter names `wmSurvivalTagBg`/`wmSoulTagBg` (Phase 31 missed them). The full `ThemeExtension` migration replaces these getters outright — rename to `daily`/`joy` semantics as part of D-01/D-02.

### Decorative / Non-Semantic Literals (装饰字面量)
- **D-03:** **All decorative literals fold INTO the token system as named roles** — no separate non-semantic constants file. ~half of the 61 literals are non-semantic: avatar color-wheel presets (`#FFD4CC`, `#E8D5F5`, dark variants), neutral overlays (`0x14000000`, `0x26FFFFFF`, `0x80FFFFFF`). They become named tokens in the `ThemeExtension`/palette so COLOR-01's "zero literals in features" is met with a single source of truth. **Chosen over** "separate decorative-constants file" and "keep avatar colors in the profile feature."
  - Note: `soft_toast.dart`'s red group (`#FEF2F2`/`#FECACA`/`#DC2626`) is the **`error` semantic family**, NOT decorative — maps to ADR-018 `error #E5484D` and its tint/border, not a one-off.
- **D-04:** **Re-hue decorative colors to the Teal/neutral family.** Avatar presets and tinted overlays currently sit in the old coral/purple identity; they get new hex consistent with Teal Clarity (planner defines the exact values — these are NOT in ADR-018's table). **Pure hue-neutral black/white overlays stay as-is** (alpha-only, identity-independent). These new decorative hex values WILL appear in Phase 34's golden diff. **Chosen over** "preserve original hex, relocate only" and "per-color planner judgment."

### Hero Gradient & olive (Hero 渐变 + olive)
- **D-05:** **home-hero target-ring gradient → teal(daily) → gold(joy) dual-ledger gradient.** Currently a hand-rolled green→gold lerp (`_joyTargetStartColor #47B88A` → `_joyTargetEndColor #D9A441`). New: start = `daily #1C7A86`, end = `joy #F0A81E` — preserves the "cool→warm progress" reading and reuses the two ledger main tokens directly (日常→悦己 journey). The two duplicate constants `_joyTargetStartColor`/`_joyTargetEndColor` (named by COLOR-03) are **removed**, sourced from ledger tokens instead. **Chosen over** "gold light→dark ramp."
- **D-06:** **olive (trends) is MERGED — no longer a distinct token.** ADR-018 gave olive an independent emerald `#3DA77E` but flagged "Phase 33 可评估是否合并"; user chose to merge. **The success-vs-daily target is planner's call** (`### Claude's Discretion`): fold into `success #2FA37A` if trends read as growth/positive, OR `daily #1C7A86` if trends read as neutral/brand data — decided by whether trend charts co-occur with daily-ledger data on the same chart (avoid same-color collision).

### Dark-Mode Scope (暗色范围)
- **D-07:** **Full dark-mode rollout — every screen responds to dark mode.** Not "re-hue existing dark usages only." This **pulls THEME-V2-02 forward into Phase 33** (it was previously deferred to a future milestone). Consequences the user accepted: every screen needs dark adaptation, every screen needs light+dark verification, and **Phase 34's golden re-baseline expands to a full dark-mode golden set** in addition to light. REQUIREMENTS.md/ROADMAP.md should be updated to reflect THEME-V2-02 being absorbed (flag for planner — see Deferred).

### Claude's Discretion
- **olive merge target (D-06):** success vs daily — planner decides from chart context.
- **Whether `AppColors`/`AppColorsDark` static classes survive** as internal raw-hex sources for the two `ThemeExtension` instances, or are deleted entirely (D-02).
- **Exact new hex for re-hued decorative tokens** (D-04) — avatar presets, tinted overlays — within the Teal/neutral family; ADR-018 does not specify these.
- **Derived values** (`*Border`, `*Chevron`, `fabGradient*`, shadows) — ADR-018 says these may be fine-tuned from the anchor hex during Phase 33.
- **Migration sequencing / verification strategy** — standard planner territory.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The Locked Palette (THE source of truth for every hex)
- `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md` — **MUST read.** Scheme D「Teal Clarity」, ratified 2026-06-01, append-only. Contains the逐角色 Hex 表 (Phase 33 contract) for BOTH `AppColors` (light) and `AppColorsDark` (dark), keyed to existing symbol names. Includes the WCAG ≥4.5:1 amount-text (`*Text`) rationale and the new success/warning/error/info family.
- `home-pocket-palette.pen` — 5 Pencil schemes; Scheme D selected. `get_variables` is the final hex export source. NOTE: the committed `.pen` binary may lag (MCP cannot flush to disk); ADR-018 is authoritative over the `.pen` if they disagree.

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` — COLOR-01 (zero `Color(0x…)` in features, ~62 literals replaced), COLOR-02 (selected palette applied uniformly across primary/daily/joy/surface/semantic), COLOR-03 (single semantic token system, duplicate constants like `_joyTargetStartColor` removed), COLOR-04 (Phase 34 golden re-baseline). **Needs amend:** THEME-V2-02 absorbed into Phase 33 per D-07.
- `.planning/ROADMAP.md` §"Phase 33" — goal + 4 success criteria (grep zero literals; single token system no duplicates; every 日常/悦己 surface uses correct token; `flutter analyze` 0 + build_runner clean-diff).

### Current Code (migration source + symbol inventory)
- `lib/core/theme/app_colors.dart` — `AppColors` + `AppColorsDark` (OLD coral palette); the semantic-role symbol inventory every token must fill. Phase 31 already renamed `daily`/`joy`/`dailyLight`/`joyLight`/`joyRoiBg`/`joyFullnessBg`. **Pitfall 4: do NOT invent parallel `survival*`/`soul*` naming.**
- `lib/core/theme/app_theme_colors.dart` — `AppThemeColors` `context.wm*` extension (brightness-resolved). Contains stale `wmSurvivalTagBg`/`wmSoulTagBg` getter names to fix (D-01).
- `lib/core/theme/app_theme.dart`, `app_text_styles.dart` — `ThemeData` wiring + amount text styles (`tabularFigures`); the `ThemeExtension` registers here.
- `docs/design/design-tokens.json` + `docs/design/flutter_color_mapping.dart` — prior token taxonomy; skeleton for the semantic-group structure.
- `lib/features/home/presentation/widgets/home_hero_card.dart` §20-25 — `_joyTargetStartColor`/`_joyTargetEndColor` duplicate constants (D-05 removes).
- `lib/features/profile/presentation/widgets/avatar_display.dart`, `lib/features/family_sync/.../member_approval_screen.dart` — avatar color-wheel presets (D-03/D-04 re-hue).
- `lib/features/accounting/presentation/widgets/soft_toast.dart` — the `error` semantic family (maps to ADR-018 error, not decorative).

### Cross-Phase / ADR Context
- `.planning/phases/32-palette-exploration-selection/32-CONTEXT.md` — D-01…D-08 selection context (D-01 coral anchor was lifted by user).
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §5 — anti-gamification 100%-behavior contract; 悦己 gold is distinct, NOT a celebration affordance (constrains hero gradient + any joy emphasis).
- `docs/arch/03-adr/ADR-017_Terminology_Unification_v1_5.md` — daily/joy/ときめき/Daily/Joy canonical vocabulary; `daily`/`joy` identifier source.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppThemeColors` extension (`context.wm*`): the existing brightness-resolution pattern — D-01 replaces its mechanism (→ ThemeExtension) but its getter SET is the inventory of theme-dependent roles to carry over.
- `AppColors`/`AppColorsDark` static-const classes: complete semantic-role inventory (backgrounds, text 3-tier, borders, primary +light/border + FAB gradient, daily/joy +light tints, olive, shared +variants, recording, tag tints, joy-card bg/border, family badge). A token is "complete" when ADR-018's row for it is filled.
- `docs/design/design-tokens.json`: prior token structure — useful skeleton for the ThemeExtension's semantic groups.

### Established Patterns
- Coral-as-action wiring (FAB gradient, action gradient, input-active border, recording gradient) already centralizes primary usage — lowers migration risk; these accent roles become `accentPrimary`/`fabGradient*` teal tokens.
- Dark theme exists but is **profile-scoped only** today — D-07 expands this to app-wide, so most screens currently have NO dark adaptation and need it added (not just re-hued). This is the bulk of the scope expansion.
- `flutter analyze` 0-issues + `build_runner` clean-diff are hard gates (success criterion #4); AUDIT-10 catches stale generated files.

### Integration Points
- `ThemeExtension<AppPalette>` registers in `app_theme.dart`'s `ThemeData(extensions: [...])` for both light and dark `ThemeData`.
- COLOR-01 grep gate: `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/` must return zero — every one of the 61 feature literals must route through a token (D-03 ensures even decorative ones do).
- Phase 34 consumes the result: every screen × light/dark needs golden baselines (expanded by D-07).

</code_context>

<specifics>
## Specific Ideas

- Hero gradient endpoints are concrete: `daily #1C7A86` → `joy #F0A81E` (D-05).
- Amount text MUST use the deeper `*Text` variants on white cards (`dailyText #145E68`, `joyText #9A6500`, `sharedText #3A6396` — all WCAG ≥4.5:1); the bright `joy #F0A81E` is tag/affordance only, never amount text (per ADR-018).
- Dark amount text reuses brightened accents directly (`dailyText≈daily #4FB0BC`, `joyText≈joy #F0C13A`).
- olive merges into success OR daily — planner picks per chart co-occurrence (D-06).
- Red appears ONLY as `error` semantic now (`#E5484D` light / `#F0676B` dark) — no coral/red primary remains anywhere.

</specifics>

<deferred>
## Deferred Ideas

- **REQUIREMENTS.md / ROADMAP.md amend (action item, not deferral):** THEME-V2-02 (full dark rollout) is **absorbed into Phase 33** per D-07 — it should be marked superseded/pulled-forward rather than left as a future milestone. Flag for planner to reconcile so the verifier doesn't treat app-wide dark mode as out-of-scope.
- **Runtime theming / user-selectable accent palettes** — `THEME-V2-01`, still out of scope. v1.5 ships exactly ONE palette (Teal Clarity).
- **Typography / spacing / component redesign** — out of v1.5 scope; if migration surfaces type/layout cleanup opportunities, capture but do not act.

</deferred>

---

*Phase: 33-Color Token System & Consolidation*
*Context gathered: 2026-06-01*
