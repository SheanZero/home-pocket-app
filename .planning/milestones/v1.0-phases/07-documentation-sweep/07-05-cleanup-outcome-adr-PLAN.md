---
phase: 07-documentation-sweep
plan: 05
type: execute
wave: 3
depends_on: ["07-01-arch-mod-drift-PLAN.md", "07-02-adr-drift-PLAN.md", "07-03-claude-md-pitfall-annotation-PLAN.md", "07-04-index-health-PLAN.md"]
files_modified:
  - docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md
  - docs/arch/03-adr/ADR-000_INDEX.md
autonomous: true
requirements: [DOCS-01, DOCS-02, DOCS-03, DOCS-04]

must_haves:
  truths:
    - "`docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exists and follows the ADR-010 template (frontmatter + 8 required sections per `.claude/rules/arch.md`:109-117)."
    - "ADR-011 contains all 4 required content sections per CONTEXT D-05 + planning context: §Cleanup Outcome (issues.json delta + Phase 3-6 summary), §`*.mocks.dart` Strategy (mocktail big-bang with Phase 4-04 citation), §Ongoing CI Enforcement (8 CI gates with audit.yml line citations), §Out of Scope / Deferred (MOD numbering D-02 + ADR-008/009/010 implementation status + markdown-link-check Phase 8 deferral)."
    - "ADR-011 cites the 8 CI gates with verified line numbers into `.github/workflows/audit.yml`: AUDIT-09 (`audit.yml:64-69`), AUDIT-10 (`audit.yml:81-89`), flutter analyze (`audit.yml:34`), dart run custom_lint (`audit.yml:36`), very_good_coverage (line citation), flutter test test/architecture/, coverde filter, schema-version migration tests."
    - "`docs/arch/03-adr/ADR-000_INDEX.md` has a new entry for ADR-011 mirroring the locked entry style from 07-PATTERNS.md lines 432-456."
    - "Final phase gate: `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (all 6 gates pass)."
    - "lib/-clean invariant FOR THE ENTIRE PHASE: `git diff --name-only main..HEAD | grep -cE '^(lib/|test/|pubspec|\\.github/|analysis_options)'` returns 0."
  artifacts:
    - path: "docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
      provides: "Cleanup-initiative outcome ADR with mocktail decision + CI enforcement registry"
      min_lines: 100
      contains: "Cleanup Outcome"
    - path: "docs/arch/03-adr/ADR-000_INDEX.md"
      provides: "ADR INDEX updated with ADR-011 entry"
      contains: "ADR-011"
  key_links:
    - from: "docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
      to: ".github/workflows/audit.yml"
      via: "8 CI gate line citations"
      pattern: "audit\\.yml:[0-9]+"
    - from: "docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
      to: "docs/arch/03-adr/ADR-002_Database_Solution.md, ADR-007, ADR-008, ADR-010"
      via: "frontmatter 相关 ADR field"
      pattern: "相关 ADR:"
    - from: "docs/arch/03-adr/ADR-000_INDEX.md"
      to: "docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
      via: "INDEX entry markdown link"
      pattern: "\\./ADR-011_Codebase_Cleanup_Initiative_Outcome\\.md"

---

<objective>
Plan 07-05 closes Phase 7 by creating ADR-011 (DOCS-04) and adding it to ADR-000 INDEX. ADR-011 documents three durable decisions from the cleanup initiative: (1) the mocktail big-bang `*.mocks.dart` strategy chosen in Phase 4-04, (2) the 8 ongoing CI gates that survive into Phase 8, and (3) the cleanup outcome (issues.json severity counts, file moves, CategoryService rename, ResolveLedgerTypeService deletion). It also runs the final phase gate: `verify-doc-sweep.sh` must exit 0 with all 6 gates passing AND the lib/-clean invariant must hold across all 5 plans' commits.

This plan runs in Wave 3 because it depends on Plans 07-01..04 (ADR-011 references the post-cleanup state landed by all earlier plans + the INDEX health gate must already be passing).

Purpose: Future contributors land on `docs/arch/03-adr/ADR-011_*.md` and understand (a) what the cleanup did, (b) what CI now permanently enforces, (c) what remains backlog. Phase 7's success criterion (`verify-doc-sweep.sh` exits 0) is mechanically demonstrated.

