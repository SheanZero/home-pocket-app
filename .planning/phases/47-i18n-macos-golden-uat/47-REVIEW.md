---
phase: 47-i18n-macos-golden-uat
reviewed: 2026-06-20T00:00:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - lib/application/analytics/get_joy_category_amounts_use_case.dart
  - lib/features/analytics/presentation/analytics_card_registry.dart
  - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
  - lib/features/analytics/presentation/widgets/cards/family_insight_data_card.dart
  - lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart
  - lib/features/analytics/presentation/widgets/cards/joy_spend_card.dart
  - lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart
  - lib/features/analytics/presentation/widgets/cards/within_month_trend_card.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - test/golden/analytics_screen_scroll_smoke_golden_test.dart
  - test/golden/category_donut_card_golden_test.dart
  - test/golden/category_drill_down_screen_golden_test.dart
  - test/golden/family_insight_data_card_golden_test.dart
  - test/golden/joy_calendar_card_golden_test.dart
  - test/golden/joy_spend_card_golden_test.dart
  - test/golden/satisfaction_histogram_card_golden_test.dart
  - test/golden/within_month_trend_card_golden_test.dart
  - test/widget/features/analytics/presentation/analytics_card_registry_test.dart
  - test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart
  - test/widget/features/analytics/presentation/widgets/cards/category_donut_card_test.dart
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 47: Code Review Report

**Reviewed:** 2026-06-20
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Phase 47 applies the Phase-46 review fixes (WR-01 dead currency plumbing deletion,
WR-02 donut true-total + neutral "Other" rollup, WR-03 single-pass joy use-case
refactor, WR-04 calendar inline-list refresh), deletes 3 orphan ARB section-header
keys, and authors anti-toxicity + macOS golden coverage.

Overall the work is high quality. Verified directly:
- `flutter analyze` on the changed `lib/` files: **0 issues**.
- The 14 donut widget tests + 6 registry structural tests + 36 anti-toxicity
  sweeps all pass; golden masters for every referenced `matchesGoldenFile` exist
  (including the two `category_donut_card_other_*` masters and the inline-expand
  calendar master).
- ARB trilingual parity holds: **664 keys in each** of en/ja/zh; the 3 deleted
  section-header keys (`analyticsGroupHeaderTime/Distribution/Stories`) plus their
  `@`-metadata are removed symmetrically across all three files, with **0 residual
  references** in `lib/`.
- WR-03 single-pass refactor is correct and the `entrySourceFilter` is wired to
  the `manualOnly` variant in `state_analytics.dart`.
- WR-04 `ref.listen → ref.invalidate` mirrors a DIFFERENT provider
  (`joyDayTransactionsProvider`) than the one watched, so no invalidation loop.
- Riverpod 3 conventions respected (no `Notifier`-suffix providers in new code,
  `.value` nullable reads, `ref.listen` used for the side-effecting invalidate).

No BLOCKERs found. The findings below are robustness, i18n-register, and coverage
concerns plus minor info-level items.

## Warnings

### WR-01: WR-02 "Other" arithmetic silently mis-renders when breakdown sum ≠ totalExpenses

**File:** `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:138-145, 231-251`
**Issue:** The "Other" rollup is computed as `otherAmount = total - donutTotal`,
where `total = monthly.totalExpenses` and `donutTotal = sum(top-10 L1 rollups)`.
Legend percentages now divide by `total` (the true center), while the pie slices
are drawn from the raw L1 amounts plus the Other slice. This only reconciles when
`monthly.totalExpenses == sum(all categoryBreakdowns)`. If the two upstream values
disagree (e.g. an uncategorized/unknown-category expense is counted in
`totalExpenses` but absent from `categoryBreakdowns`, or breakdowns over-count):
- `sum(breakdowns) > total` → `otherAmount < 0` → `hasOther == false`, but the
  drawn pie slices then sum to MORE than the center total and legend percents can
  exceed 100% with no reconciling row.
- `sum(breakdowns) < total` with ≤10 categories → a spurious "Other" row appears
  even though nothing was truncated, mislabeling residual uncategorized spend as
  long-tail rollup.

The current tests only exercise the perfectly-reconciled case (`totalExpenses`
exactly equals the breakdown sum), so the divergent path is unverified.
**Fix:** Either (a) assert/clamp the invariant — derive the center from
`max(total, donutTotal)` or clamp `otherAmount` to `>= 0` AND surface a residual
when `donutTotal < total` even with ≤10 rows is intentional; or (b) document and
test the `sum(breakdowns) != totalExpenses` contract explicitly. Minimum: add a
widget test with `totalExpenses` deliberately ≠ `sum(breakdowns)` to pin the
intended behavior.
```dart
// Guard against upstream drift so percentages never exceed 100%:
final donutTotal = rows.fold<int>(0, (s, r) => s + r.amount);
final reconcileTotal = total < donutTotal ? donutTotal : total; // center never < slices
final otherAmount = reconcileTotal - donutTotal;
final hasOther = otherAmount > 0;
// ...divide percents by reconcileTotal, animate center to reconcileTotal.
```

### WR-02: Anti-toxicity forbidden-list does not cover the streak/target/cross-period vocabulary ADR-012 requires

