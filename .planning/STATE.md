---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: 购物清单
status: executing
stopped_at: Phase 37 context gathered
last_updated: "2026-06-08T02:22:11.553Z"
last_activity: 2026-06-08
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 13
  completed_plans: 9
  percent: 25
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-07 — v1.6 购物清单 started)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations
**Current focus:** Phase 37 — application-use-cases-sync-integration

## Current Position

Phase: 37 (application-use-cases-sync-integration) — EXECUTING
Plan: 3 of 6
Status: Ready to execute
Last activity: 2026-06-08

```
v1.6 progress: [░░░░] 0% — Phase 36-39 defined, 0/4 complete
```

## Last Milestone Snapshot (v1.5)

- **Phases:** 5 (31-35)
- **Plans:** 24
- **Duration:** 2026-05-31 → 2026-06-02 (~2 days)
- **Commits:** 155 (vs v1.4 tag); 550 files changed; +43,552 / -4,650 LOC
- **Audit Status at Close:** `tech_debt` — accepted (15/15 requirements, 5/5 phases verified `passed`, 6/6 cross-phase integration seams wired). Re-audit after Phase 35 closed the W1/W2 leaks the initial 2026-06-01 audit found. Residual: 1 pending on-device screen-reader UAT (P35 W1); Phases 31/32/34/35 draft-Nyquist (`nyquist_compliant: false`, Phase 33 approved/compliant); out-of-scope `Book.*Balance` DB-column carve-out (A1/D-06); 5 remaining hardcoded a11y labels (IN-02); `.pen` v2 not flushed (D-03b)
- **Outcome:** Brownfield consistency refactor — unified 日常/悦己/ときめき/Daily/Joy vocabulary across zh/ja/en + internal identifiers (`LedgerType { daily, joy }` + 242 call sites, 25 ARB key roots, v17→v18 Drift migration rewriting stored enum values + `soul_satisfaction`→`joy_fullness`, ADR-017); selected ADR-018 "Teal Clarity" palette from 5 Pencil schemes; encoded it in a single `AppPalette` ThemeExtension replacing all `Color(0x…)` literals + AppColors/AppColorsDark shims with full dark-mode rollout (THEME-V2-02 pulled forward, D-07); re-baselined 77 golden masters (34 dark) to teal; Phase 35 closed audit-found W1 (a11y labels → l10n) + W2 (totalSoulTx→totalJoyTx). Suite 2281/2281 green. Schema at v18. **Note:** Schema actually advanced to v19 (category sort-order quick task 260603-ti2) and then ADR-019 "Sakura Mochi × Wakaba" palette replaced ADR-018 "Teal Clarity" (quick task 260603-lr5) — `AppPalette` tokens fully re-valued; CLAUDE.md updated with v1.6 palette section.
- **Tag:** `v1.5`

## Previous Milestone Snapshot (v1.4)

- **Phases:** 7 (24-30)
- **Plans:** 29
- **Duration:** 2026-05-29 → 2026-05-31 (~3 days)
- **Commits:** 283 (vs v1.3 tag); 316 files changed; +51,409 / -2,207 LOC
- **Audit Status at Close:** `tech_debt` — accepted (22/22 requirements, 7/7 phases, 7/7 E2E flows; GAP-1 calendar-staleness closed at close via quick task 260531-u34; GAP-2 `watchByBookIds` dead-code + Phases 25/26/27/29/30 draft-Nyquist docs carried)
- **Outcome:** Full kakeibo-style List tab in new `lib/features/list/` module — `table_calendar` month header (per-day expense totals, own-book), month nav + day-tap filter, sortable · searchable · filterable transaction list, family-aware shadow-book merge + "Mine only", pull-to-refresh, 3-variant empty states. `table_calendar ^3.2.0` (iOS build green). Schema unchanged at v17.
- **Tag:** `v1.4`

## Previous Milestone Snapshots

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

## Deferred Items

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

Last session: 2026-06-08T02:22:11.546Z
Stopped at: Phase 37 context gathered

**Next:** `/gsd-plan-phase 36` — plan Phase 36: Data Layer + Domain + Import Guard
