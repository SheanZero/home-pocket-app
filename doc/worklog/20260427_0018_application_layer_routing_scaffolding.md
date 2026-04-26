# Application-Layer Routing Scaffolding (Plan 04-01)

**日期:** 2026-04-27
**时间:** 00:18
**任务类型:** 功能开发 + 重构
**状态:** 已完成
**相关模块:** HIGH-02 (Application Layer Routing)

---

## 任务概述

执行 Phase 04 Plan 01：为所有 6 个功能模块创建 `lib/application/<feature>/repository_providers.dart` DI 脚手架文件，以及 4 个 Use Case 类，将直接访问 `infrastructure/` 的 Presentation 层代码提升到 Application 层。这是 Plan 04-02（替换 33 个直接 infrastructure/ 导入）的前置准备。

---

## 完成的工作

### 1. Task 1 — FormatterService + LocaleSettings Re-export

- 创建 `lib/application/i18n/formatter_service.dart`：`const FormatterService()` 类，8 个实例方法委托给 `DateFormatter`/`NumberFormatter` 静态方法
- 创建 `lib/application/i18n/locale_settings_view.dart`：re-export wrapper
- 创建测试 `test/unit/application/i18n/formatter_service_test.dart`：13 个测试，包含 `initializeDateFormatting` setup

### 2. Task 2 — 5 个功能模块 DI 提升

创建了以下文件，所有 provider 使用 `app` 前缀（Warning 7 fix）：
- `lib/application/family_sync/repository_providers.dart`：7 个 app 前缀 provider（appApnsPushMessagingClient, appKeyManager, appE2eeService, appRelayApiClient, appPushNotificationService, appSyncQueueManager, appWebSocketService）+ `appSyncRepositoryProvider` throw-if-not-overridden sentinel
- `lib/application/accounting/repository_providers.dart`：appAppDatabase + appKeyManager re-exports
- `lib/application/analytics/repository_providers.dart`：appAppDatabase re-export
- `lib/application/profile/repository_providers.dart`：appAppDatabase + appKeyManager re-exports
- `lib/application/settings/repository_providers.dart`：appAppDatabase re-export

### 3. Task 3 — ML + Voice + dual_ledger + home + 4 Use Cases

- `lib/application/ml/lookup_merchant_use_case.dart`：封装 `MerchantDatabase.findMerchant()`
- `lib/application/ml/repository_providers.dart`：`@Riverpod(keepAlive: true) appMerchantDatabase`（HIGH-05 保留）
- `lib/application/voice/start_speech_recognition_use_case.dart`：封装 callback-based SpeechRecognitionService
- `lib/application/voice/repository_providers.dart`：appSpeechRecognitionService + startSpeechRecognitionUseCase
- `lib/application/family_sync/notify_member_approval_use_case.dart`：WebSocket 连接管理 use case
- `lib/application/family_sync/listen_to_push_notifications_use_case.dart`：推送通知流 use case
- `lib/application/home/repository_providers.dart`：appAppDatabase scaffold
- `lib/application/dual_ledger/providers.dart` → `repository_providers.dart` 重命名

### 4. Task 4 — 覆盖率验证 + 补充测试

运行覆盖率门控，对 3 个不达标文件补充测试：
- `StartSpeechRecognitionUseCase`：添加 cancel() 和 isAvailable 测试（77.78% → 100%）
- `NotifyMemberApprovalUseCase`：添加 signMessage 回调调用测试（76.92% → 100%）
- `family_sync/repository_providers_test`：添加 notifyMemberApproval + listenToPushNotifications provider 测试（75% → 94.44%）

### 5. 技术决策

- **`app` 前缀**：所有提升的 provider 使用 `app` 前缀，防止 Wave 2/3 共存期间 Riverpod codegen 符号冲突
- **throw-if-not-overridden sentinel**：`appSyncRepositoryProvider` 模仿 `appDatabaseProvider` 模式；Plan 04-02 提供具体实现的 override
- **覆盖率门控范围**：7 个纯 `@riverpod` provider 文件的可执行代码在 `.g.dart` 中（被 lcov filter 排除），0/0 不计入失败；覆盖率门控仅针对有真实可执行行的 8 个文件

