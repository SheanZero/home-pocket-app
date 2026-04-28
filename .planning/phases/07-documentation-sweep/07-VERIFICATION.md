---
phase: 07-documentation-sweep
verified: 2026-04-27T22:30:00Z
status: gaps_found
score: 4/4 must-haves verified (1 with material gate defect)
overrides_applied: 0
gaps:
  - truth: "verify-doc-sweep.sh gate 4 mechanically detects future doc/arch/ singular-path drift in CLAUDE.md and .claude/rules/arch.md"
    status: failed
    reason: "Gate 4 is structurally broken — `grep -cE 'pattern' file1 file2` emits per-file counts (e.g. `CLAUDE.md:0\\n.claude/rules/arch.md:0`) rather than a summed integer; the subsequent `[ \"$hits\" -gt 0 ]` integer test errors with 'integer expression expected', returns non-zero, and the `||` branch unconditionally prints OK. Verified empirically: deliberately appending `doc/arch/foo` to CLAUDE.md produces the same OK output and exit 0. The gate cannot detect drift it was created to detect."
    artifacts:
      - path: ".planning/phases/07-documentation-sweep/verify-doc-sweep.sh"
        issue: "Line 22-23: `hits=$(grep -cE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null || true)` returns multi-line per-file counts; `[ \"$hits\" -gt 0 ]` fails with 'integer expression expected' on every run (visible in the script's stderr); `|| echo \"  OK\"` always fires."
    missing:
      - "Sum the per-file counts before comparing — change line 22 to `hits=$(grep -hcE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null | awk '{s+=$1} END {print s+0}')` (or equivalently use `grep -hE ... | wc -l | tr -d ' '`)"
      - "Add a smoke fixture test that injects `doc/arch/foo` into a fixture file and asserts the gate fails — prevents regression"
  - truth: "Append-only ADR updates land at the file end, with no orphan trailing metadata after the appended Update section"
    status: partial
    reason: "Three of the four append-only ADRs (002, 008, 010) have a stray metadata line trailing AFTER the appended `## Update 2026-04-27` block. The Phase 7 commit messages (3b6a121, e0687d5) state the section was 'appended at file end', but the diffs actually inserted the Update block ABOVE the file's pre-existing trailing metadata footer (e.g., `**下次Review日期:** 2026-08-03`, `**下次审查:** ...`, `**优先级:** P1（高优先级）`). ADR-007 is the only one of the four that handled this correctly. Result: each affected file ends with a disconnected metadata line floating after the appended Update — readers see an orphan attribute that no longer 'belongs' to anything; future appends become ambiguous (above or below this orphan?)."
    artifacts:
      - path: "docs/arch/03-adr/ADR-002_Database_Solution.md"
        issue: "Last line is `**下次Review日期:** 2026-08-03` — orphan metadata after the Update section"
      - path: "docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md"
        issue: "Last line is `**下次审查:** 实施完成后进行效果评估` — orphan metadata after the Update section"
      - path: "docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md"
        issue: "Last line is `**优先级:** P1（高优先级）` — orphan metadata after the Update section"
    missing:
      - "Move each trailing metadata line so it sits BEFORE the `## Update 2026-04-27: Cleanup Initiative Outcome` heading (i.e., absorbed into the original document footer), preserving the 'append-only at file end' contract."
  - truth: "All append-only ADR Update sections cite a real, locatable 'ADR append-only convention' in `.claude/rules/arch.md`"
    status: failed
    reason: "All four appended Update sections (ADR-002/007/008/010) end with the sentence 'The original decision body above is preserved verbatim per ADR append-only convention (`.claude/rules/arch.md:171-173`).' But `.claude/rules/arch.md:171-173` is the start of `### Claude 执行规范` (Claude execution norms) — not an append-only convention. The actual document-update rule lives at `.claude/rules/arch.md:157-161` (`### 文档更新规则`), and even that section does NOT contain the phrase 'append-only' — it explicitly allows direct modification ('1. 小改动: 直接修改文档'). `grep -nE 'append|追加|append-only' .claude/rules/arch.md` returns zero matches. The cited convention does not exist anywhere in the rules file. Future readers who follow the link will not find what the prose claims is there."
    artifacts:
      - path: "docs/arch/03-adr/ADR-002_Database_Solution.md"
        issue: "Trailing paragraph cites `.claude/rules/arch.md:171-173` for an append-only convention that lines 171-173 do not describe"
      - path: "docs/arch/03-adr/ADR-007_Layer_Responsibilities.md"
        issue: "Same spurious citation"
      - path: "docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md"
        issue: "Same spurious citation"
      - path: "docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md"
        issue: "Same spurious citation"
    missing:
      - "Either (a) add a real 'ADR append-only' rule to `.claude/rules/arch.md` (preferably under `### 文档更新规则`) and re-cite the correct line range, or (b) drop the spurious line citation and reword to a verifiable phrase, e.g. 'preserved verbatim — per ADR convention, this file is append-only after acceptance; later context is added as Update sections.'"
  - truth: "Statistics rollups in ADR-000_INDEX.md and docs/arch/README.md reflect the new ADR-011 entry"
    status: failed
    reason: "Phase 7 added the ADR-011 entry to the table at ADR-000_INDEX.md line 360 (commit 22ef1ec) but did NOT update the rollup statistics block (lines 411-419) or the next-review schedule (lines 423-436). The same staleness exists in docs/arch/README.md (lines 225-230) and ARCH-000_INDEX.md document-completion table. ADR-011 is real but the metadata describing the document inventory still claims pre-Phase-7 totals."
    artifacts:
      - path: "docs/arch/03-adr/ADR-000_INDEX.md"
        issue: "Lines 411-419: statistics block reads `已接受 9 / 已实施 1 / 总计 10个ADR` — should be `已接受 10 / 已实施 1 / 总计 11个ADR`. Lines 423-436: 下次Review计划 table has no row for ADR-011 even though line 378 promises '下次Review: 2026-10-27 (每半年)'"
      - path: "docs/arch/README.md"
        issue: "Lines 225-230: document-completion table reads `ADR 决策记录 10 / 总计 32` — should be `ADR 决策记录 11 / 总计 33`. Directory tree at lines 14-61 enumerates ADR files but does not include ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
      - path: "docs/arch/01-core-architecture/ARCH-000_INDEX.md"
        issue: "Completion-stats table (around line 573) similarly bumps needed: ADR count 10 → 11, total 30 → 31"
    missing:
      - "Update ADR-000_INDEX.md statistics block to `已接受 10 / 已实施 1 / 总计 11个ADR` and add an ADR-011 row to the 下次Review计划 table"
      - "Update docs/arch/README.md statistics table to ADR=11, total=33; add ADR-011 entry to the directory tree under 03-adr/"
      - "Update ARCH-000_INDEX.md document-completion stats table"
