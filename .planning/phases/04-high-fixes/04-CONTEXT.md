# Phase 4: HIGH Fixes - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminate every HIGH-severity requirement (HIGH-01..HIGH-08) from `.planning/REQUIREMENTS.md`. The Phase 4 substantive scope is HIGH-02 (presentation→infrastructure decoupling), HIGH-03 (`ResolveLedgerTypeService` deletion), HIGH-04 (single `repository_providers.dart` per feature + `state_*.dart` convention), HIGH-05 (six `keepAlive: true` providers preserved), HIGH-06 (no `UnimplementedError` providers in production), and HIGH-07 (`*.mocks.dart` strategy applied). HIGH-01 (zero open HIGH entries in `issues.json`) is trivially true on entry — the audit tooling did not generate HIGH-tagged findings; this phase's "definition of done" is requirement-driven, not finding-driven. HIGH-08 imposes the standard fix-phase exit gate. Every file touched reaches ≥80% coverage with characterization tests written before refactor.

**Important calibration — the source-of-truth difference:** Unlike Phase 3 (which closed CRITICAL findings against `import_guard`-generated entries in `issues.json`), Phase 4's scope is sourced from `REQUIREMENTS.md` (HIGH-01..HIGH-08), which was derived from `.planning/codebase/CONCERNS.md` and `SUMMARY.md` analysis — not from automated audit output. `issues.json` currently has zero HIGH entries. Phase 4 closes the requirements; the audit catalogue is updated as a side effect (status remains accurate to its own scoring model).

**Hard exit gate at Phase 4 close:**
- HIGH-02: `lib/features/*/presentation/import_guard.yaml` deny `infrastructure/**` is in place; `flutter analyze` exits 0 against the new rules; `test/architecture/presentation_layer_rules_test.dart` passes.
- HIGH-04/05/06: `test/architecture/provider_graph_hygiene_test.dart` passes — single `repository_providers.dart` per feature, `state_*.dart` naming convention enforced, six named keepAlive providers retain `keepAlive: true`, no `UnimplementedError` provider bodies in `lib/`.
- HIGH-07: zero `*.mocks.dart` files committed; zero `mockito` references in `test/`.
- HIGH-08: per-plan `coverage_gate.dart --files <touched-files> --threshold 80` exits 0; `flutter analyze` 0; `dart run custom_lint` 0; all tests GREEN; user-observable behavior unchanged.

**In scope (this phase only):**
- HIGH-02: 33 presentation→infrastructure imports (5 sub-patterns: i18n formatters, locale_settings model, repository_providers wiring, direct service classes, sync clients in screens)
- HIGH-03: `ResolveLedgerTypeService` deletion (6 sites: source, provider, .g.dart, mocks, test, test mocks) — no production callers exist; pure dead code
- HIGH-04: collapse `features/<f>/presentation/providers/` to a single `repository_providers.dart` for DI + `state_*.dart` files for notifier/state providers; merge non-DI provider files via rename, fold use_case providers into `repository_providers.dart`
- HIGH-05: verify and lock the six named `keepAlive: true` providers (`syncEngineProvider`, `transactionChangeTrackerProvider`, `merchantDatabaseProvider`, `activeGroupProvider`, `activeGroupMembersProvider`, `ledgerProvider`) via architecture-test hard list
- HIGH-06: assert no `UnimplementedError` provider body remains in `lib/` (test override fixtures excepted)
- HIGH-07: Mocktail big-bang migration of all 14 `*.mocks.dart` fixtures with inline hand-written fakes; remove `mockito` from dev_deps if no transitive consumer
- Characterization tests: every Phase-4 touched file in `Phase-4 touched-files ∩ files-needing-tests.txt` gets coverage written BEFORE its refactor commit (Phase 3 D-15 strict interpretation continues)

**Out of scope (deferred to later phases or v2):**
- MEDIUM/LOW severity findings (Phase 5/6)
- `CategoryLocaleService` rename (MED-02 — Phase 5)
- ARB-key extraction at large scale (MED-03/04 — Phase 5)
- MOD-009 deprecated code deletion (MED-06 — Phase 5)
- Drift index additions (LOW-04 — Phase 6)
- `recoverFromSeed()` key-overwrite bug (FUTURE-ARCH-04, security architecture out of PROJECT.md scope)
- Documentation updates for the new conventions introduced here (`state_*.dart` prefix, FormatterService injectable wrapper, presentation/infrastructure prohibition, Mocktail-only test pattern) — Phase 7 documentation sweep
- Driving CategoryLocaleService from ARB (FUTURE-ARCH-01)
- Re-evaluating Mocktail vs DCM (FUTURE-ARCH-02 / FUTURE-ARCH-03)

