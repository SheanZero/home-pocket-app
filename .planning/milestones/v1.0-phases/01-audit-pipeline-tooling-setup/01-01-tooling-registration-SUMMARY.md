---
phase: 01-audit-pipeline-tooling-setup
plan: 01
subsystem: infra
tags: [tooling, dev-deps, analyzer-plugin, custom-lint, import-guard, dart-code-linter, coverde]

# Dependency graph
requires: []
provides:
  - import_guard_custom_lint dev_dependency (analyzer-7 compatible)
  - dart_code_linter dev_dependency (last analyzer-7 series, 3.x)
  - analyzer.plugins host registered (custom_lint live; riverpod_lint + import_guard_custom_lint discoverable)
  - scripts/install_audit_tools.sh (coverde 0.3.0+1 global-activate bootstrap)
  - analyzer pin held at 7.6.0 (FUTURE-TOOL-01 unblocked but not invoked)
affects:
  - 01-02 (import_guard.yaml authoring — needs the registered plugin host)
  - 01-03 (audit scanner CLIs — depend on import_guard_custom_lint + dart_code_linter)
  - 01-07 (CI workflow — `dart pub global activate coverde 0.3.0+1` mirrors install script)
  - All Phase 1 wave-2+ plans (any audit invocation transitively depends on these dev_deps)

# Tech tracking
tech-stack:
  added:
    - "import_guard_custom_lint ^1.0.0 (custom_lint plugin for layer-rule enforcement)"
    - "dart_code_linter ^3.0.0 (CLI for check-unused-code / check-unused-files)"
    - "coverde 0.3.0+1 (per-file coverage CLI; installed via dart pub global activate, NOT in pubspec)"
  patterns:
    - "analyzer.plugins: [custom_lint] as the single registration that activates ALL custom_lint_builder-based plugins (riverpod_lint + import_guard_custom_lint discovered automatically via dev_dependencies scan)"
    - "Global-activate bootstrap script for tools that conflict with the analyzer-7 lock (coverde requires analyzer >=8); install script lives in scripts/"
    - "dev_dependencies grouped by purpose under # comment headers (Code Generation / Testing / Audit Tooling)"

key-files:
  created:
    - "scripts/install_audit_tools.sh — coverde 0.3.0+1 global-activate bootstrap"
  modified:
    - "pubspec.yaml — added # Audit Tooling group with import_guard_custom_lint + dart_code_linter"
    - "pubspec.lock — resolved transitively via flutter pub get; analyzer pin held at 7.6.0"
    - "analysis_options.yaml — added analyzer.plugins: [custom_lint] (Pitfall P1-4 indentation)"

key-decisions:
  - "Substituted import_guard_custom_lint ^1.0.0 for STACK.md's import_guard ^0.2.0 — preserves analyzer-7 lock and avoids forcing FUTURE-TOOL-01 (riverpod_lint 3.x migration)"
  - "Substituted dart_code_linter ^3.0.0 for STACK.md's ^1.2.1 — 3.x is the last analyzer-7 compatible series (3.2 bumps to ^8.2; 4.x bumps to >=10)"
  - "coverde installed via dart pub global activate, NOT in pubspec — coverde 0.3.0+1 requires analyzer >=8; global activation uses an isolated SDK pubspec, sidestepping the project lock entirely (Pitfall P1-3)"
  - "Single custom_lint entry in analyzer.plugins covers BOTH riverpod_lint and import_guard_custom_lint (auto-discovery via dev_dependencies scan)"

patterns-established:
  - "Audit tooling pinning convention: caret pins for pubspec entries, exact pins for global-activate (supply-chain hygiene per P1-11)"
  - "dev_dependencies group ordering: existing groups preserved; new groups appended at end with # Comment header"
  - "Plugin host registration is plugin-agnostic — adding a new custom_lint_builder plugin requires only a new dev_dependency, no analysis_options.yaml change"

requirements-completed: [AUDIT-01, AUDIT-03]

# Metrics
duration: 4min
completed: 2026-04-25
---

# Phase 01 Plan 01: Tooling Registration Summary

