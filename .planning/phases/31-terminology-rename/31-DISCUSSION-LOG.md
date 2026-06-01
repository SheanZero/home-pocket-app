# Phase 31: Terminology Rename - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 31-terminology-rename
**Areas discussed:** 重命名边界/scope, ARB key 命名约定, 派生颜色符号深度, ADR 记录策略

---

## 重命名边界 / Scope — LedgerType handling

| Option | Description | Selected |
|--------|-------------|----------|
| 不动，明确出界 | Keep `LedgerType.survival/.soul` — de-facto schema, already Out-of-Scope; rename only table-layer vocab + non-persisted identifiers | |
| 连枚举一起改 + 写 migration | Rename enum, change DB CHECK constraint, write Drift migration for existing rows, adjust sync | ✓ |

**User's choice:** 连枚举一起改 + 写 migration
**Notes:** Claude flagged the tension (contradicts locked Out-of-Scope line) and investigated hash-chain risk before accepting. Found `ledger_type` is NOT in the hash payload (`hash_chain_service.dart:18`), clearing the scariest blocker. Decision stands with REQUIREMENTS amendment required.

## 重命名边界 / Scope — P2P sync cross-version compat

| Option | Description | Selected |
|--------|-------------|----------|
| 加容错读取层 | Backward-compat mapping: accept both old `'survival'/'soul'` and new strings | |
| 不管，视为干净升级 | No compat layer; pre-release v0.1.0, no deployed old peers | ✓ |

**User's choice:** 不管，视为干净升级
**Notes:** Justified by pre-release status. CONTEXT notes to revisit before any real release.

## 重命名边界 / Scope — non-persisted file/class names

| Option | Description | Selected |
|--------|-------------|----------|
| 一并改，彻底一致 | Rename ~7 soul*/survival* files + classes via Serena rename_symbol + git mv | ✓ |
| 只改枚举+符号，保留文件/类名 | Leave class/file names; gate doesn't check them | |

**User's choice:** 一并改，彻底一致

---

## ARB key 命名约定 — overall convention

| Option | Description | Selected |
|--------|-------------|----------|
| 机械 token 替换 | s/soul/joy/, s/survival/daily/ preserving the rest | |
| 重新设计语义 key 命名 | Semantic redesign of key names | ✓ |

**User's choice:** 重新设计语义 key 命名

## ARB key 命名约定 — soulSatisfaction

| Option | Description | Selected |
|--------|-------------|----------|
| joySatisfaction（机械） | Pure token swap | |
| joyFullness（对齐 fullness） | Align key with 充盈度/fullness value semantics | ✓ |

**User's choice:** joyFullness

## ARB key 命名约定 — boundary

| Option | Description | Selected |
|--------|-------------|----------|
| 仅 ledger-vocab 相关键 | Only keys touching soul/survival vocab | |
| 顺手清理邻近键群 | Also normalize sibling keys in the same key-group | ✓ |

**User's choice:** 顺手清理邻近键群 (bounded: not a global 533-key retaxonomy)

## ARB key 命名约定 — naming principle

| Option | Description | Selected |
|--------|-------------|----------|
| concept token + 保留结构 | soul→joy/survival→daily, preserve prefix/structure, targeted semantic fixes | ✓ |
| 我列出映射表你过目 | Per-key approval at plan stage | |

**User's choice:** concept token + 保留结构 (full mapping table still surfaced in PLAN.md for visibility)

---

## 派生颜色符号深度

| Option | Description | Selected |
|--------|-------------|----------|
| 全部现在改，彻底一致 | Rename all derived symbols (Light, RoiBg/Border, SatisfactionBg/Border) in Phase 31 | ✓ |
| accent 现改，dark 常量留 P33 | Rename stable accents now, defer profile-dark constants to Phase 33 consolidation | |
| 只改 gate 要求的，其余全留 P33 | Only AppColors.survival/.soul; all derived to P33 | |

**User's choice:** 全部现在改，彻底一致
**Notes:** Phase 33 must treat these as already renamed (consolidate only, no re-rename). soulSatisfactionBg/Border → joyFullnessBg/Border to match the joyFullness key decision.

---

## ADR 记录策略 — location

| Option | Description | Selected |
|--------|-------------|----------|
| append 到 ADR-015 | Append an Update section to existing lexical-hierarchy ADR | |
| 新建 ADR-017 successor | New standalone ADR cross-linking ADR-015 | ✓ |

**User's choice:** 新建 ADR-017 successor

## ADR 记录策略 — content

| Option | Description | Selected |
|--------|-------------|----------|
| 记，含 schema 决策 | Record vocab mapping + identifier convention + LedgerType-rename-with-migration decision & rationale | ✓ |
| 只记词表映射 | Minimal TERMID-04 — vocab table only | |

**User's choice:** 记，含 schema 决策

---

## Claude's Discretion

- **Migration / commit sequencing** (big-bang vs staged) — delegated to planner, based on dependency graph. Hard constraint: every step keeps build green (analyze 0 / build_runner clean-diff / tests pass).
- **Test fixture + golden handling** — Phase 31 keeps the suite green; full golden re-baseline is Phase 34.

## Deferred Ideas

- Global ARB key retaxonomy (all ~533 keys) — own phase, not Phase 31.
- P2P sync backward-compat dual-string read path — revisit before public release.
- Color token consolidation (duplicate constant dedup) — Phase 33's job.