</domain>

<decisions>
## Implementation Decisions

### HIGH-02 routing strategy

- **D-01:** **Strict, zero exceptions.** Every one of the 33 `lib/features/*/presentation/` files importing `lib/infrastructure/...` routes through Application. No carve-outs for "pure helpers" or "DI glue files." This is the most restrictive of the three tabled options and yields the largest cleanup surface — accepted because half-strict rules accumulate exception lists and grow brittle.
- **D-02:** **Mixed routing form, three categories with distinct boundaries:**
  - **(a) Wiring deps** — `appDatabaseProvider`, crypto providers, sync-client providers (e2ee, push, websocket, relay, sync_queue, apns), merchant_database_provider, speech_recognition_service_provider: **hoisted into `lib/application/<feature>/repository_providers.dart`** (a new file per affected feature). Feature presentation imports `application/<feature>/repository_providers.dart` (or its providers) only — never `infrastructure/`. The application-layer file may import `infrastructure/...` because Application is permitted Infrastructure access by the 5-layer rule.
  - **(b) Business actions** — `CategoryService.resolveLedgerType`, `MerchantDatabase.lookup`, `E2EEService.encrypt`, `SpeechRecognitionService.start`, etc., currently called directly from screens: **wrapped as `*_use_case.dart` classes** in `lib/application/<domain>/`. Screens call `ref.read(<verb>UseCaseProvider).execute(...)`. Pre-existing use cases in `application/` continue as-is.
  - **(c) Pure helpers** — `DateFormatter`, `NumberFormatter` (currently `infrastructure/i18n/formatters/*`): **wrapped as injectable `lib/application/i18n/formatter_service.dart`** with method-call interface (no static facades; instances obtained via `ref.read(formatterServiceProvider)`). Static helper functions in `infrastructure/i18n/formatters/` remain as the implementation; the application service is the public API for presentation. `LocaleSettings` model (`infrastructure/i18n/models/locale_settings.dart`) routes via the same pattern.
- **D-03:** **import_guard.yaml + architecture test, mirroring Phase 3 D-02.** Phase 4 lands `lib/features/*/presentation/import_guard.yaml` with `inherit: true` plus deny rules for `infrastructure/**` (allowing only `application/**`, `<self-feature>/domain/**`, `<self-feature>/presentation/**`, `core/**`, `shared/**`, `l10n/**`, `generated/**`, `dart:**`, `package:flutter/**`, `package:flutter_riverpod/**`, `package:riverpod_annotation/**`, `package:freezed_annotation/**`, `package:go_router/**`, and other vetted UI deps). Companion `test/architecture/presentation_layer_rules_test.dart` parses each presentation `import_guard.yaml` and asserts the `infrastructure/**` deny entry is present and not weakened.
- **D-04:** Hoisted application-layer files are named `lib/application/<feature>/repository_providers.dart` (mirroring the feature-side filename for consistency). Naming collision is by-path (different directories), not by-symbol — provider names inside differ. No application-layer file is named differently to avoid that "naming collision" concern; the path itself disambiguates.

### HIGH-04 single-source-of-truth interpretation

- **D-05:** **Strict reading.** After Phase 4: `lib/features/<f>/presentation/providers/` contains exactly two file kinds:
  - `repository_providers.dart` — single file per feature, all DI providers (repository factories, use case providers, domain service providers).
  - `state_*.dart` — N files per feature, each holding one notifier/state provider concept. Filename pattern: `state_<concept>.dart` (e.g., `state_voice.dart`, `state_active_group.dart`, `state_locale.dart`, `state_ledger_view.dart`). One concept per file is the convention; if multiple closely-related state providers go together they may co-locate, but the file name reflects the dominant concept.
- **D-06:** **Existing 10+ provider files are restructured per the rule:**
  - `voice_providers.dart` → `state_voice.dart` (all are notifier/transcription state)
  - `use_case_providers.dart` (accounting) → fold contents into `repository_providers.dart`; delete file
  - `category_reorder_notifier.dart` → `state_category_reorder.dart`
  - `active_group_provider.dart` → `state_active_group.dart`
  - `notification_navigation_provider.dart` → `state_notification_navigation.dart`
  - `sync_providers.dart` → split: DI portions fold into `repository_providers.dart`, notifier portions become `state_sync.dart`
  - `group_providers.dart` → split: DI portions fold into `repository_providers.dart`, notifier portions become `state_group.dart`
  - `avatar_sync_providers.dart` → split per the same rule (state vs DI)
  - `ledger_providers.dart` (dual_ledger) → split: DI portions to `repository_providers.dart`, notifier portions to `state_ledger.dart`
  - `today_transactions_provider.dart`, `home_providers.dart`, `shadow_books_provider.dart` → categorize per provider; DI fold, state rename
  - `user_profile_providers.dart` → split per same rule
  - `locale_provider.dart` → `state_locale.dart`
  - `settings_providers.dart`, `backup_providers.dart`, `analytics_providers.dart` → split per same rule
