---
phase: 16
plan: 08
subsystem: analytics/presentation
tags: [statsui-v2, presentation-layer, widget, golden, tdd]
requires:
  - 16-02  # ARB i18n keys (analyticsLedger* + analyticsCardTitleLedgerThisWindow)
  - 16-03  # Domain models (SoulLedgerSnapshot, SurvivalLedgerSnapshot, SoulVsSurvivalSnapshot)
  - 16-06  # Riverpod providers (soulVsSurvivalSnapshotProvider + soulVsSurvivalSnapshotFamilyProvider)
provides:
  - SoulVsSurvivalCard
affects:
  - lib/features/analytics/presentation/widgets/  # +1 new widget file
  - lib/l10n/  # +1 ARB key (analyticsLedgerFamilyError) added across en/ja/zh
  - test/widget/features/analytics/presentation/widgets/  # +1 test file
  - test/golden/  # +1 golden test file + 4 PNG baselines
tech-stack:
  added: []  # no new deps; uses already-pinned flutter_riverpod, flutter_test
  patterns:
    - consumer-widget-async-when           # AsyncValue.when over the snapshot provider
    - sealed-pattern-switch                # switch (result) over MetricResult<SoulVsSurvivalSnapshot>
    - type-system-d04-gate                 # _SurvivalCell cannot render avgSatisfaction (model lacks the field)
    - dual-async-value-split               # family AsyncValue split: loading/error/Empty/Value
    - intrinsic-height-two-column          # solo two-column equal-height layout
    - labeled-row-grid                     # group 2x2: single label per row + cells
    - dark-light-golden                    # 4 golden PNG variants (solo/group × light/dark)
key-files:
  created:
    - lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart
    - test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart
    - test/golden/soul_vs_survival_card_golden_test.dart
    - test/golden/goldens/soul_vs_survival_card_light_ja.png
    - test/golden/goldens/soul_vs_survival_card_dark_ja.png
    - test/golden/goldens/soul_vs_survival_card_group_light_ja.png
    - test/golden/goldens/soul_vs_survival_card_group_dark_ja.png
  modified:
    - lib/l10n/app_en.arb        # +1 key: analyticsLedgerFamilyError
    - lib/l10n/app_ja.arb        # +1 key: analyticsLedgerFamilyError
    - lib/l10n/app_zh.arb        # +1 key: analyticsLedgerFamilyError
decisions:
  - "Added analyticsLedgerFamilyError ARB key during execution per Plan 16-08 Task 1 step 4c(ii) — the planner anticipated this discovery; key is added across all 3 locales (en: 'Family data unavailable', ja: '家族データを取得できません', zh: '无法获取家庭数据')."
  - "Refactored the Group-mode row label from 'inside each cell' to 'single _LabeledRow shell wrapping the cell pair'. The original sketch put labels inside both _SoulCell and _SurvivalCell which would duplicate the You/Family label twice per row — defeating the purpose of a unique row identifier. The _LabeledRow widget owns the label, the cell pair owns the metrics. Tests caught this regression on the first GREEN run."
  - "Family AsyncValue split honored explicitly per Plan revision iteration 1: loading → LinearProgressIndicator skeleton, error → analyticsLedgerFamilyError caption, Empty → analyticsLedgerFamilyEmpty caption, Value → family Soul + Survival cells. This is the WARNING 7 fix from the planner."
  - "D-04 type-system gate enforced by the domain model alone: _SurvivalCell takes a SurvivalLedgerSnapshot which has no avgSatisfaction field; the cell renders 2 numeric rows (count + spend) and CANNOT render avg sat. grep confirms no survival.avgSatisfaction access in the widget code."
  - "All forbidden anti-toxicity literals (compare/versus/better/worse/winner/loser/vs) verified absent in the widget source via grep — anti-toxicity widget assertion is sourced from ARB keys (which are descriptive engagement-axis copy per D-12) so the widget itself cannot leak forbidden framing."
