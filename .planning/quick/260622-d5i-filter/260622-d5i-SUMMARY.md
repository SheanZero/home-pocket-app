---
status: complete
phase: quick-260622-d5i
plan: "01"
subsystem: analytics
tags: [analytics, joy-drawer, member-filter, dimension, l10n, golden]
requires:
  - donutDimensionStateProvider (DonutDimensionView{dimension, memberFilterDeviceId})
  - getMemberSpendBreakdownUseCaseProvider
  - getJoyCategoryAmountsUseCaseProvider
provides:
  - joyMemberAmountsProvider (悦己 by-member, ledgerType: joy)
  - joyCategoryAmountsProvider deviceId family key
  - borderless dimension-aware member-filtered JoySpendDrawer
affects:
  - lib/features/analytics/presentation/widgets/joy_spend_drawer.dart
  - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
key-files:
  created: []
  modified:
    - lib/application/analytics/get_joy_category_amounts_use_case.dart
    - lib/application/analytics/get_member_spend_breakdown_use_case.dart
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/analytics/presentation/providers/state_analytics.g.dart
    - lib/features/analytics/presentation/widgets/joy_spend_drawer.dart
    - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations*.dart
decisions: [D1, D2, D3]
metrics:
  duration: ~35min
  completed: 2026-06-22
---

# Quick Task 260622-d5i: 统计页「分类支出」卡片 — 悦己去边框/分割线分离 + 随成员维度&筛选联动 Summary

去掉 `JoySpendDrawer` 的樱粉边框，改用 1px `borderDivider` 分割线把悦己部分与整体（donut + 类别图例）分离，保留「♡悦び」chip + 计数 + ¥总额；并让悦己部分随顶部「分类/成员」维度切换 (D3) 和成员筛选 (D2) 联动，过滤逻辑与整体分类明细完全一致 (`tx.deviceId == deviceId`)。

## What Changed (per task)

**Task 1 (0f8ddff4) — use-case optional filters (TDD):**
- `GetJoyCategoryAmountsUseCase.execute` 加可选 `String? deviceId`，扩展 expense-only `where` 为 `&& (deviceId == null || tx.deviceId == deviceId)`。
- `GetMemberSpendBreakdownUseCase.execute` 加可选 `LedgerType? ledgerType`（默认 null），直传 `findByBookIds`（替换硬编码 `ledgerType: null`）。
- 单测：joy 用例 +1 case（deviceId 过滤 + null 不变）；member 用例 +2 case（默认转发 null / `ledgerType: joy` 转发 + daily-only 成员无桶）。RED→GREEN 验证（编译期 RED：参数不存在 → 实现后 15/15 green）。

