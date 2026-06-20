# Home Pocket — まもる家計簿

## Current State

**Shipped:** v1.0 Codebase Cleanup Initiative (2026-04-29) — see `.planning/milestones/v1.0-ROADMAP.md`
**Shipped:** v1.1 Happiness Metric & Display (2026-05-05) — see `.planning/milestones/v1.1-ROADMAP.md`
**Shipped:** v1.2 Happiness Metric Refresh (2026-05-21) — see `.planning/milestones/v1.2-ROADMAP.md` + `.planning/milestones/v1.2-MILESTONE-AUDIT.md`
**Shipped:** v1.3 迭代帐本输入 (2026-05-26) — see `.planning/milestones/v1.3-ROADMAP.md` + `.planning/milestones/v1.3-MILESTONE-AUDIT.md`
**Shipped:** v1.4 列表功能 (2026-05-31) — see `.planning/milestones/v1.4-ROADMAP.md` + `.planning/milestones/v1.4-MILESTONE-AUDIT.md`
**Shipped:** v1.5 文案与配色统一 (2026-06-02) — see `.planning/milestones/v1.5-ROADMAP.md` + `.planning/milestones/v1.5-MILESTONE-AUDIT.md`
**Shipped:** v1.6 购物清单 (2026-06-12) — see `.planning/milestones/v1.6-ROADMAP.md` + `.planning/milestones/v1.6-MILESTONE-AUDIT.md`
**Shipped:** v1.7 多币种支持 (2026-06-14) — see `.planning/milestones/v1.7-ROADMAP.md` + `.planning/milestones/v1.7-MILESTONE-AUDIT.md`

## Current Milestone: v1.8 统计页面重设计（实用化 × 悦己情感化）

**Goal:** 把统计页面从「指标罗列」全面重设计为「更实用 + 凸显悦己、让用户为自己花钱而感到开心」的体验。开发前先调研现状、用 HTML 产出多套设计方向并充分讨论选定一案（设计探索关卡），通过后再进入开发。

**Phase numbering:** Continues from v1.7's Phase 42 → v1.8 starts at **Phase 43**.

**Target features:**
- **HTML 设计探索关卡（开发前置）** — 深入调研现状实现 + 产出多个 HTML 设计方向 + 充分讨论 → 选定一案（未获批前不进入开发）
- **统计页全面重设计** — 信息架构 + 视觉 + 叙事框架刷新
- **收支总览 / 结余率前面化** — 收入−支出−结余率作为一等概览（现仅内部计算，未前面化）
- **支出趋势 & 分类下钻** — 6 个月滚动 + 分类构成下钻 / 可切换视图（更易回答「钱花哪了」）
- **悦己叙事强化** — 情感化呈现「已花悦己」的满足感与价值；具体形式在设计阶段于 ADR-012 约束下决定

**Central open design question:** 「为自己花钱而开心」如何在 ADR-012 反游戏化恒久约束（禁止徽章/连续天数/前月对比/目标达成/排行榜，由 `anti_toxicity_*_test` + `home_screen_isolation_test` 结构化锁定）下表达——作为 HTML 设计探索的主要论点，以方向案比较后决定（必要时评估是否需新 ADR）。

**Design gate outcome (Phase 43 — CLOSED 2026-06-16, verified 4/4):** 设计探索关卡通过，零生产代码（仅 `.planning/` 下 HTML/Markdown）。产出现状深研图（GATE-01，17 widget 清单）、5 套 HTML 方向 + 4 轮迭代各带 ADR-012 自审（GATE-02），用户选定 **round-5 B（M2 衍生）**并批准（GATE-03，`.planning/phases/43-html-design-gate-no-production-code/mocks/selected/`）。选定形态：支出趋势置顶（总/日常/悦己 tab）+ 醒目支出分类圆环（1 级降序、无悦己合计）+「悦己花在哪」水平堆叠条 + 小确幸日历 + 满足度直方图，悦己侧全描述性。关键决策（GATE-04）：① JOY-04 静态只读 → **no-go**（不新增 ADR、保持 no-Drift）；② 支出侧「本月vs上月」趋势 = **ADR-012 §4 跨期约束的显式例外**（仅支出侧，悦己侧跨期仍绝对禁止），需在 Phase 45 前以 `## Update` 追加到 ADR-012；③ 情感词表锁定（target/目标 仅限 analytics，保留 HomeHero 目标环）；④ fl_chart 1.2.0 逐图校验：donut/histogram/trend 原生 ✅，悦己水平堆叠条 ⚠ + 小确幸日历 ❌ 需自定义 widget（Phase 46 风险）。

**Build outcome (Phase 45 — COMPLETE 2026-06-17, verified 4/4):** 展示外壳重建（纯结构重构、行为保持 D-A1）。`analytics_screen.dart` 739→176 LOC 瘦外壳；7 张内联 `_*Card` + `_AnalyticsDataCard` 抽进 `widgets/cards/`（各 <400 LOC、ConsumerWidget、本地 `.when`）；新增 typed `analytics_card_registry.dart`（渲染顺序 + `_refresh` 失效并集单一来源）；`_refresh()` 108→12 LOC 由注册表派生（并集 ⊆ analytics、零 `home/*`）。HomeHero 隔离由构造保证：注册表零 `home/*` import + 结构不变量单测（`analytics_card_registry_test.dart`）+ `home_screen_isolation_test` 绿；`shadowBooksProvider` 直接失效按 **D-B3 Option A** 丢弃（仅保留显示读取的既有行为，组模式刷新经 `familyHappinessProvider` 传递再读，Assumption A1 实测为真）。全量 **2925/2925 绿**、golden 零重基线、`analytics_screen_test` diff 为空（D-A1 实证）。ADR-012 §4 支出侧「本月vs上月」例外以 `## Update` 追加（D-D1）。REDES-01 + GUARD-01 validated。代码评审：0 阻断、1 注释级 warning（WR-01 shadow-books 缓存再读措辞，坐在锁定决策上，可选 `--fix` 软化）。

**Build outcome (Phase 46 — COMPLETE 2026-06-17, verified 6/6):** round-5 B 扁平 5 卡阵容上线，逐卡构建已批准的 GATE-03 设计，全程 ADR-012-safe。卡序：①支出趋势 LineChart（pill tabs 总支出/日常/悦己；当月内按天累计，支出侧本月实线+上月虚线双线、悦己侧本月单线**零跨期**——D-E1 由 `WithinMonthCumulativeTrend` 无 `previousMonthJoy` 字段在构造上保证）→ ②支出分类圆环 hero（中心「本月支出」count-up，10 个 L1 金额降序图例，**整行** tap 下钻 D-B1）→ ③悦己花在哪 横向堆叠条（R-1 自定义 `Row`+`Flexible`，**零 fl_chart** GATE-04）→ ④小确幸日历热力（R-2 自定义 `GridView`，色深=当天悦己笔数，tap 某天 inline 展开；**零 fl_chart**）→ ⑤满足度直方图（fl_chart 1.2.0 原生 `BarChartRodData.label`，删除 `Stack` hack REDES-02）+ group-mode 条件卡 `family_insight`（`isVisible` GUARD-02）。新增只读 `CategoryDrillDownScreen`（DRILL-01，无 swipe-delete/tap-edit）。数据路径均为 `findByBookIds`+L1 rollup 之上的纯 Dart 变换（零新 DAO、零 migration、schema 仍 v21）；REDES-03 count-up 仅落 donut 中心 + 悦己 header 两处锚点（无循环/glow/庆祝爆发）。JOY-03（记忆故事）/JOY-04（kakeibo Q4）随 round-5 B **Descoped**（GATE-03，由 REQUIREMENTS.md 台账补正承载，零加回）。7 plans / 4 waves，degraded 顺序执行于主树（worktree base-drift #683）。全量 **2971/2971 绿**、`flutter analyze` 0 issues、fl_chart 保持 `^1.2.0`。代码评审：**0 阻断**、4 warning（WR-01 硬编码 `'JPY'` 未接 `currencyCode`、WR-02 >10 分类时中心总额与图例百分比不对账、WR-03 joy 金额 rollup O(n·k)、WR-04 展开日列表 pull-to-refresh 不刷新）——均为边缘质量项、不破坏任何 SC，结转 Phase 47/backlog。视觉/真机 UAT + chart golden 重基线为 Phase 47 范围。

**Build outcome (Phase 47 — COMPLETE 2026-06-20, verified 4/4 — v1.8 LAST PHASE):** round-5 B 重设计页面的验证收尾。6 plans / 4 waves，degraded 顺序执行于主树（worktree base-drift #683）。① Phase-46 评审 4 项 WR 全部修复：WR-01 删除死 `currencyCode` 管道、WR-02 圆环真总额对账 + 中性不可点「その他」长尾 rollup 切片（图例百分比按真总额）、WR-03 `GetJoyCategoryAmountsUseCase` 单趟累计 + 诚实 docstring、WR-04 展开日历日 inline 列表 pull-to-refresh 失效修复（panel 级 `ref.listen → ref.invalidate(joyDayTransactionsProvider)`，不扩大注册表并集、零 `home/*`）。② i18n（GUARD-03）：删除 46-07 遗留的 3 个 orphan section-header ARB 键（三语对称、`flutter gen-l10n` 干净、`git add -f lib/generated/`），三语 parity 1499 键/语、生存/灵魂 grep-ban 0 命中。③ 反毒性（GUARD-03）：`anti_toxicity_phase47_test.dart`（827 LOC）扫 5 卡 × ja/zh/en × 全状态矩阵（含 WR-02 Other + 日历 inline-expand），36/36 禁词 `findsNothing`。④ macOS golden（GUARD-04）：图表从零 golden 覆盖——8 测试文件 + 48 PNG masters（生产 `AppTheme` wrap、ADR-019 调色保真、count-up 锚点 `pumpAndSettle` 落定），`--update-goldens` 仅作用于新文件（GUARD-04 diff 归因干净）。⑤ 全量门禁（GUARD-04）：FULL `flutter test` **3057/3057 绿**、`flutter analyze` 0、cleaned-lcov 覆盖 80.48%（强制门 70% per Phase-8 amendment）。⑥ 真机视觉 UAT（GUARD-05）：用户于真机 iOS locale=ja 验证 10/10 D-10 项全过（`47-UAT.md` status passed）。代码评审：**0 阻断**、4 warning（WR-01 Other 算术仅在上游对账时成立、WR-02 反毒词表缺 streak/target/cross-period 令牌、WR-03 `app_ja.arb` joy 卡文案残留中文字形 vs `ときめき`、WR-04 一个 golden 缺 `currentLocaleProvider` override）+ 3 info——均结转 backlog，不破坏任何 SC。schema 仍 v21、fl_chart 仍 `^1.2.0`。**v1.8 五个 phase（43-47）全部完成，里程碑就绪可执行 `/gsd-complete-milestone` 收口。**

**Deferred backlog (carried forward, NOT in v1.8 scope):** MOD-005 OCR writer landing (OCR ledger entry hidden behind reversible `kOcrEntryEnabled` flag, quick task 260614-iww), combined family-calendar totals + undo-on-delete (v1.4 deferrals), FAMILY-V2-01/02/03 family privacy hardening, runtime theme-switching / selectable palettes (THEME-V2-01), `Book.survivalBalance`/`soulBalance` DB-column rename (v1.5 carve-out), remaining hardcoded a11y Semantics labels (v1.5 IN-02), FUTURE-QA-01 release-readiness QA, FUTURE-DOC/TOOL cleanup, fl_chart 1.x→2.x upgrade (TOOL-V2-01) — **note: a "全面大改" of the analytics charts may pull this forward**, voice flow polish (VOICE-POLISH-V2-01..08), English voice parser (VOICE-EN-V2-01), Multi-Currency v2 (CUR-V2-01/02, SHOP-CURRENCY-V2).

The v1.0 initiative was a pure-refactor cleanup. It delivered an operational hybrid audit pipeline, eliminated 50 catalogued findings (24 CRITICAL, 8 HIGH, 8 MEDIUM, 7 LOW + 3 layer-violation closures), aligned all architecture documentation with the post-refactor codebase, and locked 4 permanent CI guardrails.

The v1.1 milestone delivered the happiness metric domain, HomePage `HomeHeroCard`, AnalyticsScreen Variant δ unified dashboard, and final trilingual UI copy rename pass. It also ratified the v1.1 anti-gamification and lexical hierarchy ADRs.

The v1.2 milestone shipped the ADR-016 Joy migration (density → `Σ joy_contribution`), HomeHero target ring rebuild with user-configurable `monthly_joy_target` + 3-month median recommendation, AnalyticsScreen Variant ε with Custom Time Windows (week/month/quarter/year/arbitrary), Per-Category breakdown + Soul-vs-Survival comparison (anti-toxicity framed), and Manual-Only Joy sub-metric variant on Drift schema v17 (`entry_source` column). HomeHero isolation invariant (ADR-016 §3) is structurally enforced. Audit closed at `tech_debt` — Phase 13/17 lack VERIFICATION.md and 3 VALIDATION.md drafts have `nyquist_compliant: false`; documentation-grade debt only, all 11 v1.2 requirements satisfied in implementation.

