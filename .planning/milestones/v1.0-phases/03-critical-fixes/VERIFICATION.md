---
phase: 03-critical-fixes
verified: 2026-04-26T11:37:35Z
status: gaps_found
score: 5/5
overrides_applied: 0
gaps:
  - truth: "audit.yml dart run custom_lint step is blocking (continue-on-error removed — D-17)"
    status: failed
    reason: "D-17 blocking flip was deferred in plan 03-01 SUMMARY (gating condition not met at the time), but was never completed after plans 03-02..03-05 finished. .github/workflows/audit.yml line 41 still has continue-on-error: true on the 'dart run custom_lint' step."
    artifacts:
      - path: ".github/workflows/audit.yml"
        issue: "Line 41: 'continue-on-error: true   # Phase 4 exit gate flips this blocking (D-04)' — comment incorrectly defers to Phase 4; per D-17 this flip was the LAST commit of Phase 3."
    missing:
      - "Remove continue-on-error: true from 'dart run custom_lint' step in .github/workflows/audit.yml (lines 40-42)"
      - "Commit with message: feat(03): flip import_guard to blocking — Phase 3 close (D-17)"
---

# Phase 3: CRITICAL Fixes — Verification Report

**Phase Goal:** Every CRITICAL-severity finding in `issues.json` is resolved; the codebase has no layer violations that could silently break behavior and no runtime-crash providers; all fix-phase exit gates pass.

**Verified:** 2026-04-26T11:37:35Z
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | `issues.json` shows zero entries with `"severity": "CRITICAL"` and `"status": "open"` | VERIFIED | Python check on `.planning/audit/issues.json`: 24 CRITICAL total, 0 open, 24 closed (LV-001..LV-024 all closed) |
| SC2 | `lib/features/family_sync/use_cases/` directory no longer exists; no feature module contains a `use_cases/` subdirectory | VERIFIED | `ls lib/features/family_sync/` shows: `domain/`, `import_guard.yaml`, `presentation/` only. `find lib/features -type d -name use_cases` returns 0 results. All 5 use cases confirmed in `lib/application/family_sync/` |
| SC3 | `appDatabaseProvider` no longer throws `UnimplementedError`; createTestProviderScope helper always provides the override | VERIFIED | `lib/infrastructure/security/providers.dart` line 108: throws `StateError` (not `UnimplementedError`). `test/helpers/test_provider_scope.dart` implements `createTestProviderScope()`. `test/infrastructure/security/providers_test.dart` line 10 verifies StateError behavior; line 46 verifies createTestProviderScope does not crash |
| SC4 | `import_guard` reports zero violations for Domain-layer files; Domain files import only Dart core, freezed_annotation, and json_annotation | VERIFIED | `grep -rn "import.*package:home_pocket/(data\|infrastructure\|application\|features.*/presentation)" lib/features/*/domain/` returns 0 matches. Architecture test `test/architecture/domain_import_rules_test.dart` passes (18/18 assertions). `flutter analyze` (0 errors, 0 warnings) and `dart run custom_lint` (exit 0) confirm no violations |
| SC5 | Every touched file has ≥80% coverage; `flutter analyze` exits 0; `dart run custom_lint` exits 0; all tests GREEN | VERIFIED (with plan gap noted separately) | `flutter test`: 1070/1070 passed. `flutter analyze --no-fatal-infos`: 8 info-level only, 0 errors, 0 warnings. `dart run custom_lint`: exit code 0, 19 pre-existing riverpod_lint INFOs, zero import_guard violations. Coverage: app_initializer.dart 96.7%, init_failure_screen.dart 87.5%, providers.dart 100%. main.dart 63.9% but was not in files-needing-tests.txt (pre-refactor baseline was already excluded from the CRIT-05 gating list) |

**Score:** 5/5 ROADMAP success criteria verified

---

### Plan-Level Must-Have Gap (Not Blocking ROADMAP SC)

