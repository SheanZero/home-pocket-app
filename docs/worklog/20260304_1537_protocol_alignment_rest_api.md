# Protocol Alignment: REST API Section 7

**日期:** 2026-03-04
**时间:** 15:37
**任务类型:** 重构
**状态:** 已完成
**相关模块:** [MOD-003] FamilySync

---

## 任务概述

对照 `docs/arch/server/PROTOCOL.md` Section 7 (REST API 详细定义)，逐项检查 Flutter 客户端实现，发现 9 处差异 (D1-D9)，严格按协议文档进行修正。

---

## 完成的工作

### 1. 主要变更

**D1+D2 (CRITICAL): ISO 8601 日期格式对齐**
- `lib/infrastructure/sync/relay_api_client.dart`: `pullSync` 的 `since` 参数从 `int?` 改为 `String?` (ISO 8601)
- `lib/application/family_sync/pull_sync_use_case.dart`: `createdAt` 解析从 `as int` 改为 `DateTime.parse(... as String)`; `lastServerTimestamp` 类型从 `int?` 改为 `DateTime?`

**D3 (IMPORTANT): SyncMessage 模型补全**
- `lib/features/family_sync/domain/models/sync_message.dart`: 添加 `chunkIndex` 和 `totalChunks` 字段

**D4+D9 (IMPORTANT): 新增 push 通知处理器**
- `lib/infrastructure/sync/push_notification_service.dart`: 添加 `member_left` 和 `group_dissolved` handler 字段、注册接口、switch 路由、导航 intent
- `lib/infrastructure/sync/sync_trigger_service.dart`: 扩展 `SyncTriggerEventType` 枚举; 添加 `KeyManager` 依赖; 实现 `_handleMemberLeft` (自身被移除 vs 其他成员离开) 和 `_handleGroupDissolved`
- `lib/features/family_sync/presentation/providers/sync_providers.dart`: 添加 `keyManager` 到 SyncTriggerService 构造

**D5 (IMPORTANT): 移除 registerDevice 的 pushToken 参数**
- `lib/infrastructure/sync/relay_api_client.dart`: 移除 `pushToken` 参数
- `lib/features/family_sync/use_cases/create_group_use_case.dart`: 移除 `getPushToken`
- `lib/features/family_sync/use_cases/join_group_use_case.dart`: 移除 `getPushToken`
- `lib/features/family_sync/presentation/providers/group_providers.dart`: 移除 `getPushToken` wiring

**D6+D7 (MINOR): 响应字段对齐**
- `join_group_use_case.dart`: 解析协议定义的 `deviceName` 字段
- `create_group_use_case.dart`: 解析并验证 `bookId` 与输入匹配

**D8 (MINOR): 文档注释修正**
- `relay_api_client.dart`: 移除 `hasMore` 提及 (协议未定义)

### 2. 技术决策
- Push token 通过 `PUT /device/push-token` 独立注册 (PushNotificationService.registerToken)，从 registerDevice 移除是安全的
- `member_left` / `group_dissolved` handler 预先添加，server 端尚未发送这些 push 类型 (标记为 🔜)，handler 不会被触发直到 server 实现

### 3. 代码变更统计
- 修改文件数量: 16 (含测试)
- 主要源文件: 9
- 测试文件: 7

---

## 遇到的问题与解决方案

### 问题 1: sync_trigger_service_test.dart 缺少 GroupMember import
**症状:** `The function 'GroupMember' isn't defined` 分析错误
**原因:** 新增的 member_left 测试使用了 GroupMember 但未 import
**解决方案:** 添加 `import 'package:home_pocket/features/family_sync/domain/models/group_member.dart'`

---

## 测试验证

- [x] 单元测试通过 (670/670)
- [x] flutter analyze 0 issues
- [x] build_runner 成功
- [ ] 手动测试验证 (需要 server 配合)
- [x] 代码审查完成

---

## 后续工作

- [ ] Server 端实现 `member_left` 和 `group_dissolved` push 通知后进行端到端测试
- [ ] 确认 server 端 `createdAt` 和 `since` 参数已切换为 ISO 8601 格式
- [ ] 考虑添加 SyncMessage 的 chunk 重组逻辑 (当 totalChunks > 1 时)

---

## 参考资源

- [PROTOCOL.md Section 7](docs/arch/server/PROTOCOL.md)
- [Plan: wise-knitting-tarjan.md](/Users/xinz/.claude/plans/wise-knitting-tarjan.md)

---

**创建时间:** 2026-03-04 15:37
**作者:** Claude Opus 4.6
