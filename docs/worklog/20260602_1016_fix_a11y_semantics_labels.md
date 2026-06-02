# Fix Stale a11y Semantics Labels (W1 — Phase 35 Plan 01)

**日期:** 2026-06-02
**时间:** 10:16
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** List Tab — ListSortFilterBar widget

---

## 任务概述

修复了列表页排序/筛选栏中两个无障碍（Accessibility）Semantics 标签使用了硬编码的过时字符串（`'Survival ledger'` 和 `'Soul ledger'`），改为通过 l10n（`l10n.listLedgerDaily` / `l10n.listLedgerJoy`）动态获取。这是 v1.5 里程碑审计发现的最后一个屏幕阅读器词汇泄漏点（W1）。

---

## 完成的工作

### 1. 主要变更

- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart`
  - Line 235: `Semantics(label: 'Survival ledger', ...)` → `Semantics(label: l10n.listLedgerDaily, ...)`
  - Line 268: `Semantics(label: 'Soul ledger', ...)` → `Semantics(label: l10n.listLedgerJoy, ...)`

### 2. 技术决策

- 无需新增 ARB key：`listLedgerDaily` 和 `listLedgerJoy` 已存在于全部 3 个语言文件（ja/zh/en）
- 无需运行 `flutter gen-l10n`（未修改任何 `.arb` 文件）
- `l10n` 变量已在 `build()` 方法 line 127 赋值（`final l10n = S.of(context);`），在两个 Semantics 调用点均在作用域内

### 3. 代码变更统计

- 修改文件：1 (`list_sort_filter_bar.dart`)
- 逻辑行变更：2 行（替换字符串字面量为 l10n 引用）
- `dart format` 同时规范化了若干既有空白（`_showSortMenu` 签名、`anyFilterActive` 表达式），属正常格式化行为

---

## 遇到的问题与解决方案

无 — 变更直接、清晰，无需额外调试。

---

## 测试验证

- [x] `grep -rn "'Survival ledger'\|'Soul ledger'" lib/` → 0 结果 ✓
- [x] `grep -n "listLedgerDaily\|listLedgerJoy" list_sort_filter_bar.dart` → 4 处命中（2 Semantics + 2 Text）✓
- [x] `flutter analyze` → 0 新增 issue（4 个预存 info 均在无关文件）✓
- [x] `dart format` 应用 ✓

---

## Git 提交记录

```
Commit: 9d39076e
Date: 2026-06-02

fix(35-01): replace hardcoded Semantics labels with l10n values

- 'Survival ledger' → l10n.listLedgerDaily (line 235)
- 'Soul ledger' → l10n.listLedgerJoy (line 268)
- No new ARB keys; no flutter gen-l10n needed
- flutter analyze: 0 new issues

Commit: d61e2f01
Date: 2026-06-02

docs(35-01): complete W1 a11y Semantics labels fix plan
```

---

## 后续工作

- [ ] Phase 35 Plan 02: W2 — totalSoulTx 标识符重命名（下一个执行计划）

---

**创建时间:** 2026-06-02 10:16
**作者:** Claude Sonnet 4.6
