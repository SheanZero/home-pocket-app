# Phase 3: CRITICAL Fixes - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminate every CRITICAL-severity finding from `.planning/audit/issues.json` (24 layer violations + 5 misplaced `use_cases/` files = 29 LV findings) AND fix `appDatabaseProvider` UnimplementedError (CRIT-03, sourced from CONCERNS.md, not in `issues.json`). Every file touched in this phase reaches ≥80% test coverage with **characterization tests written before the refactor**. `flutter analyze` exits 0; `dart run custom_lint` exits 0; all tests GREEN; user-observable behavior is byte-identical to the pre-Phase-3 baseline.

**Hard exit gate at Phase 3 close:** `import_guard` flips to **blocking** in CI (per Phase 1 D-04). Any open layer-violation finding after Phase 3 blocks Phase 4 from starting.

**In scope (this phase only):**
- 24 layer-violation findings (LV-001..LV-024) in `issues.json`
- CRIT-03 `appDatabaseProvider` UnimplementedError (CONCERNS.md `appDatabaseProvider throws by default`)
- AppInitializer extraction (CONCERNS.md "Centralized AppInitializer missing" — closed concurrently because CRIT-03 fix path requires it)
- Characterization tests on every file in the touched-files list, including pure renames

**Out of scope (deferred to later phases or v2):**
- HIGH/MEDIUM/LOW severity findings (Phases 4–6)
- ResolveLedgerTypeService deletion (Phase 4 HIGH-03)
- CategoryLocaleService rename (Phase 5 MED-02)
- ARB-key extraction at large scale (Phase 5 MED-03/04) — Phase 3 only seeds 3 init-failure keys
- MOD-009 deprecated code deletion (Phase 5 MED-06)
- Drift index additions (Phase 6 LOW-04)
- `recoverFromSeed()` key-overwrite bug (FUTURE-ARCH-04, security-architecture out of scope)
- `*.mocks.dart` strategy (Phase 4 HIGH-07)

</domain>

<decisions>
## Implementation Decisions

### Domain layer rule (LV-001..LV-016, LV-023, LV-024 — 19 of 24 findings)

- **D-01:** Resolve via **per-file allow lists in subdirectory `import_guard.yaml`**, not by relaxing the feature-level rule. Each `features/<f>/domain/models/` and `features/<f>/domain/repositories/` directory gets its own `import_guard.yaml` with `inherit: true`, declaring only the specific intra-domain files it composes (e.g., `models/category_ledger_config.dart` allows `transaction.dart`). The feature-level deny list (data, infrastructure, application, presentation, flutter) is preserved upstream and inherited.
- **D-02:** Ship `test/architecture/domain_import_rules_test.dart` — a Dart unit test that loads each `features/<f>/domain/import_guard.yaml` (and its subdirectory descendants), parses the YAML, and asserts the deny list still contains `data/**`, `infrastructure/**`, `application/**`, `presentation/**`, `flutter/**`. Fails CI if anyone weakens the rule beyond the documented intra-domain composition.
- **D-03:** Establish a new `test/architecture/` directory as the convention for "meta-tests about codebase shape." Future phases (provider-graph hygiene in Phase 4, etc.) extend this directory.

### `appDatabaseProvider` + AppInitializer (CRIT-03)

- **D-04:** Replace the placeholder `@riverpod AppDatabase appDatabase(Ref ref) { throw UnimplementedError(...); }` with a **concrete provider that derives the master key, builds the encrypted executor, and returns `AppDatabase`**. The provider is self-overriding in production; tests still inject `.overrideWithValue()` for in-memory `AppDatabase.forTesting()`.
- **D-05:** Extract `lib/core/initialization/app_initializer.dart` per CLAUDE.md spec. Function signature: `Future<InitResult> initialize(ProviderContainer container)`. `InitResult` is a Freezed sealed class with `success`/`failure` variants; `failure` carries a structured error (typed enum: `masterKeyError | databaseError | seedError | unknownError` + an originating exception).
- **D-06:** AppInitializer captures the **full `lib/main.dart:28-83` sequence verbatim** — master-key check + key generation → encrypted executor → AppDatabase → ensure default book → any other inlined steps. Pure refactor: behavior identical, just centralized and unit-testable.
- **D-07:** On `InitResult.failure`, `main.dart` renders a **localized error fallback screen** with title + message + retry button. This requires 3 new ARB keys (`initFailedTitle`, `initFailedMessage`, `initFailedRetry`) added to `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb`, then `flutter gen-l10n`. Retry button re-invokes `AppInitializer.initialize()`.
- **D-08:** AppInitializer takes constructor-injected dependencies (`MasterKeyRepository`, `AppDatabase` factory, `SeedService`). Tests pass fakes that throw at each stage; ~10 unit tests cover happy path + 3-4 failure modes (master-key error, DB error, seed error). Hits CRIT-05 ≥80% coverage on `app_initializer.dart` cleanly. No real `flutter_secure_storage` in tests.

