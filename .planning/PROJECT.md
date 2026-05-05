# Home Pocket — まもる家計簿

## Current State

**Shipped:** v1.0 Codebase Cleanup Initiative (2026-04-29) — see `.planning/milestones/v1.0-ROADMAP.md`
**Shipped:** v1.1 Happiness Metric & Display (2026-05-05) — see `.planning/milestones/v1.1-ROADMAP.md`

The v1.0 initiative was a pure-refactor cleanup, not a feature release. It delivered an operational hybrid audit pipeline, eliminated 50 catalogued findings (24 CRITICAL, 8 HIGH, 8 MEDIUM, 7 LOW + 3 layer-violation closures), aligned all architecture documentation with the post-refactor codebase, and locked 4 permanent CI guardrails. Re-audit reports zero open findings across all 4 categories.

The v1.1 milestone delivered the happiness metric domain, HomePage `HomeHeroCard`, AnalyticsScreen Variant δ unified dashboard, and final trilingual UI copy rename pass. It also ratified the v1.1 anti-gamification and lexical hierarchy ADRs. One Phase 11 human/device UAT item remains accepted as known close debt in `.planning/STATE.md`.

The codebase is now ready for the next milestone cycle. Candidate directions include release-readiness QA, OCR, family sync hardening, strict family analytics consent, or toolchain/doc guardrail cleanup.

## Current Milestone

No active milestone. Start the next milestone with `$gsd-new-milestone`.

<details>
<summary>v1.1 Happiness Metric & Display (archived)</summary>

**Goal:** 把"花钱的幸福"从模糊感觉变成可计算、可展示的指标——让 HomePage 和统计页围绕「悦己账本」的幸福度数据组织起来；同时为家庭模式提供反对抗、合作型的共同指标。

**Delivered:**
- 4 personal Joy indicators: Avg Satisfaction, Joy per ¥, Highlights count, Best Joy story
- 2 aggregate-only family indicators: Family Highlights Sum and Shared Joy Insight
- HomePage integrated `HomeHeroCard`
- AnalyticsScreen Variant δ unified dashboard
- ARB-only rename across ja/zh/en: Joy/Daily ledger language, Joy density/index, satisfaction ladder, and `satisfactionExcellent`

**Archive:** `.planning/milestones/v1.1-ROADMAP.md`, `.planning/milestones/v1.1-REQUIREMENTS.md`

</details>

<details>
<summary>v1.0 Project Description (archived)</summary>

## What This Is (v1.0)

A focused, audit-driven refactor of the Home Pocket (まもる家計簿) Flutter codebase, targeting four categories of accumulated technical debt: layer violations, redundant code, dead code, and Riverpod provider hygiene. The goal was to bring the codebase into a long-term stable state — pure refactor, zero behavior change to end users — before the next wave of feature modules (MOD-005 OCR, MOD-007 Analytics, MOD-013 Gamification) is implemented.

## Core Value (v1.0)

**Re-running the audit at the end finds zero violations across all four categories.** Met — REAUDIT-DIFF.json reports `resolved=50, regression=0, new=0, open_in_baseline=0`.

</details>

## What This Is

Home Pocket (まもる家計簿) is a local-first, privacy-focused family accounting app with a dual-ledger system (Survival ledger + Soul ledger). Zero-knowledge architecture with 4-layer encryption, P2P family sync, and offline-first design. Target: iOS 14+ / Android 7+ (API 24+). The v1.0 cleanup established the architectural and quality baseline; v1.1+ resumes feature work on top of it.

## Core Value

A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes survival spending from soul spending so families can have honest money conversations.

## Requirements

### Validated

<!-- Capabilities shipped or confirmed stable. Existing app baselines are unchanged; v1.0 cleanup-shipped capabilities are added below. -->

**Existing app baseline (unchanged by v1.0 cleanup):**

