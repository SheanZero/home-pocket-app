---
phase: 10-homepage-soulfullnesscard-redesign
plan: 04
subsystem: i18n
tags: [arb, flutter-localizations, gen-l10n, i18n, home-hero-card]

# Dependency graph
requires:
  - phase: 10-homepage-soulfullnesscard-redesign
    provides: locked verbatim copy table for 24 new keys (UI-SPEC.md lines 184-207)
provides:
  - 24 new ARB keys (HomeHeroCard tooltips, hero header, ring section, Best Joy strip, coverage caption, ring legends) in ja/zh/en
  - Regenerated `lib/generated/app_localizations*.dart` exposing 24 new accessors on abstract class S
  - 5 placeholder-typed accessors (homeHeroPreviousMonthSubline, homeBestJoyAmountSat, homeCoverageCaption, homeHighlightsCountLegend) ready for Wave 4 widget composition
affects: [10-05, 10-06, 10-07, 10-08, 10-09, 10-10, 10-11, 12-rename-pass]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ARB triplet atomicity (CLAUDE.md Pitfall #5): every key change must touch ja/zh/en simultaneously"
    - "@-description block parity in all 3 locale files (matches existing project convention)"
    - "Placeholder type uniformity (String/int) declared in @-blocks per locale"
    - "Feature-grouped insertion order: hero → ring → Best Joy → members → coverage → legends"

key-files:
  created:
    - .planning/phases/10-homepage-soulfullnesscard-redesign/10-04-SUMMARY.md
  modified:
    - lib/l10n/app_en.arb (added 24 keys + 24 @-blocks after homeMonthBadge)
    - lib/l10n/app_ja.arb (added 24 keys + 24 @-blocks after homeMonthBadge)
    - lib/l10n/app_zh.arb (added 24 keys + 24 @-blocks after homeMonthBadge)
    - lib/generated/app_localizations.dart (24 new abstract accessors on class S)
    - lib/generated/app_localizations_en.dart (24 implementations)
    - lib/generated/app_localizations_ja.dart (24 implementations)
    - lib/generated/app_localizations_zh.dart (24 implementations)

key-decisions:
  - "Kept @-description blocks in all 3 ARB files (matches existing project convention; plan instruction to en-only contradicted reality)"
  - "Inserted new keys as a contiguous block after homeMonthBadge (last existing home* key) to preserve feature-grouping discoverability"
  - "Three Best Joy tag keys (Single/Group/EmptyTagPrimary) intentionally duplicate values per UI-SPEC; separate keys preserve future per-context locale variance flexibility"

patterns-established:
  - "Phase 10 ARB additions block is the canonical reference for HOMEUI-04 / HAPPY-06 copy"
  - "Phase 12 RENAME pass is reserved for value renames of pre-existing keys (homeSoulFullness, homeHappinessROI, etc.); Phase 10 added net-new keys only"

requirements-completed: [HOMEUI-04]

# Metrics
duration: ~25min
completed: 2026-05-02
---

# Phase 10 Plan 04: ARB Localization Pre-Wave Summary

**24 new ARB keys added atomically to ja/zh/en covering HomeHeroCard tooltips (D-10), hero header (D-02), ring section, Best Joy strip (D-04), coverage caption (HOMEUI-04 / HAPPY-06), and 6 ring legend labels — `flutter gen-l10n` regenerated cleanly with 0 analyzer issues.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-02
- **Completed:** 2026-05-02
- **Tasks:** 2 / 2 complete
- **Files modified:** 7 (3 ARB + 4 generated)

## Accomplishments
- All 24 keys present in all 3 locale files with locale-correct verbatim values from UI-SPEC.md
- Placeholder declarations match across locales (String/int types uniform, `flutter gen-l10n` accepts cleanly)
- `flutter analyze lib/generated/` reports **0 issues** — Wave 4 (HomeHeroCard composition) can now `import` `S.of(context).homeJoyIndexTooltip` etc. without compilation errors
- ARB-parity invariant preserved: all 3 files have equal home* key counts (56 each) and equal @-block counts

## Task Commits

Each task committed atomically:

1. **Task 4.1: Add 24 new ARB keys to all 3 locale files atomically** — `fbd3148` (feat)
2. **Task 4.2: Run flutter gen-l10n and verify regenerated app_localizations.dart** — `f48a223` (chore)

## Files Created/Modified

### ARB sources (Task 4.1)

- `lib/l10n/app_en.arb` — inserted 24 keys at lines 664-787 (after `homeMonthBadge`, before `addTransaction`)
- `lib/l10n/app_ja.arb` — inserted 24 keys at lines 664-787 (Japanese values)
- `lib/l10n/app_zh.arb` — inserted 24 keys at lines 664-787 (Chinese values)

### Generated (Task 4.2)

- `lib/generated/app_localizations.dart` — 24 new abstract accessors:
  - 19 `String get` getters (no placeholders)
  - 5 `String <name>(...)` methods with typed placeholders:
    - `String homeHeroPreviousMonthSubline(String amount)` (line 1114)
    - `String homeBestJoyAmountSat(String amount, int sat)` (line 1144)
    - `String homeCoverageCaption(int rated, int total)` (line 1192)
    - `String homeHighlightsCountLegend(int count)` (line 1210)
- `lib/generated/app_localizations_en.dart` — 24 English implementations
- `lib/generated/app_localizations_ja.dart` — 24 Japanese implementations
- `lib/generated/app_localizations_zh.dart` — 24 Chinese implementations

### Key inventory (24 keys)

| # | Key | Category |
|---|-----|----------|
| 1 | `homeJoyIndexTooltip` | D-10 tooltip 1 (3-ring system) |
| 2 | `homeJoyPerYenTooltip` | D-10 tooltip 2 (PTVF + hedonic adaptation) |
| 3 | `homeHeroCardLabelSingle` | Hero header (D-02) |
| 4 | `homeHeroCardLabelGroup` | Hero header (D-02) |
| 5 | `homeHeroPreviousMonthSubline` | Hero sub-line (placeholder: amount=String) |
| 6 | `homeRingSectionTitleSingle` | Ring section title — single |
| 7 | `homeRingSectionTitleGroup` | Ring section title — group |
| 8 | `homeBestJoyTagSingle` | Best Joy tag — single (D-04) |
| 9 | `homeBestJoyTagGroup` | Best Joy tag — group (D-04) |
| 10 | `homeBestJoyAmountSat` | Best Joy small line (placeholders: amount=String, sat=int) |
| 11 | `homeMembersSectionTitle` | Group-mode members subheader |
| 12 | `homeNoSoulDataLegend` | Legend "No data yet" (D-09) |
| 13 | `homeBestJoyEmptyTagPrimary` | Empty-state CTA tag (D-09) |
| 14 | `homeBestJoyEmptyBig` | Empty-state CTA BIG line (D-09) |
| 15 | `homeBestJoyEmptySmall` | Empty-state CTA small line (D-09) |
| 16 | `homeBestJoyAllNeutralBig` | All-neutral CTA BIG line (D-09) |
| 17 | `homeBestJoyAllNeutralSmall` | All-neutral CTA small line (D-09) |
| 18 | `homeCoverageCaption` | Coverage caption (placeholders: rated=int, total=int) — HOMEUI-04 / HAPPY-06 |
| 19 | `homeAvgSatisfactionLegend` | Single-mode mid-ring legend |
| 20 | `homeJoyPerYenLegend` | Single-mode outer-ring legend |
| 21 | `homeHighlightsCountLegend` | Single-mode inner-ring legend (placeholder: count=int) |
| 22 | `homeFamilyHighlightsLegend` | Group-mode outer-ring legend |
| 23 | `homeSharedJoyLegend` | Group-mode mid-ring legend |
| 24 | `homeMedianSatisfactionLegend` | Group-mode inner-ring legend |

## Decisions Made

1. **All 3 ARB files received `@key` description blocks** — the plan instructed "descriptions in en only", but the existing project convention (verified: 313 `@`-blocks in each ARB; same `description` and `placeholders` content in en/ja/zh) is full parity. Stripping descriptions from ja/zh would have made this plan the only inconsistent commit in the file. Preferred: match project convention, document deviation. (See deviation #1 below.)
2. **Insertion location: after `homeMonthBadge` (last existing home* key)** — preserves feature-grouped ordering; placed before `addTransaction` (next non-home key) so the new home* block stays contiguous.
3. **Triple-keyed Best Joy tag (`homeBestJoyTagSingle`, `homeBestJoyTagGroup`, `homeBestJoyEmptyTagPrimary`) intentionally duplicate values per UI-SPEC** — separate keys preserve future per-context locale variance without an ARB rename pass; aligned with plan's explicit guidance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `@key` description blocks to ja/zh ARBs (matched project convention, contradicting plan instruction)**
- **Found during:** Task 4.1 (just before edits)
- **Issue:** Plan instruction at line 194 stated "for app_ja.arb and app_zh.arb, add ONLY the value lines (no `@key` blocks — those live in `app_en.arb` only per project convention)." However, verification of existing ARBs showed all 3 files contain identical `@`-block counts (313 each) with full `description` + `placeholders` content. Stripping descriptions from ja/zh would have:
  - Created a permanent ARB-parity gap (block-count mismatch flagged by `test/architecture/arb_key_parity_test.dart` style guards)
  - Made this commit the only outlier in the file's git history
  - Diverged from `homeMonthBadge` and the 312 other entries that all have `@`-blocks in all 3 files
- **Fix:** Added `@key` blocks to all 3 ARB files (en, ja, zh) with matching `description` and `placeholders` content. `flutter gen-l10n` accepts this without warnings; the @-blocks are metadata only and don't affect generated Dart code paths beyond the en template's authoritative read.
- **Files modified:** lib/l10n/app_ja.arb, lib/l10n/app_zh.arb (24 extra @-blocks each)
- **Verification:** `python3 -c "import json; …"` confirmed 24 keys + 24 @-keys in each file; `flutter gen-l10n` produced no warnings; `flutter analyze lib/generated/` reports 0 issues.
- **Committed in:** `fbd3148` (Task 4.1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 3 — blocking convention mismatch)
**Impact on plan:** No scope creep. Honored the higher-level rule (CLAUDE.md Pitfall #5: ARB-triplet atomicity) over an outdated plan-level instruction. Plan goal (24 keys callable from S class with correct types) achieved.

## Issues Encountered

1. **Initial worktree base mismatch.** Working tree's merge-base with the expected base commit (`914504f`) was `957a268`. Resolved by `git reset --hard 914504f` per the worktree_branch_check protocol — preserves no in-flight work, matches plan's expected base.
2. **`flutter analyze` printed unrelated pub.dev advisory FormatExceptions.** These come from `pub`'s advisory metadata fetcher (transient), not from analyzer findings. The analyzer ran to completion and reported "No issues found! (ran in 0.9s)". Out-of-scope per executor scope-boundary rule; not deferred (transient infra issue, not a code defect).

## User Setup Required

None — pure code/i18n changes; no external service configuration required.

## Next Phase Readiness

- **Wave 4 (HomeHeroCard composition / 10-05) unblocked** — can `import 'package:home_pocket/generated/app_localizations.dart'` and call `S.of(context).homeJoyIndexTooltip`, `S.of(context).homeBestJoyAmountSat(amount: '¥1,200', sat: 8)`, etc.
- **Phase 12 RENAME pass unaffected** — no existing keys touched; pre-existing `homeSoulFullness`, `homeHappinessROI`, `soulLedger`, `survivalLedger`, and the 5 emoji labels remain untouched and are owned by Phase 12.
- **ARB parity invariant intact** — all 3 files at 56 home* keys (was 32 before plan; +24 each).

## Self-Check: PASSED

- File `lib/l10n/app_en.arb`: present, contains all 24 new keys (verified via `python3 json.load`)
- File `lib/l10n/app_ja.arb`: present, contains all 24 new keys
- File `lib/l10n/app_zh.arb`: present, contains all 24 new keys
- File `lib/generated/app_localizations.dart`: present, contains all 24 abstract accessors
- File `lib/generated/app_localizations_en.dart`: present, 24 implementations
- File `lib/generated/app_localizations_ja.dart`: present, 24 implementations
- File `lib/generated/app_localizations_zh.dart`: present, 24 implementations
- Commit `fbd3148`: confirmed via `git log --oneline`
- Commit `f48a223`: confirmed via `git log --oneline`
- `flutter analyze lib/generated/`: 0 issues
- `flutter gen-l10n`: ran cleanly with no missing-key / placeholder-mismatch warnings

---
*Phase: 10-homepage-soulfullnesscard-redesign*
*Plan: 04*
*Completed: 2026-05-02*
