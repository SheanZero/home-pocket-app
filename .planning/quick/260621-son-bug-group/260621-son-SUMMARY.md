---
phase: quick-260621-son
plan: 01
subsystem: analytics
status: complete
tags: [analytics, donut, member-dimension, i18n, golden, bugfix]
requires:
  - userProfileProvider (profile feature)
  - keyManager.getDeviceId() (family_sync repository_providers)
  - activeGroupMembersProvider (family_sync)
provides:
  - currentDeviceIdProvider (analytics self-deviceId source)
  - self-name resolution in member-dimension donut legend
  - self injection into member-filter option list (no-group case)
  - controls row positioned below donut, above legend
affects:
  - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
  - lib/features/analytics/presentation/widgets/donut_hero.dart
  - lib/features/analytics/presentation/widgets/donut_dimension_member_controls.dart
  - lib/features/analytics/presentation/providers/state_donut_dimension.dart
tech-stack:
  added: []
  patterns: [riverpod-futureprovider, watch-not-snapshot, null-aware-element]
key-files:
  created: []
  modified:
    - lib/features/analytics/presentation/providers/state_donut_dimension.dart
    - lib/features/analytics/presentation/providers/state_donut_dimension.g.dart
    - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
    - lib/features/analytics/presentation/widgets/donut_dimension_member_controls.dart
    - lib/features/analytics/presentation/widgets/donut_hero.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations*.dart
    - test/features/analytics/presentation/providers/state_donut_dimension_test.dart
    - test/widget/features/analytics/presentation/widgets/cards/category_donut_card_test.dart
    - test/golden/goldens/category_donut_card_*.png (13)
    - test/golden/goldens/analytics_screen_scroll_smoke_light_ja.png
decisions:
  - "self name single source = userProfileProvider (watched, not snapshotted) → 改名 invalidate 后实时同步"
  - "self injected as a synthesized GroupMember (empty role/status/publicKey) so trigger/sheet/legend all walk ONE list, deduped by deviceId"
  - "profile.displayName empty → fall back to localized analyticsDonutMemberFilterSelf, never a truncated deviceId"
  - "Bug 3 layout: net height ≈ unchanged (controls moved from card-level Column-above-hero into hero between donut and legend); only ONE SizedBox(12) leading gap to avoid a 4px viewport overflow in bare widget tests"
metrics:
  duration: ~30min
  tasks_completed: 2
  tasks_total: 3
  completed_date: 2026-06-21
---

# Quick 260621-son: 成员维度圆环 3-bug 修复 Summary

成员维度圆环卡现在对「自己」显示设置里的用户名（实时同步），无 group 时也能按「自己」过滤，且 分类/成员 toggle + filter 行已移到圆环下方、详细列表上方。Task 1 & 2（两个 `type="auto"`）已完成并各自原子提交；Task 3（`checkpoint:human-verify` gate="blocking"）等待用户真机/模拟器验收。

## What Was Built

### Task 1 — Bug 1 (self 名字) + Bug 2 (无 group 也有「自己」) — commit `01b29fc8`

- **新增 `currentDeviceIdProvider`**（`state_donut_dimension.dart`）：轻量 `@riverpod Future<String?>`，包 `ref.watch(keyManagerProvider).getDeviceId()`。这是「自己」识别的唯一来源（与交易写入时赋给 `transactions.deviceId` 同源）。改注解后跑了 build_runner 生成 `.g.dart`。
- **Bug 1 — `category_donut_card.dart`**：build 顶部 `watch` `userProfileProvider` + `currentDeviceIdProvider`；构建 `memberNames`/`memberEmojis` 后，对 self 这条用 `profile.displayName`/`profile.avatarEmoji` 覆盖。`watch`（非快照）保证设置页改名 `ref.invalidate(userProfileProvider)` 后名字同步刷新。
- **Bug 2 — `donut_dimension_member_controls.dart`**：新增 `_withSelf()` 静态方法，把 self 合成成一个 `GroupMember`（profile 名或空时回退到本地化「自己」label）prepend 到 `activeGroupMembers`，按 deviceId 去重；trigger label 与 sheet 选项统一走这个 `effectiveMembers`。给 trigger 加 `ValueKey('donut_member_filter_trigger')` 以便测试。
- **i18n**：新增 `analyticsDonutMemberFilterSelf`（ja=自分 / zh=自己 / en=Me）+ `@`-description 到全部三个 ARB，`flutter gen-l10n` 重生成 `lib/generated/app_localizations*.dart`。
- **测试**：provider 单测（override 返回固定 deviceId）+ 2 个 card widget 测试（Bug 1：成员 legend 显示 "Shean" 不显示截断 id；Bug 2：无 group 时 filter sheet ListTile 含「All members」+「Shean」）。

### Task 2 — Bug 3 (toggle+filter 行下移) + golden 重基线 — commit `0c1fcf10`

