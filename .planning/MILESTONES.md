# Milestones — Home Pocket

## v1.9 语音类目与商家识别系统重构（解耦 · 交叉验证 · 日本商家库） (Shipped: 2026-06-25)

**Shipped:** 2026-06-25
**Phases:** 49-52 (4 phases, 22 plans) — merchant data foundation (49) + decoupled recognizers (50) + cross-validation & ledger rework (51) + recognition UX & English voice (52)
**Duration:** 2026-06-23 → 2026-06-24 phase execution, closed 2026-06-25 (git range `v1.8..HEAD` = 195 commits, 459 files, +46,943 / −9,819 LOC — includes the post-v1.8 single-page voice-entry redesign quick-task series (260622-nhs R1–R8, 260623-0cj numpad) alongside the Phase 49-52 recognition rebuild)
**Tag:** `v1.9` · schema **v21→v22** (Phase 49 only) · drift stays **2.31.0** (no bump) · `sqlcipher_flutter_libs` 0.6.8 · **no new heavy deps**
**Audit Status at Close:** `tech_debt` — milestone goal achieved (20/20 requirements satisfied, 0 orphaned; 4/4 phases verified — 49:5/5, 50:4/4, 51:14/14, 52:7/7; 5/5 cross-phase integration seams wired; 4/4 E2E flows complete at the logic layer). The one material divergence the audit flagged — the recognition confidence band hidden in production after UAT (**T-01**) — was **resolved before close** (band re-enabled, commit `f00b1487`), with the stale UAT note corrected (**T-02**). Residual is documentation/confirm-only: T-03 (two learning loops co-fire at save — pre-v1.9, not a regression), T-04 (draft-Nyquist VALIDATION for 49/51/52), T-05 (SUMMARY frontmatter under-tagging on 5 IDs). Suite **3352/3353** green (per-phase: 51 ran 3270/3270, 52 ran 3353 with the chips test), `flutter analyze` 0. See `.planning/milestones/v1.9-MILESTONE-AUDIT.md`.
**Known deferred items at close:** the pre-close artifact audit flagged 34 quick-tasks; the **4 genuinely-incomplete v1.3-era voice items (260526 k92/l0o/n7b/pg6) were RESOLVED as superseded-by-v1.9** before close (commit `fc944d86`) — their target pipeline (`voice_category_resolver.dart`, the manual/voice tab UI, `voice_input_screen.dart`) was deleted/rebuilt by this milestone + 260622-nhs, and pg6's orphan-key contract is a live Phase-52 invariant. The remaining 30 are cosmetic metadata-drift (verified-done tasks missing `status:` frontmatter), acknowledged in `.planning/STATE.md` Deferred Items §v1.9.

### Delivered

The voice ledger pipeline was re-architected so a user can speak one sentence (zh/ja/en) and have it booked as the **right category + the right ledger (日常/悦己)**, backed by a real Japanese merchant database. v1.9 is a layered **decoupling + arbitration insert**, not a rewrite: the existing pipeline already had the right skeleton (a coordinating use case, a category resolver, merchant lookup, two learning tables, a DB-backed ledger resolver) but lacked **independence** (merchant matching was embedded in the text parser and short-circuited the category resolver) and **arbitration** (nowhere for two independent verdicts to cross-check). The milestone split the pipeline into two mutually non-calling pure-Dart engines — `MerchantRecognizer` and `CategoryRecognizer` — inserted a pure-domain `RecognitionReconciler` that arbitrates the two via an explicit none/weak/strong 3×3 truth table (keyword intent wins conflicts, merchant falls back, both-weak asks the user — never an auto-high-confidence stamp), reworked the daily/joy ledger into a **pure function of the final cross-validated category** at a single derivation site (deleting the merchant `ledgerType` short-circuit and the entire divergent `lib/application/dual_ledger/` `RuleEngine`/`ClassificationService` map), migrated the 13-entry hardcoded merchant list into a persistent encrypted Drift `merchants` table (391 Japanese merchants, schema v21→v22), and brought English voice to practical parity with zh/ja. The entry form now surfaces a qualitative 3-tier confidence band + tappable alternate chips + inline correction that teaches the KEYWORD table only — all ADR-012-safe (no accuracy %, streaks, badges, or numeric confidence).

### Key Accomplishments

1. **Japanese merchant data foundation (Phase 49)** — the 13-entry hardcoded in-memory merchant list migrated to a persistent, indexed, idempotently-seedable Drift `merchants` table (schema **v21→v22**), seeded with **391 Japanese merchants** carrying `region` + multi-locale store names + aliases + a seed-time normalized match-key + L2 `categoryId` + a non-authoritative ledger hint, designed for a 600-800 ceiling. Explicit `CREATE INDEX IF NOT EXISTS` in **both** onCreate and onUpgrade (dodging the `customIndices` decorative trap); the full migration ladder (v3→v22, v17→v22, v21→v22, fresh v22) verified against the **encrypted SQLCipher executor**, not just `NativeDatabase.memory()`. A zero-dependency `normalizeMerchantKey` (NFKC-lite fullwidth→halfwidth + kana fold + lowercase + 中黒/whitespace strip) is the single seed-time AND query-time match function, verified by a 66-assertion property + idempotency test. (MERCH-01..05)
2. **Decoupled recognizers (Phase 50)** — `MerchantRecognizer` (anchored/normalized **scored** matching — replacing the bidirectional-substring `contains||contains` with a minimum-alias-length-by-script scorer + an adversarial false-positive corpus) and `CategoryRecognizer` (unconditional, keyword-only, full **138-L2** zh+ja seed, 515 direct-seed rows) split into two **constructionally independent** engines; the merchant-priority short-circuit removed so the category engine always runs (「加油用了400块」→ fuel L2 with no merchant). Legacy `MerchantDatabase`/`LookupMerchantUseCase`/`VoiceCategoryResolver` retired (D-05). (DECOUP-01..03)
3. **Cross-validation + daily/joy ledger rework (Phase 51, one code surgery)** — a pure-domain `RecognitionReconciler` (zero I/O) arbitrates the two verdicts via an explicit none/weak/strong **3×3 truth table** written test-first as `cross_validation_test.dart` (22 cells/boundaries): agreement boosts confidence, a strong keyword beats a strong merchant (「在星巴克买了个杯子」→ 购物, cafe demoted to an alternate chip), no keyword → merchant fallback, both-weak → ask. The ledger was reworked into `CategoryService.resolveLedgerType(finalCategoryId) ?? daily` at a **single post-reconciliation site** — the merchant `ledgerType` short-circuit deleted, the entire `lib/application/dual_ledger/` retired, `category_ledger_configs` reseeded to **14 L2 overrides** (D-18 user-approved at a blocking spot-check), with three invariant gates: every reachable L2 resolves non-null (D-19), `ledgerType == resolveLedgerType(finalCategoryId)` on every path (D-20), merchant `ledgerHint` is never read for a transaction ledger (D-21). Category fill gated to the first end-of-speech final + hysteresis (partials fill amount/text live, the chip stops jittering — no new timer). (XVAL-01..03, LEDGER-01..02)
4. **Recognition UX + learning loop (Phase 52 RECUX)** — the entry form renders a **purely-visual 3-tier qualitative confidence band** (intensity by `ConfidenceBand` enum, colored by daily/joy ledger family, a11y-only Semantics, **zero painted number/%/gauge** — ADR-012-safe) + ≤3 tappable alternate-category chips + an exit chip to the full selector, appearing at resolve-on-final (D-08), clearing on selection (D-09), absent for manual entry (D-10). Inline correction was moved to a **single deferred write at confirmed save** that teaches `category_keyword_preferences` only — never the merchant table — counting both chip-tap and full-selector paths, with discard-on-abandon and null-keyword protection, and `resolvedKeyword` **write==read parity** (防 260526-pg6 orphan-key regression). The band was re-enabled in production at close (T-01). (RECUX-01..03)
5. **English voice parity (Phase 52 VEN)** — **166 lowercase English category-keyword seeds** across every zh/ja-covered L2 (paired with an en-residual lowercasing fix so they match capitalized iOS STT output), a **bounded ~30-line English number-word fallback** (one…twenty, hundred/thousand, a/an→1, 「X fifty」→X.50) that fires **only** on Arabic-digit miss + en locale + money context and **never enters the CJK numeral path**, plus English currency-word reuse and `localeId` threaded end-to-end through en-US. An isolation test proves any English utterance never leaks into the zh/ja numeral path (guards the v1.8 golden WR-04 `currentLocaleProvider`-miss class). English merchant + currency recognition verified (not rebuilt) by new recognizer cases. (VEN-01..02)
6. **Inline trilingual close-out gate (Phase 52, merge-blocking)** — a new-UI anti-toxicity sweep across band-strong / band-weak+chips / correction-open / manual-no-affordance / voice-panel × {en,ja,zh} with the **COMPLETE banned-token list** (fixing the v1.8 WR-02 incompleteness: score/streak/accuracy/正确率/連続/ストリーク/達成 + anti-shrink guard), trilingual ARB parity (equal key counts 1587/locale, no orphans, the new recognition keys present, `gen-l10n` clean, merchant names kept as Drift data not ARB), and a green full-suite + analyze — run **inline before merge**, not deferred to milestone close (the v1.7/v1.8 lesson). (RECUX-04, RECUX-05)

