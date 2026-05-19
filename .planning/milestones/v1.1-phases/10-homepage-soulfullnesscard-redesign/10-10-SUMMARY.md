---
phase: 10-homepage-soulfullnesscard-redesign
plan: 10
subsystem: home-feature
tags: [tests, widget, golden, home-hero-card]
requires:
  - test/helpers/happiness_test_fixtures.dart
  - test/widget/features/home/helpers/test_localizations.dart
  - lib/features/home/presentation/widgets/home_hero_card.dart
provides:
  - test/widget/features/home/presentation/widgets/home_hero_card_test.dart (20 widget tests)
  - test/golden/home_hero_card_golden_test.dart (5 golden tests)
  - test/golden/goldens/home_hero_card_*.png (5 baseline PNGs)
affects: [home-feature]
tech-stack:
  added: []
  patterns:
    - Pure-StatelessWidget contract testing (no ProviderScope; constructor-driven data flow per UI-SPEC line 277)
    - Per-test FixtureSnapshot composer + 6 builder helpers (rich / empty / thin / all-neutral / group-rich / group-empty-shadows)
    - Golden test fixed-size SizedBox wrap (matches summary_cards_golden_test.dart pattern)
key-files:
  created:
    - test/golden/goldens/home_hero_card_single_light_ja.png
    - test/golden/goldens/home_hero_card_family_light_ja.png
    - test/golden/goldens/home_hero_card_family_dark_ja.png
    - test/golden/goldens/home_hero_card_thin_sample_ja.png
    - test/golden/goldens/home_hero_card_all_neutral_cta_ja.png
  modified:
    - test/widget/features/home/presentation/widgets/home_hero_card_test.dart
    - test/golden/home_hero_card_golden_test.dart