### 6. 代码变更统计

- 创建文件：20 个（14 个源文件 + 6 个测试文件）
- 修改文件：5 个（1 个重命名 + 4 个 import 更新）
- 提交数量：14 个（包含 final metadata commit）

---

## 遇到的问题与解决方案

### 问题 1: MerchantDatabase.lookup() 方法不存在
**症状:** 编译错误
**原因:** 计划模板使用了错误的方法名
**解决方案:** 使用实际方法 `findMerchant()`

### 问题 2: SpeechRecognitionService 使用回调 API 而非 Stream
**症状:** 计划预期 Stream API，实际是 callback-based
**原因:** 计划模板描述与实际实现不符
**解决方案:** `StartSpeechRecognitionUseCase` 封装 callback API

### 问题 3: NotifyMemberApprovalUseCase 有未使用的字段
**症状:** analyzer 警告 `unused_field`
**原因:** `RelayApiClient` 在 use case 中从未使用
**解决方案:** 移除该依赖

### 问题 4: dual_ledger 重命名需要两个额外 fix commit
**症状:** git mv 提交后 `part` 指令仍引用旧文件名
**原因:** 内容编辑和 git mv 分开提交
**解决方案:** 两个额外 fix commit 修正 `part` 指令和 `.g.dart` 内容

### 问题 5: FormatterService 测试中 LocaleDataException
**症状:** `Locale data has not been initialized`
**原因:** intl 包需要在使用前初始化 locale 数据
**解决方案:** `setUpAll(() async { await initializeDateFormatting(...) })`

---

## 测试验证

- [x] 单元测试通过：1226 个测试全部 PASS
- [x] 覆盖率门控：8 个有真实可执行行的文件全部 ≥80%
- [x] `flutter analyze`：0 个新问题（26 个为测试文件中的预存警告）
- [x] `git diff --exit-code lib/`：CLEAN（无残留生成文件差异）

---

## Git 提交记录

```
82e4ff4 feat(04-01): add FormatterService + LocaleSettings re-export
51ac1dc feat(04-01): hoist sync-client + crypto DI to family_sync/repository_providers.dart
f7bf667 feat(04-01): hoist app database + key manager re-exports to accounting/repository_providers.dart
96fc649 feat(04-01): hoist app database re-export to analytics/repository_providers.dart
82cf9f4 feat(04-01): hoist app database + key manager re-exports to profile/repository_providers.dart
fcb5fe9 feat(04-01): hoist app database re-export to settings/repository_providers.dart
1141bb8 feat(04-01): add LookupMerchantUseCase + ml/repository_providers.dart
3c64a4f feat(04-01): add StartSpeechRecognitionUseCase + voice/repository_providers.dart
c95a40a feat(04-01): add NotifyMemberApprovalUseCase + ListenToPushNotificationsUseCase
88a68e5 refactor(04-01): rename dual_ledger/providers.dart to repository_providers.dart
912b187 feat(04-01): add home/repository_providers.dart
9f2196c fix(04-01): update part directive in dual_ledger/repository_providers.dart
2847758 fix(04-01): update part of directive in dual_ledger/repository_providers.g.dart
55c19ee test(04-01): coverage top-up for voice, notify-approval, and family-sync providers
b809929 docs(04-01): complete application-layer routing scaffolding plan summary
```

---

## 后续工作

- [ ] Plan 04-02：替换 33 个 feature presentation 中的直接 infrastructure/ 导入为 application/ 层导入
- [ ] Plan 04-02：提供 appSyncRepositoryProvider 的具体实现 override
- [ ] Plan 04-02 Task 5：删除 feature 侧原始（无前缀）provider 定义

---

## 参考资源

- `.planning/phases/04-high-fixes/04-01-application-layer-routing-scaffolding-PLAN.md`
- `.planning/phases/04-high-fixes/04-01-SUMMARY.md`
- `.planning/phases/04-high-fixes/04-PATTERNS.md`

---

**创建时间:** 2026-04-27 00:18
**作者:** Claude Sonnet 4.6
