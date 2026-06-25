---
phase: 51-cross-validation-daily-joy-ledger-rework
plan: 04
subsystem: accounting
tags: [flutter, refactor, dual-ledger-retirement, single-source-of-truth, ledger-purity]

# Dependency graph
requires:
  - phase: 51-02
    provides: reconciler wired into ParseVoiceInputUseCase; ledger derived after reconciliation via resolveLedgerType
provides:
  - CreateTransactionUseCase ledger derivation re-routed to CategoryService.resolveLedgerType(...) ?? daily (single post-reconciliation ledger site)
  - lib/application/dual_ledger/ fully retired (second divergent hardcoded daily/joy map deleted — LEDGER-02)
  - rebuilt invariant tests (currency-triple / hash-chain / entry-source) on CategoryService double
affects: [51 LEDGER wave-4, manual/OCR/test create paths, ledger purity invariant LEDGER-01]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single ledger site: every create path derives ledger from category_ledger_configs via CategoryService.resolveLedgerType — matching the form's own derivation, so no path stamps a ledger contradicting its category (D-14)"
    - "Conservative fallback (D-16): resolveLedgerType returning null falls back to LedgerType.daily — an unknown/no-config category is never mis-stamped as joy"
    - "Re-route touches ONLY the ledger-resolution branch; validation / currency-triple / category-exists / hash-chain blocks left byte-identical (ASVS V5/V6 survive)"

key-files:
  created: []
  modified:
    - lib/application/accounting/create_transaction_use_case.dart
    - lib/features/accounting/presentation/providers/repository_providers.dart
    - test/unit/application/accounting/create_transaction_use_case_test.dart
    - test/unit/features/accounting/presentation/providers/use_case_providers_characterization_test.dart
    - test/application/accounting/create_transaction_currency_test.dart
    - test/integration/entry_path_stamping_test.dart
    - test/integration/features/accounting/manual_save_entry_source_test.dart
    - test/integration/features/accounting/voice_save_entry_source_test.dart
  deleted:
    - lib/application/dual_ledger/classification_service.dart
    - lib/application/dual_ledger/rule_engine.dart
    - lib/application/dual_ledger/classification_result.dart
    - lib/application/dual_ledger/repository_providers.dart
    - lib/application/dual_ledger/repository_providers.g.dart
    - test/unit/application/dual_ledger/rule_engine_test.dart
    - test/unit/application/dual_ledger/classification_service_test.dart
    - test/unit/application/dual_ledger/classification_result_test.dart
    - test/unit/application/dual_ledger/providers_characterization_test.dart

decisions:
  - "Ledger derives from CategoryService.resolveLedgerType(categoryId) ?? daily on the manual/OCR/test create path (D-14/D-16) — the authoritative category_ledger_configs, never a merchant ledger hint"
  - "Integration tests construct a real CategoryService but the ledger is supplied explicitly (form/parser always pass a non-null ledgerType=daily), so the resolveLedgerType fallback is never exercised there; the fallback is unit-covered in create_transaction_use_case_test (joy / null→daily / user-override-wins cases)"

# Metrics
duration: ~12min
completed: 2026-06-24
status: complete
---

# Phase 51 Plan 04: Retire dual_ledger; re-route ledger to CategoryService Summary

**Re-routed `CreateTransactionUseCase`'s ledger derivation from the retired `ClassificationService` to the authoritative `CategoryService.resolveLedgerType(...) ?? daily` (D-14/D-16), rewired its provider, deleted the entire `lib/application/dual_ledger/` directory (the second divergent hardcoded daily/joy map — LEDGER-02), and rebuilt the 6 invariant-carrying tests on a CategoryService double while deleting the 4 retired-code tests — full suite 3263/3263 green, analyze 0.**

## Performance

- **Duration:** ~12 min active
- **Completed:** 2026-06-24
- **Tasks:** 3 (re-route use case + provider → rebuild/delete tests → retire dual_ledger dir)
- **Files:** 2 production + 6 tests modified; 5 source + 4 tests deleted

## Accomplishments
- **Use case re-route (Task 1):** dropped `import '../dual_ledger/classification_service.dart'`, added `import 'category_service.dart'`. Swapped the `ClassificationService classificationService` constructor param/field for `CategoryService categoryService`. Replaced the `ledgerType==null` fallback branch with `resolvedLedgerType = await _categoryService.resolveLedgerType(params.categoryId) ?? LedgerType.daily` (D-14/D-16). The user-override path (`params.ledgerType != null`) is unchanged. Validation (lines 87-128), currency-triple, category-exists, and the hash-chain block are byte-identical — verified by acceptance greps (validateCurrencyTriple/category-not-found/calculateTransactionHash all still present).
- **Provider rewire (Task 1):** dropped the `application/dual_ledger/repository_providers.dart` import; `createTransactionUseCaseProvider` now wires `categoryService: ref.watch(categoryServiceProvider)` (the provider already existed). No `.g.dart` regen needed — no provider was added or removed.
- **Test rebuild (Task 2):** swapped `_MockClassificationService` → `_MockCategoryService` in `create_transaction_use_case_test` and `create_transaction_currency_test`. Added a D-16 case (resolveLedgerType returns null → daily-ledger transaction), a joy case (resolveLedgerType → joy), and a user-override-wins case (verifyNever resolveLedgerType when params.ledgerType is set). The 3 real-DB integration tests (entry_path_stamping, manual/voice save-entry-source) construct a real `CategoryService(categoryRepository, ledgerConfigRepository)`; they always supply ledgerType explicitly so the fallback path isn't hit there. The provider characterization test now exercises the real `categoryServiceProvider` chain (no override) instead of overriding `classificationServiceProvider`. All currency-triple, hash-chain, and entry-source cases re-assert verbatim.
- **dual_ledger retirement (Task 3):** deleted all 5 files in `lib/application/dual_ledger/` (the second divergent daily/joy map — `RuleEngine` carried dead ids `cat_entertainment`/`cat_shopping`). `ledger_hint_deriver.dart` and `features/dual_ledger/` (joy-celebration UI) untouched. Tree-wide grep for retired symbols (`RuleEngine`/`ClassificationService`/`ClassificationResult`/`classificationServiceProvider`/`application/dual_ledger`) == 0.

