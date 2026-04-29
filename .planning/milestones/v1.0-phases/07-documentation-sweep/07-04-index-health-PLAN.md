---
phase: 07-documentation-sweep
plan: 04
type: execute
wave: 2
depends_on: ["07-01-arch-mod-drift-PLAN.md", "07-02-adr-drift-PLAN.md", "07-03-claude-md-pitfall-annotation-PLAN.md"]
files_modified:
  - scripts/verify_index_health.sh
  - docs/arch/02-module-specs/MOD-000_INDEX.md
  - docs/arch/01-core-architecture/ARCH-000_INDEX.md
  - docs/arch/README.md
autonomous: true
requirements: [DOCS-01, DOCS-03]

must_haves:
  truths:
    - "Wave 0 task creates `scripts/verify_index_health.sh` (executable; mirrors Pattern 3 shell loop from 07-RESEARCH.md). On the first run after creation, the script exits non-zero (some INDEX issues are present in main: phantom files in README.md, missing MOD-000 INDEX, etc.)."
    - "After this plan completes, `bash scripts/verify_index_health.sh` exits 0: every INDEX entry links to a real file; every file in each indexed directory is referenced by its INDEX (orphan-free)."
    - "`docs/arch/02-module-specs/MOD-000_INDEX.md` exists with the locked stub-with-pointer content from CONTEXT D-04 (3-line body delegating to ARCH-000_INDEX.md `#功能模块技术文档` section)."
    - "`docs/arch/01-core-architecture/ARCH-000_INDEX.md` references all UI specs (UI-001) and BASIC files (BASIC-001..004) that exist on disk; no orphan files in `01-core-architecture/`, `02-module-specs/`, or `03-adr/` (excluding INDEX itself)."
    - "`docs/arch/README.md` is synced to the actual directory listing: no `arch2/` references, no phantom `MOD-009_Internationalization.md`, no phantom `ARCH-009_I18N_Update_Summary.md`; MOD-009 description corrected to '语音记账'; `04-basic/BASIC-001..004` subsection added."
    - "lib/-clean invariant: this plan's commits modify ONLY paths under `docs/arch/` and `scripts/verify_index_health.sh`."
  artifacts:
    - path: "scripts/verify_index_health.sh"
      provides: "INDEX health check script (broken-link + orphan-file loops)"
      min_lines: 30
    - path: "docs/arch/02-module-specs/MOD-000_INDEX.md"
      provides: "MOD INDEX stub-with-pointer (D-04)"
      contains: "ARCH-000_INDEX.md"
    - path: "docs/arch/README.md"
      provides: "Directory README synced to actual file list"
  key_links:
    - from: "docs/arch/02-module-specs/MOD-000_INDEX.md"
      to: "docs/arch/01-core-architecture/ARCH-000_INDEX.md"
      via: "stub-with-pointer markdown link"
      pattern: "\\.\\./01-core-architecture/ARCH-000_INDEX\\.md"
    - from: "scripts/verify_index_health.sh"
      to: "docs/arch/01-core-architecture/, docs/arch/02-module-specs/, docs/arch/03-adr/"
      via: "shell loop checking links + orphans"
      pattern: "check_dir docs/arch"

---

<objective>
Plan 07-04 covers DOCS-03 (verify INDEX files reference only existing files) and the README portion of DOCS-01 (D6 — `docs/arch/README.md` sync). Begins with a Wave 0 task creating `scripts/verify_index_health.sh` (the second mandatory verification script — paired with `verify-doc-sweep.sh` from Plan 07-01).

This plan runs in Wave B because it must run AFTER Plans 07-01..03 land their drift fixes; INDEX entries reference paths that may have been corrected in those plans, and orphan checks require the post-Wave-A file set.

Purpose: Make INDEX health a one-command verification (`bash scripts/verify_index_health.sh` → exit 0) and create the missing `MOD-000_INDEX.md` per D-04 (strict reading of DOCS-03 requires all three INDEXes to exist).

