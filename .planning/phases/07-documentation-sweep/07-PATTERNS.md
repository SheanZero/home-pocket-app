# Phase 7: Documentation Sweep — Pattern Map

**Mapped:** 2026-04-27
**Files analyzed:** 13 (docs to edit) + 3 (new files to create) = 16
**Analogs found:** 16 / 16 (all in-repo; pure-Markdown / shell phase)

> **Phase character:** Pure-Markdown documentation sweep. Zero Dart code, zero providers, zero generated files. The "patterns" here are heading conventions, append-only diffs, link/cross-ref formats, and shell-grep gates — every analog is an existing file in this repo.

---

## File Classification

### Modified files (existing — drift fixes)

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` | ARCH — global tech-stack/architecture narrative | request-response (reader → doc) | self (in-place edits) | n/a — edit-in-place |
| `docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md` | ARCH — ASCII diagram document | request-response | self | n/a — edit-in-place |
| `docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md` | ARCH — layer-rule narrative | request-response | self | n/a — edit-in-place |
| `docs/arch/02-module-specs/MOD-006_Analytics.md` | MOD — module spec | request-response | self | n/a — edit-in-place |
| `docs/arch/02-module-specs/MOD-007_Settings.md` | MOD — module spec | request-response | self | n/a — edit-in-place |
| `docs/arch/02-module-specs/MOD-008_Gamification.md` | MOD — module spec | request-response | self | n/a — edit-in-place |
| `docs/arch/02-module-specs/MOD-009_VoiceInput.md` | MOD — module spec | request-response | self | n/a — edit-in-place |
| `docs/arch/02-module-specs/MOD-002_DualLedger.md` | MOD — module spec | request-response | self | n/a — edit-in-place |
| `docs/arch/05-UI/UI-001_Page_Inventory.md` | UI inventory doc | request-response | self | n/a — edit-in-place |
| `docs/arch/03-adr/ADR-002_Database_Solution.md` | ADR — append-only update | event-driven (decision history) | `ADR-006_Key_Derivation_Security.md` (already-implemented ADR with status update) | role-match |
| `docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` | ADR — append-only update | event-driven | `ADR-006` (status-update precedent) | role-match |
| `docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` | ADR — append-only update | event-driven | `ADR-006` | role-match |
| `docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` | ADR — append-only update | event-driven | `ADR-006` | role-match |
| `docs/arch/01-core-architecture/ARCH-000_INDEX.md` | INDEX — master index table | catalog | self | n/a — edit-in-place |
| `docs/arch/03-adr/ADR-000_INDEX.md` | INDEX — ADR-only catalog | catalog | self (existing entry style) | exact |
| `docs/arch/README.md` | README — directory overview | request-response | self | n/a — full rewrite to match actual file list |
| `CLAUDE.md` | Project instructions — Common Pitfalls + Key References | reference | self (existing 13-item list at lines 263-277) | exact |
| `.claude/rules/arch.md` | Project rule file — path-spelling fix | reference | self | n/a — sed-style replacement |

### New files (create)

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|---------------|
| `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` | ADR — new historical decision record | event-driven | `docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` (most recent ADR; same template) | exact |
| `docs/arch/02-module-specs/MOD-000_INDEX.md` | Stub — pointer to canonical INDEX | catalog | `docs/arch/01-core-architecture/ARCH-000_INDEX.md` (master) + `docs/arch/03-adr/ADR-000_INDEX.md` (sibling) | exact |
| `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` | Shell gate — multi-grep verifier | batch (CLI exit code) | `scripts/build_coverage_baseline.sh` (multi-step, `set -euo pipefail`, exit-on-fail pattern) | role-match |
| `scripts/verify_index_health.sh` | Shell gate — INDEX link/orphan check loop | batch | `scripts/audit_layer.sh` + `scripts/build_coverage_baseline.sh` (mixed: simple wrapper vs. richer pipeline) | role-match |

---

## Pattern Assignments

### `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` (NEW ADR — exact analog: ADR-010)

**Analog:** `docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md`

**Frontmatter pattern** (ADR-010 lines 1-19) — **mirror exactly, swap fields**:

```markdown
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
```

**Section header pattern** (ADR-010 lines 21, 187, 1084, 1165, 1408):
- `## 🎯 背景 (Context)` — required
- `## 🔍 考虑的方案 (Considered Options)` — required
- `## 💡 推荐方案` (or `## ✅ 已决策的问题`) — for the decision body
- `## 🔧 实施细节` — required (used for "Cleanup Outcome" + "*.mocks.dart Strategy" + "Ongoing CI Enforcement" subsections)
- `## 📝 下一步行动` — for "Out of Scope / Deferred"

