# Phase 5: MEDIUM Fixes - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 5 resolves every MEDIUM-severity cleanup item in the current milestone:

- Close all open MEDIUM findings in `.planning/audit/issues.json`.
- Eliminate the dual `CategoryService` naming collision.
- Extract user-visible hardcoded CJK UI strings to ARB/localization access.
- Preserve ARB key parity across Japanese, Chinese, and English.
- Remove live `lib/` references to deprecated MOD-009-era code paths or module numbering.
- Ensure real monetary displays use both currency formatting and amount text styles that preserve tabular figures.

This remains a pure cleanup/refactor phase. User-visible behavior, historical architecture documentation, and feature scope do not change in Phase 5.

</domain>

<decisions>
## Implementation Decisions

### CategoryService Split
- **D-01:** Rename only `lib/infrastructure/category/category_service.dart`'s static localization helper to `CategoryLocaleService`; keep `lib/application/accounting/category_service.dart` as the accounting business service.
- **D-02:** Use `git mv` from `lib/infrastructure/category/category_service.dart` to `lib/infrastructure/category/category_locale_service.dart`, update all imports, and do not keep a deprecated compatibility re-export.
- **D-03:** Keep the static category translation map implementation in this phase, but add a consistency/regression test around it. Full ARB-driven category translation remains deferred to `FUTURE-ARCH-01`.
- **D-04:** Add a stricter architecture test that prevents cross-layer service name collisions, including the `CategoryService` case, so the same ambiguity cannot return later.

### Hardcoded CJK Boundary
- **D-05:** Only user-visible UI copy is in scope for CJK extraction: screen/widget titles, buttons, empty states, toast/snackbar messages, and chart labels.
- **D-06:** Explicitly whitelist intentional language data: voice/NLP dictionaries, merchant seed data, date/number formatter outputs, the static category localization map, and language examples in comments.
- **D-07:** Add a repo-local scanner or architecture test that scans `lib/**/*.dart`, excludes the approved whitelist paths/patterns, and fails on user-visible hardcoded CJK.
- **D-08:** User-visible chart labels must use `S.of(context)` or `FormatterService`; formatter-internal locale outputs such as `万`, `今日`, and `昨日` remain allowed.

### ARB Key Strategy
- **D-09:** Normalize relevant home/analytics/accounting ARB key names during this phase so the resulting ARB surface is tidy, not merely additive.
- **D-10:** Run a static ARB reference audit before deleting any key. Delete only keys proven unused and not part of the explicit placeholder/stub set.
- **D-11:** Preserve `ocrScan`, `ocrScanTitle`, and `ocrHint` in all three ARB files, with `@key` description metadata noting that they are future OCR/MOD-005 stubs.
- **D-12:** Add an ARB key parity test/script comparing `app_en.arb`, `app_ja.arb`, and `app_zh.arb` normal keys plus metadata keys. Run `flutter gen-l10n` after ARB changes.

### MOD-009 Cleanup Boundary
- **D-13:** Clean only `lib/` references to deprecated MOD-009 architecture, paths, numbering, comments, imports, or naming. Do not delete still-active voice feature code.
- **D-14:** The user preferred cleaning all MOD-009 historical docs now, but this conflicts with the fixed Phase 5 boundary and `PROJECT.md`; defer documentation cleanup to Phase 7 Documentation Sweep.
- **D-15:** Rewrite comments such as "used by MOD-004 OCR and MOD-009 Voice" into capability descriptions such as "shared merchant lookup used by OCR and voice-input classification".
- **D-16:** Add a scan assertion that `lib/` contains no `MOD-009`, `mod009`, or deprecated i18n module path references; explicitly exclude `docs/` and `doc/`.

### Money Display Enforcement
- **D-17:** Only real monetary values are in scope: transaction amounts, monthly expenses, ledger spending, budget/category amounts, and amount input previews. Percentages, status copy, and non-money legends are out of scope.
- **D-18:** Real monetary values must use `AppTextStyles.amountLarge`, `AppTextStyles.amountMedium`, or `AppTextStyles.amountSmall`, or `copyWith` based on those styles. Bare `TextStyle` must not be used in a way that loses `FontFeature.tabularFigures()`.
- **D-19:** Add focused widget/style tests that assert touched money widgets' `Text.style.fontFeatures` include `FontFeature.tabularFigures()`, while keeping the existing `app_text_styles_test.dart`.
- **D-20:** Currency formatting must use `FormatterService.formatCurrency(...)`, and monetary styling must use `AppTextStyles.amount*`. Both are required in money UI and neither replaces the other.

### the agent's Discretion
- Exact file split and plan sequencing within Phase 5.
- Exact whitelist implementation for the hardcoded CJK scanner, provided it preserves D-05 through D-08.
- Exact ARB key names after normalization, provided they remain domain-scoped and parity-clean.
- Exact shape of the architecture tests or scripts, provided they are committed and runnable in normal project verification.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project scope and constraints
- `.planning/PROJECT.md` — Cleanup initiative scope, strict behavior preservation, documentation-sweep deferral, and out-of-scope boundaries.
- `.planning/REQUIREMENTS.md` §MED-01..MED-08 — Locked Phase 5 deliverables.
- `.planning/ROADMAP.md` §"Phase 5: MEDIUM Fixes" — Phase goal, dependencies, and success criteria.
- `.planning/STATE.md` — Current milestone state and repo-lock continuity.

