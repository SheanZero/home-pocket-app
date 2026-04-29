# Phase 6: LOW Fixes - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Eliminate LOW-severity cleanup debt before the documentation sweep: unused private members and orphaned files, stale suppression directives, missing Drift indices with a schema migration, and unsafe production logging. This is still a pure refactor phase: no user-visible behavior changes, no feature work, and every touched file must reach 80% coverage.

Important catalogue state: `.planning/audit/issues.json` currently has no open `LOW` entries, while `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` define concrete LOW work. Phase 6 must treat that as stale LOW catalogue data, not as absence of work.

</domain>

<decisions>
## Implementation Decisions

### LOW Scope Source of Truth
- **D-01:** Start Phase 6 with a LOW re-scan before fixing. The missing open `LOW` rows in `.planning/audit/issues.json` are treated as a stale catalogue state.
- **D-02:** Add stable issue rows to `.planning/audit/issues.json` for concrete scanner-backed LOW findings discovered by the re-scan, then close those rows during Phase 6. This preserves Phase 8 traceability.
- **D-03:** Roadmap-defined LOW work that is requirement-backed but not emitted as a scanner finding, especially the known Drift index/migration work, remains in scope through LOW-01..LOW-07 even if it does not map cleanly to a scanner row.

### Debug Logging Boundary
- **D-04:** Review all production logging, not only unguarded `print()` and bare `debugPrint()`. Scope includes `print`, `debugPrint`, and `dart:developer` `dev.log` calls in production paths.
- **D-05:** Guard or scrub logs that could expose request bodies, transaction IDs, device IDs, tokens, signatures, group identifiers, or other operational identifiers. Debug-only logs should remain behind `kDebugMode`; logs that remain in release paths must be non-sensitive.
- **D-06:** A centralized logging utility is not required unless the planner determines it is the smallest safe implementation. The locked requirement is privacy-safe production logging, not a new logging abstraction.

### Gate Tightening Timing
- **D-07:** Keep Phase 6 implementation unblocked while cleanup is in progress. Flip LOW-related gates to blocking in the final Phase 6 close commit after all LOW work is fixed.
- **D-08:** By Phase 6 close, `dart_code_linter` dead-code checks, per-file coverage enforcement, and logging/print enforcement must be blocking through the normal verification/CI path.
- **D-09:** Intermediate plans may run these checks locally as verification, but should not make CI fail on known in-progress LOW debt before the final close commit.

### the agent's Discretion
- Exact plan split and sequencing within Phase 6.
- Exact stable ID numbering for new LOW rows, provided the audit schema and stable-ID permanence rules are followed.
- Exact Drift index column set for each of the three required tables, provided it satisfies LOW-04 and uses project Drift conventions.
- Whether logging cleanup is implemented by local guards/scrubbing or a small shared helper, provided D-04 through D-06 are met.
- Exact shape of tests and scanner assertions, provided all touched files meet the 80% coverage gate and all Phase 6 success criteria pass.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 6 goal, success criteria, and severity ordering.
- `.planning/REQUIREMENTS.md` — LOW-01 through LOW-07 acceptance requirements.
- `.planning/PROJECT.md` — Pure-refactor constraint, behavior preservation, cleanup initiative boundaries.
- `.planning/STATE.md` — Current phase position and recent decisions carried forward from Phase 5.

### Audit Catalogue and Gates
- `.planning/audit/issues.json` — Current finding catalogue; note that open LOW rows are missing and must be refreshed by Phase 6 re-scan.
- `.planning/audit/ISSUES.md` — Human-readable audit summary from the catalogue.
- `.planning/audit/SCHEMA.md` — Stable finding schema, severity taxonomy, stable ID rules, lifecycle fields, and coverage baseline schema.
- `.planning/audit/REPO-LOCK-POLICY.md` — Cleanup runway merge and coverage discipline; Phase 6 close lifts the lock.
- `.planning/audit/shards/dead_code.json` — Current dead-code scanner shard; empty at context time and must be refreshed.
- `.planning/audit/agent-shards/drift_col.json` — Current Drift-column shard; notes that no programmatic Drift unused-column scan completed in Phase 1.
- `.github/workflows/audit.yml` — Existing staged CI gates; Phase 6 close flips LOW-related gates blocking.

