---
phase: 07-documentation-sweep
plan: 06
type: execute
wave: 4
gap_closure: true
depends_on: ["07-05-cleanup-outcome-adr-PLAN.md"]
files_modified:
  - .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
  - .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh
  - .claude/rules/arch.md
  - docs/arch/03-adr/ADR-002_Database_Solution.md
  - docs/arch/03-adr/ADR-007_Layer_Responsibilities.md
  - docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md
  - docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md
  - docs/arch/03-adr/ADR-000_INDEX.md
  - docs/arch/README.md
  - docs/arch/01-core-architecture/ARCH-000_INDEX.md
autonomous: true
requirements: [DOCS-01, DOCS-02, DOCS-03, DOCS-04]

must_haves:
  truths:
    - "verify-doc-sweep.sh gate 4 mechanically detects future doc/arch/ singular-path drift in CLAUDE.md and .claude/rules/arch.md (per-file counts summed; integer test does not error; deliberate drift injection FAILs the gate)."
    - "A hermetic smoke fixture (verify-doc-sweep-smoke.sh) injects `doc/arch/foo` into a TEMP COPY of CLAUDE.md, runs verify-doc-sweep.sh against the temp copy, asserts gate 4 fails (script exits non-zero), and cleans up the temp copy. The real CLAUDE.md is not mutated."
    - "ADR-002, ADR-008, and ADR-010 each end with the `## Update 2026-04-27: Cleanup Initiative Outcome` section as the last top-level content; pre-existing trailing metadata lines (`**下次Review日期:**` / `**下次审查:**` / `**优先级:**`) are relocated to before the Update heading, preserving the append-only-at-file-end contract."
    - "`.claude/rules/arch.md` contains a real ADR append-only rule (Chinese-language, located under `### 文档更新规则`) so the citation in the 4 append-only ADRs points to actual content."
    - "All 4 append-only ADRs (002, 007, 008, 010) cite a verifiable line range that contains the phrase `append-only` or `追加`; no ADR cites the obsolete `arch.md:171-173` range for an append-only convention."
    - "ADR-000_INDEX.md statistics block reports `已接受 10 / 已实施 1 / 总计 11个ADR`; the 下次Review计划 table contains an ADR-011 row."
    - "docs/arch/README.md statistics table reports `ADR 决策记录 11 / 总计 33`; the directory tree under 03-adr/ enumerates ADR-011_Codebase_Cleanup_Initiative_Outcome.md."
    - "ARCH-000_INDEX.md document-completion stats table reports ADR count = 11 and total = 31."
    - "Final verification: `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (all 6 gates pass with the corrected gate 4); `bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` exits 0 (smoke confirms gate 4 fails on drift); `bash scripts/verify_index_health.sh` exits 0 (INDEX health unbroken)."
    - "lib/-clean invariant: `git diff --name-only ef4b770..HEAD | grep -cE '^(lib/|test/|pubspec|\\.github/|analysis_options)'` returns 0 (zero forbidden paths modified by this gap-closure plan)."
  artifacts:
    - path: ".planning/phases/07-documentation-sweep/verify-doc-sweep.sh"
      provides: "Phase 7 close gate (6 gates, gate 4 now mechanically functional)"
      contains: "grep -hcE"
    - path: ".planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh"
      provides: "Hermetic smoke test confirming gate 4 detects injected drift"
      min_lines: 20
    - path: ".claude/rules/arch.md"
      provides: "Real ADR append-only rule under 文档更新规则 subsection"
      contains: "append-only"
    - path: "docs/arch/03-adr/ADR-000_INDEX.md"
      provides: "Statistics + review-schedule synced to ADR-011"
      contains: "11个ADR"
    - path: "docs/arch/README.md"
      provides: "Document-completion table + directory tree synced to ADR-011"
      contains: "ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
    - path: "docs/arch/01-core-architecture/ARCH-000_INDEX.md"
      provides: "Completion-stats table synced to ADR-011"
  key_links:
    - from: ".planning/phases/07-documentation-sweep/verify-doc-sweep.sh"
      to: "CLAUDE.md, .claude/rules/arch.md"
      via: "grep -hcE 'doc/arch[^/]' summed via awk"
      pattern: "grep -hcE.*doc/arch.*awk"
    - from: ".planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh"
      to: ".planning/phases/07-documentation-sweep/verify-doc-sweep.sh"
      via: "TEMP-copy injection + assert non-zero exit"
      pattern: "verify-doc-sweep\\.sh"
    - from: "docs/arch/03-adr/ADR-002, ADR-007, ADR-008, ADR-010"
      to: ".claude/rules/arch.md (new append-only rule line range)"
      via: "text citation in Update section"
      pattern: "\\.claude/rules/arch\\.md:[0-9]+"
    - from: "docs/arch/03-adr/ADR-000_INDEX.md statistics block"
      to: "actual ADR file count on disk (11)"
      via: "rollup table"
      pattern: "11个ADR"
    - from: "docs/arch/README.md document-completion table"
      to: "actual document count on disk (33)"
      via: "rollup table"
      pattern: "33"

---

<objective>
Plan 07-06 closes the FOUR MEDIUM-severity gaps recorded in `.planning/phases/07-documentation-sweep/07-VERIFICATION.md` (frontmatter `gaps:` block; aliased as WR-01..WR-05 in 07-REVIEW.md). The Phase 7 goal is achieved at the 4-of-4 success-criteria level, but four real defects compromise the rigor of the deliverable:

1. **WR-01 — verify-doc-sweep.sh gate 4 is structurally broken.** `grep -cE 'pattern' file1 file2` emits per-file counts (`CLAUDE.md:0\n.claude/rules/arch.md:0`), the integer test errors with "integer expression expected", and the `||` branch unconditionally prints OK. Empirically confirmed: injecting `doc/arch/foo` into CLAUDE.md still produces EXIT 0 / OK. This plan fixes the gate (sum per-file counts via `awk`) AND adds a hermetic smoke fixture that PROVES the gate detects drift.

2. **WR-02 — orphan trailing metadata in ADR-002, ADR-008, ADR-010.** Each file ends with a stray pre-existing metadata line AFTER the appended `## Update 2026-04-27` block, contradicting the "appended at file end" contract. ADR-007 was handled correctly. This plan relocates each trailing metadata line so it sits BEFORE the Update heading, preserving the metadata text verbatim.

3. **WR-03 — fictitious citation `.claude/rules/arch.md:171-173` in all 4 append-only ADRs.** Lines 171-173 are `### Claude 执行规范`, not an append-only convention. `grep -nE 'append|追加|append-only' .claude/rules/arch.md` returns zero matches — the cited convention does not exist. This plan adds the real rule under `### 文档更新规则` and updates all 4 ADR citations to the new line range.

4. **WR-04/WR-05 — statistics tables not synced to ADR-011.** ADR-000_INDEX.md still reports `已接受 9 / 总计 10个ADR`; docs/arch/README.md still reports `ADR 10 / 总计 32`; ARCH-000_INDEX.md reports `ADR 10 / 总计 30`. Eleven ADRs exist on disk; this plan bumps the three rollup tables and adds the missing directory-tree entries.

Wave 4 (after Wave 3's plan 07-05 created ADR-011 — the statistics fixes are downstream of ADR-011's existence).

Output: 1 corrected gate + 1 new smoke fixture + 1 new rule subsection + 4 ADR edits + 3 INDEX/README edits = 10 files modified.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/07-documentation-sweep/07-CONTEXT.md
@.planning/phases/07-documentation-sweep/07-RESEARCH.md
@.planning/phases/07-documentation-sweep/07-PATTERNS.md
@.planning/phases/07-documentation-sweep/07-VERIFICATION.md
@.planning/phases/07-documentation-sweep/07-REVIEW.md
@.planning/phases/07-documentation-sweep/07-VALIDATION.md
@.planning/phases/07-documentation-sweep/07-05-SUMMARY.md
@.claude/rules/arch.md

<gap_evidence>
<!-- Empirically verified concrete values that the executor MUST use; do NOT re-derive these from the source artifacts — apply them directly. -->

