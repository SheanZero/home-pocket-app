# Quick Task 260603-lr5: 根据 Pencil soqKs 桜餅×若葉 配色更新整个 App 配色 - Context

**Gathered:** 2026-06-03
**Status:** Ready for planning

<domain>
## Task Boundary

Update the entire app's color identity from the current **ADR-018 "Teal Clarity"** palette to the new **桜餅×若葉 (Sakura Mochi × Wakaba)** direction defined in Pencil node `soqKs` (file `/Users/xinz/Documents/home1.pen`, frame "Palette Notes · Sakura Mochi × Wakaba").

The single source of truth for app color is the `AppPalette` ThemeExtension at
`lib/core/theme/app_palette.dart` (light = `AppPalette.light`, dark = `AppPalette.dark`,
~60 tokens each, resolved via `context.palette`). Updating "the whole app" means
re-valuing those tokens — NOT hunting raw hex literals in widgets (the coral→teal
migration already removed raw literals from `lib/features/`, `lib/application/`, `lib/shared/`).

This is the same class of work as Phases 32–34 (the teal migration): token re-value +
synchronized dark derivation + golden master re-baseline + ADR record.

</domain>

<decisions>
## Implementation Decisions

### soqKs palette spec (light, verbatim from Pencil)
| Role (CN) | Hex value(s) | Stated usage |
|---|---|---|
| 背景 background | `#FBF7F4` | warm cream page base, reduces coldness |
| 主色 primary | `#6FA36F` / `#5FAE72` | current tab, primary buttons, link actions |
| 若叶浅底 light surface | `#EEF6EC` / `#CFE6CF` | family invite, lightweight action containers |
| 樱粉 sakura pink | `#D98CA0` | central add entry ONLY, minor emotion anchor |
| 悦己文字 joy text | `#A15C00` | favorite titles + minor highlights |
| 文字/线 text/line | `#20352B` / `#71877A` / `#E6DDD8` | primary text / secondary label / card stroke |

Design intent (from soqKs notes):
- 若叶绿 (leaf green) carries HomeHero + navigation + daily actions + family sharing.
- 樱粉 (sakura pink) is reserved for the central ADD entry (FAB) only — do NOT spread it.
- Joy highlights stay minimal so they don't compete with the add entry.

### Dark mode (LOCKED)
- **Derive dark synchronously** using the same method Phase 33/34 used: lighten/desaturate
  the primaries for dark surfaces, warm-cream background → warm-dark background, keep the
  amount-text `*Text` tokens WCAG AA ≥4.5:1 on dark `card`.
- Update BOTH `AppPalette.light` and `AppPalette.dark` in this task.
- Re-baseline ALL golden masters (≈70 total, incl. ~31 dark). This is in-scope, not deferred.

### Joy ledger identity (LOCKED)
- **Joy fully re-hues to the warm amber `#A15C00` family.** This reverts the 丁香 Mauve
  (quick 260602-jcl) entirely.
- Affected tokens shift to amber/warm tints: `joy`, `joyText`, `joyLight`, `joyFullnessBg`,
  `joyFullnessBorder`, `satisfactionPillBg`, `satisfactionPillRose`, `textMutedGold`.
- `joyText` (amount text on card) must stay WCAG AA ≥4.5:1 → `#A15C00` is a strong dark amber,
  good for text; pick a lighter amber for `joy`/fills as needed.
- `joyRoi*` stays GREEN (it encodes ROI/success semantic, not the joy hue) — leave it.
- The **悦己充盈环** keeps its separate Butter palette (`happiness_ring_palette.dart`) — out of scope, do not touch.

### Add-entry / FAB (LOCKED)
- The central add entry (FAB) + its gradient → sakura pink `#D98CA0` family
  (`fabGradientStart`/`fabGradientEnd`/`actionShadow`/`fabShadow`/`actionGradient*`).
- This is the ONE place pink appears prominently. Daily/primary actions stay leaf-green.

### Primary / Daily (LOCKED)
- `accentPrimary` (nav, current tab, primary buttons, links, `borderInputActive`) → leaf green
  `#6FA36F` (light). Dark variant derived (e.g. brighter leaf green).
- `daily` ledger → leaf green family; `dailyText` stays WCAG AA on card; `dailyLight` → `#EEF6EC`/`#CFE6CF` wakaba light surface.
- Backgrounds → warm cream `#FBF7F4` family (`background`, `backgroundSubtle`, `backgroundMuted`, dividers re-warmed).
- Text tokens → `textPrimary #20352B`, `textSecondary #71877A`, `textTertiary` derived lighter.
- Borders → `#E6DDD8` warm stroke family for `borderDefault`/`borderDivider`/`borderList`.
- Decorative avatar/member gradients (D-04 teal-family) → re-hue to leaf-green/cream family to match.

### Shared ledger (LOCKED)
- **Keep steel-blue `#5B8AC4`** unchanged. green(daily)+amber(joy)+blue(shared) keeps the
  3-ledger distinction crisp; soqKs did not ask to change it.

### Semantic colors (LOCKED)
- Keep ADR-018 semantics (`success #2FA37A`, `warning #C98A00`, `error #E5484D`, `info #2A8FB8`)
  and their dark variants, error tints, recording gradient (red = live/danger).
- ONLY exception: if `success` green sits visibly too close to the new primary leaf green in
  any surface, nudge `success` slightly deeper/less-saturated for separation. Minor, executor discretion.

### ADR + process (LOCKED — Claude's call, stated)
- Create **ADR-019** (next sequential after ADR-018) recording 桜餅×若葉 v1.6 as the live palette,
  marking it as superseding ADR-018. Follow `.claude/rules/arch.md` (check max number, update ADR INDEX).
- Update `lib/core/theme/app_palette.dart` docstrings that say "ADR-018 Teal Clarity" → ADR-019.
- Update `CLAUDE.md` palette references and the memory file if appropriate (memory handled by orchestrator).

</decisions>

<specifics>
## Specific Ideas

- Pencil source: `/Users/xinz/Documents/home1.pen`, node `soqKs`. Read via Pencil MCP only (encrypted).
- Token contract file: `lib/core/theme/app_palette.dart` (light/dark static const + copyWith + lerp).
- Golden tests live under `test/` — find the golden master set (≈70 png, ~31 dark) and re-baseline
  with `flutter test --update-goldens` after the palette change compiles clean.
- Known pre-existing advisory (Phase 34 WR-01): dark `list_transaction_tile` golden zh/en variants
  render internal date in `ja` (locale not threaded). Cosmetic; do not try to fix here.

</specifics>

<canonical_refs>
## Canonical References

- `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md` — the palette being superseded; mirror its
  structure for ADR-019 (full light+dark hex-per-role table keyed to AppPalette/AppPaletteDark symbols).
- `.claude/rules/arch.md` — ADR numbering + INDEX update workflow (ADR is append-only once accepted).
- `lib/core/theme/happiness_ring_palette.dart` — OUT OF SCOPE (separate Butter palette for 充盈环).
- CLAUDE.md "Amount Display Style" + AppPalette docstring — `*Text` tokens must be WCAG AA ≥4.5:1 on `card`.

</canonical_refs>