### Stats

- **Commits since v1.8 tag:** 195 (`v1.8..HEAD`)
- **Files changed:** 459 (+46,943 / −9,819 LOC) — includes the post-v1.8 single-page voice-entry redesign quick-task series (260622-nhs, 260623-0cj) alongside the Phase 49-52 recognition rebuild
- **Suite:** 3352/3353 green (51 ran 3270/3270; 52 ran 3353 with the chips test) · `flutter analyze` 0
- **Schema:** v21→v22 (Phase 49) · **drift** 2.31.0 (no bump) · `sqlcipher_flutter_libs` 0.6.8 · no new heavy deps
- **Tag:** `v1.9`

---

## v1.8 统计页面重设计（实用化 × 悦己情感化） (Shipped: 2026-06-22)

**Shipped:** 2026-06-22
**Phases:** 43-48 (6 phases, 32 plans) — design gate (43) + reuse-first build (44-46) + verification (47) + post-audit tech-debt cleanup (48)
**Duration:** 2026-06-15 → 2026-06-22 (git range `v1.7..HEAD` = 255 commits, 428 files, +55,226 / −17,507 LOC — includes post-v1.7 doc churn and the 06-15→06-22 analytics rebuild)
**Tag:** `v1.8` · schema stays **v21** (no migration) · fl_chart stays **^1.2.0** (no bump)
**Audit Status at Close:** `tech_debt` — milestone goal achieved (18/18 active requirements satisfied, 2 deliberately descoped at the GATE, 5/5 phases verified passed, 9/9 cross-phase integration flows wired, E2E data→shell→card→i18n complete). Both **code-grade** debt items the audit flagged (member-filter donut pull-to-refresh staleness + stale TREND-01 dartdoc) were closed inline by **Phase 48**; residual is documentation-grade only (Phase 47 draft-Nyquist, SUMMARY frontmatter drift), mirroring the accepted v1.2–v1.7 close precedent. Suite **3090/3090** green, `flutter analyze` 0, coverage 80.48%. See `.planning/milestones/v1.8-MILESTONE-AUDIT.md`.
**Known deferred items at close:** acknowledged via the pre-close artifact audit — 35 items (34 quick-task metadata-drift/voice-backlog stubs + 1 false-positive UAT flag on Phase 47, which is actually `passed`/0-pending) + Phase 47 draft-Nyquist + SUMMARY frontmatter drift; see `.planning/STATE.md` Deferred Items §v1.8.

### Delivered

The statistics/analytics page was fully overhauled — more practical and emotionally surfacing 悦己 self-spending so users feel good about spending on themselves — under the permanent ADR-012 anti-gamification contract, via a design-gate-first decomposition. **Phase 43** was a hard HTML design gate with no production code: a deep-research map of the current implementation, five HTML directions (M1–M5) each carrying an ADR-012 self-audit, four discussion rounds, and user selection of **round-5 B** (M2-derived), plus GATE-04 decisions (JOY-04 text-persistence NO-GO; an ADR-012 §4 expense-side cross-period carve-out; a locked calm-warm emotional wordlist; an fl_chart 1.2.0 per-chart affordance table). The build (Phases 44–46) was reuse-first: a domain-pure L1-category rollup helper (single source for both the donut transform and the drill subtotal), a within-month per-day cumulative trend, and one read-only category drill path — all over the existing `findByBookIds` primitive with zero new DAO/index/Drift migration (schema stays v21). `analytics_screen.dart` was rebuilt from a 739-LOC monolith into a registry-driven thin shell (176 LOC) + a `widgets/cards/` system with a single-source `_refresh()` union; HomeHero isolation (GUARD-01) holds by construction and by test. The live screen is the **round-5 B flat 5-card lineup**: within-month spend trend (pill tabs; 本月+上月 dual lines on spend, a structurally-single 本月 line on joy — zero cross-period) → category donut hero (count-up center 本月支出, 10 L1 amount-desc legend rows, full-row tap → read-only drill) → 悦己花在哪 custom stacked bar (zero fl_chart) → 小确幸 calendar heatmap (zero fl_chart) → satisfaction histogram (native fl_chart 1.2.0 `BarChartRodData.label`, Stack hack deleted), plus a group-mode `family_insight` conditional card. **Phase 47** validated it: trilingual ARB parity, a 36-case anti-toxicity sweep across all 5 cards × ja/zh/en × states, 48 macOS golden baselines authored from scratch, full suite green, and a 10/10 on-device visual UAT (locale=ja, user-approved). **Phase 48** cleared the two post-audit code-grade tech-debt items. Joy is surfaced entirely descriptively (celebrate-past: already-spent joy amount + 去向 + 满足度 distribution + calendar texture) — never ranking, target, streak, or cross-period.

### Key Accomplishments