The v1.3 milestone transformed ledger entry into a single-screen, voice-trustworthy core experience. Shipped: single shared `TransactionDetailsForm` widget consumed by 4 hosts (manual, voice, edit, OCR review); `ManualOneStepScreen` replacing the prior 2-screen chain; SmartKeyboard 48dp touch-target floor; locale-aware zh + ja voice number parsing (state machines + `VoiceChunkMerger` 2.5s continued-listening window) at zh 96% + ja 100% corpus accuracy; `VoiceCategoryResolver` always-L2 contract with merchant DB + synonym dictionary (extensible without code changes); hold-to-record gesture with AnimatedContainer shape morph + caption swap (`<100ms` verified); edit-from-list path with `entry_source` verbatim preservation. Two BLOCKER gaps (G-01 recognizer self-termination, G-02 silent errors) closed in Phase 22. Phase 23 cleanup absorbed carried tech-debt (scanner allow-lists, 6 voice-flow surgical fixes, 4 mechanical polish items, REQUIREMENTS.md reconciliation, 9 device UATs run + passed, voice_input_screen.dart 838→776 LOC via mixin + helpers extraction). Audit closed at `tech_debt` — documentation-grade Nyquist debt only; all 15 v1.3 requirements satisfied and reconciled.

The v1.4 milestone built the placeholder List tab into a full transaction overview (Japanese-kakeibo layout) in a new `lib/features/list/` module. Shipped: a `table_calendar` month header with per-day expense totals (own-book in v1.4), month navigation, tap-a-day-to-filter, and a current-month expense summary; a transaction list that is sortable (date / edit-time / amount ± direction), text-searchable (category · merchant · note), and filterable by ledger, multiple categories, and family member — all AND-composed with one-tap clear; rows that reuse the v1.3 edit path on tap and route swipe-delete through `DeleteTransactionUseCase` (soft-delete, hash-chain preserved); family-aware shadow-book merge with per-row owner attribution + "Mine only"; reactive updates + pull-to-refresh; 3-variant empty states; and full ja/zh/en ARB coverage (533 keys/locale) with golden baselines. A shared `DateBoundaries` util consolidated month-boundary arithmetic; `table_calendar ^3.2.0` was added (iOS build verified green). Audit closed at `tech_debt` — 22/22 requirements, 7/7 phases, 7/7 E2E flows; the one functional gap (GAP-1 calendar staleness after family-sync/FAB) was closed at milestone close via quick task 260531-u34; residual GAP-2 dead-code (`watchByBookIds` unused) + draft-Nyquist documentation debt accepted.

The v1.6 milestone built the placeholder 4th nav tab (待办事项/Todo) into a complete family shopping list in a new `lib/features/shopping_list/` module. Shipped: public/private segmented lists (two independent lists, visibility immutable after creation — D1/D6); name-only-required add/edit form with optional ledger 日常/悦己, category, tags, encrypted note, quantity, and estimated price reusing the existing selectors (D4, ITEM-03); tap-to-complete with animated strikethrough and completed-to-bottom DAO ordering; chip-bar filtering shared across segments with reset-on-switch (D5); swipe-delete, long-press batch-select with select-all, clear-all-completed; 3-variant empty states; context-aware FAB preserving all 6 accounting post-entry invalidations (D2, NAV-01); family sync for public items through the existing E2EE pipeline (attribution chips, sticky-complete merge per D-03, tombstone safety, reactive Drift `readsFrom:` delivery — the v1.4 GAP-2 lesson applied), with private items excluded by gates at the use-case boundary, the change tracker, and (since quick task 260612-daz) the receiving end. Drift schema v19→v20; ARB parity ja/zh/en; 54 golden baselines; a 2026-06-09/10 quick-task series hardened sort-mode UX (single-mechanism `reorderBatch`→`applyOrder`), redesigned the form, and fixed an iOS startup keychain-accessibility brick. Audit closed at `tech_debt` — 27/27 requirements, 4/4 phases, 6/6 seams, 10/10 E2E flows; audit warnings W1 (fullSync shopping reconcile) + W2 (receiver listType trust) were closed at milestone close (260612-daz); residual is draft-Nyquist docs (P37/38/39), three 37-REVIEW advisories, and one pending on-device confirm (260609-ruu). Suite 2588/2588 green.

The v1.5 milestone was a brownfield consistency refactor — no new user features. It unified the half-migrated dual-ledger vocabulary across all three locales **and** internal code identifiers (`LedgerType { daily, joy }` enum + 242 call sites, 25 ARB key roots + values to 日常/悦己/ときめき/Daily/Joy, v17→v18 Drift migration rewriting stored enum values + `soul_satisfaction`→`joy_fullness`, ADR-017), then explored 5 palette directions → user-selected ADR-018 "Teal Clarity" → encoded it in a single `AppPalette` ThemeExtension that replaced every `Color(0x…)` literal and the AppColors/AppColorsDark shims, with full dark-mode rollout (THEME-V2-02 pulled forward, D-07). Goldens were re-baselined to teal (77 masters, 34 dark; suite 2281/2281 green). A follow-up Phase 35 closed two residual leaks found by the milestone audit (W1 hardcoded a11y Semantics labels → l10n; W2 `totalSoulTx`→`totalJoyTx`). Audit closed at `tech_debt` — 15/15 requirements, 5/5 phases, 6/6 integration seams wired; residual is one pending on-device screen-reader UAT, draft-Nyquist docs (P31/32/34/35), and the documented out-of-scope `Book.*Balance` DB-column carve-out.

The v1.7 milestone added foreign-currency ledger entry end to end while leaving the JPY-only path byte-for-byte unchanged. Users select a currency on the SmartKeyboard (JPY-first selector with recent-use reordering + full-ISO search) or speak it in zh/ja (「五十美元」/「50ドル」); the app fetches the exchange rate for the transaction date from a free no-key API (Frankfurter + fawazahmed0 fallback), caches it per (date, currency) in an encrypted Drift table with offline fallback and weekend/holiday date transparency, shows a live JPY conversion preview, stores the JPY-converted integer in the existing `amount` column (driving all lists/analytics/sorting unchanged) plus original currency/amount/rate as three nullable sync-safe fields, and exposes a two-input/one-derived edit view (ADR-022 D-01; JPY read-only). Three ADRs (ADR-020 string rate precision / ADR-021 hash excludes currency fields / ADR-022 edit policy) and a single `convertToJpy()` conversion site anchor the design; the never-block-save invariant keeps zero HTTP in the accounting use cases. Drift schema v20→v21; first external network dependency (outbound rate queries only, no user data on the wire, fully offline-capable). Audit closed at `tech_debt` — 23/23 requirements, 3/3 phases, 6/6 integration seams wired, E2E flow complete, all four Phase 42 human/device UAT items passed; residual is documentation-grade draft-Nyquist docs (P40/41/42). Suite 2786/2786 green.

<details>
<summary>v1.7 多币种支持 (archived)</summary>

**Started:** 2026-06-12
**Shipped:** 2026-06-14 (phases executed 2026-06-12→13; quick-task hardening through 06-14)
**Phase numbering:** Phases 40-42
**Trigger:** The app booked everything as JPY; the owner travels and wanted foreign-currency entry with historical-rate conversion before any v1 release, without compromising the local-first/privacy architecture.

**Goal:** 记账支持外币输入——小键盘选币种、按账目日期自动取汇率转换成日元入账，原币种/原金额/汇率作为附加字段保留并在 UI 中可见。

**Delivered:**
- **Data + domain + sync foundation (Phase 40):** three blocking ADRs (ADR-020 string rate precision / ADR-021 hash excludes currency fields / ADR-022 date-change + edit policy); CNY/JPY `¥` collision fixed in `NumberFormatter` (`CN¥`, KRW 0-decimal, HK$/A$/C$/NT$/S$) + golden re-baseline; Drift v20→v21 (`exchange_rates` cache table + 3 nullable `transactions` columns, explicit CREATE INDEX); `Transaction` Freezed extension + `ExchangeRateDao`/repository; `TransactionSyncMapper` null-safe round-trip + partial-triple domain invariant. (STORE-01..05)
- **Exchange-rate service (Phase 41):** `ExchangeRateApiClient` three-source fallback (Frankfurter → fawazahmed0 jsDelivr → Cloudflare) with rate inversion, weekend/holiday `actualDate`, SC-5 URL privacy; cache-first `ExchangeRateCacheService` (permanent historical, short-TTL today, never-throws); `GetExchangeRateUseCase` with `RateResult` sealed union + RATE-04 manual override + ADR-022 D-02/D-03 signals; `BackupData` rate export/import; `connectivity_plus ^7.1.1`. Never-block-save invariant structurally enforced (zero HTTP in accounting use cases). (RATE-01..06)
- **Entry + display + voice (Phase 42):** SmartKeyboard currency key + `CurrencySelectorSheet` (JPY-pinned, recent-use LRU, full-ISO search, 48dp flag rows); per-currency decimal gate (D-07 cap / D-08 truncate; JPY/KRW 0-decimal); live `ConversionPreviewPanel` (single-site `convertToJpy()`, no-jump skeleton, amber staleness); foreign-row list annotation; two-input/one-derived edit host (ADR-022 D-01, JPY read-only); zh/ja voice currency detection → ISO flowing through the shared form. SC-5 smoke: USD 50 @ 148.30 → `amount=7415`. (CURR-01..05, DISP-01..04, VOICE-CUR-01..03)
- **Post-phase hardening (quick tasks 260613-*/260614-*):** unified foreign-currency card across add/edit (260613-ufn), edit-interaction + date-trigger + debounce polish (260613-mgc/n5c/njf/wuv), currency-picker dedup + long-tail l10n + real symbols (260613-ohz/ote), integer no-trailing-zeros (260614-dx1), voice currency-switch + header-pill fix (260614-goh), Home recent-item refresh-after-edit fix (260613-wjx), and OCR-entry hide behind reversible `kOcrEntryEnabled` flag + continuous-entry FAB mode (260614-iww).

**Out of v1.7 scope (carried forward):** "remember this rate" (CUR-V2-01), per-currency analytics sub-totals (CUR-V2-02), shopping `estimatedPrice` multi-currency (SHOP-CURRENCY-V2); live intraday rates, retroactive mass rate-update, per-user home currency other than JPY, automatic currency detection without an explicit currency word — see `.planning/milestones/v1.7-REQUIREMENTS.md`.

**Known close debt** (documented in `.planning/milestones/v1.7-MILESTONE-AUDIT.md`):
- Draft-Nyquist docs: Phases 40/41/42 all `nyquist_compliant: false` (documentation-grade; suite 2786/2786 green)
- Advisory: pre-existing no-rehash-on-edit policy (ADR-021) — editing an amount re-derives JPY but leaves `currentHash` unchanged; intentional, not multi-currency-specific
- 33 quick-task metadata-drift/voice-backlog stubs acknowledged at close (see STATE.md Deferred Items §v1.7)

**Archive:** `.planning/milestones/v1.7-ROADMAP.md`, `.planning/milestones/v1.7-REQUIREMENTS.md`, `.planning/milestones/v1.7-MILESTONE-AUDIT.md`

</details>

<details>
<summary>v1.6 购物清单 (archived)</summary>

**Started:** 2026-06-07
**Shipped:** 2026-06-12 (phases executed 2026-06-07→08; quick-task hardening through 06-12)
**Phase numbering:** Phases 36-39
**Trigger:** The 4th nav tab was still the placeholder `Center(Text(todoTab))`; owner wanted a family shopping list with privacy separation before any v1 release.

**Goal:** Build the placeholder 4th nav tab into a complete shopping-list feature with public/private separation, rich add-item metadata, filtering, and batch management.

**Delivered:**
- **Data + domain foundation (Phase 36):** `shopping_items` Drift table (schema v19→v20, nullable `completedAt` per D-03, explicit `CREATE INDEX` after CR-01 exposed `customIndices` as a no-op), reactive `ShoppingItemDao`, `ShoppingItemRepositoryImpl` (note encryption + JSON tags at boundary), 3 Freezed models + zero-Drift repository interface, `LedgerTypeSelector` → `lib/shared/widgets/`, full `import_guard.yaml` coverage.
- **Use cases + sync (Phase 37):** 6 privacy-gated use cases; `ShoppingItemChangeTracker` (second privacy gate) + `ShoppingItemSyncMapper`; `ApplySyncOperationsUseCase` shopping branch (tombstone + sticky-complete); `SyncOrchestrator` flush; reactive round-trip integration test, no `ref.invalidate`.
- **UI shell (Phase 38):** nav rename + shopping-bag icon, keepAlive provider graph, `ShoppingItemTile`/`ShoppingFilterBar`/`ShoppingEmptyState` (3 variants)/batch chrome/`ShoppingItemFormScreen`, context-aware FAB with all 6 accounting invalidations intact (SC1 gate).
- **i18n + goldens + smoke (Phase 39):** ARB parity, zero stale 待办/Todo, 54 golden baselines (user-approved), provider smoke test, 77.3% shopping coverage.
- **Post-phase hardening (quick tasks 260609-*/260610-ss7/260612-daz):** group filter + private chip, tile/reorder UX (`reorderBatch`→`applyOrder`), form redesign, AppBar title, iOS keychain-accessibility startup fix, and audit W1/W2 closure (fullSync shopping push + receiver listType gate).

