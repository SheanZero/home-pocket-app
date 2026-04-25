---
phase: 01-audit-pipeline-tooling-setup
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - pubspec.yaml
  - pubspec.lock
  - analysis_options.yaml
  - scripts/install_audit_tools.sh
autonomous: true
requirements: [AUDIT-01, AUDIT-03]
tags: [tooling, dev-deps, analyzer-plugin, custom-lint]

must_haves:
  truths:
    - "`flutter pub get` resolves with `import_guard_custom_lint ^1.0.0` and `dart_code_linter ^3.0.0` added to dev_dependencies"
    - "`analyzer` package stays pinned at 7.x (no upgrade)"
    - "`analysis_options.yaml` registers `custom_lint` as an analyzer plugin"
    - "`flutter analyze --no-fatal-infos` exits 0 on the unmodified codebase after the changes"
    - "`dart run custom_lint` exits 0 on the unmodified codebase (riverpod_lint + import_guard_custom_lint discoverable)"
    - "`coverde` global-activate convention is documented in `scripts/install_audit_tools.sh` (NOT in pubspec) per Pitfall P1-3"
  artifacts:
    - path: "pubspec.yaml"
      provides: "dev_dependency entries for import_guard_custom_lint ^1.0.0 and dart_code_linter ^3.0.0 under a `# Audit Tooling` group"
      contains: "import_guard_custom_lint:"
    - path: "analysis_options.yaml"
      provides: "`analyzer.plugins` block listing `custom_lint`"
      contains: "plugins:"
    - path: "scripts/install_audit_tools.sh"
      provides: "Reproducible developer + CI bootstrap of the globally-activated coverde CLI"
      contains: "dart pub global activate coverde"
  key_links:
    - from: "analysis_options.yaml"
      to: "pubspec.yaml dev_dependencies"
      via: "`custom_lint` plugin auto-discovery scans dev_dependencies"
      pattern: "plugins:\\s*\\n\\s*-\\s*custom_lint"
    - from: "pubspec.lock"
      to: "analyzer 7.x"
      via: "Resolution stays on analyzer 7.x because import_guard_custom_lint and dart_code_linter ^3.0.0 are analyzer-7-compatible"
      pattern: "analyzer"
---

<objective>
Register the audit toolchain so `custom_lint` discovers `import_guard_custom_lint` alongside the already-installed `riverpod_lint`, and provide the documented bootstrap path for the globally-activated `coverde` CLI. This is the foundational wave-1 task — every later plan depends on these dev_deps and the `custom_lint` plugin being live.

Purpose: Implement AUDIT-01 (deps with verified pinned versions per RESEARCH §1 — analyzer-7 lock) and AUDIT-03 (`analysis_options.yaml` registers the plugin host so `flutter analyze` exercises both `riverpod_lint` and `import_guard_custom_lint`).

Output:
- `pubspec.yaml` extended with one new `# Audit Tooling` group in `dev_dependencies`
- `pubspec.lock` updated by `flutter pub get`
- `analysis_options.yaml` extended with `analyzer.plugins: [custom_lint]`
- `scripts/install_audit_tools.sh` created to document/run the `coverde` global activate
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md
@.planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md
@CLAUDE.md
@pubspec.yaml
@analysis_options.yaml

<interfaces>
<!-- Pin specs and YAML keys the executor must reproduce verbatim. From RESEARCH.md §1 + §2 + PATTERNS.md Group A. -->

Pinned dev_dependency entries (RESEARCH §1):
```yaml
  # Audit Tooling
  import_guard_custom_lint: ^1.0.0
  dart_code_linter: ^3.0.0
```
**Do NOT add `coverde` to pubspec.** RESEARCH Pitfall P1-3: all `coverde` versions require analyzer ≥8.0.0 and would break the analyzer-7 lock.

Final analysis_options.yaml shape (RESEARCH §2; current 14 lines + 2 new lines under `analyzer:`):
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
  plugins:
    - custom_lint

linter:
  rules:
    prefer_single_quotes: true
    prefer_relative_imports: true
    avoid_print: false
```
RESEARCH Pitfall P1-4: `plugins:` MUST be a child of `analyzer:`, NOT a top-level key.

scripts/install_audit_tools.sh contents (greenfield, RESEARCH §1 install commands):
```bash
#!/usr/bin/env bash
# scripts/install_audit_tools.sh
# Bootstrap audit tools that cannot live in pubspec.yaml due to analyzer-7 lock (Pitfall P1-3).
# Run once on a developer machine and at CI runner setup time.
set -euo pipefail

echo "[audit:install] Activating coverde globally (pinned to 0.3.0+1)..."
dart pub global activate coverde 0.3.0+1

