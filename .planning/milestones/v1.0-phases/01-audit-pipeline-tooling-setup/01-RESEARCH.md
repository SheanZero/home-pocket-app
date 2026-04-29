# Phase 1: Audit Pipeline + Tooling Setup — Research

**Researched:** 2026-04-25
**Domain:** Flutter/Dart static-analysis tooling, analyzer-plugin orchestration, audit-pipeline scripting
**Confidence:** HIGH

---

## Summary

Phase 1 stands up the hybrid audit pipeline (4 tooling scanners + 4 AI-agent semantic scanners) and produces the stable-ID `issues.json` catalogue that defines "done" for every fix phase. **Discovery only — no `lib/` code is modified.** The locked decisions in `01-CONTEXT.md` (D-01..D-11 + Claude's Discretion) bind: 8 scanners, JSON shards under `.planning/audit/{shards,agent-shards}/`, `scripts/merge_findings.dart` dedupes and assigns stable IDs (`LV-NNN`/`PH-NNN`/`DC-NNN`/`RD-NNN`), GitHub Actions CI with staged enablement.

**Critical research finding (red flag for the planner):** the original tool stack proposed in `STACK.md` does **not** install cleanly against the project's currently-resolved analyzer 7.6.0. `import_guard 0.2.0` requires analyzer ≥8.2.0 and `dart_code_linter 4.x` requires analyzer ≥10. Both conflict with `riverpod_lint 2.6.5` (pinned at `analyzer ^7.0.0`) and `json_serializable 6.9.5` (pinned at `analyzer >=6.9.0 <8.0.0`). FUTURE-TOOL-01 explicitly defers the analyzer-bump migration. The resolution that keeps the analyzer-7 stack intact is documented below — different package picks but same audit coverage.

**Primary recommendation:** Use `import_guard_custom_lint ^1.0.0` (analyzer 7.x compatible, runs as a `custom_lint` plugin alongside `riverpod_lint`) instead of `import_guard`; pin `dart_code_linter ^3.0.0` (the last 3.x line that supports `analyzer ^7.4.1`) for `check-unused-code` / `check-unused-files`; install `coverde` via `dart pub global activate` (bypasses pubspec analyzer constraint entirely). All four tooling scanners + the merger script are thin POSIX-shell wrappers around Dart cores following the `scripts/arb_to_csv.dart` precedent. CI is greenfield (`.github/` does not exist); the workflow ships with `continue-on-error: true` on every gate except the two safe-immediately gates.

---

## User Constraints (from CONTEXT.md)

### Locked Decisions

**AI-Agent Semantic Scan (AUDIT-07):**
- **D-01:** Invocation is a project-local GSD slash command `/gsd-audit-semantic` that spawns four parallel subagents — one per scan dimension: (a) misplaced `features/*/use_cases/`, (b) semantic duplication / parallel implementations, (c) indirect layer violations via type aliases or transitive imports, (d) Drift unused-column detection. Each agent has a locked prompt file under `.claude/commands/audit/` (or equivalent project-local path) so prompts are version-controlled and Phase 8 re-runs the same exact contract.
- **D-02:** Agents consume codebase maps (`.planning/codebase/CONCERNS.md` + `STRUCTURE.md` + `CONVENTIONS.md`) for context plus a pre-computed file list scoped to that agent's dimension (e.g., the layer-violation agent gets all files under `lib/features/*/use_cases/` + Domain files via Glob). Token-efficient and deterministic between Phase 1 and Phase 8 runs.
- **D-03:** Each scanner (4 tooling + 4 AI agents = 8 total) writes its own JSON shard to `.planning/audit/shards/<tool>.json`. `scripts/merge_findings.dart` reads all shards, dedupes overlapping findings (same `file_path` + `line_start` + `category`), assigns stable IDs, sorts by severity-then-category, writes `issues.json`. Each finding records `tool_source` so dedupe decisions are auditable.

**CI Gate Enforcement Timing:**
- **D-04:** Staged enablement aligned to fix-phase exit gates. Phase 1 ships every gate in `report-only` mode (warnings logged in CI, never blocks). Each gate flips to blocking when its corresponding fix phase closes:
  - End of Phase 1: `sqlite3_flutter_libs` reject + `build_runner` stale-diff become **blocking** (no findings to clear; safe immediately).
  - End of Phase 3: `import_guard` becomes **blocking**.
  - End of Phase 4: `riverpod_lint` / `custom_lint` becomes **blocking**.
  - End of Phase 5: i18n / hardcoded-CJK / theme-token checks become **blocking**.
  - End of Phase 6: `dart_code_linter` (`check-unused-code`, `check-unused-files`) + `coverde` per-file ≥80% become **blocking**.
  - End of Phase 8: all gates remain blocking permanently.
- **D-05:** CI provider: GitHub Actions. `.github/workflows/audit.yml` runs on every PR + push to `main`. Repo currently has no `.github/workflows/` directory — this initiative is greenfield for CI.

**Stable Finding ID Scheme:**
- **D-06:** ID format = category prefix + zero-padded 3-digit sequence: `LV-NNN` / `PH-NNN` / `DC-NNN` / `RD-NNN`. Sequence assigned by `merge_findings.dart` in deterministic sort order (`file_path` ascending, then `line_start` ascending). Width 3 caps each category at 999.
- **D-07:** ID is permanent once assigned. Fix phases update the `status` field (`open` → `closed` with `closed_in_phase` + `closed_commit` recorded) on the existing entry; they do **not** re-issue IDs. Phase 8's re-audit produces a fresh shard set; `scripts/reaudit_diff.dart` matches by `(category, normalized_file_path, description)`. Re-audit finding without a Phase-1 match = a regression / new finding.
- **D-08:** Splits and merges follow a documented convention in `.planning/audit/SCHEMA.md`: a split keeps the original ID open and adds new IDs (`LV-014` stays open, `LV-201`, `LV-202` added with `split_from: LV-014`). A merge closes child IDs with `closed_as_duplicate_of: <parent_id>`. Planner is responsible for the bookkeeping; the merger script does **not** auto-detect splits/merges.

**`ISSUES.md` Format:**
- **D-09:** Dual audience: project owner skim + `/gsd-plan-phase` consumption.
- **D-10:** Grouping: severity-first (`## CRITICAL` / `## HIGH` / `## MEDIUM` / `## LOW`), then category (`### Layer Violations` / `### Provider Hygiene` / `### Dead Code` / `### Redundant Code`).
- **D-11:** Per-finding detail: compact Markdown table per category with columns `ID | File:Line | Description | Suggested Fix | tool_source`. ~1 line per finding.

### Claude's Discretion (research-confirmed below)

- **Audit script language:** `scripts/audit_*.sh` is a thin POSIX shell wrapper that invokes `scripts/audit/<dimension>.dart`. Matches the existing `scripts/arb_to_csv.dart` precedent.
- **Pinned versions:** verify on pub.dev at planning time, pin via caret. **See Section 1 below — version reality differs from STACK.md.**
- **`confidence` enum:** three-level (`high` / `medium` / `low`). `high` = tool-flagged with structural rule match. `medium` = AI-agent finding with strong code-anchored evidence. `low` = AI-agent inference / pattern-similarity.
- **Layout under `.planning/audit/`:** `SCHEMA.md`, `issues.json`, `ISSUES.md`, `shards/<tool>.json`, `agent-shards/<dimension>.json`, `coverage-baseline.txt` and `files-needing-tests.txt` (Phase 2 populates).

### Deferred Ideas (OUT OF SCOPE)

- Removing the `import_guard` reliance on `riverpod_lint 3.x` — `FUTURE-TOOL-01` covers this.
- Custom Dart script for Drift-column unused detection — `FUTURE-TOOL-02` covers this. Phase 1 uses the AI agent.
- DCM (paid) upgrade — `FUTURE-ARCH-03`. The free `dart_code_linter` fork is the Phase 1 choice.
- Mocktail migration vs CI-generated mocks — Phase 4 territory.
- `appDatabaseProvider` replacement strategy — Phase 3 territory.
- `CategoryLocaleService` long-term ARB-driven architecture — `FUTURE-ARCH-01`.
- Pre-commit hook in addition to GitHub Actions CI — declined.

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUDIT-01 | Add `import_guard`, `dart_code_linter`, `coverde` to dev_dependencies with verified pinned versions | Section 1 (Tooling Verification) — package picks adjusted to `import_guard_custom_lint ^1.0.0` + `dart_code_linter ^3.0.0`; `coverde` installed globally, not in pubspec |
| AUDIT-02 | `import_guard.yaml` encodes 5-layer dependency rules | Section 3 (Layer Rules); Section 2.1 of STRUCTURE.md drives the rule set |
| AUDIT-03 | `analysis_options.yaml` registers `custom_lint`, `riverpod_lint`, and `import_guard*` plugins; `flutter analyze` exercises all three | Section 2 (analysis_options shape) |
| AUDIT-04 | Locked finding-record schema documented in `.planning/audit/SCHEMA.md` | Section 5 (JSON Schema) |
| AUDIT-05 | Four-level severity taxonomy CRITICAL/HIGH/MEDIUM/LOW with definitions | Section 5 (severity definitions; references SUMMARY.md) |
| AUDIT-06 | `audit_layer.sh`, `audit_dead_code.sh`, `audit_providers.sh`, `audit_duplication.sh` invocable individually | Section 4 (Scanner Architecture) |
| AUDIT-07 | AI-agent semantic-scan workflow runnable via `/gsd-audit-semantic`, 4 dimensions | Section 7 (Slash Command + Subagents) |
| AUDIT-08 | `issues.json` (machine-readable, stable IDs) + `ISSUES.md` (human-readable, severity-sorted) | Section 6 (Merger Algorithm) |
| AUDIT-09 | CI guardrail rejects `sqlite3_flutter_libs` in `pubspec.lock` | Section 8 (CI Workflow) |
| AUDIT-10 | CI guardrail runs `build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` | Section 8 (CI Workflow) |

---

## Project Constraints (from CLAUDE.md + analysis_options.yaml)

- **Generated-file exclusion is sacred.** `analyzer.exclude:` MUST keep `**/*.g.dart` + `**/*.freezed.dart`. Audit scanners MUST also ignore these paths. Adding new excludes is fine; removing existing ones breaks the build (riverpod/freezed regenerate code that would then fail their own implicit lints).
- **`dart format` + zero-warning policy.** Every Dart file added in Phase 1 (scanners, merger, slash-command prompts) must `dart format` cleanly and pass `flutter analyze` with 0 issues.
- **`prefer_relative_imports: true` is on.** All new Dart code under `lib/` must use relative imports; under `scripts/` and `test/` use `package:home_pocket/...`. Phase 1 only touches `scripts/`, so absolute `package:` imports apply.
- **`avoid_print: false` is currently permissive.** Audit scripts may use `print(...)` for CLI output without violating analyzer (this avoids the LOW-06 wrapping concern surfacing in Phase 1's own scripts).
- **`sqlcipher_flutter_libs` only.** Never add a dep whose transitive closure includes `sqlite3_flutter_libs`. The CI gate (AUDIT-09) is the long-term enforcement.
- **`build_runner` correctness.** Any new `@riverpod`/`@freezed`/Drift-annotation file requires `flutter pub run build_runner build --delete-conflicting-outputs`. Phase 1 SHOULD NOT add any annotated files (scanners are plain Dart scripts).
- **Drift index syntax.** Out of Phase 1 scope (no table edits) but the `import_guard.yaml` rules and the audit scanners must respect this when scanning `lib/data/tables/` for non-violations.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tooling installation (`pubspec.yaml`) | Build/Dev | — | Analyzer-plugin pin lives in dev_dependencies; no runtime impact |
| Layer-rule encoding (`import_guard.yaml`) | Build/Dev | — | Static analysis configuration; consumed only by analyzer plugin |
| Audit scanner CLIs (`scripts/audit_*.sh` + `scripts/audit/*.dart`) | Build/Dev (project root `scripts/`) | — | Off-runtime tooling; runs in CI and on developer machines, never imported by `lib/` |
| Finding-record schema doc (`SCHEMA.md`) | Documentation (`.planning/audit/`) | — | Source-of-truth contract for downstream phases; not loaded by code |
| `merge_findings.dart` deduper | Build/Dev | — | Project-local Dart script following `scripts/arb_to_csv.dart` pattern |
| AI-agent semantic-scan slash command | Claude Code config (`.claude/commands/`) | — | Authored prompt files; spawned by user invocation |
| GitHub Actions workflow (`audit.yml`) | CI (greenfield `.github/workflows/`) | — | Cloud-side enforcement; reads project files but writes only PR comments |
| Stable-ID issues catalogue (`issues.json` + `ISSUES.md`) | Documentation / planning artifact | — | Read by every fix phase's `/gsd-plan-phase`; never imported into runtime |

**Implication for the planner:** every Phase 1 task lives outside `lib/`. The planner can confidently exclude any task whose `lib/` file_path is non-empty.

---

## Standard Stack

### 1. Tooling Verification — pub.dev versions and the analyzer-7 lock-in

> **HIGH-confidence reality check.** STACK.md picked `import_guard` (the new native-analyzer-plugin variant) and `dart_code_linter ^1.2.1`. Verifying live versions on pub.dev shows those picks won't resolve cleanly against the project's currently-locked `analyzer 7.6.0`. The project is locked at analyzer 7 because `json_serializable 6.9.5` and `riverpod_lint 2.6.5` both pin to analyzer 7. FUTURE-TOOL-01 already defers the analyzer bump. Substituting drop-in equivalents preserves Phase 1 scope without forcing the deferred upgrade.

**Currently installed (verified via `pubspec.lock`):**

| Tool | Resolved version | Constraint | Status |
|------|------------------|------------|--------|
| `analyzer` (transitive) | `7.6.0` | locked by below | Cannot bump without breaking `json_serializable` + `riverpod_lint` |
| `riverpod_lint` | `2.6.5` | `analyzer: ^7.0.0` | `[VERIFIED: pub.dev/packages/riverpod_lint/versions/2.6.5]` |
| `custom_lint` | `0.7.6` | host for plugins | OK |
| `json_serializable` | `6.9.5` | `analyzer >=6.9.0 <8.0.0` | `[VERIFIED: pub.dev/packages/json_serializable/versions/6.9.5]` |
| `freezed` | `3.1.0` | `analyzer >=6.9.0 <8.0.0` | `[VERIFIED: pub.dev/packages/freezed/versions/3.1.0]` |
| `flutter_lints` | `^6.0.0` | base ruleset | OK |

**Phase 1 additions (verified analyzer-7 compatible):**

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `import_guard_custom_lint` | `^1.0.0` | Layer-violation enforcement as a `custom_lint` plugin | `[VERIFIED: pub.dev/packages/import_guard_custom_lint]` — uses `analyzer >=7.0.0 <9.0.0`; coexists with `riverpod_lint` under the same `custom_lint` host. Same author as `import_guard`. The "native analyzer plugin" variant (`import_guard ^0.2.0`) requires analyzer ≥8.2 and conflicts with the current stack. |
| `dart_code_linter` | `^3.0.0` | Dead-symbol + orphaned-file detection CLI | `[VERIFIED: pub.dev/packages/dart_code_linter/versions/3.0.0]` — uses `analyzer ^7.4.1`. The 3.0 line is the last analyzer-7 compatible series. 3.2.x bumps to analyzer ^8.2; 4.x bumps to analyzer ≥10. |
| `coverde` | global activate, NOT in pubspec | Per-file coverage CLI | `[VERIFIED: pub.dev/packages/coverde]` — current `0.3.0+1` requires `analyzer >=8.0.0`. Installing as `dart pub global activate coverde` uses an isolated SDK pubspec, sidestepping the project-analyzer conflict entirely. The `coverde check <min> --input coverage/lcov.info` command supports global thresholds; per-file enforcement is implemented by Phase 2's own `scripts/coverage_gate.dart` reading raw `lcov.info`. |
| `very_good_coverage@v2` | GitHub Action | CI global coverage gate | `[VERIFIED: github.com/VeryGoodOpenSource/very_good_coverage]` — Phase 1 wires it report-only; Phase 2 (BASE-06) makes it blocking. |

**Installation commands:**

```bash
# Project-local (pubspec.yaml dev_dependencies)
flutter pub add --dev import_guard_custom_lint:^1.0.0 dart_code_linter:^3.0.0

# Verify analyzer stays at 7.x (no upgrade)
grep -A 1 "^  analyzer:" pubspec.lock

# Globally activated (developer + CI runner)
dart pub global activate coverde
```

**Version verification commands the planner should run during planning:**

```bash
flutter pub global list                       # confirms coverde install path
flutter pub deps --no-dev | grep -i sqlite    # must show sqlcipher_flutter_libs only
flutter analyze --no-fatal-infos              # baseline 0 issues before any change
dart run custom_lint                          # baseline 0 issues before any change
```

### Alternatives Considered (and why rejected for Phase 1)

| Instead of | Could Use | Why Not |
|------------|-----------|---------|
| `import_guard_custom_lint ^1.0.0` | `import_guard ^0.2.0` (native analyzer plugin) | Requires analyzer ≥8.2; would force `riverpod_lint 3.x` upgrade (FUTURE-TOOL-01) |
| `dart_code_linter ^3.0.0` | `dart_code_linter ^4.0.2` (latest) | Requires analyzer ≥10; same FUTURE-TOOL-01 blocker |
| `dart_code_linter` | `dyzer ^1.0.3` (DCM fork twin) | Less mature; same `unused_files_analyzer` API; not adopted in any reference project |
| `dart_code_linter` | DCM (commercial) | Paid license, deferred to FUTURE-ARCH-03 |
| `coverde` global activate | `coverde` in dev_dependencies | analyzer ≥8 conflict |
| `coverde` for per-file | `lcov` + custom Dart parser | Phase 2's `scripts/coverage_gate.dart` does parse lcov directly; coverde is for human-readable reports |
| `jscpd` (npm) for duplication | Native Dart CPD tool | None exist with AST-level precision in the free tier; CONTEXT.md punts duplication to AI agent (D-01.b) so jscpd isn't even needed in Phase 1 |

### 2. `analysis_options.yaml` Final Shape

**Current contents (verbatim):**
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_single_quotes: true
    prefer_relative_imports: true
    avoid_print: false
```

**Phase 1 extension:**
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
  plugins:
    - custom_lint           # already-effective host (riverpod_lint runs under it; now also import_guard_custom_lint)

linter:
  rules:
    prefer_single_quotes: true
    prefer_relative_imports: true
    avoid_print: false
```

**Why a single `custom_lint` entry covers both plugins:** `riverpod_lint 2.6.5` and `import_guard_custom_lint 1.0.0` are both `custom_lint_builder`-based plugins. `custom_lint` discovers them automatically by scanning `dev_dependencies` of the analyzed package. Listing `custom_lint` once in `analyzer.plugins` is the entire registration. `[VERIFIED: pub.dev/packages/custom_lint]`

**`flutter analyze` integration:** `custom_lint` plugin output appears under `flutter analyze` (the analyzer host invokes it). `dart run custom_lint` is a separate manual invocation that produces the same diagnostics in CLI form — this is the audit-pipeline entry point used by `scripts/audit_layer.sh` and `scripts/audit_providers.sh`.

### 3. `import_guard.yaml` — Layer Rules Encoding STRUCTURE.md

`import_guard_custom_lint` uses **per-directory `import_guard.yaml`** files with hierarchical inheritance, NOT a single root file with path-scoped rules. `[CITED: github.com/ryota-kishimoto/import_guard/tree/main/packages/import_guard_custom_lint]`

**Layer rules to encode (from STRUCTURE.md + CLAUDE.md "Where to Put New Code"):**

| Rule | Where | Forbidden imports |
|------|-------|-------------------|
| Domain depends on nothing | `lib/features/*/domain/import_guard.yaml` | `package:home_pocket/data/**`, `package:home_pocket/infrastructure/**`, `package:home_pocket/application/**`, `package:home_pocket/features/*/presentation/**`, `dart:ui`, `package:flutter/**` |
| Application uses Domain + Infrastructure | `lib/application/import_guard.yaml` | `package:home_pocket/features/*/presentation/**`, `package:home_pocket/data/tables/**`, `package:home_pocket/data/daos/**` |
| Data uses Domain + Infrastructure | `lib/data/import_guard.yaml` | `package:home_pocket/features/*/presentation/**`, `package:home_pocket/application/**` |
| Presentation uses Application + Domain (NOT Infrastructure directly) | `lib/features/*/presentation/import_guard.yaml` | `package:home_pocket/data/tables/**`, `package:home_pocket/data/daos/**`, `package:home_pocket/infrastructure/crypto/services/**`, `package:home_pocket/infrastructure/sync/**` (must go through application use cases — HIGH-02) |
| Infrastructure depends only on external SDKs + dart core | `lib/infrastructure/import_guard.yaml` | `package:home_pocket/features/**`, `package:home_pocket/application/**`, `package:home_pocket/data/**` |
| "Thin Feature" — no application/infra inside features | `lib/features/import_guard.yaml` (root for all features) | `package:home_pocket/features/*/use_cases/**` (catches CRIT-02 violation in `family_sync/use_cases/`); also denies `lib/features/*/data/tables/**`, `lib/features/*/data/daos/**`, `lib/features/*/infrastructure/**` |
| Project-wide | `lib/import_guard.yaml` | `dart:mirrors` (security/perf hygiene); also `sqlite3_flutter_libs` (defense-in-depth alongside CI gate AUDIT-09) |

**Concrete syntax (verbatim from `import_guard_custom_lint` README):**

```yaml
# lib/features/accounting/domain/import_guard.yaml — Domain layer is leafmost
deny:
  - package:home_pocket/data/**
  - package:home_pocket/infrastructure/**
  - package:home_pocket/application/**
  - package:home_pocket/features/**/presentation/**
  - package:flutter/**

# Allow only Dart core + freezed/json annotations (per CRIT-04)
allow:
  - dart:core
  - package:freezed_annotation/**
  - package:json_annotation/**
  - package:meta/**

inherit: true   # picks up parent rules from lib/features/import_guard.yaml etc.
```

```yaml
# lib/features/import_guard.yaml — Thin Feature rule
deny:
  # No use_cases/ directory inside any feature (CRIT-02 territory)
  - package:home_pocket/features/*/use_cases/**
  # No application/infrastructure/data internals inside any feature
  - package:home_pocket/features/*/application/**
  - package:home_pocket/features/*/infrastructure/**
  - package:home_pocket/features/*/data/**

inherit: true
```

```yaml
# lib/features/<f>/presentation/import_guard.yaml — Presentation may NOT reach Infrastructure directly (HIGH-02)
deny:
  - package:home_pocket/data/tables/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/infrastructure/crypto/services/**
  - package:home_pocket/infrastructure/sync/**
  - package:home_pocket/infrastructure/security/secure_storage_service.dart
  # all crypto repositories: presentation must go through application use cases
  - package:home_pocket/infrastructure/crypto/repositories/**

inherit: true
```

**Notes:**
- The `allow:` list is read as "either exceptions to deny OR whitelist mode." Use `allow:` only on Domain (the strict whitelist case); Application/Data/Infrastructure use deny-only.
- The `inherit: true` flag is the default per the README; explicit declaration is documentation hygiene.
- Path globs accept `**` (recursive) and `*` (one segment). Test the glob behavior on a sample file before locking the YAML — `[ASSUMED]` that `package:home_pocket/features/*/use_cases/**` matches `lib/features/family_sync/use_cases/*.dart` because the package-uri-to-path mapping is one-to-one in this single-package project.

### 4. Generated-file & ARB exclusions

The audit scanners must respect the same exclusions as `analysis_options.yaml`:
- `**/*.g.dart`, `**/*.freezed.dart`, `**/*.mocks.dart` — never reported on
- `lib/generated/**` — flutter_localizations output, ignored
- `lib/l10n/*.arb` — JSON, scanned only by Phase 5's i18n auditor (not Phase 1)

The `merge_findings.dart` should drop any shard finding whose `file_path` matches these globs as a defense-in-depth before assigning IDs.

---

## Architecture Patterns

### System Architecture Diagram

```
                       ┌────────────────────────────────────────┐
                       │  /gsd-audit-semantic (slash command)   │
                       │  spawns 4 parallel subagents           │
                       └──────────────┬─────────────────────────┘
                                      │
   developer / CI                     ▼
        │                ┌─────────────────────┐
        │                │ AI Agent: layer-viol│──┐
        ├───────────────►│ AI Agent: dup       │──┤
        │                │ AI Agent: transitive│──┤   .planning/audit/agent-shards/
        │                │ AI Agent: drift-col │──┤   ├── layer.json
        │                └─────────────────────┘  │   ├── duplication.json
        │                                         │   ├── transitive.json
        │                ┌─────────────────────┐  │   └── drift_col.json
        ├───────────────►│ scripts/audit_      │──┤
        │                │   layer.sh          │──┤
        │                │ ↳ wraps             │──┤   .planning/audit/shards/
        │                │   scripts/audit/    │──┤   ├── layer.json
        │                │   layer.dart        │──┤   ├── dead_code.json
        │                │ (uses dart run      │──┤   ├── providers.json
        │                │   custom_lint       │──┤   └── duplication.json
        │                │   --output=json)    │──┤
        │                ├─────────────────────┤  │
        ├───────────────►│ audit_dead_code.sh  │──┤
        │                │ (dart_code_linter:  │──┤
        │                │  metrics check-     │──┤
        │                │  unused-{code,files}│──┤
        │                │  --reporter=json)   │──┤
        │                ├─────────────────────┤  │
        ├───────────────►│ audit_providers.sh  │──┤
        │                │ (dart run custom_   │──┤
        │                │  lint, filtered to  │──┤
        │                │  riverpod_lint)     │──┤
        │                ├─────────────────────┤  │
        └───────────────►│ audit_duplication.sh│──┤  (Phase 1 stub: emits
                         │ (jscpd OR no-op     │──┘   empty shard; D-01.b
                         │  stub)              │      defers to AI agent)
                         └─────────────────────┘
                                      │
                                      ▼
                       ┌────────────────────────────┐
                       │ scripts/merge_findings.dart│
                       │  - reads ALL 8 shards      │
                       │  - dedupes by              │
                       │    (file, line, category)  │
                       │  - assigns LV-/PH-/DC-/RD- │
                       │    NNN stable IDs          │
                       │  - severity-classifies     │
                       │  - emits issues.json       │
                       │  - emits ISSUES.md         │
                       └──────────────┬─────────────┘
                                      │
                                      ▼
                       ┌────────────────────────────┐
                       │ .planning/audit/           │
                       │   ├── SCHEMA.md            │
                       │   ├── issues.json          │
                       │   ├── ISSUES.md            │
                       │   ├── shards/*.json        │
                       │   └── agent-shards/*.json  │
                       └────────────────────────────┘
                                      │
                                      ▼
                  consumed by /gsd-plan-phase
                  for Phases 3-6 fix plans
```

### Component Responsibilities

| Component | Inputs | Outputs | Lives At |
|-----------|--------|---------|----------|
| `audit_layer.sh` + `audit/layer.dart` | `lib/`, `import_guard.yaml` files | `.planning/audit/shards/layer.json` | `scripts/` |
| `audit_dead_code.sh` + `audit/dead_code.dart` | `lib/` | `.planning/audit/shards/dead_code.json` | `scripts/` |
| `audit_providers.sh` + `audit/providers.dart` | `lib/`, riverpod_lint plugin | `.planning/audit/shards/providers.json` | `scripts/` |
| `audit_duplication.sh` + `audit/duplication.dart` | `lib/` | `.planning/audit/shards/duplication.json` (likely empty in Phase 1; AI handles) | `scripts/` |
| AI subagent prompts | codebase maps + scoped file glob | `.planning/audit/agent-shards/<dim>.json` | `.claude/commands/audit/<dim>.md` |
| `/gsd-audit-semantic` slash command | (no args) | spawns 4 subagents in parallel | `.claude/commands/gsd-audit-semantic.md` |
| `merge_findings.dart` | all shards + agent-shards | `issues.json` + `ISSUES.md` | `scripts/` |
| `reaudit_diff.dart` (stub in Phase 1) | `issues.json` (baseline) + re-audit `issues.json` | `re-audit-diff.json` (Phase 8) | `scripts/` |
| `audit.yml` GitHub Actions | repo on PR/push | CI status comments | `.github/workflows/` |

### Pattern 1: Thin POSIX-shell wrapper around Dart core

**What:** Each audit dimension is a **single-line shell script** that exec's a Dart entry. Cross-platform-friendly; degrades gracefully on Windows by invoking the Dart entry directly.

**When to use:** Every audit scanner. Matches the `scripts/arb_to_csv.dart` precedent.

**Example:**
```bash
#!/usr/bin/env bash
# scripts/audit_layer.sh
set -euo pipefail
exec dart run scripts/audit/layer.dart "$@"
```

```dart
// scripts/audit/layer.dart — runs `dart run custom_lint` and filters to layer findings,
// re-emits in the locked schema, writes to .planning/audit/shards/layer.json.
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final result = await Process.run(
    'dart',
    ['run', 'custom_lint', '--format=json'],
    runInShell: true,
  );
  final lints = jsonDecode(result.stdout as String) as List<dynamic>;
  final layerFindings = lints
      .where((d) => (d as Map)['code'].toString().startsWith('import_guard'))
      .map(_normalize)
      .toList();
  final shardPath = '.planning/audit/shards/layer.json';
  await File(shardPath).create(recursive: true);
  await File(shardPath).writeAsString(jsonEncode({
    'tool_source': 'import_guard',
    'generated_at': DateTime.now().toIso8601String(),
    'findings': layerFindings,
  }));
}
// `_normalize` maps custom_lint diagnostic JSON to the schema in Section 5.
```

**Trade-offs:**
- Shell wrapper adds 5 lines but lets developers invoke `./scripts/audit_layer.sh` exactly as AUDIT-06 requires without typing `dart run scripts/audit/layer.dart`.
- `--format=json` flag on `custom_lint` `[ASSUMED]` — verify by running `dart run custom_lint --help` during planning. If JSON output isn't directly supported, the Dart entry parses the plain output. `[VERIFIED: pub.dev/packages/custom_lint]` confirms `--reporter=json` IS supported.

### Pattern 2: Hierarchical config via per-directory YAML

`import_guard_custom_lint` reads per-directory `import_guard.yaml` files with `inherit: true`. This means:
- Adding a new layer rule = adding a YAML file at the layer's directory.
- A future top-level rule (e.g., "no `firebase_*` in domain") edits ONE file, not seven.
- Encoding the "Thin Feature" rule at `lib/features/import_guard.yaml` automatically applies to every `features/<X>/` subtree without per-feature duplication.

### Pattern 3: Stable-ID stamping at merge time, not at scan time

Scanners produce **un-IDed shards**. The merger assigns IDs in deterministic sort order (`file_path` asc, `line_start` asc, then category prefix priority `LV` < `PH` < `DC` < `RD`). This means:
- Re-running a single scanner doesn't shift IDs (the merger reassigns from the full corpus).
- Re-running the merger on identical shards produces identical `issues.json` (idempotent).
- Phase 8's re-audit follows the same path; differential is computed by `(category, normalized_file_path, description)` matching, not by ID.

### Pattern 4: AI-agent prompt as version-controlled contract

Each subagent prompt under `.claude/commands/audit/<dim>.md` is the **public interface** of that audit dimension. Phase 8 invokes the same `/gsd-audit-semantic` command, which loads the same prompt files, which scope the same file globs — so Phase 1 and Phase 8 outputs are comparable. Treat these prompt files like API definitions: changing them mid-initiative requires a documented rationale.

### Anti-Patterns to Avoid

- **Don't put `import_guard.yaml` only at the repo root.** Per-directory placement is what gets the inheritance + locality. A single root file with embedded path-scoped rules is *not* what `import_guard_custom_lint` parses (that's the syntax of the *other* `import_guard` package).
- **Don't run scanners inside `lib/`.** Audit scripts run from project root; `--targets lib/` (or equivalent) is the file-list entry. No scanner imports anything from `lib/`.
- **Don't auto-fix during scan.** AUDIT-PROJECT.md "Auto-fix during audit" is in Out of Scope. Even if `dart_code_linter` has `--fix`, do not enable it.
- **Don't auto-detect splits/merges in `merge_findings.dart`.** Per D-08, splits/merges are manual planner bookkeeping. Adding heuristics here silently loses findings.
- **Don't skip the deterministic sort.** ID assignment must be `file_path` asc, then `line_start` asc. Any other order breaks Phase 8 re-audit ID matching.
- **Don't filter generated files at scanner level only.** Filter again at merger level. Defense-in-depth — scanner regressions slipping `*.g.dart` findings into the catalogue would derail every fix phase.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Layer-violation detection | Custom regex grep over `import` statements | `import_guard_custom_lint` plugin | Misses transitive imports, type aliases, parts; analyzer plugin gets full AST |
| Dead-code detection | `find lib/ -name '*.dart' -exec grep -L "import.*<file>"` | `dart_code_linter:metrics check-unused-files lib` | Misses imports via `part 'foo.g.dart'`, type-only imports, conditional imports |
| Riverpod hygiene | Custom AST walk for `UnimplementedError` | `riverpod_lint` (already installed) | Already battle-tested for misplaced provider, scope, dependency-graph rules |
| Coverage parsing | Custom lcov.info parser | `coverde` (CLI) + `scripts/coverage_gate.dart` for per-file (Phase 2) | lcov format has edge cases (DA: vs FN:, branch coverage); `coverde` handles them |
| JSON shard schema | Untyped `Map<String, dynamic>` | Freezed model in `scripts/audit/finding.dart` | Compile-time guarantees on field names; one source of truth for both writers and `merge_findings.dart` |
| Stable-ID generation | UUIDs / file-hash | Sequential `<PREFIX>-NNN` per category in deterministic sort | Human-readable, mentioned in commits, fits the canonical `LV-001` style in REQUIREMENTS.md |
| Severity classification | Heuristic regex on description | Rule-based mapping table keyed on `(category, tool_source, code)` | Auditable; reviewable; doesn't drift between runs |

**Key insight:** every component the planner might be tempted to build from scratch already has a maintained, analyzer-7-compatible alternative or is best implemented as a small, focused Dart script that follows the `arb_to_csv.dart` precedent.

---

## Common Pitfalls (Phase-1-specific)

### Pitfall P1-1: Adding `import_guard ^0.2.0` (the new analyzer-plugin variant)

**What goes wrong:** `flutter pub get` succeeds (`import_guard` doesn't directly conflict), but `flutter pub deps` shows analyzer 7.6 fighting analyzer ≥8.2; pub falls back to the lower bound and the plugin silently fails to load. `flutter analyze` works (no error) but no `import_guard:*` codes appear. CI passes a green light on a non-functional gate.
**Why it happens:** Pub's solver picks the highest version satisfying all constraints; `import_guard 0.2.0` has `analyzer >=8.2 <13` while `riverpod_lint 2.6.5` has `analyzer ^7.0`. Pub fails resolution (correct) but a developer who notices and uses `--ignore-versioning` or `dependency_overrides` can mask the failure.
**How to avoid:** Pin `import_guard_custom_lint ^1.0.0` instead. Verify with `flutter pub deps | grep -E "(import_guard|analyzer)"` after install.
**Warning signs:** `dart run custom_lint` runs but `flutter analyze` shows zero `import_guard_*` lints on a file you know violates a rule.

### Pitfall P1-2: Adding `dart_code_linter` to dev_dependencies as `^4.0.2`

Same trap as P1-1, different package. Pin `^3.0.0` (the last analyzer-7 line). 3.2.x bumps to analyzer ^8.2 and is ALSO incompatible.
**Verification:** `dart run dart_code_linter:metrics --version` should report `3.0.x`.

### Pitfall P1-3: Adding `coverde` to `pubspec.yaml` dev_dependencies

All `coverde` versions require `analyzer >=8.0.0`. Adding it to pubspec breaks resolution. The canonical install is `dart pub global activate coverde` — this lives in the developer's `~/.pub-cache/bin` (or CI runner equivalent) and is invoked as `coverde check ...`. Do not list it in pubspec.

### Pitfall P1-4: `analyzer.plugins` indentation in `analysis_options.yaml`

The `plugins:` key MUST be a child of `analyzer:`, not a top-level key. Some `import_guard` README snippets show `plugins:` at top level — that's the older format and doesn't work with current analyzer. Verify the YAML structure exactly matches Section 2 above.

### Pitfall P1-5: `import_guard.yaml` placed only at repo root

`import_guard_custom_lint` reads per-directory configs. A single root `import_guard.yaml` with all rules works only if the rules are flat. Path-scoped rules (different forbidden-imports lists per layer) require **multiple `import_guard.yaml` files** at the layer directories. This is opposite of what the new `import_guard` package does — easy to confuse.

### Pitfall P1-6: Writing into `lib/` during Phase 1

The phase boundary is "no code modifications." Adding scanners under `scripts/` is fine. Adding the `import_guard.yaml` files under `lib/features/<f>/domain/` etc. **is technically a code-tree edit** but is a configuration file, not Dart source — `flutter analyze` ignores YAML files. Treat them as analyzer config, not code, and audit phase 1 git-diffs to confirm `lib/**/*.dart` is untouched.

### Pitfall P1-7: `build_runner` regen during Phase 1 churn

Adding new dev_dependencies and running `flutter pub get` triggers `custom_lint` to re-discover plugins, but does NOT trigger `build_runner`. However, AUDIT-10's CI gate runs `build_runner build --delete-conflicting-outputs && git diff --exit-code lib/`. If the developer machine has stale generated files (from a prior pull without regen), the CI gate fires. **Run build_runner once at the start of Phase 1 work and confirm clean diff before any scanner work.**

### Pitfall P1-8: `custom_lint --format=json` quirks

`dart run custom_lint --format=json` produces a JSON array on stdout, but it ALSO prints non-JSON status lines on stderr (plugin discovery, plugin compile timing). The Dart core scripts (`scripts/audit/layer.dart`, etc.) must read **stdout only** and avoid concatenating stderr. `Process.run(...)` returns `stdout` and `stderr` separately — use `result.stdout`.

### Pitfall P1-9: Severity drift between scanner output and merger

A finding's tool_source determines its initial severity (e.g., `import_guard:domain_imports_data` is always CRITICAL). If the merger applies severity per-finding rather than per-rule, the same lint code could end up with different severities across runs. Lock severity at the merger via a static `Map<String, String>` keyed by `(tool_source, code)`. See Section 5.

### Pitfall P1-10: AI agent shard ordering instability

LLM output is non-deterministic. Two runs of the layer-violation agent against an identical codebase MAY produce findings in different orders. The merger's deterministic sort (`file_path` asc, `line_start` asc) protects ID stability, but the agent shard itself MUST always include enough info (`file_path`, `line_start`, `description`) for the merger to sort. Add a JSON-schema validator step in `merge_findings.dart` that fails fast on missing fields.

### Pitfall P1-11: GitHub Actions workflow runs in parallel with `pub get` cache miss

Fresh CI runner has no `~/.pub-cache`. The workflow MUST `flutter pub get` and `dart pub global activate coverde` before any audit step. Cache the global pub-cache between runs (`actions/cache@v4` keyed on `pubspec.lock`) to avoid 60+ second cold-starts.

---

## Code Examples

### Example 1: `audit_layer.sh` (POSIX shell wrapper)

```bash
#!/usr/bin/env bash
# scripts/audit_layer.sh
# Runs custom_lint, filters to import_guard codes, emits .planning/audit/shards/layer.json
set -euo pipefail
exec dart run scripts/audit/layer.dart "$@"
```

### Example 2: `scripts/audit/finding.dart` — shared schema

```dart
// scripts/audit/finding.dart
// Schema lock for every audit shard. Mirrors .planning/audit/SCHEMA.md.

class Finding {
  final String? id; // null until merge_findings stamps it
  final String category; // 'layer_violation' | 'provider_hygiene' | 'dead_code' | 'redundant_code'
  final String severity; // 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'
  final String filePath; // e.g. 'lib/features/family_sync/use_cases/foo.dart'
  final int lineStart;
  final int lineEnd;
  final String description;
  final String rationale;
  final String suggestedFix;
  final String toolSource; // 'import_guard' | 'riverpod_lint' | 'dart_code_linter' | 'agent:layer' | ...
  final String confidence; // 'high' | 'medium' | 'low'
  final String status; // 'open' | 'closed' (Phase 1 emits 'open')
  final String? closedInPhase; // null in Phase 1
  final String? closedCommit; // null in Phase 1

  const Finding({
    this.id,
    required this.category,
    required this.severity,
    required this.filePath,
    required this.lineStart,
    required this.lineEnd,
    required this.description,
    required this.rationale,
    required this.suggestedFix,
    required this.toolSource,
    required this.confidence,
    this.status = 'open',
    this.closedInPhase,
    this.closedCommit,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'category': category,
    'severity': severity,
    'file_path': filePath,
    'line_start': lineStart,
    'line_end': lineEnd,
    'description': description,
    'rationale': rationale,
    'suggested_fix': suggestedFix,
    'tool_source': toolSource,
    'confidence': confidence,
    'status': status,
    if (closedInPhase != null) 'closed_in_phase': closedInPhase,
    if (closedCommit != null) 'closed_commit': closedCommit,
  };

  factory Finding.fromJson(Map<String, dynamic> j) => Finding(
    id: j['id'] as String?,
    category: j['category'] as String,
    severity: j['severity'] as String,
    filePath: j['file_path'] as String,
    lineStart: j['line_start'] as int,
    lineEnd: j['line_end'] as int,
    description: j['description'] as String,
    rationale: j['rationale'] as String,
    suggestedFix: j['suggested_fix'] as String,
    toolSource: j['tool_source'] as String,
    confidence: j['confidence'] as String,
    status: (j['status'] as String?) ?? 'open',
    closedInPhase: j['closed_in_phase'] as String?,
    closedCommit: j['closed_commit'] as String?,
  );
}
```

> **Avoid `@freezed` here.** Freezed-annotated files trigger `build_runner` and require `.freezed.dart` / `.g.dart` regen. Plain Dart classes keep `scripts/` build-runner-free.

### Example 3: `scripts/merge_findings.dart` skeleton

```dart
// scripts/merge_findings.dart
// Reads .planning/audit/{shards,agent-shards}/*.json, dedupes,
// stamps stable IDs, writes issues.json + ISSUES.md.

import 'dart:convert';
import 'dart:io';

import 'audit/finding.dart';

const _categoryPrefix = {
  'layer_violation': 'LV',
  'provider_hygiene': 'PH',
  'dead_code': 'DC',
  'redundant_code': 'RD',
};

const _generatedFileGlobs = [
  '.g.dart',
  '.freezed.dart',
  '.mocks.dart',
];

Future<void> main(List<String> args) async {
  final shards = <Finding>[];
  for (final dir in ['shards', 'agent-shards']) {
    final shardDir = Directory('.planning/audit/$dir');
    if (!shardDir.existsSync()) continue;
    for (final f in shardDir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final findings = (data['findings'] as List).cast<Map<String, dynamic>>();
      shards.addAll(findings.map(Finding.fromJson));
    }
  }

  // 1. Drop generated-file findings (defense-in-depth)
  final filtered = shards.where((f) =>
      !_generatedFileGlobs.any(f.filePath.endsWith)).toList();

  // 2. Dedupe by (file_path, line_start, category) — prefer high confidence,
  //    prefer tool_source over agent (CONTEXT.md "specifics").
  final byKey = <String, Finding>{};
  for (final f in filtered) {
    final k = '${f.filePath}|${f.lineStart}|${f.category}';
    final existing = byKey[k];
    if (existing == null || _isPreferred(f, over: existing)) {
      byKey[k] = f;
    }
  }

  // 3. Sort deterministically: file_path asc, line_start asc, category prefix.
  final sorted = byKey.values.toList()
    ..sort((a, b) {
      final fp = a.filePath.compareTo(b.filePath);
      if (fp != 0) return fp;
      final ln = a.lineStart.compareTo(b.lineStart);
      if (ln != 0) return ln;
      return _categoryPrefix[a.category]!.compareTo(_categoryPrefix[b.category]!);
    });

  // 4. Stamp IDs per category in sort order.
  final counters = <String, int>{};
  final stamped = sorted.map((f) {
    final prefix = _categoryPrefix[f.category]!;
    final n = (counters[prefix] = (counters[prefix] ?? 0) + 1);
    return Finding(
      id: '$prefix-${n.toString().padLeft(3, '0')}',
      category: f.category,
      severity: f.severity,
      filePath: f.filePath,
      lineStart: f.lineStart,
      lineEnd: f.lineEnd,
      description: f.description,
      rationale: f.rationale,
      suggestedFix: f.suggestedFix,
      toolSource: f.toolSource,
      confidence: f.confidence,
    );
  }).toList();

  // 5. Emit issues.json (machine-readable).
  await File('.planning/audit/issues.json').writeAsString(
    JsonEncoder.withIndent('  ')
        .convert({'findings': stamped.map((f) => f.toJson()).toList()}),
  );

  // 6. Emit ISSUES.md (human-readable, severity-then-category, table per group).
  final md = _renderMarkdown(stamped);
  await File('.planning/audit/ISSUES.md').writeAsString(md);
}

bool _isPreferred(Finding a, {required Finding over}) {
  // Higher-confidence wins; tie-broken by preferring tool_source over agent:*
  const order = {'high': 3, 'medium': 2, 'low': 1};
  if ((order[a.confidence] ?? 0) > (order[over.confidence] ?? 0)) return true;
  if ((order[a.confidence] ?? 0) < (order[over.confidence] ?? 0)) return false;
  final aIsAgent = a.toolSource.startsWith('agent:');
  final overIsAgent = over.toolSource.startsWith('agent:');
  if (!aIsAgent && overIsAgent) return true;
  return false;
}

String _renderMarkdown(List<Finding> findings) {
  // Group by severity then category; emit '## CRITICAL' etc. with tables.
  // (full implementation omitted for brevity; planner spells out the template)
  return ''; // placeholder
}
```

### Example 4: AI subagent prompt skeleton (`.claude/commands/audit/layer.md`)

```markdown
# Audit Subagent: Layer Violations

You scan the file list provided and emit findings for indirect layer violations
that the `import_guard_custom_lint` plugin does NOT catch.

## Inputs (read these before scanning)

- `.planning/codebase/STRUCTURE.md` — 5-layer Clean Architecture
- `.planning/codebase/CONCERNS.md` — confirmed live violations
- `.planning/codebase/CONVENTIONS.md` — project import conventions

## Scope

Files: every `.dart` file under `lib/features/*/use_cases/` AND every Domain file
(`lib/features/*/domain/**/*.dart`). Do NOT scan generated files (`*.g.dart`,
`*.freezed.dart`).

## What to flag

1. A Domain file that imports any non-Domain symbol via a type alias
   (e.g., `typedef Foo = SomeDataLayerType;`).
2. A `features/<f>/use_cases/` file (the location is itself a CRIT-02 violation
   per CONCERNS.md `lib/features/family_sync/use_cases/`).
3. A `features/<f>/presentation/` import that reaches `infrastructure/` directly
   (HIGH-02).

## Output format

Write a single JSON file to `.planning/audit/agent-shards/layer.json` with:

\`\`\`json
{
  "tool_source": "agent:layer",
  "generated_at": "<ISO8601>",
  "findings": [
    {
      "category": "layer_violation",
      "severity": "CRITICAL" | "HIGH",
      "file_path": "lib/features/...",
      "line_start": 1,
      "line_end": 1,
      "description": "...",
      "rationale": "...",
      "suggested_fix": "...",
      "tool_source": "agent:layer",
      "confidence": "high" | "medium" | "low"
    }
  ]
}
\`\`\`

`high` = direct evidence (the type alias, the import line). `medium` = strong
inference (e.g., a Domain class field whose name suggests a Data type). `low` =
pattern similarity only.
```

---

## CI Workflow (`.github/workflows/audit.yml`)

> Greenfield: `.github/workflows/` does not exist. Phase 1 creates the directory and the single workflow file.

### Trigger

```yaml
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
```

### Job structure (parallelizable where safe)

```yaml
name: audit

concurrency:
  group: audit-${{ github.ref }}
  cancel-in-progress: true

jobs:
  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version-file: pubspec.yaml
      - uses: actions/cache@v4
        with:
          path: |
            ~/.pub-cache
            .dart_tool/
          key: pub-${{ hashFiles('pubspec.lock') }}
      - run: flutter pub get
      - run: dart pub global activate coverde 0.3.0+1
      - name: Verify analyzer pin (smoke check)
        run: |
          if grep -A 1 '^  analyzer:' pubspec.lock | grep -q 'version: "7'; then
            echo "analyzer 7.x confirmed"
          else
            echo "::warning::analyzer pin moved off 7.x — verify FUTURE-TOOL-01 readiness"
          fi
      - name: flutter analyze
        continue-on-error: true   # Phase 1 ships report-only; flips blocking at end of Phase 6 per D-04
        run: flutter analyze --no-fatal-infos
      - name: dart run custom_lint
        continue-on-error: true   # Phase 1 ships report-only; flips blocking at end of Phase 4 per D-04
        run: dart run custom_lint
      - name: Audit scanners
        continue-on-error: true   # Phase 1 ships report-only; each flips blocking at the corresponding fix-phase exit (D-04)
        run: |
          bash scripts/audit_layer.sh
          bash scripts/audit_dead_code.sh
          bash scripts/audit_providers.sh
          bash scripts/audit_duplication.sh
      - name: Merge findings
        run: dart run scripts/merge_findings.dart
      - uses: actions/upload-artifact@v4
        with:
          name: audit-issues
          path: |
            .planning/audit/issues.json
            .planning/audit/ISSUES.md
            .planning/audit/shards/*.json
            .planning/audit/agent-shards/*.json

  guardrails:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version-file: pubspec.yaml
      - run: flutter pub get

      # AUDIT-09 — sqlite3_flutter_libs reject. BLOCKING from end of Phase 1 (D-04).
      - name: Reject sqlite3_flutter_libs in pubspec.lock
        run: |
          if grep -q sqlite3_flutter_libs pubspec.lock; then
            echo "::error::sqlite3_flutter_libs detected in pubspec.lock — conflicts with sqlcipher_flutter_libs"
            exit 1
          fi

      # AUDIT-10 — build_runner stale-diff. BLOCKING from end of Phase 1 (D-04).
      - name: Build runner clean diff
        run: |
          flutter pub run build_runner build --delete-conflicting-outputs
          if ! git diff --exit-code lib/; then
            echo "::error::Generated files in lib/ are stale — run build_runner locally and commit"
            exit 1
          fi

  coverage:
    runs-on: ubuntu-latest
    needs: static-analysis
    if: ${{ github.event_name == 'pull_request' }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version-file: pubspec.yaml
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: VeryGoodOpenSource/very_good_coverage@v2
        continue-on-error: true   # Phase 1 ships report-only; Phase 2 BASE-06 makes it blocking
        with:
          path: coverage/lcov.info
          min_coverage: 80
          exclude: |
            **/*.g.dart
            **/*.freezed.dart
            **/*.mocks.dart
            lib/generated/**
```

### Staged enablement contract (D-04 mapping)

| Gate | Phase 1 ship state | Flips blocking at end of |
|------|--------------------|--------------------------|
| `sqlite3_flutter_libs` reject | **BLOCKING immediately** | Phase 1 |
| `build_runner` stale-diff | **BLOCKING immediately** | Phase 1 |
| `import_guard*` (via `dart run custom_lint`) | report-only | Phase 3 |
| `riverpod_lint` (via `dart run custom_lint`) | report-only | Phase 4 |
| i18n / hardcoded-CJK / theme-token (Phase 5 scanners) | not yet implemented | Phase 5 |
| `dart_code_linter check-unused-{code,files}` | report-only | Phase 6 |
| `coverde` per-file ≥80% | not yet enforced (Phase 2 ships gate) | Phase 6 |
| `very_good_coverage@v2` global ≥80% | report-only | Phase 2 |

**How the blocking flip is implemented:** remove the `continue-on-error: true` line on the corresponding step at the end of the gating phase. Each fix-phase's `/gsd-verify-work` checklist MUST include this CI-edit step.

### Why split into 3 jobs

- `static-analysis` does the heavy `flutter analyze` + custom_lint + 4 scanners + merger (~3 min).
- `guardrails` is fast (~30 s) and runs the two AUDIT-09/AUDIT-10 gates that go blocking immediately.
- `coverage` runs `flutter test --coverage` (~2 min) only on PRs, in parallel with `static-analysis`.

Total wall-clock time on PR: ~3 min (parallelism saves ~50% over sequential).

### CI failure modes

| Symptom | Likely cause |
|---------|-------------|
| `dart pub global activate coverde` fails | Dart SDK on runner too old; pin Flutter version in `pubspec.yaml`'s `environment.flutter` to ensure runner matches |
| `dart run custom_lint --format=json` produces non-JSON output | Plugin discovery printed to stdout — confirm `--format=json` redirects status to stderr; fall back to plain-text parsing in `audit/layer.dart` (Pitfall P1-8) |
| `merge_findings.dart` finds zero findings on the unmodified codebase | Either rules are misconfigured (Section 3) OR scanners failed silently — check artifact for missing shard files |
| `git diff --exit-code lib/` fails on a fresh checkout | `pubspec.lock` lockfile change pulled in new freezed/json_serializable that regenerates differently — re-run `build_runner build --delete-conflicting-outputs` locally and commit the diff |

---


## Runtime State Inventory

> Phase 1 is **not** a rename/refactor/migration phase. No runtime state changes.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Phase 1 writes only to `.planning/audit/`, `scripts/`, `pubspec.yaml`, `analysis_options.yaml`, and `.github/workflows/`. No app data, no schema changes. | None |
| Live service config | None — no infra services touched. | None |
| OS-registered state | None — no scheduled tasks, no installed binaries beyond the developer-installed `coverde` global. The `coverde` global pub-cache entry is per-developer; CI runs install it fresh each time. | None |
| Secrets/env vars | None — Phase 1 introduces no new secrets. CI workflow uses only `GITHUB_TOKEN` (default-provided). | None |
| Build artifacts | `pubspec.lock` updates after adding `import_guard_custom_lint` and `dart_code_linter` (and any transitive bumps). Commit the lockfile change. | Commit lockfile change once with the dev_deps additions. |

**Nothing else found:** verified by inspection of the locked decisions (D-01..D-11) — every Phase 1 deliverable lives outside `lib/` and outside any persistent service.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `dart_code_metrics` (pub.dev) | `dart_code_linter` (free OSS fork) | June 2023 (DCM commercial split) | Original archived; only the fork sees Dart 3 updates. Use the fork. |
| Native analyzer plugins per package | `custom_lint` host + plugin packages | 2023+ | One `analyzer.plugins: - custom_lint` entry registers all plugins. `riverpod_lint` and `import_guard_custom_lint` both use this model. |
| `import_guard ^0.0.x` (custom-lint-based) | `import_guard ^0.2.x` (native analyzer plugin) | January 2026 | New variant requires analyzer ≥8.2; Phase 1 uses the still-maintained `import_guard_custom_lint ^1.0.0` instead because of the analyzer-7 lock. |
| `dart analyze --format=machine` (pipe-delimited) | `--format=json` + `--reporter=json` (where supported) | Dart 3 | Cleaner parsing; JSON output is the audit pipeline's input format. |

**Deprecated/outdated:**
- `dart_code_metrics` (the original) — Pub.dev page exists but archived since June 2023. Do not use.
- `import_guard 0.0.x` line — superseded by either `0.2.x` (native plugin) or `import_guard_custom_lint 1.0.0` (custom_lint plugin). Phase 1 uses the latter.
- `dart_code_linter 1.x`–`2.x` — analyzer 5/6 only; no Dart 3.10 support. Use `^3.0.0`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `import_guard_custom_lint`'s `package:home_pocket/features/*/use_cases/**` glob matches `lib/features/family_sync/use_cases/*.dart` | Section 3 (rule encoding) | Layer rule misses CRIT-02 territory; planner must verify by writing one test rule and probing during plan-execution. |
| A2 | `dart run custom_lint --format=json` and `--reporter=json` are supported in `custom_lint 0.7.6` | Section 4 / Pattern 1 | Scanner Dart cores fall back to plain-text parsing if not. `[VERIFIED: custom_lint pub.dev README]` shows JSON support but version-specific verification needed. |
| A3 | `dart_code_linter:metrics check-unused-{code,files} --reporter=json` produces parseable JSON in 3.0.0 | Section 4 | Same as A2 — fallback to text parsing. `[CITED: github.com/bancolombia/dart-code-linter]` confirms JSON reporter exists, version 3.x retention not explicitly verified. |
| A4 | `coverde` installed via `dart pub global activate` does NOT pull the project's analyzer pin | Section 1 | If wrong, coverde install fails; fallback is to use raw `lcov`/awk and skip coverde. |
| A5 | `pub` resolver's analyzer-7 lock means `import_guard ^0.2.0` and `dart_code_linter ^4.x` are blocked from clean install | Section 1 / Pitfall P1-1 | Confirmed via per-version pub.dev metadata; verify with `flutter pub get --dry-run` adding each candidate before the pubspec edit lands. |
| A6 | Phase 1 introduces zero new build_runner-annotated files | Pitfall P1-7 | If a planner adds `@freezed` to `Finding` (e.g., to share with `lib/`), build_runner regen becomes Phase 1 churn. Section "Code Examples" already calls out plain-Dart-class preference. |
| A7 | `.github/workflows/audit.yml` job runs successfully on `ubuntu-latest` with the project's flutter SDK | Section 8 | Standard Flutter CI pattern; verify by running the workflow once before staged-enablement flips. |
| A8 | The `agent:layer` shard format (Section "Code Examples — Example 4") matches what the merger expects without per-agent translation | Section 6 / Example 4 | If the agents drift, `merge_findings.dart` schema validator catches it and fails fast. |
| A9 | `coverde 0.3.x` global activation works on the GitHub Actions runner's Dart SDK | Pitfall P1-11 | Verify by running `dart pub global activate coverde` once on the runner image; if the SDK is too old, Phase 2 BASE-05/06 may need to bypass coverde and parse lcov directly. |

**If the planner discovers any of A1–A9 to be wrong, the resolution is local to a single task — none cascades into other Phase 1 work.**

---

## Validation Architecture

> `workflow.nyquist_validation: true` (default) per `.planning/config.json`. This section is REQUIRED.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) for any Phase-1 Dart test; `bash` self-tests for shell scripts; YAML lint via `yq` or `dart pub run yaml_lint` for `import_guard.yaml` files |
| Config file | `analysis_options.yaml` (existing, Phase 1 extends); `pubspec.yaml` (existing, Phase 1 extends dev_deps); `import_guard.yaml` files (new, per-directory in `lib/`) |
| Quick run command | `flutter analyze --no-fatal-infos && dart run custom_lint` (under 60 s) |
| Full suite command | `flutter test && flutter analyze && dart run custom_lint && bash scripts/audit_layer.sh && bash scripts/audit_dead_code.sh && bash scripts/audit_providers.sh && bash scripts/audit_duplication.sh && dart run scripts/merge_findings.dart` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUDIT-01 | `import_guard_custom_lint`, `dart_code_linter` listed in dev_deps; `coverde` available globally | smoke | `flutter pub deps \| grep -E "(import_guard_custom_lint\|dart_code_linter)" && which coverde` | ❌ Wave 0 — `test/scripts/dependencies_test.dart` |
| AUDIT-02 | Per-directory `import_guard.yaml` files exist at the 7 layer dirs and parse cleanly | smoke | `find lib -name import_guard.yaml \| wc -l` (expect 7); `dart run scripts/audit/lint_layer_yaml.dart` (parses each) | ❌ Wave 0 — `scripts/audit/lint_layer_yaml.dart` |
| AUDIT-03 | `analysis_options.yaml` registers `custom_lint` plugin; `flutter analyze` exits 0 on the unmodified codebase | smoke | `flutter analyze --no-fatal-infos` → exit 0 | ✅ exists |
| AUDIT-04 | `.planning/audit/SCHEMA.md` documents 11 fields + lifecycle fields | unit | `dart run scripts/audit/lint_schema.dart` (parses MD, asserts all field names present) | ❌ Wave 0 — `scripts/audit/lint_schema.dart` |
| AUDIT-05 | Severity taxonomy CRITICAL/HIGH/MEDIUM/LOW defined in SCHEMA.md with definitions | unit | (same as AUDIT-04) | ❌ Wave 0 |
| AUDIT-06 | Each `audit_*.sh` is invocable; emits a JSON shard | integration | `bash scripts/audit_layer.sh && jq '.findings \| length \| numbers' .planning/audit/shards/layer.json` (and repeat for the other three) | ❌ Wave 0 — `test/scripts/scanners_smoke_test.dart` |
| AUDIT-07 | `/gsd-audit-semantic` slash command exists; 4 subagent prompt files exist; agents emit shards in correct location | smoke + dry-run | `ls .claude/commands/gsd-audit-semantic.md .claude/commands/audit/*.md \| wc -l` (expect 5); manual dry-run by invoking the slash command and asserting `.planning/audit/agent-shards/*.json` populated | ❌ Wave 0 — slash-command files + manual dry-run checklist |
| AUDIT-08 | `merge_findings.dart` produces stable, deterministic `issues.json` and `ISSUES.md`; idempotent | integration | `dart run scripts/merge_findings.dart && diff <(jq -S . .planning/audit/issues.json) <(dart run scripts/merge_findings.dart -o /dev/stdout \| jq -S .)` | ❌ Wave 0 — `test/scripts/merger_idempotency_test.dart` |
| AUDIT-09 | CI gate rejects `sqlite3_flutter_libs` in pubspec.lock | integration | `! grep -q sqlite3_flutter_libs pubspec.lock` (in `audit.yml`) | ❌ Wave 0 — workflow YAML |
| AUDIT-10 | CI gate rejects stale generated files | integration | `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` (in `audit.yml`) | ❌ Wave 0 — workflow YAML |

### Sampling Rate

- **Per task commit:** `flutter analyze --no-fatal-infos && dart run custom_lint` (quick run, ≤ 60 s)
- **Per wave merge:** Full suite command above (≤ 5 min including all 4 scanners + merger)
- **Phase gate:** Full suite green before `/gsd-verify-work`; manual dry-run of `/gsd-audit-semantic` (D-01 specifics) on unchanged codebase to verify pipeline produces stable shard set

### Wave 0 Gaps

- [ ] `scripts/audit/finding.dart` — shared schema model (Section "Code Examples — Example 2")
- [ ] `scripts/audit/lint_layer_yaml.dart` — validates each `import_guard.yaml` file parses
- [ ] `scripts/audit/lint_schema.dart` — validates SCHEMA.md has all 11 + 4 lifecycle fields
- [ ] `test/scripts/dependencies_test.dart` — asserts dev_deps include the new tools
- [ ] `test/scripts/scanners_smoke_test.dart` — runs each scanner against an empty fixture and asserts the JSON shard exists & is well-formed
- [ ] `test/scripts/merger_idempotency_test.dart` — runs merger twice on identical shards, asserts byte-identical output
- [ ] `test/` framework: existing `flutter_test` covers the Dart side; bash scripts validated via `bats` (optional) or just-shell `set -e` smoke
- [ ] `.github/workflows/audit.yml` — greenfield; staged enablement (Section 8)

---

## Security Domain

> `security_enforcement` is not explicitly disabled in `.planning/config.json`; treat as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 1 introduces no auth surface |
| V3 Session Management | no | No sessions |
| V4 Access Control | no | No access-control changes |
| V5 Input Validation | yes | Audit scanners read JSON shards from disk; `merge_findings.dart` MUST schema-validate every shard before merging (drop malformed entries with a logged warning, never crash). Lint of YAML configs (`import_guard.yaml`) before they go into `lib/`. |
| V6 Cryptography | no | Phase 1 touches none of `lib/infrastructure/crypto/` |
| V7 Error Handling and Logging | yes | Scanner errors must be logged to stderr with structured prefix (`[audit:<dim>]`), never silently swallowed. Failed scanner = the merger emits a "scan_failed" entry rather than producing a half-complete catalogue. |
| V12 File Integrity | yes | `merge_findings.dart` writes to `.planning/audit/issues.json` and `ISSUES.md`. Both are committed; `git diff` after `merge_findings` shows what changed. CI artifact upload is the integrity check (no overwrites between phases). |
| V14 Configuration | yes | `analysis_options.yaml`, `pubspec.yaml`, `.github/workflows/audit.yml` are all version-controlled. AUDIT-09 + AUDIT-10 CI gates ARE the V14 enforcement once they flip blocking at end of Phase 1. |

### Known Threat Patterns for `scripts/` + CI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious shard injection (PR adding hand-edited `agent-shards/*.json` to mask findings) | Tampering | `merge_findings.dart` MUST regenerate shards from scratch in CI; never trust committed shard files. CI workflow always runs scanners + merger in a clean checkout. |
| Workflow command injection via PR title / branch name | Injection | Use `${{ github.event.pull_request.title }}` only inside quoted contexts; never eval branch names as shell. Standard GitHub Actions hygiene. |
| Stale `pubspec.lock` masking analyzer conflict | Tampering | CI runs `flutter pub get` fresh on every job; `pubspec.lock` change in PR triggers a re-resolve check. |
| `dart pub global activate` pulls a malicious coverde version | Supply-chain | Pin `dart pub global activate coverde 0.3.0+1` in CI workflow. Verify SHA on the activated package. |
| `import_guard.yaml` rules accidentally allow Domain → Data (rule misconfig) | Tampering | The 4 AI subagents are an independent check on the rules. Phase 1 dry-run against the unmodified codebase MUST surface the live CRIT-02 violations from CONCERNS.md; if the dry-run shows zero CRITICAL findings, the rules are misconfigured. |

---

## Sources

### Primary (HIGH confidence)

- **pub.dev (verified each via WebFetch on 2026-04-25):**
  - [pub.dev: import_guard_custom_lint](https://pub.dev/packages/import_guard_custom_lint) — v1.0.0, analyzer >=7.0.0 <9.0.0
  - [pub.dev: import_guard_custom_lint/versions/0.0.8](https://pub.dev/packages/import_guard_custom_lint/versions/0.0.8) — predecessor, custom_lint_builder >=0.7.5 <0.9.0
  - [pub.dev: import_guard](https://pub.dev/packages/import_guard) — v0.2.0, analyzer >=8.2.0 <13.0.0 (incompatible with current stack)
  - [pub.dev: dart_code_linter/versions/3.0.0](https://pub.dev/packages/dart_code_linter/versions/3.0.0) — analyzer ^7.4.1 (the chosen version)
  - [pub.dev: dart_code_linter/versions/4.0.2](https://pub.dev/packages/dart_code_linter/versions/4.0.2) — analyzer >=10.0.0 <13.0.0 (incompatible)
  - [pub.dev: coverde/versions/0.3.0+1](https://pub.dev/packages/coverde/versions/0.3.0+1) — analyzer >=8.0.0 <=10.0.0 (must install globally)
  - [pub.dev: riverpod_lint/versions/2.6.5](https://pub.dev/packages/riverpod_lint/versions/2.6.5) — analyzer ^7.0.0 (currently installed)
  - [pub.dev: riverpod_lint/versions/3.1.3](https://pub.dev/packages/riverpod_lint/versions/3.1.3) — analyzer ^9.0.0 (FUTURE-TOOL-01)
  - [pub.dev: json_serializable/versions/6.9.5](https://pub.dev/packages/json_serializable/versions/6.9.5) — analyzer >=6.9.0 <8.0.0 (locks the project at analyzer 7)
  - [pub.dev: freezed/versions/3.1.0](https://pub.dev/packages/freezed/versions/3.1.0) — analyzer >=6.9.0 <8.0.0
- **Project files:**
  - `pubspec.lock` — `analyzer 7.6.0`, `riverpod_lint 2.6.5`, `custom_lint 0.7.6`, `json_serializable 6.9.5`, `freezed 3.1.0`
  - `analysis_options.yaml` (current 14 lines, Phase 1 extension defined in Section 2)
  - `scripts/arb_to_csv.dart` — Dart-script precedent
  - `.planning/config.json` — `commit_docs: true`, `nyquist_validation: true`, `code_review: true`
  - `.planning/PROJECT.md` — initiative scope, behavior-preservation
  - `.planning/REQUIREMENTS.md` — AUDIT-01..AUDIT-10
  - `.planning/ROADMAP.md` — Phase 1 success criteria (verbatim in Phase Requirements section)
  - `.planning/STATE.md` — current pos = ready to plan Phase 1
  - `.planning/research/SUMMARY.md` / `STACK.md` / `ARCHITECTURE.md` / `PITFALLS.md` — reference research
  - `.planning/codebase/STRUCTURE.md` / `CONCERNS.md` / `CONVENTIONS.md` / `TESTING.md` / `STACK.md`
  - `.planning/phases/01-audit-pipeline-tooling-setup/01-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence, single-source)

- [github.com/bancolombia/dart-code-linter](https://github.com/bancolombia/dart-code-linter) — JSON reporter + check-unused-{code,files} CLI confirmation
- [github.com/ryota-kishimoto/import_guard](https://github.com/ryota-kishimoto/import_guard) — README YAML syntax + per-directory inheritance
- [github.com/VeryGoodOpenSource/very_good_coverage](https://github.com/VeryGoodOpenSource/very_good_coverage) — @v2 CI action

### Tertiary (LOW confidence — flag for verification)

- `custom_lint --format=json` versus `--reporter=json` flag spelling — verify with `dart run custom_lint --help` during planning. (A2)
- Exact glob semantics in `import_guard_custom_lint`'s `deny:` patterns — verify with one test rule before locking the 7 YAML files. (A1)
- `coverde` global-activation behavior on Ubuntu CI runner with the project's Flutter SDK — verify with one CI run. (A9)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every recommended package version verified against per-version pub.dev metadata; analyzer-conflict matrix walked end-to-end.
- Architecture: HIGH — pipeline shape locked by CONTEXT.md; researcher's role is to confirm package picks resolve, not to redesign.
- Pitfalls: HIGH — every pitfall (P1-1..P1-11) is grounded in either a verified version conflict, a documented YAML-syntax variant, or a CONTEXT.md / CLAUDE.md hard rule.
- AI subagent contracts: MEDIUM — prompt-file structure is straightforward; whether the four agents can produce stable shards is verified only at Phase 1 dry-run.

**Research date:** 2026-04-25
**Valid until:** 2026-05-25 (30 days for stable Dart toolchain; if `riverpod_lint`, `json_serializable`, or `analyzer` see a major bump, re-verify Section 1).

---
*Phase 1 research complete — ready for `/gsd-plan-phase`.*
