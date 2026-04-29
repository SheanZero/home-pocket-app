---
phase: 06-low-fixes
plan: 01
subsystem: audit
tags: [dead-code, audit-catalogue, architecture-tests, dart-code-linter]

requires:
  - phase: 05-medium-fixes
    provides: closed MEDIUM catalogue rows and scanner enforcement patterns
provides:
  - refreshed dead-code scanner parsing for dart_code_linter JSON output
  - stable LOW dead-code findings closed with traceable commit metadata
  - LOW closure and stale suppression architecture gates
affects: [phase-06-low-fixes, phase-08-reaudit]

tech-stack:
  added: []
  patterns:
    - preserve closed audit lifecycle metadata during shard regeneration
    - retain closed findings after clean scanner shards remove active rows

key-files:
  created:
    - test/architecture/low_findings_closed_test.dart
    - test/architecture/stale_suppressions_scan_test.dart
  modified:
    - scripts/audit/dead_code.dart
    - scripts/merge_findings.dart
    - scripts/audit/finding.dart
    - .planning/audit/issues.json
    - .planning/audit/shards/dead_code.json

key-decisions:
  - "Closed LOW rows retain stable DC IDs even after clean scanner shards emit zero active findings."
  - "Generated files tied only to deleted source files were removed with their source so direct unused-file gates can reach zero."

patterns-established:
  - "LOW closure gate mirrors the MEDIUM closure JSON parsing pattern."
  - "Suppression scanner skips generated outputs and requires explicit allow-list reasons for any non-generated ignore directive."

requirements-completed: [LOW-01, LOW-02, LOW-03, LOW-07]

duration: 47min
completed: 2026-04-27
---

# Phase 06: Plan 01 Summary

**LOW dead-code catalogue restored, scanner-confirmed orphaned code removed, and closure gates added**

## Performance

- **Duration:** 47 min
- **Started:** 2026-04-27T07:51:54Z
- **Completed:** 2026-04-27T08:38:14Z
- **Tasks:** 2
- **Files modified:** 55

## Accomplishments

- Fixed the dead-code scanner wrapper so dart_code_linter progress output and `unusedCode` / `unusedFiles` JSON shapes are parsed correctly.
- Recorded 24 scanner-backed LOW `DC-*` rows, removed the corresponding orphaned code/tests, then closed every LOW row with cleanup commit `f635b1aaee3293b46afaa3adbd66c7d63b60cf66`.
- Added architecture gates for open LOW findings and stale non-generated suppression directives.

## Task Commits

1. **Task 1: Re-scan LOW findings and restore catalogue traceability** - `bb1ca8f`
2. **Task 2: Delete dead code and stale suppressions, then add closure gates** - `f635b1a`, `8e67332`

## Files Created/Modified

- `test/architecture/low_findings_closed_test.dart` - Fails when any LOW finding remains open.
- `test/architecture/stale_suppressions_scan_test.dart` - Scans non-generated Dart files for unapproved `// ignore:` directives.
- `scripts/audit/dead_code.dart` - Parses current dart_code_linter JSON output and clean zero-finding output.
- `scripts/merge_findings.dart` - Preserves closed lifecycle metadata and retained closed rows across clean shard regeneration.
- `.planning/audit/issues.json` - Contains 24 closed LOW dead-code rows with Phase 6 closure metadata.

## Decisions Made

- Deleted generated outputs only when their source file was removed and the direct unused-file gate reported the generated output as orphaned.
- Kept prior CRITICAL/HIGH/MEDIUM closures intact by preserving lifecycle metadata during merge regeneration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated audit merger lifecycle handling**
- **Found during:** Task 1
- **Issue:** Regenerating `issues.json` from shards would reopen previously closed non-LOW findings and later drop closed LOW rows after the scanner became clean.
- **Fix:** Preserve existing closed lifecycle metadata by stable finding key and retain closed rows absent from clean shards.
- **Files modified:** `scripts/merge_findings.dart`, `scripts/audit/finding.dart`, `test/scripts/merge_findings_test.dart`
- **Verification:** `flutter test test/scripts/merge_findings_test.dart`
- **Committed in:** `bb1ca8f`, `f635b1a`

**Total deviations:** 1 auto-fixed (Rule 3). **Impact:** Required to keep Phase 6 traceability correct; no behavior scope expansion.

## Issues Encountered

- The first executor agent stalled without producing artifacts, so Plan 01 was executed inline.
- Removing first-pass unused files exposed second-order orphaned widgets and generated outputs; the dead-code checks were rerun until both unused-code and unused-file gates reached zero.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 can proceed. The LOW catalogue is trustworthy, dead-code scanners report zero active findings, and the LOW/stale-suppression architecture gates pass.

## Self-Check: PASSED

- `bash scripts/audit_dead_code.sh` passed with 0 findings.
- `dart run scripts/merge_findings.dart` passed and retained 50 total findings with 0 open LOW rows.
- `dart run dart_code_linter:metrics check-unused-code lib` passed.
- `dart run dart_code_linter:metrics check-unused-files lib` passed.
- `flutter test test/architecture/low_findings_closed_test.dart test/architecture/stale_suppressions_scan_test.dart` passed.
- `flutter analyze` passed.

---
*Phase: 06-low-fixes*
*Completed: 2026-04-27*
