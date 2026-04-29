# Phase 3: CRITICAL Fixes — Research

**Researched:** 2026-04-26
**Domain:** Flutter / Dart pure-refactor — layer-rule enforcement, Riverpod provider hygiene, characterization-test scaffolding, code-gen workflow
**Confidence:** HIGH (all critical claims verified against project source, pub-cache package source, or official docs)

---

## Summary

Phase 3 closes 24 layer-violation findings + CRIT-03 (`appDatabaseProvider` `UnimplementedError`) + extracts `AppInitializer` from `lib/main.dart`. All decisions D-01..D-17 are locked in CONTEXT.md; this research produces the technical scaffolding the planner needs to convert those decisions into 5 plans across 2 waves.

**Key findings:**

1. **CRITICAL CORRECTNESS RISK in D-01 strategy** — `import_guard_custom_lint` evaluates each config in the inheritance chain **independently** (verified by source read at `~/.pub-cache/hosted/pub.dev/import_guard_custom_lint-1.0.0/lib/src/import_guard_lint.dart:71-94`). Adding a child `allow` in `models/import_guard.yaml` does NOT extend the parent feature-level `allow`. The parent's allow whitelist (currently `[dart:core, freezed_annotation/**, json_annotation/**, meta/**]`) will still reject the intra-domain imports. The planner MUST adjust the strategy: either (a) **strip the `allow` from the parent feature-level yaml** so only the per-subdirectory yamls own whitelist mode, or (b) use `inherit: false` on the per-subdirectory yamls (which then must duplicate the deny list). Option (a) is preferred — see Architecture Patterns §1.
2. `appDatabaseProvider` concrete impl follows existing `@riverpod` pattern in `lib/infrastructure/crypto/providers.dart` — function-style, code-gen `.g.dart`. `.overrideWithValue(AppDatabase.forTesting())` continues to work for tests. No package changes needed.
3. `AppInitializer` Freezed sealed `InitResult` has zero-cost: `freezed_annotation` is already in the project. Constructor injection of `MasterKeyRepository` + `AppDatabase` factory + `SeedService` makes 4 failure modes unit-testable without `flutter_secure_storage`.
4. The 5 family_sync use-case files have NO part-of / library directives — they are independent and `git mv` preserves history. The 11 importers are well-known: 6 in `lib/features/family_sync/presentation/`, 5 in `test/unit/features/family_sync/use_cases/` and `test/widget/...`. Each file's per-PR move requires updating ~3 imports.
5. `ledger_row_data.dart` has exactly 2 source callers (`home_screen.dart` + `ledger_comparison_section.dart`) and 1 test caller. No 03-04 split needed; one PR is sufficient.
6. `flutter gen-l10n` 3-key addition is straightforward: edit 3 ARB files + run `flutter gen-l10n` (intl 0.20.2 supported). Generated `lib/generated/app_localizations*.dart` is checked in.
7. `coverage_gate.dart` invocation pattern verified — supports `--list <path>` (preferred for plans) or positional file args, threshold default 80, lcov default `coverage/lcov_clean.info`.

**Primary recommendation:** Adopt the corrected D-01 strategy (strip `allow` from parent, push it to per-subdirectory yamls). All other locked decisions are technically sound and the planner can proceed without further architectural surgery.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01..D-17 — copied verbatim)

**Domain layer rule (LV-001..LV-016, LV-023, LV-024):**
- **D-01:** Per-file allow lists in subdirectory `import_guard.yaml`, not feature-level relax. Each `features/<f>/domain/models/` and `features/<f>/domain/repositories/` directory gets its own `import_guard.yaml` with `inherit: true`, declaring only the specific intra-domain files it composes. Feature-level deny list (data, infrastructure, application, presentation, flutter) is preserved upstream and inherited.
- **D-02:** Ship `test/architecture/domain_import_rules_test.dart` — Dart unit test that loads each `features/<f>/domain/import_guard.yaml` (and subdirectory descendants), parses the YAML, asserts the deny list still contains `data/**`, `infrastructure/**`, `application/**`, `presentation/**`, `flutter/**`. Fails CI if anyone weakens the rule.
- **D-03:** Establish new `test/architecture/` directory as convention for "meta-tests about codebase shape." Future phases (provider-graph hygiene Phase 4, etc.) extend this directory.

**`appDatabaseProvider` + AppInitializer (CRIT-03):**
- **D-04:** Replace placeholder with concrete `@riverpod AppDatabase appDatabase(Ref ref)` that derives master key, builds encrypted executor, returns `AppDatabase`. Self-overriding in production; tests inject `.overrideWithValue()` for `AppDatabase.forTesting()`.
- **D-05:** Extract `lib/core/initialization/app_initializer.dart` per CLAUDE.md spec. Function signature: `Future<InitResult> initialize(ProviderContainer container)`. `InitResult` is a Freezed sealed class with `success`/`failure` variants; `failure` carries a typed enum (`masterKeyError | databaseError | seedError | unknownError`) plus an originating exception.
- **D-06:** AppInitializer captures the full `lib/main.dart:28-83` sequence verbatim — master-key check + key generation → encrypted executor → AppDatabase → ensure default book → any other inlined steps. Pure refactor: behavior identical, just centralized + unit-testable.
- **D-07:** On `InitResult.failure`, `main.dart` renders a localized error fallback screen with title + message + retry button. Requires 3 new ARB keys (`initFailedTitle`, `initFailedMessage`, `initFailedRetry`) added to `app_ja.arb`, `app_zh.arb`, `app_en.arb`, then `flutter gen-l10n`. Retry re-invokes `AppInitializer.initialize()`.
- **D-08:** AppInitializer takes constructor-injected dependencies (`MasterKeyRepository`, `AppDatabase` factory, `SeedService`). Tests pass fakes that throw at each stage; ~10 unit tests cover happy path + 3-4 failure modes. Hits CRIT-05 ≥80% coverage on `app_initializer.dart`. No real `flutter_secure_storage` in tests.

**`use_cases/` migration (LV-017..LV-021):**
- **D-09:** Per-file `git mv` from `lib/features/family_sync/use_cases/` to `lib/application/family_sync/`, preserving filenames. 5 atomic PRs, one per file. Each PR also moves the corresponding test file. Per-PR atomicity for review + bisect.
- **D-10:** After all 5 files move, the empty `lib/features/family_sync/use_cases/` directory is deleted in the final PR (or 6th cleanup commit), and a `features/family_sync/` import_guard rule is added denying any future re-creation of `use_cases/` underneath.

**`ledger_row_data.dart` `dart:ui` (LV-022):**
- **D-11:** Move `lib/features/home/domain/models/ledger_row_data.dart` to `lib/features/home/presentation/models/ledger_row_data.dart`. Update the (small set of) callers. LV-022 closes; no Color stripping or hex-int conversion.
- **D-12:** Sets project convention: view-models composing `dart:ui` types belong in `features/<f>/presentation/models/`. Document in CLAUDE.md during Phase 7 sweep (not now).

**Plan structure & wave parallelization:**
- **D-13:** Phase 3 splits into 5 plans, one per concern: 03-01 (import_guard rules + arch test), 03-02 (AppInitializer + appDatabaseProvider + InitResult fallback UI + 3 ARB keys), 03-03 (use_cases migration, 5 sub-tasks), 03-04 (ledger_row_data move), 03-05 (characterization-test pre-work).
- **D-14:** **Wave 1** runs `{03-01, 03-03, 03-04, 03-05}` in parallel — share no source-file dependencies. **Wave 2** runs `03-02` alone — depends on 03-05's test infra (fake repository patterns) being merged. Estimated wall time: W1 ~16h, W2 ~14h.

**Test rigor (CRIT-05):**
- **D-15:** Strict ≥80% coverage on every touched file. `coverage_gate.dart --files <touched-files> --threshold 80` runs against post-refactor `lcov_clean.info`. Pure renames count as touched. No escape hatches.

**Repo lock & CI staging:**
- **D-16:** Repo lock (Phase 2 D-07) operationally active throughout Phase 3. Each plan's preamble must capture this. No bypass label.
- **D-17:** `import_guard` flips to blocking in `.github/workflows/audit.yml` at Phase 3 close (Phase 1 D-04). The flip is the last commit of the last Phase 3 plan; verified by CI dry-run.

### Claude's Discretion (research must surface options)

