# Replace Hardcoded UI Strings with Localized Equivalents

**日期:** 2026-04-06
**时间:** 10:25
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MOD-014] i18n

---

## 任务概述

将三个文件中残留的硬编码英文字符串替换为通过 `S.of(context)` 调用的本地化等价项，确保 UI 文字全面支持 ja/zh/en 三语言。

---

## 完成的工作

### 1. 主要变更

**`lib/main.dart`**
- `_buildHome()` 改为接受 `BuildContext context` 参数
- `home:` 处改用 `Builder(builder: (context) => _buildHome(context))` 以获取 MaterialApp 树下的正确 context，使 `S.of(context)` 可用
- `AppBar(title: const Text('Error'))` → `AppBar(title: Text(S.of(context).error))`
- `Text(_error!)` → `Text(S.of(context).initializationError(_error!))` (positional 参数)

**`lib/features/home/presentation/screens/main_shell_screen.dart`**
- 添加 `import '../../../../generated/app_localizations.dart'`
- `const Center(child: Text('List'))` → `Center(child: Text(S.of(context).listTab))`
- `const Center(child: Text('Todo'))` → `Center(child: Text(S.of(context).todoTab))`
- 移除 `const` 修饰符（`S.of(context)` 不是编译期常量）

**`lib/features/home/presentation/screens/home_screen.dart`**
- 添加 `import '../../../../generated/app_localizations.dart'`
- `const SnackBar(content: Text('Date picker coming soon'))` → `SnackBar(content: Text(S.of(context).datePickerComingSoon))`
- `const Duration(seconds: 1)` 保持 const，移除外层 SnackBar 的 const

### 2. 技术决策

- **Builder 包装 `_buildHome`：** `MaterialApp.home:` 的 context 来自 `ConsumerStatefulWidget.build`，位于 MaterialApp 之上，`S.of(context)` 在该 context 中不可用。用 `Builder` 在 MaterialApp 子树内创建新 context，使本地化委托生效。
- **`initializationError` 使用 positional 参数：** ARB 文件定义了 placeholder `{error}`，但生成的 Dart 方法签名为 `String initializationError(String error)`（positional），不能用命名参数语法。

### 3. 代码变更统计
- 修改文件：3
- 净变更：+13 / -9 行

---

## 遇到的问题与解决方案

### 问题 1: initializationError 参数调用方式错误
**症状:** `flutter analyze` 报 `not_enough_positional_arguments` 和 `undefined_named_parameter`
**原因:** 初始调用使用了 `initializationError(error: _error!)` 命名参数语法
**解决方案:** 改为 positional 调用 `initializationError(_error!)`，与生成的方法签名一致

---

## 测试验证

- [x] 单元测试通过（878 tests passed）
- [x] `flutter analyze` 0 issues
- [ ] 集成测试（不适用）
- [ ] 手动测试验证（需设备）
- [x] 代码审查完成

---

## Git 提交记录

```
Commit: 290b43c
Date: 2026-04-06

fix: replace hardcoded UI strings with localized equivalents
```

---

## 后续工作

- 其余文件中仍存在少量硬编码日文字符串（如 `'今月の支出'`、`'帳 本'` 等），可在后续任务中逐步迁移到 ARB

---

**创建时间:** 2026-04-06 10:25
**作者:** Claude Sonnet 4.6
