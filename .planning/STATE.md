---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: 多币种支持
status: planning
last_updated: "2026-06-12T03:24:24.654Z"
last_activity: 2026-06-12
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-12 after v1.6 milestone)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations
**Current focus:** v1.6 shipped — planning next milestone (run /gsd-new-milestone)

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-06-12 — Milestone v1.7 started

## Last Milestone Snapshot (v1.6)

- **Phases:** 4 (36-39)
- **Plans:** 27
- **Duration:** 2026-06-07 → 2026-06-08 phase execution; quick-task hardening through 2026-06-12
- **Commits:** 369 (vs v1.5 tag); 630 files changed; +58,316 / −3,400 LOC (range includes post-v1.5 ADR-019 palette re-value + 06-09/10 quick-task series)
- **Audit Status at Close:** `tech_debt` — accepted (27/27 requirements, 4/4 phases verified `passed`, 6/6 seams wired, 10/10 E2E flows; integration checker executed 32/32 cross-phase tests). W1 (fullSync had no shopping reconcile despite tracker comment) + W2 (receiver trusted inbound listType) **closed at close** via quick task 260612-daz, re-verified analyze 0 + full suite 2588/2588. Residual: Phases 37/38/39 draft-Nyquist; 37-REVIEW advisories WR-02/IN-01/WR-05; 260609-ruu 待真机确认; note-plaintext-on-wire by design + accepted threat T-q260612-04 (inbound shopping delete ungated)
- **Outcome:** Placeholder 4th nav tab → complete family shopping list in new `lib/features/shopping_list/` + `lib/application/shopping_list/`: public/private segmented lists (listType immutable, D6), name-only-required form with optional ledger/category/tags/encrypted-note/quantity/estimatedPrice reusing existing selectors, tap-to-complete + completed-to-bottom DAO ordering, chip filters with segment-switch reset (D5), swipe-delete + batch-select + clear-completed, 3-variant empty states, context-aware FAB (6 accounting invalidations intact), family sync for public items (attribution chips, sticky-complete D-03, tombstone safety, reactive readsFrom delivery) with three-layer privacy enforcement (use case + tracker + receiver), schema v19→v20, ARB parity + 54 goldens. Sort-mode UX rebuilt on single `reorderBatch`→`applyOrder` mechanism; iOS keychain-accessibility startup fix (260610-ss7)
- **Tag:** `v1.6`

## Previous Milestone Snapshot (v1.5)

- **Phases:** 5 (31-35)
- **Plans:** 24
- **Duration:** 2026-05-31 → 2026-06-02 (~2 days)
- **Commits:** 155 (vs v1.4 tag); 550 files changed; +43,552 / -4,650 LOC
- **Audit Status at Close:** `tech_debt` — accepted (15/15 requirements, 5/5 phases verified `passed`, 6/6 cross-phase integration seams wired). Re-audit after Phase 35 closed the W1/W2 leaks the initial 2026-06-01 audit found. Residual: 1 pending on-device screen-reader UAT (P35 W1); Phases 31/32/34/35 draft-Nyquist (`nyquist_compliant: false`, Phase 33 approved/compliant); out-of-scope `Book.*Balance` DB-column carve-out (A1/D-06); 5 remaining hardcoded a11y labels (IN-02); `.pen` v2 not flushed (D-03b)
- **Outcome:** Brownfield consistency refactor — unified 日常/悦己/ときめき/Daily/Joy vocabulary across zh/ja/en + internal identifiers (`LedgerType { daily, joy }` + 242 call sites, 25 ARB key roots, v17→v18 Drift migration rewriting stored enum values + `soul_satisfaction`→`joy_fullness`, ADR-017); selected ADR-018 "Teal Clarity" palette from 5 Pencil schemes; encoded it in a single `AppPalette` ThemeExtension replacing all `Color(0x…)` literals + AppColors/AppColorsDark shims with full dark-mode rollout (THEME-V2-02 pulled forward, D-07); re-baselined 77 golden masters (34 dark) to teal; Phase 35 closed audit-found W1 (a11y labels → l10n) + W2 (totalSoulTx→totalJoyTx). Suite 2281/2281 green. Schema at v18. **Note:** Schema actually advanced to v19 (category sort-order quick task 260603-ti2) and then ADR-019 "Sakura Mochi × Wakaba" palette replaced ADR-018 "Teal Clarity" (quick task 260603-lr5) — `AppPalette` tokens fully re-valued; CLAUDE.md updated with v1.6 palette section.
- **Tag:** `v1.5`

## Previous Milestone Snapshots

- **v1.4** (7 phases, 29 plans, 2026-05-29 → 2026-05-31, audit `tech_debt` accepted) — 列表功能 (kakeibo-style List tab, `table_calendar`)
- **v1.3** (6 phases, 47 plans, 2026-05-22 → 2026-05-26, audit `tech_debt` accepted) — 迭代帐本输入 (single-screen voice-capable ledger entry)
- **v1.2** (5 phases, 37 plans, 2026-05-19 → 2026-05-21, audit `tech_debt` accepted) — Happiness Metric Refresh
- **v1.1** (4 phases, 40 plans, 2026-05-01 → 2026-05-05, audit `known_debt` accepted) — Happiness Metric & Display
- **v1.0** (8 phases, 48 plans, 2026-04-24 → 2026-04-29, audit `passed`) — Codebase Cleanup Initiative

## Accumulated Context

### Roadmap Evolution

- Phase 35 added: Close vocab leaks: a11y Semantics labels (W1) + totalSoulTx identifiers (W2)
- v1.6 roadmap first written 2026-06-07 as 7 phases (36-42)
- v1.6 roadmap revised 2026-06-07 to 4 phases (36-39) — user-directed consolidation merging data+domain+import_guard into Phase 36; use cases+sync into Phase 37; shell+widgets into Phase 38; i18n+goldens+smoke into Phase 39

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. v1.0 + v1.1 + v1.2 + v1.3 + v1.4 + v1.5 decisions captured there with outcomes.

**v1.6 locked product decisions (pre-implementation):**

- D1: Public/Private as a top segmented control — two independent lists, not a per-item visibility flag
- D2: Context-aware FAB — on the shopping tab routes to add-item screen; on other tabs stays transaction-entry FAB
- D3: Pure list — completing an item only checks it off; NO transaction/accounting linkage
- D4: Add-item form fields: name (required) + optional ledger, category, tags, note, quantity, estimated price
- D5: Filter state shared across both segments and resets when switching public↔private
- D6: An item's public/private attribute is immutable after creation (eliminates public→private sync-tombstone edge case)
- D7: Concurrent completion edits resolve last-write-wins (no `completedAt` column — Option B from OPEN-1)
- D8: Differentiators in scope: per-item family attribution + dual-ledger color accent; deferred: running subtotal, name-autocomplete, category-grouping, tag-filter, duplicate-detection

**v1.6 architecture decisions (from research):**