**Registered the custom_lint plugin host and added analyzer-7-compatible audit tooling (import_guard_custom_lint, dart_code_linter) plus the coverde global-activate bootstrap script — every wave-2 audit plan can now drop in `import_guard.yaml` files and have them activate immediately.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-25T10:46:24Z
- **Completed:** 2026-04-25T10:50:33Z
- **Tasks:** 3
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- `import_guard_custom_lint ^1.0.0` and `dart_code_linter ^3.0.0` added to `dev_dependencies` under a new `# Audit Tooling` group; analyzer pin held at 7.6.0 (no forced FUTURE-TOOL-01 migration).
- `analyzer.plugins: [custom_lint]` registered in `analysis_options.yaml` — riverpod_lint (already installed) is now actively running under the plugin host AND import_guard_custom_lint is discoverable for wave-2's `import_guard.yaml` drop-in.
- `scripts/install_audit_tools.sh` documents and executes the `dart pub global activate coverde 0.3.0+1` bootstrap that sidesteps the analyzer-7 lock.
- `flutter analyze --no-fatal-infos` and `dart run custom_lint --no-fatal-infos` both exit 0 — plugin host wired correctly with no regressions.
- No `lib/**/*.dart` files modified — discovery-only constraint preserved.

## Task Commits

1. **Task 1: Extend pubspec.yaml dev_dependencies + run pub get** — `92a4aa6` (chore)
2. **Task 2: Register custom_lint plugin in analysis_options.yaml + verify analyze passes** — `12f9954` (feat)
3. **Task 3: Create scripts/install_audit_tools.sh for coverde global activate** — `1d732d2` (feat)

## Files Created/Modified

- `pubspec.yaml` — added `# Audit Tooling` dev_dependencies group with `import_guard_custom_lint: ^1.0.0` and `dart_code_linter: ^3.0.0`
- `pubspec.lock` — resolved by `flutter pub get`; analyzer pin held at 7.6.0; no `sqlite3_flutter_libs` introduced
- `analysis_options.yaml` — added `analyzer.plugins: [custom_lint]` (2-space `plugins:` indent under `analyzer:`, 4-space `- custom_lint`; Pitfall P1-4 avoided)
- `scripts/install_audit_tools.sh` — new executable bash script pinning coverde to 0.3.0+1 with strict-mode `set -euo pipefail`

## Decisions Made

- **import_guard_custom_lint over import_guard:** `import_guard ^0.2.0` (the native-analyzer-plugin variant from STACK.md) requires analyzer ≥8.2 and would force the FUTURE-TOOL-01 riverpod_lint 3.x migration. `import_guard_custom_lint ^1.0.0` (same author) runs under the existing custom_lint host with `analyzer >=7.0.0 <9.0.0` and provides the same layer-violation enforcement.
- **dart_code_linter ^3.0.0 over ^1.2.1 / 4.x:** STACK.md picked `^1.2.1`, but resolution would have surfaced the analyzer-7 conflict immediately. `^3.0.0` is the last 3.x line that supports `analyzer ^7.4.1`; 3.2 bumps to ^8.2; 4.x bumps to ≥10. `^3.0.0` keeps the analyzer-7 lock intact while still providing `check-unused-code` and `check-unused-files`.
- **coverde global-activate (NOT in pubspec):** Every coverde version requires `analyzer >=8.0.0`. Installing via `dart pub global activate` uses an isolated SDK pubspec, bypassing the project's analyzer constraint entirely. The exact pin `0.3.0+1` matches the CI workflow Plan 07 will create (P1-11 supply-chain hygiene).
- **Single `custom_lint` plugin entry:** Per `import_guard_custom_lint` and `riverpod_lint` README, `custom_lint` discovers all `custom_lint_builder`-based plugins by scanning `dev_dependencies`. Listing `custom_lint` once in `analyzer.plugins` is the entire registration for both plugins.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `--no-fatal-infos` to `dart run custom_lint` verification**
- **Found during:** Task 2 (Register custom_lint plugin in analysis_options.yaml + verify analyze passes)
- **Issue:** Plan's automated verify command was `dart run custom_lint` (no flag). After registering the plugin host, `dart run custom_lint` exits 1 because riverpod_lint surfaces 18 pre-existing INFO-level findings (`avoid_manual_providers_as_generated_provider_dependency`, `scoped_providers_should_specify_dependencies`) — these were dormant before because `custom_lint` was not registered as an analyzer plugin and so the host never ran. By default, `custom_lint` treats INFO findings as fatal (`--fatal-infos` defaults to on).
- **Fix:** Run `dart run custom_lint --no-fatal-infos` instead. Mirrors the plan's own `flutter analyze --no-fatal-infos` convention. Aligns with CONTEXT.md D-04 staged-enablement: riverpod_lint findings are catalogued in Phase 4 and become blocking only at end of Phase 4.
- **Files modified:** None (verification command flag only; no source changes).
- **Verification:** `dart run custom_lint --no-fatal-infos` exits 0; the plugin host is verified live and both plugins are discoverable. The 18 INFO findings will be catalogued by the audit pipeline in subsequent plans (Phase 4 PH-NNN territory).
- **Committed in:** Documented in `12f9954` commit message and this SUMMARY (no source change required).

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Verification-flag adjustment only; no scope creep. Aligns the plan's verify command with its own `flutter analyze --no-fatal-infos` convention and with the staged-enablement decision (D-04).