Output: 1 new shell script + 1 new MOD-000 stub + 2 modified existing files (ARCH-000_INDEX.md adds UI-001 entry if missing; README.md is rewritten to match actual file listing).
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
@.planning/phases/07-documentation-sweep/07-VALIDATION.md
@.planning/phases/07-documentation-sweep/07-01-SUMMARY.md
@.planning/phases/07-documentation-sweep/07-02-SUMMARY.md
@.planning/phases/07-documentation-sweep/07-03-SUMMARY.md

<index_health_facts>
<!-- Per 07-RESEARCH.md INDEX.md Health Audit and 07-PATTERNS.md -->

ARCH-000_INDEX.md current state:
- Files in `docs/arch/01-core-architecture/`: 9 (ARCH-000 + ARCH-001..008)
- All 9 are listed (no broken links, no orphans)
- BASIC-001..004 are listed at lines ~42-49 (already correct)
- POSSIBLE GAP: UI-001_Page_Inventory.md from `docs/arch/05-UI/` is not yet referenced (per RESEARCH §INDEX-Health-A E)
- `~~MOD-005 安全隐私~~ 文件不存在` strikethrough at line ~36 — leave as-is (deprecated entry pattern)

ADR-000_INDEX.md current state:
- All 10 ADR entries (ADR-001..010) link to existing files; no orphans, no broken links
- ADR-011 entry will be added by Plan 07-05 (NOT this plan)

MOD-000_INDEX.md:
- DOES NOT EXIST in main
- D-04 locks: stub-with-pointer (3-line body delegating to ARCH-000)

docs/arch/README.md current state:
- Line ~1: title says `(arch2)` (legacy); should be `(docs/arch/)`
- Line ~11: body says `arch2/` repeatedly
- Line ~36: phantom `MOD-009_Internationalization.md` (real file is `MOD-009_VoiceInput.md`)
- Line ~26: phantom `ARCH-009_I18N_Update_Summary.md` (only 8 ARCH files exist)
- Line ~82: phantom `MOD-009 - 国际化多语言` description (real MOD-009 is voice input)
- Missing: BASIC-001..004 subsection
</index_health_facts>
</context>

<tasks>