1. **Design gate, zero production code (Phase 43)** — a deep-research map of the current `lib/features/analytics/` implementation, five HTML directions (M1–M5) spanning the 实用↔悦己 intensity axis each with an ADR-012 self-audit table, and four discussion rounds → user-selected **round-5 B** (M2-derived). GATE-04 locked the four go/no-go decisions: JOY-04 text-persistence **NO-GO** (no new ADR, stays no-Drift), an ADR-012 §4 **expense-side cross-period carve-out** (joy-side cross-period prohibition stays absolute), the **calm-warm emotional wordlist** (target/目标 scoped analytics-only; HomeHero keeps the only target ring), and an **fl_chart 1.2.0 per-chart affordance table**. Gate-exit no-Dart condition verified EMPTY.
2. **Reuse-first data layer (Phase 44)** — a domain-pure **L1-category rollup helper** (`l1AncestorOf` + `L1CategoryRollup`, the single source for both the OVW-01 donut transform and the DRILL-01 subtotal — donut can never drift from drill), a **within-month per-day cumulative trend** (replacing the deleted 6-month `MonthlyTrend`/BarChart stack), and **one read-only category drill path** — all over the existing `findByBookIds` primitive. Zero new DAO/index/Drift migration; schema stays v21.
3. **Thin shell + card registry (Phase 45)** — `analytics_screen.dart` rebuilt from a 739-LOC monolith into a **176-LOC registry-driven thin shell** + a `widgets/cards/` system, each card exposing a single-source `<card>RefreshTargets(ctx)`; the `_refresh()` union (108→12 LOC) is derived from the registry (union ⊆ analytics, zero `home/*`). **HomeHero isolation (GUARD-01) guaranteed by construction** + structural-invariant test + green `home_screen_isolation_test`; behavior preserved byte-for-byte (2925/2925, zero golden re-baseline).
4. **round-5 B 5-card lineup (Phase 46)** — within-month trend (dual spend / single joy, zero cross-period by construction) → category donut hero (count-up center, 10 L1 legend rows, full-row drill) → 悦己花在哪 custom Row+Flexible stacked bar → 小确幸 custom GridView calendar heatmap → satisfaction histogram (native fl_chart 1.2.0 `BarChartRodData.label`, Stack hack deleted) + group-mode `family_insight`; read-only `CategoryDrillDownScreen`. All descriptive celebrate-past; JOY-03/JOY-04 descoped per GATE-03.
5. **Verification (Phase 47)** — trilingual ARB parity (orphan section-header keys deleted symmetrically), a 36-case anti-toxicity sweep (5 cards × ja/zh/en × all states), **48 macOS golden baselines authored from scratch** (closing the zero-golden gap on the new charts), full suite **3057/3057** + analyze 0 + coverage 80.48%, and a blocking **10/10 on-device visual UAT** (physical iOS, locale=ja, user-approved).
6. **Post-audit tech-debt cleanup (Phase 48)** — TD-1: the member-filter donut pull-to-refresh staleness fixed by threading `donutDimensionStateProvider`'s filter through `AnalyticsCardContext` → `categoryDonutRefreshTargets` (+ a "union ⊇ card watches" completeness regression assertion); TD-2: stale `GetExpenseTrendUseCase`/`MonthlyTrend` dartdoc scrubbed from `repository_providers.dart` (+ regenerated `.g.dart`), `grep` = 0. Suite **3090/3090**, zero golden re-baseline.

### Stats

- **Commits since v1.7 tag:** 255 (`v1.7..HEAD`)
- **Files changed:** 428 (+55,226 / −17,507 LOC) — includes post-v1.7 doc churn alongside the analytics rebuild
- **Suite:** 3090/3090 green · `flutter analyze` 0 · coverage 80.48%
- **Schema:** v21 (no migration) · **fl_chart:** ^1.2.0 (no bump)
- **Tag:** `v1.8`

---

Historical record of shipped versions. Each entry links to its full archive in `.planning/milestones/`.

---

## v1.7 — 多币种支持 (Multi-Currency)

**Shipped:** 2026-06-14
**Phases:** 40-42 (3 phases, 20 plans, 28 tasks)
**Duration:** 2026-06-12 → 2026-06-13 phase execution, hardened through 2026-06-14 (git range `v1.6..HEAD` = 197 commits, 246 files, +33,923 / −2,248 LOC — includes the 2026-06-13/14 foreign-currency UI/edit/voice quick-task series and the OCR-entry-hide + continuous-entry FAB task)
**Tag:** `v1.7`
**Audit Status at Close:** `tech_debt` — milestone goal achieved (23/23 requirements satisfied, 3/3 phases verified, 6/6 cross-phase integration seams wired, E2E flow complete). All four Phase 42 human/device items passed via UAT (`42-UAT.md`, 2026-06-14, 4/4 pass, 0 issues), clearing the `human_needed` flag. The sole residual is documentation-grade Nyquist debt: all three VALIDATION.md files (Phases 40/41/42) are drafts with `nyquist_compliant: false`, while the underlying test suite is fully green at 2786/2786 and `flutter analyze` is clean. Mirrors the accepted v1.2–v1.6 close precedent. See `.planning/milestones/v1.7-MILESTONE-AUDIT.md`.
**Known deferred items at close:** acknowledged via the pre-close artifact audit — 33 quick-task metadata-drift/voice-backlog stubs + 1 stale Phase 42 verification flag (resolved by UAT) + 3-phase Nyquist documentation debt; see `.planning/STATE.md` Deferred Items §v1.7.

### Delivered

