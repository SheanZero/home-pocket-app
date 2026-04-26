---
phase: 03-critical-fixes
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/family_sync/use_cases/check_group_use_case.dart
  - lib/application/family_sync/check_group_use_case.dart
  - lib/features/family_sync/use_cases/deactivate_group_use_case.dart
  - lib/application/family_sync/deactivate_group_use_case.dart
  - lib/features/family_sync/use_cases/leave_group_use_case.dart
  - lib/application/family_sync/leave_group_use_case.dart
  - lib/features/family_sync/use_cases/regenerate_invite_use_case.dart
  - lib/application/family_sync/regenerate_invite_use_case.dart
  - lib/features/family_sync/use_cases/remove_member_use_case.dart
  - lib/application/family_sync/remove_member_use_case.dart
  - lib/features/family_sync/import_guard.yaml
  - test/unit/features/family_sync/use_cases/check_group_use_case_test.dart
  - test/unit/application/family_sync/check_group_use_case_test.dart
  - test/unit/features/family_sync/use_cases/deactivate_group_use_case_test.dart
  - test/unit/application/family_sync/deactivate_group_use_case_test.dart
  - test/unit/features/family_sync/use_cases/leave_group_use_case_test.dart
  - test/unit/application/family_sync/leave_group_use_case_test.dart
  - test/unit/features/family_sync/use_cases/regenerate_invite_use_case_test.dart
  - test/unit/application/family_sync/regenerate_invite_use_case_test.dart
  - test/unit/features/family_sync/use_cases/remove_member_use_case_test.dart
  - test/unit/application/family_sync/remove_member_use_case_test.dart
autonomous: true
requirements:
  - CRIT-01
  - CRIT-02
  - CRIT-05
  - CRIT-06
tags:
  - use_cases_migration
  - thin_feature_rule
  - critical_fixes
must_haves:
  truths:
    - "lib/features/family_sync/use_cases/ directory no longer exists; all 5 use-case source files moved to lib/application/family_sync/ preserving filenames per CONTEXT.md D-09"
    - "All 5 corresponding test files moved from test/unit/features/family_sync/use_cases/ to test/unit/application/family_sync/ preserving filenames"
    - "Each move is an atomic per-file commit using git mv (5 commits total) for review/bisect granularity per CONTEXT.md D-09; per-file PR also updates the file's relative imports from 3-up to 2-up since the file moves up the tree"
    - "All 5 callers (presentation/screens/group_management_screen.dart + siblings) updated to import the new package:home_pocket/application/family_sync/<name>.dart paths; flutter analyze exits 0 after each per-file commit"
    - "5 LV findings (LV-017..LV-021) closed in issues.json with closed_in_phase: 3"
    - "Per CONTEXT.md D-10 literal compliance: a `lib/features/family_sync/import_guard.yaml` is added that explicitly denies any future re-creation of `use_cases/` underneath this feature. The pre-existing global `lib/features/import_guard.yaml` deny rule (`package:home_pocket/features/*/use_cases/**`) remains in place AND is supplemented by the feature-scoped rule per D-10's wording (`a features/family_sync/ import_guard rule is added that explicitly denies any future re-creation of use_cases/ underneath features`)."
    - "After the move + directory deletion + new feature-scoped yaml, dart run custom_lint exits 0 with no new violations and no regression of either the global or the feature-scoped deny rule"
    - "git log --follow lib/application/family_sync/<name>.dart shows pre-move history (rename detection succeeds because each per-file PR is git mv + minimal import-path adjustment ONLY, no behavior changes — RESEARCH.md Pitfall 5)"
    - "Existing *.mocks.dart files associated with the migrated tests are kept as-is (CONTEXT.md <deferred> — Phase 4 HIGH-07 owns the Mocktail migration decision)"
    - "Operational repo lock per Phase 2 D-07 / D-16 active throughout; Wave 1 — runs in parallel with Plans 03-01, 03-04, 03-05 (no shared source-file dependencies)"
    - "Every touched file in Phase 3 Plan 03 ∩ files-needing-tests.txt reaches >=80% coverage via coverage_gate.dart per CONTEXT.md D-15. Specifically: deactivate_group_use_case.dart (line 70 of files-needing-tests.txt), regenerate_invite_use_case.dart (line 71), remove_member_use_case.dart (line 72) need new tests written by Plan 03-05 BEFORE the corresponding move commit lands"
  artifacts:
    - path: "lib/application/family_sync/check_group_use_case.dart"
      provides: "Migrated use case (formerly at lib/features/family_sync/use_cases/)"
      contains: "class CheckGroupUseCase"
    - path: "lib/application/family_sync/deactivate_group_use_case.dart"
      provides: "Migrated use case"
      contains: "class DeactivateGroupUseCase"
    - path: "lib/application/family_sync/leave_group_use_case.dart"
      provides: "Migrated use case"
      contains: "class LeaveGroupUseCase"
    - path: "lib/application/family_sync/regenerate_invite_use_case.dart"
      provides: "Migrated use case"
      contains: "class RegenerateInviteUseCase"
    - path: "lib/application/family_sync/remove_member_use_case.dart"
      provides: "Migrated use case"
      contains: "class RemoveMemberUseCase"
    - path: "lib/features/family_sync/import_guard.yaml"
      provides: "Feature-scoped deny rule per D-10 — explicitly denies future re-creation of use_cases/ underneath family_sync"
      contains: "deny:"
  key_links:
    - from: "callers under lib/features/family_sync/presentation/"
      to: "lib/application/family_sync/<name>.dart"
      via: "import 'package:home_pocket/application/family_sync/<name>.dart'"
      pattern: "package:home_pocket/application/family_sync/"
    - from: "lib/features/family_sync/import_guard.yaml"
      to: "lib/features/import_guard.yaml"
      via: "inherit: true (feature-scoped deny composes with parent global deny)"
      pattern: "inherit:\\s*true"