- ✓ Local-first encrypted accounting database (SQLCipher AES-256, 11 Drift tables) — schema bumped v14 → v15 in v1.0 (3 new indices)
- ✓ 5-layer Clean Architecture with "Thin Feature" rule — now structurally enforced by `import_guard` (v1.0)
- ✓ Field-level encryption (ChaCha20-Poly1305), hash-chain integrity verification
- ✓ Key management (Ed25519 device keys, BIP39 recovery phrase, biometric lock, secure storage)
- ✓ Dual-ledger system (Survival + Soul) with rule-engine + merchant-database classification
- ✓ Family sync (WebSocket relay + APNS push + E2EE + sync queue + CRDT-style apply pipeline)
- ✓ Voice input (speech recognition + parser + fuzzy category matching + correction learning)
- ✓ Analytics (monthly reports, expense trends, budget progress)
- ✓ Settings: backup export/import, clear-all-data
- ✓ Profile management (user profile + avatar sync)
- ✓ i18n infrastructure (ja default / zh / en, ARB-driven, custom formatters)
- ✓ Riverpod-based DI (`@riverpod` code-gen)
- ✓ Freezed-based immutable domain models
- ✓ Explicit, ordered app boot (`AppInitializer`: KeyManager → Database → others) — `AppInitializer` extracted in v1.0 (CRIT-03)

**Shipped in v1.0 (Codebase Cleanup Initiative):**

- ✓ Hybrid audit pipeline (4 automated scanners + AI semantic-scan workflow) producing machine-readable `issues.json` with stable IDs — v1.0
- ✓ Zero open findings across all 4 audit categories (REAUDIT-DIFF.json `resolved=50, regression=0, new=0, open=0`) — v1.0
- ✓ All layer-violation findings eliminated; Domain purity enforced by `import_guard` — v1.0
- ✓ All redundant-code findings eliminated (duplicate providers, `ResolveLedgerTypeService` deletion, `CategoryService` collision resolved) — v1.0
- ✓ All dead-code findings eliminated; MOD-009 deprecated code removed; `dart_code_linter check-unused-code/files` reports 0 — v1.0
- ✓ All Riverpod provider-hygiene findings eliminated (single `repository_providers.dart` per feature, `keepAlive` reconciled, no `UnimplementedError` outside test fixtures) — v1.0
- ✓ All hardcoded CJK strings extracted to ARB; ARB key parity locked across ja/zh/en — v1.0
- ✓ All ARCH/MOD/ADR docs and CLAUDE.md aligned with post-refactor codebase; ADR-011 records cleanup outcome — v1.0
- ✓ 4 permanent CI guardrails (`import_guard`, `riverpod_lint`/`custom_lint`, `coverde` per-file ≥70%, `sqlite3_flutter_libs` rejection) + global `very_good_coverage@v2` ≥70% + `build_runner` clean-diff — v1.0
- ✓ Mocktail big-bang migration (13 fixtures); mockito removed — v1.0 (HIGH-07)
- ✓ v1.1 happiness metric domain contracts validated in Phase 09: personal metric formulas, family aggregate-only return type, sealed `MetricResult`, soul-only filter, v16 default-2 satisfaction semantics, no-gamification ADRs, and full HAPPY-08 picker mapping test coverage.
- ✓ v1.1 HomePage happiness display validated in Phase 10: personal metric tiles, Best Joy story card, group-mode family insight, empty states, info tooltips, and golden coverage.
- ✓ v1.1 AnalyticsScreen unified dashboard validated in Phase 11: KPI mini-hero, Joy-per-¥ trend, satisfaction histogram, story cards, month picker, and aggregate-only family insight.
- ✓ v1.1 UI copy rename pass validated in Phase 12: ARB value rewrites for ja/zh/en, picker sentiment-positive icon ladder, RENAME-07 requirement, accepted ADR-015 lexical hierarchy, and refreshed goldens.

### Active

No active milestone requirements. `$gsd-new-milestone` will define the next scoped requirement set and recreate `.planning/REQUIREMENTS.md`.

### Out of Scope

<!-- Explicit boundaries carried forward from v1.0 — many no longer apply (v1.0 has shipped); reviewed at next milestone. -->