echo "[audit:install] Verifying coverde is on PATH..."
if ! command -v coverde >/dev/null 2>&1; then
  echo "[audit:install] WARNING: coverde not on PATH — add ~/.pub-cache/bin to PATH" >&2
fi

echo "[audit:install] Done."
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Extend pubspec.yaml dev_dependencies + run pub get</name>
  <files>pubspec.yaml, pubspec.lock</files>
  <read_first>
    - pubspec.yaml (current dev_dependencies block — preserve all existing groups exactly)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Standard Stack — 1. Tooling Verification" (analyzer-7 lock; the `import_guard_custom_lint ^1.0.0` and `dart_code_linter ^3.0.0` picks)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group A — pubspec.yaml" (the `# Audit Tooling` group placement pattern)
    - CLAUDE.md (`sqlcipher_flutter_libs` only — verify the lockfile keeps that)
  </read_first>
  <action>
    Append to `pubspec.yaml` `dev_dependencies` block (after the existing `# Testing` group, preserving all prior content) per the locked picks (D-01-implicit + RESEARCH §1, ALL CONTEXT.md decisions):

    ```yaml
      # Audit Tooling
      import_guard_custom_lint: ^1.0.0
      dart_code_linter: ^3.0.0
    ```

    Then run:
    ```bash
    flutter pub get
    ```

    Pubspec.lock will update. Verify with:
    ```bash
    grep -A 1 '^  analyzer:' pubspec.lock | head -3
    ```
    The version line should show `version: "7.x.x"` — analyzer must NOT bump (the entire RESEARCH §1 reasoning depends on this lock holding).

    Verify lockfile cleanliness:
    ```bash
    flutter pub deps --no-dev | grep -i sqlite
    ```
    Output MUST contain `sqlcipher_flutter_libs` and MUST NOT contain `sqlite3_flutter_libs` (CLAUDE.md pitfall #6 + AUDIT-09 is in Plan 07).

    DO NOT add `coverde` here — Pitfall P1-3 (all coverde versions require analyzer ≥8.0.0; install globally instead, see Task 3).

    DO NOT modify `flutter_lints`, the existing `# Code Generation` group, or any other dev_dep. Append-only.
  </action>
  <verify>
    <automated>flutter pub get && grep -q "import_guard_custom_lint:" pubspec.yaml && grep -q "dart_code_linter:" pubspec.yaml && grep -A 1 '^  analyzer:' pubspec.lock | grep -q 'version: "7' && ! grep -q sqlite3_flutter_libs pubspec.lock</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "import_guard_custom_lint: \\^1.0.0" pubspec.yaml` succeeds
    - `grep -q "dart_code_linter: \\^3.0.0" pubspec.yaml` succeeds
    - `grep -q "# Audit Tooling" pubspec.yaml` succeeds (new group header committed)
    - `! grep -q "coverde:" pubspec.yaml` (coverde NOT in pubspec — Pitfall P1-3)
    - `flutter pub get` exits 0
    - `grep -A 1 '^  analyzer:' pubspec.lock | grep -q 'version: "7'` succeeds (analyzer pinned at 7.x; no upgrade)
    - `! grep -q "sqlite3_flutter_libs" pubspec.lock` (no transitive SQLCipher conflict was pulled in)
    - The existing dev_dependency entries (`flutter_test`, `flutter_lints`, `build_runner`, `freezed`, `json_serializable`, `riverpod_generator`, `custom_lint`, `riverpod_lint`, `drift_dev`, `mockito`, `mocktail`) are all still present and at their original versions
  </acceptance_criteria>
  <done>
    `pubspec.yaml` has the `# Audit Tooling` group with the two new pinned deps; `pubspec.lock` reflects the resolution; analyzer is still 7.x; no SQLCipher conflict.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Register custom_lint plugin in analysis_options.yaml + verify analyze passes</name>
  <files>analysis_options.yaml</files>
  <read_first>
    - analysis_options.yaml (the current 14-line file — preserve EVERY existing line)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Standard Stack — 2. analysis_options.yaml Final Shape" (the verbatim final shape) AND §"Common Pitfalls — Pitfall P1-4" (`plugins:` indentation requirement)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Group A — analysis_options.yaml" (the extension pattern)
  </read_first>
  <action>
    Edit `analysis_options.yaml` to add an `analyzer.plugins:` block. Resulting file MUST be byte-identical to:

    ```yaml
    include: package:flutter_lints/flutter.yaml

    analyzer:
      exclude:
        - "**/*.g.dart"
        - "**/*.freezed.dart"
      errors:
        invalid_annotation_target: ignore
      plugins:
        - custom_lint

    linter:
      rules:
        prefer_single_quotes: true
        prefer_relative_imports: true
        avoid_print: false
    ```

    Critical (RESEARCH Pitfall P1-4): `plugins:` MUST be a child of `analyzer:` (4-space indent followed by `- custom_lint` at 6-space indent). Some import_guard READMEs show `plugins:` at top-level — that is the OLDER format and breaks current analyzer.

    DO NOT touch `linter.rules`. DO NOT remove `**/*.g.dart` or `**/*.freezed.dart` from `analyzer.exclude` (RESEARCH §"Project Constraints" — generated-file exclusion is sacred).

    A single `custom_lint` entry covers BOTH plugins (riverpod_lint already installed + import_guard_custom_lint added in Task 1). custom_lint discovers them automatically by scanning dev_dependencies. RESEARCH §2 + verified via pub.dev custom_lint README.

    Then run baseline checks:
    ```bash
    flutter analyze --no-fatal-infos
    dart run custom_lint
    ```
    Both must exit 0 on the unmodified codebase. (Plans 02 will add `import_guard.yaml` files which will then surface live findings; Phase 1's CI workflow ships those with `continue-on-error: true` per D-04.) For THIS task, no `import_guard.yaml` files exist yet, so `import_guard_custom_lint` should be plugin-discovered but emit no findings.

    Per CONTEXT.md success criterion #1, `flutter analyze` MUST exit 0 here so we can prove the plugin host is wired correctly without depending on layer rules existing yet.
  </action>
  <verify>
    <automated>grep -E '^  plugins:$' analysis_options.yaml && grep -E '^    - custom_lint$' analysis_options.yaml && flutter analyze --no-fatal-infos && dart run custom_lint</automated>
  </verify>
  <acceptance_criteria>
    - `grep -E '^  plugins:$' analysis_options.yaml` succeeds (the `plugins:` key is at 2-space indent under `analyzer:`)
    - `grep -E '^    - custom_lint$' analysis_options.yaml` succeeds (the entry is at 4-space indent — child of `plugins:`)
    - The existing `analyzer.exclude` lines (`**/*.g.dart`, `**/*.freezed.dart`) are still present
    - The existing `linter.rules` (`prefer_single_quotes: true`, `prefer_relative_imports: true`, `avoid_print: false`) are still present
    - `flutter analyze --no-fatal-infos` exits 0
    - `dart run custom_lint` exits 0
    - `! grep -E '^plugins:$' analysis_options.yaml` (no top-level `plugins:` — confirms Pitfall P1-4 avoided)
  </acceptance_criteria>
  <done>
    `analysis_options.yaml` registers `custom_lint` under `analyzer.plugins`; both `flutter analyze` and `dart run custom_lint` exit 0 on the unmodified codebase. The plugin host is live and ready for Plan 02 to drop in `import_guard.yaml` files.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Create scripts/install_audit_tools.sh for coverde global activate</name>
  <files>scripts/install_audit_tools.sh</files>
  <read_first>
    - .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md §"Standard Stack — 1. Tooling Verification" (`coverde` global activate command + Pitfall P1-3 + Pitfall P1-11 supply-chain pin)
    - .planning/phases/01-audit-pipeline-tooling-setup/01-PATTERNS.md §"Shared Patterns — Shell script header" (POSIX wrapper template)
    - scripts/arb_to_csv.dart (sole Dart-script precedent — confirms `scripts/` is the right home)
  </read_first>
  <action>
    Create `scripts/install_audit_tools.sh` with the verbatim content (RESEARCH §1 install commands + Pitfall P1-11 supply-chain pin):

    ```bash
    #!/usr/bin/env bash
    # scripts/install_audit_tools.sh
    # Bootstrap audit tools that cannot live in pubspec.yaml due to analyzer-7 lock.
    # See .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md Pitfall P1-3:
    # all coverde versions require analyzer >=8.0.0, which would break the project's
    # analyzer-7 pin (json_serializable + riverpod_lint). Global-activate sidesteps it.
    set -euo pipefail

    echo "[audit:install] Activating coverde globally (pinned to 0.3.0+1)..."
    dart pub global activate coverde 0.3.0+1

    echo "[audit:install] Verifying coverde is on PATH..."
    if ! command -v coverde >/dev/null 2>&1; then
      echo "[audit:install] WARNING: coverde not on PATH — add ~/.pub-cache/bin to PATH" >&2
    fi

    echo "[audit:install] Done."
    ```

    Then make executable:
    ```bash
    chmod +x scripts/install_audit_tools.sh
    ```

    Pin to `0.3.0+1` matches the CI workflow Plan 07 will create (RESEARCH §"CI Workflow" — `dart pub global activate coverde 0.3.0+1`). Pinning prevents supply-chain drift (RESEARCH "Known Threat Patterns").

    DO NOT execute the script in this task. Coverde global-activate is a side effect on the developer's `~/.pub-cache/`; the executor running this plan does not need coverde for any Phase-1 verification (Phase 2 BASE-05 is the first place coverde is invoked). The script's existence is the AUDIT-01 deliverable for the coverde piece. Plan 02–07 do not depend on coverde being activated.
  </action>
  <verify>
    <automated>test -x scripts/install_audit_tools.sh && grep -q "dart pub global activate coverde 0.3.0+1" scripts/install_audit_tools.sh && bash -n scripts/install_audit_tools.sh</automated>
  </verify>
  <acceptance_criteria>
    - `scripts/install_audit_tools.sh` exists
    - File is executable: `[ -x scripts/install_audit_tools.sh ]`
    - Shebang is `#!/usr/bin/env bash` (first line)
    - Strict mode is enabled: `grep -q '^set -euo pipefail$' scripts/install_audit_tools.sh`
    - Coverde version is pinned: `grep -q "dart pub global activate coverde 0.3.0+1" scripts/install_audit_tools.sh`
    - Bash syntax check passes: `bash -n scripts/install_audit_tools.sh` exits 0
    - Comment header references the analyzer-7 lock rationale (`grep -q "analyzer-7 lock" scripts/install_audit_tools.sh`)
  </acceptance_criteria>
  <done>
    `scripts/install_audit_tools.sh` exists, is executable, has correct shebang + strict mode, pins coverde to `0.3.0+1`, and parses cleanly. AUDIT-01's coverde piece is delivered as a documented bootstrap script per the analyzer-7-lock workaround.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| pub.dev → developer machine / CI runner | Untrusted package contents enter via `flutter pub get` and `dart pub global activate`. Mitigation = pinned versions (caret for pubspec entries, exact `0.3.0+1` for coverde global). |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1-01-01 | Tampering | `pubspec.yaml` dev_dependency entries | mitigate | Pin via caret (`^1.0.0`, `^3.0.0`); commit `pubspec.lock` so CI re-resolution is reviewed; RESEARCH Pitfall P1-1/P1-2 calls out the analyzer-version traps |
| T-1-01-02 | Tampering | `coverde` global-activate supply chain | mitigate | Pin to `0.3.0+1` exactly in `scripts/install_audit_tools.sh` and matching CI workflow (Plan 07); RESEARCH Pitfall P1-11 |
| T-1-01-03 | Configuration | `analysis_options.yaml` `plugins:` indentation regression | mitigate | Acceptance criteria explicitly grep for the 2-space `plugins:` and 4-space `- custom_lint` indents (Pitfall P1-4) |
| T-1-01-04 | Tampering | Transitive `sqlite3_flutter_libs` creep | mitigate | Acceptance criterion `! grep -q sqlite3_flutter_libs pubspec.lock` after `flutter pub get` (defense-in-depth ahead of the AUDIT-09 CI gate in Plan 07; this is T-1-09 surfaced early) |

No new threat surface beyond the version-pinning controls already named.
</threat_model>

<verification>
1. `flutter pub get` succeeds with no version conflicts
2. `flutter analyze --no-fatal-infos` exits 0
3. `dart run custom_lint` exits 0 (riverpod_lint + import_guard_custom_lint both discovered, both report 0 lints since no `import_guard.yaml` files exist yet)
4. Analyzer pinned at 7.x in `pubspec.lock`
5. `scripts/install_audit_tools.sh` parses with `bash -n` and is executable
6. No `lib/**/*.dart` file modified (discovery-only constraint)
</verification>

<success_criteria>
- AUDIT-01 partially satisfied: `import_guard_custom_lint ^1.0.0` and `dart_code_linter ^3.0.0` in dev_dependencies; coverde install path documented in `scripts/install_audit_tools.sh` (NOT in pubspec, per analyzer-7 lock)
- AUDIT-03 satisfied: `analysis_options.yaml` registers `custom_lint`; `flutter analyze` exits 0 on unmodified codebase
- `pubspec.lock` analyzer pin held at 7.x — RESEARCH-flagged traps (Pitfalls P1-1/P1-2/P1-3) avoided
- Wave-2 plans can now drop in `import_guard.yaml` files and have them activate via the registered plugin
</success_criteria>

<output>
After completion, create `.planning/phases/01-audit-pipeline-tooling-setup/01-01-SUMMARY.md` describing the deps added, the analyzer.plugins registration, the coverde install convention, and any deviations from RESEARCH §1 if pub.dev versions shifted between research and execution.
</output>
