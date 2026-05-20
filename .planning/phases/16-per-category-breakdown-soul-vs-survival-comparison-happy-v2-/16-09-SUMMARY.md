---
phase: 16
plan: 09
subsystem: analytics/presentation/test
tags: [happy-v2, statsui-v2, anti-toxicity, widget-test, i18n, trilingual, d-14, tdd]
requires:
  - 16-02  # ARB i18n keys (forbidden lists locked here in CONTEXT D-14 + UI-SPEC §Forbidden substrings)
  - 16-07  # PerCategoryBreakdownCard (widget under test)
  - 16-08  # SoulVsSurvivalCard (widget under test)
provides:
  - anti_toxicity_phase16_test  # D-14 trilingual forbidden-substring sweep across both new cards
affects:
  - test/widget/features/analytics/presentation/widgets/  # +1 new test file
tech-stack:
  added: []
  patterns:
    - parameterized-testwidgets       # locale loop ⇒ 1 declaration × 3 runs (8 declarations × 3 = 24 runs)
    - provider-override-state-driver  # state matrix driven by Empty/Value/sub-min-N overrides — no mock data layer
    - find-text-containing-rich-text  # find.textContaining(substring, findRichText: true) walks RichText subtrees
    - locked-const-forbidden-lists    # const forbiddenEn/forbiddenZh/forbiddenJa frozen at CONTEXT D-14 minimums
    - diagnostic-reason-tuples        # failure reasons embed (card, locale, state, substring) for fast triage
key-files:
  created:
    - test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart
  modified: []
decisions:
  - "Used `for (final locale in locales)` loop around 8 inline testWidgets declarations (4 per card × 2 cards) instead of 24 hand-written declarations. The grep-c acceptance criterion (≥ 8 testWidgets declarations) is satisfied by the 8 declarations; the runtime expansion to 24 test runs is what the sweep actually requires."
  - "Each override-list helper is local to its state (one helper per state per card variant) so a missing provider override causes a loud, attributable error at the override site instead of silently producing a passing sweep against an unbuilt/loading widget tree."
  - "Failure reason strings embed the full (card, locale, state, substring) tuple plus a recovery hint ('revert the offending ARB change or extend the locked forbidden list (requires CONTEXT D-14 update)'). Past anti-toxicity regressions in this project surfaced as opaque 'expect: found X widgets' failures with no provenance — the explicit reason avoids re-litigating that triage cost."
  - "Did NOT include the error state in the sweep. The card's `error` branch renders `AnalyticsCardErrorState` whose `analyticsCardErrorHeading` for zh is '数据加载失败' — the character '败' is in the locked forbidden-zh list. That match would be a false positive (the error surface is read-only, anti-toxicity copy review for that ARB key is a separate concern), so the sweep is scoped to the four user-visible product states (empty / sub-min-N / value-solo / value-group) per the plan's `<interfaces>` state list."
  - "Forbidden lists are declared `const <String>[ ... ]` at file scope, NOT inside a `setUp` or test helper. This keeps the lists greppable from CI (grep for the substring confirms it's locked in this file) and makes future expansion (planner adding more substrings per D-14 'planner adds more if locale review surfaces additional risk patterns') a one-line edit."
metrics:
  duration: ~10 minutes
  completed: 2026-05-20
  tasks: 1
  files_created: 1
  files_modified: 0
  tests_added: 24  # 8 declarations × 3 locale iterations
  loc_added: 473
---

# Phase 16 Plan 09: Anti-Toxicity Phase 16 Test Summary

Locked the D-14 trilingual forbidden-substring sweep as a compile-and-test gate: future ARB changes that drift toward comparison / value-judgment framing in either of the two new Phase 16 cards (`PerCategoryBreakdownCard`, `SoulVsSurvivalCard`) now fail this widget test rather than slipping into the next release as a silent anti-toxicity regression. Each (card, locale, state) tuple is asserted via `find.textContaining(forbidden, findRichText: true)` returning `findsNothing` across 24 test runs (2 cards × 3 locales × 4 states). All green.

## What Was Built

### Task 1 — Anti-toxicity widget test (commit `4044357`)

`test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` (473 lines):

**Locked forbidden-substring lists** (verbatim from CONTEXT D-14 + UI-SPEC §Forbidden substrings, lines 117-122):

