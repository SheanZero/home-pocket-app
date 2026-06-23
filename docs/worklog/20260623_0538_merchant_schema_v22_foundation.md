# Phase 49 Plan 01: 商家数据基础 Schema v22

**日期:** 2026-06-23
**时间:** 05:38
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** [MERCH] 商家识别系统重构（v1.9）

---

## 任务概述

在 Drift schema **v22** 新增两张商家表（`merchants` + `merchant_match_keys`），onCreate 与 v21→v22 onUpgrade 两条路径都显式创建索引，并附 host-VM migration 单元测试证明全新安装的列/索引以及升级路径。本计划只建 schema，不插任何数据行（seed 是 Plan 05）。

---

## 完成的工作

### 1. 主要变更

- 新建 `lib/data/tables/merchants_table.dart`（`MerchantRow`）：`id` PK、`name_ja` 必填、`name_zh`/`name_en` 可空、`region` 默认 `'JP'`（companion 层默认）、`category_id`（真实 L2）、`ledger_hint`（存储的非权威提示）。
- 新建 `lib/data/tables/merchant_match_keys_table.dart`（`MerchantMatchKeyRow`）：`id` PK、`merchant_id` FK → `merchants(id)`、`surface`、`match_key`（索引，**非唯一**）、`kind`。
- `lib/data/app_database.dart`：注册两表；`schemaVersion` 21→22；新增 `from < 22` onUpgrade 块（建两表 + 调索引 helper）；新增 `_createMerchantIndexes()`，从 onCreate **和** from<22 两处调用（`customIndices` 装饰性陷阱 — MEMORY.md）。四个显式 `CREATE INDEX IF NOT EXISTS`。
- 新建 `test/unit/data/migrations/merchant_v22_migration_test.dart`：9 条断言（全新安装表/列/索引、`PRAGMA index_list` 非空、match_key 索引非唯一、两行共享 match_key 不报错、region 默认 JP、v21→v22 升级契约）。
- build_runner 重新生成 `app_database.g.dart`。

### 2. 技术决策

- `match_key` 索引**非唯一**：两个不同商家可合法共享同一 match_key（RESEARCH #6），用插入两行同 match_key 的回归测试守护。
- `region` 默认放在 companion 层（`withDefault(Constant('JP'))`），用省略列插入测试验证。
- `ledger_hint` 保留为存储的非权威提示列（D-09），不删除。
- `merchant_id` FK 用列内 `customConstraint('NOT NULL REFERENCES merchants(id)')`，而非表级 `customConstraints`。

### 3. 代码变更统计

- 创建文件：3（2 张表 + 1 个 migration 测试）
- 修改文件：3（app_database.dart、app_database.g.dart、schema_v21_migration_test.dart）

---

## 遇到的问题与解决方案

### 问题 1: RED 测试编译失败
**症状:** `Variable<String>` 未通过 `app_database.dart` 重导出，测试编译失败而非按预期失败。
**原因:** drift 符号未透出。
**解决方案:** 直接 `import 'package:drift/drift.dart'`（对齐 `category_v14_migration_test.dart` 写法），测试随后按正确原因（缺表/缺索引）失败。

### 问题 2: 旧 schema_v21 测试硬钉版本号
**症状:** v22 升级后 `schema_v21_migration_test.dart` 断言 `schemaVersion == 21` 失败。
**原因:** 由本计划改动直接引起（in-scope，偏差 Rule 1）。
**解决方案:** 改为 `greaterThanOrEqualTo(21)` — 该套件真实关注点是 v21 多币种列/索引仍在；精确版本钉死交给新的 `merchant_v22_migration_test.dart`。

---

## 测试验证

- [x] `flutter analyze` → No issues found（全项目）
- [x] `flutter test test/unit/data/migrations/merchant_v22_migration_test.dart` → 9/9 通过
- [x] `flutter test test/unit/data/migrations/` → 77/77 通过
- [x] `grep -c '_createMerchantIndexes'` → 3（定义 + onCreate + from<22）
- [x] match_key 无 UNIQUE 约束；两表 customIndices 标注为装饰性

---

## Git 提交记录

```
e24dd8cb test(49-01): add failing v22 merchant migration test (RED)
040dd7d9 feat(49-01): define merchants + merchant_match_keys Drift tables
4d530ba2 feat(49-01): register merchant tables, bump schema to v22, add migration (GREEN)
279d37da docs(49-01): complete merchant schema foundation plan
```

---

## 后续工作

- [ ] Plan 02: `MerchantNameNormalizer`
- [ ] Plan 03: `DefaultMerchants` const 列表 + `deriveLedgerHint`
- [ ] Plan 04: `MerchantDao`/`MerchantRepository`(+Impl)/`Merchant` model
- [ ] Plan 05: `SeedMerchantsUseCase` + wiring（插入 ~400 行商家）
- [ ] Plan 06: 加密 `integration_test/` migration ladder（cipher_version 非空）

---

## 参考资源

- `.planning/phases/49-merchant-data-foundation/49-01-PLAN.md`
- `.planning/phases/49-merchant-data-foundation/49-01-SUMMARY.md`
- MEMORY.md: drift-customindices-is-decorative

---

**创建时间:** 2026-06-23 05:38
**作者:** Claude Opus 4.8 (1M context)
