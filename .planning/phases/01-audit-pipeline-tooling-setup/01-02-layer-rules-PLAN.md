---
phase: 01-audit-pipeline-tooling-setup
plan: 02
type: execute
wave: 2
depends_on: [01]
files_modified:
  - lib/import_guard.yaml
  - lib/features/import_guard.yaml
  - lib/features/accounting/domain/import_guard.yaml
  - lib/features/analytics/domain/import_guard.yaml
  - lib/features/family_sync/domain/import_guard.yaml
  - lib/features/home/domain/import_guard.yaml
  - lib/features/profile/domain/import_guard.yaml
  - lib/features/settings/domain/import_guard.yaml
  - lib/features/accounting/presentation/import_guard.yaml
  - lib/features/analytics/presentation/import_guard.yaml
  - lib/features/dual_ledger/presentation/import_guard.yaml
  - lib/features/family_sync/presentation/import_guard.yaml
  - lib/features/home/presentation/import_guard.yaml
  - lib/features/profile/presentation/import_guard.yaml
  - lib/features/settings/presentation/import_guard.yaml
  - lib/application/import_guard.yaml
  - lib/data/import_guard.yaml
  - lib/infrastructure/import_guard.yaml
autonomous: true
requirements: [AUDIT-02]
tags: [import-guard, layer-rules, clean-architecture]

must_haves:
  truths:
    - "Per-directory `import_guard.yaml` files exist at all 5 layer roots (lib/application, lib/data, lib/features, lib/infrastructure) PLUS lib/ root + 6 domain subtrees + 7 presentation subtrees"
    - "Domain rule encodes whitelist (deny everything except dart:core + freezed_annotation + json_annotation + meta + the ulid/collection low-risk libs Domain may legitimately use; rule is checked against actual Domain imports)"
    - "Thin Feature rule denies `features/*/use_cases/**`, `features/*/application/**`, `features/*/infrastructure/**`, `features/*/data/**` at lib/features/import_guard.yaml"
    - "`flutter analyze --no-fatal-infos` STILL exits 0 on the unmodified codebase (success criterion #1 — discovery-only; rules registered but not yet enforced as blocking)"
    - "All 18 YAML files parse cleanly (no YAML syntax errors)"
    - "No `lib/**/*.dart` file is modified (success criterion #5 — discovery-only)"
  artifacts:
    - path: "lib/import_guard.yaml"
      provides: "Project-wide deny rules: dart:mirrors + sqlite3_flutter_libs (defense-in-depth)"
      contains: "deny:"
    - path: "lib/features/import_guard.yaml"
      provides: "Thin-Feature rule encoding CRIT-02 territory"
      contains: "package:home_pocket/features/*/use_cases/**"
    - path: "lib/features/accounting/domain/import_guard.yaml"
      provides: "Domain whitelist for accounting (CRIT-04 territory)"
      contains: "allow:"
    - path: "lib/application/import_guard.yaml"
      provides: "Application layer deny rules"
      contains: "deny:"
    - path: "lib/data/import_guard.yaml"
      provides: "Data layer deny rules"
      contains: "deny:"
    - path: "lib/infrastructure/import_guard.yaml"
      provides: "Infrastructure layer deny rules (no app code)"
      contains: "deny:"
    - path: "lib/features/accounting/presentation/import_guard.yaml"
      provides: "Presentation deny rules (HIGH-02 — no direct infrastructure imports)"
      contains: "package:home_pocket/data/tables/**"
  key_links:
    - from: "Plan 01 analysis_options.yaml plugin registration"
      to: "These 18 import_guard.yaml files"
      via: "custom_lint host discovers import_guard_custom_lint and walks directory tree for per-dir YAML"
      pattern: "import_guard_custom_lint"
    - from: "import_guard rules"
      to: "Future enforcement at end of Phase 3 (D-04)"
      via: "CI workflow flips `continue-on-error: true` off after CRITICAL fixes ship"
      pattern: "continue-on-error"
