# Roadmap: Home Pocket — Codebase Cleanup Initiative

## Overview

An audit-driven, severity-ordered refactor of the Home Pocket Flutter codebase. The initiative runs a hybrid automated + AI-agent audit pipeline to produce a machine-readable findings catalogue, then eliminates every finding in strict severity order (CRITICAL → HIGH → MEDIUM → LOW), adds characterization-test coverage on every touched file, sweeps architecture documentation once the code is stable, and re-runs the full audit pipeline to verify zero remaining violations. The only exit criterion that matters: the re-audit reports zero open findings across all four categories (layer violations, redundant code, dead code, Riverpod hygiene).

Phase 1 (Tooling + Audit) and Phase 2 (Coverage Baseline) are parallelizable — neither makes code changes. All subsequent phases serialize strictly on the previous phase's exit gate.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Audit Pipeline + Tooling Setup** - Establish hybrid audit tooling and produce the machine-readable findings catalogue (issues.json) that scopes every fix phase
- [ ] **Phase 2: Coverage Baseline** - Snapshot pre-refactor per-file coverage; produce the list of files needing characterization tests before fix phases begin (parallelizable with Phase 1)
- [ ] **Phase 3: CRITICAL Fixes** - Eliminate all CRITICAL-severity findings (layer violations, UnimplementedError runtime failures); every touched file reaches ≥80% coverage
- [ ] **Phase 4: HIGH Fixes** - Eliminate all HIGH-severity findings (provider hygiene, architectural rule violations, deprecated service wiring); every touched file reaches ≥80% coverage
- [ ] **Phase 5: MEDIUM Fixes** - Eliminate all MEDIUM-severity findings (dead code, redundancy, i18n violations, theme token debt); every touched file reaches ≥80% coverage
- [ ] **Phase 6: LOW Fixes** - Eliminate all LOW-severity findings (unused members, stale suppression directives, Drift index additions, debug logging); every touched file reaches ≥80% coverage
- [ ] **Phase 7: Documentation Sweep** - Centralized post-refactor update of all ARCH/MOD/ADR docs and CLAUDE.md to match the cleaned codebase
- [ ] **Phase 8: Re-Audit + Exit Verification** - Re-run full audit pipeline; confirm zero open findings across all four categories and all CI gates pass simultaneously

## Phase Details

### Phase 1: Audit Pipeline + Tooling Setup
**Goal**: The hybrid audit pipeline is operational and `issues.json` with stable finding IDs is produced — this catalogue is the definition of "done" for every subsequent fix phase
**Depends on**: Nothing (first phase; runs in parallel with Phase 2)
**Requirements**: AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04, AUDIT-05, AUDIT-06, AUDIT-07, AUDIT-08, AUDIT-09, AUDIT-10
**Success Criteria** (what must be TRUE):
  1. `flutter analyze` runs `import_guard`, `riverpod_lint`, and `dart_code_linter` plugins simultaneously and exits 0 on the unmodified codebase (tools installed but no code changed yet)
  2. Each of the four audit scripts (`audit_layer.sh`, `audit_dead_code.sh`, `audit_providers.sh`, `audit_duplication.sh`) is individually invocable and produces structured output in the locked schema (id, category, severity, file_path, line_start, line_end, description, rationale, suggested_fix, tool_source, confidence)
  3. `.planning/audit/issues.json` exists with stable IDs, all findings severity-classified (CRITICAL / HIGH / MEDIUM / LOW), and human-readable `.planning/audit/ISSUES.md` produced alongside it
  4. Two CI guardrails are active: (a) `grep sqlite3_flutter_libs pubspec.lock` exits non-zero (rejects SQLCipher conflict); (b) `build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits non-zero on stale generated files
  5. No code files are modified during this phase — audit is discovery-only
**Plans**: 8 plans
  - [x] 01-01-tooling-registration-PLAN.md — Register custom_lint plugin host + analyzer-7-compatible audit deps
  - [x] 01-02-layer-rules-PLAN.md — Place 18 import_guard.yaml files encoding the 5-layer Clean Architecture
  - [x] 01-03-schema-and-catalogue-layout-PLAN.md — Lock SCHEMA.md + scripts/audit/finding.dart canonical model
  - [x] 01-04-tooling-scanners-PLAN.md — 4 audit_*.sh wrappers + Dart cores producing JSON shards
  - [x] 01-05-merger-and-id-stamping-PLAN.md — Merger with stable IDs + idempotency TDD test + reaudit_diff stub
  - [x] 01-06-ai-semantic-scan-PLAN.md — /gsd-audit-semantic slash command + 4 locked subagent prompts
  - [ ] 01-07-ci-workflow-PLAN.md — .github/workflows/audit.yml (3 jobs, staged enablement, AUDIT-09+10 blocking)
  - [ ] 01-08-end-to-end-pipeline-run-PLAN.md — Full pipeline dry-run + owner sanity-check checkpoint

### Phase 2: Coverage Baseline
**Goal**: Pre-refactor per-file coverage is snapshotted and the list of files requiring characterization tests before their fix phase begins is available
**Depends on**: Nothing (parallelizable with Phase 1; both must complete before any fix phase begins)
**Requirements**: BASE-01, BASE-02, BASE-03, BASE-04, BASE-05, BASE-06
**Success Criteria** (what must be TRUE):
  1. `flutter test --coverage` runs cleanly and produces `coverage/lcov.info`; generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`) are stripped to produce `lcov_clean.info`
  2. `.planning/audit/coverage-baseline.txt` contains per-file coverage percentages for all non-generated source files
  3. `.planning/audit/files-needing-tests.txt` lists every file below 80% coverage — these are the characterization-test targets for Phases 3–6
  4. `scripts/coverage_gate.dart` exists and exits non-zero when any file in the supplied list falls below 80% coverage
  5. A GitHub Actions step using `very_good_coverage@v2` with `min_coverage: 80` against `lcov_clean.info` is added to CI
  6. No code files are modified during this phase