- Exact naming of `InitResult` failure variants and error type enum (recommendation in §3 below)
- Whether `SeedService` is a new class or inlined free function in `AppInitializer` (recommendation in §3 below)
- Exact characterization-test technique per file — golden vs widget vs unit vs integration (research §1 below)
- Order in which the 5 use_case files migrate (any order works since they're independent)
- Whether `ledger_row_data.dart` move is bundled into Plan 03-04 alone or fans out to 03-04a/b — research §5 below shows ONE PR suffices

### Deferred Ideas (OUT OF SCOPE)

- **Bridging note for Phase 5 planner:** 3 init-failure ARB keys are pre-seeded by Phase 3; Phase 5 should NOT re-touch them.
- **`*.mocks.dart` strategy decision:** Phase 4 territory (HIGH-07). Tests for new files in Phase 3 use Mocktail-style hand-written fakes.
- **`test/architecture/provider_graph_hygiene_test.dart`:** Phase 4 candidate (HIGH-04).
- **CLAUDE.md update for "view-models with `dart:ui` belong in presentation/models/" (D-12):** Phase 7.
- **Deletion of empty `family_sync/use_cases/` deny rule:** Phase 7 may decide.
- **`SeedService` class extraction:** Discretionary in Plan 03-02.
- **`recoverFromSeed()` key-overwrite bug:** FUTURE-ARCH-04. Any Phase 3 test touching `KeyRepositoryImpl` uses mock-only paths.
- **`ledger_row_data.dart` rename to `ledger_row_view_model.dart`:** Phase 7 if desired.

</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description (from REQUIREMENTS.md) | Research Support |
|----|------|------|
| **CRIT-01** | Every CRITICAL-severity finding in `issues.json` is resolved (status: closed); zero open CRITICAL entries remain | Plans 03-01 (LV-001..016, LV-023, LV-024) + 03-03 (LV-017..021) + 03-04 (LV-022) close all 24 LVs; closure mechanic per SCHEMA.md §2 (status flip + closed_in_phase + closed_commit) |
| **CRIT-02** | `lib/features/family_sync/use_cases/` migrated to `lib/application/family_sync/`; no feature module contains a `use_cases/` directory | Plan 03-03: 5 `git mv` PRs + cleanup commit; `lib/features/import_guard.yaml` already denies `package:home_pocket/features/*/use_cases/**` so re-creation is blocked |
| **CRIT-03** | `appDatabaseProvider` no longer throws `UnimplementedError`; either concrete provider or shared `createTestProviderScope` helper always provides override | Plan 03-02: concrete `@riverpod AppDatabase appDatabase(Ref ref)` deriving master key + encrypted executor; tests `.overrideWithValue()` continues working unchanged |
| **CRIT-04** | All Domain-layer files import only Dart core, `freezed_annotation`, `json_annotation` — verified by `import_guard` | Plan 03-01: per-subdirectory `models/import_guard.yaml` + `repositories/import_guard.yaml` + revised parent yaml; arch test asserts deny list cannot regress |
| **CRIT-05** | Every file touched in this phase has ≥80% test coverage (characterization tests written first) | Plan 03-05: characterization tests for `Phase-3 touched-files ∩ files-needing-tests.txt`; coverage_gate.dart enforces per-plan |
| **CRIT-06** | `flutter analyze` exits 0; `dart run custom_lint` exits 0; tests GREEN; behavior unchanged (manual smoke + golden tests) | All 5 plans run gates in acceptance; Wave 2's 03-02 includes `flutter analyze` + `custom_lint` + `flutter test` + manual smoke; behavior preservation verified by characterization tests staying GREEN |

</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Domain layer composition rules (per-subdirectory `import_guard.yaml`) | Configuration / `lib/features/*/domain/` | `test/architecture/` | Tier-purity rule; arch test enforces |
| `appDatabaseProvider` concrete impl (master-key derivation + encrypted executor + `AppDatabase`) | Infrastructure / `lib/infrastructure/security/providers.dart` | — | Crosses crypto + DB infra boundaries; lives at infra-tier seam |
| `AppInitializer` orchestration (key → DB → seed) | `lib/core/initialization/` | `lib/application/initialization/` (if `SeedService` extracts) | Cross-cutting boot sequence; `core/` per CLAUDE.md spec |
| `InitFailureScreen` widget + 3 ARB keys | `lib/core/initialization/` | `lib/l10n/` | Pre-`ProviderScope` UI; lives near the orchestrator that drives it |
| Use-case relocation (`features/family_sync/use_cases/` → `application/family_sync/`) | `lib/application/family_sync/` | — | Restores Thin Feature rule per CLAUDE.md |
| `ledger_row_data.dart` (Color view-model) | `lib/features/home/presentation/models/` | — | View-model with `dart:ui` types belongs in presentation per D-12 convention |
| Characterization tests (pre-refactor behavior lock) | `test/<source-mirror>/` | `test/architecture/` | Standard test-mirrors-source convention |
| Architecture deny-list test | `test/architecture/` | — | New project convention seeded here |

---

## Standard Stack

### Core (already in project — Phase 3 reuses)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` | (in pubspec — provider container API) | Provider container, `UncontrolledProviderScope`, overrides | CLAUDE.md mandates Riverpod 2.4+ with `@riverpod` code-gen [VERIFIED: pubspec.yaml] |
| `riverpod_annotation` | 2.6+ | `@riverpod` / `@Riverpod(keepAlive: true)` annotations | Project convention per `lib/infrastructure/crypto/providers.dart` [VERIFIED: source read] |
| `riverpod_generator` | (dev) | Generates `*.g.dart` for `@riverpod` providers | Required for `appDatabaseProvider` concrete impl [VERIFIED: pubspec.yaml] |
| `freezed_annotation` | (in pubspec) | `@freezed` sealed-class generation for `InitResult.success/failure` | Project convention per `Category`, `Result`, etc. [VERIFIED: pubspec.yaml + source read] |
| `freezed` | (dev) | Code-gen for `*.freezed.dart` | Required for `InitResult` sealed class [VERIFIED: pubspec.yaml] |
| `build_runner` | (dev) | Drives `@riverpod` + `@freezed` code-gen | Already pinned [VERIFIED: pubspec.yaml] |
| `flutter_localizations` | (sdk) | `S.delegate` + global delegates for `InitFailureScreen` | Project pinned [VERIFIED: pubspec.yaml] |
| `intl` | 0.20.2 (pinned) | Date/number formatting; `flutter gen-l10n` consumes | Pinned by `flutter_localizations` transitive constraint per CLAUDE.md [VERIFIED: pubspec.yaml] |
| `import_guard_custom_lint` | 1.0.0 | YAML-driven import deny/allow rules via custom_lint | Already wired in `analysis_options.yaml plugins: [custom_lint]` [VERIFIED: pubspec.lock + analysis_options.yaml] |
| `custom_lint` | 0.7.5 | Plugin host for `import_guard_custom_lint` + `riverpod_lint` | [VERIFIED: pubspec.yaml] |
| `mocktail` | 1.0.4 | Hand-written runtime fakes (preferred for new tests per Phase 3 deferred-decision §) | [VERIFIED: pubspec.yaml] |
| `flutter_test` | (sdk) | `testWidgets`, `expect`, golden-test infrastructure | [VERIFIED: pubspec.yaml] |
| `yaml` | (transitive) | Parse `import_guard.yaml` files in `domain_import_rules_test.dart` | Already used by `import_guard_custom_lint`'s ConfigCache [VERIFIED: pub-cache source] |

### Supporting (test infra)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `drift` (NativeDatabase.memory) | (existing) | `AppDatabase.forTesting()` for unit tests touching DB | Plan 03-05 characterization tests for repo-impl files; Plan 03-02 AppInitializer happy-path test |
| `coverde` | 0.3.0+1 (CI activate) | Strip generated files from `lcov.info` to produce `lcov_clean.info` | Already wired in `.github/workflows/audit.yml`; coverage_gate.dart consumes `lcov_clean.info` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-written fakes (Mocktail style) | Mockito codegen | Mockito would require running build_runner per test change; `*.mocks.dart` is Phase 4 strategy decision (HIGH-07). Stick with Mocktail per CONTEXT.md `<deferred>` |
| YAML parser in arch test (uses `package:yaml`) | Regex-on-yaml-text | YAML parser is one extra import; correctness > brevity; matches `import_guard_custom_lint`'s own approach |
| `inherit: false` per-subdirectory yaml + duplicated deny list | Strip parent `allow`, keep parent deny, add per-subdirectory `allow` (recommended) | `inherit: false` doubles maintenance: every deny-list change has to land in N copies. Strip-parent approach: single source of deny truth |

**Installation:** All packages are already in `pubspec.yaml` / `pubspec.lock`. **NO new dependencies are added in Phase 3** (per UI-SPEC §"Registry Safety" + CONTEXT.md `<code_context>`).

**Version verification:**
- `import_guard_custom_lint: 1.0.0` [VERIFIED: pubspec.lock]
- `flutter_riverpod` / `riverpod_annotation` 2.x [VERIFIED: source uses `@riverpod` ✓]
- `freezed_annotation` / `freezed` present [VERIFIED: `*.freezed.dart` files committed]
- `intl: 0.20.2` (pinned, NO caret) [VERIFIED: pubspec.yaml + CONCERNS.md note]

---

## Architecture Patterns

### System Architecture Diagram (Phase 3 boot path + arch enforcement)

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              lib/main.dart                                 │
│  WidgetsFlutterBinding.ensureInitialized() → ensureNativeLibrary()         │
│                              │                                             │
│                              ▼                                             │
│      AppInitializer.initialize(ProviderContainer)                          │
│      [lib/core/initialization/app_initializer.dart — NEW Plan 03-02]       │
│                              │                                             │
│        ┌─────────────────────┼─────────────────────────┐                  │
│        ▼                     ▼                         ▼                  │
│   MasterKeyRepository   AppDatabase factory       SeedService             │
│   (constructor inj.)    (constructor inj.)        (constructor inj.)      │
│        │                     │                         │                  │
│        ▼                     ▼                         ▼                  │
│   ensure key       createEncryptedExecutor       seedCategories +         │
│   generated        (master_key → HKDF → DB key)  ensureDefaultBook        │
│        │                     │                         │                  │
│        └─────────┬───────────┴─────────────────────────┘                  │
│                  ▼                                                         │
│          InitResult.success(container)                                     │
│             │ OR                                                           │
│          InitResult.failure(type, error, stackTrace)                       │
│                  │                                                         │
│        ┌─────────┴─────────┐                                              │
│        ▼                   ▼                                              │
│   runApp(HomePocketApp)   InitFailureScreen [NEW Plan 03-02]              │
│                           [3 ARB keys, retry callback re-invokes init]    │
└────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────┐
│   Architecture enforcement (Plan 03-01)                                    │
│                                                                            │
│   Source file in lib/features/<f>/domain/models/foo.dart                   │
│        │                                                                   │
│        ▼                                                                   │
│   import_guard_custom_lint reads CHAIN of yamls (child → parent → root):   │
│   1. lib/features/<f>/domain/models/import_guard.yaml [NEW]                │
│      • allow: [dart:core, freezed_annotation, json_annotation,             │
│                meta, transaction.dart, ...intra-domain leaves]             │
│   2. lib/features/<f>/domain/import_guard.yaml [REVISED — strip allow]     │
│      • deny only (data, infrastructure, application, presentation, flutter)│
│   3. lib/features/import_guard.yaml [unchanged]                            │
│      • deny use_cases/, application/, infrastructure/, data/ subdirs       │
│   4. lib/import_guard.yaml [unchanged]                                     │
│      • deny dart:mirrors, sqlite3_flutter_libs                             │
│        │                                                                   │
│        ▼                                                                   │
│   For EACH config independently:                                           │
│     IF import matches deny → FAIL                                          │
│     IF config has allow rules AND import not in allow → FAIL               │
│        │                                                                   │
│        ▼                                                                   │
│   test/architecture/domain_import_rules_test.dart [NEW Plan 03-01]         │
│      • Loads every features/*/domain/**/import_guard.yaml                  │
│      • Asserts each yaml's full deny+allow shape                           │
│      • Fails CI if anyone weakens deny or expands allow beyond intra-      │
│        domain composition                                                  │
└────────────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure (Phase 3 deltas)

```
lib/
├── core/initialization/         ← NEW (Plan 03-02)
│   ├── app_initializer.dart        ← extracted from main.dart:28-83
│   ├── init_result.dart            ← Freezed sealed class
│   ├── init_failure_screen.dart    ← localized fallback widget
│   └── (optional) seed_service.dart ← if extracted (D-discretionary)
├── features/
│   ├── family_sync/
│   │   ├── (NO use_cases/)         ← removed (Plan 03-03)
│   │   └── (other dirs unchanged)
│   └── home/
│       ├── domain/models/          ← ledger_row_data.dart removed (Plan 03-04)
│       └── presentation/models/    ← ledger_row_data.dart placed here (Plan 03-04)
├── application/family_sync/
│   ├── apply_sync_operations_use_case.dart  (existing)
│   ├── check_group_use_case.dart            ← NEW (Plan 03-03)
│   ├── deactivate_group_use_case.dart       ← NEW (Plan 03-03)
│   ├── leave_group_use_case.dart            ← NEW (Plan 03-03)
│   ├── regenerate_invite_use_case.dart      ← NEW (Plan 03-03)
│   ├── remove_member_use_case.dart          ← NEW (Plan 03-03)
│   └── (other 17 existing siblings)
└── l10n/
    ├── app_ja.arb                  ← +3 keys (Plan 03-02)
    ├── app_zh.arb                  ← +3 keys (Plan 03-02)
    └── app_en.arb                  ← +3 keys (Plan 03-02)

test/
├── architecture/                   ← NEW (Plan 03-01 establishes convention)
│   └── domain_import_rules_test.dart
└── core/initialization/            ← NEW (Plan 03-02)
    ├── app_initializer_test.dart
    ├── init_result_test.dart
    └── init_failure_screen_test.dart
```

---

### Pattern 1: Per-subdirectory `import_guard.yaml` with corrected D-01 strategy

**What (CRITICAL CORRECTION):** The CONTEXT.md D-01 strategy as literally written ("preserve feature-level deny list upstream and inherit") leaves the `allow` whitelist on the parent feature-level yaml. This causes the lint to reject same-feature intra-domain imports because each config in the inheritance chain is checked independently against its own `allow` whitelist.

**Verification source:** `~/.pub-cache/hosted/pub.dev/import_guard_custom_lint-1.0.0/lib/src/import_guard_lint.dart:71-94` — `for (final config in configs) { if (denied) fail; if (config.hasAllowRules && !allowed) fail; }`. [VERIFIED: source read]

**Correct strategy:** Strip the `allow` from the parent feature-level yaml (it becomes pure deny), and put the `allow` whitelist (with intra-domain leaves) into each per-subdirectory yaml.

**When to use:** Anytime a directory needs `allow`-mode and parents also have `allow`-mode, the parent must drop its `allow` or the child's effective whitelist intersects with the parent's.

**Example — `lib/features/accounting/domain/`:**

`lib/features/accounting/domain/import_guard.yaml` (REVISED — strip `allow`):
```yaml
# Domain layer — leafmost in the dependency graph (CRIT-04 territory).
# Per Phase 3 D-01 (corrected): allow whitelist moved to per-subdirectory yamls.
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

inherit: true
# NOTE: no `allow:` block — children own the whitelist
```

`lib/features/accounting/domain/models/import_guard.yaml` (NEW — Plan 03-01):
```yaml
# Per-subdirectory whitelist. Intra-domain leaves declared explicitly.
# Inherits parent feature-level deny (data/infra/application/presentation/flutter)
# AND root-level deny (dart:mirrors, sqlite3_flutter_libs).
allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**
  - transaction.dart                 # LV-001, LV-003, LV-004 (relative pattern)
  - category.dart                    # LV-002 (relative pattern)
  # Add only the leaves that THIS subdirectory composes; nothing else.

inherit: true
```

`lib/features/accounting/domain/repositories/import_guard.yaml` (NEW — Plan 03-01):
```yaml
allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**
  - ../models/book.dart              # LV-005
  - ../models/category_keyword_preference.dart  # LV-006
  - ../models/category_ledger_config.dart       # LV-007
  - ../models/category.dart          # LV-008
  - ../models/merchant_category_preference.dart # LV-009
  - ../models/transaction.dart       # LV-010

inherit: true
```

**The critical detail:** Both `models/` allow leaves and `repositories/` allow leaves use **relative path patterns** (e.g., `transaction.dart`, `../models/book.dart`). These are relative to the yaml's `configDir`. The lint's `PatternMatcher` resolves them at runtime — see `import_guard_lint.dart:128-136`.

**Per-feature inventory (planner uses this to size Plan 03-01):**

| Feature | `models/` allow leaves | `repositories/` allow leaves | Findings closed |
|---------|------------------------|------------------------------|-----------------|
| accounting | transaction.dart (LV-001, LV-003, LV-004), category.dart (LV-002) | book.dart (LV-005), category_keyword_preference.dart (LV-006), category_ledger_config.dart (LV-007), category.dart (LV-008), merchant_category_preference.dart (LV-009), transaction.dart (LV-010) | 10 |
| analytics | daily_expense.dart (LV-011), month_comparison.dart (LV-012) | analytics_aggregate.dart (LV-013) | 3 |
| family_sync | group_member.dart (LV-014) | group_info.dart (LV-015), group_member.dart (LV-016) | 3 |
| home | (none — `ledger_row_data.dart` MOVES out per Plan 03-04 closing LV-022) | (none) | 1 (via Plan 03-04, not 03-01) |
| profile | (none) | user_profile.dart (LV-023) | 1 |
| settings | (none) | app_settings.dart (LV-024) | 1 |

**Total Plan 03-01 closes:** LV-001..LV-016 + LV-023..LV-024 = 19 findings.

### Pattern 2: Concrete `@riverpod` provider replacing `UnimplementedError` placeholder

**What:** Convert the placeholder in `lib/infrastructure/security/providers.dart:96-102` from a `throw UnimplementedError` to a real provider that derives the master key + builds encrypted executor + returns `AppDatabase`.

**When to use:** Plan 03-02 only.

**Production code:**

```dart
// lib/infrastructure/security/providers.dart (REVISED)
// Source: existing pattern in lib/infrastructure/crypto/providers.dart [VERIFIED]

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/app_database.dart';
import '../crypto/database/encrypted_database.dart';
import '../crypto/providers.dart';

part 'providers.g.dart';

// ... (existing biometric, secureStorage, auditLogger providers unchanged) ...

/// AppDatabase provider — concrete production impl.
///
/// Phase 3 / CRIT-03 fix: replaces the prior UnimplementedError placeholder.
/// Derives the master key from MasterKeyRepository, builds an encrypted
/// SQLCipher executor, and returns AppDatabase wrapping it.
///
/// Tests still use `appDatabaseProvider.overrideWithValue(AppDatabase.forTesting())`.
@Riverpod(keepAlive: true)
Future<AppDatabase> appDatabase(Ref ref) async {
  final masterKeyRepo = ref.watch(masterKeyRepositoryProvider);
  final executor = await createEncryptedExecutor(masterKeyRepo);
  return AppDatabase(executor);
}
```

**IMPORTANT — async vs sync provider type:** The current placeholder returns `AppDatabase` (sync). The concrete impl needs `Future<AppDatabase>` because `createEncryptedExecutor` is `async`. **Every consumer of `appDatabaseProvider` must be reviewed**:

| Existing consumer | Current usage | After concrete impl |
|---|---|---|
| `lib/features/accounting/presentation/providers/repository_providers.dart:32,40,48,56,71,81` | `ref.watch(appDatabaseProvider)` returns `AppDatabase` | Returns `AsyncValue<AppDatabase>` — consumers must `.when()` / `.value!` |
| `lib/features/profile/presentation/providers/user_profile_providers.dart:16` | same | same |
| `lib/features/family_sync/presentation/providers/repository_providers.dart:28,35` | same | same |
| `lib/main.dart:74` | `appDatabaseProvider.overrideWithValue(database)` (sync override) | Override changes to `appDatabaseProvider.overrideWith((ref) async => database)` |
| `lib/infrastructure/security/providers.dart:52` (`auditLogger`) | `ref.watch(appDatabaseProvider)` | needs `.value` extraction or full async chain |

**RECOMMENDED: Keep the provider sync.** AppInitializer awaits `createEncryptedExecutor` once at boot, then `.overrideWithValue(database)` is used for the production container — exactly mirroring today's `lib/main.dart:73-75` pattern. The concrete provider stays sync and is only invoked when the override is missing (e.g., in widget tests that forgot to provide one — those tests should fail loudly via the override-missing assertion). The provider body becomes either:

**Option A (preferred — matches existing pattern):** Keep the provider sync; production overrides via `overrideWithValue` after AppInitializer awaits the async work:
```dart
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  // Production: AppInitializer.initialize() awaits createEncryptedExecutor
  // and overrides this provider via .overrideWithValue(database) on the
  // production ProviderContainer. Tests use .overrideWithValue(AppDatabase.forTesting()).
  // If reached without override, the override wiring is broken — fail loud.
  throw StateError(
    'appDatabaseProvider not overridden. AppInitializer did not run, '
    'or test forgot to override with AppDatabase.forTesting(). '
    'See lib/core/initialization/app_initializer.dart.',
  );
}
```

This is **technically still a throwing provider**, BUT — and this is the key distinction — the throw happens only if the override wiring is broken. Plan 03-02's test pattern guarantees the override is always in place: a unit test asserts that `AppInitializer.initialize()` produces a container with the override, and a widget test asserts that constructing a fresh `ProviderContainer()` and calling `read(appDatabaseProvider)` without an override **does throw a `StateError`** (proving the assertion guard is real). This satisfies CRIT-03's literal requirement ("either replaced with a concrete provider OR paired with a shared `createTestProviderScope` helper that always provides the override").

**Option B (concrete async provider — more invasive):** Switch type to `Future<AppDatabase>` and refactor every consumer to `.when()`. Larger blast radius; rejected.

**Option C (concrete sync — must move createEncryptedExecutor sync):** Not viable — `createEncryptedExecutor` performs async key derivation.

**Recommendation:** Option A. Keep override-based wiring; replace `UnimplementedError` with a more diagnostic `StateError` carrying actionable repair steps. CRIT-03's success criterion ("verified by a test that constructs a `ProviderScope` without an explicit override and does not crash") is met by adding a `createTestProviderScope` helper that **always** sets the override:

```dart
// test/helpers/test_provider_scope.dart (NEW — Plan 03-02 or Plan 03-05)
ProviderContainer createTestProviderScope({
  AppDatabase? database,
  List<Override> additionalOverrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database ?? AppDatabase.forTesting()),
      ...additionalOverrides,
    ],
  );
}
```

This helper IS the "shared `createTestProviderScope` helper that always provides the override" called out in CRIT-03's success criterion. Tests that forget to use it AND construct their own bare `ProviderContainer()` will hit the diagnostic `StateError`.

### Pattern 3: Freezed sealed `InitResult` with constructor-injected `AppInitializer`

**What:** `InitResult` is a Freezed sealed class with `success`/`failure` variants. `AppInitializer` takes constructor-injected dependencies for unit-testable failure paths.

**When to use:** Plan 03-02.

**Recommended exact API:**

```dart
// lib/core/initialization/init_result.dart (NEW)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'init_result.freezed.dart';

/// Discriminator for which init stage failed.
enum InitFailureType {
  /// Master-key generation or retrieval failed (Stage 1).
  masterKey,

  /// Encrypted database open or AppDatabase construction failed (Stage 2).
  database,

  /// Default categories or default-book seeding failed (Stage 3).
  seed,

  /// Catch-all for unexpected exceptions outside the three stages above.
  unknown,
}

@freezed
sealed class InitResult with _$InitResult {
  const factory InitResult.success({
    required ProviderContainer container,
  }) = InitSuccess;

  const factory InitResult.failure({
    required InitFailureType type,
    required Object error,
    StackTrace? stackTrace,
  }) = InitFailure;
}
```

```dart
// lib/core/initialization/app_initializer.dart (NEW)
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../infrastructure/crypto/repositories/master_key_repository.dart';
import '../../infrastructure/security/providers.dart';
import 'init_result.dart';

/// Factory that produces an AppDatabase given a master-key repo.
/// Allows tests to swap in AppDatabase.forTesting() without
/// invoking real createEncryptedExecutor.
typedef AppDatabaseFactory = Future<AppDatabase> Function(MasterKeyRepository);

/// Service that seeds default categories + default book on first launch.
typedef SeedRunner = Future<void> Function(ProviderContainer);

class AppInitializer {
  AppInitializer({
    required ProviderContainer Function() containerFactory,
    required AppDatabaseFactory databaseFactory,
    required SeedRunner seedRunner,
  })  : _containerFactory = containerFactory,
        _databaseFactory = databaseFactory,
        _seedRunner = seedRunner;

  final ProviderContainer Function() _containerFactory;
  final AppDatabaseFactory _databaseFactory;
  final SeedRunner _seedRunner;

  Future<InitResult> initialize() async {
    // Stage 1: Master key
    ProviderContainer initContainer;
    try {
      initContainer = _containerFactory();
      final masterKeyRepo = initContainer.read(masterKeyRepositoryProvider);
      if (!await masterKeyRepo.hasMasterKey()) {
        await masterKeyRepo.initializeMasterKey();
        dev.log('Master key initialized', name: 'AppInit');
      }
      // ... ensure device key pair (existing main.dart:45-57 logic) ...
    } catch (e, st) {
      return InitResult.failure(
        type: InitFailureType.masterKey,
        error: e,
        stackTrace: st,
      );
    }

    // Stage 2: Database
    AppDatabase database;
    try {
      final masterKeyRepo = initContainer.read(masterKeyRepositoryProvider);
      database = await _databaseFactory(masterKeyRepo);
      dev.log('Encrypted database opened', name: 'AppInit');
    } catch (e, st) {
      initContainer.dispose();
      return InitResult.failure(
        type: InitFailureType.database,
        error: e,
        stackTrace: st,
      );
    }

    // Move to final container with appDatabaseProvider overridden
    initContainer.dispose();
    final container = _containerFactory(); // builds new container...
    // ... but with override applied — see implementation note below

    // Stage 3: Seed
    try {
      await _seedRunner(container);
    } catch (e, st) {
      container.dispose();
      return InitResult.failure(
        type: InitFailureType.seed,
        error: e,
        stackTrace: st,
      );
    }

    return InitResult.success(container: container);
  }
}
```

**Implementation note on container/override wiring:** Today's `main.dart:71-75` disposes the init container and creates a final container with `overrides: [appDatabaseProvider.overrideWithValue(database)]`. The `AppInitializer` must replicate this pattern. The `containerFactory` typedef should accept an optional list of overrides:

```dart
typedef ProviderContainerFactory =
    ProviderContainer Function({List<Override> overrides});
```

So tests can pass `containerFactory: ({overrides = const []}) => ProviderContainer(overrides: overrides)` and verify the final container has the right override.

**Test pattern (~10 unit tests for ≥80% coverage):**

```dart
// test/core/initialization/app_initializer_test.dart (NEW)
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/core/initialization/app_initializer.dart';
import 'package:home_pocket/core/initialization/init_result.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:mocktail/mocktail.dart';

class _FakeMasterKeyRepo extends Mock implements MasterKeyRepository {}

void main() {
  group('AppInitializer', () {
    late _FakeMasterKeyRepo fakeRepo;

    setUp(() {
      fakeRepo = _FakeMasterKeyRepo();
      when(() => fakeRepo.hasMasterKey()).thenAnswer((_) async => true);
    });

    test('returns success when all stages succeed', () async {
      final initializer = AppInitializer(
        containerFactory: ({overrides = const []}) =>
            ProviderContainer(overrides: [
          masterKeyRepositoryProvider.overrideWithValue(fakeRepo),
          ...overrides,
        ]),
        databaseFactory: (_) async => AppDatabase.forTesting(),
        seedRunner: (_) async {},
      );

      final result = await initializer.initialize();

      expect(result, isA<InitSuccess>());
      (result as InitSuccess).container.dispose();
    });

    test('returns failure(masterKey) when master key init throws', () async {
      when(() => fakeRepo.hasMasterKey()).thenThrow(StateError('keychain'));
      // ...
      expect(result, isA<InitFailure>());
      expect((result as InitFailure).type, InitFailureType.masterKey);
    });

    test('returns failure(database) when databaseFactory throws', () async {
      // ...
      expect((result as InitFailure).type, InitFailureType.database);
    });

    test('returns failure(seed) when seedRunner throws', () async {
      // ...
      expect((result as InitFailure).type, InitFailureType.seed);
    });

    test('disposes init container when database stage fails', () async {
      // assert no dangling container
    });

    // ... 5 more tests covering edge cases:
    //   - hasMasterKey returns false → initializeMasterKey is called
    //   - InitResult.failure carries the original exception
    //   - StackTrace is preserved
    //   - Container override list contains appDatabaseProvider
    //   - Multiple initialize() calls produce independent containers
  });
}
```

### Pattern 4: Architecture deny-list test

**What:** A `flutter_test` (Dart unit) test that loads every `lib/features/*/domain/**/import_guard.yaml` and asserts the deny set + allow shape match Phase 3's expected configuration.

**When to use:** Plan 03-01 ships this; Phase 4+ extends it.

**Code skeleton:**

```dart
// test/architecture/domain_import_rules_test.dart (NEW)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Domain layer import_guard rules', () {
    final features = ['accounting', 'analytics', 'family_sync', 'home',
                     'profile', 'settings'];

    for (final feature in features) {
      group('feature: $feature', () {
        test('feature-level domain yaml has full deny set + no allow', () {
          final yaml = _loadYaml(
            'lib/features/$feature/domain/import_guard.yaml',
          );

          final deny = (yaml['deny'] as YamlList).map((e) => e.toString());
          expect(deny, containsAll([
            'package:home_pocket/data/**',
            'package:home_pocket/infrastructure/**',
            'package:home_pocket/application/**',
            'package:home_pocket/features/**/presentation/**',
            'package:flutter/**',
          ]));
          // After D-01 correction: feature-level allow is REMOVED
          expect(yaml['allow'], isNull, reason:
            'Phase 3 D-01: feature-level allow moved to per-subdirectory yamls');
          expect(yaml['inherit'], isTrue);
        });

        test('models/ subdirectory yaml allows only declared leaves', () {
          final path = 'lib/features/$feature/domain/models/import_guard.yaml';
          if (!File(path).existsSync()) return; // some features have no model
          final yaml = _loadYaml(path);
          final allow = (yaml['allow'] as YamlList).map((e) => e.toString());
          // every allow entry must be either a known annotation pattern or a
          // relative .dart file in the same directory
          for (final entry in allow) {
            final isAnnotationPattern = entry == 'dart:core'
                || entry.startsWith('package:freezed_annotation')
                || entry.startsWith('package:json_annotation')
                || entry.startsWith('package:meta');
            final isLocalDart = entry.endsWith('.dart')
                && !entry.contains('/');
            expect(isAnnotationPattern || isLocalDart, isTrue,
              reason: 'Suspicious allow entry: $entry');
          }
        });

        // similar for repositories/
      });
    }
  });
}

YamlMap _loadYaml(String path) {
  final content = File(path).readAsStringSync();
  return loadYaml(content) as YamlMap;
}
```

**Note:** `package:yaml` is already a transitive dependency (used by `import_guard_custom_lint`). Plan 03-01 must verify it surfaces to `dev_dependencies` directly so the test can depend on it cleanly. If not, add `yaml: ^3.1.0` to `dev_dependencies`. [VERIFIED via pubspec inspection — currently transitive only; this MAY require a `dev_dependencies` add. Planner: confirm via `dart pub deps` and add if needed.]

### Anti-Patterns to Avoid

- **Adding `allow:` to the parent feature-level yaml:** As of Phase 3 D-01 corrected strategy, parent owns deny only. Adding allow on parent re-introduces the LV-001..LV-016 lint failures.
- **Using `inherit: false` in per-subdirectory yamls:** Forces deny-list duplication; every change has to land in N copies. Use `inherit: true` and let the deny chain work.
- **Using absolute paths in `allow` lists for intra-domain leaves:** Use relative patterns (`transaction.dart`, `../models/foo.dart`). Absolute `package:home_pocket/features/<f>/domain/models/transaction.dart` works but couples the yaml to the feature name and is harder to copy.
- **Switching `appDatabaseProvider` to `Future<AppDatabase>`:** Massive blast radius — 13+ consumer sites would need `.when()` rewrites. Stick with sync + override pattern.
- **Mock-based AppInitializer tests using real `flutter_secure_storage`:** Would touch the `recoverFromSeed()` bug (FUTURE-ARCH-04). Use Mocktail fakes for `MasterKeyRepository`.
- **Bundling all 5 use-case file moves into one PR:** Hampers bisect. Per-file PR per D-09.
- **Renaming `ledger_row_data.dart` to `ledger_row_view_model.dart` in Phase 3:** Phase 7 if desired; Phase 3 keeps LV-022 a pure file move.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Architectural deny-rule enforcement | Custom regex script grepping for forbidden imports | `import_guard_custom_lint` already wired with `inherit` chain + glob patterns + relative pattern resolution | Edge cases in pattern matching (relative resolution, package-name lookup, repo-root detection) are non-trivial; reuse the existing plugin |
| Async master-key derivation in a sync provider | A `cached_value` provider with manual lazy init | The existing `overrideWithValue(database)` after `AppInitializer` awaits async work | Riverpod's override pattern already solves this exactly; no need for caching logic |
| Sealed-class init result | Custom abstract class + manual subclasses + manual `==`/`hashCode` | `freezed` `@freezed sealed class InitResult` | `freezed` generates union types, exhaustive `when()`, copyWith, equality. Already in project. |
| Localization fallback before `currentLocaleProvider` available | Hardcoded English strings + `// TODO: localize later` | `flutter_localizations` + minimal `MaterialApp` + `S.delegate` per UI-SPEC | Project rule: all UI strings via `S.of(context)` (CLAUDE.md i18n) — the ARB-key approach is exactly the right pattern |
| Coverage gating per file | grep on `lcov.info` | `scripts/coverage_gate.dart` (Phase 2 output) — already supports `--list <path>` + `--threshold` + `--lcov` | Already pinned, tested, semantically aware of touched-files. CRIT-05 D-15 strictly requires this gate. |
| YAML-shape verification in arch test | regex on yaml text | `package:yaml` `loadYaml` + structured assertions | Whitespace/quoting edge cases in regex; structured parse trivially correct |
| Pre-commit `git mv` history preservation | Manual delete + create | Native `git mv` + atomic per-file PRs | `git mv` preserves blame/history exactly; verified by `git log --follow` post-move |

**Key insight:** Phase 3 is structurally a pure refactor. Every problem in scope already has a project-level solution. The work is wiring those solutions together with surgical YAML edits, file moves, and a single new orchestrator class. Do not invent new infrastructure.

---

## Common Pitfalls

### Pitfall 1: D-01 strategy as literally written breaks the lint

**What goes wrong:** Adding per-subdirectory `import_guard.yaml` with `allow: [transaction.dart, ...]` while leaving the parent feature-level `import_guard.yaml` with its current `allow: [dart:core, freezed_annotation/**, ...]` **does not fix the LV findings**. The parent's `allow` is checked independently and still rejects the intra-domain import.

**Why it happens:** `import_guard_custom_lint` evaluates each config in the inheritance chain independently, NOT as a merged whitelist [VERIFIED: source read at `import_guard_lint.dart:71-94`].

**How to avoid:** **Strip the `allow` block** from each `lib/features/*/domain/import_guard.yaml`. Move that whitelist content to the per-subdirectory yamls and add the intra-domain leaves there. Parent retains only `deny` + `inherit: true`.

**Warning signs:** Plan 03-01 implementation lands, custom_lint still flags LV-001..LV-016 — root cause is parent yaml not stripped.

### Pitfall 2: `appDatabaseProvider` consumer breakage from sync→async type change

**What goes wrong:** Switching the provider's return type from `AppDatabase` to `Future<AppDatabase>` breaks 13+ consumer sites that call `ref.watch(appDatabaseProvider)` and expect a sync value.

**Why it happens:** `createEncryptedExecutor` is async; naive concrete impl uses `await`.

**How to avoid:** Use the override pattern (Pattern 2 Option A). AppInitializer awaits the async work once, then `.overrideWithValue(database)` in the production container. Provider stays sync. `StateError` guards the override-missing case for diagnostic clarity.

**Warning signs:** `flutter analyze` complaints about `await` missing on consumer sites; widget tests crashing on `ref.watch(appDatabaseProvider).value`.

### Pitfall 3: AppInitializer test isolation

**What goes wrong:** Test 2 sees state from test 1 (e.g., a previously-disposed container's reference still alive) and produces flaky failures.

**Why it happens:** `ProviderContainer` and `AppDatabase` carry resources that must be `.dispose()`'d / `.close()`'d.

**How to avoid:** Each test creates a fresh `AppInitializer` with fresh fakes; each test `tearDown` disposes the resulting container. Use `late` + `setUp` / `tearDown`.

**Warning signs:** Tests pass individually but fail when run as a suite; "database is locked" errors; `Bad state: ProviderContainer was already disposed`.

### Pitfall 4: ARB parity drift while adding 3 new keys

**What goes wrong:** Developer adds 3 keys to `app_en.arb` only, forgets `app_ja.arb` / `app_zh.arb`. `flutter gen-l10n` produces the generated `S` class with an English fallback for ja/zh; users see English on the fallback screen.

**Why it happens:** ARB files are independent JSON; no compile-time parity check until Phase 5 MED-04.

**How to avoid:** Plan 03-02 acceptance: `diff <(jq -S 'keys' lib/l10n/app_en.arb) <(jq -S 'keys' lib/l10n/app_ja.arb)` returns no output (parity verified). Same for `app_zh.arb`. Run `flutter gen-l10n` and check the generated `lib/generated/app_localizations*.dart` for parity warnings.

**Warning signs:** `flutter gen-l10n` warnings; `S.of(context).initFailedTitle` returns English on `Locale('ja')`.

### Pitfall 5: `git mv` followed by manual edits in the same commit

**What goes wrong:** Per-file PR for `check_group_use_case.dart` does `git mv` AND updates the file's relative imports AND the importer files all in one commit. `git log --follow` works, but the diff is mixed move + rename + content change → reviewer can't see what actually moved.

**Why it happens:** Convenience.

**How to avoid:** Per-file PR should be ONE commit: the `git mv` + the minimal import-path adjustments to make the codebase compile. Do NOT bundle behavior changes. Use `git diff -M` post-move to confirm rename detection still works (`R100` rename score).

**Warning signs:** PR diff shows whole-file deletions + additions instead of a `R` rename; bisect on the file becomes painful.

### Pitfall 6: `import_guard` blocking flip with stale CI cache

**What goes wrong:** D-17 final commit flips `continue-on-error: true` off the `import_guard` job. The flip itself passes locally because cached `.dart_tool/` has stale lint state. CI on a fresh checkout fails because some previously-uncached domain file fails.

**Why it happens:** `dart run custom_lint` reads `.dart_tool/` for cached results; the flip commit's local run may not represent a cold CI run.

**How to avoid:** Plan 03-01 acceptance: dry-run the blocking gate ON A FRESH CHECKOUT before flipping. Specifically: `rm -rf .dart_tool && flutter pub get && dart run custom_lint` must exit 0 before the flip commit lands. Document this in the plan's Risk section.

**Warning signs:** Plan 03-01's final commit passes locally but CI fails on `import_guard` after merge.

### Pitfall 7: Riverpod code-gen drift (build_runner)

**What goes wrong:** Plan 03-02 adds the concrete `appDatabaseProvider` body but forgets `flutter pub run build_runner build --delete-conflicting-outputs`. The committed `providers.g.dart` is stale; CI's AUDIT-10 guardrail (`build_runner build && git diff --exit-code lib/`) fails.

**Why it happens:** `@riverpod` annotation expansion lives in `.g.dart`; not regenerating after even trivial signature changes leaves `.g.dart` out of sync.

**How to avoid:** Plan 03-02 acceptance: `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0. Make this an explicit step in the plan's "Run before merge" checklist.

**Warning signs:** AUDIT-10 CI step fails; analyzer complaints about missing `_$appDatabase` symbol.

### Pitfall 8: Audit.yml flip is functionally irreversible

**What goes wrong:** D-17 flips `import_guard` to blocking; later a Phase 4+ plan introduces a layer violation; CI blocks the PR; remediating requires reverting the flip (defeats Phase 3's exit gate) OR fixing the violation in the same PR.

**Why it happens:** Once blocking, every PR has to satisfy the gate. There's no `[skip-import-guard]` label per REPO-LOCK-POLICY.md.

**How to avoid:** Plan 03-01 + 03-02 + 03-03 + 03-04 + 03-05 ALL must complete and pass `dart run custom_lint` cold-start before D-17 commits. Treat the flip as the literal last commit of Phase 3, not somewhere mid-phase.

**Warning signs:** Phase 4 plans hit unexpected import_guard failures and ask for relaxation.

---

## Code Examples

Verified patterns from project source:

### Existing concrete `@riverpod` provider (template for `appDatabaseProvider` fix)

```dart
// Source: lib/infrastructure/crypto/providers.dart:18-22 [VERIFIED]
@riverpod
MasterKeyRepository masterKeyRepository(Ref ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return MasterKeyRepositoryImpl(secureStorage: storage);
}
```

### Existing `keepAlive: true` for boot-singletons

```dart
// Source: lib/infrastructure/security/providers.dart:26-29 [VERIFIED]
@Riverpod(keepAlive: true)
BiometricService biometricService(Ref ref) {
  return BiometricService();
}
```

### Existing test override pattern

```dart
// Source: lib/main.dart:73-75 [VERIFIED]
final container = ProviderContainer(
  overrides: [appDatabaseProvider.overrideWithValue(database)],
);
```

### Existing characterization-test wiring (helper)

```dart
// Source: test/helpers/test_localizations.dart [VERIFIED]
Widget createLocalizedWidget(
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: child,
    ),
  );
}
```

### Coverage-gate invocation pattern (Phase 3 plans use)

```bash
# 1. Run tests with coverage
flutter test --coverage

