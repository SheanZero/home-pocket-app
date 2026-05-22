---
phase: quick-260522-fj5
plan: 01
subsystem: home/presentation + analytics/use-case + l10n
tags: [ui-polish, l10n, joy-target, home-hero, ring-painter]
one_liner: "7 single-mode home-hero UI fixes — info-icon repositioned in legend, highlights count moved to right column, fallback joy target 50→100, ring-center caption removed, residual zh '小確幸' simplified, inner-ring divisor switched to /10, outer-ring alpha seam removed."
dependency_graph:
  requires:
    - lib/features/home/presentation/widgets/home_hero_card.dart (pre-existing single-mode card)
    - lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart (fallback constant)
    - lib/l10n/app_{zh,ja,en}.arb (i18n keys)
  provides:
    - homeHighlightsCountLegend as a no-arg getter in all 3 locales
    - _legendRow(labelTrailing:) slot for icons that render between label and value
    - HappinessRingsPainter outer single-color sweep
    - _innerSingle(MetricResult<int>) — single-arg variant dividing by 10.0
    - _fallbackBaseline = 100 (cold-start joy target)
  affects:
    - lib/features/home/presentation/screens/home_screen.dart (reads fallbackBaseline getter — transparent)
    - lib/features/settings/presentation/screens/settings_screen.dart (reads fallbackBaseline getter — transparent)
    - test/widget/features/home/presentation/widgets/home_hero_card_test.dart (4 tests now fail — assertions hard-coded "目標 50" caption; tests need re-baselining)
    - test/golden/home_hero_card_golden_test.dart (7 goldens now fail — intentional visual changes; user must re-baseline)
tech_stack:
  added: []
  patterns:
    - "Optional named widget parameter (labelTrailing) renders inline within an Expanded child via Row(MainAxisSize.min) + Flexible(text) — preserves ellipsis behavior while keeping the trailing widget at intrinsic size."
    - "Single-color SweepGradient with two identical colors keeps the HappinessRingsPainter contract (Gradient) intact while eliminating visible seam at arc start/end meeting point — minimal-diff alternative to switching paint APIs."
key_files:
  created: []
  modified:
    - lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart
    - lib/l10n/app_zh.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart
    - lib/features/home/presentation/widgets/home_hero_card.dart
decisions:
  - "D-FJ5-A applied as planned: dropped {count} placeholder block from homeHighlightsCountLegend in all 3 ARB files; generator emits no-arg getter; caller passes count as right-column value."
  - "D-FJ5-B applied as planned: added labelTrailing slot to _legendRow; legacy trailing parameter kept (no remaining call sites, analyze silent — no need to break API)."
  - "D-FJ5-C applied as planned: _innerSingle now takes 1 arg and divides by 10.0; caller drops happiness.totalSoulTx."
  - "D-FJ5-D applied as planned: outer SweepGradient uses two identical colors — preserves Gradient contract while eliminating seam."
  - "D-FJ5-E applied as planned: homeJoyTargetReference ARB key retained in all 3 ARB files (unused by widget but generated API surface preserved)."
metrics:
  duration_minutes: 12
  completed_date: "2026-05-22"
  total_tasks: 4
  total_commits: 3
  files_modified: 9
---

# Quick Task 260522-fj5: Home Hero UI 7-Item Polish Summary

## Objective

Apply 7 targeted UI fixes to the 悦己充盈 single-mode card on the home page,
plus bump the cold-start joy-target fallback from 50 to 100.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Bump fallback joy target baseline 50 → 100 | `1f809a8` | `lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart` |
| 2 | ARB simplification + placeholder removal (zh/ja/en) and regenerate | `23d891f` | `lib/l10n/app_{zh,ja,en}.arb`, `lib/generated/app_localizations*.dart` |
| 3 | home_hero_card widget refactor (5 changes) | `c54e06f` | `lib/features/home/presentation/widgets/home_hero_card.dart` |
| 4 | Full project verification | — | (verification only) |

## Per-Requirement Outcome

| Req ID | Description | Outcome |
|--------|-------------|---------|
| FJ5-UI-01 | Info (i) icon between label and value (not right of value) | ✅ Implemented via new `labelTrailing` slot on `_legendRow` |
| FJ5-UI-02 | Legend row 3 shows '小确幸' label left + bold count right | ✅ Caller passes `'$highlights'` as right value; ARB drops `{count}` placeholder |
| FJ5-UI-03 | Fallback monthly joy target is 100 (was 50) | ✅ `_fallbackBaseline = 100` |
| FJ5-UI-04 | Ring center shows only cumulative value (no '目标 N' caption) | ✅ `_centerContent` returns single `Text` wrapped in `Semantics` (Column removed) |
| FJ5-UI-05 | All zh.arb '小確幸' replaced with '小确幸' | ✅ 5 zh keys updated; `grep -c '小確幸' lib/l10n/app_zh.arb` returns 0; ja unchanged (6 hits preserved) |
| FJ5-UI-06 | Inner ring fills proportionally to highlights/10 | ✅ `_innerSingle` divides by 10.0; `int total` parameter removed; caller drops `happiness.totalSoulTx` |
| FJ5-UI-07 | Outer ring renders as solid single-color sweep (no alpha seam) | ✅ `SweepGradient(colors: [_singleProgressColor(), _singleProgressColor()])` |