**Plans**: TBD

### Phase 3: CRITICAL Fixes
**Goal**: Every CRITICAL-severity finding in `issues.json` is resolved; the codebase has no layer violations that could silently break behavior and no runtime-crash providers; all fix-phase exit gates pass
**Depends on**: Phase 1 (issues.json required) AND Phase 2 (coverage baseline required); both must be complete before Phase 3 begins
**Requirements**: CRIT-01, CRIT-02, CRIT-03, CRIT-04, CRIT-05, CRIT-06
**Success Criteria** (what must be TRUE):
  1. `issues.json` shows zero entries with `"severity": "CRITICAL"` and `"status": "open"` — verified by `scripts/reaudit_diff.dart` against the CRITICAL subset
  2. `lib/features/family_sync/use_cases/` directory no longer exists; all use-case files have been migrated to `lib/application/family_sync/` and no feature module contains a `use_cases/` subdirectory
  3. `appDatabaseProvider` in `lib/infrastructure/security/providers.dart` no longer throws `UnimplementedError`; either a concrete provider or a shared `createTestProviderScope` helper always provides the override — verified by a test that constructs a `ProviderScope` without an explicit override and does not crash
  4. `import_guard` reports zero violations for Domain-layer files importing Data or Infrastructure — Domain files import only Dart core, `freezed_annotation`, and `json_annotation`
  5. Every file touched in this phase has ≥80% test coverage (characterization tests written before the refactor); `flutter analyze` exits 0; `dart run custom_lint` exits 0; all tests GREEN; user-observable behavior is unchanged
**Plans**: TBD

### Phase 4: HIGH Fixes
**Goal**: Every HIGH-severity finding in `issues.json` is resolved; the Riverpod provider graph is hygienic, deprecated services are fully deleted, and no presentation layer imports infrastructure directly
**Depends on**: Phase 3 (CRITICAL must be fully resolved and exit-gated before HIGH begins)
**Requirements**: HIGH-01, HIGH-02, HIGH-03, HIGH-04, HIGH-05, HIGH-06, HIGH-07, HIGH-08
**Success Criteria** (what must be TRUE):
  1. `issues.json` shows zero entries with `"severity": "HIGH"` and `"status": "open"`
  2. No file under `lib/features/*/presentation/` has a direct import from `lib/infrastructure/` — all infrastructure access routes through Application use cases (verified by `import_guard`)
  3. `ResolveLedgerTypeService` is fully deleted: source file, provider definition, generated `.g.dart` part, test file, and all `*.mocks.dart` references are gone; `flutter analyze` exits 0 and `flutter test` passes after each of the six deletion steps
  4. Each feature has exactly one `repository_providers.dart` (no duplicate provider definitions for the same dependency); `keepAlive: true` is preserved on `syncEngineProvider`, `transactionChangeTrackerProvider`, `merchantDatabaseProvider`, `activeGroupProvider`, `activeGroupMembersProvider`, and `ledgerProvider`
  5. Every file touched in this phase has ≥80% test coverage; `flutter analyze` exits 0; `dart run custom_lint` exits 0; all tests GREEN; behavior unchanged
