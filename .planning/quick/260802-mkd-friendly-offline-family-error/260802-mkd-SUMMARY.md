---
phase: quick-260802-mkd
plan: 01
subsystem: family-sync
tags: [flutter, family-sync, offline, error-handling, i18n]
requirements: [FAMILY-OFFLINE-UX]
status: complete
provides:
  - "Family relay transport failures are classified without leaking exception details"
  - "Localized cancel/retry network dialog for family entry and group creation"
  - "Draft-preserving retry behavior on create-group network failure"
tech_stack:
  added: []
  patterns:
    - "Application-layer typed error kind drives presentation behavior"
    - "Shared presentation dialog returns an explicit retry decision"
key_files:
  created:
    - lib/features/family_sync/presentation/widgets/family_network_unavailable_dialog.dart
    - test/unit/application/family_sync/group_operation_error_test.dart
  modified:
    - lib/application/family_sync/group_operation_error.dart
    - lib/application/family_sync/create_group_use_case.dart
    - lib/application/family_sync/check_group_use_case.dart
    - lib/features/family_sync/presentation/screens/create_group_screen.dart
    - lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
decisions:
  - "Offline startup remains local-first; only family relay operations prompt for connectivity"
  - "Network errors keep the current screen and user input instead of entering a full-screen error state"
  - "Technical exception text and relay URLs never cross the application-to-presentation boundary"
metrics:
  completed_date: "2026-08-02"
  tasks_completed: "2 of 2"
  tests: "4320 passed, 11 skipped, 0 failed"
  commit: "not created — relevant files contained pre-existing overlapping user changes"
---

# Quick 260802-mkd: Friendly offline family error Summary

首次进入家庭同步进行服务端状态检查、以及创建家庭进行设备注册时，网络不可用现在会显示三语友好弹窗。弹窗说明需要检查网络和本应用的数据权限，提供取消与重试；创建页不会切换到截图中的技术错误页面，已输入的家庭名称会保留。

## Completed work

- `SocketException`、`http.ClientException`、`TimeoutException` 及常见包装形式统一映射为 `GroupOperationErrorKind.networkUnavailable`。
- `CreateGroupUseCase` 与 `CheckGroupUseCase` 对网络错误仅返回稳定的 `Network unavailable` 内部消息，不暴露 host、URI 或系统异常。
- 新增共享 `family_network_unavailable_dialog.dart`，使用 ja/zh/en ARB 文案与取消/重试动作。
- 家庭入口检查失败时留在当前设置页；创建失败时保留草稿，用户点击重试后重新执行创建。
- 普通服务端/业务错误以及单家庭冲突的现有行为保持不变。

## Verification

- RED：新增测试最初因缺少 `networkUnavailable` 类型、分类函数和弹窗而编译失败。
- GREEN：应用层相关 unit tests 全绿。
- 创建页与家庭入口 widget tests 全绿，断言界面不出现 `ClientException`、域名或请求 URI。
- `flutter gen-l10n` 成功。
- ARB parity 与 hardcoded-CJK architecture tests 全绿。
- `flutter analyze`：0 issues。
- `flutter test`：4320 passed、11 skipped、0 failed。

## Commit note

未创建 git commit。任务开始前，相关家庭同步源文件、ARB、generated l10n 和测试已包含大量未提交修改，且 `group_operation_error.dart` 与创建页测试本身是未跟踪的用户文件。提交这些路径会把既有工作夹带进本任务，因而按工作区保护规则保留为未提交改动。

## Self-check

PASSED — 功能与自动化门禁均完成；唯一未满足的 GSD quick 机械步骤是出于现有脏工作树保护而跳过提交。
