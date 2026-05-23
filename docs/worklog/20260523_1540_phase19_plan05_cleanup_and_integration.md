# Phase 19 Plan 05: Close-Out Cleanup and Integration Tests

**日期:** 2026-05-23
**时间:** 15:40
**任务类型:** 测试/Bug修复/重构
**状态:** 已完成
**相关模块:** [MOD-001] BasicAccounting (ManualOneStepScreen, TransactionDetailsForm)

---

## 任务概述

Phase 19 的第 5 个（也是最后一个）计划，执行收尾工作：删除 3 个已废弃的 stale 测试文件（对应已删除的 TransactionEntryScreen 和 TransactionConfirmScreen），将商户学习测试重新指向 ManualOneStepScreen，补充 SC-4 集成测试（entry_source='manual' DB 写入验证），以及 D-16 语音流向回归测试（entry_source='voice' 端到端验证）。最后执行 Phase 19 完整收尾门控。

---

## 完成的工作

### 1. Task 1 — 删除 stale 测试文件 + 修复 Dartdoc + 预存在分析器问题

- `git rm` 3 个 stale 测试文件：
  - `test/widget/.../transaction_entry_screen_test.dart`
  - `test/unit/.../transaction_entry_screen_characterization_test.dart`
  - `test/unit/.../transaction_confirm_screen_characterization_test.dart`
- 修复 `lib/application/voice/record_category_correction_use_case.dart` Dartdoc：将 "TransactionConfirmScreen" 替换为 "ManualOneStepScreen (or any other host that mounts TransactionDetailsForm with a voiceKeyword)"
- 修复预存在分析器警告：`entry_widgets_dark_mode_test.dart` 中 SmartKeyboard 缺少 `actionLabel` 参数；`transaction_details_form_update_amount_test.dart` 中删除未使用的 mock 类

### 2. Task 2 — 重定向商户学习测试 + 恢复缺失的 hook

- 将 `transaction_confirm_screen_merchant_learning_test.dart` 完整重写，将被测宿主从已删除的 TransactionConfirmScreen 替换为 ManualOneStepScreen
- **关键发现（Rule 2）：** 商户学习 hook（`merchantCategoryLearningService.recordSelection()`）在旧 TransactionConfirmScreen 中存在，但在 Phase 18/19 重构时未迁移到 TransactionDetailsForm。在 `transaction_details_form.dart` 的 `submit()` 方法中补充了该 hook（$new 分支，CreateTransactionUseCase 成功后调用）

### 3. Task 3 — SC-4 集成测试（TDD RED→GREEN）

- 新建 `test/integration/features/accounting/manual_save_entry_source_test.dart`
- 使用真实 `AppDatabase.forTesting()` + 真实 `CreateTransactionUseCase`（mock 加密服务）
- 验证 ManualOneStepScreen 保存路径将 `entry_source='manual'` 写入 Drift DB
- 幂等性测试：以 `EntrySource.voice` 构造时写入 `entry_source='voice'`
- 关键技术点：必须覆盖 `appDatabaseProvider`，否则 locale/settings provider chain 会抛 StateError

### 4. Task 4 — D-16 语音回归测试（TDD RED→GREEN）

- 新建 `test/widget/.../voice_to_manual_one_step_screen_test.dart`
- TEST 1 (D-16)：VoiceInputScreen → ManualOneStepScreen 导航，验证 `entrySource=voice`，DB 写入 `entry_source='voice'`, `amount=1200`
- TEST 2：VoiceInputScreen 传参验证（amount=800, initialCategory, initialMerchant='Starbucks'）
- TEST 3 (D-15 soul)：使用 `_MockCategoryService` 返回 `LedgerType.soul`，验证 DB 同时写入 `entry_source='voice'` 和 `ledger_type='soul'`

### 5. Task 5 — Phase 完整门控

- flutter analyze: PASS (0 源码错误/警告)
- flutter test: 1732 passed, 11 failed (均为预存在的 `home_hero_card_golden_test.dart`，与 Phase 19 无关)
- 生产代码 grep: 无 TransactionConfirmScreen/TransactionEntryScreen 引用
- ARB parity: `keyboardToolbarDone` 存在于全部 3 个 ARB 文件
- pubspec.yaml/pubspec.lock 未变更
- flutter gen-l10n 正常
- 6 个 SmartKeyboard golden PNG 基准存在
- build_runner 无生成文件漂移

### 2. 技术决策

