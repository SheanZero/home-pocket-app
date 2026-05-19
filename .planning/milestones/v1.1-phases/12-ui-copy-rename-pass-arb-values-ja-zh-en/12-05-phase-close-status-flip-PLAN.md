---
phase: 12-ui-copy-rename-pass-arb-values-ja-zh-en
plan: 05
type: execute
wave: 4
depends_on:
  - 12-ui-copy-rename-pass-arb-values-ja-zh-en/01
  - 12-ui-copy-rename-pass-arb-values-ja-zh-en/02
  - 12-ui-copy-rename-pass-arb-values-ja-zh-en/03
  - 12-ui-copy-rename-pass-arb-values-ja-zh-en/04
files_modified:
  - docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md
  - docs/arch/03-adr/ADR-000_INDEX.md
  - doc/worklog/YYYYMMDD_HHMM_phase_12_ui_copy_rename_pass.md
autonomous: true
requirements:
  - RENAME-01
  - RENAME-02
  - RENAME-03
  - RENAME-04
  - RENAME-05
  - RENAME-06
  - RENAME-07
user_setup: []

must_haves:
  truths:
    - "Phase 12 integration verification passes: ARB-parity test + flutter gen-l10n + flutter analyze + picker tests all green AFTER all of Plans 01-04 have landed"
    - "Plans 01-04 outputs are inspected (commits in main, no follow-ups outstanding) before status flip"
    - "ADR-015 status badge flips from `📝 草稿` to `✅ 已接受` (and the change-log row gains a v1.1 acceptance entry dated 2026-05-04)"
    - "ADR-000_INDEX.md statistics block updates: 草稿 4→3 (ADR-015 leaves Draft), 已接受 10→11 (ADR-015 enters Accepted); 总计 stays 15"
    - "doc/worklog/YYYYMMDD_HHMM_phase_12_ui_copy_rename_pass.md created per .claude/rules/worklog.md template, with every completion section filled (任务概述 / 完成的工作 / 测试验证 / Git 提交记录 of plans 01-04 + this plan / 后续工作 / 参考资源)"
    - "No further code, ARB, or test edits in this plan — pure status-flip + worklog operation"
  artifacts:
    - path: "docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md"
      provides: "ADR-015 with status `✅ 已接受`"
      contains: "✅ 已接受"
    - path: "docs/arch/03-adr/ADR-000_INDEX.md"
      provides: "Statistics: 已接受=11 / 草稿=3 / 总计=15"
      contains: "已接受 | 11"
    - path: "doc/worklog/YYYYMMDD_HHMM_phase_12_ui_copy_rename_pass.md"
      provides: "Phase 12 worklog per project rules"
      min_lines: 50
  key_links:
    - from: "ADR-015 (Plan 04 Draft)"
      to: "ADR-015 (Plan 05 Accepted)"
      via: "Status badge edit + change log append"
      pattern: "Plan 04 Draft → Plan 05 Accepted is the only ADR-015 substantive edit in Phase 12; future revisions use append-only Update sections"
---

<objective>
Close Phase 12 by performing four operations:

1. Run integration verification across the full Phase 12 surface (ARB-parity test + flutter gen-l10n + flutter analyze + satisfaction picker tests + grep gates) to confirm Plans 01-04 cleanly composed.
2. Flip ADR-015 status from `📝 草稿` to `✅ 已接受` and append the acceptance entry to its change log.
3. Update ADR-000_INDEX.md statistics to reflect ADR-015's transition to Accepted.
4. Generate the Phase 12 worklog file under `doc/worklog/` per `.claude/rules/worklog.md`.

Per CONTEXT.md, this plan is the v1.1 milestone-close ceremony for Phase 12. ADR-015 transitions from Draft → Accepted under the same pattern Phase 9 used to transition ADR-012/013/014.

Purpose: Provide a clean close-out commit with verification evidence, ADR finalization, and worklog provenance — so that subsequent v1.1 milestone retrospective and v1.2 planning have a stable baseline to read from.