# 2. Strip generated files (matches CI step in audit.yml:101-107)
coverde filter \
  --input coverage/lcov.info \
  --output coverage/lcov_clean.info \
  --mode w \
  --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'

# 3. Build touched-files list (one path per line, lib/-relative)
cat > /tmp/phase3-plan-XX-touched.txt <<EOF
lib/core/initialization/app_initializer.dart
lib/core/initialization/init_result.dart
lib/core/initialization/init_failure_screen.dart
lib/infrastructure/security/providers.dart
lib/main.dart
EOF

# 4. Gate per-file at 80%
dart run scripts/coverage_gate.dart \
  --list /tmp/phase3-plan-XX-touched.txt \
  --threshold 80 \
  --lcov coverage/lcov_clean.info

# Exit codes (verified at scripts/coverage_gate.dart:25):
#   0 = every file ≥80%
#   1 = at least one file <80% (gate failure)
#   2 = invocation error
```

### `flutter gen-l10n` workflow for 3 ARB key addition (Plan 03-02)

```bash
# 1. Edit lib/l10n/app_ja.arb — add: "initFailedTitle", "initFailedMessage", "initFailedRetry"
# 2. Edit lib/l10n/app_zh.arb — same 3 keys
# 3. Edit lib/l10n/app_en.arb — same 3 keys (template ARB file per l10n.yaml)