- **D-07:** **Architecture test 04-05** (`test/architecture/provider_graph_hygiene_test.dart`) asserts:
  1. **HIGH-04 structure:** `find lib/features/*/presentation/providers/ -type f -name "*.dart"` returns exactly `{repository_providers.dart, state_<concept>.dart, ...}` per feature; no other file names allowed.
  2. **HIGH-04 DI consolidation:** every Riverpod provider whose return type is a `*Repository`, `*UseCase`, or matches the `Service`-suffix pattern in `lib/application/.../service.dart` is defined in `repository_providers.dart` (parsed via `.g.dart` generated provider list or by scanning source `@riverpod` annotations). Violations fail the test with a "DI provider found outside repository_providers.dart" message.
  3. **HIGH-04 global uniqueness:** scan all `@riverpod` (and `Provider<X>(...)` shorthand) definitions across `lib/`; no two provider names map to the same dependency identity.
  4. **HIGH-05 keepAlive list:** hard-coded `const _expectedKeepAliveProviders = ['syncEngineProvider', 'transactionChangeTrackerProvider', 'merchantDatabaseProvider', 'activeGroupProvider', 'activeGroupMembersProvider', 'ledgerProvider']` — every entry must have `@Riverpod(keepAlive: true)` (or `Provider<...>(...) ..keepAlive`) somewhere in `lib/`. If a name is renamed during Phase 4 refactor, the test's hard-coded entry is updated in the same commit. Adding new keepAlive providers is allowed; removing one of the six requires updating both the source and the test list (lockstep) — the test failure is the alarm.
  5. **HIGH-06 no UnimplementedError:** grep across `lib/**/*.dart` for `throw UnimplementedError` inside `@riverpod` function bodies or `Provider<X>` constructors and fail. Test override fixtures and constructor-arg defaults are excluded by path filter (`test/` paths are not scanned).

### HIGH-07 `*.mocks.dart` strategy

- **D-08:** **Mocktail hand-written fakes, big-bang migration.** Aligns with SUMMARY.md recommendation and Phase 3 D-08 / D-15 (AppInitializer fakes were already hand-written Mocktail-style). Drift risk on committed Mockito mocks is the documented driver in CONCERNS.md.
- **D-09:** **Standalone Plan 04-04 executes the full migration in one PR.** All 14 `*.mocks.dart` files deleted; corresponding test files updated to declare inline `class _Fake<X> extends Fake implements X { ... }` or `class _Mock<X> extends Mock implements X { ... }` (mocktail) classes; `@GenerateMocks` annotations removed from test sources; Mockito removed from `pubspec.yaml dev_dependencies` if no transitive consumer remains. The 14-fixture impact is single-PR-scoped to make Mocktail conventions land cohesively across the repo.
- **D-10:** **Fakes are inline in each test file** (continues Phase 3 D-15 / AppInitializer test convention). No new `test/_fakes/` directory. If a fake is needed by multiple tests in Phase 4+, the Phase 4 work duplicates it (acceptable cost; promotes test isolation); future phases may extract to a shared location if the duplication crosses an empirical pain threshold (Phase 7 decides).
- **D-11:** **Test mocks for currently uncovered fakes are written as part of the migration.** Phase 4 doesn't generate new Mockito mocks for files that didn't have them; existing 14-file coverage is migrated 1-to-1.

### HIGH-03 `ResolveLedgerTypeService` deletion

- **D-12:** **Confirmed pure dead code.** The service is `@Deprecated('Use CategoryService instead')` and delegates to `CategoryService` internally. Zero production read sites for the deprecated provider — `transaction_confirm_screen.dart` already uses `categoryServiceProvider` directly. The only references are: source class def, the `resolveLedgerTypeService` provider entry in `use_case_providers.dart`, generated `.g.dart` provider line, the test file, and the test's `*.mocks.dart`. **No call-site replacement work.**
- **D-13:** **Six atomic commits, mirroring Phase 3 D-09 / D-10 use_cases migration pattern.** Plan 04-03 ships:
  - Commit 1: delete `lib/application/dual_ledger/resolve_ledger_type_service.dart`
  - Commit 2: remove the `resolveLedgerTypeService` provider definition from `lib/features/accounting/presentation/providers/use_case_providers.dart` (note: this file is also restructured by Plan 04-02 — Plan 04-03 lands first; Plan 04-02 absorbs the now-shorter file when it folds use cases into `repository_providers.dart`)
  - Commit 3: regenerate `use_case_providers.g.dart` (drops `_$resolveLedgerTypeServiceHash`, the internal `Provider`, and `ResolveLedgerTypeServiceRef` typedef) — verify clean diff
  - Commit 4: delete `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart`
  - Commit 5: delete `test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart`
  - Commit 6: cleanup — verify `flutter analyze` 0, `flutter test` GREEN, no orphan imports of the deleted symbol; close HIGH-03 in `issues.json` if a tracking entry exists
