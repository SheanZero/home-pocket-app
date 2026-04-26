# Home Pocket — Codebase Cleanup Initiative

## What This Is

A focused, audit-driven refactor of the Home Pocket (まもる家計簿) Flutter codebase, targeting four categories of accumulated technical debt: layer violations, redundant code, dead code, and Riverpod provider hygiene. The goal is to bring the codebase into a long-term stable state — pure refactor, zero behavior change to end users — before the next wave of feature modules (MOD-005 OCR, MOD-007 Analytics, MOD-013 Gamification) is implemented.

## Core Value

**Re-running the audit at the end finds zero violations across all four categories.** That is the only success criterion that matters; everything else is supporting it.

## Requirements

### Validated

<!-- Existing capabilities of the Home Pocket app, inferred from codebase map (.planning/codebase/) — these are NOT in scope to change behavior; they are the baseline being refactored under. -->

- ✓ Local-first encrypted accounting database (SQLCipher AES-256, schema v14, 11 Drift tables, full migration ladder v3→v14) — existing
- ✓ 5-layer Clean Architecture with "Thin Feature" rule (Infrastructure / Data / Domain / Application / Presentation) — existing
- ✓ Field-level encryption (ChaCha20-Poly1305) for sensitive fields, hash-chain integrity verification — existing
- ✓ Key management (Ed25519 device keys, BIP39 recovery phrase, biometric lock, secure storage) — existing
- ✓ Dual-ledger system (Survival ledger + Soul ledger) with rule-engine + merchant-database classification — existing
- ✓ Family sync (WebSocket relay + APNS push + E2EE + sync queue + CRDT-style apply pipeline) — existing
- ✓ Voice input (speech recognition + parser + fuzzy category matching + correction learning) — existing
- ✓ Analytics (monthly reports, expense trends, budget progress) — existing
- ✓ Settings: backup export/import, clear-all-data — existing
- ✓ Profile management (user profile + avatar sync) — existing
- ✓ i18n infrastructure (ja default / zh / en, ARB-driven, custom formatters for date/number/currency) — existing
- ✓ Riverpod-based DI (`@riverpod` code-gen) wired across all layers — existing
- ✓ Freezed-based immutable domain models with JSON serialization — existing
- ✓ Explicit, ordered app boot (`AppInitializer`: KeyManager → Database → others) — existing

### Active

<!-- The cleanup project itself. Each is a hypothesis until shipped + validated by re-audit. -->

- [x] Establish a hybrid audit pipeline (automated tooling + AI-agent semantic scan) that catalogs every violation across the four target categories, with file references, line references, and severity classifications  *(Validated in Phase 1: Audit Pipeline + Tooling Setup — terminal `.planning/audit/issues.json` produced with 26 findings, stable IDs, owner-approved)*
- [ ] Eliminate all layer-violation findings (Domain importing Data, features holding `application/`/`infrastructure/`/`data/tables/`/`data/daos/` code, dependency-flow inversions)
- [ ] Eliminate all redundant-code findings (duplicate models/types, duplicate provider definitions, parallel implementations of the same concern)
- [ ] Eliminate all dead-code findings (unused exports, unreachable branches, orphaned utilities, deprecated modules including MOD-009)
- [ ] Eliminate all Riverpod provider-hygiene findings (duplicated repository providers, `UnimplementedError` placeholders, misplaced provider definitions, missing single-source-of-truth in `repository_providers.dart`)
- [ ] Reach ≥80% test coverage on every file touched by the refactor; preserve or raise overall project coverage
- [ ] Centralized post-refactor sweep of architecture documentation (ARCH/MOD/ADR under `doc/arch/`) so docs match the refactored code
- [ ] Final verification: re-run the full audit pipeline; result must be zero findings across all four categories

### Out of Scope

<!-- Explicit boundaries with reasoning, so they don't get silently re-added. -->