Output: 2 doc files edited (ADR-015 + INDEX), 1 worklog file created, 1 atomic commit.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/ROADMAP.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-01-SUMMARY.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-02-SUMMARY.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-03-SUMMARY.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-04-SUMMARY.md
@docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md
@docs/arch/03-adr/ADR-000_INDEX.md
@.claude/rules/worklog.md

<interfaces>
<!-- Plan 04 INDEX statistics state (after Plan 04, before Plan 05): -->
| ✅ 已接受 | 10 |
| ✅ 已实施 | 1 |
| 🔄 讨论中 | 0 |
| ❌ 已拒绝 | 0 |
| 📝 草稿 | 4 |
**总计:** 15个ADR

<!-- Plan 05 target INDEX statistics state: -->
| ✅ 已接受 | 11 |
| ✅ 已实施 | 1 |
| 🔄 讨论中 | 0 |
| ❌ 已拒绝 | 0 |
| 📝 草稿 | 3 |
**总计:** 15个ADR

<!-- Plan 04 ADR-015 entry status in INDEX (line within the "ADR-015: 词汇分层 v1.1" section): -->
**状态:** 📝 草稿

<!-- Plan 05 target — same field: -->
**状态:** ✅ 已接受
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Integration verification — Plans 01-04 composition stays green</name>
  <files>(read-only — verification gate before any edits in this plan)</files>
  <read_first>
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-01-SUMMARY.md (Plan 01 outcome)
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-02-SUMMARY.md (Plan 02 outcome)
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-03-SUMMARY.md (Plan 03 outcome)
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-04-SUMMARY.md (Plan 04 outcome)
  </read_first>
  <action>
    Run all Phase 12 verification commands and capture outputs for the worklog (Task 4). If any of these fails, STOP and surface the failure — do NOT proceed to Tasks 2-4.

    1. ARB key parity test (must pass):
       `flutter test test/architecture/arb_key_parity_test.dart`

    2. Localization regen smoke (must produce 0 warnings — re-run to prove idempotency post-Plan-01):
       `flutter gen-l10n 2>&1 | tee /tmp/gen-l10n-final.txt`

    3. Picker widget test (must pass with new labels):
       `flutter test test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart`

    4. Analyzer (must report 0 issues across lib/):
       `flutter analyze lib/`

    5. Grep gates from Plans 01-02 — confirm no regression:
       - `grep -c '"soulLedger": "Joy Ledger"' lib/l10n/app_en.arb` returns 1
       - `grep -c '"soulLedger": "ときめき帳"' lib/l10n/app_ja.arb` returns 1
       - `grep -c '"soulLedger": "悦己账本"' lib/l10n/app_zh.arb` returns 1
       - `grep -rE "Icons\\.sentiment_(very_)?dissatisfied" lib/` returns 0 matches
       - `grep -c "RENAME-07" .planning/REQUIREMENTS.md` returns at least 2 (bullet + traceability)
       - `grep -c "ADR-015" docs/arch/03-adr/ADR-000_INDEX.md` returns at least 2 (entry + review row)
       - `grep -c "📝 草稿" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns 1 (still Draft pre-flip)

    Capture each command's exit code and a 3-line stdout/stderr excerpt for Task 4 worklog body.
  </action>
  <verify>
    <automated>flutter test test/architecture/arb_key_parity_test.dart && flutter test test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart && flutter analyze lib/ 2>&1 | grep -q "No issues found" && echo PASS</automated>
  </verify>
  <acceptance_criteria>
    - ARB parity test exits 0
    - Picker widget test exits 0
    - `flutter analyze lib/` reports "No issues found"
    - All 7 grep gates from `<action>` produce expected counts
    - Verification outputs captured in working memory for Task 4 worklog body
  </acceptance_criteria>
  <done>Integration verification PASSES; Plans 01-04 compose cleanly; ready for status flip.</done>
</task>

<task type="auto">
  <name>Task 2: Flip ADR-015 status from 草稿 → 已接受 + append change-log row</name>
  <files>docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md (full file as authored in Plan 04 — confirm `**状态:** 📝 草稿` location and change-log table location)
  </read_first>
  <action>
    Two Edit tool calls:

    **Edit 1 — flip the status badge in the header block:**
    Replace `**状态:** 📝 草稿` with `**状态:** ✅ 已接受`.
    There MUST be exactly one occurrence of `**状态:** 📝 草稿` in the file (the header). DO NOT use `replace_all` — use the surrounding context (e.g., the line above containing `# ADR-015:` or the line below containing `**日期:**`) to anchor the edit.

    **Edit 2 — append the acceptance row to the 变更历史 (Change Log) table:**
    The table currently looks like:
    ```
    | 日期 | 版本 | 变更内容 | 作者 |
    |------|------|---------|------|
    | 2026-05-04 | 1.0 | 初版起草 (Draft) | Claude planning agent |
    ```

    Append a new row immediately after the 1.0 row:
    ```
    | 日期 | 版本 | 变更内容 | 作者 |
    |------|------|---------|------|
    | 2026-05-04 | 1.0 | 初版起草 (Draft) | Claude planning agent |
    | 2026-05-04 | 1.1 | 状态翻转: 📝 草稿 → ✅ 已接受 (Phase 12 close — RENAME-01..07 verified, INDEX synced) | Claude planning agent |
    ```

    DO NOT modify any other section. The Append-only protocol section's text remains intact — Plan 05 is the singular Draft→Accepted flip, not a substantive edit.
  </action>
  <verify>
    <automated>grep -c "✅ 已接受" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md && grep -c "📝 草稿" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "^\\*\\*状态:\\*\\* ✅ 已接受" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1 (badge flipped)
    - `grep -c "^\\*\\*状态:\\*\\* 📝 草稿" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns 0 (Draft badge gone from header)
    - Note: the file may still contain the literal phrase 「📝 草稿」 once inside the change-log row (`📝 草稿 → ✅ 已接受`) — that occurrence is permitted; the test discriminates via line-anchor `^**状态:**`
    - `grep -c "状态翻转: 📝 草稿 → ✅ 已接受" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns exactly 1 (change-log row added)
    - `grep -c "Phase 12 close" docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` returns at least 1
    - File diff vs Plan 04 commit shows exactly 2 line changes (the status badge line + 1 new row in the change-log table)
  </acceptance_criteria>
  <done>ADR-015 transitioned to Accepted with audit-trail entry in change log.</done>