- **D-14:** **Plan 04-03 runs in Wave 1, parallel to Plan 04-04.** No file-level dependency between RLS deletion and Mocktail migration except for the RLS test's `*.mocks.dart` (Commit 5). To avoid Wave 1 internal sequencing, Plan 04-04 explicitly skips that one file (it's already deleted by Plan 04-03 Commit 5); Plan 04-04's "13 fixtures" excludes `resolve_ledger_type_service_test.mocks.dart`.

### Plan structure & wave parallelization

- **D-15** [informational — describes plan structure, embodied by 6 plan files]**:** Phase 4 splits into **6 plans**:
  - **Plan 04-01:** Application-layer routing scaffolding — new `lib/application/<feature>/repository_providers.dart` files for each affected feature; new use cases wrapping sync/ml/speech business actions; new `lib/application/i18n/formatter_service.dart` injectable wrapper (HIGH-02 prep)
  - **Plan 04-02:** Presentation refactor — replace 33 `infrastructure/` imports with `application/` paths; restructure `features/<f>/presentation/providers/` per D-05/D-06 (`repository_providers.dart` consolidation + `state_*.dart` rename + DI fold); add `lib/features/*/presentation/import_guard.yaml`; add `test/architecture/presentation_layer_rules_test.dart` (HIGH-02, HIGH-04 — depends on 04-01)
  - **Plan 04-03:** `ResolveLedgerTypeService` 6-atomic-commit deletion (HIGH-03 — independent of 04-01/02; Wave 1)
  - **Plan 04-04:** Mocktail big-bang migration — 13 fixtures (excluding RLS-test mocks deleted by 04-03), inline hand-written fakes, mockito removal (HIGH-07 — independent; Wave 1)
  - **Plan 04-05:** `test/architecture/provider_graph_hygiene_test.dart` covering HIGH-04 structure + HIGH-04 DI consolidation + HIGH-04 global uniqueness + HIGH-05 keepAlive hard list + HIGH-06 no UnimplementedError (depends on 04-02 — Wave 4)
  - **Plan 04-06:** Characterization tests for `Phase-4 touched-files ∩ files-needing-tests.txt` — must land before refactor commits in 04-01/02/03/04 (Wave 0 prereq)
- **D-16** [informational — describes wave structure]**:** **Wave 0** runs `Plan 04-06` (test infra prerequisite). **Wave 1** runs `{Plan 04-03, Plan 04-04}` in parallel (independent file scopes; cross-coordinated via D-14 to skip RLS-test mock). **Wave 2** runs `Plan 04-01` alone (consumes 04-06 conventions). **Wave 3** runs `Plan 04-02` alone (consumes 04-01 application-layer scaffolding). **Wave 4** runs `Plan 04-05` (asserts the structure created by 04-02). Estimated wall time: W0 ~12h; W1 ~14h parallel (RLS ~3h, Mocktail ~14h); W2 ~16h; W3 ~24h (largest plan); W4 ~6h.

### Test rigor (HIGH-08, continues Phase 3 D-15)

- **D-17:** **Strict interpretation of "every file touched ≥80% coverage" continues from Phase 3.** `dart run scripts/coverage_gate.dart --files <touched-files> --threshold 80 --lcov coverage/lcov_clean.info` runs against post-refactor lcov on every Phase 4 plan. Pure renames (the ~10 `state_*.dart` rename moves) count as touched. No escape hatches. Plan 04-06's job: every file in `Phase-4 touched-files ∩ files-needing-tests.txt` gets characterization tests landing BEFORE the refactor commits in Plans 04-01..04 land.
- **D-18:** **Touched-files manifest expected scope:** Plan 04-02 will touch ~33 presentation files plus ~10 provider rename files (~43 touched in 04-02 alone). Plan 04-01 touches the `application/<feature>/repository_providers.dart` new files (~5-7 files) plus new use case classes (~5-8 files) plus `application/i18n/formatter_service.dart`. Plan 04-04 touches ~14 test files. Plan 04-03 touches 5 files (one deleted symbol cascading through the locked references). Total Phase 4 touched-file estimate: 65–80 files. Coverage burden for characterization tests is non-trivial; Plan 04-06 absorbs that cost up front.

