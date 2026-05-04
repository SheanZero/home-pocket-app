---
phase: 12-ui-copy-rename-pass-arb-values-ja-zh-en
plan: 03
type: execute
wave: 3
depends_on:
  - 12-ui-copy-rename-pass-arb-values-ja-zh-en/01
files_modified:
  - .planning/REQUIREMENTS.md
autonomous: true
requirements:
  - RENAME-07
user_setup: []

must_haves:
  truths:
    - "REQUIREMENTS.md RENAME section contains a new RENAME-07 entry whose body matches D-05 spec amendment text (satisfactionExcellent value rewrite to Amazing! / 至福！/ 最爱！; consumer NOT changed; rationale = register-aligned bottom hint)"
    - "Traceability table contains a new row `| RENAME-07 | Phase 12 | Pending |`"
    - "Coverage block at the bottom of REQUIREMENTS.md updates totals: v1.1 active REQ count 28 → ?? — see action for the precise math; the count must be incremented by exactly 1"
    - "No other REQ rows are altered, deleted, or reordered"
  artifacts:
    - path: ".planning/REQUIREMENTS.md"
      provides: "Updated requirements doc with RENAME-07"
      contains: "RENAME-07"
  key_links:
    - from: ".planning/REQUIREMENTS.md RENAME bullet list"
      to: ".planning/REQUIREMENTS.md Traceability table"
      via: "REQ-ID consistency"
      pattern: "RENAME-07 must appear in BOTH the RENAME section bullet list AND the traceability table; no orphaned IDs"
---

<objective>
Amend `.planning/REQUIREMENTS.md` to formally add **RENAME-07** as a v1.1 active requirement, capturing the D-05 decision that bottom-hint key `satisfactionExcellent` undergoes a value rewrite (en "Amazing!" / ja "至福！" / zh "最爱！") synchronized with `levelLabels[4]` per the picker's scale-anchor-vs-level-achieved double semantic. Update the traceability table to map RENAME-07 → Phase 12. Update the coverage totals at the bottom of the file.

Purpose: Capture spec-level provenance for the satisfactionExcellent value rewrite that landed in Plan 01. Without this amend, RENAME-07 exists only in CONTEXT.md (D-05) and PLAN frontmatter — REQUIREMENTS.md is the canonical source of truth and must reflect what shipped.

Output: 1 file edited (REQUIREMENTS.md), 1 atomic commit.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/REQUIREMENTS.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md
@.claude/rules/coding-style.md

<interfaces>
<!-- Current REQUIREMENTS.md structure (verified at planner read time) -->

Lines 70-77 contain the RENAME bullet list:
```
- [ ] **RENAME-01**: `soulLedger` ARB value renamed across ja/zh/en — JP: ときめき帳; ZH: 悦己账本; EN: Joy Ledger. Key unchanged.
- [ ] **RENAME-02**: `survivalLedger` ARB value renamed across ja/zh/en — JP: 日々の帳; ZH: 日常账本; EN: Daily Ledger. Key unchanged.
- [ ] **RENAME-03**: `homeHappinessROI` ARB value renamed — JP: ハピネス密度; ZH: 幸福密度; EN: Joy per ¥. Key unchanged (semantically misleading post-rename, but key-rename forces wider edits and triggers ARB-parity CI churn; deferred to v1.2+).
- [ ] **RENAME-04**: `homeSoulFullness` ARB value renamed — JP: ときめき度; ZH: 悦己充盈; EN: Joy Index. Key unchanged.
- [ ] **RENAME-05**: ADR **`ADR-XXX_Lexical_Hierarchy_v1_1.md`** captures the translation register hierarchy: 幸福 / happiness reserved for documentation; ときめき / 悦己 / Joy used in-product; CN family-mode uses 「家族的小确幸」 NOT 「家族悦己」 (collision with personal account name)
- [ ] **RENAME-06**: Native-speaker register review for ja/zh translations completed before merge — register matters more than lexical accuracy here
```

Lines 119-152 contain the Traceability table; the RENAME block ends at line 151:
```
| RENAME-01 | Phase 12 | Pending |
| RENAME-02 | Phase 12 | Pending |
| RENAME-03 | Phase 12 | Pending |
| RENAME-04 | Phase 12 | Pending |
| RENAME-05 | Phase 12 | Pending |
| RENAME-06 | Phase 12 | Pending |
```

Lines 153-156 contain coverage totals:
```
**Coverage:**
- v1.1 requirements: 28 total (was 25; +3 from Phase 10 D-06 scope expansion)
- Mapped to phases: 28
- Unmapped: 0 ✓
```

Note: CONTEXT.md D-05 mentions "v1.1 active REQ 数 31 → 32" because v1.1 requirements span HAPPY-01..09 (9; HAPPY-08 split treated as 1) + FAMILY-01..03 (3) + HOMEUI-01..07 (7) + STATSUI-01..07 (7) + RENAME-01..06 (6) = 32 active REQs. The current 28 figure in REQUIREMENTS.md predates Phase 11's STATSUI-05/06/07 expansion (which CONTEXT.md notes were added but the coverage totals were not re-bumped). The amend should bump from 28 → 29 (delta = +1 for RENAME-07) WITHOUT re-relitigating the underlying total — leave the explanatory parenthetical intact and append "+1 from RENAME-07 spec amendment" to the lineage note.

