# Project Research Summary

**Project:** Home Pocket — Codebase Cleanup Initiative
**Domain:** Audit-driven, severity-ordered structural refactor of a Flutter/Dart application
**Researched:** 2026-04-25
**Confidence:** HIGH (all four research dimensions grounded in direct codebase inspection)

---

## Executive Summary

Home Pocket is a ~30k-line Flutter application that has accumulated four categories of technical debt during fast greenfield growth: layer violations (domain/presentation importing infrastructure or data directly), redundant code (dual `CategoryService` classes, deprecated `ResolveLedgerTypeService` still wired in the provider graph), dead code (orphaned files, ~169 hardcoded CJK strings, stale ARB keys), and Riverpod provider hygiene failures (`UnimplementedError` placeholders, duplicate repository providers). The codebase map and direct file inspection have confirmed specific live violations in all four categories — this is not a speculative audit. The recommended approach is a hybrid automated + AI-agent audit pipeline that produces a machine-readable findings catalogue (`issues.json`) sorted by a four-level severity taxonomy (CRITICAL / HIGH / MEDIUM / LOW), followed by severity-ordered fix phases and a final re-audit that must reach zero findings to declare the initiative complete.

The tooling stack is almost entirely already installed. `riverpod_lint` and `custom_lint` are active; `dart analyze` runs on every commit. Three additions to `dev_dependencies` cover the remaining audit gaps: `import_guard` (layer-violation enforcement as an analyzer plugin), `dart_code_linter` (dead-symbol and orphaned-file detection), and `coverde` (per-file coverage enforcement CLI). A GitHub Actions step using `very_good_coverage@v2` closes the CI coverage gate. No paid licenses are required for the core pipeline; DCM is the gold-standard upgrade path if the team later acquires a license.

The critical risks are behavioral rather than architectural: stale generated files (`.g.dart`, `.freezed.dart`, `.mocks.dart`) after refactor create silent mismatches that `flutter analyze` cannot detect because generated files are excluded from analysis; the dual `CategoryService` naming collision means correcting an import path can silently switch to the wrong implementation; and `appDatabaseProvider` throws `UnimplementedError` if any test constructs a `ProviderScope` without the override that lives only in `main.dart`. Every fix phase must run `build_runner build --delete-conflicting-outputs` and the full test suite before closing. These are not theoretical — they are confirmed defects in the current codebase.

---

## Key Findings

### Recommended Stack

**Tooling additions to `dev_dependencies`:**

| Tool | Purpose | Version | Notes |
|------|---------|---------|-------|
| `import_guard` | Layer-violation enforcement (analyzer plugin) | verify pub.dev | Dart 3.10+ compatible; Jan 2026; configures via `import_guard.yaml` |
| `dart_code_linter` | Dead-symbol + orphaned-file detection CLI | `^1.2.1` | Free OSS fork of DCM; Nov 2025 update |
| `coverde` | Per-file ≥80% coverage enforcement CLI | verify pub.dev | Jan 2026; reads standard `lcov.info` |
| `very_good_coverage@v2` | CI global coverage gate | v2 (GitHub Action) | No pubspec entry; reads `coverage/lcov.info` |
| `jscpd` | Mechanical copy-paste detection | npm latest | `npx jscpd lib/ --languages dart --min-lines 5 --min-tokens 50` |

**Already installed — must not change:**

| Tool | Version | Critical constraint |
|------|---------|-------------------|
| `riverpod_lint` | `^2.6.4` | Do NOT upgrade to 3.x — confirmed `analyzer` version conflict with `json_serializable` |
| `custom_lint` | `^0.7.5` | Plugin host; run via `dart run custom_lint` separately from `flutter analyze` |
| `flutter_lints` | `^6.0.0` | Base ruleset |

**What tooling cannot catch** (requires AI-agent semantic scan): `features/*/use_cases/` misplacements (confirmed: `lib/features/family_sync/use_cases/`), duplicate provider definitions across features that are each individually correct, semantic code duplication (same concept, different names), and indirect layer violations using type aliases.

