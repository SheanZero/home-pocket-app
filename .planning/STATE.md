---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: 文案与配色统一
status: Awaiting next milestone
stopped_at: Milestone v1.5 complete (archived 2026-06-02)
last_updated: "2026-06-02T03:56:24.054Z"
last_activity: 2026-06-02 — Completed quick task 260602-hz0: 首页三色圆环重设计（5 方案 HTML/SVG 设计稿）
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 24
  completed_plans: 24
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-02 — v1.5 文案与配色统一 shipped + archived)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations
**Current focus:** Planning next milestone (`/gsd-new-milestone`)

## Current Position

Phase: Milestone v1.5 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-03 — Quick task 260603-stw 修复未来月份越界 crash（截图：本月点「›」前进到下个月触发 analytics `endDate must not be in the future`）：显示月=当前真实年月时隐藏向右箭头，首页+月度列表页同治。`HeroHeader` 加必填 `showNextChevron`（false 时 `SizedBox(28×28)` 占位保布局），`home_screen` 派生 `isCurrentMonth` 传 `!isCurrentMonth`；`HomeSelectedMonth.nextMonth()` 加 clamp 守卫（本月 no-op）；`list_screen` AppBar `actions` collection-if `if(!isCurrentMonth)` 省略右 chevron。两处 HeroHeader 测试补 `showNextChevron` + 新增本月隐藏用例，list 测试 +2 用例。3 atomic commit（18e62888/c0cc3786），analyze 0 新增、2303/2303 全绿（+4 测试）、无 golden 受影响。 ‖ 前序: Quick task 260603-s07 补全首页两项功能：(1) 月份切换——新增 `HomeSelectedMonth` Riverpod 3 keepAlive notifier（年/月记录态 + selectMonth/prevMonth/nextMonth）→ `homeSelectedMonthProvider`；`home_screen.dart` 用它替换硬编码 `DateTime.now()`（monthlyReport/happinessReport/bestJoy/heroCard 随选中月响应；今日交易段保持显示当天）；`hero_header.dart` 月份标签两侧加 chevron 翻月（`onPrevMonth`/`onNextMonth`），点标签开 `_MonthPickerDialog`（年导航 2000–2099 clamp + 4×3 月份网格，三语 `homeMonthPickerTitle`/`homeMonthPickerClose`）。(2) 最近交易查看全部——原 TODO → `listFilterProvider.notifier.selectMonth(本月)` + `selectedTabIndexProvider.select(1)` 切 List tab 定位本月（IndexedStack，无新路由）。偏离(Rule 1)：2 个 HeroHeader 测试 helper 补回调。2 atomic commit（baa2f927/2f6e93ca），analyze 0、gen-l10n 通过、2299/2299 全绿。 ‖ 前序: Quick task 260603-nr1 记账/首页 UI 6 项（HTML 设计稿确认后落地）：(1) 记账反馈重设计→方案 A 顶部统一吐司（成功绿/错误红，新 `feedback_toast.dart` + `SoftToast` 加 success 配色）+ 新增空/零金额校验 + 成功后不关页（移除 `popUntil` + 表单复位 连续记账）+ 确认删除弹窗抽共享暖色圆角 `soft_confirm_dialog.dart`（列表滑删/编辑页复用）+ 三语 `pleaseEnterAmount`/`successKeepGoing`；(2) 首页标题图标 auto_awesome→`Icons.eco`(悦己充盈)/`Icons.workspace_premium`(本月最爱)；(3) 悦己vs日常 bar 去渐变改纯色 joy；(4) 月度列表项 padding 10→16 + 尾部 chevron 与 Dismissible 共存；(5) 修复删除/编辑后首页+分析页不刷新——新 `invalidate_transaction_dependents.dart` 失效 list/calendar/today/monthly/happiness/bestJoy，接入 list_screen 滑删与编辑保存；(6) 编辑页 AppBar 加红色删除按钮→共享确认→delete→失效→pop(true)。3 atomic commit（92227367/bea205f8/618ba6cf），analyze 0 新增、gen-l10n 通过、2297/2297 绿（16 golden re-baseline）；2 测试断言随码更新(Rule 1)。 ‖ 前序: Quick task 260603-lr5b（lr5 follow-up）Joy 全族转樱粉：应用户要求把悦己(Joy)全部颜色从 lr5 设的暖琥珀(#A15C00 族)改为樱粉 #D98CA0 及其变体——`AppPalette` joy/joyText/joyLight/joyFullness*/satisfactionPill*/textMutedGold（明+暗各 8 个；joyText 用可读深玫瑰 #A53D5E 明/#E89BB0 暗 保 WCAG AA）+ `happiness_ring_palette.dart` 内环 target(悦己目标) butter黄→樱粉（外/中环 teal/sage 保留三环色盲可分）。级联覆盖：悦己vs日常进度条、悦己目标环、本月最爱 strip、list joy 文字/徽章（皆读 joy token）。joyRoi 绿/shared 钢蓝/semantic/FAB 不变（FAB 与 joy 现共用樱粉,user-directed,覆盖 soqKs「粉仅用于添加入口」）。ADR-019 追加 Update 章节；20 golden re-baseline；analyze 0 新增、2297/2297 绿；契约测试 3 项同步更新(Rule 1)。 ‖ 前序: 260603-lr5 桜餅×若葉(Sakura Mochi×Wakaba)配色全面替换 ADR-018 Teal Clarity(v1.6)：据 Pencil node soqKs 重估 AppPalette light+dark 全 token——primary/daily→若叶绿 #6FA36F、FAB/添加入口→樱粉 #D98CA0、joy 全族 Mauve→暖琥珀 #A15C00、背景→暖米白 #FBF7F4、文字 #20352B/#71877A、描边 #E6DDD8；shared 钢蓝/semantic/joyRoi 绿/悦己充盈环 Butter 保留；dark 同步派生(暖深底, *Text WCAG AA)。新建 ADR-019 superseding ADR-018 + INDEX + CLAUDE.md v1.6。偏离自动修复：app_theme.dart 硬编码色→AppPalette.* 动态、dark coverage 测试 bg #0C1719→#171210、7 个 test/widget golden 一并重拍。80 golden 全重拍；analyze 0 新增、2297/2297 绿。先 --discuss 锁 4 决策。 ‖ 前序: 260602-vo8 满足度 emoji 全站铺开: 把 SVG emoji 脸从 picker 推广到另外 3 处(home_screen 近期 tx tile、home_hero_card 本月最爱 seal、list_screen 月度 tile)。新增共享 `lib/shared/widgets/satisfaction_face_icon.dart`(`satisfactionFaceAsset(int)` + `SatisfactionFaceIcon` widget,srcIn 染色)作为唯一 value→asset 映射;删除 3 处重复的 `_satisfactionIcon`/`_satisfactionPillIcon`(原 Material sentiment_* 映射);tile 参数 `satisfactionIcon: IconData?`→`satisfactionValue: int?`。9 个 home_hero_card golden 重拍(所有渲染 seal 的变体:single/family×light/dark + joy_target_0/50/100/over + thin);全量 2297/2297 绿,analyze 0。先前最终图标定稿: 用户改提供 5 张 JPG 位图(白底黑线 emoji 脸:平和→微笑→咧嘴→星星眼→爱心眼,01→05 递增)。因 App 用可染色 SVG 管线,用 `sips`(jpg→bmp)+ `potrace`(brew 装)描摹成干净单色 SVG(透明底,4 path,~3KB),替换 `assets/satisfaction/sat_01..05.svg`;picker 代码不变(仍 SvgPicture srcIn 染色 + 64/56 尺寸),golden 重拍 light+dark 目视确认。先前曾用 line-art 猫 SVG(01→05),落地到 `satisfaction_emoji_picker.dart`——加 `flutter_svg ^2.3.0`(win32 未冲突)、`assets/satisfaction/sat_01..05.svg`、注册 pubspec assets、`Icon`→`SvgPicture.asset` 保留 srcIn 染色(选中 joy/未选 textSecondary)、size 24→30、新增 picker golden(light+dark 已目视确认猫渲染正确)+ widget 测试断言 5 个 SvgPicture。analyze 0(仅遗留 onReorder info)、全量 2297/2297 绿。home_hero_card/home_screen/list_screen 的满足度 seal 仍用 Material 脸(未在本次范围)。 ‖ 前序: 调研满意度 icon 候选（5 组，优先猫猫）——发现 Unicode 猫脸满意度梯度 🐱→😺→😸→😹→😻，OpenMoji 同套有彩色+黑线两版（单色也能要猫且保留染色）；产出 RESEARCH.md + satisfaction-icons-showcase.html（CDN 实时渲染，27 URL 全 200）+ 截图；纯调研，待用户选向。 ‖ 前一条 quick task 260602-u5x: 本月最爱改用「票根×日历瓦片」融合布局（融合·轻）——左日历瓦片(日期) + 中父类目图标+类型名/金额 + 右无框满足度图标over档位词，票根容器(淡彩底+左6px强调条+虚线撕口)；逆转 s9g 的去框决定（用户确认）；10 golden re-baseline，analyze 0，2294/2294 绿；punch-hole 缺口 deferred

## Last Milestone Snapshot (v1.5)

- **Phases:** 5 (31-35)
- **Plans:** 24
- **Duration:** 2026-05-31 → 2026-06-02 (~2 days)
- **Commits:** 155 (vs v1.4 tag); 550 files changed; +43,552 / -4,650 LOC
- **Audit Status at Close:** `tech_debt` — accepted (15/15 requirements, 5/5 phases verified `passed`, 6/6 cross-phase integration seams wired). Re-audit after Phase 35 closed the W1/W2 leaks the initial 2026-06-01 audit found. Residual: 1 pending on-device screen-reader UAT (P35 W1); Phases 31/32/34/35 draft-Nyquist (`nyquist_compliant: false`, Phase 33 approved/compliant); out-of-scope `Book.*Balance` DB-column carve-out (A1/D-06); 5 remaining hardcoded a11y labels (IN-02); `.pen` v2 not flushed (D-03b)
- **Outcome:** Brownfield consistency refactor — unified 日常/悦己/ときめき/Daily/Joy vocabulary across zh/ja/en + internal identifiers (`LedgerType { daily, joy }` + 242 call sites, 25 ARB key roots, v17→v18 Drift migration rewriting stored enum values + `soul_satisfaction`→`joy_fullness`, ADR-017); selected ADR-018 "Teal Clarity" palette from 5 Pencil schemes; encoded it in a single `AppPalette` ThemeExtension replacing all `Color(0x…)` literals + AppColors/AppColorsDark shims with full dark-mode rollout (THEME-V2-02 pulled forward, D-07); re-baselined 77 golden masters (34 dark) to teal; Phase 35 closed audit-found W1 (a11y labels → l10n) + W2 (totalSoulTx→totalJoyTx). Suite 2281/2281 green. Schema at v18.
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

### Decisions

Decisions are logged in PROJECT.md Key Decisions table. v1.0 + v1.1 + v1.2 + v1.3 + v1.4 + v1.5 decisions captured there with outcomes.

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

- Run `/gsd-new-milestone` to scope the next milestone (v1.5 shipped 2026-06-02)
- Refresh `.planning/codebase/` via `/gsd-map-codebase` before next-milestone planning — it is five milestones stale (notably the v1.5 vocabulary/palette rename + schema v18)

### Blockers / Concerns

No active blockers. Carried-forward debt (cross-milestone):

- **v1.5 a11y UAT:** Phase 35 W1 on-device screen-reader announcement of localized ledger-chip labels (code grep-verified; tracked in 35-HUMAN-UAT.md) — human_needed
- **v1.5 vocab residual** *(out-of-scope carve-out)*: `Book.survivalBalance`/`soulBalance` DB columns (Research A1/D-06) — needs a DB-migration phase before public release; 5 hardcoded a11y Semantics labels (IN-02) needing ARB keys
- **v1.5 Nyquist debt:** Phases 31/32/34/35 draft + `nyquist_compliant: false`; Phase 33 approved/compliant — documentation-grade only
- **v1.4 GAP-2** *(dead code)*: LIST-02 `watchByBookIds` stream unused; reactivity via manual `ref.invalidate` — consume or delete the 3-layer chain (defer to v1.6; see Deferred Items §v1.4)
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
| 260526-k92 | 语音 tab 4-fix：(1) ARB `manualInput` zh=手动/ja=手動 与 OCR/语音 长度对齐；(2) CRITICAL 保存按钮永久灰 — voice screen 没像 manual 那样 seed 默认 category，加 `_initializeDefaultCategory()` postFrame 调用 + `_canSave` 不再 gate `_hostAmount > 0`（无金额时点 submit 由 snackbar 兜底）；(3) 加固定 40dp transcript 区域显示 `_partialText` / `_finalText`；(4) `extractDate` 已存在但 `parsedDate` 没消费，加 `updateDate` setter + LAST-wins 多次提及规则 + zh/ja 各 5 条 date corpus | 2026-05-26 | f6fa621 | Superseded by 260526-l0o (real-world test surfaced 5 regressions/bugs) | [260526-k92-voice-tab-fixes-save-transcript-date-cat](./quick/260526-k92-voice-tab-fixes-save-transcript-date-cat/) |
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
| 260602-jcl | 悦己(Joy) ledger identity 色の代替探索（设计探索）：现状 `joy: #F0A81E`（gold）が「黄色系で good-looking でない」との所感を受け、teal #1C7A86 と対で映える Joy 候补 6 种（Terracotta/Coral/Tangerine/Magenta/Orchid/Plum）を现状 gold 参照列と并べて视覚提示。各候补で悦己 pill×日常 pill 横并び・金额 + live WCAG 比・「本月最爱」ストリップを再现、light/dark 両対応。交付 `docs/design/joy-color-explore.html`。全候补 light/dark とも joyText AA ≥4.5:1。推奨: Terracotta（安全な映える暖色）/ Orchid（脱黄色・teal 补色 wellness 感）。**偏离 hz0 と同理由**（设计稿でコードでない / Pencil 落盘不可 D-03b / executor MCP 剥离）。**已落地（Iteration 3）**：用户选定 **丁香 Mauve #A586B0**，更新 `app_palette.dart` joy 系 token（明+暗各 8 个：joy→#A586B0/joyText→#6B4877/joyLight→#F2ECF4/satisfactionPillRose/textMutedGold 等；joyRoi* 绿与 surfaceCream* teal 及悦己充盈环 Butter 保持不变），契约测试 3 件 + ADR-018 Update 章节；14 golden re-baseline（全部 daily_vs_joy_card + home_hero_card，无其它受影响）；analyze 0 新增、2286/2286 绿 | 2026-06-02 | a4ba49a8→(landing) | Verified 2026-06-02 (analyze 0 新增 + 2286/2286 + golden 目视：joy=mauve/daily=teal/环=Butter) | [260602-jcl](./quick/260602-jcl-joy-ledger-color-explore/) |
| 260602-nb2 | 本月最爱卡片改用新 strip 布局：HomeHeroCard Region 6 由裸排版（❤+大金额+档位 pill）改为 **Joy 淡彩 strip 容器**（joy bg α0.08 浅/0.13 深 + 0.22 描边，r14 pad14）——标题去❤改 Joy 色，左 36×36 joyLight 图标块（新增 `categoryIconFromId(id)` 纯解析：`DefaultCategories.all` 查 `.icon`→`resolveCategoryIcon`，未知 id fallback `Icons.favorite_border`），中 品类名 + `日期(周)` 副标题（去掉「悦己 ・」前缀），右 金额(joyText 17px) over 复用的档位满足度 pill。ARCH-002 守恒（BestJoyMomentRow 不动，主标题只用品类名）；AppPalette token 不改。设计稿 `docs/design/best-joy-redesign.html` 用户确认（品类名+档位词+去前缀）。TDD 4 测；10 个 home_hero_card_*_ja golden re-baseline（Best Joy 为常驻区，全部 shift 含 4 joy_target 变体）；analyze 0、2290/2290 绿 | 2026-06-02 | ba93d9da | Verified 2026-06-02 (analyze 0 + 2290/2290 + golden 目视 light+dark：Mauve strip/图标块/名+日期/金额 over pill) | [260602-nb2](./quick/260602-nb2-strip-joy-pill/) |
| 260602-s9g | 主页 4 项 UI 修复：(1) Best Joy strip 去淡彩底框/描边，标题改 `auto_awesome` + bodyLarge/textPrimary 与悦己充盈一致；(2) 左侧图标改用**一级（父）类目**图标——新增 `parentCategoryIconFromId(id)` 纯解析（`DefaultCategories.all` 查父 `.parentId`→父 `.icon`，父缺→自身图标，未知→`favorite_border`），strip 与 recent-tx 都改用它；(3) 二级类目标题放大到 17 与金额同号并与金额垂直居中（去掉日期副标题成单行），满足度 pill 缩小 icon20→16/文 14→12/pad(12,7)→(8,4)；(4) HomeTransactionTile 重构对齐月度 ListTransactionTile（前导 28px L1 图标 → L2 名/账本徽章+商户列 → 金额，去 swipe/member chip），home_screen 传 l1Icon + nullable merchant。TDD 4 测；10 个 home_hero_card golden re-baseline（list_transaction_tile 未漂移）；analyze 0、2294/2294 绿 + **follow-up (dfb36c54)**：用户回归 2 修——(a) Best Joy strip 恢复日期副标题（17px 品类名 over `日期(周)`，居中需求下保留信息）；(b) recent-tx 账本徽章 魂/生→`listLedgerJoy/listLedgerDaily`（悦己/日常）与月度 ListTransactionTile 一致；9 golden re-baseline | 2026-06-02 | 8bee5a0e (+dfb36c54) | Verified 2026-06-02 (analyze 0 + 2294/2294 + golden 目视 light+dark) | [260602-s9g](./quick/260602-s9g-ui-icon/) |
| 260602-u5x | 本月最爱 → 「票根×日历瓦片」融合布局（融合·轻，用户在 `docs/design/best-joy-fusion.html` 确认）：VALUE 态改为票根 chrome（`_bestJoyTicket`：`ClipRRect(14)`+`IntrinsicHeight`+`Row(stretch)`，左 6px joy 强调条 + 淡彩 joy 底/描边）包裹 `日历瓦片(月条+大日号+周) → 中(父类目图标@15+L2名@15 / 金额@18 joyText) → _DashedVLine 撕口 → 无框 seal(满足度图标@24 over 档位词@10)`；EMPTY/all-neutral 同 chrome + 「—」占位+引导语。CJK 月/日格式收进 `DateFormatter.formatCalendarMonth/Day`（i18n 白名单），dark 月条文字用 `palette.background` 不留裸色。**逆转 s9g「去框」决定**（用户确认票根观感）；满足度沿用 ADR-014 Material 图标（非 HTML emoji，golden 稳定）；数据层不动（ARCH-002）。punch-hole 缺口 OPTIONAL→deferred（虚线撕口已够票根感）。10 golden re-baseline（list_transaction_tile 未漂移）；analyze 0、2294/2294 绿 + **follow-up (70c77ba3, approved)**：放宽满足度 seal 间距——票根右内距 6→16、虚线前加 8px、虚线→图标 8→14，让图标左右更宽松、虚线左移；10 golden re-baseline | 2026-06-02 | be0b00bf (+70c77ba3) | Verified 2026-06-02 (analyze 0 + 2294/2294 + golden 目视 light+dark：票根/日历瓦片/无框 seal；间距 follow-up user-approved) | [260602-u5x](./quick/260602-u5x-over/) |
| 260602-vo8 | 调研外部开源 icon 库的满意度 icon 候选（≥4-5 组，优先猫猫元素）。核心发现：Unicode 自带「猫脸满意度递增梯度」🐱→😺→😸→😹→😻（终点爱心眼=最爱），4 个开源 emoji 项目（OpenMoji/Twemoji/Noto/Fluent）均覆盖。产出 5 组候选：彩色全猫梯度（OpenMoji-CC / Fluent Flat-MIT / Twemoji-CC / Noto-Apache）+ 单色可染色（Tabler mood+cat-MIT）；关键洞察 **OpenMoji 同套猫脸有彩色+黑色线性两版** → 单色路线也能要猫且保留 palette 染色。交付 `260602-vo8-RESEARCH.md`（横向对比+许可证+集成成本）+ `docs/design/satisfaction-icons-showcase.html`（CDN 实时渲染真实 SVG，含彩色/单色/深色三态，27 个 URL 全 200 校验）+ 渲染截图。**纯调研产出，未改代码**；待用户选定方向后再开后续替换任务 | 2026-06-02 → 06-03 | e0279710 (final) | Complete — 5 line-art emoji 脸 SVG 全站统一(picker + home/list tile + hero seal),共享 SatisfactionFaceIcon,2297/2297 绿 | [260602-vo8-icon-icon-4-5](./quick/260602-vo8-icon-icon-4-5/) |
| 260603-lr5 | 根据 Pencil node `soqKs`「桜餅×若葉 (Sakura Mochi × Wakaba)」配色全面替换 ADR-018 Teal Clarity（v1.6）。`AppPalette` light+dark 全 ~60 token 重估：primary/nav/tab/button/link + daily → **若叶绿 #6FA36F**；FAB/中央添加入口 → **樱粉 #D98CA0**（仅此处出现粉）；joy 全族 Mauve→**暖琥珀 #A15C00**（joy/joyText/joyLight/joyFullnessBg/satisfactionPill*/textMutedGold）；背景 → **暖米白 #FBF7F4**；文字 #20352B/#71877A；描边 #E6DDD8 暖族；avatar/member 装饰渐变 → 若叶/米白族。**保留**：shared 钢蓝 #5B8AC4、semantic(success/warning/error/info)、joyRoi* 绿(ROI)、悦己充盈环 Butter(`happiness_ring_palette.dart`)。dark 同步派生（暖深底 #171210/card #231E1B，*Text WCAG AA≥4.5:1）。新建 **ADR-019**（superseding ADR-018，全 light+dark 逐角色 hex 表）+ ADR-000 INDEX + CLAUDE.md「App Color Scheme v1.6」。**偏离自动修复(Rule 1)**：`app_theme.dart` 残留硬编码 ADR-018 色→改 `AppPalette.*` 动态引用；`theme_dark_mode_coverage_test` 硬编码 dark bg #0C1719→#171210；7 个 `test/widget/` golden 一并重拍。80 golden master 全重拍；analyze 0 新增（仅 4 处遗留非本次文件）、golden 73/73、全量 **2297/2297 绿**。先经 `--discuss` 锁定 4 项决策（dark 同步派生/joy 转琥珀/shared 保留/semantic 保留）。.pen 落盘 D-03b 仍 deferred（Pencil MCP 本环境不可落盘） | 2026-06-03 | 0e37262e+d148f6e7 (+lr5b 19a14552) | Complete — analyze 0 new + 2297/2297 + golden 目视 light+dark（若叶绿主色/樱粉 FAB/暖米白底）。**follow-up lr5b**：应用户要求 Joy 全族 amber→樱粉 #D98CA0+变体（joyText 深玫瑰 #A53D5E/#E89BB0 保 AA）+ 充盈环内环 target(悦己目标) butter→樱粉（外/中环 teal/sage 留）；级联进度条/最爱/list；20 golden re-baseline、2297/2297 绿；Joy 与 FAB 现共用樱粉(user-directed) | [260603-lr5-pencil-soqks-app](./quick/260603-lr5-pencil-soqks-app/) |
| 260603-nr1 | 记账/首页 UI 6 项（HTML 设计稿确认后落地）：(1) **记账反馈重设计**——方案 A 顶部统一吐司（成功绿/错误红，复用 voice overlay 范式 + `SoftToast` 加 `FeedbackTone.success` + 新 `feedback_toast.dart`），新增空/零金额校验，成功后**不关页**（移除 `popUntil(first)` + 表单复位 → 连续记账），并把确认删除弹窗抽成共享暖色圆角 `lib/shared/widgets/soft_confirm_dialog.dart`（列表滑删 + 编辑页删除复用）；三语新增 `pleaseEnterAmount`/`successKeepGoing` + gen-l10n。(2) 首页标题图标 `auto_awesome`→`Icons.eco`（悦己充盈，选项 F）/`Icons.workspace_premium`（本月最爱，选项 I）。(3) 悦己vs日常 bar 去 `LinearGradient` 改纯色 `palette.joy`。(4) 月度列表项 padding 10→16 + 尾部 `Icons.chevron_right` 与 `Dismissible(endToStart)` 共存（iOS Mail 模式）。(5) **修复删除/编辑后首页+分析页不刷新**——新 `lib/shared/utils/invalidate_transaction_dependents.dart` 普通函数失效 list+calendar(keyed) / today+monthly+happiness+bestJoy(family)，接入 list_screen 滑删与编辑保存返回。(6) 编辑页 AppBar 加红色删除按钮 → 共享确认 → delete use-case → 共享失效 → pop(true)。**偏离(Rule 1)**：2 处测试断言随码更新（保存后页面保持打开；确认对话框 AlertDialog→Dialog）。analyze 0 新增（仅遗留 onReorder info×2，非本次文件）、gen-l10n 通过、**2297/2297 全绿**（10 home_hero + 6 list_tile golden re-baseline）。先 HTML mockup `mockups/01-feedback`+`02-icons` 经用户确认 4 决策 | 2026-06-03 | 92227367+bea205f8+618ba6cf | Verified 2026-06-03 (independent: analyze 0 新增 on touched + 三 commit 落地确认 + 全量 2297/2297) | [260603-nr1](./quick/260603-nr1-ui-feedback-icons-list-fixes/) |
| 260603-s07 | 补全首页两项功能：(1) **月份切换**——新增 `HomeSelectedMonth` Riverpod 3 keepAlive notifier（`({int year,int month})` 记录态，`selectMonth`/`prevMonth`/`nextMonth`）→ 生成 `homeSelectedMonthProvider`；`home_screen.dart` 用它替换硬编码 `DateTime.now()` 的 year/month（`monthlyReport`/`happinessReport`/`bestJoy`/heroCard 全部随选中月响应；`todayTransactionsProvider` 保持永远显示当天）；`hero_header.dart` 月份标签两侧加 `Icons.chevron_left/right` `IconButton`（新 `onPrevMonth`/`onNextMonth` 必填回调），点击标签开 `_MonthPickerDialog`（年份导航 2000–2099 clamp + 4×3 月份网格，三语新增 `homeMonthPickerTitle`/`homeMonthPickerClose`）。(2) **最近交易查看全部**——原 TODO stub → `ref.read(listFilterProvider.notifier).selectMonth(now.year, now.month)` + `ref.read(selectedTabIndexProvider.notifier).select(1)`，切到 List tab 并定位本月（`MainShellScreen` 已是 IndexedStack，无需新路由）。**偏离(Rule 1)**：2 个 HeroHeader 测试 helper 补 `onPrevMonth`/`onNextMonth`（解 8 个 analyzer 错）。2 atomic commit、analyze 0、gen-l10n 通过、**2299/2299 全绿** | 2026-06-03 | baa2f927+2f6e93ca | Verified 2026-06-03 (independent: 主树 grep 确认 5 符号落地 + `flutter analyze lib/features/home/` 0 issues + 三语 ARB key 各 2 行) | [260603-s07-1-2](./quick/260603-s07-1-2/) |
| 260603-stw | 修复未来月份越界 crash（用户截图：处于本月时点「›」前进到下个月触发 analytics `endDate must not be in the future`）：当显示月=当前真实年月时**隐藏向右箭头**，首页与月度列表页同治。(1) `HeroHeader` 新增必填 `showNextChevron: bool`，false 时用 `SizedBox(28×28)` 占位替换右 `IconButton` 保持布局稳定；`home_screen.dart` 派生 `isCurrentMonth = year==now.year && month==now.month` 传 `showNextChevron: !isCurrentMonth`。(2) `HomeSelectedMonth.nextMonth()` 加 clamp 守卫（已在本月则 early-return no-op，防任何代码路径越界）。(3) `list_screen.dart` AppBar `actions:` 用 collection-if `if(!isCurrentMonth)` 省略右 chevron（基于 `listFilterProvider` 的 `selectedYear/Month`）。两处 HeroHeader 测试补 `showNextChevron`（过去月用 true）+ 新增「本月隐藏 chevron」用例；`list_screen_refresh_test` 参数化 + 新增「本月隐藏/过去月显示」2 用例。无 golden 受影响（AppBar/HeroHeader 不在 golden 套件内）。3 atomic commit、analyze 0 新增、**2303/2303 全绿**（+4 新测试） | 2026-06-03 | 18e62888+c0cc3786 | Verified 2026-06-03 (independent: 主树 grep 确认 showNextChevron/isCurrentMonth/nextMonth clamp/list collection-if 落地 + analyze 0 + 41 home/list 测试绿含新增 chevron 可见性用例) | [260603-stw](./quick/260603-stw-analytics-enddate-must-not-be-in-the-fut/) |

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

Last session: 2026-06-02 — Milestone v1.5 audited (`tech_debt`, re-audit after Phase 35) and completed/archived (tag `v1.5`).
Stopped at: Milestone v1.5 complete — awaiting next milestone.

**Planned Next:** `/gsd-new-milestone` — scope the next milestone.

## Operator Next Steps

- Start the next milestone with `/gsd-new-milestone`
- Refresh `.planning/codebase/` via `/gsd-map-codebase` before planning (five milestones stale)
