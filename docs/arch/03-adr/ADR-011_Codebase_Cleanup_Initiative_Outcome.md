# ADR-011: Codebase Cleanup Initiative Outcome

**文档编号:** ADR-011
**文档版本:** 1.0
**创建日期:** 2026-04-27
**状态:** ✅ 已接受
**决策者:** Architecture Team
**影响范围:** 全局重构（Phases 3–6）, CI 守门, 测试基础设施
**相关 ADR:** ADR-002 (Database Solution), ADR-007 (Layer Responsibilities), ADR-008/009/010 (实施推迟)

---

## 📋 状态

**当前状态:** ✅ 已接受
**决策日期:** 2026-04-27
**实施状态:** 已完成 (Phases 3–6 已落地)

---

## 🎯 背景 (Context)

2026年初，项目审计发现代码库积累了大量架构债务：层职责混乱、死代码、Riverpod卫生问题，以及测试覆盖率不足。为系统清理这些问题，项目启动了一个6阶段的清理计划（Phase 3–6），在零行为变更（no-behavior-change）的约束下专注于结构修正。

Phase 7（本文档所在阶段）完成了配套的文档扫描，将 `docs/arch/` 中的架构文档与清理后的 `lib/` 目录树对齐。Phase 8 将做最终的重审计验证。

本 ADR 记录三项在 Phases 3–6 中产生的**持久决策**：

1. **`*.mocks.dart` 策略** — 在 Phase 4-04 中做出的 Mocktail 大爆炸迁移选择
2. **常驻 CI 守门** — 8 个 CI 门禁，在 Phase 8 及以后持续执行
3. **清理结果** — 按阶段的发现关闭统计

未来的贡献者应能通过本 ADR 理解：(a) 清理做了什么，(b) CI 现在永久执行什么，(c) 还有什么遗留在积压中。

---

## 🔍 考虑的方案 (Considered Options)

### 清理方案

**采用方案（已实施）：** 按严重程度分阶段清理（CRITICAL → HIGH → MEDIUM → LOW → 文档扫描 → 重审计），每阶段设退出门禁（exit gate）。

**拒绝的备选方案：**
- **合并阶段**：一次性处理所有问题 — 拒绝，因为混合严重程度使得审查困难，且无法形成稳定的中间快照
- **逐阶段更新文档**：每修复一个阶段就更新一次文档 — 拒绝，文档更新开销高且会分散修复工作的注意力；推迟到 Phase 7 集中处理
- **不写集中 ADR**：分散在各阶段 SUMMARY 中记录 — 拒绝，未来贡献者无法从单一入口点理解 CI 守门机制的全貌

### `*.mocks.dart` 策略

**采用方案（Phase 4-04）：** Mocktail 大爆炸迁移——移除所有 `*.mocks.dart` 文件和 mockito，改用 `mocktail` 包（`pubspec.yaml`: `mocktail: ^1.0.4`）。

**拒绝的备选方案：**
- **CI 生成 mockito mocks**：继续用 `@GenerateMocks` 但在 CI 中重新生成 — 拒绝，因为 `*.mocks.dart` 提交到仓库会使 AUDIT-10（stale-diff 门禁）永远触发警告，且阅读生成的 mock 类比 mocktail 的 inline stub 难度更高
- **保持 mockito 现状**：不迁移 — 拒绝，mockito 生成文件是技术债务的来源之一（HIGH-07）

---

## ✅ 决策 (Decision)

### A. `*.mocks.dart` 策略

**决策：** 选择 Mocktail 大爆炸迁移（Phase 4-04）。

在 Phase 4-04 中，所有 13 个 `*.mocks.dart` fixture 文件被删除，`mockito` 依赖被移除，所有测试改用 `mocktail ^1.0.4`（见 `pubspec.yaml`）。

来自 `.planning/STATE.md`（Blockers/Concerns 节）的决策记录：

> `*.mocks.dart` strategy (CI-generated vs Mocktail migration) must be decided before Phase 4
> (interface changes happen there) — SUMMARY.md recommends Mocktail

**计划路径：** `.planning/phases/04-high-fixes/04-04-mocktail-bigbang-migration-PLAN.md`