Output: 1 new ADR file + 1 INDEX update.
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
@.planning/phases/07-documentation-sweep/07-01-SUMMARY.md
@.planning/phases/07-documentation-sweep/07-02-SUMMARY.md
@.planning/phases/07-documentation-sweep/07-03-SUMMARY.md
@.planning/phases/07-documentation-sweep/07-04-SUMMARY.md
@.claude/rules/arch.md

<adr_011_skeleton>
<!-- Locked content map per CONTEXT D-05 + planner instructions in <adr_011_required_content> -->
<!-- Mirror ADR-010 template per 07-PATTERNS.md lines 49-122 -->

# ADR-011: Codebase Cleanup Initiative Outcome

**文档编号:** ADR-011
**文档版本:** 1.0
**创建日期:** 2026-04-27
**状态:** ✅ 已接受
**决策者:** Claude Sonnet 4.x + 项目维护者
**影响范围:** 全局重构（Phases 3–6）, CI 守门, 测试基础设施
**相关 ADR:** ADR-002 (Database Solution), ADR-007 (Layer Responsibilities), ADR-008/009/010 (实施推迟)

---

## 📋 状态

**当前状态:** ✅ 已接受
**决策日期:** 2026-04-27
**实施状态:** 已完成 (Phases 3–6 已落地)

---

## 🎯 背景 (Context)

(Why now? Phases 3-6 closed CRITICAL/HIGH/MEDIUM/LOW findings; this ADR captures the durable decisions that survive into Phase 8 and beyond.)

## 🔍 考虑的方案 (Considered Options)

(Severity-ordered phase plan; characterization-tests-first; exit-gated phases. Alternatives: collapse phases / per-phase doc updates / no centralized ADR — all rejected.)

## ✅ 决策 (Decision)

### A. `*.mocks.dart` Strategy

(Chose mocktail big-bang over incremental migration. Cite Phase 4-04 plan + STATE.md decision.)

### B. Ongoing CI Enforcement

| Gate | File:Line | Purpose |
|------|-----------|---------|
| AUDIT-09 SQLCipher | `.github/workflows/audit.yml:64-69` | Rejects sqlite3_flutter_libs in pubspec.lock |
| AUDIT-10 build_runner | `.github/workflows/audit.yml:81-89` | Blocks PRs with stale generated files |
| flutter analyze | `.github/workflows/audit.yml:34` | Type + lint check |
| dart run custom_lint | `.github/workflows/audit.yml:36` | import_guard + riverpod_lint |
| very_good_coverage | `.github/workflows/audit.yml:{LINE}` | Global ≥80% on lcov_clean.info |
| flutter test test/architecture/ | (CI step) | domain_import_rules + provider_graph_hygiene |
| coverde filter | (CI step) | Strips generated from lcov.info |
| schema-version migration | (CI step OR test/) | v(N-1)→vN PRAGMA index_list |

### C. Cleanup Outcome

(Phase 3 closed N CRITICAL, Phase 4 closed N HIGH, Phase 5 closed 8 MEDIUM, Phase 6 closed 7 LOW. Reference `.planning/audit/issues.json` delta.)

## 🤔 决策理由 (Rationale)

(Why mocktail over mockito/CI-generated; why centralize CI gates in one ADR; why audit-driven over feature-driven cleanup.)

## 🔄 后果 (Consequences)

**Positive:** CI enforces what was previously manual; future regressions caught at PR time.
**Negative:** Some pitfalls remain manually-checked (Pitfalls 4, 7, 9, 11 per CLAUDE.md annotations).
**Neutral:** ADR count grows by 1; INDEX maintenance burden +1 entry.

## 📋 实施计划 (Implementation Plan)

Already complete; pointer to Phase 3-6 phase directories under `.planning/phases/`.

## 📝 Out of Scope / Deferred

- MOD numbering drift (D-02 in CONTEXT.md) — lifted to FUTURE-DOC backlog.
- ADR-008/009/010 implementation status — accepted but NOT implemented as part of cleanup.
- markdown-link-check CI gate — deferred to Phase 8 (re-audit) / FUTURE-TOOL.
- recoverFromSeed() key-overwrite bug — FUTURE-ARCH-04.
- DCM upgrade — FUTURE-ARCH-03.
- riverpod_lint 3.x — FUTURE-TOOL-01.
- ARB-driven CategoryLocaleService — FUTURE-ARCH-01.
- Drift unused-column detection — FUTURE-TOOL-02.

</adr_011_skeleton>