### Repo lock & CI continuity

- **D-19:** **Repo lock (Phase 2 D-07)** remains operationally active throughout Phase 4. Each plan's preamble must capture this constraint: only PRs implementing this phase's plans merge to `main`; non-cleanup PRs continue to wait until Phase 6 closes.
- **D-20:** **`import_guard` is already blocking at Phase 4 entry** (Phase 3 D-17 final-commit flip). Phase 4 adds new `lib/features/*/presentation/import_guard.yaml` rules. Critical sequencing: the new yaml lands in the SAME commit as the resolved violations, never standalone. Pattern: each Plan 04-02 sub-commit resolves a feature's presentation→infrastructure violations, then in the same commit adds that feature's `presentation/import_guard.yaml`. CI never sees a broken state.
- **D-21:** **`coverage_gate.dart` per-file gate** is still local-only / per-plan in Phase 4 (Phase 2 D-06: enters CI only after Phase 6). No CI changes for the gate itself; per-plan invocation by the planner / executor remains the enforcement point.

### Claude's Discretion

- Exact split point for `sync_providers.dart` / `group_providers.dart` / `avatar_sync_providers.dart` / `home_providers.dart` between DI fold and `state_*.dart` rename — planner determines per provider after reading each file
- Concrete naming of new use cases in Plan 04-01 (e.g., `LookupMerchantUseCase` vs `FindMerchantByVoiceUseCase`) — planner picks per existing application/ naming conventions (verb + noun + UseCase)
- Whether `lib/application/i18n/formatter_service.dart` is a class with methods or a Riverpod-provider-only "facade module" — planner decides based on whether instance state is needed
- Whether to remove `mockito` from pubspec dev_deps in Plan 04-04 or in a follow-up plan; depends on whether any transitive test dependency still references it (most likely yes — clean removal possible)
- The exact allowlist set in `lib/features/*/presentation/import_guard.yaml` — planner derives from compiled list of legitimate imports across the post-refactor codebase
- Order of feature processing within Plan 04-02 — accounting (largest), family_sync (sync-client surface), settings (locale routing), home, profile, analytics in any order; planner picks based on size/dependency
- Whether `lib/application/<feature>/repository_providers.dart` is a new file alongside existing application-layer code or is colocated with existing `application/<feature>/providers.dart` (currently exists for `dual_ledger` only) — planner reconciles per feature

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents (researcher, planner, executor) MUST read these before planning or implementing.**

### Project scope and constraints
- `.planning/PROJECT.md` — Initiative scope, behavior-preservation constraint, key decisions, out-of-scope items
- `.planning/REQUIREMENTS.md` §HIGH-01..HIGH-08 — The 8 locked deliverables this phase must produce; the source of truth for Phase 4 since `issues.json` has no HIGH entries
- `.planning/ROADMAP.md` §"Phase 4: HIGH Fixes" — Goal, dependencies, success criteria
- `.planning/STATE.md` — Project state at Phase 4 entry (Phase 3 complete, import_guard blocking)

### Audit catalogue (Phase 1 output)
- `.planning/audit/issues.json` — Note: zero HIGH entries; Phase 4 closes requirements not findings
- `.planning/audit/ISSUES.md` — Human-readable severity-grouped catalogue
- `.planning/audit/SCHEMA.md` — Finding-record schema (used if Phase 4 discovers and adds new HIGH findings during implementation)
- `.planning/audit/REPO-LOCK-POLICY.md` — Repo lock contract every Phase 4 plan must reference

### Coverage baseline (Phase 2 output, Phase 4's gating prerequisite)
- `.planning/audit/coverage-baseline.txt` / `.json` — Pre-refactor per-file coverage; the "before" image (frozen)
- `.planning/audit/files-needing-tests.txt` / `.json` — The <80% file list; intersect with Phase-4 touched-files for Plan 04-06
- `scripts/coverage_gate.dart` — Per-plan exit gate; invocation: `dart run scripts/coverage_gate.dart --files <touched-files> --threshold 80 --lcov coverage/lcov_clean.info`

### Prior phase contracts (locked, Phase 4 must respect)
- `.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md` — Specifically:
  - **D-04 (staged enablement)** — `import_guard` is already blocking at Phase 4 entry
  - **D-06/D-07 (stable IDs)** — close findings, do not re-issue
  - **D-08 (split/merge convention)** — bookkeeping for findings that change