| # | Must-Have | Status | Evidence |
|---|-----------|--------|----------|
| D-17 | `audit.yml` `dart run custom_lint` step has `continue-on-error: true` REMOVED | FAILED | `.github/workflows/audit.yml` line 41 still contains `continue-on-error: true`. Plan 03-01 SUMMARY documented this as deferred (gating condition not met at the time), but no subsequent plan completed it after all Wave 1/2 plans finished. This is a plan-level must-have from 03-01 PLAN frontmatter, not a ROADMAP SC. |

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/*/domain/import_guard.yaml` (6 files) | Deny-only parent yaml | VERIFIED | All 6 exist with `deny:` block, no `allow:` at parent level |
| `lib/features/*/domain/{models,repositories}/import_guard.yaml` | Per-subdir allow whitelist (intra-domain only) | VERIFIED | 10 subdirectory yamls exist with correct allow lists (dart:core, freezed_annotation, json_annotation, meta, intra-domain leaves) |
| `lib/features/family_sync/import_guard.yaml` | Feature-level deny for future use_cases/ recreation | VERIFIED | Exists; denies `package:home_pocket/features/family_sync/use_cases/**` |
| `test/architecture/domain_import_rules_test.dart` | Meta-test asserting domain import shape | VERIFIED | Exists; 18 tests all pass |
| `lib/application/family_sync/check_group_use_case.dart` | Migrated use case | VERIFIED | Contains `class CheckGroupUseCase` |
| `lib/application/family_sync/deactivate_group_use_case.dart` | Migrated use case | VERIFIED | Exists with correct class |
| `lib/application/family_sync/leave_group_use_case.dart` | Migrated use case | VERIFIED | Exists with correct class |
| `lib/application/family_sync/regenerate_invite_use_case.dart` | Migrated use case | VERIFIED | Exists with correct class |
| `lib/application/family_sync/remove_member_use_case.dart` | Migrated use case | VERIFIED | Exists with correct class |
| `lib/features/home/presentation/models/ledger_row_data.dart` | LedgerRowData in presentation (not domain) | VERIFIED | File is at `lib/features/home/presentation/models/ledger_row_data.dart`; `lib/features/home/domain/` contains only `import_guard.yaml` |
| `lib/core/initialization/init_result.dart` | Freezed sealed class `InitResult` | VERIFIED | Contains `@freezed sealed class InitResult`, `enum InitFailureType { masterKey, database, seed, unknown }` |
| `lib/core/initialization/app_initializer.dart` | Constructor-injected `AppInitializer` | VERIFIED | `class AppInitializer` with `containerFactory`, `databaseFactory` typedefs; `Future<InitResult> initialize()` method |
| `lib/core/initialization/init_failure_screen.dart` | StatefulWidget using AppColors/AppTextStyles/S.of | VERIFIED | `class InitFailureScreen extends StatefulWidget`; uses `S.of(context)`, `AppColors`, `AppTextStyles` |
| `lib/infrastructure/security/providers.dart` | appDatabaseProvider throws StateError (not UnimplementedError) | VERIFIED | Line 108: `throw StateError(...)` with diagnostic message referencing AppInitializer |
| `test/helpers/test_provider_scope.dart` | createTestProviderScope helper | VERIFIED | Implements `ProviderContainer createTestProviderScope({AppDatabase?, List<Override>})` |
| `lib/main.dart` | Delegates to AppInitializer, sealed switch on InitResult | VERIFIED | Lines 36, 54, 62, 68: `AppInitializer(`, `switch (result)`, `case InitFailure`, `runApp(InitFailureApp(...))` |
| `lib/l10n/app_{ja,zh,en}.arb` | 3 new ARB keys (initFailedTitle, initFailedMessage, initFailedRetry) | VERIFIED | All 3 keys present in all 3 ARB files |
| `lib/generated/app_localizations.dart` | Generated localizations include new keys | VERIFIED | `String get initFailedTitle`, `initFailedMessage`, `initFailedRetry` present |
| `.github/workflows/audit.yml` | `dart run custom_lint` step blocking (D-17 flip) | FAILED | Line 41 still has `continue-on-error: true` |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/main.dart` | `AppInitializer.initialize()` | Constructor call + sealed switch | VERIFIED | main.dart line 36: `AppInitializer(`, line 54: `switch (result)` |
| `AppInitializer` | `InitResult.success/failure` | Freezed sealed class | VERIFIED | Both success and failure branches return sealed InitResult variants |
| `InitFailureScreen` | `S.of(context)` (i18n) | ARB keys | VERIFIED | Uses `initFailedTitle`, `initFailedMessage`, `initFailedRetry` via l10n |
| Domain files | Only allowed imports | import_guard.yaml rules | VERIFIED | Zero violations; architecture test 18/18 pass |
| `lib/application/family_sync/` use cases | Callers in presentation | Updated import paths | VERIFIED | No remaining dart imports of `features/family_sync/use_cases/` path |
| `appDatabaseProvider` | StateError diagnostic | Production: AppInitializer override | VERIFIED | Provider throws StateError; AppInitializer.initialize() always overrides with real DB |

---

### Behavioral Spot-Checks

| Behavior | Result | Status |
|----------|--------|--------|
| `flutter analyze --no-fatal-infos` exits 0 | 8 info-level issues, 0 errors, 0 warnings | PASS |
| `flutter test` 1070 tests pass | 1070/1070 passed | PASS |
| `dart run custom_lint` exits 0 | Exit code 0, 19 pre-existing riverpod_lint INFOs, 0 import_guard violations | PASS |
| Architecture test `domain_import_rules_test.dart` passes | 18/18 assertions pass | PASS |
| No feature module `use_cases/` directory | `find lib/features -type d -name use_cases` = 0 results | PASS |
| LedgerRowData in presentation/models/ (not domain/models/) | File at `lib/features/home/presentation/models/ledger_row_data.dart` | PASS |
| D-17 blocking flip in audit.yml | `continue-on-error: true` still present on line 41 | FAIL |

---

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| CRIT-01 | Zero open CRITICAL findings in issues.json | SATISFIED | 0 open, 24 closed |
| CRIT-02 | lib/features/family_sync/use_cases/ removed; no feature has use_cases/ | SATISFIED | Directory gone; 5 use cases in lib/application/family_sync/ |
| CRIT-03 | appDatabaseProvider no longer throws UnimplementedError; createTestProviderScope exists | SATISFIED | StateError thrown; helper exists; tests pass |
| CRIT-04 | Domain files import only Dart core, freezed_annotation, json_annotation | SATISFIED | 0 violations; arch test green |
| CRIT-05 | Every touched file has ≥80% coverage | SATISFIED (scoped) | Files in Phase 3 ∩ files-needing-tests.txt all ≥80%; main.dart (63.9%) not in files-needing-tests.txt |
| CRIT-06 | flutter analyze 0; dart run custom_lint 0; all tests GREEN; behavior unchanged | SATISFIED | All three gates pass; 1070/1070 tests; 0 analyzer errors |

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `.github/workflows/audit.yml` line 41 | `continue-on-error: true` on `dart run custom_lint` — D-17 flip not applied | Warning | CI does not enforce import_guard violations as blocking; a future PR introducing layer violations would pass CI even though `dart run custom_lint` would report them |
| `test/core/initialization/app_initializer_test.dart` line 68 | Local variable `_makeInitializer` with underscore prefix | Info | `flutter analyze` info-level (`no_leading_underscores_for_local_identifiers`) — does not affect behavior |
| `test/features/home/presentation/models/ledger_row_data_test.dart` lines 25-32 | Local variables with underscore prefix (`_tagBg`, `_tagText`, etc.) | Info | Same analyzer info — does not affect behavior |

---

### Human Verification Required

None required for this phase — all verifications were automated.

---

### Gaps Summary

**One gap identified, one false-alarm resolved:**

**BLOCKER (plan-level):** D-17 audit.yml blocking flip was never completed. Plan 03-01 SUMMARY documented it as deferred because 6 open CRITICALs remained when Wave 1 ran. After all plans completed (03-02 through 03-05), the D-17 flip was not executed as the "LAST commit of Phase 3." The `.github/workflows/audit.yml` `dart run custom_lint` step still has `continue-on-error: true` on line 41.

**This gap is a PLAN-level must-have (03-01 frontmatter), NOT a ROADMAP success criterion.** The ROADMAP SC5 says "`dart run custom_lint` exits 0" — the tool does exit 0 locally. The gap is the CI enforcement wrapper, not the tool output.

**Verdict on ROADMAP goal:** All 5 ROADMAP success criteria are VERIFIED. The phase goal "Zero CRITICAL-severity findings when the full audit pipeline runs against the post-Phase-3 codebase" is achieved at the code level.

**Recommended follow-up:** Before proceeding to Phase 4, execute the D-17 flip as a single commit:
1. Remove `continue-on-error: true` from the `dart run custom_lint` step in `.github/workflows/audit.yml`
2. Commit: `feat(03): flip import_guard to blocking — Phase 3 close (D-17)`

This is a one-line change that closes the only remaining plan-level gap.

---

_Verified: 2026-04-26T11:37:35Z_
_Verifier: Claude (gsd-verifier)_
