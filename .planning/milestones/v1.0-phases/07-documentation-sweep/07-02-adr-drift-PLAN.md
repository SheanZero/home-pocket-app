---
phase: 07-documentation-sweep
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - docs/arch/03-adr/ADR-002_Database_Solution.md
  - docs/arch/03-adr/ADR-007_Layer_Responsibilities.md
  - docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md
  - docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md
autonomous: true
requirements: [DOCS-01]

must_haves:
  truths:
    - "ADR-002, ADR-007, ADR-008, and ADR-010 each have a single appended `## Update 2026-04-27: Cleanup Initiative Outcome` section at the bottom of the file (D-06 append-only pattern)."
    - "The original decision body of every ADR is byte-identical to its pre-Plan-07-02 state — no `-` lines in `git diff` other than within the trailing whitespace of the previous-last section if a blank line was rebalanced."
    - "Each appended section cross-references ADR-011 via the relative link `[ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)`."
    - "ADR-002's appendix mentions sqlite3_flutter_libs is now CI-rejected (cite `audit.yml:64-69` and `lib/import_guard.yaml:5`); the original ADR-002 body is preserved verbatim."
    - "ADR-008's appendix notes that `lib/features/accounting/data/repositories/transaction_repository_impl.dart` is now at `lib/data/repositories/transaction_repository_impl.dart`; the original code samples are preserved verbatim (D1-10, D1-11)."
    - "ADR-010's appendix notes the same path move applies to its line-37 reference (D1-12); original body preserved."
    - "ADR-007's appendix notes that the Layer Responsibilities decision is now mechanically enforced by `lib/*/import_guard.yaml` + `test/architecture/domain_import_rules_test.dart`."
    - "lib/-clean invariant: this plan's commits modify ONLY paths under `docs/arch/03-adr/`."
  artifacts:
    - path: "docs/arch/03-adr/ADR-002_Database_Solution.md"
      provides: "Database tooling decision + append-only Cleanup Initiative Outcome section"
      contains: "## Update 2026-04-27: Cleanup Initiative Outcome"
    - path: "docs/arch/03-adr/ADR-007_Layer_Responsibilities.md"
      provides: "Layer rules decision + append-only enforcement update"
      contains: "## Update 2026-04-27: Cleanup Initiative Outcome"
    - path: "docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md"
      provides: "Book balance strategy + append-only path update"
      contains: "## Update 2026-04-27: Cleanup Initiative Outcome"
    - path: "docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md"
      provides: "CRDT conflict resolution + append-only path update"
      contains: "## Update 2026-04-27: Cleanup Initiative Outcome"
  key_links:
    - from: "docs/arch/03-adr/ADR-002_Database_Solution.md"
      to: "docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
      via: "relative markdown link in appended `## Update` section"
      pattern: "\\[ADR-011\\]\\(\\./ADR-011_Codebase_Cleanup_Initiative_Outcome\\.md\\)"
    - from: "docs/arch/03-adr/ADR-007_Layer_Responsibilities.md"
      to: "docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
      via: "relative markdown link"
      pattern: "\\[ADR-011\\]"
    - from: "docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md"
      to: "docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
      via: "relative markdown link"
      pattern: "\\[ADR-011\\]"
    - from: "docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md"
      to: "docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md"
      via: "relative markdown link"
      pattern: "\\[ADR-011\\]"

---

<objective>
Plan 07-02 covers DOCS-01 part 2: ADR drift fixes via the locked append-don't-mutate pattern (CONTEXT D-06). Four ADRs (002, 007, 008, 010) reference now-deprecated tooling (`sqlite3_flutter_libs`) or pre-cleanup file paths (`lib/features/accounting/data/repositories/...`). Per Pattern 2 in 07-RESEARCH.md and the rule in `.claude/rules/arch.md:171-173`, the decision bodies MUST be preserved verbatim. We append a single `## Update 2026-04-27: Cleanup Initiative Outcome` section at the bottom of each file, cross-referencing the (yet-to-be-created) ADR-011.

Purpose: Preserve historical decision context (ADRs are sacred records) while making the post-cleanup state discoverable from anyone landing on these ADRs.

Output: 4 modified ADRs with strictly additive diffs; each diff is a single `## Update` section appended at file end, no edits inside the original body.