- Schema v19→v20 (NOT v18→v19; v19 was consumed by 260603-ti2 category sort-order quick task; actual `schemaVersion` in `lib/data/app_database.dart` confirmed at 19)
- Reactive `.watch()` stream mandatory (Drift `readsFrom:` the shopping table) — NOT FutureProvider + ref.invalidate (v1.4 GAP-2 lesson)
- `LedgerTypeSelector` must move to `lib/shared/widgets/` BEFORE any shopping list UI is written (Phase 36)
- `CategorySelectionScreen` allow-listed in `shopping_list/presentation/import_guard.yaml` (cannot move to shared — depends on accounting providers)
- Note field encrypted at repository boundary (mirrors `TransactionRepositoryImpl`)
- Privacy gate: `listType == 'public'` guard lives at use-case boundary (primary) AND inside `ShoppingItemChangeTracker` (secondary safety net)
- `listTypeProvider` and `shoppingFilterProvider` both `keepAlive: true` (IndexedStack tab-switch persistence)
- Two SliverList sections: active items in `SliverReorderableList`, completed items in plain `SliverList` below a divider
- OPEN-1 resolved: Option B (last-write-wins on isCompleted; no `completedAt` column)
- OPEN-2 resolved: Option A (per-segment independent filter, reset on segment switch per D5)
- OPEN-3 resolved: Option A (listType immutable after creation per D6)

**v1.5 roadmap decisions:**

- Terminology workstream (Phases 31) runs before palette workstream (Phase 32) — TERMID-02 (AppColors.survival→daily / soul→joy symbol rename) lands first so the COLOR-03 semantic token system (Phase 33) is built on already-renamed symbols, eliminating churn
- PALETTE-03 (user selects one of 4–5 Pencil mockup palettes) is a hard gate before Phase 33; Phase 32 explicitly ends at that user-selection checkpoint
- Phase 34 is dedicated to golden re-baseline to keep visual verification isolated and clearly attributable to the palette change
- Locale mapping locked: Survival→日常/日常(にちじょう)/Daily; Soul→悦己/ときめき/Joy (zh/ja/en)

**v1.4 locked product decisions (pre-implementation):**

- Calendar per-day totals: own-book only in v1.4 (combined family calendar totals deferred to v1.5+)
- Swipe-delete: confirm-only soft-delete, NO undo SnackBar in v1.4 (undo deferred — requires `RestoreTransactionUseCase`)
- Filter state persistence: keepAlive under `IndexedStack` — filter/sort state persists across tab switches (decided in Phase 26)
- Family "Mine only" shortcut: included in v1.4 (FAM-04)
- Scope: expense-only; no income tracking; no month settlement/lock; no amount-range filter; no "New" badge
- [Phase ?]: initializeDateFormatting placed at top of AppInitializer.initialize() before provider container setup
- [Phase ?]: CategoryFilterSheet tests use ProviderScope + currentLocaleProvider override to prevent async retry timers
- [Phase 29]: Pull-to-refresh = RefreshIndicator + dual-invalidate (list + calendar providers) + await .future.catchError for honest spinner (D-05/Pitfall F)
- [Phase 29]: anyFilterActive 5-condition form identical in list_screen.dart + list_sort_filter_bar.dart (incl memberBookId, Pitfall B); loading/error/empty branches all SingleChildScrollView(AlwaysScrollableScrollPhysics) (Pitfall E)

### Pending Todos

- Run `/gsd-plan-phase 36` to begin Phase 36 (Data Layer + Domain + Import Guard)
- First action in Phase 36: confirm `schemaVersion` in `lib/data/app_database.dart` is 19; shopping migration must be `if (from < 20)` with `schemaVersion => 20`
- Phase 37 internal ordering: use cases before sync wiring (use cases are the call site for ShoppingItemChangeTracker)
- Phase 38 depends on Phase 36 (domain interfaces) and Phase 37 (use cases for provider wiring)
- Phase 39 is the final phase — defer all goldens here; no premature baselining during Phase 38

### Blockers / Concerns

No active blockers. Carried-forward debt (cross-milestone):

- **v1.5 a11y UAT:** Phase 35 W1 on-device screen-reader announcement of localized ledger-chip labels (code grep-verified; tracked in 35-HUMAN-UAT.md) — human_needed
- **v1.5 vocab residual** *(out-of-scope carve-out)*: `Book.survivalBalance`/`soulBalance` DB columns (Research A1/D-06) — needs a DB-migration phase before public release; 5 hardcoded a11y Semantics labels (IN-02) needing ARB keys
- **v1.5 Nyquist debt:** Phases 31/32/34/35 draft + `nyquist_compliant: false`; Phase 33 approved/compliant — documentation-grade only
- **v1.4 GAP-2** *(dead code)*: LIST-02 `watchByBookIds` stream unused; reactivity via manual `ref.invalidate` — consume or delete the 3-layer chain (defer; see Deferred Items §v1.4)
- **v1.4 Nyquist debt:** Phases 25/26/27/29/30 draft + `nyquist_compliant: false`; Phase 28 approved — documentation-grade only

