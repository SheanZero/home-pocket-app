---
phase: "07-documentation-sweep"
plan: "04"
subsystem: "docs/arch INDEX health + README sync"
tags: ["docs", "index-health", "verification-script", "readme-sync"]
dependency_graph:
  requires: ["07-01-SUMMARY.md", "07-02-SUMMARY.md", "07-03-SUMMARY.md"]
  provides: ["scripts/verify_index_health.sh", "docs/arch/02-module-specs/MOD-000_INDEX.md", "ARCH-000 UI section"]
  affects: ["docs/arch/README.md", "docs/arch/01-core-architecture/ARCH-000_INDEX.md"]
tech_stack:
  added: ["scripts/verify_index_health.sh (INDEX health shell verifier)"]
  patterns: ["stub-with-pointer (D-04)", "cross-directory INDEX master pattern"]
key_files:
  created:
    - "scripts/verify_index_health.sh"
    - "docs/arch/02-module-specs/MOD-000_INDEX.md"
  modified:
    - "docs/arch/01-core-architecture/ARCH-000_INDEX.md"
    - "docs/arch/README.md"
decisions:
  - "D-04 applied: MOD-000_INDEX.md is a 3-line stub-with-pointer, not a full duplicate of ARCH-000"
  - "Script uses index_dir-relative path resolution for broken-link check (handles cross-dir ../02-module-specs/ links)"
  - "ARCH-000_INDEX.md is the master index for UI specs (05-UI/) per D-04 rationale"
metrics:
  duration: "~20 minutes"
  completed: "2026-04-28"
  tasks_completed: 4
  files_changed: 4
---

# Phase 07 Plan 04: Index Health + README Sync Summary

INDEX files now reference only existing files; `bash scripts/verify_index_health.sh` exits 0 with zero BROKEN LINK and zero ORPHAN warnings across all three indexed directories.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| W0 | Create scripts/verify_index_health.sh (Wave 0 — currently fails) | 1ed23c6 | scripts/verify_index_health.sh |
| 1 | Create MOD-000_INDEX.md stub + add UI-001 entry to ARCH-000_INDEX.md | b6aab3b | docs/arch/02-module-specs/MOD-000_INDEX.md, docs/arch/01-core-architecture/ARCH-000_INDEX.md |
| 2 | Sync docs/arch/README.md to actual directory listing (D6) | 2cab7c3 | docs/arch/README.md |
| 3 | Fix verify_index_health.sh broken-link check + confirm exit 0 | 30339c8 | scripts/verify_index_health.sh |

## Pre/Post verify_index_health.sh Exit Codes

- **Pre-fix (Wave 0 commit 1ed23c6):** exits non-zero — ORPHAN: UI-001_Page_Inventory.md + MOD-000_INDEX.md missing
- **Post-fix (after commit 30339c8):** exits 0 — zero BROKEN LINK, zero ORPHAN (DOCS-03 closed)

## README.md Sync: Zero Phantom Files

The `find` loop (reference-existence check) reported ZERO MISSING lines after Task 2. All 34 file references in README.md (ARCH, MOD, ADR, BASIC, UI) exist on disk. Verified via:
```
grep -oE '[A-Z]+-[0-9]+(_[A-Z][A-Za-z_0-9]+)?\.md' docs/arch/README.md | sort -u
# → 34 filenames, all found under docs/arch/
```

## ARCH-000_INDEX.md: UI Section Added

Added new `### UI 规范文档` subsection after the BASIC-001..004 section, listing:
- `UI-001_Page_Inventory.md` with relative path `../05-UI/UI-001_Page_Inventory.md`

This closes RESEARCH §INDEX-Health-A E (UI-001 was ORPHAN in 05-UI/ before this plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed broken-link check path resolution in verify_index_health.sh**
- **Found during:** Task 3 (pre-run analysis)
- **Issue:** The script's broken-link check used `"$dir/$(basename "$path")"` which resolves cross-directory links `../02-module-specs/MOD-001.md` to `docs/arch/01-core-architecture/MOD-001.md` — a non-existent path. This would produce false-positive BROKEN LINK warnings for all MOD, BASIC, ADR, and UI references in ARCH-000_INDEX.md.
- **Fix:** Changed to `"${index_dir}/${path}"` where `index_dir=$(dirname "$index")`. Relative paths like `../02-module-specs/MOD-001.md` now correctly resolve through the filesystem to `docs/arch/02-module-specs/MOD-001.md`.
- **Files modified:** `scripts/verify_index_health.sh`
- **Commit:** 30339c8

## Lib/-Clean Confirmation

```
git diff --name-only 3bf7e32c4b8052bec97bb6670c69c84bd84993c5 HEAD
# → docs/arch/01-core-architecture/ARCH-000_INDEX.md
# → docs/arch/02-module-specs/MOD-000_INDEX.md
# → docs/arch/README.md
# → scripts/verify_index_health.sh
# Zero files under lib/, test/, pubspec*, .github/, or analysis_options
```

lib/-clean: CONFIRMED (0 code files modified).

## Known Stubs

`docs/arch/02-module-specs/MOD-000_INDEX.md` is an intentional stub-with-pointer per D-04. It delegates to ARCH-000_INDEX.md's `#功能模块技术文档` section. This is by design — full duplication would create two-source-of-truth drift.

## Self-Check

Files created/modified exist on disk:
- scripts/verify_index_health.sh: FOUND (executable, 51 lines)
- docs/arch/02-module-specs/MOD-000_INDEX.md: FOUND (3 lines)
- docs/arch/01-core-architecture/ARCH-000_INDEX.md: FOUND (UI-001 entry present)
- docs/arch/README.md: FOUND (all 5 bugs fixed)

Commits exist:
- 1ed23c6: FOUND
- b6aab3b: FOUND
- 2cab7c3: FOUND
- 30339c8: FOUND

## Self-Check: PASSED
