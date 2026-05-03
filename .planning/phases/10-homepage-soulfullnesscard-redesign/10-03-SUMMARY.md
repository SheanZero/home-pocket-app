---
phase: 10-homepage-soulfullnesscard-redesign
plan: 03
subsystem: home/test-scaffold
tags: [wave-0, test-scaffold, fixtures, regression-guard]
dependency-graph:
  requires:
    - "Phase 9 contracts: HappinessReport, FamilyHappiness, BestJoyMomentRow, MetricResult, SharedJoyInsight"
    - "lib/features/analytics/domain/models/monthly_report.dart (MonthlyReport, MonthComparison)"
    - "lib/features/home/presentation/providers/state_shadow_books.dart (ShadowBookInfo, ShadowAggregate)"
    - "lib/features/accounting/domain/models/book.dart (Book — for ShadowBookInfo construction)"
    - "test/widget/features/home/helpers/test_localizations.dart (testLocalizedApp)"
  provides:
    - "test/helpers/happiness_test_fixtures.dart — 24 reusable fixture factories"
    - "test/widget/features/home/presentation/widgets/home_hero_card_test.dart — skeleton (20 skipped tests, 8 groups)"
    - "test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart — skeleton (8 skipped tests)"
    - "test/golden/home_hero_card_golden_test.dart — skeleton (5 skipped golden tests)"
    - "test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart — permanent CI regression guard"
  affects:
    - "Plans 10-04 / 10-05 / 10-06 / 10-07 / 10-08 — test bodies populate these scaffolds"
    - "Plan 10-08 unskips home_screen_helpers_removed_test.dart after deleting the 3 helpers"
tech-stack:
  added: []
  patterns:
    - "Direct-instantiation widget tests via testLocalizedApp helper"
    - "Single-file fixed-size SizedBox wrap for golden tests (matches soul_fullness_card_golden_test.dart, summary_cards_golden_test.dart)"
    - "Mock canvas via mocktail Mock implements Canvas with Rect / Paint fallback values"
    - "Source-grep CI regression guard via dart:io File.readAsStringSync()"
key-files:
  created:
    - "test/helpers/happiness_test_fixtures.dart (345 lines)"
    - "test/widget/features/home/presentation/widgets/home_hero_card_test.dart (132 lines)"
    - "test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart (69 lines)"
    - "test/golden/home_hero_card_golden_test.dart (68 lines)"
    - "test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart (56 lines)"
  modified: []
decisions:
  - "testWidgets's `skip` parameter is `bool?` (per flutter_test/lib/src/widget_tester.dart line 151), not `String?`. The plan's example `skip: 'pending …'` would not compile. Resolution: use `skip: true /* skip: 'pending Phase 10 implementation' */` so the rationale string remains grep-discoverable while the API contract is honored. Plain `test()` accepts a `String? skip` argument so the painter file (which uses `test`, not `testWidgets`) keeps the original string form."
  - "Paint cannot be implemented via Fake (it is a final class in dart:ui post-Flutter 3.41). Resolution: register a real `Paint()` instance as the fallback value for mocktail."
  - "Shadow book fixtures use synthetic Book instances built from Book(...) constructor with minimal fields (id, name, currency, deviceId, createdAt, isShadow=true, groupId, ownerDeviceId, ownerDeviceName). Member display names are alphabetical (TestMember1/2/3) to give golden tests deterministic ordering."
  - "Empty-list helper `fixtureShadowBooksEmpty()` returns `const []` rather than a typed empty list — relies on inference from the function return type."
metrics:
  duration: ~25 min
  completed: 2026-05-02
---

# Phase 10 Plan 03: Wave 0 Test Scaffold Summary

Wave 0 test scaffold for Phase 10 HomeHeroCard redesign — 4 skeleton test files + 1 shared fixtures file + 1 permanent CI regression guard, all compiling cleanly under `flutter analyze` and running as `flutter test` no-ops with every test skipped pending later-wave implementations.

## Tasks Completed