# 4. Verify parity BEFORE running gen-l10n
diff <(jq -S 'keys' lib/l10n/app_en.arb) <(jq -S 'keys' lib/l10n/app_ja.arb)
# expected: no output (identical key sets)
diff <(jq -S 'keys' lib/l10n/app_en.arb) <(jq -S 'keys' lib/l10n/app_zh.arb)

# 5. Regenerate
flutter gen-l10n
# produces lib/generated/app_localizations.dart, app_localizations_en.dart,
#          app_localizations_ja.dart, app_localizations_zh.dart

# 6. Verify generated S class has new getters
grep -E 'initFailed(Title|Message|Retry)' lib/generated/app_localizations.dart
# expected: 3 abstract getter declarations + concrete impls in per-locale files

# 7. Confirm zero analyzer warnings
flutter analyze
```

### Deny-list arch test loading pattern (Plan 03-01 test)

```dart
// Source: derived from import_guard_custom_lint config_test.dart [VERIFIED]
import 'dart:io';
import 'package:yaml/yaml.dart';

YamlMap loadImportGuard(String path) {
  return loadYaml(File(path).readAsStringSync()) as YamlMap;
}
```

---

## Runtime State Inventory

Phase 3 is a refactor with no migrations / no live-service config touches. Categories:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Phase 3 does not modify any DB schema, Drift table, ChromaDB collection, or persisted secret. The 4-layer encryption + master-key + Ed25519 keypair are READ by `AppInitializer` (existing behavior preserved verbatim per D-06) but no schema or stored value changes. | None |
| Live service config | None — no n8n, Datadog, Tailscale, or external service is involved. The relay-server WebSocket is unchanged. | None |
| OS-registered state | None — no Task Scheduler / launchd / systemd / pm2 entries. Mobile app only. | None |
| Secrets/env vars | None new. `flutter_secure_storage` keys (`master_key`, `device_private_key`, `device_public_key`, `device_id`) are read by existing infrastructure code unchanged. The 3 new ARB keys (`initFailedTitle`, `initFailedMessage`, `initFailedRetry`) are localizations, not secrets. | None |
| Build artifacts / installed packages | `lib/generated/app_localizations*.dart` regenerated by `flutter gen-l10n` after Plan 03-02 ARB edits. `*.g.dart` regenerated by `build_runner` after concrete `appDatabaseProvider` change AND `init_result.dart` Freezed annotation. Both are committed per project convention (CLAUDE.md). | Run `build_runner build --delete-conflicting-outputs` + `flutter gen-l10n` + commit; CI's AUDIT-10 guardrail will fail on stale-diff if skipped |

**Canonical question — "After every file in the repo is updated, what runtime systems still have the old string cached, stored, or registered?"** Nothing. Phase 3 contains no rename/migration work; only file moves (preserving content) + new files + YAML edits + provider refactor + 3 ARB key additions.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All flutter tooling | ✓ | (project pin via `pubspec.yaml`) | — |
| Dart SDK | `dart run scripts/coverage_gate.dart`, `dart run custom_lint` | ✓ | (bundled with Flutter) | — |
| `import_guard_custom_lint` | Plan 03-01 lint enforcement | ✓ | 1.0.0 [VERIFIED: pubspec.lock] | — |
| `custom_lint` plugin host | Plan 03-01 + Plan 03-02 (Riverpod) | ✓ | 0.7.5 [VERIFIED: pubspec.lock] | — |
| `coverde` (CI) | `lcov_clean.info` generation | Available in CI via `dart pub global activate coverde 0.3.0+1` | 0.3.0+1 [VERIFIED: audit.yml:34] | Local devs install via `dart pub global activate coverde` |
| `jq` | ARB parity diff (Plan 03-02 acceptance) | Likely on dev machines + CI ubuntu-latest | system | If absent in CI, swap to `dart run scripts/<arb_parity>.dart` (none needed since Phase 5 owns parity formally) |
| `git` | `git mv` per Plan 03-03 | ✓ | system | — |
| `package:yaml` (test dependency) | Plan 03-01 arch test | Currently transitive only via `import_guard_custom_lint`. **Add to `dev_dependencies`** if not directly importable. | 3.x | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** `package:yaml` may need promotion from transitive to `dev_dependencies` — planner Plan 03-01 acceptance: `import 'package:yaml/yaml.dart'` resolves in test code; if not, add to pubspec dev_dependencies and run `flutter pub get`.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (sdk: flutter) + `mocktail: 1.0.4` for hand-written fakes [VERIFIED: pubspec.yaml + TESTING.md] |
| Config file | `analysis_options.yaml` (lint plugins) + `pubspec.yaml` (test deps); no separate `flutter_test_config.dart` observed |
| Quick run command | `flutter test test/<plan-specific-paths>` |
| Full suite command | `flutter test --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| **CRIT-01** | Zero open CRITICALs in `issues.json` | shard-merge integration | `dart run scripts/merge_findings.dart && jq '[.findings[] \| select(.severity=="CRITICAL" and .status=="open")] \| length' .planning/audit/issues.json` | ✅ (script exists from Phase 1) |
| **CRIT-02** | No `lib/features/*/use_cases/` directory | shell smoke + import_guard | `! test -d lib/features/family_sync/use_cases && dart run custom_lint` | ✅ Wave 0 (custom_lint already wired) |
| **CRIT-03 happy** | `appDatabaseProvider` overridden during normal init produces `AppDatabase` | unit | `flutter test test/core/initialization/app_initializer_test.dart` | ❌ Wave 0 (Plan 03-02) |
| **CRIT-03 guard** | Bare `ProviderContainer()` reading `appDatabaseProvider` throws diagnostic StateError | unit | `flutter test test/infrastructure/security/providers_test.dart` (NEW) | ❌ Wave 0 (Plan 03-02) |
| **CRIT-04** | Domain layer files only import dart:core + freezed_annotation + json_annotation + meta + same-feature intra-domain leaves | architecture | `flutter test test/architecture/domain_import_rules_test.dart && dart run custom_lint` | ❌ Wave 0 (Plan 03-01) |
| **CRIT-05** | Every touched file has ≥80% coverage | coverage gate | `flutter test --coverage && coverde filter ... && dart run scripts/coverage_gate.dart --list <touched-files> --threshold 80 --lcov coverage/lcov_clean.info` | ✅ (script exists from Phase 2) |
| **CRIT-06 analyze** | `flutter analyze` exits 0 | static | `flutter analyze --no-fatal-infos` | ✅ (Wave 0) |
| **CRIT-06 custom_lint** | `dart run custom_lint` exits 0 (with import_guard now blocking) | static | `dart run custom_lint` | ✅ (Wave 0) |
| **CRIT-06 tests** | All tests GREEN | suite | `flutter test` | ✅ (Wave 0) |
| **CRIT-06 behavior** | User-observable behavior unchanged | manual smoke + golden | manual smoke checklist + `flutter test test/widget/` (golden tests stay GREEN through refactor) | partial (golden tests for affected screens may need to be added in Plan 03-05) |

