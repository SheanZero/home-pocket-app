---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: 多币种支持
status: verifying
stopped_at: Completed 42-09-PLAN.md (last plan; phase ready_for_verification)
last_updated: "2026-06-13T04:05:17.754Z"
last_activity: 2026-06-13
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 20
  completed_plans: 20
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-12 after v1.6 milestone)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations
**Current focus:** Phase 42 — entry-ui-display-voice

## Current Position

Phase: 42 (entry-ui-display-voice) — EXECUTING
Plan: 9 of 9
Status: Phase complete — ready for verification
Last activity: 2026-06-13 - Completed quick task 260613-mgc: 修改外币编辑交互

Progress: [███████░░░] 65%

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260613-mgc | 修改外币编辑交互（头部金额点击弹现有键盘编辑；原币金额卡上移至分类卡前，仅留汇率+日元） | 2026-06-13 | 03a041d7 | [260613-mgc-foreign-currency-edit-ui](./quick/260613-mgc-foreign-currency-edit-ui/) |

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

Last session: 2026-06-13T04:05:17.751Z
Stopped at: Completed 42-09-PLAN.md (last plan; phase ready_for_verification)
Resume file: None

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 41 P01 | 6min | 2 tasks | 6 files |
| Phase 41 P02 | 5min | 2 tasks | 2 files |
| Phase 41 P03 | 2min | 2 tasks | 3 files |
| Phase 41 P04 | 6min | 3 tasks | 13 files |
| Phase 41 P05 | 7min | 2 tasks | 4 files |
| Phase 42 P01 | ~18min | 2 tasks | 5 files |
| Phase 42 P02 | 7min | 1 tasks | 2 files |
| Phase Phase 42 P03 P03 | ~4min | 1 task tasks | 3 files files |
| Phase 42 P04 | 25m | 2 tasks | 7 files |
| Phase 42 P05 | 10min | 2 tasks | 6 files |
| Phase 42 P06 | ~12min | 2 tasks | 5 files |
| Phase 42 P07 | ~18min | 2 tasks | 9 files |
| Phase 42 P08 | ~35 min | 2 tasks | 6 files |
| Phase 42 P09 | 13min | 2 tasks | 9 files |

## Decisions

