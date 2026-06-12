---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: 多币种支持
status: ready_to_plan
stopped_at: Phase 40 complete (6/6) — ready to discuss Phase 41
last_updated: 2026-06-12T11:25:04.481Z
last_activity: 2026-06-12 -- Phase 40 execution started
progress:
  total_phases: 3
  completed_phases: 7
  total_plans: 252
  completed_plans: 6
  percent: 233
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-12 after v1.6 milestone)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations
**Current focus:** Phase 41 — 汇率服务 (exchange rate service)

## Current Position

Phase: 41
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-12

Progress: [░░░░░░░░░░] 0%

## Last Milestone Snapshot (v1.6)

- **Phases:** 4 (36-39), **Plans:** 27
- **Duration:** 2026-06-07 → 2026-06-08 execution; quick-task hardening through 2026-06-12
- **Audit Status at Close:** `tech_debt` — accepted (27/27 requirements, 4/4 phases `passed`, 6/6 seams, 10/10 E2E flows; W1+W2 closed at close via 260612-daz; suite 2588/2588 green)
- **Outcome:** Placeholder 4th nav tab → complete family shopping list; three-layer privacy enforcement (use case + tracker + receiver); schema v19→v20; 54 goldens
- **Tag:** `v1.6`, schema at v20

## Previous Milestone Snapshots

- **v1.5** (5 phases 31-35, 24 plans, `tech_debt`) — 文案与配色统一; ADR-019 "Sakura Mochi × Wakaba" palette
- **v1.4** (7 phases 24-30, 29 plans, `tech_debt`) — 列表功能 kakeibo-style List tab
- **v1.3** (6 phases 18-23, 47 plans, `tech_debt`) — 迭代帐本输入 single-screen voice entry
- **v1.2** (5 phases 13-17, 37 plans, `tech_debt`) — Happiness Metric Refresh (ADR-016, Σ joy_contribution)
- **v1.1** (4 phases 9-12, 40 plans, `known_debt`) — Happiness Metric & Display
- **v1.0** (8 phases 1-8, 48 plans, `passed`) — Codebase Cleanup Initiative

## Accumulated Context

### Roadmap Evolution

- v1.7 roadmap first written 2026-06-12 as 6 phases (40-45) following the research A→F build order
- v1.7 roadmap revised 2026-06-12 to 3 phases (40-42) — user-directed consolidation merging data+domain+sync into Phase 40; infrastructure client+use cases into Phase 41; presentation+voice into Phase 42 (voice as a parallel wave inside the phase). Mirrors the v1.6 consolidation precedent (7→4)

### v1.7 Pre-Implementation Decisions (locked by research)

- **Rate cache storage:** Drift `exchange_rates` table (not SharedPreferences) — queryable, encrypted, offline-fallback SQL; explicit `CREATE INDEX` in both `onCreate` and `onUpgrade`
- **Infrastructure directory:** `lib/infrastructure/exchange_rate/` (not `currency/`) — mirrors `sync/` naming convention
- **Rate precision:** store `exchangeRate` as `TextColumn` (string, full precision) — NOT `RealColumn`; prevents preview-vs-stored divergence on re-multiplication
- **Hash scope:** new currency fields excluded from `HashChainService.calculateTransactionHash` — existing chains stay valid
- **CNY symbol fix (Phase 40, before UI):** `NumberFormatter._getCurrencySymbol` → `'CN¥'` for CNY; controls when goldens re-baseline
- **Offline-first invariant:** `CreateTransactionUseCase` NEVER contains an HTTP call; rate is always pre-computed and passed in
- **Domain triple invariant:** if any of (`originalCurrency`, `originalAmount`, `appliedRate`) is non-null, all three must be non-null → `Result.error` on partial state
- **Edit policy:** date-change re-fetch shows toast when >1% JPY amount difference; manual-override is NOT clobbered unless user changes date after overriding
- **Phase 42 internal waves:** keypad/display wave and voice wave are independent — run in parallel inside the phase
- **`元` ambiguity:** zh locale = CNY; ja locale = JPY (bare `元`/`円` keeps existing JPY-terminator behavior unchanged)
- **KRW decimal override:** `sealed_currencies` reports subunit 100 (ISO) but display convention is 0 decimals — NumberFormatter needs a KRW special case like JPY

### Pending Todos

- Run `/gsd-plan-phase 40` to begin Phase 40 (数据与同步基础)
- Phase 40 first action: confirm `schemaVersion` in `lib/data/app_database.dart` is 20; migration must be `if (from < 21)` with `schemaVersion => 21`
- Phase 40 ADR work: check `ls docs/arch/03-adr/ADR-*.md` for current max number before writing new ADRs (must be sequential, no gaps)
- Phase 41 research flag: re-verify fawazahmed0 CDN URL for TWD at planning time (live-verified 2026-06-12 in SUMMARY.md; re-verify before implementation)
- Phase 42 design note: SmartKeyboard decimal input state machine has no codebase precedent — plan carefully before implementation; DISP-04 three-field bidirectional linked editing is the highest-complexity UI item