deferred:
  - truth: "Pre-existing MOD-numbering drift inside MOD-002/006/007/008 internal headers"
    addressed_in: "FUTURE-DOC backlog (per ADR-011 §Out of Scope, line 182)"
    evidence: "ADR-011 line 182 explicitly defers: 'MOD 编号漂移（D-02）：02-module-specs/ 目录中文件名编号与内部标题编号不一致的问题是预先存在的；Phase 7 不修改 MOD 文件名（会破坏所有外部书签），已提升到 FUTURE-DOC 积压'"
  - truth: "ARCH-008 cites the wrong ADR for layer responsibilities (ADR-006 in seven places; should be ADR-007)"
    addressed_in: "FUTURE-DOC backlog mentioned in ADR-011"
    evidence: "Pre-existing drift not introduced by Phase 7; ADR-011 §Out of Scope line 182 defers MOD/cross-ref drift outside Phase 7's gates"
---

# Phase 07: Documentation Sweep Verification Report

**Phase Goal:** All ARCH/MOD/ADR files under `docs/arch/` and CLAUDE.md accurately reflect the post-refactor codebase; one centralized sweep rather than per-phase churn.

**Verified:** 2026-04-27T22:30:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The four primary success criteria are substantively met — the drift the phase set out to fix is gone (mockito, sqlite3_flutter_libs, MOD-014 phantom, layer-centralization paths, `doc/arch/` singular spelling), ADR-011 is filed and indexed, INDEX health passes, all 13 CLAUDE.md pitfalls are annotated, and the lib/-clean invariant holds across the entire phase (0 forbidden files modified). However, the code review surfaced four real defects that compromise the rigor of the deliverable: one mechanical gate is structurally unable to detect what it claims to detect, three append-only ADR diffs left orphan trailing metadata, all four append-only ADRs cite a non-existent rules-file line range, and statistics tables in three index/README files were not updated to reflect ADR-011.

