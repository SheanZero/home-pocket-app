# Phase 08 Plan 01: reaudit_diff Implementation

**日期:** 2026-04-28
**时间:** 06:19
**任务类型:** 功能开发 + 测试
**状态:** 已完成
**相关模块:** Phase 8 Re-Audit + Exit Verification (EXIT-02)

---

## 任务概述

实现 Phase 8 关闭门 `scripts/reaudit_diff.dart`：将 Phase 1 留下的 9 行 stub 替换为完整的 D-01 严格退出门实现，覆盖 `(category, file_path, description)` 三元组匹配（drop `line_start` 因清理后行号会偏移）、四桶分类（resolved / regression / new / open_in_baseline）、双输出（REAUDIT-DIFF.json 字节稳定 + REAUDIT-DIFF.md 人类可读）。配套 9 个 subprocess 测试覆盖全部 4 个退出分支 + JSON/MD 形状 + 3 个 invocation 错误路径。

---

## 完成的工作

### 1. 主要变更

- `scripts/reaudit_diff.dart` (9 → 297 行)：完整实现 Phase 8 D-01 strict-exit 合约
  - 读 `.planning/audit/issues.json` (baseline) + `.planning/audit/re-audit/issues.json` (re-audit)
  - 用 `Finding.fromJson` 解码（无自定义 JSON walking）
  - 匹配键 `${category}|${filePath}|${description}` (drop `lineStart` per Phase 1 D-07 + Phase 8 D-02)
  - 分桶：resolved (baseline 中、re-audit 缺) / regression (baseline closed、re-audit 重现) / new (re-audit 中、baseline 缺) / open_in_baseline (baseline 仍 open)
  - stdout 紧凑摘要 `[reaudit:diff] resolved=N regression=N new=N open_in_baseline=N`
  - 写 `JsonEncoder.withIndent('  ')` 格式的 REAUDIT-DIFF.json（无 top-level `generated_at` 保字节稳定）
  - 写 bucket-then-severity-then-category 结构的 REAUDIT-DIFF.md
  - exit(0) 仅当 `regression == 0 && new == 0 && open_in_baseline == 0`；否则 exit(1)；invocation 错误（缺文件、坏 JSON、未知 flag）→ exit(2)

- `test/scripts/reaudit_diff_test.dart` (新建 341 行)：9 个 subprocess 测试
  - 用 `Directory.systemTemp.createTempSync` + `Link('${tmp.path}/.dart_tool').createSync(...)` 镜像 merge_findings_test.dart 模式（无 per-test pub get）
  - Test 1: exit 0 happy path（baseline all-closed + re-audit empty）
  - Test 2: exit 1 regression（baseline closed → re-audit 重现，line_start 不同也能匹配）
  - Test 3: exit 1 new（re-audit 有、baseline 无）
  - Test 4: exit 1 open_in_baseline（baseline 仍 open）
  - Test 5: REAUDIT-DIFF.json shape（summary + buckets 都键齐全且类型正确）
  - Test 6: REAUDIT-DIFF.md shape（title + bucket headings 都在）
  - Test 7: exit 2 missing baseline
  - Test 8: exit 2 missing re-audit
  - Test 9: exit 2 unknown flag

### 2. 技术决策

- **Match key drops `lineStart`** (D-02)：清理 phase 后 line 号必然偏移，但 (category, file_path, description) 三元组在重运行间稳定。Test 2 显式用 `line: 1` (baseline) vs `line: 5` (re-audit) 验证 key 仍匹配。
- **`exit(2)` 保留给 invocation 错误**（沿用 `coverage_gate.dart` 模式，区分 gate-failure 和 bug-in-CLI）。
- **REAUDIT-DIFF.json 无 top-level `generated_at`**（沿用 Phase 1 D-09 idempotency carry-over，保字节稳定）。
- **Markdown 桶优先排版**（与 merge_findings.dart 的 severity-first 不同）—— diff 的主分类轴是 bucket 不是 severity。

### 3. 代码变更统计

- 修改文件：`scripts/reaudit_diff.dart` (9 → 297 行，net +288)
- 新增文件：`test/scripts/reaudit_diff_test.dart` (341 行)
- SUMMARY/STATE/REQUIREMENTS 文档更新

---

## 遇到的问题与解决方案

无。两个 task 都一次过：实现 Task 1 后 `dart analyze` 干净，subprocess smoke test 跑通；Task 2 写完 9 个测试一次跑全 GREEN（约 6 秒）。

---

## 测试验证

- [x] `dart analyze scripts/reaudit_diff.dart test/scripts/reaudit_diff_test.dart` → No issues found
- [x] `flutter test test/scripts/reaudit_diff_test.dart` → 9/9 passed in ~6s
- [x] 真实 subprocess smoke test (临时目录 + symlink .dart_tool)：happy path → exit 0、regression → exit 1、unknown flag → exit 2
- [x] 全部 plan acceptance 条件 grep 检查通过（line count、key import 等）
- [x] 文档已更新（SUMMARY.md + STATE.md decisions + REQUIREMENTS.md EXIT-02 标记 complete）

---

## Git 提交记录

```
70a65d9  feat(08-01): implement reaudit_diff.dart strict-exit gate
833217d  test(08-01): subprocess tests for reaudit_diff strict-exit branches
b0e079c  docs(08-01): complete reaudit_diff implementation plan
```

---

## 后续工作

- [x] Plan 08-01 完成
- [ ] Plan 08-02 等下一波（pending）
- [ ] Plan 08-05 会调用 reaudit_diff 对真实 re-audit catalogue 跑端到端
- [ ] Plan 08-08 会引用 REAUDIT-DIFF.json schema 做 ADR-011 amendment

---

## 参考资源

- Plan: `.planning/phases/08-re-audit-exit-verification/08-01-PLAN.md`
- Summary: `.planning/phases/08-re-audit-exit-verification/08-01-SUMMARY.md`
- Context: `.planning/phases/08-re-audit-exit-verification/08-CONTEXT.md` (D-01, D-02, D-08)
- Pattern map: `.planning/phases/08-re-audit-exit-verification/08-PATTERNS.md`
- Requirement: `.planning/REQUIREMENTS.md` EXIT-02

---

**创建时间:** 2026-04-28 06:19