- **FUTURE-TOOL-03** *(coverage-baseline-review)*: Review 70% coverage threshold (triggered post-v1.2; still open)
- **FUTURE-QA-01** *(smoke-test-owner-driven)*: Owner runs smoke tests before v1 release
- **FUTURE-DOC-01..06** *(documentation drift)*: 6 doc-related items from v1.0 close
- **FUTURE-ARCH-04** *(security)*: `recoverFromSeed()` key-overwrite bug fix (held — security architecture out of scope)
- **v1.1 verification debt:** Phase 11 device/simulator UAT for AnalyticsScreen month chip + pull-to-refresh (human_needed)
- **v1.2 verification debt:** Phase 13 + 17 missing VERIFICATION.md (live code wired + integration-verified at milestone close)
- **v1.3 Nyquist debt:** Phase 18 + 21 missing VALIDATION.md; Phase 19 + 20 draft + `nyquist_compliant: false`; Phase 22 draft + `nyquist_compliant: true` — documentation-grade only
- **v1.3 voice-flow polish backlog:** Phase 22 advisory WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03 on `voice_input_screen.dart`; Phase 23 WR-06 `_voiceLocaleId` reassignment functionally dead. Candidate for VOICE-POLISH-V2 phase.
- **MOD-005 OCR slot:** `ocr_review_screen.dart:54,58` hardcodes `EntrySource.manual` pending writer landing — annotated with `// MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)`. Schema accepts 'ocr' literal already (v1.2 schema v17).
- **VOICE-EN-V2-01:** English voice parser skeleton only (Plan 23-03 `voice_corpus_en.dart`); no production en voice parser.

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260518-kyr | Fix soul stats and monthly favorite not refreshing after new soul ledger entry | 2026-05-18 | 7f216e7 | Verified | [260518-kyr-fix-soul-stats-and-monthly-favorite-not-](./quick/260518-kyr-fix-soul-stats-and-monthly-favorite-not-/) |
| 260518-pf5 | Home polish Bucket A — typography spacing, ledger bar color, caption removal, family invite i18n, tx display, analytics spacing | 2026-05-18 | 5b7b6ee | Verified (3/6 PASS round 1; remaining 3 items reworked in pf6) | [260518-pf5-home-polish-typography-spacing-ledger-ba](./quick/260518-pf5-home-polish-typography-spacing-ledger-ba/) |
| 260518-v4v | Home polish Round 2 — Best Joy Variant A (Pencil mock) + r2 flat-layout tweak, recent-tx soul color + icon reposition, home SizedBox 16→24 for analytics parity | 2026-05-19 | e142f4f | Verified | [260518-v4v-home-polish-round-2-best-joy-variant-a-r](./quick/260518-v4v-home-polish-round-2-best-joy-variant-a-r/) |
| 260522-fj5 | 悦己充盈卡片 UI 修复 — info icon 位置、小确幸数字右移、目标 default 50→100、圆环中心不显示目标、繁体→简体、内环目标固定 10、外环颜色过渡修复 | 2026-05-22 | c90ef9a | Verified 2026-05-31 (golden baselines approved) | [260522-fj5-ui-7-info-icon-50-100-10](./quick/260522-fj5-ui-7-info-icon-50-100-10/) |
| 260526-i9a | 添加账目 tab 切换改为只换 tag 下面的内容区（MaterialPageRoute → zero-duration PageRouteBuilder，AppBar/tab 不再整页滑动） | 2026-05-26 | 2a7d6ce | Verified | [260526-i9a-tab-switch-inner-content-only](./quick/260526-i9a-tab-switch-inner-content-only/) |
| 260526-inb | IME 收起后恢复数字键盘（TextField 加 textInputAction.done + onTapOutside；fixup: `_handleFocusChange` 把 `_amountFocused` 镜像到 `!hasTextFocus` 才能让 `_showSmartKeypad` 真正变 true）+ KeyboardToolbar elevation 0 + 完成按钮加 outlined frame | 2026-05-26 | 91b401a | Verified | [260526-inb-ime-dismiss-restore-keypad-and-action-ba](./quick/260526-inb-ime-dismiss-restore-keypad-and-action-ba/) |
| 260526-j98 | 添加账目 4 项 polish：(1) 备注 拆独立卡片放分类后；(2) 支出分类 → 用途/用途/Purpose（ARB 单 key）；(3) 底部 scrollPaddingBottom 从全键盘高改 32dp（删 `_computeSmartKeypadHeight`）；(4) freezed 加 `onPickerDismissed` 回调，date/category picker dismiss 后 `_restoreKeypadFocus()` 让 SmartKeyboard 回来；voice mic golden 同步 re-baseline | 2026-05-26 | fedf995 | Verified | [260526-j98-form-restructure-note-card-rename-paddin](./quick/260526-j98-form-restructure-note-card-rename-paddin/) |
| 260526-k92 | 语音 tab 4-fix：(1) ARB `manualInput` zh=手动/ja=手動 与 OCR/语音 长度对齐；(2) CRITICAL 保存按钮永久灰 — voice screen 没像 manual 那样 seed 默认 category，加 `_initializeDefaultCategory()` postFrame 调用 + `_canSave` 不再 gate `_hostAmount > 0`（无金额时点 submit 由 snackbar 兜底）；(3) 加固定 40dp transcript 区域显示 `_partialText` / `_finalText`；(4) `extractDate` 已存在但 `parsedDate` 没消费，加 `updateDate` setter + LAST-wins 多次提及规则 + zh/ja 各 5 条 date corpus | 2026-05-26 | 2a7d6ce | Superseded by 260526-l0o (real-world test surfaced 5 regressions/bugs) | [260526-k92-voice-tab-fixes-save-transcript-date-cat](./quick/260526-k92-voice-tab-fixes-save-transcript-date-cat/) |
| 260526-l0o | Voice follow-up 5-fix（k92 真机回归）：(1) `12,450日元 → 450` — `日元` 不在 `VoiceCurrencySuffixes.all` 导致 comma-aware regex miss 退回 `\d{3,7}` fallback；加 `日元/日圓/日币`；(2) `新干线 → 交际费/聚会饮酒` — `default_synonyms.dart` 没 Shinkansen 词条 + resolver 缺 substring fallback；加 13 个交通同义词 + resolver 增 substring 兜底；(3+5) 反转 voice 默认 category seed（manual 仍保留）+ `_canSave = !_isSubmitting`（去掉 `_hostCategory` gate，submit 时 snackbar 兜底）+ guard `_stopRecordingAndCommit` 不让 null 覆盖 host category；(4) transcript 从 bodyMedium/40dp → caption/28dp single-line ellipsis | 2026-05-26 | 5f94743 | Verified 2026-05-31 | [260526-l0o-voice-followup-amount-parse-loss-categor](./quick/260526-l0o-voice-followup-amount-parse-loss-categor/) |
| 260526-n7b | 语音 amount parser 直接修复（无 plan/summary，单 commit）：「上周二交公交卡用了¥5240」→ 0 — 两个叠加 bug：(a) 周二 的 二 触发 `_numeralHintPattern` → 路由到 state machine → 失败但**不 fallthrough 到 arabic regex**（docstring 承诺了但 code 没做）；(b) `[¥￥]\s*(\d{1,3}...)` 的 \d{1,3} 贪婪匹配 "524" 出自 "5240"，无 `(?!\d)` 锚，alternation 永不试 `\d{4,9}`。加 fallthrough + 加 `(?!\d)` + 2 个 corpus 测试 | 2026-05-26 | (hotfix) | Verified 2026-05-31 | (no plan dir) |
| 260526-pg6 | Option F active-learning（v1.3.1 quick win，研究报告推荐路径之一）：发现 write/read 用两个 keyword extractor 导致 learned row **silent orphan**（write 留 `日元` 后缀，read 剥掉 → 永不重命中）。加 `VoiceParseResult.resolvedKeyword` 共享 canonical key；learned row `hitCount ≥ 3` 自动 promote 到 substring fallback；`tool/dump_learned_keywords.dart` CLI inspection。Schema v17 不变。350/350 测试通过，zh/ja corpus 100% | 2026-05-26 | 6ff4ea3 | Verified 2026-05-31 (round-trip 学习) | [260526-pg6-voice-active-learning-record-full-keywor](./quick/260526-pg6-voice-active-learning-record-full-keywor/) |
| 260526-r8y | 语音 polish + CRITICAL toolbar save bug：(1) 语音区包 `_FormCard` 风格 14dp 圆角+1px AppColors.borderDefault 边框，与上面表单卡片对齐；transcript 上方加 12dp padding；mic 手势/渐变不动；(2) 语音底部按钮 `l10n.save` → `l10n.record`（复用现有 ARB，0 文件 ARB 改动，zh=记录/ja=記録する/en=Record）；(3) CRITICAL — TextField `onTapOutside: unfocus`（260526-inb 加的）在 pointer-down 触发，**早于** KeyboardToolbar InkWell `onTap` 在 pointer-up resolve，unfocus 把 `_isTextFieldFocused→false` 翻转 → toolbar 下一帧被卸载 → tap-up 永远到不了 `onSave`。Fix：toolbar 包 `TapRegion(groupId: kKeyboardToolbarTapRegionGroup)` + 两个 TextField 加同样 `groupId`，toolbar 上的 tap 不再触发 `onTapOutside`。re-baseline voice mic golden（mic 现在住卡片里背景像素自然变） | 2026-05-26 | dc1f677 | Verified | [260526-r8y-voice-area-border-transcript-spacing-sav](./quick/260526-r8y-voice-area-border-transcript-spacing-sav/) |
| 260529-e5f | 用途 ledger pills 移到标题右侧同行（Card B `[Text, SizedBox(12), LedgerTypeSelector]` → `Row(spaceBetween)` + `Flexible` 标题左 / pills 右；`LedgerTypeSelector` Row 加 `MainAxisSize.min` 以可嵌入水平布局）— Card B 变矮，灵魂满足度选择器获得更多垂直空间；共享 widget 影响 4 hosts；whole-screen voice golden re-baseline。Follow-up：pills 字号 titleMedium→titleSmall、padding 10/16→8/14、icon 16→15 缩小以与标题层级一致（commit 8d6a479） | 2026-05-29 | f86e8fc | Verified 2026-05-31 | [260529-e5f-purpose-pills-inline-right](./quick/260529-e5f-purpose-pills-inline-right/) |
| 260529-gbp | 修复语音灵魂支出满足度默认值 bug：voice 流程对 soul ledger 跑 `VoiceSatisfactionEstimator` 并 `updateSatisfaction` 覆盖表单默认 2；`_mapToSatisfaction` 旧 `0.3+score*0.7` 把中性语音(~0.3)映射到 ~5（中间表情）。重锚定线性映射：中性 ≈0.26→2、兴奋+正面 ≈0.56→7（`round(-2.4+16.7*score)` clamp 1..10）；估算回 2 时与默认相等，`updateSatisfaction` no-op，停在默认。同步更新 estimator 单测中性区间（calm 4-6→1-3、empty 3-5→1-4），excited/negative/range 不变。widget 测试用 fake estimator 不受影响 | 2026-05-29 | 11120ca | Verified 2026-05-31 | [260529-gbp-voice-soul-satisfaction-default-2](./quick/260529-gbp-voice-soul-satisfaction-default-2/) |
| 260531-oqn | 日历列表页 UI 6 项调整：(1) ListScreen 加 Scaffold+AppBar，月份移到标题（中心，可点击跳当月）+ 左右 chevron 翻月，删除 `_MonthNavBar`，解决「头部无月份」+「顶太高」；(2) 无金额日期格加 `SizedBox(height:14)` 占位，数字垂直对齐；(3) 新增 `WeekStartDay` 设置（默认周一，SharedPreferences 持久化，外观设置页选择器，3 ARB key）；(4) 周六数字蓝色 `0xFF1565C0`、周日黑色，按 `day.weekday` 判定不随列；(5) `SortField` 删 `updatedAt` 仅留 timestamp+amount，默认 timestamp-desc，同步 DAO/UI/默认值；(6) 列表项重构：L1 图标+L2 类目名（灵魂加满足度 emoji）主标题，账本类型+店名副标题，金额右侧，去时间。build_runner+gen-l10n+analyze 0 issue，2238/2238 测试通过，goldens re-baseline | 2026-05-31 | 002ac6b3 | Verified 2026-05-31 | [260531-oqn-ui](./quick/260531-oqn-ui/) |
| 260531-se5 | 按金额排序时全量排序、隐藏日期分组、标题改为「日期+二级类目」 | 2026-05-31 | ae85734e | Verified 2026-05-31 (analyze 0 issues, 2238/2238 tests pass) | [260531-se5](./quick/260531-se5-amount-sort-flat-date-title/) |
| 260531-u34 | fix CAL-02/CAL-04 calendar staleness after family-sync + FAB (GAP-1) — invalidate `calendarDailyTotalsProvider(current month)` at the two shell sites (post-sync, post-FAB) alongside the existing `listTransactionsProvider` invalidation; calendar per-day totals + month summary now refresh without pull-to-refresh | 2026-05-31 | 291a9ff4 | Verified 2026-05-31 — closes milestone-audit GAP-1 | [260531-u34](./quick/260531-u34-fix-cal-02-cal-04-calendar-staleness-aft/) |
| 260602-h29 | 与上个月对比改为同期对比：`_getPreviousMonthComparison` 加可选 `asOf` 参数，当报表月份==当前日历月时上月按「截止今天 day-of-month」截断（短月钳制防 DateTime 溢出，当月最后一天→上月全月），历史月份保持整月 vs 整月；首页副标题 `homeHeroPreviousMonthSubline` 改为「上月同期/先月同期/last month (same period)」三 ARB + gen-l10n；5 个 TDD 用例（月中/月末/短月钳制/历史/跨年），9 个 home_hero golden re-baseline。analyze 0 新增 issue，21/21 单测 + 77/77 golden + 2209/2209 通过 | 2026-06-02 | 666190c3 | Verified 2026-06-02 (independent: analyze 0 new, 21/21 use-case tests green) | [260602-h29](./quick/260602-h29-fix-month-over-month-expense-comparison-/) |
| 260602-hz0 | 首页三色圆环重设计（设计探索）：调研市面 ring/donut 实现（Apple Fitness/Card、Copilot/Emma/Monzo、Cleo），提炼自然过渡（OKLCH 类比色 / 接缝端色相接 / 锥形渐变）与亲和度（圆头端点 / 粉彩 / 暖心圆心 / 有机形态）技法；产出 5 个差异化方案 D1 柔光三环 / D2 一盘渐变甜甜圈 / D3 日出仪表弧 / D4 流体花瓣环 / D5 堆叠进度+吉祥物，交付为 `docs/design/home-ring-redesign.html`（浅/深色切换 + 对比表 + 推荐路径，基于 ADR-018 token）。**偏离：** Pencil MCP 本环境无法落盘（D-03b）+ executor 被剥离 MCP（claude-code#13898），改 HTML/SVG 交付以保可验证持久；浏览器实测 0 console error、浅深色双验证 | 2026-06-02 | (docs) | Verified 2026-06-02 (chrome-devtools 渲染截图，浅+深色，0 console error) | [260602-hz0](./quick/260602-hz0-pencil-5/) |
| 260602-jcl | 悦己(Joy) ledger identity 色の代替探索（设计探索） — 最终落地：用户选定 **丁香 Mauve #A586B0**，更新 `app_palette.dart` joy 系 token | 2026-06-02 | a4ba49a8 | Verified 2026-06-02 | [260602-jcl](./quick/260602-jcl-joy-ledger-color-explore/) |
| 260602-nb2 | 本月最爱卡片改用新 strip 布局 | 2026-06-02 | ba93d9da | Verified 2026-06-02 | [260602-nb2](./quick/260602-nb2-strip-joy-pill/) |
| 260602-s9g | 主页 4 项 UI 修复 | 2026-06-02 | 8bee5a0e | Verified 2026-06-02 | [260602-s9g](./quick/260602-s9g-ui-icon/) |
| 260602-u5x | 本月最爱 → 「票根×日历瓦片」融合布局 | 2026-06-02 | be0b00bf | Verified 2026-06-02 | [260602-u5x](./quick/260602-u5x-over/) |
| 260602-vo8 | 调研外部开源 icon 库的满意度 icon 候选 — 最终落地：5 line-art emoji 脸 SVG 全站统一，2297/2297 绿 | 2026-06-02 | e0279710 | Complete | [260602-vo8-icon-icon-4-5](./quick/260602-vo8-icon-icon-4-5/) |
| 260603-lr5 | ADR-019 "桜餅×若葉 (Sakura Mochi × Wakaba)" palette — `AppPalette` full re-value; 80 golden master re-baseline; 2297/2297 green | 2026-06-03 | 0e37262e | Complete | [260603-lr5-pencil-soqks-app](./quick/260603-lr5-pencil-soqks-app/) |
| 260603-nr1 | 记账/首页 UI 6 项（HTML 设计稿确认后落地）：记账反馈重设计 + 首页标题图标 + 悦己vs日常 bar + 月度列表项 padding + 删除/编辑后首页刷新 + 编辑页删除按钮 | 2026-06-03 | 92227367 | Verified 2026-06-03 | [260603-nr1](./quick/260603-nr1-ui-feedback-icons-list-fixes/) |
| 260603-s07 | 补全首页两项功能：月份切换（keepAlive notifier + HeroHeader chevron + MonthPickerDialog）+ 最近交易查看全部（切换到 List tab + 定位本月） | 2026-06-03 | baa2f927 | Verified 2026-06-03 | [260603-s07-1-2](./quick/260603-s07-1-2/) |
| 260603-stw | 修复未来月份越界 crash — hide right chevron when displaying current month; nextMonth() clamp guard | 2026-06-03 | 18e62888 | Verified 2026-06-03 | [260603-stw](./quick/260603-stw-analytics-enddate-must-not-be-in-the-fut/) |
| 260603-ti2 | 将「外出就餐」调为食费一级类目下第一个二级类目 + schema v18→v19 migration | 2026-06-03 | 77a4833a | Verified 2026-06-03 | [260603-ti2-category](./quick/260603-ti2-category/) |
| 260604-fyd | 修复 iPhone 15 Pro 选大字体时首页布局溢出 — `textScaleClamp` builder clamping at 1.2× | 2026-06-04 | f156d721 | Verified 2026-06-04 | [260604-fyd-iphone-15-pro](./quick/260604-fyd-iphone-15-pro/) |
| 260607-jrz | 首页月份选择从 header 左右翻月 chevron 改为「点月份标签 → 弹窗式月份网格」 | 2026-06-07 | 80b16179 | Verified 2026-06-07 | [260607-jrz-month-picker-dialog](./quick/260607-jrz-month-picker-dialog/) |
| 260609-dnp | 购物筛选栏增强：日常\|悦己 合并为单个分段控件（可点击取消）+ 全部 改为「重置」入口（仅无筛选时高亮、点击 clearAll）+ 删除清除 chip；新建 shopping 专用 L1-only 分类弹窗 `ShoppingCategoryFilterSheet`（共享 `CategoryFilterSheet` 不动）；修复 L1 行把图标名 `restaurant` 当文本渲染的 bug → 改用 `Icon(resolveCategoryIcon(l1.icon))`。analyze 0 issues，13/13 scoped 测试（7 widget + 6 golden re-baseline）通过 | 2026-06-09 | 3f96e9be | Verified 2026-06-09 (analyze 0 issues, 13/13 scoped tests green) | [260609-dnp-enhance-shopping-list-filter-combine-dai](./quick/260609-dnp-enhance-shopping-list-filter-combine-dai/) |
| 260609-ec2 | 购物清单交互+样式升级（参考第三方 to-do）：①item 左侧圆形完成图标（点击 toggle，ledger accent 填充）②点击整行进入编辑（移除 chevron）③数量挪到右侧（quantity>1 才显示 `×N`）④新增 `shoppingReorderModeProvider`，filter bar 左对齐 chips + 右侧 ≡/✓ 排序入口，拖拽手柄仅排序模式显示、排序模式禁用 toggle/编辑/滑动删除。无 Drift migration（quantity 已存在，schema v20）；颜色全走 context.palette（0 硬编码 hex）；3 ARB + gen-l10n。analyze 0 issues，tile 19/19 + filter 9/9 测试通过，24 golden re-baseline | 2026-06-09 | 8d08819d | Verified 2026-06-09 (analyze 0 issues; tile 19/19, filter 9/9 green; 24 goldens re-baselined; provider_graph_hygiene + hardcoded_cjk_ui_scan green) | [260609-ec2-shopping-list-ui-upgrade](./quick/260609-ec2-shopping-list-ui-upgrade/) |
| 260609-g8z | 购物私有/公共功能（2 plan）。Plan 01：filter bar 在 日常/悦己 后加 always-on 私有 chip（`showPrivateOnly` → `watchByListType('private')`，不论是否入 group）；表单公私选择器在所有模式显示（创建可改/编辑只读）；个人→私有 label 改名；私有项不 sync（D37-06 既有 gate，未改）。Plan 02 三处修复（用户反馈）：①新建默认日常账本；去掉 tile 的 日常/悦己 badge；恢复悦己左侧 accent 线 ②公私选择器重做成与 日常/悦己 同款 pill chip（`ListTypeSelector`），放在账本选择器后，顺序 公共→私有，默认公共；所有 create 入口默认 public ③tile 在原 badge 位置给私有项加 私有 标识、公共项不标。无 schema/ARB/codegen 改动；listType 创建后不可变（D37-04）保持。analyze 0 issues；受影响 widget 测试 50/50 绿 + ListTypeSelector 新测试；18 tile golden re-baseline（私有标识/accent/去 badge，视觉已确认）；全量非 golden 套件唯一 3 红为 `test/scripts/{merge_findings,coverage_gate}`（subprocess 工具测试，与购物无关，隔离运行全绿） | 2026-06-09 | 0fb224ad | Verified 2026-06-09 (analyze 0 issues; 50/50 shopping widget tests + new ListTypeSelector tests green; 18 tile goldens re-baselined & visually confirmed; 3 full-suite reds are flaky subprocess tooling tests, green in isolation) | [260609-g8z-group-filter-filter-group-sync](./quick/260609-g8z-group-filter-filter-group-sync/) |
| 260609-pmc | 购物排序模式 UX 4 改：①Fix1 filter row 在排序模式与常态布局一致 — 删 `ShoppingFilterBar.reorderPrefix()`，移除三个 ActionChip 的 `avatar:` + 分段控件内 `if(reorderMode)` drag_indicator 块（保留右侧 ≡/✓ 排序入口）②Fix2 长按 item 任意位置即可拖拽 — 在 `SliverReorderableList.itemBuilder` 用 `ReorderableDelayedDragStartListener` 包裹 tile（手柄上原 `ReorderableDragStartListener` 即时拖拽保留）③Fix3 拖拽中 item 高亮 — 给 `SliverReorderableList` 加 `proxyDecorator`（elevation 0→6 + 6px 左 `BorderSide(palette.borderInputActive)`，0 硬编码 hex；调研结论：原本未实现）④Fix4 排序模式每个 active item 加一键置顶/置底 — `_buildTrailingCluster` 加 ↑/↓ IconButton，置顶 `execute(item.id,-1)`、置底 `execute(item.id, activeCount)`（复用 `reorderShoppingItemsUseCaseProvider`，sort_order 列已存在 v20，无 schema 改动）；新增 ARB `shoppingMoveToTop`/`shoppingMoveToBottom` zh/ja/en + gen-l10n。analyze 0 issues；shopping widget 84/84、arch 47/47、filter golden 6/6、tile golden 24/24（含 6 新 reorder_mode 变体）全绿。**Plan 02（真机反馈两改）**：①置顶/置底图标 `keyboard_arrow_up/down` → `vertical_align_top/bottom`（带横线，语义更清晰）②proxyDecorator 修复拖拽变灰 — `Material(color: Colors.transparent)` 透明 body 让 elevation 阴影透出致整行变灰，改 `color: ctx.palette.card`（不透明卡面）+ 删除绿色 6px 左 BorderSide，仅保留 elevation 0→6 阴影（tile 自身 4px ledger accent 线保留）。analyze 0、shopping widget 84/84、tile golden 24/24 全绿。**Plan 03（真机 bug 修复）**：置顶/置底多次点击失效 — 根因 `reorder()` 只写单行 sort_order，按钮用固定值（置顶 -1 / 置底 activeCount），多 item 共值后 `ORDER BY sort_order,created_at` 的 created_at tiebreak 让后续点击无视觉变化。改为读当前 active 项 min/max sortOrder：置顶 = min-1、置底 = max+1（单调递增，无限次点击都有效）。仅改 `shopping_item_tile.dart` onTap（含相对 extremes 计算，需 pre-warm filteredShoppingItemsProvider 才能在 tap 时同步读到 .value）+ 测试（新增 move-to-bottom tap 测试、真实 sortOrder 断言）。无 UI/golden 变化。**Plan 04（真机 bug 修复 — plan-03 暴露的拖拽 bug）**：拖拽 item 到顶/底却落到第二/倒二位。根因 drag 把单行 sort_order 写成 newIndex(可见位置)，而置顶/置底(plan-03 的 min-1/max+1)会留下非连续值（如 -1）：拖到顶写 0，但另一项仍是 -1<0 → 落第二；中间放置也无法用单整数表达。改为**单一机制**：新增 `ShoppingItemDao.reorderBatch(orderedIds)`（事务内整表写连续 0..N-1）+ repo 接口/impl + `UseCase.applyOrder(orderedIds)`；drag 与置顶/置底统一走 applyOrder（置顶/置底改为"移到首/尾后整表重排"，替代 min-1/max+1）。新增 DAO reorderBatch 测试（复现 -1 stale → 拖 c 到顶 → c,a,b 且 sort 0,1,2 / 空列表 no-op）+ UseCase applyOrder 测试 + tile 断言完整 id 顺序。analyze 0、shopping widget 85/85、shopping unit/data 41/41、arch 47/47、golden 30/30 全绿，无 UI/golden 变化。**Plan 05（真机反馈）**：长按 item 想拖拽却弹出"重新排序"——根因手柄上的 `Tooltip(message: shoppingReorderItem='重新排序')` 在 long-press 触发，弹文字而非拖拽。去掉该 Tooltip（保留 Semantics 无障碍 label）；手柄图标 `Icons.drag_handle`(两条线) → `Icons.reorder`(三条线，与 filter bar 排序入口一致)；hit target 44→56px、图标 20→24 更易抓取。tile 断言 Icons.reorder + `find.byTooltip(重新排序) findsNothing`；6 个 reorder_mode tile golden re-baseline。analyze 0、shopping widget 85/85、arch 47/47、golden 24/24 全绿。**Plan 06（两需求）**：①已完成项按 `completed_at DESC` 排序（最近完成在最上）—— DAO `watchByListType`/`watchAll` 的 ORDER BY 改为 `is_completed ASC, CASE WHEN is_completed=0 THEN sort_order/created_at END ASC, completed_at DESC, created_at DESC`（active 组仍 sort_order/created_at；completed 组按完成时间倒序，created_at DESC 兜底 legacy null completed_at）。②点击完成标识恢复未完成 —— 核查发现已工作（ToggleItemCompletedUseCase 翻转 isCompleted=false + 清 completedAt；repo.update 正确写 Value(null)；圆圈 onTap 仅受 reorderMode 门控、与 isCompleted 无关），补回归测试锁定（点已完成 item 圆圈 → toggle.execute 被调用）。新增 DAO 排序测试（3 完成项乱序 completed_at → newest-first）。analyze 0、shopping widget 86/86、shopping unit/data+smoke 44/44、arch 47/47、golden 30/30 全绿，无 UI/golden 变化。**Plan 07**：进入排序模式隐藏已完成区、退出后恢复 —— `_buildBody` 把 completed section（header + SliverList）的 gate 改为 `completedItems.isNotEmpty && !reorderMode`（排序时专注活动项排列，已完成项本就不可拖拽）。新增 screen 测试（normal 显示 active+completed；reorder 隐藏 completed、保留 active）。analyze 0、shopping widget 88/88、arch 47/47 全绿，无 golden 变化 | 2026-06-09 | c35ce16a | Verified 2026-06-09 (on-device approved — all 7 plans: filter parity / long-press-anywhere drag / opaque-card drag highlight / 3-line handle no-tooltip / move-to-top·bottom / contiguous reorder / completed-by-completedAt-DESC / tap-to-un-complete / hide-completed-in-reorder. automated: analyze 0, shopping widget 88/88, unit+data+smoke 44/44, arch 47/47, golden 30/30) | [260609-pmc-shopping-list-sort-ux](./quick/260609-pmc-shopping-list-sort-ux/) |
| 260609-ruu | 重新设计添加/修改商品页（ShoppingItemFormScreen）与「添加账目」视觉一致，HTML 稿先经用户确认。三区域卡片布局：①商品名称单独成卡（create 模式自动聚焦弹键盘）；②数量/用途/类型同卡 — 数量步进器 [−][1][＋]（最小 1、create 默认填 1、无上限、中间仍可手输）、用途（原「账本」label，复用 `expenseClassification`/`dailyExpense`/`joyExpense`，**始终 daily/joy 二选一不能 toggle 成 null**，与账目一致）、类型（原「清单」label → ARB `shoppingFormListTypeLabel` zh=类型/ja=タイプ/en=Type，钢蓝公共/私有药丸，edit 只读）；③分类（改整行点击 + chevron 跳 CategorySelectionScreen，删旧 OutlinedButton「更改」）/预估价格（`AppTextStyles.amountSmall`）/备注同卡。标签字段隐藏不渲染但 edit 保存透传 `widget.item!.tags`（不丢数据）。保存按钮**留在 AppBar 右上角**（位置不变）改为樱粉渐变填充按钮（`fabGradientStart/End`）更醒目易点，保留文案 key `shoppingFormSave`。不变量：listType 编辑只读(D37-04/SYNC-03)、quantity sanitize(<1→1)、find.text('Save') 仍命中。analyze 0、shopping form widget 22/22（含新 STEPPER-01/LEDGER-NO-NULL-01/TAGS-D2-01）、全项目 2560/2560 全绿，无 golden 失败 | 2026-06-09 | 0bce4af8 | Implemented 2026-06-09（自动化全绿；待真机确认） | [260609-ruu-redesign-shopping-form](./quick/260609-ruu-redesign-shopping-form/) |
| 260610-ss7 | 修复 iOS 启动「初始化失败」。承接 18:33 未提交的「升级数据丢失」修复（①铸 key 守卫 + ②keychain accessibility 改动）。根因：`flutter_secure_storage 10.x`（darwin 0.3.1）`read()` 经共享 `baseQuery` 把 `kSecAttrAccessible` 注入**读取查询**（`FlutterSecureStorage.swift:218-220`/`read():462`，无忽略 accessibility 的回退）；②把 accessibility `unlocked_this_device`→`first_unlock_this_device` 后，存量 master key（旧 accessibility 存储）读取不匹配 → `errSecItemNotFound` → `hasMasterKey()`=false → 磁盘 DB 仍在 → ①守卫触发 → 失败屏。即②制造「读不到 key」、①忠实拦下。**处置（用户确认需保数据、非破坏性）：回退②、保留①。** `providers.dart`/`secure_storage_service.dart` accessibility 改回 `unlocked_this_device`+注释警告（改 accessibility 必配 read-rewrite 迁移，否则 bricks 存量）；①守卫与其测试不动。无测试断言 accessibility 值。analyze 0、`security/`+`initialization/` 105/105、全量 `flutter test` 2565/2565 全绿。边界：若该设备 key 因过往开发期重装致 keychain access group 变化而物理不可达，回退也救不回（另议 recovery kit） | 2026-06-10 | 4dd06a63 | Verified 2026-06-10（真机：release 覆盖安装=升级路径 → 正常启动越过初始化失败屏 + 数据保留；签名 team 6Y64KR8RLP 不变即 keychain access group 不变，回退②使旧 key 重新可读） | [260610-ss7-fix-startup-keychain-accessibility](./quick/260610-ss7-fix-startup-keychain-accessibility/) |
| 260609-t1t | 购物清单两处微调：①购物 tab body Column 顶部新增本地化标题（新 ARB key `shoppingListScreenTitle` ja=買い物リスト/zh=购物清单/en=Shopping List + gen-l10n，`AppTextStyles.headlineSmall`+`palette.textPrimary`，不受 group 模式影响始终显示）②表单公共/私有「创建后不可更改」锁定提示（复用现有 key `shoppingListTypeLockedHint`）去掉 `if(isEditMode)` 守卫 → 添加+编辑两种模式都显示，改红色（`palette.error`，0 硬编码 hex）、加 `Icons.lock_outline` 图标、`MainAxisAlignment.end` 右对齐（`Flexible` 防 en 长文案溢出）；ListTypeSelector `enabled:!isEditMode` 既有行为不变。同步翻转 FORM-SELECTOR-04 测试（原断言 create 模式无提示 → 现 findsOneWidget）。analyze 0 issues（两改动屏）、shopping form widget 24/24、list screen 测试通过、gen-l10n 含 getter，无 golden 改动。**Follow-up（用户反馈）：** 标题原为 Column 内手动 `Text(AppTextStyles.headlineSmall)`，与统计页 `AnalyticsScreen`（同 IndexedStack 兄弟 tab）的 `AppBar` 标题不一致 → 改用 `appBar: AppBar(title: Text(shoppingListScreenTitle))`，样式交给 appBarTheme 与统计页一致，删除 Column 顶部手动标题块（commit 0678b76d，analyze 0、list screen 11/11、无 golden 依赖）。已批准 | 2026-06-09 | 0678b76d | Approved 2026-06-09 | [260609-t1t-1-2-icon](./quick/260609-t1t-1-2-icon/) |
| 260612-daz | 修复 v1.6 milestone-audit W1+W2（shopping sync 加固）。**W1/SYNC-01**：`full_sync_use_case.dart` 原本零 shopping 支持，但 tracker 注释声称 "fullSync on next launch will reconcile" — 现 FullSyncUseCase 增加必填 `fetchAllShoppingOps` 回调（带防御性 public-only 过滤），provider 经 `watchByListType('public').first` → `ShoppingItemSyncMapper.toCreateOperation` 接线，full sync 真正推送公共购物项；tracker 误导注释改正（"next launch" 0 处）。**W2/SYNC-02/03**：接收端不再信任 wire — `_applyShoppingItemOp` 对 create/update 加 `_isPublicShoppingOp` 门控（非 public op 整体丢弃，沿用 D37-05 per-op skip 模式；delete 不带 listType 故不门控，记为已接受威胁 T-q260612-04），update merge 钉死 `listType: existing.listType`（D37-04 接收端不变量）。TDD 全程 RED→GREEN；随改 D39-06 smoke test 至新契约（私有 op 被整体丢弃、两表均无痕、删除失效 helper）。riverpod .g.dart 已 regen | 2026-06-12 | e9bcf7ac | Verified 2026-06-12 (analyze 0; family_sync+sync integration 138/138; full suite 2588/2588 green on merged main) | [260612-daz-fix-shopping-sync-w1-fullsync-reconcile-](./quick/260612-daz-fix-shopping-sync-w1-fullsync-reconcile-/) |

