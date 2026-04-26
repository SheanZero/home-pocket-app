---
phase: 3
slug: critical-fixes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-26
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart 3.x) + custom_lint (import_guard_custom_lint) |
| **Config file** | `analysis_options.yaml` + per-feature `lib/features/*/domain/import_guard.yaml` |
| **Quick run command** | `flutter test --no-pub --reporter compact <changed_test_file>` |
| **Full suite command** | `flutter analyze && dart run custom_lint && flutter test --coverage && dart run scripts/coverage_gate.dart --files <touched-files> --threshold 80 --lcov coverage/lcov_clean.info` |
| **Estimated runtime** | ~120 seconds (flutter test) + ~30s (analyze + custom_lint) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test --no-pub <changed_test_file>` (≤10s)
- **After every plan wave:** Run `flutter analyze && dart run custom_lint && flutter test --coverage` (≤180s)
- **Before `/gsd-verify-work`:** Full suite must be green AND `coverage_gate.dart` exits 0 against the merged Phase-3 touched-files list
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-* | 01 | 1 | CRIT-01 | — | Domain files cannot import data/infra/application/presentation/flutter | arch/lint | `dart run custom_lint && flutter test test/architecture/domain_import_rules_test.dart` | ❌ W0 | ⬜ pending |
| 03-03-* | 03 | 1 | CRIT-02 | — | `lib/features/family_sync/use_cases/` does not exist; tests for moved files pass at new path | unit | `flutter test test/application/family_sync/ && ! test -d lib/features/family_sync/use_cases` | ❌ W0 | ⬜ pending |
| 03-04-* | 04 | 1 | CRIT-04 | — | `ledger_row_data.dart` resides at `lib/features/home/presentation/models/`; callers updated; `dart:ui` import isolated to presentation | unit/widget | `flutter test test/features/home/ && ! test -f lib/features/home/domain/models/ledger_row_data.dart` | ❌ W0 | ⬜ pending |
| 03-05-* | 05 | 1 | CRIT-05 | — | Characterization tests GREEN before refactor; touched-files reach ≥80% coverage post-refactor | unit/widget/golden | `flutter test --coverage && dart run scripts/coverage_gate.dart --files <touched-files> --threshold 80` | ❌ W0 | ⬜ pending |
| 03-02-* | 02 | 2 | CRIT-03, CRIT-06 | — | `appDatabaseProvider` does not throw; `AppInitializer.initialize()` returns InitResult; failure renders localized fallback screen | unit/widget | `flutter test test/core/initialization/ test/infrastructure/security/providers_test.dart && flutter test integration_test/init_failure_test.dart` | ❌ W0 | ⬜ pending |
| 03-CLOSE | 01 | 2-end | CRIT-01..06 | — | `.github/workflows/audit.yml` flips `import_guard` to blocking; CI dry-run passes against post-fix codebase | CI | `gh workflow run audit.yml --ref <branch> && gh run watch --exit-status` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 (test infrastructure) is owned by Plan 03-05. Specifically:

- [ ] `test/architecture/domain_import_rules_test.dart` — D-02: meta-test loading every `lib/features/*/domain/**/import_guard.yaml`, asserting deny list contains `data/**`, `infrastructure/**`, `application/**`, `presentation/**`, `flutter/**`. Required before Plan 03-01 commits.
- [ ] `test/core/initialization/app_initializer_test.dart` — Plan 03-02's primary test. ~10 cases covering happy path + 3-4 failure modes (master-key error, DB error, seed error, unknown error). Uses Mocktail-style hand-written fakes for `MasterKeyRepository`, `AppDatabase` factory, `SeedService`. NEVER touches `flutter_secure_storage` or `recoverFromSeed()`.
- [ ] `test/infrastructure/security/providers_test.dart` (additions) — verifies concrete `appDatabaseProvider` does not throw when given a properly-configured `ProviderScope`; verifies `.overrideWithValue(AppDatabase.forTesting())` continues to work.
- [ ] `test/features/home/presentation/models/ledger_row_data_test.dart` — characterization test pre-move (Plan 03-04 + Plan 03-05). Locks current `Color` field values + formatted display strings.
- [ ] `test/application/family_sync/<5_files>_test.dart` — moved from `test/features/family_sync/use_cases/`; verified GREEN at new path before deleting old test files (Plan 03-03 + Plan 03-05).
- [ ] Characterization tests for every file in `Phase-3 touched-files ∩ files-needing-tests.txt` — written in Plan 03-05, GREEN before the matching refactor commit lands. Per-file technique: golden test (UI widgets), widget test (stateful screens), unit test (plain Dart classes / Freezed models / providers).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Init-failure fallback screen renders correctly across `ja`/`zh`/`en` locales with `Retry` button restoring app on success | CRIT-03, CRIT-06 | Visual + interaction verification of `S.of(context).initFailedTitle/Message/Retry`; widget test covers structure but device-frame visual is manual | (1) Run `flutter run` with master-key seeded to throw on derive (debug flag) (2) Verify localized title + message + retry render per UI-SPEC.md (3) Tap Retry, verify app boots normally after flag cleared |
| `import_guard` blocking flip in `.github/workflows/audit.yml` does not break unrelated CI jobs | CRIT-01 | CI configuration; production-only effect | (1) Open PR with the flip commit (2) Confirm GitHub Actions passes the now-blocking `import_guard` job on the post-fix codebase (3) Confirm no unrelated jobs (test, analyze, coverage) regress |
| `git mv` history preservation for the 5 use_cases files survives squash-merge | CRIT-02 | History semantics depend on merge strategy at the org level | (1) After all 5 use_cases PRs merge, run `git log --follow lib/application/family_sync/<file>.dart` (2) Verify pre-move history still appears |

---

## Validation Sign-Off

- [ ] All tasks have automated verify command in their PLAN.md acceptance criteria, OR an entry in Wave 0 Requirements above
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (Plan 03-01..05 each commit per sub-task; verify after each)
- [ ] Wave 0 covers all MISSING references in Per-Task Verification Map (`❌ W0` rows above)
- [ ] No watch-mode flags (`flutter test --watch` is forbidden in Plan acceptance criteria — must be one-shot exit-code-checkable)
- [ ] Feedback latency < 180s for full-suite run on touched-files
- [ ] `nyquist_compliant: true` set in frontmatter once all checkboxes complete

**Approval:** pending
