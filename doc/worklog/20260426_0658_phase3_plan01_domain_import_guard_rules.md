# Phase 3 Plan 01: Domain Import Guard Rules

**日期:** 2026-04-26
**时间:** 06:58
**任务类型:** 架构决策 / 配置
**状态:** 已完成（Task 4 门控延迟 — 需等待其他 Phase 3 计划完成）
**相关模块:** Phase 3 CRIT-01, CRIT-04, CRIT-06

---

## 任务概述

执行 Phase 3 Plan 01，通过"修正的 D-01 策略"关闭 18 个 CRITICAL 层级违规发现（LV-001..016, LV-023, LV-024）。核心问题是 `import_guard_custom_lint` 对继承链中的每个 yaml 配置进行独立评估，因此 parent feature-level yaml 的 `allow:` 块无法解决子目录内部的 intra-domain 导入问题。

---

## 完成的工作

### 1. 主要变更

**Task 1: 修改 6 个 feature-level domain import_guard.yaml（去掉 allow: 块）**
- `lib/features/accounting/domain/import_guard.yaml` — 删除 `allow:` 块，保留 `deny:` + `inherit: true`
- `lib/features/analytics/domain/import_guard.yaml` — 同上
- `lib/features/family_sync/domain/import_guard.yaml` — 同上
- `lib/features/home/domain/import_guard.yaml` — 同上
- `lib/features/profile/domain/import_guard.yaml` — 同上
- `lib/features/settings/domain/import_guard.yaml` — 同上

**Task 1: 创建 8 个新的子目录 import_guard.yaml（带 allow 白名单）**
- `lib/features/accounting/domain/models/import_guard.yaml` — 允许 transaction.dart, category.dart（关闭 LV-001..004）
- `lib/features/accounting/domain/repositories/import_guard.yaml` — 允许 ../models/*.dart（关闭 LV-005..010）
- `lib/features/analytics/domain/models/import_guard.yaml` — 允许 daily_expense.dart, month_comparison.dart（关闭 LV-011..012）
- `lib/features/analytics/domain/repositories/import_guard.yaml` — 允许 ../models/analytics_aggregate.dart（关闭 LV-013）
- `lib/features/family_sync/domain/models/import_guard.yaml` — 允许 group_member.dart（关闭 LV-014）
- `lib/features/family_sync/domain/repositories/import_guard.yaml` — 允许 ../models/group_info.dart, group_member.dart（关闭 LV-015..016）
- `lib/features/profile/domain/repositories/import_guard.yaml` — 允许 ../models/user_profile.dart（关闭 LV-023）
- `lib/features/settings/domain/repositories/import_guard.yaml` — 允许 ../models/app_settings.dart（关闭 LV-024）

**Task 2: 架构元测试 + yaml dev_dependency**
- `pubspec.yaml` — 添加 `yaml: ^3.1.0` 到 dev_dependencies
- `test/architecture/domain_import_rules_test.dart` — NEW：18 个测试，验证 feature-level yaml 无 allow 块、子目录 yaml 只允许 intra-domain 叶子

**Task 3: 关闭 issues.json 中的 18 个 LV 发现**
- `.planning/audit/issues.json` — LV-001..016, LV-023, LV-024 状态设为 closed，closed_in_phase: 3，closed_commit: d6509c9

### 2. 技术决策

**修正的 D-01 策略（关键）:**
`import_guard_custom_lint` 对继承链中每个 yaml 配置独立评估其 allow 白名单。若 parent feature-level yaml 保留 `allow: [dart:core, freezed_annotation, json_annotation, meta]`，则子目录内的 intra-domain 导入（如 `transaction.dart`）因不在 parent allow 列表中而仍然失败。

解决方案：将 parent yaml 变为纯 deny-only，将 allow 白名单下推到每个子目录 yaml。

**Task 4 门控延迟:**
audit.yml 阻塞性翻转（D-17）需要 issues.json 中零个 open CRITICAL 发现。当前还有 6 个（LV-017..022，分别由 Plans 03-03 和 03-04 负责）。Task 4 必须作为 Phase 3 的最后一个 commit 执行。

### 3. 代码变更统计
- 修改文件数：18
- 新建文件：9（8 个 yaml + 1 个测试文件）
- 修改文件：9（6 个 feature-level yaml + pubspec.yaml + pubspec.lock + issues.json）

---

## 遇到的问题与解决方案

### 问题 1: Plan 文档中的计数错误

**症状:** Plan 说关闭 "19 LV findings"，但 LV-001..016 = 16 个，加上 LV-023 和 LV-024 = 18 个，共 18 个。
**原因:** 计划文档中的计数错误（"19" vs 实际 "18"）。
**解决方案:** 执行正确的 18 个关闭，SUMMARY 和 worklog 中记录了实际数量。

### 问题 2: Plan 文档中另一个计数错误

**症状:** Plan 说 "remaining open LVs returns 5"，但 LV-017..021（5 个）+ LV-022（1 个）= 6 个。
**原因:** PLAN.md 计数错误。
**解决方案:** 实际结果正确（6 个），已在 SUMMARY 中记录此差异。

---

## 测试验证

- [x] `dart run custom_lint` — 0 layer_violation 发现（CLEAN）
- [x] `flutter analyze --no-fatal-infos` — No issues found
- [x] `flutter test test/architecture/domain_import_rules_test.dart` — 18/18 通过
- [x] 6 个 feature-level domain yaml 无 `allow:` 块
- [x] 8 个新子目录 yaml 存在并包含正确的 allow 叶子
- [x] issues.json 18 个 LV 发现已关闭
- [x] issues.json 剩余 6 个 open CRITICALs（LV-017..022）

---

## Git 提交记录

```
Commit: d6509c9
feat(03-01): strip parent allow + add per-subdirectory import_guard yamls (D-01 corrected)

Commit: 1ea8718
test(03-01): add domain_import_rules_test.dart architecture meta-test (D-02/D-03)

Commit: 2450c7e
chore(03-01): close 19 LV findings in issues.json (LV-001..016, LV-023, LV-024)

Commit: 9f0b1ec
docs(03-01): complete domain import guard rules plan — 18 LV findings closed
```

---

## 后续工作

- [ ] Plan 03-03: 迁移 5 个 family_sync use_cases（关闭 LV-017..021）
- [ ] Plan 03-04: 移动 ledger_row_data.dart（关闭 LV-022）
- [ ] Task 4 (deferred): 在所有 Phase 3 计划完成后，翻转 audit.yml 为阻塞模式（D-17）
- [ ] Phase 4: 扩展 `test/architecture/` 目录增加 provider-graph hygiene 测试

---

## 参考资源

- 03-RESEARCH.md §"Pattern 1: Per-subdirectory import_guard.yaml with corrected D-01 strategy"
- import_guard_custom_lint 源码: `~/.pub-cache/hosted/pub.dev/import_guard_custom_lint-1.0.0/lib/src/import_guard_lint.dart:71-94`
- 03-CONTEXT.md D-01, D-02, D-03, D-17

---

**创建时间:** 2026-04-26 07:06
**作者:** Claude Sonnet 4.6