- **`recoverFromSeed()` key-overwrite bug fix** — HIGH-severity per CONCERNS.md but security-architecture changes are out of scope; deferred to FUTURE-ARCH-04
- **Riverpod 3.x upgrade** — confirmed `analyzer` version conflict with `json_serializable` (deferred to FUTURE-TOOL-01)
- **`sqlite3_flutter_libs` adoption** — SQLCipher conflict; actively rejected by CI guardrail
- **Removal of historical deprecated documentation** — deprecated *code* is deleted; deprecated *doc entries* (e.g., MOD-009 index entry) remain as historical record
- **DCM (paid) audit pipeline upgrade** — deferred to FUTURE-ARCH-03

<details>
<summary>v1.0 Out of Scope (archived — most no longer apply post-shipment)</summary>

- **New feature modules** (MOD-005 OCR, MOD-007 Analytics expansion, MOD-013 Gamification) — feature work was paused for the cleanup initiative; **lifted now that v1.0 has shipped**
- **User-visible behavior changes** — strict pure refactor for v1.0; v1.1+ may include user-visible changes
- **API/database breaking changes** — held backward-compatible during cleanup; v1.1+ may revisit
- **Performance optimization as a goal** — was not a v1.0 target
- **Security-architecture changes** — the 4-layer encryption stack was treated as fixed; security cleanup limited to enforcing existing rules
- **Per-phase doc updates** — v1.0 used centralized sweep at Phase 7 to avoid churn

</details>

## Context

- **Current state (post-v1.1):** Codebase Cleanup Initiative shipped 2026-04-29; Happiness Metric & Display shipped 2026-05-05. Schema is now v16 with unipolar positive satisfaction defaults. HomePage and AnalyticsScreen consume the v1.1 Joy metric contracts. Coverage threshold remains 70% (lowered from 80% per Phase 8 amendment; FUTURE-TOOL-03 to revisit).
- **Codebase map:** `.planning/codebase/` was generated 2026-04-25 (`/gsd-map-codebase`). Contents: ARCHITECTURE.md, STACK.md, STRUCTURE.md, CONVENTIONS.md, INTEGRATIONS.md, TESTING.md, CONCERNS.md. **Note:** Map predates the v1.0 cleanup and v1.1 feature milestone; refresh via `/gsd-map-codebase` or `/gsd-scan` before next milestone planning.
- **Tech stack:** Flutter, Riverpod 2.4+ (`@riverpod` code-gen), Freezed, Drift + SQLCipher, GoRouter, flutter_localizations (intl 0.20.2 pinned), Mocktail (replaced mockito in v1.0)
- **Active CI guardrails:** `import_guard` (custom_lint), `riverpod_lint`/`custom_lint`, `coverde` per-file ≥70% with `--deferred` mechanism (10 explicit exceptions), `sqlite3_flutter_libs` rejection, `very_good_coverage@v2` ≥70% global, `build_runner` clean-diff
- **Coverage:** Global ~74.6% (post-cleanup); 164 cleanup-touched files at 70%+; 10 deferred-list files below 70% (FUTURE-TOOL-03 review trigger)
- **Known issues / debt carried forward:** 1 Phase 11 human/device UAT verification item; 2 INFO-level analyzer warnings in `shadow_books_provider_characterization_test.dart`; pre-existing MOD-numbering drift in MOD-002/006/007/008 internal headers; ARCH-008 cites ADR-006 instead of ADR-007 (FUTURE-DOC); doc-sweep verifiers exist but not in CI; 12 architecture tests run only transitively via coverage job; Phase 03/06/08 missing canonical VERIFICATION.md (substitute evidence exists); Phase 02/04 missing VALIDATION.md; Phase 07 `nyquist_compliant: false`
- **Why next:** v1.1 completed the Joy metric/display milestone. Next-wave candidates: release-readiness QA, MOD-005 OCR, family sync hardening, strict family analytics consent (`FAMILY-V2-03`), or documentation/tooling guardrail cleanup before a user-facing v1 release.

## Constraints