**File:** `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart:54-99`
**Issue:** The phase intent (ADR-012 anti-gamification invariants) is "no
streak/ranking/cross-period/target language," but the locked forbidden lists only
cover comparison/winner/score/rank substrings (`compare`, `winner`, `rank`,
`比較`, `对比`, etc.). They contain **no** streak (`連勝`/`streak`/`连续`),
target (`目標`/`target`/`目标`), or cross-period (`前月比`/`vs last month`/`较上月`)
tokens. The sweep therefore cannot detect a regression that ships, e.g., a
"目標まであと…" or "连续 N 天" string into one of the five swept cards — exactly
the failure class ADR-012 is meant to gate. The header comment frames the lists as
"COPIED VERBATIM" from phase-16 and "never shrink," which is fine, but copying an
incomplete list forward leaves the named invariant under-enforced.
**Fix:** Extend each locale's forbidden list with the streak / target /
cross-period tokens that ADR-012 actually forbids in the analytics surface (gate
the addition behind a CONTEXT/ADR note, per the file's own escalation rule). At
minimum add: en `streak`, `target`, `vs last`; ja `連勝`, `目標`, `前月比`,
`連続`; zh `连续`, `目标`, `较上月`, `连胜`.

### WR-03: Japanese card titles/captions leak Chinese glyphs, contradicting the JA `ときめき` glossary

**File:** `lib/l10n/app_ja.arb:1975, 1979, 1991, 1995, 2028, 2052`
**Issue:** The JA locale's canonical joy term is `ときめき` (app_ja.arb:166 `joy`,
and `analyticsCardTitlePerCategoryJoy: "ときめき · カテゴリ"` at :2110). But the
five round-5 B card titles/captions rendered THIS phase mix Chinese script into
the Japanese file:
- `analyticsCardTitleJoySpend`: `"悦己 · どこへ使った"`
- `analyticsCardCaptionJoySpend`: `"あなたの悦己支出の内訳"`
- `analyticsCardTitleJoyCalendar`: `"小确幸 · カレンダー"` (`小确幸` is *simplified* Chinese — JA/traditional would be `小確幸`)
- `analyticsCardCaptionJoyCalendar`: `"悦己の日々の手ざわり"`
- `analyticsCardTitleSatisfactionHistogram`: `"悦己 · 満足度の分布 1–10"`

These strings are shipped to JA users by `JoySpendCard`, `JoyCalendarCard`, and
`SatisfactionHistogramCard` — all in scope for this phase. The mixed register is
inconsistent with the rest of the JA glossary and the per-category-joy keys.
(Pre-existing: Phase 47 only deleted the section-header keys and did not touch
these lines — but they are the rendered copy of the cards under review.)
**Fix:** Normalize these JA values to the `ときめき`/`小さな幸せ` register used
elsewhere in the JA file, e.g. `"ときめき · どこへ使った"`,
`"ときめき · カレンダー"`, `"ときめき · 満足度の分布 1–10"`. Update all three ARB
files only if the term changes cross-locale; here only JA needs correcting. Re-run
`flutter gen-l10n` and re-baseline the affected JA goldens on macOS.

### WR-04: `within_month_trend_card_golden_test` omits the `currentLocaleProvider` override used by every sibling golden

**File:** `test/golden/within_month_trend_card_golden_test.dart:57-64`
**Issue:** Every other card golden in this phase overrides
`locale_providers.currentLocaleProvider` in its `ProviderScope` so locale-driven
formatting resolves deterministically. This file omits it. It happens to pass
because `WithinMonthTrendCard` reads copy only via `S.of(context)` (driven by
`MaterialApp.locale`) and does not read `currentLocaleProvider`. But this is a
latent fragility: if the card (or a child it adopts) later reads
`currentLocaleProvider`, the unoverridden auto-dispose provider will fall back to
its real implementation and the ja/zh/en masters could silently diverge or hang on
a real DB read.
**Fix:** Add the locale override for parity with the other golden harnesses:
```dart
overrides: [
  locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
  withinMonthCumulativeTrendProvider(/* ... */).overrideWith((_) async => trend),
],
```

## Info

### IN-01: `_ctx()` boilerplate duplicated across all six card files

**File:** `lib/features/analytics/presentation/widgets/cards/*.dart` (each `_ctx()`)
**Issue:** Every card re-declares a near-identical private `_ctx()` building a
minimal `AnalyticsCardContext` with `isGroupMode: false` and `locale: Locale('ja')`
placeholders, solely to call its own `*RefreshTargets`. This is a small,
intentional decoupling cost (the cards must build independently of the shell), but
it is repeated logic that can drift from `AnalyticsCardContext`'s field set.
**Fix:** Optional — a `AnalyticsCardContext.minimal({bookId, startDate, endDate,
joyMetricVariant})` factory would centralize the placeholder defaults so a new
required field is added in one place.

### IN-02: `_LegendRow` keeps a fixed 18px trailing `SizedBox` for non-tappable rows

**File:** `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart:328-332`
**Issue:** The non-tappable "Other" row substitutes a hardcoded
`SizedBox(width: 18)` to match the chevron's width. The chevron is
`Icon(..., size: 18)`, so 18 is a magic number coupling the two sites; if the
chevron size changes, alignment silently breaks.
**Fix:** Extract `const _chevronSize = 18.0;` and use it for both the `Icon` size
and the spacer width.

### IN-03: `forbiddenEn` contains the bare substring `'vs'`, risking future false positives

**File:** `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart:58`
**Issue:** `'vs'` is matched via `find.textContaining('vs')`, which would also fire
on legitimate words containing "vs" (none today, but e.g. a future "savings" label
renders "...vs..."? no — but "advsearch"/proper nouns could). Low risk given the
analytics copy, noted for awareness; the same applies to `'score'`/`'rank'` as
substrings.
**Fix:** Optional — anchor to word boundaries (regex) if false positives ever
appear; not actionable now.

---

_Reviewed: 2026-06-20_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
