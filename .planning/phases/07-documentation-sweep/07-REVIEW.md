---
phase: 07-documentation-sweep
reviewed: 2026-04-27T00:00:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - .claude/rules/arch.md
  - CLAUDE.md
  - docs/arch/01-core-architecture/ARCH-000_INDEX.md
  - docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md
  - docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md
  - docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md
  - docs/arch/02-module-specs/MOD-000_INDEX.md
  - docs/arch/02-module-specs/MOD-002_DualLedger.md
  - docs/arch/02-module-specs/MOD-006_Analytics.md
  - docs/arch/02-module-specs/MOD-007_Settings.md
  - docs/arch/02-module-specs/MOD-008_Gamification.md
  - docs/arch/02-module-specs/MOD-009_VoiceInput.md
  - docs/arch/03-adr/ADR-000_INDEX.md
  - docs/arch/03-adr/ADR-002_Database_Solution.md
  - docs/arch/03-adr/ADR-007_Layer_Responsibilities.md
  - docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md
  - docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md
  - docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md
  - docs/arch/05-UI/UI-001_Page_Inventory.md
  - docs/arch/README.md
  - scripts/verify_index_health.sh
  - .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
findings:
  critical: 0
  warning: 5
  info: 6
  total: 11
status: issues_found
---

# Phase 07: Code Review Report

**Reviewed:** 2026-04-27
**Depth:** standard
**Files Reviewed:** 22 (20 markdown + 2 shell scripts)
**Status:** issues_found

## Summary

Phase 7 successfully removed the targeted drift it set out to fix (mockito, `sqlite3_flutter_libs`, MOD-014 phantom file, layer-centralization paths in non-ADR docs, `doc/arch/` singular spelling in CLAUDE.md/rules). ADR-011 is well-structured, and all four append-only ADR updates (ADR-002/007/008/010) preserve the original decision bodies verbatim. CI line citations in ADR-011 (`audit.yml:38`, `:41`, `:69-75`, `:79-84`, `:100-105`, `:108`) all point at the correct lines.

However, the review surfaces several real defects:

- **The new `verify-doc-sweep.sh` gate 4 is structurally broken** — it always prints "OK" regardless of whether `doc/arch/` drift exists, because `grep -cE` against multiple files emits per-file `file:count` pairs rather than a summed integer, and the resulting `[ -gt 0 ]` test fails with a stderr error that gets swallowed by the `||` branch. This is a BLOCKER-class defect for the gate's stated purpose; the gate cannot detect future drift.
- **Three of the four append-only ADRs (ADR-002, ADR-008, ADR-010) leave a stray metadata line trailing after the appended Update section**, breaking the "appended at file end" contract.
- **ADR-000_INDEX.md and docs/arch/README.md statistics tables were not updated** when ADR-011 was added — they still report 10 ADRs / total 30 / 32 documents respectively.
- **All four append-only updates cite `.claude/rules/arch.md:171-173` for an "ADR append-only convention" that does not exist** at those lines (or anywhere) in the rules file.
- **`scripts/verify_index_health.sh` has a latent empty-glob bug** that would mis-report a literal `*.md` filename if any monitored directory ever empties.

Pre-existing drift acknowledged in ADR-011 ("Out of Scope / Deferred") — most notably the MOD numbering drift inside MOD-002/006/007/008 internal headers — is correctly documented and not in this phase's scope.

## Warnings

### WR-01: verify-doc-sweep.sh gate 4 is structurally unable to detect `doc/arch/` drift

**File:** `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh:21-23`
**Issue:** Gate 4 always prints `OK` no matter what the input files contain, and emits a stderr "integer expression expected" warning on every run. The bug:

```bash
hits=$(grep -cE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null || true)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits 'doc/arch' references"; fail=1; } || echo "  OK"
```

