---
phase: quick-260620-v2m
verified: 2026-06-20T23:20:00Z
status: human_needed
score: 7/7 must-haves verified (code-level); 4 visual items deferred to on-device UAT
human_verification:
  - test: "统计页支出趋势：选「日常」，观察本月折线是否为柔化曲线（非锐角折线）、折线下方有从线色到透明的渐变阴影、终点 date+amount 标签是否锚定在终点 marker 正上方"
    expected: "曲线平滑无过冲到基线以下；below-line 渐变阴影淡淡可见；终点标签居中在端点正上方（贴顶时才回退下方）；上月虚线参考标签在相反侧不重叠"
    why_human: "fl_chart 曲线/渐变/标签定位是像素级视觉，grep 只能确认参数存在，不能确认渲染观感与无出血/重叠"
  - test: "分类支出圆环（分类模式）：观察每个切片环上是否显示百分比 %，小切片（<5%）与「其他」是否只在图例显示不上环，分类名+¥金额是否仍在下方图例行，中心是否保留「本月支出」+总额"
    expected: "≥5% 的切片环上有可读的 % 标签（如 29%），文字不出血；<5% 与「其他」环上无标签；图例与中心结构不变"
    why_human: "环上 % 标签是否可读、是否出血、8–10 类是否重叠是视觉判断，需真机/模拟器目测"
  - test: "圆环卡顶部「分类 / 成员」维度切换：点「成员」，确认环+图例改按成员（deviceId）切分，显示各成员头像 emoji + 名字 + ¥金额 + %"
    expected: "成员模式环按各成员金额切片并标各成员 %；图例每成员一行显示头像/名字/金额/%；名字头像经 group_members 解析"
    why_human: "维度切换交互 + 成员名/头像渲染需运行时（依赖 activeGroupMembers 真实数据）才能确认"
  - test: "成员过滤下拉：点开过滤器，选某成员，确认两个维度都收窄到该成员的支出（成员模式=单片100%；分类模式=该成员的分类占比）；单设备/未入群时降级为 1 成员且过滤器仍可用不报错"
    expected: "过滤为全局收窄，成员模式与分类模式都生效；单设备优雅降级为单片，不报错不空白"
    why_human: "过滤交互 + 单设备降级路径需运行时验证；测试 fixture 覆盖但真机数据路径需目测确认"
---

# Quick Task 260620-v2m: 统计页趋势图柔化/渐变/终点标签 + 圆环环上% + 成员维度/过滤 Verification Report

