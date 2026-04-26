# Phase 3: CRITICAL Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `03-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 3-critical-fixes
**Areas discussed:** Domain import_guard rule, appDatabaseProvider fix (CRIT-03), Tactical fixes (use_cases + dart:ui), Plan structure & test rigor

---

## Domain import_guard rule

### Q1: How should we resolve the 19 intra-domain composition violations (LV-001..016, LV-023, LV-024)?

| Option | Description | Selected |
|--------|-------------|----------|
| Relax: allow same-feature domain composition | Add `package:home_pocket/features/<same_feature>/domain/**` to each feature's allow list. All 19 findings auto-resolve as schema fix; ~6h work. | |
| Refactor: break composition, use IDs only | Restructure 19 files to reference each other by ID only. Architecturally pure but ~30-50h work; risks behavior change. | |
| Hybrid: extract shared types to feature/domain/shared/ | Move shared enums/value objects to features/<f>/domain/shared/; refactor remaining cross-refs to ID-only. ~15h work. | |
| Per-file allow lists (most precise) | Each domain subdirectory gets its own import_guard.yaml explicitly allowing the files it composes. ~10h Phase 3 work; recurring tax on future domain changes. | ✓ |

**User's choice:** Per-file allow lists (most precise)
**Notes:** D-01, D-03 — implemented as per-subdirectory `import_guard.yaml` (one each in `models/` and `repositories/`) with `inherit: true` chaining to feature-level rules.

### Q2: Add architecture test (golden file) asserting deny list cannot regress?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — Dart unit test that parses import_guard.yaml | Loads each feature's import_guard.yaml, asserts deny list still contains data/infra/application/presentation/flutter. ~2h. | ✓ |
| No — trust import_guard + CI to catch regressions | import_guard becomes blocking at Phase 3 close; arch test would be belt-on-suspenders. | |

**User's choice:** Yes — ship a Dart unit test that parses import_guard.yaml
**Notes:** D-02 — establishes belt-and-suspenders coverage so the deny list itself can't regress accidentally.

### Q3: Where do per-file `import_guard.yaml` files live?

| Option | Description | Selected |
|--------|-------------|----------|
| Per-subdirectory (models/, repositories/) | Each domain subdirectory gets its own import_guard.yaml with `inherit: true`. ~10 yaml files. | ✓ |
| Per-file pseudo-yaml via in-file directives | Encode rules as comment headers + custom_lint reader. Eliminates yaml proliferation but is a project-only convention. | |
| One yaml per feature with explicit per-file blocks | Single feature yaml with `per_file:` map. Requires import_guard 1.x+. | |
| One yaml per file (.dart ↔ .yaml pair) | Sibling .yaml per .dart file. ~30+ new yaml files; high maintenance tax on every model rename. | |

**User's choice:** Per-subdirectory (models/, repositories/)
**Notes:** Granular but matches existing convention; keeps allow rules close to the files they govern.

### Q4: Naming convention for the architecture test file?

| Option | Description | Selected |
|--------|-------------|----------|
| test/architecture/domain_import_rules_test.dart | New test/architecture/ directory establishes "meta-tests about codebase shape" convention. | ✓ |
| test/audit/import_guard_test.dart | Group under test/audit/ alongside any Phase 8 re-audit harness tests. | |
| scripts/audit/test/import_guard_test.dart | Co-locate with audit Dart cores. Needs special CI config. | |

**User's choice:** test/architecture/domain_import_rules_test.dart
**Notes:** D-04 — Phase 4+ extends this directory with provider-graph hygiene tests, etc.

---

## appDatabaseProvider fix (CRIT-03)

### Q1: How should `appDatabaseProvider` be fixed so it never throws UnimplementedError?

| Option | Description | Selected |
|--------|-------------|----------|
| Concrete provider + AppInitializer | Replace placeholder with concrete @riverpod; lift main.dart init logic into lib/core/initialization/app_initializer.dart. Closes CRIT-03 AND missing-AppInitializer concern. ~12h. | ✓ |
| Test helper + assertion guard | Keep placeholder, add runtime guard, ship createTestProviderScope helper. ~4h but doesn't address missing-AppInitializer. | |
| Concrete provider only — inline in providers.dart | Replace throw-er with concrete impl, keep main.dart inlined. ~6h. | |
| Hybrid: concrete provider + helper for tests | Both paths. ~14h. Most complete. | |