**Out of v1.6 scope (carried forward):** running subtotal (SUBTOTAL-01), name autocomplete, category grouping, tag filter, duplicate detection, collapsible completed section, voice-add, APNS push for family additions, price history — see v2 requirements in `.planning/milestones/v1.6-REQUIREMENTS.md`.

**Known close debt** (documented in `.planning/milestones/v1.6-MILESTONE-AUDIT.md`):
- Draft-Nyquist docs: Phases 37/38/39 `nyquist_compliant: false`; Phase 36 validated/compliant
- 37-REVIEW advisories WR-02 (pushedCount telemetry; partially addressed by 260612-daz) / IN-01 (`dynamic ledgerType`) / WR-05 (jsonDecode without local try/catch)
- 260609-ruu form redesign pending on-device visual confirm
- Shopping note plaintext on sync wire by design (transport E2EE); accepted threat T-q260612-04 (inbound shopping delete op ungated — wire carries no listType)

**Archive:** `.planning/milestones/v1.6-ROADMAP.md`, `.planning/milestones/v1.6-REQUIREMENTS.md`, `.planning/milestones/v1.6-MILESTONE-AUDIT.md`, `.planning/milestones/v1.6-phases/`

</details>

<details>
<summary>v1.5 文案与配色统一 (archived)</summary>

**Started:** 2026-05-31
**Shipped:** 2026-06-02 (~2 days)
**Phase numbering:** Phases 31-35
**Trigger:** Half-migrated dual-ledger vocabulary (生存/灵魂/Survival/Soul leaking through ARB values + code identifiers) and scattered hardcoded `Color(0x…)` literals — owner wanted one consistent vocabulary + one semantic palette before any v1 release.

**Goal:** Unify the dual-ledger vocabulary across zh/ja/en + internal identifiers; explore/select a stronger palette (ADR); apply it through a single semantic design-token system replacing scattered hardcoded colors. No new user features.

