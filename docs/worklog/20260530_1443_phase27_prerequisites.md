# Phase 27 Plan 01: Prerequisites Setup

**日期:** 2026-05-30
**时间:** 14:43
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** Phase 27 — Calendar Header + Month Summary

---

## 任务概述

为 Phase 27 后续计划（27-02 calendarTotalsProvider、27-03 ListCalendarHeader widget）添加必要前置条件：table_calendar 依赖、三语言 ARB placeholder keys、AppInitializer 中的 initializeDateFormatting 调用、widgets/ 目录，以及 Wave 0 编译通过的测试桩文件。

---

## 完成的工作

### 1. 主要变更

- **pubspec.yaml**: 在 `t` 字母顺序位置添加 `table_calendar: ^3.2.0`；`intl: 0.20.2` pin 未更改
- **lib/l10n/app_{ja,en,zh}.arb**: 每个文件各添加 3 个 ARB keys：
  - `calMonthTotal`: 今月の支出 / Monthly Spend / 本月支出
  - `calDayTotal`: `{date}の支出` / `{date} Spend` / `{date}支出`（带 placeholder metadata）
  - `calLoadError`: データを読み込めません / Unable to load data / 无法加载数据
- **lib/core/initialization/app_initializer.dart**: 在 `initialize()` 方法顶部添加 `await initializeDateFormatting()`，import `package:intl/date_symbol_data_local.dart`
- **lib/features/list/presentation/widgets/.gitkeep**: 创建 widgets/ 目录供 Plan 27-03 使用
- **test/unit/.../calendar_totals_provider_test.dart**: 5 个 Wave 0 测试桩（calendarTotalsProvider）
- **test/widget/.../list_calendar_header_test.dart**: 3 个 Wave 0 测试桩（ListCalendarHeader）

### 2. 技术决策

- `initializeDateFormatting()` 无参数（初始化所有 locale）而非只初始化特定 locale，保证 table_calendar 在 ja/zh 下的星期几标题正确渲染
- calDayTotal 的 `{date}` placeholder 类型用 `String`（由调用方通过 DateFormatter 预格式化），遵循项目现有 ARB 约定
- Wave 0 桩文件用 `// ignore_for_file: unused_import, unused_element` 抑制 lint 警告，确保 flutter analyze 0 warnings

### 3. 代码变更统计

- 修改/创建文件：9 个（pubspec.yaml, pubspec.lock, 3 ARB, app_initializer.dart, .gitkeep, 2 test stubs）
- Task 1 commit: af35b82
- Task 2 commit: 9fe03ad
- Metadata commit: 48d65b2

---

## 遇到的问题与解决方案

### 问题 1: lib/generated/ 目录在 .gitignore 中

**症状:** `git add lib/generated/*.dart` 报 "ignored by .gitignore"
**原因:** 项目 .gitignore 排除 `lib/generated/`（生成文件不进入版本控制）
**解决方案:** 跳过 generated 文件，只提交 ARB 源文件，符合项目规范

### 问题 2: flutter analyze 报 Wave 0 桩的 unused_import/unused_element

**症状:** 3 个 warnings（unused import, 2× unused_element）
**原因:** Wave 0 桩中引入了 Plan 27-02/27-03 才会用到的 mock 类和 import
**解决方案:** 在两个桩文件顶部加 `// ignore_for_file: unused_import, unused_element`

---

## 测试验证

- [x] 单元测试通过：5 tests pass（calendar_totals_provider_test.dart）
- [x] widget 测试通过：3 tests pass（list_calendar_header_test.dart）
- [x] flutter analyze 0 errors, 0 warnings
- [x] flutter pub get exit 0，无依赖冲突
- [x] flutter gen-l10n exit 0，无 ARB 错误

---

## Git 提交记录

```bash
Commit: af35b82
feat(27-01): add table_calendar dep and ARB placeholder keys

Commit: 9fe03ad
feat(27-01): add initializeDateFormatting, widgets/ dir, Wave 0 test stubs

Commit: 48d65b2
docs(27-01): complete prerequisites plan — table_calendar, ARB keys, test stubs
```

---

## 后续工作

- [ ] Plan 27-02: 实现 calendarTotalsProvider（使用 AnalyticsRepository）
- [ ] Plan 27-03: 实现 ListCalendarHeader widget（使用 table_calendar ^3.2.0）
- [ ] Plan 27-04: 集成与最终验证

---

**创建时间:** 2026-05-30 14:43
**作者:** Claude Sonnet 4.6