### `use_cases/` migration (LV-017..LV-021 — 5 findings)

- **D-09:** Per-file `git mv` from `lib/features/family_sync/use_cases/` to `lib/application/family_sync/`, **preserving filenames** (existing `application/family_sync/` already uses the `_use_case.dart` suffix consistently). 5 atomic PRs, one per file. Each PR also moves the corresponding test file (`test/features/family_sync/use_cases/<name>_test.dart` → `test/application/family_sync/<name>_test.dart`). Per-PR atomicity makes review trivial and bisect-friendly.
- **D-10:** After all 5 files move, the empty `lib/features/family_sync/use_cases/` directory is deleted in the final per-file PR (or as a 6th cleanup commit), and a `features/family_sync/` import_guard rule is added that explicitly denies any future re-creation of `use_cases/` underneath features.

### `ledger_row_data.dart` dart:ui import (LV-022 — 1 finding)

- **D-11:** Move `lib/features/home/domain/models/ledger_row_data.dart` to `lib/features/home/presentation/models/ledger_row_data.dart`. The file holds 10 `Color` fields plus formatted display strings — it is by nature a presentation view-model, not a domain entity. Update the (small set of) callers (`home_screen.dart` and friends). LV-022 closes; no Color stripping or hex-int conversion needed.
- **D-12:** This sets a project convention: **view-models that compose `dart:ui` types (Color, TextStyle, Size, etc.) belong in `features/<f>/presentation/models/`**. Document the convention in CLAUDE.md during the Phase 7 sweep (not now).

### Plan structure & wave parallelization

- **D-13** [informational — describes plan structure, embodied by the 5 plan files existing]**:** Phase 3 splits into **5 plans, one per concern**:
  - **Plan 03-01:** Domain `import_guard.yaml` per-subdirectory rules + `test/architecture/domain_import_rules_test.dart` (covers LV-001..016, LV-023, LV-024 — 19 findings)
  - **Plan 03-02:** `AppInitializer` extraction + concrete `appDatabaseProvider` + `InitResult` fallback UI + 3 ARB keys (covers CRIT-03)
  - **Plan 03-03:** `family_sync/use_cases/` migration — 5 sub-tasks, one per file (covers LV-017..021)
  - **Plan 03-04:** `ledger_row_data.dart` move to presentation (covers LV-022)
  - **Plan 03-05:** Characterization-test pre-work for files in `files-needing-tests.txt` ∩ Phase-3 touched-files (gating prerequisite for Plan 03-02; concurrent prereq for Plans 03-01/03/04)
- **D-14** [informational — describes wave structure, embodied by plan frontmatter `wave:` and `depends_on:` fields]**:** **Wave 1** runs `{Plan 03-01, Plan 03-03, Plan 03-04, Plan 03-05}` in parallel — they share no source-file dependencies (yaml-only, file moves to disjoint dirs, test-only changes). **Wave 2** runs `Plan 03-02` alone — depends on Plan 03-05's test infra (fake repository patterns) being merged. Estimated wall time: W1 ~16h parallel, W2 ~14h sequential.

### Test rigor (CRIT-05)

- **D-15:** **Strict interpretation** of "every file touched ≥80% coverage." `coverage_gate.dart --files <touched-files> --threshold 80` runs against the post-refactor `lcov_clean.info`. **Pure renames count as touched** — even `git mv` triggers the gate. No escape hatches; no per-file rationale skips. Aligns with Phase 2 D-09 (plan declares touched-files; gate runs against that list) and PROJECT.md "no negotiable done." Plan 03-05's job is to write characterization tests for every file in `Phase-3 touched-files ∩ files-needing-tests.txt` BEFORE the corresponding refactor commits land.

### Repo lock & CI staging