- [Phase 42]: 42-01: Wave 0 RED scaffolds (5 test files) lock Phase 42 acceptance contracts. `create_transaction_currency_test` is GREEN-on-arrival (Phase 40 shipped the create triple) — kept as the SC-5 7415 regression guard, NOT fabricated RED; the RED half of SC-5 plumbing lives in `update_transaction_currency_test` (compile-fails on not-yet-existing UpdateTransactionParams currency fields → plan 42-03). Voice corpus asserts `VoiceParseResult.detectedCurrency` (RED → 42-04); `AmountInputController` (RED → 42-05); `CurrencyLinkedEditFields` (RED → 42-09). D-08 truncation asserted as string op not rounding (0.99→0, 50.50→50, 50.567→50.56)
- [Phase ?]: 41-01: ExchangeRateRepository extended with findLatestNonManual (D-07), deleteOlderThan (D-09 TTL), findAll (D-10); TTL delete uses UtcEpochDateTimeConverter().toSql() before isSmallerThanValue (TypeConverter-aware)
- [Phase ?]: 41-02: connectivity_plus ^7.1.1 added (D-05 gate); flutter pub get clean, all pins intact (file_picker 11.0.2 / package_info_plus 9.0.1 / share_plus 12.0.2 / win32 5.15.0 / intl 0.20.2 / sqlcipher 0.6.8); iOS debug build human-verified green (no sqlite3 symbol conflict)
- [Phase ?]: 41-03: ExchangeRateApiClient three-source fallback (Frankfurter→fawazahmed0 jsDelivr→Cloudflare); 404/timeout/non-200 route onward, all-fail throws; rate inversion 1/raw toStringAsPrecision(7); actualRateDate surfaces weekend/holiday (RATE-05); RateResult sealed union (5 variants) + RateSignal/RateResultWithSignal
- [Phase 41]: 41-04: ExchangeRateCacheService cache-first orchestration (D-01/D-03/D-05/D-06/D-07/D-08/D-09), getRate never throws; GetExchangeRateUseCase adds ADR-022 D-02 dialog/D-03 toast + RATE-04 manual override; BackupData.exchangeRates D-10 export+import; SC-5 verified (0 HTTP in accounting)
- [Phase ?]: 41-05: Three @riverpod providers wired (appExchangeRateApiClient/CacheService/GetExchangeRateUseCase); build_runner regenerated .g.dart; full suite 2705/2705 GREEN, analyze 0, architecture 47/47; SC-5 holds. Phase 42 can ref.watch(appGetExchangeRateUseCaseProvider). Fixed 2 carry regressions (logging-privacy scanner false-positive in api_client; backup characterization test missing appExchangeRateRepositoryProvider override)
- [Phase ?]: 42-02: Per-currency decimals routed through intl currencyFractionDigits via single shared helper currencyFractionDigitsFor(); subunitToUnitFor=pow(10,n) so BHD/JOD/KWD=3 yields 1000; KRW kept explicit 0-decimal (T-42-03); unknown code falls back to intl DEFAULT 2 (T-42-02); convertToJpy() byte-unchanged (ADR-020 single conversion site)
- [Phase 42]: 42-03: UpdateTransactionParams gains the currency triple; execute() coalesces from seed (EDIT-02), recomputes JPY via single-site convertToJpy() (ADR-020) only for foreign rows, no rehash (ADR-021, prevHash/currentHash frozen). Extracted shared validateCurrencyTriple() into currency_conversion.dart; CreateTransactionUseCase refactored to reuse it (removed ~50 dup lines + dead _iso4217). update_transaction_currency_test GREEN; 56/56 use-case tests green; analyze 0.
- [Phase 42]: 42-04: Voice currency detection — shared NumeralStateMachine.detectCurrencyToken (longest-first leftmost-wins scan over VoiceCurrencySuffixes.all) returns the token SEPARATELY from parse(), so the integer-amount path is byte-identical (T-42-07). VoiceCurrencySuffixes.tokenToIso maps zh 美元/欧元/英镑/港币/澳元/加元 + ja ドル/ユーロ/ポンド/香港ドル/豪ドル → ISO. VoiceParseResult gains nullable detectedCurrency (null=JPY-native, Pitfall 1 — no rate-fetch). ParseVoiceInputUseCase._detectCurrency locale-routes + resolves bare 元 by locale (zh→CNY, ja→JPY-native→null) via bareYuanToken const (keeps use case out of hardcoded_cjk_ui_scan). _extractKeyword strips new tokens (5美元的咖啡→咖啡, T-42-08). currency_detection_test GREEN (16); 400/400 voice + CJK-scan + analyze 0. Form surfacing/rate-fetch deferred to 42-09.
- [Phase 42]: 42-05: AmountInputController truncates-not-rounds decimals on currency switch (D-08, string op)
- [Phase 42]: 42-06: CurrencySelectorSheet (JPY-pinned, code/name search, 'more' full-ISO, flag+symbol+code+name 48dp rows, accentPrimary selection) + non-persisted session recentCurrencyProvider (LRU, JPY excluded from reorder). Common-zone names localized in ARB; long-tail ISO+English. Goldens mask flag cell (6 macOS baselines). Sheet wiring to SmartKeyboard is 42-08.
- [Phase 42]: 42-07: ConversionPreviewPanel (DISP-01) consumes P41 appGetExchangeRateUseCaseProvider via keyed conversionRateProvider(currency,date,amount); main row ≈¥{jpy} via single-site convertToJpy() (ADR-020, matches persisted 7415), sub-row {CODE} 1 = ¥{rate} · {date}. In-place fixed-height skeleton kConversionPreviewBlockHeight=56 (D-04 no-jump). Warning-amber staleness label for RateFallback (cached) OR fetched.actualDate≠txDate (weekend, D-05) — amber reserved. RateSignal D-02 dialog/D-03 toast surfaced via ref.listen→onSignal callback, never ref.watch (host renders in 42-08). JPY-guarded (assert, CURR-04). RateUnavailable/error → mandatory-rate prompt (P41 D-08). 4 new ARB keys ja/zh/en; 14 tests + 6 macOS goldens green; analyze 0. Host mounting is 42-08.
- [Phase ?]: 42-08: foreign triple resolved via the preview's keyed conversionRateProvider so persisted JPY == previewed JPY (single convertToJpy site, ADR-020)
- [Phase ?]: 42-08: onSignal is a documented no-op on the entry screen (no previousRate so no D-02/D-03 signal); full ADR-022 dialog/toast UX is 42-09
- [Phase ?]: 42-09: JPY edit row is read-only derived (ADR-022 D-01); original × rate → JPY only (no bidirectional loop)
- [Phase ?]: 42-09: D-02/D-03 date-change semantics colocated in CurrencyLinkedEditFields (owns the original amount for the JPY delta)
- [Phase ?]: 42-09: hand-editing the rate flips manualOverride=true (next date change → D-02 dialog vs D-03 toast)
- [Phase ?]: 42-09: CurrencyEditStrings null-safe l10n resolver keeps the delegate-less Wave-0 RED harness renderable
