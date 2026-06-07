---
phase: 35-close-vocab-leaks-a11y-semantics-labels-w1-totalsoultx-ident
reviewed: 2026-06-02T00:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
  - lib/features/analytics/domain/models/happiness_report.dart
  - lib/features/analytics/domain/models/family_happiness.dart
  - lib/application/analytics/get_happiness_report_use_case.dart
  - lib/application/analytics/get_family_happiness_use_case.dart
  - lib/application/analytics/get_best_joy_moment_use_case.dart
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart
  - lib/features/analytics/presentation/providers/state_happiness.dart
  - test/helpers/happiness_test_fixtures.dart
  - test/unit/features/analytics/domain/models/happiness_report_test.dart
  - test/unit/features/analytics/presentation/providers/repository_providers_test.dart
  - test/unit/application/analytics/get_family_happiness_use_case_test.dart
  - test/unit/application/analytics/get_happiness_report_use_case_test.dart
  - test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart
  - test/widget/features/analytics/presentation/widgets/kpi_mini_hero_strip_test.dart
  - test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart
  - test/widget/features/home/presentation/widgets/home_hero_card_test.dart
findings:
  critical: 0
  warning: 0
  info: 2
  total: 2
status: issues_found
---

# Phase 35: Code Review Report

**Reviewed:** 2026-06-02T00:00:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found (Info-only)

## Summary

Phase 35 is a two-part vocabulary-cleanup tech-debt phase. I reviewed both changes adversarially against the listed source files, cross-referenced the full diff range (`dbb48f70^..HEAD`), and grepped the entire `lib/` + `test/` trees for leftover references, missed call sites, and semantic drift.

**35-01 (a11y Semantics labels):** The two hardcoded literals `Semantics(label: 'Survival ledger')` and `Semantics(label: 'Soul ledger')` in `list_sort_filter_bar.dart` were correctly replaced with `l10n.listLedgerDaily` / `l10n.listLedgerJoy`. Both l10n keys are confirmed present in all three ARB files (`app_ja.arb` 日常/ときめき, `app_zh.arb` 日常/悦己, `app_en.arb` Daily/Joy at lines 2135–2140). The chip `Text` labels in those same `Semantics` blocks already used these keys, so the label now matches the visible glyph — a genuine consistency fix. No leftover `'Survival ledger'` / `'Soul ledger'` label literals remain anywhere in `lib/`. The remaining 111-line diff on this file is `dart format` reflow only (line-wrapping), with zero behavioral change — every conditional, mutator call, and provider wiring is byte-identical in logic.

**35-02 (totalSoulTx → totalJoyTx rename):** The rename is complete and consistent across the whole repo. Grep for `totalSoulTx` / `totalGroupSoulTx` in `lib/` and `test/` returns zero matches. The Freezed model sources, the regenerated `.freezed.dart` files (27 occurrences each of the new names, 0 of the old — out of review scope but verified present and consistent), all 6 lib consumers, and all 9 test files use the new names. Critically, the positional `sampleSize` arguments to `Value<T>(data, sampleSize)` were NOT touched (e.g. `Value<int>(23, 30)` in `family_insight_card_test.dart` is unchanged), so the rename touched only the intended named field and introduced no off-by-one or argument-shuffle bug. Guard/conditional logic that reads the field (`report.totalJoyTx < 5` histogram gate in `analytics_screen.dart:529`; `report.totalJoyTx > 0` sub-line gate in `joy_headline_kpi_tile.dart:78`; `totalGroupJoyTx == 0` empty short-circuit in `get_family_happiness_use_case.dart:77`; `totalJoyTx == 0` co-empty short-circuit in `get_happiness_report_use_case.dart:73`) is preserved verbatim. The phase claim that these fields are in-memory-only holds: no JSON keys, no Drift column, no serialization touches the name.

No correctness, security, or robustness defects found. Two Info-level observations follow.

## Info

### IN-01: a11y label change has no asserting test coverage

**File:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart:233,266`
**Issue:** The whole point of 35-01 is correctness of the accessibility labels, yet neither widget test (`test/widget/features/list/list_sort_filter_bar_test.dart`, `list_sort_filter_bar_member_test.dart`) asserts the `Semantics.label` values for the 日常 / ときめき chips. A grep of `test/` for `listLedgerDaily` / `listLedgerJoy` / `Soul ledger` / `Survival ledger` returns no match. A future refactor could silently regress these labels back to a hardcoded or wrong string and CI would stay green. The golden tests do not cover Semantics labels (goldens are pixel comparisons; Semantics is the a11y tree).
**Fix:** Add a focused widget-test expectation, e.g.:
```dart
testWidgets('ledger chips expose localized Semantics labels', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(/* localized ListSortFilterBar, ja */);
  await tester.pumpAndSettle();
  expect(find.bySemanticsLabel('日常'), findsWidgets);
  expect(find.bySemanticsLabel('ときめき'), findsWidgets);
  handle.dispose();
});
```
This converts the manual fix into a regression-locked invariant.

### IN-02: Sibling Semantics labels in the same widget remain hardcoded English

**File:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart:158,210,299,412,496`
**Issue:** Five other `Semantics(label: ...)` strings in the same bar are still hardcoded English literals: `'Sort by'` (158), `'Show all ledgers'` (210), `'Filter by category'` (299), `'Search transactions'` (412), `'Clear all filters'` (496). This is the same class of "vocab leak / un-localized a11y label" that 35-01 set out to close — a screen-reader user in ja/zh hears mixed-language labels (localized ledger names alongside English action labels). Closing only two of seven leaks leaves the file internally inconsistent. This is explicitly outside the stated Phase 35 scope (which named only the two ledger labels), so it is informational, not a defect against the phase contract.
**Fix:** Track as follow-up tech-debt: add `listSortBySemantics`, `listShowAllLedgersSemantics`, `listFilterByCategorySemantics`, `listSearchTransactionsSemantics`, `listClearAllSemantics` (or reuse existing nearby keys such as `l10n.listClearAll`) to the three ARB files, run `flutter gen-l10n`, and swap the literals. No action required for this phase to ship.

---

_Reviewed: 2026-06-02T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
