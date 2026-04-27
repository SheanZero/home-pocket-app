---
phase: 07-documentation-sweep
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - CLAUDE.md
  - .claude/rules/arch.md
autonomous: true
requirements: [DOCS-01, DOCS-02]

must_haves:
  truths:
    - "Every one of CLAUDE.md's 13 numbered Common Pitfalls (lines ~263-277) has an enforcement-status annotation on an indented italics follow-up line, using one of the three locked tags: `*[Structurally enforced — ...]*`, `*[Partially enforced — ...]*`, or `*[Manually-checked only — ...]*`."
    - "The 13 annotations match the locked Pitfall-to-annotation map in 07-PATTERNS.md lines 273-287 verbatim."
    - "All `doc/arch/` (singular, broken) references in CLAUDE.md (D4-1, D4-2, D4-3) are replaced with `docs/arch/` (plural, correct) — 6 sites per 07-RESEARCH.md."
    - "All `doc/arch/` references in `.claude/rules/arch.md` (D4-4) are replaced with `docs/arch/` — 10+ sites per 07-RESEARCH.md."
    - "Phantom MOD-014 references in CLAUDE.md (D5-1, D5-2) are replaced: line 190 spec link → BASIC-003 path; line 220 module-priority list → `BASIC-003 i18n` (D-01)."
    - "lib/-clean invariant: this plan's commits modify ONLY `CLAUDE.md` and `.claude/rules/arch.md`."
    - "After Wave 1 commits, gates 4 + 5 of `verify-doc-sweep.sh` PASS."
  artifacts:
    - path: "CLAUDE.md"
      provides: "Project instructions with annotated Common Pitfalls + corrected paths"
      contains: "Common Pitfalls"
    - path: ".claude/rules/arch.md"
      provides: "Architecture-doc workflow rule with corrected docs/arch/ paths"
  key_links:
    - from: "CLAUDE.md"
      to: ".claude/rules/arch.md"
      via: "cross-reference for full doc workflow"
      pattern: "\\.claude/rules/arch\\.md"
    - from: "CLAUDE.md"
      to: "docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md"
      via: "Spec link replaces phantom MOD-014_i18n.md"
      pattern: "BASIC-003_I18N_Infrastructure\\.md"

---

<objective>
Plan 07-03 covers DOCS-02 (annotate the 13 Common Pitfalls with their enforcement status) and the CLAUDE.md / `.claude/rules/arch.md` portions of DOCS-01 (path-spelling drift `doc/arch/` → `docs/arch/`; phantom MOD-014 → BASIC-003 per D-01 + D-03).

Purpose: Future contributors landing on CLAUDE.md get an accurate "what's automated vs what relies on review" map of the 13 pitfalls, plus working links into `docs/arch/`. The companion rule file `.claude/rules/arch.md` is fixed in the same plan because CLAUDE.md cross-references it (D-03 — both must agree).

Output: 2 modified files. CLAUDE.md gains 13 annotation lines + 6 path corrections + 2 phantom-MOD-014 replacements. `.claude/rules/arch.md` gets ~10 path corrections.
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
@CLAUDE.md
@.claude/rules/arch.md

<annotation_map>
<!-- Locked Pitfall-to-annotation map; verbatim from 07-PATTERNS.md lines 273-287. -->
<!-- Each pitfall gets ONE annotation line, indented 3 spaces, italics with em-dash separator. -->

| # | Annotation tag (verbatim) |
|---|----------------------------|
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

Format constraints (D-CONTEXT):
- Italics: single asterisk on each side, then square brackets.
- Indented 3 spaces under the numbered item.
- Em-dash (`—`, not `--` or `-`) between status and mechanism.
- Mechanism is concrete: file path, test name, or CI gate ID.
</annotation_map>
</context>

<tasks>