- `.planning/phases/02-coverage-baseline/02-CONTEXT.md` — Specifically:
  - **D-05 (very_good_coverage blocking)** — global ≥80% gate is blocking; Phase 4 must not regress global coverage
  - **D-07 (repo lock)** — operationally active throughout Phase 4
  - **D-08 (frozen baseline)** — files-needing-tests.txt is immutable mid-initiative; Phase 4 does NOT regenerate it
  - **D-09 (touched-files gating contract)** — every Phase 4 plan declares touched-files; gate runs against that list
- `.planning/phases/03-critical-fixes/03-CONTEXT.md` — Specifically:
  - **D-01/D-02 (per-subdir import_guard.yaml + arch test)** — pattern Phase 4 D-03 mirrors for `presentation/`
  - **D-03 (`test/architecture/` directory)** — Phase 4 extends with `presentation_layer_rules_test.dart` and `provider_graph_hygiene_test.dart`
  - **D-08 (constructor-injection + hand-written fakes)** — pattern Phase 4 D-08/D-10 generalizes to all 14 fixtures via Mocktail
  - **D-15 (every-file-touched ≥80%)** — strict interpretation continues into Phase 4
  - **D-17 (import_guard blocking flip)** — already in effect; Phase 4 yaml additions never standalone
  - **D-12 (deferred CLAUDE.md update)** — Phase 4's `state_*.dart` convention doc and FormatterService convention doc deferred to Phase 7 with Phase 3's view-model doc

### Codebase ground-truth
- `.planning/codebase/CONCERNS.md` — Specifically:
  - "Deprecated services still wired" / "ResolveLedgerTypeService retained alongside CategoryService" — HIGH-03 scope
  - "Hardcoded UI strings" — NOT Phase 4 scope (Phase 5 MED-03)
  - "appDatabaseProvider throws by default" — Phase 3 closed; Phase 4 verifies HIGH-06 globally
  - `recoverFromSeed()` key-overwrite bug — explicitly out of Phase 4 scope (security architecture, FUTURE-ARCH-04)
- `.planning/codebase/STRUCTURE.md` — 5-layer Clean Architecture file layout; Phase 4 must preserve and tighten enforcement on the presentation/infrastructure boundary
- `.planning/codebase/CONVENTIONS.md` — Riverpod `@riverpod` code-gen convention; Phase 4 D-07 architecture test parses generated provider list
- `.planning/codebase/TESTING.md` — 14 committed `*.mocks.dart` files (Phase 4 territory now); `AppDatabase.forTesting()` in-memory pattern

### Project-wide rules
- `CLAUDE.md` §"Riverpod Provider Rules" — "ONE `repository_providers.dart` per feature"; "NEVER duplicate repository provider definitions"; "NEVER throw `UnimplementedError` in providers" — HIGH-04, HIGH-06 enforcement
- `CLAUDE.md` §"Dependency Flow" — "Outer layers depend on inner, never reverse" — HIGH-02 enforcement
- `CLAUDE.md` §"Thin Feature Rule" — "Features NEVER contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/`" — Phase 4 D-04 application-layer hoisting respects this
- `CLAUDE.md` §"Common Pitfalls" #2, #10 — layer dependencies, no duplicate repository provider definitions
- `.claude/rules/testing.md` — ≥80% coverage as project rule; Phase 4 D-17 enforces strictly
- `.claude/rules/arch.md` — Per-phase doc updates DEFERRED to Phase 7

### Files Phase 4 directly modifies (initial inventory)

#### Plan 04-01 (Application-layer routing scaffolding)
- `lib/application/<feature>/repository_providers.dart` (NEW per affected feature: accounting, family_sync, analytics, profile, settings, dual_ledger, home)
- `lib/application/family_sync/<verb>_use_case.dart` (NEW use cases wrapping sync clients)
- `lib/application/ml/lookup_merchant_use_case.dart` (NEW)
- `lib/application/voice/start_speech_recognition_use_case.dart` (NEW)
- `lib/application/i18n/formatter_service.dart` (NEW injectable wrapper)
- `lib/application/dual_ledger/...` use cases for any direct CategoryService.* calls in screens

#### Plan 04-02 (Presentation refactor + import_guard + arch test)
- All 33 files in `lib/features/*/presentation/` currently importing `infrastructure/` (see scout output for full list)
- 10+ provider files in `lib/features/*/presentation/providers/` per D-06 rename mapping
- `lib/features/<f>/presentation/import_guard.yaml` (NEW per feature)
- `test/architecture/presentation_layer_rules_test.dart` (NEW)