These are MEDIUM-severity gaps rather than BLOCKERS — the goal is achieved in spirit, but Phase 7's mechanical gate (verify-doc-sweep.sh) cannot reliably guard the work it produced, and the appended ADR sections contain a self-referential citation defect that will mislead future readers.

### Observable Truths

| #   | Truth (from ROADMAP success criteria) | Status     | Evidence       |
| --- | -------------------------------------- | ---------- | -------------- |
| 1   | Every ARCH/MOD/ADR file under docs/arch/ that referenced relocated files, renamed classes, or deleted modules is updated to match the post-refactor file paths and class names | VERIFIED | verify-doc-sweep.sh gates 1, 2, 3, 5 all PASS (script exits 0). MOD-006/007 use_cases paths now point at `lib/application/{domain}/`. mockito drift in MOD-002/006/007/008/009 + ARCH-001/007 replaced with mocktail. ARCH-001:48 sqlite3_flutter_libs line deleted. ARCH-007 line ~360 mockito → mocktail. Phantom MOD-014 → BASIC-003 in ARCH-007/008/UI-001. ARCH-001:2078 MOD-009 cross-ref corrected to "语音记账". |
| 2   | docs/arch/INDEX.md files (ARCH-000, ADR-000, MOD-000) reference only files that still exist on disk | VERIFIED | `bash scripts/verify_index_health.sh` exits 0 (zero BROKEN LINK, zero ORPHAN). MOD-000_INDEX.md created as 3-line stub-with-pointer per D-04. UI-001 entry added to ARCH-000. README.md synced to actual directory listing. |
| 3   | CLAUDE.md "Common Pitfalls" list is annotated to mark which of the 13 items are now structurally enforced | VERIFIED | All 13 pitfalls (CLAUDE.md lines 265-290) carry annotation tags: 7 `Structurally enforced`, 2 `Partially enforced`, 4 `Manually-checked only`. Annotation format consistent (3-space indent, em-dash, italic). Note: pitfall 8 cites `audit.yml line 34` but actual `flutter analyze` step is at line 38 (see IN-06). |
| 4   | A new ADR is filed documenting the cleanup initiative outcome, the *.mocks.dart strategy decision, and ongoing CI enforcement mechanisms | VERIFIED | ADR-011_Codebase_Cleanup_Initiative_Outcome.md exists (10685 bytes / 183 lines). All 8 standard ADR sections present (状态/背景/考虑的方案/决策/决策理由/后果/实施计划/Out of Scope). All three locked sub-sections present: §A `*.mocks.dart` Strategy (line 60), §B Ongoing CI Enforcement with 8-gate table (line 80), §C Cleanup Outcome with per-phase table (line 100). Indexed at ADR-000_INDEX.md line 360. CI gate citations (audit.yml:38, :41, :70-75, :79-84, :100-105, :108) all verified accurate. |

