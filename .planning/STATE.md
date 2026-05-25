---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: 迭代帐本输入
status: executing
stopped_at: Phase 23 context gathered
last_updated: "2026-05-25T12:31:44.638Z"
last_activity: 2026-05-25 -- Phase 23 execution started
progress:
  total_phases: 6
  completed_phases: 5
  total_plans: 46
  completed_plans: 43
  percent: 83
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-22 — v1.3 迭代帐本输入 milestone opened)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes survival spending from soul spending
**Current focus:** Phase 23 — v1-3-cleanup-scanner-allow-lists-voice-flow-polish

## Current Position

Phase: 23 (v1-3-cleanup-scanner-allow-lists-voice-flow-polish) — EXECUTING
Plan: 1 of 8
Status: Executing Phase 23
Last activity: 2026-05-25 -- Phase 23 execution started

## Last Milestone Snapshot (v1.2)

- **Phases:** 5 (13-17)
- **Plans:** 37
- **Duration:** 2026-05-19 → 2026-05-21 (3 days)
- **Commits:** 212 (vs v1.1 tag); 521 files changed; +57,460 / -7,168 LOC
- **Audit Status at Close:** `tech_debt` — accepted (Phase 13/17 missing VERIFICATION.md; 3 VALIDATION.md drafts; documentation-grade debt only)
- **Outcome:** ADR-016 Joy migration (density → `Σ joy_contribution`); HomeHero target ring rebuild; user-configurable `monthly_joy_target` + 3-month median recommendation + fallback 50; AnalyticsScreen Variant ε with Custom Time Windows + Per-Category breakdown + Soul-vs-Survival comparison + Manual-Only Joy variant; Drift schema v17 (`entry_source`); HomeHero isolation structurally enforced
- **Tag:** `v1.2`

## Previous Milestone Snapshots

- **v1.1** (4 phases, 40 plans, 2026-05-01 → 2026-05-05, audit `known_debt` accepted) — Happiness Metric & Display
- **v1.0** (8 phases, 48 plans, 2026-04-24 → 2026-04-29, audit `passed`) — Codebase Cleanup Initiative

## v1.3 Phase Map

| Phase | Name | Requirements | Depends On |
|-------|------|--------------|------------|
| 18 | Shared Details Form Foundation | INPUT-03, INPUT-04, EDIT-01, EDIT-02 | — (foundation) |
| 19 | Manual One-Step + Keypad Polish | KEYPAD-01, INPUT-01 | Phase 18 |
| 20 | Voice Number Parser (zh + ja) | VOICE-01, VOICE-02, VOICE-03 | — (parallel-safe with 19) |
| 21 | Voice Category Resolver Level-2 Enforcement | VOICE-04, VOICE-05, VOICE-06 | Phase 20 |
| 22 | Voice One-Step Integration + Record Button UX | INPUT-02, REC-01, REC-02 | Phases 18, 20, 21 |

Coverage: 15/15 v1.3 requirements mapped, 0 unmapped.

## Accumulated Context

### Roadmap Evolution

- Phase 23 added: v1.3 cleanup: scanner allow-lists + voice flow polish

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. v1.0 + v1.1 + v1.2 decisions captured there with outcomes.

v1.3 decisions to date:

- 5-phase split chosen over 4-phase: separates voice number parser (Phase 20) from voice category resolver (Phase 21) — different testing surfaces (state-machine corpus vs database resolution), and isolates the voice integration phase (22) so it consumes stable parser + resolver outputs.
- Phase 18 ships first as foundation — INPUT-03 shared widget unblocks INPUT-01 (manual one-step), INPUT-02 (voice one-step), and EDIT-01/02 (edit-from-list path).
- Phase 20 deliberately UI-independent — voice parser strengthening can start in parallel with Phase 19, both feed into Phase 22 integration.

### Pending Todos

(None — ready to plan Phase 18 via `/gsd:plan-phase 18`.)

### Blockers / Concerns

No active blockers. Carried-forward debt (cross-milestone):

