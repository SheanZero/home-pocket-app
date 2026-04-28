# Requirements: Home Pocket — Codebase Cleanup Initiative

**Defined:** 2026-04-25
**Core Value:** Re-running the audit at the end finds zero violations across all four categories.

## v1 Requirements

Requirements for the cleanup initiative. Each maps to exactly one phase. All are gated by the project's universal constraints (strict behavior preservation, ≥80% coverage on touched files, `flutter analyze = 0`, all tests GREEN).

### Audit Pipeline (AUDIT)

- [ ] **AUDIT-01**: `import_guard`, `dart_code_linter`, and `coverde` are added to `pubspec.yaml` `dev_dependencies` with pinned versions verified on pub.dev
- [ ] **AUDIT-02**: `import_guard.yaml` encodes the 5-layer dependency rules from CLAUDE.md (Domain → nothing; Data → Domain + Infrastructure; Application → Domain + Infrastructure; Presentation → Application + Domain + Infrastructure; Infrastructure → external SDKs only)
- [ ] **AUDIT-03**: `analysis_options.yaml` is updated to register `custom_lint`, `riverpod_lint`, and `import_guard` plugins; `flutter analyze` exercises all three
- [ ] **AUDIT-04**: A finding-record schema is locked (id, category, severity, file_path, line_start, line_end, description, rationale, suggested_fix, tool_source, confidence) and documented in `.planning/audit/SCHEMA.md`
- [ ] **AUDIT-05**: A four-level severity taxonomy (CRITICAL / HIGH / MEDIUM / LOW) is locked with explicit definitions matching SUMMARY.md
- [ ] **AUDIT-06**: Audit scanners exist and are invocable individually (`scripts/audit_layer.sh`, `scripts/audit_dead_code.sh`, `scripts/audit_providers.sh`, `scripts/audit_duplication.sh`)
- [ ] **AUDIT-07**: An AI-agent semantic-scan workflow is defined and runnable, covering `features/*/use_cases/` misplacements, semantic duplication, indirect layer violations, and Drift unused-column detection
- [ ] **AUDIT-08**: A merged catalogue is produced as `.planning/audit/issues.json` (machine-readable, stable IDs) and `.planning/audit/ISSUES.md` (human-readable, severity-sorted, with suggested fix per finding)
- [ ] **AUDIT-09**: A CI guardrail rejects any future addition of `sqlite3_flutter_libs` to `pubspec.lock`
- [ ] **AUDIT-10**: A CI guardrail runs `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` to prevent stale generated-file commits

### Coverage Baseline (BASE)