**WR-01 evidence:** verify-doc-sweep.sh:22 currently reads:

    hits=$(grep -cE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null || true)

Required replacement (verified to work):

    hits=$(grep -hcE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null | awk '{s+=$1} END {print s+0}')

Note the `-h` flag (suppress filenames) AND the awk sum. Line 23 (the `[ "$hits" -gt 0 ] && ... || echo "  OK"` test) is left untouched — it works correctly once `$hits` is a single integer.

**WR-02 evidence (verified line numbers via grep):**
- ADR-002_Database_Solution.md: total 652 lines. Line 635 = `## Update 2026-04-27: Cleanup Initiative Outcome`. Line 652 (last) = `**下次Review日期:** 2026-08-03`. The Update section runs lines 635-651 (line 651 ends with the citation paragraph).
- ADR-008_Book_Balance_Update_Strategy.md: total 1205 lines. Line 1191 = `## Update 2026-04-27: Cleanup Initiative Outcome`. Line 1205 (last) = `**下次审查:** 实施完成后进行效果评估`.
- ADR-010_CRDT_Conflict_Resolution_Strategy.md: total 1480 lines. Line 1469 = `## Update 2026-04-27: Cleanup Initiative Outcome`. Line 1480 (last) = `**优先级:** P1（高优先级）`.
- ADR-007 is correct — no fix needed for WR-02; it IS modified for WR-03 (citation update).

**WR-03 evidence:** all 4 ADRs contain the literal string `(.claude/rules/arch.md:171-173).` (formatted with backticks around the path) at:
- ADR-002:651
- ADR-007:986
- ADR-008:1204
- ADR-010:1479

**WR-04 evidence (ADR-000_INDEX.md):**
- Lines 411-419 = decision-statistics table; line 413 = `| ✅ 已接受 | 9 |`; line 419 = `**总计:** 10个ADR`.
- Lines 423-436 = 下次Review计划 table; ADR-001..010 are listed; ADR-011 is NOT.
- ADR-011 row should mirror ADR-007 cadence: `| ADR-011 | 2026-10-27 | 每6个月 |` (per ADR-011 line 378 promise + ADR-011 self-stated review date).

**WR-05 evidence (docs/arch/README.md):**
- Lines 14-61 = directory tree; lines 38-49 enumerate `03-adr/`; the file currently lists ADR-001..010 inside the tree but NOT ADR-011.
- Lines 223-230 = 文档统计 table; line 227 = `| ADR 决策记录 | 10 | ✅ 完成 |`; line 230 = `| **总计** | **32** | **✅ 完成** |`.

**WR-05 evidence (ARCH-000_INDEX.md):**
- Lines 569-577 = 文档完成度 table; line 575 = `| ADR决策记录 | 10 | ✅ 100% |`; line 577 = `| **总计** | **30** | **✅ 100%** |`.