**关键理由：**
- Mocktail 消除了生成噪声（无 `*.mocks.dart` 提交，AUDIT-10 不再发出警告）
- 测试代码更易读（inline stub 替代 `@GenerateMocks` + 生成类）
- 与 import_guard 和 riverpod_lint 无冲突

### B. Ongoing CI Enforcement

以下 8 个 CI 门禁在 `.github/workflows/audit.yml` 中常驻，作用于每个 PR 和 main 分支推送：

| Gate | File:Line | Purpose |
|------|-----------|---------|
| flutter analyze | `.github/workflows/audit.yml:38` | 类型检查 + lint（`--no-fatal-infos`） |
| dart run custom_lint | `.github/workflows/audit.yml:41` | import_guard 层违规 + riverpod_lint |
| AUDIT-09 SQLCipher 拒绝 | `.github/workflows/audit.yml:70-75` | 阻止 `sqlite3_flutter_libs` 进入 `pubspec.lock` |
| AUDIT-10 build_runner 差异 | `.github/workflows/audit.yml:79-84` | 阻止带过期生成文件的 PR 合并 |
| coverde filter | `.github/workflows/audit.yml:100-105` | 从 `lcov.info` 中剥离生成文件，生成 `lcov_clean.info` |
| very_good_coverage ≥80% | `.github/workflows/audit.yml:108` | 全局覆盖率门禁，针对 `lcov_clean.info`，`min_coverage: 80` |
| 架构测试 test/architecture/ | `flutter test test/architecture/`（CI coverage step） | domain_import_rules + provider_graph_hygiene + service_name_collision + production_logging_privacy 等 |
| 每文件覆盖率门禁 | `scripts/coverage_gate.dart`（CI coverage step） | 对 `phase6-touched-files.txt` 中的文件强制 ≥80% 覆盖率 |

**import_guard.yaml 5层规则**（`dart run custom_lint` 门禁的子集）：
- `lib/import_guard.yaml`
- `lib/application/import_guard.yaml`
- `lib/data/import_guard.yaml`
- `lib/features/import_guard.yaml`
- `lib/infrastructure/import_guard.yaml`

### C. Cleanup Outcome

**发现统计（按阶段关闭）：**

| 阶段 | 严重程度 | 关闭数量 | 主要修复内容 |
|------|----------|----------|-------------|
| Phase 3 | CRITICAL | 24 | 层集中化（use_cases/repositories 迁移到 lib/application/ 和 lib/data/）、analyzer 警告清零、CategoryService 重命名、ResolveLedgerTypeService 删除 |
| Phase 4 | HIGH | (见下注) | Mocktail 大爆炸（HIGH-07）、schema 版本迁移测试、覆盖率基线 |
| Phase 5 | MEDIUM | 8（MED-01..MED-08） | ARB 覆盖率对等、硬编码 CJK 标签本地化、CategoryService 重命名执行 |
| Phase 6 | LOW | 24（DC-001..DC-024） | 死代码删除（未使用文件、未使用 import）、日志隐私清理 |

> **注：** `.planning/audit/issues.json` 跟踪了 50 项自动发现（CRITICAL 24 + MEDIUM 2 + LOW 24）。Phase 4 的 HIGH 发现通过 `.planning/ROADMAP.md` 的 `HIGH-01..HIGH-NN` 条目追踪，未全部包含在 issues.json 中。总体 87 项 finding 的统计来自 ROADMAP 计划条目（含手动分类的 HIGH 条目）。

**文件级变更（Phases 3-6 汇总）：**
- 层集中化：`lib/application/` 新增 Use Case 文件；`lib/data/repositories/` 汇聚所有 Repository 实现
- 重命名：`category_service.dart` → `category_locale_service.dart`（`lib/infrastructure/category/`）
- 删除：`ResolveLedgerTypeService`、13 个 `*.mocks.dart` 文件、多个未使用的 dead-code 文件
- 数据库 schema：v14 → v15（Phase 6-02，添加索引）

详细变更见 `.planning/phases/03-critical-fixes/`、`04-high-fixes/`、`05-medium-fixes/`、`06-low-fixes/` 目录下各计划的 SUMMARY.md。

---

## 🤔 决策理由 (Rationale)

### 为什么选 Mocktail 而非 mockito