</task>

<task type="auto">
  <name>Task 3: Sync ADR-000_INDEX.md statistics + ADR-015 entry status</name>
  <files>docs/arch/03-adr/ADR-000_INDEX.md</files>
  <read_first>
    - docs/arch/03-adr/ADR-000_INDEX.md lines 430-495 (post-Plan-04 ADR-015 entry + statistics block)
  </read_first>
  <action>
    Two Edit tool calls:

    **Edit 1 — flip ADR-015 status in the INDEX entry:**
    Within the ADR-015 section added by Plan 04, replace the literal line `**状态:** 📝 草稿` (the one inside the ADR-015 block, not anywhere else) with `**状态:** ✅ 已接受`.

    Anchor by surrounding context: the previous line should read `### [ADR-015: 词汇分层 v1.1](./ADR-015_Lexical_Hierarchy_v1_1.md)` and the next line should read `**日期:** 2026-05-04`.

    **Edit 2 — update statistics block:**
    Replace:
    ```
    | ✅ 已接受 | 10 |
    | ✅ 已实施 | 1 |
    | 🔄 讨论中 | 0 |
    | ❌ 已拒绝 | 0 |
    | 📝 草稿 | 4 |

    **总计:** 15个ADR
    ```

    With:
    ```
    | ✅ 已接受 | 11 |
    | ✅ 已实施 | 1 |
    | 🔄 讨论中 | 0 |
    | ❌ 已拒绝 | 0 |
    | 📝 草稿 | 3 |

    **总计:** 15个ADR
    ```

    DO NOT modify the review schedule table (ADR-015 row stays as `v1.2 milestone start | 一次性评估` — the review trigger is the next milestone, unchanged by this acceptance flip). DO NOT modify the relationship diagram. DO NOT modify the `**最后更新:**` field again — it was already bumped to 2026-05-04 in Plan 04.
  </action>
  <verify>
    <automated>grep -c "✅ 已接受 | 11" docs/arch/03-adr/ADR-000_INDEX.md && grep -c "📝 草稿 | 3" docs/arch/03-adr/ADR-000_INDEX.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "| ✅ 已接受 | 11 |" docs/arch/03-adr/ADR-000_INDEX.md` returns exactly 1
    - `grep -c "| 📝 草稿 | 3 |" docs/arch/03-adr/ADR-000_INDEX.md` returns exactly 1
    - `grep -c "| ✅ 已接受 | 10 |" docs/arch/03-adr/ADR-000_INDEX.md` returns 0 (old count gone)
    - `grep -c "| 📝 草稿 | 4 |" docs/arch/03-adr/ADR-000_INDEX.md` returns 0 (old count gone)
    - `grep -c "^\\*\\*总计:\\*\\* 15个ADR\\|^\\*\\*总计：\\*\\* 15个ADR" docs/arch/03-adr/ADR-000_INDEX.md` returns 1 (unchanged total)
    - The ADR-015 INDEX entry's `**状态:**` line reads `✅ 已接受` (verify by extracting lines around `### [ADR-015:` heading)
    - `grep -c "| ADR-015 | v1.2 milestone start | 一次性评估 |" docs/arch/03-adr/ADR-000_INDEX.md` returns exactly 1 (review schedule unchanged)
  </acceptance_criteria>
  <done>INDEX statistics + ADR-015 entry status synced to Accepted.</done>