- `const forbiddenEn` (15 substrings): `better`, `worse`, `winner`, `loser`, `vs`, `versus`, `compare`, `comparison`, `higher is good`, `lower is bad`, `score`, `rank`, `ranking`, `wins`, `loses`.
- `const forbiddenZh` (13 substrings): `更好`, `更差`, `赢`, `输`, `胜`, `败`, `vs`, `对比`, `比较`, `排名`, `分数`, `胜出`, `落败`.
- `const forbiddenJa` (10 substrings): `勝ち`, `負け`, `より良い`, `より悪い`, `比較`, `対決`, `スコア`, `ランキング`, `勝つ`, `負ける`.

**State matrix** — driven entirely by `ProviderScope` overrides (no mock repo, no DAO setup):

| Card | State | Override |
|---|---|---|
| PerCategoryBreakdownCard | empty | `perCategorySoulBreakdownProvider` → `Empty<PerCategorySoulBreakdown>()` |
| PerCategoryBreakdownCard | sub_min_n | `perCategorySoulBreakdownProvider` → `Value(items=[], otherCount=5, otherCategoryCount=2)` |
| PerCategoryBreakdownCard | value_solo | `perCategorySoulBreakdownProvider` → `Value(3 items + otherCount=2)` |
| PerCategoryBreakdownCard | value_group | `perCategorySoulBreakdownFamilyProvider` → `Value(3 items + otherCount=2)`, scope=family |
| SoulVsSurvivalCard | empty | `soulVsSurvivalSnapshotProvider` → `Empty<SoulVsSurvivalSnapshot>()` |
| SoulVsSurvivalCard | value_solo | `soulVsSurvivalSnapshotProvider` → `Value(soul=(5,1500,7.4), survival=(8,12000))` |
| SoulVsSurvivalCard | value_group_complete | single-book Value + `soulVsSurvivalSnapshotFamilyProvider` → `Value(familySoul=(12,3500,6.8), familySurvival=(18,24000))` |
| SoulVsSurvivalCard | value_group_family_empty | single-book Value + family `Empty` (D-20 fallback) |

**Sweep helper** — `_sweepForbiddenSubstrings({ locale, card, state })` loops over `_forbiddenFor(locale)` and asserts each substring is absent. Failure reason: `'D-14 anti-toxicity violation — {card} / {languageCode} / {state} — forbidden substring "{substring}" leaked into rendered output. Either revert the offending ARB change or extend the locked forbidden list (requires CONTEXT D-14 update).'`

**Test groups** — 2 groups (one per card), each with 4 testWidgets declarations × 3 locale iterations = 12 runs per card = 24 total.

## How It Works

```
                ┌──────────────────────────────────────────────────┐
                │ anti_toxicity_phase16_test.dart                  │
                │                                                  │
                │  const forbiddenEn = [...]   ← LOCKED (D-14)     │
                │  const forbiddenZh = [...]   ← LOCKED (D-14)     │
                │  const forbiddenJa = [...]   ← LOCKED (D-14)     │
                │  const locales     = [en, ja, zh]                │
                └────────────────────┬─────────────────────────────┘
                                     │ for each locale
                                     ▼
              ┌──────────────────────────────────────────────────┐
              │ testWidgets (8 declarations × 3 locales = 24)    │
              │                                                  │
              │  1. createLocalizedWidget(card, locale, overrides) │
              │     - ProviderScope owns the state matrix        │
              │     - MaterialApp owns the locale binding        │
              │  2. tester.pumpAndSettle()                       │
              │  3. _sweepForbiddenSubstrings(...)               │
              │     - for substring in _forbiddenFor(locale):    │
              │         expect(find.textContaining(substring,    │
              │                  findRichText: true),            │
              │                findsNothing,                     │
              │                reason: 'D-14 ... (card, locale,  │
              │                         state, substring)')      │
              └──────────────────────────────────────────────────┘
```

## Verification

- **Analyzer (file-scoped):** `flutter analyze test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` → `No issues found! (ran in 1.8s)`.
- **Analyzer (whole project):** `flutter analyze` → `No issues found! (ran in 5.8s)`.
- **Widget tests:** `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart -r expanded` → `+24: All tests passed!` (no skipped, no failed).

**Acceptance criteria** (from Plan 16-09):