**Avoid:** `dart_code_metrics` (sunset 2023, archived), `riverpod_lint 3.x` (analyzer conflict), `sqlite3_flutter_libs` transitively (SQLCipher conflict — CI gate required).

---

### What the Audit Pipeline Must Produce

**Severity taxonomy (locked before any scanning):**

| Severity | Definition | Confirmed live examples |
|----------|-----------|------------------------|
| CRITICAL | Violates architectural contract; could silently break behavior during refactor or create runtime failure risk if not fixed before next phase | `lib/features/family_sync/use_cases/` with direct infrastructure imports; `appDatabaseProvider` throwing `UnimplementedError`; domain importing data layer |
| HIGH | Violates declared architectural rule; DI graph corruption or copy-paste propagation risk, but no immediate runtime break | Presentation screen directly importing `infrastructure/`; deprecated service wired with `// ignore:` suppressions; duplicate repository providers |
| MEDIUM | Technical debt that degrades maintainability | ~169 hardcoded CJK strings; unused ARB keys; `ResolveLedgerTypeService` retained past `@Deprecated`; parallel static translation maps; coverage below 80% on refactored files |
| LOW | Isolated, non-propagating, no architectural impact | Unused private helpers; unreachable branches; stale `*.mocks.dart`; single-site TODO markers |

**Finding record schema:** `{ id, category, severity, file_path, line_start, line_end, description, rationale, suggested_fix, tool_source, confidence }`

**Required scanner output:** Layer violations (automated + AI-agent), dead code (symbol-level + file-level), deprecated code, duplicate providers, `UnimplementedError` in providers, misplaced providers, ARB unused keys, hardcoded CJK strings.

**Deliverables:** `ISSUES.json` (machine-readable, stable IDs for re-audit diffing) + `ISSUES.md` (human-readable, severity-sorted, suggested fix per finding).

**Anti-features (deliberately excluded):** Auto-fix during audit, behavior-change suggestions, performance profiling, security redesign suggestions, style linting beyond `dart format` + `flutter analyze`.

---

### Architecture: The Five-Component Pipeline

```
Audit Engine → Issue Catalogue → Fix Phases (A-D) → Doc Sweep → Re-Audit
```

Producer/consumer relationship is strictly linear. The Re-Audit is the only feedback loop — it re-runs the Audit Engine to verify zero findings.

**Key patterns:**
- **Characterization-test-first (Feathers pattern):** Before modifying any file below 80% coverage, write tests capturing current observable behavior. Refactor next. Tests must stay GREEN throughout.
- **Stable IDs in `issues.json`:** Findings get IDs like `LV-001`, `PH-012`. Re-audit diffs by ID — programmatically checkable, not eye-compared.
- **Shell + Dart scripts, no Melos:** Single-package project; `scripts/` has existing precedent (`arb_to_csv.dart`).
- **Hard gate between CRITICAL and HIGH:** `flutter analyze = 0` and all tests GREEN before the next phase begins.

**Artifact structure:**
```
.planning/
├── ISSUES.md              # Human-readable catalogue
├── issues.json            # Machine-readable, stable IDs, phase-assigned
├── coverage-baseline.txt  # Pre-refactor per-file coverage snapshot
└── re-audit/ISSUES-REAUDIT.json

scripts/
├── audit_layer.sh         # Import-graph layer-violation scanner
├── audit_dead_code.sh     # Dead symbol/file scanner
├── audit_providers.sh     # Riverpod hygiene scanner
├── coverage_gate.sh       # Per-file ≥80% enforcer
└── reaudit_diff.sh        # Diff issues.json vs re-audit output
```

---

### Critical Pitfalls — Every Fix Phase Must Respect These

