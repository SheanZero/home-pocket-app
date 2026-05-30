# calendarDailyTotalsProvider 实现（Phase 27 Plan 02）

**日期:** 2026-05-30
**时间:** 14:55
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [CAL-02, CAL-04] Calendar Header + Month Summary

---

## 任务概述

实现 `calendarDailyTotalsProvider` — 一个 `@riverpod` async family provider，从 `AnalyticsRepository.getDailyTotals` 获取按天计算的支出合计，并将其折叠为 `Map<DateTime, int>`（使用 `_dayKey` 归一化键）。运行 build_runner 生成 `.g.dart` 文件，用 5 个真实单元测试替换 Wave 0 占位测试。

---

## 完成的工作

### 1. RED 阶段（测试先行）

创建 5 个真实失败测试（替换 Wave 0 TODO 桩），覆盖：
- SC#2: expense-only basis — stub 返回 1 条 DailyTotal
- _dayKey 归一化：非午夜时间戳的 key 查找仍成功
- empty month：map 为空，fold 返回 0
- D-11: month total fold 等于各天合计之和
- 错误传播：repository 抛出 StateError → AsyncValue.error 存储原始错误

### 2. GREEN 阶段（最小实现）

创建 `lib/features/list/presentation/providers/state_calendar_totals.dart`：
- 文件级辅助函数 `_dayKey(DateTime d) => DateTime(d.year, d.month, d.day)`（两处使用：provider fold + 未来 cell lookup）
- `@riverpod Future<Map<DateTime, int>> calendarDailyTotals(Ref ref, {required String bookId, required int year, required int month}) async { ... }`
- 使用 `show analyticsRepositoryProvider` 导入（无重复声明，符合 D-09 隔离）
- `DateBoundaries.monthRange(year, month)` 获取月份闭区间
- Phase 29 缝合注释 `// Phase 29: combine shadow books for family per-day totals`（D-10）
- 不引用 `listFilterProvider`（D-09 / Pitfall 3 隔离）

运行 `flutter pub run build_runner build --delete-conflicting-outputs` 生成 `state_calendar_totals.g.dart`。

### 3. REFACTOR 阶段

- `flutter analyze` → 0 个新问题（4 个预存在 info/warning 不变）
- 移除测试文件中未使用的 `package:flutter_riverpod/misc.dart` 导入

### 4. 关键技术决策

**Riverpod 3.1.0 async 错误行为：** `@riverpod Future<T>` provider 中抛出的异常直接存储在 `AsyncValue.error` 中（原始类型，非 `ProviderException` 封装）。`ProviderException` 封装仅适用于同步 Provider 的同步 `container.read()` 调用。CLAUDE.md 中的相关说明适用于同步 Provider，文档存在误导性。测试 5 更新为直接断言 `result.error is StateError`。

---

## 遇到的问题与解决方案

### 问题 1: ProviderException 测试断言不符合 Riverpod 3.1.0 实际行为

**症状:** 测试 5 "ProviderException wraps repository error" 失败，实际 `result.error` 为 `StateError`，非 `ProviderException`。

**原因:** CLAUDE.md Riverpod 3 conventions 中关于 `ProviderException` 的说明是针对同步 Provider 的行为，`@riverpod Future<T>` 的 async 错误不经历相同的封装流程。

**解决方案:** 修改测试断言为 `expect(result.hasError, isTrue)` + `expect(result.error, isA<StateError>())`。同时移除未使用的 `import 'package:flutter_riverpod/misc.dart'`（`flutter analyze` 报 unused_import）。

---

## 测试验证

- [x] 单元测试通过（5/5）
- [x] 代码分析零新问题（flutter analyze）
- [x] _dayKey 出现 2 处（定义 + fold 使用）
- [x] ref.watch(listFilterProvider) 出现 0 处（隔离合同）
- [x] calendarDailyTotalsProvider 存在于 .g.dart 文件中
- [x] TDD gate compliance：RED commit f083457 → GREEN commit a837db8

---

## Git 提交记录

```
f083457 test(27-02): add failing tests for calendarDailyTotalsProvider (RED)
a837db8 feat(27-02): implement calendarDailyTotalsProvider with _dayKey normalization (GREEN)
46630ec docs(27-02): complete calendarDailyTotalsProvider plan summary and state
```

---

## 后续工作

- [ ] Plan 27-03: 实现 `ListCalendarHeader` widget（消费 calendarDailyTotalsProvider）
- [ ] Plan 27-04: 将 CalendarHeaderWidget 集成到 ListScreen

---

**创建时间:** 2026-05-30 14:55
**作者:** Claude Sonnet 4.6