---

<objective>
Close LV-017..LV-021 (5 of the 24 CRITICAL layer-violation findings) and CRIT-02 by migrating 5 use-case files from `lib/features/family_sync/use_cases/` to `lib/application/family_sync/` per CONTEXT.md D-09. Each file moves atomically via `git mv` (5 commits, one per file), preserving filenames. The corresponding test files in `test/unit/features/family_sync/use_cases/` move alongside to `test/unit/application/family_sync/`. After all 5 moves land, the now-empty `lib/features/family_sync/use_cases/` directory is deleted. Per CONTEXT.md D-10 literal compliance, a NEW `lib/features/family_sync/import_guard.yaml` is added that explicitly denies any future re-creation of `use_cases/` underneath this feature. The pre-existing global `lib/features/import_guard.yaml` deny rule already provides a project-wide ban; the feature-scoped rule supplements it as D-10 literally requires.

The migration is a **pure refactor**: file content stays byte-identical except for relative-import-path adjustments (the file moves up the tree by 1 level relative to the project root, so `import '../../../infrastructure/...';` becomes `import '../../infrastructure/...';` and `import '../domain/models/group_member.dart';` becomes `import '../../features/family_sync/domain/models/group_member.dart';`). Existing `*.mocks.dart` files associated with the migrated tests stay as-is (Phase 4 HIGH-07 owns the Mocktail/Mockito strategy decision per CONTEXT.md `<deferred>`).

Purpose: Restore CLAUDE.md "Thin Feature" rule for family_sync, close 5 of the LV findings ahead of the Phase 3 close blocking flip in Plan 03-01 Task 4, and satisfy D-10's literal wording ("a features/family_sync/ import_guard rule is added that explicitly denies any future re-creation of use_cases/ underneath features") by shipping the feature-scoped yaml as a new Task 6.

Output:
- 5 source files moved (`git mv`)
- 5 test files moved (`git mv`)
- All importers updated (presentation screens, providers, sibling tests)
- `lib/features/family_sync/use_cases/` directory deleted
- `lib/features/family_sync/import_guard.yaml` NEW (feature-scoped deny per D-10)
- 5 LV findings flipped from open → closed in `issues.json`
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/03-critical-fixes/03-CONTEXT.md
@.planning/phases/03-critical-fixes/03-RESEARCH.md
@.planning/phases/03-critical-fixes/03-PATTERNS.md
@.planning/phases/03-critical-fixes/03-VALIDATION.md
@.planning/audit/issues.json
@.planning/audit/REPO-LOCK-POLICY.md
@CLAUDE.md

<interfaces>
<!-- Embedded contracts. -->

## Source files to migrate (5)

| Old path | New path | Closes |
|---|---|---|
| lib/features/family_sync/use_cases/check_group_use_case.dart | lib/application/family_sync/check_group_use_case.dart | LV-017 |
| lib/features/family_sync/use_cases/deactivate_group_use_case.dart | lib/application/family_sync/deactivate_group_use_case.dart | LV-018 |
| lib/features/family_sync/use_cases/leave_group_use_case.dart | lib/application/family_sync/leave_group_use_case.dart | LV-019 |
| lib/features/family_sync/use_cases/regenerate_invite_use_case.dart | lib/application/family_sync/regenerate_invite_use_case.dart | LV-020 |
| lib/features/family_sync/use_cases/remove_member_use_case.dart | lib/application/family_sync/remove_member_use_case.dart | LV-021 |

## Test files to migrate (5)

| Old path | New path |
|---|---|
| test/unit/features/family_sync/use_cases/check_group_use_case_test.dart | test/unit/application/family_sync/check_group_use_case_test.dart |
| test/unit/features/family_sync/use_cases/deactivate_group_use_case_test.dart | test/unit/application/family_sync/deactivate_group_use_case_test.dart |
| test/unit/features/family_sync/use_cases/leave_group_use_case_test.dart | test/unit/application/family_sync/leave_group_use_case_test.dart |
| test/unit/features/family_sync/use_cases/regenerate_invite_use_case_test.dart | test/unit/application/family_sync/regenerate_invite_use_case_test.dart |
| test/unit/features/family_sync/use_cases/remove_member_use_case_test.dart | test/unit/application/family_sync/remove_member_use_case_test.dart |

## Existing destination — `lib/application/family_sync/` (17 sibling files already use `_use_case.dart` suffix)

apply_sync_operations_use_case.dart, check_group_validity_use_case.dart, confirm_join_use_case.dart, confirm_member_use_case.dart, create_group_use_case.dart, full_sync_use_case.dart, handle_group_dissolved_use_case.dart, handle_member_left_use_case.dart, join_group_use_case.dart, pull_sync_use_case.dart, push_sync_use_case.dart, rename_group_use_case.dart, shadow_book_service.dart, sync_avatar_use_case.dart, sync_engine.dart, sync_orchestrator.dart, transaction_change_tracker.dart

