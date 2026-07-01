---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: 完成第一版上线前最后的功能开发
current_phase: 56
current_phase_name: setting
status: executing
stopped_at: Completed 56-01-PLAN.md
last_updated: "2026-07-01T09:50:43.317Z"
last_activity: 2026-07-01
last_activity_desc: Phase 56 execution started
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 29
  completed_plans: 25
  percent: 75
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-25 after v1.9 milestone close)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations
**Current focus:** Phase 56 — setting

## Current Position

Phase: 56 (setting) — EXECUTING
Plan: 3 of 6
Status: Ready to execute
Last activity: 2026-07-01 — Phase 56 execution started

Progress: Phase 56 PLANNED (0/6 executed); Phase 55 COMPLETE (12/12); Phase 54 complete; Phase 53 complete.

> **Planning gate note (Phase 56):** §13a decision-coverage-plan gate evaluated cleanly this time — `passed:true, total:5, covered:5` (D-01..D-05). No CJK false-negative and no override needed (contrast Phase 55). §13 requirements coverage = all 10 IDs covered. `state.planned-phase` CLI no-op'd (`updated:[]`, known on this STATE.md) → STATE hand-updated here.

### Decisions

v1.9 decisions (D-18..D-21 + the 52-0x plan decisions) are archived in `.planning/PROJECT.md` Key Decisions and the v1.9 milestone archive. No decisions are pending for the next milestone.