### Task 3.1: Shared happiness test fixtures
- **Commit:** 89e114d
- **File:** `test/helpers/happiness_test_fixtures.dart` (345 lines)
- **Fixtures inventory (24 factories):**
  - **MonthlyReport (2):** `fixtureMonthlyReportRich` (2026-04, total ¥142,800), `fixtureMonthlyReportEmpty` (all zeros)
  - **HappinessReport (3):** `fixtureHappinessReportRich` (totalSoulTx=31, all 4 main metrics Value), `fixtureHappinessReportThin` (totalSoulTx=3, sample size 3 — drives n<5 coverage caption test), `fixtureHappinessReportEmpty` (totalSoulTx=0, all 5 MetricResult Empty)
  - **FamilyHappiness (2):** `fixtureFamilyHappinessRich` (familyHighlightsSum=27, sharedJoyInsight=Value, medianSatisfaction=Value), `fixtureFamilyHappinessEmpty` (all 3 Empty)
  - **BestJoyMomentRow (2):** `fixtureBestJoyMomentRich` (¥3,000 coffee, sat=10), `fixtureBestJoyMomentAllNeutral` (¥10,000 shopping, sat=2 — D-09 CTA case)
  - **MetricResult&lt;BestJoyMomentRow&gt; wrappers (4):** `fixtureBestJoyResultRich` (sample 31), `fixtureBestJoyResultThin` (sample 3), `fixtureBestJoyResultEmpty` (Empty), `fixtureBestJoyResultAllNeutral` (sample 5)
  - **SharedJoyInsight (1):** `fixtureSharedJoyInsightRich` (cat_coffee, avg=8.5, count=8)
  - **ShadowBookInfo / ShadowAggregate (3):** `fixtureShadowBooksThree` (3 books TestMember1/2/3 with emojis 🦊/🐻/🐼), `fixtureShadowAggregateThree` (totalExpenses ¥72,500, prev ¥68,000), `fixtureShadowBooksEmpty` (empty list)
- All factories pure — no IO, no `DateTime.now()` (uses `DateTime.utc(2026, 4, 15, 14, 30)` etc.) — for golden test stability.

### Task 3.2: home_hero_card_test.dart skeleton
- **Commit:** 34033e6
- **File:** `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` (132 lines)
- **8 group blocks (20 skipped testWidgets total):**
  1. `single mode (HOMEUI-01, HOMEUI-05, HOMEUI-06)` — 3 tests
  2. `group mode (HOMEUI-03, HOMEUI-07, FAMILY-03)` — 4 tests
  3. `empty states (D-09)` — 4 tests
  4. `info icons (HOMEUI-04, D-10)` — 2 tests
  5. `tap target (D-11, Pitfall 3)` — 1 test
  6. `typography (CLAUDE.md Amount Display Style, Pitfall 10)` — 2 tests
  7. `currency resolution (D-12, CLAUDE.md Pitfall 9)` — 1 test
  8. `i18n parity (CLAUDE.md i18n rules)` — 3 tests (ja / zh / en)
- All tests use `skip: true /* skip: 'pending Phase 10 implementation' */` form; the fixtures + test_localizations imports are gated with `// ignore: unused_import` until Plan 10-08 wires bodies.

### Task 3.3: painter + golden test skeletons
- **Commit:** 9028dd1
- **File 1:** `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` (69 lines)
  - 1 group `HappinessRingsPainter`, 8 skipped `test()` cases:
    - 3 drawArc-count tests (Empty, Mixed, AllValue)
    - 2 sweep-angle tests (ratio 0.5 = pi, ratio clamps at 1.0)
    - 3 shouldRepaint tests (equal inputs, outerSweepRatio differ, trackColor differ)
  - `_MockCanvas extends Mock implements Canvas` per RESEARCH §"Pattern" line 633-712.
  - `_FakeRect` for fallback; `Paint()` instance (not Fake) registered because `Paint` is final in dart:ui.
