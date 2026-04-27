# Phase 05: medium-fixes - Research

## RESEARCH COMPLETE

**Date:** 2026-04-27  
**Purpose:** Research what the planner needs to create executable plans for Phase 5 MEDIUM fixes.

## Phase Scope

Phase 5 closes `MED-01` through `MED-08`:

- Close all open MEDIUM findings in `.planning/audit/issues.json`.
- Remove the cross-layer `CategoryService` naming collision.
- Extract user-visible hardcoded CJK UI strings to ARB and `S.of(context)`.
- Maintain ARB parity and preserve OCR placeholders.
- Remove live `lib/` references to deprecated MOD-009-era numbering/paths.
- Enforce money display formatting and `AppTextStyles.amount*` usage.
- Preserve behavior and keep every touched file at >=80% coverage.

## Current Evidence

### MEDIUM findings

`.planning/audit/issues.json` contains two open MEDIUM findings:

- `RD-001`: `lib/application/accounting/category_service.dart` duplicates the `CategoryService` class name used by infrastructure.
- `RD-002`: `lib/infrastructure/category/category_service.dart` is the companion duplicate.

The user locked the resolution in `05-CONTEXT.md`: keep the application-layer business service name, rename the infrastructure static localization helper to `CategoryLocaleService`.

### CategoryService collision

Relevant current files:

- `lib/application/accounting/category_service.dart` — business logic: resolves ledger type and L1 category from repositories. Keep this as `CategoryService`.
- `lib/infrastructure/category/category_service.dart` — static category localization helper with large locale maps. Rename to `CategoryLocaleService` and file `category_locale_service.dart`.
- `lib/application/accounting/category_localization_service.dart` — currently imports infrastructure helper as `infra.CategoryService`; update to `infra.CategoryLocaleService`.
- `lib/features/accounting/presentation/providers/repository_providers.dart` — exposes application `CategoryService`; should remain valid.
- `lib/application/voice/fuzzy_category_matcher.dart` and related tests — use the business `CategoryService`; should remain valid.

Planning implication: make the rename its own early plan because it reduces ambiguity before ARB/CJK work.

### Hardcoded CJK hotspots

Known user-visible hotspots from targeted scan:

- `lib/features/home/presentation/screens/home_screen.dart`
  - `'今月の支出'`
  - `'帳 本'`
  - `'最近の取引'`
  - `'すべて見る'`
  - `'取引がまだありません'`
- `lib/features/home/presentation/widgets/soul_fullness_card.dart`
  - `'灵魂の充実度'`
  - `'満足度'`
  - `'幸福ROI'`
  - `'最近の灵魂支出'`
- `lib/features/accounting/presentation/screens/voice_input_screen.dart`
  - `'マイクへのアクセスを許可してください'`
- Analytics widgets contain CJK/yen labels that should route through localization/formatter services:
  - `lib/features/analytics/presentation/widgets/daily_expense_chart.dart`
  - `lib/features/analytics/presentation/widgets/expense_trend_chart.dart`

Intentional CJK data should be whitelisted:

- `lib/application/voice/voice_text_parser.dart`
- `lib/application/voice/voice_satisfaction_estimator.dart`
- `lib/application/voice/fuzzy_category_matcher.dart`
- `lib/infrastructure/ml/merchant_database.dart`
- `lib/infrastructure/i18n/formatters/date_formatter.dart`
- `lib/infrastructure/i18n/formatters/number_formatter.dart`
- `lib/infrastructure/category/category_locale_service.dart` after rename
- comments that demonstrate language examples

Planning implication: add a committed scanner/test after the extraction plan, not just manual `rg`.

### ARB state

Relevant files:

- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_zh.arb`
- `lib/generated/app_localizations*.dart`

Current ARB files already include many home/voice/OCR keys, including:

- `homeMonthlyExpense`, `homeSurvivalExpense`, `homeSoulExpense`
- `homeSoulFullness`, `homeHappinessROI`
- `homeRecentSoulTransaction`
- `ocrScan`, `ocrScanTitle`, `ocrHint`

The user explicitly chose to normalize relevant ARB key names during Phase 5, not just add missing keys. This means planning must budget for getter renames, call-site changes, and regenerated localization files.

Planning implication: make ARB audit/parity a Wave 0 or early plan before broad UI replacements.

### MOD-009 live code references

Targeted `lib/` scan found:

- `lib/infrastructure/ml/merchant_database.dart:41`
  - Current comment: "This is the shared infrastructure — used by MOD-004 OCR and MOD-009 Voice."

No active `lib/` imports with `MOD-009`/`mod009` paths were found. Historical docs contain many MOD-009 references, but those are out of Phase 5 scope and deferred to Phase 7.

Planning implication: this is a small cleanup plus a lib-only scan assertion.

### Money display hotspots

Already-compliant examples:

- `lib/features/accounting/presentation/widgets/amount_display.dart`
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart`
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`
- `lib/features/accounting/presentation/screens/voice_input_screen.dart`
- `lib/features/home/presentation/widgets/month_overview_card.dart`
- `lib/features/home/presentation/widgets/ledger_comparison_section.dart`
- `lib/features/home/presentation/widgets/home_transaction_tile.dart`
- `lib/features/home/presentation/widgets/soul_fullness_card.dart`

Likely non-compliant monetary display hotspots:

- `lib/features/analytics/presentation/widgets/category_breakdown_list.dart`
  - raw `'¥${breakdown.amount}'`
- `lib/features/analytics/presentation/widgets/daily_expense_chart.dart`
  - raw `'$day日\n¥${rod.toY.toInt()}'`
- `lib/features/analytics/presentation/widgets/ledger_ratio_chart.dart`
  - raw `'¥$amount'`
- `lib/features/analytics/presentation/widgets/budget_progress_list.dart`
  - raw `'¥${progress.spentAmount} / ¥${progress.budgetAmount}'`
  - raw `'Remaining: ¥${progress.remainingAmount}'`
  - raw `'Exceeded: ¥${progress.remainingAmount.abs()}'`
- `lib/features/analytics/presentation/widgets/summary_cards.dart`
  - raw `'¥${_formatAmount(amount)}'`

Planning implication: analytics should probably get a focused plan covering both CJK labels and money formatting/style tests.

## Recommended Plan Split

### Plan 05-01 — CategoryLocaleService rename and collision guard

Purpose:

- Close `RD-001`/`RD-002` naming ambiguity.
- Rename infrastructure helper via `git mv`.
- Update `category_localization_service.dart`.
- Add architecture test preventing future cross-layer service-name collisions.
- Add category localization map regression/consistency test.

Requirements: `MED-01`, `MED-02`, part of `MED-05`.

### Plan 05-02 — ARB audit, parity, and key normalization

Purpose:

- Audit existing ARB key usage.
- Normalize relevant home/analytics/accounting key names per user decision.
- Preserve `ocrScan`, `ocrScanTitle`, `ocrHint` with metadata.
- Add ARB parity test/script.
- Run `flutter gen-l10n`.

Requirements: `MED-03`, `MED-04`, `MED-05`.

### Plan 05-03 — Home/accounting UI CJK extraction

Purpose:

- Replace user-visible hardcoded UI copy in `home_screen.dart`, `soul_fullness_card.dart`, and `voice_input_screen.dart`.
- Use `S.of(context)` and existing/new ARB getters.
- Add/update widget tests where touched files need coverage.

Requirements: `MED-03`, `MED-08`.

### Plan 05-04 — Analytics localization and money display enforcement

Purpose:

- Localize analytics chart/list labels.
- Route currency strings through `FormatterService.formatCurrency`.
- Style real monetary values with `AppTextStyles.amount*`.
- Add focused tests verifying `FontFeature.tabularFigures()` survives in touched money widgets.

Requirements: `MED-03`, `MED-07`, `MED-08`.

### Plan 05-05 — MOD-009 lib cleanup and scan gates

Purpose:

- Rewrite live `lib/` MOD-009 comments to capability language.
- Add lib-only MOD-009 scan assertion.
- Add/extend hardcoded CJK scanner with whitelist.
- Verify zero user-visible CJK outside approved whitelist.
- Close remaining MEDIUM entries in `issues.json` after all fixes land.

Requirements: `MED-01`, `MED-03`, `MED-06`, `MED-08`.

## Recommended Wave Structure

- **Wave 0:** Plan 05-02 ARB audit/parity/normalization. It defines the localization surface used by later UI plans.
- **Wave 1:** Plan 05-01 CategoryLocaleService rename. It is mostly independent of ARB key normalization, but should happen before final scan gates.
- **Wave 2:** Plans 05-03 and 05-04 can run after ARB normalization if file scopes remain disjoint enough.
- **Wave 3:** Plan 05-05 final scan gates and `issues.json` closure after the code fixes land.

## Verification Commands

Core commands planners should include where relevant:

```bash
flutter gen-l10n
dart format .
flutter analyze
flutter test
dart run scripts/coverage_gate.dart --files <touched-files> --threshold 80 --lcov coverage/lcov_clean.info
rg -n "import.*infrastructure/category/category_service" lib test
rg -n "MOD-009|mod009" lib --glob "*.dart" --glob "!lib/generated/**"
```

The planner should add exact scanner commands/tests once it chooses the concrete scanner implementation.

## Risks and Mitigations

- **ARB getter rename churn:** Normalize only keys touched by Phase 5 and verify all generated getter call sites compile.
- **False-positive CJK scanner:** Encode path/pattern whitelist from `05-CONTEXT.md` before making the scanner blocking.
- **Accidental doc churn:** Exclude `docs/` and `doc/` from MOD-009 scan and from this phase's file list.
- **Money style overreach:** Apply `AppTextStyles.amount*` only to real monetary values, not percentages/status labels.
- **Coverage burden:** Each plan must list touched files and run the per-file coverage gate; add characterization/widget tests before refactors where baseline coverage is below 80%.

## Validation Architecture

The validation strategy for Phase 5 should use existing Flutter test infrastructure:

- Unit/architecture tests for service-name collision guard, ARB parity, CJK scanner, and MOD-009 scan.
- Widget tests for localized UI strings and money widget style usage.
- Existing `flutter gen-l10n`, `flutter analyze`, and `flutter test` gates.
- Per-plan `coverage_gate.dart` using the exact touched-file list.

Recommended validation map:

- `MED-01`: `issues.json` MEDIUM status check in final plan.
- `MED-02`: architecture test + old import grep.
- `MED-03`: CJK scanner + widget tests.
- `MED-04`: ARB parity test + `flutter gen-l10n`.
- `MED-05`: ARB static reference audit + OCR metadata assertions.
- `MED-06`: lib-only MOD-009 scan.
- `MED-07`: focused money-display widget/style tests.
- `MED-08`: coverage gate + `flutter analyze` + `flutter test`.