The 5 incoming filenames already match the convention; **no rename needed**.

## Import-path rewrite rules (from RESEARCH.md §4 + PATTERNS.md §"family_sync use_case moves")

For each migrated source file:

| Pattern in old file (under `features/family_sync/use_cases/`) | Pattern in new file (under `application/family_sync/`) |
|--------------------------------------------------------------|--------------------------------------------------------|
| `import '../../../infrastructure/<X>';` (3 levels up) | `import '../../infrastructure/<X>';` (2 levels up) |
| `import '../../../data/<X>';` (3 up) | `import '../../data/<X>';` (2 up) |
| `import '../../../core/<X>';` (3 up) | `import '../../core/<X>';` (2 up) |
| `import '../domain/repositories/<X>';` (relative to feature) | `import '../../features/family_sync/domain/repositories/<X>';` (cross-feature) |
| `import '../domain/models/<X>';` | `import '../../features/family_sync/domain/models/<X>';` |
| `import 'package:home_pocket/...';` (absolute) | unchanged |

For each migrated test file: same rules + the production-file import `import 'package:home_pocket/features/family_sync/use_cases/<name>.dart';` becomes `import 'package:home_pocket/application/family_sync/<name>.dart';`.

## Caller files to update (importers)

After each per-file move, find callers via:
`grep -rln "family_sync/use_cases/<name_being_moved>" lib/ test/`

Known importer prefixes per RESEARCH.md §4:
- lib/features/family_sync/presentation/screens/group_management_screen.dart
- lib/features/family_sync/presentation/providers/repository_providers.dart (if any)
- lib/features/family_sync/presentation/providers/group_providers.dart (if any)
- Sibling tests in test/widget/family_sync/ if any

Update each caller's import path to: `import 'package:home_pocket/application/family_sync/<name>.dart';`.

## Pre-move sanity (RESEARCH.md A6)

`grep -rE "^library |^part of " lib/features/family_sync/use_cases/` must return empty (no `library` / `part of` directives that would break on `git mv`).

## CONTEXT.md D-10 — final cleanup + feature-scoped deny rule

After all 5 file moves merge, the empty `lib/features/family_sync/use_cases/` directory is deleted in a 6th cleanup commit. The deny rule in `lib/features/import_guard.yaml` (`package:home_pocket/features/*/use_cases/**`) stays in place permanently — RESEARCH.md notes Phase 7 may revisit.

**Per D-10 literal wording, this plan ALSO ships a NEW `lib/features/family_sync/import_guard.yaml`** (Task 6) that scopes the deny rule to `family_sync/` itself. The schema mirrors the existing `lib/features/import_guard.yaml` (deny list using `package:home_pocket/...` glob patterns + `inherit: true`). This satisfies D-10 verbatim: "a features/family_sync/ import_guard rule is added that explicitly denies any future re-creation of use_cases/ underneath features."

## Existing schema reference — `lib/features/import_guard.yaml` (DO NOT MODIFY in this plan)

```yaml
# lib/features/import_guard.yaml — Thin Feature rule (CLAUDE.md "Thin Feature Rule")
# Catches the live CRIT-02 violation in lib/features/family_sync/use_cases/
# (per .planning/codebase/CONCERNS.md).
deny:
  - package:home_pocket/features/*/use_cases/**
  - package:home_pocket/features/*/application/**
  - package:home_pocket/features/*/infrastructure/**
  - package:home_pocket/features/*/data/**

inherit: true
```

