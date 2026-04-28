# Phase 07 Plan 06: Verification Gap Closure

**日期:** 2026-04-28
**时间:** 11:16
**任务类型:** 文档
**状态:** 已完成
**相关模块:** Phase 07 Documentation Sweep

---

## 任务概述

执行 GSD 计划 07-06，关闭 Phase 7 文档扫描验证报告中记录的四个 MEDIUM 级别缺陷（WR-01..WR-05）。本计划是 Phase 7 的最终计划（gap closure wave），修复了 verify-doc-sweep.sh 门控脚本的结构性缺陷、ADR 文件尾部元数据位置问题、虚假引用问题以及统计表未同步问题。

---

## 完成的工作

### 1. 主要变更

**WR-01 — verify-doc-sweep.sh gate 4 修复：**
- `grep -cE` 在多文件时输出每文件计数而非整数，`[ "$hits" -gt 0 ]` 报错 "integer expression expected"
- 修复：改用 `grep -hcE ... | awk '{s+=$1} END {print s+0}'` + 子 shell `|| true` 防止 pipefail 中断
- 额外修复：grep 模式从 `doc/arch[^/]` 改为 `(^|[^s])doc/arch`，使 `doc/arch/foo` 格式的 drift 可被检测

**WR-01 smoke fixture — verify-doc-sweep-smoke.sh（新建）：**
- hermetic 测试：使用 `mktemp -d` + `trap EXIT` 创建隔离工作目录
- 向临时 CLAUDE.md 注入 `see doc/arch/foo for details`，通过 sed 将 gate 脚本的文件引用重定向到临时目录
- 验证 gate 4 返回非零退出码（drift 被检测到）

**WR-02 — ADR 孤立尾部元数据重定位：**
- ADR-002: `**下次Review日期:** 2026-08-03` 从文件末尾移到 `## Update` 前的 footer block 中
- ADR-008: `**下次审查:** 实施完成后进行效果评估` 同上
- ADR-010: `**优先级:** P1（高优先级）` 同上

**WR-03 — arch.md append-only 规则 + ADR 引用更新：**
- `.claude/rules/arch.md:162` 新增 item 4：ADR append-only 规则（中文，含 append-only 和 追加 关键字）
- ADR-002/007/008/010 引用行范围从虚假的 `:171-173` 更新为真实的 `:157-162`

**WR-04/WR-05 — 统计表同步：**
- ADR-000_INDEX.md：已接受 9→10，总计 10→11个ADR，下次Review计划表添加 ADR-011 行
- docs/arch/README.md：ADR 决策记录 10→11，总计 32→33，目录树添加 ADR-011
- ARCH-000_INDEX.md：ADR决策记录 10→11，总计 30→31

### 2. 技术决策

- gate 4 grep 模式必须使用 `(^|[^s])doc/arch` 而非 `doc/arch[^/]`，因为单数路径 `doc/arch/foo` 的斜杠被 `[^/]` 排除
- smoke fixture 使用 sed 路径重写而非直接修改真实文件，保证 hermeticity
- ADR footer 元数据应置于 `---` 分隔符之前（进入 Update section 之前），而非 Update 内容之后

### 3. 代码变更统计

- 修改文件数：10
- 创建文件：1（verify-doc-sweep-smoke.sh）
- 任务提交：9 次 + 1 次 metadata commit = 10 次提交

---

## 遇到的问题与解决方案

### 问题 1: pipefail 导致 gate 4 静默中断

**症状:** `bash verify-doc-sweep.sh` 在 gate 4 输出 `[4/6] Checking...` 后直接退出，不打印 OK/FAIL，exit 1
**原因:** `grep -hcE` 在无匹配时 exit 1，在 `set -euo pipefail` 下触发脚本中断，`|| true` 位于 pipe 之后无效
**解决方案:** 将 `grep` 包裹在 `{ grep ... || true; }` 子 shell 组内，再 pipe 给 awk

### 问题 2: smoke fixture 注入 `doc/arch/foo` 但 gate 4 无法检测

**症状:** `verify-doc-sweep-smoke.sh` 输出 `SMOKE FAIL: gate 4 did NOT detect injected doc/arch/foo drift`
**原因:** 模式 `doc/arch[^/]` 排除斜杠，`doc/arch/foo` 因后跟斜杠而不匹配
**解决方案:** 改为 `(^|[^s])doc/arch`，通过负向前缀 `[^s]` 区分 `doc/arch`（单数，drift）和 `docs/arch`（正确复数）

---

## 测试验证

- [x] `bash verify-doc-sweep.sh` 退出 0，6 个 gate 全部 OK，无 "integer expression expected" 警告
- [x] `bash verify-doc-sweep-smoke.sh` 输出 "SMOKE PASS"，退出 0
- [x] `bash scripts/verify_index_health.sh` 退出 0，零 BROKEN LINK / ORPHAN
- [x] `git diff --name-only ef4b770..HEAD | grep -cE '^(lib/|test/|...)'` 返回 0（lib/-clean invariant）
- [x] 所有 4 个 WR gaps 闭合验证通过

---

## Git 提交记录

```bash
73e5bbb fix(07-06): repair gate 4 grep-count sum in verify-doc-sweep.sh (WR-01)
41de0cb fix(07-06): improve gate 4 pattern to detect doc/arch/ path drift (WR-01 Rule 1)
4e31fc0 feat(07-06): add hermetic smoke fixture verify-doc-sweep-smoke.sh (WR-01)
259cf60 fix(07-06): relocate orphan trailing metadata in ADR-002, ADR-008, ADR-010 (WR-02)
29c8934 feat(07-06): add ADR append-only rule to .claude/rules/arch.md (WR-03)
5ff300e fix(07-06): update ADR append-only citations from :171-173 to :157-162 (WR-03)
09150f2 docs(07-06): sync ADR-000_INDEX.md statistics to reflect ADR-011 (WR-04)
f970674 docs(07-06): sync docs/arch/README.md statistics + add ADR-011 to tree (WR-05)
3e7fdd5 docs(07-06): sync ARCH-000_INDEX.md completion stats to ADR-011 (WR-05)
ea8403e docs(07-06): complete verification gap closure plan — SUMMARY + state updates
```

---

## 后续工作

Phase 7 (documentation-sweep) 已全部完成（6/6 计划执行完毕）。Phase 8 为后续积压工作：

- [ ] MOD 编号漂移修复（ADR-011 §Out of Scope，FUTURE-DOC 积压）
- [ ] ARCH-008 跨引用 ADR-006 应改为 ADR-007（FUTURE-DOC 积压）
- [ ] recoverFromSeed() key-overwrite bug（FUTURE-ARCH-04）

---

## 参考资源

- `.planning/phases/07-documentation-sweep/07-06-SUMMARY.md`
- `.planning/phases/07-documentation-sweep/07-VERIFICATION.md`（原始 gap 记录）
- `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh`
- `.planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh`

---

**创建时间:** 2026-04-28 11:16
**作者:** Claude Sonnet 4.6