| Criterion | Check | Result |
|---|---|---|
| File `anti_toxicity_phase16_test.dart` exists | `ls -la …/anti_toxicity_phase16_test.dart` | ✅ FOUND |
| Contains `const forbiddenEn`, `const forbiddenZh`, `const forbiddenJa` | `grep -c 'const forbidden(En\|Zh\|Ja)'` | ✅ 3 / 3 |
| `forbiddenEn` contains D-14 minimums (`better`, `worse`, `winner`, `loser`, `vs`, `versus`, `compare`, `comparison`) | substring scan of the const list | ✅ all 8 present |
| `forbiddenZh` contains D-14 minimums (`更好`, `更差`, `胜`, `败`, `对比`, `比较`, `排名`, `分数`) | substring scan | ✅ all 8 present |
| `forbiddenJa` contains D-14 minimums (`勝ち`, `負け`, `より良い`, `より悪い`, `比較`, `対決`, `スコア`, `ランキング`) | substring scan | ✅ all 8 present |
| Covers BOTH `PerCategoryBreakdownCard` AND `SoulVsSurvivalCard` | `grep -cE 'PerCategoryBreakdownCard\|SoulVsSurvivalCard'` ≥ 2 | ✅ 29 |
| Covers all 3 locales (en, ja, zh) | `const locales = [Locale('en'), Locale('ja'), Locale('zh')]` | ✅ present |
| ≥ 8 distinct `testWidgets(` declarations (2 cards × 4 states minimum) | `grep -c 'testWidgets('` ≥ 8 | ✅ 8 (×3 locale loop → 24 runtime cases) |
| Uses `find.textContaining(...)` with `findRichText: true` and `findsNothing` matcher | `grep -c 'findRichText: true'` ≥ 1 AND `grep -c 'findsNothing'` ≥ 1 | ✅ 1 / 1 (single helper call site) |
| `flutter analyze` 0 issues | command output | ✅ `No issues found!` |
| `flutter test …` exits 0 | command output | ✅ `+24: All tests passed!` |
| Test failure messages reference "D-14" and the specific (card, locale, state, substring) tuple | `grep -c 'D-14'` ≥ 1 | ✅ 7 markers (helper template + 6 doc/header references) |

## Why Each Forbidden List Is Currently Clean (and the test passes)

A defensive grep of the ARB files for any analytics keys containing forbidden substrings turned up exactly two hits — both safe by construction, so the sweep correctly returns clean across all four state buckets:

1. **`analyticsSurvivalVsSoul`** (stale ARB key: en "Survival vs Soul", ja "生存 vs 魂", zh "生存 vs 灵魂"). NOT referenced by either Phase 16 card or by anything in the user-visible widget tree under test. `grep -rn analyticsSurvivalVsSoul lib/ test/ --include="*.dart"` returns only the three generated localizations and the abstract base — no widget consumer. Safe.
2. **`analyticsCardErrorHeading`** (zh: "数据加载失败" — contains "败"). Rendered only by `AnalyticsCardErrorState`, which is reached via the `error` branch of `AsyncValue.when`. The sweep does NOT trigger the error branch (state list is empty / sub-min-N / value-solo / value-group), so "败" never appears in the rendered tree. Safe.

The remaining Phase 16 ARB keys (`analyticsCardTitlePerCategorySoul*`, `analyticsPerCategoryRow`, `analyticsPerCategoryOtherFold`, `analyticsPerCategoryShow*`, `analyticsCardTitleLedgerThisWindow`, `analyticsLedgerColumn{Soul,Survival}`, `analyticsLedgerRow{You,Family}`, `analyticsLedgerCell{Entries,AvgSat}`, `analyticsLedger{Empty,FamilyEmpty,FamilyError}`) are descriptive engagement-axis copy by construction (CONTEXT D-12) and contain none of the locked forbidden substrings in any of the three locales — confirmed by grep + test run.

## Deviations from Plan

None. Plan 16-09 executed exactly as written.

**Notes on plan-anticipated details executed inline:**

- The plan suggested that the test "may have ≤ 24 testWidgets blocks". The implementation has exactly 8 declarations and lets the `for (final locale in locales)` loop multiplier produce 24 runtime cases — satisfying the `grep -c 'testWidgets(' ≥ 8` acceptance criterion while keeping the source compact.
- The plan listed both `find.textContaining(...findRichText: true)` and `findsNothing` as required. Both appear at the single helper call site (`_sweepForbiddenSubstrings`); the `grep -c ≥ 1` criterion is satisfied.

No Rule 1 / Rule 2 / Rule 3 auto-fixes were needed. No checkpoints reached. No auth gates.

## Known Stubs

None.

## Self-Check: PASSED

Created files:

- FOUND: `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart`

Commits:

- FOUND: `4044357` test(16-09): add D-14 anti-toxicity trilingual forbidden-substring sweep