**Task 2 (968e1e5f) — providers + build_runner:**
- `joyCategoryAmounts` 加可选 `deviceId` 进 family key（null = 旧 key/值，现有 watcher 字节不变）。
- 新增 `joyMemberAmounts` provider，复用 `getMemberSpendBreakdownUseCaseProvider` 传 `ledgerType: LedgerType.joy`，镜像 `memberSpendBreakdown`（同 key 元组 / D-12 dayRange / manualOnly 映射 / auto-dispose / 零 home/*）。
- `build_runner` 重生成 `state_analytics.g.dart`（新 family key + `joyMemberAmountsProvider`，5 处引用）。

**Task 3 (20cdc950) — drawer rewrite + ARB:**
- 新增 ARB key `analyticsJoyDrawerMemberCount`（ja「{count} メンバー」/ zh「{count} 名成员」/ en「{count} members」）对称 ×3 + `flutter gen-l10n`。
- `JoySpendDrawer` 重写：去 `Container` 樱粉边框（D1），改 Column 头部 1px `palette.borderDivider` 分割线；标签行 = ♡悦び chip（`joyLight`/`joyText` + `Icons.favorite_border`，文案走 `analyticsJoySpendHeaderLabel`）— count — ¥total（右对齐）。category 维度 watch `joyCategoryAmountsProvider(deviceId: donutView.memberFilterDeviceId)` 经 `JoySpendDrawerBody` 渲染；member 维度 watch `joyMemberAmountsProvider` 在 widget 内按 `memberFilterDeviceId` 过滤，直接构造 `JoySpendSegment`（label=成员名、`JoyWarmPalette.colorAt(i)`、`Icons.person_outline`）经 `JoySpendStackedBar` 渲染，空态复用 `analyticsJoySpendEmpty`。
- `CategoryDonutCard` 下传 `donutView`/`memberNames`/`memberEmojis`，并把 `joyMemberAmountsProvider`（未筛选 key）折入 `categoryDonutRefreshTargets`。

**Task 4 (fa9b97f1) — widget test + golden + 最终门:**
- `category_donut_card_test.dart`：新增 D1（无边框 box / 分割线 / ♡悦び chip+count+total）+ D3（member 维度经 `JoySpendStackedBar` 渲染 person-icon 成员段 + 「2 members」计数）断言；10/10 green。
- golden `_wrapMember` 加 `joyMemberAmountsProvider` override（半额对比）使 by-member joy bar 真实入基线。
- macOS 重基线 4 个 golden（见下）。

**registry-fix (d163abbc) — Rule 1 out-of-scope-但由本改动引发:**
- `analytics_card_registry_test.dart` whitelist 加 `JoyMemberAmountsProvider`，`categoryDonutRefreshTargets` 期望列表加折入的 joyMemberAmounts target（我的刷新并集改动破坏了 D-B2 单源断言）。

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 标签行 Row 在 dark-en 成员 golden 溢出 20px**
- **Found during:** Task 4（golden 重基线时 `member dimension multi — dark en` 抛 `RenderFlex overflowed by 20 pixels`）。
- **Issue:** `_chrome` 的标签行用 `Spacer()` 时，chip+count+total 自然宽度在窄约束（320px）下仍溢出。
- **Fix:** count 改 `Expanded`（吃剩余空间、左对齐、`overflow: ellipsis`），total 仍钉行尾右对齐。
- **Files modified:** `lib/features/analytics/presentation/widgets/joy_spend_drawer.dart`
- **Commit:** fa9b97f1（与 Task 4 同提交，因属同一 golden-baseline 单元）。

**2. [Rule 1 - Bug] registry 结构测试因刷新并集变化失败**
- **Found during:** Task 4 后跑全量 analytics widget 套件时。
- **Issue:** `categoryDonutRefreshTargets` 新增 `joyMemberAmountsProvider` → 该 provider 不在测试 whitelist 且未在期望列表 → (a)/(e) 断言 fail。
- **Fix:** whitelist + 期望列表各加该 analytics family（合法、零 home/*）。
- **Files modified:** `test/widget/features/analytics/presentation/analytics_card_registry_test.dart`
- **Commit:** d163abbc

## Verification

- **byte-unchanged null-param 路径：** category-dim value/dark/other/empty 6+2 golden 在 4 个提交内**零变化**（`git diff --name-only HEAD~4 HEAD -- test/golden/goldens/` 仅列出 4 个 member/scroll-smoke 文件）→ 证实 `joyCategoryAmounts(deviceId: null)` 分类路径视觉字节不变；单测显式断言 deviceId-null / ledgerType-null 与改前一致。
- **golden 重基线计数：4 个**（macOS / darwin）：
  - `analytics_screen_scroll_smoke_light_ja.png`（drawer 高度变化导致位移）
  - `category_donut_card_member_multi_light_ja.png`
  - `category_donut_card_member_multi_dark_en.png`
  - `category_donut_card_member_solo_light_ja.png`
  （后三者现渲染 by-member 悦己条）
- **`git add -f lib/generated/` 备注：** 本仓当前 `lib/generated/` 实测**未被 gitignore**（`git check-ignore` exit=1，文件以 `M` 正常 staged），常规 `git add` 即可；但仍按约束用 `git add -f lib/generated/` 防御性 staged，规避项目记忆里的「gitignored-yet-tracked」陷阱。
- **Guards：** `Border.all` in joy_spend_drawer.dart == 0；`analyticsJoyDrawerMemberCount` 存在于全 3 ARB；`joyMemberAmountsProvider` ∈ `categoryDonutRefreshTargets`；joy_spend_drawer.dart 无 `features/home` import、无裸 hex（`Color(0x`/`#`）；`color_literal_scan` + `hardcoded_cjk_ui_scan` 架构测试 green。
- **Quality gate：** `flutter analyze` = **0 issues**；受影响 unit/widget/golden + `anti_toxicity_phase47_test.dart` = **74/74 green**；全 analytics widget+golden 套件 **421/421 green**。

## Commits

| # | Hash | Task |
|---|------|------|
| 1 | 0f8ddff4 | use-case optional deviceId/ledgerType (+ TDD unit) |
| 2 | 968e1e5f | thread deviceId + joyMemberAmounts provider + build_runner |
| 3 | 20cdc950 | borderless divider drawer + ARB + gen-l10n |
| 4 | fa9b97f1 | widget structure tests + macOS golden re-baseline (+ Row-overflow fix) |
| 5 | d163abbc | registry test accepts joyMemberAmounts refresh target (Rule 1) |

## Self-Check: PASSED

- Created files: none (all modifications).
- All 5 commits present in `git log` (0f8ddff4, 968e1e5f, 20cdc950, fa9b97f1, d163abbc).
- Key modified files exist and analyze clean; affected test set + architecture guards green.