**`.claude/rules/arch.md` ADR template** (rule lines 109-117) requires these 8 sections:
1. 标题和编号 (already in frontmatter)
2. 状态 (Status)
3. 背景 (Context)
4. 考虑的方案 (Considered Options)
5. 决策 (Decision)
6. 决策理由 (Rationale)
7. 后果 (Consequences)
8. 实施计划 (Implementation Plan)

**Bilingual convention** (ADR-010 throughout):
- Chinese section headings (`## 🎯 背景`, `## 🔍 考虑的方案`)
- English code identifiers in fenced blocks (`Transaction`, `VectorClock`, `resolveConflict`)
- Decision-driver headings can be English-in-parens: `## 🎯 背景 (Context)`

**Cross-reference link pattern** (ADR-010 line 9):
```markdown
**相关 ADR:** ADR-004 (CRDT Sync Protocol)
```
For ADR-011 use:
```markdown
**相关 ADR:** ADR-002 (Database Solution), ADR-007 (Layer Responsibilities), ADR-008/009/010 (实施推迟)
```

**Internal link convention** (ADR-010 line 25): When citing other docs, use relative paths from the ADR's own directory:
```markdown
（`ARCH-005_Integration_Patterns.md` 和 `ADR-004_CRDT_Sync.md`）
```
ADR-011 will cite `audit.yml`, `lib/import_guard.yaml`, `pubspec.yaml`, `STATE.md`, `issues.json` — use the same backtick-with-relative-path style.

**CI gate citation pattern** (D-CONTEXT requires line citations) — invent a row pattern not in ADR-010 but compatible:
```markdown
| Gate | File:Line | Purpose |
|------|-----------|---------|
| AUDIT-09 SQLCipher | `.github/workflows/audit.yml:64-69` | Rejects sqlite3_flutter_libs in pubspec.lock |
| AUDIT-10 build_runner | `.github/workflows/audit.yml:81-89` | Blocks PRs with stale generated files |
```

---

### `docs/arch/03-adr/ADR-002_Database_Solution.md` (APPEND-ONLY UPDATE — D-06 locks pattern)

**Analog:** none in `docs/arch/03-adr/` has a "## Update" precedent yet — Plan 07-02 establishes the precedent. Closest stylistic analog is ADR-002's own existing `## 变更历史` (line ~622, format below) and the rule in `.claude/rules/arch.md:171-173` ("文档废弃: 不删除文件，在文档头部添加 [已废弃] 标记").

**Append-section pattern** (define-here, locked by D-06):

```markdown
---

## Update 2026-04-27: Cleanup Initiative Outcome

**Cross-reference:** [ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

Phases 3–6 of the codebase cleanup initiative changed how this decision is enforced
in production:

- `sqlite3_flutter_libs` is now actively rejected by CI gate AUDIT-09
  (`.github/workflows/audit.yml:64-69`) and by `lib/import_guard.yaml:5`.
- Only `sqlcipher_flutter_libs` is permitted; the original ADR-002 dual-listing of
  both libraries is **historical context only**.

The original decision body above is preserved verbatim per ADR append-only convention
(`.claude/rules/arch.md:171-173`).
```

**Append rules** (D-06):
1. Section header is exactly `## Update {YYYY-MM-DD}: Cleanup Initiative Outcome`.
2. Goes at the **bottom** of the file, after `## 变更历史` (or whatever the last section is).
3. **Never** modifies any line above the new section.
4. Cross-references ADR-011 via relative link.

**Acceptance grep** (per D-06):
```bash
grep -B1 "## Update.*Cleanup" docs/arch/03-adr/ADR-002_Database_Solution.md
# Must return the appended section.
```

**Diff guard:**
```bash
# Lines removed from existing decision body must be 0
git diff docs/arch/03-adr/ADR-002_Database_Solution.md | grep -cE '^-[^-]' | grep -q '^0$'
```

---

### `docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` (APPEND-ONLY)

Same pattern as ADR-002 above. Use:

```markdown
## Update 2026-04-27: Cleanup Initiative Outcome

**Cross-reference:** [ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

Phase 3 centralization moved repository implementations from
`lib/features/accounting/data/repositories/` to `lib/data/repositories/`. The code
samples in this ADR (lines ~830) reflect the pre-cleanup layout; the post-cleanup
location is `lib/data/repositories/transaction_repository_impl.dart`.
```

