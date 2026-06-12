# 完成 v1.6 购物清单 Milestone（audit + W1/W2 修复 + 归档 + 打 tag）

**日期:** 2026-06-12
**时间:** 10:39
**任务类型:** 架构决策（milestone 关闭）+ Bug修复
**状态:** 已完成
**相关模块:** shopping_list / family_sync / .planning

---

## 任务概述

执行 `/gsd-complete-milestone` 关闭 v1.6 购物清单 milestone。关闭前先补跑了缺失的 `/gsd-audit-milestone`（27/27 requirements、4/4 phases、6/6 seams、10/10 E2E flows），audit 发现两个实质性 warning（W1/W2），按用户决定先修复再关闭，最后完成归档、PROJECT.md 演进、retrospective 与 git tag `v1.6`。

---

## 完成的工作

### 1. Milestone audit（补跑）

- Integration checker 以"执行证明"方式跑了 32/32 跨 phase 测试（含 sync round-trip），6/6 seams WIRED、10/10 flows COMPLETE。
- 发现 **W1 (SYNC-01)**：`shopping_item_change_tracker.dart` 注释声称 "fullSync on next launch will reconcile"，但 `full_sync_use_case.dart` 零 shopping 支持——10s debounce 窗口内被杀进程会永久丢失待推送公共购物 ops。
- 发现 **W2 (SYNC-02/03)**：接收端信任 wire 上的 `listType`，公共/不可变门控只在发送端。
- 产出 `.planning/v1.6-MILESTONE-AUDIT.md`（status: `tech_debt`，后归档至 milestones/）。

### 2. Quick task 260612-daz：修复 W1+W2（TDD）

- **W1**：`FullSyncUseCase` 增加必填 `fetchAllShoppingOps` 回调（防御性 public-only 过滤）；provider 经 `watchByListType('public').first` → `ShoppingItemSyncMapper.toCreateOperation` 接线；误导注释删除（`grep "next launch"` = 0）。
- **W2**：`_applyShoppingItemOp` 对 create/update 加 `_isPublicShoppingOp` 门控（非 public op 丢弃，沿用 D37-05 per-op skip）；update merge 钉死 `listType: existing.listType`（D37-04 接收端不变量）。delete 不带 listType 故不门控，记为已接受威胁 T-q260612-04。
- 随改 `shopping_provider_smoke_test.dart` D39-06 测试至新契约（私有 op 被整体丢弃 → 不再有 post-write emission，改为断言两表均无痕）。

### 3. Milestone 归档

- `gsd-sdk query milestone.complete` 归档 ROADMAP/REQUIREMENTS/AUDIT 至 `.planning/milestones/`；phase 目录 36-39 移至 `milestones/v1.6-phases/`。
- ROADMAP.md 折叠 v1.6 为 `<details>` 块；MILESTONES.md 手工重写 v1.6 条目（SDK 自动提取为噪声）；PROJECT.md 全面演进（Validated v1.6 requirements、8 条 Key Decisions、Context post-v1.6、footer）；RETROSPECTIVE.md 增 v1.6 章节 + trends + lessons 21-24；STATE.md snapshot 轮换 + Deferred Items §v1.6（6 项）。
- `git rm .planning/REQUIREMENTS.md`（先 safety commit 后删除）。

---

## 遇到的问题与解决方案

### 问题 1: W2 门控导致 D39-06 smoke test 超时
**症状:** 全量套件 1 红：`TimeoutException after 0:00:05` 等待 post-write emission。
**原因:** 旧测试模拟 peer 写入私有 op 并等待 DB 写入后的 stream 再发射；W2 门控让该 op 在落库前被丢弃 → 无任何 emission。
**解决方案:** 更新测试至更强的新契约（断言私有/公共两表均无该 item、provider 状态保持空），删除失效的 `_waitForSettledEmission` helper。教训：加固改变行为契约时，要主动清扫编码旧契约的测试——失败形态是 hang/timeout 而非断言差异。

### 问题 2: worktree cleanup 被 SUMMARY.md 阻塞
**症状:** `worktree.cleanup-wave` 报 `worktree_dirty`。
**原因:** 按设计 executor 把 SUMMARY.md 留给 orchestrator 提交（未跟踪文件）。
**解决方案:** 拷出 SUMMARY.md 至主树后删除 worktree 副本，重跑 cleanup → `merged_removed`。

---

## 测试验证

- [x] `flutter analyze` 0 issues（合并后主树）
- [x] family_sync + sync integration 138/138 绿
- [x] 全量 `flutter test` **2588/2588** 绿
- [x] 归档文件先 commit 后删原件（safety checkpoint）
- [x] Tag `v1.6` 创建

---

## Git 提交记录

```
ed5ba200..e9bcf7ac  quick-260612-daz W1+W2 修复（TDD 5+1 commits）
401ee934  docs(quick-260612-daz): close v1.6 audit W1+W2
1768b43a  chore: archive v1.6 milestone files
27f0bc72  chore: remove REQUIREMENTS.md for v1.6 milestone
tag: v1.6
```

---

## 后续工作

- [ ] `/gsd-new-milestone` 启动下一 milestone（candidate themes 见 PROJECT.md Current State）
- [ ] 260609-ruu 购物表单重设计待真机确认（deferred §v1.6）
- [ ] Phases 37/38/39 draft-Nyquist：`/gsd-validate-phase` 可追溯关闭（第 7 次连续 milestone 出现，考虑接入 close flow 或正式放弃该 artifact）
- [ ] 37-REVIEW advisories（IN-01 `dynamic ledgerType` 等）v1.7+ cleanup

---

**创建时间:** 2026-06-12 10:39
**作者:** Claude (Fable 5)