- **New feature modules** (MOD-005 OCR, MOD-007 Analytics expansion, MOD-013 Gamification, etc.) — feature work is fully paused for this initiative; cleanup-first to avoid cherry-pick conflicts and unstable foundations
- **User-visible behavior changes** (UI, interactions, data, formatting) — strict pure refactor; users must not perceive any difference. Bug fixes that would change observable behavior are deferred
- **API/database breaking changes** — schema, public types, and Drift table shapes stay backward-compatible; a destabilizing migration is not part of this scope
- **Performance optimization as a goal** — performance changes that fall out of cleaner code are welcome, but performance is not a target; if a refactor measurably degrades perf the refactor is wrong
- **Security-architecture changes** — the 4-layer encryption stack is treated as fixed; security cleanup is limited to enforcing existing rules (e.g., "no direct flutter_secure_storage access"), not redesigning crypto
- **Per-phase doc updates** — ARCH/MOD/ADR docs are NOT updated phase-by-phase to avoid churn; one centralized sweep at the end
- **deprecated documentation entries** (e.g., MOD-009's index entry) are kept as historical record while deprecated *code* is deleted — only code/file removals are in scope, not historical doc pruning

## Context

- **Codebase maturity:** Home Pocket is in active development at v0.1.0 (Phase 1 — Infrastructure). The codebase has grown rapidly across multiple feature areas (accounting, family sync, voice, analytics, settings, profile) and accumulated the typical entropy of fast greenfield work
- **Codebase map exists:** `.planning/codebase/` was generated 2026-04-25 (`/gsd-map-codebase`). Contents: ARCHITECTURE.md, STACK.md, STRUCTURE.md, CONVENTIONS.md, INTEGRATIONS.md, TESTING.md, CONCERNS.md. These are the canonical "current state" reference for audit and planning
- **CLAUDE.md "Common Pitfalls" list:** The project's `CLAUDE.md` already enumerates 13 known pitfalls (don't duplicate repository providers, don't violate layer dependencies, don't mutate, etc.) — these are exactly the categories this initiative will systematically eliminate
- **Known deprecated module:** MOD-009 i18n was deprecated in favor of MOD-014. Code references to MOD-009 should be removed as part of this initiative
- **Tech stack:** Flutter, Riverpod 2.4+ (`@riverpod` code-gen), Freezed, Drift + SQLCipher, GoRouter, flutter_localizations (intl 0.20.2 pinned)
- **Test infrastructure:** flutter_test exists; coverage tooling configured. Current coverage level not yet quantified — Phase 1 audit will establish baseline
- **Why now:** Better to consolidate before the next wave of features (OCR, analytics, gamification) layer more code on potentially unstable foundations. Fixing layer violations and provider duplication early prevents them from being copy-pasted into new modules

## Constraints

- **Tech stack:** Flutter / Dart only; no language or framework migrations as part of this initiative — Reduces risk surface and keeps the refactor purely structural
- **Behavior preservation:** Strict — every refactored path must yield identical observable behavior (UI, data, interactions, API responses) — Pure refactor enables regression-style verification and protects users
- **Test coverage:** ≥80% on every file the refactor touches; CLAUDE.md mandates this — Provides the safety net required to refactor without introducing regressions
- **Audit completeness:** Hybrid (automated tooling + AI-agent semantic review) — Codebase scope is too large to enumerate by memory; relying on automation + agents prevents missed violations
- **Sequencing:** Strictly by severity (CRITICAL → HIGH → MEDIUM → LOW) — Avoids small polishing on top of architecturally broken foundations; biggest risks first
- **Concurrency:** No new feature modules during the initiative — Eliminates merge/cherry-pick conflicts and forces full focus on cleanup
- **Documentation:** Per-phase doc updates are deferred; one centralized sweep at the end — Doc churn during a multi-phase refactor wastes effort; sweep when the code is stable
- **Quality gates:** `flutter analyze` MUST be 0 issues, `dart format` clean, all tests passing — Standard project gates apply to every commit; cleanup work doesn't get to lower the bar

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Audit-driven (no manual issue list) | Codebase is too large for memory-based enumeration to be reliable | — Pending |
| Hybrid audit (tooling + AI agent) | Tooling catches mechanical issues fast and exhaustively; AI agents catch semantic/structural issues that grep can't see | — Pending |
| Severity-ordered phases (CRITICAL → LOW) | Architecture-breaking violations must be fixed before the codebase is otherwise polished, otherwise polish is on quicksand | — Pending |
| Strict behavior preservation (pure refactor) | Lowers blast radius; allows regression-style verification (golden tests, snapshot, manual smoke) | — Pending |
| ≥80% coverage on refactored files | Without a test net, refactor-induced regressions become silent; CLAUDE.md already mandates this for the project | — Pending |
| New feature work paused | Prevents conflicts and ensures the cleanup actually completes instead of stalling at 60% | — Pending |
| Delete deprecated code (e.g., MOD-009 references) | Deprecated code is dead weight that gets copy-pasted into new modules; remove now | — Pending |
| Centralized doc sweep (not per-phase) | Doc churn during refactor is wasted effort; one sweep at the end aligns docs to final state | — Pending |
| Audit re-run as final gate (zero violations) | Without a programmatic exit criterion, "done" becomes negotiable and the initiative drags | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-26 after Phase 2 (Coverage Baseline) completion — frozen baseline at `.planning/audit/coverage-baseline.{txt,json}` (234 files, 102 below 80%); REPO-LOCK window now operationally active until Phase 6 close*