<task type="auto">
  <id>07-03-01</id>
  <wave>1</wave>
  <name>Task 1: Annotate CLAUDE.md "Common Pitfalls" with 13 enforcement-status tags (DOCS-02)</name>
  <files>CLAUDE.md</files>
  <read_first>
    - CLAUDE.md (lines ~263-277 — the 13 Common Pitfalls list)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 220-289 — annotation pattern + Pitfall-to-annotation map)
    - .planning/phases/07-documentation-sweep/07-VALIDATION.md (line ~46 — Python verification snippet)
    - analysis_options.yaml (verify line numbers cited; the annotations cite `audit.yml line 34`, `pubspec.yaml line 18` — these are read-only references)
    - pubspec.yaml (verify line 18 has the `intl: 0.20.2` exact pin cited in pitfall #5 annotation)
    - .github/workflows/audit.yml (verify lines 34, 64-69, 81-89 are the cited gates)
  </read_first>
  <action>
    Locate the `## Common Pitfalls` section in `CLAUDE.md` (currently around lines 263-277). The section contains 13 numbered items.

    For each item N, insert a new line IMMEDIATELY AFTER the existing item-N text. The new line must:
    - Be indented exactly 3 spaces from the left margin.
    - Contain the EXACT annotation string from the locked map in `<annotation_map>` above (use the em-dash character `—`, NOT `--` or `-`).
    - Be wrapped in single asterisks for italics.

    Example final state of items 1 and 2:
    ```markdown
    1. Don't modify generated files (`.g.dart`, `.freezed.dart`)
       *[Partially enforced — AUDIT-10 catches stale committed files; hand-edits matching generator output go undetected]*
    2. Don't violate layer dependencies (Domain must not import Data)
       *[Structurally enforced — import_guard via custom_lint + arch test domain_import_rules_test.dart]*
    ```

    Do NOT modify the original numbered text of any pitfall. Only INSERT the indented annotation line below it.

    Verify final state with:
    ```bash
    python3 -c "
    import re
    t = open('CLAUDE.md').read()
    section = re.search(r'## Common Pitfalls.+?(?=\n## |\Z)', t, re.S).group()
    items = [i for i in re.split(r'\n(?=\d+\. )', section) if re.match(r'\d+\.', i)]
    assert len(items) == 13, f'Expected 13 pitfalls, got {len(items)}'
    for i, item in enumerate(items, 1):
        assert re.search(r'\*\[(Structurally enforced|Partially enforced|Manually-checked only) — ', item), f'Pitfall #{i} missing annotation'
    print('OK: all 13 pitfalls annotated')
    "
    ```
  </action>
  <verify>
    <automated>python3 -c "import re; t=open('CLAUDE.md').read(); section=re.search(r'## Common Pitfalls.+?(?=\n## |\Z)', t, re.S).group(); items=[i for i in re.split(r'\n(?=\d+\. )', section) if re.match(r'\d+\.', i)]; assert len(items)==13; assert all(re.search(r'\*\[(Structurally enforced|Partially enforced|Manually-checked only) — ', i) for i in items); print('OK')"</automated>
  </verify>
  <acceptance_criteria>
    - The Python verification snippet above prints `OK` (all 13 pitfalls have one of the three annotation tags)
    - `grep -cE '^   \*\[(Structurally|Partially) enforced|^   \*\[Manually-checked only' CLAUDE.md` returns at least `13` (each annotation line is on its own indented line)
    - `grep -c '\*\[Structurally enforced —' CLAUDE.md` returns at least `7` (per locked map: pitfalls 2, 3, 5, 6, 8, 10, 13)
    - `grep -c '\*\[Partially enforced —' CLAUDE.md` returns at least `2` (pitfalls 1, 12)
    - `grep -c '\*\[Manually-checked only —' CLAUDE.md` returns at least `4` (pitfalls 4, 7, 9, 11)
    - `grep -F -- '*[Structurally enforced — exact pin in pubspec.yaml line 18]*' CLAUDE.md` matches (pitfall #5 exact tag landed)
    - `grep -F -- '*[Structurally enforced — flutter analyze CI step (audit.yml line 34)]*' CLAUDE.md` matches (pitfall #8 exact tag landed)
    - The original 13 numbered pitfall lines are still present (NO `Don't ...` text was removed): `grep -cE "^[0-9]+\. Don't" CLAUDE.md` returns at least `13`
    - No annotation contains `--` (double-hyphen instead of em-dash): `! grep -E '\*\[.*--.*\]\*' CLAUDE.md` exits 0
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>CLAUDE.md</files_modified>
  <done>All 13 Common Pitfalls in CLAUDE.md have the exact locked annotation lines; original numbered text preserved; no double-hyphens introduced.</done>
</task>

<task type="auto">
  <id>07-03-02</id>
  <wave>1</wave>
  <name>Task 2: Fix CLAUDE.md doc/arch path drift + phantom MOD-014 references (D4-1..D4-3, D5-1, D5-2)</name>
  <files>CLAUDE.md</files>
  <read_first>
    - CLAUDE.md (lines 190, 220, 227, 255-258 — drift sites)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 291-335 — exact replacements)
    - docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md (verify file exists at this path before linking to it)
  </read_first>
  <action>
    Apply the following exact replacements in `CLAUDE.md`:

    **Path drift (D4 — `doc/arch/` → `docs/arch/`):**
    - Line ~227: `## Architecture Docs (\`doc/arch/\`)` → `## Architecture Docs (\`docs/arch/\`)`
    - Lines ~255-258: 4 links of the form `\`doc/arch/01-core-architecture/ARCH-XXX...\`` → `\`docs/arch/01-core-architecture/ARCH-XXX...\``
    - Any other `doc/arch/` (singular, with non-`/` next char) occurrence in CLAUDE.md → `docs/arch/`

    **Phantom MOD-014 (D5 + D-01):**
    - Line ~190: `**Spec:** \`doc/arch/02-module-specs/MOD-014_i18n.md\`` → `**Spec:** \`docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md\`` (combines D4-1 path fix + D5-1 phantom replacement)
    - Line ~220: `1. **Infrastructure:** MOD-006 Security, MOD-014 i18n` → `1. **Infrastructure:** MOD-006 Security, BASIC-003 i18n`

    Use a careful pass — DO NOT do a blind `sed` replacement because some lines need both transformations. Read each line, apply the correct combined replacement.

    Verify:
    ```bash
    grep -nE 'doc/arch[^/]' CLAUDE.md     # → 0 hits
    grep -n  'MOD-014'      CLAUDE.md     # → 0 hits
    ```
  </action>
  <verify>
    <automated>! grep -nE 'doc/arch[^/]' CLAUDE.md && ! grep -n 'MOD-014' CLAUDE.md && grep -q 'docs/arch/04-basic/BASIC-003_I18N_Infrastructure\.md' CLAUDE.md && grep -q 'BASIC-003 i18n' CLAUDE.md</automated>
  </verify>
  <acceptance_criteria>
    - `! grep -nE 'doc/arch[^/]' CLAUDE.md` exits 0 (no more singular `doc/arch/` references; D4-1, D4-2, D4-3 closed)
    - `! grep -n 'MOD-014' CLAUDE.md` exits 0 (no more phantom MOD-014 references; D5-1, D5-2 closed)
    - `grep -q 'docs/arch/04-basic/BASIC-003_I18N_Infrastructure\.md' CLAUDE.md` exits 0 (D-01 replacement landed in spec link)
    - `grep -q 'BASIC-003 i18n' CLAUDE.md` exits 0 (D-01 replacement landed in module-priority list)
    - `grep -c 'docs/arch/' CLAUDE.md` returns at least `5` (the 5+ replacements landed correctly)
    - `grep -c '## Architecture Docs (`docs/arch/`)' CLAUDE.md` returns `1` (header line corrected)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>CLAUDE.md</files_modified>
  <done>CLAUDE.md has zero `doc/arch[^/]` matches and zero `MOD-014` matches; spec link points to BASIC-003; module priority list says BASIC-003 i18n.</done>
</task>

<task type="auto">
  <id>07-03-03</id>
  <wave>1</wave>
  <name>Task 3: Fix .claude/rules/arch.md doc/arch path drift (D4-4, D-03)</name>
  <files>.claude/rules/arch.md</files>
  <read_first>
    - .claude/rules/arch.md (lines 7, 29, 34, 87, 90, 94, 97, 187, 191, 220 — per 07-RESEARCH.md D4-4 row; verify each via `grep -nE 'doc/arch[^/]'`)
    - .planning/phases/07-documentation-sweep/07-CONTEXT.md (D-03 — `.claude/rules/arch.md` is in scope; ~10 sed-style replacements)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 339-353 — single-token replacement + diff-size guard)
  </read_first>
  <action>
    Apply a global `doc/arch/` → `docs/arch/` replacement in `.claude/rules/arch.md`. This is purely mechanical — every occurrence of the singular form (with a non-slash next character) becomes the plural form.

    Run `grep -nE 'doc/arch[^/]' .claude/rules/arch.md` BEFORE editing to enumerate the sites. Per 07-RESEARCH.md D4-4 expect ≈10 hits at lines 7, 29, 34, 87, 90, 94, 97, 187, 191, 220.

    Apply the replacement (e.g., editor multi-cursor on the regex, or `sed -i '' 's|doc/arch/|docs/arch/|g'` on macOS — verify the file was modified, no side effects).

    Verify:
    ```bash
    ! grep -nE 'doc/arch[^/]' .claude/rules/arch.md   # → 0 hits
    git diff --stat .claude/rules/arch.md             # ≈10 lines changed
    ```

    DO NOT introduce any other change to `.claude/rules/arch.md` in this task. Per CONTEXT D-03, only the path-spelling fix is in scope.
  </action>
  <verify>
    <automated>! grep -nE 'doc/arch[^/]' .claude/rules/arch.md</automated>
  </verify>
  <acceptance_criteria>
    - `! grep -nE 'doc/arch[^/]' .claude/rules/arch.md` exits 0 (D4-4 closed)
    - `grep -c 'docs/arch/' .claude/rules/arch.md` is at least `10` (≈10 replacements landed, matching RESEARCH count)
    - The number of changed lines reported by `git diff --stat .claude/rules/arch.md` is between 5 and 25 (the bulk should be `doc/arch/` → `docs/arch/` only; if much higher, scope creep occurred)
    - `! grep -E 'doc/arch[^/]' .claude/rules/arch.md` exits 0 (extra safety: no leftover singular form anywhere)
    - The file's overall structure is preserved: `grep -c '^## ' .claude/rules/arch.md` returns the same count as before this task (sanity check that no headings were renumbered)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean)
  </acceptance_criteria>
  <files_modified>.claude/rules/arch.md</files_modified>
  <done>.claude/rules/arch.md has zero `doc/arch[^/]` matches; replacement is mechanical and bounded to ~10 sites.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Contributor reading CLAUDE.md → Pitfall enforcement understanding | A "Structurally enforced" tag tells contributors they don't need to manually check; a wrong tag causes false security or wasted review. |
| Cross-doc link CLAUDE.md → docs/arch/* | Broken paths waste time and erode trust; D4 path-spelling drift is a project-wide bug. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-03-01 | Information Disclosure (false sense of security) | Annotating a manually-checked pitfall as "Structurally enforced" | mitigate | The locked map in 07-PATTERNS.md is the source of truth; each tag was derived from inspection of analysis_options.yaml + import_guard.yaml + audit.yml + arch tests in RESEARCH §"CLAUDE.md Pitfall Classification". The plan copies the map verbatim — no judgment call. |
| T-07-03-02 | Tampering | Phantom MOD-014 link survives, sending contributors to a non-existent file | mitigate | Task 07-03-02 acceptance includes `! grep -n 'MOD-014' CLAUDE.md` and `grep -q 'BASIC-003_I18N_Infrastructure\.md'` — both must pass. |
| T-07-03-03 | Tampering | Annotation accidentally introduces double-hyphen instead of em-dash | mitigate | Acceptance includes `! grep -E '\*\[.*--.*\]\*' CLAUDE.md` (no double-hyphen inside annotation). |
| T-07-03-04 | Repudiation | `.claude/rules/arch.md` left out of scope, so CLAUDE.md and the rule file diverge | mitigate | D-03 explicitly LOCKED scope to include `.claude/rules/arch.md`; Task 07-03-03 covers it. |
</threat_model>

<verification>
- All 3 task acceptance criteria pass.
- After this plan completes:
  - Gate [4/6] of `verify-doc-sweep.sh` PASSES (`grep -cE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md` → 0).
  - Gate [5/6] of `verify-doc-sweep.sh` PARTIALLY passes (CLAUDE.md is clean; `docs/arch/` is still being swept by Plan 07-01 in parallel).
- The Python annotation-completeness check returns OK.
- `flutter analyze --no-fatal-infos` exits 0.
</verification>

<success_criteria>
- 13 annotation lines added to CLAUDE.md, matching the locked map verbatim.
- 6 path-drift sites in CLAUDE.md fixed (`doc/arch/` → `docs/arch/`).
- 2 phantom MOD-014 sites in CLAUDE.md replaced with BASIC-003 path/label.
- ~10 path-drift sites in `.claude/rules/arch.md` fixed.
- Zero `doc/arch[^/]` matches across BOTH CLAUDE.md and `.claude/rules/arch.md`.
- Zero `MOD-014` matches in CLAUDE.md.
- `git diff --name-only main..HEAD` lists ONLY `CLAUDE.md` and `.claude/rules/arch.md` (lib/-clean).
</success_criteria>

<output>
After completion, create `.planning/phases/07-documentation-sweep/07-03-SUMMARY.md` with:
- Pre/post grep counts for `doc/arch[^/]` and `MOD-014` in each file
- Pre/post Python annotation-completeness check result
- Confirmation lib/-clean
</output>