### Existing Patterns
- `.planning/codebase/CONVENTIONS.md` — Drift `TableIndex` syntax, provider/file conventions, logging notes, and no-suppression policy.
- `.planning/codebase/TESTING.md` — In-memory Drift database testing pattern and test organization.
- `.planning/codebase/INTEGRATIONS.md` — Existing logging and sync integration surfaces.
- `.planning/audit/coverage-baseline.txt` — Frozen Phase 2 per-file coverage baseline; used to identify characterization coverage needs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/audit/dead_code.dart` and `scripts/audit_dead_code.sh`: Existing LOW scanner path for `dart_code_linter:metrics check-unused-code` and `check-unused-files`; should be re-run and, if needed, fixed before adding stable LOW issue rows.
- `scripts/coverage_gate.dart`: Existing per-file coverage gate. Phase 6 plans should invoke it against touched files after generating `coverage/lcov_clean.info`.
- `test/unit/data/migrations/category_v14_migration_test.dart`: Existing migration-test style. It uses `AppDatabase.forTesting()`, raw setup SQL, and direct assertions; Phase 6 migration/index tests should follow this pattern unless planner finds a safer Drift-native migration harness.
- Existing `TableIndex` usage in `books_table.dart`, `categories_table.dart`, `transactions_table.dart`, and other tables: Use `List<TableIndex> get customIndices => [...]` with Symbol syntax such as `{#columnName}` and no `@override`.

### Established Patterns
- Drift schema version currently lives in `lib/data/app_database.dart` as `schemaVersion => 14`; Phase 6 index work should bump it and add a guarded migration block.
- Known missing-index targets from LOW-04 are `lib/data/tables/audit_logs_table.dart`, `lib/data/tables/user_profiles_table.dart`, and `lib/data/tables/category_ledger_configs_table.dart`.
- `analysis_options.yaml` currently has `avoid_print: false`; Phase 6 close should decide and apply the enforcement mechanism that makes logging regressions fail.
- Many `debugPrint` calls are already guarded by `if (kDebugMode)`, especially under `lib/application/family_sync/` and `lib/infrastructure/sync/`; this is the preferred local pattern when retaining debug-only diagnostics.
- `dart:developer` `dev.log` exists in app initialization and accounting paths. These are now in Phase 6 scope because D-04 covers all production logging.

### Integration Points
- `lib/data/app_database.dart`: schema bump and migration step for added indices.
- `lib/data/tables/audit_logs_table.dart`: add `customIndices` for audit-log query paths.
- `lib/data/tables/user_profiles_table.dart`: add `customIndices` for profile lookup/update query paths.
- `lib/data/tables/category_ledger_configs_table.dart`: add `customIndices` for ledger-config query paths.
- `.github/workflows/audit.yml`: final close commit flips LOW-related gates to blocking.
- `.planning/audit/issues.json` and `.planning/audit/ISSUES.md`: refreshed LOW findings should be recorded and later closed with lifecycle fields.

</code_context>

<specifics>
## Specific Ideas

- The user explicitly chose “re-scan first” because the absence of open LOW rows conflicts with the roadmap/requirements. Planner should make the first Phase 6 plan restore audit-catalogue trust before remediation work.
- The user explicitly chose stable issue rows for scanner-backed LOW findings. Do not leave LOW work only in transient shard files if a concrete scanner-backed finding exists.
- The user explicitly chose the broader logging boundary. Even though LOW-06 names `print()` and `debugPrint()`, `dev.log` should be checked where it can expose identifiers or sensitive operational context.
- The user explicitly chose final-close gate tightening. Avoid making CI fail on known in-progress LOW debt during intermediate Phase 6 plans; the final close commit is where LOW gates become blocking.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 6 scope.

</deferred>

---

*Phase: 06-low-fixes*
*Context gathered: 2026-04-27*