The new feature-scoped yaml uses the SAME schema (deny + inherit:true), with patterns scoped to `family_sync` specifically.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Pre-move sanity check + migrate `check_group_use_case.dart` (LV-017) — source + test</name>
  <files>
    lib/features/family_sync/use_cases/check_group_use_case.dart,
    lib/application/family_sync/check_group_use_case.dart,
    test/unit/features/family_sync/use_cases/check_group_use_case_test.dart,
    test/unit/application/family_sync/check_group_use_case_test.dart
  </files>
  <read_first>
    - lib/features/family_sync/use_cases/check_group_use_case.dart (current state — full file, including all imports, to map relative paths to new positions)
    - test/unit/features/family_sync/use_cases/check_group_use_case_test.dart (current state — to map test imports including the production-file import)
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Common Pitfalls" #5 — `git mv` followed by manual edits in same commit; A6 — no `library`/`part of` directives)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"family_sync use_case moves" — full template)
    - lib/application/family_sync/push_sync_use_case.dart (sibling reference for what 2-up imports look like)
  </read_first>
  <action>
    **Step 1 — pre-move sanity (run once for all 5 files):** run `grep -rE "^library |^part of " lib/features/family_sync/use_cases/`. Expected: empty output. If any directive is found, STOP and surface to orchestrator — `git mv` may not preserve history cleanly.

    **Step 2 — `git mv` source file:** `git mv lib/features/family_sync/use_cases/check_group_use_case.dart lib/application/family_sync/check_group_use_case.dart`.

    **Step 3 — adjust imports inside the moved source file** per the rewrite table in `<interfaces>`. Open `lib/application/family_sync/check_group_use_case.dart`. For every `import '../../../<X>';` line (3 levels up), change to `import '../../<X>';` (2 up). For every `import '../domain/<X>';` line, change to `import '../../features/family_sync/domain/<X>';`. Keep `import 'package:...';` unchanged. Keep all class/function bodies byte-identical (no logic changes — RESEARCH.md Pitfall 5).

    **Step 4 — `git mv` test file:** `git mv test/unit/features/family_sync/use_cases/check_group_use_case_test.dart test/unit/application/family_sync/check_group_use_case_test.dart`.

    **Step 5 — adjust imports inside the moved test file.** Open `test/unit/application/family_sync/check_group_use_case_test.dart`. Update the production-file import:
    - From: `import 'package:home_pocket/features/family_sync/use_cases/check_group_use_case.dart';`
    - To: `import 'package:home_pocket/application/family_sync/check_group_use_case.dart';`
    Other imports (mocktail, mockito, freezed_annotation, etc.) stay unchanged. If the test uses Mockito codegen (`*.mocks.dart` part-of), keep `*.mocks.dart` as-is per CONTEXT.md `<deferred>` (Phase 4 HIGH-07 owns the strategy). If a `*.mocks.dart` file lives next to the moved test, also `git mv` it to the new location alongside the test.

    **Step 6 — find and update all callers of `check_group_use_case.dart`.** Run `grep -rln "family_sync/use_cases/check_group_use_case" lib/ test/`. For each match, edit the import path from the `features/family_sync/use_cases/` form (or relative variant) to `package:home_pocket/application/family_sync/check_group_use_case.dart`. Save.

    **Step 7 — verify and commit atomically.** Run in order, all must exit 0:
    1. `flutter analyze --no-fatal-infos`
    2. `flutter test test/unit/application/family_sync/check_group_use_case_test.dart`
    3. `git diff --stat` — confirm only the 5 files (source + test + 1-3 callers + maybe mocks file) appear
    4. `git diff -M --name-status lib/application/family_sync/check_group_use_case.dart` — expect `R100` or near-100 rename score

    Commit with message: `refactor(03-03): move check_group_use_case to lib/application/family_sync (LV-017)`.

    **Step 8 — close LV-017 in issues.json**: flip `"id": "LV-017"` from `"status": "open"` to `"status": "closed"`, add `"closed_in_phase": 3`, `"closed_commit": "<short-sha>"`.
  </action>
  <verify>
    <automated>flutter analyze --no-fatal-infos &amp;&amp; flutter test test/unit/application/family_sync/check_group_use_case_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `! test -f lib/features/family_sync/use_cases/check_group_use_case.dart` exits 0 (source moved)
    - `test -f lib/application/family_sync/check_group_use_case.dart` exits 0
    - `grep -q "class CheckGroupUseCase" lib/application/family_sync/check_group_use_case.dart` exits 0
    - `! test -f test/unit/features/family_sync/use_cases/check_group_use_case_test.dart` exits 0
    - `test -f test/unit/application/family_sync/check_group_use_case_test.dart` exits 0
    - `grep -q "package:home_pocket/application/family_sync/check_group_use_case.dart" test/unit/application/family_sync/check_group_use_case_test.dart` exits 0 (test import rewritten)
    - `grep -rln "family_sync/use_cases/check_group_use_case" lib/ test/` returns no output (zero stale references)
    - `flutter analyze --no-fatal-infos` exits 0
    - `flutter test test/unit/application/family_sync/check_group_use_case_test.dart` exits 0
    - `jq -r '.findings[] | select(.id == "LV-017") | .status' .planning/audit/issues.json` returns `closed`
  </acceptance_criteria>
  <done>check_group_use_case.dart + test moved with all importers updated; LV-017 closed; commit is atomic per RESEARCH.md Pitfall 5.</done>
</task>

<task type="auto">
  <name>Task 2: Migrate `deactivate_group_use_case.dart` (LV-018) — source + test</name>
  <files>
    lib/features/family_sync/use_cases/deactivate_group_use_case.dart,
    lib/application/family_sync/deactivate_group_use_case.dart,
    test/unit/features/family_sync/use_cases/deactivate_group_use_case_test.dart,
    test/unit/application/family_sync/deactivate_group_use_case_test.dart
  </files>
  <read_first>
    - lib/features/family_sync/use_cases/deactivate_group_use_case.dart (full source — to map imports)
    - test/unit/features/family_sync/use_cases/deactivate_group_use_case_test.dart (full test — to map imports)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"family_sync use_case moves")
    - The Plan 03-05 SUMMARY (this file is in `files-needing-tests.txt` line 70 — Plan 03-05 may have written a characterization test for this file BEFORE the move)
  </read_first>
  <action>
    Apply the SAME 8-step procedure as Task 1, substituting `deactivate_group_use_case` for `check_group_use_case` and `LV-018` for `LV-017`.

    Per CONTEXT.md D-15 strict ≥80% coverage: this file IS in `files-needing-tests.txt` (line 70). Plan 03-05 must have written/extended its characterization test BEFORE this commit lands. If `flutter test` fails on the moved test or coverage drops below 80% post-move, STOP and coordinate with Plan 03-05.

    Commit message: `refactor(03-03): move deactivate_group_use_case to lib/application/family_sync (LV-018)`.

    Close LV-018 in issues.json (status -> closed, closed_in_phase: 3, closed_commit: short-sha).
  </action>
  <verify>
    <automated>flutter analyze --no-fatal-infos &amp;&amp; flutter test test/unit/application/family_sync/deactivate_group_use_case_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `! test -f lib/features/family_sync/use_cases/deactivate_group_use_case.dart` exits 0
    - `test -f lib/application/family_sync/deactivate_group_use_case.dart` exits 0
    - `grep -q "class DeactivateGroupUseCase" lib/application/family_sync/deactivate_group_use_case.dart` exits 0
    - `grep -rln "family_sync/use_cases/deactivate_group_use_case" lib/ test/` returns no output
    - `flutter test test/unit/application/family_sync/deactivate_group_use_case_test.dart` exits 0
    - `jq -r '.findings[] | select(.id == "LV-018") | .status' .planning/audit/issues.json` returns `closed`
  </acceptance_criteria>
  <done>deactivate_group_use_case migrated; LV-018 closed; touched-file coverage >=80% (verified by Plan 03-05 pre-tests + post-move re-run).</done>