## Deferred Items

### Items acknowledged and deferred at v1.6 milestone close on 2026-06-12

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| nyquist_gap | Phases 37/38/39 VALIDATION.md draft + `nyquist_compliant: false`; Phase 36 validated/compliant. Documentation-grade, mirrors accepted v1.2–v1.5 pattern. Run `/gsd-validate-phase {N}` per phase to close retroactively | accept (documentation-grade) | v1.6 close |
| review_advisory | 37-REVIEW advisories: WR-02 pushedCount telemetry accuracy (partially addressed by 260612-daz which made pushedCount include shopping ops); IN-01 `final dynamic ledgerType` in create_shopping_item_use_case.dart should be `LedgerType?`; WR-05 jsonDecode(rawTags) without local try/catch (covered by D37-05 per-op skip) | defer to v1.7+ cleanup | v1.6 close |
| uat_pending | 260609-ruu (shopping form redesign): automated suite green, status "Implemented — 待真机确认" (on-device visual confirm pending) | human_needed | v1.6 close |
| security_note | Shopping note plaintext on the sync wire by design (WR-06); confidentiality rests on transport E2EE. Accepted threat T-q260612-04: inbound shopping `delete` op ungated (wire carries no listType) | accept (recorded for security ledger) | v1.6 close |
| metadata_drift | `gsd-sdk audit-open` reports 38 quick tasks as `missing` status (SUMMARY.md lack `status: complete` frontmatter — convention never adopted in this project) + Phase 39 UAT file flagged though `resolved` with 0 open scenarios. All 38 recorded Verified/Approved in the Quick Tasks Completed table above. Cosmetic, no functional gap | cosmetic, no functional gap | v1.6 close |
| audit_w1_w2 | v1.6 audit W1 (fullSync shopping reconcile) + W2 (receiver listType gate) were **fixed at close** by quick task 260612-daz, not deferred — recorded for audit-trail completeness | resolved | v1.6 close |