decisions:
  - Used findsAtLeastNWidgets(1) for the familyHighlightsSum value '27' assertion because the same data appears both in the ring center text (size 18) and the legend value (size 14) — test asserts presence rather than uniqueness.
  - For the currency-resolution test (Pitfall #9), used CNY (which shares the ¥ symbol with JPY but adds 2 decimals) — assertion verifies the ".00" suffix to prove the constructor-passed code is honored, not a hardcoded JPY decimals=0.
metrics:
  duration: ~1h
  completed: 2026-05-02
  tests-added: 25
  goldens-added: 5
  per-file-coverage-home-hero-card: 98.8%
---

# Phase 10 Plan 10: HomeHeroCard widget + golden tests Summary

Populated the Plan 10-03 widget + golden test scaffolds for `HomeHeroCard` with real assertion bodies and generated 5 baseline golden PNGs — pinning the HOMEUI-01..07, FAMILY-03 D-08 minimum gate, D-09 four empty states, D-10 tooltip absorption, D-11 whole-card tap, and CLAUDE.md Pitfall #9 (currency resolution) + Pitfall #10 (tabular figures) contracts as executable spec.

## Tasks Completed

| # | Task | Commit | Status |
|---|------|--------|--------|
| 10.1 | Populate `home_hero_card_test.dart` (unskip + fill bodies) | `41be603` | done |
| 10.2 | Populate `home_hero_card_golden_test.dart` + generate 5 PNGs | `b75c2db` | done |
| 10.3 | Verify per-file coverage on `home_hero_card.dart` ≥70% | (verification only — 98.8% measured) | done |

## Verification

- `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart` → **20/20 passed**.
- `flutter test test/golden/home_hero_card_golden_test.dart` → **5/5 passed** (baselines generated via `--update-goldens` then re-verified in normal mode).
- `flutter analyze` (project-wide) → **0 issues**.
- `flutter test --coverage test/widget/features/home/ test/golden/home_hero_card_golden_test.dart` → **66 tests passed**.
- Per-file coverage on `lib/features/home/presentation/widgets/home_hero_card.dart` → **98.8% (327/331 lines)** — well above the 70% gate.
- `grep -c "skip:" test/widget/features/home/presentation/widgets/home_hero_card_test.dart` → **0** (every scaffold unskipped).
- `grep -c "skip:" test/golden/home_hero_card_golden_test.dart` → **0**.
- `grep -c "testWidgets(" test/widget/features/home/presentation/widgets/home_hero_card_test.dart` → **20** (≥18 plan target).

## Test Map

| Group | Test Count | Coverage Target |
|-------|-----------|-----------------|
| Single mode (HOMEUI-01, 05, 06) | 3 | 4 metrics + hero + split bar |
| Group mode (HOMEUI-03, 07, FAMILY-03) | 4 | rings + member rows + D-08 minimum gate + group-mode toggle |
| Empty states (D-09) | 4 | totalExpenses=0 / totalSoulTx=0 / thin / all-neutral |
| Info icons (HOMEUI-04, D-10) | 2 | exactly-2 cap + tap absorption |
| Tap target (D-11, Pitfall #3) | 1 | whole-card single onTap |
| Typography (Pitfall #10) | 2 | hero amountLarge + Best Joy small line tabularFigures |
| Currency resolution (D-12, Pitfall #9) | 1 | CNY decimals proves constructor honored |
| i18n parity | 3 | ja / zh / en |
| **Total widget tests** | **20** | |
| Golden tests | 5 | single light ja, family light ja, family dark ja, thin sample ja, all-neutral CTA ja |

## Golden PNG Inventory

| File | Size | Variant |
|------|------|---------|
| `home_hero_card_single_light_ja.png` | 23 KB | Single-mode rich, light theme, ja |
| `home_hero_card_family_light_ja.png` | 27 KB | Group-mode rich + 3 members, light theme, ja |
| `home_hero_card_family_dark_ja.png` | 30 KB | Group-mode rich + 3 members, dark theme, ja |
| `home_hero_card_thin_sample_ja.png` | 23 KB | Thin-sample (n=3), light theme, ja |
| `home_hero_card_all_neutral_cta_ja.png` | 23 KB | All-neutral Best Joy (sat=2), light theme, ja |

Golden image structure matches v8 mockup (hero row → trend chip on right → ja sub-line → 魂/生存 split bar → divider → 3-ring section + legend → divider → Best Joy strip → optional members section). Glyphs render as fallback boxes in the test environment (no Outfit font); structural fidelity is preserved per UI-SPEC §"Visual Reference" ("structural and proportional fidelity, not pixel-precise replication").

## Deviations from Plan

**1. [Plan-vs-reality] `find.text('27')` in group-mode rings test**
- **Found during:** Task 10.1 first run (test 4 failed)
- **Issue:** The plan specified `find.text('27')` to assert one widget, but the value `27` appears twice — once as the ring-center text (`AppTextStyles.amountMedium`, size 18) and once as the `homeFamilyHighlightsLegend` legend value (size 14, weight 600).
- **Fix:** Relaxed to `findsAtLeastNWidgets(1)`. The semantic assertion (group-mode ring renders the family-highlights value) is preserved; uniqueness is not part of the contract.
- **Files modified:** `test/widget/features/home/presentation/widgets/home_hero_card_test.dart`
- **Commit:** `41be603`

**2. [Plan-vs-reality] `find.text('🦊').or(find.text('🐻'))` syntax**
- **Found during:** Task 10.1 authoring
- **Issue:** The plan suggested `find.X.or(find.Y)`, but `Finder` has no `.or()` method in flutter_test.
- **Fix:** Asserted each emoji individually with `findsOneWidget` — strictly stronger than the plan's "any of" check.
- **Files modified:** `test/widget/features/home/presentation/widgets/home_hero_card_test.dart`
- **Commit:** `41be603`

**3. [Plan-vs-reality] No supplementary coverage tests required**
- **Found during:** Task 10.3
- **Issue:** Plan budgeted "1-3 supplementary tests" if coverage <70%.
- **Outcome:** Per-file coverage on `home_hero_card.dart` is **98.8%** (327/331 lines). All branches in the plan's "Likely uncovered branches" list (joyPerYen empty, all-neutral CTA, group + empty shadowBooks gate, family null) are covered by the existing 20 tests. No supplementary tests needed.

No auto-fixed bugs (Rule 1) or auto-added missing functionality (Rule 2) were required — the production widget from Plans 10-07a/07b/08a/08b/09 was contract-correct, and the test assertions matched the widget's behavior on the first run except for the two fixture-driven adjustments above.

## Auth Gates

None required.

## Known Stubs

None. `home_hero_card.dart` consumes 100% of its constructor inputs; no placeholder values flow to UI.

## Self-Check: PASSED

- `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` → FOUND
- `test/golden/home_hero_card_golden_test.dart` → FOUND
- `test/golden/goldens/home_hero_card_single_light_ja.png` → FOUND (23 KB)
- `test/golden/goldens/home_hero_card_family_light_ja.png` → FOUND (27 KB)
- `test/golden/goldens/home_hero_card_family_dark_ja.png` → FOUND (30 KB)
- `test/golden/goldens/home_hero_card_thin_sample_ja.png` → FOUND (23 KB)
- `test/golden/goldens/home_hero_card_all_neutral_cta_ja.png` → FOUND (23 KB)
- Commit `41be603` (Task 10.1) → FOUND in `git log`
- Commit `b75c2db` (Task 10.2 + 5 PNGs) → FOUND in `git log`
- All success criteria met: 20 widget tests green, 5 golden tests green, 5 PNGs committed, coverage 98.8% ≥ 70%, `flutter analyze` 0 issues.