Home Pocket ledger entry now supports foreign-currency input end to end while leaving the JPY-only path byte-for-byte unchanged. On the SmartKeyboard a user taps the currency symbol beside the amount to open a JPY-first selector (common currencies re-ordered by recent use, "more" expanding the full ISO 4217 list with code/name search), or speaks the currency in zh/ja (「五十美元」/「50ドル」). The app fetches the exchange rate **for the transaction date** (historical, not today's) from a free no-key API (Frankfurter primary, fawazahmed0 fallback), caches it per (date, currency) in an encrypted Drift table, and shows a live JPY conversion preview that updates on every keypad tap and currency/rate/date change — with weekend/holiday actual-date transparency and offline fallback to the most recent cached rate. The JPY-converted integer is stored in the existing `amount` column (driving all lists/analytics/sorting unchanged); the original currency, original amount, and applied rate ride along as three nullable fields that transit family sync null-safely in both directions. Foreign rows show a secondary annotation in the list; the detail/edit view shows the full original record with a two-input/one-derived editor (original amount + rate editable, JPY read-only derived via the single conversion site — ADR-022 D-01). Saving is **never** blocked on the network. Drift schema v20→v21.

### Key Accomplishments

1. **Sync-safe multi-currency data + domain foundation** (Phase 40) — three blocking ADRs (ADR-020 rate stored as full-precision `TextColumn`; ADR-021 currency fields excluded from the hash formula so existing chains stay valid; ADR-022 date-change re-fetch / edit policy); the CNY/JPY `¥` collision fixed in `NumberFormatter` (`CN¥`, KRW 0-decimal, HK$/A$/C$/NT$/S$ disambiguation) with golden re-baseline; Drift v20→v21 migration (`exchange_rates` cache table + three nullable `transactions` columns, explicit CREATE INDEX); `Transaction` Freezed extension + `ExchangeRateDao`/repository; `TransactionSyncMapper` null-safe round-trip (new→old drops extra keys, old→new applies as JPY) + partial-triple domain invariant (`Result.error` on 1-or-2-of-3). (STORE-01..05)
2. **Offline-safe exchange-rate service** (Phase 41) — `ExchangeRateApiClient` three-source fallback (Frankfurter → fawazahmed0 jsDelivr → Cloudflare) with rate inversion, weekend/holiday `actualDate` surfacing, and SC-5 URL privacy (no user data in any URL); cache-first `ExchangeRateCacheService` (permanent historical rates, short-TTL today, never-throws); `GetExchangeRateUseCase` with `RateResult` sealed union, RATE-04 manual override, and ADR-022 D-02 dialog / D-03 toast signals; `BackupData` extended for rate export/import; `connectivity_plus ^7.1.1` added (iOS build human-verified). The never-block-save invariant is structurally enforced — zero HTTP in the accounting use cases. (RATE-01..06)
3. **Currency entry, display & voice** (Phase 42) — SmartKeyboard currency key + `CurrencySelectorSheet` (JPY-pinned, recent-use LRU session provider, full-ISO search, flag+symbol+code+name 48dp rows); per-currency decimal gate via intl `currencyFractionDigits` (D-07 cap / D-08 truncate; JPY/KRW 0-decimal); live `ConversionPreviewPanel` (single-site `convertToJpy()`, fixed-height no-jump skeleton, amber staleness label); foreign-row list annotation; two-input/one-derived edit host (ADR-022 D-01, JPY read-only); zh/ja voice currency detection (美元/欧元/英镑/港币/澳元/加元 + ドル/ユーロ/ポンド/香港ドル/豪ドル → ISO, bare 元/ドル locale-routed) flowing through the shared form. SC-5 smoke verified: USD 50 @ 148.30 → `amount=7415`, `original_currency='USD'`. (CURR-01..05, DISP-01..04, VOICE-CUR-01..03)
4. **Single conversion site + hash invariant enforced across the stack** — `convertToJpy()` (`currency_conversion.dart`) is the sole JPY computation site, consumed by create/update use cases, entry preview, edit card, voice, and list annotation with no inline `* rate` arithmetic anywhere; `calculateTransactionHash` takes only (id, JPY amount, timestamp, prevHash) — the triple is never hashed and edits never rehash (ADR-021). The sync wire boundary (`transaction_sync_mapper.dart`) validates the full triple inline and degrades partial/invalid peer payloads to JPY-native rather than persisting them.
5. **Post-phase UX hardening via quick-task series** (2026-06-13/14) — unified foreign-currency card across add/edit screens (260613-ufn), edit-interaction + date-trigger + debounce polish (260613-mgc/n5c/njf/wuv), currency-picker dedup + long-tail l10n + real symbols (260613-ohz/ote), no-trailing-zeros on integer foreign amounts (260614-dx1), voice currency-switch recognition + header-pill fix (260614-goh), and the Home recent-item refresh-after-edit bug fix (260613-wjx); plus the OCR-entry hide behind a reversible `kOcrEntryEnabled` flag + continuous-entry FAB mode (260614-iww).

### Stats

- **Commits since v1.6 tag:** 197 (docs 93, feat 42, fix 34, test 18, chore 7, style 2, revert 1)
- **Files changed:** 246 (+33,923 / −2,248 LOC)
- **Requirements:** 23/23 v1.7 requirements complete (REQUIREMENTS.md footer "21 total" was stale; the traceability table and audit both enumerate 23)
- **Drift schema:** v20 → v21 (`exchange_rates` table + 3 nullable `transactions` columns)
- **Test suite:** 2786/2786 green; `flutter analyze` 0 issues
- **ARB parity:** ja = zh = en maintained
- **New stack dep:** `connectivity_plus ^7.1.1` (iOS build verified green)
- **First external network dependency:** outbound rate queries only, no user data on the wire; fully offline-capable via cache + manual rate

### Notable Decisions

- **3-phase consolidation** (from the research 6-phase A→F build order) — data+domain+sync into Phase 40, infrastructure client+use cases into Phase 41, presentation+voice into Phase 42 (voice as a parallel wave). Mirrors the v1.6 7→4 precedent.
- **Rate stored as `TextColumn` full precision** (ADR-020), not `RealColumn` — prevents preview-vs-stored divergence on re-multiplication.
- **Currency fields excluded from the hash** (ADR-021) — existing chains stay valid; editing an amount re-derives JPY but leaves `currentHash` unchanged (advisory, intentional, not multi-currency-specific).
- **DISP-04 "bidirectional linked editing" wording VOID** — superseded by ADR-022 D-01 two-input/one-derived model (JPY read-only derived); a bidirectional implementation would have been a defect.
- **Never-block-save invariant** — rate is always pre-computed and passed in; accounting use cases contain zero HTTP.
- **Nyquist documentation debt accepted at close** — three draft VALIDATION.md files; underlying coverage exists (suite green). Consistent with v1.2–v1.6.

### Archive

- `.planning/milestones/v1.7-ROADMAP.md` — full phase details
- `.planning/milestones/v1.7-REQUIREMENTS.md` — final requirement status (23/23) + v2 backlog
- `.planning/milestones/v1.7-MILESTONE-AUDIT.md` — pre-close audit report (status: `tech_debt`)

---

## v1.6 — 购物清单 (Shopping List)

**Shipped:** 2026-06-12
**Phases:** 36-39 (4 phases, 27 plans)
**Duration:** 2026-06-07 → 2026-06-08 phase execution, hardened through 2026-06-12 (git range `v1.5..HEAD` = 369 commits, 630 files, +58,316 / −3,400 LOC — includes the post-v1.5 ADR-019 palette quick tasks and the 2026-06-09/10 shopping UX + startup-fix quick-task series)
**Tag:** `v1.6`
**Audit Status at Close:** `tech_debt` — milestone goal achieved (27/27 requirements, 4/4 phases verified `passed`, 6/6 cross-phase seams wired, 10/10 E2E flows complete; integration checker executed 32/32 cross-phase tests). The two substantive warnings the 2026-06-11 audit found — W1 (fullSync had no shopping reconcile despite the tracker comment claiming it) and W2 (receiver trusted inbound `listType` on the wire) — were **closed at milestone close** via quick task 260612-daz and re-verified (analyze 0, full suite 2588/2588 green). Residual debt is documentation-grade: draft-Nyquist docs (Phases 37/38/39 `nyquist_compliant: false`; Phase 36 validated/compliant), three 37-REVIEW advisories, one pending on-device confirm (260609-ruu form redesign). See `.planning/milestones/v1.6-MILESTONE-AUDIT.md`.
**Known deferred items at close:** 6 acknowledged (1 Nyquist, 1 review-advisory bundle, 1 UAT pending, 1 security note incl. accepted threat T-q260612-04, 1 metadata drift covering 38 stale quick-task status stubs, 1 resolved W1/W2 audit-trail entry) — see `.planning/STATE.md` Deferred Items §v1.6.

### Delivered

The placeholder 4th nav tab (待办/Todo) is now a complete family shopping list. A top segmented control switches between 公共 (public) and 私人 (private) lists — two fully independent lists with the visibility attribute immutable after creation (D6). Items carry rich optional metadata (ledger 日常/悦己, category, tags, encrypted note, quantity, estimated price) behind a name-only-required form that reuses the existing category tree, tag system, and ledger selector. The list supports tap-to-complete with animated strikethrough (completed items sort below a divider via DAO query order), chip-bar filtering (ledger/category/status, shared across segments and reset on switch), swipe-delete, long-press batch-select with select-all and batch-delete, clear-all-completed, and 3-variant empty states. Public items sync to family members through the existing E2EE family_sync pipeline with per-item attribution chips, sticky-complete merge, tombstone safety, and reactive Drift-stream delivery (no manual refresh); private items never enter the sync pipeline — enforced at the use-case boundary, the change tracker, and (since 260612-daz) the receiving end. All strings ship in ja/zh/en (ARB parity) with 54 golden baselines. Schema v19→v20.

### Key Accomplishments

1. **Encrypted, migration-safe data foundation + enforced layer boundaries** (Phase 36) — `shopping_items` Drift table (18 columns, 4 CHECK constraints, v19→v20 migration with explicit `CREATE INDEX` in onCreate+onUpgrade after CR-01 exposed `customIndices` as a no-op), reactive `ShoppingItemDao.watchByListType` (`readsFrom:`), `ShoppingItemRepositoryImpl` with note encryption at the boundary, Freezed domain models + repository interface with zero Drift imports, `import_guard.yaml` coverage for every shopping_list subdir, and `LedgerTypeSelector` promoted to `lib/shared/widgets/`. (SHOP-01, DONE-02, ITEM-03/05, SYNC-05 column)
2. **Use-case layer with a dual privacy gate + family-sync integration** (Phase 37) — six use cases mediate every mutation; public-only tracking enforced at both the use-case boundary and `ShoppingItemChangeTracker`; `listType` immutability fail-fast (D37-04); `ApplySyncOperationsUseCase` gained a `shopping_item` branch with tombstone guard + sticky-complete merge; `SyncOrchestrator` flushes shopping ops in the incremental push; reactive round-trip proven by integration test without any `ref.invalidate`. (ITEM-01/02/04, DONE-01/03, MGMT-01/02, SYNC-01/02/03/05/06)
3. **Complete gesture-safe shopping UI on a renamed nav tab** (Phase 38) — `ShoppingListScreen` + tile (dual-ledger 4px accent, attribution chip on public tiles only, animated strikethrough), filter chip bar, 3-variant empty states, batch-select chrome (selection header, floating action bar, swipe disabled via `DismissDirection.none`), create/edit form, shopping-bag tab icon, and a context-aware FAB that preserves all 6 accounting post-entry invalidations (no regression). (SHOP-02/03/04, FILT-01/02/03, MGMT-03, NAV-01/02, SYNC-04)
4. **i18n parity + pixel verification + provider smoke test** (Phase 39) — ARB key parity across ja/zh/en, zero stale 待办/Todo strings, 54 golden baselines (4 widgets × 3 locales × 2 modes, user-approved), presentation-layer reactive smoke test, 77.3% shopping-module coverage, analyze 0. (NAV-03)
5. **Post-phase UX hardening via quick-task series** (2026-06-09/10) — group filter + private chip + `ListTypeSelector` pill (260609-dnp/g8z), tile interaction + reorder-mode UX with single-mechanism `reorderBatch`→`applyOrder` contiguous re-sort (260609-ec2/pmc, 7 plans), form redesign matching the accounting entry screen (260609-ruu), AppBar title + lock-hint restyle (260609-t1t), and the iOS startup keychain-accessibility fix (260610-ss7, on-device verified).
6. **Audit-gap closure at milestone close** (260612-daz, 2026-06-12) — `FullSyncUseCase` now pushes public shopping items (required `fetchAllShoppingOps` callback + provider wiring), and the receiver drops non-public inbound shopping ops + pins `listType` on update merge, closing audit W1/SYNC-01 and W2/SYNC-02/03 with TDD; full suite 2588/2588 green.

---

## v1.5 — 文案与配色统一 (Vocabulary & Palette Unification)

**Shipped:** 2026-06-02
**Phases:** 31-35 (5 phases, 24 plans, 42 tasks)
**Duration:** 2026-05-31 → 2026-06-02 (~2 days; git range `v1.4..HEAD` = 155 commits, 550 files, +43,552 / −4,650 LOC)
**Tag:** `v1.5`
**Audit Status at Close:** `tech_debt` — milestone goal achieved (15/15 requirements, 5/5 phases verified `passed`, 6/6 cross-phase integration seams wired). The two leaks that held the initial 2026-06-01 audit at `tech_debt` — W1 (user-facing a11y Semantics labels) and W2 (internal `totalSoulTx` identifiers) — were closed by Phase 35 and independently re-verified at re-audit. Residual debt is non-blocking: one pending on-device screen-reader UAT (Phase 35 Truth 1; code grep-verified), draft-Nyquist docs (Phases 31/32/34/35 `nyquist_compliant: false`; Phase 33 approved/compliant), and the documented out-of-scope `Book.survivalBalance`/`soulBalance` DB-column carve-out (Research A1 / D-06). See `.planning/milestones/v1.5-MILESTONE-AUDIT.md`.
**Known deferred items at close:** 8 acknowledged (2 UAT/verification gaps, 1 a11y backlog, 1 vocab residual, 1 Nyquist, 1 metadata drift covering 17 stale quick-task stubs, 1 test-fidelity) — see `.planning/STATE.md` Deferred Items §v1.5.

### Delivered

Brownfield consistency refactor — no new user-facing features. The half-migrated dual-ledger vocabulary is now unified across all three locales **and** internal code identifiers, and every scattered hardcoded color is consolidated into a single semantic design-token system. Users see 日常/悦己 (zh), 日常/ときめき (ja), Daily/Joy (en) everywhere; the codebase carries one `LedgerType { daily, joy }` enum, one set of `daily*`/`joy*` ARB keys, one `AppPalette` ThemeExtension (ADR-018 "Teal Clarity"), and full dark-mode support — with no `Color(0x…)` literals, no `AppColors`/`AppColorsDark` shims, and no stale Survival/Soul vocabulary in any rendered string.

### Key Accomplishments

1. **Terminology rename across copy + code** (Phase 31) — `LedgerType` enum renamed survival→daily / soul→joy across 242 call sites; `Transaction.joyFullness` replaces `soulSatisfaction`; 25 ledger-vocab ARB key roots + zh/ja/en values rewritten to canonical 日常/悦己/ときめき/Daily/Joy; v17→v18 Drift migration (atomic stored enum-value rewrite + `soul_satisfaction`→`joy_fullness` column) with a Wave-0 raw-sqlite3 contract test; ADR-017 accepted. (TERM-01..04, TERMID-01..04)
2. **Palette exploration → selection** (Phase 32) — 5 candidate directions mined from 7 VoltAgent brand DESIGN.md refs → `home-pocket-palette.pen` with 5 schemes × 6 frames (home-hero / list / analytics × light+dark) → user selected Scheme D "Teal Clarity" (teal primary #0E9AA7, Daily teal-navy ↔ Joy gold) after rejecting all coral-anchored options; ADR-018 ratified post-selection with a full light+dark hex-per-role contract. (PALETTE-01..03)
3. **Semantic token system + dark rollout** (Phase 33) — `AppPalette` ThemeExtension built as the single source of truth encoding ADR-018; all `Color(0x…)` literals replaced; AppColors/AppColorsDark shims deleted; full dark-mode rollout via `context.palette.*` (zero `isDark` ternaries), absorbing THEME-V2-02 (D-07); 11 on-device visual items human-approved. (COLOR-01..03, THEME-V2-02)
4. **Golden re-baseline** (Phase 34) — 50 golden masters re-baselined to the teal palette + 27 new dark masters added (77 total, 34 dark), with diff-attribution confirming the palette change as the only visual delta; full suite 2281/2281 green, 79.0% filtered coverage. (COLOR-04)
5. **Residual leak closure** (Phase 35) — W1: hardcoded `'Survival ledger'`/`'Soul ledger'` Semantics a11y labels → `l10n.listLedgerDaily`/`listLedgerJoy`; W2: `totalSoulTx`/`totalGroupSoulTx` → `totalJoyTx`/`totalGroupJoyTx` across Freezed models (build_runner regen), use-case consumers, and 9 test files. Both re-verified at milestone re-audit (grep exit 1).

---

## v1.4 — 列表功能 (Transaction List)

**Shipped:** 2026-05-31
**Phases:** 24-30 (7 phases, 29 plans, 33 tasks)
**Duration:** 2026-05-29 → 2026-05-31 (~3 days; git range `v1.3..HEAD` spans 2026-05-26, including v1.3.x voice hotfix quick-tasks tagged after v1.3)
**Tag:** `v1.4`
**Audit Status at Close:** `tech_debt` — milestone goal achieved (22/22 requirements, 7/7 phases, 7/7 E2E flows). The one functional gap, GAP-1 (calendar staleness after family-sync / FAB), was closed at milestone close via quick task 260531-u34. Residual debt is non-blocking: GAP-2 (LIST-02 `watchByBookIds` reactive stream is dead code — reactivity achieved via manual `ref.invalidate`) and draft-Nyquist documentation debt (Phases 25/26/27/29/30 `nyquist_compliant: false`; Phase 28 approved). Mirrors v1.2/v1.3 close precedent. See `.planning/milestones/v1.4-MILESTONE-AUDIT.md`.
**Known deferred items at close:** see `.planning/STATE.md` Deferred Items §v1.4.

### Delivered

The placeholder List tab is now a full transaction overview in a Japanese-kakeibo layout. A `table_calendar` month header shows per-day expense totals (expense-only, own-book in v1.4), supports month navigation and tap-a-day-to-filter, and carries a current-month expense summary. Below it, a transaction list is sortable (date / edit-time / amount, with direction toggle), text-searchable (category · merchant · note), and filterable by ledger, multiple categories, and — in family mode — by member, all composing with AND logic and a one-tap clear. Rows reuse the v1.3 edit path on tap and route swipe-delete exclusively through `DeleteTransactionUseCase` (soft-delete, hash-chain preserved). When a family is joined, members' transactions (shadow books) merge in with per-row owner attribution and a "Mine only" shortcut. The list updates reactively after add / edit / delete / family-sync and supports pull-to-refresh; empty states have three distinct variants; all new strings ship in ja/zh/en with golden baselines.

### Key Accomplishments

1. **Data foundation + shared month-boundary util** (Phase 24) — `TransactionDao.findByBookIds(...)` multi-book query + `watchByBookIds(...)` reactive stream; extracted `DateBoundaries` utility to `lib/shared/utils/` consolidating the `DateTime(y, m+1, 0, 23,59,59)` idiom (6 prior call sites); `SortField` + `SortDirection` enums; 6 SC#1 DAO tests.
2. **Pure-Dart domain + use case** (Phase 25) — Freezed `ListFilterState` / `ListSortConfig` value objects, repository interface, and `GetListTransactionsUseCase` with `execute()` (Future + Result) and `watch()` (Stream) methods + `GetListParams` composite; 8 Mocktail tests covering SORT-01..04 forwarding, no Riverpod dependency.
3. **Providers + shell wiring** (Phase 26) — all list Riverpod providers wired with an explicit `keepAlive`-under-`IndexedStack` policy so filter/sort state persists across tab switches; `ListScreen` replaces the `main_shell_screen.dart` text placeholder (loading state reachable).
4. **Calendar header + month summary** (Phase 27) — `table_calendar` month grid with `calendarDailyTotalsProvider` per-day expense totals (`_dayKey` normalization contract, expense-only, isolated from filter state), month navigation, day-tap filter, and a `NumberFormatter`-formatted month summary; iOS build gate passed; human-approved render. (CAL-01..04)
5. **Transaction tile + sort/filter bar** (Phase 28) — `ListTransactionTile` (Dismissible swipe-delete via `DeleteTransactionUseCase`, tap-to-edit into the v1.3 `TransactionEditScreen`, ledger-color tag, tabular-figure amounts) + `ListDayGroupHeader` day grouping; sort/filter bar wiring text search + ledger + multi-category filters with AND composition. (LIST-01, ROW-01/02, SORT/FILTER)
6. **List screen assembly + family-aware** (Phase 29) — full screen with `RefreshIndicator` pull-to-refresh (honest spinner via dual-invalidate + `await .future.catchError`); shadow-book merge, per-row member chip attribution, per-member + "Mine only" filters guarded by `isGroupMode`; the `anyFilterActive` 5-condition fix (incl. `memberBookId`) mirrored across screen + bar. (LIST-04, FAM-01..04)
7. **i18n + empty states + golden polish** (Phase 30) — 3-variant `ListEmptyState` (no-data / no-match / loading-error), full ja/zh/en ARB coverage, and golden baselines; closes LIST-03.

Plus, at milestone close: **GAP-1 closed** (quick task 260531-u34) — `calendarDailyTotalsProvider(current month)` now invalidated at both shell sites (post-family-sync, post-FAB) so calendar totals + month summary refresh without pull-to-refresh.

### Stats

- **Commits since v1.3 tag:** 283
- **Files changed:** 316 (+51,409 / -2,207 LOC)
- **Commit categories:** docs 162, feat 50, test 26, fix 25, chore 15, refactor 2
- **Requirements:** 22/22 v1.4 requirements complete (LIST-03 checkbox reconciled at close — Phase 30 VERIFICATION had it ✓ SATISFIED)
- **ARB parity:** 533 keys per locale (ja=zh=en) — +27 from v1.3 baseline of 506
- **Drift schema:** unchanged at v17 (no migration this milestone)
- **New stack dep:** `table_calendar: ^3.2.0` (intl 0.20.2-compatible; no win32/native; iOS build verified green)

### Notable Decisions

- **Calendar per-day totals own-book only in v1.4** — combined family-calendar totals deferred to v1.5+ (CAL-02 family mode seam reserved; `bookId` is a single value in `calendarDailyTotalsProvider`).
- **Swipe-delete is confirm-only soft-delete, no undo SnackBar** — undo deferred (needs `RestoreTransactionUseCase`); deletion stays on the hash-chain-safe `DeleteTransactionUseCase` path.
- **Filter/sort state persists across tab switches** via `keepAlive: true` under `IndexedStack` (Phase 26 decision).
- **Calendar provider isolated from filter state** (`_dayKey` normalization, watches only bookId/year/month) to avoid re-rendering 31 cells on every search keystroke.
- **Scope held to expense-only** — no income tracking, no month settlement/lock, no amount-range filter, no "New" badge (all explicitly deferred).
- **GAP-1 fixed inline as a quick task at close** rather than carried to v1.5; GAP-2 (dead `watchByBookIds` stream) and draft-Nyquist docs accepted as tracked debt.

### Archive

- `.planning/milestones/v1.4-ROADMAP.md` — full phase details
- `.planning/milestones/v1.4-REQUIREMENTS.md` — final requirement status (22/22) + v1.5+ backlog
- `.planning/milestones/v1.4-MILESTONE-AUDIT.md` — pre-close audit report (status: `tech_debt`; GAP-1 closed after audit was taken)

---

## v1.3 — 迭代帐本输入

**Shipped:** 2026-05-26
**Phases:** 18-23 (6 phases, 47 plans)
**Duration:** 2026-05-22 → 2026-05-26 (~5 days)
**Tag:** `v1.3`
**Audit Status at Close:** `tech_debt` — milestone goal achieved with documentation-grade Nyquist debt accepted (Phase 18/21 missing VALIDATION.md; Phase 19/20 draft + `nyquist_compliant: false`; Phase 22 draft + `nyquist_compliant: true`). Phase 23 closed all functional gaps from the original audit. Mirrors v1.0 FUTURE-DOC-05 / v1.2 close precedent. See `.planning/milestones/v1.3-MILESTONE-AUDIT.md`.
**Known deferred items at close:** 4 items — see `.planning/STATE.md` Deferred Items §v1.3.

### Delivered

Home Pocket ledger entry now lives on a single screen for both manual and voice flows. A single shared `TransactionDetailsForm` widget powers four hosts: manual entry, voice entry, edit-existing, and OCR-review (architectural slot reserved for MOD-005). The numeric keypad enforces a 48dp touch-target floor across iOS HIG / Material guidance; six light/dark × ja/zh/en golden baselines lock visual discriminability. Voice number parsing now correctly combines 千/百/十/零/万 across zh + ja, including intra-pause merges via a `VoiceChunkMerger` 2.5s continued-listening window — corpora pass at zh 48/50 (96%) + ja 50/50 (100%). Voice category resolution always lands on an L2 category via a 3-stage fallback (override → `${l1Id}_other` convention → `findByParent.first`) consulting both merchant DB and an extensible synonym dictionary. The record button uses a hold-to-record gesture with AnimatedContainer shape morph + caption swap to "录音中…" — Stopwatch-verified perceived state change `<100ms`. Edit-from-list opens the shared form pre-populated; `entry_source` is preserved verbatim through edits.

### Key Accomplishments

1. **Single shared `TransactionDetailsForm` widget across 4 hosts** (Phase 18) — Freezed `TransactionDetailsFormConfig` sealed class with `.$new(...)` and `.edit(seed:)` factories; consumed by `ManualOneStepScreen`, `VoiceInputScreen`, `TransactionEditScreen`, `OcrReviewScreen` via `Config.when(...)`. `UpdateTransactionUseCase` preserves `entry_source` verbatim via `seed.copyWith()` with no `entrySource` override (DAO test exercises all 3 EntrySource literals).
2. **Manual one-step entry + keypad polish** (Phase 19) — `ManualOneStepScreen` collapses prior 2-screen entry chain; SmartKeyboard `math.max(48.0, rawKeyHeight)` non-negotiable touch-target floor; 6 golden baselines (ja/zh/en × light/dark) at 390×844; `manual_save_entry_source_test.dart` verifies `entry_source='manual'` round-trip against real Drift DB.
3. **Voice number parser zh + ja with continued-listening** (Phase 20) — Locale-aware numeral state machines + JA numeral dictionary in `lib/infrastructure/voice/` (per "Thin Feature" rule); `VoiceChunkMerger` 2.5s window via `SpeechRecognitionService.restartListen()`; zh corpus 96% + ja corpus 100%; anchor cases (zh 2204 / 1840, ja 2204 / 1840) verbatim verified. VOICE-02 device UAT (8 anchor cases) cleared in Phase 23 plan 23-08.
4. **Voice category resolver Level-2 enforcement** (Phase 21) — `VoiceCategoryResolver` always-L2 contract via `_ensureL2` 3-stage fallback (override map → `${l1Id}_other` convention → `findByParent.first` safety net); 19-L1 architecture invariant test; merchant DB (12 L2 entries) + synonym dict (59 seed entries) extensible without code changes — runtime-insert tests for 珍珠奶茶 (zh) + タピオカ (ja); legacy `FuzzyCategoryMatcher` + Levenshtein deleted.
5. **Voice one-step integration + hold-to-record button UX** (Phase 22) — `VoiceInputScreen` embeds `TransactionDetailsForm`; hold-to-record gesture via `RawGestureDetector` with `Duration.zero`; AnimatedContainer 180ms shape morph + AnimatedSwitcher caption swap to "录音中…"; Stopwatch test enforces `<100ms` perceived state change. Two BLOCKER gaps (G-01 recognizer self-termination, G-02 silent errors) elevated from code review and closed via plans 22-08/09/10 with 4 new ARB error keys + permanent-error mic gate.
6. **v1.3 cleanup phase absorbs carried tech-debt** (Phase 23) — Scanner allow-list cleanup (VOICE-SCANNER-ALLOWLIST cleared 2026-05-24); 6 voice-flow surgical fixes (D-05 intra-session guard, D-07 cold-start race, D-08 popUntil deferral, D-09 listener-leak regression, D-10 mixin extraction, D-11 G-02 localized assert); 4 mechanical polish items (D-12 constant dedup, D-13 substring guard, D-14 SeedAllUseCase, D-15 その他/其他/other seed); REQUIREMENTS.md + 7 SUMMARY frontmatters reconciled (D-04); 9/9 carried device UATs run and passed; `voice_input_screen.dart` slimmed 838 → 776 LOC via `VoiceLocaleReadinessMixin` + pure-helper extraction (Plan 23-09) — back under CLAUDE.md `<800` cap.

### Stats

- **Commits since v1.2 tag:** 330
- **Files changed:** 304 (+64,157 / -4,747 LOC); `lib/` +6,559 / -2,197; `test/` +10,246 / -836
- **Commit categories:** feat 52, fix 18, refactor 14, test 38, docs 158
- **Phase commit distribution:** Phase 20: 15, Phase 21: 14, Phase 22: 11, Phase 23: 10 (Phases 18-19 commits intermixed in early v1.3 tail)
- **Requirements:** 15/15 v1.3 requirements complete (4 fully verified at audit time + 11 partial-by-documentation-only reconciled in Phase 23 plan 23-07)
- **ARB parity:** 506 keys per locale (ja=zh=en) — +19 from v1.2 baseline of 487
- **Drift schema:** unchanged at v17 (no migration this milestone)
- **LOC cap:** `voice_input_screen.dart` 776 LOC (under 800 cap after Plan 23-09 mixin + helpers extraction)

### Notable Decisions

- 5-phase split (18-22) + cleanup phase (23) separates voice number parser (state-machine corpus) from voice category resolver (database resolution); isolates voice integration phase; cleanup phase chosen inline (vs carry to v1.4) for same-milestone debt absorption.
- Phase 18 ships first as foundation — INPUT-03 shared widget unblocks INPUT-01 (manual), INPUT-02 (voice), and EDIT-01/02 (edit-from-list).
- Phase 20 deliberately UI-independent (parallel-safe with Phase 19); both feed into Phase 22 integration.
- **Hold-to-record gesture** (vs tap-to-toggle) chosen and consistent app-wide; reduces accidental activation; documented in 22-04 SUMMARY.
- L1 → `${l1Id}_other` convention + `cat_other_expense → cat_other_other` override; always-L2 contract via deterministic fallback; architecture invariant test enforces 19 expense L1s.
- Phase 22 G-01/G-02 elevated to BLOCKER from code review (production-risk recognizer self-termination + silent errors); cannot be advisory-deferred. Closed in plans 22-08/09/10 before Phase 22 close.
- OCR slot intentionally hardcodes `EntrySource.manual` pending MOD-005 writer (annotated `// MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)`); schema accepts 'ocr' literal already.
- Phase 23 plan 23-09 LOC-cap extraction (838 → 776) via `VoiceLocaleReadinessMixin` + 3 pure helpers; zero behavior change.

### Archive

- `.planning/milestones/v1.3-ROADMAP.md` — full phase details
- `.planning/milestones/v1.3-REQUIREMENTS.md` — final requirement status + v1.4+ backlog
- `.planning/milestones/v1.3-MILESTONE-AUDIT.md` — pre-close audit report (status: `tech_debt`; Phase 23 closed all functional gaps after audit was taken)
- `.planning/milestones/v1.3-phases/` — archived phase directories (18-23)

---

## v1.2 — Happiness Metric Refresh

**Shipped:** 2026-05-21
**Phases:** 13-17 (5 phases, 37 plans, 63 tasks)
**Duration:** 2026-05-19 → 2026-05-21 (3 days)
**Tag:** `v1.2`
**Audit Status at Close:** `tech_debt` — milestone goal achieved with documentation-grade close debt accepted (Phase 13/17 missing VERIFICATION.md; 3 VALIDATION.md drafts with `nyquist_compliant: false`). Mirrors v1.0 FUTURE-DOC-05 pattern. See `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.
**Known deferred items at close:** 6 items (2 verification gaps, 1 Nyquist gap, 1 stale test from Phase 15 ARB drift, 1 forward-compat schema slot, 1 quick-task metadata drift) — see `.planning/STATE.md` Deferred Items §v1.2.

### Delivered

The Home Pocket Joy metric is now expressed as `Σ joy_contribution` (cumulative per-month) per ADR-016, superseding the v1.1 density (Joy/¥) formulation. HomeHero shows a single-month accumulation ring against a user-configurable `monthly_joy_target` with sage-green→gold color interpolation; AnalyticsScreen Variant ε retired density and added Custom Time Windows, Per-Category breakdown, Soul-vs-Survival comparison (anti-toxicity framed), and a Manual-Only Joy audit-lens variant. Drift schema migrated to v17 (`transactions.entry_source` column). HomeHero isolation invariant (ADR-016 §3) is structurally enforced by test guards across Phases 15-17.

### Key Accomplishments

1. **ADR-016 Joy migration shipped end-to-end** — `Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)` replaces density (Joy/¥) as the single Joy expression. `lib/` is density-free (`grep -rn 'density|joyPerYen|homeHappinessROI' lib/` returns 0 hits); ARB density vocabulary fully scrubbed across ja/zh/en at 487 keys parity.
2. **HomeHero target ring + user-configurable target** — sage-green `#47B88A` → gold smooth color interpolation with clamp at 100% (no oscillation, no discrete events at threshold per ADR-012 §2 / ADR-016 §5). `monthly_joy_target` persists in SharedPreferences; recommended value = `ceil(median(past 3 months Σ joy_contribution))` when ≥3 months data, else fallback baseline 50 (Phase 13 spike decision).
3. **AnalyticsScreen Variant ε with Custom Time Windows** — Freezed `TimeWindow` sealed value object (week/month/quarter/year/arbitrary), `TimeWindowValidation` calendar-month guard, `selectedTimeWindowProvider` session state, AppBar `TimeWindowChip` + `TimeWindowPickerSheet`. Six analytics use cases migrated to `(startDate, endDate)`; HomeHero remains current-month-anchored.
4. **Per-Category Breakdown + Soul-vs-Survival comparison shipped with type-system invariants** — `PerCategoryBreakdownCard` with min-N=3 filter + "Other" rollup. `SoulVsSurvivalCard` Soul column shows entries + spend + avgSatisfaction; Survival column shows entries + spend only — enforced by `SurvivalLedgerSnapshot` Freezed class having no `avgSatisfaction` field (D-04 type-system gate). Trilingual anti-toxicity widget sweep (24 cases × 3 locales × 4 states) passes.
5. **Manual-Only Joy variant on schema v17** — `ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL DEFAULT 'manual' CHECK ∈ {manual, voice, ocr}`. `EntrySource? entrySourceFilter` threaded through 12+ use cases + 16 analytics providers + DAO `AND entry_source = ?` clauses. `JoyMetricVariantChip` toggle on AnalyticsScreen AppBar; HomeHero isolation SC-4 enforced (variant toggle does not affect HomeHero providers).
6. **HomeHero isolation invariant structurally enforced** — `lib/features/home/` has zero hits for `selectedTimeWindowProvider`, `state_time_window`, `state_joy_metric_variant`, or `joyMetricVariant`. `home_screen_isolation_test.dart` combines source-grep guards, Phase 16 `verifyNever` assertions, and Phase 17 SC-4 variant-toggle non-effect verification.

### Stats

- **Commits since v1.1 tag:** 212
- **Files changed:** 521 (+57,460 / -7,168 LOC); `lib/` +15,828 / -5,189; `test/` +8,034 / -1,565
- **Phase commit distribution:** 13: 26, 14: 17, 15: 36, 16: 39, 17: 32
- **Requirements:** 11/11 v1.2 requirements complete (8 fully verified, 3 partial-due-to-missing-VERIFICATION.md with integration-check substitute evidence)
- **ARB parity:** 487 keys per locale (ja=zh=en)
- **Drift schema:** v16 → v17 (single column addition + inline backfill default)

### Notable Decisions

- ADR-016 ratify (2026-05-19) consciously broke v1.1 baseline purity to consolidate density retirement and target-ring rebuild into a single coherent milestone (ADR-016 §1 accepted cost).
- HomeHero ring is **single-month accumulation only**; no cross-period delta surfaces (hard ADR-012 §4 boundary).
- HomeHero ring at and beyond 100%: **no copy, no toast, no notification, no haptic, no celebration animation** — only ambient color change (hard ADR-012 §2 / ADR-016 §5 contract; verified by widget test asserting absence of all event paths).
- Monthly Joy target fallback baseline = 50 (Phase 13 spike-decided); revisit after real-user data collected.
- `SurvivalLedgerSnapshot` deliberately lacks `avgSatisfaction` field (D-04) — type-system gate against value-judgment framing on the survival ledger.
- Family privacy hardening (FAMILY-V2-01/02/03) explicitly out of v1.2 scope to keep Joy-axis focused; remains v2 backlog.
- Phase 13 + 17 shipped without running `/gsd:verify-work` — integration check at milestone close acts as backstop; documented as v1.2 close debt for retroactive backfill.

### Archive

- `.planning/milestones/v1.2-ROADMAP.md` — full phase details
- `.planning/milestones/v1.2-REQUIREMENTS.md` — final requirement status + v2 backlog
- `.planning/milestones/v1.2-MILESTONE-AUDIT.md` — pre-close audit report (status: `tech_debt`)
- `.planning/milestones/v1.2-phases/` — archived phase directories (13-17)

---

## v1.1 — Happiness Metric & Display

**Shipped:** 2026-05-05
**Phases:** 9-12 (4 phases, 40 plans)
**Tag:** `v1.1`
**Audit Status at Close:** `known_debt` — milestone goal achieved; one Phase 11 human UAT verification item acknowledged as deferred
**Known deferred items at close:** 1 verification gap (Phase 11 `11-VERIFICATION.md` human UAT); see `.planning/STATE.md` Deferred Items.

### Delivered

Home Pocket now has a v1.1 happiness metric layer and UI surface: personal Joy metrics, aggregate-only family Joy insights, an integrated HomeHeroCard, a unified AnalyticsScreen dashboard, and final ja/zh/en product copy aligned to the 悦己 / ときめき / Joy lexical hierarchy.

### Key Accomplishments

1. **Happiness metric domain locked** — schema v16 default satisfaction semantics, sealed `MetricResult`, PTVF Joy-per-yen math, Top Joy ordering, soul-only filtering, and family aggregate-only contracts are implemented and verified.
2. **Anti-gamification decisions codified** — ADR-012/013/014/015 capture no-gamification, Joy density scaling, unipolar satisfaction semantics, and trilingual lexical hierarchy.
3. **HomePage rebuilt around Joy context** — `HomeHeroCard` replaces the previous monthly overview, ledger comparison, and SoulFullness surfaces with rings, split bar, Best Joy story, and group-mode family rows.
4. **AnalyticsScreen Variant δ shipped** — unified KPI strip plus Time, Distribution, and Story groups render total-ledger and Joy-ledger analytics through use cases/providers, with v1.0 analytics widgets removed.
5. **Trilingual copy rename completed** — ARB values for Joy/Daily ledger language, Joy density/index labels, satisfaction ladder, and `satisfactionExcellent` are updated across ja/zh/en; ADR-015 is accepted.
6. **Verification baseline passed** — final Phase 12 gates included `flutter analyze`, full `flutter test` (1413 tests), ARB parity, hardcoded-CJK scan, picker tests, analytics widget tests, and refreshed HomeHeroCard goldens.

### Stats

- **Files archived:** `.planning/milestones/v1.1-ROADMAP.md`, `.planning/milestones/v1.1-REQUIREMENTS.md`
- **Phase execution:** 4 phases, 40 plans, 80 GSD tasks
- **Requirements:** 29/29 v1.1 requirements complete
- **Timeline:** 2026-05-01 → 2026-05-05

### Notable Decisions

- Strict per-member family analytics consent is deferred to v1.2 (`FAMILY-V2-03`) rather than partially shipping schema/settings work.
- ARB key renames are deferred (`TOOL-V2-02`); v1.1 changed values only to avoid wider generated-code churn.
- Voice estimator range realignment is deferred (`HAPPY-V2-03`) because v1.1 locked picker semantics first.
- One Phase 11 visual/device UAT item remains human-needed and is accepted as known close debt.

### Archive

- `.planning/milestones/v1.1-ROADMAP.md` — full phase details
- `.planning/milestones/v1.1-REQUIREMENTS.md` — final requirement status + v2 backlog

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