<adr_011_index_entry>
<!-- Locked entry style per 07-PATTERNS.md lines 432-456 -->

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
</adr_011_index_entry>
</context>

<tasks>

<task type="auto">
  <id>07-05-01</id>
  <wave>1</wave>
  <name>Task 1: Create ADR-011_Codebase_Cleanup_Initiative_Outcome.md (DOCS-04)</name>
  <files>docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md (template — frontmatter + section heading style)
    - .claude/rules/arch.md (lines 109-117 — required ADR sections; lines 60-72 — frontmatter format)
    - .github/workflows/audit.yml (FULL READ — verify cited line numbers: 34, 36, 64-69, 81-89; find very_good_coverage line; find coverde line; find schema-version migration step)
    - .planning/audit/issues.json (read severity counts for the §Cleanup Outcome table — pre-cleanup vs post-cleanup deltas)
    - .planning/STATE.md (decisions ledger — quote Phase 4-04 mocktail decision)
    - .planning/phases/07-documentation-sweep/07-CONTEXT.md (D-05 — locked title + required subsections)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 49-122 — ADR-010 template + bilingual heading convention + CI gate citation pattern)
    - .planning/phases/07-documentation-sweep/07-RESEARCH.md (lines 388-440 — DOCS-04 scope + cross-references)
    - pubspec.yaml (verify mocktail version — Section A cites this)
  </read_first>
  <action>
    Create the file `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` following the locked skeleton in `<adr_011_skeleton>` above.

    **Frontmatter (mirror ADR-010 lines 1-19 exactly, swap fields per `<adr_011_skeleton>`):** include 文档编号, 文档版本, 创建日期 (2026-04-27), 状态 (✅ 已接受), 决策者, 影响范围, 相关 ADR.

    **Required 8 sections per `.claude/rules/arch.md`:109-117:**
    1. 标题和编号 — already in frontmatter.
    2. 状态 — `## 📋 状态` block with 当前状态 / 决策日期 / 实施状态.
    3. 背景 (Context) — `## 🎯 背景 (Context)` — explain why ADR-011 is filed now (Phases 3-6 just closed; need durable record of what survives).
    4. 考虑的方案 (Considered Options) — `## 🔍 考虑的方案 (Considered Options)` — outline the cleanup approach and rejected alternatives.
    5. 决策 (Decision) — `## ✅ 决策 (Decision)` — THREE sub-sections, exactly per CONTEXT D-05:
       - **A. `*.mocks.dart` Strategy** — chose mocktail big-bang; cite Phase 4-04 (path: `.planning/phases/04-high-fixes/04-04-mocktail-bigbang-migration-PLAN.md` per ROADMAP), pubspec.yaml mocktail version, STATE.md decision line ("*.mocks.dart strategy must be decided before Phase 4 — SUMMARY.md recommends Mocktail").
       - **B. Ongoing CI Enforcement** — table of 8 gates with line citations (use the table from `<adr_011_skeleton>`; replace `{LINE}` placeholders with actual line numbers verified by reading `.github/workflows/audit.yml` first).
       - **C. Cleanup Outcome** — link to `.planning/audit/issues.json`; per-phase summary table:
         | Phase | Severity | Findings closed |
         |-------|----------|------------------|
         | Phase 3 | CRITICAL | (count from issues.json) |
         | Phase 4 | HIGH | (count) |
         | Phase 5 | MEDIUM | 8 (per ROADMAP MED-01..MED-08) |
         | Phase 6 | LOW | 7 (per ROADMAP LOW-01..LOW-07) |
    6. 决策理由 (Rationale) — `## 🤔 决策理由 (Rationale)` — why these choices over alternatives. Mocktail over mockito (less generated noise, easier reading); centralize CI in one ADR (single point of reference for future audits); audit-driven over feature-driven (zero behavior change goal demanded discovery-only audit).
    7. 后果 (Consequences) — `## 🔄 后果 (Consequences)` — Positive / Negative / Neutral subsections per `<adr_011_skeleton>`.
    8. 实施计划 (Implementation Plan) — `## 📋 实施计划 (Implementation Plan)` — already complete; pointer to `.planning/phases/03-critical-fixes/`, `04-high-fixes/`, `05-medium-fixes/`, `06-low-fixes/` directories.

    **PLUS** an explicit `## 📝 Out of Scope / Deferred` section listing:
    - MOD numbering drift (D-02 in CONTEXT.md) lifted to FUTURE-DOC backlog
    - ADR-008/009/010 implementation status (accepted but NOT implemented in cleanup)
    - markdown-link-check CI gate (deferred to Phase 8 / FUTURE-TOOL)
    - recoverFromSeed() key-overwrite bug (FUTURE-ARCH-04)
    - DCM upgrade (FUTURE-ARCH-03)
    - riverpod_lint 3.x (FUTURE-TOOL-01)
    - ARB-driven CategoryLocaleService (FUTURE-ARCH-01)
    - Drift unused-column detection (FUTURE-TOOL-02)

    **Section ordering, bilingual heading style** (per 07-PATTERNS.md lines 73-97 + ADR-010): Top-level Chinese headings with optional emoji + English-in-parens. English code identifiers in fenced blocks. Cross-references use relative paths.

    **CI gate verification protocol:** BEFORE writing the Section B table, READ `.github/workflows/audit.yml` and locate the actual line numbers for: `flutter analyze`, `dart run custom_lint`, `very_good_coverage`, `coverde`, schema-version migration test. If any cited line is wrong, the ADR misleads future contributors (per A6 in 07-RESEARCH.md). For any gate whose exact line cannot be verified, use the form `(approximate; see audit.yml § <step name>)` with a step-name reference rather than a hallucinated line number.

    File length target: 100-300 lines (substantial enough to be useful, not bloated).
  </action>
  <verify>
    <automated>test -f docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md && for s in "## 📋 状态" "## 🎯 背景" "## 🔍 考虑的方案" "## ✅ 决策" "## 🤔 决策理由" "## 🔄 后果" "## 📋 实施计划" "Out of Scope"; do grep -q "$s" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md || { echo "MISSING SECTION: $s"; exit 1; }; done && grep -q "mocktail" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md && grep -qE 'audit\.yml:[0-9]+' docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md && grep -q "AUDIT-09" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md && grep -q "AUDIT-10" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md</automated>
  </verify>
  <acceptance_criteria>
    - `test -f docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0
    - `head -1 docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` returns `# ADR-011: Codebase Cleanup Initiative Outcome`
    - `grep -q "^**文档编号:** ADR-011" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0 (frontmatter present)
    - `grep -q "^**创建日期:** 2026-04-27" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0
    - `grep -q "^**状态:** ✅ 已接受" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0
    - All 8 required sections present: `for s in "## 📋 状态" "## 🎯 背景" "## 🔍 考虑的方案" "## ✅ 决策" "## 🤔 决策理由" "## 🔄 后果" "## 📋 实施计划" "Out of Scope"; do grep -q "$s" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md || exit 1; done` exits 0
    - Three locked decision sub-sections present:
      - `grep -qE "(\\*\\.mocks\\.dart Strategy|mocks\\.dart 策略)" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0 (decision §A)
      - `grep -qE "(Ongoing CI Enforcement|CI 守门|CI 强制)" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0 (decision §B)
      - `grep -qE "(Cleanup Outcome|清理成果|清理结果)" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0 (decision §C)
    - `grep -q "mocktail" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0 (mocktail decision documented)
    - `grep -qE "audit\.yml:[0-9]+" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0 (at least one CI line citation present)
    - `grep -c "AUDIT-09\|AUDIT-10\|audit\.yml" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` returns at least `4` (multiple CI gate references)
    - `grep -q "FUTURE-DOC\|FUTURE-ARCH\|FUTURE-TOOL" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exits 0 (deferred items listed)
    - `wc -l docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md | awk '{print $1}'` returns a value between 100 and 400 (substantial but not bloated)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md</files_modified>
  <done>ADR-011 file exists with all 8 ADR-template sections + 3 locked decision sub-sections + Out of Scope list; CI gate citations point to verified audit.yml lines.</done>
</task>

<task type="auto">
  <id>07-05-02</id>
  <wave>2</wave>
  <name>Task 2: Add ADR-011 entry to ADR-000_INDEX.md</name>
  <files>docs/arch/03-adr/ADR-000_INDEX.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-000_INDEX.md (full file — find ADR-010 entry at the bottom; insertion point is immediately after ADR-010's `---` divider)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 432-456 — locked entry style)
  </read_first>
  <action>
    Append the locked ADR-011 entry from `<adr_011_index_entry>` (above in the context block) to the END of `docs/arch/03-adr/ADR-000_INDEX.md`. Insert AFTER the existing ADR-010 entry's terminating `---` divider.

    Use the EXACT format:

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

    Do NOT modify any earlier ADR-001..010 entries.
  </action>
  <verify>
    <automated>grep -q "\[ADR-011: Codebase Cleanup Initiative Outcome\]" docs/arch/03-adr/ADR-000_INDEX.md && grep -q "ADR-011_Codebase_Cleanup_Initiative_Outcome\.md" docs/arch/03-adr/ADR-000_INDEX.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "ADR-011" docs/arch/03-adr/ADR-000_INDEX.md` exits 0
    - `grep -q "ADR-011_Codebase_Cleanup_Initiative_Outcome\.md" docs/arch/03-adr/ADR-000_INDEX.md` exits 0 (link target uses locked filename)
    - `grep -q "Mocktail big-bang" docs/arch/03-adr/ADR-000_INDEX.md` exits 0 (key-reason text present per locked entry)
    - `grep -q "8 项 CI 守门" docs/arch/03-adr/ADR-000_INDEX.md` exits 0
    - The number of `### \[ADR-` headings in ADR-000_INDEX.md is now exactly 11 (was 10): `grep -c '^### \[ADR-' docs/arch/03-adr/ADR-000_INDEX.md` returns `11`
    - `git diff docs/arch/03-adr/ADR-000_INDEX.md | grep -cE '^-[^-]'` returns `0` (append-only — no existing entries removed)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>docs/arch/03-adr/ADR-000_INDEX.md</files_modified>
  <done>ADR-000_INDEX.md has the new ADR-011 entry; total entry count is 11; no existing entries modified.</done>