**Plans**: TBD

### Phase 5: MEDIUM Fixes
**Goal**: Every MEDIUM-severity finding in `issues.json` is resolved; the dual-CategoryService naming collision is eliminated, all hardcoded CJK strings are extracted to ARB files, and MOD-009 deprecated code references are deleted
**Depends on**: Phase 4 (HIGH must be fully resolved and exit-gated before MEDIUM begins)
**Requirements**: MED-01, MED-02, MED-03, MED-04, MED-05, MED-06, MED-07, MED-08
**Success Criteria** (what must be TRUE):
  1. `issues.json` shows zero entries with `"severity": "MEDIUM"` and `"status": "open"`
  2. `lib/infrastructure/category/category_service.dart` is renamed to `CategoryLocaleService`; a grep for `"import.*infrastructure/category/category_service"` returns zero results; `import_guard` reports zero ambiguous `CategoryService` import paths
  3. All three ARB files (`app_ja.arb`, `app_zh.arb`, `app_en.arb`) have identical key sets; `flutter gen-l10n` completes without warnings; OCR placeholder keys (`ocrScan`, `ocrScanTitle`, `ocrHint`) are preserved with `@key` description comments
  4. `lib/` contains zero hardcoded CJK strings outside intentional dictionaries; every UI string uses `S.of(context).<key>`
  5. No `lib/` file imports from any MOD-009 (deprecated i18n module) code path; monetary-display widgets use `AppTextStyles.amountLarge/amountMedium/amountSmall` and widget tests verify `FontFeature.tabularFigures()` is present
  6. Every file touched in this phase has ≥80% test coverage; `flutter analyze` exits 0; all tests GREEN; behavior unchanged
**Plans**: TBD

### Phase 6: LOW Fixes
**Goal**: Every LOW-severity finding in `issues.json` is resolved; unused private members and orphaned files are deleted, stale suppression directives are removed, Drift indices are added with a migration step, and unguarded debug logging is wrapped
**Depends on**: Phase 5 (MEDIUM must be fully resolved and exit-gated before LOW begins)
**Requirements**: LOW-01, LOW-02, LOW-03, LOW-04, LOW-05, LOW-06, LOW-07
**Success Criteria** (what must be TRUE):
  1. `issues.json` shows zero entries with `"severity": "LOW"` and `"status": "open"`
  2. `dart run dart_code_linter:metrics check-unused-code lib` and `check-unused-files lib` both report zero findings; all resolved `// ignore:` directives are removed
  3. `lib/data/tables/audit_logs_table.dart`, `user_profiles_table.dart`, and `category_ledger_configs_table.dart` each declare the appropriate `customIndices` using `TableIndex` with `{#columnName}` Symbol syntax; `schemaVersion` is bumped; a parameterized migration step (no string interpolation) exists in `app_database.dart`
  4. An integration test opens a v(N-1) schema, runs migrations to vN, and asserts the new indices exist via `PRAGMA index_list(table_name)` — test passes GREEN
  5. All `print()` and unguarded `debugPrint()` calls in production code paths are wrapped in `if (kDebugMode)` or moved to a centralized logging utility; `flutter analyze` exits 0 with `avoid_print: true`; all tests GREEN; behavior unchanged
**Plans**: TBD