- **`donut_hero.dart`**：`DonutHero` 增加 nullable `controls` 参数；在分类模式 `build()` 与成员模式 `_buildMemberMode()` 两个分支里，都在「圆环 Stack 的 `SizedBox(height:200)`」之后、legend 行之前插入 `?controls`（null-aware element）。
- **`category_donut_card.dart`**：`controls` 从卡片级 `Column[controls, hero, JoySpendDrawer]` 移除，改为 `Column[hero, JoySpendDrawer]`，并作为 `controls:` 参数传给全部三处 `DonutHero` 构造（成员模式 / 分类+filter / 分类无filter），三条路径一致显示该行。
- **golden 重基线（macOS）**：scoped `--update-goldens` 仅对 `category_donut_card_golden_test.dart` + `analytics_screen_scroll_smoke_golden_test.dart`，共 14 个 PNG 重基线。

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Bug 3 双重 spacing 导致测试视口 4px 溢出**
- **Found during:** Task 2 full-suite gate
- **Issue:** 初版把 controls 插入为 `if (controls != null) ...[const SizedBox(height: 12), controls!]` 并保留其后已有的 `SizedBox(height: 12)`，比原布局多了 12px，使卡片在 800×600 测试视口里 `RenderFlex overflowed by 4.0 pixels`，连带 7 个既有 card 测试失败（这些测试用 bare `_subject()` 无 scroll view）。
- **Fix:** 改为只保留一个 `SizedBox(height: 12)`（圆环后），controls 直接跟随（controls 自带 `Padding(bottom:6)`）。净高度 ≈ 原布局（controls 只是从 hero 上方移到 hero 内部），不再溢出。修正后重跑 `--update-goldens` 覆盖了第一次（含多余 spacing）的基线。
- **Files modified:** `donut_hero.dart`
- **Commit:** `0c1fcf10`

**2. [Rule 1 — Lint] `use_null_aware_elements` analyzer info**
- **Found during:** Task 2 final analyze
- **Issue:** `if (controls != null) controls!,`（两处）触发 analyzer `use_null_aware_elements` info；CLAUDE.md 要求 0 issues、不用 `// ignore:`。
- **Fix:** 改用 null-aware element `?controls,`（语义/布局完全等价，无视觉变化，无需再次重基线）。
- **Files modified:** `donut_hero.dart`
- **Commit:** `0c1fcf10`

**3. [Rule 1 — Test] Bug 2 断言收窄到 sheet 的 ListTile**
- **Found during:** Task 1 GREEN
- **Issue:** 「All members」既出现在闭合的 filter trigger（当前过滤=全部）上，也出现在 sheet 选项里 → 裸 `find.text('All members')` 命中 2 个，`findsOneWidget` 失败。这是正确行为不是 bug。
- **Fix:** 断言改为 `find.descendant(of: find.byType(ListTile), matching: find.text(...))`，把「至少有这两个选项」的语义精确表达在 sheet 选项层。
- **Commit:** `01b29fc8`

## i18n

| key | ja | zh | en |
|-----|----|----|----|
| `analyticsDonutMemberFilterSelf` | 自分 | 自己 | Me |

三 locale 同步 + `@`-description；`flutter gen-l10n` 重生成 `lib/generated/app_localizations*.dart`（tracked-yet-gitignored，已随 staged modification 进入提交）。

## Quality Gates

- `flutter analyze`：**0 issues**。
- `flutter test`（全量）：**3091/3091 green**（含 architecture / anti-toxicity / golden baseline-existence）。
- golden：14 个仅在 macOS（darwin）重基线，受影响文件 = `category_donut_card_*`、`analytics_screen_scroll_smoke_light_ja`。
- 未手改任何 `.g.dart`/`.freezed.dart` 手写内容（`state_donut_dimension.g.dart` 由 build_runner 生成）。

## Task 3 — AWAITING HUMAN VERIFICATION（blocking checkpoint，未由执行者满足）

Task 3 是 `type="checkpoint:human-verify" gate="blocking"`，需用户在真机/模拟器上视觉确认。执行者不尝试满足。

**How to verify（来自 PLAN.md）：**
1. 真机/模拟器运行，进入统计页（图表 tab）「分类支出」卡片。
2. 确认 toggle（分类|成员）+ filter 行现在位于圆环**下方**、详细列表**上方**。
3. 切到「成员」维度：图例「自己」那条显示设置里的名字（应为 Shean，不是 95fayo… 截断 id）。
4. 去「设置 → 编辑个人资料」改名 → 回统计页（必要时下拉刷新/重进 tab），确认成员维度名字同步更新。
5. 点开 filter 下拉：确认在没有加入任何 group 的单人场景下，除「所有成员」外还有「自己（Shean）」可选，选它后圆环/详细只显示自己的支出。

**Resume signal:** 用户回复 "approved" 或描述问题。

## Self-Check: PASSED

- 文件存在：所有 modified 源文件已确认存在并提交（见下）。
- 提交存在：`01b29fc8`（Task 1）、`0c1fcf10`（Task 2）均在 `git log` 中。
- 工作树：仅 `.planning/quick/260621-son-bug-group/` 未跟踪（docs，由 orchestrator 处理）。