metrics:
  duration: ~30 minutes
  completed: 2026-05-20
  tasks: 3
  files_created: 7
  files_modified: 3
  tests_added: 14  # 10 widget + 4 golden
  loc_added: ~1014  # widget 472 + widget test 399 + golden test 143 + ARB +3 lines × 3
---

# Phase 16 Plan 08: SoulVsSurvivalCard Widget Summary

Built `SoulVsSurvivalCard` (STATSUI-V2-01) — the engagement-axis presentation surface that supersedes the misleading "satisfaction comparison" framing. Widget renders two layouts: solo two-column (Soul | Survival) and group 2×2 grid (You/Family × Soul/Survival). Soul column carries the asymmetric avg satisfaction row (D-03); Survival column literally cannot render satisfaction (D-04 type-system gate). All UI text via `S.of(context)`; all amounts via `NumberFormatter.formatCurrency` + `AppTextStyles.amountMedium`. Soul accent `#47B88A`; Survival accent `#5A9CC8`. 10 widget tests + 4 golden PNGs (solo + group, light + dark in ja locale) committed and stable.

## What Was Built

### Task 1 — `SoulVsSurvivalCard` widget (commit `8809768`)

**File:** `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` (472 lines)

A `ConsumerWidget` parameterized by `bookId / startDate / endDate / currencyCode / locale / isGroupMode`. Top-level structure:

```
Card(borderRadius 14, EdgeInsets.all(14), context.wmCard)
└── Column
    ├── Text(analyticsCardTitleLedgerThisWindow, titleLarge)
    └── asyncSnapshot.when(
          loading: SizedBox(height: 200),
          error: AnalyticsCardErrorState(onRetry: invalidate),
          data: switch (result) {
            Empty: _EmptyBody (analyticsLedgerEmpty caption),
            Value: isGroupMode ? _GroupGrid : _SoloTwoColumn,
          },
        )
```

**`_SoloTwoColumn`:** `IntrinsicHeight + Row` with `Expanded(_SoulCell) + VerticalDivider + Expanded(_SurvivalCell)`. Equal-height columns guaranteed by `IntrinsicHeight`.

**`_GroupGrid`:** `Column` with two `_LabeledRow` children (You + Family). Each `_LabeledRow` is `Row[label SizedBox(width:64), Expanded(child)]` so the row label appears exactly ONCE per row (not duplicated across cells). The Family row branches on the family `AsyncValue`:

| Family AsyncValue | Rendered body |
|---|---|
| `loading` | `_FamilyLoadingBody` → `LinearProgressIndicator` skeleton |
| `error` | `_FamilyCaptionBody(analyticsLedgerFamilyError)` |
| `Empty<...>()` (D-20) | `_FamilyCaptionBody(analyticsLedgerFamilyEmpty)` |
| `Value(:final data)` | `IntrinsicHeight + Row[_SoulCell, divider, _SurvivalCell]` |

**`_SoulCell`:** Container with `context.wmSoulTagBg` background + 8px padding. Renders: column header ("Soul" → `AppColors.soul`), then 3 numeric rows (count, spend, avg sat). All numbers in `AppTextStyles.amountMedium` (tabular figures).

**`_SurvivalCell`:** Container with `context.wmSurvivalTagBg` background + 8px padding. Renders: column header ("Survival" → `AppColors.survival`), then 2 numeric rows (count, spend). **No avg sat row — `SurvivalLedgerSnapshot` lacks the field; D-04 type-system gate enforces this at compile time.**

### Task 2 — Widget tests (commit `bdbda2c` — TDD RED)

**File:** `test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart` (399 lines, 10 testWidgets)

10 cases covering the full UI-SPEC state matrix plus D-04 / D-05 / D-20 invariants:

| # | Name | What it verifies |
|---|---|---|
| 1 | solo Value | title + Soul/Survival column headers + count/spend/avg-sat text + IntrinsicHeight marker |
| 2 | solo Empty (D-05) | analyticsLedgerEmpty caption rendered; no column headers |
| 3 | group Value all 4 cells | You + Family labels + 4 cells populated; 2 avg-sat instances (Soul cells only) |
| 4 | group D-20 family-empty | family row shows analyticsLedgerFamilyEmpty caption; no family numeric values |
| 5 | group D-05 (single-book Empty) | entire card renders Empty caption; no You / Family rows |
| 6 | loading placeholder | title visible, no column headers; non-completing provider |
| 7 | error → AnalyticsCardErrorState | AnalyticsCardErrorState widget rendered |
| 8 | D-04 invariant | `find.textContaining('平均満足')` exactly 1 widget in solo Value mode |
| 9 | group + family LOADING | LinearProgressIndicator present; Empty caption absent |
| 10 | group + family ERROR | analyticsLedgerFamilyError caption present; Empty caption absent; no family numerics |

Tests use `createLocalizedWidget` from `test/helpers/test_localizations.dart` with `overrides` to drive the provider state. `_locale = Locale('ja')`; `_currencyCode = 'JPY'`; fixed `_startDate / _endDate / _bookId` constants for determinism.

### Task 3 — Golden tests (commit `702a57b`)

**File:** `test/golden/soul_vs_survival_card_golden_test.dart` (143 lines, 4 goldens)

Capture deterministic PNG baselines for visual regression:

| Golden | Dimensions | Theme | Mode |
|---|---|---|---|
| `soul_vs_survival_card_light_ja.png` | 360×360 | Light | Solo |
| `soul_vs_survival_card_dark_ja.png` | 360×360 | Dark | Solo |
| `soul_vs_survival_card_group_light_ja.png` | 360×500 | Light | Group |
| `soul_vs_survival_card_group_dark_ja.png` | 360×500 | Dark | Group |

Goldens use `ProviderScope` overrides on `soulVsSurvivalSnapshotProvider` + `soulVsSurvivalSnapshotFamilyProvider` to drive the widget deterministically with fixed Soul (5/1500/7.4) + Survival (8/12000) snapshots; family snapshot uses Soul (12/3500/6.8) + Survival (18/24000). Baselines generated via `flutter test --update-goldens` and verified stable on second run.

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│ AnalyticsScreen (Plan 16-10 will integrate this)                    │
│   SoulVsSurvivalCard(bookId:..., isGroupMode:..., ...)              │
└────────────────────────┬────────────────────────────────────────────┘
                         │ ref.watch
                         ▼
┌────────────────────────────────────────────────────────────────────┐
│ state_ledger_snapshot.dart (Plan 16-06)                            │
│   soulVsSurvivalSnapshotProvider           (single-book)            │
│   soulVsSurvivalSnapshotFamilyProvider     (D-20 gated; group only) │
└────────────────────────┬────────────────────────────────────────────┘
                         │ AsyncValue<MetricResult<SoulVsSurvivalSnapshot>>
                         ▼
