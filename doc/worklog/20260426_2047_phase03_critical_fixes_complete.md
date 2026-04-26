# Phase 3: CRITICAL Fixes — Complete

**日期:** 2026-04-26
**时间:** 20:47
**任务类型:** 重构
**状态:** 已完成
**相关模块:** Phase 3 — Critical Fixes (全部5个计划)

---

## 任务概述

执行 GSD Phase 3 "critical-fixes"，关闭所有24个CRITICAL级别的层违规发现（LV-001..LV-024）及CRIT-03（appDatabaseProvider抛出UnimplementedError运行时崩溃）。采用Wave并行执行策略：Wave 1 并行运行4个plan，Wave 2 单独运行最大的plan（03-02）。

---

## 完成的工作

### Wave 1 — 4个计划并行 (03-01, 03-03, 03-04, 03-05)

**Plan 03-01: Domain Import Guard Rules**
- 为6个feature的domain/目录添加`import_guard.yaml`规则文件
- 为domain/models/和domain/repositories/添加per-subdir allow白名单
- 新建`test/architecture/domain_import_rules_test.dart`（18个架构元测试）
- 关闭 LV-001..LV-016, LV-023, LV-024（18个CRITICAL发现）

**Plan 03-03: Use Cases Migration**
- 将5个family_sync use_case从`lib/features/family_sync/use_cases/`迁移到`lib/application/family_sync/`
- 更新所有presentation层的import路径
- 关闭 LV-017..LV-021 + CRIT-02

**Plan 03-04: LedgerRowData Presentation Move**
- 将`ledger_row_data.dart`从`domain/models/`移到`presentation/models/`
- 关闭 LV-022

**Plan 03-05: Characterization Tests**
- 为5个文件写表征测试（pre-refactor行为锁定）
- `deactivate_group_use_case_characterization_test.dart`
- `regenerate_invite_use_case_characterization_test.dart`
- `remove_member_use_case_characterization_test.dart`
- `providers_characterization_test.dart`
- `main_characterization_smoke_test.dart`

### Post-Wave 1: 修复合并后的import路径冲突
- 03-05的表征测试使用了旧路径（features/family_sync/use_cases），03-03已移动文件
- 修复3个测试文件的import路径，flutter analyze 0错误

### Wave 2 — Plan 03-02: AppInitializer + Database Provider (内联执行)

**Task 1: ARB keys**
- 3个key × 3个locale: initFailedTitle, initFailedMessage, initFailedRetry
- `flutter gen-l10n`重新生成

**Task 2: InitResult Freezed密封类**
- `lib/core/initialization/init_result.dart`
- `enum InitFailureType { masterKey, database, seed, unknown }`
- 8个单元测试

**Task 3: AppInitializer**
- `lib/core/initialization/app_initializer.dart`
- 构造函数注入: ProviderContainerFactory, AppDatabaseFactory, SeedRunner
- 14个单元测试（覆盖率96.7%）

**Task 4: appDatabaseProvider修复**
- `@Riverpod(keepAlive: true)` + `StateError`诊断替换`UnimplementedError`
- `test/helpers/test_provider_scope.dart`: createTestProviderScope()助手
- 7个单元测试

**Task 5: InitFailureScreen**
- `lib/core/initialization/init_failure_screen.dart`: StatefulWidget
- 本地化via S.of(context)，重试按钮带加载状态
- 9个widget测试（3 locale × strings, retry, loading, icon, background）

**Task 6: main.dart重写**
- `main()` → `_boot()` → `AppInitializer.initialize()` → sealed switch on InitResult
- 失败路径渲染`InitFailureApp(onRetry: _boot)`

**Task 7: 退出门检查**
- flutter analyze: 0 error, 0 warning ✅
- dart run custom_lint: 19 INFO（预存在）✅
- flutter test: 1070/1070 ✅

### Phase 3 Close: D-17 audit.yml blocking flip
- `dart run custom_lint`步骤移除`continue-on-error: true`
- 关闭Phase 3，`import_guard`现在在CI中为阻塞性

---

## 遇到的问题与解决方案

### 问题 1: Wave 1执行后import路径冲突
**症状:** 合并后flutter analyze显示37个错误
**原因:** 03-05写了旧路径的import，03-03移动了源文件
**解决方案:** 修复3个测试文件的import路径

### 问题 2: AppInitializer测试中需要override两个provider
**症状:** keyManagerProvider通过flutter_secure_storage失败
**原因:** keyManagerProvider依赖keyRepositoryProvider（不是masterKeyRepositoryProvider）
**解决方案:** 在test factory中同时override masterKeyRepositoryProvider和keyRepositoryProvider

### 问题 3: DeviceKeyPair构造函数参数错误
**症状:** publicKeyBase64参数不存在
**原因:** 实际参数是publicKey+createdAt
**解决方案:** 查看DeviceKeyPair定义后修正

---

## 测试验证

- [x] 单元测试通过 (1070/1070)
- [x] 代码审查通过 (verifier: 5/5 ROADMAP成功标准)
- [x] flutter analyze 0 error/warning
- [x] dart run custom_lint exit 0
- [x] VERIFICATION.md 已生成

---

## Git 提交记录

```
38e6605 docs(phase-03): mark Phase 3 complete in ROADMAP + STATE
f95497d feat(03): flip import_guard to blocking — Phase 3 close (D-17)
9003d29 docs(state): Phase 03 all 5 plans complete, entering verification
3ce5ade docs(03-02): write plan SUMMARY, close CRIT-03 (Task 7)
bff5797 fix: remove unused cryptography import from app_initializer_test
0326dce feat(03-02): delegate main() to AppInitializer + sealed switch on InitResult (D-06, Task 6)
610a189 feat(03-02): InitFailureScreen StatefulWidget + 9 widget tests (D-07, D-08, Task 5)
509e063 feat(03-02): fix appDatabaseProvider StateError + createTestProviderScope + 7 tests (CRIT-03, Task 4)
06adfae feat(03-02): AppInitializer constructor-injected + 14 unit tests (D-05, D-08, Task 3)
f537d72 feat(03-02): InitResult Freezed sealed class + 8 unit tests (D-04, Task 2)
d675403 feat(03-02): add 3 ARB keys + flutter gen-l10n for InitFailureScreen (D-07, Task 1)
```

---

## 后续工作

- [ ] Phase 4: HIGH Fixes — 下一阶段（HIGH级别发现修复）
- [ ] 可选: 写worklog报告Phase 3执行摘要

---

**创建时间:** 2026-04-26 20:47
**作者:** Claude Sonnet 4.6