**Score:** 4/4 truths verified (with 4 documented MEDIUM-severity sub-defects — see Gaps Summary)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Pre-existing MOD-numbering drift inside MOD-002/006/007/008 internal headers | FUTURE-DOC backlog | ADR-011 line 182 explicit deferral |
| 2 | ARCH-008 cross-references ADR-006 throughout for "层次职责划分" but actual ADR is ADR-007 | FUTURE-DOC backlog | Pre-existing drift not introduced by Phase 7; outside the 6 gates of verify-doc-sweep.sh |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` | 6-gate phase close gate, exit 0 | VERIFIED (with defect — see WR-01) | Exists, executable, 35 lines. Exits 0 with all 6 gates printing OK — but gate 4 prints OK regardless of input due to per-file-count grep bug |
| `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` | New ADR documenting cleanup outcome | VERIFIED | 183 lines, all 8 sections + 3 locked sub-sections present, CI citations verified |
| `docs/arch/03-adr/ADR-000_INDEX.md` | Indexed ADR-011 entry | VERIFIED (entry) / FAILED (rollup) | ADR-011 entry at line 360 — but statistics block still reads "总计: 10个ADR", review schedule has no ADR-011 row |
| `docs/arch/02-module-specs/MOD-000_INDEX.md` | New MOD index (D-04 stub) | VERIFIED | 3-line stub-with-pointer to ARCH-000_INDEX.md |
| `scripts/verify_index_health.sh` | INDEX health gate, exit 0 | VERIFIED (with latent IN-01/IN-02 bugs) | Exits 0; nullglob latent bug + regex-injection latent bug noted in 07-REVIEW.md but dormant under current contents |
| `CLAUDE.md` | 13 pitfalls annotated | VERIFIED (with IN-06 line-citation defect) | All 13 annotated; pitfall 8 cites audit.yml line 34 (echo) instead of line 38 (flutter analyze) |
| `.claude/rules/arch.md` | doc/arch/ → docs/arch/ path drift fixed | VERIFIED | 13 occurrences mechanically replaced; gate 4 of verify-doc-sweep.sh would catch a regression IF it actually worked |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| Phase 7 plans | docs/arch/ source files | grep -rn for stale patterns | WIRED | All 9 plans modified the targeted files; commits 97cc25f, 2c7d969, bac778f, 0b978f5, 3b6a121, 649ad87, e0687d5, 8c60920, 61ed96d, 6c835bb, b6aab3b, 2cab7c3, 30339c8, c1b3052, 22ef1ec |
| ADR-011 | audit.yml CI gates | line citations | WIRED | All 6 cited line ranges (38, 41, 70-75, 79-84, 100-105, 108) match actual file content |
| ADR-002/007/008/010 | ADR-011 forward link | relative href `./ADR-011_...md` | WIRED | All 4 appended sections contain the link; ADR-011 file exists |
| Append-only ADR sections | ".claude/rules/arch.md:171-173 ADR append-only convention" | text citation | NOT_WIRED | Cited line range does NOT contain the cited convention; convention text does not exist in the rules file (gap #3) |
| verify-doc-sweep.sh gate 4 | doc/arch/ singular drift detection | grep -cE pattern | NOT_WIRED | Per-file count output breaks integer test; gate fires OK regardless of input (gap #1) |
| ADR-000_INDEX.md statistics | actual ADR file count | rollup table | NOT_WIRED | Statistics table reports 10 ADRs but 11 exist on disk (gap #4) |
| docs/arch/README.md statistics | actual document count | rollup table | NOT_WIRED | README reports 32 docs but actual count is 33 with ADR-011 (gap #4) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| verify-doc-sweep.sh exit code on clean tree | `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh; echo EXIT: $?` | EXIT: 0 with 6 OK lines (gate 4 emits stderr "integer expression expected" warning) | PASS (with defect) |
| verify-doc-sweep.sh detects deliberate drift | Inject `doc/arch/foo` into CLAUDE.md; rerun script | EXIT: 0, gate 4 still prints OK | FAIL — confirms WR-01 |
| verify_index_health.sh exit code | `bash scripts/verify_index_health.sh; echo EXIT: $?` | EXIT: 0 (zero BROKEN LINK / zero ORPHAN across all three indexed dirs) | PASS |
| ADR-011 file presence | `test -f docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` | exit 0 | PASS |
| ADR-011 indexed | `grep -q "ADR-011" docs/arch/03-adr/ADR-000_INDEX.md` | exit 0 | PASS |
| 13 pitfalls annotated | `grep -cE '^   \*\[(Structurally|Partially) enforced\|^   \*\[Manually-checked only' CLAUDE.md` | 13 | PASS |
| ADR-011 references all CI gates | `grep -E "audit\.yml:(38\|41\|70-75\|79-84\|100-105\|108)" docs/arch/03-adr/ADR-011_*.md` | 6 distinct citations present | PASS |
| lib/-clean invariant for entire Phase 7 | `git diff --name-only 3eae063..HEAD \| grep -cE '^(lib/\|test/\|pubspec\|\.github/\|analysis_options)'` | 0 | PASS |
| .claude/rules/arch.md "append-only" convention exists | `grep -nE 'append\|追加\|append-only' .claude/rules/arch.md` | zero matches | FAIL — confirms WR-03 |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| ----------- | -------------- | ----------- | ------ | -------- |
| DOCS-01 | 07-01, 07-02, 07-03, 07-04, 07-05 | All ARCH/MOD/ADR files reviewed and updated for relocated files / renamed classes / deleted modules | SATISFIED | Gates 1, 2, 3, 5 of verify-doc-sweep.sh all OK; 9 ARCH/MOD files + 4 ADR append-only updates landed |
| DOCS-02 | 07-03, 07-05 | CLAUDE.md "Common Pitfalls" annotated with enforcement status | SATISFIED | All 13 pitfalls annotated (7 Structurally / 2 Partially / 4 Manual); IN-06 line-citation defect noted but does not block satisfaction |
| DOCS-03 | 07-04, 07-05 | docs/arch/INDEX.md files reference only files that still exist | SATISFIED | scripts/verify_index_health.sh exits 0 across all three indexed directories |
| DOCS-04 | 07-05 | New ADR filed documenting cleanup outcome, *.mocks.dart strategy, CI enforcement | SATISFIED | ADR-011 exists with all 3 locked sub-sections (§A *.mocks.dart Strategy, §B CI Enforcement 8-gate table, §C Cleanup Outcome per-phase table) |

All 4 requirement IDs (DOCS-01..04) are claimed across the 5 plans' frontmatter and have implementation evidence on disk. Zero ORPHANED requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` | 22-23 | Multi-file `grep -c` per-file output sent into integer test → `[: integer expression expected` → unconditional OK fallthrough | WARNING | Gate 4 cannot detect regressions; phase gate is structurally compromised |
| `docs/arch/03-adr/ADR-002_Database_Solution.md` | last line | Orphan trailing metadata after appended Update section | WARNING | Append-only contract violated; future-append ambiguity |
| `docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` | last line | Orphan trailing metadata after appended Update section | WARNING | Same |
| `docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` | last line | Orphan trailing metadata after appended Update section | WARNING | Same |
| `docs/arch/03-adr/ADR-002_Database_Solution.md` (and 007, 008, 010) | trailing paragraph | Citation `.claude/rules/arch.md:171-173` for non-existent "ADR append-only convention" | WARNING | 4 inaccurate citations; misleading future readers |
| `docs/arch/03-adr/ADR-000_INDEX.md` | 411-419, 423-436 | Statistics & review-schedule tables not synced to ADR-011 entry | WARNING | INDEX entry table accurate, but rollups disagree |
| `docs/arch/README.md` | 14-61, 225-230 | Directory tree + document-count table not synced to ADR-011 | WARNING | Document inventory metadata stale |
| `docs/arch/01-core-architecture/ARCH-000_INDEX.md` | ~573 | Completion-stats table not synced to ADR-011 | WARNING | Metadata stale |
| `CLAUDE.md` | 280 | Pitfall 8 cites `audit.yml line 34` (echo line) instead of `line 38` (flutter analyze run line) | INFO | Inaccurate cross-reference; ADR-011 has the correct citation |
| `scripts/verify_index_health.sh` | 31-37 | Latent empty-glob bug (`for f in "$dir"/*.md` with no nullglob) | INFO | Dormant under current contents; would mis-pass on any newly-empty directory |
| `scripts/verify_index_health.sh` | 34 | `grep -q "$base"` treats filename as regex (no `-F` flag) | INFO | Dormant; only matters if filename ever contains regex specials |
| `docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md` | multiple | Pre-existing ADR-006 / ADR-007 cross-ref drift | INFO | Pre-existing — explicitly deferred to FUTURE-DOC backlog by ADR-011 |
| `docs/arch/03-adr/ADR-011_*.md` | 154 | "ADR-008/009/010 在清理期间没有被实施（仍为'已接受但待实施'状态）" but INDEX lists them as `✅ 已接受` without "待实施" qualifier | INFO | Mild internal inconsistency between ADR-011 narrative and INDEX status labels |
| `docs/arch/03-adr/ADR-011_*.md` | 104-111 | Headline "87 findings" mixes auto-discovered (50, in issues.json) and manually-tracked HIGH (37, in ROADMAP); footnote acknowledges this but headline number not split | INFO | Traceability ambiguity for external auditors |