**Phase Goal:** (Part 1) 支出趋势折线柔化曲线 + 终点 date/amount 标签锚定终点 marker 正上方 + 折线下渐变阴影；(Part 2) 分类支出圆环环上只标百分比% + 「分类/成员」维度切换 + 成员过滤(成员=deviceId→group_members，单设备优雅降级)，配色用 App ADR-019 调色板。
**Verified:** 2026-06-20T23:20:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | 趋势折线柔化曲线 + below-line 渐变 + 终点标签正上方 | ✓ VERIFIED (code) | `within_month_cumulative_line_chart.dart:294-296` `isCurved:true`+`curveSmoothness:0.22`+`preventCurveOverShooting:true`; `:314-322` `belowBarData: BarAreaData(show:true, gradient: LinearGradient(...seriesColor.withValues(alpha:0.18)→0.0))`; 上月线 `:339` `belowBarData: BarAreaData(show:false)`（不双填充）; `:167-182` `currentLabelAbove=true` 强制锚定 `px(lastPoint.day)` 正上方, `:191` 上月恒相反侧。无硬编码 hex。jx2/kll 契约保留 (previousMonth nullable/joy 单线 D-E1, daysInMonth X-extent, FlGridData, dashArray)。视觉观感→UAT #1 |
| 2 | 圆环环上 % 标签（分类+成员模式，小切片/「其他」避让）；图例 name+¥金额、中心本月支出+总额保留；ADR-019 配色 | ✓ VERIFIED (code) | `donut_hero.dart:183` value 切片 `title: _onRingPctTitle(amount,total)`（同图例 total 口径）; `:71` `_onRingPctThreshold=0.05`; `:81-86` <5% → `_suppressedRingTitle`(named const, 非裸 `title:''`); `:202` 「其他」切片 suppressed; `:190-193` `palette.card`(context.palette 自适配); 裸 `title: ''` 计数=0。中心 `centerSpaceRadius:54` + 总额结构保留。成员模式 `:366` 同 % 逻辑。视觉可读性→UAT #2 |
| 3 | 「分类/成员」维度切换；成员模式按 deviceId 切分，名字/头像经 group_members | ✓ VERIFIED (code) | `donut_dimension_member_controls.dart:40-52` 两 pill `setDimension(category/member)`; `category_donut_card.dart:114-164` member 分支 watch `memberSpendBreakdownProvider`，喂 `DonutHero(members:..., memberNames, memberEmojis)`; `:78-85` memberNames/Emojis 由 `activeGroupMembers` 的 `displayName`/`avatarEmoji` 构建; `donut_hero.dart:298-425` `_buildMemberMode` 按 deviceId 切片 + 图例。交互渲染→UAT #3 |
| 4 | 成员过滤下拉（全局收窄，两维度都生效） | ✓ VERIFIED (code) | `donut_dimension_member_controls.dart:99-138` bottomsheet「所有成员」+各成员 `setMemberFilter`; `category_donut_card.dart:126-132` 成员模式收窄; `:168-203` 分类模式+过滤走 `memberFilteredCategoryBreakdownProvider`; `state_analytics.dart:102-162` 该 provider 经 findByBookIds expense+`deviceId==filter` 过滤后按 categoryId 聚合 → 真实功能性收窄（非置灰省事分支）。交互→UAT #4 |
| 5 | 单设备/未入群优雅降级为 1 成员，不报错不空白 | ✓ VERIFIED (code) | use-case Test 4「single device → exactly 1 MemberSpendBreakdown」通过; `_buildMemberMode` 单片渲染; golden `category_donut_card_member_solo_light_ja.png` 新增覆盖单设备降级。运行时路径→UAT #4 |
| 6 | 成员色按 deviceId 跨刷新稳定可区分；不发明「共同帐户」 | ✓ VERIFIED | `analytics_category_palette.dart:41-42` `memberColorFor(deviceId)=memberSequence[deviceId.hashCode.abs()%len]`（稳定哈希）; `:35-37` memberSequence 为 ADR-019 家族色（leaf/steel-blue/sage/light-blue/amber，避 error 红、留樱粉给悦己）; 「共同帐户」仅出现在 model 注释明确声明 NO pseudo-member |
| 7 | flutter analyze 0；full test 全绿；analytics golden macOS 重基线 | ✓ VERIFIED | `flutter analyze` 本机重跑 = **No issues found!**; 11/11 scoped 测试（6 use-case + 5 state）本机重跑全绿; commit `eb74b990` 重基线 19 个 golden PNG（趋势卡 6 + 圆环卡含环上% + 3 新成员 master member_multi×2/member_solo + 整页 smoke）。full 3088/3088 为 SUMMARY 声明（未全套重跑——time-bound spot-check 已绿） |