---

### `docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` (APPEND-ONLY)

Same pattern. Footnote that line 37 reference to `lib/features/accounting/data/repositories/transaction_repository_impl.dart` reflects pre-Phase-3 layout.

---

### MOD-006/007/008/009 + MOD-002 (in-place edits — DOCS-01)

**Analog:** self. These are find-and-replace fixes, not structural rewrites.

**Replacement-token table** (concrete tokens to replace, derived from RESEARCH §"Drift Inventory"):

| Stale token | Replacement | Notes |
|-------------|-------------|-------|
| `lib/features/{f}/use_cases/` | `lib/application/{domain}/` | Verify each via `find lib/application/` before commit (A4) |
| `lib/features/{f}/application/use_cases/` | `lib/application/{domain}/` | Same |
| `lib/features/{f}/data/repositories/` | `lib/data/repositories/` | Verified target exists |
| `package:mockito/mockito.dart` | `package:mocktail/mocktail.dart` | Per Phase 4-04 |
| `@GenerateMocks(...)` | (delete; mocktail needs no annotation) | |
| `*_test.mocks.dart` | (delete the import; runtime mocks only) | |
| `MockX = MockX()` (mockito-style) | `class MockX extends Mock implements X` (mocktail-style) | |
| `sqlite3_flutter_libs` | `sqlcipher_flutter_libs` (or delete the line entirely if duplicate) | D2-8 wants line deletion |
| `MOD-014_i18n.md` | `BASIC-003_I18N_Infrastructure.md` (path) | D5 |
| `MOD-014` (label) | `BASIC-003` (label) | D5 |

**Per-file acceptance grep** (DOCS-01):
```bash
grep -rn "features/[a-z_]*/use_cases\|features/[a-z_]*/data/repositories\|mockito\|@GenerateMocks\|sqlite3_flutter_libs\|MOD-014" \
  docs/arch/01-core-architecture/ docs/arch/02-module-specs/ docs/arch/05-UI/
# Expected: 0 hits.
```

---

### `CLAUDE.md` Common Pitfalls — annotation pattern (DOCS-02)

**Analog:** self. The existing 13-item numbered list at `CLAUDE.md:263-277` is the structure to preserve.

**Existing list excerpt** (CLAUDE.md lines 263-277):

