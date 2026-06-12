# Phase 37: Application Use Cases + Sync Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 37-application-use-cases-sync-integration
**Areas discussed:** Reorder sync policy, Remote un-complete, listType reject style, Apply-loop isolation

---

## Reorder sync policy

| Option | Description | Selected |
|--------|-------------|----------|
| 本地排序，不同步 | 拖拽只改本地 sortOrder；ReorderShoppingItemsUseCase 不推送 sync op。避免 op 爆发 + 重排竞态；DAO 已有兜底排序。 | ✓ |
| 共享排序，同步 | sortOrder 变化推送全家；更协作，但每次拖拽推 N 个 op + LWW 收敛复杂。 | |

**User's choice:** 本地排序，不同步 (recommended)
**Notes:** Cross-device shared ordering deferred out of v1.6. Reorder is the one mutation that does NOT touch the change tracker. → D37-01.

---

## Remote un-complete (completion-state merge)

| Option | Description | Selected |
|--------|-------------|----------|
| 主动取消可同步 | 显式取消勾选清空 completedAt + 带新 updatedAt，正常生效；非完成相关的编辑(改名/改价)走字段级 delta，不携带/不覆盖 isCompleted。sticky 只挡陈旧快照误取消。 | ✓ |
| 完全粘性，远程不可取消 | 已完成项对所有远程 op 免疫，只能本地取消。保护最强但反直觉。 | |

**User's choice:** 主动取消可同步 (recommended)
**Notes:** Extends locked D-03 sticky-complete. Implementation leaning: prefer delta-style update ops so a rename never carries stale isCompleted (planner to confirm against TransactionSyncMapper.toUpdateOperation). → D37-02 / D37-03.

---

## listType reject style (D6 / SYNC-03)

| Option | Description | Selected |
|--------|-------------|----------|
| 返回错误/抛 invariant | fail-fast；测试立刻抓违规调用。UI 不提供改 listType 入口，正常用户碰不到。 | ✓ |
| 静默 no-op | 忽略 listType、其余字段照常更新。更宽容但掩盖 bug。 | |

**User's choice:** 返回错误/抛 invariant (recommended)
**Notes:** Document the invariant inline in UpdateShoppingItemUseCase. → D37-04.

---

## Apply-loop isolation

| Option | Description | Selected |
|--------|-------------|----------|
| 仅 shopping 分支 try/catch 跳过 | 只给 shopping_item 分支加 try/catch + skip-and-continue；bill/profile/avatar 语义完全不变，零回归。下次 fullSync 兜底。 | ✓ |
| 保持现状(抛错中断整批) | 与 bill 一致；最简单，但一条坏 shopping 数据阻塞同批 bill apply。 | |

**User's choice:** 仅 shopping 分支 try/catch 跳过 (recommended)
**Notes:** Do not widen blast radius to existing branches. → D37-05.

---

## Claude's Discretion

- Exact `shopping_item` op wire payload field set (mirror bill mapper; sortOrder does NOT travel; note encryption-across-sync mirrors existing handling).
- `ShoppingItemChangeTracker` separate-instance vs folded; separate push call vs merged push (separate recommended, matches profile-ops pattern).
- `ClearCompletedItemsUseCase` per-item soft-delete → tombstone op via tracker (same path as single delete).
- Provider wiring shape (mirror state_sync.dart / repository_providers.dart); constructor change to ApplySyncOperationsUseCase is atomic THIS phase.

## Deferred Ideas

- Cross-device shared shopping-list ordering (sync sortOrder) — deferred out of v1.6 (D37-01).
- Tag-based filtering (v2 TAGFILT-01) — carried from Phase 36.
- Decimal/unit-bearing quantity — D8 / out of scope.
