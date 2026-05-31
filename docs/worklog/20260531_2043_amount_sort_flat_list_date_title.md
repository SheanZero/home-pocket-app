# 列表按金额排序全量排序、隐藏日期组、标题改为日期+类目

**日期:** 2026-05-31
**时间:** 20:43
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** List Feature — Presentation Layer

---

## 任务概述

当用户将交易列表的排序方式改为「金额」（SortField.amount）时，列表必须渲染为全量排序的扁平列表：不再按日期分组，不显示日期组标题（DayHeaderItem），每个条目的标题从「二级类目」改为「日期 + 二级类目」（例如 `5月31日 餐飲`）。排序方式为「日期」时，已有的分组行为完全保持不变。

---

## 完成的工作

### 1. 主要变更

- **`lib/features/list/presentation/screens/list_screen.dart`**
  - 新增 `import '../../../../shared/constants/sort_config.dart'` 引入 `SortField`
  - 在 `_buildList` 的 `data:` 分支中，对 `filter.sortConfig.sortField` 做条件分支：
    - `SortField.amount`：直接以 `txs`（已排序的 `List<TaggedTransaction>`）构建 `ListView.builder`，跳过 `buildFlatList`，不注入任何 `DayHeaderItem`；每个 tile 传入 `showDate: true`
    - `SortField.timestamp`（默认）：保留原有 `buildFlatList` 分组路径，完全不改动
  - `_buildTile` 签名：参数 `items` 类型改为 `List<dynamic>`（兼容两种模式），新增具名参数 `{bool showDate = false}`
  - `_buildTile` 构造 `ListTransactionTile` 时传入 `locale: locale, showDate: showDate`
  - 分割线逻辑：`showDate ? nextItem != null : nextItem is TransactionRowItem`（amount 模式下除最后一行外始终显示分割线）

- **`lib/features/list/presentation/widgets/list_transaction_tile.dart`**
  - 新增 `import '../../../../infrastructure/i18n/formatters/date_formatter.dart'`
  - 构造函数新增 `required this.locale`（`Locale`）和 `this.showDate = false`（`bool`）
  - 标题 `Text` 内容：`showDate` 为 true 时，渲染 `'${DateFormatter.formatShortMonthDay(taggedTx.transaction.timestamp, locale)} $category'`；否则保持原有 `category` 字符串

- **测试文件修复**（Rule 2 — 新增必填参数）
  - `test/golden/list_transaction_tile_golden_test.dart`：新增 `locale: const Locale('ja')`
  - `test/widget/features/list/list_transaction_tile_test.dart`：新增 `locale: const Locale('ja')`

### 2. 技术决策

- `_buildTile` 的 `items` 参数改为 `List<dynamic>` 而非保持 `List<ListItem>`，以便 amount 模式传入 `List<TaggedTransaction>`，只用于长度判断（分割线 lookahead）；不影响类型安全，因为在 timestamp 模式下 `nextItem is TransactionRowItem` 检查依然有效
- 日期格式化使用现有 `DateFormatter.formatShortMonthDay`（ja/zh → `M月d日`，en → `MMM d`），不引入新的 ARB key 或硬编码字符串

### 3. 代码变更统计

- 修改文件：4 个（2 个生产代码 + 2 个测试文件）
- 新增文件：0 个
- 删除文件：0 个

---

## 遇到的问题与解决方案

### 问题 1: 测试文件缺少新增的必填参数 `locale`

**症状:** 全量 `flutter analyze` 报告 2 个 error —— `test/golden/list_transaction_tile_golden_test.dart` 和 `test/widget/features/list/list_transaction_tile_test.dart` 各缺少 `locale:` 实参  
**原因:** `ListTransactionTile` 新增了 `required this.locale`，两个测试文件的构造调用未同步更新  
**解决方案:** 在两处 `ListTransactionTile(...)` 调用中添加 `locale: const Locale('ja')`（测试场景固定用日语，与生产行为一致）

---

## 测试验证

- [x] 单元/Widget 测试通过 (2238/2238 `flutter test`)
- [x] Golden 测试通过（`test/golden/` 全部 43 项通过，无需重新基线）
- [x] `flutter analyze` 无新增 issue（4 个 pre-existing 第三方 info/warning，与本次改动无关）
- [x] `dart format` 无剩余 diff

---

## Git 提交记录

```
Commit: ae85734e
Date:   2026-05-31

feat(260531-se5): flat amount-sort list with date-prefixed tile title

- When sortField == SortField.amount: render a flat ListView.builder
  directly over the globally-sorted txs — no buildFlatList, no
  DayHeaderItem rows (D-01 flat mode)
- When sortField == SortField.timestamp: existing grouped-by-day path
  unchanged (day headers shown, tile title = L2 category only)
- ListTransactionTile gains showDate (default false) and locale params;
  when showDate is true, title = "M月d日 category" / "MMM d category"
  via DateFormatter.formatShortMonthDay (D-02 date prefix)
- _buildTile receives showDate bool; divider logic adapted for both modes
- Fixed tests: locale: const Locale('ja') added to both tile call sites
```

---

## 后续工作

无 — 任务完全交付，无遗留 stub 或 TODO。

---

## 参考资源

- 任务计划：`.planning/quick/260531-se5-amount-sort-flat-date-title/260531-se5-PLAN.md`
- 任务总结：`.planning/quick/260531-se5-amount-sort-flat-date-title/260531-se5-SUMMARY.md`
- DateFormatter 规范：`lib/infrastructure/i18n/formatters/date_formatter.dart`

---

**创建时间:** 2026-05-31 20:43
**作者:** Claude Sonnet 4.6