When `grep -c` runs against multiple files, it outputs `CLAUDE.md:0\n.claude/rules/arch.md:0` (per-file counts), not a summed integer. `$hits` therefore contains a multi-line string. The `[ "$hits" -gt 0 ]` test then errors with `integer expression expected` and exits non-zero — which routes execution into the `||` branch and unconditionally prints `OK`. Even if a real `doc/arch/foo` reference were introduced, the test would still fail the same way and still print `OK`, so the gate cannot detect future drift. This was also confirmed by running the script — it emits the stderr warning even on a clean tree.

**Fix:** Sum the per-file counts before comparing, or use a different counting strategy:

```bash
echo "[4/6] Checking doc/arch path drift in CLAUDE.md and rules..."
hits=$(grep -hcE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null | awk '{s+=$1} END {print s+0}')
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits 'doc/arch' references"; fail=1; } || echo "  OK"
```

Or equivalently use `grep -E ... | wc -l` (count matching lines, not per-file counts):

```bash
hits=$(grep -hE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null | wc -l | tr -d ' ')
```

Recommend covering this gate with a smoke test that introduces a deliberate `doc/arch/foo` string in a fixture file and asserts the gate fails.

### WR-02: Three append-only ADRs have a stray trailing metadata line after the appended Update section

**File:** `docs/arch/03-adr/ADR-002_Database_Solution.md` (last line `**下次Review日期:** 2026-08-03`); `docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` (last line `**下次审查:** 实施完成后进行效果评估`); `docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` (last line `**优先级:** P1（高优先级）`)
**Issue:** The phase commit messages (`3b6a121`, `e0687d5`) state the new section was "appended at file end", but the diffs actually inserted the Update block **above** the file's trailing metadata footer. The result is that each file ends with an orphan metadata line floating after the appended block, with no surrounding context. ADR-007 is the only one of the four that handled this correctly (the Update section is genuinely the last content in the file).

This is a minor structural defect — readers landing at the end of the file see a disconnected `**下次Review日期:**` / `**下次审查:**` / `**优先级:**` line that no longer "belongs" to anything. It also makes future appends ambiguous: do they go before or after that orphan line?

**Fix:** Move the trailing metadata line so it sits with the original document footer (i.e., before the `## Update 2026-04-27: Cleanup Initiative Outcome` heading), or absorb it into the Update section as a property the reviewer can re-evaluate. Example for ADR-002:

```markdown
...preserve d in the original closing block...
**下次Review日期:** 2026-08-03

---

## Update 2026-04-27: Cleanup Initiative Outcome
...rest of new section, no trailing orphan line...
```

### WR-03: `.claude/rules/arch.md:171-173` citation does not point to an "ADR append-only convention"

**File:** Cited in `docs/arch/03-adr/ADR-002_Database_Solution.md` (last paragraph), `ADR-007_Layer_Responsibilities.md` (last paragraph), `ADR-008_Book_Balance_Update_Strategy.md` (last paragraph), `ADR-010_CRDT_Conflict_Resolution_Strategy.md` (last paragraph)
**Issue:** All four append-only ADRs end with the sentence "The original decision body above is preserved verbatim per ADR append-only convention (`.claude/rules/arch.md:171-173`)." But:

- `.claude/rules/arch.md:171-173` is the start of `### Claude 执行规范` ("Claude execution norms") — not an append-only convention.
- The actual document-update rule lives at `.claude/rules/arch.md:157-161` (`### 文档更新规范`), and even that section does not contain the phrase "append-only" — it allows direct modification ("1. 小改动: 直接修改文档").
- A `grep -n "append-only\|追加" .claude/rules/arch.md` returns zero matches, confirming the convention as cited does not exist at all.

The citation is therefore inaccurate in 4 places. Future readers who follow the link will not find what the prose claims is there.

**Fix:** Either (a) add a real "ADR append-only" rule to `.claude/rules/arch.md` (preferably under `### 文档更新规则`) and update the four citations to that line range, or (b) drop the spurious line citation and reword to something verifiable, e.g.:

