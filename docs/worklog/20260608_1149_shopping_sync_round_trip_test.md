# Phase 37 Wave 4: shopping_sync_round_trip_test.dart SC-5 Implementation

**日期:** 2026-06-08
**时间:** 11:49
**任务类型:** 功能开发 (TDD — GREEN phase)
**状态:** 已完成
**相关模块:** [MOD-003] Family Sync / [Phase 37] Application Use Cases + Sync Integration

---

## 任务概述

Phase 37 的最终 wave（Wave 4）。将 `test/integration/sync/shopping_sync_round_trip_test.dart` 从 Wave-0 脚手架实现为完全通过的 GREEN 状态。这是 SC-5 证明：来自模拟远端成员的 public item 在 `watchByListType('public')` 流中出现，**无需** `ref.invalidate` 调用（通过 Drift `.watch()` readsFrom 实现响应式推送，运用 v1.4 GAP-2 经验）。运行 Phase Gate 确认所有 13 个需求已被测试覆盖。

---

## 完成的工作

### 1. 主要变更

**文件:** `test/integration/sync/shopping_sync_round_trip_test.dart`

- **修复响应式流测试**：原脚手架使用 `.first` 捕获了 Drift 订阅时立即发出的初始空状态（在写入之前），导致测试失败（`Expected: true, Actual: <false>`）。改为 `.skip(1).first.timeout(Duration(seconds: 5))`，跳过初始空状态 emission，等待写入后的 re-emission。
- **新增第4个测试**（sticky-complete merge）：脚手架只有3个测试，计划要求4个。新增 sticky-complete 测试：T1（completedAt，较晚）>T0（stale update，较早），stale update 的 `isCompleted=false` 不应覆盖本地完成状态。
- **全局使用 `kShoppingItemEntityType` 常量**：替换所有内联的 `'shopping_item'` 字符串字面量。

### 2. 4个测试全部 GREEN

| 测试 | 验证内容 | 需求 |
|------|---------|------|
| 响应式流传递 | public item 通过 Drift `.watch()` 响应式出现，无 ref.invalidate | SYNC-06, SC-5 |
| private item 隔离 | private item 永不出现在 public 流中（SQL WHERE 过滤） | SYNC-02, SC-5 |
| 墓碑不复活 | create→delete→update 后 isDeleted 仍为 true | SC-4 |
| sticky-complete | T0<T1 的 stale update 不解除已完成状态 | D-03, SC-4 |

### 3. Phase Gate — 13个需求全部覆盖

531/531 测试通过。`flutter analyze lib/` 0 错误（2个预存在的 INFO 级弃用警告，不在范围内）。

### 4. 技术决策

- **skip(1) 模式**：Drift 响应式流订阅时立即发出初始快照。`.first` 会在写入前完成。使用 `.skip(1).first` 跳过初始状态，等待写入后的 re-emission，正确证明无需 `ref.invalidate` 的响应式特性。
- **确定性 DateTime**：sticky-complete 测试使用 `DateTime(2026, 6, 8, 10, 0)` 和 `DateTime(2026, 6, 8, 9, 0)` 明确指定 T1/T0，避免时钟偏差导致的不确定性。

---

## 遇到的问题与解决方案

### 问题 1: 响应式流测试失败（`.first` 捕获初始空状态）
**症状:** 第1个测试：`Expected: true, Actual: <false>`，`streamFuture` 解析为空列表
**原因:** Drift 的 `.watch()` 在订阅时立即发出初始快照（空列表）。`.first` 在写入发生前就完成了。
**解决方案:** 改用 `.skip(1).first.timeout(const Duration(seconds: 5))` 跳过初始状态。

### 问题 2: 第4个测试（sticky-complete）在脚手架中缺失
**症状:** Wave-0 脚手架只有3个测试，计划的 `<behavior>` 要求4个
**解决方案:** 按照计划规范，使用明确的 ISO 8601 T0/T1 编码实现了第4个测试。

---

## 测试验证

- [x] `flutter test test/integration/sync/shopping_sync_round_trip_test.dart` — 4/4 GREEN
- [x] `flutter test test/unit/application/ test/integration/sync/` — 531/531 GREEN
- [x] `flutter analyze lib/` — 0 errors (2 pre-existing INFO out of scope)
- [x] grep 断言：watchByListType (5次), isDeleted (1次), isCompleted (10次)
- [x] 所有13个需求ID有通过的测试证据

---

## Git 提交记录

```bash
Commit: 1b991f0d
Date: 2026-06-08
test(37-06): implement shopping_sync_round_trip_test.dart GREEN (SC-5, SYNC-06)

Commit: ae2923e5
Date: 2026-06-08
docs(37-06): complete shopping sync round trip — Phase 37 final wave
```

---

## 后续工作

- Phase 37 完成 (6/6 plans done, 13/13 requirements covered)
- 下一步: `/gsd-verify-work` 或 Phase 38 (Shell + Widgets)

---

**创建时间:** 2026-06-08 11:49
**作者:** Claude Sonnet 4.6
