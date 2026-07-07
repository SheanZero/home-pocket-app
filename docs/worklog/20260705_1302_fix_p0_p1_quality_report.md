# 质量报告 P0/P1 问题修复

**日期:** 2026-07-05
**时间:** 13:02
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** 数据层（Drift 迁移）、备份导入导出、加密、架构守卫

---

## 任务概述

修复 `docs/CODE_QUALITY_REPORT_2026-07-02.md` 中的全部 P0 与 P1 问题（P0-1 已于报告当日由 `3bc599b5` 修复）。每项修复均 TDD（失败测试先行）、独立 commit。

---

## 完成的工作

### 1. 主要变更（4 个 commit）

- **P0-2 `f422c78e`** — 备份恢复/清除数据事务化：新增 `UnitOfWork` domain 接口（`lib/features/settings/domain/repositories/unit_of_work.dart`）+ data 层 Drift 事务实现；`ImportBackupUseCase._restoreData` 与 `ClearAllDataUseCase` 整体包进事务，SharedPreferences 写挪到事务内最后一步；real-DB 回滚测试证明损坏备份导入失败后原数据完好
- **P1-1+P1-4 `2cb07b08`** — schemaVersion 22→23：`_createAllDeclaredIndexes()` 补齐 25 条缺失索引（含 transactions 全部 6 条），同挂 onCreate 与 `from<23`；`createTable(groups/groupMembers)` 从 `from>=7&&from<8` 放宽为 `from<8` 修复 v≤6 升级缝隙；新增两类守卫测试（源码解析 TableIndex ↔ sqlite_master 对账；手搭 v6 schema 的真实 v6→v23 全链条迁移测试）
- **P1-3 `84eb8f7a`** — 备份加密下沉 `infrastructure/crypto/services/backup_crypto_service.dart`：Argon2id（OWASP 参数、off-isolate，镜像 pin_kdf）+ AES-256-GCM + 'HPB' 版本化自描述文件头；旧 PBKDF2-100k 无头格式自动识别、保持可导入；头部 KDF 参数设上限防恶意文件 OOM
- **P1-2 `e811a219`** — 新 `test/architecture/layer_import_rules_test.dart` 扫描真实 import（相对路径归一化）执法分层规则；`appLockService` 接线移入 applock 组合根、`seedAllUseCase` 移入 accounting 组合根（删除 `application/seed/seed_providers.dart`）；`RateResult` 移入 `features/currency/domain/models/`（新测试额外发现的第 3 处反向依赖）；CLAUDE.md pitfall #2 的不实 Structurally enforced 标注更正

### 2. 技术决策

- 事务抽象选 `UnitOfWork` 接口注入而非在 data 层新建 BackupRepository：复用现有 repository（含字段加密路径），Drift 事务 zone 语义让 repo 内部调用自动挂进事务，改动面最小
- 备份 KDF 选 Argon2id（同 pin_kdf 参数）而非 PBKDF2-600k：项目已有先例与实现，内存硬更抗 GPU 暴破；文件头自描述使未来升参数无需破坏兼容
- 分层执法选"真实 import 扫描测试"而非给 12 个 deny-mode yaml 补相对路径 pattern：pattern 依赖 import 深度、脆弱易漏，测试是单一可靠执法点；yaml 对齐降级为 P2 清理项

### 3. 代码变更统计

- 4 个 commit，63 个文件变更（+2262 / -634 行，含生成文件与测试）
- 新增源文件 5 个、新增测试文件 6 个、删除源文件 2 个（seed_providers 及其 .g）

---

## 遇到的问题与解决方案

### 问题 1: P1-2 真实 import 扫描发现的违规比审查报告多
**症状:** 新架构测试报 8 处违规而非预期 3 处
**原因:** 审查 agent 靠人工抽查；测试全量扫描。其中 infra→domain 的 4 处按项目规则（outer depends on inner）属合法，规则收敛后剩 4 处真实违规——比报告多出 `exchange_rate_cache_service → application/currency/rate_result.dart` 一处
**解决方案:** `RateResult`（纯 sealed 值类型）移入 currency domain，13 个引用文件更新

### 问题 2: P0-2 接线后 backup_providers_characterization_test 失败
**症状:** `appDatabaseProvider not overridden` StateError
**原因:** 新 `unitOfWork` provider 需要 AppDatabase，而该 characterization 测试的 container 未注入
**解决方案:** 按错误信息指引注入 `appDatabaseProvider.overrideWithValue(AppDatabase.forTesting())`

### 问题 3: v6→v23 全链条迁移测试的 v6 schema 复原
**症状:** 深度回拨 user_version 需要老 schema，现代表结构会让 addColumn/RENAME 步骤炸掉
**解决方案:** 只手搭迁移链会读写的 6 张表的 v6 最小形态（audit_logs/books/categories/category_ledger_configs/merchant_category_preferences/transactions），后建表全部留给真实 migrator

---

## 测试验证

- [x] 每项修复先写失败测试（RED）再实现（GREEN）
- [x] 全量 `flutter test`：**3561/3561 通过**（修复前基线 3492 通过 / 1 失败）
- [x] `flutter analyze`：0 issues
- [x] 新增守卫：索引 parity 测试、v22→v23 真实迁移测试、v6→v23 全链条测试、备份加密 roundtrip/兼容/防篡改测试、restore/clear 原子性测试、layer_import_rules 测试

---

## Git 提交记录

```
e811a219 fix: close import_guard enforcement hole and remove reverse layer deps (P1-2)
84eb8f7a fix: move backup crypto to infrastructure/crypto and upgrade KDF to Argon2id (P1-3)
2cb07b08 fix: backfill all declared Drift indices (v23) + close v≤6 groups migration seam (P1-1, P1-4)
f422c78e fix: make backup restore and clear-all-data atomic (P0-2)
```

---

## 后续工作

- [ ] P2 清理：import_guard yaml 与现实对齐（deny-mode 补相对 pattern 或标注 inert；组合根 DAO import 加 allow 例外）
- [ ] P1-1 上真机后可用 `EXPLAIN QUERY PLAN` 抽查交易列表/日历/分析页热查询确认索引命中
- [ ] 报告 §3 其余 P2/P3 项按批次推进（搜索防抖、分页 D-02、覆盖率门槛决议、joy 文字色等）

---

## 参考资源

- `docs/CODE_QUALITY_REPORT_2026-07-02.md`（已更新修复状态表）
- Phase 36 CR-01（customIndices 装饰性）
- ADR-020（rate 全精度字符串）

---

**创建时间:** 2026-07-05 13:02
**作者:** Claude (Fable 5)
