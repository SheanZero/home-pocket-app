---
phase: 07-documentation-sweep
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
  - docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md
  - docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md
  - docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md
  - docs/arch/02-module-specs/MOD-002_DualLedger.md
  - docs/arch/02-module-specs/MOD-006_Analytics.md
  - docs/arch/02-module-specs/MOD-007_Settings.md
  - docs/arch/02-module-specs/MOD-008_Gamification.md
  - docs/arch/02-module-specs/MOD-009_VoiceInput.md
  - docs/arch/05-UI/UI-001_Page_Inventory.md
autonomous: true
requirements: [DOCS-01]

must_haves:
  truths:
    - "Wave 0 verification script `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exists, is executable, and contains the 6 grep gates from 07-RESEARCH.md §Code Examples."
    - "Before Wave 1 commits, the script exits NON-ZERO (drift still present at this point — failure is the contract)."
    - "After Wave 1 commits, every D1-1..D1-7 layer path in MOD-006/MOD-007 is replaced with `lib/application/{domain}/` or `lib/data/repositories/` matching the verified post-Phase-3..4 location."
    - "After Wave 1 commits, every D2-1..D2-7 mockito reference in MOD-002/006/007/008/009 + ARCH-001/007 is replaced with the mocktail equivalent (or the @GenerateMocks block deleted)."
    - "After Wave 1 commits, ARCH-001:48 sqlite3_flutter_libs line is deleted (D2-8)."
    - "After Wave 1 commits, ARCH-007 line ~360 mockito reference is replaced with `mocktail 1.0+` (D2-6) and the sqlite3_flutter_libs line at ~317-318 is deleted (D2-10)."
    - "After Wave 1 commits, every phantom MOD-014 reference in ARCH-007/ARCH-008/UI-001 is replaced with `BASIC-003` per D-01 (D5-3, D5-4, D5-5)."
    - "After Wave 1 commits, ARCH-001:2078 cross-ref `MOD-009: 趣味功能` is corrected to `MOD-009: 语音记账` (D3-6 — only D3 site that's in Phase 7 scope per CONTEXT D-02)."
    - "After Wave 1 commits, MOD-008 D1-8/D1-9/D1-14 paths are annotated as `**目标位置（未实施）:**` rather than rewritten (gamification feature is not yet implemented in lib/)."
    - "After Wave 1 commits, gates 1, 2, 3, 5 of `verify-doc-sweep.sh` PASS for the files modified by this plan (other plans are still in-flight; gate 4 + 6 may still fail)."
    - "lib/-clean invariant: this plan's commits modify ONLY paths under `docs/arch/` and `.planning/phases/07-documentation-sweep/`."
  artifacts:
    - path: ".planning/phases/07-documentation-sweep/verify-doc-sweep.sh"
      provides: "Phase-7 close gate script (6 grep checks)"
      min_lines: 25
    - path: "docs/arch/02-module-specs/MOD-007_Settings.md"
      provides: "Settings module spec — post-cleanup file paths"
    - path: "docs/arch/02-module-specs/MOD-006_Analytics.md"
      provides: "Analytics module spec — post-cleanup file paths"
    - path: "docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md"
      provides: "Tech stack + global file tree — post-cleanup"
  key_links:
    - from: ".planning/phases/07-documentation-sweep/verify-doc-sweep.sh"
      to: "docs/arch/, CLAUDE.md, .claude/rules/arch.md"
      via: "grep -rn over file tree"
      pattern: "set -euo pipefail.*\\[1/6\\].*\\[6/6\\]"

---

<objective>
Sweep ARCH/MOD/UI documentation drift introduced by Phases 3-6 cleanup. Plan 07-01 covers DOCS-01 part 1: edits to `docs/arch/01-core-architecture/`, `docs/arch/02-module-specs/`, and `docs/arch/05-UI/`. Begins with the mandatory Wave 0 task that creates the phase's mechanical gate (`verify-doc-sweep.sh`) so reviewers can confirm "drift gone" via exit code, not eyeballing.