- [ ] **BASE-01**: `flutter test --coverage` runs cleanly; `coverage/lcov.info` is produced
- [ ] **BASE-02**: Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`) are stripped from `lcov.info` to produce `lcov_clean.info`
- [ ] **BASE-03**: Per-file coverage percentages are written to `.planning/audit/coverage-baseline.txt`
- [ ] **BASE-04**: The list of files below 80% coverage is generated as `.planning/audit/files-needing-tests.txt` (these need characterization tests before their fix phase begins)
- [ ] **BASE-05**: `scripts/coverage_gate.dart` is created and enforces ≥80% per-file coverage on the supplied file list, exiting non-zero on failure
- [ ] **BASE-06**: A GitHub Actions step using `very_good_coverage@v2` is added with `min_coverage: 80` against `lcov_clean.info`

### CRITICAL-Severity Fixes (CRIT)

- [ ] **CRIT-01**: Every CRITICAL-severity finding in `issues.json` is resolved (status: closed); zero open CRITICAL entries remain
- [ ] **CRIT-02**: `lib/features/family_sync/use_cases/` is migrated to `lib/application/family_sync/`; no feature module contains a `use_cases/` directory
- [ ] **CRIT-03**: `appDatabaseProvider` no longer throws `UnimplementedError`; either replaced with a concrete provider or paired with a shared `createTestProviderScope` helper that always provides the override
- [ ] **CRIT-04**: All Domain-layer files import only Dart core, `freezed_annotation`, and `json_annotation` — verified by `import_guard`
- [ ] **CRIT-05**: Every file touched in this phase has ≥80% test coverage (characterization tests written first, then refactor)
- [ ] **CRIT-06**: `flutter analyze` exits 0; `dart run custom_lint` exits 0; all tests GREEN; user-observable behavior is unchanged (manual smoke + golden tests)

### HIGH-Severity Fixes (HIGH)

- [ ] **HIGH-01**: Every HIGH-severity finding in `issues.json` is resolved; zero open HIGH entries remain
- [ ] **HIGH-02**: No `lib/features/*/presentation/` file directly imports from `lib/infrastructure/` — all infrastructure access flows through Application use cases
- [ ] **HIGH-03**: `ResolveLedgerTypeService` is fully deleted (source file → provider → mocks → tests → all references); no `// ignore: deprecated_member_use` suppressions remain pointing to it
- [ ] **HIGH-04**: Every feature has exactly one `repository_providers.dart` (single source of truth); no duplicate provider definitions for the same dependency
- [ ] **HIGH-05**: Every Riverpod provider that requires session-long persistence retains `keepAlive: true` (verified against pre-refactor inventory: `syncEngineProvider`, `transactionChangeTrackerProvider`, `merchantDatabaseProvider`, `activeGroupProvider`, `activeGroupMembersProvider`, `ledgerProvider`, plus any others discovered during audit)
- [ ] **HIGH-06**: No Riverpod provider throws `UnimplementedError` outside of explicit test override fixtures
- [ ] **HIGH-07**: `*.mocks.dart` strategy decision applied: either CI-generated (not committed) OR migrated to Mocktail; mock files are consistent with current interfaces
- [ ] **HIGH-08**: Every file touched in this phase has ≥80% test coverage; `flutter analyze` 0; tests GREEN; behavior unchanged

### MEDIUM-Severity Fixes (MED)

- [x] **MED-01**: Every MEDIUM-severity finding in `issues.json` is resolved; zero open MEDIUM entries remain
- [x] **MED-02**: `lib/infrastructure/category/category_service.dart` is renamed to `CategoryLocaleService`; all import sites updated; the dual-`CategoryService` naming collision is eliminated
- [x] **MED-03**: All hardcoded CJK strings in `lib/` are extracted to ARB files; `S.of(context)` is used for every UI string
- [x] **MED-04**: All three ARB files (`app_ja.arb`, `app_zh.arb`, `app_en.arb`) have key parity (same key set, no orphans on any side); `flutter gen-l10n` succeeds without warnings
- [x] **MED-05**: Unused ARB keys are deleted only after the static-locale-map audit has been completed; intentional stubs (e.g., `ocrScan`, `ocrScanTitle`, `ocrHint`) are preserved with `@key` description comments
- [x] **MED-06**: All MOD-009 (deprecated i18n module) code references are deleted from `lib/`; deprecated documentation entries in `doc/arch/` are NOT touched (per PROJECT.md scope)
- [x] **MED-07**: All monetary-display widgets use `AppTextStyles.amountLarge/amountMedium/amountSmall`; widget tests verify `FontFeature.tabularFigures()` is preserved
- [x] **MED-08**: Every file touched in this phase has ≥80% test coverage; `flutter analyze` 0; tests GREEN; behavior unchanged

### LOW-Severity Fixes (LOW)

- [x] **LOW-01**: Every LOW-severity finding in `issues.json` is resolved; zero open LOW entries remain
- [x] **LOW-02**: Unused private members, unreachable branches, and orphaned files are deleted; `dart_code_linter check-unused-code` and `check-unused-files` both report 0 findings
- [x] **LOW-03**: All `// ignore:` and `// ignore_for_file:` suppression directives whose underlying violation is now fixed are removed
- [x] **LOW-04**: The three known missing Drift indices are added (`audit_logs_table.dart`, `user_profiles_table.dart`, `category_ledger_configs_table.dart`); `schemaVersion` bumped; migration step added using parameterized SQL only (no string interpolation)
- [x] **LOW-05**: An integration test verifies the v(N-1)→vN migration creates the new indices via `PRAGMA index_list`
- [x] **LOW-06**: All `print()` and bare `debugPrint()` calls in production code paths are wrapped in `if (kDebugMode)` or moved to a centralized logging utility
- [x] **LOW-07**: Every file touched in this phase has ≥80% test coverage; `flutter analyze` 0; tests GREEN; behavior unchanged

### Documentation Sweep (DOCS)

- [x] **DOCS-01**: All ARCH/MOD/ADR files under `doc/arch/` are reviewed; entries describing relocated files, renamed classes, or deleted modules are updated to match the post-refactor codebase
- [x] **DOCS-02**: CLAUDE.md "Common Pitfalls" list (currently 13 items) is annotated to mark which items are now structurally enforced by `import_guard` / `riverpod_lint` / `dart_code_linter` / CI gates
- [x] **DOCS-03**: `doc/arch/INDEX.md` files (ARCH-000, ADR-000, MOD-000) are verified to reference only files that still exist
- [x] **DOCS-04**: A new ADR is filed describing the cleanup initiative's outcome, decisions made (e.g., `*.mocks.dart` strategy), and ongoing CI enforcement

### Re-Audit / Exit Verification (EXIT)

- [ ] **EXIT-01**: The full audit pipeline is re-run on the post-refactor codebase; `.planning/audit/re-audit/issues.json` is produced
- [ ] **EXIT-02**: `scripts/reaudit_diff.dart` runs and reports the resolved / regression / new-finding counts; exits 0 only when there are zero open findings across all four categories
- [ ] **EXIT-03**: Global coverage from `flutter test --coverage` is ≥80% (against `lcov_clean.info`); `very_good_coverage@v2` does not fail
- [ ] **EXIT-04**: All eight exit-criterion gates from SUMMARY.md pass simultaneously: re-audit zero, `flutter analyze` 0, `dart run custom_lint` 0, `flutter test` GREEN with ≥80% coverage, `very_good_coverage@v2` pass, `import_guard` 0 violations, `dart_code_linter check-unused-code` 0 findings, `build_runner` clean diff
- [ ] **EXIT-05**: The four CI guardrails (`import_guard`, `riverpod_lint`/`custom_lint`, `coverde` per-file, `sqlite3_flutter_libs` rejection) become permanent — failing them blocks future PRs

## v2 Requirements

Deferred — explicitly out of this initiative but acknowledged for future tracking.

### Architecture (FUTURE-ARCH)

- **FUTURE-ARCH-01**: Drive `CategoryLocaleService` from ARB files (eliminate the parallel 735-line static map)
- **FUTURE-ARCH-02**: Replace committed `*.mocks.dart` strategy with full Mocktail migration if Phase 4 chose CI-generation
- **FUTURE-ARCH-03**: Upgrade audit pipeline to DCM (paid) for unified architecture-rule + dead-code + duplication detection
- **FUTURE-ARCH-04**: Fix `recoverFromSeed()` key-overwrite bug (HIGH-severity issue noted in CONCERNS.md but explicitly out of scope per PROJECT.md security-architecture exclusion)

### Tooling (FUTURE-TOOL)

- **FUTURE-TOOL-01**: Add `riverpod_lint` 3.x once `json_serializable` analyzer conflict is resolved upstream
- **FUTURE-TOOL-02**: Build a Drift-column unused-detection custom Dart script if AI-agent scan accuracy is insufficient at scale

## Out of Scope

Explicit exclusions per PROJECT.md, documented to prevent scope creep during planning and execution.

| Item | Reason |
|------|--------|
| New feature modules (MOD-005 OCR, MOD-007 Analytics expansion, MOD-013 Gamification) | Feature work paused per PROJECT.md to avoid cherry-pick conflicts and unstable foundations |
| Any user-visible behavior change | Strict pure refactor — UI / interactions / data / formatting must be byte-identical to the user |
| API/database breaking changes | Schema, public types, and Drift table shapes stay backward-compatible; no destabilizing migrations |
| Performance optimization as a goal | Performance changes that fall out of cleaner code are welcome; performance is not a target |
| Security architecture redesign | The 4-layer encryption stack is fixed; only enforcement of existing security rules is in scope |
| Per-phase doc updates | One centralized sweep at the end (DOCS-01..04) — avoids churn during multi-phase refactor |
| Removal of historical deprecated documentation | Deprecated *code* is deleted; deprecated *doc entries* (e.g., MOD-009 index entry) remain as historical record |
| Auto-fix during audit | Audit is discovery-only; conflating discovery with remediation skips test verification |
| Behavior-change suggestions in audit findings | Out of scope for pure refactor — would tempt scope creep |
| Style linting beyond `dart format` + `flutter analyze` | Existing lint rules are sufficient; adding style debates derails the initiative |
| `sqlite3_flutter_libs` adoption | SQLCipher conflict — actively rejected by CI guardrail |
| Riverpod 3.x upgrade | Confirmed `analyzer` version conflict with `json_serializable` (deferred to FUTURE-TOOL-01) |
| `recoverFromSeed()` key-overwrite bug fix | HIGH-severity per CONCERNS.md but security-architecture changes are out of PROJECT.md scope; deferred to FUTURE-ARCH-04 |

## Traceability

Phase mapping populated by `gsd-roadmapper` during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDIT-01 | Phase 1 | Pending |
| AUDIT-02 | Phase 1 | Pending |
| AUDIT-03 | Phase 1 | Pending |
| AUDIT-04 | Phase 1 | Pending |
| AUDIT-05 | Phase 1 | Pending |
| AUDIT-06 | Phase 1 | Pending |
| AUDIT-07 | Phase 1 | Pending |
| AUDIT-08 | Phase 1 | Pending |
| AUDIT-09 | Phase 1 | Pending |
| AUDIT-10 | Phase 1 | Pending |
| BASE-01 | Phase 2 | Pending |
| BASE-02 | Phase 2 | Pending |
| BASE-03 | Phase 2 | Pending |
| BASE-04 | Phase 2 | Pending |
| BASE-05 | Phase 2 | Pending |
| BASE-06 | Phase 2 | Pending |
| CRIT-01 | Phase 3 | Pending |
| CRIT-02 | Phase 3 | Pending |
| CRIT-03 | Phase 3 | Pending |
| CRIT-04 | Phase 3 | Pending |
| CRIT-05 | Phase 3 | Pending |
| CRIT-06 | Phase 3 | Pending |
| HIGH-01 | Phase 4 | Pending |
| HIGH-02 | Phase 4 | Pending |
| HIGH-03 | Phase 4 | Pending |
| HIGH-04 | Phase 4 | Pending |
| HIGH-05 | Phase 4 | Pending |
| HIGH-06 | Phase 4 | Pending |
| HIGH-07 | Phase 4 | Pending |
| HIGH-08 | Phase 4 | Pending |
| MED-01 | Phase 5 | Complete |
| MED-02 | Phase 5 | Complete |
| MED-03 | Phase 5 | Complete |
| MED-04 | Phase 5 | Complete |
| MED-05 | Phase 5 | Complete |
| MED-06 | Phase 5 | Complete |
| MED-07 | Phase 5 | Complete |
| MED-08 | Phase 5 | Complete |
| LOW-01 | Phase 6 | Complete |
| LOW-02 | Phase 6 | Complete |
| LOW-03 | Phase 6 | Complete |
| LOW-04 | Phase 6 | Complete |
| LOW-05 | Phase 6 | Complete |
| LOW-06 | Phase 6 | Complete |
| LOW-07 | Phase 6 | Complete |
| DOCS-01 | Phase 7 | Complete |
| DOCS-02 | Phase 7 | Complete |
| DOCS-03 | Phase 7 | Complete |
| DOCS-04 | Phase 7 | Complete |
| EXIT-01 | Phase 8 | Pending |
| EXIT-02 | Phase 8 | Pending |
| EXIT-03 | Phase 8 | Pending |
| EXIT-04 | Phase 8 | Pending |
| EXIT-05 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 54 total
- Mapped to phases: 54 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-25*
*Last updated: 2026-04-25 — traceability populated by gsd-roadmapper*