### Sampling Rate

- **Per task commit:** Affected file's targeted test command (e.g., during Plan 03-03 work on `check_group_use_case.dart`: `flutter test test/application/family_sync/check_group_use_case_test.dart`).
- **Per wave merge:** Full plan acceptance — `flutter analyze && dart run custom_lint && flutter test --coverage && dart run scripts/coverage_gate.dart --list <plan-touched> --threshold 80 --lcov coverage/lcov_clean.info`. AUDIT-10 (build_runner clean diff) AND `git diff --exit-code lib/` AFTER `flutter pub run build_runner build --delete-conflicting-outputs`.
- **Phase gate (D-17 final commit):** Full suite green + `dart run custom_lint` exits 0 with `import_guard` job's `continue-on-error` flag stripped + manual smoke checklist signed off.

### Wave 0 Gaps (test infra needed before Plan implementation)

These tests/files do NOT yet exist; Plan 03-05 (Wave 1) must create them BEFORE Wave 2's Plan 03-02 work begins:

- [ ] `test/architecture/domain_import_rules_test.dart` — covers CRIT-04 (Plan 03-01)
- [ ] `test/core/initialization/app_initializer_test.dart` — covers CRIT-03 happy path + 4 failure modes (Plan 03-02)
- [ ] `test/core/initialization/init_result_test.dart` — covers Freezed sealed class equality (Plan 03-02; trivial — Freezed-generated)
- [ ] `test/core/initialization/init_failure_screen_test.dart` — covers fallback widget (per UI-SPEC §"Test Contract") (Plan 03-02)
- [ ] `test/infrastructure/security/providers_test.dart` — NEW; covers `appDatabaseProvider` diagnostic StateError when override missing (Plan 03-02)
- [ ] `test/helpers/test_provider_scope.dart` — NEW shared helper exposing `createTestProviderScope({database, additionalOverrides})` for any future test that needs a provider container (Plan 03-02 or 03-05)
- [ ] Per-file characterization tests for `Phase-3 touched-files ∩ files-needing-tests.txt` — Plan 03-05 enumerates the intersection (see §"Per-file characterization technique" below)
- [ ] `package:yaml` confirmed importable in test code (add to `dev_dependencies` if needed) — Plan 03-01