</task>

<task type="auto">
  <name>Task 3: Migrate `leave_group_use_case.dart` (LV-019) — source + test</name>
  <files>
    lib/features/family_sync/use_cases/leave_group_use_case.dart,
    lib/application/family_sync/leave_group_use_case.dart,
    test/unit/features/family_sync/use_cases/leave_group_use_case_test.dart,
    test/unit/application/family_sync/leave_group_use_case_test.dart
  </files>
  <read_first>
    - lib/features/family_sync/use_cases/leave_group_use_case.dart (full source)
    - test/unit/features/family_sync/use_cases/leave_group_use_case_test.dart (full test)
    - .planning/phases/03-critical-fixes/03-PATTERNS.md (§"family_sync use_case moves")
  </read_first>
  <action>
    Apply the SAME 8-step procedure as Task 1, substituting `leave_group_use_case` and `LV-019`.

    Note: this file is NOT in `files-needing-tests.txt` (not lines 70-72). Existing test stays GREEN; coverage carry-over from pre-Phase-3 is sufficient (D-15 strict still applies — pure renames count as touched and existing tests must still pass).

    Commit message: `refactor(03-03): move leave_group_use_case to lib/application/family_sync (LV-019)`.

    Close LV-019 in issues.json.
  </action>
  <verify>
    <automated>flutter analyze --no-fatal-infos &amp;&amp; flutter test test/unit/application/family_sync/leave_group_use_case_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `! test -f lib/features/family_sync/use_cases/leave_group_use_case.dart` exits 0
    - `test -f lib/application/family_sync/leave_group_use_case.dart` exits 0
    - `grep -q "class LeaveGroupUseCase" lib/application/family_sync/leave_group_use_case.dart` exits 0
    - `grep -rln "family_sync/use_cases/leave_group_use_case" lib/ test/` returns no output
    - `flutter test test/unit/application/family_sync/leave_group_use_case_test.dart` exits 0
    - `jq -r '.findings[] | select(.id == "LV-019") | .status' .planning/audit/issues.json` returns `closed`
  </acceptance_criteria>
  <done>leave_group_use_case migrated; LV-019 closed.</done>
</task>

<task type="auto">
  <name>Task 4: Migrate `regenerate_invite_use_case.dart` (LV-020) — source + test</name>
  <files>
    lib/features/family_sync/use_cases/regenerate_invite_use_case.dart,
    lib/application/family_sync/regenerate_invite_use_case.dart,
    test/unit/features/family_sync/use_cases/regenerate_invite_use_case_test.dart,
    test/unit/application/family_sync/regenerate_invite_use_case_test.dart
  </files>
  <read_first>
    - lib/features/family_sync/use_cases/regenerate_invite_use_case.dart
    - test/unit/features/family_sync/use_cases/regenerate_invite_use_case_test.dart
    - .planning/phases/03-critical-fixes/03-PATTERNS.md
  </read_first>
  <action>
    Apply the SAME 8-step procedure as Task 1, substituting `regenerate_invite_use_case` and `LV-020`.

    Per CONTEXT.md D-15: this file IS in `files-needing-tests.txt` (line 71). Plan 03-05 must have written its characterization test BEFORE this commit lands.

    Commit message: `refactor(03-03): move regenerate_invite_use_case to lib/application/family_sync (LV-020)`.

    Close LV-020 in issues.json.
  </action>
  <verify>
    <automated>flutter analyze --no-fatal-infos &amp;&amp; flutter test test/unit/application/family_sync/regenerate_invite_use_case_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `! test -f lib/features/family_sync/use_cases/regenerate_invite_use_case.dart` exits 0
    - `test -f lib/application/family_sync/regenerate_invite_use_case.dart` exits 0
    - `grep -q "class RegenerateInviteUseCase" lib/application/family_sync/regenerate_invite_use_case.dart` exits 0
    - `grep -rln "family_sync/use_cases/regenerate_invite_use_case" lib/ test/` returns no output
    - `flutter test test/unit/application/family_sync/regenerate_invite_use_case_test.dart` exits 0
    - `jq -r '.findings[] | select(.id == "LV-020") | .status' .planning/audit/issues.json` returns `closed`
  </acceptance_criteria>
  <done>regenerate_invite_use_case migrated; LV-020 closed.</done>
</task>