Purpose: Restore alignment between architecture documentation and the actual `lib/` tree (post-centralization use_cases at `lib/application/{domain}/`, post-centralization repositories at `lib/data/repositories/`, mocktail-not-mockito mock convention, sqlite3_flutter_libs hard-rejected).

Output: 9 modified Markdown files + 1 new shell script. Every grep gate listed in must_haves passes for files in this plan's `files_modified` list.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/phases/07-documentation-sweep/07-CONTEXT.md
@.planning/phases/07-documentation-sweep/07-RESEARCH.md
@.planning/phases/07-documentation-sweep/07-PATTERNS.md
@.planning/phases/07-documentation-sweep/07-VALIDATION.md
@.claude/rules/arch.md
@CLAUDE.md
</context>

<tasks>

<task type="auto">
  <id>07-01-W0-01</id>
  <wave>0</wave>
  <name>Task 0: Create verify-doc-sweep.sh and confirm it currently FAILS</name>
  <files>.planning/phases/07-documentation-sweep/verify-doc-sweep.sh</files>
  <read_first>
    - .planning/phases/07-documentation-sweep/07-RESEARCH.md (lines 532-571 — verbatim script body)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 525-599 — pattern principles to mirror)
    - scripts/build_coverage_baseline.sh (analog: shebang, set -euo pipefail, numbered echo, fail accumulator)
  </read_first>
  <action>
    Create `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` with the EXACT body specified in 07-RESEARCH.md §"Code Examples" lines 536-571 (also reproduced verbatim in 07-PATTERNS.md lines 549-584). The script MUST:

    1. Start with shebang `#!/usr/bin/env bash` (NOTE: 07-RESEARCH.md uses `#!/bin/bash`; mirror 07-PATTERNS.md's `#!/usr/bin/env bash` form which matches scripts/audit_*.sh convention).
    2. Header comment block: file path, purpose ("Verifies that documentation drift is fully remediated. Exits 0 only when ALL drift gates pass.").
    3. `set -euo pipefail`.
    4. `fail=0` accumulator.
    5. Six numbered echo+grep gates labelled `[1/6]` through `[6/6]`:
       - [1/6] Layer-centralization drift in `docs/arch/` (excluding ADR `## Update` sections).
       - [2/6] mockito drift (`package:mockito`, `@GenerateMocks`, `\.mocks\.dart`) in `docs/arch/` excluding ADR `## Update`.
       - [3/6] sqlite3_flutter_libs in non-historical contexts (excluding `docs/arch/03-adr/` entirely).
       - [4/6] `doc/arch/` (singular) path drift in `CLAUDE.md` and `.claude/rules/arch.md` via `grep -cE 'doc/arch[^/]'`.
       - [5/6] Phantom MOD-014 references (`MOD-014_i18n\.md|MOD-014 i18n`) in `docs/arch/` and `CLAUDE.md`.
       - [6/6] ADR-011 file presence + ADR-000 INDEX entry.
    6. Each gate increments `fail=1` on hit, prints `OK` on clean.
    7. `exit $fail` at the end.

    Then `chmod +x` the script and run it once to confirm it currently exits NON-ZERO (drift still present in main; failures are the contract per D-07). Capture the failing output in the commit body for traceability.

    Do NOT modify any other file in this task. The first commit in Plan 07-01 must be script-creation only.
  </action>
  <verify>
    <automated>test -x .planning/phases/07-documentation-sweep/verify-doc-sweep.sh && ! bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh; [ $? -eq 0 ] || echo "Script exists and currently fails — expected"</automated>
  </verify>
  <acceptance_criteria>
    - `test -x .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0
    - `head -1 .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` outputs `#!/usr/bin/env bash`
    - `grep -c '^echo "\[' .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` returns `6`
    - `grep -c '^set -euo pipefail$' .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` returns `1`
    - `grep -q 'features/\[a-z_\]\*/use_cases' .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (gate 1 token present)
    - `grep -q 'package:mockito' .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (gate 2 token present)
    - `grep -q 'sqlite3_flutter_libs' .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (gate 3 token present)
    - `grep -q "doc/arch\[\^/\]" .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (gate 4 token present)
    - `grep -q 'MOD-014_i18n' .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (gate 5 token present)
    - `grep -q 'ADR-011' .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` exits 0 (gate 6 token present)
    - `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh; [ $? -ne 0 ]` succeeds (script currently FAILS as expected — drift not yet fixed)
  </acceptance_criteria>
  <files_modified>.planning/phases/07-documentation-sweep/verify-doc-sweep.sh</files_modified>
  <done>verify-doc-sweep.sh exists, is executable, has 6 grep gates, and exits non-zero on current main (failure expected and documented).</done>
</task>

<task type="auto">
  <id>07-01-01</id>
  <wave>1</wave>
  <name>Task 1: Fix MOD-006 + MOD-007 layer-centralization drift (D1-1..D1-7) and MOD-007 mockito drift (D2-1)</name>
  <files>docs/arch/02-module-specs/MOD-006_Analytics.md, docs/arch/02-module-specs/MOD-007_Settings.md</files>
  <read_first>
    - docs/arch/02-module-specs/MOD-006_Analytics.md (full file — drift sites at lines 268, 520, 1269, 1272-1276)
    - docs/arch/02-module-specs/MOD-007_Settings.md (full file — drift sites at lines 47, 101, 236, 371, 819, 822-830)
    - lib/application/analytics/ (verify post-cleanup paths exist: `get_monthly_report_use_case.dart`, `get_budget_progress_use_case.dart`, `get_expense_trend_use_case.dart`, `demo_data_service.dart`)
    - lib/application/settings/ (verify post-cleanup paths exist: `export_backup_use_case.dart`, `import_backup_use_case.dart`, `clear_all_data_use_case.dart`)
    - lib/features/settings/domain/models/backup_data.dart (verify D1-13 path: Domain stays in features per Thin Feature rule — this is NOT drift; do NOT change)
    - test/unit/application/settings/ (verify D1-4 target: `test/unit/application/settings/export_backup_use_case_test.dart` exists)
    - test/unit/application/analytics/ (verify D1-7 target — find actual path with `find test -name 'get_monthly_report_use_case_test.dart'`)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 192-217 — replacement-token table)
  </read_first>
  <action>
    Apply the following find-and-replace edits. Each edit has a verified replacement target derived from the actual `lib/`/`test/` tree (confirmed via `find` before commit):

    **MOD-007_Settings.md:**
    - Line ~101: replace `lib/features/settings/application/use_cases/export_backup_use_case.dart` → `lib/application/settings/export_backup_use_case.dart` (D1-1)
    - Line ~236: replace `lib/features/settings/application/use_cases/import_backup_use_case.dart` → `lib/application/settings/import_backup_use_case.dart` (D1-2)
    - Line ~371: replace `lib/features/settings/data/repositories/settings_repository_impl.dart` → `lib/data/repositories/settings_repository_impl.dart` (D1-3)
    - Line ~819: replace `test/features/settings/application/use_cases/export_backup_use_case_test.dart` → `test/unit/application/settings/export_backup_use_case_test.dart` (D1-4 — verified path)
    - Lines ~822-830: replace mockito-style block with mocktail-style block (D2-1):
      - `import 'package:mockito/mockito.dart';` → `import 'package:mocktail/mocktail.dart';`
      - `import 'export_backup_use_case_test.mocks.dart';` → DELETE this line
      - `@GenerateMocks([SettingsRepository])` annotation block → DELETE
      - `MockSettingsRepository = MockSettingsRepository()` → `class MockSettingsRepository extends Mock implements SettingsRepository {}` defined at file scope, then `final mockRepo = MockSettingsRepository();`
    - Line ~47 `lib/features/settings/domain/models/backup_data.dart`: VERIFY first via `test -f` before editing — Domain layer survives in features per Thin Feature rule. If file exists at that path, NO change. If file does NOT exist, replace with the actual path found via `find lib -name backup_data.dart`. (D1-13 is conditional drift.)

    **MOD-006_Analytics.md:**
    - Line ~268: replace `lib/features/analytics/application/use_cases/get_monthly_report_use_case.dart` → `lib/application/analytics/get_monthly_report_use_case.dart` (D1-5)
    - Line ~520: replace `lib/features/analytics/application/use_cases/get_budget_progress_use_case.dart` → `lib/application/analytics/get_budget_progress_use_case.dart` (D1-6)
    - Line ~1269: replace `test/features/analytics/application/use_cases/get_monthly_report_use_case_test.dart` → actual path found via `find test -name 'get_monthly_report_use_case_test.dart'` (likely `test/unit/application/analytics/get_monthly_report_use_case_test.dart`) (D1-7)
    - Lines ~1272-1276: replace mockito @GenerateMocks block with mocktail equivalent following the same transformation pattern as MOD-007 (D2-2)

    For the mocktail conversion pattern, use this template (per 07-PATTERNS.md lines 198-209):
    ```dart
    // OLD (mockito):
    import 'package:mockito/mockito.dart';
    import 'foo_test.mocks.dart';
    @GenerateMocks([FooRepository])
    void main() {
      final mock = MockFooRepository();
    }

    // NEW (mocktail):
    import 'package:mocktail/mocktail.dart';
    class MockFooRepository extends Mock implements FooRepository {}
    void main() {
      final mock = MockFooRepository();
    }
    ```

    After edits, run gates 1 + 2 of verify-doc-sweep.sh restricted to MOD-006/MOD-007 to confirm zero hits.
  </action>
  <verify>
    <automated>! grep -nE 'features/(settings|analytics)/(application/use_cases|data/repositories)' docs/arch/02-module-specs/MOD-006_Analytics.md docs/arch/02-module-specs/MOD-007_Settings.md && ! grep -nE 'package:mockito|@GenerateMocks|\.mocks\.dart' docs/arch/02-module-specs/MOD-006_Analytics.md docs/arch/02-module-specs/MOD-007_Settings.md</automated>
  </verify>
  <acceptance_criteria>
    - `! grep -n "features/settings/application/use_cases" docs/arch/02-module-specs/MOD-007_Settings.md` exits 0 (D1-1, D1-2 closed)
    - `! grep -n "features/settings/data/repositories" docs/arch/02-module-specs/MOD-007_Settings.md` exits 0 (D1-3 closed)
    - `! grep -n "test/features/settings/application/use_cases" docs/arch/02-module-specs/MOD-007_Settings.md` exits 0 (D1-4 closed)
    - `! grep -n "features/analytics/application/use_cases" docs/arch/02-module-specs/MOD-006_Analytics.md` exits 0 (D1-5, D1-6 closed)
    - `! grep -n "test/features/analytics/application/use_cases" docs/arch/02-module-specs/MOD-006_Analytics.md` exits 0 (D1-7 closed)
    - `! grep -n "package:mockito\|@GenerateMocks" docs/arch/02-module-specs/MOD-006_Analytics.md docs/arch/02-module-specs/MOD-007_Settings.md` exits 0 (D2-1, D2-2 closed)
    - `! grep -n "_test\.mocks\.dart" docs/arch/02-module-specs/MOD-006_Analytics.md docs/arch/02-module-specs/MOD-007_Settings.md` exits 0
    - `grep -q "lib/application/settings/export_backup_use_case.dart" docs/arch/02-module-specs/MOD-007_Settings.md` exits 0 (replacement landed)
    - `grep -q "lib/application/analytics/get_monthly_report_use_case.dart" docs/arch/02-module-specs/MOD-006_Analytics.md` exits 0 (replacement landed)
    - `grep -q "package:mocktail/mocktail.dart" docs/arch/02-module-specs/MOD-007_Settings.md` exits 0 (mocktail import landed)
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean invariant)
  </acceptance_criteria>
  <files_modified>docs/arch/02-module-specs/MOD-006_Analytics.md, docs/arch/02-module-specs/MOD-007_Settings.md</files_modified>
  <done>MOD-006 and MOD-007 free of D1 layer drift and D2 mockito drift; gates 1+2 of verify-doc-sweep.sh return zero hits when restricted to these two files.</done>
</task>

<task type="auto">
  <id>07-01-02</id>
  <wave>1</wave>
  <name>Task 2: Fix MOD-002/008/009 mockito drift + MOD-008 speculative-path annotation + UI-001 phantom MOD-014</name>
  <files>docs/arch/02-module-specs/MOD-002_DualLedger.md, docs/arch/02-module-specs/MOD-008_Gamification.md, docs/arch/02-module-specs/MOD-009_VoiceInput.md, docs/arch/05-UI/UI-001_Page_Inventory.md</files>
  <read_first>
    - docs/arch/02-module-specs/MOD-002_DualLedger.md (drift sites at lines 927-1010)
    - docs/arch/02-module-specs/MOD-008_Gamification.md (drift sites at lines 104-105, 440, 586, 1272-1281, 1434-1437)
    - docs/arch/02-module-specs/MOD-009_VoiceInput.md (drift sites at lines 1266-1273)
    - docs/arch/05-UI/UI-001_Page_Inventory.md (drift sites at lines 15, 386)
    - .planning/phases/07-documentation-sweep/07-RESEARCH.md (lines 215-262 — D2 + D5 drift inventory)
    - .planning/phases/07-documentation-sweep/07-PATTERNS.md (lines 192-217 — replacement-token table)
  </read_first>
  <action>
    **MOD-002_DualLedger.md (lines ~927-1010):**
    - Replace mockito imports/annotations with mocktail equivalents (same pattern as Task 07-01-01).
    - Replace `MockTFLiteClassifier`/`MockMerchantDatabase` mockito-style usage with mocktail-style (`class MockX extends Mock implements X {}` at file scope).
    - Replace `verifyNever(mockTFLiteClassifier.predict(...))` etc. with mocktail's `verifyNever(() => mockTFLiteClassifier.predict(...))` (mocktail wraps the call in a closure — this is the known mocktail signature change). (D2-5)

    **MOD-008_Gamification.md:**
    - Lines ~1272-1281 + ~1434-1437: replace TWO mockito @GenerateMocks blocks with mocktail equivalents. (D2-3)
    - Line ~440 (D1-8): replace `lib/features/gamification/data/repositories/conversion_unit_repository_impl.dart` with `**目标位置（未实施）:** lib/data/repositories/conversion_unit_repository_impl.dart` — annotate as not-yet-implemented since gamification feature is not in `lib/` yet (verified: `find lib -path "*gamification*"` returns empty per 07-RESEARCH.md). Insert a one-line clarification: `> 注：MOD-008 游戏化模块为 v2 backlog 项；下列路径为目标位置，尚未在 lib/ 实施。`
    - Line ~586 (D1-9): same treatment for `fortune_repository_impl.dart`.
    - Lines ~104-105 (D1-14): in the ASCII diagram showing `ConversionUnitRepositoryImpl` / `FortuneRepositoryImpl`, prepend or append a footnote `(目标位置，未实施)` to make speculative status explicit.

    **MOD-009_VoiceInput.md (lines ~1266-1273):**
    - Replace `MockCategoryService` mockito-style declaration with mocktail `class MockCategoryService extends Mock implements CategoryService {}` at file scope.
    - Update import to `package:mocktail/mocktail.dart`.
    - Delete `.mocks.dart` import line if present. (D2-4)
    - NOTE: `CategoryService` is the application-layer accounting business service — do NOT rename to `CategoryLocaleService` (that rename was only for the infrastructure helper per Phase 5-01).

    **UI-001_Page_Inventory.md (D5-5):**
    - Line ~15: replace `MOD-001 ~ MOD-009、MOD-014` with `MOD-001 ~ MOD-009、BASIC-003`.
    - Line ~386: replace any `[MOD-014_i18n.md](...)` link with `[BASIC-003_I18N_Infrastructure.md](../04-basic/BASIC-003_I18N_Infrastructure.md)`.

    All edits are append-or-replace; no MOD file is renamed (Pitfall 7-C in 07-RESEARCH.md).
  </action>
  <verify>
    <automated>! grep -nE 'package:mockito|@GenerateMocks|_test\.mocks\.dart' docs/arch/02-module-specs/MOD-002_DualLedger.md docs/arch/02-module-specs/MOD-008_Gamification.md docs/arch/02-module-specs/MOD-009_VoiceInput.md && ! grep -nE 'MOD-014_i18n\.md|MOD-014 i18n' docs/arch/05-UI/UI-001_Page_Inventory.md</automated>
  </verify>
  <acceptance_criteria>
    - `! grep -n "package:mockito\|@GenerateMocks" docs/arch/02-module-specs/MOD-002_DualLedger.md` exits 0 (D2-5 closed)
    - `! grep -n "package:mockito\|@GenerateMocks" docs/arch/02-module-specs/MOD-008_Gamification.md` exits 0 (D2-3 closed)
    - `! grep -n "package:mockito\|@GenerateMocks" docs/arch/02-module-specs/MOD-009_VoiceInput.md` exits 0 (D2-4 closed)
    - `grep -q "package:mocktail/mocktail.dart" docs/arch/02-module-specs/MOD-002_DualLedger.md` exits 0
    - `grep -q "package:mocktail/mocktail.dart" docs/arch/02-module-specs/MOD-008_Gamification.md` exits 0
    - `grep -q "package:mocktail/mocktail.dart" docs/arch/02-module-specs/MOD-009_VoiceInput.md` exits 0
    - `grep -q "目标位置（未实施）\|目标位置，未实施" docs/arch/02-module-specs/MOD-008_Gamification.md` exits 0 (D1-8/D1-9/D1-14 annotated, not blindly rewritten)
    - `! grep -n "MOD-014_i18n\.md\|MOD-014 i18n" docs/arch/05-UI/UI-001_Page_Inventory.md` exits 0 (D5-5 closed)
    - `grep -q "BASIC-003" docs/arch/05-UI/UI-001_Page_Inventory.md` exits 0 (replacement landed)
    - No file in this task's `files_modified` is renamed (no `MOD-*.md` rename — Pitfall 7-C respected).
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean invariant)
  </acceptance_criteria>
  <files_modified>docs/arch/02-module-specs/MOD-002_DualLedger.md, docs/arch/02-module-specs/MOD-008_Gamification.md, docs/arch/02-module-specs/MOD-009_VoiceInput.md, docs/arch/05-UI/UI-001_Page_Inventory.md</files_modified>
  <done>MOD-002/008/009 free of D2 mockito drift; MOD-008 speculative paths properly annotated; UI-001 free of phantom MOD-014 references; all 4 files lib/-clean.</done>
</task>

<task type="auto">
  <id>07-01-03</id>
  <wave>1</wave>
  <name>Task 3: Fix ARCH-001/007/008 tech-stack + diagram drift (D2-6, D2-7, D2-8, D2-10, D3-6, D5-3, D5-4)</name>
  <files>docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md, docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md, docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md</files>
  <read_first>
    - docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md (drift sites at lines 48, 86, 2078)
    - docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md (drift sites at lines 13, 28, 141, 317-318, 360, 436, 470)
    - docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md (drift sites at lines 354-357)
    - pubspec.yaml (verify mocktail version — currently `^1.0.4` per 07-RESEARCH.md)
    - .planning/phases/07-documentation-sweep/07-RESEARCH.md (lines 224-228 + 256-264 — D2 + D5 inventory)
    - .planning/phases/07-documentation-sweep/07-CONTEXT.md (D-01 — phantom MOD-014 → BASIC-003)
  </read_first>
  <action>
    **ARCH-001_Complete_Guide.md:**
    - Line ~48: DELETE the entire line `Database Engine: sqlite3_flutter_libs ^0.5.18` (D2-8). The remaining `sqlcipher_flutter_libs ^0.5.18` (or current pubspec value) is the only allowed entry per CI gate AUDIT-09.
    - Line ~86: replace `Mocking: mockito ^5.4.4` with `Mocking: mocktail ^1.0.4` (verified version from pubspec.yaml; D2-7).
    - Line ~2078: replace `### MOD-009: 趣味功能` with `### MOD-009: 语音记账` (D3-6 — only D3 site fixed in Phase 7 per CONTEXT D-02 carve-out; this is a content bug regardless of numbering policy).

    **ARCH-007_Architecture_Diagram_I18N.md:**
    - Lines ~317-318: DELETE the entire line `├─ sqlite3_flutter_libs 0.5+` from any dependency tree ASCII diagram. Adjust the surrounding box-drawing characters so the tree remains visually balanced (e.g., promote a sibling line from `├─` to the new last position with `└─`). (D2-10)
    - Line ~360: replace `└─ mockito 5.4+` with `└─ mocktail 1.0+`. (D2-6)
    - Lines 13, 28, 141, 436, 470 (D5-3): replace each `MOD-014` label/reference with `BASIC-003`. For ASCII diagrams where the label is part of a fixed-width box, keep the same character count (e.g., `MOD-014` is 7 chars; `BASIC-003` is 9 chars — re-draw the box if needed, or use the shorter label `BASIC-3` if alignment matters). Add a one-line legend immediately above the first updated diagram: `> 注：BASIC-003 即原 MOD-014 i18n 模块（已于 2026-02-22 合并至 docs/arch/04-basic/）。`

    **ARCH-008_Layer_Clarification.md (D5-4):**
    - Lines ~354-357: in the table that labels `DateFormatter` / `NumberFormatter` / `LocaleSettings` / `SupportedLocales` as belonging to `MOD-014`, replace each `MOD-014` cell with `BASIC-003`. Keep the rest of the row content unchanged.

    All edits in this task are textual replacements within `docs/arch/01-core-architecture/`. No file is renamed.
  </action>
  <verify>
    <automated>! grep -nE 'sqlite3_flutter_libs|mockito ' docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md && ! grep -n "MOD-014" docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md && grep -q "MOD-009: 语音记账" docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md</automated>
  </verify>
  <acceptance_criteria>
    - `! grep -n "sqlite3_flutter_libs" docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` exits 0 (D2-8 closed)
    - `! grep -n "sqlite3_flutter_libs" docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md` exits 0 (D2-10 closed)
    - `! grep -nE "mockito [0-9]" docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md` exits 0 (D2-6, D2-7 closed; the `mockito` keyword in version-context replaced)
    - `grep -q "mocktail" docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` exits 0 (replacement landed)
    - `grep -q "mocktail" docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md` exits 0 (replacement landed)
    - `grep -q "MOD-009: 语音记账" docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` exits 0 (D3-6 fixed — the only D3 in scope)
    - `! grep -n "MOD-009: 趣味功能" docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` exits 0 (stale ref removed)
    - `! grep -n "MOD-014" docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md` exits 0 OR every remaining `MOD-014` mention is inside the new legend line referring to "原 MOD-014" — verify with `grep -B1 'MOD-014' ...` shows context is the legend, not a fresh reference (D5-3 closed)
    - `! grep -n "MOD-014" docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md` exits 0 (D5-4 closed)
    - `grep -q "BASIC-003" docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md` exits 0
    - `grep -q "BASIC-003" docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md` exits 0
    - `git diff --name-only HEAD~ HEAD | grep -cE '^(lib/|test/|pubspec|\.github/|analysis_options)'` returns `0` (lib/-clean invariant)
  </acceptance_criteria>
  <files_modified>docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md, docs/arch/01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md, docs/arch/01-core-architecture/ARCH-008_Layer_Clarification.md</files_modified>
  <done>ARCH-001/007/008 free of D2 tech-stack drift, D5 phantom MOD-014, and the in-scope D3 cross-ref bug; all 3 files lib/-clean; legend explaining MOD-014→BASIC-003 added.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Documentation reader → Architecture facts | Future contributors trust ARCH/MOD docs to match the actual codebase. Drift is an Information Disclosure failure mode (false sense of architecture). |
| ASCII diagram label → File path | Diagrams reference module IDs that map to file paths. Phantom labels (MOD-014) waste contributor time. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-07-01-01 | Information Disclosure | ARCH/MOD docs claiming non-existent file paths | mitigate | Every replacement path verified against actual `lib/`/`test/` tree via `find` before commit (per A4 in 07-RESEARCH.md Assumptions Log). |
| T-07-01-02 | Tampering | Accidental code edit during doc commit | mitigate | Every task acceptance includes `git diff --name-only` lib/-clean check (D-08 enforcement). |
| T-07-01-03 | Repudiation | Phantom MOD-014 references hide that i18n moved to BASIC-003 | mitigate | Legend added in ARCH-007 explicitly documents the rename and date. |
| T-07-01-04 | Information Disclosure | sqlite3_flutter_libs left in tech stack docs while CI rejects it | mitigate | Line deleted from ARCH-001:48 and ARCH-007:317-318; ADR-002 update (handled in Plan 07-02) tells the historical story. |
</threat_model>

<verification>
- All 3 Wave-1 task acceptance criteria pass.
- After this plan completes, gates [1/6], [2/6], [5/6] of `verify-doc-sweep.sh` should PASS for files modified by this plan (full pass requires Plans 07-02..05 to also commit; gates [3/6], [4/6], [6/6] still expected to fail until later plans land).
- `git diff --name-only main..HEAD docs/arch/` shows changes ONLY in the 9 files listed in `files_modified` (plus the new shell script).
- No file under `lib/`, `test/`, `pubspec.*`, `.github/`, or `analysis_options.yaml` is modified.
</verification>

<success_criteria>
- `verify-doc-sweep.sh` exists, is executable, contains 6 grep gates, and exits non-zero on first run (drift exists; Wave 0 contract).
- After Wave 1 commits, the following grep commands all return ZERO hits:
  - `grep -rn "features/[a-z_]*/use_cases\|features/[a-z_]*/data/repositories" docs/arch/01-core-architecture/ docs/arch/02-module-specs/ docs/arch/05-UI/`
  - `grep -rn "package:mockito\|@GenerateMocks\|\.mocks\.dart" docs/arch/01-core-architecture/ docs/arch/02-module-specs/`
  - `grep -rn "sqlite3_flutter_libs" docs/arch/01-core-architecture/`
  - `grep -rn "MOD-014_i18n\.md\|MOD-014 i18n" docs/arch/01-core-architecture/ docs/arch/02-module-specs/ docs/arch/05-UI/`
  - `grep -n "MOD-009: 趣味功能" docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md`
- All 9 modified docs still parse as valid Markdown (no broken table rows or unbalanced fences) — verified by `grep -c '^```' file | awk '{ if ($1 % 2 != 0) exit 1 }'` for each file.
- `flutter analyze --no-fatal-infos` exits 0 and `flutter test test/architecture/` passes (sanity backstop — pure-doc commits cannot affect them, but verify nothing was accidentally edited under lib/).
</success_criteria>

<output>
After completion, create `.planning/phases/07-documentation-sweep/07-01-SUMMARY.md` with:
- List of files modified + line ranges
- Grep results showing each gate's hit count went from N→0 for files in scope
- Confirmation that `git diff --name-only main..HEAD` is lib/-clean
- Note that gates 3 (sqlite3_flutter_libs in ADR), 4 (CLAUDE.md path drift), and 6 (ADR-011 presence) are still red — handled by Plans 07-02, 07-03, 07-05 respectively
</output>