1. **无生成噪声：** Mocktail 的 stub 在测试代码中内联定义，不需要 `@GenerateMocks` 注解和生成的 `*.mocks.dart` 文件。AUDIT-10 stale-diff 门禁在提交后无需担忧。
2. **可读性：** 阅读 `MockTransactionRepository` 的 inline stub 比理解 `GeneratedMockTransactionRepository` 的生成类更直观。
3. **维护成本低：** 删除一个接口方法后，编译器会立即报错指向 stub；不需要重新运行 code generation。

### 为什么集中在一个 ADR 中

三个子主题（清理结果 + `*.mocks.dart` 策略 + CI 守门）是强相关的：CI 守门的动机来自清理发现的问题，`*.mocks.dart` 决策是 CI AUDIT-10 的直接输入。拆分成三份 ADR 会使未来的贡献者需要跨多个文件才能理解完整上下文。

### 为什么审计驱动而非功能驱动

Phases 3–6 的核心约束是"零行为变更"——每个 commit 只能改善结构/测试/工具，不能改变应用逻辑。审计驱动的发现目录（`issues.json`）提供了可追溯的退出标准：当所有 CRITICAL/HIGH/MEDIUM/LOW 发现都关闭时，该阶段结束。功能驱动的方式无法提供同等清晰的完成信号。

---

## 🔄 后果 (Consequences)

**Positive:**
- CI 守门将以前的手动检查机械化：analyzer 0 警告、import 层规则、SQLCipher 强制、build_runner 同步、≥80% 覆盖率
- 未来的 PR 在到达人工 review 之前就能在 CI 中被自动拦截
- `*.mocks.dart` 的删除减少了仓库中的生成文件噪声

**Negative:**
- CI 门禁数量增加（8个）意味着绿色 CI 所需时间略长
- Pitfall 4（mutation）、7（Podfile EXCLUDED_ARCHS）、9（widget 硬编码默认值）、11（Drift 索引语法）仍然是手动检查项，没有机械执行——见 `CLAUDE.md` Common Pitfalls 注释

**Neutral:**
- ADR 数量增加到 11 个；ADR-000_INDEX.md 维护负担 +1 条目
- ADR-008/009/010 在清理期间没有被实施（仍为"已接受但待实施"状态）

---

## 📋 实施计划 (Implementation Plan)

实施已完成。各阶段详情见以下计划目录：

- Phase 3（CRITICAL）：`.planning/phases/03-critical-fixes/`
- Phase 4（HIGH）：`.planning/phases/04-high-fixes/`（含 `04-04-mocktail-bigbang-migration-PLAN.md`）
- Phase 5（MEDIUM）：`.planning/phases/05-medium-fixes/`
- Phase 6（LOW）：`.planning/phases/06-low-fixes/`
- Phase 7（文档扫描）：`.planning/phases/07-documentation-sweep/`（本计划）

Phase 8（重审计验证）：待执行——将重新运行完整审计脚本，确认 `issues.json` 中零活跃发现。

---

## 📝 Out of Scope / Deferred

以下条目在 Phases 3–6 清理范围之外，已记录到 `.planning/STATE.md` 的 "Deferred Items" 一节：

- **FUTURE-ARCH-01：** ARB 驱动的 CategoryLocaleService（消除 735 行静态映射表）
- **FUTURE-ARCH-03：** DCM 升级（付费审计工具）
- **FUTURE-ARCH-04：** `recoverFromSeed()` 密钥覆写 bug 修复
- **FUTURE-TOOL-01：** riverpod_lint 3.x 升级（受 json_serializable analyzer 冲突阻塞）
- **FUTURE-TOOL-02：** Drift 未使用列检测自定义脚本
- **ADR-008/009/010 实施状态：** 这三份 ADR 在清理期间未被实施；它们仍然是"已接受 / Phase N 后评估"的设计决策，不是 v1 代码
- **MOD 编号漂移（D-02）：** `02-module-specs/` 目录中文件名编号与内部标题编号不一致的问题是预先存在的；Phase 7 不修改 MOD 文件名（会破坏所有外部书签），已提升到 FUTURE-DOC 积压
- **markdown-link-check CI 门禁：** 自动检测 docs/ 中的断链——推迟到 Phase 8（重审计）或 FUTURE-TOOL 积压