1. **Stale generated files after any annotation change** — Editing `@riverpod`, `@freezed`, `@DriftDatabase`, or `@GenerateMocks`-annotated files without running `build_runner build --delete-conflicting-outputs` creates stale `.g.dart`/`.freezed.dart`/`.mocks.dart`. `flutter analyze` reports 0 issues (generated files excluded from analysis). Manifests as `NoSuchMethodError` at runtime. CI gate: `build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` on every commit.

2. **Dual `CategoryService` naming collision** — `lib/application/accounting/category_service.dart` (async, database-backed) and `lib/infrastructure/category/category_service.dart` (abstract final, 735 lines, static locale maps) share the class name and overlap in method names. Correcting an import path without knowing both exist silently switches implementations — type-checks pass, behavior differs. Fix in Phase 5 (Medium): rename infrastructure version to `CategoryLocaleService` before any provider consolidation.

3. **`appDatabaseProvider` throws `UnimplementedError` without its override** — override exists only in `main.dart`. Any test constructing its own `ProviderScope` without the override crashes if the refactored provider graph reaches `appDatabaseProvider` transitively. Fix in Phase 3 (Critical): replace with concrete provider or add shared `createTestProviderScope` helper that always includes the override.

4. **Cascade errors from incomplete deprecated-code deletion** — `ResolveLedgerTypeService` has source file + provider in `use_case_providers.dart` + dedicated test file + mock definitions in two `*.mocks.dart` files. Deletion checklist: source → provider → `build_runner` regen → test file → mock regen → `flutter analyze 0` → `flutter test GREEN`. All six steps required.

5. **ARB key deletion without static locale map audit** — `CategoryLocaleService` contains `_ja`, `_zh`, `_en` maps accessed via dynamic key lookup. Grep for `S.of(context).categoryFoo` returns 0 references, but the keys are live. OCR placeholder keys (`ocrScan`, `ocrScanTitle`, `ocrHint`) are intentional MOD-005 stubs. Protect with `@key` description comments; audit the static map before deleting any ARB key.

6. **`keepAlive` dropped during provider consolidation** — `syncEngineProvider`, `transactionChangeTrackerProvider`, `merchantDatabaseProvider`, `activeGroupProvider`, `activeGroupMembersProvider`, `ledgerProvider` require `keepAlive: true`. If the surviving provider definition lacks it, sync timers cancel silently mid-session. Capture `keepAlive` status before every consolidation.