**Verified empirically (2026-04-28):**
- `ls docs/arch/03-adr/*.md | wc -l` = 12 (11 ADRs + ADR-000_INDEX.md). 11 numbered ADRs.
- `ls docs/arch/01-core-architecture/*.md` = 9 (ARCH-000 + ARCH-001..008).
- `ls docs/arch/02-module-specs/*.md` = 9 (MOD-000 + 8 MOD files).
- `ls docs/arch/04-basic/*.md` = 4.
- `ls docs/arch/05-UI/*.md` = 1.
- README.md "文档统计" table totals: 整体架构 8 + 模块 9 + ADR 10 → 11 + BASIC 4 + UI 1 = 32 → **33** post-fix.
- ARCH-000_INDEX.md "文档完成度" table totals: 核心架构 8 + 模块 8 + ADR 10 → 11 + BASIC 4 = 30 → **31** post-fix. (Note: ARCH-000's table does NOT include UI-001 — it counts 30 not 31; bumping ADR 10→11 gives 31.)

**Append-only rule wording (locked, Chinese, matches arch.md style):**

    4. **ADR append-only:** ADR 文件在状态变为「✅ 已接受」之后只能 append — 后续上下文以 `## Update YYYY-MM-DD: <topic>` 区段追加在文件末尾，不修改原决策正文（保留决策的历史完整性）。

This becomes item 4 of `### 文档更新规则` (currently lists 1, 2, 3 — see arch.md:159-161). After insertion, the rule subsection spans roughly lines 157-162 (1 new line); the citing line range becomes `arch.md:157-162`.

**Cross-reference for citation update:** the literal replacement target in all 4 ADRs is the line `The original decision body above is preserved verbatim per ADR append-only convention\n(\`.claude/rules/arch.md:171-173\`).` → replace `171-173` with `157-162`. Keep the rest of the sentence intact.

**Phase-base commit for lib/-clean invariant:** `ef4b770` (current HEAD as of 2026-04-28; the last commit before plan 07-06 commits land — verified via `git rev-parse HEAD`). Use this SHA for the cross-plan diff check.
</gap_evidence>

<smoke_fixture_skeleton>
The verify-doc-sweep-smoke.sh script structure (locked — see Task 2 action for full content):

1. Shebang `#!/usr/bin/env bash` then `set -euo pipefail`.
2. `WORKDIR=$(mktemp -d)` + `trap 'rm -rf "$WORKDIR"' EXIT`.
3. Copy CLAUDE.md and .claude/rules/arch.md into WORKDIR (preserve subdir structure).
4. Append `see doc/arch/foo for details` to the temp CLAUDE.md ONLY (real CLAUDE.md untouched).
5. Use sed to produce a temp copy of verify-doc-sweep.sh that points the gate-4 file references at WORKDIR paths.
6. Run the temp gate script. Expect non-zero exit.
7. If exit 0 → print SMOKE FAIL and exit 1; else print SMOKE PASS and exit 0.

</smoke_fixture_skeleton>

</context>

<tasks>

<task type="auto">
  <id>07-06-01</id>
  <wave>1</wave>
  <name>Task 1: Fix verify-doc-sweep.sh gate 4 (WR-01) — sum per-file grep counts</name>
  <files>.planning/phases/07-documentation-sweep/verify-doc-sweep.sh</files>
  <read_first>
    - .planning/phases/07-documentation-sweep/verify-doc-sweep.sh (current state — line 22 is the bug)
    - .planning/phases/07-documentation-sweep/07-VERIFICATION.md (gap 1 missing[] block — exact replacement command specified)
    - .planning/phases/07-documentation-sweep/07-REVIEW.md (WR-01 — full diagnosis)
  </read_first>
  <action>
    Replace line 22 of `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh`. The current line is:

    `hits=$(grep -cE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null || true)`

    Replace it with EXACTLY:

    `hits=$(grep -hcE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null | awk '{s+=$1} END {print s+0}')`

    Two changes:
    1. `-cE` → `-hcE` (the `-h` flag suppresses filename prefixes so `-c` outputs only the count number per file).
    2. `|| true` removed; replaced by `| awk '{s+=$1} END {print s+0}'` which sums per-file counts and prints a single integer (defaults to `0` if input is empty).

    DO NOT modify line 21 (the echo line) or line 23 (the integer test). The fix is purely on line 22.

    DO NOT modify any other gate (gates 1, 2, 3, 5, 6 are already correct per 07-VERIFICATION.md).

    After the edit, verify on a clean tree (no drift injected): `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh; echo EXIT: $?` → must print `EXIT: 0` with all 6 lines OK and NO `integer expression expected` warning on stderr.
  </action>
  <verify>
    <automated>grep -q "grep -hcE 'doc/arch\[\^/\]'" .planning/phases/07-documentation-sweep/verify-doc-sweep.sh && grep -q "awk '{s+=\$1} END {print s+0}'" .planning/phases/07-documentation-sweep/verify-doc-sweep.sh && bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh 2>&1 | { ! grep -q 'integer expression expected'; } && bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "grep -hcE 'doc/arch\[\^/\]'" .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (line 22 has new -h flag)
    - `grep -q "awk '{s+=\$1} END {print s+0}'" .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (awk sum present)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh; echo $?` returns `0` (clean tree → all gates pass)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh 2>&1 | grep -c 'integer expression expected'` returns `0` (no stderr warning anymore)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh 2>&1 | grep -c '^  OK$'` returns at least `6` (all 6 gates print OK)
    - `wc -l .planning/phases/07-documentation-sweep/verify-doc-sweep.sh | awk '{print $1}'` returns `35` (line count unchanged — only line 22 modified)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0`
  </acceptance_criteria>
  <files_modified>.planning/phases/07-documentation-sweep/verify-doc-sweep.sh</files_modified>
  <done>Gate 4 line 22 fixed; full script exits 0 cleanly with no stderr warning and 6 OK lines.</done>
</task>

<task type="auto">
  <id>07-06-02</id>
  <wave>1</wave>
  <name>Task 2: Add hermetic smoke fixture verify-doc-sweep-smoke.sh (WR-01 regression guard)</name>
  <files>.planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh</files>
  <read_first>
    - .planning/phases/07-documentation-sweep/verify-doc-sweep.sh (post-Task-1 state — the script the smoke fixture will exercise)
    - CLAUDE.md (verify it exists and is readable — the smoke copies it)
    - .claude/rules/arch.md (verify it exists and is readable — the smoke copies it)
  </read_first>
  <action>
    Create the new file `.planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` with the following EXACT content:

    ```bash
    #!/usr/bin/env bash
    # .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh
    # Hermetic smoke test: confirms verify-doc-sweep.sh gate 4 detects `doc/arch/`
    # singular-path drift. Injects a deliberate violation into a TEMP COPY of
    # CLAUDE.md (NOT the real file), runs the gate against the temp copy, and
    # asserts the gate fails. Cleans up unconditionally.
    #
    # Exit 0 = gate 4 correctly detected drift (smoke PASS).
    # Exit non-zero = gate 4 still cannot detect drift (smoke FAIL — regression).

    set -euo pipefail

    WORKDIR=$(mktemp -d)
    trap 'rm -rf "$WORKDIR"' EXIT

    # Copy CLAUDE.md and .claude/rules/arch.md into the workdir
    cp CLAUDE.md "$WORKDIR/CLAUDE.md"
    mkdir -p "$WORKDIR/.claude/rules"
    cp .claude/rules/arch.md "$WORKDIR/.claude/rules/arch.md"

    # Inject deliberate drift into the temp CLAUDE.md
    echo "see doc/arch/foo for details" >> "$WORKDIR/CLAUDE.md"

    # Build a temp copy of the gate script that reads from $WORKDIR
    TEMP_SCRIPT="$WORKDIR/verify-doc-sweep.sh"
    sed -e "s|CLAUDE\.md|$WORKDIR/CLAUDE.md|g" \
        -e "s|\.claude/rules/arch\.md|$WORKDIR/.claude/rules/arch.md|g" \
        .planning/phases/07-documentation-sweep/verify-doc-sweep.sh > "$TEMP_SCRIPT"
    chmod +x "$TEMP_SCRIPT"

    # Run the gate; expect non-zero exit (drift was injected)
    if bash "$TEMP_SCRIPT" >/dev/null 2>&1; then
      echo "SMOKE FAIL: gate 4 did NOT detect injected doc/arch/foo drift"
      exit 1
    fi

    echo "SMOKE PASS: gate 4 correctly fails on doc/arch/ drift"
    exit 0
    ```

    Key invariants the file MUST satisfy:
    1. Begins with `#!/usr/bin/env bash` shebang.
    2. Includes `set -euo pipefail`.
    3. Uses `mktemp -d` to create a hermetic working directory.
    4. Sets a `trap 'rm -rf "$WORKDIR"' EXIT` to guarantee cleanup.
    5. Copies `CLAUDE.md` and `.claude/rules/arch.md` into the temp workdir (preserving the `.claude/rules/` subdirectory).
    6. Appends the literal string `see doc/arch/foo for details` as a NEW LINE to the temp `CLAUDE.md` (does NOT touch the real CLAUDE.md).
    7. Uses `sed` to redirect the gate script's CLAUDE.md and .claude/rules/arch.md references to the temp workdir paths.
    8. Runs the temp script with output suppressed.
    9. If the temp script EXITS 0 (gate 4 did NOT detect drift), prints `SMOKE FAIL: ...` and exits 1.
    10. Otherwise prints `SMOKE PASS: ...` and exits 0.

    After writing the file, run `chmod +x .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh`.

    Then verify the smoke test PASSES (confirms the gate works correctly post-Task-1):
    `bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh; echo EXIT: $?` → expected `SMOKE PASS` line, `EXIT: 0`.

    **Hermeticity invariant:** running the smoke MUST NOT modify the real `CLAUDE.md`, `.claude/rules/arch.md`, or `verify-doc-sweep.sh`. Verify with `git status --porcelain CLAUDE.md .claude/rules/arch.md` after running the smoke — both must be clean.

    Smoke fixture must NOT depend on any tool beyond stock macOS / Linux bash (mktemp, cp, sed, awk, grep, bash). No flutter, no dart, no node.
  </action>
  <verify>
    <automated>test -x .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh && head -1 .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh | grep -q '^#!/usr/bin/env bash$' && grep -q 'mktemp -d' .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh && grep -q "trap 'rm -rf" .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh && grep -q 'doc/arch/foo' .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh && bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh</automated>
  </verify>
  <acceptance_criteria>
    - `test -x .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` exits 0 (file exists and is executable)
    - `head -1 .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` outputs `#!/usr/bin/env bash`
    - `grep -c '^set -euo pipefail$' .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` returns `1`
    - `grep -q 'mktemp -d' .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` exits 0 (hermetic temp dir present)
    - `grep -q "trap 'rm -rf" .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` exits 0 (cleanup trap present)
    - `grep -q 'doc/arch/foo' .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` exits 0 (drift injection present)
    - `grep -q 'SMOKE PASS' .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` exits 0 (success message defined)
    - `grep -q 'SMOKE FAIL' .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` exits 0 (failure message defined)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh; [ $? -eq 0 ]` exits 0 (smoke confirms gate 4 detects drift post-Task-1)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh 2>&1 | grep -q '^SMOKE PASS'` exits 0 (success message printed)
    - After running the smoke: `git status --porcelain CLAUDE.md .claude/rules/arch.md` returns empty if those were unmodified pre-smoke (real files unmodified — hermeticity)
    - `wc -l .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh | awk '{print $1}'` returns at least `20`
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0`
  </acceptance_criteria>
  <files_modified>.planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh</files_modified>
  <done>Smoke fixture exists, is executable, runs hermetically, and reports SMOKE PASS — confirming gate 4 mechanically detects future doc/arch/ drift.</done>
</task>

<task type="auto">
  <id>07-06-03</id>
  <wave>1</wave>
  <name>Task 3: Relocate orphan trailing metadata in ADR-002, ADR-008, ADR-010 (WR-02)</name>
  <files>docs/arch/03-adr/ADR-002_Database_Solution.md, docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md, docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-002_Database_Solution.md (full file — confirm line 635 = Update heading; line 652 = `**下次Review日期:** 2026-08-03`; lines 633-634 = the original document footer)
    - docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md (full file — confirm line 1191 = Update heading; line 1205 = `**下次审查:** 实施完成后进行效果评估`)
    - docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md (full file — confirm line 1469 = Update heading; line 1480 = `**优先级:** P1（高优先级）`)
    - docs/arch/03-adr/ADR-007_Layer_Responsibilities.md (REFERENCE — line 960 = Update heading; the file ENDS at line 986 with the citation line — no orphan trailing metadata. This is the correct shape ADR-002/008/010 should mirror.)
    - .planning/phases/07-documentation-sweep/07-VERIFICATION.md (gap 2 — exact orphan line text per ADR)
  </read_first>
  <action>
    For each of the three ADRs, MOVE the trailing metadata line from AFTER the Update section to BEFORE the `## Update 2026-04-27: Cleanup Initiative Outcome` heading. Preserve the metadata text VERBATIM — only its position changes. Do NOT modify the Update section content; do NOT add any new content.

    **ADR-002_Database_Solution.md:**
    1. Locate line 652: `**下次Review日期:** 2026-08-03` (the very last line of the file).
    2. Delete that line plus any trailing blank line preceding it that is now orphaned.
    3. Read lines 631-634 (the original document footer block, including the `---` separator around the Update heading on line 635). The content immediately before line 635 is the original closing block — typically a `---` then the Update heading.
    4. Insert `**下次Review日期:** 2026-08-03` as a new line WITHIN the original footer block, BEFORE the `---` separator that immediately precedes line 635 (the Update heading). The insertion point belongs to the original closing block, not a new section.
    5. Final result: the file's last `## ` heading is the Update heading; no `**...:**` metadata line appears AFTER it.

    **ADR-008_Book_Balance_Update_Strategy.md:**
    Same pattern. Move `**下次审查:** 实施完成后进行效果评估` from line 1205 to BEFORE the `## Update 2026-04-27` heading on line 1191. Place it within the original footer block (right after the existing `**决策状态:**` / `**待办事项:**` lines or immediately before the `---` separator that introduces the Update section).

    **ADR-010_CRDT_Conflict_Resolution_Strategy.md:**
    Same pattern. Move `**优先级:** P1（高优先级）` from line 1480 to BEFORE the `## Update 2026-04-27` heading on line 1469. Place it within the original footer block (right before the `---` separator that introduces the Update section, alongside the existing `**文档状态:**` / `**决策完成:**` / `**预计实施时间:**` lines).

    **Verification protocol per file:** acceptance criteria use grep matches (NOT line numbers, since metadata-relocation may shift line numbers by ±1) to verify:
    - The file's LAST `## ` heading is `## Update 2026-04-27: Cleanup Initiative Outcome`.
    - No `**...:**` metadata line appears AFTER the Update heading anywhere in the file.
    - The metadata text still exists in the file (relocated, not deleted).
    - Total line count is unchanged ±1 line per file.
    - Update section content (cross-reference link, decision-impact narrative, citation paragraph) is unchanged.

    **DO NOT** apply this fix to ADR-007 — its Update section is already correctly the last top-level content; changing it would create new drift.

    **DO NOT** modify the citation line `(\`.claude/rules/arch.md:171-173\`).` in this task — that's Task 5 (WR-03).
  </action>
  <verify>
    <automated>for f in docs/arch/03-adr/ADR-002_Database_Solution.md docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md; do last_section=$(grep -nE '^## ' "$f" | tail -1 | cut -d: -f1); last_meta=$(grep -nE '^\*\*[^*]+:\*\*' "$f" | tail -1 | cut -d: -f1); [ "$last_meta" -lt "$last_section" ] || { echo "FAIL: $f trailing metadata after Update (meta=$last_meta, section=$last_section)"; exit 1; }; done</automated>
  </verify>
  <acceptance_criteria>
    - ADR-002: the LAST `## ` heading in the file is `## Update 2026-04-27: Cleanup Initiative Outcome`. Verify: `grep -nE '^## ' docs/arch/03-adr/ADR-002_Database_Solution.md | tail -1 | grep -q 'Update 2026-04-27'` exits 0
    - ADR-002: NO `**...:**` metadata line appears after the Update heading. Verify: `awk '/^## Update 2026-04-27/{found=1; next} found && /^\*\*[^*]+:\*\*/{exit 1}' docs/arch/03-adr/ADR-002_Database_Solution.md` exits 0
    - ADR-002: `**下次Review日期:** 2026-08-03` STILL EXISTS in the file (relocated, not deleted). Verify: `grep -qF '**下次Review日期:** 2026-08-03' docs/arch/03-adr/ADR-002_Database_Solution.md` exits 0
    - ADR-002: line count is within 651..653 (was 652; ±1 tolerance for blank-line moves). Verify: `lc=$(wc -l < docs/arch/03-adr/ADR-002_Database_Solution.md); [ "$lc" -ge 651 ] && [ "$lc" -le 653 ]` succeeds
    - ADR-008: the LAST `## ` heading is `## Update 2026-04-27: Cleanup Initiative Outcome`. Same awk no-trailing-metadata check. `grep -qF '**下次审查:** 实施完成后进行效果评估' docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` exits 0. Line count within 1204..1206 (was 1205).
    - ADR-010: the LAST `## ` heading is `## Update 2026-04-27: Cleanup Initiative Outcome`. Same awk no-trailing-metadata check. `grep -qF '**优先级:** P1（高优先级）' docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` exits 0. Line count within 1479..1481 (was 1480).
    - ADR-007 is NOT modified by this task: `git diff --name-only HEAD~ HEAD docs/arch/03-adr/ADR-007_Layer_Responsibilities.md | wc -l` returns `0`
    - Update section content preserved in all three: `grep -c 'Cross-reference' docs/arch/03-adr/ADR-002_Database_Solution.md docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md | grep -c ':1$'` returns `3` (each file has exactly one cross-reference line)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0`
  </acceptance_criteria>
  <files_modified>docs/arch/03-adr/ADR-002_Database_Solution.md, docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md, docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md</files_modified>
  <done>The three ADRs each end with the Update section as their last top-level heading; previously-trailing metadata is now positioned within the original footer block, preserving append-only-at-file-end.</done>
</task>

<task type="auto">
  <id>07-06-04</id>
  <wave>2</wave>
  <name>Task 4: Add real ADR append-only rule to .claude/rules/arch.md (WR-03 root cause)</name>
  <files>.claude/rules/arch.md</files>
  <read_first>
    - .claude/rules/arch.md (full file — focus on lines 157-161 = `### 文档更新规则`; this is the insertion target. Lines 165-169 = `### 禁止操作`. Lines 171-... = `### Claude 执行规范`.)
  </read_first>
  <action>
    Open `.claude/rules/arch.md` and locate `### 文档更新规则` (currently at line 157). The subsection currently has 3 numbered items at lines 159-161:

        1. **小改动:** 直接修改文档，更新版本号的修订版（如 1.0 → 1.1）
        2. **重大改动:** 更新版本号的主版本（如 1.x → 2.0）
        3. **文档废弃:** 不删除文件，在文档头部添加 `[已废弃]` 标记，并注明替代文档

    Append item 4 immediately after item 3 (line 161). Insert this single new line:

        4. **ADR append-only:** ADR 文件在状态变为「✅ 已接受」之后只能 append — 后续上下文以 `## Update YYYY-MM-DD: <topic>` 区段追加在文件末尾，不修改原决策正文（保留决策的历史完整性）。

    The new line is item 4 of the existing `### 文档更新规则` subsection. After insertion:
    - Line 157 (unchanged): `### 文档更新规则`
    - Line 158 (unchanged): blank
    - Line 159 (unchanged): item 1
    - Line 160 (unchanged): item 2
    - Line 161 (unchanged): item 3
    - Line 162 (NEW): item 4 — the append-only rule
    - Subsequent line numbers shift by +1

    Do NOT modify any other subsection. Do NOT modify item numbering of items 1-3. Do NOT change `### 禁止操作` or `### Claude 执行规范`.

    **Citation target after this task:** the line range covering items 1-4 is `.claude/rules/arch.md:157-162`. Task 5 will use this exact range when updating the 4 ADR citations.

    Verify with the original gate WR-03 was based on:
    `grep -nE 'append-only|追加' .claude/rules/arch.md` must return at least 1 match (the new item 4 contains BOTH 'append-only' and '追加').
  </action>
  <verify>
    <automated>grep -qE 'append-only|追加' .claude/rules/arch.md && grep -q '^4\. \*\*ADR append-only:\*\*' .claude/rules/arch.md && awk 'NR==157,NR==162' .claude/rules/arch.md | grep -q 'append-only'</automated>
  </verify>
  <acceptance_criteria>
    - `grep -qE 'append-only|追加' .claude/rules/arch.md` exits 0 (the cited convention now actually exists)
    - `grep -c 'append-only' .claude/rules/arch.md` returns at least `1`
    - `grep -c '追加' .claude/rules/arch.md` returns at least `1`
    - `grep -q '^4\. \*\*ADR append-only:\*\*' .claude/rules/arch.md` exits 0 (item 4 added with the locked numbering and bold prefix)
    - `awk 'NR==157,NR==162' .claude/rules/arch.md | grep -q 'append-only'` exits 0 (the cited line range :157-162 actually contains the rule — Task 5 can safely cite this range)
    - `grep -q '^### 文档更新规则$' .claude/rules/arch.md` exits 0 (subsection heading still present)
    - `grep -q '^### 禁止操作$' .claude/rules/arch.md` exits 0 (next subsection unchanged)
    - `grep -q '^### Claude 执行规范$' .claude/rules/arch.md` exits 0 (subsection still exists; line number shifted but content unchanged)
    - `grep -q '^1\. \*\*小改动:\*\*' .claude/rules/arch.md && grep -q '^2\. \*\*重大改动:\*\*' .claude/rules/arch.md && grep -q '^3\. \*\*文档废弃:\*\*' .claude/rules/arch.md` exits 0 (existing items 1-3 preserved verbatim)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0`
  </acceptance_criteria>
  <files_modified>.claude/rules/arch.md</files_modified>
  <done>.claude/rules/arch.md now contains a real ADR append-only rule as item 4 of `### 文档更新规则`. The phrase 'append-only' (and '追加') appear in the file. Lines 157-162 contain the citable rule range.</done>
</task>

<task type="auto">
  <id>07-06-05</id>
  <wave>3</wave>
  <name>Task 5: Update citation line range in 4 append-only ADRs (WR-03 fix)</name>
  <files>docs/arch/03-adr/ADR-002_Database_Solution.md, docs/arch/03-adr/ADR-007_Layer_Responsibilities.md, docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md, docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-002_Database_Solution.md (line containing the `171-173` citation — currently at line 651 pre-Task-3, may be at line 651 or 652 post-Task-3)
    - docs/arch/03-adr/ADR-007_Layer_Responsibilities.md (line 986 = the citation line; ADR-007 was NOT modified by Task 3 so line stays at 986)
    - docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md (citation line — line 1204 pre-Task-3, may shift ±1 post-Task-3)
    - docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md (citation line — line 1479 pre-Task-3, may shift ±1 post-Task-3)
    - .claude/rules/arch.md (post-Task-4 state — confirm `### 文档更新规则` is at line 157 and item 4 is at line 162)
  </read_first>
  <action>
    For each of the four ADRs, replace the literal string `.claude/rules/arch.md:171-173` with `.claude/rules/arch.md:157-162` in the citation paragraph. Use grep to locate the exact line first; do not blind-replace.

    **Step-by-step (apply to each of the 4 files):**
    1. Read the file. Find the line matching the literal `(\`.claude/rules/arch.md:171-173\`).` (it appears exactly once per file — verified via grep in `<gap_evidence>`).
    2. Replace `171-173` with `157-162` on that line. Keep everything else (the parentheses, backticks, surrounding sentence) unchanged.
    3. Resulting line: `(\`.claude/rules/arch.md:157-162\`).`

    **Special case for ADR-010:** ADR-010 has TWO append-only-related lines (lines 1476 and 1478-1479 pre-Task-3). The FIRST line says `preserved as historical context per ADR append-only convention.` (no line range). Only the SECOND line cites `.claude/rules/arch.md:171-173`. Replace `171-173` with `157-162` only on the second occurrence. Leave the first line unchanged.

    **Optional prose strengthening (permitted but not required for acceptance):** The full sentence may be replaced from
    `The original decision body above is preserved verbatim per ADR append-only convention (\`.claude/rules/arch.md:171-173\`).`
    to
    `The original decision body above is preserved verbatim per the ADR append-only rule (\`.claude/rules/arch.md:157-162\`, item 4 of 文档更新规则).`
    Acceptance criteria below check ONLY for the line-range update.

    **Verification:** after the four edits, the obsolete citation must not appear anywhere:
    `grep -l '171-173' docs/arch/03-adr/ADR-002*.md docs/arch/03-adr/ADR-007*.md docs/arch/03-adr/ADR-008*.md docs/arch/03-adr/ADR-010*.md` → expected: no output.

    And the new citation must appear exactly once per file:
    `for f in docs/arch/03-adr/ADR-002*.md docs/arch/03-adr/ADR-007*.md docs/arch/03-adr/ADR-008*.md docs/arch/03-adr/ADR-010*.md; do [ "$(grep -c '157-162' "$f")" = "1" ] || { echo "FAIL: $f"; exit 1; }; done`

    **Backstop verification:** the cited line range must contain the cited content:
    `awk 'NR==157,NR==162' .claude/rules/arch.md | grep -q 'append-only'` → expected exit 0. This was guaranteed by Task 4 — Task 5 inherits Task 4's correctness.
  </action>
  <verify>
    <automated>! grep -l '171-173' docs/arch/03-adr/ADR-002_Database_Solution.md docs/arch/03-adr/ADR-007_Layer_Responsibilities.md docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md && for f in docs/arch/03-adr/ADR-002_Database_Solution.md docs/arch/03-adr/ADR-007_Layer_Responsibilities.md docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md; do grep -q '\.claude/rules/arch\.md:157-162' "$f" || { echo "FAIL: $f"; exit 1; }; done && awk 'NR==157,NR==162' .claude/rules/arch.md | grep -q 'append-only'</automated>
  </verify>
  <acceptance_criteria>
    - `grep -l '171-173' docs/arch/03-adr/ADR-002*.md docs/arch/03-adr/ADR-007*.md docs/arch/03-adr/ADR-008*.md docs/arch/03-adr/ADR-010*.md` produces no output (the obsolete citation is gone from all 4 files)
    - All 4 ADRs cite the new range exactly once: `for f in ADR-002 ADR-007 ADR-008 ADR-010; do grep -c '157-162' docs/arch/03-adr/${f}*.md; done` returns `1` for each file
    - `grep -q '\.claude/rules/arch\.md:157-162' docs/arch/03-adr/ADR-002_Database_Solution.md` exits 0
    - `grep -q '\.claude/rules/arch\.md:157-162' docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` exits 0
    - `grep -q '\.claude/rules/arch\.md:157-162' docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` exits 0
    - `grep -q '\.claude/rules/arch\.md:157-162' docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` exits 0
    - The cited range contains the rule: `awk 'NR==157,NR==162' .claude/rules/arch.md | grep -q 'append-only'` exits 0 (citation honesty restored)
    - Cross-reference links to ADR-011 still present in all 4 files: `for f in ADR-002 ADR-007 ADR-008 ADR-010; do grep -q 'ADR-011' docs/arch/03-adr/${f}*.md; done` succeeds for each
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0`
  </acceptance_criteria>
  <files_modified>docs/arch/03-adr/ADR-002_Database_Solution.md, docs/arch/03-adr/ADR-007_Layer_Responsibilities.md, docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md, docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md</files_modified>
  <done>All 4 append-only ADRs cite `.claude/rules/arch.md:157-162` instead of the obsolete `:171-173`; the cited line range really contains an append-only rule; obsolete citation eradicated.</done>
</task>

<task type="auto">
  <id>07-06-06</id>
  <wave>3</wave>
  <name>Task 6: Sync ADR-000_INDEX.md statistics + add ADR-011 review row (WR-04)</name>
  <files>docs/arch/03-adr/ADR-000_INDEX.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-000_INDEX.md (full file — focus lines 411-419 = decision-statistics table; lines 423-436 = 下次Review计划 table; line 360 = ADR-011 entry; line 378 = "下次Review: 2026-10-27 (每半年)" promise)
    - .planning/phases/07-documentation-sweep/07-VERIFICATION.md (gap 4 — exact target values)
  </read_first>
  <action>
    Apply two surgical edits to `docs/arch/03-adr/ADR-000_INDEX.md`:

    **Edit 1 — Statistics table (lines 411-419):**
    - Line 413: `| ✅ 已接受 | 9 |` → `| ✅ 已接受 | 10 |`
    - Line 419: `**总计:** 10个ADR` → `**总计:** 11个ADR`

    Other rows in the table (`✅ 已实施 | 1`, `🔄 讨论中 | 0`, `❌ 已拒绝 | 0`, `📝 草稿 | 0`) are UNCHANGED. The math: 10 已接受 + 1 已实施 + 0 + 0 + 0 = 11 总计. Verify the math holds before committing.

    **Edit 2 — 下次Review计划 table (lines 423-436):**
    Append a new row for ADR-011 immediately after the ADR-010 row (currently the last row, around line 436):

        | ADR-011 | 2026-10-27 | 每6个月 |

    The cadence (`每6个月`) and date (`2026-10-27`) are dictated by:
    - ADR-000_INDEX.md line 378's existing entry promises `下次Review: 2026-10-27 (每半年)`. "每半年" = "每6个月" — match the existing column-2 vocabulary used by ADR-001/002/004/005/007 rows.
    - 2026-10-27 = 6 months after the 2026-04-27 acceptance date.

    DO NOT modify any other content in this file. The ADR-011 entry block at lines ~360-380 was added by Plan 07-05 and is correct as-is.

    Math sanity check (verify on disk first): `ls docs/arch/03-adr/ADR-*.md | grep -v INDEX | wc -l` should return 11. If it returns a different number, abort and investigate — the statistics fix would be wrong.
  </action>
  <verify>
    <automated>grep -q '^| ✅ 已接受 | 10 |$' docs/arch/03-adr/ADR-000_INDEX.md && grep -q '^\*\*总计:\*\* 11个ADR$' docs/arch/03-adr/ADR-000_INDEX.md && grep -q '| ADR-011 | 2026-10-27 | 每6个月 |' docs/arch/03-adr/ADR-000_INDEX.md && [ "$(ls docs/arch/03-adr/ADR-*.md | grep -v INDEX | wc -l | tr -d ' ')" = "11" ]</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q '^| ✅ 已接受 | 10 |$' docs/arch/03-adr/ADR-000_INDEX.md` exits 0 (decision-statistics row updated)
    - `grep -q '^\*\*总计:\*\* 11个ADR$' docs/arch/03-adr/ADR-000_INDEX.md` exits 0 (total updated)
    - `! grep -q '^\*\*总计:\*\* 10个ADR$' docs/arch/03-adr/ADR-000_INDEX.md` exits 0 (old total removed)
    - `! grep -q '^| ✅ 已接受 | 9 |$' docs/arch/03-adr/ADR-000_INDEX.md` exits 0 (old count removed)
    - `grep -q '| ADR-011 | 2026-10-27 | 每6个月 |' docs/arch/03-adr/ADR-000_INDEX.md` exits 0 (review-schedule row added)
    - `grep -c '^| ADR-' docs/arch/03-adr/ADR-000_INDEX.md` reflects an additional row in the review-schedule table (was 10 ADR-XXX rows in that table; now 11 — though the file may have other table rows containing `ADR-`, the relevant invariant is the ADR-011 row exists)
    - Math sanity (must hold pre-edit): `[ "$(ls docs/arch/03-adr/ADR-*.md | grep -v INDEX | wc -l | tr -d ' ')" = "11" ]` succeeds
    - ADR-011 entry block (added by Plan 07-05) preserved: `grep -q '\[ADR-011: Codebase Cleanup Initiative Outcome\]' docs/arch/03-adr/ADR-000_INDEX.md` exits 0
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0`
  </acceptance_criteria>
  <files_modified>docs/arch/03-adr/ADR-000_INDEX.md</files_modified>
  <done>ADR-000_INDEX.md statistics report 10 已接受 / 11 总计; 下次Review计划 table contains an ADR-011 row.</done>
</task>

<task type="auto">
  <id>07-06-07</id>
  <wave>3</wave>
  <name>Task 7: Sync docs/arch/README.md statistics + add ADR-011 to directory tree (WR-05)</name>
  <files>docs/arch/README.md</files>
  <read_first>
    - docs/arch/README.md (full file — focus lines 14-61 = directory tree; lines 38-49 = 03-adr/ enumeration; lines 223-230 = 文档统计 table)
    - .planning/phases/07-documentation-sweep/07-VERIFICATION.md (gap 4 — exact target values for README)
  </read_first>
  <action>
    Apply two surgical edits to `docs/arch/README.md`:

    **Edit 1 — Statistics table (lines 223-230):**
    - Line 227: `| ADR 决策记录 | 10 | ✅ 完成 |` → `| ADR 决策记录 | 11 | ✅ 完成 |`
    - Line 230: `| **总计** | **32** | **✅ 完成** |` → `| **总计** | **33** | **✅ 完成** |`

    Other rows (`整体架构文档 | 8`, `模块功能文档 | 9`, `基础能力 PRD | 4`, `UI 规范文档 | 1`) are UNCHANGED. Math: 8 + 9 + 11 + 4 + 1 = 33. Verify before committing.

    **Edit 2 — Directory tree (lines 14-61):**
    Locate the `03-adr/` block in the tree. Pre-edit it lists ADR-001..010 at lines ~40-49. The line just before the closing `│` for the 03-adr block looks like:

        │   └── ADR-010_CRDT_Conflict_Resolution_Strategy.md

    Change that line's tree-character from `└──` (last child) to `├──` (intermediate child), and add a new line immediately after for ADR-011, using `└──` to mark it as the new last child:

        │   ├── ADR-010_CRDT_Conflict_Resolution_Strategy.md
        │   └── ADR-011_Codebase_Cleanup_Initiative_Outcome.md

    DO NOT modify any other tree entries. The exact tree characters MUST match the surrounding pattern (`│   ` indent followed by `├──` or `└──`).

    DO NOT modify any other section of the README (no other prose changes, no other table edits).

    Math sanity check: `ls docs/arch/03-adr/ADR-*.md | grep -v INDEX | wc -l` returns 11. `ls docs/arch/03-adr/*.md | wc -l` returns 12 (including INDEX). The README counts NUMBERED ADRs (excluding INDEX) → 11.
  </action>
  <verify>
    <automated>grep -q '^| ADR 决策记录 | 11 | ✅ 完成 |$' docs/arch/README.md && grep -q '^| \*\*总计\*\* | \*\*33\*\* | \*\*✅ 完成\*\* |$' docs/arch/README.md && grep -q 'ADR-011_Codebase_Cleanup_Initiative_Outcome\.md' docs/arch/README.md && ! grep -q '^| ADR 决策记录 | 10 | ✅ 完成 |$' docs/arch/README.md && ! grep -q '^| \*\*总计\*\* | \*\*32\*\* | \*\*✅ 完成\*\* |$' docs/arch/README.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q '^| ADR 决策记录 | 11 | ✅ 完成 |$' docs/arch/README.md` exits 0 (statistics row bumped)
    - `grep -q '^| \*\*总计\*\* | \*\*33\*\* | \*\*✅ 完成\*\* |$' docs/arch/README.md` exits 0 (total bumped)
    - `! grep -q '^| ADR 决策记录 | 10 | ✅ 完成 |$' docs/arch/README.md` exits 0 (old count removed)
    - `! grep -q '^| \*\*总计\*\* | \*\*32\*\* | \*\*✅ 完成\*\* |$' docs/arch/README.md` exits 0 (old total removed)
    - `grep -q 'ADR-011_Codebase_Cleanup_Initiative_Outcome\.md' docs/arch/README.md` exits 0 (directory tree includes ADR-011)
    - The directory tree's `03-adr/` block ends with ADR-011 as the last child marked with `└──`: `awk '/^├── 03-adr/,/^├── 04-basic|^└── 04-basic|^├── 05-UI|^└── 05-UI|^└── README/' docs/arch/README.md | grep -q '└── ADR-011_Codebase_Cleanup_Initiative_Outcome\.md'` exits 0 (ADR-011 is the last child in the 03-adr subtree)
    - ADR-010 is now an intermediate child (changed from `└──` to `├──`): `grep -q '├── ADR-010_CRDT_Conflict_Resolution_Strategy\.md' docs/arch/README.md` exits 0
    - Math sanity: `[ "$(ls docs/arch/03-adr/ADR-*.md | grep -v INDEX | wc -l | tr -d ' ')" = "11" ]` succeeds
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0`
  </acceptance_criteria>
  <files_modified>docs/arch/README.md</files_modified>
  <done>docs/arch/README.md reports 11 ADRs / 33 total; the 03-adr/ subtree of the directory tree includes ADR-011 as the last child.</done>
</task>

<task type="auto">
  <id>07-06-08</id>
  <wave>3</wave>
  <name>Task 8: Sync ARCH-000_INDEX.md document-completion stats (WR-05)</name>
  <files>docs/arch/01-core-architecture/ARCH-000_INDEX.md</files>
  <read_first>
    - docs/arch/01-core-architecture/ARCH-000_INDEX.md (full file — focus lines 569-577 = 文档完成度 table)
    - .planning/phases/07-documentation-sweep/07-VERIFICATION.md (gap 4 — exact target values for ARCH-000)
  </read_first>
  <action>
    Apply two surgical edits to `docs/arch/01-core-architecture/ARCH-000_INDEX.md`:

    **Edit 1 — Document-completion table (lines 569-577):**
    - Line 575: `| ADR决策记录 | 10 | ✅ 100% |` → `| ADR决策记录 | 11 | ✅ 100% |`
    - Line 577: `| **总计** | **30** | **✅ 100%** |` → `| **总计** | **31** | **✅ 100%** |`

    Other rows (`核心架构文档 | 8`, `功能模块文档 | 8 (+1 缺失)`, `基础能力 PRD | 4`) are UNCHANGED. Math: 8 + 8 + 11 + 4 = 31. Verify before committing.

    Note: ARCH-000_INDEX.md table does NOT include UI-001 (UI specs are not counted in this table). The total of 31 is correct without UI inclusion. The README.md table DOES include UI-001 → 33. The discrepancy (31 vs 33) is acceptable because the two tables count different scopes — README counts all docs/arch/ files; ARCH-000 counts only the four categories it tracks (core / module / ADR / BASIC).

    DO NOT modify any other content in this file (no other table edits, no other prose changes).

    Math sanity check: 8 (核心架构) + 8 (功能模块, with the +1 缺失 annotation kept verbatim) + 11 (ADR post-fix) + 4 (BASIC) = 31. Verify before committing.
  </action>
  <verify>
    <automated>grep -q '^| ADR决策记录 | 11 | ✅ 100% |$' docs/arch/01-core-architecture/ARCH-000_INDEX.md && grep -q '^| \*\*总计\*\* | \*\*31\*\* | \*\*✅ 100%\*\* |$' docs/arch/01-core-architecture/ARCH-000_INDEX.md && ! grep -q '^| ADR决策记录 | 10 | ✅ 100% |$' docs/arch/01-core-architecture/ARCH-000_INDEX.md && ! grep -q '^| \*\*总计\*\* | \*\*30\*\* | \*\*✅ 100%\*\* |$' docs/arch/01-core-architecture/ARCH-000_INDEX.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q '^| ADR决策记录 | 11 | ✅ 100% |$' docs/arch/01-core-architecture/ARCH-000_INDEX.md` exits 0
    - `grep -q '^| \*\*总计\*\* | \*\*31\*\* | \*\*✅ 100%\*\* |$' docs/arch/01-core-architecture/ARCH-000_INDEX.md` exits 0
    - `! grep -q '^| ADR决策记录 | 10 | ✅ 100% |$' docs/arch/01-core-architecture/ARCH-000_INDEX.md` exits 0 (old count removed)
    - `! grep -q '^| \*\*总计\*\* | \*\*30\*\* | \*\*✅ 100%\*\* |$' docs/arch/01-core-architecture/ARCH-000_INDEX.md` exits 0 (old total removed)
    - Other table rows preserved: `grep -q '^| 核心架构文档 | 8 | ✅ 100% |$' docs/arch/01-core-architecture/ARCH-000_INDEX.md && grep -q '基础能力 PRD | 4' docs/arch/01-core-architecture/ARCH-000_INDEX.md` exits 0
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0`
  </acceptance_criteria>
  <files_modified>docs/arch/01-core-architecture/ARCH-000_INDEX.md</files_modified>
  <done>ARCH-000_INDEX.md document-completion table reports 11 ADRs and 31 total.</done>
</task>

<task type="auto">
  <id>07-06-09</id>
  <wave>4</wave>
  <name>Task 9: Final gate — run all three verification scripts + lib/-clean phase invariant</name>
  <files></files>
  <read_first>
    - .planning/phases/07-documentation-sweep/verify-doc-sweep.sh (post-Task-1 — gate 4 fixed)
    - .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh (Task-2 fixture)
    - scripts/verify_index_health.sh (created in Plan 07-04 — must remain passing)
    - All 8 task SUMMARYs for tasks 1-8 above (cumulative state for the close-out report)
  </read_first>
  <action>
    Run the final phase gates. This task does NOT modify any production files — it is purely verification + summary capture.

    **Gate 1 — verify-doc-sweep.sh (post-Task-1 fix):**

        bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
        # Expected: exit code 0; all six [N/6] lines print "OK"; no `integer expression expected` on stderr

    **Gate 2 — verify-doc-sweep-smoke.sh (Task-2 hermetic fixture):**

        bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh
        # Expected: prints `SMOKE PASS: gate 4 correctly fails on doc/arch/ drift`; exit code 0

    **Gate 3 — verify_index_health.sh (still green from Plan 07-04):**

        bash scripts/verify_index_health.sh
        # Expected: exit code 0; zero BROKEN LINK / ORPHAN warnings

    **Gate 4 — lib/-clean invariant for plan 07-06's commits:**

        git diff --name-only ef4b770..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'
        # Expected: 0

    `ef4b770` is the SHA captured in `<gap_evidence>` as the last commit before plan 07-06 began. If the executor lands commits on a different base (e.g., another phase merges first), substitute the actual pre-07-06 base SHA captured by reading `git log` for the first 07-06 commit's parent.

    **Gate 5 — Phase 7 cumulative invariant (cross-plan, including 07-06):**

        git diff --name-only main..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'
        # Expected: 0

    This is the same Phase-level invariant Plan 07-05 verified, re-checked AFTER the gap-closure plan's commits land. The 10 files modified by 07-06 are all under `docs/`, `.claude/rules/`, or `.planning/phases/07-documentation-sweep/` — none under the forbidden paths.

    All five gates MUST pass simultaneously.

    **If any gate fails:**
    - Gate 1 / 2: regression in Task 1 or 2 — re-read the gate script and the smoke fixture; do not modify production files to "make the gate pass" — diagnose root cause.
    - Gate 3: a Task 6/7/8 edit broke INDEX health (unlikely; statistics edits don't affect link/orphan checks). Roll back the offending edit.
    - Gate 4 / 5: forbidden file accidentally modified. Roll back, do not commit.

    **Capture all five gates' stdout + exit codes** in the SUMMARY file produced after this task.

    **Source-of-truth audit:** also verify the four MEDIUM gaps from 07-VERIFICATION.md are now closed:
    - WR-01: `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh 2>&1 | grep -c 'integer expression expected'` returns 0 (no stderr leak); smoke gate 2 passes.
    - WR-02: `for f in docs/arch/03-adr/ADR-002_Database_Solution.md docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md; do awk '/^## Update 2026-04-27/{f=1; next} f && /^\*\*[^*]+:\*\*/{exit 1}' "$f" || exit 1; done` exits 0 (no orphan trailing metadata).
    - WR-03: `grep -lR '171-173' docs/arch/03-adr/ADR-00*.md docs/arch/03-adr/ADR-010*.md 2>/dev/null` produces no output (obsolete citation eradicated); `grep -qE 'append-only|追加' .claude/rules/arch.md` exits 0 (real rule exists).
    - WR-04: `grep -q '11个ADR' docs/arch/03-adr/ADR-000_INDEX.md && grep -q '| ADR-011 | 2026-10-27' docs/arch/03-adr/ADR-000_INDEX.md` exits 0.
    - WR-05: `grep -q 'ADR 决策记录 | 11' docs/arch/README.md && grep -q 'ADR-011_Codebase_Cleanup_Initiative_Outcome' docs/arch/README.md && grep -q 'ADR决策记录 | 11' docs/arch/01-core-architecture/ARCH-000_INDEX.md` exits 0.
  </action>
  <verify>
    <automated>bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh && bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh && bash scripts/verify_index_health.sh && [ "$(git diff --name-only main..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)')" = "0" ]</automated>
  </verify>
  <acceptance_criteria>
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (Gate 1 — all 6 grep gates pass)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh 2>&1 | grep -c '^  OK$'` returns at least `6`
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh 2>&1 | grep -c 'integer expression expected'` returns `0` (no stderr warning)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` exits 0 (Gate 2 — smoke confirms gate 4 detects drift)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh 2>&1 | grep -q '^SMOKE PASS'` exits 0
    - `bash scripts/verify_index_health.sh` exits 0 (Gate 3 — INDEX health unbroken)
    - `bash scripts/verify_index_health.sh 2>&1 | grep -cE 'BROKEN LINK|ORPHAN'` returns `0`
    - `git diff --name-only main..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (Gate 4/5 — Phase-level lib/-clean invariant; covers all of 07-01..07-06)
    - All 4 WR gaps closed: WR-01 (gate fixed + smoke present), WR-02 (no orphan metadata in ADR-002/008/010), WR-03 (no `171-173` citations remain; real rule exists), WR-04/WR-05 (statistics tables sync with ADR-011)
    - SUMMARY file `.planning/phases/07-documentation-sweep/07-06-SUMMARY.md` exists and captures stdout from all five gates plus the per-WR audit
  </acceptance_criteria>
  <files_modified></files_modified>
  <done>All five gates pass simultaneously; the four WR gaps from 07-VERIFICATION.md are closed; lib/-clean invariant holds across the entire phase.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Future contributor → verify-doc-sweep.sh gate 4 | Gate must mechanically detect drift, not just print OK. The fix replaces a structurally-broken grep with a summed integer test. |
| Future contributor → 4 append-only ADR citations | Citations must point at real, locatable rule content. The fix adds the rule and updates citations atomically. |
| README/INDEX statistics → actual ADR file count on disk | Rollup tables are the document inventory; staleness misleads external auditors. |
| Smoke fixture → real CLAUDE.md | The smoke MUST be hermetic — copying-into-tmpdir, never mutating the real file. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-06-01 | Tampering | A "fix" to verify-doc-sweep.sh that silences the gate without restoring detection | mitigate | Task 2's smoke fixture proves gate 4 detects injected drift; if smoke fails, Task 1's "fix" was wrong. The smoke is non-negotiable. |
| T-07-06-02 | Tampering (real CLAUDE.md mutation) | smoke fixture writes drift into the actual CLAUDE.md instead of the temp copy | mitigate | Task 2 acceptance includes `git status --porcelain CLAUDE.md` returning empty after smoke run. The smoke uses `mktemp -d` + temp copy + `trap rm -rf` cleanup. |
| T-07-06-03 | Information Disclosure | Citation update lands `157-162` but Task 4 actually wrote rule at `162-167` (line drift) | mitigate | Task 4's last acceptance check is `awk 'NR==157,NR==162' .claude/rules/arch.md \| grep -q 'append-only'` — fails if the rule is outside the cited range, blocking commit. |
| T-07-06-04 | Tampering (deferred-item drift) | Plan 07-06 attempts to fix a deferred item (e.g., MOD numbering, ARCH-008 ADR-006 citations) and exceeds scope | mitigate | files_modified frontmatter explicitly lists 10 paths; the executor MUST fail acceptance if any other file is touched. The Phase-level lib/-clean check is a hard backstop. |
| T-07-06-05 | Repudiation | Statistics tables get bumped but the ADR-011 file does not actually exist in the directory | mitigate | Task 6 includes `[ "$(ls docs/arch/03-adr/ADR-*.md | grep -v INDEX | wc -l | tr -d ' ')" = "11" ]` as a sanity gate before committing the bump. |
| T-07-06-06 | DoS (verification-side) | Smoke test runs slowly or blocks CI | accept | Smoke is local-only, runs in <1s on stock bash; not added to CI by this plan. |

</threat_model>

<verification>
- All 9 task acceptance criteria pass.
- Final task (07-06-09) runs all five gates and confirms simultaneous green.
- Specifically:
  - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` → exit 0 with 6 OK lines, NO stderr "integer expression expected".
  - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh` → exit 0 with `SMOKE PASS` printed.
  - `bash scripts/verify_index_health.sh` → exit 0.
  - `git diff --name-only main..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` → 0 (covers all of Phase 7, including the new commits).
  - All four WR gaps from 07-VERIFICATION.md frontmatter are mechanically closed.
- Phase 7's mechanical drift gate (verify-doc-sweep.sh) now actually detects the drift it was created to detect — proven by the smoke fixture, not just by reading the script.

</verification>

<success_criteria>
- 1 corrected gate script (verify-doc-sweep.sh gate 4)
- 1 new hermetic smoke fixture (verify-doc-sweep-smoke.sh)
- 1 new rule subsection (item 4 of `### 文档更新规则` in .claude/rules/arch.md)
- 4 ADR citation fixes (ADR-002, 007, 008, 010 — `171-173` → `157-162`)
- 3 ADR metadata relocations (ADR-002, 008, 010 — orphan trailing line moved before Update heading)
- 3 statistics-table bumps (ADR-000_INDEX, README, ARCH-000_INDEX)
- 1 directory-tree entry added (README.md ADR-011 row)
- 1 review-schedule row added (ADR-000_INDEX.md)
- All four MEDIUM-severity gaps from 07-VERIFICATION.md closed mechanically.
- Phase 7's lib/-clean invariant continues to hold across the gap-closure commits (verifiable by `git diff --name-only main..HEAD`).
- All four phase requirement IDs (DOCS-01..04) addressed:
  - DOCS-01 (ARCH/MOD/ADR drift fix): WR-02/WR-03 strengthen ADR append-only craft; WR-05 syncs README + ARCH-000.
  - DOCS-02 (CLAUDE.md pitfalls annotated): not directly modified, but the `verify-doc-sweep.sh` gate that backstops this contract is now mechanically functional (WR-01).
  - DOCS-03 (INDEX integrity): WR-04 syncs ADR-000_INDEX.md statistics + review schedule.
  - DOCS-04 (ADR-011 + CI enforcement): WR-03 makes ADR-011's append-only convention citation honest; WR-04 syncs the INDEX entry.
</success_criteria>

<output>
After completion, create `.planning/phases/07-documentation-sweep/07-06-SUMMARY.md` with:
- Capture stdout + exit codes from all five gates (verify-doc-sweep.sh, verify-doc-sweep-smoke.sh, verify_index_health.sh, two `git diff` lib/-clean checks)
- Per-WR closure audit:
  - WR-01: pre/post stderr capture; smoke fixture pass evidence
  - WR-02: per-file last-section heading and no-trailing-metadata grep results
  - WR-03: pre/post `grep -nE 'append-only|追加'` on .claude/rules/arch.md; per-ADR `grep '157-162'` results
  - WR-04: ADR-000_INDEX.md statistics block diff
  - WR-05: README.md and ARCH-000_INDEX.md statistics block diffs; directory tree diff
- Final files-modified list (must be exactly the 10 paths in this plan's frontmatter)
- Phase-level lib/-clean confirmation: list of all files modified across Phase 7 (07-01 through 07-06)
- Closing note: all four MEDIUM-severity gaps from 07-VERIFICATION.md closed; verify-doc-sweep.sh now mechanically guards what it claims to guard
</output>