**User's choice:** Concrete provider + AppInitializer
**Notes:** D-05 — closes the CONCERNS.md "Centralized AppInitializer missing" item simultaneously.

### Q2: Where does AppInitializer live and what does it return?

| Option | Description | Selected |
|--------|-------------|----------|
| lib/core/initialization/app_initializer.dart returning InitResult | Matches CLAUDE.md spec verbatim. InitResult is Freezed sealed class success/failure. | ✓ |
| lib/main.dart helpers (no separate file) | Top-level functions in main.dart. Contradicts CLAUDE.md spec. | |
| lib/application/initialization/app_initializer.dart | Application-layer placement. Contradicts CLAUDE.md explicit path. | |

**User's choice:** lib/core/initialization/app_initializer.dart returning InitResult (Recommended)
**Notes:** D-05 — aligns prod with CLAUDE.md instead of inverse.

### Q3: Should AppInitializer also seed default book/categories?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — capture full inlined init verbatim | Move entire main.dart:28-83 sequence: master-key → DB → seed. Pure refactor. | ✓ |
| No — only key+DB; leave seeding in main.dart | Smaller blast radius but partial init path. | |
| Yes, but split: AppInitializer + DataSeeder use case | Two units. Cleaner separation but doubles surface area. | |

**User's choice:** Yes — capture full inlined init verbatim
**Notes:** D-06 — pure refactor: behavior identical, just centralized and unit-testable.

### Q4: What does main.dart render when AppInitializer returns InitResult.failure?

| Option | Description | Selected |
|--------|-------------|----------|
| Localized error fallback screen + retry button | Render Material app with 3 ARB keys + retry button that re-invokes AppInitializer. Adds 3 ARB keys. | ✓ |
| Plain English fallback screen (no i18n) | Hardcode 'App initialization failed' + 'Retry'. Violates CLAUDE.md S.of(context) rule. | |
| Crash with rich diagnostic (no UI fallback) | Structured error to log + crash. No improvement over today's UnimplementedError throw. | |

**User's choice:** Localized error fallback screen + retry button
**Notes:** D-07 — adds initFailedTitle/Message/Retry keys to ja/zh/en. Bridges into MED-04 ARB-parity surface early; bridging note captured in CONTEXT.md `<deferred>`.

### Q5: How to test failure path for CRIT-05 ≥80% coverage?

| Option | Description | Selected |
|--------|-------------|----------|
| Inject failures via fake repositories | Constructor-injected dependencies; fakes throw at each stage. ~10 unit tests. | ✓ |
| Integration test only — real MasterKeyRepository in fake mode | Single integration test with in-memory DB. Misses failure paths. | |
| Mix: fake-injection unit tests + 1 wired integration test | Both layers. ~15 tests. Most thorough. | |

**User's choice:** Inject failures via fake repositories
**Notes:** D-08 — establishes the test pattern Phase 4 will extend (HIGH-07 mocks strategy).

---

## Tactical fixes (use_cases + dart:ui)

### Q1: How do we migrate the 5 features/family_sync/use_cases/*.dart files?

| Option | Description | Selected |
|--------|-------------|----------|
| Git mv preserving filenames; one PR per file | 5 atomic PRs; each moves source + test together; bisect-friendly. | ✓ |
| Single atomic PR moving all 5 + tests + import_guard cleanup | One diff; harder to bisect. | |
| Per-file mv but rename to remove _use_case suffix | Existing siblings already use the suffix; renaming would break consistency. | |

**User's choice:** Git mv preserving filenames; one PR per file
**Notes:** D-09 — each PR also moves the test file (D-12).

### Q2: How do we resolve LV-022 — ledger_row_data.dart imports dart:ui for 10 Color fields?

| Option | Description | Selected |
|--------|-------------|----------|
| Move to features/home/presentation/models/ | File is by nature a presentation view-model; Move closes LV-022 cleanly. ~3h. | ✓ |
| Strip Colors — store ARGB int hex; convert at presentation | Lossy abstraction; every consumer adds boilerplate. ~6h. | |
| Move to features/home/presentation/widgets/ next to its consumer | Conflates view-model with widget code. | |

