# Fix: 悦己统计 and 本月最爱 Not Refreshing After FAB Transaction Entry

**日期:** 2026-05-18
**时间:** 15:25
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** Home Screen / Analytics / MainShellScreen

---

## 任务概述

修复主页的悦己统计（Soul stats ring）和本月最爱（Monthly favorite strip）在通过 FAB 新增一条灵魂账本记录后不自动刷新的问题。同样修复了同步完成后同一问题（sync listener parity）。根因是 `MainShellScreen` 中的两处 provider 失效调用遗漏了 `happinessReportProvider` 和 `bestJoyMomentProvider`。

---

## 完成的工作

### 1. 主要变更

- 修改文件：`lib/features/home/presentation/screens/main_shell_screen.dart`
- 新增 2 个 import：`repository_providers.dart` 和 `state_happiness.dart`
- FAB `onFabTap` 回调：在已有的 `monthlyReport` 和 `todayTransactions` 失效调用后，增加 `happinessReportProvider` 和 `bestJoyMomentProvider` 的 `ref.invalidate`
- 同步 listener `wasSyncing && nowDone` 块：相同的两个失效调用，保持与 FAB 路径的一致性
- `currencyCode` 通过 `ref.read(bookByIdProvider(bookId: bookId)).value?.currency ?? 'JPY'` 解析，与 `home_screen.dart:95–96` 模式完全一致

### 2. 技术决策

- 使用 `ref.invalidate`（非 `ref.refresh`）：`invalidate` 是惰性失效（下次有 listener 时才重新执行），`refresh` 是立即重新执行（即使当前没有 listener 订阅也会触发）。这里只需清除缓存，让下一次 widget 读取时自然触发。
- `currencyCode` 必须与 `HomeScreen` 构建 provider family 实例时使用的值完全一致，才能命中同一个缓存键（`happinessReportProvider` 是 4-arg family）。

### 3. 代码变更统计

- 修改文件数：1
- 新增行数：28
- 删除行数：0

---

## 遇到的问题与解决方案

无明显问题，代码修改直接命中 PLAN.md 描述的精确位置。

---

## 测试验证

- [x] `flutter analyze lib/features/home/presentation/screens/main_shell_screen.dart` — No issues found!
- [x] `flutter analyze`（全项目）— No issues found!
- [x] `grep -n "happinessReport\|bestJoyMoment"` — 4 matches（2 in sync block, 2 in FAB block）
- [x] `grep -c "ref\.invalidate"` — 10（≥8 required）
- [ ] 手动 in-app 测试（需用户在真机/模拟器执行）

---

## Git 提交记录

```
Commit: 2cb534f
Date: 2026-05-18

fix(260518-kyr): invalidate happinessReport and bestJoyMoment on FAB return and sync complete
```

---

## 后续工作

- [ ] 相关风险：`analytics_screen.dart` FAB 路径存在同样的隐患（soul stats 在分析页 FAB 创建记录后不自动刷新），需手动下拉刷新 — 已记录于 SUMMARY.md "Related Risk"，超出本次修复范围

---

## 参考资源

- PLAN: `.planning/quick/260518-kyr-fix-soul-stats-and-monthly-favorite-not-/260518-kyr-PLAN.md`
- SUMMARY: `.planning/quick/260518-kyr-fix-soul-stats-and-monthly-favorite-not-/260518-kyr-SUMMARY.md`

---

**创建时间:** 2026-05-18 15:25
**作者:** Claude Sonnet 4.6