## Source-Level Sanity Checks (post-implementation)

```
grep -c '小確幸' lib/l10n/app_zh.arb              → 0  (expected 0)
grep -c '小確幸' lib/l10n/app_ja.arb              → 6  (expected ≥1, ja unchanged)
grep -n 'withValues(alpha: 0.6)' .../home_hero_card.dart → 1 hit (line 244, _splitBar — unrelated to ring)
grep -n 'data / 10.0' .../home_hero_card.dart      → 3 hits (_middleSingle, _innerSingle, _innerGroup)
grep -n 'homeJoyTargetReference' .../home_hero_card.dart → 0 hits (caller removed; ARB key retained)
grep -n 'labelTrailing' .../home_hero_card.dart    → 4 hits (1 call site + 1 param decl + 2 body refs)
grep -n '_fallbackBaseline = 100' .../use_case.dart → 1 hit
```

All sanity checks pass.

## Verification Results

### `flutter analyze lib/`

```
2 issues found.
   info • 'onReorder' is deprecated ... lib/features/accounting/presentation/screens/category_selection_screen.dart:386:17
   info • 'onReorder' is deprecated ... lib/features/accounting/presentation/screens/category_selection_screen.dart:502:13
```

**Both are pre-existing INFO-level deprecation warnings on a file NOT touched by this task.** Verified the file is unchanged on the base commit `fe98477`. Out of scope per the SCOPE BOUNDARY rule — logged below under Deferred.

### `flutter test` — Targeted

1. **`test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart` — 8/8 PASS.**
   The fallback constant change does not affect this suite (tests use `repeatedBaseRows(50)` as input sample data, unrelated to the `_fallbackBaseline` constant).

2. **`test/widget/features/home/` — partial run.** See Failing Tests section below.

3. **`test/golden/home_hero_card_golden_test.dart` — 7 goldens FAILED (expected).** See Re-baselining section below.

## Failing Tests (expected, surfaced for human review per Task 4 instruction)

### A. 4 widget tests in `test/widget/features/home/presentation/widgets/home_hero_card_test.dart`

All fail with the same shape:
```
Expected: exactly one matching candidate
  Actual: _TextContainingWidgetFinder:<Found 0 widgets with text containing 目標 50: []>
```

Failing test descriptions:
- `HomeHeroCard — single mode (HOMEUI-01, HOMEUI-05, HOMEUI-06) shows zero cumulative Joy and target reference without percentage`
- `HomeHeroCard — single mode (HOMEUI-01, HOMEUI-05, HOMEUI-06) shows half-target cumulative Joy without percentage`
- `HomeHeroCard — single mode (HOMEUI-01, HOMEUI-05, HOMEUI-06) shows target-level cumulative Joy without percentage`
- `HomeHeroCard — single mode (HOMEUI-01, HOMEUI-05, HOMEUI-06) shows over-target cumulative Joy uncapped without percentage`

**Root cause:** These tests assert the ring center caption `目標 50` is present, but req FJ5-UI-04 explicitly removed that caption (it lives only in the Semantics label now). Per plan instruction "If any non-golden test fails, report the failure verbatim in the SUMMARY without attempting a fix", I did NOT auto-update these tests. The user should:

1. Inspect the new ring center visually (Best Joy / single-mode hero card)
2. If happy with the change, update each of the 4 tests to assert the value Text instead of "目標 N" — for example, replace the `find.textContaining('目標 50')` assertion with `find.bySemanticsLabel(RegExp(r'目標 50'))` to keep the accessibility guarantee, or drop the assertion entirely since the target is no longer a visible UI element.

### B. 2 test files fail to compile (PRE-EXISTING — NOT caused by this task)

- `test/widget/features/home/presentation/screens/home_screen_test.dart`
- `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart`

Failure:
```
.pub-cache/hosted/pub.dev/lucide_icons-0.257.0/lib/src/icon_data.dart:3:30:
Error: The class 'IconData' can't be extended outside of its library because it's a final class.
```

**Root cause:** The base commit `fe98477` predates the `lucide_icons` → `lucide_icons_flutter` package swap that exists on main (visible in the pre-task `git status` showing `pubspec.yaml` and 6 family_sync screen files modified — those changes were intentionally excluded from this task per the constraints). The `lucide_icons` package is incompatible with Dart 3 final-class semantics. This is unrelated infrastructure debt that will be resolved when the lucide_icons swap commit lands on main.