```markdown
## Common Pitfalls

1. Don't modify generated files (`.g.dart`, `.freezed.dart`)
2. Don't violate layer dependencies (Domain must not import Data)
3. Don't skip code generation after modifying annotated classes
4. Don't mutate objects — always use `copyWith`
5. Don't use `intl` version other than 0.20.2 (pinned by flutter_localizations)
6. Don't add `sqlite3_flutter_libs` (use only `sqlcipher_flutter_libs`)
7. Don't modify Podfile `post_install` without preserving EXCLUDED_ARCHS fix
8. Don't commit with analyzer warnings
9. Don't hardcode widget parameter defaults — use nullable + provider fallback
10. Don't duplicate repository provider definitions
11. Don't use wrong Drift index syntax — use `TableIndex` with `{#column}`
12. Don't skip AppInitializer — initialize core services before `runApp()`
13. Don't forget to regenerate code after merge/pull
```

**Annotation pattern** (locked by CONTEXT D-CONTEXT, RESEARCH §"CLAUDE.md annotation format"):

```markdown
1. Don't modify generated files (`.g.dart`, `.freezed.dart`)
   *[Partially enforced — AUDIT-10 CI catches stale committed files; hand-edits matching generator output go undetected]*
2. Don't violate layer dependencies (Domain must not import Data)
   *[Structurally enforced — import_guard via custom_lint + arch test domain_import_rules_test.dart]*
```

**Annotation tag must be one of three exact strings** (case + dash matter):
- `*[Structurally enforced — {mechanism}]*`
- `*[Partially enforced — {mechanism}]*`
- `*[Manually-checked only — {reason}]*`

**Format constraints:**
- Italics (single asterisk on each side, then square brackets).
- Indented 3 spaces under the numbered item.
- Em-dash (`—`, not `--` or `-`) between status and mechanism.
- Mechanism is concrete: file path or test name or CI gate ID.

**Acceptance grep** (DOCS-02):
```bash
# Every numbered pitfall must have an annotation immediately below
grep -A1 "^[0-9]\+\. Don't" CLAUDE.md | grep -cE '^\s+\*\[(Structurally|Partially) enforced|Manually-checked only'
# Expected: 13
```

**Pitfall-to-annotation map** (locked, per CONTEXT §"Pitfall enforcement classification"):

| # | Annotation tag |
|---|----------------|
| 1 | `*[Partially enforced — AUDIT-10 catches stale committed files; hand-edits matching generator output go undetected]*` |
| 2 | `*[Structurally enforced — import_guard via custom_lint + arch test domain_import_rules_test.dart]*` |
| 3 | `*[Structurally enforced — AUDIT-10 CI guardrail blocks PRs with stale generated files]*` |
| 4 | `*[Manually-checked only — freezed enforces it on @freezed classes; general mutation undetected]*` |
| 5 | `*[Structurally enforced — exact pin in pubspec.yaml line 18]*` |
| 6 | `*[Structurally enforced — import_guard deny rule + AUDIT-09 CI guardrail]*` |
| 7 | `*[Manually-checked only — no Podfile lint; relies on reviewer + iOS build verification]*` |
| 8 | `*[Structurally enforced — flutter analyze CI step (audit.yml line 34)]*` |
| 9 | `*[Manually-checked only — no automated detection]*` |
| 10 | `*[Structurally enforced — arch test provider_graph_hygiene_test.dart + riverpod_lint]*` |
| 11 | `*[Manually-checked only — Drift compiler does not enforce naming or symbol-syntax conventions]*` |
| 12 | `*[Partially enforced — provider_graph_hygiene_test.dart catches UnimplementedError providers; "forgot to call initialize()" is manual]*` |
| 13 | `*[Structurally enforced — AUDIT-10 CI guardrail catches stale generated files post-merge]*` |

---

### `CLAUDE.md` Key References + path drift (D4)

**Analog:** self (existing CLAUDE.md links at lines 190, 220, 227, 255-258 — all currently use the broken singular `doc/arch/`).

**Existing broken excerpt** (CLAUDE.md line 255-258):
```markdown
- **Architecture:** `doc/arch/01-core-architecture/ARCH-001_Complete_Guide.md`
- **Data:** `doc/arch/01-core-architecture/ARCH-002_Data_Architecture.md`
- **Security:** `doc/arch/01-core-architecture/ARCH-003_Security_Architecture.md`
- **State:** `doc/arch/01-core-architecture/ARCH-004_State_Management.md`
```

**Replacement** (mirror exactly, swap `doc/arch/` → `docs/arch/`):
```markdown
- **Architecture:** `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md`
- **Data:** `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md`
- **Security:** `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md`
- **State:** `docs/arch/01-core-architecture/ARCH-004_State_Management.md`
```

**Existing broken excerpt** (CLAUDE.md line 190):
```markdown
**Spec:** `doc/arch/02-module-specs/MOD-014_i18n.md`
```

**Replacement** (D-01 locks: phantom MOD-014 → BASIC-003):
```markdown
**Spec:** `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md`
```

**Existing broken excerpt** (CLAUDE.md line 220):
```markdown
1. **Infrastructure:** MOD-006 Security, MOD-014 i18n
```

**Replacement** (D-01):
```markdown
1. **Infrastructure:** MOD-006 Security, BASIC-003 i18n
```

**Acceptance grep** (combined D4 + D5):
```bash
grep -nE 'doc/arch[^/]' CLAUDE.md      # → 0 hits
grep -n 'MOD-014' CLAUDE.md            # → 0 hits
```

---

### `.claude/rules/arch.md` (D-03 path-spelling fix)

**Analog:** self. ~10 occurrences of `doc/arch/` (singular) per RESEARCH D4-4. Mechanical replacement.

**Acceptance grep** (D-03):
```bash
grep -nE 'doc/arch[^/]' .claude/rules/arch.md
# Expected: 0 hits.
```

**Diff size guard** (sanity):
```bash
git diff --stat .claude/rules/arch.md | tail -1 | awk '{print $4}'
# Expected: ≈10 (matches RESEARCH §D4-4 site count)
```

---

### `docs/arch/01-core-architecture/ARCH-000_INDEX.md` — INDEX entry pattern

**Analog:** self (most recent entries at lines 32-49). Used as the **template for any new INDEX entry**.

**Existing entry pattern** (ARCH-000_INDEX.md lines 32-40 — module table row):

```markdown
| 🔹 MOD-001 基础记账 | [MOD-001_BasicAccounting.md](../02-module-specs/MOD-001_BasicAccounting.md) | PRD_Module_BasicAccounting.md | 13天 | ✅ 完成 |
```

**Existing entry pattern** (ARCH-000_INDEX.md lines 42-49 — BASIC table row):

```markdown
| BASIC-003 I18N 基础设施 | [BASIC-003_I18N_Infrastructure.md](../04-basic/BASIC-003_I18N_Infrastructure.md) | 国际化基础设施实现规范 | ✅ 已有 |
```

**Existing entry pattern** (ARCH-000_INDEX.md line 36 — deprecated row, RESEARCH §INDEX-Health-A C):

```markdown
| ~~🔹 MOD-005 安全隐私~~ | ~~文件不存在~~ | ~~编号跳过~~ | — | ⚠️ 缺失 |
```

This **strikethrough + ⚠️ 缺失** pattern is the canonical "deprecated entry" style. Per `.claude/rules/arch.md:171-173` deprecated docs get `[已废弃]`; INDEX entries use strikethrough.

**Acceptance gate** (Plan 07-04 — INDEX health):
```bash
# (A) Every linked file exists
for f in $(grep -oE '\(\.\./[^)]+\.md\)' docs/arch/01-core-architecture/ARCH-000_INDEX.md | tr -d '()'); do
  test -f "docs/arch/01-core-architecture/$f" || echo "BROKEN: $f"
done
# Expected: 0 lines printed.

# (B) Every file in dir is in INDEX (excluding INDEX itself)
ls docs/arch/01-core-architecture/*.md | grep -v INDEX | while read f; do
  base=$(basename "$f")
  grep -q "$base" docs/arch/01-core-architecture/ARCH-000_INDEX.md || echo "ORPHAN: $base"
done
# Expected: 0 lines printed.
```

---

### `docs/arch/03-adr/ADR-000_INDEX.md` — ADR-only catalog (DOCS-04 ADR-011 entry)

**Analog:** self. Entry style at ADR-000_INDEX.md lines 16-37 (ADR-001 block) is the template.

**Existing entry pattern** (ADR-000_INDEX.md lines 16-37):

```markdown
### [ADR-001: 选择Riverpod作为状态管理方案](./ADR-001_State_Management.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** 整个应用的状态管理层

**核心决策:**
选择 **flutter_riverpod 2.x** 作为状态管理方案

**关键理由:**
- 编译时类型安全
- 自动依赖注入
- 优秀的DevTools支持
- 代码生成减少样板代码
- 测试友好

**备选方案:**
- flutter_bloc (样板代码过多)
- GetX (类型安全性差)
- Provider (功能较弱)

**下次Review:** 2026-08-03

---
```

**ADR-011 entry to add** (Plan 07-05 — mirror exact structure):

```markdown
### [ADR-011: Codebase Cleanup Initiative Outcome](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

**状态:** ✅ 已接受
**日期:** 2026-04-27
**影响范围:** 全局重构（Phases 3–6）, CI 守门, 测试基础设施

**核心决策:**
记录 Phases 3–6 重构的最终状态、`*.mocks.dart` 策略、以及永久性 CI 守门机制。

**关键理由:**
- Phase 3-6 完成 87 项 finding 修复（CRITICAL/HIGH/MEDIUM/LOW 全部关闭）
- Mocktail big-bang 替换 mockito（Phase 4-04）
- 8 项 CI 守门常驻 `.github/workflows/audit.yml`

**备选方案:**
- 不写 ADR（拒绝：未来贡献者无法理解 CI 守门动机）
- 拆为多份 ADR（拒绝：三个子主题强相关，分拆失去整体性）

**下次Review:** 2026-10-27 (每半年)

---
```

**Acceptance grep** (DOCS-04):
```bash
grep -q "ADR-011" docs/arch/03-adr/ADR-000_INDEX.md
test -f docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md
```

---

### `docs/arch/02-module-specs/MOD-000_INDEX.md` (NEW — D-04 stub-with-pointer)

**Analog:** the existing two index files combined:
- `docs/arch/01-core-architecture/ARCH-000_INDEX.md` (master — already lists every MOD file at lines 30-40)
- `docs/arch/03-adr/ADR-000_INDEX.md` (sibling INDEX style)

**Concrete content** (locked verbatim by D-04):

```markdown
# MOD Index

This directory's master index lives in [ARCH-000_INDEX.md](../01-core-architecture/ARCH-000_INDEX.md) — see the "功能模块技术文档" section.
```

**Why this exact form** (D-04 rationale):
- DOCS-03 literally says "ARCH-000, ADR-000, MOD-000" — strict reading needs the file.
- Full duplication of ARCH-000's MOD table creates two-source-of-truth drift.
- 3-line stub satisfies the requirement at minimal cost.

**Acceptance:**
```bash
test -f docs/arch/02-module-specs/MOD-000_INDEX.md
# Plus: file is referenced by scripts/verify_index_health.sh INDEX loop
```

---

### `docs/arch/README.md` (D6 — sync to actual file list)

**Analog:** self (lines 1-49 are the existing structure). RESEARCH §INDEX-Health-D6 lists the exact bugs.

**Existing broken excerpt** (README.md lines 1, 11, 36, 82):
- Line 1: `# Home Pocket MVP - 架构技术文档 (arch2)` — title says `arch2`
- Line 11: `本目录采用模块化架构文档组织结构...arch2/` — same
- Line 36: `MOD-009_Internationalization.md` — phantom (file is MOD-009_VoiceInput.md)
- Line 26: `ARCH-009_I18N_Update_Summary.md` — phantom (only 8 ARCH files exist)
- Line 82: `MOD-009 - 国际化多语言` — wrong description

**Replacement** (sync directory tree to actual `ls` output):
- Replace `arch2/` → `docs/arch/` everywhere.
- Drop the phantom `ARCH-009_I18N_Update_Summary.md` line.
- Drop the phantom `MOD-009_Internationalization.md`; replace MOD list to match `ls docs/arch/02-module-specs/`.
- Replace `MOD-009 - 国际化多语言` with `MOD-009 - 语音记账`.
- Add `04-basic/BASIC-001..004` subsection (currently absent).

**Acceptance:**
```bash
# Phantom file references gone
grep -nE 'arch2/|MOD-009_Internationalization|ARCH-009_I18N_Update_Summary|国际化多语言' docs/arch/README.md
# Expected: 0 hits.

# Every file mentioned exists
for f in $(grep -oE '[A-Z]+-[0-9]+_[A-Z][A-Za-z_]+\.md' docs/arch/README.md | sort -u); do
  find docs/arch -name "$f" -type f | grep -q . || echo "MISSING: $f"
done
```

---

### `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` (NEW — Wave 0 gate)

**Analog:** `scripts/build_coverage_baseline.sh` (richest existing shell pipeline; uses `set -euo pipefail`, multi-step `echo`, exit-on-fail file checks).

**Excerpt to mirror** (build_coverage_baseline.sh lines 1-13):

```bash
#!/usr/bin/env bash
# scripts/build_coverage_baseline.sh
# Local end-to-end run of the Phase 2 coverage baseline pipeline
# (mirrors the audit.yml `coverage` job). Produces the four
# .planning/audit/coverage-* artifacts.
#
# Steps:
#   1. flutter test --coverage              → coverage/lcov.info
#   2. coverde filter (strip generated)     → coverage/lcov_clean.info
#   3. dart run scripts/coverage_baseline   → 4 .planning/audit/ artifacts
#   4. Verify all four artifact files exist

set -euo pipefail
```

**Concrete `verify-doc-sweep.sh` body** (locked verbatim by RESEARCH §"Code Examples", D-07):

```bash
#!/usr/bin/env bash
# .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
# Verifies that documentation drift is fully remediated.
# Exits 0 only when ALL drift gates pass.

set -euo pipefail
fail=0

echo "[1/6] Checking layer-centralization drift..."
hits=$(grep -rn "features/[a-z_]*/use_cases\|features/[a-z_]*/data/repositories" docs/arch/ | grep -v "^docs/arch/03-adr/.*## Update" | wc -l)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits stale layer paths in docs/arch/"; fail=1; } || echo "  OK"

echo "[2/6] Checking mockito drift..."
hits=$(grep -rn "package:mockito\|@GenerateMocks\|\.mocks\.dart" docs/arch/ | grep -v "^docs/arch/03-adr/.*## Update" | wc -l)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits mockito references"; fail=1; } || echo "  OK"

echo "[3/6] Checking sqlite3_flutter_libs drift in non-historical contexts..."
hits=$(grep -rn "sqlite3_flutter_libs" docs/arch/ | grep -v "^docs/arch/03-adr/" | wc -l)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits sqlite3_flutter_libs in non-ADR docs"; fail=1; } || echo "  OK"

echo "[4/6] Checking doc/arch path drift in CLAUDE.md and rules..."
hits=$(grep -cE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null || true)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits 'doc/arch' references"; fail=1; } || echo "  OK"

echo "[5/6] Checking MOD-014 phantom references..."
hits=$(grep -rn "MOD-014_i18n\.md\|MOD-014 i18n" docs/arch/ CLAUDE.md | wc -l)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits phantom MOD-014 file references"; fail=1; } || echo "  OK"

echo "[6/6] Checking ADR-011 presence..."
test -f docs/arch/03-adr/ADR-011_*.md || { echo "  FAIL: ADR-011 missing"; fail=1; }
grep -q "ADR-011" docs/arch/03-adr/ADR-000_INDEX.md || { echo "  FAIL: ADR-011 not indexed"; fail=1; }
[ "$fail" -eq 0 ] && echo "  OK"

exit $fail
```

**Pattern principles mirrored from analog:**
1. Shebang `#!/usr/bin/env bash` (matches `scripts/audit_*.sh`).
2. Header comment block: file path on line 2, purpose on line 3-4.
3. `set -euo pipefail` immediately after header.
4. Numbered step echo: `echo "[N/M] Checking ..."` — same shape as `[coverage:baseline] running ...` in build_coverage_baseline.sh.
5. Exit non-zero on any failure (not via `exit 1` mid-script — accumulator pattern via `fail=1` so all gates run).

**Setup acceptance** (D-07):
```bash
chmod +x .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
# First commit in Plan 07-01: script exists + currently exits non-zero (drift still present)
bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh; [ $? -ne 0 ]  # expected at start
# Phase close: same script exits 0
```

---

### `scripts/verify_index_health.sh` (NEW — INDEX link/orphan loop)

**Analog:** `scripts/audit_layer.sh` for the wrapper shape; `scripts/build_coverage_baseline.sh` for multi-check structure. RESEARCH §"Code Examples" provides the body verbatim.

**Concrete body** (locked by RESEARCH §"Code Examples"):

```bash
#!/usr/bin/env bash
# scripts/verify_index_health.sh
# Confirms every link in INDEX files points to a real file,
# and every file in the directory is mentioned in INDEX.

set -euo pipefail
fail=0

check_dir() {
  local dir=$1
  local index=$2
  echo "Checking $dir against $index..."

  # (A) Broken-link check
  while read -r path; do
    full="$dir/$(basename "$path")"
    if [ ! -f "$full" ]; then
      echo "  BROKEN LINK in $index: $path"
      fail=1
    fi
  done < <(grep -oE '\([^)]+\.md\)' "$index" | tr -d '()' | grep -v '^http' | sort -u)

  # (B) Orphan-file check
  for f in "$dir"/*.md; do
    base=$(basename "$f")
    [ "$base" = "$(basename "$index")" ] && continue
    if ! grep -q "$base" "$index"; then
      echo "  ORPHAN: $base not listed in $index"
      fail=1
    fi
  done
}

check_dir docs/arch/01-core-architecture docs/arch/01-core-architecture/ARCH-000_INDEX.md
check_dir docs/arch/03-adr docs/arch/03-adr/ADR-000_INDEX.md
[ -f docs/arch/02-module-specs/MOD-000_INDEX.md ] && check_dir docs/arch/02-module-specs docs/arch/02-module-specs/MOD-000_INDEX.md

exit $fail
```

**Mirrored conventions:**
1. Shebang + header comment block (same as audit shell scripts).
2. `set -euo pipefail` (same as `scripts/build_coverage_baseline.sh:13`).
3. Function-then-driver structure (richer than the 5-line audit_layer.sh wrappers).
4. Conditional `[ -f ... ] && check_dir ...` for the optional MOD-000 INDEX (Plan 07-04 creates it).

**Acceptance:**
```bash
chmod +x scripts/verify_index_health.sh
bash scripts/verify_index_health.sh
# Expected: 0 BROKEN/ORPHAN lines printed; exit 0
```

---

## Shared Patterns

### Cross-cutting Pattern A: ADR Bilingual Heading Style

**Source:** All `docs/arch/03-adr/ADR-*.md` files (verified via `grep -nE '^## '` on ADR-002 and ADR-010).

**Apply to:** ADR-011 creation; "## Update" appendices to ADR-002/008/010 (the appendix uses English heading per D-06 lock; the rest of ADR-011 follows the ADR-010 bilingual convention).

**Convention:**
- Top-level Chinese heading with optional emoji + English-in-parens for technical clarity:
  - `## 🎯 背景 (Context)`
  - `## 🔍 考虑的方案 (Considered Options)`
  - `## 💡 推荐方案`
- Appendix headings use English (per D-06 locked format `## Update {YYYY-MM-DD}: Cleanup Initiative Outcome`).

---

### Cross-cutting Pattern B: Cross-Reference Link Style

**Source:** `docs/arch/01-core-architecture/ARCH-000_INDEX.md:32` and `docs/arch/03-adr/ADR-000_INDEX.md:16`.

**Apply to:** Every doc that links to another doc in `docs/arch/`.

**Convention:**
- INDEX files use `[Title](./relative-path.md)` from same dir or `[Title](../sibling-dir/file.md)` for cross-section.
- Inline body references use backticked filenames or `[Display Text](./relative)`.
- Never use absolute paths or `docs/arch/` prefix from inside `docs/arch/*` files.

**Examples to copy:**
```markdown
[ARCH-001_Complete_Guide.md](./ARCH-001_Complete_Guide.md)              <!-- same dir -->
[MOD-001_BasicAccounting.md](../02-module-specs/MOD-001_BasicAccounting.md)  <!-- cross-section -->
[ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)             <!-- short-form display -->
```

---

### Cross-cutting Pattern C: Append-Don't-Mutate (D-06)

**Source:** `.claude/rules/arch.md:171-173` ("文档废弃: 不删除文件，在文档头部添加 [已废弃] 标记") + RESEARCH §"Pattern 2".

**Apply to:** ADR-002, ADR-007, ADR-008, ADR-010 in Plan 07-02.

**Mechanism:**
1. Read the existing ADR top-to-bottom.
2. **Do not** edit any line in the existing body.
3. Append a `## Update {YYYY-MM-DD}: Cleanup Initiative Outcome` section at file end (after `## 变更历史` if present).
4. Cross-reference ADR-011 from inside the new section.

**Diff guard** (per-commit acceptance):
```bash
git diff docs/arch/03-adr/ADR-002_Database_Solution.md \
  | awk '/^---/{f=1} /^\+\+\+/{f=2} /^@@/{c++} f==2 && c==1' \
  | head -1
# First @@ hunk should start at the file end (insertion at last line), not in the body.
```

---

### Cross-cutting Pattern D: lib/-clean Commits (D-08)

**Apply to:** Every Phase 7 commit, regardless of plan.

**Mechanism:** Per-commit pre-push check:
```bash
git diff --name-only HEAD~ HEAD | grep -E '^(lib/|test/|pubspec|\.github/|analysis_options)' | wc -l
# Expected: 0
```

**Files-modified frontmatter constraint** (every plan in Phase 7):
- Allowed: `docs/`, `CLAUDE.md`, `.claude/rules/`, `.planning/phases/07-documentation-sweep/`, `scripts/verify_index_health.sh`.
- Forbidden: anything else.

---

## No Analog Found

None. Every output file has a closely-matching analog already in the repo:

| File | Analog basis |
|------|--------------|
| ADR-011 | ADR-010 template + ADR-002 status convention |
| MOD-000_INDEX.md stub | ARCH-000 / ADR-000 sibling style |
| verify-doc-sweep.sh | scripts/build_coverage_baseline.sh |
| scripts/verify_index_health.sh | scripts/audit_*.sh wrappers |
| All in-place edits | self (find-and-replace via grep gates) |

This is expected for a pure-Markdown sweep phase: the codebase already encodes every pattern needed.

---

## Metadata

**Analog search scope:**
- `docs/arch/01-core-architecture/` (9 files)
- `docs/arch/02-module-specs/` (8 files)
- `docs/arch/03-adr/` (11 files)
- `docs/arch/04-basic/` (4 files)
- `docs/arch/README.md`
- `CLAUDE.md`
- `.claude/rules/arch.md`
- `scripts/` (15 files; focus on `audit_*.sh` and `build_coverage_baseline.sh`)
- `.planning/phases/07-documentation-sweep/` (existing 07-CONTEXT.md, 07-RESEARCH.md)

**Files scanned:** ≈50 (heading scans via grep; full reads of ADR-010, ARCH-000_INDEX, ADR-000_INDEX, BASIC-003 head, CLAUDE.md target sections, README.md, build_coverage_baseline.sh, audit_*.sh).

**Pattern extraction date:** 2026-04-27.

**Read budget consumed:** ~7 file reads + ~6 grep scans, no re-reads. No file > 2000 lines was loaded in full.