- **FUTURE-TOOL-03** *(coverage-baseline-review)*: Review 70% coverage threshold after v1.2 close (now triggered)
- **FUTURE-QA-01** *(smoke-test-owner-driven)*: Owner runs smoke tests before v1 release
- **FUTURE-DOC-01..06** *(documentation drift)*: 6 doc-related items from v1.0 close
- **FUTURE-ARCH-04** *(security)*: `recoverFromSeed()` key-overwrite bug fix (held — security architecture out of scope per long-term project rule)
- **v1.1 verification debt:** Phase 11 device/simulator UAT for AnalyticsScreen month chip + pull-to-refresh (human_needed)
- **v1.2 verification debt:** Phase 13 + 17 missing VERIFICATION.md (live code wired + integration-verified at milestone close; per-phase verifier artifact never run)
- **v1.3 verification debt:** Phase 20 Plan 20-08 device verification deferred (VOICE-02-DEVICE-VERIFY) — 8 anchor cases on physical iPhone/Android (zh: 2204 continuous, 1840 intra-pause merge, 1800 false-merge regression; ja: にせんにひゃくよん→2204, せんはっぴゃく+よんじゅう円→1840, 一万二千→12000; sanity: record button stays lit across finals + ManualOneStepScreen carries correct initialAmount). Resume via `/gsd:verify-work 20` after device run, or carry into Phase 22 if not resolved by milestone close. See `.planning/phases/20-voice-number-parser-zh-ja/20-08-SUMMARY.md` for tuning levers if cases fail (`_windowDuration`, restartListen, lexical-gate normalize).
- ~~**v1.3 scanner regressions (Phase 20)** *(VOICE-SCANNER-ALLOWLIST)*: cleared 2026-05-24 (commit `f04b978`). Added 3 Phase 20 NLP lexicon files to `hardcoded_cjk_ui_scan` allow-list + 8 corpus-test `// ignore: avoid_print` entries to `stale_suppressions_scan` allow-list. All 45 architecture tests pass; total project failures restored to 11 (= pre-Phase-20 baseline).~~

**Phase 20 verification verdict:** `PASS_WITH_DEBT` (5/5 SCs verified at parser/corpus layer; VOICE-SCANNER-ALLOWLIST cleared; only VOICE-02-DEVICE-VERIFY remains open). See `.planning/phases/20-voice-number-parser-zh-ja/20-VERIFICATION.md` (commit `c3e2069`).

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260518-kyr | Fix soul stats and monthly favorite not refreshing after new soul ledger entry | 2026-05-18 | 7f216e7 | Verified | [260518-kyr-fix-soul-stats-and-monthly-favorite-not-](./quick/260518-kyr-fix-soul-stats-and-monthly-favorite-not-/) |
| 260518-pf5 | Home polish Bucket A — typography spacing, ledger bar color, caption removal, family invite i18n, tx display, analytics spacing | 2026-05-18 | 5b7b6ee | Verified (3/6 PASS round 1; remaining 3 items reworked in pf6) | [260518-pf5-home-polish-typography-spacing-ledger-ba](./quick/260518-pf5-home-polish-typography-spacing-ledger-ba/) |
| 260518-v4v | Home polish Round 2 — Best Joy Variant A (Pencil mock) + r2 flat-layout tweak, recent-tx soul color + icon reposition, home SizedBox 16→24 for analytics parity | 2026-05-19 | e142f4f | Verified | [260518-v4v-home-polish-round-2-best-joy-variant-a-r](./quick/260518-v4v-home-polish-round-2-best-joy-variant-a-r/) |
| 260522-fj5 | 悦己充盈卡片 UI 修复 — info icon 位置、小确幸数字右移、目标 default 50→100、圆环中心不显示目标、繁体→简体、内环目标固定 10、外环颜色过渡修复 | 2026-05-22 | c90ef9a | — (28 golden diffs pending human re-baseline) | [260522-fj5-ui-7-info-icon-50-100-10](./quick/260522-fj5-ui-7-info-icon-50-100-10/) |

## Deferred Items

### Items acknowledged and deferred at v1.2 milestone close on 2026-05-21

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| verification_gap | Phase 13 (`ADR-016 Backend Foundation`) lacks 13-VERIFICATION.md; live code wired and integration-verified via Phase 14 transitively + audit integration check at close | accept (documentation-grade) | v1.2 close |
| verification_gap | Phase 17 (`Manual-Only Joy Sub-Metric`) lacks 17-VERIFICATION.md; live code wired and integration-verified at close | accept (documentation-grade) | v1.2 close |
| nyquist_gap | Phase 13/14/17 VALIDATION.md status: draft, `nyquist_compliant: false`, `wave_0_complete: false`; mirrors v1.0 FUTURE-DOC-06 pattern | accept (FUTURE-DOC equivalent) | v1.2 close |
| test_debt | 6 pre-existing test failures in `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` caused by Phase 15 commit `8d5f136` (`今月、` prefix dropped from `analyticsFamilyHighlightsSentence`); does NOT break any v1.2 user-observable flow; documented in Phase 16 `deferred-items.md` | accept (re-baseline test strings in next milestone) | v1.2 close |
| forward_compat | `EntrySource.ocr` literal accepted by schema v17 CHECK constraint and by DAO filter, but no production write site stamps `EntrySource.ocr` yet (consistent with MOD-005 OCR being a later module) | reserved (will be writer-claimed by MOD-005) | v1.2 close |
| metadata_drift | `gsd-sdk audit-open` reports 3 quick tasks (`260518-kyr`, `260518-pf5`, `260518-v4v`) as `missing` status while STATE.md confirms all 3 Verified with commit refs; tool reads internal slug metadata not STATE.md table | cosmetic, no functional gap | v1.2 close |