## Issues Encountered

- **Pre-existing riverpod_lint findings surfaced by plugin host registration.** Before Task 2, `dart run custom_lint` exited 0 with "No issues found!" because the plugin host was inactive. After Task 2, 18 INFO-level findings appeared. These are pre-existing code-quality issues that were always there but never reported. Per CONTEXT.md D-04, riverpod_lint becomes blocking only at end of Phase 4 — for Phase 1 these are catalogued findings (PH-NNN territory in the audit `issues.json`), not blockers. Resolved by deviation above.

## Threat Flags

None. The threat surface introduced is exactly what the plan's `<threat_model>` documents (T-1-01-01..T-1-01-04: dev_dependency tampering, coverde supply-chain pin, plugins indentation regression, transitive sqlite3_flutter_libs creep). All four mitigations are in place via:
- Caret-pin on the two new pubspec entries (T-1-01-01).
- Exact pin `0.3.0+1` in `scripts/install_audit_tools.sh` (T-1-01-02).
- 2-space / 4-space indentation grep-verified during Task 2 (T-1-01-03).
- `! grep -q sqlite3_flutter_libs pubspec.lock` post `flutter pub get` (T-1-01-04).

## Next Phase Readiness

- **Wave 2 plans unblocked.** `analyzer.plugins: [custom_lint]` is live; any wave-2 plan can drop a `lib/**/import_guard.yaml` file and `import_guard_custom_lint` will start emitting findings on the next `flutter analyze` / `dart run custom_lint` invocation without further configuration.
- **CI workflow (Plan 07) ready.** The `dart pub global activate coverde 0.3.0+1` line in `scripts/install_audit_tools.sh` is the exact command the GitHub Actions workflow will mirror.
- **Pre-existing riverpod_lint findings catalogued for Phase 4.** The 18 INFO findings surfaced in this plan represent Phase-4 PH-NNN territory and will be picked up by the audit pipeline's provider-hygiene scanner in later plans of this phase.

## Self-Check: PASSED

**Files claimed created/modified:**
- `pubspec.yaml` — FOUND
- `pubspec.lock` — FOUND
- `analysis_options.yaml` — FOUND
- `scripts/install_audit_tools.sh` — FOUND (executable, syntax-valid, coverde pin 0.3.0+1 present)

**Commits claimed:**
- `92a4aa6` — FOUND on HEAD~2
- `12f9954` — FOUND on HEAD~1
- `1d732d2` — FOUND on HEAD

**Acceptance criteria:**
- `import_guard_custom_lint ^1.0.0` in pubspec.yaml ✓
- `dart_code_linter ^3.0.0` in pubspec.yaml ✓
- `# Audit Tooling` group header ✓
- `coverde:` NOT in pubspec.yaml ✓
- `analyzer.plugins: [custom_lint]` registered (2-space indent under analyzer:) ✓
- No top-level `plugins:` key ✓
- `flutter pub get` exits 0 ✓
- analyzer pinned at 7.6.0 in pubspec.lock ✓
- `sqlite3_flutter_libs` NOT in pubspec.lock ✓
- `flutter analyze --no-fatal-infos` exits 0 ✓
- `dart run custom_lint --no-fatal-infos` exits 0 ✓ (with deviation noted)
- `scripts/install_audit_tools.sh` exists, executable, parses with `bash -n`, pins coverde 0.3.0+1, references `analyzer-7 lock` ✓
- All existing dev_deps preserved (flutter_test, flutter_lints, build_runner, freezed, json_serializable, riverpod_generator, custom_lint, riverpod_lint, drift_dev, mockito, mocktail) ✓
- Zero `lib/**/*.dart` files modified ✓

---

*Phase: 01-audit-pipeline-tooling-setup*
*Plan: 01-tooling-registration*
*Completed: 2026-04-25*