- **File 2:** `test/golden/home_hero_card_golden_test.dart` (68 lines)
  - 1 group `HomeHeroCard golden`, 5 skipped `testWidgets` cases:
    - single mode light ja
    - family mode light ja
    - family mode dark ja
    - thin sample (n<5) light ja
    - all-neutral CTA light ja
  - `_wrap()` helper supplies MaterialApp + l10n delegates + 600x720 SizedBox.

### Task 3.4: home_screen_helpers_removed_test.dart (permanent regression guard)
- **Commit:** ba9ca83
- **File:** `test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart` (56 lines)
- **Contract:** Reads `lib/features/home/presentation/screens/home_screen.dart` via `dart:io File.readAsStringSync()` and asserts the 3 deleted-helper identifiers do not appear:
  - `_computeHappinessROI` (deleted in D-01 — misleading "budget-share" framing per FEATURES.md line 81-82)
  - `_computeSatisfaction` (deleted in D-01 — superseded by `HappinessReport.avgSatisfaction` per Phase 9 D-15)
  - `_buildLedgerRows` (deleted in D-01 — `HomeHeroCard` consumes `MonthlyReport.soulTotal/survivalTotal` directly)
- **Lifecycle:** Currently `skip: 'pending Plan 10-08 helper deletion'` because Wave 0 leaves the helpers in place (still present in `home_screen.dart` lines 115/134/258/345/362). Plan 10-08 task 8.1 deletes the helpers and **must** remove the `skip:` argument so the test becomes an active CI guard.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] testWidgets `skip` parameter is `bool?`, not `String?`**
- **Found during:** Task 3.2 verification (`flutter analyze` reported `argument_type_not_assignable` on every `skip: 'pending Phase 10 implementation'` line).
- **Issue:** The plan's example code passed a `String` to `testWidgets(...)` `skip:`. Per `flutter_test/lib/src/widget_tester.dart` line 151, the parameter is `bool? skip`. Plain `test(...)` from `package:test` does accept `String? skip` (and the painter test uses that form successfully), but `testWidgets(...)` does not.
- **Fix:** For `testWidgets` calls (in `home_hero_card_test.dart` and `home_hero_card_golden_test.dart`) replaced `skip: 'pending Phase 10 implementation'` with `skip: true /* skip: 'pending Phase 10 implementation' */`. The block comment preserves the rationale string for the acceptance grep `grep -c "skip: 'pending"` and for human readers.
- **Files modified:** `test/widget/features/home/presentation/widgets/home_hero_card_test.dart`, `test/golden/home_hero_card_golden_test.dart`
- **Commits:** 34033e6 (home_hero_card_test), 9028dd1 (golden test)

**2. [Rule 1 — Bug] `Paint` is a final class — cannot be `implement`-ed via Fake**
- **Found during:** Task 3.3 verification (`flutter analyze` reported `invalid_use_of_type_outside_library` on `class _FakePaint extends Fake implements Paint {}`).
- **Issue:** `Paint` (in `dart:ui`) became a `final` class, so external libraries cannot `implements` it. The plan's example pattern (`class _FakePaint extends Fake implements Paint {}`) was written for an earlier Flutter version.
- **Fix:** Use a real `Paint()` instance as the fallback value: `registerFallbackValue(Paint())`. Documented the rationale in a code comment so future readers understand why this differs from the `_FakeRect` pattern.
- **Files modified:** `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart`
- **Commit:** 9028dd1

**3. [Rule 1 — Bug] `import 'package:flutter/material.dart'` was unused after refactor**
- **Found during:** Task 3.2 analyzer pass (after switching to `skip: true`, no Material types remained referenced).
- **Fix:** Removed the unused import; analyzer reports 0 issues.
- **Commit:** 34033e6

**4. [Rule 1 — Bug] Dangling library doc comment in fixtures file**
- **Found during:** Task 3.1 analyzer pass (`info • Dangling library doc comment`).
- **Fix:** Added `library;` directive after the `///` doc block to attach it to the library.
- **Commit:** 89e114d