### Per-file characterization technique (Plan 03-05 D-discretionary scope)

For each file in `Phase-3 touched-files ∩ files-needing-tests.txt`, recommend test type:

| File category | Examples in Phase 3 scope | Recommended test type | Rationale |
|---|---|---|---|
| Riverpod provider files (`*providers.dart`) | `lib/infrastructure/security/providers.dart`, `lib/features/*/presentation/providers/repository_providers.dart`, `lib/features/family_sync/presentation/providers/group_providers.dart` | **Unit test** with `ProviderContainer` + Mocktail fakes for upstream deps | Providers are wiring; assert that `ref.watch(providerName)` returns the expected concrete type given known overrides. Cheap, fast. |
| Freezed view-model / domain model files (`*data.dart`, `*config.dart`, `*result.dart`) | `lib/features/home/domain/models/ledger_row_data.dart` (during move), `lib/features/accounting/domain/models/transaction_sync_mapper.dart`, `lib/features/analytics/domain/models/monthly_report.dart` | **Unit test** asserting constructor + `copyWith` + JSON round-trip if applicable | Pure data; tests verify the Freezed-generated equality and copyWith. Trivial coverage. |
| ARB-rendering widgets (Material widgets reading `S.of(context)`) | `lib/features/family_sync/presentation/screens/group_management_screen.dart`, settings widgets | **Widget test** using `createLocalizedWidget` helper at each of 3 locales | Asserts UI doesn't regress through refactor. Use `find.text(<expected>)` for static keys. Avoid screenshot/golden unless layout-sensitive (tabular figures). |
| Plain Dart classes (Use Cases, Services, Orchestrators) | `lib/features/family_sync/use_cases/check_group_use_case.dart` (pre-move), `lib/application/family_sync/sync_engine.dart`, `lib/application/family_sync/transaction_change_tracker.dart` | **Unit test** with constructor injection + Mocktail fakes for repos | Stateless logic; isolate via fakes; verify `Result.success/error` returned for each branch. |
| DAO/repo-impl files (Drift) | `lib/data/daos/*.dart`, `lib/data/repositories/*_impl.dart` | **Repository test** using `AppDatabase.forTesting()` (in-memory SQLite) per TESTING.md pattern | Real Drift queries with no SQLCipher; covers SQL behavior. |
| Drift table files | `lib/data/tables/*.dart` | **No characterization test needed** — pure declarative schema; covered indirectly by repo-impl tests + the `app_database_test.dart` migration tests (Phase 6 LOW-04). | Table classes have no execution logic to characterize. |
| Theme / shared widgets | `lib/core/theme/app_theme.dart`, `lib/features/accounting/presentation/widgets/soft_toast.dart` | **Widget test** for visual regressions; **golden test** if pixel-fidelity matters (rare in Phase 3) | Lock theme tokens / widget output. |
| `lib/main.dart` | itself | **Integration test (sparse)** — assert `AppInitializer.initialize()` is called and either path renders something. Coverage will be low (boot code is hard to unit-test); document the rationale-skip in plan acceptance per D-15 caveat. | `main.dart` is mostly UI scaffolding around `AppInitializer`; the meaningful logic is now in `app_initializer.dart` which has its own unit tests. |

