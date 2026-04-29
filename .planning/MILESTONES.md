# Milestones — Home Pocket

Historical record of shipped versions. Each entry links to its full archive in `.planning/milestones/`.

---

## v1.0 — Codebase Cleanup Initiative

**Shipped:** 2026-04-29
**Phases:** 1-8 (8 phases, 48 plans)
**Duration:** 2026-04-25 → 2026-04-28 (~4 days)
**Tag:** `v1.0`
**Audit Status at Close:** `tech_debt` — milestone goal achieved with deferred items accepted as known debt
**Known deferred items at close:** ~17 items across 4 categories (see Tech Debt Carried Forward in archive). None are blockers; FUTURE-TOOL-03, FUTURE-QA-01, FUTURE-DOC-01..06 are tracked for v1.1+.

### Delivered

An audit-driven, severity-ordered refactor of the Home Pocket Flutter codebase that established a hybrid (automated + AI semantic) audit pipeline, eliminated all 50 known findings across the 4 categories (layer violations, redundant code, dead code, Riverpod hygiene), added characterization-test coverage on touched files, swept architecture documentation, and re-ran the full audit pipeline to verify zero remaining violations. Result: `REAUDIT-DIFF.json` reports `resolved=50, regression=0, new=0, open_in_baseline=0`.

### Key Accomplishments

1. **Hybrid audit pipeline operational** — 4 automated scanners + AI semantic-scan workflow + machine-readable `issues.json` + 4 permanent CI guardrails (`import_guard`, `riverpod_lint`, `coverde` per-file ≥70%, `sqlite3_flutter_libs` rejection)
2. **Zero open findings on re-audit** — 50 resolved, 0 regression, 0 new (REAUDIT-DIFF.json)
3. **Architectural debt eliminated** — Family-sync use cases moved to Application layer; Domain purity enforced; provider hygiene locked (single `repository_providers.dart` per feature, `keepAlive` reconciled, `ResolveLedgerTypeService` deleted, 33 presentation→infrastructure imports rerouted)
4. **i18n + dead-code cleanup** — All hardcoded CJK extracted to ARB; ARB key parity enforced; MOD-009 references deleted; `CategoryService` collision eliminated; 3 Drift indices added with v15 migration
5. **Coverage safety net** — `coverage_gate.dart` per-file gate (164 files, 0 failed at 70%) with `--deferred` mechanism for 10 explicit exceptions; global `very_good_coverage@v2` ≥70% (74.6% achieved)
6. **Documentation aligned** — All ARCH/MOD/ADR/CLAUDE.md updated; ADR-011 v1.1 amendment records cleanup outcome with commit-level traceability

### Stats

- **Initiative commits:** 315 (since 2026-04-25)
- **Files changed:** 1,061 (+282,686 / -100 lines, including tests + tooling + audit artifacts)
- **Languages:** Dart / Flutter
- **Requirements:** 54/54 complete (42 fully verified, 12 partial-due-to-bookkeeping with substitute evidence)

### Notable Decisions

- Coverage threshold amended 80→70% post-cleanup (FUTURE-TOOL-03 to revisit after v1 feature work)
- Smoke-test execution deferred to v1 release as owner-driven gate (FUTURE-QA-01)
- Mocktail big-bang migration chosen over CI-generated `*.mocks.dart` (HIGH-07)
- Documentation sweep centralized at Phase 7 rather than per-phase (avoids churn)
- ADR-011 v1.1 amendment uses 4-layer narrative (honest documentation pattern) rather than retrospective clean-win framing

### Archive

- `.planning/milestones/v1.0-ROADMAP.md` — full phase details
- `.planning/milestones/v1.0-REQUIREMENTS.md` — final requirement status + v2 backlog
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md` — pre-close audit report