### Items acknowledged and deferred at v1.5 milestone close on 2026-06-02

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| uat_gap | Phase 35 `35-HUMAN-UAT.md` [partial] — 1 pending scenario: on-device screen-reader (VoiceOver/TalkBack) announcement of the localized ledger-filter chip a11y labels (W1 fix). Code grep-verified to route through `l10n.listLedgerDaily`/`listLedgerJoy` (list_sort_filter_bar.dart:233/266); no widget test asserts Semantics.label. Quality-confirmation step, not a defect | human_needed | v1.5 close |
| verification_gap | Phase 35 `35-VERIFICATION.md` [human_needed] — Truth 1 (screen-reader announcement) same root cause as the UAT gap above; 6/7 automated truths VERIFIED | accept (documentation-grade; pairs with the UAT item) | v1.5 close |
| uat_gap | Phase 33 `33-HUMAN-UAT.md` [passed] — 11 scenario checkboxes never ticked, but VERIFICATION frontmatter records `human_verification_result: approved 2026-06-01 (all 11 on-device visual items confirmed)`. Tracking artifact, not an open gap | resolved (approved; checkboxes cosmetic) | v1.5 close |
| a11y_backlog | IN-02 (Phase 35 REVIEW): 5 sort/filter/search/clear controls in `list_sort_filter_bar.dart` (lines 158/210/299/412/496) still use hardcoded English `Semantics(label:)` — same leak class as W1 but no ARB keys exist for them; outside Phase 35 contract | defer to v1.6+ a11y/i18n pass | v1.5 close |
| vocab_residual | WARNING-01 (integration checker): `Book.survivalBalance`/`soulBalance` live identifiers (books_table.dart, book.dart, book_repository[_impl].dart, book_dao.dart) — explicitly out-of-scope per Research A1 / D-06; renaming changes Drift SQLite column names and needs a further DB migration. Seam internally consistent | defer to a future DB-migration phase before public release | v1.5 close |
| nyquist_gap | Phases 31/32/34/35 VALIDATION.md draft + `nyquist_compliant: false`; Phase 33 approved/compliant. Phase 32 artifact-only (Nyquist N/A in practice). Documentation-grade, mirrors accepted v1.2/v1.3/v1.4 pattern. Run `/gsd-validate-phase {N}` per phase to close retroactively | accept (documentation-grade) | v1.5 close |
| metadata_drift | `gsd-sdk audit-open` reports 17 quick tasks as `missing` status (their SUMMARY.md lack a `status: complete` frontmatter field — a convention this project never adopted). All predate v1.5 (v1.3/v1.4 era, slugs 260518–260531) and are recorded Verified in the Quick Tasks Completed table above (e.g. 260531-u34 closed v1.4 GAP-1 at close). Cosmetic, no functional gap | cosmetic, no functional gap | v1.5 close |
| test_fidelity | `test/golden/list_transaction_tile_golden_test.dart`: tagText:'Survival' (line 87) + `Locale('ja')` not threaded to tile (line 94, WR-01 in 34-REVIEW.md). zh/en dark goldens render tile-internal date in Japanese; goldens pass because masters generated with same defect. Test-fidelity only, not user-facing | accept | v1.5 close |

