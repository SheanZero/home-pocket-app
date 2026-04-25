---
phase: 1
slug: audit-pipeline-tooling-setup
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-25
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test 1.x (already installed) + bash for script tests |
| **Config file** | `pubspec.yaml` (dev_dependencies) |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter analyze && bash scripts/test_audit_pipeline.sh` |
| **Estimated runtime** | ~30–90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter analyze && bash scripts/test_audit_pipeline.sh`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

> The planner is responsible for filling this table from each PLAN.md task with the correct
> Test Type / Automated Command / File Exists status. Replace the placeholder rows below
> when plans are written. Each row corresponds to one `<task>` in a `*-PLAN.md`.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | AUDIT-01 | — | `flutter analyze` exits 0 on unmodified codebase | unit | `flutter analyze` | ❌ W0 | ⬜ pending |
| 1-02-01 | 02 | 2 | AUDIT-02 | — | `import_guard.yaml` files present at 5-layer roots | unit | `test -f lib/import_guard.yaml && test -f lib/features/import_guard.yaml` | ❌ W0 | ⬜ pending |
| 1-03-01 | 03 | 2 | AUDIT-03 | — | Each scanner shell wrapper invocable | smoke | `bash scripts/audit_layer.sh --dry-run` | ❌ W0 | ⬜ pending |
| 1-04-01 | 04 | 2 | AUDIT-04 | — | `merge_findings.dart` produces deterministic output | unit | `dart test test/scripts/merge_findings_test.dart` | ❌ W0 | ⬜ pending |
| 1-05-01 | 05 | 2 | AUDIT-05 | — | `.planning/audit/SCHEMA.md` describes locked fields | doc | `grep -q "tool_source" .planning/audit/SCHEMA.md` | ❌ W0 | ⬜ pending |
| 1-06-01 | 06 | 3 | AUDIT-06 | — | All 4 scanner JSON shards produced by full pipeline run | integration | `bash scripts/run_full_audit.sh && test -f .planning/audit/issues.json` | ❌ W0 | ⬜ pending |
| 1-07-01 | 07 | 3 | AUDIT-07 | — | `/gsd-audit-semantic` slash command + 4 prompt files exist | smoke | `test -f .claude/commands/gsd-audit-semantic.md && ls .claude/commands/audit/*.md \| wc -l \| grep -q '^[[:space:]]*4'` | ❌ W0 | ⬜ pending |
| 1-08-01 | 08 | 4 | AUDIT-08 | — | Re-run pipeline produces identical sorted IDs (idempotency) | integration | `bash scripts/test_idempotency.sh` | ❌ W0 | ⬜ pending |
| 1-09-01 | 09 | 4 | AUDIT-09 | T-1-09 | `grep sqlite3_flutter_libs pubspec.lock` exits non-zero | unit | `! grep -q sqlite3_flutter_libs pubspec.lock` | ✅ | ⬜ pending |
| 1-10-01 | 10 | 4 | AUDIT-10 | T-1-10 | build_runner stale-diff guardrail blocks dirty `lib/` | integration | `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> The planner is expected to expand this table to one row per `<task>` in each PLAN.md.
> Tasks that are pure documentation/configuration without an executable check should be
> labeled Test Type = `manual` and added to the "Manual-Only Verifications" section instead.

---

## Wave 0 Requirements

- [ ] `scripts/test_audit_pipeline.sh` — orchestrates per-scanner smoke tests + merger sanity check
- [ ] `scripts/test_idempotency.sh` — runs full pipeline twice, diffs `.planning/audit/issues.json` to confirm stable IDs
- [ ] `test/scripts/merge_findings_test.dart` — unit test for dedupe + ID-stamping in `merge_findings.dart`
- [ ] (Optional) `test/scripts/reaudit_diff_test.dart` — unit test for `reaudit_diff.dart` stub if planner exposes a callable function

*All Wave 0 artifacts live outside `lib/`, consistent with the discovery-only constraint of this phase.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `/gsd-audit-semantic` produces 4 agent shards with code-anchored evidence | AUDIT-07 | Subagent quality is judgment-bound; no deterministic "correct output" | Run `/gsd-audit-semantic` on the unmodified codebase, manually inspect `.planning/audit/agent-shards/*.json`: each finding must include a `file_path` + `line_start` + `line_end` triple that points at real source lines, and `rationale` text >100 chars. |
| `ISSUES.md` is human-skimmable + agent-parseable | AUDIT-04 | Format quality / readability is subjective | Owner skim: top-level `## CRITICAL/HIGH/MEDIUM/LOW`, per-category Markdown table with `ID \| File:Line \| Description \| Suggested Fix \| tool_source` columns, ≤1 line per finding. |
| Severity classification calls match owner expectations | AUDIT-04 | Severity boundaries (CRITICAL vs HIGH) require owner sanity-check | Owner reads `.planning/audit/ISSUES.md`, spot-checks ~5 findings per severity tier; flags any escalation/de-escalation requests as a Phase-1 amendment. |
| GitHub Actions workflow runs on PR + main push as designed | AUDIT-08 | Real CI environment can't be exercised locally | Open a noop PR, observe `audit.yml` runs report-only on warnings and FAILS the two blocking gates (sqlite3_flutter_libs reject + build_runner stale-diff) when intentionally tripped. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (`scripts/test_audit_pipeline.sh`, `scripts/test_idempotency.sh`, `test/scripts/merge_findings_test.dart`)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