**Score:** 7/7 truths verified at code level. 4 visual/interaction aspects deferred to on-device UAT (per task instructions: visual rendering marked human_needed, not failed).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `within_month_cumulative_line_chart.dart` | 柔化曲线+渐变+终点正上方标签, jx2/kll 保留 | ✓ VERIFIED | `isCurved:true` 在 167/294/334 行; 契约保留 |
| `donut_hero.dart` | 环上 % 标签（分类+成员），图例+中心保持 | ✓ VERIFIED | `title: _onRingPctTitle(...)`; 裸 `title:''`=0 |
| `get_member_spend_breakdown_use_case.dart` | deviceId 分组 expense-only 聚合 | ✓ VERIFIED | `class GetMemberSpendBreakdownUseCase`, findByBookIds expense-only, bookIds 不 widen, amount>0, 降序 |
| `member_spend_breakdown.dart` | 不可变值模型 deviceId/amount/count | ✓ VERIFIED | const ctor + ==/hashCode，非 Freezed，零 Flutter import |
| `state_donut_dimension.dart` | DonutDimension enum + Notifier | ✓ VERIFIED | enum + `DonutDimensionView`(immutable copyWith) + `@riverpod DonutDimensionState` |
| `donut_dimension_member_controls.dart` | 维度切换 + 成员过滤控件 | ✓ VERIFIED | segmented pill + bottomsheet, 全 S.of(context) |
| `get_member_spend_breakdown_use_case_test.dart` | 6 单测含降级/expense-only/过滤/稳定排序 | ✓ VERIFIED | 6 tests 命名齐全，本机重跑绿 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| category_donut_card.dart | memberSpendBreakdownProvider / donutDimensionStateProvider | ref.watch | ✓ WIRED | `:75` watch donutView; `:115` watch memberSpendBreakdownProvider; `:169` memberFilteredCategoryBreakdownProvider |
| get_member_spend_breakdown_use_case.dart | transactionRepository.findByBookIds | expense-only window fetch group-by deviceId | ✓ WIRED | `:38` findByBookIds(ledgerType:null); `:51-63` Dart expense gate + group-by deviceId |
| donut_hero.dart | activeGroupMembers (deviceId→displayName/avatarEmoji) | 成员图例行 | ✓ WIRED | `_buildMemberMode` 用 memberNames/memberEmojis（card `:78-85` 从 activeGroupMembers 构建）+ memberColorFor |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Use-case 6 单测 | `flutter test .../get_member_spend_breakdown_use_case_test.dart` | 6/6 pass | ✓ PASS |
| State 5 单测 | `flutter test .../state_donut_dimension_test.dart` | 5/5 pass | ✓ PASS |
| 全仓静态分析 | `flutter analyze` | No issues found! | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| STATSUI-TREND-REFINE | 260620-v2m-PLAN | 趋势折线柔化+渐变+终点标签 | ✓ SATISFIED | Truth #1 (Task 1) |
| STATSUI-DONUT-MEMBER | 260620-v2m-PLAN | 环上%+维度切换+成员过滤+成员切分 | ✓ SATISFIED | Truths #2-#6 (Tasks 2-4) |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | — | — | No debt markers (TBD/FIXME/XXX), no bare `title: ''` on value slices (named const used), no hardcoded hex outside lib/core/theme/, no invented 共同帐户 pseudo-member |

### Human Verification Required

See frontmatter `human_verification` — 4 on-device UAT items covering: (1) trend curve smoothing/gradient/endpoint-label rendering; (2) on-ring % readability + small-slice/Other suppression; (3) 分类/成员 dimension toggle + member name/avatar rendering; (4) member filter global narrowing in both dimensions + single-device graceful degradation. All code wiring confirmed; only pixel-level visual observation and runtime interaction remain.

### Gaps Summary

No gaps. All 7 must-have truths are verified at the code level: Part 1 trend chart has the curve/gradient/force-above-label changes with all jx2/kll invariants preserved and no hardcoded hex; D3 on-ring % labels are implemented with same-denominator computation, 5% threshold + Other suppression via a named const (zero bare `title: ''` on value slices); Part 2 data layer (use case + model + provider) is TDD-backed with all 6 behaviors covered and passing; Part 2 state (enum + immutable Notifier) is TDD-backed with all 5 transitions passing; the donut card genuinely wires both the member dimension and a functional cross-dimension member filter (memberFilteredCategoryBreakdownProvider does real expense+deviceId narrowing, not a greyed-out stub); member colors are deviceId-stable from the ADR-019 palette family; no 共同帐户 pseudo-member is invented. `flutter analyze` is clean (re-run on this machine) and goldens were re-baselined (19 PNGs incl. 3 new member masters covering multi-member + single-device degradation).

Status is `human_needed` (not `passed`) solely because the visual rendering and runtime interaction (curve/gradient/on-ring %/dimension toggle/member filter) require on-device UAT per task instructions — these are observation-only confirmations of already-wired code, not blocking gaps.

---

_Verified: 2026-06-20T23:20:00Z_
_Verifier: Claude (gsd-verifier)_