<task type="auto">
  <name>Task 5: Migrate `remove_member_use_case.dart` (LV-021) + delete empty `use_cases/` directory + final-plan verify</name>
  <files>
    lib/features/family_sync/use_cases/remove_member_use_case.dart,
    lib/application/family_sync/remove_member_use_case.dart,
    test/unit/features/family_sync/use_cases/remove_member_use_case_test.dart,
    test/unit/application/family_sync/remove_member_use_case_test.dart
  </files>
  <read_first>
    - lib/features/family_sync/use_cases/remove_member_use_case.dart
    - test/unit/features/family_sync/use_cases/remove_member_use_case_test.dart
    - .planning/phases/03-critical-fixes/03-PATTERNS.md
    - .planning/phases/03-critical-fixes/03-CONTEXT.md (D-10 — final cleanup deletes empty directory)
    - .planning/audit/files-needing-tests.txt (line 72 — remove_member_use_case.dart needs a test from Plan 03-05)
  </read_first>
  <action>
    **Step 1 — apply the SAME 8-step procedure as Task 1**, substituting `remove_member_use_case` and `LV-021`.

    Per CONTEXT.md D-15: this file IS in `files-needing-tests.txt` (line 72).

    Commit message: `refactor(03-03): move remove_member_use_case to lib/application/family_sync (LV-021)`.

    Close LV-021 in issues.json.

    **Step 2 — delete the now-empty `lib/features/family_sync/use_cases/` directory** (CONTEXT.md D-10):
    1. Confirm empty: `ls -A lib/features/family_sync/use_cases/` returns no output.
    2. Run `rmdir lib/features/family_sync/use_cases/` (or `git rm -r` if tracked).
    3. If `test/unit/features/family_sync/use_cases/` is also now empty, `rmdir` it too.
    4. Commit with message: `chore(03-03): remove empty lib/features/family_sync/use_cases/ directory (CRIT-02 close)`.

    **Step 3 — final per-plan exit gate.** Build the touched-files list at `/tmp/phase3-plan03-touched.txt` containing exactly these 5 lines:
    ```
    lib/application/family_sync/check_group_use_case.dart
    lib/application/family_sync/deactivate_group_use_case.dart
    lib/application/family_sync/leave_group_use_case.dart
    lib/application/family_sync/regenerate_invite_use_case.dart
    lib/application/family_sync/remove_member_use_case.dart
    ```

    Run, in order, all must exit 0:
    1. `flutter analyze --no-fatal-infos`
    2. `dart run custom_lint`
    3. `flutter test`
    4. `flutter test --coverage`
    5. `coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --mode w --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'`
    6. `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan03-touched.txt --threshold 80 --lcov coverage/lcov_clean.info`

    If `coverage_gate.dart` flags any file <80% (esp. deactivate/regenerate/remove_member that need Plan 03-05's tests), surface to orchestrator.

    **Step 4 — verify CRIT-02 closure note** in plan summary: `lib/features/family_sync/use_cases/` directory does not exist; the deny rule in `lib/features/import_guard.yaml` (line 5: `package:home_pocket/features/*/use_cases/**`) prevents future re-creation. Note that Task 6 (next) adds the feature-scoped supplement per D-10.
  </action>
  <verify>
    <automated>flutter analyze --no-fatal-infos &amp;&amp; dart run custom_lint &amp;&amp; flutter test &amp;&amp; dart run scripts/coverage_gate.dart --list /tmp/phase3-plan03-touched.txt --threshold 80 --lcov coverage/lcov_clean.info</automated>
  </verify>
  <acceptance_criteria>
    - `! test -d lib/features/family_sync/use_cases` exits 0 (directory deleted)
    - `! test -f lib/features/family_sync/use_cases/remove_member_use_case.dart` exits 0
    - `test -f lib/application/family_sync/remove_member_use_case.dart` exits 0
    - `grep -q "class RemoveMemberUseCase" lib/application/family_sync/remove_member_use_case.dart` exits 0
    - `grep -rln "family_sync/use_cases/" lib/ test/` returns no output (zero stale references)
    - `flutter analyze --no-fatal-infos` exits 0
    - `dart run custom_lint` exits 0
    - `flutter test` exits 0 (full suite GREEN)
    - `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan03-touched.txt --threshold 80 --lcov coverage/lcov_clean.info` exits 0
    - `jq -r '.findings[] | select(.id == "LV-021") | .status' .planning/audit/issues.json` returns `closed`
    - `jq '[.findings[] | select(.severity == "CRITICAL" and .status == "open" and (.id | startswith("LV-")) and (.id != "LV-022"))] | length' .planning/audit/issues.json` returns at most 0 (LV-017..LV-021 all closed; LV-022 closes via Plan 03-04; LV-001..016/023/024 close via Plan 03-01)
  </acceptance_criteria>
  <done>All 5 use-case files migrated; `lib/features/family_sync/use_cases/` directory deleted; LV-017..LV-021 closed; CRIT-02 closed; full suite + coverage gate GREEN.</done>
</task>

<task type="auto">
  <name>Task 6: Add feature-scoped `lib/features/family_sync/import_guard.yaml` per CONTEXT.md D-10 literal compliance</name>
  <files>
    lib/features/family_sync/import_guard.yaml
  </files>
  <read_first>
    - lib/features/import_guard.yaml (existing global deny — schema reference; DO NOT modify, only mirror its format)
    - .planning/phases/03-critical-fixes/03-CONTEXT.md (§"### `use_cases/` migration (LV-017..LV-021 — 5 findings)" D-10 verbatim wording: "a features/family_sync/ import_guard rule is added that explicitly denies any future re-creation of `use_cases/` underneath features")
    - .planning/phases/03-critical-fixes/03-RESEARCH.md (§"Pattern 1" — import_guard_custom_lint config inheritance semantics; same engine that enforces lib/features/<f>/domain/import_guard.yaml will enforce this feature-scoped yaml)
    - .planning/audit/issues.json (LV-017..LV-021 closure rows — the new yaml provides the structural guarantee that future re-creations are blocked feature-by-feature, not only by the global rule)
  </read_first>
  <action>
    **GATING CONDITION** — this task runs AFTER Task 5 lands (the directory deletion + 5 use_case migrations are merged). The new yaml is the FINAL commit of Plan 03-03.

    **Step 1 — confirm the existing global deny rule** at `lib/features/import_guard.yaml`. It already denies `package:home_pocket/features/*/use_cases/**`. Do NOT modify it.

    **Step 2 — write the new feature-scoped yaml** at `lib/features/family_sync/import_guard.yaml` with EXACTLY this content (mirroring the schema of the existing `lib/features/import_guard.yaml`):

    ```yaml
    # lib/features/family_sync/import_guard.yaml — feature-scoped Thin Feature rule.
    #
    # Per Phase 3 CONTEXT.md D-10 (verbatim): "a features/family_sync/ import_guard
    # rule is added that explicitly denies any future re-creation of use_cases/
    # underneath features."
    #
    # Closes LV-017..LV-021. The global rule at lib/features/import_guard.yaml
    # already denies package:home_pocket/features/*/use_cases/** project-wide;
    # this feature-scoped supplement satisfies D-10 literally and gives
    # contributors a discoverable, family_sync-local signal that use_cases/
    # belong in lib/application/family_sync/, not under this feature.
    deny:
      - package:home_pocket/features/family_sync/use_cases/**
      - package:home_pocket/features/family_sync/application/**
      - package:home_pocket/features/family_sync/infrastructure/**
      - package:home_pocket/features/family_sync/data/**

    inherit: true
    ```

    **Step 3 — verify the lint passes from cold start** (per RESEARCH.md Pitfall 6 cache-invalidation rule):
    ```bash
    rm -rf .dart_tool
    flutter pub get
    dart run custom_lint
    ```
    Expected: exits 0. The new feature-scoped yaml composes with the global deny and the inherited parent without conflict.

    **Step 4 — verify the structural guarantee.** Create a temporary throwaway file at `lib/features/family_sync/use_cases/_test_should_be_blocked.dart` with `import 'dart:async';`. Run `dart run custom_lint`. Expected: the file triggers a `layer_violation` because `package:home_pocket/features/family_sync/use_cases/**` is now denied by BOTH the global yaml AND the feature-scoped yaml. Then DELETE the throwaway file (do NOT commit). This step proves the deny rule fires at the feature scope.

    **Step 5 — commit:** `chore(03-03): add lib/features/family_sync/import_guard.yaml — D-10 literal (LV-017..LV-021)`.

    Commit message MUST reference LV-017, LV-018, LV-019, LV-020, LV-021 (the 5 LV findings the rule structurally protects against future regression of) AND CONTEXT.md D-10 in the body. Example:

    ```
    chore(03-03): add lib/features/family_sync/import_guard.yaml — D-10 literal (LV-017..LV-021)

    Per CONTEXT.md D-10 verbatim: "a features/family_sync/ import_guard rule is
    added that explicitly denies any future re-creation of use_cases/ underneath
    features." The pre-existing global rule at lib/features/import_guard.yaml
    already covered this case project-wide; this feature-scoped yaml satisfies
    D-10's literal wording and gives contributors a family_sync-local signal.

    Closes structural-regression risk for LV-017..LV-021.
    ```
  </action>
  <verify>
    <automated>test -f lib/features/family_sync/import_guard.yaml &amp;&amp; grep -q "use_cases/\*\*" lib/features/family_sync/import_guard.yaml &amp;&amp; rm -rf .dart_tool &amp;&amp; flutter pub get &amp;&amp; dart run custom_lint</automated>
  </verify>
  <acceptance_criteria>
    - `test -f lib/features/family_sync/import_guard.yaml` exits 0 (file exists)
    - `grep -q "package:home_pocket/features/family_sync/use_cases/\*\*" lib/features/family_sync/import_guard.yaml` exits 0 (feature-scoped use_cases/ deny present)
    - `grep -q "^deny:" lib/features/family_sync/import_guard.yaml` exits 0 (deny block present)
    - `grep -q "^inherit: true" lib/features/family_sync/import_guard.yaml` exits 0 (composes with parent)
    - `grep -qE "D-10|CONTEXT\.md" lib/features/family_sync/import_guard.yaml` exits 0 (rationale comment cites D-10)
    - `rm -rf .dart_tool && flutter pub get && dart run custom_lint` exits 0 (cold-start lint clean — global + feature yamls compose without conflict)
    - `! test -f lib/features/family_sync/use_cases/_test_should_be_blocked.dart` exits 0 (Step 4 throwaway file deleted, not committed)
    - `git log -1 --pretty=%B lib/features/family_sync/import_guard.yaml | grep -E "LV-017|LV-018|LV-019|LV-020|LV-021"` returns at least one match (commit message references LV-017..LV-021 per D-10 traceability)
    - `git log -1 --pretty=%B lib/features/family_sync/import_guard.yaml | grep -E "D-10"` exits 0 (commit message references D-10)
  </acceptance_criteria>
  <done>`lib/features/family_sync/import_guard.yaml` exists with feature-scoped deny rule per D-10 literal wording; cold-start `dart run custom_lint` exits 0; commit references LV-017..LV-021 + D-10; structural-regression guarantee in place.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Source file at old path → import_guard.yaml deny | Any stale importer leaks the old path; lint flags it |
| `git mv` history → blame/bisect | Per-file atomic commit boundary preserves rename detection |
| Existing `*.mocks.dart` files → migrated tests | Mockito codegen is Phase 4 territory; Phase 3 must not regenerate |
| Feature-scoped `lib/features/family_sync/import_guard.yaml` → CI gate | New yaml composes with global yaml; both must agree on the deny set |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-03-03-01 | Tampering | Stale imports leaking into archive paths | mitigate | Per-PR `flutter analyze` exits 0; full-suite `dart run custom_lint` exits 0; explicit `grep -rln "family_sync/use_cases/<name>"` returns empty acceptance criterion per task |
| T-03-03-02 | Repudiation | "Phase 3 broke history; can't bisect bug back to its source" | mitigate | RESEARCH.md Pitfall 5 — each per-file PR is `git mv` + minimal import-path adjustment ONLY; `git diff -M` confirms `R100` rename score; commit messages name the LV finding ID |
| T-03-03-03 | Tampering | Test accidentally exercises real `flutter_secure_storage` (FUTURE-ARCH-04) | accept | Existing migrated tests retain their existing mock infrastructure (Mockito codegen). Phase 4 HIGH-07 evaluates the strategy. Phase 3 explicitly does NOT touch `*.mocks.dart` files (CONTEXT.md `<deferred>`). |
| T-03-03-04 | DoS | `git mv` followed by manual edits in same commit obscures review | mitigate | Acceptance criterion `git diff --stat` confirms only 5 files (source + test + 1-3 callers + maybe mocks file) appear per per-file commit |
| T-03-03-05 | Information Disclosure | None — file moves don't surface secrets | accept | All moved files are pure logic + use-case patterns; no embedded secrets |
| T-03-03-06 | Tampering | Future contributor weakens the feature-scoped deny rule (Task 6 yaml) | mitigate | Task 6 commit message cites D-10 + LV-017..LV-021; arch test (Plan 03-01 Task 2) covers domain yamls; Phase 7 docs sweep records the convention so the yaml is discoverable. Direct yaml deletion is git-blame discoverable. |

**Security block on:** HIGH (per security_threat_model_gate). All threats above either MITIGATED or explicitly ACCEPTED.
</threat_model>

<verification>
**Per-plan exit gates** (Task 5 final verify enforces all; Task 6 adds the feature-scoped yaml):
- `flutter analyze --no-fatal-infos` exits 0 (CRIT-06)
- `dart run custom_lint` exits 0 (CRIT-06; also exits 0 from cold start after Task 6)
- `flutter test` exits 0 (full suite GREEN)
- `dart run scripts/coverage_gate.dart --list /tmp/phase3-plan03-touched.txt --threshold 80 --lcov coverage/lcov_clean.info` exits 0 (CRIT-05 D-15)
- `! test -d lib/features/family_sync/use_cases` exits 0 (CRIT-02)
- `grep -rln "family_sync/use_cases/" lib/ test/` returns no output (zero stale references)
- `test -f lib/features/family_sync/import_guard.yaml` exits 0 (D-10 literal)
- 5 LV findings (LV-017..LV-021) closed in `issues.json`

**Manual verification** (per VALIDATION.md §Manual-Only Verifications):
- After all 5 PRs merge, run `git log --follow lib/application/family_sync/check_group_use_case.dart` (and 4 siblings); verify pre-move history still appears (rename detection survived).
</verification>

<success_criteria>
- 5 source files moved via `git mv`; filenames preserved
- 5 test files moved alongside; production-file imports updated
- All callers updated; zero stale references to `features/family_sync/use_cases/`
- `lib/features/family_sync/use_cases/` directory deleted
- `lib/features/family_sync/import_guard.yaml` exists with feature-scoped deny rule per D-10 literal wording
- LV-017, LV-018, LV-019, LV-020, LV-021 closed in `issues.json`
- CRIT-02 closed (recorded in plan SUMMARY)
- All per-plan exit gates pass (analyze, custom_lint, full test suite, coverage_gate ≥80% on the 5 migrated source files)
- Operational repo lock (D-16) honored — only Phase 3 plan PRs merge to main
</success_criteria>

<output>
After completion, create `.planning/phases/03-critical-fixes/03-03-SUMMARY.md` recording: 5 commit SHAs (one per file move), the cleanup commit SHA, the new feature-scoped yaml commit SHA (Task 6), the LV-017..LV-021 closures, and a confirmation that `git log --follow` shows pre-move history on each migrated file.

Generate `doc/worklog/YYYYMMDD_HHMM_phase3_plan03_use_cases_migration.md` per `.claude/rules/worklog.md`.
</output>