<task type="auto">
  <id>07-04-W0-01</id>
  <wave>0</wave>
  <name>Task 0: Create scripts/verify_index_health.sh and confirm it currently FAILS</name>
  <files>scripts/verify_index_health.sh</files>
  <read_first>
    - .planning/phases/07-documentation-sweep/07-RESEARCH.md (lines 575-615 — verbatim script body)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 603-661 — pattern principles)
    - scripts/audit_layer.sh (analog: shebang + simple wrapper structure)
    - scripts/build_coverage_baseline.sh (analog: set -euo pipefail + multi-step structure)
    - docs/arch/01-core-architecture/ARCH-000_INDEX.md (current INDEX state)
    - docs/arch/03-adr/ADR-000_INDEX.md (current INDEX state)
  </read_first>
  <action>
    Create `scripts/verify_index_health.sh` with the EXACT body specified in 07-RESEARCH.md §"Code Examples" lines 575-615 (also reproduced verbatim in 07-PATTERNS.md lines 609-647).

    Required structure:
    1. Shebang `#!/usr/bin/env bash`.
    2. Header comment block: file path, purpose ("Confirms every link in INDEX files points to a real file, and every file in the directory is mentioned in INDEX.").
    3. `set -euo pipefail` immediately after header.
    4. `fail=0` accumulator.
    5. `check_dir()` function that takes `(dir, index)` arguments and runs:
       - (A) Broken-link check: for every `(./...md)` link in INDEX, verify the file exists; print `BROKEN LINK in $index: $path` and set `fail=1` on miss.
       - (B) Orphan-file check: for every `*.md` in the directory, verify it's mentioned by basename in INDEX; print `ORPHAN: $base not listed in $index` and set `fail=1` on miss.
       - Skip the INDEX file itself in the orphan loop.
    6. Driver section calling `check_dir` for:
       - `docs/arch/01-core-architecture` against `ARCH-000_INDEX.md`
       - `docs/arch/03-adr` against `ADR-000_INDEX.md`
       - `docs/arch/05-UI` against `../01-core-architecture/ARCH-000_INDEX.md` (cross-section: ARCH-000 doubles as the master index for UI specs per CONTEXT D-04 rationale; UI-001 must appear in ARCH-000's UI subsection)
       - `docs/arch/02-module-specs` against `MOD-000_INDEX.md` ONLY IF the latter exists (use `[ -f docs/arch/02-module-specs/MOD-000_INDEX.md ] && check_dir ...`)
    7. `exit $fail` at the end.

    **Note on W-01 fix:** The 05-UI driver call is required so that on `main` (where UI-001 is NOT listed in ARCH-000) the script exits non-zero, satisfying the W0 "must currently fail" contract. Plan 07-04 Task 1 sub-task B then adds the UI-001 entry, which makes this gate pass.

    Then `chmod +x scripts/verify_index_health.sh` and run it once. Per the current state in `<index_health_facts>` it must print at least one `ORPHAN: UI-001_Page_Inventory.md not listed in ../01-core-architecture/ARCH-000_INDEX.md` warning. Confirm exit non-zero — failure is the contract.
  </action>
  <verify>
    <automated>test -x scripts/verify_index_health.sh && grep -q "check_dir docs/arch/01-core-architecture" scripts/verify_index_health.sh && grep -q "check_dir docs/arch/03-adr" scripts/verify_index_health.sh && bash scripts/verify_index_health.sh; [ $? -ne 0 ] || echo "Script exists and currently fails as expected"</automated>
  </verify>
  <acceptance_criteria>
    - `test -x scripts/verify_index_health.sh` exits 0
    - `head -1 scripts/verify_index_health.sh` outputs `#!/usr/bin/env bash`
    - `grep -c '^set -euo pipefail$' scripts/verify_index_health.sh` returns `1`
    - `grep -q '^check_dir() {' scripts/verify_index_health.sh` exits 0 (function defined)
    - `grep -q "BROKEN LINK" scripts/verify_index_health.sh` exits 0 (broken-link check present)
    - `grep -q "ORPHAN:" scripts/verify_index_health.sh` exits 0 (orphan check present)
    - `grep -q "check_dir docs/arch/01-core-architecture" scripts/verify_index_health.sh` exits 0
    - `grep -q "check_dir docs/arch/03-adr" scripts/verify_index_health.sh` exits 0
    - `grep -q "check_dir docs/arch/05-UI" scripts/verify_index_health.sh` exits 0 (W-01 fix: cross-section UI driver present)
    - `grep -q "MOD-000_INDEX\.md" scripts/verify_index_health.sh` exits 0 (conditional MOD INDEX check present)
    - `bash scripts/verify_index_health.sh 2>&1 | grep -q "ORPHAN: UI-001_Page_Inventory.md"` exits 0 (script reports the expected drift item on main)
    - `bash scripts/verify_index_health.sh; [ $? -ne 0 ]` succeeds (script currently FAILS — contract)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean; `scripts/` is allowed per CONTEXT lib/-clean invariant)
  </acceptance_criteria>
  <files_modified>scripts/verify_index_health.sh</files_modified>
  <done>verify_index_health.sh exists, is executable, has check_dir function and 3 driver calls, and currently exits non-zero (some INDEX issues remain).</done>
</task>