┌────────────────────────────────────────────────────────────────────┐
│ SoulVsSurvivalCard (THIS WIDGET)                                    │
│                                                                     │
│   Solo mode:                                                        │
│     IntrinsicHeight + Row                                           │
│       _SoulCell (count/spend/avgSat) ▍ _SurvivalCell (count/spend) │
│                                                                     │
│   Group mode:                                                       │
│     Column                                                          │
│       _LabeledRow("You")  → [_SoulCell, _SurvivalCell]              │
│       Divider                                                       │
│       _LabeledRow("Family") → family AsyncValue branch:             │
│         loading → LinearProgressIndicator                           │
│         error   → analyticsLedgerFamilyError caption                │
│         Empty   → analyticsLedgerFamilyEmpty caption (D-20)         │
│         Value   → [_SoulCell, _SurvivalCell]                        │
└────────────────────────────────────────────────────────────────────┘
```

## Verification

- `flutter analyze lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` → **No issues found** (0)
- `flutter analyze test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart` → **No issues found** (0)
- `flutter analyze test/golden/soul_vs_survival_card_golden_test.dart` → **No issues found** (0)
- `flutter analyze` (full project) → **No issues found** (0)
- `flutter test test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart` → **10/10 passing** (`+10: All tests passed!`)
- `flutter test test/golden/soul_vs_survival_card_golden_test.dart` → **4/4 passing** (`+4: All tests passed!`) — stable on second run after `--update-goldens` baseline generation.
- D-04 grep check: `grep -E 'survival\.avgSatisfaction|survivalRow\.avgSat' lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` → empty (confirmed)
- Anti-toxicity grep check: `grep -iE 'compare|versus|better|worse|winner|loser|vs ' lib/features/.../soul_vs_survival_card.dart | grep -v '//'` → empty (confirmed)
- ARB key references in widget: 14 hits across all 10 expected keys (`analyticsCardTitleLedgerThisWindow`, `analyticsLedgerColumn{Soul,Survival}`, `analyticsLedgerRow{You,Family}`, `analyticsLedgerCell{Entries,AvgSat}`, `analyticsLedger{Empty,FamilyEmpty,FamilyError}`).
- Acceptance criteria checks (all pass):
  - `class SoulVsSurvivalCard extends ConsumerWidget` — 1
  - `_SoulCell` references — 5
  - `_SurvivalCell` references — 5
  - `IntrinsicHeight` — 4
  - `AppColors.soul` — 1
  - `AppColors.survival` — 1
  - `BorderRadius.circular(14)` — 1
  - `EdgeInsets.all(14)` — 1
  - `AppTextStyles.amountMedium` — 5
  - `NumberFormatter.formatCurrency` — 2

## Layer-Purity Check

`lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` imports:
- `flutter/material.dart` (allowed)
- `flutter_riverpod/flutter_riverpod.dart` (allowed; presentation layer)
- `core/theme/*` (allowed; cross-feature core)
- `generated/app_localizations.dart` (allowed; i18n)
- `infrastructure/i18n/formatters/number_formatter.dart` (allowed; presentation may consume infrastructure formatters)
- `features/analytics/domain/models/*` (allowed; presentation may consume domain)
- `features/analytics/presentation/providers/state_ledger_snapshot.dart` (allowed; same feature, same layer)
- `features/analytics/presentation/widgets/analytics_card_error_state.dart` (allowed; same feature, same layer)

**No imports from `lib/data/`** — CLAUDE.md Pitfall #2 honored.

## CLAUDE.md Rule Adherence

- ✅ All UI text via `S.of(context)` — never hardcoded strings.
- ✅ Currency via `NumberFormatter.formatCurrency(amount, currencyCode, locale)`.
- ✅ All monetary values use `AppTextStyles.amountMedium` (tabular figures).
- ✅ Theme-dependent colors via `context.wm*` extensions; brand accents (`AppColors.soul/survival`) stay stable across themes.
- ✅ Widget parameter pattern: bookId/locale/currencyCode all received as required ctor params (no hardcoded defaults).
- ✅ Immutability: widget is a `StatelessWidget`/`ConsumerWidget`; all sub-widgets are stateless; no mutation.
- ✅ File organization: 472 lines, single feature widget; 7 small private sub-widgets each <80 lines.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Refactored row labels from per-cell to per-row**

- **Found during:** Task 2 (TDD GREEN — running test cases 3 and 4 produced "Found 2 widgets with text 'あなた'" failures)
- **Issue:** The initial planner sketch placed the row label inside both `_SoulCell` and `_SurvivalCell`, so the "You" / "Family" label was rendered twice per row, breaking the row-label-uniqueness contract.
- **Fix:** Introduced a new `_LabeledRow` widget that owns the label exactly once per row; `_SoulCell` and `_SurvivalCell` no longer accept a `label` parameter in the group-mode path (they still accept it as a `String?` for API uniformity, but it's always passed `null` from `_GroupGrid`).
- **Files modified:** `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart`
- **Commit:** `8809768`

### Anticipated ARB additions

**2. [Plan-anticipated] Added `analyticsLedgerFamilyError` ARB key across en/ja/zh**

- **Why:** Plan 16-08 Task 1 step 4c(ii) explicitly anticipated this discovery: when the family `AsyncValue` is in the `error` branch, the widget needs an error-caption string. The planner verified during task generation that `analyticsErrorGeneric` does not exist in the ARB files and instructed the executor to add `analyticsLedgerFamilyError` instead (with three-locale values: en "Family data unavailable", ja "家族データを取得できません", zh "无法获取家庭数据").
- **Trilingual values:** Match the planner's recommendation exactly.
- **Generated localizations regenerated:** `flutter gen-l10n` succeeded; `lib/generated/app_localizations_{en,ja,zh}.dart` now expose `String get analyticsLedgerFamilyError`. (Generated files are gitignored per `.gitignore` — they regenerate on every `flutter pub get` / `gen-l10n` run.)
- **Files modified:** `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`
- **Commit:** `bdbda2c`

## Deferred Issues (out of scope per SCOPE BOUNDARY rule)

The following pre-existing test failures exist on the base commit `ed5399a` and are NOT caused by this plan's changes (verified by checking that the failing test files are byte-identical between HEAD and the base):

- `test/widget/features/analytics/presentation/widgets/best_joy_story_strip_test.dart` — 2 test cases fail looking for stale Japanese strings ("今月の最大ハイライトはまだ見つからない", "今月の最大ハイライト N回") that no longer match the current ARB values ("最大ハイライトはまだ見つからない" without "今月" prefix). Looks like an upstream ARB refactor not propagated to the test fixtures.
- `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` — 3 test cases fail looking for stale strings ("今月、家族の小確幸 23回", "みんなで [食費] が好きみたい (n=5, 平均8.2/10)", "共通のお気に入り品目はまだ集計できません — もう少し記録してみよう") — same root cause.

These failures total 5 and are unrelated to Soul-vs-Survival — out of Plan 16-08 scope. They should be addressed in a separate hygiene plan; logging them here for traceability.

## TDD Gate Compliance

Plan 16-08 follows the per-task TDD pattern (`tdd="true"` on Tasks 1 + 2). Gate sequence in git log:

- ✅ RED gate: `bdbda2c test(16-08): add failing widget tests for SoulVsSurvivalCard` — confirmed failing via `flutter test ... soul_vs_survival_card_test.dart` returning compilation error "Method not found: 'SoulVsSurvivalCard'".
- ✅ GREEN gate: `8809768 feat(16-08): implement SoulVsSurvivalCard widget` — all 10 widget tests pass.
- ✅ Golden gate (Task 3): `702a57b test(16-08): add golden tests for SoulVsSurvivalCard` — 4 PNGs generated via `--update-goldens` and verified stable on second run.

No REFACTOR commit was needed — the single in-implementation refactor (labels per row vs per cell) was applied inline before GREEN was committed.

## Self-Check: PASSED

Created files:
- FOUND: `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart`
- FOUND: `test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart`
- FOUND: `test/golden/soul_vs_survival_card_golden_test.dart`
- FOUND: `test/golden/goldens/soul_vs_survival_card_light_ja.png`
- FOUND: `test/golden/goldens/soul_vs_survival_card_dark_ja.png`
- FOUND: `test/golden/goldens/soul_vs_survival_card_group_light_ja.png`
- FOUND: `test/golden/goldens/soul_vs_survival_card_group_dark_ja.png`

Modified files:
- FOUND: `lib/l10n/app_en.arb` (+1 ARB key: analyticsLedgerFamilyError)
- FOUND: `lib/l10n/app_ja.arb` (+1 ARB key)
- FOUND: `lib/l10n/app_zh.arb` (+1 ARB key)

Commits:
- FOUND: `bdbda2c` test(16-08): add failing widget tests for SoulVsSurvivalCard
- FOUND: `8809768` feat(16-08): implement SoulVsSurvivalCard widget (STATSUI-V2-01)
- FOUND: `702a57b` test(16-08): add golden tests for SoulVsSurvivalCard