### Phase 7: Documentation Sweep
**Goal**: All ARCH/MOD/ADR files under `doc/arch/` and CLAUDE.md accurately reflect the post-refactor codebase; one centralized sweep rather than per-phase churn
**Depends on**: Phase 6 (all code changes must be complete before documentation is updated to the final state)
**Requirements**: DOCS-01, DOCS-02, DOCS-03, DOCS-04
**Success Criteria** (what must be TRUE):
  1. Every ARCH/MOD/ADR file under `doc/arch/` that referenced relocated files, renamed classes (e.g., `CategoryLocaleService`), or deleted modules (e.g., `ResolveLedgerTypeService`, MOD-009 code) is updated to match the post-refactor file paths and class names
  2. `doc/arch/INDEX.md` files (ARCH-000, ADR-000, MOD-000) reference only files that still exist on disk
  3. CLAUDE.md "Common Pitfalls" list is annotated to mark which of the 13 items are now structurally enforced by `import_guard` / `riverpod_lint` / `dart_code_linter` / CI gates (so future contributors know which pitfalls are automated)
  4. A new ADR is filed (next sequential number after current max) documenting the cleanup initiative outcome, the `*.mocks.dart` strategy decision, and ongoing CI enforcement mechanisms
**Plans**: TBD

### Phase 8: Re-Audit + Exit Verification
**Goal**: The full audit pipeline is re-run on the post-refactor codebase and `reaudit_diff.dart` exits 0 — zero open findings across all four categories; all eight exit-criterion gates pass simultaneously; CI guardrails become permanent
**Depends on**: Phase 7 (documentation sweep must be complete before final verification)
**Requirements**: EXIT-01, EXIT-02, EXIT-03, EXIT-04, EXIT-05
**Success Criteria** (what must be TRUE):
  1. `.planning/audit/re-audit/issues.json` is produced by re-running the full audit pipeline on the post-refactor codebase; `scripts/reaudit_diff.dart` exits 0 with zero entries `"status": "open"` across all four finding categories (layer violations, redundant code, dead code, Riverpod hygiene)
  2. All eight exit gates pass simultaneously: `flutter analyze` exits 0; `dart run custom_lint` exits 0; `flutter test --coverage` exits 0 with global ≥80% coverage; `very_good_coverage@v2` does not fail against `lcov_clean.info`; `import_guard` reports 0 violations; `dart run dart_code_linter:metrics check-unused-code lib` reports 0 findings; `build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0
  3. The four CI guardrails (`import_guard`, `riverpod_lint`/`custom_lint`, `coverde` per-file ≥80%, `sqlite3_flutter_libs` rejection) are permanent — they block future PRs and are documented in the CI configuration
  4. A human smoke test confirms user-observable behavior is identical to the pre-refactor baseline (UI, data, interactions, formatting are byte-identical from the user's perspective)
**Plans**: TBD

## Build-Order Dependencies

```
Phase 1 (Audit Pipeline)  ─┐
                            ├── BOTH must complete before Phase 3
Phase 2 (Coverage Baseline)─┘

Phase 3 (CRITICAL) → Phase 4 (HIGH) → Phase 5 (MEDIUM) → Phase 6 (LOW) → Phase 7 (Docs) → Phase 8 (Re-Audit)
```

**Hard rules:**
- Phase 1 produces `issues.json` — without it, no fix phase has a definition of "done"
- Phase 2 produces `files-needing-tests.txt` — without it, characterization-test pre-work cannot be scoped
- Each fix phase (3–6) is exit-gated: `flutter analyze = 0`, all tests GREEN, ≥80% coverage on touched files, zero open findings at its severity tier before the next phase begins
- Documentation (Phase 7) runs after all code is stable — no per-phase doc updates
- Re-audit (Phase 8) is terminal and must show zero open findings

## Progress

**Execution Order:**
Phases 1 and 2 run in parallel. Then: 3 → 4 → 5 → 6 → 7 → 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Audit Pipeline + Tooling Setup | 0/TBD | Not started | - |
| 2. Coverage Baseline | 0/TBD | Not started | - |
| 3. CRITICAL Fixes | 0/TBD | Not started | - |
| 4. HIGH Fixes | 0/TBD | Not started | - |
| 5. MEDIUM Fixes | 0/TBD | Not started | - |
| 6. LOW Fixes | 0/TBD | Not started | - |
| 7. Documentation Sweep | 0/TBD | Not started | - |
| 8. Re-Audit + Exit Verification | 0/TBD | Not started | - |