The 31 figure in CONTEXT.md D-05 reflects a CONTEXT-author count that does not match REQUIREMENTS.md's accounting; do NOT propagate that 31. The single durable rule: increment by exactly 1 (RENAME-07) and document in lineage.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Append RENAME-07 to RENAME bullet list (after RENAME-06)</name>
  <files>.planning/REQUIREMENTS.md</files>
  <read_first>
    - .planning/REQUIREMENTS.md lines 68-78 (RENAME section header + RENAME-01..06 bullets)
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md D-05 (rationale text for RENAME-07)
  </read_first>
  <action>
    Use Edit tool to add a new RENAME-07 bullet immediately after the existing RENAME-06 line. The RENAME-06 line currently reads:

    `- [ ] **RENAME-06**: Native-speaker register review for ja/zh translations completed before merge — register matters more than lexical accuracy here`

    Replace it with itself + one new bullet appended (use Edit's old_string = the RENAME-06 bullet exactly + new_string = the same RENAME-06 bullet + newline + the new RENAME-07 bullet):

    ```
    - [ ] **RENAME-06**: Native-speaker register review for ja/zh translations completed before merge — register matters more than lexical accuracy here
    - [ ] **RENAME-07**: `satisfactionExcellent` ARB value rewritten to Amazing! / 至福！/ 最爱！ across en/ja/zh — synchronized with `levelLabels[4]` (Amazing / 至福 / 最爱) plus `!` strengthening to keep the picker's bottom-hint scale-anchor in register with the level-achieved label. Key unchanged. `transaction_confirm_screen.dart` consumer (`bottomLabels: [satisfactionBad, satisfactionNormal, satisfactionExcellent]`) UNCHANGED — the rewrite stays inside the values-only Phase 12 boundary. Phase 12 D-05 spec amendment.
    ```

    DO NOT modify any RENAME-01..06 bullet. DO NOT alter any other section.
  </action>
  <verify>
    <automated>grep -c "RENAME-07.*satisfactionExcellent" .planning/REQUIREMENTS.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "^\\- \\[ \\] \\*\\*RENAME-07\\*\\*" .planning/REQUIREMENTS.md` returns exactly 1
    - `grep -c "satisfactionExcellent.*Amazing!" .planning/REQUIREMENTS.md` returns at least 1
    - `grep -c "至福！" .planning/REQUIREMENTS.md` returns at least 1
    - `grep -c "最爱！" .planning/REQUIREMENTS.md` returns at least 1
    - `grep -c "Phase 12 D-05 spec amendment" .planning/REQUIREMENTS.md` returns exactly 1
    - `grep -c "RENAME-06" .planning/REQUIREMENTS.md` returns exactly 2 (one in bullet list, one in traceability) — proves RENAME-06 not duplicated/lost
  </acceptance_criteria>
  <done>RENAME-07 bullet inserted directly after RENAME-06 with the D-05 rationale text.</done>
</task>

<task type="auto">
  <name>Task 2: Add RENAME-07 row to traceability table</name>
  <files>.planning/REQUIREMENTS.md</files>
  <read_first>
    - .planning/REQUIREMENTS.md lines 145-160 (traceability table tail + Coverage block)
  </read_first>
  <action>
    Use Edit tool to insert a new traceability row immediately after the `| RENAME-06 | Phase 12 | Pending |` row.

    Current line:
    `| RENAME-06 | Phase 12 | Pending |`

    Replace with:
    ```
    | RENAME-06 | Phase 12 | Pending |
    | RENAME-07 | Phase 12 | Pending |
    ```

    Preserve table column alignment (single-space padding on either side of `|`). DO NOT modify any other row.
  </action>
  <verify>
    <automated>grep -E "^\\| RENAME-0[1-7] \\| Phase 12 \\| Pending \\|" .planning/REQUIREMENTS.md | wc -l</automated>
  </verify>
  <acceptance_criteria>
    - `grep -cE "^\\| RENAME-0[1-7] \\| Phase 12 \\| Pending \\|" .planning/REQUIREMENTS.md` returns exactly 7
    - `grep -c "^\\| RENAME-07 \\| Phase 12 \\| Pending \\|" .planning/REQUIREMENTS.md` returns exactly 1
    - The 7 RENAME rows appear consecutively (no other row interleaved): verify by `awk '/^\\| RENAME-0[1-7]/' .planning/REQUIREMENTS.md | wc -l` returns 7 AND `awk '/^\\| RENAME-0[1-7]/{n++} END{print n}' .planning/REQUIREMENTS.md` returns 7
  </acceptance_criteria>
  <done>Traceability table contains 7 consecutive RENAME rows (RENAME-01 through RENAME-07).</done>
</task>

<task type="auto">
  <name>Task 3: Update coverage totals (28 → 29) with lineage annotation</name>
  <files>.planning/REQUIREMENTS.md</files>
  <read_first>
    - .planning/REQUIREMENTS.md lines 152-156 (Coverage block)
  </read_first>
  <action>
    Use Edit tool to update the two count lines in the Coverage block. The current block is:

    ```
    **Coverage:**
    - v1.1 requirements: 28 total (was 25; +3 from Phase 10 D-06 scope expansion)
    - Mapped to phases: 28
    - Unmapped: 0 ✓
    ```

    Replace with:

    ```
    **Coverage:**
    - v1.1 requirements: 29 total (was 25; +3 from Phase 10 D-06 scope expansion; +1 from Phase 12 D-05 RENAME-07 spec amendment)
    - Mapped to phases: 29
    - Unmapped: 0 ✓
    ```

    DO NOT modify the "Unmapped: 0 ✓" line beyond preserving it. DO NOT touch any other section.
  </action>
  <verify>
    <automated>grep -c "v1.1 requirements: 29 total" .planning/REQUIREMENTS.md && grep -c "+1 from Phase 12 D-05 RENAME-07 spec amendment" .planning/REQUIREMENTS.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "v1.1 requirements: 29 total" .planning/REQUIREMENTS.md` returns exactly 1
    - `grep -c "Mapped to phases: 29" .planning/REQUIREMENTS.md` returns exactly 1
    - `grep -c "+1 from Phase 12 D-05 RENAME-07 spec amendment" .planning/REQUIREMENTS.md` returns exactly 1
    - `grep -c "Unmapped: 0 ✓" .planning/REQUIREMENTS.md` returns exactly 1 (untouched)
    - `grep -c "v1.1 requirements: 28 total" .planning/REQUIREMENTS.md` returns exactly 0 (old line gone)
  </acceptance_criteria>
  <done>Coverage totals bumped 28 → 29 with lineage note appended.</done>
</task>

<task type="auto">
  <name>Task 4: Commit REQUIREMENTS.md amendment</name>
  <files>(git commit only)</files>
  <read_first>
    - .claude/rules/git-workflow.md
  </read_first>
  <action>
    Stage `.planning/REQUIREMENTS.md` only and commit:

    ```
    docs(12): amend REQUIREMENTS.md to add RENAME-07 spec entry

    Phase 12 D-05 spec amendment: satisfactionExcellent value rewrite
    (Amazing! / 至福！/ 最爱！) is now formally tracked as RENAME-07.

    Changes:
    - RENAME bullet list: append RENAME-07 after RENAME-06 with D-05 rationale
    - Traceability table: add `| RENAME-07 | Phase 12 | Pending |` row
    - Coverage totals: 28 → 29 (lineage: +1 from Phase 12 D-05)

    The actual ARB value rewrite (satisfactionExcellent across en/ja/zh) shipped
    in Plan 01 atomic ARB-rewrite commit; this commit is the spec-level mirror.

    Refs: D-05; RENAME-07; Phase 12
    ```

    DO NOT use `git add -A`. Stage only the one file.
  </action>
  <verify>
    <automated>git diff HEAD~1 --stat | grep -c ".planning/REQUIREMENTS.md" | grep -q 1 && git log -1 --pretty=format:"%s" | grep -q "docs(12).*amend REQUIREMENTS.md.*RENAME-07" && echo PASS || echo FAIL</automated>
  </verify>
  <acceptance_criteria>
    - Commit subject: `docs(12): amend REQUIREMENTS.md to add RENAME-07 spec entry`
    - `git diff HEAD~1 --stat` shows exactly 1 file: `.planning/REQUIREMENTS.md`
    - Commit body references D-05, RENAME-07, Phase 12
    - `git status` clean post-commit
  </acceptance_criteria>
  <done>REQUIREMENTS.md amendment committed in 1 file diff.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Spec doc → planner audits | REQUIREMENTS.md is the source of truth for downstream phases / `gsd-validate-phase`. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-12-07 | Tampering | Coverage totals drift (e.g., 28→27 by mistake) | mitigate | Task 3 acceptance gates both `29 total` and `Mapped to phases: 29`; Task 2 acceptance gates 7 consecutive RENAME rows. |
| T-12-08 | Repudiation | RENAME-07 appears in PLAN frontmatter but not in REQUIREMENTS.md | mitigate | This plan exists specifically to close that gap; covered by must_haves truths. |
</threat_model>

<verification>
- 1 new RENAME-07 bullet present, RENAME-01..06 unchanged
- 7 consecutive RENAME rows in traceability table
- Coverage totals bumped 28 → 29 with lineage
- Single-file commit with `docs(12):` subject
</verification>

<success_criteria>
- REQUIREMENTS.md cleanly amended with RENAME-07 in 3 locations (bullet list / traceability / coverage)
- No collateral edits
</success_criteria>

<output>
After completion, create `.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-03-SUMMARY.md` summarizing:
- The 3 edit locations in REQUIREMENTS.md
- The new coverage total math
- Commit hash
</output>