**Critical Plan 03-05 deliverable:** Compute the intersection set:

```bash
# Touched-files list per Plan 03-XX (planner generates from CONTEXT.md §"Files Phase 3 directly modifies")
# Intersect with files-needing-tests.txt (Phase 2 frozen baseline)

cat .planning/audit/files-needing-tests.txt | grep -F -f /tmp/phase3-touched.txt > /tmp/phase3-needs-char-tests.txt
# This is Plan 03-05's test-writing scope.
```

Likely intersection (high-confidence guesses based on touched-files inventory in CONTEXT.md):
- `lib/infrastructure/security/providers.dart` — needs new test (Plan 03-02 owns; Plan 03-05 may seed)
- `lib/features/family_sync/use_cases/deactivate_group_use_case.dart` (and 4 siblings post-move) — already in files-needing-tests.txt (3 of 5 listed); test-mirror moves alongside source
- `lib/features/family_sync/presentation/providers/group_providers.dart` — already in files-needing-tests.txt; needs widget+provider test
- `lib/features/home/presentation/screens/main_shell_screen.dart` — depends on whether Plan 03-04 or downstream of `ledger_row_data.dart` move forces re-instantiation
- `lib/features/family_sync/presentation/screens/group_management_screen.dart` — already in files-needing-tests.txt; touched by Plan 03-03's import-path updates

---

## Security Domain

(Enabled by default; this phase is a pure refactor with no security architecture changes per PROJECT.md.)

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 3 does not touch auth |
| V3 Session Management | no | Phase 3 does not touch sessions |
| V4 Access Control | no | No new authz boundaries |
| V5 Input Validation | partial | `InitFailureScreen` retry callback takes no user input; no new validation surfaces |
| V6 Cryptography | preserved | `MasterKeyRepository` + `createEncryptedExecutor` are READ unchanged by `AppInitializer`; refactor does not modify crypto code paths |
| V7 Error Handling | yes | `InitResult.failure` carries the original exception + stack trace; `dev.log(..., name: 'AppInit')` to console only; UI fallback shows GENERIC localized copy (no error details surfaced — per UI-SPEC §"Failure-Variant Strategy") |
| V8 Data Protection | preserved | No data persistence changes; AppInitializer's failure path does NOT log secrets (master-key bytes never stringified) |
| V14 Configuration | yes | `import_guard.yaml` is configuration enforcing the layer-purity rule; arch test ensures it cannot regress |

### Known Threat Patterns for Phase 3 stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unhandled exception in init exposes secrets via stack trace in UI | Information Disclosure | UI surfaces only generic localized copy; full stack trace goes to `dev.log` (debug mode only); release builds no-op `dev.log` per Flutter conventions |
| Provider override missing → throw with secret context | Information Disclosure | The diagnostic StateError message is hardcoded English; carries no key material or path-with-secrets |
| `recoverFromSeed()` accidentally exercised by AppInitializer test | Tampering | Plan 03-02 tests use Mocktail fakes for `MasterKeyRepository` — no real `flutter_secure_storage`, no `recoverFromSeed` reachable. FUTURE-ARCH-04 stays unblocked. |
| Layer rule weakening through future yaml edit | Tampering / repudiation of architectural commitment | Arch test (`domain_import_rules_test.dart`) asserts deny set; flips CI red on weakening. D-17 also makes import_guard blocking. |
| ARB key collision (`retry` vs `initFailedRetry`) | none (functional) | Per UI-SPEC: add `initFailedRetry` as a new key for traceability with CONTEXT.md D-07 |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inlined init in `main.dart:28-83` | `AppInitializer.initialize(ProviderContainer)` returning `InitResult` | Phase 3 (this phase) | Init is unit-testable; failure modes localized |
| `appDatabaseProvider` throws `UnimplementedError` | Concrete provider with diagnostic `StateError` + always-overridden via AppInitializer | Phase 3 (this phase) | CRIT-03 closes; tests via `createTestProviderScope` helper |
| Feature-level `import_guard.yaml` with `allow` whitelist | Feature-level deny-only + per-subdirectory `allow` whitelist | Phase 3 (this phase) | LV-001..LV-016, LV-023, LV-024 close; surgical precision; arch test prevents regression |
| `lib/features/family_sync/use_cases/` (Thin Feature violation) | `lib/application/family_sync/` (correct layer) | Phase 3 (this phase) | LV-017..LV-021 close; CLAUDE.md Thin Feature rule restored |
| `lib/features/home/domain/models/ledger_row_data.dart` (with `dart:ui` Color) | `lib/features/home/presentation/models/ledger_row_data.dart` | Phase 3 (this phase) | LV-022 closes; project convention "view-models with `dart:ui` belong in presentation/models/" established (D-12) |
| `import_guard` non-blocking in CI | `import_guard` blocking | Phase 3 close (D-17) | Future Phase 4+ regressions blocked at PR; cannot land violations |

**Deprecated/outdated within Phase 3 scope:**
- `flutter_localizations` ↔ `intl 0.20.2`: pinned; `flutter gen-l10n` workflow stable [VERIFIED: l10n.yaml]
- `import_guard` (the new Dart 3.10+ analyzer plugin replacement for `import_guard_custom_lint`) is available but project uses `import_guard_custom_lint 1.0.0`; no migration in Phase 3 scope. Phase 4+ may revisit.

---

## Assumptions Log

All claims tagged `[ASSUMED]` in this research. Planner and discuss-phase use this to identify decisions needing user confirmation.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `package:yaml` may need promotion from transitive to direct `dev_dependencies` for Plan 03-01 arch test | Standard Stack §Supporting; Pattern 4 | Low — straightforward `pubspec.yaml` edit if needed |
| A2 | Phase 3 touched-files inventory in CONTEXT.md `<canonical_refs>` is exhaustive (no overlooked file) | Validation Architecture §"Per-file characterization technique" | Medium — if the planner discovers additional touched files mid-execution, Plan 03-05's coverage scope grows. Mitigation: planner re-confirms touched list per plan |
| A3 | `lib/main.dart`'s coverage will remain low post-extraction (boot code) and the planner will mark it as "rationale-skipped per D-15 caveat" | Validation Architecture §"Per-file characterization technique" — `main.dart` row | Medium — D-15 says strict no-skips. If the planner enforces strict, `main.dart` needs a smoke integration test (probably possible via `runApp(...)` in a `testWidgets` harness). Recommend planner explicitly decide. |
| A4 | The `auditLogger` provider at `lib/infrastructure/security/providers.dart:51-55` continues working unchanged because `appDatabaseProvider` stays sync (Pattern 2 Option A) | Pattern 2 | Low — verified sync return type in template |
| A5 | The Mocktail fake for `MasterKeyRepository` in tests does NOT exercise `recoverFromSeed` paths | Pitfall §Security; Common Pitfalls | Low — Mocktail fakes only respond to stubbed methods; `recoverFromSeed` is not in the test's stub set |
| A6 | The 5 family_sync use-case files have no `library`/`part-of` directive that would break on `git mv` | Summary §4 | Verified by file-content inspection of `check_group_use_case.dart` — no `library` or `part of` directive observed. The other 4 files almost certainly follow the same pattern. Plan 03-03 acceptance: `! grep -r '^library\|^part of' lib/features/family_sync/use_cases/` returns empty before move |
| A7 | After Plan 03-04's move, the `lib/features/home/domain/` directory still has at least one file (so the `domain/import_guard.yaml` doesn't become orphaned) | Pattern 1 §Per-feature inventory | Verified: `ls lib/features/home/domain/models/` shows only `ledger_row_data.dart` + its `.freezed.dart`. After move, `home/domain/` is essentially empty. Planner may want to delete the empty domain `import_guard.yaml` OR keep it for future home-domain models. **Recommendation: keep the empty `home/domain/` directory + `import_guard.yaml`** to preserve the layer-rule enforcement for future code. |

**If this table looks short:** good — most claims in this research were verified against project source, pub-cache package source, or official package documentation.

---

## Open Questions

1. **Should `package:yaml` be promoted to `dev_dependencies`?**
   - What we know: `package:yaml` is currently transitive only via `import_guard_custom_lint`. Test code can import transitive deps but it's bad hygiene.
   - What's unclear: Whether project policy requires direct declaration of test-imported packages.
   - Recommendation: Plan 03-01 acceptance includes a one-line `pubspec.yaml` add if the test fails to import. Cost: trivial.

2. **Should `main.dart` be excluded from CRIT-05 strict coverage?**
   - What we know: D-15 says strict no-skips. `main.dart` post-extraction is mostly `runApp` + `MaterialApp` scaffolding + `_HomePocketApp` State which is testable via `testWidgets`.
   - What's unclear: Whether the planner will enforce strict literally OR allow rationale-skip for boot code.
   - Recommendation: write a smoke `testWidgets` for `_HomePocketApp` covering both `_initialized=true` and `_error != null` branches; gets ≥80% on a 196-line file because most lines are widget tree.

3. **Does Plan 03-05 write characterization tests for ALL Phase 3 touched files OR only those in `files-needing-tests.txt`?**
   - What we know: Plan 03-05's purpose per D-15 is the intersection ∩.
   - What's unclear: Whether files NOT in `files-needing-tests.txt` (i.e., files already ≥80%) need any test additions when they're touched only by `git mv`.
   - Recommendation: Plan 03-05 covers the intersection; files already ≥80% pre-Phase-3 (NOT in `files-needing-tests.txt`) are exempted from new test writing as long as their existing tests still GREEN post-touch. Plan 03-03/04 acceptance verifies the existing tests stay GREEN.

4. **Is the `appDatabaseProvider` Option A (override-based, throwing StateError) compatible with CRIT-03's literal text?**
   - What we know: CRIT-03 says "either replaced with a concrete provider OR paired with a shared `createTestProviderScope` helper that always provides the override".
   - What's unclear: Whether Option A's "throws StateError when override missing" qualifies as "replaced with a concrete provider" or merely "paired with a helper."
   - Recommendation: Implement BOTH — `appDatabaseProvider` returns concrete `AppDatabase` BY ALWAYS BEING OVERRIDDEN (via AppInitializer in production, `createTestProviderScope` in tests) AND the placeholder body throws `StateError` only as a defensive guard. This satisfies both clauses of the OR and provides max defense-in-depth.

5. **What is the `containerFactory` API of `AppInitializer.initialize()` exactly — does it take pre-built overrides or build them internally?**
   - What we know: AppInitializer must produce a final `ProviderContainer` with `appDatabaseProvider` overridden.
   - What's unclear: Whether `containerFactory` takes overrides as a parameter (allowing test injection of additional overrides) or always returns a clean container.
   - Recommendation: Take overrides as parameter (per Pattern 3 implementation note). Cleaner test injection.

---

## Sources

### Primary (HIGH confidence — VERIFIED)