- **D-16:** Repo lock (Phase 2 D-07) is **operationally active throughout Phase 3**. Each plan's preamble must capture this constraint: only PRs implementing this phase's plans merge to `main`; non-cleanup PRs wait until Phase 6 closes. No bypass label.
- **D-17:** `import_guard` flips to **blocking** in `.github/workflows/audit.yml` at Phase 3 close (Phase 1 D-04). The flip is the last commit of the last Phase 3 plan; verified by a CI dry-run that confirms the post-fix codebase passes the now-blocking gate before Phase 4 begins.

### Claude's Discretion

- Exact naming of the `InitResult` failure variants and error type enum
- Whether `SeedService` is a new class or an inlined free function in `AppInitializer`
- Exact characterization-test technique per file (golden tests vs widget tests vs unit tests vs integration tests) — picked per-file by the planner based on the file's nature
- Order in which the 5 use_case files migrate (any order works since they're independent)
- Whether the `ledger_row_data.dart` move is bundled into Plan 03-04 alone or fans out to a 03-04a (move) + 03-04b (caller updates) split — planner's call based on caller count

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents (researcher, planner, executor) MUST read these before planning or implementing.**

### Project scope and constraints
- `.planning/PROJECT.md` — Initiative scope, behavior-preservation constraint, key decisions, out-of-scope items
- `.planning/REQUIREMENTS.md` §CRIT-01..CRIT-06 — The 6 locked deliverables this phase must produce
- `.planning/ROADMAP.md` §"Phase 3: CRITICAL Fixes" — Goal, dependencies, success criteria

### Audit catalogue (Phase 1 output, Phase 3's source of truth)
- `.planning/audit/issues.json` — 24 CRITICAL findings (LV-001..LV-024) + 1 RD-001/RD-002 MEDIUM (out of Phase 3 scope)
- `.planning/audit/ISSUES.md` — Human-readable, severity-grouped catalogue; Phase 3 owns everything under `## CRITICAL`
- `.planning/audit/SCHEMA.md` — Finding-record schema; Phase 3 closes findings by setting `status: open → closed` with `closed_in_phase: 3` + `closed_commit: <sha>`
- `.planning/audit/REPO-LOCK-POLICY.md` — Repo lock contract every Phase 3 plan must reference

### Coverage baseline (Phase 2 output, Phase 3's gating prerequisite)
- `.planning/audit/coverage-baseline.txt` — Pre-Phase-3 per-file coverage; the "before" image
- `.planning/audit/coverage-baseline.json` — Machine-readable companion
- `.planning/audit/files-needing-tests.txt` — The <80% file list; intersect with Phase-3 touched-files to scope Plan 03-05
- `.planning/audit/files-needing-tests.json` — Machine-readable companion
- `scripts/coverage_gate.dart` — Phase 3's per-plan exit gate; invocation: `dart run scripts/coverage_gate.dart --files <touched-files> --threshold 80 --lcov coverage/lcov_clean.info`

### Prior phase contracts (locked, Phase 3 must respect)
- `.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md` — Specifically:
  - **D-04 (staged enablement)** — `import_guard` flips blocking at Phase 3 close
  - **D-06/D-07 (stable IDs)** — close findings, do not re-issue
  - **D-08 (split/merge convention)** — if a CRIT finding splits during fixing, follow the documented bookkeeping
- `.planning/phases/02-coverage-baseline/02-CONTEXT.md` — Specifically:
  - **D-05 (very_good_coverage blocking)** — global ≥80% gate is already blocking when Phase 3 starts
  - **D-07 (repo lock)** — operationally active throughout Phase 3
  - **D-08 (frozen baseline)** — files-needing-tests.txt is immutable mid-initiative; Phase 3 does NOT regenerate it
  - **D-09 (touched-files gating contract)** — every Phase 3 plan declares touched-files; gate runs against that list

### Codebase ground-truth (current state)
- `.planning/codebase/CONCERNS.md` — Specifically:
  - "Deprecated services still wired" / "Hardcoded UI strings" — NOT Phase 3 scope (Phase 4/5)
  - "appDatabaseProvider throws by default" — IS Phase 3 scope (CRIT-03 source)
  - "Centralized AppInitializer" — Phase 3 closes this concurrently with CRIT-03 fix
- `.planning/codebase/STRUCTURE.md` — 5-layer Clean Architecture file layout; Phase 3 must preserve it
- `.planning/codebase/CONVENTIONS.md` — `scripts/` precedent for new arch test
- `.planning/codebase/TESTING.md` — 14 committed `*.mocks.dart` files (Phase 4 territory; Phase 3 does NOT touch them); `AppDatabase.forTesting()` in-memory pattern (Phase 3 reuses)

### Project-wide rules
- `CLAUDE.md` §"App Initialization" — `AppInitializer` spec verbatim; Phase 3 D-05/06 align to this
- `CLAUDE.md` §"Common Pitfalls" #12 — "Don't skip AppInitializer — initialize core services before runApp()"; Phase 3 enforces this
- `CLAUDE.md` §"i18n Rules" — All UI text via `S.of(context)`; Phase 3 D-07 fallback screen complies
- `CLAUDE.md` §"Riverpod Provider Rules" — "NEVER throw `UnimplementedError` in providers"; CRIT-03 closes this
- `.claude/rules/testing.md` — ≥80% coverage as project rule; Phase 3 D-15 enforces strictly
- `.claude/rules/arch.md` — Per-phase doc updates DEFERRED to Phase 7; Phase 3 must NOT touch ARCH/MOD/ADR docs

### Files Phase 3 directly modifies (initial inventory)
- `lib/features/*/domain/import_guard.yaml` (6 feature-level + new per-subdirectory yamls) — Plan 03-01
- `lib/infrastructure/security/providers.dart` (concrete `appDatabaseProvider`) — Plan 03-02
- `lib/main.dart` (delegate init to `AppInitializer.initialize()`) — Plan 03-02
- `lib/core/initialization/app_initializer.dart` (NEW) — Plan 03-02
- `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` (3 new keys) — Plan 03-02
- `lib/features/family_sync/use_cases/*.dart` → `lib/application/family_sync/*.dart` (5 files) — Plan 03-03
- `test/features/family_sync/use_cases/*` → `test/application/family_sync/*` (5 files) — Plan 03-03
- `lib/features/home/domain/models/ledger_row_data.dart` → `lib/features/home/presentation/models/ledger_row_data.dart` — Plan 03-04
- `test/architecture/domain_import_rules_test.dart` (NEW) — Plan 03-01
- `test/core/initialization/app_initializer_test.dart` (NEW) — Plan 03-02
- Characterization tests for files in `Phase-3 touched-files ∩ files-needing-tests.txt` — Plan 03-05
- `.github/workflows/audit.yml` (flip `import_guard` to blocking) — final commit of Plan 03-01 or a Phase 3 close commit

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/data/app_database.dart` — `AppDatabase.forTesting()` in-memory constructor; tests reuse this for `appDatabaseProvider` overrides
- `lib/infrastructure/crypto/database/encrypted_database.dart` — `createEncryptedExecutor(masterKeyRepo)` is the production factory `AppInitializer` calls
- `lib/infrastructure/crypto/repositories/master_key_repository.dart` — `MasterKeyRepository.deriveKey()` HKDF; `AppInitializer` consumes via constructor injection
- `lib/application/family_sync/` — Already houses 17 use-case files; the 5 incoming migrations join existing siblings (apply_sync_operations_use_case.dart, full_sync_use_case.dart, etc.)
- `lib/generated/app_localizations*.dart` — Phase 3 adds 3 keys; regenerate via `flutter gen-l10n` after ARB edits
- `scripts/coverage_gate.dart` (Phase 2 output) — Per-plan exit gate
- `scripts/merge_findings.dart` (Phase 1 output) — Phase 3 may invoke to verify status updates round-trip cleanly

### Established Patterns
- **Riverpod `@riverpod` code-gen** — All providers in `lib/infrastructure/security/providers.dart` follow this; Phase 3's concrete `appDatabaseProvider` extends the same pattern
- **Freezed sealed classes** — `InitResult.success` / `InitResult.failure` follows the established Freezed pattern (e.g., classification results, sync results elsewhere in the codebase)
- **Constructor injection for testability** — Existing pattern across `application/` use cases; `AppInitializer` adopts the same
- **Per-feature `import_guard.yaml`** — Already in place at `lib/features/*/domain/import_guard.yaml`; Phase 3 extends with subdirectory descendants using `inherit: true`
- **Test directory mirrors source** — `test/<source-relative-path>` is project convention; Plan 03-03 source moves trigger matching test moves
- **`AppDatabase.forTesting()` for unit tests** — `AppInitializer` tests use this same pattern via the injected DB factory

### Integration Points
- `.github/workflows/audit.yml` — Phase 3's final touch flips `import_guard` to blocking; coordinated with the last plan to merge
- `lib/l10n/` — 3 new ARB keys cross-cut all three locale files; verified by Phase 5 MED-04 ARB-parity check (Phase 3's additions stay parity-clean)
- `pubspec.yaml` — No new dependencies in Phase 3 (Freezed already present; uses `ProviderContainer` from existing `flutter_riverpod`)
- `analysis_options.yaml` — No changes (the architecture test runs via `flutter test`, not the analyzer)

</code_context>

<specifics>
## Specific Ideas

- **Phase 3 close = `import_guard` blocking flip** — The very last commit of Phase 3 must be the audit.yml edit that removes `continue-on-error: true` from the `import_guard` job. A pre-flip dry-run in CI confirms the post-Phase-3 codebase passes the now-blocking gate. If anything regresses between the last fix commit and the flip commit, Phase 3 is not closed.
- **AppInitializer test injection becomes the Phase 3+ pattern** — The fake-repository constructor-injection pattern Plan 03-05 establishes for `AppInitializer` becomes the default test pattern Phase 4 will extend (the upcoming `*.mocks.dart` strategy decision in HIGH-07 will lean on this same fake-injection convention).
- **`test/architecture/` directory is the seedbed for future arch tests** — Phase 4 will likely add `provider_graph_hygiene_test.dart` (HIGH-04 enforcement: every feature has exactly one `repository_providers.dart`); Phase 3 establishes the directory and convention.
- **Per-subdirectory `import_guard.yaml` proliferation is a deliberate trade-off** — More YAML files (~10 net new) in exchange for surgical precision and zero risk of weakening the deny list. The architecture test (D-02) prevents the deny list from regressing accidentally.
- **3 ARB keys early are a known scope bridge** — Strictly speaking the i18n surface is Phase 5 territory (MED-04). Phase 3 needs them now because the InitResult fallback can't be tested for CRIT-05 coverage without rendering localized strings. Bridging note in `<deferred>` for the Phase 5 planner so the keys aren't double-counted.

</specifics>

<deferred>
## Deferred Ideas

- **Bridging note for Phase 5 planner**: The 3 init-failure ARB keys (`initFailedTitle`, `initFailedMessage`, `initFailedRetry`) are pre-seeded by Phase 3 across `app_ja.arb` / `app_zh.arb` / `app_en.arb`. They count toward MED-04 ARB-parity (already parity-clean as introduced) and toward MED-03 hardcoded-CJK elimination (added directly to ARB, never inlined). Phase 5 should NOT re-touch these specific keys.
- **`*.mocks.dart` strategy decision** — Explicitly Phase 4 territory (HIGH-07). Phase 3 keeps existing committed mockito artifacts as-is; tests for new files use Mocktail-style hand-written fakes (consistent with the constructor-injection convention) so Phase 4 can re-evaluate strategy without Phase 3 having pre-committed.
- **`test/architecture/provider_graph_hygiene_test.dart`** — Phase 4 candidate (HIGH-04 enforcement). The `test/architecture/` directory established by Phase 3 D-03 makes adding it trivial.
- **CLAUDE.md update for the "view-models with `dart:ui` belong in presentation/models/" convention (D-12)** — Phase 7 documentation sweep. Phase 3 establishes the convention by example; the doc edit waits.
- **Deletion of the empty `lib/features/family_sync/use_cases/` directory's deny rule** — Phase 7 may decide whether the explicit "no `use_cases/` under features" deny stays in `import_guard.yaml` permanently or gets removed once the test/architecture suite enforces it.
- **`SeedService` class extraction** — Discretionary in Plan 03-02. If the planner finds the inlined seed logic is small enough to live as a private method on `AppInitializer`, extraction is deferred. If it grows, extract to `lib/application/initialization/seed_service.dart` (matching the placement-decision rule).
- **`recoverFromSeed()` key-overwrite bug** — FUTURE-ARCH-04, security-architecture out of scope per PROJECT.md. Any Phase 3 test touching `KeyRepositoryImpl` uses mock-only paths (no real `flutter_secure_storage`) to avoid accidentally exercising the bug. Reaffirms STATE.md blocker note.
- **`ledger_row_data.dart` rename** — Considered renaming to `ledger_row_view_model.dart` to match its presentation role; declined for Phase 3 to keep the LV-022 fix a pure file move. Rename can happen during Phase 7 if desired.

</deferred>

---

*Phase: 03-critical-fixes*
*Context gathered: 2026-04-26*
