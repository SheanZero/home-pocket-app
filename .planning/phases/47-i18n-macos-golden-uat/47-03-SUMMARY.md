---
phase: 47-i18n-macos-golden-uat
plan: 03
subsystem: i18n
tags: [i18n, arb, l10n, codegen, cleanup, dual-ledger]

# Dependency graph
requires:
  - phase: 46-cards
    provides: "46-07 flat round-5 B lineup that orphaned the 3 section-header keys (zero source consumers)"
  - phase: 47-i18n-macos-golden-uat
    provides: "47-01 WR-02 donut edit (reuses kept analyticsCategoryDonutOther — must not race the orphan delete)"
provides:
  - "lib/l10n/app_{en,ja,zh}.arb without the 3 orphan section-header keys"
  - "regenerated lib/generated/app_localizations*.dart with the orphan getters removed"
affects: [analytics, i18n, 47-i18n-macos-golden-uat wave gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Symmetric ARB key deletion across all 3 locales + flutter gen-l10n + git add -f the gitignored-yet-tracked generated Dart (Phase 46 gotcha guard)"

key-files:
  created: []
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart

key-decisions:
  - "Deleted exactly 3 plain-string keys (analyticsGroupHeaderTime/Distribution/Stories) at lines 1955-1957 from each ARB file — verified zero @-metadata twins and zero source consumers across lib/ before deletion"
  - "Retained analyticsCategoryDonutOther (line ~2006) — reused by 47-01 WR-02; depends_on 47-01 only so the orphan delete cannot race the donut edit"
  - "Left analyticsCardTitleTotalSixMonth/CaptionTotalSixMonth ARB keys in place — out of this plan's scope (only the 3 section-header orphans are targeted)"
  - "Used git add -f on lib/generated/ per the mandatory MEMORY/Phase-46 gotcha; the 4 generated Dart files staged as modified-tracked (not left modified-unstaged)"

patterns-established:
  - "Orphan ARB key removal: grep zero consumers across lib/ → delete symmetrically from en/ja/zh → flutter gen-l10n (no untranslated/extra warnings) → grep generated getters == 0 → git add -f generated → parity + analyze green"

requirements-completed: [GUARD-03]

# Metrics
duration: 6min
completed: 2026-06-18
---

# Phase 47 Plan 03: Delete orphan section-header ARB keys + regenerate l10n Summary

**The 3 orphan section-header ARB keys (`analyticsGroupHeaderTime`/`Distribution`/`Stories`) left behind by the 46-07 flat-lineup flattening are deleted symmetrically from all 3 ARB files, localizations regenerated, and the gitignored-yet-tracked generated Dart force-added — ARB key-set parity green, `flutter analyze` 0 issues, `analyticsCategoryDonutOther` retained for WR-02 (GUARD-03 / D-15).**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-06-18
- **Completed:** 2026-06-18
- **Tasks:** 1
- **Files modified:** 7 (3 ARB + 4 generated Dart)

## Accomplishments
- Verified the 3 orphan keys live at lines 1955-1957 in each of `app_en.arb`/`app_ja.arb`/`app_zh.arb` as plain string entries with NO `@`-metadata twins.
- Confirmed **zero source consumers** across `lib/` (excluding `lib/generated/`) before deleting — safe orphan removal.
- Deleted exactly those 3 lines per file, symmetrically; nothing else touched.
- Ran `flutter gen-l10n` clean (exit 0, no untranslated/extra-message warnings).
- Verified the regenerated `lib/generated/app_localizations.dart` has **0** `analyticsGroupHeader` getters.
- Force-added the 4 regenerated Dart files (`git add -f lib/generated/...`) per the Phase 46 gitignored-yet-tracked gotcha; confirmed they staged as tracked-modified, not left modified-unstaged.
- `flutter test test/architecture/arb_key_parity_test.dart` green (key-sets match across all 3 locales, incl. metadata twins).
- `flutter analyze` reports **No issues found!** from the regenerated tree.
- `analyticsCategoryDonutOther` retained in all 3 ARB files (kept for 47-01 WR-02).

## Task Commits

1. **Task 1: Delete 3 orphan ARB keys symmetrically + gen-l10n + git add -f generated** - `c0d5a87d` (chore)

_Pure i18n cleanup + codegen — no behavior to test-drive; the `arb_key_parity_test` + `flutter analyze` from the regenerated tree are the preservation/correctness gates._

## Files Created/Modified
- `lib/l10n/app_en.arb` - removed the 3 orphan section-header keys
- `lib/l10n/app_ja.arb` - removed the 3 orphan section-header keys
- `lib/l10n/app_zh.arb` - removed the 3 orphan section-header keys
- `lib/generated/app_localizations.dart` - regenerated; orphan getters gone (force-added)
- `lib/generated/app_localizations_en.dart` - regenerated (force-added)
- `lib/generated/app_localizations_ja.dart` - regenerated (force-added)
- `lib/generated/app_localizations_zh.dart` - regenerated (force-added)

## Decisions Made
- **Scope held to the 3 section-header orphans:** `analyticsCardTitleTotalSixMonth`/`CaptionTotalSixMonth` remain in ARB even though their source consumers were removed in 46-01. The plan explicitly targets only the 3 section-header keys; touching the TotalSixMonth keys would exceed scope. Left in place.
- **`git add -f` applied as mandated:** `git check-ignore` reported these specific generated files as *not* currently ignored (they showed `M` tracked-modified), so a plain `git add` would also have worked — but the plan and the MEMORY Phase-46 gotcha mandate `git add -f`, which is harmless when not ignored and correct when ignored. Used `-f` for safety.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ARB edits isolated to this single lane (no other Wave-2 plan touches ARB); `analyticsCategoryDonutOther` retained so 47-01 WR-02 is unaffected.
- The 生存/灵魂 grep-ban (ADR-017) + full-suite gate run at the Plan 06 wave gate, not here.
- Generated Dart confirmed staged via `git add -f` — HEAD carries no stale getters for the deleted keys (Phase 46 failure mode avoided).

## Self-Check: PASSED

- FOUND: lib/l10n/app_en.arb (orphan keys removed)
- FOUND: lib/l10n/app_ja.arb (orphan keys removed)
- FOUND: lib/l10n/app_zh.arb (orphan keys removed)
- FOUND: lib/generated/app_localizations.dart (regenerated, getters gone)
- FOUND commit: c0d5a87d
- grep "analyticsGroupHeader" in app_en/ja/zh.arb = 0 each
- grep "analyticsGroupHeader" in lib/generated/app_localizations.dart = 0
- grep "analyticsCategoryDonutOther" in app_en/ja/zh.arb = 1 each (retained)
- grep source consumers across lib/ (excl. generated) = 0
- flutter gen-l10n = exit 0, no untranslated/extra warnings
- flutter test arb_key_parity_test.dart = 3/3 passed
- flutter analyze = No issues found!
- git status --porcelain lib/generated/ = staged (M in column 1), then clean post-commit

---
*Phase: 47-i18n-macos-golden-uat*
*Completed: 2026-06-18*