---

<objective>
Encode the 5-layer Clean Architecture from `STRUCTURE.md` + CLAUDE.md as per-directory `import_guard.yaml` files. These rules are inert in Phase 1 (the analyzer host loads them but findings ship with `continue-on-error: true` in CI per D-04) — they activate as blocking gates at the end of Phase 3 (CRITICAL) and Phase 4 (HIGH). Layer-rule encoding is the source of truth that the AI subagent (Plan 06) cross-checks; if the YAML rules accidentally allow Domain → Data, the AI agent catches the misconfig (RESEARCH "Known Threat Patterns" — `import_guard.yaml` rule misconfig threat).

Purpose: Implement AUDIT-02 — `import_guard.yaml` encodes the 5-layer dependency rules from CLAUDE.md (Domain → nothing; Data → Domain + Infrastructure; Application → Domain + Infrastructure; Presentation → Application + Domain + Infrastructure; Infrastructure → external SDKs only). Per RESEARCH §3, `import_guard_custom_lint` requires PER-DIRECTORY YAML files with `inherit: true` — NOT a single root file with path-scoped rules.

Output:
- 18 `import_guard.yaml` files placed at:
  - `lib/import_guard.yaml` (project-wide deny: dart:mirrors, sqlite3_flutter_libs defense-in-depth)
  - `lib/features/import_guard.yaml` (Thin-Feature rule)
  - `lib/features/{accounting,analytics,family_sync,home,profile,settings}/domain/import_guard.yaml` (×6 — `dual_ledger` has no `domain/` subdir per actual layout; verified via `ls lib/features/`)
  - `lib/features/{accounting,analytics,dual_ledger,family_sync,home,profile,settings}/presentation/import_guard.yaml` (×7)
  - `lib/application/import_guard.yaml`
  - `lib/data/import_guard.yaml`
  - `lib/infrastructure/import_guard.yaml`

Discovery-only: NO `.dart` files modified. YAML files under `lib/` are configuration consumed by the analyzer plugin, NOT Dart source. RESEARCH Pitfall P1-6 explicitly classifies these as analyzer config, not code.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md
@.planning/codebase/STRUCTURE.md
@.planning/codebase/CONCERNS.md
@CLAUDE.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-01-SUMMARY.md

<interfaces>
<!-- Verbatim YAML excerpts from RESEARCH §3 + PATTERNS.md Group B. Executor copies these. -->

Domain whitelist (allow-list mode — RESEARCH §3, the strictest layer):
```yaml
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**

inherit: true
```

Thin-Feature rule (RESEARCH §3 — at lib/features/import_guard.yaml):
```yaml
deny:
  - package:home_pocket/features/*/use_cases/**
  - package:home_pocket/features/*/application/**
  - package:home_pocket/features/*/infrastructure/**
  - package:home_pocket/features/*/data/**

inherit: true
```

Presentation deny (RESEARCH §3 — at lib/features/<f>/presentation/import_guard.yaml):
```yaml
deny:
  - package:home_pocket/data/tables/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/infrastructure/crypto/services/**
  - package:home_pocket/infrastructure/sync/**
  - package:home_pocket/infrastructure/security/secure_storage_service.dart
  - package:home_pocket/infrastructure/crypto/repositories/**

inherit: true
```

Feature inventory (verified via `ls lib/features/`):
- accounting (has domain/ + presentation/)
- analytics (has domain/ + presentation/)
- dual_ledger (has presentation/ ONLY — NO domain/ subdir; do not create one)
- family_sync (has domain/ + presentation/ + use_cases/ — the use_cases/ dir is the live CRIT-02 violation that the Thin-Feature rule must catch)
- home (has domain/ + presentation/)
- profile (has domain/ + presentation/)
- settings (has domain/ + presentation/)