**User's choice:** Move to features/home/presentation/models/ (Recommended)
**Notes:** D-11 — sets convention "view-models with Color belong in presentation/models/" (D-12, deferred CLAUDE.md update to Phase 7).

### Q3: When 5 use_case files move from features/ to application/, what about their test files?

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror the source move | Test directory mirrors source layout; bundled into per-file PR. | ✓ |
| Mirror, but consolidate any duplicates with existing test/application/family_sync/ | Adds triage step; prevents test ghosts. | |
| Defer test moves to a separate cleanup PR | Imports break immediately when source moves; not viable. | |

**User's choice:** Mirror the source move
**Notes:** D-12 — bundled into each per-file PR.

---

## Plan structure & test rigor

### Q1: How should Phase 3 be broken into plans?

| Option | Description | Selected |
|--------|-------------|----------|
| 5 plans, one per concern | (1) import_guard, (2) AppInit, (3) use_cases mv, (4) ledger_row mv, (5) char-tests. Plans 1/3/4/5 parallelizable; Plan 2 depends on Plan 5. | ✓ |
| 8 plans, one per touched feature | Per-feature plans. Cross-cutting domain rule fix doesn't fit per-feature splits. | |
| 1 large plan with sub-sections | Smallest planning overhead; defeats wave-based parallelization. | |
| 3 plans by risk tier | Risk-ordered execution. Loses per-concern atomicity. | |

**User's choice:** 5 plans, one per concern (Recommended)
**Notes:** D-13 — clear ownership per plan, atomic exit gates.

### Q2: How strictly do we interpret CRIT-05 — 'every file touched in this phase has ≥80% coverage'?

| Option | Description | Selected |
|--------|-------------|----------|
| Strict: every file in touched-files including pure renames | coverage_gate.dart runs against post-refactor list; renames trigger gate. No escape hatches. | ✓ |
| Pragmatic: skip pure renames with documented rationale | Subjective judgment; auditable only if every skip documented. | |
| Hybrid: strict for logic files, pragmatic for presentation models | Adds 'logic vs data' classification step; risk of mis-classifying. | |

**User's choice:** Strict: every file in touched-files including pure renames (Recommended)
**Notes:** D-15 — aligns with Phase 2 D-09 and PROJECT.md "no negotiable done."

### Q3: What's the parallelization strategy across the 5 plans?

| Option | Description | Selected |
|--------|-------------|----------|
| W1: {1, 3, 4, 5} parallel; W2: {2} | Plans 1/3/4/5 share no deps; Plan 5 produces test infra Plan 2 needs. ~16h W1 + ~14h W2. | ✓ |
| Strict serial: 1 → 5 → 3 → 4 → 2 | One at a time. ~50h wall time. | |
| W1: {5}; W2: {1, 3, 4}; W3: {2} | Tests first, then parallel cheap fixes, then deep change. ~25h. Most conservative. | |

**User's choice:** Wave 1: {1 import_guard, 3 use_cases, 4 ledger_row, 5 chars-tests} parallel; Wave 2: {2 AppInit} (Recommended)
**Notes:** D-14 — fastest wall-clock path; Plan 2 depends on Plan 5's test infra (fakes for crypto/DB).

---

## Claude's Discretion

- Exact naming of `InitResult` failure variants and error type enum
- Whether `SeedService` is a new class or inlined free function in `AppInitializer`
- Per-file characterization-test technique (golden, widget, unit, integration)
- Order of the 5 use_case file migrations (any order works)
- Whether `ledger_row_data.dart` move is bundled into Plan 03-04 alone or splits into 03-04a/b based on caller count

## Deferred Ideas

- 3 init-failure ARB keys are pre-seeded by Phase 3 (Phase 5 MED-04 bridging note)
- `*.mocks.dart` strategy decision (Phase 4 HIGH-07)
- `test/architecture/provider_graph_hygiene_test.dart` (Phase 4 HIGH-04)
- CLAUDE.md update for "view-models with dart:ui belong in presentation/models/" (Phase 7)
- Deletion of empty `features/family_sync/use_cases/` directory's deny rule (Phase 7)
- `SeedService` class extraction (discretionary in Plan 03-02)
- `recoverFromSeed()` key-overwrite bug (FUTURE-ARCH-04, out of scope)
- `ledger_row_data.dart` rename to `ledger_row_view_model.dart` (Phase 7 if desired)