### Audit and coverage contracts
- `.planning/audit/issues.json` — Source of MEDIUM findings `RD-001` and `RD-002`; planner must close relevant entries without reissuing IDs.
- `.planning/audit/ISSUES.md` — Human-readable finding catalogue.
- `.planning/audit/SCHEMA.md` — Finding status bookkeeping contract.
- `.planning/audit/REPO-LOCK-POLICY.md` — Repo lock remains active through Phase 6.
- `.planning/audit/coverage-baseline.txt` / `.json` — Frozen pre-refactor coverage baseline.
- `.planning/audit/files-needing-tests.txt` / `.json` — Frozen list to intersect with Phase 5 touched files.
- `scripts/coverage_gate.dart` — Per-plan touched-file coverage gate.

### Prior phase contracts
- `.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md` — Stable finding IDs, staged gate enablement, audit layout.
- `.planning/phases/02-coverage-baseline/02-CONTEXT.md` — Strict touched-file coverage gating and frozen baseline policy.
- `.planning/phases/03-critical-fixes/03-CONTEXT.md` — `test/architecture/` convention, strict coverage interpretation, import-guard patterns.
- `.planning/phases/04-high-fixes/04-CONTEXT.md` — `FormatterService` as the public i18n formatting access path and strict provider/architecture-test precedent.

### Codebase ground truth
- `.planning/codebase/CONCERNS.md` — Hardcoded UI strings, duplicate `CategoryService`, static category map, MOD-009/MOD-014 history, and amount-display/style concerns.
- `.planning/codebase/CONVENTIONS.md` — i18n rules, Riverpod/provider conventions, amount-display style requirements.
- `.planning/codebase/STRUCTURE.md` — Current `lib/` layout and placement rules.
- `.planning/codebase/TESTING.md` — Current test structure and Mocktail convention after Phase 4.

### Source files and docs directly relevant to planning
- `lib/application/accounting/category_service.dart` — Business `CategoryService`; should keep the name.
- `lib/infrastructure/category/category_service.dart` — Static category localization helper; should be renamed to `CategoryLocaleService`.
- `lib/application/i18n/formatter_service.dart` — Required formatting API for UI-facing date/number/currency formatting.
- `lib/core/theme/app_text_styles.dart` — Defines `amountLarge`, `amountMedium`, and `amountSmall` with tabular figures.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb` — ARB source files; parity and metadata must be maintained.
- `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md` — Historical i18n implementation reference; read only for context, do not update in Phase 5.
- `docs/arch/01-core-architecture/ARCH-000_INDEX.md` — Historical module index; user preferred MOD-009 cleanup here, but update is deferred to Phase 7.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/application/i18n/formatter_service.dart` already wraps `DateFormatter` and `NumberFormatter`; Phase 5 should use this in UI money/chart/date surfaces instead of importing infrastructure formatters.
- `lib/core/theme/app_text_styles.dart` already centralizes amount styles and `FontFeature.tabularFigures()`.
- `test/architecture/` already exists from Phases 3 and 4; Phase 5 can extend it with CJK, ARB parity, MOD-009 scan, or service-name collision tests.
- `test/helpers/test_localizations.dart` provides localized widget wrapping for tests that need `S.of(context)`.

### Established Patterns
- Generated files (`*.g.dart`, `*.freezed.dart`, `lib/generated/**`) are not hand-edited; ARB changes require `flutter gen-l10n`.
- Feature UI text must use `S.of(context)` and should capture `final l10n = S.of(context);` in build methods.
- Presentation code should consume application-layer formatting (`FormatterService`) rather than infrastructure formatters directly.
- Mocktail is now the test mocking convention after Phase 4; do not introduce Mockito.
- Every plan must declare touched files and run the per-file coverage gate against those files.

### Integration Points
- `lib/l10n/` and `lib/generated/` — ARB source and generated localization output.
- `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/home/presentation/widgets/soul_fullness_card.dart`, and analytics chart widgets — known user-visible hardcoded CJK hotspots.
- `lib/infrastructure/ml/merchant_database.dart` — known old module-number comment referring to MOD-009 voice; rewrite to capability language, do not delete merchant seed data.
- `lib/features/accounting/presentation/screens/voice_input_screen.dart` — contains active voice functionality plus some user-visible strings and formatter/style surfaces; preserve behavior while localizing UI.
- `lib/features/accounting/presentation/widgets/amount_display.dart`, `lib/features/home/presentation/widgets/*`, and chart/list widgets — candidate money-display enforcement surfaces.

</code_context>

<specifics>
## Specific Ideas

- User explicitly chose strict service-name regression prevention over a one-off `CategoryService` fix. Planner should include a reusable test that detects cross-layer same-class-name service ambiguity, not just the immediate rename.
- User explicitly chose to normalize relevant ARB keys in this phase, even though the recommended default was narrower additive keying. Planner should budget for generated-code churn from renamed ARB getters and update all call sites safely.
- User asked to clean all MOD-009 docs now. This is recorded but not executed in Phase 5 because `PROJECT.md` and the roadmap reserve documentation sweep for Phase 7.
- CJK scanning must distinguish user-visible UI strings from language data. A naive "no CJK anywhere in lib/" rule would incorrectly flag NLP dictionaries, merchant seed data, formatter output, and the static category localization map.

</specifics>

<deferred>
## Deferred Ideas

- Drive `CategoryLocaleService` from ARB files and eliminate the parallel static category map — remains `FUTURE-ARCH-01`.
- Clean historical MOD-009 documentation and index references — defer to Phase 7 Documentation Sweep.

</deferred>

---

*Phase: 05-medium-fixes*
*Context gathered: 2026-04-27*