#### Plan 04-03 (ResolveLedgerTypeService deletion)
- DELETE `lib/application/dual_ledger/resolve_ledger_type_service.dart`
- EDIT `lib/features/accounting/presentation/providers/use_case_providers.dart` (remove resolveLedgerTypeService entry); regenerate `.g.dart`
- DELETE `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart`
- DELETE `test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart`

#### Plan 04-04 (Mocktail big-bang)
- DELETE all `*.mocks.dart` (14 files; 13 after RLS-test mock removal by 04-03)
- EDIT corresponding `_test.dart` files to inline `class _Mock<X> extends Mock implements X` / `class _Fake<X> extends Fake implements X`
- EDIT `pubspec.yaml` — remove `mockito` from `dev_dependencies` if no transitive consumer

#### Plan 04-05 (Architecture test)
- `test/architecture/provider_graph_hygiene_test.dart` (NEW)

#### Plan 04-06 (Characterization tests)
- N test files in `test/<source-relative-path>/` for each entry in `Phase-4 touched-files ∩ files-needing-tests.txt`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/application/dual_ledger/category_service.dart` (lib/application/accounting/category_service.dart) — `resolveLedgerType` already lives here; Plan 04-03 deletion benefits from this
- `lib/application/family_sync/` — 22 use case files; pattern Plan 04-01 mirrors for sync-client wrappers
- `lib/application/dual_ledger/providers.dart` (`@Riverpod(keepAlive: true) dualLedgerView`) — example of application-layer provider with keepAlive (HIGH-05 reference)
- `lib/infrastructure/i18n/formatters/date_formatter.dart`, `number_formatter.dart` — kept as static implementation under `infrastructure/`; Plan 04-01 wraps in `application/i18n/formatter_service.dart` injectable
- `lib/infrastructure/i18n/models/locale_settings.dart` — model that needs an application-layer wrapper for HIGH-02 compliance
- `scripts/coverage_gate.dart` (Phase 2) — per-plan exit gate, no changes
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — example of correct call pattern (uses `categoryServiceProvider`); template for Plan 04-02 conversions
- `test/unit/application/family_sync/shadow_book_service_test.dart` and similar — already use Mocktail-style `class _MockX extends Mock implements X` (Phase 3 pattern); Plan 04-04 generalizes

### Established Patterns
- **Riverpod `@riverpod` code-gen** — All providers across `lib/features/*/`, `lib/application/`, `lib/infrastructure/security/` use this; `provider_graph_hygiene_test.dart` parses these or `.g.dart` companions
- **Freezed sealed classes** — Pattern continues for any new state types in Plan 04-01 use cases
- **Constructor injection for testability** — Established by Phase 3 D-08 / AppInitializer; Plan 04-01 use cases follow same pattern
- **Per-feature `import_guard.yaml`** — Existing at `lib/features/*/domain/`; Phase 4 extends to `lib/features/*/presentation/`
- **Test directory mirrors source** — `test/<source-relative-path>` is project convention; Plan 04-04 fake replacements stay in same test files; Plan 04-06 characterization tests follow the pattern
- **`AppDatabase.forTesting()`** — Used by tests that need an in-memory DB (Phase 3 reusable)
- **Mocktail-style hand-written fakes/mocks** — Phase 3 AppInitializer test established this; Plan 04-04 generalizes the pattern across the repo

### Integration Points
- `.github/workflows/audit.yml` — `import_guard` already blocking; Phase 4 yaml additions tested via existing CI flow; no audit.yml changes needed in Phase 4
- `lib/l10n/` — No new ARB keys in Phase 4 (formatter wrappers are i18n infrastructure but UI string surface unchanged)
- `pubspec.yaml` — Add `mocktail` dev_dep if not present; remove `mockito` if no transitive consumer (Plan 04-04)
- `analysis_options.yaml` — No changes (architecture tests run via `flutter test`, not analyzer)
- `lib/application/<existing>/providers.dart` files (e.g., `lib/application/dual_ledger/providers.dart`) — coexist alongside new `lib/application/<feature>/repository_providers.dart` files; planner reconciles overlap per feature

</code_context>

<specifics>
## Specific Ideas

- **Phase 4 close = `provider_graph_hygiene_test.dart` GREEN.** The arch-test plan (04-05) is the last Phase 4 plan to merge. If anything regresses between the last refactor commit (04-02) and 04-05's lockdown, Phase 4 is not closed. Mirrors Phase 3 D-17's `import_guard` blocking flip — the architecture test serves the same "alarm against future regression" function for the provider graph.
- **`state_*.dart` is a deliberate naming convention, not just a phase 4 suffix.** Future contributors (and Phase 5+ work) MUST follow this convention. CLAUDE.md update for the convention is deferred to Phase 7 documentation sweep — Phase 4 establishes it by example and arch-test enforcement.
- **The `application/<feature>/repository_providers.dart` "naming collision" is by-path, not by-symbol.** Feature side has `lib/features/family_sync/presentation/providers/repository_providers.dart` and application side has `lib/application/family_sync/repository_providers.dart`. Symbol names inside differ (the application side hoists infrastructure-touching providers; the feature side aggregates domain-side DI for screens). Path disambiguation is the rule; planner ensures import paths are explicit.
- **Mocktail migration is the de-facto Phase 4+ test convention.** Once Plan 04-04 lands, every new test in the project uses Mocktail. The pattern (inline `class _MockX extends Mock implements X`) applies to characterization tests in 04-06 too — Plan 04-06 cannot use Mockito mocks (those would be deleted by 04-04 immediately after).
- **Phase 4 architecture-test extension establishes `test/architecture/` as the project's "structural alarm" directory.** Phase 3 created it for Domain rules; Phase 4 adds Presentation rules and provider-graph rules. Phase 5+ will extend with whatever rule falls under that severity tier (e.g., MED-04 ARB-parity could land here if the planner sees fit).
- **HIGH-04 strict interpretation is more aggressive than Phase 3's interpretation of CRIT-04.** Phase 3 closed Domain-layer rule violations under existing files. Phase 4 restructures Presentation provider files (10+ renames + folds). This is acknowledged as larger surface; the wave structure (D-16) absorbs the cost via parallel Wave 1 (independent plans) and serial Wave 2/3 (dependency chain).
- **`lib/application/i18n/formatter_service.dart` should NOT re-implement formatting.** It wraps the existing `infrastructure/i18n/formatters/*.dart` static functions. Implementation stays where it is (correctness preserved); only the public-API surface moves to `application/`. Tests for the service mock the underlying static calls via instance methods.

</specifics>

<deferred>
## Deferred Ideas

- **Bridging note for Phase 5 planner:** `state_*.dart` rename convention introduced by Phase 4 D-05/D-06 affects future MED-04 ARB-parity work IF the architecture test's grep extends to ARB-related providers. Phase 5 planner should re-read this CONTEXT.md §HIGH-04 before planning MED work.
- **Documentation updates for Phase 4 conventions** — Phase 7 territory:
  - `state_*.dart` filename convention for non-DI presentation providers
  - "presentation NEVER imports infrastructure" rule formalization in CLAUDE.md (currently informal in §"Dependency Flow")
  - FormatterService injectable pattern as the canonical i18n consumption path
  - Mocktail-only test convention (replaces any lingering "Mockito acceptable" guidance)
  - `lib/application/<feature>/repository_providers.dart` hoisting pattern documented
- **CLAUDE.md "Common Pitfalls" annotation** — Phase 7 DOCS-02. Several Phase 4 enforcement mechanisms (`import_guard` for presentation, architecture tests for provider graph) directly automate Common Pitfalls #2 and #10. The annotation goes in Phase 7.
- **`test/_fakes/` shared directory** — Phase 4 D-10 deferred this. If Mocktail fake duplication crosses an empirical pain threshold during Phase 4 execution, the planner may revisit; otherwise Phase 7 / Phase 8 decides based on observed pain.
- **CategoryLocaleService rename and ARB-driven static map elimination** — Phase 5 MED-02 + FUTURE-ARCH-01. Phase 4's HIGH-02 routing wraps `CategoryService` calls in use cases; Phase 5 renames the underlying class. The Phase 4 use cases use the post-rename name once Phase 5 lands; sequencing is forward-compatible.
- **Removing `mockito` from `pubspec.yaml`** — Plan 04-04 attempts; if a transitive test dep still requires it, the removal moves to a follow-up plan / Phase 6.
- **Drift unused-column scan** — `audit:drift_unused_column` agent shard exists with empty findings (Phase 1 dry-run). Phase 4 does not invoke; Phase 5/6 territory.
- **Re-evaluating Mocktail vs Mockito CI-generated** — Phase 4 commits to Mocktail; FUTURE-ARCH-02 captures the option to revisit with full migration if Phase 4 chose CI-generation. Since Phase 4 chose Mocktail, FUTURE-ARCH-02 effectively closes; mark for archival in Phase 7.
- **Adding `dart_code_linter` provider hygiene rules** — current architecture tests are the project's authoritative provider-hygiene check; if `dart_code_linter` adds equivalent rules, Phase 7/8 may consider replacing the test with the lint rule. Not now.

</deferred>

---

*Phase: 04-high-fixes*
*Context gathered: 2026-04-26*