### Items acknowledged and deferred at v1.4 milestone close on 2026-05-31

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| dead_code | GAP-2: LIST-02 reactive stream `TransactionDao.watchByBookIds` exists at DAO/repo/use-case layers but has zero consumers — reactivity is achieved by manual `ref.invalidate` at every mutation site. Stated mechanism is unwired; shell comments (`main_shell_screen.dart` near the invalidation sites) are stale/misleading. Fix: either consume `useCase.watch()` or delete the 3-layer chain + fix comments | defer to v1.5+ (accept as non-blocking; all verified flows work via manual invalidate) | v1.4 close |
| nyquist_gap | Phases 25/26/27/29/30 VALIDATION.md draft + `nyquist_compliant: false`; Phase 28 approved (`nyquist_compliant: true`, `wave_0_complete: false`); Phase 24 compliant (final). Documentation-grade, mirrors accepted v1.2/v1.3 pattern. Run `/gsd-validate-phase {N}` per phase to close retroactively | accept (documentation-grade) | v1.4 close |
| metadata_drift | `gsd-sdk audit-open` reports 17 quick tasks as `missing` status (their SUMMARY.md lack a `status: complete` frontmatter field — a convention this project never adopted) and 3 phases (26/28/29) with UAT files flagged though all are `passed`/`resolved` with 0 open scenarios; all quick tasks are recorded Verified in the Quick Tasks Completed table above (9 of them confirmed via on-device visual pass 2026-05-31). Cosmetic, no functional gap | cosmetic, no functional gap | v1.4 close |
| forward_compat | GAP-1 (calendar staleness after family-sync / FAB) was **fixed at close**, not deferred — quick task 260531-u34 invalidates `calendarDailyTotalsProvider(current month)` at both shell sites. Recorded here for audit-trail completeness | resolved | v1.4 close |