<task type="auto">
  <id>07-04-01</id>
  <wave>1</wave>
  <name>Task 1: Create MOD-000_INDEX.md stub + add UI-001 entry to ARCH-000_INDEX.md (D-04, INDEX-Health-A E)</name>
  <files>docs/arch/02-module-specs/MOD-000_INDEX.md, docs/arch/01-core-architecture/ARCH-000_INDEX.md</files>
  <read_first>
    - docs/arch/01-core-architecture/ARCH-000_INDEX.md (full file — find the section that lists MOD entries; look for any existing UI section OR find the right place to add one)
    - docs/arch/05-UI/UI-001_Page_Inventory.md (verify file exists)
    - .planning/phases/07-documentation-sweep/07-CONTEXT.md (D-04 — exact MOD-000 stub content)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 466-489 — locked MOD-000 verbatim content; lines 357-395 — INDEX entry pattern)
  </read_first>
  <action>
    **Sub-task A: Create `docs/arch/02-module-specs/MOD-000_INDEX.md`** with EXACTLY the content locked by D-04 in CONTEXT.md (also reproduced verbatim in 07-PATTERNS.md lines 472-477):

    ```markdown
    # MOD Index

    This directory's master index lives in [ARCH-000_INDEX.md](../01-core-architecture/ARCH-000_INDEX.md) — see the "功能模块技术文档" section.
    ```

    Do NOT duplicate the ARCH-000 module table. The stub is intentional per D-04 rationale ("Full duplication of ARCH-000 content creates two-source-of-truth drift").

    **Sub-task B: Add UI-001 entry to `ARCH-000_INDEX.md`**

    Read `docs/arch/01-core-architecture/ARCH-000_INDEX.md`. Identify if there is already a "UI Specs" or `05-UI` subsection. If NOT, add one immediately after the BASIC-001..004 subsection (typically around line 49 per 07-PATTERNS.md ARCH-000 lines 42-49 reference). Mirror the exact table format used by the BASIC subsection:

    ```markdown
    ## UI 规范文档

    | 编号 | 文档 | 描述 | 状态 |
    |------|------|------|------|
    | UI-001 页面清单 | [UI-001_Page_Inventory.md](../05-UI/UI-001_Page_Inventory.md) | 全部页面分类、数量、优先级清单 | ✅ 已有 |
    ```

    If a UI section already exists and UI-001 is referenced, do NOT add a duplicate row — leave as-is.

    Verify both sub-tasks:
    ```bash
    test -f docs/arch/02-module-specs/MOD-000_INDEX.md
    grep -q "ARCH-000_INDEX.md" docs/arch/02-module-specs/MOD-000_INDEX.md
    grep -q "UI-001_Page_Inventory\.md" docs/arch/01-core-architecture/ARCH-000_INDEX.md
    ```
  </action>
  <verify>
    <automated>test -f docs/arch/02-module-specs/MOD-000_INDEX.md && grep -q '\.\./01-core-architecture/ARCH-000_INDEX\.md' docs/arch/02-module-specs/MOD-000_INDEX.md && grep -q 'UI-001_Page_Inventory\.md' docs/arch/01-core-architecture/ARCH-000_INDEX.md</automated>
  </verify>
  <acceptance_criteria>
    - `test -f docs/arch/02-module-specs/MOD-000_INDEX.md` exits 0 (D-04 satisfied — file exists)
    - `wc -l docs/arch/02-module-specs/MOD-000_INDEX.md` returns at least `3` and at most `15` (it's a stub, not a full duplicate of ARCH-000)
    - `grep -q '^# MOD Index$' docs/arch/02-module-specs/MOD-000_INDEX.md` exits 0 (heading matches D-04 locked content)
    - `grep -q '\.\./01-core-architecture/ARCH-000_INDEX\.md' docs/arch/02-module-specs/MOD-000_INDEX.md` exits 0 (pointer link present)
    - `grep -q '功能模块技术文档' docs/arch/02-module-specs/MOD-000_INDEX.md` exits 0 (locked content "see the section X" present)
    - `grep -q 'UI-001_Page_Inventory\.md' docs/arch/01-core-architecture/ARCH-000_INDEX.md` exits 0 (UI-001 entry added — closes RESEARCH §INDEX-Health-A E)
    - `grep -q '\.\./05-UI/UI-001_Page_Inventory\.md' docs/arch/01-core-architecture/ARCH-000_INDEX.md` exits 0 (link uses correct relative path)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>docs/arch/02-module-specs/MOD-000_INDEX.md, docs/arch/01-core-architecture/ARCH-000_INDEX.md</files_modified>
  <done>MOD-000 INDEX stub created with the locked D-04 content; ARCH-000 INDEX includes a UI-001 entry under a UI section.</done>
</task>

<task type="auto">
  <id>07-04-02</id>
  <wave>1</wave>
  <name>Task 2: Sync docs/arch/README.md to actual directory listing (D6)</name>
  <files>docs/arch/README.md</files>
  <read_first>
    - docs/arch/README.md (full file — drift sites at lines 1, 11, 26, 36, 82 per 07-RESEARCH.md and 07-PATTERNS.md lines 493-521)
    - Output of `ls docs/arch/01-core-architecture/`, `ls docs/arch/02-module-specs/`, `ls docs/arch/03-adr/`, `ls docs/arch/04-basic/`, `ls docs/arch/05-UI/` — the README must match these listings
    - .planning/phases/07-documentation-sweep/07-RESEARCH.md (lines 264-271 — D6 inventory)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 493-521 — exact bug list + replacement guidance)
  </read_first>
  <action>
    Apply the following targeted edits to `docs/arch/README.md`:

    **Bug 1 — `arch2/` → `docs/arch/`:**
    - Line ~1: title `# Home Pocket MVP - 架构技术文档 (arch2)` → `# Home Pocket MVP - 架构技术文档 (docs/arch/)`
    - Line ~11: any body sentence containing `arch2/` → `docs/arch/`
    - Any other `arch2/` reference → `docs/arch/`

    **Bug 2 — Phantom `ARCH-009_I18N_Update_Summary.md`:**
    - Line ~26: DELETE the line referencing `ARCH-009_I18N_Update_Summary.md` (file does not exist; only ARCH-001..008 do).

    **Bug 3 — Phantom `MOD-009_Internationalization.md`:**
    - Line ~36: replace `MOD-009_Internationalization.md` with `MOD-009_VoiceInput.md` (the real filename).

    **Bug 4 — Wrong MOD-009 description:**
    - Line ~82: `MOD-009 - 国际化多语言` → `MOD-009 - 语音记账`.

    **Bug 5 — Missing BASIC subsection:**
    - Add a new subsection after the existing MOD list, listing the 4 BASIC files that exist on disk. Use the same table or list format as the existing MOD subsection. Confirm filenames via `ls docs/arch/04-basic/` (expected: BASIC-001_Crypto_Infrastructure.md, BASIC-002_*.md, BASIC-003_I18N_Infrastructure.md, BASIC-004_*.md — verify exact names before writing).

    **Synthesis:** After all 5 edits, ensure every `[XXX-NNN_*.md]` reference in README.md points to a file that exists in the directory it claims to. Run:
    ```bash
    for f in $(grep -oE '[A-Z]+-[0-9]+(_[A-Z][A-Za-z_0-9]+)?\.md' docs/arch/README.md | sort -u); do
      find docs/arch -name "$f" -type f | grep -q . || echo "MISSING: $f"
    done
    ```
    Expected output: empty (no MISSING lines).
  </action>
  <verify>
    <automated>! grep -nE 'arch2/|MOD-009_Internationalization|ARCH-009_I18N_Update_Summary|国际化多语言' docs/arch/README.md && grep -q "MOD-009_VoiceInput\.md" docs/arch/README.md && grep -q "BASIC-001\|BASIC-003" docs/arch/README.md</automated>
  </verify>
  <acceptance_criteria>
    - `! grep -n 'arch2/' docs/arch/README.md` exits 0 (Bug 1 closed)
    - `! grep -n 'MOD-009_Internationalization' docs/arch/README.md` exits 0 (Bug 3 closed)
    - `! grep -n 'ARCH-009_I18N_Update_Summary' docs/arch/README.md` exits 0 (Bug 2 closed)
    - `! grep -n '国际化多语言' docs/arch/README.md` exits 0 (Bug 4 closed)
    - `grep -q 'MOD-009_VoiceInput\.md' docs/arch/README.md` exits 0 (real MOD-009 filename now referenced)
    - `grep -q 'MOD-009 - 语音记账' docs/arch/README.md` exits 0 (correct description)
    - `grep -q 'BASIC-001\|BASIC-003' docs/arch/README.md` exits 0 (Bug 5 closed — BASIC subsection exists)
    - The reference-existence loop (in <action>) prints zero `MISSING:` lines: `for f in $(grep -oE '[A-Z]+-[0-9]+(_[A-Z][A-Za-z_0-9]+)?\.md' docs/arch/README.md | sort -u); do find docs/arch -name "$f" -type f | grep -q . || echo "MISSING: $f"; done | grep -c '^MISSING' | grep -q '^0$'` succeeds
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>docs/arch/README.md</files_modified>
  <done>README.md is free of `arch2/`, phantom files, and wrong descriptions; every referenced filename exists in `docs/arch/`; BASIC-001..004 subsection added.</done>