**5. [Rule 2 — Critical scaffold scaffolding] Unused-element / unused-import suppressions**
- **Issue:** Plan-spec scaffolds intentionally include helpers (`_wrap` in golden test, fixture imports in widget test) that go unused while the test bodies are placeholder `expect(true, isTrue)`. Without suppression, `flutter analyze` reports warnings.
- **Fix:** Added `// ignore_for_file: unused_import, unused_element` (golden) or per-line `// ignore: unused_import` (widget test). All suppressions are scoped to scaffold-only files; Plan 10-08 will remove them when test bodies use the imports.
- **Commits:** 34033e6, 9028dd1

## Verification

**Per-file `flutter analyze`:**
```
test/helpers/happiness_test_fixtures.dart                                           No issues found
test/widget/features/home/presentation/widgets/home_hero_card_test.dart             No issues found
test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart  No issues found
test/golden/home_hero_card_golden_test.dart                                         No issues found
test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart  No issues found
```

**Combined `flutter test` on the 4 test files (fixtures has no main):**
```
00:00 +0 ~34: All tests skipped.
```
- 20 skipped tests in `home_hero_card_test.dart`
- 8 skipped tests in `happiness_rings_painter_test.dart`
- 5 skipped tests in `home_hero_card_golden_test.dart`
- 1 skipped test in `home_screen_helpers_removed_test.dart`
- Total: 34 tests, 0 failures, 0 errors.

**Acceptance criteria grep counts:**
- `grep -c "fixture[A-Z]" test/helpers/happiness_test_fixtures.dart` → 24 (≥14 required)
- `grep -c "skip: 'pending" test/widget/features/home/presentation/widgets/home_hero_card_test.dart` → 21 (≥18 required)
- `grep -c "group(" test/widget/features/home/presentation/widgets/home_hero_card_test.dart` → 8 (≥7 required)
- `grep -c "skip: 'pending" test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` → 8 (≥8 required)
- `grep -c "skip: 'pending" test/golden/home_hero_card_golden_test.dart` → 5 (≥5 required)
- All 4 grep checks for the regression test (3 helper names + skip token) pass.

## Self-Check: PASSED

- File `test/helpers/happiness_test_fixtures.dart`: FOUND
- File `test/widget/features/home/presentation/widgets/home_hero_card_test.dart`: FOUND
- File `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart`: FOUND
- File `test/golden/home_hero_card_golden_test.dart`: FOUND
- File `test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart`: FOUND
- Commit 89e114d (Task 3.1): FOUND
- Commit 34033e6 (Task 3.2): FOUND
- Commit 9028dd1 (Task 3.3): FOUND
- Commit ba9ca83 (Task 3.4): FOUND

## Threat Flags

None — Wave 0 introduces only test scaffolds (no network, auth, file IO at trust boundaries, or schema changes). The single use of `dart:io File.readAsStringSync()` in `home_screen_helpers_removed_test.dart` reads a project-internal source file with no external input.

## Hand-off Notes for Subsequent Plans

- **Plans 10-04 / 10-05 / 10-06 / 10-07 / 10-08:** import `test/helpers/happiness_test_fixtures.dart` (relative path varies by test file location) and call the appropriate fixture factory. Numeric values are reproducible by contract — do not redefine.
- **Plan 10-04 (HappinessRingsPainter):** when implementing the painter, populate the 8 skipped tests in `happiness_rings_painter_test.dart`. The `_MockCanvas` and fallback registrations are already in place.
- **Plan 10-08 (HomeHeroCard widget):**
  1. Replace `// import 'package:home_pocket/features/home/presentation/widgets/home_hero_card.dart';` placeholders with the real import in both `home_hero_card_test.dart` and `home_hero_card_golden_test.dart`.
  2. Remove the `// ignore: unused_import` annotations once imports become live.
  3. For each skipped `testWidgets`: replace `expect(true, isTrue)` with the real assertions, and remove the `skip:` argument (or the `skip: true /* … */` form).
  4. After physically deleting `_computeHappinessROI` / `_computeSatisfaction` / `_buildLedgerRows` from `home_screen.dart`, **remove the `skip: 'pending Plan 10-08 helper deletion'` argument** from `home_screen_helpers_removed_test.dart` so the regression guard becomes active.
