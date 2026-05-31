# v1.4 列表功能 — GAP-1 修复 + 里程碑收尾

**日期:** 2026-05-31
**时间:** 22:10
**任务类型:** [Bug修复 + 架构决策 + 文档]
**状态:** 已完成
**相关模块:** features/list, features/home (MainShellScreen), v1.4 milestone

---

## 任务概述

修复 v1.4 里程碑审计发现的 GAP-1（家庭同步 / FAB 录入后日历支出合计与月度摘要不刷新），随后完成 v1.4「列表功能」里程碑的归档与打标签。

---

## 完成的工作

### 1. GAP-1 修复（quick task 260531-u34）

- **根因:** `main_shell_screen.dart` 在家庭同步完成（~line 93）和 FAB 录入返回（~line 172）两处只 `ref.invalidate(listTransactionsProvider)`，未 invalidate Phase 27 新增的 `calendarDailyTotalsProvider`。列表行刷新，但日历每日合计（CAL-02）+ 月度摘要（CAL-04）保持陈旧，直到下拉刷新或列内编辑/删除。
- **修复:** 两处在既有 `listTransactionsProvider` invalidation 旁追加 `ref.invalidate(calendarDailyTotalsProvider(bookId:, year: now.year, month: now.month))`，复用各处已声明的 `now`；新增 import `state_calendar_totals.dart`。
- **范围守卫:** 仅 GAP-1；未触碰 GAP-2（`watchByBookIds` 死代码）与 `// D-03` 注释。
- `flutter analyze` 0 issue。提交 `291a9ff4`（代码）+ `cc34d2e3`（docs）。

### 2. 9 项待目视检查 quick task 真机验证

- release build 部署到物理 iPhone（signing team 6Y64KR8RLP，Xcode build 58.5s），逐项走查 9 个「Pending visual check」quick task（含 4 个需真机麦克风的语音项 l0o/n7b/pg6/gbp + UI 项 fj5/e5f/oqn/se5/u34）。
- 全部 pass，STATE.md 9 行状态更新为 Verified。提交 `b9c8bcca`。

### 3. v1.4 里程碑归档

- 修正 LIST-03 文档漂移（VERIFICATION ✓ 但 REQUIREMENTS.md 仍 `[ ]`/Pending → 改为 Complete），22/22 需求完成。
- `gsd-sdk query milestone.complete v1.4` 归档 ROADMAP/REQUIREMENTS/audit 至 `milestones/`。
- 主 ROADMAP.md 折叠 v1.4 区块（341→91 行）；MILESTONES.md 重写 v1.4 条目（替换噪声自动摘要）；PROJECT.md 全量演进（Validated +22 需求、Key Decisions、Context post-v1.4、归档 details 块）；STATE.md 快照 + Deferred Items §v1.4；RETROSPECTIVE.md v1.4 段 + cross-milestone 表。
- `git rm REQUIREMENTS.md`；annotated tag `v1.4`；push `main`（284 commits）+ tag 至 origin。

---

## 技术决策

- **Invalidation-set 完整性**（GAP-1 教训）：新增响应式读取面（provider）会隐式扩展每个写入/刷新点的 invalidation 契约——新增 consumer 时必须审计所有 `ref.invalidate` 站点。
- **响应式机制二选一**（GAP-2 教训）：手动 `ref.invalidate` 与 `watch()` stream 只选其一并接线，避免死代码。
- GAP-1 在里程碑收尾以 quick task 就地修复（而非推迟到 v1.5）。

---

## 测试验证

- [x] `flutter analyze` 0 issues（改动文件）
- [x] 真机目视验证 9 项 quick task 全 pass
- [x] 归档文件校验（v1.4-REQUIREMENTS.md LIST-03 = Complete）
- [x] tag v1.4 已推送至 origin（`85f45b9f`）

---

## Git 提交记录

```
291a9ff4  fix(260531-u34): invalidate calendarDailyTotalsProvider at sync + FAB sites
cc34d2e3  docs(quick-260531-u34): fix CAL-02/CAL-04 calendar staleness (GAP-1)
b9c8bcca  docs: mark 9 pending quick-task visual checks as Verified
aa0a27ff  chore: archive v1.4 milestone files
29394c01  chore: remove REQUIREMENTS.md for v1.4 milestone
tag v1.4  (annotated)
```

---

## 后续工作

- [ ] `/gsd-new-milestone` 规划下一里程碑（候选：family-calendar 合并合计、undo-on-delete、MOD-005 OCR writer、FAMILY-V2、FUTURE-QA-01）
- [ ] GAP-2：消费 `useCase.watch()` 或删除 `watchByBookIds` 三层链 + 修注释（v1.5）
- [ ] draft-Nyquist：Phases 25/26/27/29/30 `/gsd-validate-phase {N}` 回补（文档级）

---

**创建时间:** 2026-05-31 22:10
**作者:** Claude Opus 4.8