### C. 7 golden tests in `test/golden/home_hero_card_golden_test.dart`

All fail with pixel diffs in the 1.09% – 2.17% range, exactly matching the intentional visual changes (no caption inside ring, restructured legend row 3, outer-ring color seam removed).

Failing golden test names + filenames:
- `HomeHeroCard golden single mode light ja` → `goldens/home_hero_card_single_light_ja.png` (2.17%, 7809px)
- `HomeHeroCard golden single mode target 0 light ja` → `goldens/home_hero_card_joy_target_0_ja.png` (1.09%, 3940px)
- `HomeHeroCard golden single mode target 50 light ja` → `goldens/home_hero_card_joy_target_50_ja.png` (1.74%, 6260px)
- `HomeHeroCard golden single mode target 100 light ja` → `goldens/home_hero_card_joy_target_100_ja.png` (2.17%, 7809px)
- `HomeHeroCard golden single mode target over 100 light ja` → `goldens/home_hero_card_joy_target_over_100_ja.png` (2.17%, 7809px)
- `HomeHeroCard golden thin sample (n<5) light ja` → `goldens/home_hero_card_thin_sample_ja.png` (1.20%, 4321px)
- `HomeHeroCard golden all-neutral CTA light ja` → `goldens/home_hero_card_all_neutral_cta_ja.png` (2.17%, 7809px)

**Re-baseline command** (run only after visually inspecting `test/golden/failures/*.png`):
```bash
flutter test --update-goldens test/golden/home_hero_card_golden_test.dart
```

The diff PNGs are at `test/golden/failures/` (untracked — left in place for human inspection).

## Deviations from Plan

Plan executed exactly as written. Three minor observations:

1. **D-FJ5-B post-condition:** Analyze stayed silent on the now-unused `trailing` parameter of `_legendRow`, so per the conditional in the plan I LEFT the parameter in place (kept as optional API surface). No remaining call sites.

2. **Stash rule violation (recovered):** During verification I ran `git stash` once by accident — this is prohibited per the worktree isolation rules. The stash contained ONLY the unrelated `pubspec.lock` churn from `flutter test` runs (no task-related work), and I immediately ran `git stash drop stash@{0}` to remove my entry from the global stash list. All 3 commits remained intact throughout. The global stash list is restored to its pre-task state. No data loss; reporting for transparency.

3. **`flutter analyze` pre-existing issues:** 2 INFO-level `deprecated_member_use` warnings on `lib/features/accounting/presentation/screens/category_selection_screen.dart` lines 386 and 502 exist on the base commit `fe98477`. These are out of scope per the SCOPE BOUNDARY rule (file not touched by this task). Logged under Deferred Issues.

## Deferred Issues

| Item | Why deferred | Suggested follow-up |
|------|--------------|---------------------|
| 4 widget test failures in `home_hero_card_test.dart` (target-caption assertions) | Intentional behavior change (FJ5-UI-04); plan instructs "report failures verbatim without attempting a fix" | Re-baseline the 4 tests to no longer assert the removed caption (or use `Semantics` finder) |
| 7 golden failures in `home_hero_card_golden_test.dart` | Intentional visual changes (FJ5-UI-01, 02, 04, 07) | Visually inspect `test/golden/failures/` PNGs, then run `flutter test --update-goldens test/golden/home_hero_card_golden_test.dart` |
| 2 compilation failures in `home_screen_test.dart` + `home_screen_isolation_test.dart` | Pre-existing `lucide_icons` Dart 3 incompatibility; resolved by the in-flight `lucide_icons_flutter` swap on main | Wait for the package-swap commit to land on main + rebase |
| 2 `onReorder` deprecation INFO warnings on `category_selection_screen.dart` | Pre-existing on base commit `fe98477`; outside this task's scope | Track as separate tech-debt; switch to `onReorderItem` callback |

## Known Stubs

None — all 7 changes wire real data through the existing rendering pipeline. No placeholders, hardcoded empties, or "coming soon" text introduced.

## Self-Check

**Files created/modified verification:**

- ✅ FOUND: `lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart` (Task 1)
- ✅ FOUND: `lib/l10n/app_zh.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_en.arb` (Task 2)
- ✅ FOUND: `lib/generated/app_localizations*.dart` (Task 2, 4 files)
- ✅ FOUND: `lib/features/home/presentation/widgets/home_hero_card.dart` (Task 3)

**Commit verification:**

- ✅ FOUND: `1f809a8` (Task 1) — `fix(260522-fj5): bump fallback joy target baseline 50 → 100`
- ✅ FOUND: `23d891f` (Task 2) — `fix(260522-fj5): simplify zh '小確幸' to '小确幸' and drop count placeholder from homeHighlightsCountLegend`
- ✅ FOUND: `c54e06f` (Task 3) — `fix(260522-fj5): home hero card single-mode legend + ring polish (5 ui fixes)`

## Self-Check: PASSED