### Human Verification Required

None. The four success criteria are observable via grep, file checks, and script exit codes — no UI, real-time behavior, or external service in scope. The flagged gaps are mechanically verifiable defects, not subjective judgments.

### Gaps Summary

Phase 7's primary goal (drift gone, ADR-011 filed, INDEX health, pitfalls annotated, lib/-clean) is achieved at the 4-of-4 success-criteria level. However, four MEDIUM-severity defects from the code review (07-REVIEW.md WR-01..WR-05) are real on disk and warrant remediation before Phase 8 begins:

1. **WR-01 (most material) — verify-doc-sweep.sh gate 4 is structurally broken.** The phase's own mechanical drift gate cannot detect future `doc/arch/` singular-path drift in CLAUDE.md or `.claude/rules/arch.md`. Verified empirically: deliberately injecting `doc/arch/foo` into CLAUDE.md produces the same OK / EXIT 0 output as a clean tree. This means future contributors who reintroduce drift will not be caught by the gate this phase created. Single-line fix (sum per-file counts).

2. **WR-02 — orphan trailing metadata in 3 of 4 append-only ADRs.** ADR-002/008/010 each end with a stray pre-existing metadata line (`**下次Review日期:**`, `**下次审查:**`, `**优先级:**`) AFTER the appended Update section, contradicting the "appended at file end" claim in commit messages. ADR-007 was handled correctly. Cosmetic but undermines the append-only contract for future appends.