</task>

<task type="auto">
  <id>07-04-03</id>
  <wave>2</wave>
  <name>Task 3: Run scripts/verify_index_health.sh — must exit 0 (DOCS-03 close gate)</name>
  <files></files>
  <read_first>
    - scripts/verify_index_health.sh (created in Wave 0)
    - docs/arch/01-core-architecture/ARCH-000_INDEX.md (post-Task-1 state)
    - docs/arch/02-module-specs/MOD-000_INDEX.md (post-Task-1 state)
    - docs/arch/03-adr/ADR-000_INDEX.md (current state — Plan 07-05 will add ADR-011 entry; for THIS plan, ADR-011 file does not yet exist, so the script must NOT yet check ADR-011 — it doesn't, because the orphan loop only checks files in the directory)
  </read_first>
  <action>
    Run `bash scripts/verify_index_health.sh`. Per the post-Tasks-1+2 state, the script SHOULD now exit 0 because:
    - ARCH-000 has all 8 ARCH files + UI-001 + BASIC-001..004 = no orphans, no broken links.
    - MOD-000 INDEX exists; orphan loop runs against MOD-001..009 (per `ls docs/arch/02-module-specs/`); the stub mentions only ARCH-000 cross-reference, so MOD-001..009 will be flagged as ORPHAN unless the stub explicitly delegates.

    **CRITICAL ADJUSTMENT:** The orphan check looks for the basename of each `*.md` file in the INDEX. Since MOD-000_INDEX.md is a stub-with-pointer that does NOT list the MOD-* files (by D-04 design), the orphan check would flag every MOD-* file as ORPHAN. To resolve this CORRECTLY without violating D-04 (no duplication), the orphan check on MOD-000 should be SKIPPED or the script must accept a "see ARCH-000" delegation.

    **The accepted resolution** (per 07-PATTERNS.md line 645 conditional `[ -f ... ] && check_dir ...`):
    - Option A: The script's existing conditional `[ -f docs/arch/02-module-specs/MOD-000_INDEX.md ] && check_dir docs/arch/02-module-specs ...` will now run check_dir against MOD-000, finding orphans. To avoid this, EITHER:
      - (A1) Skip MOD-000 orphan check by checking an "exempt" marker in the INDEX (e.g., presence of "master index lives in" sentence skips orphan loop). Adjust `scripts/verify_index_health.sh` to check this.
      - (A2) Change driver to NOT call `check_dir` for MOD-000 (revert to checking only ARCH-000 + ADR-000).

    **Recommended:** Apply A2 — modify the script's MOD-000 driver line to be commented out or removed (the stub's `## D-04 lock` purpose is satisfied by file existence; orphan check is not needed since ARCH-000 is the master). Update the script in this task with:
    ```bash
    # MOD-000 is a stub-with-pointer per ADR-011 D-04 — not a full INDEX, so we skip
    # the orphan/link check here. The presence of MOD-000_INDEX.md is the DOCS-03 contract.
    test -f docs/arch/02-module-specs/MOD-000_INDEX.md || { echo "MOD-000_INDEX.md missing"; fail=1; }
    ```

    After adjustment, run `bash scripts/verify_index_health.sh` again — must exit 0.

    If the script still fails, identify the BROKEN LINK or ORPHAN message and either fix the underlying INDEX entry or fix the directory file listing — but do NOT silently widen the script's tolerances.
  </action>
  <verify>
    <automated>bash scripts/verify_index_health.sh</automated>
  </verify>
  <acceptance_criteria>
    - `bash scripts/verify_index_health.sh` exits 0 (the gate that DOCS-03 ultimately tracks)
    - `bash scripts/verify_index_health.sh 2>&1 | grep -cE 'BROKEN LINK|ORPHAN'` returns `0` (no warning lines printed)
    - `test -f docs/arch/02-module-specs/MOD-000_INDEX.md` exits 0 (D-04 file presence preserved through this task)
    - The script's adjusted MOD-000 handling does NOT call `check_dir` against MOD-000 (verified: `grep -A1 'MOD-000_INDEX' scripts/verify_index_health.sh | grep -q "check_dir docs/arch/02-module-specs"` should return 1 — i.e., NOT calling check_dir on MOD dir)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>scripts/verify_index_health.sh</files_modified>
  <done>scripts/verify_index_health.sh now exits 0; the script has been adjusted to handle MOD-000 stub correctly (file-presence check only, no orphan loop).</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| README reader → Directory contents | A new contributor reads `docs/arch/README.md` first; phantom files send them to dead links. |
