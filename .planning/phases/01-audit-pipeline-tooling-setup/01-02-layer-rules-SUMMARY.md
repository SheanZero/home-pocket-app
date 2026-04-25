---
phase: 01-audit-pipeline-tooling-setup
plan: 02
subsystem: audit-pipeline
tags: [import-guard, layer-rules, clean-architecture, discovery-only]
requirements: [AUDIT-02]
dependency_graph:
  requires:
    - "01-01: import_guard_custom_lint plugin registered in pubspec.yaml + analysis_options.yaml"
  provides:
    - "18 per-directory import_guard.yaml files encoding 5-layer Clean Architecture rules"
    - "Thin Feature rule (catches CRIT-02 territory: features/*/use_cases/, application/, infrastructure/, data/)"
    - "Domain whitelist (catches CRIT-04 territory: Domain importing Data/Application/Infrastructure/Flutter)"
    - "Presentation→Infrastructure deny (catches HIGH-02 territory)"
  affects:
    - "Plan 04 audit_layer.sh: will surface findings these rules detect"
    - "Plan 06 AI subagents: cross-check these rules against actual imports"
    - "Plan 07 CI workflow: ships with continue-on-error: true (D-04), flips to blocking at end of Phase 3"
tech-stack:
  added: []
  patterns:
    - "Per-directory YAML (not single root file) — required by import_guard_custom_lint inheritance model"
    - "Whitelist-mode (allow:) reserved for Domain layer; other layers use deny-only"
    - "inherit: true on every YAML so child rules compose with parent rules"
key-files:
  created:
    - lib/import_guard.yaml
    - lib/features/import_guard.yaml
    - lib/application/import_guard.yaml
    - lib/data/import_guard.yaml
    - lib/infrastructure/import_guard.yaml
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
  modified: []
decisions:
  - "Used per-directory YAML files (not a single root file with path-scoped rules) per RESEARCH §3 Pitfall P1-5 — import_guard_custom_lint requires this for inheritance"
  - "Domain layer uses whitelist mode (allow: dart:core + freezed_annotation + json_annotation + meta); all other layers use deny-only"
  - "dual_ledger has NO domain/ subdir per verified inventory, so no domain YAML created (6 domain YAMLs total, not 7)"
  - "All 18 files end with inherit: true so cross-layer rules compose at every level"
  - "Did not extend Domain whitelist with ulid/collection — Phase 1 is conservative; Plan 06 AI dry-run will surface any legitimate Domain imports of these libs and trigger an amendment if needed"
metrics:
  duration_minutes: 2
  completed_date: 2026-04-25
  tasks_completed: 2
  files_created: 18
  files_modified: 0
  dart_files_touched: 0
---

# Phase 01 Plan 02: Layer Rules (import_guard.yaml) Summary

One-liner: Encoded the 5-layer Clean Architecture as 18 per-directory `import_guard.yaml` files (5 cross-layer + 6 domain whitelist + 7 presentation deny), ready to surface CRIT-02/CRIT-04/HIGH-02 territory once Plan 04's `audit_layer.sh` runs.

## Outcome

AUDIT-02 satisfied. The 5-layer dependency rules from `STRUCTURE.md` + CLAUDE.md are now encoded as analyzer config consumed by `import_guard_custom_lint` (registered in Plan 01). Rules are inert in Phase 1 (CI ships `continue-on-error: true` per D-04) and become blocking gates at the end of Phase 3 (CRITICAL) and Phase 4 (HIGH).

The Thin-Feature rule at `lib/features/import_guard.yaml` covers the live CRIT-02 violation in `lib/features/family_sync/use_cases/` (per `.planning/codebase/CONCERNS.md`); Plan 04's `audit_layer.sh` will surface it, and Plan 06's AI subagents will cross-check the rule encoding for misconfig (the `import_guard.yaml` rule misconfig threat identified in RESEARCH "Known Threat Patterns" — Threat T-1-02-01).

## Tasks Completed

| # | Name | Commit | Files |
| - | ---- | ------ | ----- |
| 1 | Create cross-layer import_guard.yaml files | a43abfc | lib/import_guard.yaml, lib/features/import_guard.yaml, lib/application/import_guard.yaml, lib/data/import_guard.yaml, lib/infrastructure/import_guard.yaml |
| 2 | Create per-feature domain (×6) + presentation (×7) import_guard.yaml files | 5bd1f42 | 6 domain whitelist YAMLs + 7 presentation deny YAMLs |

