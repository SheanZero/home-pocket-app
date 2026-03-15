# Bill Sync (Shadow Book) 开发报告

**日期:** 2026-03-15
**任务类型:** 开发实现 + 实现复核
**负责分支:** `codex-dev`
**状态:** 条件通过 (CONDITIONAL PASS)
**相关计划:**
- `docs/plans/2026-03-15-bill-sync-dev-plan.md`
- `docs/plans/2026-03-15-bill-sync-implementation.md`

---

## 结论摘要

本次交付已经完成 Bill Sync 的核心数据链路：

- 使用单远端成员单 Shadow Book 的存储模型
- 在每条同步交易的 `metadata` 中保留来源账本信息
- 打通本地创建记账后的增量推送
- 打通 pull 后按 `fromDeviceId` 路由到 Shadow Book 的写入链路
- 打通确认入组后的全量同步
- 打通 leave / deactivate / group_dissolved / local removed 场景下的同步数据清理

自动化验证结果：

- `flutter analyze` → `No issues found!`
- `flutter test` → `01:44 +714: All tests passed!`

架构复核结果：

- 无阻塞上线的 critical 架构问题
- 存在 3 个中等级别的计划偏差/待补项，见下文“Review Findings”

---

## 已实现内容

### 1. Shadow Book 数据模型与存储

- `books` 表扩展了 Shadow Book 字段：
  - `isShadow`
  - `groupId`
  - `ownerDeviceId`
  - `ownerDeviceName`
- Drift schema 版本从 `10` 升到 `11`
- `Book` domain model、`BookRepository`、`BookDao`、`BookRepositoryImpl` 已同步扩展
- 新增 `ShadowBookService` 统一处理创建、查找、清理

### 2. 同步交易序列化与落库

- `Transaction` domain model 新增 `metadata`
- 新增 `TransactionSyncMapper`
  - `toSyncMap`
  - `fromSyncMap`
  - `toCreateOperation`
- 同步交易 metadata 中保留来源账本维度：
  - `sourceBookId`
  - `sourceBookName`
  - `sourceBookType`
- `TransactionRepositoryImpl` 已支持 `metadata` 的 JSON 编解码

### 3. Pull Sync 应用链路

- `PullSyncUseCase` 会把 `fromDeviceId` 注入到标准化 operation
- 新增 `ApplySyncOperationsUseCase`
  - `create` / `insert` 写入 Shadow Book
  - `delete` 做 soft delete
  - `update` 写入已有 Shadow Book 交易
- 当 Shadow Book 尚不存在时，支持按 group 成员信息懒创建

### 4. Push / Full Sync 触发链路

- `CreateTransactionUseCase` 成功落库后 fire-and-forget 推送同步消息
- `DeleteTransactionUseCase` 成功软删后 fire-and-forget 推送删除消息
- `FullSyncUseCase` provider 改为遍历所有本地非 shadow books，并附带来源账本 metadata
- `ConfirmMemberUseCase` 与 `SyncTriggerService.member_confirmed` 处理链路中都已触发 full sync

### 5. Group 生命周期清理

- `LeaveGroupUseCase`
- `DeactivateGroupUseCase`
- `SyncTriggerService._handleMemberLeft`
- `SyncTriggerService._handleGroupDissolved`

以上场景都会清空队列并删除对应 group 的 Shadow Book + Shadow transactions。

---

## 架构复核

本次复核参考：

- `docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md`
- `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md`
- `docs/arch/02-module-specs/MOD-003_FamilySync.md`
- `docs/arch/04-basic/BASIC-001_Crypto_Infrastructure.md`

### 通过项

1. **分层方向正确**
   - Shadow Book 编排逻辑放在 `lib/application/family_sync/`
   - Repository 接口仍在 domain 层
   - DAO / Drift / Repository 实现在 `lib/data/`
   - Sync 技术能力仍在 `lib/infrastructure/sync/`

2. **数据访问职责正确**
   - `books` 表、DAO、RepositoryImpl 的改动都集中在 data 层，符合 `ARCH-002`

3. **Hash chain 的 per-book 边界未被破坏**
   - 本地交易继续按本地 `bookId` 接链
   - 远端交易进入 Shadow Book，避免与本地账本交错，符合 `BASIC-001` 对 per-book 验证边界的要求

4. **同步协议接入点合理**
   - `PullSyncUseCase` 只负责解密、标准化、回调 apply
   - 真正的业务落库逻辑放在 `ApplySyncOperationsUseCase`
   - 符合 `MOD-003_FamilySync` 中 application/use case 分工

### Review Findings