```markdown
The original decision body above is preserved verbatim — per ADR convention,
this file is append-only after acceptance; later context is added as Update sections.
```

### WR-04: ADR-000_INDEX.md statistics block out of sync with new ADR-011

**File:** `docs/arch/03-adr/ADR-000_INDEX.md:411-419`
**Issue:** Phase 7 added the ADR-011 entry to the table at line 360 (commit `22ef1ec`) but did not update the rollup statistics:

```
| 状态 | 数量 |
|------|------|
| ✅ 已接受 | 9 |    ← should be 10 (ADR-001/002/003/004/005/007/008/009/010/011)
| ✅ 已实施 | 1 |    ← unchanged (ADR-006)
...
**总计:** 10个ADR        ← should be 11
```

Same staleness in the "下次Review计划" table (lines 423-436) — ADR-011 has no entry, despite line 378 promising "下次Review: 2026-10-27 (每半年)".

**Fix:**

```markdown
| 状态 | 数量 |
|------|------|
| ✅ 已接受 | 10 |
| ✅ 已实施 | 1 |
...
**总计:** 11个ADR
```

And add the ADR-011 row to the review-schedule table:

```markdown
| ADR-011 | 2026-10-27 | 每6个月 |
```

### WR-05: `docs/arch/README.md` document-completion table out of sync

**File:** `docs/arch/README.md:223-230`
**Issue:** The completion-statistics table has not been updated to reflect Phase 7 changes:

```
| 整体架构文档 | 8 | ✅ 完成 |
| 模块功能文档 | 9 | ✅ 完成 |    ← actually 8 MOD files + MOD-000_INDEX = 9, but listing in same file claims 8 (excluding MOD-005)
| ADR 决策记录 | 10 | ✅ 完成 |    ← should be 11 after ADR-011
| 基础能力 PRD | 4 | ✅ 完成 |
| UI 规范文档 | 1 | ✅ 完成 |
| **总计** | **32** | **✅ 完成** |  ← should now be 33
```

The same file's directory tree (lines 14-61) lists ADR files but does not include `ADR-011_Codebase_Cleanup_Initiative_Outcome.md` even though the new file is in the directory. (The tree explicitly enumerates each ADR.)

**Fix:** Bump ADR count to 11, total to 33, and add `ADR-011_Codebase_Cleanup_Initiative_Outcome.md` to the tree under `03-adr/`. Same applies to `docs/arch/01-core-architecture/ARCH-000_INDEX.md:573` (completion stats table) — bump ADR count to 11 and total to 31 (or 32 if UI-001 is included).

## Info

### IN-01: `verify_index_health.sh` empty-glob latent bug

**File:** `scripts/verify_index_health.sh:31-37`
**Issue:** `for f in "$dir"/*.md; do` — if `$dir` ever has zero `.md` files, the unquoted glob expands to the literal pattern `$dir/*.md`, the loop body runs once with that literal string, `basename` returns `*.md`, and `grep -q "*.md"` then searches the index for a regex that matches any `*md` substring (because `*` after a non-special char is treated as zero-or-more-of-preceding). With current contents this is dormant, but if any monitored directory is ever emptied (or a directory is added later that may legitimately be empty), the gate would silently succeed against bogus input.

**Fix:** Enable nullglob locally for the loop, or pre-check with `compgen`:

```bash
shopt -s nullglob
for f in "$dir"/*.md; do
  base=$(basename "$f")
  ...
done
shopt -u nullglob
```

### IN-02: `verify_index_health.sh` uses unquoted regex with `grep -q "$base"`

**File:** `scripts/verify_index_health.sh:34`
**Issue:** `grep -q "$base" "$index"` treats `$base` as a regex. The `.md` extension means `.` matches any character, so `MOD-001_BasicAccounting.md` would also match, e.g., `MOD-001_BasicAccountingXmd` (extremely unlikely in practice). More importantly, future filenames containing regex specials (`+`, `[`, `]`) could mismatch. Use `grep -F` (fixed-string) for filename lookups:

```bash
if ! grep -qF "$base" "$index"; then
```

### IN-03: ARCH-008 cites the wrong ADR for layer responsibilities (pre-existing)

**File:** `docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md:5, 43, 579-580, 589, 615, 619, 691`
**Issue:** ARCH-008 references ADR-006 throughout as the source of "层次职责划分标准" — but ADR-006 is `ADR-006_Key_Derivation_Security.md` (HKDF/密钥派生). The actual layer-responsibility ADR is **ADR-007** (`ADR-007_Layer_Responsibilities.md`), confirmed in `ADR-000_INDEX.md:220` and `MOD-000_INDEX.md` master pointer. Line 580 even claims a file `ADR-006_Layer_Responsibilities.md` that does not exist.

This is pre-existing drift not introduced by Phase 7, and is not part of any of the 6 documented drift gates in `verify-doc-sweep.sh`. However, since ARCH-008 is in the file list for this review, the bad cross-reference is worth surfacing — if a developer follows the citation expecting layer rules, they will land on the HKDF security ADR.

**Fix:** Replace all `ADR-006` references in ARCH-008 with `ADR-007`. Or add this to the FUTURE-DOC backlog mentioned in ADR-011 line 182.

### IN-04: ADR-011 implementation-status mismatch with ADR-008/009/010 entries in INDEX

**File:** `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md:154`
**Issue:** ADR-011 says "ADR-008/009/010 在清理期间没有被实施（仍为'已接受但待实施'状态）". But `ADR-000_INDEX.md` lists all of ADR-008/009/010 as "✅ 已接受" without an "待实施" qualifier. ADR-011 is making a statement about implementation status that the index does not reflect. The two should agree, or one should explicitly cite the other.

**Fix:** Either add an "(待实施)" annotation to the ADR-008/009/010 entries in `ADR-000_INDEX.md`, or soften the language in ADR-011 to "仍处于已接受状态，实施推迟到未来 phase".

### IN-05: ADR-011 cleanup-outcome table footnote inconsistency

**File:** `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md:104-111`
**Issue:** The table says Phase 4 closed `(见下注)` HIGH findings, and the footnote explains: "总体 87 项 finding 的统计来自 ROADMAP 计划条目". But the entry on `ADR-000_INDEX.md:370` (which is also part of this phase's edits) advertises:

> Phase 3-6 完成 87 项 finding 修复（CRITICAL/HIGH/MEDIUM/LOW 全部关闭）

These two statements together imply the 87 figure is reliable, but the same footnote also says "Phase 4 的 HIGH 发现…未全部包含在 issues.json 中" — meaning the headline 87 includes manually-classified items that an external auditor cannot independently verify against `issues.json`. A reader using the headline number for traceability will be misled.

**Fix:** Either (a) split the headline into "auto-discovered (50, in `issues.json`) + manually-tracked HIGH (37, in ROADMAP)" or (b) explicitly cite the ROADMAP/STATE.md path that contains the canonical HIGH list. Recommend (a) for clearer attribution.

### IN-06: CLAUDE.md analyzer enforcement citation points at the wrong line

**File:** `CLAUDE.md:280`
**Issue:** Pitfall 8 says: "Don't commit with analyzer warnings — Structurally enforced — flutter analyze CI step (audit.yml line 34)". But `audit.yml:34` is `echo "analyzer 7.x confirmed"` (inside the analyzer-pin smoke check). The actual `flutter analyze --no-fatal-infos` step is at `audit.yml:38`. ADR-011 cites the correct line (audit.yml:38 in its table).

**Fix:** Update the CLAUDE.md citation:

```markdown
8. Don't commit with analyzer warnings
   *[Structurally enforced — flutter analyze CI step (audit.yml line 38)]*
```

---

_Reviewed: 2026-04-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