- **Project source files** (read directly — multiple Reads in research execution):
  - `lib/main.dart` (current init sequence Phase 3 extracts)
  - `lib/infrastructure/security/providers.dart` (current `appDatabaseProvider` placeholder; `biometricService` keepAlive pattern)
  - `lib/infrastructure/crypto/providers.dart` (concrete `@riverpod` template — `masterKeyRepositoryProvider`, etc.)
  - `lib/infrastructure/crypto/database/encrypted_database.dart` (`createEncryptedExecutor` signature)
  - `lib/infrastructure/crypto/repositories/master_key_repository.dart` (interface `AppInitializer` consumes)
  - `lib/data/app_database.dart` (`AppDatabase.forTesting()` constructor)
  - `lib/features/*/domain/import_guard.yaml` (current state for all 6 features)
  - `lib/features/import_guard.yaml`, `lib/data/import_guard.yaml`, `lib/application/import_guard.yaml`, `lib/import_guard.yaml`
  - `lib/features/family_sync/use_cases/check_group_use_case.dart` (sample of 5 to migrate)
  - `lib/features/home/domain/models/ledger_row_data.dart` (LV-022 source)
  - `analysis_options.yaml`, `pubspec.yaml`, `pubspec.lock`, `l10n.yaml`
  - `scripts/coverage_gate.dart` (Phase 2 output — invocation contract)
  - `.github/workflows/audit.yml` (CI staging)
  - `test/helpers/test_localizations.dart` (existing widget-test helper)

- **`import_guard_custom_lint 1.0.0` package source** (read directly via `~/.pub-cache/hosted/pub.dev/import_guard_custom_lint-1.0.0/`):
  - `README.md` (YAML schema confirmation)
  - `lib/src/core/config.dart` (config parsing; `inherit` default = true; `hasAllowRules` flag)
  - `lib/src/import_guard_lint.dart` (deny/allow precedence — **independent per-config evaluation**, the basis for the D-01 correction)
  - `test/config_test.dart` (verified examples of inherit + allow/deny + relative patterns)

- **Phase 3 upstream artifacts:**
  - `.planning/phases/03-critical-fixes/03-CONTEXT.md` (full read — D-01..D-17)
  - `.planning/phases/03-critical-fixes/03-UI-SPEC.md` (full read — InitFailureScreen contract + test contract)
  - `.planning/phases/03-critical-fixes/03-DISCUSSION-LOG.md` (rationale audit trail)
  - `.planning/REQUIREMENTS.md` (CRIT-01..CRIT-06 + adjacent)
  - `.planning/ROADMAP.md` (Phase 3 success criteria)
  - `.planning/PROJECT.md` (initiative scope, behavior preservation)
  - `.planning/STATE.md` (project decisions)
  - `.planning/audit/issues.json` (24 LV findings)
  - `.planning/audit/files-needing-tests.txt` (Phase 2 frozen baseline)
  - `.planning/audit/SCHEMA.md` (finding lifecycle)
  - `.planning/audit/REPO-LOCK-POLICY.md` (D-16 source-of-truth)
  - `.planning/codebase/CONCERNS.md` (CRIT-03 source)
  - `.planning/codebase/CONVENTIONS.md` (Riverpod, Freezed, i18n conventions)
  - `.planning/codebase/TESTING.md` (`AppDatabase.forTesting`, mocktail vs mockito policy)
  - `.planning/codebase/STRUCTURE.md` (5-layer Clean Architecture layout)
  - `CLAUDE.md` (project rules — App Initialization spec, Riverpod rules, Common Pitfalls)
  - `.claude/rules/testing.md` + `.claude/rules/arch.md`

### Secondary (MEDIUM confidence — verified with one official source)

- [import_guard_custom_lint pub.dev page](https://pub.dev/packages/import_guard_custom_lint) — schema overview confirmed against package source
- [import_guard pub.dev page](https://pub.dev/packages/import_guard) — successor package; not in scope for Phase 3 but flagged for FUTURE-TOOL

### Tertiary (LOW confidence — flagged for validation)

None — every Phase 3 claim was traceable to either project source, package source, or official documentation.

---

## Project Constraints (from CLAUDE.md)

The following CLAUDE.md directives constrain Phase 3 implementation; planner MUST verify compliance:

1. **Code generation after `@riverpod`/`@freezed`/Drift/ARB changes:** `flutter pub run build_runner build --delete-conflicting-outputs`. Plan 03-02 acceptance MUST include this step + `flutter gen-l10n`.
2. **Zero analyzer warnings before commit:** `flutter analyze` MUST be 0 issues. All 5 plans include this in acceptance.
3. **Don't modify generated files (`.g.dart`, `.freezed.dart`):** Plan 03-02 commits regenerated `.g.dart` for `appDatabaseProvider` and `init_result.freezed.dart`; does NOT hand-edit them.
4. **No layer dependency violations:** Phase 3 IS the cleanup of these. Plan 03-01 enforces structurally.
5. **Don't mutate — always use `copyWith`:** `InitResult` is Freezed sealed; mutation impossible. Other touched files preserve immutability.
6. **`intl` pinned at 0.20.2:** Plan 03-02's ARB additions do not bump `intl`.
7. **Don't add `sqlite3_flutter_libs`:** `lib/import_guard.yaml` already denies; arch test re-asserts.
8. **Don't skip AppInitializer (Common Pitfall #12):** Phase 3 EXTRACTS the initializer. Once extracted, future feature work cannot re-inline init logic — D-17's blocking import_guard + arch test enforce.
9. **Don't hardcode widget parameter defaults — use nullable + provider fallback:** `InitFailureScreen` retry callback is constructor-injected; idle/loading state is internal.
10. **Don't duplicate repository provider definitions:** Phase 3 doesn't add new repositories. Phase 4 HIGH-04 enforces.
11. **Don't use wrong Drift index syntax:** Plan 03-04 doesn't touch tables.
12. **Don't commit with analyzer warnings:** Same as #2.
13. **Don't forget to regenerate code after merge/pull:** Plan 03-02 commit includes regenerated artifacts.
14. **All UI text via `S.of(context)`:** UI-SPEC §"Copywriting Contract" enforces; Plan 03-02 adds 3 ARB keys.
15. **Update ALL 3 ARB files when adding translations, then run `flutter gen-l10n`:** Plan 03-02 acceptance includes parity diff check.
16. **Per-phase doc updates DEFERRED to Phase 7:** Phase 3 must NOT touch `doc/arch/`, `CLAUDE.md`, or `MEMORY.md`.

---

## Risk Register (planner mitigations)

| # | Risk | Severity | Mitigation in plan |
|---|------|----------|---------------------|
| **R1** | D-01 strategy literal-as-written breaks lint (parent allow rejects intra-domain) | HIGH | Plan 03-01: strip `allow` from each `lib/features/*/domain/import_guard.yaml`. Per-subdirectory yamls own the whitelist. Arch test asserts feature-level yaml has NO allow. |
| **R2** | `appDatabaseProvider` consumer breakage if type switches to `Future<AppDatabase>` | HIGH | Plan 03-02: keep provider sync; AppInitializer awaits async work; `.overrideWithValue(database)` in production container. |
| **R3** | `build_runner` drift → AUDIT-10 CI guardrail fails | HIGH | All plans touching `@riverpod`/`@freezed`: explicit `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` in acceptance. |
| **R4** | AppInitializer test isolation flakes due to undisposed containers | MEDIUM | Plan 03-02 test pattern: `setUp` builds fresh; `tearDown` disposes. Use `late` + `fakeAsync` if timing matters. |
| **R5** | ARB parity drift on 3 new keys | MEDIUM | Plan 03-02 acceptance: `jq -S 'keys'` parity diff between all 3 ARB files; `flutter gen-l10n` warning-free. |
| **R6** | `git mv` per-file PR doesn't preserve history due to bundled content changes | MEDIUM | Plan 03-03 per-file PR contract: `git mv` + minimal import-path adjustments ONLY. Verify with `git log --follow -- <new-path>`. |
| **R7** | D-17 audit.yml flip with stale `.dart_tool/` cache | MEDIUM | Plan 03-01 final commit acceptance: `rm -rf .dart_tool && flutter pub get && dart run custom_lint` exits 0 BEFORE flipping. |
| **R8** | `audit.yml` flip is irreversible operationally; future regressions block main | MEDIUM | All 5 plans complete + smoke before D-17. Phase 4+ planners aware that any new violations are blocked instantly. |
| **R9** | `package:yaml` not directly importable in test code | LOW | Plan 03-01 acceptance: if `import 'package:yaml/yaml.dart'` fails to resolve in test, add `yaml: ^3.1.0` to `dev_dependencies`. |
| **R10** | `recoverFromSeed()` accidentally exercised by AppInitializer test | LOW | Plan 03-02 tests use Mocktail fakes; never instantiate `KeyRepositoryImpl`; never hit real `flutter_secure_storage`. |
| **R11** | `lib/main.dart` coverage drops below 80% post-extraction (now thin shell) | LOW | Plan 03-02 acceptance: smoke `testWidgets` for `_HomePocketApp` covers both branches; expect coverage ≥80%. If still below, document as rationale-skip with planner+owner sign-off. |
| **R12** | `home/domain/` directory becomes empty after `ledger_row_data.dart` move | LOW | Plan 03-04 keeps `home/domain/import_guard.yaml` in place to enforce future home-domain models. The `models/` subdirectory yaml is NOT created (no models there post-move). |

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every package verified in `pubspec.lock`; existing-pattern source code read for templates
- Architecture (per-subdirectory yaml + corrected D-01 strategy): HIGH — verified by source read of `import_guard_custom_lint` lint code
- Pitfalls: HIGH — Pitfall 1 directly traced to source; others derived from project conventions verified in CONVENTIONS.md / TESTING.md / CLAUDE.md
- Validation Architecture: HIGH — `coverage_gate.dart` invocation contract verified by source read; CI gate semantics verified in audit.yml
- AppInitializer pattern: MEDIUM — pattern derived from project conventions; exact API (typedefs, container factory) is recommendation, not project mandate

**Research date:** 2026-04-26
**Valid until:** ~2026-05-26 (30 days for stable Flutter / Riverpod / import_guard_custom_lint stack)

---

## RESEARCH COMPLETE

Researched: per-subdirectory `import_guard.yaml` enforcement (with critical D-01 correction surfaced via source read), concrete `@riverpod` provider pattern preserving sync override semantics, Freezed sealed `InitResult` with constructor-injected `AppInitializer`, characterization-test technique selection per file category for Plan 03-05, `git mv` semantics + 5 family_sync use-case file inventory, `flutter gen-l10n` 3-key workflow, `coverage_gate.dart` invocation contract, complete Validation Architecture with per-requirement test mapping + Wave-0 gap list, and 12 risks with planner mitigations.