</task>

<task type="auto">
  <name>Task 4: Generate Phase 12 worklog file per .claude/rules/worklog.md</name>
  <files>doc/worklog/YYYYMMDD_HHMM_phase_12_ui_copy_rename_pass.md</files>
  <read_first>
    - .claude/rules/worklog.md (full file — template structure + naming convention)
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md domain section (Phase 12 boundary)
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-0[1-4]-SUMMARY.md (each plan's deliverables — Task 1 already gathered context)
  </read_first>
  <action>
    Determine the timestamp at execution time:
    ```
    DATE=$(date +%Y%m%d_%H%M)
    FILENAME="${DATE}_phase_12_ui_copy_rename_pass.md"
    PATH="doc/worklog/${FILENAME}"
    ```

    Use Write tool to create the file at the resolved path. The file MUST follow the worklog.md template structure verbatim:

    ```markdown
    # Phase 12 — UI Copy Rename Pass (ARB values, ja/zh/en)

    **日期:** 2026-05-04
    **时间:** <HH:MM at execution>
    **任务类型:** 文档 + 重构 (UI Copy Rename + ADR + Picker Icon)
    **状态:** 已完成
    **相关模块:** v1.1 milestone Phase 12 / RENAME-01..07 / ADR-015

    ---

    ## 任务概述

    Phase 12 是 v1.1 milestone 收尾 phase: values-only ARB rename + picker icon
    sentiment-positive 升级 + ADR-015 lexical hierarchy 起草并接受 + REQUIREMENTS.md
    spec amendment (RENAME-07). 完全机械化, 无 schema/逻辑/视觉重构。

    ---

    ## 完成的工作

    ### 1. 主要变更 (Plans 01-05)

    **Plan 01 — ARB value rewrites:**
    - 30 value edits across lib/l10n/app_{en,ja,zh}.arb (10 keys × 3 locales)
    - flutter gen-l10n regenerated lib/generated/app_localizations*.dart
    - Register-audit evidence captured in commit body (D-06)
    - Commit: <hash from `git log` of Plan 01>

    **Plan 02 — Picker icon ladder + test labels:**
    - lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart:
      _icons array swapped to D-01 sentiment-positive ladder
    - test/widget/.../satisfaction_emoji_picker_test.dart: JP labels updated
    - Commit: <hash from `git log` of Plan 02>

    **Plan 03 — REQUIREMENTS.md amend (RENAME-07):**
    - RENAME-07 bullet appended after RENAME-06
    - Traceability table: 7 RENAME rows
    - Coverage 28 → 29
    - Commit: <hash>

    **Plan 04 — ADR-015 Draft + INDEX update:**
    - docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md created (Draft)
    - INDEX statistics: 14 → 15 ADR; 草稿 3 → 4
    - Phase 11 commit-of-record cited for `homeRingSectionTitleGroup`
    - Commit: <hash>

    **Plan 05 — Phase close (this commit):**
    - Integration verification: ARB parity + gen-l10n + analyze + picker tests all green
    - ADR-015 status flip: 📝 草稿 → ✅ 已接受 (change-log row 1.1 appended)
    - INDEX statistics: 已接受 10 → 11; 草稿 4 → 3
    - This worklog file created

    ### 2. 技术决策

    - **Values-only scope保护**: keys 不动, dead keys (homeHappinessROI/homeSoulFullness)
      仅改值不删 (D-04). Key GC 推迟到 v1.2 (TOOL-V2-02).
    - **Picker UX identity保留**: 5 sentiment-faces, 仅升级到全正向 register; ADR-014 +
      ADR-015 binding 永久禁止再引入 negative-emotion icons.
    - **JP wellbeing-kanji ladder (D-03)**: 無難 → 快適 → 順調 → 満足 → 至福 — 与 ときめき帳 /
      日々の帳 和風文学 register 同列 (拒绝 katakana ニュートラル / 哲学 中性 / 现代 フラット).
    - **CN family-mode anti-collision (ADR-015)**: 「家族的小确幸」 NOT 「家族悦己」 — 防止
      与 personal `soulLedger` 「悦己账本」 命名碰撞 + ADR-012 anti-leaderboard binding 互证.
    - **Voice estimator [3,10] 不动**: ADR-014 D-12 / HAPPY-V2-03 推迟到 v1.2.

    ### 3. 代码变更统计

    - 修改文件: 9 (3 ARB + 4 generated localizations + 1 widget + 1 widget test)
      + 3 docs (REQUIREMENTS.md + ADR-015 new + ADR-000_INDEX.md)
    - 新增文件: 2 (ADR-015 + this worklog)
    - 删除文件: 0
    - ARB 价值改动: 30 (10 keys × 3 locales, keys 不变)
    - Negative-sentiment icon 移除: 4 个 (sentiment_very_dissatisfied + sentiment_dissatisfied)

    ---

    ## 遇到的问题与解决方案

    (Fill in if any during execution; if all plans landed cleanly, write
    "无 — Plans 01-04 sequentially landed; Plan 05 verification + status flip + worklog
    无 surprise.")

    ---

    ## 测试验证

    - [x] ARB key parity test: `flutter test test/architecture/arb_key_parity_test.dart` PASS
    - [x] Picker widget test: `flutter test test/widget/.../satisfaction_emoji_picker_test.dart` 5/5 PASS
    - [x] flutter gen-l10n: 0 warnings
    - [x] flutter analyze lib/: "No issues found"
    - [x] grep gate — soulLedger new values present in all 3 ARB files
    - [x] grep gate — negative-sentiment icons removed from lib/
    - [x] grep gate — RENAME-07 in REQUIREMENTS.md (bullet + traceability)
    - [x] grep gate — ADR-015 in INDEX with ✅ 已接受 status
    - [x] 文档已更新 (ADR-015 + INDEX + REQUIREMENTS.md)

    ---

    ## Git 提交记录

    Phase 12 共 5 个 atomic commits:

    ```
    <Plan 01 hash>  feat(12): rewrite 10 ARB values across en/ja/zh per Phase 12 D-02/D-03/D-05
    <Plan 02 hash>  feat(12): swap picker icons to sentiment-positive ladder + update test labels
    <Plan 03 hash>  docs(12): amend REQUIREMENTS.md to add RENAME-07 spec entry
    <Plan 04 hash>  docs(arch): add ADR-015 Lexical Hierarchy v1.1 (Draft)
    <Plan 05 hash>  docs(12): Phase 12 close — ADR-015 accepted + worklog
    ```

    ---

    ## 后续工作

    Phase 12 完工 = v1.1 milestone 全部 phases (9-12) 完成。下一步:

    - [ ] v1.1 milestone retrospective + tag (`v1.1`)
    - [ ] STATE.md 更新: milestone v1.1 → v1.2 planning; phases 9-12 标记 100% complete
    - [ ] v1.2 milestone start: 优先项 = TOOL-V2-02 (ARB key GC) + HAPPY-V2-03 (voice realignment) + REGISTER-V2-01 (full ARB register polish)
    - [ ] ADR-015 next review: v1.2 milestone start (per ADR-015 §下次Review)

    ---

    ## 参考资源

    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md (D-01..D-08)
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-DISCUSSION-LOG.md
    - docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md
    - docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md
    - docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md
    - docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md
    - .planning/REQUIREMENTS.md (RENAME-01..07 + Traceability)
    - .planning/ROADMAP.md (Phase 12 entry + critical pitfalls)

    ---

    **创建时间:** <date +%Y-%m-%d %H:%M at execution>
    **作者:** Claude planning agent (Opus 4.7 1M context)
    ```

    Substitute `<hash>` placeholders with actual commit SHAs from `git log --oneline | head -10`. Substitute `<HH:MM>` and the trailing creation timestamp with the current execution time.

    Worklog file MUST be at `doc/worklog/` (NOT `docs/worklog/` — this project's actual rule directory is `doc/worklog/` per `.claude/rules/worklog.md` and the existing `doc/worklog/PROJECT_DEVELOPMENT_PLAN.md` reference). Verify by listing the directory:
    ```
    ls -d doc/worklog/ docs/worklog/ 2>/dev/null
    ```
    The path that exists is the right destination. (CONTEXT.md and CLAUDE.md mention both `doc/worklog/` and `docs/worklog/` due to drift; the worklog rule is canonical → use `doc/worklog/`.)
  </action>
  <verify>
    <automated>WORKLOG=$(ls -t doc/worklog/*phase_12_ui_copy_rename* 2>/dev/null | head -1); test -n "$WORKLOG" && wc -l "$WORKLOG" | awk '{exit ($1 < 50)}' && grep -c "Phase 12" "$WORKLOG" && echo PASS</automated>
  </verify>
  <acceptance_criteria>
    - File exists at `doc/worklog/YYYYMMDD_HHMM_phase_12_ui_copy_rename_pass.md` (timestamp prefix matches execution time, snake_case task name)
    - File line count >= 50
    - File contains all 7 standard sections per worklog.md template (任务概述 / 完成的工作 / 遇到的问题... / 测试验证 / Git 提交记录 / 后续工作 / 参考资源)
    - File 测试验证 section has all 9 checkboxes ticked `[x]`
    - File Git 提交记录 section lists 5 commits with actual SHAs (NOT `<hash>` placeholders)
    - File `**作者:**` field present
    - `grep -c "RENAME-01..07" "$WORKLOG"` returns at least 1
    - `grep -c "ADR-015" "$WORKLOG"` returns at least 2
  </acceptance_criteria>
  <done>Phase 12 worklog file created with all template sections populated.</done>
</task>

<task type="auto">
  <name>Task 5: Commit Phase 12 close — ADR-015 acceptance + worklog</name>
  <files>(git commit only)</files>
  <read_first>
    - .claude/rules/git-workflow.md
    - .claude/rules/arch.md (commit subject convention for arch docs)
  </read_first>
  <action>
    Stage exactly 3 files:
    - `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md`
    - `docs/arch/03-adr/ADR-000_INDEX.md`
    - `doc/worklog/YYYYMMDD_HHMM_phase_12_ui_copy_rename_pass.md` (resolved actual filename)

    Commit:

    ```
    docs(12): Phase 12 close — ADR-015 accepted + worklog

    Phase 12 (UI Copy Rename Pass) close-out commit. Plans 01-04 verified to
    compose cleanly:
    - ARB key parity test PASS
    - flutter gen-l10n: 0 warnings
    - flutter analyze lib/: 0 issues
    - satisfaction_emoji_picker_test.dart: 5/5 PASS
    - All grep gates green (new ARB values, no negative-sentiment icons,
      RENAME-07 in REQUIREMENTS.md, ADR-015 in INDEX)

    Changes in this commit:
    - ADR-015 status flip: 📝 草稿 → ✅ 已接受 (change-log row 1.1 appended)
    - ADR-000_INDEX.md statistics: 已接受 10→11; 草稿 4→3 (总计 unchanged 15)
    - doc/worklog/<TIMESTAMP>_phase_12_ui_copy_rename_pass.md created

    v1.1 milestone Phase 12 = COMPLETE. RENAME-01..07 all delivered. Next step
    is v1.1 milestone retrospective + tag.

    Refs: D-07, D-08; RENAME-01..07; ADR-015 acceptance
    ```

    DO NOT use `git add -A`. Stage only the 3 files.
  </action>
  <verify>
    <automated>git diff HEAD~1 --stat | wc -l | awk '{exit ($1 < 3)}' && git log -1 --pretty=format:"%s" | grep -q "docs(12).*Phase 12 close.*ADR-015 accepted" && echo PASS || echo FAIL</automated>
  </verify>
  <acceptance_criteria>
    - Commit subject: `docs(12): Phase 12 close — ADR-015 accepted + worklog`
    - `git diff HEAD~1 --stat` shows exactly 3 files (ADR-015, INDEX, worklog)
    - Commit body references D-07, D-08, RENAME-01..07
    - `git status` clean post-commit
    - `git log --oneline | head -5 | grep -c "(12)\\|adr.*ADR-015\\|RENAME"` returns 5 (Phase 12's full commit chain visible)
  </acceptance_criteria>
  <done>Phase 12 closed atomically with ADR acceptance + worklog provenance.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Phase 12 close → v1.1 milestone retrospective | Worklog + ADR acceptance status are inputs to milestone retrospective; integrity matters for downstream auditing. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-12-12 | Tampering | ADR-015 substantive sections accidentally edited during status flip | mitigate | Task 2 acceptance gates "diff vs Plan 04 commit shows exactly 2 line changes"; Append-only protocol declared in ADR-015 §10. |
| T-12-13 | Repudiation | Phase 12 close commit references commit SHAs that do not exist | mitigate | Task 4 worklog template MUST be filled with `git log --oneline | head -10` actual SHAs; Task 5 acceptance verifies the 5-commit chain. |
| T-12-14 | Denial of service | Verification fails mid-flip (ADR partially accepted, INDEX still showing Draft) | mitigate | Task 1 runs ALL verification BEFORE any edits; if Task 1 fails, executor STOPs without touching files. |
</threat_model>

<verification>
- All Plans 01-04 verifications still green (Task 1 acceptance)
- ADR-015 status `✅ 已接受`, change-log row 1.1 added (Task 2)
- INDEX statistics updated: 已接受 11 / 草稿 3 / 总计 15 (Task 3)
- Worklog file created at `doc/worklog/...` ≥ 50 lines, all template sections (Task 4)
- Single commit `docs(12): Phase 12 close — ADR-015 accepted + worklog` affecting exactly 3 files (Task 5)
- v1.1 Phase 12 = COMPLETE; ready for milestone retrospective
</verification>

<success_criteria>
- ADR-015 fully Accepted (badge + change log)
- INDEX consistent
- Worklog generated per project rules
- Phase 12 chain of 5 commits visible in `git log`
</success_criteria>

<output>
After completion, create `.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-05-SUMMARY.md` summarizing:
- Verification matrix (all 9 gates green)
- ADR-015 status flip details (badge + change-log row)
- INDEX statistics math (10→11 已接受 / 4→3 草稿)
- Worklog filename + key sections
- Full Phase 12 commit chain (5 SHAs)
- Confirmation that v1.1 milestone Phase 12 is COMPLETE
</output>