| INDEX → Files | INDEX is the contract; dangling links indicate documentation rot. |
| MOD-000 stub → ARCH-000 master | Cross-doc delegation pattern; D-04 explicitly chose stub-with-pointer over duplication. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-04-01 | Information Disclosure | README.md lists files that don't exist; contributors waste time | mitigate | Task 07-04-02 acceptance includes the per-filename `find` loop returning zero MISSING lines. |
| T-07-04-02 | Tampering | INDEX modified to "fix" a broken link by renaming a real file | mitigate | The orphan/link check only flags issues; remediation is via the plan's explicit edits, not via in-script auto-rename. The script is read-only. |
| T-07-04-03 | Repudiation | MOD-000 INDEX stub creates impression of a real index when it's just a pointer | accept | D-04 rationale documents the trade-off; the stub explicitly delegates with the phrase "master index lives in...". |
| T-07-04-04 | Tampering | scripts/ directory mutation breaks audit pipeline | mitigate | The new script is in `scripts/` but does NOT modify any audit invariant; it's a one-off verifier. The lib/-clean rule's allowed paths include `scripts/` per CONTEXT D-08 hint (verification scripts allowed). |
</threat_model>

<verification>
- All 3 task acceptance criteria pass.
- After this plan completes:
  - `bash scripts/verify_index_health.sh` exits 0 (DOCS-03 contract).
  - `docs/arch/02-module-specs/MOD-000_INDEX.md` exists with the locked stub content.
  - `docs/arch/README.md` lists only files that exist in the directory tree.
  - ARCH-000 INDEX includes UI-001 entry.
- `git diff --name-only main..HEAD docs/arch/ scripts/` shows ONLY the 4 expected files.
- `flutter analyze --no-fatal-infos` exits 0.
</verification>

<success_criteria>
- 1 new shell script + 1 new MOD-000 stub + 2 modified existing files.
- Pre/post `bash scripts/verify_index_health.sh` exit codes: pre = non-zero (Wave 0 contract), post = 0 (DOCS-03 close).
- README.md sync: zero phantom-file references; BASIC-001..004 subsection added.
- ARCH-000 INDEX includes UI-001.
- MOD-000_INDEX.md exists as a 3-line stub with pointer to ARCH-000.
- lib/-clean.
</success_criteria>

<output>
After completion, create `.planning/phases/07-documentation-sweep/07-04-SUMMARY.md` with:
- The 4 files modified (1 new script, 1 new stub, 2 edited)
- Pre/post `bash scripts/verify_index_health.sh` exit codes
- Confirmation that every filename referenced in README.md exists on disk (the find loop printed zero MISSING)
- Confirmation lib/-clean
</output>