1. **[MEDIUM] Group 有效性检查未实现**
   - 开发计划中的 `CheckGroupValidityUseCase` / `GroupValidityCache` 尚未落地。
   - 当前创建/删除账单时仍然是“只要本地 active group 存在就允许推送”。
   - 影响：如果 group 已在服务器失效，本地仍可能继续入队，直到后续生命周期事件或服务端交互才被动发现。

2. **[MEDIUM] Update 同步的 LWW 语义未完整实现**
   - 计划里定义了 `updatedAt` 驱动的 LWW。
   - 当前 `ApplySyncOperationsUseCase` 已支持 `update` 分支，但还没有显式比较远端 `updatedAt` 与本地版本，也没有完整的 update 发起链路。
   - 影响：未来接入“编辑账单”后，需要补齐 update payload 时间戳和冲突处理，否则更新语义不完整。

3. **[MEDIUM] 计划中的集成/覆盖率/家庭视图阶段未完成**
   - 未新增 round-trip integration test
   - 未运行 `flutter test --coverage`
   - Phase 6 的家庭聚合视图/UI 未实现
   - 影响：当前交付覆盖的是“核心同步数据链路”，不是整个计划文件的所有后续阶段

---

## 与原计划的偏差说明

### 偏差 1: Shadow Book 创建时机

原计划中有“确认入组时立即创建 Shadow Book”的方案。

本次实现采用了更简单的替代方案：

- 在首次收到某个 `fromDeviceId` 的 bill operation 时懒创建 Shadow Book

结论：

- 行为上满足需求
- 实现复杂度更低
- 不阻塞 full sync/pull sync
- 可以接受

### 偏差 2: InitialSyncUseCase 未单独抽象

原计划中提到 `InitialSyncUseCase`。

本次实现直接复用了已有 `FullSyncUseCase`，并在：

- `ConfirmMemberUseCase`
- `SyncTriggerService._handleMemberConfirmed`

两个入口触发。

结论：

- 功能上等价
- 减少了重复抽象
- 可以接受

### 偏差 3: Books migration test 未新建独立文件

原计划建议新增 `books_table_migration_test.dart`。

本次实现把相关断言并入现有 `books_table_test.dart`。

结论：

- 覆盖了 Shadow Book 字段和索引行为
- 但“迁移路径”本身的专项回归保护弱于独立 migration test
- 建议后续补 dedicated migration regression test

---

## 关键实现文件

### 数据与模型

- `lib/data/tables/books_table.dart`
- `lib/data/app_database.dart`
- `lib/data/daos/book_dao.dart`
- `lib/data/repositories/book_repository_impl.dart`
- `lib/features/accounting/domain/models/book.dart`
- `lib/features/accounting/domain/models/transaction.dart`
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart`

### 核心业务链路

- `lib/application/family_sync/shadow_book_service.dart`
- `lib/application/family_sync/apply_sync_operations_use_case.dart`
- `lib/application/family_sync/pull_sync_use_case.dart`
- `lib/application/accounting/create_transaction_use_case.dart`
- `lib/application/accounting/delete_transaction_use_case.dart`

### Provider / Trigger / 生命周期

- `lib/features/family_sync/presentation/providers/sync_providers.dart`
- `lib/features/family_sync/use_cases/confirm_member_use_case.dart`
- `lib/features/family_sync/use_cases/leave_group_use_case.dart`
- `lib/features/family_sync/use_cases/deactivate_group_use_case.dart`
- `lib/infrastructure/sync/sync_trigger_service.dart`

---

## 测试与验证

### 新增/更新的重点测试

- `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart`
- `test/unit/application/family_sync/shadow_book_service_test.dart`
- `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`
- `test/unit/application/accounting/create_transaction_use_case_test.dart`
- `test/unit/application/accounting/delete_transaction_use_case_test.dart`
- `test/infrastructure/sync/sync_trigger_service_test.dart`

### 最终验证结果

```text
flutter analyze
No issues found! (ran in 1.4s)
```

```text
flutter test
01:44 +714: All tests passed!
```

---

## 建议的下一步

1. 实现 `CheckGroupValidityUseCase` 与缓存层，补齐计划的 Phase 5
2. 补齐 update 编辑链路与 `updatedAt`-based LWW
3. 新增 end-to-end round trip integration test
4. 跑一次 `flutter test --coverage`，确认新增核心代码覆盖率
5. 再进入家庭聚合视图/UI 阶段

---

**结论:** Shadow Book 方案 3 的核心同步链路已经落地，架构方向正确，可作为后续家庭视图和 group validity 扩展的稳定基础继续推进。