## Task Commits

1. **Task 1: re-route use case + provider to CategoryService** — `92f8a14d` (refactor) — also folded the 4 retired-test deletions (git rm staging; see Deviations)
2. **Task 2: rebuild invariant tests on CategoryService** — `8a6f9d31` (test)
3. **Task 3: retire lib/application/dual_ledger/ (5 files)** — `cbc59420` (refactor)

## Files Created/Modified
- `lib/application/accounting/create_transaction_use_case.dart` — ledger derivation re-routed to `CategoryService.resolveLedgerType(...) ?? daily`.
- `lib/features/accounting/presentation/providers/repository_providers.dart` — `createTransactionUseCase` wired with `categoryService`; dual_ledger import dropped.
- 6 test files rebuilt against `CategoryService`; 4 retired-code tests + 5 dual_ledger source files deleted.

## Decisions Made
- **Manual/OCR/test create path derives ledger from `CategoryService.resolveLedgerType(categoryId) ?? daily` (D-14/D-16):** establishes the single post-reconciliation ledger site (`category_ledger_configs`), matching the form's own derivation — no path stamps a ledger contradicting its category, and an unknown/no-config category conservatively falls back to daily.
- **Integration tests supply ledger explicitly:** the form (`_ledgerType` defaults to daily, non-null) and the voice parser (`VoiceParseResult.ledgerType: daily`) always pass a non-null `ledgerType` into `CreateTransactionParams`, so the `resolveLedgerType` fallback is not exercised in the real-DB integration tests — only in the unit tests where it is mocked directly. The integration tests therefore just need the `CategoryService` to construct; they re-assert the entry-source invariants unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `git rm` staged the 4 retired-test deletions into the Task 1 commit instead of Task 2**
- **Found during:** Task 2 commit
- **Issue:** the 4 retired-code test deletions (`rule_engine_test`/`classification_service_test`/`classification_result_test`/`providers_characterization_test`) were removed via `git rm` (which stages immediately) before the Task 1 commit. They were swept into commit `92f8a14d` rather than the intended Task 2 commit. A subsequent `git add` with a stale pathspec aborted, surfacing the state.
- **Fix:** committed Task 2's rebuilt tests on top (`8a6f9d31`) and documented the fold-in in both commit messages. No work lost; the deletions are coherent with the production re-route they accompany.
- **Files modified:** none (commit-ordering only).
- **Verification:** `git show --stat 92f8a14d` confirms the 4 deletions landed there; full suite green.

---

**Total deviations:** 1 auto-fixed (Rule 3 — commit ordering, no behavior change). No architectural changes.

## Threat Model Compliance
- **T-51-04-01 (ledger desync — two divergent maps):** LEDGER-02 deletes the second map (`RuleEngine`); single source of truth is now `category_ledger_configs` via `CategoryService`. Tree-wide retired-symbol grep == 0.
- **T-51-04-02 (input validation dropped during re-route):** re-route touched ONLY the ledger branch; acceptance greps confirm `validateCurrencyTriple`, category-exists, amount↔triple consistency, and `calculateTransactionHash` all survive (ASVS V5/V6). The full currency/WR-03/WR-04/D-05 test cases stay green.
- **T-51-04-03 (lost non-classification invariants when deleting tests):** D-22 honored — only the 4 retired-code tests deleted; the 6 invariant-carrying tests rebuilt re-asserting currency/hash/entry-source verbatim.
- **T-51-04-04 (accidental deletion of ledger_hint_deriver / features/dual_ledger):** both confirmed still present post-retirement (Pitfall 1/2).

## Issues Encountered
None beyond the commit-ordering deviation. The disambiguation held: the architecture tests (`presentation_layer_rules_test`, `provider_graph_hygiene_test`, `domain_import_rules_test`) reference only `features/dual_ledger` (joy-UI) and stayed green without edits.

## Verification
- `flutter test` over the 6 rebuilt files — 49/49 green (currency-triple / hash-chain / entry-source cases intact; D-16 null→daily case present).
- `lib/application/dual_ledger/` gone; `ledger_hint_deriver.dart` + `features/dual_ledger/` intact.
- Tree-wide grep for retired symbols (`application/dual_ledger`/`RuleEngine`/`ClassificationService`/`ClassificationResult`/`ClassificationMethod`/`classificationServiceProvider`/`ruleEngineProvider`) == 0 across `lib test`.
- `flutter analyze` — 0 issues.
- **Full suite (per-wave gate, run manually): `flutter test` — 3263/3263 passed.**

## Self-Check: PASSED

All 5 source + 4 test deletions confirmed gone from disk; both production files modified; all 3 task commits (`92f8a14d`, `8a6f9d31`, `cbc59420`) present in git history.

---
*Phase: 51-cross-validation-daily-joy-ledger-rework*
*Completed: 2026-06-24*