### Items acknowledged and deferred at v1.1 milestone close on 2026-05-05

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| verification_gap | Phase 11 `11-VERIFICATION.md` human UAT: run AnalyticsScreen on device/simulator and exercise month chip + pull-to-refresh on real app data | human_needed | v1.1 close |

### Items acknowledged and deferred at v1.0 milestone close on 2026-04-29

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| FUTURE-ARCH-01 | Drive `CategoryLocaleService` from ARB files (eliminate 735-line static map) | v2 backlog | v1.0 close |
| FUTURE-ARCH-02 | Replace residual committed `*.mocks.dart` with full Mocktail (largely closed in Phase 4) | v2 backlog | v1.0 close |
| FUTURE-ARCH-03 | Upgrade audit pipeline to DCM (paid) | v2 backlog | v1.0 close |
| FUTURE-ARCH-04 | Fix `recoverFromSeed()` key-overwrite bug (security-architecture) | v2 backlog | v1.0 close |
| FUTURE-TOOL-01 | Add `riverpod_lint` 3.x once `json_serializable` analyzer conflict resolves upstream | v2 backlog | v1.0 close |
| FUTURE-TOOL-02 | Drift-column unused-detection custom Dart script | v2 backlog | v1.0 close |
| FUTURE-TOOL-03 | Coverage-baseline review (raise uniformly to 80% or split per-area) | v2 backlog | 2026-04-28 (Phase 8 amend) |
| FUTURE-QA-01 | Owner-driven smoke-test execution before v1 release | v2 backlog | 2026-04-28 (Phase 8 close) |
| FUTURE-DOC-01 | MOD-numbering drift in MOD-002/006/007/008 internal headers | v2 backlog | v1.0 close |
| FUTURE-DOC-02 | ARCH-008 ADR-006 → ADR-007 citation drift | v2 backlog | v1.0 close |
| FUTURE-DOC-03 | Wire doc-sweep verifiers into CI | v2 backlog | v1.0 close |
| FUTURE-DOC-04 | Backfill 02-VALIDATION.md + 04-VALIDATION.md | v2 backlog | v1.0 close |
| FUTURE-DOC-05 | Backfill 03/06/08-VERIFICATION.md (substitute evidence exists) | v2 backlog | v1.0 close |
| FUTURE-DOC-06 | /gsd-validate-phase 07 (`nyquist_compliant: false`) | v2 backlog | v1.0 close |
| Tech-debt nit | 2 INFO-level analyzer warnings in `shadow_books_provider_characterization_test.dart` (lines 57, 73) | accept | v1.0 close |
| Tech-debt nit | `amount_display.dart` absent from `cleanup-touched-files.txt` (Plan 08-04 deferred-items.md) | accept | v1.0 close |

**v1.1-deferred items (subsumed into v1.2 active scope and shipped):**

- HAPPY-V2-01..03 → shipped in Phases 16, 15, 17 respectively
- STATSUI-V2-01 → shipped in Phase 16
- TOOL-V2-02 → shipped in Phase 14
- FAMILY-V2-01..03 → still v2 backlog (explicitly out of v1.2 scope; candidate for next milestone)
- TOOL-V2-01 (fl_chart 1.x) → still v2 backlog

## Session Continuity

Last session: 2026-05-25T10:46:09.394Z
Stopped at: Phase 23 context gathered
Resume file: .planning/phases/23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish/23-CONTEXT.md

**Planned Next:** Run `/gsd:verify-work 20` to produce the phase verification artifact, then advance to Phase 21 (Voice Category Resolver Level-2 Enforcement).

## Operator Next Steps

- Run `/gsd:verify-work 20` to verify Phase 20 against VOICE-01/VOICE-02/VOICE-03 requirements (verifier will flag the deferred Plan 20-08 device run as a verification gap — accept or clear via device test).
- Optional: clear `VOICE-02-DEVICE-VERIFY` device verification debt by running the 8 anchor cases on a physical iPhone/Android (script in `.planning/phases/20-voice-number-parser-zh-ja/20-08-SUMMARY.md`).
- Then advance: `/gsd:discuss-phase 21` → `/gsd:plan-phase 21` → `/gsd:execute-phase 21`.
- Backlog (no longer blocking): Phase 18 (Shared Details Form Foundation) — re-evaluate whether v1.3 still needs it given Phase 20's parallel-safe completion.
