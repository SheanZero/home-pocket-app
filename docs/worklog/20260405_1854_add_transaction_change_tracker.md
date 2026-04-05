# Add TransactionChangeTracker for Incremental Push

**日期:** 2026-04-05
**时间:** 18:54
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-004] Family Sync

---

## 任务概述

实现 Task 4：添加 `TransactionChangeTracker`，使 `incrementalPush` 能够实际推送新创建/删除的交易记录。在此之前，`onTransactionChanged()` 触发 `incrementalPush` 时，只推送 profile 变更和排空离线队列，交易操作本身不会被推送。

---

## 完成的工作

### 1. 新建文件

**`lib/application/family_sync/transaction_change_tracker.dart`**
- 纯内存追踪器，收集待推送的交易操作（create/delete）
- `trackCreate(operation)` — 记录创建操作
- `trackDelete({transactionId, bookId})` — 记录删除操作（构建标准 delete 操作体）
- `flush()` — 返回并清空所有待推送操作
- `pendingCount` getter — 返回当前待推送数量
- 有意设计为纯内存（无持久化）：10s debounce 保证快速 flush，下次启动 fullSync 会做对账

### 2. 修改文件

**`lib/application/family_sync/sync_orchestrator.dart`**
- 新增 `TransactionChangeTracker _changeTracker` 字段及构造函数参数（required）
- `_executeIncrementalPush()` 在推送 profile 之前先 flush tracker，有待推送的 tx ops 则调用 `_pushSync.execute()`
- 返回值更新为 `SyncOrchestratorSuccess(pushedCount: txnOps.length)`

**`lib/application/accounting/create_transaction_use_case.dart`**
- 新增可选参数 `TransactionChangeTracker? changeTracker`
- persist 后、`onTransactionChanged()` 前调用 `_changeTracker?.trackCreate()`
- 使用 `TransactionSyncMapper.toCreateOperation()` 构建操作体
- 注意：`sourceBookName` 使用 `bookId` 作为 fallback（use case 层无 book name 可用）

**`lib/application/accounting/delete_transaction_use_case.dart`**
- 新增可选参数 `TransactionChangeTracker? changeTracker`
- `softDelete` 后、`onTransactionChanged()` 前调用 `_changeTracker?.trackDelete()`
- 使用 `existing.bookId` 作为 bookId（已在 findById 时获取到 existing 对象）

**`lib/features/family_sync/presentation/providers/sync_providers.dart`**
- 新增 `@Riverpod(keepAlive: true) TransactionChangeTracker transactionChangeTracker(Ref ref)`（keepAlive 保证跨页面存活）
- `syncOrchestratorProvider` 注入 `transactionChangeTrackerProvider`

**`lib/features/accounting/presentation/providers/use_case_providers.dart`**
- `createTransactionUseCaseProvider` 注入 `transactionChangeTrackerProvider`
- `deleteTransactionUseCaseProvider` 注入 `transactionChangeTrackerProvider`

### 3. 代码变更统计

- 新建文件：1 个
- 修改文件：4 个
- 代码生成：`sync_providers.g.dart` 更新（新增 `transactionChangeTrackerProvider`）

---

## 遇到的问题与解决方案

### 问题 1: sourceBookName 无法获取
**症状:** `CreateTransactionUseCase` 只有 `bookId`，没有 book 名称
**原因:** use case 层未注入 BookRepository
**解决方案:** 使用 `bookId` 作为 fallback。`sourceBookName` 是 metadata，用于对端显示，不影响核心同步逻辑。全量同步时会用正确的 book name 覆盖。

---

## 测试验证

- [x] 单元测试通过（878 个测试全部通过）
- [x] 静态分析 0 issue（`flutter analyze`）
- [x] 代码生成成功（build_runner build）
- [ ] 集成测试（无新增集成测试，现有测试覆盖 orchestrator 行为）

---

## Git 提交记录

```bash
feat: track and push individual transaction changes in incrementalPush
```

---

## 后续工作

- [ ] 考虑在 `CreateTransactionUseCase` 中注入 `BookRepository` 以提供正确的 `sourceBookName`
- [ ] 可考虑对 `TransactionChangeTracker` 增加单元测试覆盖

---

**创建时间:** 2026-04-05 18:54
**作者:** Claude Sonnet 4.6