NOTE: ADR-011 itself is created by Plan 07-05 (Wave B). The relative link `[ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)` will resolve once 07-05 lands; this plan's link target is forward-looking but specified by the locked D-05 filename. Plan 07-04's INDEX health check tolerates this transient state because ADR-011 lands before INDEX validation runs in Wave B.
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
@.claude/rules/arch.md

<append_pattern>
<!-- The exact append-section template, locked by CONTEXT D-06 + 07-PATTERNS.md lines 130-147 -->

```markdown
---

## Update 2026-04-27: Cleanup Initiative Outcome

**Cross-reference:** [ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

{file-specific paragraph — see each task's <action> for the exact content}

The original decision body above is preserved verbatim per ADR append-only convention
(`.claude/rules/arch.md:171-173`).
```

Rules (D-06):
1. Section header is exactly `## Update 2026-04-27: Cleanup Initiative Outcome`.
2. Goes at the **bottom** of the file (after `## 变更历史` if present, otherwise at file end).
3. **Never** modifies any line above the new section. Diff-guard:
   `git diff {file} | grep -cE '^-[^-]'` returns 0.
4. Cross-references ADR-011 via relative link.
</append_pattern>
</context>

<tasks>

<task type="auto">
  <id>07-02-01</id>
  <wave>1</wave>
  <name>Task 1: Append Cleanup-Outcome update to ADR-002 (Database Solution) — sqlite3_flutter_libs CI rejection</name>
  <files>docs/arch/03-adr/ADR-002_Database_Solution.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-002_Database_Solution.md (full file — focus on lines 52, 387 where sqlite3_flutter_libs is mentioned, and the file-end to find insertion point)
    - .planning/phases/07-documentation-sweep/07-CONTEXT.md (D-06)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 124-167 — exact pattern + diff guard)
    - .github/workflows/audit.yml (verify line numbers 64-69 are the AUDIT-09 sqlite3_flutter_libs gate before citing)
    - lib/import_guard.yaml (verify line 5 denies `package:sqlite3_flutter_libs/**`)
  </read_first>
  <action>
    Append the following section at the END of `docs/arch/03-adr/ADR-002_Database_Solution.md`. Do NOT modify any line above the insertion point. If the file ends with `## 变更历史` or any other section, insert AFTER that section's last line, separated by a blank line and `---` divider.

    ```markdown

    ---

    ## Update 2026-04-27: Cleanup Initiative Outcome

    **Cross-reference:** [ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

    Phases 3–6 of the codebase cleanup initiative changed how this decision is enforced
    in production:

    - `sqlite3_flutter_libs` is now actively rejected by CI gate AUDIT-09
      (`.github/workflows/audit.yml:64-69`) and by `lib/import_guard.yaml:5`
      (`package:sqlite3_flutter_libs/**` deny rule).
    - Only `sqlcipher_flutter_libs` is permitted; the original ADR-002 dual-listing of
      both libraries (lines 52, 387) is **historical context only** — the SQLCipher
      conflict described in those sections is now an active CI gate rather than a
      reviewer-discretion concern.

    The original decision body above is preserved verbatim per ADR append-only convention
    (`.claude/rules/arch.md:171-173`).
    ```

    Verify with `grep -B1 "## Update.*Cleanup" docs/arch/03-adr/ADR-002_Database_Solution.md` that the section is present.

    Verify with `git diff docs/arch/03-adr/ADR-002_Database_Solution.md | grep -cE '^-[^-]'` that ZERO lines were removed (the diff is purely additive).
  </action>
  <verify>
    <automated>grep -q "^## Update 2026-04-27: Cleanup Initiative Outcome$" docs/arch/03-adr/ADR-002_Database_Solution.md && grep -q "\[ADR-011\](\./ADR-011_Codebase_Cleanup_Initiative_Outcome\.md)" docs/arch/03-adr/ADR-002_Database_Solution.md && [ "$(git diff docs/arch/03-adr/ADR-002_Database_Solution.md | grep -cE '^-[^-]')" = "0" ]</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "^## Update 2026-04-27: Cleanup Initiative Outcome$" docs/arch/03-adr/ADR-002_Database_Solution.md` exits 0
    - `grep -q "\[ADR-011\](\./ADR-011_Codebase_Cleanup_Initiative_Outcome\.md)" docs/arch/03-adr/ADR-002_Database_Solution.md` exits 0 (cross-ref present)
    - `grep -q "audit\.yml:64-69" docs/arch/03-adr/ADR-002_Database_Solution.md` exits 0 (CI gate citation present per D-06)
    - `grep -q "lib/import_guard\.yaml:5" docs/arch/03-adr/ADR-002_Database_Solution.md` exits 0 (deny-rule citation present)
    - `git diff docs/arch/03-adr/ADR-002_Database_Solution.md | grep -cE '^-[^-]'` returns `0` (NO lines removed; append-only)
    - `git diff docs/arch/03-adr/ADR-002_Database_Solution.md | awk '/^---/{f=1} /^\+\+\+/{f=2} /^@@/{c++} f==2 && c==1' | head -1 | grep -qE '@@ .+\+[0-9]+,'` succeeds (first hunk is at file end, not in body) — sanity guard for D-06
    - The original line `sqlite3_flutter_libs ^0.5.18` (or similar) at line 52 is STILL present (verify body preservation): `grep -q "sqlite3_flutter_libs" docs/arch/03-adr/ADR-002_Database_Solution.md` exits 0
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>docs/arch/03-adr/ADR-002_Database_Solution.md</files_modified>
  <done>ADR-002 has the locked `## Update 2026-04-27: Cleanup Initiative Outcome` appendix with citations to audit.yml:64-69 and lib/import_guard.yaml:5; original body preserved (zero `-` lines in git diff).</done>
</task>

<task type="auto">
  <id>07-02-02</id>
  <wave>1</wave>
  <name>Task 2: Append Cleanup-Outcome update to ADR-007 (Layer Responsibilities) — mechanical enforcement</name>
  <files>docs/arch/03-adr/ADR-007_Layer_Responsibilities.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-007_Layer_Responsibilities.md (full file — find insertion point at end; identify any stack diagrams that mention mocktail/mockito)
    - .planning/phases/07-documentation-sweep/07-CONTEXT.md (D-06; "07-02-adr-drift-PLAN.md ... ADR-007 (mocktail line in stack diagram)" hint in `<plan_structure>`)
    - lib/import_guard.yaml, lib/application/import_guard.yaml, lib/data/import_guard.yaml, lib/features/import_guard.yaml, lib/infrastructure/import_guard.yaml (verify these 5 files exist — they're cited in the appendix)
    - test/architecture/domain_import_rules_test.dart (verify exists — cited in appendix)
    - test/architecture/provider_graph_hygiene_test.dart (verify exists — cited in appendix)
    - .github/workflows/audit.yml (verify line 36 runs `dart run custom_lint`)
  </read_first>
  <action>
    Append the following section at the END of `docs/arch/03-adr/ADR-007_Layer_Responsibilities.md`, AFTER the file's last existing section. Insert with a leading blank line and `---` divider.

    ```markdown

    ---

    ## Update 2026-04-27: Cleanup Initiative Outcome

    **Cross-reference:** [ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

    Phases 3–6 of the codebase cleanup initiative made the layer rules described above
    **mechanically enforced**:

    - `import_guard_custom_lint` plugin loaded via `analysis_options.yaml` plugins list,
      with per-layer YAML configs at:
      - `lib/import_guard.yaml` (root)
      - `lib/application/import_guard.yaml`
      - `lib/data/import_guard.yaml`
      - `lib/features/import_guard.yaml` (Thin Feature rule — features must NOT contain
        `application/`, `infrastructure/`, `data/tables/`, or `data/daos/`)
      - `lib/infrastructure/import_guard.yaml`
    - CI runs `dart run custom_lint` (`.github/workflows/audit.yml:36`) on every PR.
    - Architecture tests `test/architecture/domain_import_rules_test.dart` and
      `test/architecture/provider_graph_hygiene_test.dart` enforce the same invariants
      from the Dart side.

    Additionally, the code-sample stack diagrams in this ADR predate the Phase 4-04
    mocktail migration. Any `mockito` reference in this ADR's body should be read as
    a historical artifact; the post-cleanup mock framework is `mocktail` (per ADR-011
    §`*.mocks.dart` Strategy).

    The original decision body above is preserved verbatim per ADR append-only convention
    (`.claude/rules/arch.md:171-173`).
    ```

    Do NOT modify any line above the insertion point.
  </action>
  <verify>
    <automated>grep -q "^## Update 2026-04-27: Cleanup Initiative Outcome$" docs/arch/03-adr/ADR-007_Layer_Responsibilities.md && [ "$(git diff docs/arch/03-adr/ADR-007_Layer_Responsibilities.md | grep -cE '^-[^-]')" = "0" ]</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "^## Update 2026-04-27: Cleanup Initiative Outcome$" docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` exits 0
    - `grep -q "\[ADR-011\](\./ADR-011_Codebase_Cleanup_Initiative_Outcome\.md)" docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` exits 0
    - `grep -q "import_guard_custom_lint" docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` exits 0 (mechanism cited)
    - `grep -q "domain_import_rules_test\.dart" docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` exits 0 (arch test cited)
    - `grep -q "provider_graph_hygiene_test\.dart" docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` exits 0
    - `grep -q "audit\.yml:36" docs/arch/03-adr/ADR-007_Layer_Responsibilities.md` exits 0 (CI line cited)
    - `git diff docs/arch/03-adr/ADR-007_Layer_Responsibilities.md | grep -cE '^-[^-]'` returns `0` (append-only)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>docs/arch/03-adr/ADR-007_Layer_Responsibilities.md</files_modified>
  <done>ADR-007 has the appendix citing 5 import_guard YAML files, 2 arch tests, and audit.yml:36; original body preserved.</done>
</task>

<task type="auto">
  <id>07-02-03</id>
  <wave>1</wave>
  <name>Task 3: Append Cleanup-Outcome updates to ADR-008 + ADR-010 (Repository path moves)</name>
  <files>docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md, docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md (drift sites at lines 832, 848; identify file-end insertion point)
    - docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md (drift site at line 37; identify file-end insertion point)
    - lib/data/repositories/transaction_repository_impl.dart (verify exists at the post-cleanup path — confirmed via `ls`)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 169-189 — ADR-008 + ADR-010 specific append text)
  </read_first>
  <action>
    Append the following section at the END of EACH of `ADR-008_Book_Balance_Update_Strategy.md` and `ADR-010_CRDT_Conflict_Resolution_Strategy.md`. Each file gets its own commit (or a combined commit; both must be append-only).

    **For ADR-008:**
    ```markdown

    ---

    ## Update 2026-04-27: Cleanup Initiative Outcome

    **Cross-reference:** [ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

    Phase 3 centralization moved repository implementations from
    `lib/features/accounting/data/repositories/` to `lib/data/repositories/`. The code
    samples in this ADR (lines ~832, ~848) still show the pre-cleanup layout; the
    post-cleanup canonical location is:
    - Source: `lib/data/repositories/transaction_repository_impl.dart`
    - Test: `test/unit/data/repositories/transaction_repository_impl_test.dart` (verify
      via `find test -name 'transaction_repository_impl_test.dart'` if path differs)

    The original decision body above is preserved verbatim per ADR append-only convention
    (`.claude/rules/arch.md:171-173`).
    ```

    **For ADR-010:**
    ```markdown

    ---

    ## Update 2026-04-27: Cleanup Initiative Outcome

    **Cross-reference:** [ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)

    Phase 3 centralization moved the file at line 37 of this ADR
    (`lib/features/accounting/data/repositories/transaction_repository_impl.dart`) to
    `lib/data/repositories/transaction_repository_impl.dart`. The line-37 reference is
    preserved as historical context per ADR append-only convention.

    The original decision body above is preserved verbatim per ADR append-only convention
    (`.claude/rules/arch.md:171-173`).
    ```

    Do NOT modify any line above either insertion point.
  </action>
  <verify>
    <automated>grep -q "^## Update 2026-04-27: Cleanup Initiative Outcome$" docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md && grep -q "^## Update 2026-04-27: Cleanup Initiative Outcome$" docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md && [ "$(git diff docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md | grep -cE '^-[^-]')" = "0" ]</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "^## Update 2026-04-27: Cleanup Initiative Outcome$" docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` exits 0
    - `grep -q "^## Update 2026-04-27: Cleanup Initiative Outcome$" docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` exits 0
    - `grep -q "lib/data/repositories/transaction_repository_impl\.dart" docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` exits 0 (post-cleanup path stated)
    - `grep -q "lib/data/repositories/transaction_repository_impl\.dart" docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` exits 0
    - `grep -q "\[ADR-011\]" docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md` exits 0
    - `grep -q "\[ADR-011\]" docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` exits 0
    - `git diff docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md | grep -cE '^-[^-]'` returns `0` (append-only)
    - `git diff docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md | grep -cE '^-[^-]'` returns `0` (append-only)
    - The original line-37 reference in ADR-010 (`lib/features/accounting/data/repositories/transaction_repository_impl.dart`) is STILL present: `grep -q "features/accounting/data/repositories/transaction_repository_impl\.dart" docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md` exits 0
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>docs/arch/03-adr/ADR-008_Book_Balance_Update_Strategy.md, docs/arch/03-adr/ADR-010_CRDT_Conflict_Resolution_Strategy.md</files_modified>
  <done>ADR-008 + ADR-010 have appendix sections noting the lib/features→lib/data path move; original code samples preserved as historical context.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| ADR reader → Decision history | Future contributors trust ADRs as the authoritative record of why a decision was made. Mutating decision bodies destroys this trust. |
| ADR-011 forward-link → Eventual file | Plan 07-02 commits before Plan 07-05 creates ADR-011. Transient state where the link is broken; tolerable because Wave B INDEX checks run after both land. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-02-01 | Tampering / Repudiation | ADR decision body silently rewritten during sweep | mitigate | Every task acceptance includes `git diff ... \| grep -cE '^-[^-]'` returns 0 (append-only diff guard per D-06). |
| T-07-02-02 | Information Disclosure | Appendix incorrectly claims a CI gate enforces something | mitigate | Each cited line number (`audit.yml:64-69`, `audit.yml:36`, `lib/import_guard.yaml:5`) is verified via Read in `<read_first>` before the appendix is written. |
| T-07-02-03 | Tampering | ADR-003/006 (security ASVS V6) accidentally modified | mitigate | `files_modified` frontmatter does NOT list ADR-003 or ADR-006 — those crypto ADRs are explicitly excluded from this plan; if a task touches them, the plan-level lib/-clean check catches via wider scope. |
| T-07-02-04 | Information Disclosure | Forward-reference to ADR-011 may render as broken link if Plan 07-05 fails | accept | Wave B sequencing makes 07-05 → 07-04 verify the link before phase close; broken-link state is bounded to in-flight Wave A. |
</threat_model>

<verification>
- All 3 task acceptance criteria pass.
- After this plan completes, EACH of ADR-002, ADR-007, ADR-008, ADR-010 has exactly ONE `## Update 2026-04-27: Cleanup Initiative Outcome` section at file end.
- `git diff main..HEAD docs/arch/03-adr/` shows ONLY additions (no removals from any of the 4 ADR bodies).
- `git diff --name-only main..HEAD` includes ONLY the 4 ADRs in `files_modified`; nothing under lib/ or test/.
</verification>

<success_criteria>
- 4 ADRs have the locked appendix section.
- Zero lines removed from any of the 4 ADR bodies (per-file `git diff | grep -cE '^-[^-]'` returns 0 for all 4).
- Each appendix cites specific line numbers (audit.yml + import_guard.yaml + arch tests) that have been verified to exist.
- Each appendix cross-references ADR-011 via the locked relative-link form.
- `flutter analyze --no-fatal-infos` exits 0 (sanity backstop for accidental code edits — pure-doc commits do not affect it).
</success_criteria>

<output>
After completion, create `.planning/phases/07-documentation-sweep/07-02-SUMMARY.md` with:
- The 4 ADR files modified and the line range of the appended section in each
- Per-file confirmation that `git diff ... | grep -cE '^-[^-]'` returns 0 (append-only invariant)
- Note that the link `[ADR-011](./ADR-011_Codebase_Cleanup_Initiative_Outcome.md)` is forward-resolved by Plan 07-05; broken-link state is bounded to in-flight Wave A
</output>
