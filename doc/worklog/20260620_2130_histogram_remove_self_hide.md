# 移除满足度直方图卡片的 self-hide（始终渲染）

**日期:** 2026-06-20
**时间:** 21:30
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** [MOD-007] Analytics

---

## 任务概述

用户指示反转 D-B5（`totalJoyTx < 5` 时卡片自隐藏）。「悦己满足度分布」分区标题在
analytics_screen 外壳中无条件渲染，卡片内部的 self-hide 会在 joy 笔数 < 5 时留下一个
孤立标题（标题下方空无一物）。修复方式：删除该 gate，让直方图始终渲染——空数据时即为
`SatisfactionDistributionHistogram` 的空态（10 根零桩柱 +「0 笔」页脚，无中位数 pill），
这同时修掉了孤立标题问题。

---

## 完成的工作

### 1. 主要变更
- `lib/features/analytics/presentation/widgets/cards/satisfaction_histogram_card.dart`
  删除 `if (report.totalJoyTx < 5) return const SizedBox.shrink();`；
  `happinessAsync.when(data: (report){...})` → `data: (_) => distributionAsync.when(...)`，
  happiness 的值仅用于 loading/error gating，已丢弃（`_`）。两个 provider 仍被 watch，
  `satisfactionHistogramRefreshTargets` 刷新并集保持不变。
- `lib/features/analytics/presentation/analytics_card_registry.dart` 更新 card-4 注释。

### 2. 测试 / golden 更新
- `analytics_screen_test.dart`：`thin-sample ... hides histogram slot`（断言 findsNothing）
  → 改为断言 `SatisfactionDistributionHistogram` `findsOneWidget`。
- `anti_toxicity_phase47_test.dart`：`self_hide` sweep → `empty`，空态现在渲染卡片体，
  补上 `_expectRenderedText()` 可见文本守卫。
- `satisfaction_histogram_card_golden_test.dart`：`empty self-hide` → `empty data`，
  重基线 `satisfaction_histogram_card_empty_light_ja.png`（未删除）。
- scroll-smoke golden 重跑 `--update-goldens`，PNG 字节不变（空态内容落在视口外）。

### 3. 代码变更统计
- 2 个 lib 文件、3 个 test 文件、1 个 golden PNG。零删除。

---

## 测试验证

- [x] flutter analyze → 0 issues（无 unused-variable 警告）
- [x] flutter test 全量 → All tests passed!（3072 个）
- [x] macOS golden 重基线，仅受影响 master，零删除

---

## Git 提交记录

```
d07d5314 fix(analytics): histogram card always renders — remove totalJoyTx<5 self-hide (round-5 r5b)
0c11a936 test(analytics): flip histogram self-hide assertions to always-render (round-5 r5b)
```

---

## 后续工作

- 无。范围严格限定于直方图卡片的 self-hide；直方图视觉、donut、calendar、joy-drawer、
  trend 均未改动。

---

**创建时间:** 2026-06-20 21:30
**作者:** Claude Opus 4.8