**Delivered:**
- **Terminology rename (Phase 31):** `LedgerType` enum survival→daily / soul→joy across 242 call sites; `Transaction.joyFullness` replaces `soulSatisfaction`; 25 ARB key roots + zh/ja/en values rewritten to 日常/悦己/ときめき/Daily/Joy; v17→v18 Drift migration (atomic stored enum-value rewrite + `soul_satisfaction`→`joy_fullness`) with Wave-0 raw-sqlite3 contract test; ADR-017 accepted. CR-01 migration regression (from<4 column collision) found in review + fixed in-phase.
- **Palette selection (Phase 32):** 5 directions mined from 7 VoltAgent DESIGN.md refs → 5 Pencil schemes × 6 frames → user-selected Scheme D "Teal Clarity" (teal primary #0E9AA7, Daily teal-navy ↔ Joy gold); ADR-018 ratified post-selection with full light+dark hex-per-role table.
- **Token system + dark rollout (Phase 33):** `AppPalette` ThemeExtension as single source of truth; all `Color(0x…)` literals replaced; AppColors/AppColorsDark shims deleted; full dark mode via `context.palette.*` (zero `isDark` ternaries); 11 on-device visual items human-approved.
- **Golden re-baseline (Phase 34):** 50 masters re-based to teal + 27 new dark masters (77 total, 34 dark); diff-attribution confirms palette-only delta; suite 2281/2281 green, 79.0% filtered coverage.
- **Residual leak closure (Phase 35):** W1 a11y Semantics labels → `l10n.listLedgerDaily`/`listLedgerJoy`; W2 `totalSoulTx`/`totalGroupSoulTx` → `totalJoyTx`/`totalGroupJoyTx` across Freezed models + use-cases + 9 tests.

**Out of v1.5 scope (carried forward):**
- `Book.survivalBalance`/`soulBalance` DB-column rename — out-of-scope per Research A1 / D-06 (would change Drift SQLite column names; needs a further DB migration); defer to a future DB-migration phase before public release
- Remaining hardcoded English a11y `Semantics(label:)` on 5 sort/filter/search/clear controls (IN-02) — no ARB keys exist; defer to a v1.6+ a11y/i18n pass
- Runtime theme-switching / multiple selectable palettes (THEME-V2-01) — exactly one palette applied; now unblocked by the token system
- `home-pocket-palette.pen` v2 sync (Pencil MCP cannot flush to disk in this env) — ADR-018 is authoritative; D-03b contractually deferred

**Known close debt** (documented in `.planning/milestones/v1.5-MILESTONE-AUDIT.md`):
- One pending on-device screen-reader UAT (Phase 35 Truth 1; code grep-verified, tracked in 35-HUMAN-UAT.md)
- Draft-Nyquist documentation debt: Phases 31/32/34/35 `nyquist_compliant: false`; Phase 33 approved/compliant
- 17 stale quick-task tracking stubs from v1.3/v1.4 (metadata drift; all recorded Verified in STATE.md)

**Archive:** `.planning/milestones/v1.5-ROADMAP.md`, `.planning/milestones/v1.5-REQUIREMENTS.md`, `.planning/milestones/v1.5-MILESTONE-AUDIT.md`

</details>

<details>
<summary>v1.4 列表功能 (archived)</summary>

**Started:** 2026-05-29
**Shipped:** 2026-05-31 (~3 days)
**Phase numbering:** Phases 24-30
**Trigger:** v1.3 closed the input axis; the List tab was still a placeholder — owner wanted a kakeibo-style transaction overview before any v1 release.

**Goal:** Build the placeholder List tab into a full transaction overview — month calendar (per-day expense totals + tap-to-filter), sortable/searchable/filterable list, month summary — reusing the v1.3 edit path and surfacing family members' entries.

**Delivered:**
- **Data layer + shared util (Phase 24):** `findByBookIds` multi-book query + `watchByBookIds` stream; extracted `DateBoundaries` to `lib/shared/utils/` (consolidated 6 month-boundary call sites); `SortField`/`SortDirection` enums; 6 DAO tests.
- **Domain + use case (Phase 25):** Freezed `ListFilterState`/`ListSortConfig`, repo interface, `GetListTransactionsUseCase` (execute Future+Result / watch Stream) + `GetListParams`; 8 Mocktail tests; pure-Dart.
- **Providers + shell wiring (Phase 26):** list providers with `keepAlive`-under-`IndexedStack` filter persistence; `ListScreen` replaces shell placeholder.
- **Calendar header (Phase 27):** `table_calendar` grid, `calendarDailyTotalsProvider` per-day totals (expense-only, `_dayKey` normalization, filter-isolated), month nav, day-tap filter, month summary; iOS build gate; human-approved render.
- **Tile + sort/filter bar (Phase 28):** `ListTransactionTile` (swipe-delete via `DeleteTransactionUseCase`, tap-to-edit), day grouping, sort + text search + ledger + multi-category filters AND-composed.
- **List screen + family (Phase 29):** full screen, `RefreshIndicator` pull-to-refresh (honest spinner, dual-invalidate), shadow-book merge, per-row member chip, member + "Mine only" filters; `anyFilterActive` 5-condition fix.
- **i18n + empty states + golden polish (Phase 30):** 3-variant `ListEmptyState`, ja/zh/en ARB, golden baselines; closes LIST-03.

**Out of v1.4 scope (carried to v1.5+):**
- Combined family-calendar per-day totals (v1.4 calendar is own-book only; seam reserved)
- Undo-on-delete SnackBar (needs `RestoreTransactionUseCase`)
- Month settlement / month-lock (结账锁月), income tracking, amount-range filter, "New" badge
- MOD-005 OCR writer landing; FAMILY-V2 privacy hardening; voice-polish + English-voice carries (unchanged from v1.3)

**Known close debt** (documented in `.planning/milestones/v1.4-MILESTONE-AUDIT.md`):
- GAP-2: LIST-02 `watchByBookIds` reactive stream is dead code (reactivity via manual `ref.invalidate`); either consume `useCase.watch()` or delete the 3-layer chain + fix stale shell comments
- Draft-Nyquist documentation debt: Phases 25/26/27/29/30 `nyquist_compliant: false`; Phase 28 approved (`nyquist_compliant: true`)
- GAP-1 (calendar staleness) was the one functional gap — **closed at milestone close** via quick task 260531-u34

**Archive:** `.planning/milestones/v1.4-ROADMAP.md`, `.planning/milestones/v1.4-REQUIREMENTS.md`, `.planning/milestones/v1.4-MILESTONE-AUDIT.md`

</details>

<details>
<summary>v1.3 迭代帐本输入 (archived)</summary>

**Started:** 2026-05-22
**Shipped:** 2026-05-26 (~5 days)
**Phase numbering:** Phases 18-23
**Trigger:** "Input flow is too multi-step, mis-tap-prone, voice-unreliable" — owner feedback after v1.2

**Goal:** 把账本录入从「多步、易误按、语音不准」打磨成「单屏、稳准、语音可信」的核心体验，并复用同一 details 表单作为已存账本的编辑入口。

**Delivered:**
- **Shared details form foundation (Phase 18):** Single `TransactionDetailsForm` widget reused by 4 hosts (ManualOneStepScreen, VoiceInputScreen, TransactionEditScreen, OcrReviewScreen) via Freezed `TransactionDetailsFormConfig.when(.new/.edit)`; `UpdateTransactionUseCase` preserves `entry_source` verbatim through edits; OCR two-step architectural slot reserved with MOD-005 marker; widget test `ocr_two_step_seam_test.dart` enforces seam.
- **Manual one-step + keypad polish (Phase 19):** `ManualOneStepScreen` collapses 2-screen chain into single screen; `math.max(48.0, rawKeyHeight)` non-negotiable touch-target floor; 6 golden baselines (ja/zh/en × light/dark); `manual_save_entry_source_test.dart` verifies `entry_source='manual'` against real Drift DB.
- **Voice number parser zh + ja (Phase 20):** Locale-aware numeral state machines (千/百/十/零/万) + JA numeral dictionary in `lib/infrastructure/voice/`; `VoiceChunkMerger` 2.5s continued-listening window via `SpeechRecognitionService.restartListen()`; zh corpus 48/50 (96%) + ja corpus 50/50 (100%); anchor cases zh 2204 / 1840, ja 2204 / 1840 verbatim verified. VOICE-02 device UAT (8 anchor cases) cleared in Phase 23.
- **Voice category resolver L2 enforcement (Phase 21):** `VoiceCategoryResolver` always-L2 contract via `_ensureL2` 3-stage fallback (override map → `${l1Id}_other` convention → `findByParent.first` safety net); 19-L1 architecture invariant test; merchant DB (12 L2 entries) + synonym dict (59 seed entries) extensible without code changes — runtime-insert tests for 珍珠奶茶 (zh) + タピオカ (ja); legacy `FuzzyCategoryMatcher` + Levenshtein deleted.
- **Voice one-step integration + record button UX (Phase 22):** `VoiceInputScreen` embeds `TransactionDetailsForm`; hold-to-record gesture via `RawGestureDetector` with `Duration.zero`; AnimatedContainer 180ms shape morph + AnimatedSwitcher caption swap to "录音中…"; Stopwatch test enforces `<100ms` perceived state change. Two BLOCKER gaps (G-01 recognizer self-termination, G-02 silent errors) elevated from code review and closed via plans 22-08/09/10 with 4 new ARB error keys + permanent-error mic gate.
- **v1.3 cleanup (Phase 23):** Scanner allow-list cleanup (VOICE-SCANNER-ALLOWLIST); 6 voice-flow surgical fixes (D-05/07/08/09/10/11); 4 mechanical polish items (D-12/13/14/15); REQUIREMENTS.md + 7 SUMMARY frontmatters reconciled (D-04); 9/9 carried device UATs run and passed; `voice_input_screen.dart` slimmed 838 → 776 LOC via `VoiceLocaleReadinessMixin` + pure-helper extraction (Plan 23-09) — back under CLAUDE.md `<800` cap.

**Out of v1.3 scope (carried to v1.4+):**
- MOD-005 OCR writer landing — architectural slot reserved with `// MOD-005: flip to EntrySource.ocr when OCR writer ships` marker; schema already accepts 'ocr' literal
- FAMILY-V2-01/02/03 family privacy hardening
- FUTURE-QA-01 release-readiness smoke tests
- FUTURE-DOC-01..06 + FUTURE-TOOL-03 documentation/tooling cleanup
- TOOL-V2-01 fl_chart 1.x upgrade
- VOICE-POLISH-V2-01..08 voice flow polish (Phase 22 WR-02/03/06/07/NEW-02/NEW-03 + IN-03 + Phase 23 WR-06)
- VOICE-EN-V2-01 English voice parser (skeleton only in Plan 23-03)

**Known close debt** (documented in `.planning/milestones/v1.3-MILESTONE-AUDIT.md`):
- Phase 18 + 21 missing VALIDATION.md (Nyquist); Phase 19 + 20 draft + `nyquist_compliant: false`; Phase 22 draft + `nyquist_compliant: true` — documentation-grade debt only
- Phase 22 advisory WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03 — 9 standing warnings + 3 infos on `voice_input_screen.dart` carry as voice-flow polish backlog
- Pre-existing 15 test failures + 4 analyzer findings carry from v1.2 (none touched by v1.3)

**Archive:** `.planning/milestones/v1.3-ROADMAP.md`, `.planning/milestones/v1.3-REQUIREMENTS.md`, `.planning/milestones/v1.3-MILESTONE-AUDIT.md`, `.planning/milestones/v1.3-phases/`

</details>

<details>
<summary>v1.2 Happiness Metric Refresh (archived)</summary>

**Started:** 2026-05-19
**Shipped:** 2026-05-21 (3 days)
**Phase numbering:** Phases 13-17
**Trigger:** ADR-016 ratify (2026-05-19) — Joy metric supersede from density to `Σ joy_contribution`

**Goal:** Package the ADR-016 Joy metric supersede with v1.1-deferred Joy/Analytics backlog into one coherent refresh; redraw HomePage + AnalyticsScreen under the new `Σ joy_contribution` semantics.

**Delivered:**
- **ADR-016 backend foundation (Phase 13):** `HappinessReport.joyContribution` field, `getSoulRowsForJoyContribution` DAO, `joy_cumulative_formatter` (replaced `joy_density_formatter`), `AppSettings.monthlyJoyTarget` SharedPreferences persistence, `GetMonthlyJoyTargetRecommendationUseCase` (ceil-median of past 3 months + fallback baseline 50), density code-path deletion across `lib/`
- **ADR-016 frontend + ARB reconciliation (Phase 14):** HomeHeroCard rebuilt with cumulative center display + sage-green→gold target ring + clamp-at-100% color contract, Settings `JoyTargetSection` with user-configurable target + recommendation display + null-clears-to-recommendation flow, AnalyticsScreen Variant ε with Joy Index promoted to primary KPI, ARB density/ROI vocabulary fully scrubbed across ja/zh/en (key count 487 per locale parity)
- **Custom Time Windows (Phase 15):** Freezed `TimeWindow` sealed value object (week/month/quarter/year/custom), `TimeWindowValidation` calendar-month guard, `selectedTimeWindowProvider` session state, `TimeWindowChip` + `TimeWindowPickerSheet` widgets, six analytics use cases migrated to `(startDate, endDate)`, retired month-chip / MoM-delta UI, HomeHero stays current-month-anchored
- **Per-Category Breakdown + Soul-vs-Survival comparison (Phase 16):** `PerCategoryBreakdownCard` with min-N=3 filter + Other rollup + top-5/expand toggle (HAPPY-V2-01), `SoulVsSurvivalCard` with Soul vs Survival columns (D-04 type gate: `SurvivalLedgerSnapshot` has NO `avgSatisfaction` field, STATSUI-V2-01), 4 new DAO methods + repository surface + 4 use cases + 4 Riverpod providers, 22 new ARB keys × 3 locales, trilingual anti-toxicity widget sweep (24 cases), light/dark goldens for both surfaces
- **Manual-Only Joy Sub-Metric (Phase 17):** Drift schema v16→v17 (`transactions.entry_source` TEXT NOT NULL DEFAULT 'manual' CHECK ∈ {manual, voice, ocr}), `EntrySource` enum + Freezed `Transaction` field + sync mapper with manual fallback, `CreateTransactionParams.entrySource` required-no-default + 3 push-site stampings (voice/manual/demo), `entrySourceFilter: EntrySource?` threaded through 12+ analytics use cases + 16 analytics providers + DAO `AND entry_source = ?` clauses, `selectedJoyMetricVariantProvider` + `JoyMetricVariantChip` widget, HomeHero isolation extended for SC-4 (variant toggle non-effect verification)

**Out of v1.2 scope (carried to v1.3+):**
- FAMILY-V2-01/02/03 — family privacy hardening
- TOOL-V2-01 — fl_chart 1.x upgrade
- MOD-005 OCR
- FUTURE-QA-01 — release-readiness smoke tests

**Known close debt** (documented in `.planning/milestones/v1.2-MILESTONE-AUDIT.md`):
- Phase 13 + 17 lack VERIFICATION.md (live code wired + integration-verified; per-phase verifier artifact never run)
- Phase 13, 14, 17 VALIDATION.md status: draft, `nyquist_compliant: false` (FUTURE-DOC-equivalent)
- 6 pre-existing `family_insight_card_test.dart` failures from Phase 15 ARB drift commit `8d5f136` (`今月、` prefix dropped) — does NOT break any v1.2 flow
- `EntrySource.ocr` literal accepted by schema but no production writer yet (consistent with MOD-005 OCR being a future module)
- 3 quick-task metadata drift entries (tool reports `missing` while STATE.md confirms `verified`)

**Archive:** `.planning/milestones/v1.2-ROADMAP.md`, `.planning/milestones/v1.2-REQUIREMENTS.md`, `.planning/milestones/v1.2-MILESTONE-AUDIT.md`, `.planning/milestones/v1.2-phases/`

</details>

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

Home Pocket (まもる家計簿) is a local-first, privacy-focused family accounting app with a dual-ledger system — the 日常 (Daily) ledger for everyday spending and the 悦己 (Joy / ときめき) ledger for self-investment. Zero-knowledge architecture with 4-layer encryption, P2P family sync, and offline-first design. Target: iOS 14+ / Android 7+ (API 24+). After six milestones, the app ships a single-screen voice-capable ledger entry flow, a calculable Joy metric (`Σ joy_contribution` cumulative semantics) with user-configurable monthly targets, custom analytics time windows, per-category + Daily-vs-Joy comparison surfaces, an audit lens (manual-only Joy variant), a full kakeibo-style transaction list (month calendar with per-day expense totals + tap-to-filter, sortable/searchable/filterable rows, month summary, family-aware display), a unified 日常/悦己/ときめき/Daily/Joy vocabulary across all three locales plus a single semantic design-token system (`AppPalette` — re-valued post-v1.5 to ADR-019 "Sakura Mochi × Wakaba", superseding ADR-018) with full light/dark theming, a complete family shopping list on the 4th nav tab (public/private separation, family sync for public items with private items never entering the pipeline, rich item metadata, filtering, batch management), and — as of v1.7 — foreign-currency ledger entry (SmartKeyboard currency selector + zh/ja voice, transaction-date historical-rate conversion from a free no-key API with an encrypted offline-capable cache, JPY-converted booking amount with original currency/amount/rate preserved as sync-safe fields, list annotation + two-input/one-derived edit) with the JPY-only path left byte-for-byte unchanged.

## Core Value

A family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, with a dual-ledger system that distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations.

## Requirements

### Validated

<!-- Capabilities shipped or confirmed stable. -->

**Existing app baseline (unchanged by milestone work):**

- ✓ Local-first encrypted accounting database (SQLCipher AES-256, 11 Drift tables) — schema bumped v14 → v15 in v1.0 (3 new indices), v15 → v16 in v1.1 (satisfaction default 5 → 2 unipolar), v16 → v17 in v1.2 (`entry_source` column)
- ✓ 5-layer Clean Architecture with "Thin Feature" rule — structurally enforced by `import_guard` (v1.0)
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
- ✓ Explicit, ordered app boot (`AppInitializer`: KeyManager → Database → others) — extracted in v1.0 (CRIT-03)

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

**Shipped in v1.1 (Happiness Metric & Display):**

- ✓ Happiness metric domain (Phase 9): personal metric formulas, family aggregate-only return type, sealed `MetricResult`, soul-only filter, v16 default-2 satisfaction semantics, no-gamification ADRs, full HAPPY-08 picker mapping test coverage
- ✓ HomePage happiness display (Phase 10): personal metric tiles, Best Joy story card, group-mode family insight, empty states, info tooltips, golden coverage
- ✓ AnalyticsScreen Variant δ unified dashboard (Phase 11): KPI mini-hero, Joy-per-¥ trend, satisfaction histogram, story cards, month picker, aggregate-only family insight
- ✓ UI copy rename pass (Phase 12): ARB value rewrites for ja/zh/en, picker sentiment-positive icon ladder, RENAME-07 requirement, ADR-015 lexical hierarchy accepted, refreshed goldens

**Shipped in v1.2 (Happiness Metric Refresh):**

- ✓ **JOYMIG-01** HomeHero principal Joy metric migrated to cumulative `Σ joy_contribution` — v1.2 Phase 14
- ✓ **JOYMIG-02** User-configurable `monthly_joy_target` in Settings + recommendation (ceil-median past 3 months) + fallback baseline 50 — v1.2 Phases 13-14
- ✓ **JOYMIG-03** HomeHero ring resets monthly + fills toward active target — v1.2 Phase 14
- ✓ **JOYMIG-04** Sage-green→gold ring color state machine, clamps at gold at/beyond 100% — v1.2 Phase 14
- ✓ **JOYMIG-05** AnalyticsScreen Joy Index promoted; density (Joy/¥) UI fully removed; `lib/` density-free — v1.2 Phases 13-14
- ✓ **JOYMIG-06** 100% behavior contract — zero discrete events at threshold; structurally enforced by HomeHero source inspection — v1.2 Phase 14
- ✓ **HAPPY-V2-01** Per-category satisfaction breakdown card with min-N=3 filter + Other rollup — v1.2 Phase 16
- ✓ **HAPPY-V2-02** Custom Time Windows (week/month/quarter/year/arbitrary) wired through 6 analytics use cases; HomeHero remains current-month-anchored — v1.2 Phase 15
- ✓ **HAPPY-V2-03** Manual-only Joy sub-metric variant + Drift schema v17 (`entry_source` column) + AnalyticsScreen chip toggle; isolation SC-4 enforced — v1.2 Phase 17
- ✓ **STATSUI-V2-01** Soul-vs-Survival comparison card with anti-toxicity framing (24-case trilingual forbidden-substring sweep) — v1.2 Phase 16
- ✓ **TOOL-V2-02** ARB density/ROI keys removed; ja/zh/en parity locked at 487 keys per locale — v1.2 Phase 14

**Shipped in v1.3 (迭代帐本输入):**

- ✓ **INPUT-03** Single shared `TransactionDetailsForm` widget across 4 hosts (manual, voice, edit, OCR review) — v1.3 Phase 18
- ✓ **INPUT-04** OCR two-step architectural slot reserved (`OcrReviewScreen` mounts shared widget; writer pending MOD-005) — v1.3 Phase 18
- ✓ **EDIT-01** Tap any existing transaction in home recent-tx list → shared form opens pre-populated — v1.3 Phase 18
- ✓ **EDIT-02** Edit-existing path preserves `entry_source` verbatim (manual/voice/ocr; DAO test exercises all 3 literals) — v1.3 Phase 18
- ✓ **KEYPAD-01** SmartKeyboard 48dp non-negotiable touch-target floor + visual-discriminability goldens (ja/zh/en × light/dark) — v1.3 Phase 19
- ✓ **INPUT-01** `ManualOneStepScreen` single-screen manual entry, no "下一步" navigation — v1.3 Phase 19
- ✓ **VOICE-01** Voice parser zh "2千2百零4元" → 2204, ja 「にせんにひゃくよん」 → 2204 — v1.3 Phase 20
- ✓ **VOICE-02** Voice parser intra-pause merge: zh "1千8百4十元" → 1840, ja 「せんはっぴゃくよんじゅう」 → 1840; VOICE-02-DEVICE-VERIFY 8 anchor cases cleared via Phase 23 device UAT — v1.3 Phase 20 (+ Phase 23 23-08)
- ✓ **VOICE-03** Per-locale corpus accuracy: zh 48/50 (96%) + ja 50/50 (100%), both ≥95% — v1.3 Phase 20
- ✓ **VOICE-04** `VoiceCategoryResolver` returns L2 whenever spoken phrase matches merchant DB or synonym dict L2 entry — v1.3 Phase 21
- ✓ **VOICE-05** `_ensureL2` 3-stage fallback ensures L2 always; architecture invariant test enforces across 19 expense L1s — v1.3 Phase 21
- ✓ **VOICE-06** Merchant DB + synonym dict extensible without code changes (runtime-insert tests for 珍珠奶茶 / タピオカ) — v1.3 Phase 21
- ✓ **REC-01** Hold-to-record idle caption via `holdToRecord` ARB key × ja/zh/en; consistent app-wide — v1.3 Phase 22
- ✓ **REC-02** Recording state: AnimatedContainer 180ms shape morph + AnimatedSwitcher caption swap to "录音中…"; Stopwatch test `<100ms` — v1.3 Phase 22
- ✓ **INPUT-02** Voice-driven entry on same single screen as manual; parser fills amount/category/note/merchant in-place; edit any field before save — v1.3 Phase 22

**Shipped in v1.4 (列表功能 / Transaction List):**

- ✓ **CAL-01** Month switch (prev/next + picker) on the List tab — v1.4 Phase 27
- ✓ **CAL-02** Month calendar grid with per-day expense totals (own-book in v1.4; family-combine seam reserved) — v1.4 Phase 27
- ✓ **CAL-03** Tap a day to filter the list to that day; tap the selected day again to clear — v1.4 Phase 27
- ✓ **CAL-04** Current-month expense summary (expense-only basis) on the List tab — v1.4 Phase 27
- ✓ **LIST-01** Scrollable month transaction list; rows show category emoji + name, ledger-color tag, date, tabular-figure amount — v1.4 Phase 28
- ✓ **LIST-02** List updates reactively after add/edit/delete/family-sync (via manual `ref.invalidate`; `watchByBookIds` stream exists but is dead code — GAP-2) — v1.4 Phases 24/26/29
- ✓ **LIST-03** Clear 3-variant empty state when no transactions match month + filters — v1.4 Phase 30
- ✓ **LIST-04** Pull-to-refresh (RefreshIndicator, honest spinner) — v1.4 Phase 29
- ✓ **SORT-01/02/03/04** Sort by date / edit-time / amount + asc/desc toggle — v1.4 Phases 25/28
- ✓ **FILTER-01/02/03/04** Text search (category·merchant·note) + ledger + multi-category filters, AND-composed with one-tap clear — v1.4 Phases 26/28
- ✓ **ROW-01** Tap row → edit via v1.3 `TransactionEditScreen` + shared form (`entry_source` preserved) — v1.4 Phase 28
- ✓ **ROW-02** Swipe-to-delete with confirmation; routes exclusively through `DeleteTransactionUseCase` (soft-delete, hash-chain-safe) — v1.4 Phase 28
- ✓ **FAM-01/02/03/04** Family shadow-book merge + per-row owner attribution + member filter + "Mine only" — v1.4 Phase 29

**Shipped in v1.5 (文案与配色统一 / Terminology & Color Unification):**

- ✓ **TERM-01/02/03/04** Trilingual ledger-vocab rename — user-facing ARB values read 日常/悦己 (zh), 日常/ときめき (ja), Daily/Joy (en) everywhere; soul_satisfaction surface → joyFullness; D-17 non-literal phrasings normalized — v1.5 Phase 31 (Plans 31-02/03)
- ✓ **TERMID-01** ARB key roots renamed (`soulLedger`→`joyLedger`, `survival*`→`daily*`, `soulSatisfaction`→`joyFullness`) + call sites regenerated — v1.5 Phase 31 Plan 03
- ✓ **TERMID-02** `AppColors` ledger symbols renamed (survival→daily, soul→joy + dark-derived joyFullness/joyRoi); `tagGreen` repointed to `joyLight`; ~79 call sites — v1.5 Phase 31 Plan 04
- ✓ **TERMID-03** `LedgerType` enum rename + Drift v17→v18 migration (value rewrite + CHECK recreate + `soul_satisfaction`→`joy_fullness` column) + ~9 soul*/survival* files/classes renamed (history-preserving `git mv`); analyze-clean + custom_lint-clean gates green; terminology golden re-baseline (0 pixel drift, D-19) — v1.5 Phase 31 Plans 02/05. CR-01 migration regression (from<4 column-name collision) found in code review and fixed in-phase with regression tests.
- ✓ **TERMID-04** ADR-017 Terminology Unification records canonical locale mapping + identifier convention + v18 migration decision; ADR-015 append-only pointer; REQUIREMENTS.md out-of-scope amended (D-06) — v1.5 Phase 31 Plan 06
- ✓ **PALETTE-01** Design references mined from 7 VoltAgent brand DESIGN.md files → 5 distinct candidate palette directions with mood/lineage/per-role hex + WCAG flags — v1.5 Phase 32 Plan 01
- ✓ **PALETTE-02** 5 full color schemes × 6 frames (home-hero / list / analytics × light+dark) rendered as Pencil mockups with per-scheme WCAG pass — v1.5 Phase 32 Plan 02
- ✓ **PALETTE-03** User selected Scheme D "Teal Clarity" (rejecting all coral-anchored options); ADR-018 ratified post-selection with full light+dark hex-per-role table — v1.5 Phase 32 Plan 03
- ✓ **COLOR-01** All `Color(0x…)` literals removed from `lib/features/`, `lib/application/`, `lib/shared/` (grep gate empty; architecture scan test green) — v1.5 Phase 33
- ✓ **COLOR-02** ADR-018 palette applied consistently across all surfaces (correct 日常 teal-navy / 悦己 gold accents; no stale coral/purple); 11 on-device visual items human-approved — v1.5 Phase 33
- ✓ **COLOR-03** Single semantic token system — `AppPalette` ThemeExtension is sole source; AppColors/AppColorsDark shims deleted; duplicate constants removed — v1.5 Phase 33
- ✓ **COLOR-04** Goldens re-baselined to teal (77 masters, 34 dark) with diff-attribution; full suite 2281/2281 green, 79.0% filtered coverage — v1.5 Phase 34
- ✓ **THEME-V2-02** Full dark-mode rollout pulled forward (D-07) — every feature surface resolves dark via `context.palette.*`; zero `isDark` ternaries in `lib/features/` — v1.5 Phase 33
- ✓ **v1.5 audit W1/W2 closure** (Phase 35) — W1: hardcoded 'Survival ledger'/'Soul ledger' a11y Semantics labels → `l10n.listLedgerDaily`/`listLedgerJoy`; W2: `totalSoulTx`/`totalGroupSoulTx` → `totalJoyTx`/`totalGroupJoyTx` across Freezed models + use-cases + 9 tests

**Shipped in v1.6 (购物清单 / Shopping List):**

- ✓ **SHOP-01..04** Public/private segmented lists, item tiles (name + secondary metadata), dual-ledger accent border, 3-variant empty states — v1.6 Phases 36/38
- ✓ **DONE-01..03** Tap-to-complete with animated strikethrough, completed-to-bottom via DAO ordering, clear-all-completed with confirmation — v1.6 Phases 36-38
- ✓ **ITEM-01..05** Name-only-required add/edit form with optional ledger/category/tags/note/quantity/estimated price, reusing existing selectors; estimatedPrice integer + note encrypted at repository boundary — v1.6 Phases 36-38
- ✓ **FILT-01..03** Ledger/category/status chip filtering, shared across segments with reset-on-switch (D5), one-tap clear — v1.6 Phase 38
- ✓ **MGMT-01..03** Swipe-delete with confirmation, long-press batch-select with select-all + batch-delete, swipe disabled in batch mode — v1.6 Phases 37/38
- ✓ **SYNC-01..06** Public items sync via existing E2EE family_sync (attribution chips, sticky-complete D-03, tombstone safety, reactive Drift delivery); private items excluded at use-case + tracker + receiver gates; listType immutable (D6) — v1.6 Phases 37/38 + quick task 260612-daz (receiver gate + fullSync reconcile)
- ✓ **NAV-01..03** Context-aware FAB (accounting invalidations intact), 待办→购物清单/買い物リスト/Shopping List rename + shopping-bag icon, ARB parity ja/zh/en — v1.6 Phases 38/39
- ✓ Drift schema v19→v20 (`shopping_items` table, explicit index creation); 54 shopping golden baselines; sort-mode UX (`reorderBatch`→`applyOrder` single mechanism) via quick-task series — v1.6

**Shipped in v1.7 (多币种支持 / Multi-Currency):**

- ✓ **CURR-01..05** SmartKeyboard currency key → `CurrencySelectorSheet` (JPY-first, recent-use reorder, full-ISO search), session-remembered last currency (resets to JPY on restart), JPY domestic mode untouched, per-ISO-minor-unit decimal entry — v1.7 Phase 42
- ✓ **RATE-01..06** Transaction-date historical rate from Frankfurter (+ fawazahmed0 fallback), per-(date,currency) cache (zero-network repeat, permanent historical / short-TTL today), offline fallback with staleness date, manual override, weekend/holiday actual-date surfacing, date-change re-fetch preserving overrides — v1.7 Phase 41
- ✓ **STORE-01..05** JPY-converted integer in existing `amount` + 3 nullable fields (original currency/amount/rate), `(originalAmount × appliedRate).round()` contract, null-safe family sync both directions, hash-scope ADR-021 (currency fields excluded), CNY/JPY `¥` disambiguation; Drift v20→v21 — v1.7 Phase 40
- ✓ **DISP-01..04** Live JPY conversion preview during entry, foreign-row list annotation, full original record in detail/edit, two-input/one-derived edit (ADR-022 D-01 supersedes the "bidirectional" wording — JPY read-only derived) — v1.7 Phase 42
- ✓ **VOICE-CUR-01..03** zh/ja voice currency-word recognition (美元/欧元/英镑/港币/澳元/加元 + ドル/ユーロ/ポンド/香港ドル/豪ドル → ISO; bare 元 locale-routed, bare ドル→USD), detected currency flows through the shared form and triggers the normal rate-fetch — v1.7 Phase 42
- ✓ Single `convertToJpy()` conversion site (ADR-020); never-block-save invariant (zero HTTP in accounting use cases); first external network dependency (outbound rate queries only, no user data) — v1.7

### Active

<!-- v1.8 统计页面重设计 — requirements defined in .planning/REQUIREMENTS.md (REQ-IDs), mapped to phases by .planning/ROADMAP.md. -->

**v1.8 统计页面重设计 (active, started 2026-06-15).** Requirements live in `.planning/REQUIREMENTS.md`; phase mapping in `.planning/ROADMAP.md`. Theme: full overhaul of the analytics/statistics page — more practical (income/expense + savings-rate overview, spending trends & drill-down) and emotionally surfacing 悦己 self-spending so users feel good about spending on themselves, within the permanent ADR-012 anti-gamification constraint. A dedicated HTML design-exploration phase (deep-research the current `lib/features/analytics/` implementation → multiple HTML mockup directions → thorough discussion → selection) gates development.

### Out of Scope

<!-- Explicit boundaries carried forward. -->

- **Shopping-list completion → transaction linkage** — locked out by v1.6 D3; completing an item only checks it off (record expenses via the normal FAB)
- **Shopping v2 backlog** — running subtotal, name autocomplete, category grouping, tag filter, duplicate detection, collapsible completed section, voice-add, APNS push for family additions, price history (see `.planning/milestones/v1.6-REQUIREMENTS.md` v2 section)
- **Live intraday exchange rates** — ECB publishes once per business day; no free real-time source without an API key; per-day granularity matches how banks post transactions (v1.7 exclusion)
- **Retroactive mass rate-update on historical transactions** — destroys hash-chain integrity and analytics reproducibility; per-transaction locked rate only (v1.7 exclusion)
- **Per-user home currency other than JPY** — architectural rewrite of analytics/summaries, not an increment; original-amount annotation serves non-JPY thinkers (v1.7 exclusion)
- **Automatic currency detection without an explicit currency word** — "Dollar"-class ambiguity adds friction to the 95% JPY-only path; explicit words only, ドル→USD default (v1.7 exclusion)
- **Multi-currency v2** — "remember this rate" (CUR-V2-01), per-currency analytics sub-totals (CUR-V2-02), shopping `estimatedPrice` multi-currency (SHOP-CURRENCY-V2) — deferred, see `.planning/milestones/v1.7-REQUIREMENTS.md`
- **Combined family-calendar per-day totals** — v1.4 calendar is own-book only; combining members' per-day totals deferred to v1.5+ (seam reserved in `calendarDailyTotalsProvider`)
- **Undo-on-delete SnackBar** — v1.4 swipe-delete is confirm-only soft-delete; undo needs a `RestoreTransactionUseCase` (deferred)
- **Month settlement / month-lock (结账锁月), income tracking, amount-range filter, "New" badge** — explicit v1.4 list-feature exclusions; candidates for a later milestone
- **`Book.survivalBalance`/`soulBalance` DB-column rename** — v1.5 terminology rename deliberately carved these out (Research A1 / D-06); renaming changes Drift SQLite column names (`survival_balance`/`soul_balance`) and needs a further DB migration. Model↔repo↔DAO↔table are internally consistent on the old name; defer to a future DB-migration phase before public release
- **Remaining hardcoded a11y `Semantics(label:)` strings** — 5 sort/filter/search/clear controls in `list_sort_filter_bar.dart` (v1.5 IN-02); same leak class as the W1 fix but no ARB keys exist; defer to a v1.6+ a11y/i18n pass
- **Runtime theme-switching / multiple selectable palettes (THEME-V2-01)** — v1.5 applies exactly one palette (ADR-018); runtime accent-switching now unblocked by the `AppPalette` token system but remains a future item
- **`recoverFromSeed()` key-overwrite bug fix** — HIGH-severity per CONCERNS.md but security-architecture changes are out of scope; deferred to FUTURE-ARCH-04
- **Riverpod 3.x upgrade** — confirmed `analyzer` version conflict with `json_serializable` (deferred to FUTURE-TOOL-01)
- **`sqlite3_flutter_libs` adoption** — SQLCipher conflict; actively rejected by CI guardrail
- **Removal of historical deprecated documentation** — deprecated *code* is deleted; deprecated *doc entries* (e.g., MOD-009 index entry) remain as historical record
- **DCM (paid) audit pipeline upgrade** — deferred to FUTURE-ARCH-03
- **Cross-period Joy comparison** (this month vs last month) — hard-blocked by ADR-012 §4 and ADR-016 §3 (cross-milestone permanent)
- **Joy achievement notifications / milestone toasts** — hard-blocked by ADR-012 §2 and ADR-016 §5 (cross-milestone permanent)
- **Family member Joy leaderboards** — hard-blocked by ADR-012 §6 (cross-milestone permanent)
- **Streak displays (consecutive days, etc.)** — hard-blocked by ADR-012 §5 (cross-milestone permanent)
- **Public sharing of Joy data** — hard-blocked by ADR-012 §5 (cross-milestone permanent)

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

- **Current state (post-v1.7):** **v1.7 多币种支持 shipped 2026-06-14** (197 commits vs v1.6, 246 files, +33,923/−2,248 LOC). New `lib/infrastructure/exchange_rate/` + `lib/application/currency/` + `lib/features/currency/` modules; Drift schema **v21** (`exchange_rates` cache table + 3 nullable `transactions` columns); `connectivity_plus ^7.1.1` added; first external network dependency (outbound rate queries only, no user data, offline-capable via cache + manual rate); ADR-020/021/022 recorded; single `convertToJpy()` conversion site. Suite **2786/2786** green; analyze 0. Audit `tech_debt` accepted (23/23 requirements, 3/3 phases, 6/6 seams, E2E complete; Phase 42 4/4 device UAT passed); residual is draft-Nyquist docs (P40/41/42). OCR ledger entry hidden behind reversible `kOcrEntryEnabled` flag (260614-iww).
- **Prior state (post-v1.6):** **v1.6 购物清单 shipped 2026-06-12** (369 commits vs v1.5, 630 files, +58,316/−3,400 LOC — includes the post-v1.5 ADR-019 palette re-value and the 06-09/10 shopping-UX + startup-fix quick-task series). New `lib/features/shopping_list/` module + `lib/application/shopping_list/` use cases; Drift schema v20; `AppPalette` now encodes ADR-019 "Sakura Mochi × Wakaba" (supersedes ADR-018 Teal Clarity); suite 2588/2588 green; analyze 0. Audit `tech_debt` accepted; W1/W2 sync warnings closed at close (260612-daz).
- **Prior state (post-v1.5):** v1.0 shipped 2026-04-29; v1.1 2026-05-05; v1.2 2026-05-21; v1.3 2026-05-26; v1.4 2026-05-31; **v1.5 文案与配色统一 shipped 2026-06-02** (~2 days, 155 commits vs v1.4, 550 files changed, +43,552/-4,650 LOC). Brownfield consistency refactor: unified 日常/悦己/ときめき/Daily/Joy vocabulary across zh/ja/en + internal identifiers (`LedgerType { daily, joy }`, `joyFullness`), v17→v18 Drift migration (stored enum-value rewrite + `soul_satisfaction`→`joy_fullness`), `AppPalette` ThemeExtension (ADR-018 "Teal Clarity") replacing all `Color(0x…)` literals + AppColors/AppColorsDark shims, full dark-mode rollout, 77 golden masters re-baselined to teal. Suite 2281/2281 green. ADR-017 + ADR-018 accepted.
- **Prior state (post-v1.4):** v1.4 列表功能 shipped 2026-05-31 (~3 days, 283 commits, 316 files, +51,409/-2,207 LOC). New `lib/features/list/` kakeibo-style List tab; `table_calendar ^3.2.0`; schema v17.
- **Codebase map:** `.planning/codebase/` was last refreshed 2026-04-25 (`/gsd-map-codebase`). Contents: ARCHITECTURE.md, STACK.md, STRUCTURE.md, CONVENTIONS.md, INTEGRATIONS.md, TESTING.md, CONCERNS.md. **Stale — five milestones of drift** (notably the v1.5 vocabulary/palette rename and schema v18). Refresh via `/gsd:map-codebase` before next milestone planning.
- **Tech stack:** Flutter, Riverpod 3.x (`@riverpod` code-gen, generator 4.x), Freezed, Drift + SQLCipher (schema **v21** post-Phase-40 — `exchange_rates` cache table + 3 nullable `transactions` currency columns), GoRouter, flutter_localizations (intl 0.20.2 pinned), Mocktail, `connectivity_plus ^7.1.1` (v1.7), `http` (exchange-rate API). Theme layer: single `AppPalette` ThemeExtension (`lib/core/theme/app_palette.dart`) encoding ADR-019 "Sakura Mochi × Wakaba"; accessed via `context.palette.*`.
- **Active CI guardrails:** `import_guard` (custom_lint), `riverpod_lint`/`custom_lint`, `coverde` per-file ≥70% with `--deferred` mechanism, `sqlite3_flutter_libs` rejection, `very_good_coverage@v2` ≥70% global, `build_runner` clean-diff
- **Coverage:** Global ~74.6% baseline (last measured post-v1.0); v1.2 + v1.3 added substantial test code (~17k LOC), expect coverage at or above baseline. Re-measure during next milestone planning.
- **Known issues / debt carried forward:**
  - **v1.7 close debt** (per `.planning/milestones/v1.7-MILESTONE-AUDIT.md`): Phases 40/41/42 VALIDATION.md draft + `nyquist_compliant: false` (documentation-grade; suite 2786/2786 green); advisory pre-existing no-rehash-on-edit policy (ADR-021 — editing an amount re-derives JPY but leaves `currentHash` unchanged; intentional); 33 quick-task metadata-drift/voice-backlog stubs acknowledged at close (STATE.md Deferred Items §v1.7); OCR ledger entry hidden behind reversible `kOcrEntryEnabled` flag pending MOD-005 writer landing
  - **v1.6 close debt** (per `.planning/milestones/v1.6-MILESTONE-AUDIT.md`): Phases 37/38/39 VALIDATION.md draft + `nyquist_compliant: false` (Phase 36 validated/compliant); 37-REVIEW advisories WR-02/IN-01/WR-05; 260609-ruu form redesign pending on-device confirm; shopping note plaintext on sync wire by design (accepted threat T-q260612-04)
  - **v1.5 close debt** (per `.planning/milestones/v1.5-MILESTONE-AUDIT.md`): one pending on-device screen-reader UAT (Phase 35 W1 a11y labels; code grep-verified, in 35-HUMAN-UAT.md); Phases 31/32/34/35 VALIDATION.md draft + `nyquist_compliant: false` (Phase 33 approved/compliant); `Book.survivalBalance`/`soulBalance` DB-column rename deliberately out-of-scope (Research A1/D-06); 5 remaining hardcoded a11y Semantics labels (IN-02); `home-pocket-palette.pen` v2 not flushed to disk (Pencil MCP env limitation, D-03b; ADR-018 authoritative); test-fidelity item in `list_transaction_tile_golden_test.dart` (tagText:'Survival' + ja-locale not threaded)
  - **v1.3 close debt** (per `.planning/milestones/v1.3-MILESTONE-AUDIT.md`): Phase 18/21 missing VALIDATION.md; Phase 19/20 VALIDATION.md draft + `nyquist_compliant: false`; Phase 22 VALIDATION.md draft + `nyquist_compliant: true`; Phase 22 advisory WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03 on `voice_input_screen.dart` (voice-flow polish backlog); Phase 23 WR-06 build-side `_voiceLocaleId` reassignment functionally dead; OCR slot hardcodes `EntrySource.manual` pending MOD-005 writer
  - **v1.2 close debt** (per `.planning/milestones/v1.2-MILESTONE-AUDIT.md`): Phase 13/17 missing VERIFICATION.md; Phase 13/14/17 VALIDATION.md status draft + `nyquist_compliant: false`; 6 pre-existing `family_insight_card_test.dart` failures from Phase 15 ARB drift; `EntrySource.ocr` schema-accepted but no writer yet (now also reserved at OCR review screen layer in v1.3)
  - **v1.1 close debt:** 1 Phase 11 human/device UAT verification item (AnalyticsScreen month chip + pull-to-refresh on device)
  - **v1.0 close debt:** 2 INFO-level analyzer warnings in `shadow_books_provider_characterization_test.dart`; MOD-numbering drift in MOD-002/006/007/008; ARCH-008 cites ADR-006 instead of ADR-007; doc-sweep verifiers exist but not in CI; 12 architecture tests run only transitively via coverage job; Phase 03/06/08 missing canonical VERIFICATION.md; Phase 02/04 missing VALIDATION.md; Phase 07 `nyquist_compliant: false`
- **Why next:** v1.7 added the multi-currency axis (the first external network dependency, kept privacy-compatible). Next-wave candidates: **MOD-005 OCR writer landing** (slot reserved since v1.3; OCR entry currently hidden behind reversible `kOcrEntryEnabled` flag from 260614-iww — flip + land the writer), **THEME-V2-01** runtime theme-switching / selectable palettes (unblocked by the `AppPalette` token system), **`Book.*Balance` DB-column rename** (the one remaining vocabulary residual; needs a DB migration — would pair naturally with the next schema bump after v21), **FAMILY-V2-01/02/03** family privacy hardening, **combined family-calendar totals** + **undo-on-delete** (v1.4 deferrals), **Multi-Currency v2** (CUR-V2-01/02, SHOP-CURRENCY-V2), **FUTURE-QA-01** release-readiness QA, **VOICE-POLISH-V2 / VOICE-EN-V2-01**, **TOOL-V2-01** fl_chart 1.x upgrade, or documentation/tooling guardrail cleanup (FUTURE-DOC/TOOL) before any user-facing v1 release. **Refresh `.planning/codebase/` first** — it's now six milestones stale.

## Constraints

- **Tech stack:** Flutter / Dart; intl 0.20.2 pinned; `sqlcipher_flutter_libs` (not `sqlite3_flutter_libs`); Mocktail (mockito removed in v1.0)
- **Quality gates (permanent):** `flutter analyze` MUST be 0 issues; `dart run custom_lint --no-fatal-infos` 0 errors; `import_guard` 0 violations; `riverpod_lint` 0 violations; per-file coverage ≥70% on cleanup-touched files (with `--deferred` for exceptions); global coverage ≥70%; `build_runner` clean-diff; `sqlite3_flutter_libs` rejection
- **Coverage threshold:** Active 70% (lowered from 80% on 2026-04-28 per Phase 8 amendment; FUTURE-TOOL-03 to revisit)
- **Documentation:** ADRs are append-only after status `✅ 已接受`; new context appended via `## Update YYYY-MM-DD: <topic>` at file end
- **Architecture:** 5-layer Clean Architecture with "Thin Feature" rule, structurally enforced by `import_guard`
- **Theme tokens (ADR-018):** All feature/UI colors via the single `AppPalette` ThemeExtension (`context.palette.*`); no `Color(0x…)` literals outside `lib/core/theme/` (architecture scan test enforces); no `isDark` ternaries or `AppColors`/`AppColorsDark` refs in `lib/features/`. Canonical ledger vocabulary is `daily`/`joy` (ADR-017) — no `survival`/`soul` identifiers in non-generated source
- **Internationalization:** All UI text via `S.of(context)`; ARB key parity locked across ja/zh/en; `flutter gen-l10n` must succeed without warnings; no old-vocabulary terms (生存/灵魂/魂/ソウル/Survival/Soul) in rendered ARB values (grep gate, ADR-017)
- **Database schema:** Drift schema at **v21** (v19→v20 added `shopping_items`; v20→v21 added the `exchange_rates` cache table + 3 nullable `transactions` currency columns); explicit `CREATE INDEX` in both `onCreate` and `onUpgrade` (`customIndices` getter is decorative); SQLCipher AES-256
- **Multi-currency (ADR-020/021/022):** `convertToJpy()` (`currency_conversion.dart`) is the SINGLE JPY conversion site — no inline `* rate` arithmetic anywhere; `exchangeRate` stored as full-precision `TextColumn` (never `RealColumn`); currency fields (`originalCurrency`/`originalAmount`/`appliedRate`) excluded from `calculateTransactionHash` and never rehashed on edit; never-block-save invariant — rate is always pre-computed and passed in, zero HTTP in `CreateTransactionUseCase`/`UpdateTransactionUseCase`; no user data in any rate-API URL; partial-triple invariant — all three currency fields non-null or all null (`Result.error` otherwise)
- **Joy metric semantics (ADR-016):** `Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)` is the single Joy expression. Density (Joy/¥) is retired permanently.
- **No-gamification (ADR-012):** no streaks, no badges, no achievement unlocks, no cross-period delta surfaces, no leaderboards, no public sharing — applies cross-milestone.
- **HomeHero isolation (ADR-016 §3):** HomeHero ring is single-month accumulation, anchored to current calendar month; never affected by AnalyticsScreen time-window selector or Joy-variant audit-lens toggles. Structurally enforced by `home_screen_isolation_test.dart`.

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
| Phase 5 MEDIUM guardrails | MEDIUM cleanup needs automated regression guards | ✓ Good (v1.0) |
| Centralized doc sweep (not per-phase) | Doc churn during refactor is wasted effort | ✓ Good — single Phase 7 sweep aligned all docs (v1.0) |
| Audit re-run as final gate (zero violations) | Without programmatic exit criterion, "done" becomes negotiable | ✓ Good — REAUDIT-DIFF.json `open_in_baseline=0` is the close signal (v1.0) |
| Mocktail big-bang migration (HIGH-07) | CI-generated `*.mocks.dart` strategy added complexity for marginal benefit | ✓ Good — 13 fixtures migrated; mockito removed (v1.0) |
| Coverage threshold 80→70% (Phase 8) | Post-cleanup global coverage at 74.6%; raising bar would block close on baseline-fixable items | ⚠️ Revisit — FUTURE-TOOL-03 |
| Per-file coverage `--deferred` mechanism | 10 files below 70%; raising them in-scope was substantive | ⚠️ Revisit — FUTURE-TOOL-03 |
| Smoke-test execution deferred to v1 release | Owner-driven release gate, not cleanup-initiative gate | — Pending — FUTURE-QA-01 |
| ADR-011 v1.1 amendment with 4-layer narrative | Honest documentation pattern: surface adaptations explicitly | ✓ Good (v1.0) |
| ADR-013 per-tx PTVF scaling (α=0.88) | Single calibrated formula that survives ADR-016 supersede | ✓ Good — still active and consumed by `Σ joy_contribution` (v1.1, carried to v1.2) |
| ADR-014 unipolar positive satisfaction (default=2, scale 1..10) | Anchor metric semantics, never permit value-judgment framing | ✓ Good — D-04 type-system gate in Phase 16 enforces in code (v1.1, carried to v1.2) |
| ADR-016 Joy supersede (density → Σ joy_contribution) | Density was conceptually clean but visually unintuitive; cumulative is what users mentally model | ✓ Good — full migration completed in 1 backend + 1 frontend phase (v1.2) |
| Monthly Joy target fallback baseline = 50 (Phase 13 spike) | Needed a sane recommendation when <3 months of soul data; 50 chosen via simulation | — Pending — re-evaluate after real-user data |
| HomeHero ring: monthly reset + no discrete 100% events | ADR-012 §2 / ADR-016 §5 hard contract — gamification is the enemy of honest money | ✓ Good — structurally absent in `home_hero_card.dart` (v1.2) |
| Σ joy_contribution single-Joy-expression (no density anywhere in `lib/`) | Prevent metric drift back to Joy/¥ via partial implementations | ✓ Good — `grep -rn 'density\|joyPerYen' lib/` returns 0 hits (v1.2) |
| Custom Time Windows: HomeHero isolation kept | AnalyticsScreen window selector must never bleed into HomeHero ring semantics (single-month invariant) | ✓ Good — structural test enforcement + zero forbidden imports in `lib/features/home/` (v1.2) |
| Manual-only as audit-lens (not gating) | User wants visibility into Joy data quality without breaking the universal Joy metric | ✓ Good — AnalyticsScreen-scope chip toggle, HomeHero untouched (v1.2) |
| `entry_source` CHECK ∈ {manual, voice, ocr} | Forward-compat for MOD-005 OCR; manual fallback at sync boundary | ✓ Good — schema v17 stable; OCR writer slot reserved (v1.2) |
| Phase 13 + 17 ship without VERIFICATION.md | Single-developer flow; verification ran transitively via integration check at milestone close | ⚠️ Accept — recorded as documentation-grade close debt (v1.2) |
| 5-phase split (18-22) + cleanup phase (23) for v1.3 | Separates voice number parser (state-machine corpus) from voice category resolver (database resolution); isolates voice integration phase; cleanup phase chosen inline (vs carry to v1.4) for same-milestone debt absorption | ✓ Good — independent test surfaces, clean wave parallelism, 9/9 device UATs run in Phase 23 (v1.3) |
| Phase 18 ships first as v1.3 foundation | INPUT-03 shared widget unblocks INPUT-01 (manual), INPUT-02 (voice), EDIT-01/02 (edit-from-list) | ✓ Good — 4 hosts consume single `TransactionDetailsForm` via `Config.when(.new/.edit)` (v1.3) |
| Hold-to-record gesture (vs tap-to-toggle) | Long-press model is the dominant mobile voice-input pattern; reduces accidental activation | ✓ Good — RawGestureDetector with `Duration.zero` works on iOS + Android; consistent app-wide (v1.3) |
| `_ensureL2` 3-stage fallback (override → `${l1Id}_other` convention → `findByParent.first`) | Always-L2 contract via deterministic fallback; data-driven extensibility | ✓ Good — architecture invariant test enforces 19 expense L1s (v1.3) |
| Phase 22 G-01/G-02 elevated to BLOCKER from code review | Recognizer self-termination + silent errors are production-risk; cannot be advisory-deferred | ✓ Good — closed in plans 22-08/09/10 before Phase 22 close (v1.3) |
| OCR slot hardcodes `EntrySource.manual` pending MOD-005 | Schema accepts 'ocr' literal already (v1.2); v1.3 reserves architectural slot only with `// MOD-005: flip when writer ships (D-12)` marker | — Pending — MOD-005 OCR writer landing (v1.4+) |
| Plan 23-09 LOC-cap extraction (`voice_input_screen.dart` 838 → 776) | CLAUDE.md `<800` line cap; `VoiceLocaleReadinessMixin` + 3 pure helpers preserve behavior | ✓ Good — zero behavior change, cap re-cleared (v1.3) |
| Phase 23 cleanup phase inline (vs carry to v1.4) | Same-milestone debt absorption: surgical fixes + documentation reconciliation + device UAT runbook in single phase | ✓ Good — 9/9 plans complete; 9/9 device UATs pass; LOC-cap closed (v1.3) |
| v1.4 calendar own-book only (family-combine deferred) | Keep v1.4 list feature scoped; combining members' per-day totals adds multi-book aggregation cost | ✓ Good — `calendarDailyTotalsProvider` seam reserved; deferred to v1.5+ (v1.4) |
| `keepAlive: true` filter/sort state under `IndexedStack` | Filter/search/sort must survive tab switches; natural under IndexedStack | ✓ Good — state persists across tabs (v1.4 Phase 26) |
| Calendar provider isolated from filter state (`_dayKey` normalization) | Watching search/filter would re-render 31 day cells per keystroke | ✓ Good — provider watches only bookId/year/month (v1.4 Phase 27) |
| Swipe-delete confirm-only soft-delete, no undo | Undo needs `RestoreTransactionUseCase`; soft-delete keeps hash-chain intact | — Pending — undo deferred to v1.5+ (v1.4) |
| LIST-02 reactivity via manual `ref.invalidate` (not `watchByBookIds` stream) | Stream chain built but every mutation site already invalidates; stream went unconsumed | ⚠️ Revisit — GAP-2 dead-code debt: consume `useCase.watch()` or delete the 3-layer chain (v1.4) |
| GAP-1 fixed inline at milestone close (quick task) vs carry to v1.5 | One small, precisely-diagnosed wiring gap; cheaper to close now than track | ✓ Good — quick task 260531-u34 invalidates `calendarDailyTotalsProvider` at sync + FAB sites (v1.4) |
| Terminology workstream (P31) before palette workstream (P32-34) | Land `AppColors.survival→daily`/`soul→joy` symbol rename first so the COLOR token system is built on already-renamed symbols, eliminating churn | ✓ Good — Phase 33 AppPalette consumed renamed vocabulary with no rework (v1.5) |
| v18 migration rewrites stored `ledger_type` values + renames `soul_satisfaction`→`joy_fullness` (D-02/D-16) | Vocabulary must be consistent in persisted data, not just code; CHECK constraint recreate keeps DB honest | ✓ Good — Wave-0 contract test + CR-01 regression test green; round-trip serializes `.name` → 'daily'/'joy' (v1.5) |
| `Book.survivalBalance`/`soulBalance` carved out of v1.5 (Research A1 / D-06) | Renaming Drift columns is a separate DB migration; v1.5 scoped to `transactions.ledger_type` + `soul_satisfaction` only | — Pending — deferred to a future DB-migration phase before public release (v1.5) |
| PALETTE-03 hard user-selection gate before Phase 33 | One palette must be human-chosen before encoding it as the token contract; ADR ratified only post-selection | ✓ Good — user picked Scheme D after rejecting coral; ADR-018 flipped to 已接受 only post-selection (v1.5) |
| Single `AppPalette` ThemeExtension as sole color source (delete AppColors/AppColorsDark shims) | One semantic token system prevents color drift; `context.palette.*` resolves light/dark via the registered extension | ✓ Good — 0 `Color(0x…)` literals, 0 shim refs, 0 `isDark` ternaries in features (v1.5) |
| Full dark-mode rollout pulled forward into Phase 33 (D-07, absorbs THEME-V2-02) | Dark mode is cheapest to land while every surface is already being re-tokenized | ✓ Good — every feature surface resolves dark via tokens; THEME-V2-02 no longer a v2 item (v1.5) |
| Phase 34 dedicated to golden re-baseline (isolated from token migration) | Keep visual verification clearly attributable to the palette change; diff-attribution catches unintended deltas | ✓ Good — 77 masters re-based, palette-only delta confirmed, suite 2281/2281 (v1.5) |
| Phase 35 inserted to close audit-found W1/W2 leaks (vs accept as debt) | W1 (a11y labels) is genuinely user-facing via screen readers; W2 is milestone-goal-adjacent internal identifiers — cheap to close cleanly | ✓ Good — both re-verified at re-audit (grep exit 1); audit returned tech_debt with W1/W2 closed (v1.5) |
| 4-phase consolidated roadmap for v1.6 (vs initial 7) | User-directed consolidation: data+domain+guard / use-cases+sync / shell+widgets / i18n+goldens+smoke | ✓ Good — 27 plans across 4 phases executed in ~2 days with wave parallelism (v1.6) |
| D1 segmented public/private lists (not per-item flag) + D6 visibility immutable after creation | Two independent lists are simpler to reason about; immutability eliminates the public→private sync-tombstone edge case | ✓ Good — D37-04 invariant enforced at use case + (post-260612-daz) receiver merge (v1.6) |
| D3 pure list — no transaction linkage on completion | Keeps the shopping list honest; expenses recorded via the normal entry flow | ✓ Good — zero accounting coupling; SC1 regression gate confirmed FAB invalidations intact (v1.6) |
| D-03 `completedAt` column + sticky-complete merge (supersedes D7 LWW) | Concurrent family edits must not un-complete an item a member just checked off | ✓ Good — tombstone + sticky-complete guards tested in round-trip integration (v1.6) |
| Reactive Drift `readsFrom:` stream mandated from Phase 36 (v1.4 GAP-2 lesson) | v1.4 shipped a dead stream + manual invalidate; v1.6 required reactivity proven by test with NO ref.invalidate | ✓ Good — SC-5/SC4 reactive tests green at repository AND provider layers (v1.6) |
| Privacy enforced at THREE layers (use case → tracker → receiver) | Defense in depth for the privacy-critical SYNC-02; receiver gate added when audit W2 showed sender-only enforcement | ✓ Good — dual sender gates (Phase 37) + receiver gate/pin (260612-daz); integration-tested (v1.6) |
| Close audit W1/W2 inline at milestone close (vs defer to v1.7) | Same pattern as v1.4 GAP-1 / v1.5 Phase 35: precisely-diagnosed, cheap to close now, privacy-relevant | ✓ Good — quick task 260612-daz, TDD, suite 2588/2588 green (v1.6) |
| `customIndices` getter is decorative — explicit CREATE INDEX in onCreate+onUpgrade (CR-01) | Drift does not consume a `customIndices` getter; declared indices were silently never created | ✓ Good — real-Drift sqlite_master assertion test locks the contract (v1.6) |
| 3-phase consolidated roadmap for v1.7 (vs research 6-phase A→F) | User-directed: data+domain+sync / infra client+use-cases / presentation+voice (voice a parallel wave) | ✓ Good — 20 plans across 3 phases with wave parallelism; mirrors v1.6 7→4 (v1.7) |
| `exchangeRate` stored as full-precision `TextColumn`, not `RealColumn` (ADR-020) | Float round-trip would diverge preview-vs-stored on re-multiplication | ✓ Good — string precision preserved; single `convertToJpy()` rounding site (v1.7) |
| Currency fields excluded from the transaction hash (ADR-021) | Adding fields to the hash formula would invalidate every existing chain | ✓ Good — `calculateTransactionHash` takes only (id, JPY amount, ts, prevHash); chains stay valid (v1.7) |
| No rehash on edit; editing amount re-derives JPY but leaves `currentHash` (ADR-021) | Pre-existing policy; not multi-currency-specific | — Advisory — recorded for awareness; intentional (v1.7) |
| Two-input/one-derived edit (ADR-022 D-01) supersedes DISP-04 "bidirectional linked editing" | Three-field bidirectional editing risks circular update loops; a bidirectional impl would be a defect | ✓ Good — JPY read-only derived via single conversion site; "bidirectional" wording VOID (v1.7) |
| Never-block-save invariant — zero HTTP in accounting use cases (RATE/SC-5) | Local-first: saving a transaction must never depend on the network | ✓ Good — rate pre-computed + passed in; structurally enforced, no URL carries user data (v1.7) |
| Dual-source rate fetch (Frankfurter primary + fawazahmed0 fallback) + per-(date,currency) cache | Free no-key coverage with offline fallback; historical rates permanent, today short-TTL | ✓ Good — RATE-01..06 satisfied; weekend/holiday actual-date surfaced (v1.7) |
| Sync wire-boundary validates the full triple, degrades partial/invalid peer rows to JPY-native | Defense against malformed peer payloads without throwing (CR-01 closure) | ✓ Good — `transaction_sync_mapper.dart` `is`-typed validation; display never reads a partial triple (v1.7) |
| OCR ledger entry hidden behind reversible `kOcrEntryEnabled` flag (260614-iww) | OCR writer not yet landed (MOD-005); hide the entry without touching the reserved infrastructure | — Pending — flip the flag when the MOD-005 writer ships (v1.7) |
| Nyquist documentation debt accepted at v1.7 close | Underlying test coverage exists (suite green); formalizing VALIDATION.md is documentation-grade | ⚠️ Accept — mirrors v1.2–v1.6 close precedent (v1.7) |

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
*Last updated: 2026-06-17 — Phase 46 (卡片体系 / Cards) complete: 7/7 plans, verified 6/6. round-5 B flat 5-card lineup LIVE — within-month spend-trend LineChart (pill tabs; spend dual-line 本月+上月, joy single-line zero cross-period by construction, D-E1) → category donut hero (center 本月支出 count-up, 10 L1 amount-desc legend, full-row tap drill) → 悦己花在哪 custom stacked bar (Row+Flexible, zero fl_chart) → 小确幸 calendar heatmap (custom GridView, zero fl_chart) → satisfaction histogram (native fl_chart 1.2.0 BarChartRodData.label, Stack hack deleted) + group-mode `family_insight` card. New read-only `CategoryDrillDownScreen` (DRILL-01). Data paths = pure Dart over findByBookIds + L1 rollup (zero new DAO, schema stays v21). REDES-02/03 done; JOY-03/JOY-04 Descoped (GATE-03). Executed degraded-sequential on main tree (#683 worktree base-drift). Full suite 2971/2971 green, analyze 0, fl_chart pinned ^1.2.0. Code review: 0 blockers, 4 advisory warnings (WR-01 hardcoded JPY, WR-02 >10-cat reconciliation, WR-03 O(n·k) rollup, WR-04 stale expanded-day refresh) carried to Phase 47/backlog. Visual UAT + golden re-baseline are Phase 47 scope.*

*Prior: 2026-06-17 — Phase 45 (展示外壳重建 / Presentation Shell Rebuild) complete: 7/7 plans, verified 4/4. Pure behavior-preserving structural refactor (D-A1) — `analytics_screen.dart` 739→176 LOC thin shell; 7 inline `_*Card` + `_AnalyticsDataCard` extracted to `widgets/cards/`; new typed `analytics_card_registry.dart` as the single source of both render order and the `_refresh` invalidation union (108→12 LOC, derived, union ⊆ analytics with zero `home/*`). HomeHero isolation now guaranteed by construction (registry zero `home/*` import + structural-invariant test + `home_screen_isolation_test` green); `shadowBooksProvider` direct-invalidate dropped per D-B3 Option A (display-only read retained; group-mode refresh transitive via `familyHappinessProvider`, Assumption A1 proven true). Full suite 2925/2925 green, zero golden re-baseline, `analytics_screen_test` unchanged. ADR-012 §4 expense-side carve-out appended (D-D1). REDES-01 + GUARD-01 validated. Code review: 0 blockers, 1 comment-only warning (WR-01). Visual UAT + golden re-baseline deferred to Phase 47 (zero-visual-change phase).*

*Prior: 2026-06-15 — Milestone v1.8 统计页面重设计 (Analytics Redesign) started. Full overhaul of the statistics page: more practical (income/expense + savings-rate overview, spending trends & drill-down) and emotionally highlighting 悦己 self-spending so users feel good about spending on themselves — within the permanent ADR-012 anti-gamification constraint (the central open design question). Process: a dedicated HTML design-exploration phase (deep-research the current `lib/features/analytics/` implementation → produce multiple HTML design directions → thorough discussion → select one) gates development; build phases follow only after design approval. Scope decided "全面大改"; practical priorities = 收支/结余率总览 + 趋势与下钻. Phase numbering continues from v1.7's Phase 42 → starts at Phase 43.*

*Prior: 2026-06-14 after v1.7 多币种支持 milestone — shipped + archived (3 phases, 20 plans, tag `v1.7`). Foreign-currency ledger entry end to end (SmartKeyboard currency selector + zh/ja voice), transaction-date historical-rate conversion from a free no-key API (Frankfurter + fawazahmed0) with an encrypted offline-capable Drift cache, JPY-converted booking amount + original currency/amount/rate as sync-safe fields, single `convertToJpy()` site, hash invariant preserved (ADR-021), two-input/one-derived edit (ADR-022 D-01). JPY-only path byte-unchanged; first external network dependency (no user data on the wire). Drift schema v20→v21; `connectivity_plus` added. Audit `tech_debt` accepted (23/23 requirements, 3/3 phases, 6/6 seams, E2E complete, Phase 42 4/4 device UAT passed); residual is draft-Nyquist docs (P40/41/42). Suite 2786/2786 green. ADR-020/021/022 accepted. 34 pre-close artifact-audit items acknowledged as deferred (33 quick-task stubs + 1 stale verification flag resolved by UAT).*

*Prior: 2026-06-13 — Phase 41 (汇率服务 Exchange Rate Service) complete: 5/5 plans, verification passed 5/5. `ExchangeRateApiClient` three-source fallback (Frankfurter → fawazahmed0 jsDelivr → Cloudflare) with SC-5 URL privacy + `kDebugMode` log guards; `ExchangeRateCacheService` cache-first orchestration (D-01 today-TTL, D-03 one-shot correctable-proxy re-fetch, D-05 connectivity gate, D-06 cooldown, D-07 fallback priority, D-09 2-year prune); `RateResult`/`RateSignal` sealed unions; `GetExchangeRateUseCase` with ADR-022 dialog/toast signals; `BackupData` D-10 exchange-rate persistence; `connectivity_plus ^7.1.1` (iOS build verified green). Never-block-save invariant enforced (zero HTTP in Create/UpdateTransactionUseCase; cache key on local calendar date, no UTC skew). Code review fixed 2 Critical (CR-01 backup-import rate validation — closes the Phase 40 CR-01 sync-validation gap for the import path; CR-02 UTC/local cache-key skew) + 4 warnings, see 41-REVIEW.md. Suite 2717/2717 green, analyze 0 issues. RATE-01..06 validated.*

*Prior: 2026-06-12 — Phase 40 (数据与同步基础) complete: 6/6 plans, verification passed 5/5. Schema v20→v21 (exchange_rates cache table + 3 nullable transactions columns with explicit indexes), ADR-020/021/022 recorded (string-typed rate precision / hash chain excludes currency fields / edit semantics), CNY `CN¥` symbol disambiguation with re-baselined goldens, ExchangeRate domain model + DAO + repository + Riverpod wiring, convertToJpy single rounding site, TransactionSyncMapper null-safe bidirectional passthrough, partial-triple invariant in CreateTransactionUseCase. Suite 2635/2635 green, analyze 0 issues. Code review advisory: CR-01 (sync-ingestion path bypasses triple validation — close in Phase 41/42) + 10 warnings, see 40-REVIEW.md. STORE-01..05 validated.*

*Prior: 2026-06-12 — Milestone v1.7 多币种支持 (Multi-Currency) started. Keypad currency selection (common currencies + searchable full ISO list), transaction-date exchange-rate lookup via free API with local daily cache + manual override fallback, JPY-converted booking amount with original currency/amount/rate stored as new transaction fields, manual + edit + voice entry coverage, list annotation + detail display. First external network API dependency — outbound rate queries only, no user data; offline fully usable via cache + manual rate.*

*Prior: 2026-06-12 after v1.6 购物清单 milestone — shipped + archived (4 phases, 27 plans, tag `v1.6`). The placeholder 4th nav tab is a complete family shopping list: public/private segmented lists (D1/D6), rich optional item metadata (D4), filtering with segment-switch reset (D5), batch management, family sync for public items via the existing E2EE pipeline with three-layer privacy enforcement, schema v19→v20, ARB parity + 54 goldens. Audit `tech_debt` accepted (27/27 requirements, 4/4 phases, 6/6 seams, 10/10 flows); W1/W2 sync warnings closed at close via quick task 260612-daz; suite 2588/2588 green.*

*Prior: Last updated: 2026-06-08 — Phase 38 (presentation shell + UI widgets) complete: shopping-list UI fully wired into the nav shell — tile, form, filter bar, empty states, batch-select, context-aware FAB (SC1 no accounting regression); suite 2445/2445 green, human-verify approved. Phase 37 (application use cases + sync integration) complete: 6 privacy-gated shopping-list use cases + reactive family-sync wiring. Phase 36 (data + domain + import guard) complete. Milestone v1.6 购物清单 (Shopping List). Builds the placeholder 4th nav tab into a full shopping-list feature: public/private lists (public family-syncs, private local-only), add-item with optional ledger/category/tags/note + quantity + estimated price, filter, completed-to-bottom + one-click clear, edit/delete/batch-delete, context-aware FAB add entry, and 待办→购物清单 rename across zh/ja/en. Locked decisions: D1 segmented public/private lists, D2 context-aware FAB, D3 no transaction linkage, D4 quantity + estimated price both added. Phase numbering continues from Phase 36.*

*Prior: 2026-06-02 after v1.5 文案与配色统一 milestone — shipped + archived (5 phases, 24 plans, tag `v1.5`). Brownfield consistency refactor: unified 日常/悦己/ときめき/Daily/Joy vocabulary across zh/ja/en + internal identifiers (`LedgerType { daily, joy }`, v17→v18 migration), and consolidated all hardcoded colors into a single `AppPalette` ThemeExtension (ADR-018 "Teal Clarity") with full dark-mode rollout. Audit `tech_debt` accepted (15/15 requirements, 5/5 phases, 6/6 integration seams); residual is one pending on-device screen-reader UAT, draft-Nyquist docs (P31/32/34/35), and the out-of-scope `Book.*Balance` DB-column carve-out. ADR-017 + ADR-018 accepted.*

*Prior: 2026-06-02 — Phase 35 (Close vocab leaks) complete: W1 a11y Semantics labels → l10n, W2 totalSoulTx→totalJoyTx. Prior: Phase 34 golden re-baseline (teal), Phase 33 AppPalette token system, Phase 32 palette ADR-018, Phase 31 terminology + v18 migration. Started 2026-05-31.*

*Prior: 2026-05-31 after v1.4 列表功能 milestone — shipped + archived (7 phases, 29 plans, tag `v1.4`). Full kakeibo-style List tab. Audit `tech_debt` accepted (22/22 requirements, 7/7 phases, 7/7 flows); GAP-1 closed via quick task 260531-u34; GAP-2 dead-code + draft-Nyquist docs carried as debt.*
