---
phase: quick-260802-mkd
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/application/family_sync/group_operation_error.dart
  - lib/application/family_sync/create_group_use_case.dart
  - lib/application/family_sync/check_group_use_case.dart
  - lib/features/family_sync/presentation/widgets/family_network_unavailable_dialog.dart
  - lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart
  - lib/features/family_sync/presentation/screens/create_group_screen.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - test/unit/application/family_sync/group_operation_error_test.dart
  - test/widget/features/family_sync/presentation/screens/create_group_screen_test.dart
  - test/widget/features/family_sync/presentation/widgets/family_sync_settings_section_test.dart
autonomous: true
requirements: [FAMILY-OFFLINE-UX]
---

<objective>
启动后首次进入家庭同步、或创建家庭时网络不可用，不再向用户显示
`ClientException` / `SocketException` 等底层错误；改为本地化的友好弹窗，保留当前输入并支持取消或重试。
</objective>

<tasks>

<task type="auto">
  <name>Task 1: 传输异常分类与 RED 测试</name>
  <files>lib/application/family_sync/group_operation_error.dart, lib/application/family_sync/create_group_use_case.dart, lib/application/family_sync/check_group_use_case.dart, test/unit/application/family_sync/group_operation_error_test.dart</files>
  <action>增加 networkUnavailable 错误类型，统一识别 SocketException、HTTP ClientException 与 TimeoutException；创建/检查家庭用例只返回稳定错误类型，不泄漏底层异常文本。</action>
  <verify><automated>flutter test test/unit/application/family_sync/group_operation_error_test.dart test/unit/application/family_sync/create_group_use_case_test.dart test/unit/application/family_sync/check_group_use_case_test.dart</automated></verify>
  <done>传输异常被映射为 networkUnavailable，其他业务错误保持原语义。</done>
</task>

<task type="auto">
  <name>Task 2: 家庭入口与创建页友好弹窗</name>
  <files>lib/features/family_sync/presentation/widgets/family_network_unavailable_dialog.dart, lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart, lib/features/family_sync/presentation/screens/create_group_screen.dart, lib/l10n/app_en.arb, lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, test/widget/features/family_sync/presentation/screens/create_group_screen_test.dart, test/widget/features/family_sync/presentation/widgets/family_sync_settings_section_test.dart</files>
  <action>新增统一网络不可用弹窗；家庭入口检查失败时留在当前页，创建失败时保留草稿，不切换到全屏错误态；弹窗提供取消和重试，且三语文案同步。</action>
  <verify><automated>flutter gen-l10n &amp;&amp; flutter test test/widget/features/family_sync/presentation/screens/create_group_screen_test.dart test/widget/features/family_sync/presentation/widgets/family_sync_settings_section_test.dart &amp;&amp; flutter analyze</automated></verify>
  <done>界面不显示技术异常，取消后保持可编辑，重试会重新发起操作。</done>
</task>

</tasks>

<verification>
- 三语 ARB parity 与 generated l10n 成功。
- 创建家庭和家庭入口的针对性 widget 测试通过。
- 相关 unit 测试与 flutter analyze 通过。
</verification>

<success_criteria>
- 无网络/网络权限受限时只显示友好、本地化提示。
- 任何用户可见文本均不包含 ClientException、SocketException、host lookup 或服务 URI。
- 用户可以取消并保留当前上下文，或直接重试。
</success_criteria>

<output>
Create `.planning/quick/260802-mkd-friendly-offline-family-error/260802-mkd-SUMMARY.md` when done.
</output>