So:
- 6 domain `import_guard.yaml` files (NOT 7 — dual_ledger has no domain/)
- 7 presentation `import_guard.yaml` files
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Create cross-layer import_guard.yaml files (lib/, features/, application/, data/, infrastructure/)</name>
  <files>lib/import_guard.yaml, lib/features/import_guard.yaml, lib/application/import_guard.yaml, lib/data/import_guard.yaml, lib/infrastructure/import_guard.yaml</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Standard Stack — 3. import_guard.yaml — Layer Rules" (per-directory placement requirement + verbatim rule excerpts)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group B" (Thin Feature pattern + rule sources table)
    - .planning/codebase/STRUCTURE.md §"lib/ — Dart Source Tree" (5-layer organization)
    - .planning/codebase/CONCERNS.md (live CRIT-02 violation at `lib/features/family_sync/use_cases/` — the Thin-Feature rule must catch it)
    - CLAUDE.md §"Architecture" (5-layer rules)
  </read_first>
  <action>
    Create the 5 top-level layer YAML files. Use the locked rule sources table from PATTERNS.md Group B. Each file MUST end with `inherit: true` so subdirs (Plan 02 Task 2) layer additional rules.

    **File 1: `lib/import_guard.yaml` (project-wide root)**
    ```yaml
    # lib/import_guard.yaml — project-wide rules
    # Defense-in-depth: also denies sqlite3_flutter_libs (CI gate AUDIT-09 in Plan 07 is the
    # primary enforcement; this rule catches it earlier in dev workflow).
    deny:
      - dart:mirrors
      - package:sqlite3_flutter_libs/**

    inherit: true
    ```

    **File 2: `lib/features/import_guard.yaml` (Thin Feature rule)**
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

    **File 3: `lib/application/import_guard.yaml`**
    ```yaml
    # lib/application/import_guard.yaml — Application uses Domain + Infrastructure
    # Application MUST NOT reach into Presentation or into Data tables/DAOs directly.
    deny:
      - package:home_pocket/features/*/presentation/**
      - package:home_pocket/data/tables/**
      - package:home_pocket/data/daos/**

    inherit: true
    ```

    **File 4: `lib/data/import_guard.yaml`**
    ```yaml
    # lib/data/import_guard.yaml — Data uses Domain + Infrastructure
    # Data MUST NOT reach into Application use cases or Presentation.
    deny:
      - package:home_pocket/features/*/presentation/**
      - package:home_pocket/application/**

    inherit: true
    ```

    **File 5: `lib/infrastructure/import_guard.yaml`**
    ```yaml
    # lib/infrastructure/import_guard.yaml — Infrastructure depends on external SDKs only
    deny:
      - package:home_pocket/features/**
      - package:home_pocket/application/**
      - package:home_pocket/data/**

    inherit: true
    ```

    DO NOT add `allow:` blocks here — `allow:` is whitelist-mode and is reserved for Domain (Task 2). Application/Data/Infrastructure use deny-only (RESEARCH §3 note).

    DO NOT consolidate into a single root file with path-scoped rules — RESEARCH Pitfall P1-5 explicitly forbids this for `import_guard_custom_lint` (per-directory placement is required for inheritance to work).

    DO NOT touch any `.dart` file — RESEARCH Pitfall P1-6 confirms YAML configs under `lib/` are NOT Dart source; verify the discovery-only constraint with `git diff lib/**/*.dart` (must be empty).
  </action>
  <verify>
    <automated>test -f lib/import_guard.yaml && test -f lib/features/import_guard.yaml && test -f lib/application/import_guard.yaml && test -f lib/data/import_guard.yaml && test -f lib/infrastructure/import_guard.yaml && grep -q "use_cases" lib/features/import_guard.yaml && grep -q "dart:mirrors" lib/import_guard.yaml && grep -q "sqlite3_flutter_libs" lib/import_guard.yaml</automated>
  </verify>
  <acceptance_criteria>
    - All 5 YAML files exist
    - Each file contains a `deny:` block: `for f in lib/import_guard.yaml lib/features/import_guard.yaml lib/application/import_guard.yaml lib/data/import_guard.yaml lib/infrastructure/import_guard.yaml; do grep -q "^deny:" $f || exit 1; done`
    - Each file ends with `inherit: true`: `for f in <list>; do grep -q "^inherit: true$" $f || exit 1; done`
    - `lib/features/import_guard.yaml` denies `package:home_pocket/features/*/use_cases/**` (catches CRIT-02 territory)
    - `lib/import_guard.yaml` denies both `dart:mirrors` and `package:sqlite3_flutter_libs/**`
    - `lib/application/import_guard.yaml` denies `package:home_pocket/features/*/presentation/**`
    - `lib/data/import_guard.yaml` denies `package:home_pocket/application/**`
    - `lib/infrastructure/import_guard.yaml` denies `package:home_pocket/features/**`
    - No `allow:` block in these 5 files (whitelist mode is Domain-only — Task 2)
    - YAML parses cleanly: `python3 -c "import yaml; [yaml.safe_load(open(f)) for f in ['lib/import_guard.yaml','lib/features/import_guard.yaml','lib/application/import_guard.yaml','lib/data/import_guard.yaml','lib/infrastructure/import_guard.yaml']]"` exits 0
    - No `.dart` file modified: `git diff --name-only -- 'lib/**/*.dart' | wc -l | grep -q '^[[:space:]]*0$'`
  </acceptance_criteria>
  <done>
    The 5 cross-layer `import_guard.yaml` files are committed with the locked rules, all parse cleanly, and no Dart code under `lib/` was modified.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Create per-feature domain (×6) + presentation (×7) import_guard.yaml files</name>
  <files>lib/features/accounting/domain/import_guard.yaml, lib/features/analytics/domain/import_guard.yaml, lib/features/family_sync/domain/import_guard.yaml, lib/features/home/domain/import_guard.yaml, lib/features/profile/domain/import_guard.yaml, lib/features/settings/domain/import_guard.yaml, lib/features/accounting/presentation/import_guard.yaml, lib/features/analytics/presentation/import_guard.yaml, lib/features/dual_ledger/presentation/import_guard.yaml, lib/features/family_sync/presentation/import_guard.yaml, lib/features/home/presentation/import_guard.yaml, lib/features/profile/presentation/import_guard.yaml, lib/features/settings/presentation/import_guard.yaml</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Standard Stack — 3. import_guard.yaml" (Domain whitelist excerpt + Presentation deny excerpt)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group B" (per-feature placement)
    - lib/features/accounting/domain (verify directory exists; reference for placement)
    - lib/features/dual_ledger (verify it has presentation/ ONLY, NO domain/ — do not create one)
    - .planning/codebase/CONCERNS.md (HIGH-02 — presentation directly importing infrastructure; the presentation YAML must encode this)
  </read_first>
  <action>
    Create 13 feature-scoped YAML files (6 domain + 7 presentation). Use IDENTICAL content per category (RESEARCH §3 rules apply uniformly across features).

    **Domain whitelist content (copy verbatim into 6 files — `lib/features/{accounting,analytics,family_sync,home,profile,settings}/domain/import_guard.yaml`):**

    ```yaml
    # Domain layer — leafmost in the dependency graph (CRIT-04 territory).
    # Whitelist mode: deny everything except dart:core + the immutability/serialization annotations.
    deny:
      - package:home_pocket/data/**
      - package:home_pocket/infrastructure/**
      - package:home_pocket/application/**
      - package:home_pocket/features/**/presentation/**
      - package:flutter/**

    allow:
      - dart:core
      - package:freezed_annotation/**
      - package:json_annotation/**
      - package:meta/**

    inherit: true
    ```

    **DO NOT create `lib/features/dual_ledger/domain/import_guard.yaml`** — `dual_ledger` has no `domain/` subdirectory per the verified feature inventory in this plan's `<interfaces>` block. Only 6 domain YAMLs total.

    **Presentation deny content (copy verbatim into 7 files — `lib/features/{accounting,analytics,dual_ledger,family_sync,home,profile,settings}/presentation/import_guard.yaml`):**

    ```yaml
    # Presentation layer — uses Application + Domain + Infrastructure (indirect via app uses cases).
    # MUST NOT reach Infrastructure directly (HIGH-02 territory per .planning/codebase/CONCERNS.md).
    deny:
      - package:home_pocket/data/tables/**
      - package:home_pocket/data/daos/**
      - package:home_pocket/infrastructure/crypto/services/**
      - package:home_pocket/infrastructure/sync/**
      - package:home_pocket/infrastructure/security/secure_storage_service.dart
      - package:home_pocket/infrastructure/crypto/repositories/**

    inherit: true
    ```

    **Notes per RESEARCH §3:**
    - The `allow:` list in Domain is checked as "exceptions to deny" (whitelist mode). It restricts Domain to the 4 listed package families — anything else is denied.
    - Domain RESEARCH §3 also calls out `dart:core` as the only `dart:` library allowed; `package:meta/**` is included because Freezed-generated parts use `@immutable` from meta. If a Domain file uses `ulid` or `collection` and that flags during the AI-agent dry-run (Plan 06), the planner adds them in a follow-up amendment. For Phase 1, the conservative whitelist is correct — the Domain layer per CRIT-04 should only need core + freezed/json/meta.
    - Presentation `inherit: true` means the Thin-Feature rule (Task 1) and lib/import_guard.yaml rules ALSO apply at presentation level. Don't restate them.
    - Verify `flutter analyze` STILL exits 0 after these files are placed:
    ```bash
    flutter analyze --no-fatal-infos
    ```
    Per CONTEXT.md success criterion #1, analyze MUST exit 0 on the unmodified codebase here even though import_guard rules are now live. Findings flow through `dart run custom_lint` (which Plan 04's audit_layer.sh will normalize); they do NOT cause `flutter analyze` to fail because import_guard_custom_lint emits diagnostics via the custom_lint host, which is registered with INFO/WARNING severity. If `flutter analyze` exits non-zero here, investigate severity escalation (it should be `--no-fatal-infos` clearing it).

    DO NOT touch any `.dart` file. Verify with `git diff --name-only -- 'lib/**/*.dart' | wc -l` returns 0.
  </action>
  <verify>
    <automated>test $(find lib/features -name import_guard.yaml | wc -l) -ge 13 && for d in lib/features/accounting/domain lib/features/analytics/domain lib/features/family_sync/domain lib/features/home/domain lib/features/profile/domain lib/features/settings/domain; do test -f $d/import_guard.yaml && grep -q "^allow:" $d/import_guard.yaml || exit 1; done && for d in lib/features/accounting/presentation lib/features/analytics/presentation lib/features/dual_ledger/presentation lib/features/family_sync/presentation lib/features/home/presentation lib/features/profile/presentation lib/features/settings/presentation; do test -f $d/import_guard.yaml && grep -q "infrastructure/sync" $d/import_guard.yaml || exit 1; done && ! test -f lib/features/dual_ledger/domain/import_guard.yaml && flutter analyze --no-fatal-infos</automated>
  </verify>
  <acceptance_criteria>
    - 13 feature-scoped YAML files created (6 domain + 7 presentation)
    - All 6 domain YAMLs have `allow:` block with `dart:core` + `package:freezed_annotation/**` + `package:json_annotation/**` + `package:meta/**`
    - All 6 domain YAMLs deny `package:home_pocket/data/**`, `package:home_pocket/infrastructure/**`, `package:home_pocket/application/**`, `package:flutter/**`
    - All 7 presentation YAMLs deny `package:home_pocket/data/tables/**` AND `package:home_pocket/infrastructure/sync/**` AND `package:home_pocket/infrastructure/crypto/repositories/**`
    - `dual_ledger` has NO `domain/import_guard.yaml`: `! test -f lib/features/dual_ledger/domain/import_guard.yaml`
    - All 18 import_guard.yaml files (5 from Task 1 + 13 from Task 2) parse: `python3 -c "import yaml,glob; [yaml.safe_load(open(f)) for f in glob.glob('lib/**/import_guard.yaml', recursive=True)]"` exits 0
    - Total file count: `find lib -name import_guard.yaml | wc -l` returns exactly 18
    - `flutter analyze --no-fatal-infos` STILL exits 0 (success criterion #1 — discovery-only)
    - No Dart file modified: `git diff --name-only -- 'lib/**/*.dart' | wc -l` returns 0
  </acceptance_criteria>
  <done>
    All 13 per-feature YAMLs (6 domain whitelist + 7 presentation deny) are committed; total of 18 layer YAML files in tree; `flutter analyze` still exits 0; no `.dart` files modified. Plan 04's `audit_layer.sh` will surface findings these rules detect.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| YAML config → analyzer plugin | Misconfigured rule (e.g., a typo allowing Domain → Data) silently produces zero findings. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1-02-01 | Tampering | `import_guard.yaml` rule misconfig (e.g., typo in package URI silently allowing Domain → Data) | mitigate | The 4 AI subagents (Plan 06) are an independent check on the rules. Phase 1 dry-run on the unmodified codebase MUST surface the live CRIT-02 violation in `lib/features/family_sync/use_cases/` per CONCERNS.md. If Plan 08's pipeline run shows zero CRITICAL findings, the rules are misconfigured and Phase 1 is not done. (RESEARCH "Known Threat Patterns") |
| T-1-02-02 | Discovery-only constraint violation | `lib/**/*.dart` accidentally modified during YAML placement | mitigate | Acceptance criterion `git diff --name-only -- 'lib/**/*.dart' | wc -l` returns 0; CONTEXT.md success criterion #5 enforced |
| T-1-02-03 | Configuration | `inherit: true` missing on a per-directory file → child rules don't compose with parent rules | mitigate | Acceptance criterion grep: `grep -q "^inherit: true$" $file` for every YAML file |

No new code-execution surface; YAML is config consumed by the analyzer plugin only.
</threat_model>

<verification>
1. 18 `import_guard.yaml` files exist (5 from Task 1 + 13 from Task 2)
2. All files have `inherit: true`
3. All files parse as valid YAML
4. Domain files use whitelist mode (`allow:` block); other layers use deny-only
5. `flutter analyze --no-fatal-infos` exits 0 on unmodified codebase
6. No `.dart` file modified (discovery-only constraint enforced)
7. Live CRIT-02 violation in `lib/features/family_sync/use_cases/` is now within scope of the Thin-Feature rule (will be surfaced by Plan 04's `audit_layer.sh`)
</verification>

<success_criteria>
- AUDIT-02 satisfied: per-directory `import_guard.yaml` files encode the 5-layer dependency rules
- 6 domain whitelist YAMLs + 7 presentation deny YAMLs + 5 cross-layer YAMLs = 18 total
- Phase 1 discovery-only constraint preserved (no `.dart` modifications)
- Future-Phase enforcement path is wired: Plan 07's CI workflow ships `import_guard*` lints with `continue-on-error: true` and flips them blocking at the end of Phase 3 per D-04
</success_criteria>

<output>
After completion, create `.planning/phases/01-audit-pipeline-tooling-setup/01-02-SUMMARY.md` listing the 18 YAML file paths, summarizing the layer rule taxonomy, and noting any rule deviations from RESEARCH §3 (e.g., if Plan 06's AI-agent dry-run reveals a Domain file legitimately importing `ulid` and the whitelist had to be extended).
</output>