3. **WR-03 — fictitious citation in all 4 append-only ADRs.** Every appended Update section ends with the sentence "preserved verbatim per ADR append-only convention (`.claude/rules/arch.md:171-173`)" — but lines 171-173 are `### Claude 执行规范` (Claude execution norms) and the rules file contains zero occurrences of "append-only" or "追加". The cited convention does not exist. Either add the rule and re-cite, or drop the line range.

4. **WR-04/WR-05 — statistics tables not synced.** ADR-000_INDEX.md still reports `已接受 9 / 总计 10 ADRs` (should be 10 / 11). docs/arch/README.md still reports `ADR 决策记录 10 / 总计 32` (should be 11 / 33). ARCH-000_INDEX.md document-completion stats also stale. The ADR-011 ENTRY made it into ADR-000_INDEX.md at line 360, but the rollup metadata blocks were not bumped to match.

These four gaps form a focused remediation plan: a single follow-up plan can fix the gate, move the trailing metadata in three files, fix the citations in four files, and bump three statistics tables. None block Phase 8 fundamentally — the audit pipeline does not depend on these — but they materially weaken the rigor of Phase 7's "centralized sweep" deliverable. Recommend addressing via `/gsd-plan-phase 7 --gaps`.

INFO-level items (IN-01..IN-06) are noted for context but classified as non-blocking: latent script bugs that do not currently misfire, pre-existing drift explicitly deferred to FUTURE-DOC, and one mild line-citation defect in CLAUDE.md (ADR-011 has the correct citation).

---

_Verified: 2026-04-27T22:30:00Z_
_Verifier: Claude (gsd-verifier)_