7. **Drift schema changes without migration ladder update** — Adding `customIndices` requires bumping `schemaVersion` and adding a `createIndex` migration step. Omitting it means upgraded devices silently lack the index. New migration steps must use parameterized `customStatement('... VALUES (?, ?)', [a, b])` — never string interpolation (the v14 migration's SQL interpolation is a confirmed SQL injection risk if category names contain apostrophes).

8. **SQLCipher / sqlite3 native conflict from new transitive dependencies** — `pubspec.lock` must never contain `sqlite3_flutter_libs`. CI check: `grep sqlite3_flutter_libs pubspec.lock && echo "CONFLICT" && exit 1` after every `flutter pub get`.

---

## Implications for Roadmap

### Recommended Phase Structure: 8 Phases

The architecture researcher proposed 6 phases using sub-labels (3A, 3B, 3C, 3D) = effectively 8 discrete phases. The user's "fine" granularity setting (8–12 phases) aligns with this. The recommendation is **8 phases** — one per severity tier, plus setup, baseline, doc sweep, and re-audit.

**Do not collapse CRITICAL+HIGH into one phase.** HIGH fixes (provider hygiene, deprecated service wiring) depend on the correct application-layer file locations that CRITICAL fixes establish. Combining them means HIGH changes conflict with in-progress CRITICAL restructuring, entangles git history, and makes rollback harder.

---

### Phase 1: Tooling Setup and Audit Pipeline

**Rationale:** The findings catalogue is the definition of "done" for every subsequent phase. Without it, nothing has scope. Tooling must also be in place before any code changes so CI gates work from the first commit.

**Delivers:** `import_guard` + `dart_code_linter` + `coverde` added to `pubspec.yaml`; `import_guard.yaml` configured; `analysis_options.yaml` updated; `very_good_coverage@v2` CI step added; `sqlite3_flutter_libs` CI check added; all audit scripts created; all scanners run (automated + AI-agent); `ISSUES.json` + `ISSUES.md` produced with stable IDs and severity classifications reviewed; baseline finding count established.

**Must avoid:** Any code changes during audit. Discovery only.

**Research flag:** Standard patterns — no additional research needed.

---

### Phase 2: Coverage Baseline

**Rationale:** ≥80% coverage gate cannot be enforced without a pre-refactor snapshot. Phases 1 and 2 can run in parallel since neither makes code changes.

**Delivers:** `flutter test --coverage` run; generated files stripped from `lcov.info` → `lcov_clean.info`; per-file percentages written to `coverage-baseline.txt`; files-below-80% list generated (these need characterization tests before their fix phase begins); `scripts/coverage_gate.dart` created.

**Must avoid:** Any code changes.

**Research flag:** Flutter community standard — no additional research needed.

---

### Phase 3: CRITICAL Fixes — Layer Violations and Runtime Failures

**Rationale:** CRITICAL violations restructure files. HIGH fixes depend on the correct file locations CRITICAL establishes. Doing HIGH first wastes effort when CRITICAL moves the same files.

**Delivers:** `lib/features/family_sync/use_cases/` moved to `lib/application/family_sync/` with direct infrastructure imports removed; `appDatabaseProvider` `UnimplementedError` replaced; all other CRITICAL findings eliminated; `build_runner` run after every file move; characterization tests written for every touched file below 80% coverage.

**Gate:** `flutter analyze = 0`, all tests GREEN, ≥80% coverage on touched files, zero CRITICAL entries `"status": "open"` in `issues.json`.

**Research flag:** The `features/family_sync/use_cases/` migration is the most complex structural move. Consider a design sub-pass on the dependency injection interface before coding begins.

---

### Phase 4: HIGH Fixes — Provider Hygiene and Architectural Rule Violations

**Rationale:** HIGH violations affect the DI graph that MEDIUM cleanup will also touch. Must be clean before dead-code elimination.

**Delivers:** All presentation-to-infrastructure direct imports refactored through use cases; `ResolveLedgerTypeService` fully deleted (6-step checklist); duplicate repository providers eliminated (one `repository_providers.dart` per feature — not one global file); `keepAlive` lifecycle audit and preservation; `ref.read` vs `ref.watch` violations cleared.

**Gate:** Same as Phase 3. Zero HIGH entries `"status": "open"`.

**Must avoid:** Moving all repository providers into a single global file — that violates the "one per feature" rule and can create cross-feature layer violations.

**Research flag:** Standard Riverpod patterns — no additional research needed.

---

### Phase 5: MEDIUM Fixes — Dead Code, Redundancy, and i18n Violations

**Rationale:** Largest volume category. The `CategoryLocaleService` rename must happen before any downstream tooling assumes there is only one `CategoryService`.

**Delivers:** `lib/infrastructure/category/category_service.dart` renamed to `CategoryLocaleService` (all import sites updated); ~169 hardcoded CJK strings extracted to ARB files (all three ARB files updated atomically; `flutter gen-l10n` run after each edit); unused ARB keys removed with static-map audit first; MOD-009 code references removed; theme token TODOs addressed; `AppTextStyles.amount*` widget tests added verifying `FontFeature.tabularFigures()`.

**Gate:** Same. Zero MEDIUM entries `"status": "open"`.

**Must avoid:** Deleting ARB keys without auditing `CategoryLocaleService` static maps. Do not delete `_ja`, `_zh`, `_en` map entries flagged as "never referenced by literal key" — accessed via dynamic lookup. Protect OCR stubs with `@key` description comments.

**Research flag:** Static locale map / ARB consistency check may need a custom Dart script if manual audit is impractical at 500+ merchant entries.

---

### Phase 6: LOW Fixes — Minor Cleanup

**Rationale:** Isolated issues only safe to address after architectural foundations are clean.

**Delivers:** Unused private helpers deleted; unreachable branches removed; stale `*.mocks.dart` regenerated or migrated to Mocktail; `analysis_options.yaml` suppression directives removed for violations now fixed; three table index additions (`audit_logs_table.dart`, `user_profiles_table.dart`, `category_ledger_configs_table.dart`) with schema version bump and parameterized migration step; integration test for v(N-1)→vN migration with `PRAGMA index_list` assertion; `debugPrint`/`print` in sync engine and transaction change tracker wrapped in `if (kDebugMode)`.

**Gate:** Same. Zero LOW entries `"status": "open"`.

**Must avoid:** String interpolation in new Drift migration steps. Use `customStatement('... VALUES (?, ?)', [a, b])`.

**Research flag:** Standard patterns — no additional research needed.

---

### Phase 7: Doc Sweep

**Rationale:** Mid-refactor documentation is wrong by definition. One sweep at the end aligns to final stable state. Per PROJECT.md, MOD-009's index entry is preserved as historical record; only code deletions are in scope.

**Delivers:** All ARCH/MOD/ADR files reviewed; module specs updated for relocated files and renamed classes; CLAUDE.md pitfall list annotated for items addressed.

**Gate:** Human confirmation. No programmatic gate.

**Research flag:** Standard documentation work — no additional research needed.

---

### Phase 8: Re-Audit — Final Verification

**Rationale:** The only exit criterion that matters. Programmatically checkable via stable IDs.

**Delivers:** Full Audit Engine re-run; `.planning/re-audit/ISSUES-REAUDIT.json` produced; `reaudit_diff.dart` run reporting resolved / regression / new findings. If zero open findings: initiative declared complete, CI gates become permanent enforcement. If findings remain: return to appropriate fix phase.

**Gate:** `reaudit_diff.dart` exits 0. Zero open findings across all four categories.

**Research flag:** No additional research needed.

---

### Build-Order Dependencies (Hard)

```
Phase 1 (Audit) + Phase 2 (Baseline) — can run in parallel; both must complete before any fix phase
Phase 3 (CRITICAL) must gate before Phase 4
Phase 4 (HIGH) must gate before Phase 5
Phase 5 (MEDIUM) must gate before Phase 6
Phase 6 (LOW) must gate before Phase 7
Phase 7 (Doc Sweep) must complete before Phase 8
Phase 8 (Re-Audit) is terminal
```

**The single hardest dependency:** Phase 1 producing `issues.json` with stable IDs. Without it, no phase has a definition of "done."

### Exit Criterion — What "Zero Violations" Means Concretely

All of the following must pass simultaneously:
- `reaudit_diff.dart` reports 0 entries with `"status": "open"` across all four categories
- `flutter analyze` exits 0
- `dart run custom_lint` exits 0
- `flutter test --coverage` exits 0 with global coverage ≥80%
- `very_good_coverage@v2` does not fail (excluding `*.g.dart`, `*.freezed.dart`, `lib/generated/**`)
- `import_guard` reports 0 violations in `dart analyze` output
- `dart run dart_code_linter:metrics check-unused-code lib` reports 0 findings
- `build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0

---

## Open Questions / Decisions Deferred to Planning

1. **Committed `*.mocks.dart` strategy:** 14 committed mock files must be either moved to CI generation or migrated to Mocktail. Decision required before Phase 4 (interface changes to repositories occur there). Mocktail is preferred per project `TESTING.md` — recommend migrating as interfaces are touched.

2. **`appDatabaseProvider` replacement strategy:** Option A: replace body with concrete provider (requires `KeyManager` accessible at provider creation — verify `AppInitializer` ordering allows this). Option B: keep override pattern with a runtime assertion + shared test helper. Affects test infrastructure design.

3. **`CategoryLocaleService` long-term architecture:** The 735-line static locale map is confirmed technical debt. The rename in Phase 5 ensures correctness; whether to eventually drive this from ARB files (eliminating parallel maintenance) is a separate post-cleanup decision. Flag for the product roadmap.

4. **`import_guard` and `coverde` exact pinned versions:** STACK.md researcher flagged "verify current version on pub.dev" for both. Confirm before Phase 1 begins.

5. **OCR placeholder ARB keys:** Protect (`ocrScan`, `ocrScanTitle`, `ocrHint`) with `@key` description comments rather than deleting. Confirm with product owner before Phase 5 — these are MOD-005 stubs.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Tooling versions verified on pub.dev; `import_guard` is functional but niche — DCM is higher-confidence upgrade path if licensed |
| Features | HIGH | Finding schema, severity taxonomy, and scanner requirements grounded in direct inspection of confirmed violations with file paths and line numbers |
| Architecture | HIGH | Pipeline design follows published patterns (Feathers, standard `lcov` flow); phase count calibrated to project size, not a published standard |
| Pitfalls | HIGH | Every pitfall grounded in direct file inspection — not training-data assumptions; specific file paths confirmed |

**Overall confidence:** HIGH

### Gaps to Address During Planning

- **Exact versions for `import_guard` and `coverde`:** Verify on pub.dev before Phase 1.
- **Duplicate-code detection coverage:** No single free Dart-native tool reliably detects semantic duplication. `jscpd` + AI-agent is pragmatic but not exhaustive. If Phase 1 AI-agent scan produces many false negatives on the semantic-duplication category, a more structured approach may be needed.
- **Current coverage baseline unknown:** ~68% naive coverage ratio noted in codebase map, but per-file numbers unknown until Phase 2 runs. Number of files requiring characterization tests before fix phases begin is an open variable — Phase 2 may reveal a larger pre-work effort than anticipated.
- **`recoverFromSeed()` key-overwrite bug:** Classified HIGH in `CONCERNS.md` but out of cleanup scope. Adding tests to `KeyRepositoryImpl` in any phase could inadvertently trigger the bug in environments using real `flutter_secure_storage`. Flag this file as requiring mock-only (no real secure storage) test approach throughout the initiative.

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `.planning/codebase/CONCERNS.md` — confirmed violations, line-level findings
- `.planning/codebase/TESTING.md` — 14 committed mocks confirmed
- `.planning/PROJECT.md` — constraints, scope, key decisions
- `CLAUDE.md` — 13 known pitfalls
- Direct file inspection: `lib/infrastructure/security/providers.dart:96-102`, `lib/features/family_sync/use_cases/`, `lib/infrastructure/category/category_service.dart`, `lib/features/accounting/presentation/providers/use_case_providers.dart`, `lib/l10n/app_*.arb`

### Primary (HIGH confidence — official tooling docs)
- [pub.dev: riverpod_lint](https://pub.dev/packages/riverpod_lint) — v2.6.4, Feb 2026
- [pub.dev: dart_code_linter](https://pub.dev/packages/dart_code_linter) — v1.2.1, Nov 2025
- [pub.dev: coverde](https://pub.dev/packages/coverde) — Jan 2026
- [pub.dev: import_guard](https://pub.dev/packages/import_guard) — Jan 2026, Dart 3.10+
- [GitHub: VeryGoodOpenSource/very_good_coverage](https://github.com/VeryGoodOpenSource/very_good_coverage) — @v2

### Secondary (MEDIUM confidence)
- Feathers (2004) *Working Effectively with Legacy Code* — characterization test pattern
- [CodeHawks Severity Taxonomy](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) — CRITICAL/HIGH/MEDIUM/LOW standard
- [Riverpod issues #4393](https://github.com/rrousselGit/riverpod/issues/4393) — riverpod_lint 3.x / json_serializable conflict
- [dcm.dev: avoid-banned-imports guide](https://dcm.dev/docs/guides/advanced-architecture-rules-guide/) — DCM layer enforcement reference (not adopted)

---

*Research completed: 2026-04-25*
*Ready for roadmap: yes*