### Blockers / Concerns

No active blockers for v1.7. Pre-existing carried debt (unchanged):

- **v1.5 a11y UAT:** Phase 35 W1 on-device screen-reader announcement of localized ledger-chip labels — human_needed
- **v1.5 vocab residual:** `Book.survivalBalance`/`soulBalance` DB columns need future DB-migration phase before public release
- **v1.4 GAP-2:** LIST-02 `watchByBookIds` reactive stream is dead code; defer
- **v1.3 voice-flow polish backlog:** Phase 22 advisory WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03 on `voice_input_screen.dart`
- **MOD-005 OCR slot:** `ocr_review_screen.dart:54,58` hardcodes `EntrySource.manual` pending writer landing

## Deferred Items

### Items acknowledged and deferred at v1.6 milestone close on 2026-06-12

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| nyquist_gap | Phases 37/38/39 VALIDATION.md draft + `nyquist_compliant: false`; Phase 36 validated/compliant. Documentation-grade, mirrors accepted v1.2–v1.5 pattern | accept (documentation-grade) | v1.6 close |
| review_advisory | 37-REVIEW advisories: WR-02 pushedCount telemetry; IN-01 `final dynamic ledgerType`; WR-05 jsonDecode without local try/catch | defer to v1.7+ cleanup | v1.6 close |
| uat_pending | 260609-ruu (shopping form redesign): automated suite green, status "Implemented — 待真机确认" | human_needed | v1.6 close |
| security_note | Shopping note plaintext on sync wire by design; accepted threat T-q260612-04 (inbound shopping delete ungated) | accept (recorded for security ledger) | v1.6 close |
| metadata_drift | `gsd-sdk audit-open` reports 38 quick tasks as `missing` status (SUMMARY.md lack `status: complete` frontmatter). All recorded Verified in Quick Tasks table | cosmetic, no functional gap | v1.6 close |
| audit_w1_w2 | v1.6 audit W1 + W2 **fixed at close** by 260612-daz — recorded for audit-trail completeness | resolved | v1.6 close |

### Items acknowledged and deferred at v1.5 milestone close on 2026-06-02

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| uat_gap | Phase 35 W1 on-device screen-reader announcement of localized ledger-chip labels | human_needed | v1.5 close |
| a11y_backlog | IN-02: 5 sort/filter/search/clear controls in `list_sort_filter_bar.dart` still use hardcoded English `Semantics(label:)` | defer to v1.6+ a11y/i18n pass | v1.5 close |
| vocab_residual | `Book.survivalBalance`/`soulBalance` live identifiers — needs a further DB migration; explicitly out-of-scope per Research A1/D-06 | defer to a future DB-migration phase | v1.5 close |
| nyquist_gap | Phases 31/32/34/35 VALIDATION.md draft + `nyquist_compliant: false`; Phase 33 approved/compliant | accept (documentation-grade) | v1.5 close |
| test_fidelity | `list_transaction_tile_golden_test.dart` tagText:'Survival' + locale not threaded to tile (WR-01). Test-fidelity only, not user-facing | accept | v1.5 close |

### Items acknowledged and deferred at v1.4 milestone close on 2026-05-31

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| dead_code | GAP-2: LIST-02 `TransactionDao.watchByBookIds` exists but has zero consumers — reactivity via manual `ref.invalidate` | defer to v1.5+ | v1.4 close |
| nyquist_gap | Phases 25/26/27/29/30 VALIDATION.md draft + `nyquist_compliant: false`; Phase 28 approved | accept (documentation-grade) | v1.4 close |

### Items acknowledged and deferred at earlier milestones

- v1.3 close: Phase 18/21 missing VALIDATION.md; Phase 19/20 draft; Phase 22 draft + `nyquist_compliant: true`; voice-polish WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03; OCR slot reserved
- v1.2 close: Phase 13/17 missing VERIFICATION.md; 3 Nyquist drafts; `family_insight_card_test.dart` 6 failures from ARB drift
- v1.1 close: Phase 11 human UAT device/simulator verification
- v1.0 close: FUTURE-ARCH/TOOL/QA/DOC items (01..06); FUTURE-ARCH-04 `recoverFromSeed()` key-overwrite bug

## Session Continuity

Last session: 2026-06-12T08:33:10.075Z
Stopped at: Phase 40 context gathered
Resume file: .planning/phases/40-data-foundation-domain-sync/40-CONTEXT.md