Total: 18 YAML files, 0 Dart files modified.

## Layer Rule Taxonomy

### Cross-layer (5 files)

| File | Mode | Key rules |
| ---- | ---- | --------- |
| `lib/import_guard.yaml` | deny | dart:mirrors, package:sqlite3_flutter_libs/** (defense-in-depth for AUDIT-09) |
| `lib/features/import_guard.yaml` | deny | features/*/use_cases/**, application/**, infrastructure/**, data/** (Thin Feature rule) |
| `lib/application/import_guard.yaml` | deny | features/*/presentation/**, data/tables/**, data/daos/** |
| `lib/data/import_guard.yaml` | deny | features/*/presentation/**, application/** |
| `lib/infrastructure/import_guard.yaml` | deny | features/**, application/**, data/** (Infrastructure depends on external SDKs only) |

### Per-feature Domain whitelist (6 files)

Identical content across `lib/features/{accounting,analytics,family_sync,home,profile,settings}/domain/import_guard.yaml`:
- `deny`: data/**, infrastructure/**, application/**, features/**/presentation/**, package:flutter/**
- `allow`: dart:core, package:freezed_annotation/**, package:json_annotation/**, package:meta/**

`dual_ledger` intentionally has no domain YAML (no `domain/` subdir per verified inventory).

### Per-feature Presentation deny (7 files)

Identical content across `lib/features/{accounting,analytics,dual_ledger,family_sync,home,profile,settings}/presentation/import_guard.yaml`:
- `deny`: data/tables/**, data/daos/**, infrastructure/crypto/services/**, infrastructure/sync/**, infrastructure/security/secure_storage_service.dart, infrastructure/crypto/repositories/**

## Verification Results

| Check | Result |
| ----- | ------ |
| 18 `import_guard.yaml` files exist | PASS (find lib -name 'import_guard.yaml' returns 18) |
| All files have `inherit: true` | PASS (all 18) |
| All files parse as valid YAML (ruby -ryaml) | PASS (all 18) |
| 6 domain YAMLs use `allow:` whitelist | PASS |
| Other 12 YAMLs use deny-only (no allow:) | PASS |
| `lib/features/dual_ledger/domain/import_guard.yaml` absent | PASS |
| `flutter analyze --no-fatal-infos` exit 0 | PASS ("No issues found! ran in 6.1s") |
| No `.dart` files modified | PASS (`git diff --name-only -- 'lib/**/*.dart' \| wc -l` = 0) |
| Zero file deletions in commits | PASS |

## Deviations from Plan

None - plan executed exactly as written.

The plan's `<interfaces>` block was verified against the actual codebase before any YAML was written:
- `dual_ledger/` has only `presentation/` (no `domain/`) — confirmed by `ls lib/features/dual_ledger/`
- `family_sync/` has the live `use_cases/` violation — confirmed by `ls lib/features/family_sync/`

The Domain whitelist deliberately does NOT include `ulid` or `collection`. Per the plan's note, if Plan 06's AI dry-run flags a legitimate Domain import of these libs, a follow-up amendment can extend the whitelist. For Phase 1, conservative is correct.

## Authentication Gates

None encountered.

## Threat Surface Notes

The threat register from PLAN.md is satisfied by the verification results:

| Threat | Mitigation | Status |
| ------ | ---------- | ------ |
| T-1-02-01: Rule misconfig (typo silently allowing Domain → Data) | AI subagents (Plan 06) cross-check; live CRIT-02 in family_sync/use_cases/ MUST surface in Plan 08 | Pending Plan 06/08 (rules placed correctly per RESEARCH §3) |
| T-1-02-02: Discovery-only constraint violation (.dart files modified) | Acceptance criterion git diff check | PASS — 0 .dart files modified |
| T-1-02-03: Missing inherit: true on a per-directory file | grep `^inherit: true$` on every YAML | PASS — all 18 |

No new code-execution surface introduced. YAMLs are config consumed by the analyzer plugin only.

## Self-Check: PASSED

- All 18 `import_guard.yaml` files: FOUND
- Commit a43abfc (Task 1): FOUND in git log
- Commit 5bd1f42 (Task 2): FOUND in git log
- `flutter analyze --no-fatal-infos`: exit 0 (verified post-Task-2)
- `git diff --name-only -- 'lib/**/*.dart' | wc -l`: 0 (discovery-only constraint preserved)