### Items acknowledged and deferred at v1.3 milestone close on 2026-05-26

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| nyquist_gap | Phase 18 + 21 missing VALIDATION.md; Phase 19/20 draft + `nyquist_compliant: false`; Phase 22 draft + `nyquist_compliant: true` (`wave_0_complete: false` across the draft set) | accept (documentation-grade, mirrors v1.0 FUTURE-DOC-05 / v1.2 close precedent) | v1.3 close |
| voice_polish_backlog | 6 standing WARNINGS (WR-02/03/06/07/NEW-02/NEW-03) + 3 INFOS (IN-01/02/03) on `voice_input_screen.dart` from Phase 22 — vacuous null check, async pipeline race, mocktail catch-all stub override, addListener closure equality, spurious tear-down toast, final-transcript double-parse, no permanent-error recovery affordance, dartdoc gap, missing localized error_audio assert | defer to v1.4+ VOICE-POLISH-V2 phase | v1.3 close |
| voice_polish_backlog | Phase 23 WR-06 `_voiceLocaleId = value` build-side reassignment functionally dead after Plan 23-09 mixin extraction (mixin listener with `fireImmediately:true` is canonical writer); benign but anti-pattern | defer to v1.4+ cleanup | v1.3 close |
| forward_compat | `ocr_review_screen.dart:54,58` hardcodes `EntrySource.manual` pending MOD-005 OCR writer; schema accepts 'ocr' literal already; annotated with `// MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)` marker | reserved (will be writer-claimed by MOD-005) | v1.3 close |

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

**v1.2-deferred items (subsumed into v1.3 active scope and shipped):**

- v1.2 close debt: 6 `family_insight_card_test.dart` failures from Phase 15 ARB drift → still carried (not touched by v1.3)
- Forward-compat `EntrySource.ocr` slot → still reserved (will be writer-claimed by MOD-005)

## Session Continuity

Last session: 2026-06-09T09:42:07.161Z
Stopped at: Phase 39 context gathered

**Next:** `/gsd-plan-phase 36` — plan Phase 36: Data Layer + Domain + Import Guard

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
