# Phase 3 Plan 05: Characterization Tests

**日期:** 2026-04-26
**时间:** 16:13
**任务类型:** 测试
**状态:** 已完成（lib/main.dart deferred-final-gate 待 Plan 03-02 Task 6 合并）
**相关模块:** Phase 3 Wave 1 - Test Infrastructure

---

## 任务概述

按照 CONTEXT.md D-15 要求，在 Phase 3 重构提交落地之前写入特征化测试（characterization tests）。
目标是对 `Phase 3 touched-files ∩ files-needing-tests.txt` 中的文件进行行为锁定，确保重构后的代码行为与重构前保持一致。

---

## 完成的工作

### 1. 冻结交集列表

写入 `/tmp/phase3-plan05-intersection.txt`（5个文件）：
- `lib/features/family_sync/use_cases/deactivate_group_use_case.dart`
- `lib/features/family_sync/use_cases/regenerate_invite_use_case.dart`
- `lib/features/family_sync/use_cases/remove_member_use_case.dart`
- `lib/infrastructure/security/providers.dart`
- `lib/main.dart`

### 2. 主要变更

- 新建 `test/features/family_sync/use_cases/deactivate_group_use_case_characterization_test.dart`
  - 6 个测试：成功路径、调用顺序验证、RelayApiException、通用异常、仓库异常、无 shadowBookService 场景
  - 覆盖率：100%

- 新建 `test/features/family_sync/use_cases/regenerate_invite_use_case_characterization_test.dart`
  - 5 个测试：成功路径、updateInviteCode 调用验证、RelayApiException、通用异常、仓库异常
  - 覆盖率：100%

- 新建 `test/features/family_sync/use_cases/remove_member_use_case_characterization_test.dart`
  - 5 个测试：成功路径、剩余成员列表验证、group 不存在时跳过更新、RelayApiException、通用异常
  - 覆盖率：100%

- 新建 `test/infrastructure/security/providers_characterization_test.dart`
  - 7 个测试：UnimplementedError/StateError（anyOf 前/后兼容）、覆盖值传透、auditLogger 连线、secureStorageService 连线×2、biometricService 创建、biometricAvailability 连线
  - 覆盖率：100%（初始 66.67%，添加 biometric tests 后达到 100%）

- 新建 `test/main_characterization_smoke_test.dart`
  - 4 个 testWidgets：CircularProgressIndicator（loading）、MainShellScreen（有 profile）、ProfileOnboardingScreen（无 profile）、错误 Scaffold
  - 独立覆盖率：59.74%（deferred-final-gate；与 Plan 03-02 Task 6 合并后预期 ≥80%）

### 3. 技术决策

- 使用 Mocktail 手写 fake 类（不使用 Mockito codegen），为 Phase 4 HIGH-07 建立先例
- `_FakePushNotificationService extends Mock`（非 Fake）以支持 `takePendingNavigationIntent()` 和 `navigationIntents` stream
- 同时 override `familySyncNotificationNavigationProvider` 避免 `FamilySyncNotificationRouteListener` 在 test 中抛出错误
- `appDatabaseProvider` 使用 `AppDatabase.forTesting()` 而非真实 SQLCipher

### 4. 代码变更统计

- 新增文件：5 个测试文件 + 1 个 SUMMARY.md + 1 个 worklog
- 共创建约 900 行测试代码

---

## 遇到的问题与解决方案

### 问题 1: FamilySyncNotificationRouteListener 抛出 UnimplementedError

**症状:** `MainShellScreen` pump 时 `_FakePushNotificationService.takePendingNavigationIntent()` 抛出 `UnimplementedError`

**原因:** `_FakePushNotificationService extends Fake` 不提供方法实现，但 `FamilySyncNotificationRouteListener` 内部的 `FamilySyncNotificationNavigationController` 在构造时立即调用 `service.takePendingNavigationIntent()`

**解决方案:**
1. 改用 `extends Mock` 让 Mocktail 拦截所有调用
2. 明确 override `takePendingNavigationIntent()` 返回 null
3. override `navigationIntents` 返回空 stream
4. 同时 override `familySyncNotificationNavigationProvider` 使用已有的 fake service 实例

### 问题 2: providers.dart 覆盖率仅 66.67%

**症状:** `biometricServiceProvider`（line 26-28）和 `biometricAvailabilityProvider`（line 32-35）完全未被覆盖

**原因:** 初版 providers_characterization_test.dart 只覆盖了 appDatabase 和 auditLogger/secureStorage 的 provider

**解决方案:** 添加 2 个新 test group：biometricServiceProvider（直接读取，验证返回 BiometricService 实例）和 biometricAvailabilityProvider（通过 biometricServiceProvider override 注入 `_FakeBiometricService`，验证 future 解析）

### 问题 3: lint 提示 no_leading_underscores_for_local_identifiers

**症状:** flutter analyze 报告 `_successOverrides` 违反 lint 规则

**解决方案:** 重命名为 `buildSuccessOverrides`（单独 commit 修复）

---

## 测试验证

- [x] 单元测试通过（1001 tests ALL GREEN）
- [x] deactivate_group_use_case: 100% 覆盖率
- [x] regenerate_invite_use_case: 100% 覆盖率
- [x] remove_member_use_case: 100% 覆盖率
- [x] infrastructure/security/providers.dart: 100% 覆盖率
- [ ] lib/main.dart: 59.74%（deferred-final-gate；等待 Plan 03-02 Task 6）
- [x] flutter analyze --no-fatal-infos: 0 issues
- [x] dart run custom_lint: 91 issues（全部预先存在；Plan 03-05 未引入新问题）

---

## Git 提交记录

```
4659b99 test(03-05): add characterization test for deactivate_group_use_case
a6bc096 test(03-05): add characterization test for regenerate_invite_use_case
42eaa2b test(03-05): add characterization test for remove_member_use_case
d376e56 test(03-05): add characterization test for security/providers.dart
4783e5f test(03-05): add smoke characterization test for main.dart
86c7efa style(03-05): rename _successOverrides (lint fix)
ac0b562 test(03-05): add biometric providers coverage to providers_characterization_test
735f676 docs(03-05): complete characterization tests plan summary
```

---

## 后续工作

- [ ] Plan 03-02 Task 6 完成后运行 combined coverage gate for lib/main.dart
- [ ] Plan 03-01 Task 4 (audit.yml flip) 等待 combined coverage gate 通过
- [ ] Plan 03-03 Tasks 2/4/5 需在 git mv 时同步更新 `_characterization_test.dart` 中的 import 路径

---

## 参考资源

- `.planning/phases/03-critical-fixes/03-CONTEXT.md` - D-15: tests written before refactors
- `.planning/phases/03-critical-fixes/03-05-characterization-tests-PLAN.md` - 计划详情
- `.planning/phases/03-critical-fixes/03-05-characterization-tests-SUMMARY.md` - 执行摘要

---

**创建时间:** 2026-04-26 16:13
**作者:** Claude Sonnet 4.6