- **商户学习 hook 归属：** 决定在 `TransactionDetailsForm.submit()` 中加入 hook，而非在 ManualOneStepScreen 的某个回调中处理，因为 TransactionDetailsForm 是封装完整保存逻辑的组件，与旧 TransactionConfirmScreen 的职责对应。
- **集成测试用 initialCategory 跳过异步加载：** ManualOneStepScreen 的 `_canSave` 保护需要 `_selectedCategory != null`；通过传入 `initialCategory` 参数在组件构造时设置，避免测试依赖异步的分类初始化流程（P19-W1）。
- **appDatabaseProvider 覆盖策略：** 即使已通过 `createTransactionUseCaseProvider.overrideWithValue(useCase)` 提供了真实 use case，仍需要 `appDatabaseProvider.overrideWithValue(db)` 覆盖，因为 `settingsRepositoryProvider → currentLocaleProvider` 链路也依赖 `appDatabaseProvider`。

### 3. 代码变更统计

- 修改文件：12 个
- 新建文件：2 个（集成测试 + 语音回归测试）
- 删除文件：3 个（stale 测试文件）
- 提交数：6 个

---

## 遇到的问题与解决方案

### 问题 1: 商户学习 hook 未迁移（Plan 描述误导性）
**症状:** 计划说"仅替换 pump widget 中的屏幕类"，但测试运行时 `verify(learningService.recordSelection(...)).called(1)` 失败
**原因:** hook 原在 TransactionConfirmScreen，未迁移到 TransactionDetailsForm
**解决方案:** 应用 Rule 2（缺失关键功能）自动修复，在 TransactionDetailsForm.submit() 中添加 hook

### 问题 2: appDatabaseProvider 未覆盖引发 StateError
**症状:** 集成测试启动时崩溃 "appDatabaseProvider was not overridden"
**原因:** Locale/Settings provider chain 最终依赖 appDatabaseProvider，而集成测试中 ProviderScope 需要明确覆盖它
**解决方案:** 添加 `appDatabaseProvider.overrideWithValue(db)` 到测试的 overrides 列表

### 问题 3: 语音 TEST 3 的 ledgerType 默认值为 'survival'
**症状:** DB 写入 `ledger_type='survival'` 而非 'soul'
**原因:** `categoryServiceProvider` 未覆盖，真实 CategoryService 在测试 DB 中找不到 CategoryLedgerConfig 行，返回 null，最终默认为 survival
**解决方案:** 创建 `_MockCategoryService`，覆盖 `categoryServiceProvider`，使其始终返回 `LedgerType.soul`

### 问题 4: 预存在 golden 测试失败（11 个）
**症状:** `flutter test` 报告 11 个 `home_hero_card_golden_test.dart` 失败
**原因:** 预存在问题，在 Phase 19 Plan 05 开始前（基线提交 51ae327）即已失败
**解决方案:** 确认预存在后记录于 `deferred-items.md`，不在 Phase 19 范围内修复

---

## 测试验证

- [x] 单元测试通过（flutter analyze 0 issues）
- [x] 集成测试通过（manual_save_entry_source_test.dart 2 个测试全绿）
- [x] 语音回归测试通过（voice_to_manual_one_step_screen_test.dart 3 个测试全绿）
- [x] 商户学习测试通过（transaction_confirm_screen_merchant_learning_test.dart 重构后全绿）
- [x] 全套 flutter test 1732 passed（11 预存在 golden 失败已确认并记录）
- [x] build_runner 生成文件无漂移
- [x] flutter gen-l10n 正常
- [x] git status 干净

---

## Git 提交记录

```
dae45b2 chore(19-05): Task 1 — delete stale test files + fix Dartdoc + pre-existing analyzer fixes
757bde7 feat(19-05): Task 2 — retarget merchant-learning test + restore missing hook in form
7271da7 test(19-05): Task 3 — SC-4 integration test: ManualOneStepScreen save stamps entry_source
cead93e test(19-05): Task 4 — D-16 voice regression test: entrySource=voice preserved end-to-end
3e32069 chore(19-05): Task 5 — gate cleanup: fix comment reference + remove unused import
517807e docs(19-05): record pre-existing golden test failures as deferred
```

---

## 后续工作

- [ ] Phase 19 完成，主分支 merge 后可执行 home_hero_card_golden_test.dart 基准重建（独立 polish phase）
- [ ] `TransactionDetailsForm.submit()` 的商户学习 hook 已补全，可在 Phase 20+ 考虑增加 unit test 专门覆盖该 hook 路径

---

## 参考资源

- Phase 19 Plan 05: `.planning/phases/19-manual-one-step-keypad-polish/19-05-PLAN.md`
- Phase 19 SUMMARY: `.planning/phases/19-manual-one-step-keypad-polish/19-05-SUMMARY.md`
- Deferred items: `.planning/phases/19-manual-one-step-keypad-polish/deferred-items.md`
- RESEARCH Pitfall 4: stale tests for deleted screens (from 19-RESEARCH.md)

---

**创建时间:** 2026-05-23 15:40
**作者:** Claude Sonnet 4.6