- **Tech stack:** Flutter / Dart; intl 0.20.2 pinned; `sqlcipher_flutter_libs` (not `sqlite3_flutter_libs`); Mocktail (mockito removed in v1.0)
- **Quality gates (permanent):** `flutter analyze` MUST be 0 issues; `dart run custom_lint --no-fatal-infos` 0 errors; `import_guard` 0 violations; `riverpod_lint` 0 violations; per-file coverage ≥70% on cleanup-touched files (with `--deferred` for 10 exceptions); global coverage ≥70%; `build_runner` clean-diff; `sqlite3_flutter_libs` rejection
- **Coverage threshold:** Active 70% (lowered from 80% on 2026-04-28 per Phase 8 amendment; FUTURE-TOOL-03 to revisit)
- **Documentation:** ADRs are append-only after status `✅ 已接受`; new context appended via `## Update YYYY-MM-DD: <topic>` at file end
- **Architecture:** 5-layer Clean Architecture with "Thin Feature" rule, structurally enforced by `import_guard`
- **Internationalization:** All UI text via `S.of(context)`; ARB key parity locked across ja/zh/en; `flutter gen-l10n` must succeed without warnings

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Audit-driven (no manual issue list) | Codebase too large for memory-based enumeration | ✓ Good — 26 baseline findings; 50 resolved with no regressions (v1.0) |
| Hybrid audit (tooling + AI agent) | Tooling catches mechanical issues; AI catches semantic/structural | ✓ Good — both surfaced findings the other missed (v1.0) |
| Severity-ordered phases (CRITICAL → LOW) | Architecture-breaking violations before polish | ✓ Good — no rework cycles (v1.0) |
| Strict behavior preservation (pure refactor) | Lowers blast radius; allows regression-style verification | ✓ Good — characterization + golden tests caught regressions early (v1.0) |
| ≥80% coverage on refactored files | Without test net, refactor regressions go silent | ⚠️ Revisit — global 74.6% at v1.0 close; threshold lowered 80→70% (FUTURE-TOOL-03) |
| New feature work paused (v1.0) | Prevents conflicts; ensures cleanup completes | ✓ Good — initiative shipped in 4 days without merge conflicts |
| Delete deprecated code (MOD-009 references) | Dead weight gets copy-pasted into new modules | ✓ Good — MOD-009 references gone from `lib/` (v1.0) |
| Phase 5 MEDIUM guardrails | MEDIUM cleanup needs automated regression guards | ✓ Good — service-name collision, ARB parity, hardcoded-CJK, MOD-009, MEDIUM-closure scanners now gate regressions (v1.0) |
| Centralized doc sweep (not per-phase) | Doc churn during refactor is wasted effort | ✓ Good — single Phase 7 sweep aligned all docs (v1.0) |
| Audit re-run as final gate (zero violations) | Without programmatic exit criterion, "done" becomes negotiable | ✓ Good — REAUDIT-DIFF.json `open_in_baseline=0` is the close signal (v1.0) |
| Mocktail big-bang migration (HIGH-07) | CI-generated `*.mocks.dart` strategy added complexity for marginal benefit | ✓ Good — 13 fixtures migrated; mockito removed (v1.0) |
| Coverage threshold 80→70% (Phase 8) | Post-cleanup global coverage at 74.6%; raising bar would block close on baseline-fixable items | ⚠️ Revisit — FUTURE-TOOL-03 review trigger documented |
| Per-file coverage `--deferred` mechanism | 10 files below 70%; raising them in-scope was substantive | ⚠️ Revisit — FUTURE-TOOL-03 |
| Smoke-test execution deferred to v1 release | Owner-driven release gate, not cleanup-initiative gate | — Pending — FUTURE-QA-01 |
| ADR-011 v1.1 amendment with 4-layer narrative | Honest documentation pattern: surface adaptations explicitly | ✓ Good — commit-level traceability preserved (v1.0) |

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
*Last updated: 2026-05-05 after v1.1 milestone archive — see `.planning/MILESTONES.md` and `.planning/milestones/v1.1-*.md` for shipped traceability*
