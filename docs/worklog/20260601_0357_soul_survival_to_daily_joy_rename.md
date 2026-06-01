# Phase 31 Plan 05: Soul/Survival → Daily/Joy Widest-Ring Rename

**日期:** 2026-06-01
**时间:** 03:57
**任务类型:** 重构
**状态:** 已完成
**相关模块:** Phase 31 — Terminology Rename

---

## 任务概述

完成 D-01 "最宽环" 文件/类/字段重命名：将所有 `soul*/survival*` Dart 源文件 git mv 到 `daily/joy` 名称（保留历史），重命名约 16 个类/类型名称和 24 个快照字段引用，同步更新内部字面量，翻转测试固件中的 ledger-type 字符串，并按 D-19 执行术语驱动的 golden 像素重基线。

---

## 完成的工作

### 1. 文件重命名（git mv 保留历史）

**lib/ 源文件（7个）:**
- `get_soul_vs_survival_snapshot_use_case.dart` → `get_daily_vs_joy_snapshot_use_case.dart`
- `get_soul_vs_survival_snapshot_across_books_use_case.dart` → `get_daily_vs_joy_snapshot_across_books_use_case.dart`
- `get_per_category_soul_breakdown_use_case.dart` → `get_per_category_joy_breakdown_use_case.dart`
- `get_per_category_soul_breakdown_across_books_use_case.dart` → `get_per_category_joy_breakdown_across_books_use_case.dart`
- `per_category_soul_breakdown.dart` → `per_category_joy_breakdown.dart`
- `soul_vs_survival_card.dart` → `daily_vs_joy_card.dart`
- `soul_celebration_overlay.dart` → `joy_celebration_overlay.dart`

**测试文件（8个）+ Golden PNG（4个）:** 同步重命名

### 2. 类/类型/字段重命名（~16个类 + 24个字段）

- `SoulVsSurvivalSnapshot` → `DailyVsJoySnapshot` (字段: soul/survival/familySoul/familySurvival → joy/daily/familyJoy/familyDaily)
- `SoulLedgerSnapshot` → `JoyLedgerSnapshot`
- `SurvivalLedgerSnapshot` → `DailyLedgerSnapshot`
- `SoulCelebrationOverlay` → `JoyCelebrationOverlay`
- `SoulVsSurvivalCard` → `DailyVsJoyCard`
- `PerCategorySoulBreakdown[Item]` → `PerCategoryJoyBreakdown[Item]`
- `SoulSatisfactionOverview` → `JoyFullnessOverview`
- `SoulRowSample` → `JoyRowSample`
- `DailySoulRowSampleWithDay` → `DailyJoyRowSampleWithDay`（保留 Daily 前缀=日历日，子串陷阱已处理）

### 3. 测试固件翻转 + Golden 重基线

- 60+ 测试文件：`'soul'`/`'survival'` 字面量 → `'joy'`/`'daily'`
- CJK 字符：`魂/生存` → `ときめき/日常`
- D-19 Golden 重基线：4 个 PNG 文件（daily_vs_joy_card_*_ja.png），0 像素变化（Plan 03 已处理文本标签）

### 4. 回退（超出范围）

- `Book.survivalBalance`/`Book.soulBalance` SQLite 列名保留 — 重命名需要 DB 迁移（Research A1 明确排除）

### 5. 修复

- `import_guard.yaml`: `per_category_soul_breakdown.dart` → `per_category_joy_breakdown.dart`
- migration 测试 raw SQL: 恢复 `soul_satisfaction` 列名（v5 schema 必须用旧名以测试 v18 迁移）

---

## 遇到的问题与解决方案

### 问题 1: 批量替换破坏 migration 测试
**症状:** `SqliteException(1): no such column: "soul_satisfaction"` 在 merchant_category_preference_dao_test
**原因:** 批量替换将 pre-v18 raw SQL schema 中的 `soul_satisfaction` 改为 `joy_fullness`，但 v18 迁移期望找到旧列名
**解决方案:** 恢复该特定测试文件中的 raw SQL 列名

### 问题 2: Book 模型字段重命名导致 SQLite 列名变化
**症状:** Drift 生成的 `survival_balance`/`soul_balance` 列名变为 `daily_balance`/`joy_balance`，破坏现有 DB schema
**原因:** Dart 属性重命名 → Drift 生成的 SQLite 列名同步变化
**解决方案:** 回退重命名，遵循 Research Assumption A1（DB 列重命名超出 Phase 31 范围）

---

## 测试验证

- [x] 单元测试通过 — 2244/2244
- [x] Flutter analyze: 0 errors
- [x] dart run custom_lint --no-fatal-infos: 0 issues
- [x] git diff --exit-code generated files: clean
- [x] D-19 Golden 重基线: 4 个测试通过，0 像素变化
- [x] 文档已更新 (SUMMARY.md)

---

## Git 提交记录

```
Commit: 432bbd50
refactor(31-05): git mv + rename soul/survival → daily/joy across file/class/field surface

Commit: c86ca4be
fix(31-05): revert book balance DB column renames (out-of-scope per A1), fix import_guard

Commit: 014a447f
docs(31-05): complete soul/survival → daily/joy widest-ring rename plan
```

---

## 后续工作

- [ ] Plan 31-06: 最终清理 + ADR-017 文档
- [ ] Phase 34: PALETTE 驱动的 golden 重基线（与 Phase 33 调色板选择相关）

---

**创建时间:** 2026-06-01 03:57
**作者:** Claude Sonnet 4.6