- [Phase 53]: 53-01: onboarding sketch 001 tone A satisfies DESIGN-01, zero HTML edits (design-gate record-not-recreate)
- [Phase 53]: app-lock sketch 002 tone B (Face ID + PIN, light+dark) satisfies DESIGN-02 with zero HTML edits
- [Phase 53]: 53-04: user approved all three designs (001/A, 002/B, 003/C) — DESIGN-01/02/03 经用户确认 completed; DESIGN-04 zero-Dart gate-exit verified, gate closed
- [Phase ?]: 54-01: onboardingComplete is plaintext SharedPreferences (no Drift migration, schemaVersion stays 22); voice-default resolver constrains output to {ja,zh,en}, never 'system'
- [Phase ?]: 54-02: onboarding ARB single-owner — 24 onboarding* keys ja/zh/en (intro 4 selling points/settings rows/lock-entry); onboardingStart=この設定で始める locked, distinct from profileStart
- [Phase 54]: 54-03: SettingsScreen deep-link uses jumpTo(maxScrollExtent) then post-frame ensureVisible — bare ensureVisible no-ops on a lazy ListView (off-screen SecuritySection element unmounted, GlobalKey context null)
- [Phase 54]: 54-03: scrollToSecurity defaults false; SecuritySection wrapped in KeyedSubtree so security_section.dart stays byte-unchanged (Phase 55 fills real lock)
- [Phase ?]: 54-04: import forces onboardingComplete=true (D-06); clear-all resets flag + deletes UserProfile (D-05)
- [Phase 54]: 54-05: OnboardingSettingsScreen merges identity (nickname[required]+avatar) with UI-language/currency/voice as unified 変更 rows; writes through existing providers; voice routed via resolveVoiceLanguageForOnboarding (never 'system'); signals via onConfirmed, never sets onboarding_complete (54-07 owns that)
- [Phase ?]: 54-06: onboarding intro/lock-entry are presentational callback-only screens; skip path explicitly writes setBiometricLock(false) because biometricLockEnabled defaults true (D-13)
- [Phase 55]: 55-01: PIN stored only as salted Argon2id PHC (m=19456,t=2,p=1,32B/16B salt) in existing pinHash slot via Isolate.run; constant-time verify; pure functions no Riverpod; greenfield no-migration (LOCK-07)
- [Phase 55]: 55-02: BiometricService catches local_auth 3.x LocalAuthException; every code + wildcard + residual nets -> PIN fallback (LOCK-05/10, T-55-05/06)
- [Phase 55]: 55-03: appLockEnabled/biometricUnlockEnabled default false, plaintext prefs, no Drift (schemaVersion 22)
- [Phase 55]: 55-03/D-02: onboarding skip writes setAppLockEnabled(false); legacy biometricLockEnabled retired (never read by new lock)
- [Phase ?]: 55-04: forgot-PIN copy implies no recovery path (LOCK-09/T-55-09); lock i18n keys centralized in one foundation ARB plan
- [Phase 55]: 55-05: LOCK-08 (PIN 递增冷却) descoped per D-06 (MVP zero rate-limiting, user-informed accepted risk) → relocated to v2 LOCK-V2-04; REQUIREMENTS row + ROADMAP SC-4 annotated covered-by-descope citing 55-RESEARCH §Security Domain sign-off
- [Phase 55]: 55-06: AppLockLifecycleObserver — relock gated on _didPause (paused reached), NOT inactive (Control Center masks but never relocks); _authInProgress fences the OS biometric sheet so Face-ID never loops; device-free callback-driven, main.dart wiring deferred to Plan 11
- [Phase 55]: 55-07: AppLockService = single lockEffective predicate (D-01); disableLock clears PHC (T-55-16); reauth only AuthResultSuccess->true (D-05)
- [Phase ?]: 55-08: four tone-B lock widgets are presentational/callback-only — PinKeypad(onDigit/onBackspace), PinDots(errorTrigger shake+haptic), FaceIdPanel(onRetry/onUsePasscode, never calls biometric), PrivacyMask(opaque Container not blur, T-55-18/D-07)
- [Phase ?]: 55-08: PinKeypad bottom-left is a blank cell (numeric-only, reusable by set-PIN flow); Face ID escape lives on FaceIdPanel, sketch keypad Face-ID key intentionally not replicated
- [Phase 55]: 55-09: AppLockScreen two-surface — Face ID auto-triggers on entry, every non-success AuthResult stays with ghost passcode escape (no dead end, LOCK-05/T-55-20); PIN instant-verifies on 4th digit, wrong shakes+clears zero cooldown (D-12/D-06); unlock via onUnlocked callback only (Plan 11 flips gate); biometric fenced by onBeginAuth/onEndAuth
- [Phase 55]: 55-10: SetPinScreen double-entry (enter->confirm, mismatch restarts, never persists half-entry, T-55-26); SecuritySection master toggle arms only after PIN set (T-55-24) and disables/changes only after reauth (biometric or in-place _PinReauthDialog verifyPin, D-05/T-55-25, NOT AppLockScreen — avoids wave-3 race); D-10 deep-link lock-not-set read from settings.appLockEnabled (sync, not isLockEffective) to stay test-safe
- [Phase ?]: App-lock gate uses setState flag flips (never pushReplacement) preserving the data-reset refresh path
- [Phase 56]: 56-01: LegalUrls (lib/core/config/) single source of truth for hosted privacy/terms + donation placeholder URLs, each with 上线前填真实值 marker (D-04); url_launcher ^6.3.2 added (win32 trio untouched)
- [Phase 56]: 56-01: trilingual 9-file asset-existence gate (legal_asset_parity_test.dart) enforces LEGAL-06 parity (D-02); GREEN on first run (56-02 assets present same wave)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260613-mgc | 修改外币编辑交互（头部金额点击弹现有键盘编辑；原币金额卡上移至分类卡前，仅留汇率+日元） | 2026-06-13 | 03a041d7 | [260613-mgc-foreign-currency-edit-ui](./quick/260613-mgc-foreign-currency-edit-ui/) |
| 260613-n5c | 外币编辑微调（汇率日期触发器显示实际日期2026/06/13；编辑页金额键盘保存键执行整条目保存） | 2026-06-13 | 08c87829 | [260613-n5c-fx-edit-date-and-save](./quick/260613-n5c-fx-edit-date-and-save/) |
| 260613-njf | 撤销改动2（键盘动作键恢复纯write-back，不再整条目保存）；编辑页外币键盘动作键文案「保存」→「确认」 | 2026-06-13 | 8b274e08 | [260613-njf-revert-keypad-save-confirm-label](./quick/260613-njf-revert-keypad-save-confirm-label/) |
| 260613-ohz | 货币选择器去除粗体三字码列（flag→symbol→name）；19个长尾币种名称支持zh/ja/en本地化 | 2026-06-13 | 72b2d788 | [260613-ohz-currency-picker-dedup-l10n](./quick/260613-ohz-currency-picker-dedup-l10n/) |
| 260613-ote | 长尾币种真实货币符号（NumberFormatter 新增 16 个：฿₹₱₫₽₺/Rp/RM/NZ$/R$/R/kr/MX$/zł；CHF/AED/SAR 保留三字码） | 2026-06-13 | e8ab6f82 | [260613-ote-longtail-currency-symbols](./quick/260613-ote-longtail-currency-symbols/) |
| 260613-ufn | 统一外币添加/编辑两屏的汇率卡片（同一 CurrencyLinkedEditFields：汇率可编辑/日元只读/汇率日期不可点击+staleness；移除添加页 ≈¥ 预览块；改日期 picker 自动重查汇率两屏一致，编辑跑 ADR-022 D-02/D-03） | 2026-06-13 | 182241bd | [260613-ufn-unify-foreign-currency-card](./quick/260613-ufn-unify-foreign-currency-card/) |
| 260613-wjx | 修复 Home 首页最近项编辑/删除后列表不刷新（onTap fire-and-forget → await pop 结果并 invalidateTransactionDependents，对齐 list_screen WR-03 契约；含回归测试） | 2026-06-13 | 72d52e15 | [260613-wjx-home-bug](./quick/260613-wjx-home-bug/) |
| 260613-wuv | 外币输入时汇率/换算改为卡片样式（与编辑页一致），滚动时仅金额输入区置顶；外币金额输入增加防抖缓冲避免实时计算闪频 | 2026-06-13 | d98f7e92 | [260613-wuv-fx-input-card-debounce](./quick/260613-wuv-fx-input-card-debounce/) |
| 260614-dx1 | 外币金额为整数时编辑/显示不再出现 .00（编辑页+键盘 formatMinorAsMajor；列表注释 formatCurrency trimWholeFraction；保留真实小数 12.50 与 JPY 整数路径） | 2026-06-14 | 3423d53e | [260614-dx1-fx-no-trailing-zeros](./quick/260614-dx1-fx-no-trailing-zeros/) |
| 260614-goh | 语音外币切换：①识别口语词（人民币/美金+全货币 zh/ja/en，大小写不敏感，regexAlternation longest-first）②修复头部药丸不切换（AmountDisplay 未传 currency→硬编码 JPY；新增 _displayCurrency，汇率成功才切外币、RateUnavailable 保持 JPY）（+32 用例） | 2026-06-14 | 117aecd5,d2b9df8e | [260614-goh-voice-currency-switch](./quick/260614-goh-voice-currency-switch/) |
| 260614-iww | 隐藏 OCR 记账入口（新增 kOcrEntryEnabled=false 编译期 flag，InputModeTabs 隐藏扫描页签 + navigateToEntryMode 短路；OCR 基础设施/屏幕零改动，翻转 flag 即恢复）+ 添加账目 FAB 点击=保存即 pop 返回 + 友好提示，长按=连续记账模式（停留清空表单 + 「继续记账」提示 + 退出键/退出提示）；ja/zh/en 三语温暖文案 | 2026-06-14 | 10236350,9c9b6068,45ed4332 | [260614-iww-ocr](./quick/260614-iww-ocr/) |
| 260620-jx2 | 支出趋势图表增加坐标轴/网格/上月对比线/起止点标注（统计页 within-month 累计趋势图：Y轴金额刻度+横向网格线从0起、X轴本地化日期刻度、清晰灰色虚线上月对比线+图例、本月起点/当前点 日期+金额标注；三 tab 通用，悦己仍单线守 ADR-012/D-E1；零新 ARB key；9 golden 重基线，full test 3061/3061，analyze 0） | 2026-06-20 | ec4d43e2,c005e531 | [260620-jx2-trend-chart-axes](./quick/260620-jx2-trend-chart-axes/) |
| 260620-kll | 支出趋势图表修正R2（jx2 复审纠正）：X轴显示整月（maxX=daysInMonth(anchor)）；本月线 day1→今日 carry-forward（use-case 注入 now，图表保持无时钟以稳定 golden）；上月参考线画整月；起点不再标注；终点 date+amount 数据锚定在端点附近（本月≥上月→标点上方，否则下方；上月线同规则但位置相反；参考点=今日）；悦己仍单线（ADR-012/D-E1，无 previousMonthJoy）；零新 ARB key；analyze 0、full test 3071/3071、8 golden 重基线；代码层 9/9 must-have 通过，设备端视觉待用户确认 | 2026-06-20 | fc5e6caf,a38938ee | [260620-kll-trend-chart-fix](./quick/260620-kll-trend-chart-fix/) |
| 260620-lfp | 统计页按 round5/r5-drawer-joybar.html mock 整页重建（保留趋势图，--full 流水线）：①重新加回4个节标题(支出趋势·实用/分类支出·实用/小确幸日历·悦己/悦己满足度分布·悦己，逆转 Phase46 D-F2)，新增 AnalyticsSectionHeader 组件；②悦己横向堆叠条内嵌为分类环卡抽屉(connector+drawer，registry 6→5 specs，joyCategoryAmountsProvider 折入 donut 刷新并集；JoySpendCard 降级为薄 wrapper 保留其测试)；③新增 joy_warm_palette j1–j7 暖色板(core/theme，过 color_literal_scan)；④直方图中位满足度改数据派生(加权中位，非硬编码 mock「7」)；⑤趋势图内部冻结(仅 showHeader:false，line_chart 零 diff，守 D3)；16 新 ARB key ja/zh/en+gen-l10n。验收：plan-check PASSED+verify 9/9 must-have、analyze 0、full test 3072/3072、34 golden macOS 重基线。CR 2 非阻塞 warning(空悦己态抽屉头 chrome；嵌套致 monthlyReport error 连带隐藏 joybar) | 2026-06-20 | 8cee0dbd,971adf09,ca78e669,9ed170ac,adb7fa8a | [260620-lfp-round5-r5-drawer-joybar-html-mock](./quick/260620-lfp-round5-r5-drawer-joybar-html-mock/) |
| 260620-v2m | 统计页趋势柔化/阴影/终点标签 + 圆环环上% + 成员维度/过滤（--discuss+--validate；3 灰区问用户：D1 配色=App ADR-019 不用参考彩虹、D2 成员=deviceId→group_members、D3 环上只标%名称留图例）。Part1 支出趋势：本月线柔化曲线(isCurved+curveSmoothness0.22+preventCurveOverShooting)+below-line 线色→透明渐变填充+终点 date/amount 标签锚定终点 marker 正上方（守 jx2/kll 轴/网格/上月虚线/carry-forward/整月X/悦己单线 D-E1）。Part2 圆环：donut_hero 环上 title:''→`_onRingPctTitle`(5%阈值+「其他」`_suppressedRingTitle` 避让，名称+金额留可点图例，中心保留本月支出+总额，D3)；新增「分类/成员」维度切换 + 成员过滤下拉(成员=tx.deviceId→group_members displayName/avatar，单设备优雅降级1片，`memberColorFor` deviceId 稳定色，不发明共同帐户 D2)；新 GetMemberSpendBreakdownUseCase(6测)+DonutDimensionState Notifier(5测)+`memberFilteredCategoryBreakdownProvider`(过滤两维度都真实收窄)；ADR-019 配色(D1)、schema v21 零 DAO/migration、零 home/*(GUARD-01)；4 新 ARB key×3 locale+gen-l10n。验收：plan-check PASSED + verify 7/7 code must-have（human_needed：曲线/渐变/环上%/成员切换 设备端待 UAT，无阻塞 gap）、analyze 0、full test 3088/3088、19 golden macOS 重基线 | 2026-06-20 | 80c1d987,efdd2ec8,f8b1f722,0f18252a,eb74b990 | [260620-v2m-stats-trend-donut-member](./quick/260620-v2m-stats-trend-donut-member/) |
| 260621-son | 修复统计页「分类支出」圆环卡成员维度3个bug：①成员维度「自己」图例改用设置→编辑个人资料的用户名（watch `userProfileProvider`，改名 invalidate 自动同步），不再显示截断 deviceId(95fayo…)；②新增 `currentDeviceIdProvider`(包 keyManager.getDeviceId)，无 group 时也向成员 filter 注入合成「自己」项(deviceId 去重，新 ARB `analyticsDonutMemberFilterSelf`×3 locale)；③「分类/成员」toggle+filter 行从卡片顶部移到 `DonutHero` 圆环下方、详细列表上方(分类/成员两维度+有无 filter 三路径一致)。analyze 0、full test 3091/3091、14 golden macOS 重基线；Task3 设备端 UAT 已通过✓(2026-06-21，控件行位置/自己名显示/改名同步/无group「自己」过滤项均确认) | 2026-06-21 | 01b29fc8,0c1fcf10 | [260621-son-bug-group](./quick/260621-son-bug-group/) |
| 260621-ti1 | 统计页「分类支出」donut 卡片：类目 icon + 圆环放大 + 列表去色块。①分类详细列表行 / 悦己「钱花在哪」legend 行类目名前加「上一级(L1顶层)」类目 icon、圆环显示了%的扇区加 icon（全经共享 `parentCategoryIconFromId`，零新 ARB/数据层/依赖；成员维度保持头像 emoji 不改）。②圆环放大：section radius 30→41.4、centerSpaceRadius 54→59.4（外径×1.2/内径×1.1），容器 SizedBox 200→234、center maxWidth 96→106，widget test bare card 包 `SingleChildScrollView` 避 800×600 测试窗溢出。③圆环 icon 改为 % 正上方中线对齐：抑制内置 title（`showTitle:false`），icon+% 合成居中 Column badge（原 badgeWidget/title 沿半径分置→非6/12点钟扇区横向重叠`88🍴%`）。④分类/悦己列表行去掉色块、icon 取色块颜色（分类→该行 arc color、悦己→`segment.color`；成员/「其他」行无 icon 保留色块）。analyze 0、full test 3091/3091、多轮受影响 golden（category_donut/joy_spend/scroll-smoke）macOS 重基线；设备端 UAT 已通过✓(2026-06-21) | 2026-06-21 | 0903114b,a2925f42,0064693f,5ae71263,87a313b1,6c9794d3 | [260621-ti1-category-icon-icon](./quick/260621-ti1-category-icon-icon/) |
| 260621-uus | 统计页删除截图红框圈出的编辑性元素（纯展示层删除，零数据流改动）：①AppBar 删「全部条目 ▼」entry-filter chip（删孤立 widget+专属测试；保留 `selectedJoyMetricVariantProvider`，默认 all）；②四个分区标题删「实用/悦己」tag chip（保留左侧彩色竖条+标题）；③悦己 drawer 去 connector(dashed dots+「把悦己这一块放大看看」)+副标题「仅呈现去向，不分高下」+caption「百分比是各项占悦己自身…」，标题缩短为「悦己 {amount}」（保留金额/笔数/bar 主体）；④删小确幸日历 footer「这个月有 X 天…」+悦己满足度分布 footer「大多落在中高位…」（保留 median pill）；3 ARB 对称删 12 个 0-ref key + drawer 标题改值 + gen-l10n、删 `_JoyConnector` 类/孤立测试 helper（无 dead code）。analyze 0、full test 3081/3081、15 golden（scroll-smoke/joy_calendar/satisfaction_histogram）macOS 重基线（category_donut/joy_spend 验证无变化未重基线） | 2026-06-21 | 15ebc181,730b5bb3,412a8e9d,4c8b6c20,27224cba,547a359d,5b8c1bd9 | [260621-uus-strip-analytics-editorial-captions-tags-](./quick/260621-uus-strip-analytics-editorial-captions-tags-/) |
| 260622-0ly | 打开统计页查看当前月时，小确幸日历默认选中「今天」（高亮今天格子 + 自动展开今天的小确幸明细面板，无记录则空状态文案）；仅当前月生效、翻到其它月份不自动选中（翻回当前月重新选中今天）、同月内 pull-to-refresh 保留用户手动点击的那天、手动点击行为不变。`_JoyCalendarBodyState` 新增 `initState`/`didUpdateWidget`/`_defaultSelectedDay()`（"今天"仅当落在 anchor 当月内；单一状态 `_selectedDay` 同时驱动 ring 高亮+内联展开）；零 provider/ARB/数据层改动。决定论：现存 golden/测试窗口钉死 May 2026→今天永不落入→默认选中恒 null→**0 golden 重基线**；新增决定论 widget 测试（当前月→选中+展开 / 过去月→不选中，只比 y/m/d）。analyze 0、full test 3083/3083、仅 2 文件改动 | 2026-06-22 | 3eabc907,1811a22f | [260622-0ly-joy-calendar-default-select-today-on-ope](./quick/260622-0ly-joy-calendar-default-select-today-on-ope/) |
| 260622-d5i | 统计页「分类支出/カテゴリ支出」donut 卡片内嵌悦己抽屉(`JoySpendDrawer`)去边框 + 分割线分离 + 随成员维度&筛选联动（先出 HTML 设计稿经用户确认再开发）。①视觉(D1)：删樱粉描边 `Container`(`Border.all`/radius18/盒内边距)→1px `borderDivider` 分割线与「整体」(donut+类别图例)分离，保留「♡悦び」chip(`joyLight`/`joyText`)+¥总额+计数行。②成员筛选联动(D2)：悦己读 `donutDimensionStateProvider`，category 维度经 `joyCategoryAmounts(deviceId:)` 复用整体同款 `tx.deviceId==deviceId` 过滤。③维度切换(D3，用户选「切成员维度悦己也按成员拆」)：member 维度经新 `joyMemberAmounts`(复用 `GetMemberSpendBreakdownUseCase` 传 `ledgerType: LedgerType.joy`)in-widget 按成员收窄，成员段 label=成员名/emoji+`Icons.person_outline`+JoyWarmPalette。数据层 2 use case 各加 1 可选参数(`deviceId`/`ledgerType`，null 路径字节不变，单测+golden 双证)；零新 DAO/migration(复用 `findByBookIds`)、GUARD-01 无 home/*、全文经 `S.of(context)`、零裸 hex；新 ARB `analyticsJoyDrawerMemberCount`×3+gen-l10n；`joyMemberAmounts` 折入 `categoryDonutRefreshTargets`。analyze 0、受影响 unit/widget/golden+anti_toxicity 独立复跑 82/82(全 analytics 421/421)、4 golden macOS 重基线(scroll-smoke+3 member-dim 变体) | 2026-06-22 | 0f8ddff4,968e1e5f,20cdc950,fa9b97f1,d163abbc | [260622-d5i-filter](./quick/260622-d5i-filter/) |
| 260622-nhs | 记账录入「按住说话」单页重构：取消「手工/语音」模式切换 Tab，合并单页 push-to-talk。手工键盘唯一常驻；底部全宽樱粉「按住说话」长条(`HoldToTalkBar`)，按住升起聆听浮层(`VoiceListeningOverlay`：正在聆听脉冲+实时转写+16条波形+录音红麦克风+松开提示)，松手把解析金额/分类/商家/日期/满意度(+外币 triple)填入同一张表单并停留确认(D-2 不自动保存)。复用不重写：抽 `VoicePttSessionMixin`(录音/转写/chunk merger/解析/满意度/外币 triple 全部会话逻辑)，voice_input_screen re-host 字节级不变、全套既有测试零断言改动通过。`_lastFillWasVoice` 把 `EntrySource.voice` 透传进 live form config(submit 读 config，provenance 跨单页合并存活，T-nhs-03)；清空金额复位 manual。删 `entry_mode_switcher`/`input_mode_tabs`(InputMode enum)/`entry_mode_navigation_config`(零消费者)；voice/ocr 屏去 switcher；voice_input_screen 保留未路由(D-3)；OCR `kOcrEntryEnabled` 隐藏态不动。删孤立 Tab ARB `manualInput`/`voiceInput`/`ocrScan`+gen-l10n；新 3 key `holdToTalkBar`/`listeningTitle`/`releaseToFill`×3。偏差(Rule3)：抽 `AddScreenForeignCard` 到 `manual_one_step_foreign_card.dart` 回收 LOC(975→955)。analyze 0、full test 3097/3097、1 golden(voice mic) macOS 重基线；代码层 must_have 全过。**R2 真机迭代**：长条贴 iOS 上滑手势区难按 → 改交互模型：长条移键盘上方+底部 SafeArea、hold→单击、文案改「语音记录」+线条 mic(`Icons.mic_none`,`VoiceRecordBar`)；聆听浮层→自动填表 modal(`VoiceListeningModal`：说一句自动填表/轻点空白处或遮罩退出保留/唯一「重置·恢复账目」还原说话前快照,去完成/取消)；新增 `ManualEntrySnapshot` 支持重置还原；ARB 改 `voiceRecordBar`/`listeningTitle`/`voiceResetRestore(Sub)`。analyze 0、full test 3104/3104、0 golden(无覆盖该 UI)；旧 voice_input_screen 零改动绿。偏差(累积)：manual_one_step_screen 1007 LOC(>800 上限,待后续抽)。设备端语音 UAT 待用户确认。**R3 真机修 3 bug**：① 长条 52→38 融入键盘顶部、收紧键盘下方过大留白；② 重置后不再聆听 → 加幂等 `restartPttListening()` 重置后保证继续听；③ 语音浮层+遮罩 → 内联 `VoiceRecordPanel` **就地替换键盘**(去 scrim/overlay、背景不灰、表单实时填不跳动)。analyze 0、full test 3108/3108、0 golden。**R4 修语音生命周期 4 问题**：A 重置没清识别器累积 buffer→`resetPttSessionAndRestart` cancel+全新 startListening；B 重置后假死(reset 重启与 onStatus 双 re-arm 竞态)→`_restarting` 守卫串行化；C 状态写死→`PttListenStatus{listening,processing,stopped}` 实时驱动面板(+ARB 正在解析/停止聆听×3)；D 解析慢(final 解析两遍+只 final 才填)→去重+partial 实时填表(亚秒级)。只动 continuous tap 路径,旧 hold 屏零改动绿。analyze 0、full test 3117/3117、0 golden。**R5 修连续会话错误/状态**：根因=ptt mixin 没 override `onError`,iOS 把 `error_no_match`(静音)报 permanent→基类翻 `isInitialized=false`→bar 锁死(bug1);错误路径不更新 `_listenStatus`→停了仍显「正在聆听」(bug2)。修=override `onError` 按错误**码**白名单 `_transientSilenceErrors{no_match,speech_timeout}` 分类:连续+瞬时→不 toast 不锁、`_reArmAfterTransientError` 续听;连续+致命→teardown+`_recoverBarAfterFatalError` 重 init 让 bar 可再点;hold 走 `super.onError` 不变;`_isRecording` 转 false 同步 `_listenStatus=stopped`。analyze 0、full test 3123/3123、0 golden。**R6 一次性聆听+金额解析**：① iOS 连续 re-arm 不可靠(乐观 listening 但 mic 死)→改一次性:识别器终止即 stopped、不再 re-arm,面板显「停止聆听」+新提示「点击重置重新录入」(ARB `voiceTapResetToRerecord`×3),面板可见性由 `_voiceModalOpen` 与 `_isRecording` 解耦(否则停了面板消失);② 说「99999日元」填成 9 根因=**解析器**(`一共` 的 `一` 触发数字 hint,zh/ja 状态机 `digit=value` 逐 token 覆盖,多位阿拉伯数字只留末位;逗号又切断)→修 `normalize` 累积相邻阿拉伯数字 + `extractAmount` 阿拉伯正则权威(共享,hold 路径同获益,zh corpus 53→54/55)。analyze 0、full test 3132/3132、0 golden。**R7 面板按键重排**：删底部「重置·恢复账目」按钮;中央方块双状态(`_CentralSquare`,按 `pttListenStatus`)——录音/解析=灰底+`Icons.mic_none`(被动)、停止=红底+`Icons.restore`(可点→onReset 还原快照+重新录入);两态等高(`Visibility(maintainSize)` 预留「点击重置重新录入」占位,切换不跳动);删 `voiceResetRestore(Sub)` ARB「· 恢复账目」。palette-only(复用 backgroundMuted/textTertiary/recordingGradient,无裸 hex)。analyze 0、full test 3132/3132、0 golden。**R8 方块居中+增高**：方块是面板核心→垂直居中,面板改 `SizedBox(356)`(↑~296)三段 `Expanded(flex:1)` 上区(状态/转写/波形居中)—方块正中—下区(提示居中),上下 1:1 等分;两态等高不变。纯布局,analyze 0、full test 3136/3136、0 golden。**✅ 2026-06-23 用户真机验收通过(approved,覆盖 R1–R8 累计最终态)。** | 2026-06-22 | 4c651bbc,180c1325,c2921b5b,24898044,b68f6ccf,440afe73,19ee8f62,d9ad48d9,6d098fa0,0b6d9101,1c858612,d690f472,1eee90a6,ccc4cde6,1f309a9b,a44e7b0d,e5d64133,d2656847,d2773edf,f1e6cb36,d4e335d4,8685f019 | [260622-nhs-entry-voice-switch-redesign](./quick/260622-nhs-entry-voice-switch-redesign/) |
| 260623-0cj | 数字小键盘重设计（先出 HTML 设计稿经用户两轮确认再开发）：① 语音录入键 `VoiceRecordBar` 38dp 满宽贴边 `joyLight` 色带(+下边线) → **居中 200dp 椭圆胶囊**(`Material(StadiumBorder)`+`InkWell(customBorder)`，外层 `Container(padding:vertical8,alignment:center)`)，浮在 cream 屏背景/白键盘卡片之上、左右各内缩~95dp **不顶边**，胶囊为唯一点击区(原整条贴边可点)；`Icons.mic_none`+`l10n.voiceRecordBar` 文案/配色不变，新增 `voice-record-pill` key。② 底排(删除/¥货币/保存)由与数字键等高 → `SmartKeyboard` build() 新增 `bottomRowHeight=max(40,keyHeight×0.77)` 传入 `_buildActionRow`(三键互等高 D-08 不破)，≈40dp(−23%)；数字/extra 行仍 keyHeight(≥48dp 下限不动)。宽 200=A「贴文字」≈150 与 B「内缩20」≈310 的中间值(用户选 M)；高 40「下排40dp没问题」。仅改键盘区、数字键尺寸/配色/间距/tabular 全不变、palette-only 零裸 hex、零 ARB/codegen；`VoiceRecordPanel`/PTT/`manual_one_step_screen` 未触及。TDD：RED(无 pill key + 底排==数字键 51.12)→GREEN；TEST1 48dp 下限收窄到数字/extra 键、新增 TEST1b 底排更短、TEST5(三动作键等高)绿。analyze 0、full test 3137/3137(含 architecture+golden)、10 SmartKeyboard golden(6 matrix+4 dot-gating) macOS 重基线(voice mic golden 作用域在 voice-mic-button 子树→不受影响)。**R2(用户反馈)**：① 语音键白底「一体」——外层 `Container` 透明(悬浮 cream)→ `palette.card` 白底并接管键盘组合顶边；`SmartKeyboard` 加 `showTopBorder`(默认 true 向后兼容)，`manual_one_step_screen` 传 `false` → 语音条+键盘=一整片白、无内部分隔线。② 语音胶囊 40→**44dp**、底排由 `max(40,kh×0.77)`→**固定 44dp**(HIG 触达，仍<数字键48)。③ 胶囊配色+字体对齐「记录」键(`_GradientKey`)：`joyLight` 纯色→FAB 樱粉渐变+actionShadow+全圆角；`labelMedium/joyText`→`titleMedium 16 w700` 白字、白 mic，loose `Flexible` 防长串溢出。analyze 0、full test 3138/3138、10 golden 二次重基线(底排40→44)。**R3(用户反馈)**：语音键下方留白 ≈20dp(语音条 vertical8 + 键盘 top12)>数字行距 12dp → 语音条 `padding` `symmetric(vertical:8)`→`only(top:12)`，胶囊上方=语音条 top12、下方=键盘 top padding 12，**上下各 12dp 与数字行间距一致**（像一行键盘行）。仅 hold_to_talk_bar.dart，test 断言 `padding==only(top:12)`。analyze 0、full test 3138/3138、0 golden。**✅ 2026-06-23 用户真机验收通过（approved，覆盖 R1–R3 最终态）。** | 2026-06-23 | db828168,83175136,10d8d056 | [260623-0cj-numpad-oval-voice-bottom-row](./quick/260623-0cj-numpad-oval-voice-bottom-row/) |
| 260624-fast-band | 隐藏添加账目表单上语音识别的「置信度 band」药丸（截图红框元素）。沿用 52-UAT 隐藏 alternate chips 的可逆模式：新增 `@visibleForTesting showConfidenceBand` flag（默认 false），与 `showAlternateChips` 并列门控；两者皆 false（生产默认）时整条 recognition surface 不渲染，分类纠正仍走分类卡→全选择器（D-05/06/07 不变）。`ConfidenceBandIndicator` 组件与 `updateRecognition` 管线保留可翻转重启。可见性测试改断言 band findsNothing；chip-path 纠正用例仍以 `showAlternateChips: true` 渲染。analyze 0、受影响 3 套件 36/36 绿。 | 2026-06-24 | fdf2bd16 | — |
| 260624-fast-hint | 语音录入面板「点击重置重新录入」提示语贴近红色重置方块（截图红框：原本两条提示在下半区居中→与重置按键间距过大）。`VoiceRecordPanel` 底部 Expanded 的 Column `MainAxisAlignment.center`→`start` + 16dp 引导间距，提示组上移到重置方块正下方。布局不变式保留：仍为两个等 flex Expanded 夹中央方块（方块仍居面板垂直中心）、listening/stopped 两态等高（maintainSize 占位 + 常量间距与状态无关）。analyze 0、面板套件 13/13 绿。 | 2026-06-24 | 2c1d150a | — |
| 260624-fast-hint2 | 修正上一步（fast-hint 把两条提示都上移了）：仅上移「点击重置重新录入」，「轻点空白处退出」恢复修改前位置。底部 Expanded 还原为 `MainAxisAlignment.center` 居中分组（退出提示位置=原样，由 maintainSize 占位保证），只对重置文案套 paint-only `Transform.translate(0,-34)` 视觉上提至重置方块下方（不影响布局→退出提示不动）。偏移 -34 钉死在固定 356dp/74dp 几何。布局不变式保留（两等 flex Expanded、方块居中、两态等高）。analyze 0、面板 13/13 + anti_toxicity + manual_one_step 套件绿。 | 2026-06-24 | 6b01f554 | — |
| 260624-v84 | 进入「选择分类」页面时，若表单已带已选分类则自动滚动使其所属一级类目对齐视口顶部（已选 L1 既有的自动展开逻辑不变，L2 chip 随即可见）；无已选分类或 id 失效则停在顶部。`CategorySelectionScreen` 新增 `_pendingScrollL1Id`/`_selectedGroupKey`/`_scrollController`：`_loadCategories` 解析已选 L1 后注册 `addPostFrameCallback`；`_scrollToSelectedGroup` 两阶段——估算行高 `jumpTo` 让 `ListView.builder` 布出懒构建的目标 group，下一帧 `Scrollable.ensureVisible(alignment:0,250ms)` 精确动画对齐（弃用首选的 `cacheExtent:double.infinity`——被 viewport 布局断言拒绝、抛数千异常）；一次性，不干扰用户后续手动滚动。零 ARB/数据层/依赖改动。analyze 0、screen 套件 9/9（2 新增自动滚动 + 7 原有无回归）、related correction 套件绿；无 picker golden 主图无需重基线。 | 2026-06-24 | a50c8622 | [260624-v84-category-category](./quick/260624-v84-category-category/) |
| 260625-gwy | 修复 CI `dart run custom_lint` 失败（run 28139595431，5 条 import_guard WARNING）。5 处均为合法的同层 domain→domain 模型导入，只是缺失于 per-directory `import_guard.yaml` 白名单（每个白名单继承 feature 级 deny，须显式 re-allow 兄弟/跨 feature domain 模型）。补 5 条白名单：accounting/domain/repositories（`../models/merchant.dart`、`../models/merchant_match_entry.dart`）、analytics/domain/models（`monthly_report.dart`、跨 feature `../../../accounting/domain/models/transaction.dart`）、voice/domain/models（`recognition_outcome.dart`）。零 `.dart` 源码改动（导入本身正确）。验证：custom_lint exit 0「No issues found!」、flutter analyze 0。inline 执行（5 行白名单低于 GSD subagent 委派阈值）。 | 2026-06-25 | 26cf4f79 | [260625-gwy-fix-custom-lint-import-guard-ci-failure-](./quick/260625-gwy-fix-custom-lint-import-guard-ci-failure-/) |
| 260627-v0w | 修复设置「删除全部数据/导入备份」成功后 Home/列表/分析页不刷新需重启。双根因：① bookId 非 provider，而是 main.dart 启动时捕获并以构造参数下传，擦库后悬空于已删行（无 currentBookIdProvider，CLAUDE.md 该示例已过时）；② ClearAllDataUseCase 擦库后既未重建默认账本也未失效任何 Riverpod provider，IndexedStack 四 tab 常驻挂载致一次性 FutureProvider 不重取；_importBackup 同隐藏 bug。方案（DRY，两路径共用单一 app-root 例程）：新增全局 `dataResetSignalProvider`（@riverpod Notifier，fire() 自增），两处成功路径各 `.fire()` 一行；`_HomePocketAppState` 用 `ref.listen`（非 watch）跑 `_reinitializeAfterDataReset`——count-guarded seedAll + ensureDefaultBook 取新 bookId → `invalidateAllDataProviders(ref)` 失效全部 25 个数据 family（home/list/shadow 5 + analytics 12 + happiness 5 + bookById + appSettings + currentLocale）→ setState 重建 shell。新增 `lib/core/state/data_reset_signal.dart`、`lib/shared/utils/invalidate_all_data_providers.dart`（镜像既有 invalidate_transaction_dependents 模式，不触发 import_guard）+ 单元/集成测试；25 个 provider 名执行前逐一核验（planner 清单准确）。验收：删除全部数据/导入备份后无需重启即在三页可见；擦库后恰一个默认账本且 bookId 指向它。build_runner clean、analyze 0、full test 3358/3358 绿。 | 2026-06-27 | b57a2605,cc907e17,fb6c4632 | [260627-v0w-home-clearalldatausecase-invalidate-rive](./quick/260627-v0w-home-clearalldatausecase-invalidate-rive/) |

## Last Milestone Snapshot (v1.9)

- **Phases:** 4 (49-52), **Plans:** 22
- **Duration:** 2026-06-23 → 2026-06-24 execution; closed 2026-06-25
- **Audit Status at Close:** `tech_debt` — accepted (20/20 requirements, 4/4 phases verified [49:5/5 · 50:4/4 · 51:14/14 · 52:7/7], 5/5 cross-phase seams, 4/4 E2E flows; T-01/T-02 resolved before close; suite 3352/3353 green)
- **Outcome:** Voice pipeline decoupled into `MerchantRecognizer` + `CategoryRecognizer` arbitrated by a pure-domain `RecognitionReconciler` (none/weak/strong 3×3 truth table); ledger reworked into a pure function of the final category (retired `lib/application/dual_ledger/`); 391 JP merchants migrated to an encrypted Drift table; qualitative 3-tier confidence band + alternate chips + KEYWORD-only inline correction; English voice parity. schema v21→v22; drift 2.31.0; no new heavy deps
- **Tag:** `v1.9`, schema at v22

## Previous Milestone Snapshots

- **v1.8** (6 phases 43-48, 32 plans, `tech_debt`) — 统计页面重设计（实用化 × 悦己情感化）; round-5 B 5-card analytics rebuild; schema v21
- **v1.7** (3 phases 40-42, 20 plans, `tech_debt`) — 多币种支持 foreign-currency entry; schema v20→v21
- **v1.6** (4 phases 36-39, 27 plans, `tech_debt`) — 购物清单 family shopping list; schema v19→v20
- **v1.5** (5 phases 31-35, 24 plans, `tech_debt`) — 文案与配色统一; ADR-019 "Sakura Mochi × Wakaba" palette
- **v1.4** (7 phases 24-30, 29 plans, `tech_debt`) — 列表功能 kakeibo-style List tab
- **v1.3** (6 phases 18-23, 47 plans, `tech_debt`) — 迭代帐本输入 single-screen voice entry
- **v1.2** (5 phases 13-17, 37 plans, `tech_debt`) — Happiness Metric Refresh (ADR-016, Σ joy_contribution)
- **v1.1** (4 phases 9-12, 40 plans, `known_debt`) — Happiness Metric & Display
- **v1.0** (8 phases 1-8, 48 plans, `passed`) — Codebase Cleanup Initiative

## Accumulated Context

### Roadmap Evolution

v1.9 (Phases 49-52) shipped & archived 2026-06-25 — see `.planning/milestones/v1.9-ROADMAP.md`, `.planning/MILESTONES.md`, and `.planning/PROJECT.md`. The per-milestone roadmap evolution, locked constraints, open design questions, and pending todos for v1.9 and earlier milestones live in those archives. **v2.0 roadmap created 2026-06-28** — 4 phases (53-56) covering 31 requirements (DESIGN 4 · ONBOARD 7 · LOCK 10 · DONATE 4 · LEGAL 6), 100% mapped, 0 orphaned. Design-gate-first (Phase 53, no production code, sequels v1.8 Phase 43) → Onboarding gate (54) → App-lock (55, highest-risk, own security review) → Settings legal/donation/JP-compliance (56, launch gate with store-review slack). Integration milestone; only new runtime dep is `url_launcher`. See `.planning/ROADMAP.md` + `.planning/REQUIREMENTS.md`.

### Blockers / Concerns

No active blockers. Pre-existing carried debt carried forward to the next milestone (unchanged):

- **v1.5 a11y UAT:** Phase 35 W1 on-device screen-reader announcement of localized ledger-chip labels — human_needed
- **v1.5 vocab residual:** `Book.survivalBalance`/`soulBalance` DB columns need future DB-migration phase before public release
- **v1.4 GAP-2:** LIST-02 `watchByBookIds` reactive stream is dead code; defer
- **v1.3 voice-flow polish backlog:** Phase 22 advisories on `voice_input_screen.dart` — now largely MOOT (that screen is unrouted dead code after the v1.9 + 260622-nhs single-page rebuild); revisit only if `voice_input_screen.dart` is deleted
- **MOD-005 OCR slot:** OCR ledger entry hidden behind reversible `kOcrEntryEnabled` flag (260614-iww); flip when MOD-005 writer lands

## Deferred Items

### Items acknowledged and deferred at v1.9 milestone close on 2026-06-25

Pre-close artifact audit flagged 34 quick-tasks. The **4 genuinely-incomplete v1.3-era voice items were RESOLVED (not merely deferred)** before close as superseded-by-v1.9 (commit `fc944d86`) — their target pipeline was deleted/rebuilt by this milestone + 260622-nhs. The remaining 30 are cosmetic metadata-drift, acknowledged below (same accepted pattern as v1.5–v1.8).

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| voice_backlog_resolved | 260526-k92/l0o/pg6 (+ empty n7b dir removed) — v1.3-era VOICE-POLISH-V2 carry-overs targeting the pre-v1.9 voice pipeline (voice_category_resolver.dart / manual-voice tab / voice_input_screen.dart) that v1.9 + 260622-nhs deleted/rebuilt; pg6's orphan-key contract is a live Phase-52 invariant | resolved (superseded-by-v1.9, marked complete) | v1.9 close |
| metadata_drift | `audit-open` reports 30 quick tasks as unknown/complete-with-comment (SUMMARY.md lack a clean `status: complete` frontmatter line). All recorded Verified in the Quick Tasks Completed table. Same cosmetic pattern as v1.5 (17) / v1.6 (38) / v1.7 (33) / v1.8 (34) | cosmetic, no functional gap | v1.9 close |
| nyquist_gap | Phases 49/51/52 VALIDATION.md drafts (`nyquist_compliant: false`); Phase 50 compliant. Documentation-grade; suite 3352/3353 green. To clear: `/gsd-validate-phase 49/51/52` (T-04) | accept (documentation-grade) | v1.9 close |
| summary_frontmatter_drift | MERCH-03, XVAL-02, LEDGER-01, LEDGER-02, VEN-02 left `requirements_completed` empty in owning plan SUMMARYs; all satisfied per VERIFICATION + traceability (T-05) | cosmetic, no functional gap | v1.9 close |
| confirm | T-03: two learning loops co-fire at save (legacy Phase-18 merchant→category hook + Phase-52 KEYWORD-only correction); RECUX-03 contract literally honored (the correction path never touches the merchant table); pre-v1.9, not a regression — confirm intended | accept (awareness; pre-v1.9) | v1.9 close |

### Items acknowledged and deferred at v1.8 milestone close on 2026-06-22

Acknowledged via the pre-close artifact audit (35 items) — all benign, matching the accepted v1.2–v1.7 close pattern:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| nyquist_gap | Phase 47 `47-VALIDATION.md` draft + `nyquist_compliant: false` (Phases 43–46 compliant). Documentation-grade; underlying suite 3090/3090 green. Mirrors accepted v1.2–v1.7 pattern. To clear: `/gsd-validate-phase 47` | accept (documentation-grade) | v1.8 close |
| uat_flag | Phase 47 `47-UAT.md` flagged by `audit-open` as a UAT gap, but status is `passed` with **0 pending scenarios** (on-device D-10, 10/10 PASS, user-approved 2026-06-20) — false-positive flag, actually complete | resolved (flag stale) | v1.8 close |
| metadata_drift | `audit-open` reports 34 quick tasks as incomplete/unknown (SUMMARY.md lack `status: complete` frontmatter). All recorded in the Quick Tasks Completed table. Same cosmetic pattern as v1.5 (17) / v1.6 (38) / v1.7 (33) | cosmetic, no functional gap | v1.8 close |
| summary_frontmatter_drift | GATE-01 (in 43-01) + TREND-01 (in 44-02) satisfied + verified in their phase VERIFICATION.md but not auto-extracted into SUMMARY `requirements_completed` frontmatter. Cosmetic metadata drift, no functional gap | cosmetic, no functional gap | v1.8 close |
| voice_backlog | 260526-k92/l0o/n7b/pg6 voice-tab/active-learning follow-ups — genuinely incomplete; carried as the v1.3 VOICE-POLISH-V2 backlog (re-affirmed from v1.7 close) | defer to VOICE-POLISH-V2 | v1.8 close |

### Items acknowledged and deferred at v1.7 milestone close on 2026-06-14

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| nyquist_gap | Phases 40/41/42 VALIDATION.md draft + `nyquist_compliant: false`. Documentation-grade; underlying suite 2786/2786 green. Mirrors accepted v1.2–v1.6 pattern. To clear: `/gsd-validate-phase 40/41/42` | accept (documentation-grade) | v1.7 close |
| verification_flag | Phase 42 `42-VERIFICATION.md [human_needed]` flag never flipped — RESOLVED by `42-UAT.md` (2026-06-14, 4/4 pass, 0 issues) covering exactly the 4 flagged device items (D-02 dialog, D-03 toast, flag-emoji render, live-preview behavior) | resolved (flag stale) | v1.7 close |
| metadata_drift | `audit-open` reports 33 quick tasks as incomplete/unknown (SUMMARY.md lack `status: complete` frontmatter). All recorded in the Quick Tasks Completed table. Same cosmetic pattern as v1.5 (17) / v1.6 (38) | cosmetic, no functional gap | v1.7 close |
| voice_backlog | 260526-k92/l0o/n7b/pg6 voice-tab/active-learning follow-ups — genuinely incomplete; carried as the v1.3 VOICE-POLISH-V2 backlog | defer to VOICE-POLISH-V2 | v1.7 close |
| advisory | Pre-existing no-rehash-on-edit policy (ADR-021): editing an amount re-derives JPY but flows `currentHash` through `copyWith` unchanged. Intentional, not multi-currency-specific | accept (awareness only) | v1.7 close |
| ocr_slot | OCR ledger entry hidden behind reversible `kOcrEntryEnabled` compile-time flag (260614-iww); OCR infrastructure/screens untouched. Flip when MOD-005 writer lands | defer to MOD-005 | v1.7 close |

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

Last session: 2026-07-01T09:50:43.310Z
Stopped at: Completed 56-01-PLAN.md
Resume file: .planning/phases/56-setting/56-CONTEXT.md

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| (v1.8 not yet started) | — | — | — |
| Phase 43 P01 | 6 min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P02 | 6min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P03 | 5min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P04 | 6min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P05 | 4min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P06 | 7min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P07 | 5min | 2 tasks | 4 files |
| Phase 44 P01 | 12min | 1 tasks | 3 files |
| Phase 44 P02 | 12min | 2 tasks | 6 files |
| Phase 44 P03 | 9min | 3 tasks | 8 files |
| Phase 45 P01 | 22min | 3 tasks | 6 files |
| Phase 45 P02 | 14min | 2 tasks | 3 files |
| Phase 45 P06 | 5 min | 1 tasks | 1 files |
| Phase 45 P03 | 3min | 2 tasks | 1 files |
| Phase 45 P04 | 7min | 2 tasks | 1 files |
| Phase 45 P05 | 18min | 1 tasks | 1 files |
| Phase 45 P07 | 11min | 2 tasks | 1 files |
| Phase 46 P46-01 | 40min | 2 tasks | 20 files |
| Phase 46 P46-03 | 7min | 2 tasks | 2 files |
| Phase 46 P46-06 | ~50min | 3 tasks | 14 files |
| Phase 46 P46-02 | ~5min | 2 tasks | 8 files |
| Phase 46 P46-04 | ~18min | 2 tasks | 8 files |
| Phase 46 P46-05 | ~30min | 2 tasks | 10 files |
| Phase 46 P46-07 | ~35min | 3 tasks | 10 files |
| Phase 47 P01 | 10min | 3 tasks | 9 files |
| Phase 47 P02 | 4min | 1 tasks | 1 files |
| Phase 47 P03 | 6min | 1 tasks | 7 files |
| Phase 47 P04 | 8min | 1 tasks | 1 files |
| Phase 47 P05 | 11min | 3 tasks | 56 files |
| Phase 47 P06 | 25min | 2 tasks | 4 files |
| Phase 48 P01 | 4min | 3 tasks | 3 files |
| Phase 48 P02 | ~6min | 2 tasks | 3 files |
| Phase 49 P01 | 6m | 3 tasks | 6 files |
| Phase 49 P02 | 3min | 2 tasks | 2 files |
| Phase 49 P03 | 12 | 3 tasks | 14 files |
| Phase 49 P04 | 3 | 3 tasks | 9 files |
| Phase 49 P05 | ~3 min | 3 tasks | 6 files |
| Phase 50 P01 | 5m | 2 tasks | 7 files |
| Phase 50 P04 | 2 | 2 tasks | 2 files |
| Phase 50 P02 | ~25min | 4 tasks | 7 files |
| Phase 50 P03 | ~1h | 2 tasks | 4 files |
| Phase 50 P05 | 18 | 3 tasks | 26 files |
| Phase 51 P01 | 25 | 2 tasks | 19 files |
| Phase 51 P02 | 6 | 3 tasks | 6 files |
| Phase 51 P03 | ~20min | 2 tasks | 2 files |
| Phase 51 P04 | ~12min | 3 tasks | 11 files |
| Phase 52 P01 | 2min | 3 tasks | 5 files |
| Phase 52 P02 | 7min | 3 tasks | 13 files |
| Phase 52 P04 | 12 | 2 tasks | 6 files |
| Phase 52 P05 | 4 min | 3 tasks | 4 files |
| Phase 52 P03 | 25min | 2 tasks | 3 files |
| Phase 52 P06 | ~10min | 3 tasks | 1 files |
| Phase 53 P01 | ~6m | 2 tasks | 1 files |
| Phase 53 P02 | 5m | 2 tasks | 1 files |
| Phase 53 P04 | 5 min | 2 tasks | 2 files |
| Phase 54 P01 | 12min | 2 tasks | 6 files |
| Phase 54 P02 | 8min | 2 tasks | 7 files |
| Phase 54 P03 | 35min | 1 tasks | 2 files |
| Phase 54 P04 | 11min | 2 tasks | 5 files |
| Phase 54 P05 | 25min | 3 tasks | 3 files |
| Phase 54 P06 | 20min | 2 tasks | 4 files |
| Phase 54 P07 | 28 | 2 tasks | 7 files |
| Phase 55 P01 | 8min | 3 tasks | 3 files |
| Phase 55 P02 | 3min | 2 tasks | 2 files |
| Phase 55 P03 | 12min | 3 tasks | 7 files |
| Phase 55 P04 | 6min | 2 tasks | 7 files |
| Phase 55 P05 | 2min | 2 tasks | 2 files |
| Phase 55 P06 | 6 min | 2 tasks | 2 files |
| Phase 55-pin-phase P07 | 9 | 3 tasks | 3 files |
| Phase 55 P08 | 25m | 2 tasks | 6 files |
| Phase 55 P09 | 8min | 2 tasks | 3 files |
| Phase 55 P11 | 30min | 3 tasks | 2 files |
| Phase 56 P02 | 8m | 3 tasks | 9 files |
| Phase 56 P01 | 1 min | 3 tasks | 4 files |

## Decisions

- [v1.8 roadmap]: Phase numbering continues from Phase 42 → v1.8 = Phases 43-47 (no reset).
- [v1.8 roadmap]: Phase 43 is a standalone hard DESIGN GATE with NO production code (user "未获批前不进入开发"); build phases 44-47 follow only after the gate closes on user approval.
- [v1.8 roadmap]: Build half kept at 4 sequentially-dependent phases (data → shell → cards → validation) rather than consolidated, because the full-screen rebuild under tight ADR-012/ADR-016 invariants benefits from a clean shell-before-cards contract and a dedicated macOS-golden/full-suite gate.
- [v1.8 roadmap]: Overview reframed expense-side only (no income path exists; savings-rate would be meaningless); real savings-rate → INCOME-V2-01.
- [v1.8 roadmap]: No Drift migration, no fl_chart bump, budget-vs-actual excluded — keeps v1.8 a pure presentation-layer rebuild.
- [Phase ?]: [43-01]: Design-gate Wave-0 — GATE-01 deep-map + shared sample-data + mock README authored; zero production code (only .md under .planning/)
- [Phase ?]: 43-02: M1 practical-led mock uses lr5b sakura joy hex (light #D98CA0 / dark #E89BB0) per plan Task 1, overriding ADR-019 base-table amber #E0A040
- [Phase ?]: 43-03: M2 균衡 mock weights 实用 (总览/donut/趋势) and 悦己 (值得卡/满足度直方图/故事条) equally at mid joy 浓度; dark joy = sakura #E89BB0 (consistent with M1); histogram is distribution-only, story strip single-narrative; ADR-012 self-audit PASS
- [Phase ?]: 43-04: M3 极简实用派 mock is the LOWEST joy 浓度 — clean practical skeleton + a single quiet 值得 card; D-03 LOW JOY-01 intensity rendered as visual weight only (small type/muted sakura/whitespace), semantics unchanged (absolute Σ, no ring); histogram/story/trend/family deliberately omitted; dark joy #E89BB0; ADR-012 self-audit PASS
- [Phase ?]: 43-05: M4 温暖反思派 mock inverts the joy-led IA — emotional core (值得卡 + kakeibo Q4 反思 prompt + 满足度直方图) leads, practical 支出总览 recedes to a compact secondary strip; D-03 MID JOY-01 intensity = visual weight only (38px/confident sakura/soft glow), absolute Σ semantics unchanged (no ring); PRIMARY showcase of the kakeibo Q4 STATIC read-only reflection prompt (one values-affirming question, accepts NO input → no JOY-04 persistence, D-06); 满足度 = distribution+descriptive (no 超过上月/目标 8+); dark joy #E89BB0; ADR-012 self-audit PASS
- [Phase 43]: 43-07: GATE-03 selected = round-5 B (M2-derived, NOT an original M1–M5 as-is) — user iterated from M2 base through rounds 2–5 and gave explicit approval (通过). D-11 reasoning: joy expressed descriptively (悦己花在哪 stacked bar + 满足度 distribution + 小确幸 calendar texture, celebrate-past, never goal-driven) / trend-on-top + sorted level-1 categories (practical) / joy side fully ambient (ADR-012-safe). GATE-04: (1) JOY-04 persistence ADR = NO-GO (D-06, static read-only → no persisted text → no encryption/ADR; v1.8 stays no-Drift); (2) NEW — expense-side 本月vs上月 trend (总支出/日常 tabs) is a documented user-approved ADR-012 §4 carve-out (matches home 支出趋势, neutral labels) → requires an ADR-012 `## Update` amendment BEFORE Phase 45 (do not edit ADR-012 in this phase); joy-side cross-period prohibition stays ABSOLUTE. Emotion wordlist locked with calm-warm additions, target/目标 scoped analytics-only (HomeHero monthly_joy_target ambient ring stays legal per ADR-016 §3). fl_chart 1.2.0 per-chart table: donut/histogram/trend lines ✅ native (histogram removes Stack hack); 悦己 horizontal stacked bar ⚠ + 小确幸 calendar heatmap ❌ flagged Phase 46 risk (custom Row-flex / GridView, no fl_chart); Sankey excluded. Gate-exit no-Dart condition EMPTY (zero .dart/pubspec/lib/test). Phase 43 design gate CLOSED.
- [Phase ?]: 43-06: M5 故事画报派 mock is the HIGHEST joy 浓度 (浓墨) — elevates best_joy_story_strip into a full editorial cover-story hero (pure-CSS warm imagery, NO external image), with a 悦己手记 narrative-recap digest and a high-intensity 值得 number; D-03 HIGH JOY-01 intensity = visual weight only (56px sakura→deep-rose gradient text, most prominent), absolute Σ semantics unchanged (no ring); story is narrative recap of EXISTING best-joy moment + already-spent joy categories, intro 「不排名次、不评高下」 — NEVER a 最棒分类 ranking / top-joy leaderboard (ADR-012 #6); practical 支出总览 compressed to minimal footer (expense-side only); kakeibo Q4 not shown (M4 owns it); dark joy #E89BB0; CSS badge→thumb to keep grep gate clean; heaviest-scrutiny ADR-012 self-audit PASS (Pitfall-1 seven signals all 否, zero ❌). All 5 mocks (M1–M5) now shipped.
- [Phase ?]: [44-01]: L1CategoryRollup is a plain immutable class (const ctor + value equality), NOT Freezed — keeps the shared L1-rollup helper genuinely domain-pure (no build_runner / .freezed.dart / Flutter import)
- [Phase ?]: [44-01]: the LOCKED helper category_l1_rollup.dart lives in the feature domain/ root governed by a DENY-ONLY import_guard.yaml (no allow block, per domain_import_rules_test.dart); domain→domain imports pass (no deny match, verified via custom_lint). Both rollup entrypoints route through ONE l1AncestorOf rule so donut==drill (D-11)
- [Phase 44]: [44-02]: TREND-01 implemented as extend-in-place (D-07/D-08) — MonthlyTrend +dailyTotal/+joyTotal and GetExpenseTrendUseCase's existing 6-month loop adds one per-month getLedgerTotals call (same window as getMonthlyTotals), NOT a new query/family/DAO. So ONE trend provider family can drive all three tabs (总支出/日常/悦己).
- [Phase 44]: [44-02]: in-loop getLedgerTotals chosen over a new getMonthlyLedgerTotals repo method (planner discretion per D-08/RESEARCH Flag C — both migration-free; in-loop adds zero repo surface). Zero-default daily/joy extraction copied from get_monthly_report_use_case.dart (Pitfall 1 — getLedgerTotals omits zero-spend ledger rows). No joy cross-period delta (D-09); schema stays v21 (D-13).
- [Phase ?]: 44-03: Category drill-down subtotal/count sourced from Plan 01 l1RollupFromTransactions (D-11 single source — drill header cannot drift from donut slice)
- [Phase ?]: 44-03: drill path reuses findByBookIds + Dart-side l1AncestorOf filter — zero new DAO/index/migration, schema stays v21 (D-04/D-05/D-06/D-13)
- [Phase 45]: 45-01: AnalyticsCardContext stub lives in analytics_card_registry.dart (Plan 03 fills the AnalyticsCardSpec registry list around it; no per-card duplication of the context class)
- [Phase 45]: 45-01: single-source <card>RefreshTargets(ctx) returns List<ProviderBase<Object?>> (ProviderBase from flutter_riverpod/misc.dart); multi-error-branch cards (KpiHero, SatisfactionHistogram) keep typed ref.watch byte-faithful and retry via targets[n] from the locally-built _ctx() list (D-B2 without losing static typing)
- [Phase ?]: 45-02: familyInsightRefreshTargets drops the direct shadow-books invalidate (D-B3 Option A); familyHappinessProvider re-reads it transitively, keeping the registry union home-free
- [Phase ?]: 45-02: FamilyInsightDataCard shadowBooksAsync prop widened to AsyncValue<List<Object>?> so the cards/ layer imports zero home-feature providers (ShadowBookInfo lives only in state_shadow_books); display behavior byte-identical (T-45-03 mitigation)
- [Phase ?]: Phase 45-06: D-D1 discharged — ADR-012 gains an append-only ## Update recording the expense-side 本月vs上月 §4 carve-out (GATE-04 + STATE.md §4); joy-side cross-period stays ABSOLUTELY forbidden; decision body / §🚫 list / 状态 header byte-unchanged (arch.md append-only)
- [Phase 45]: 45-03: analyticsCardRegistry is a spec-list (List<AnalyticsCardSpec>) — single source for render order (declaration==render, D-B1) AND _refresh union; cards stay dumb ConsumerWidgets
- [Phase 45]: 45-03: dailyVsJoyRefreshTargets is group-aware (family snapshot only behind if(ctx.isGroupMode)) though the spec is always-visible — preserves today's _refresh:314 group-mode invalidation (D-A1); distinct from the family PerCategory provider
- [Phase 45]: 45-03: FamilyInsightDataCard shadowBooks is a Plan-04 shell-injected display prop (null placeholder in registry build) — registry imports zero home/* providers (D-B3 file-wide gate)
- [Phase ?]: [45-04]: analytics_screen rewritten to a 176-LOC thin shell — build maps analyticsCardRegistry.where(isVisible) into a byte-faithful Column, _refresh derives the union from registry.expand(refreshTargets).toSet()+shellRefreshTargets (no hand-listed providers, no home/* invalidate); FamilyInsightDataCard shadowBooks injected via 'built is FamilyInsightDataCard' (reorder-safe); 7 inline _*Card classes deleted; ctor preserved
- [Phase ?]: Phase 45 A1/D-B3 Option A confirmed TRUE: dropping the direct shadowBooksProvider invalidate preserves group-mode family refresh via transitive familyHappinessProvider re-read (45-07)
- [Phase ?]: [46-01]: within-month per-day-cumulative trend = pure Dart transform over findByBookIds (2-month window); no new DAO/migration, schema v21. Joy modelled current-month-only via a model with NO previousMonthJoy field (joy cross-period unrepresentable — D-E1).
- [Phase ?]: [46-01] DEVIATION: 6-month TotalSixMonth registry spec + Time section header removed in 46-01 (not deferred to 46-07) because total_six_month_card/monthly_spend_trend_bar_chart hard-import deleted data symbols — data-only deletion cannot compile, must_have needs zero dangling refs (Pitfall 4). Registry now 9 specs; round-5 B card + re-order remain for 46-07.
- [Phase 46]: [46-03] JOY-03/JOY-04 marked Descoped (superseded by GATE-03 round-5 B) in REQUIREMENTS.md; ROADMAP.md gained a Phase 46 SC section listing the round-5 B 5-card lineup (D-A1/D-A2). Requirement IDs satisfied by ledger correction, not by code.
- [Phase 46]: [46-03] DEVIATION: ROADMAP.md had no existing Phase 46 Success-Criteria block (plan's :240-254/:249 line refs stale — file is 200 lines). Added a full Phase 46 section mirroring Phase 43/47 to carry SC #3 round-5 B lineup (Rule 3, faithful-to-intent).
- [Phase 46]: [46-06] Histogram REDES-02: the score-5 "5" annotation moved onto fl_chart 1.2.0 native BarChartRodLabel(show:true, text:l10n…, offset Offset(0,-4)); the Stack/Align/DecoratedBox overlay deleted. The widget ValueKey could NOT survive (canvas-painted label has no widget key) — test now asserts rod label text + only score-5 rod label.show==true (Rule 1).
- [Phase 46]: [46-06] Read-only drill = ListTransactionTile + new readOnly flag (reuse over a new tile variant); readOnly:true renders the shared _buildRow directly (no Dismissible, no tap, no chevron). List tab byte-identical (readOnly defaults false). Drill list kept time-desc (provider order, D-B2 discretion), showDate:true.
- [Phase 46]: [46-06] Donut legend categoryMap = new auto-dispose analyticsCategoriesMapProvider over categoryRepository.findAll() (no new DAO); empty-map fallback while loading. Legend = 10 L1 rows via rollupCategoryBreakdownsToL1 (D-11); ROW tap → Navigator.push CategoryDrillDownScreen (D-B1, not slice); center total TweenAnimationBuilder<int> count-up ~480ms (D-D2). cornerRadius:4.
- [Phase 46]: [46-06] DEVIATION (Rule 1): analytics_screen_test asserted the deleted CategorySpendDonutChart child; updated to find.byType(CategoryDonutCard) since the rebuilt card no longer renders the old chart widget. Full suite 2928/2928 green; analyze 0.
- [Phase 46]: [46-02] Two JOY-side data paths built as pure Dart transforms over findByBookIds(ledgerType: joy) — zero new DAO, zero migration, schema stays v21. JoyCategoryAmount (per-L1 joy AMOUNT, D-C2) rolls up through the SAME l1AncestorOf/l1RollupFromTransactions the donut uses (D-11 single source → joy segments are a strict subset of donut L1). PerDayJoyCount (per-day joy COUNT, D-C1) = Dart group-by-local-day count (笔数, not sum — Pitfall 3), chosen over a SQL ledger+COUNT DAO variant (no DAO surface, does not cross DRILL-01 scope lock — RESEARCH Flag 2). Both models are domain-pure plain immutable value classes (not Freezed).
- [Phase 46]: [46-02] joyCategoryAmounts (DateBoundaries window-normalized key) + perDayJoyCounts (month-anchored key) wired as @riverpod auto-dispose families alongside 46-01's trend provider (added-to, not clobbered); zero home/* (GUARD-01). 11/11 plan unit tests green; analyze 0; registry + home-isolation structural locks stay green.
- [Phase 46]: [46-02] DEVIATION (Rule 3): reworded doc-comment references to the bare token `getDailyTotals` (kept the rationale) so the plan's literal Pitfall-3 grep guard returns zero matches; the use case never called it.
- [Phase 46]: [46-04] First `LineChart` in `lib/`: `WithinMonthCumulativeLineChart` mirrors the donut fl_chart wiring (SizedBox(height:) + hidden grid/axes/touch). 本月 solid `isStrokeCapRound` + optional 上月 `dashArray [4,4]`; series color passed in by the card (`seriesColor`) so the chart stays palette-agnostic/tab-driven; 上月 ref = `Color.lerp(seriesColor, palette.card, 0.55)`.
- [Phase 46]: [46-04] D-E1 cross-period guard is STRUCTURAL not runtime: the 悦己 pill tab passes `previousMonth=null` and the model has no `previousMonthJoy` field, so a joy 上月 line is unrepresentable (Pitfall 2). Spend tabs (总支出/日常) pass the previous-month list → dual line + spend-only 本月/上月 legend gated behind non-empty previous.
- [Phase 46]: [46-04] Pill tabs are local `_TrendBody` StatefulWidget state (no StateProvider) — tab switch changes only the rendered series, never re-watches the trendAnchor-keyed provider (D-12 rebuild-storm guard). `withinMonthTrendRefreshTargets(ctx)` exported (categoryDonut shape) but card NOT registered — 46-07 owns the registry.
- [Phase 46]: [46-04] Added 4 new l10n keys across en/ja/zh (analyticsCardTitle/CaptionWithinMonthTrend + analyticsTrendSeriesThisMonth/LastMonth); tab labels reuse existing analyticsKpiTotalLabel/daily/joy. Phase 47 ARB-parity/anti-toxicity note: `analyticsTrendSeriesLastMonth` is the spend-side-only ADR-012 §4 exception, never reachable from the joy tab.
- [Phase 46]: [46-05] Both round-5 B joy cards #3/#4 built as CUSTOM non-fl_chart widgets (GATE-04 verified: zero fl_chart import in all 4 new files). 悦己花在哪 = `Row` of `Flexible(flex: amount)` segments (R-1) + single-column legend + local tap-highlight (D-C2 no drill) + 悦己 header `TweenAnimationBuilder` count-up (D-D2 anchor #2). 小确幸日历 = 7-col `GridView` (R-2), cell depth = continuous `Color.lerp(joyLight, joy, count/maxCount)` ambient (ADR-016 §5, explicitly NOT a streak), tap-day → INLINE `AnimatedSize` expand (D-C1, no sheet/route). Cards NOT registered (46-07 owns registry); refreshTargets exported in donut shape.
- [Phase 46]: [46-05] Calendar inline-expand data path = NEW `joyDayTransactionsProvider` (day-scoped `findByBookIds(ledgerType: joy)` over the tapped day's whole-day window, D-12 normalized, auto-dispose, zero home/*) — chosen over widening the count model so `perDayJoyCounts` stays count-only (D-C1); passes only active book + tapped day to findByBookIds (T-46-05-01). Inline list reuses `ListTransactionTile(readOnly: true)` (D-B3, no new variant). Joy-spend segment hues lerp WITHIN the joy family (joy→joyLight), not the donut's daily-green→joy cross-ledger ramp.
- [Phase 46]: [46-05] Added 7 new l10n keys across en/ja/zh (analyticsCardTitle/CaptionJoySpend, analyticsJoySpendHeaderLabel, analyticsJoySpendEmpty, analyticsCardTitle/CaptionJoyCalendar, analyticsJoyCalendarDayEmpty) — anti-toxicity clean (celebrate-past descriptive). Phase 47 should fold them into the anti_toxicity sweep. Full suite 2963/2963 green; analyze 0.
- [Phase 46]: [46-07] analyticsCardRegistry IS the round-5 B flat 5-card lineup (within_month_trend → category_donut → joy_spend → joy_calendar → satisfaction_histogram) + family_insight group-only conditional (D-F1/D-F2). The sectionHeaderKey field + the shell's section-header interleave + _sectionLabel were removed (flat Column of cards). Group mode now adds EXACTLY FamilyHappinessProvider to the _refresh union (only group-only spec).
- [Phase 46]: [46-07] Deleted best_joy_card/kpi_hero_card/largest_expense_card/analytics_screen_section_header (D-A3; total_six_month_card + monthly_spend_trend_bar_chart already gone in 46-01). De-registered daily_vs_joy_card + per_category_breakdown_card (widget FILES retained, keep own tests; their refreshTargets fns removed from the registry). bestJoyMomentProvider/largestMonthlyExpenseProvider providers RETAINED — bestJoyMomentProvider is a HomeHero consumer, not dead-card-unique.
- [Phase 46]: [46-07] Section-header ARB keys (analyticsGroupHeaderTime/Distribution/Stories) now orphaned (zero source consumers) — DEFERRED to Phase 47 ARB sweep (removal needs gen-l10n + force-add of gitignored generated files). JOY-01/JOY-02/REDES-03/GUARD-02 flipped to Complete now the round-5 B lineup is user-visible. Full suite 2971/2971 green; analyze 0.
- [Phase 46]: [46-07] The STATE.md 46-01 sequencing blocker was ALREADY RESOLVED by 46-01 (it deleted the trend presentation consumers alongside the data layer); 46-07 verified absence + completed the integration. Marked resolved.
- [Phase ?]: [Phase 47]: [47-02]: GetJoyCategoryAmountsUseCase refactored to a single-pass <String,int> accumulate keyed by l1AncestorOf (replaces the O(n·k) distinct-L1-set + per-L1 l1RollupFromTransactions loop); false 'There is NO second rollup loop here' docstring removed; D-11 single source intact; per-L1 amounts byte-identical (existing 6 unit tests green, unchanged); no findByBookIds widening; analyze 0 (WR-03/D-04, GUARD-04)
- [Phase 47]: [47-03]: Deleted 3 orphan section-header ARB keys (analyticsGroupHeaderTime/Distribution/Stories) symmetrically across en/ja/zh + regenerated lib/generated/ via gen-l10n + git add -f (Phase-46 gitignored-yet-tracked gotcha); analyticsCategoryDonutOther retained for 47-01 WR-02; parity green, analyze 0 (GUARD-03/D-15)
- [Phase 47]: [47-04]: Authored anti_toxicity_phase47_test.dart (D-14) — 36-case sweep over the 5 round-5 B cards × en/ja/zh × {value/empty/other/inline-expand/self-hide}; forbidden en/ja/zh lists copied VERBATIM from anti_toxicity_phase16 (D-13, never relaxed); WR-02 >10-L1 donut Other state exercised so analyticsCategoryDonutOther sweeps clean (D-03); per-state overrides LOCAL+complete + added _expectRenderedText/donut_legend_row_other/inline_panel coverage guards so a failed override can't trivialize the sweep (Pitfall 1); 36/36 green, analyze 0 (GUARD-02/GUARD-03). NOTE: gsd-tools CLI unavailable in this exec env — STATE.md/ROADMAP.md updated by hand.
- [Phase ?]: [47-05] Authored 8 golden tests + 48 macOS PNG baselines for round-5 B analytics (GUARD-04 closed); all wrap PRODUCTION AppTheme so context.palette resolves real ADR-019 — bare ThemeData validates layout but NOT palette. Scoped --update-goldens to the 8 new files (clean diff attribution). Off-macOS reduces to baseline-existence via flutter_test_config.
- [Phase ?]: [Phase 47]: 47-06: full flutter test gate 3057/3057 + analyze 0 + cleaned coverage 80.48% (GUARD-04); on-device D-10 visual UAT all 10 items PASS on physical iOS locale=ja, user-approved 2026-06-20 (GUARD-05, D-12 no defer path). Plan 6/6 — Phase 47 ready_for_verification.
- [Phase 48]: [48-01] TD-1 fixed (D-01): nullable AnalyticsCardContext.memberFilterDeviceId threaded from donutDimensionStateProvider (analytics state_*, GUARD-01 intact); categoryDonutRefreshTargets appends memberFilteredCategoryBreakdownProvider via collection-if ONLY when a member filter is active (unfiltered 4-target union byte-stable). Member-filtered pull-to-refresh now invalidates the displayed filtered breakdown (no stale cached data). CategoryDonutCard._ctx() threads the live donutView filter.
- [Phase 48]: [48-01] D-02: 'MemberFilteredCategoryBreakdownProvider' whitelisted in _analyticsProviderTypeWhitelist (verbatim generated type) so union ⊆ analytics isolation still passes. D-03: added (f) completeness guard (union ⊇ active card-watch — the direction the suite never checked, which let TD-1 in) + negative control (no filter → filtered family absent, unfiltered union byte-stable) + mutual-consistency whitelist loop. Registry test 9/9 green, analyze 0, 0 golden re-baseline (refresh-wiring only).
- [Phase 48]: [48-01] DEVIATION (Rule 1): reworded categoryDonutRefreshTargets dartdoc to drop the literal `home/*` substring — the Task-1 comment tripped the pre-existing REDES-01 `source.contains('home/')` per-card guard (folded into bf0122a2). NOTE: gsd-tools CLI unavailable in this exec env — STATE.md/ROADMAP.md updated by hand (consistent with the Phase 47 47-04 note).
- [Phase 48]: [48-02] TD-2 fixed (D-04): scrubbed the removed `getExpenseTrendUseCase` / `MonthlyTrend` symbol names from the `getWithinMonthCumulativeUseCase` dartdoc (source + 3 build_runner-regenerated `.g.dart` mirrors at ~168/180/196) and from the one characterization test description (now 'within-month cumulative trend path, D-E1'). Kept the accurate `findByBookIds`/NOT-analyticsRepository rationale. `grep -rn "getExpenseTrend\|MonthlyTrend" lib/ test/` = 0; scoped analyze 0; char test 3/3; 0 golden re-baseline; .g.dart diff = ONLY the 3 dartdoc mirror blocks (no codegen drift), committed normally (not gitignored). gsd-tools CLI still unavailable — STATE.md/ROADMAP.md updated by hand.
- [Phase ?]: Phase 49-01: merchant_match_keys.match_key index is NON-UNIQUE (cross-merchant collisions legal, RESEARCH #6); region default companion-layer JP; ledger_hint kept as stored non-authoritative hint (D-09); schema v21->v22 with explicit CREATE INDEX in onCreate AND from<22
- [Phase ?]: Phase 49-02: normalizeMerchantKey is one shared hand-written kana normalizer (zero deps) reused unchanged for seed-time + Phase-50 query-time; all folds land in hiragana namespace; orphan combining marks dropped; ASCII hyphen kept, only 中黒/whitespace stripped
- [Phase ?]: Phase 49-03: DefaultMerchants seed (391 merchants) in 10 per-group files; ledger derived via deriveLedgerHint from DefaultCategories single source of truth; Amazon/ヤマダ電機/ユニクロ derive joy->daily (derived wins, D-08)
- [Phase ?]: 49-04: MerchantDao is a plain class (not @DriftAccessor); insertSeed batches both tables in one transaction via companions, no raw SQL
- [Phase ?]: 49-04: MerchantMatchKey row PK derived as merchantId__matchKey so re-seed is idempotent under INSERT OR IGNORE
- [Phase ?]: Phase 49-05: merchant seed wired as third leaf in SeedAllUseCase (after categories), seedRunner no-op untouched; ledgerHint via deriveLedgerHint(categoryId).name
- [Phase 49]: 49-06: encrypted migration ladder reuses createEncryptedExecutor unchanged via a fixed-key MasterKeyRepository test double (no second key path — V6); SQL-layer test isolation (executor documents-dir path not exposed for file unlink)
- [Phase 49]: 49-06: SQLCipher-path coverage split — integration test proves fresh-v22 + v21→v22 (real v1.8-user upgrade); deep-history v3→v22/v17→v22 DDL assertions stay on host-VM ladder merchant_v22_migration_test.dart
- [Phase ?]: Phase 50-04: CategoryRecognizer = VoiceCategoryResolver minus step-1 + minus vendor-database dep; keyword-only and unconditional (DECOUP-01/02). Purely additive — old resolver/test/provider untouched (deleted in Plan 05/Wave 3) so Wave 1 stays green.
- [Phase ?]: [Phase 50]: 50-02: keyword seed extended to FULL 138-L2 coverage (admin families cat_tax_*/cat_asset_*/cat_insurance_*/*_insurance/*_tax/cat_special_* + 19 *_other buckets INCLUDED per user scope decision + RESEARCH A4); coverage gate widened (no exclusion list); 515 zh+ja direct-seed rows; word refinements うーばー→ウーバー / 老婆零花→伴侣零花钱; split into synonyms/synonyms_*.dart (800-line rule), synonyms/ CJK-scan-excluded by prefix
- [Phase ?]: Phase 50-03: prefix tier needs per-script min-length AND strict >50% rune-coverage guard (SC2).
- [Phase ?]: Phase 50: voice pipeline cut to two decoupled engines (CategoryRecognizer + MerchantRecognizer); keyword-priority merge with 0.85 auto-fill floor; ledger = resolveLedgerType(finalCategory) (LEDGER-01); old MerchantDatabase/VoiceCategoryResolver path retired (D-05).
- [Phase ?]: Phase 51-01: extended domain_import_rules_test.dart models/ subdir check to accept isCrossFeatureDomainModel (mirrors repositories/ escape) so voice/domain is a guarded feature while voice_parse_result imports accounting LedgerType cross-feature
- [Phase ?]: Reconciler emits best-guess at band=weak (D-05); use case gates form auto-fill on band==medium, preserving 0.85-floor/WR-04 (51-02)
- [Phase ?]: RecognitionReconciler is pure/sync: D-06 boost compares L2 id strings directly (merchant ids are L2 seed ids), no DB/normalizeToL2 inside the reconciler (51-02)
- [Phase ?]: 51-03: category fill gated to first end-of-speech final (resolve-on-final hysteresis, XVAL-03); partials still fill amount/text/merchant/date live; no new timer (D-03).
- [Phase 51]: 51-04: CreateTransactionUseCase ledger derives from CategoryService.resolveLedgerType(categoryId) ?? daily (D-14/D-16) — single source = category_ledger_configs, never a merchant ledger hint.
- [Phase 51]: 51-04: lib/application/dual_ledger/ retired (LEDGER-02, D-15) — second divergent hardcoded daily/joy map (RuleEngine, dead ids cat_entertainment/cat_shopping) deleted; ledger_hint_deriver + features/dual_ledger untouched.

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone

### Blockers

- ~~46-01 Task 2 sequencing conflict: plan deletes the 6-month trend DATA layer but reserves PRESENTATION consumers (total_six_month_card.dart, monthly_spend_trend_bar_chart.dart, registry spec + registry_test + 3 screen tests) for wave-3 46-07.~~ **RESOLVED (46-01 + 46-07):** 46-01 resolved it at the time by ALSO deleting total_six_month_card.dart + monthly_spend_trend_bar_chart.dart + the Time section header + their registry specs (registry → 9 specs) so the data-only deletion compiled. 46-07 then verified those two files were already absent (no re-delete) and completed the round-5 B integration: re-ordered the registry to the flat 5-card lineup, deleted the remaining 4 dead files (best_joy_card, kpi_hero_card, largest_expense_card, analytics_screen_section_header), and updated the registry/screen/anti-toxicity tests in lockstep. Zero dangling references; full suite 2971/2971 green. No active blockers.
- **49-06 Task 3 (blocking human-verify):** run `flutter test integration_test/merchant_migration_ladder_test.dart` on a booted simulator/device; confirm `PRAGMA cipher_version` non-empty + fresh-v22/v21→v22 index+seed+categoryId∈L2 assertions + D-08 ~10-row merchant spot-check. Cannot run in headless orchestrator (no simulator).