</task>

<task type="auto">
  <id>07-05-03</id>
  <wave>3</wave>
  <name>Task 3: Final phase gate — verify-doc-sweep.sh exits 0 + lib/-clean invariant holds across the entire phase</name>
  <files></files>
  <read_first>
    - .planning/phases/07-documentation-sweep/verify-doc-sweep.sh (created in Plan 07-01)
    - .planning/phases/07-documentation-sweep/07-VALIDATION.md (per-task verification map)
    - .planning/phases/07-documentation-sweep/07-01-SUMMARY.md, 07-02-SUMMARY.md, 07-03-SUMMARY.md, 07-04-SUMMARY.md (cumulative state)
  </read_first>
  <action>
    Run the final phase gates. This task does NOT modify any files — it is purely verification.

    **Gate 1: All 6 grep gates in `verify-doc-sweep.sh` pass.**
    ```bash
    bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
    # Expected: exit code 0; all six [N/6] lines print "OK"
    ```

    If any gate fails, identify the file with residual drift and either (a) escalate by modifying the responsible plan's SUMMARY (this means a regression slipped through earlier acceptance), or (b) commit a small follow-up edit to the offending file under THIS plan's `files_modified` (which would require updating `files_modified` frontmatter — only do this if the offending file is already in scope; otherwise treat as a checker-loop trigger).

    **Gate 2: lib/-clean invariant across the entire phase.**
    ```bash
    git diff --name-only main..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)' | grep -q '^0$'
    # Expected: exit code 0 — zero phase commits modified any forbidden path
    ```

    **Gate 3: INDEX health remains green.**
    ```bash
    bash scripts/verify_index_health.sh
    # Expected: exit code 0
    ```

    **Gate 4: Architecture tests + flutter analyze still green** (sanity backstop — pure-doc commits cannot affect them, but verify nothing was accidentally edited under lib/ across the entire phase).
    ```bash
    flutter analyze --no-fatal-infos
    flutter test test/architecture/
    # Expected: exit code 0 for both
    ```

    All four gates MUST pass simultaneously. Capture each command's output in `.planning/phases/07-documentation-sweep/07-05-SUMMARY.md`.

    If any gate fails, the phase is NOT complete — return to the relevant plan and re-check the residual drift.
  </action>
  <verify>
    <automated>bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh && bash scripts/verify_index_health.sh && [ "$(git diff --name-only main..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)')" = "0" ]</automated>
  </verify>
  <acceptance_criteria>
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (all 6 grep gates pass — Phase 7 success criterion)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh 2>&1 | grep -c '^  OK$'` returns at least `6` (each gate printed OK)
    - `bash scripts/verify_index_health.sh` exits 0 (DOCS-03 contract still holds)
    - `git diff --name-only main..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (D-08 lib/-clean invariant holds across ALL 5 plans' commits — this is the phase-level invariant, not just plan-level)
    - `flutter analyze --no-fatal-infos` exits 0 (sanity)
    - `flutter test test/architecture/` exits 0 (sanity)
    - The set of files modified by Phase 7 is contained in: `docs/`, `CLAUDE.md`, `.claude/rules/`, `.planning/phases/07-documentation-sweep/`, `scripts/verify_index_health.sh`. Verify with: `git diff --name-only main..HEAD | grep -vE '^(docs/|CLAUDE\.md|\.claude/rules/|\.planning/phases/07-documentation-sweep/|scripts/verify_index_health\.sh)' | wc -l` returns `0`
  </acceptance_criteria>
  <files_modified></files_modified>
  <done>Final phase gate passes: verify-doc-sweep.sh exits 0; verify_index_health.sh exits 0; lib/-clean invariant holds across the entire phase (every commit modified only allowed paths); flutter analyze + arch tests still green.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Future contributor reading ADR-011 → CI gate facts | Wrong line citations create false sense of CI coverage. |
| Phase 7 commits → main branch invariants | The lib/-clean invariant is the contract that lets doc work merge without re-opening the coverage-gate fight Phase 6 closed. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-05-01 | Information Disclosure (false security) | ADR-011 cites a CI gate that doesn't exist or is at a different line | mitigate | Task 07-05-01 mandates reading `.github/workflows/audit.yml` BEFORE writing the table; for unverifiable lines, use `(approximate; see audit.yml § <step name>)` rather than hallucinate. |
| T-07-05-02 | Tampering | ADR-011 silently rewrites Phase 4-04 mocktail decision narrative | mitigate | The "Decision §A `*.mocks.dart` Strategy" section MUST quote the STATE.md decision line verbatim and cite the Phase 4-04 plan path. Reviewer verifies citation against STATE.md in PR review. |
| T-07-05-03 | Tampering | A late-stage edit to fix `verify-doc-sweep.sh` failure introduces a code change | mitigate | Task 07-05-03 explicitly forbids modifying `lib/`/`test/`; if a gate failure can only be fixed by code edit, the phase fails (escalate to the responsible earlier plan rather than work around). |
| T-07-05-04 | Repudiation | Phase 7 lib/-clean invariant is checked only per-plan, missing cross-plan regressions | mitigate | Task 07-05-03 acceptance includes the **phase-level** `git diff --name-only main..HEAD` check, not just plan-level. |
</threat_model>

<verification>
- All 3 task acceptance criteria pass.
- The phase is "complete" iff all 4 gates in Task 07-05-03 are simultaneously green.
- Specifically:
  - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` → exit 0 with 6 OK lines.
  - `bash scripts/verify_index_health.sh` → exit 0.
  - `git diff --name-only main..HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` → 0.
  - `flutter analyze --no-fatal-infos && flutter test test/architecture/` → exit 0.
</verification>

<success_criteria>
- 1 new ADR file (ADR-011) + 1 INDEX update.
- Phase-level lib/-clean invariant verified across all 5 plans.
- All 6 grep gates in verify-doc-sweep.sh pass.
- INDEX health gate passes.
- ADR-011 cites 8 CI gates with verified line numbers (or step-name references for unverifiable lines).
- ADR-011 contains all 4 required content sections per CONTEXT D-05.
- Phase 7 success criteria from ROADMAP all 4 satisfied:
  1. ARCH/MOD/ADR drift-corrected (Plans 07-01, 07-02, 07-04 covered docs/arch/; verify-doc-sweep.sh gate 1+2+3+5).
  2. INDEX files reference only existing files (Plan 07-04 + scripts/verify_index_health.sh).
  3. CLAUDE.md Common Pitfalls annotated with enforcement status (Plan 07-03).
  4. ADR-011 filed for cleanup outcome + *.mocks.dart strategy + CI enforcement (Plan 07-05).
</success_criteria>

<output>
After completion, create `.planning/phases/07-documentation-sweep/07-05-SUMMARY.md` with:
- Capture stdout from all 4 final gates (verify-doc-sweep.sh, verify_index_health.sh, git diff lib/-clean check, flutter analyze + arch tests)
- ADR-011 line count and section list
- ADR-000_INDEX.md ADR-011 entry confirmation
- Phase-level lib/-clean confirmation: list of files in `git diff --name-only main..HEAD`, all under allowed paths
- Closing note: Phase 7 ROADMAP success criteria 1-4 all satisfied
</output>
