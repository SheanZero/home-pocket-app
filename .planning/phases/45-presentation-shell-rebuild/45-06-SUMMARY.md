---
phase: 45-presentation-shell-rebuild
plan: 06
subsystem: docs/architecture
tags: [adr, anti-gamification, cross-period, doc-only]
requires:
  - "GATE-04 decision 2 (expense-side cross-period = recorded ADR-012 amendment)"
  - "STATE.md §4 carve-out record"
provides:
  - "ADR-012 ## Update section recording the expense-side 本月vs上月 §4 carve-out"
affects:
  - "Phase 46 cross-period expense-trend UI (red-line now recorded ahead of render)"
tech-stack:
  added: []
  patterns: ["append-only ADR amendment (arch.md)"]
key-files:
  created: []
  modified:
    - "docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md"
decisions:
  - "D-D1 discharged: expense-side 本月vs上月 trend recorded as user-approved §4 carve-out; joy-side cross-period stays ABSOLUTELY forbidden"
  - "Append-only: original decision body, §🚫 Forbidden Features list, and 状态: header line left byte-unchanged; ratification-since-Phase-12 noted as an Update remark rather than a hand-edit to line 7"
metrics:
  duration: "~5 min"
  completed: "2026-06-17"
  tasks: 1
  files: 1
---

# Phase 45 Plan 06: ADR-012 §4 Expense-Side Carve-Out Append Summary

Appended a single append-only `## Update 2026-06-17` section to ADR-012 recording the expense-side 本月vs上月 trend (总支出/日常 tabs) as a user-approved §4 carve-out, with the joy-side cross-period prohibition reaffirmed as absolute — zero functional coupling, discharging the long-recorded D-D1 obligation before Phase 46 renders any cross-period expense UI.

## What Was Built

- One new `## Update 2026-06-17: 支出侧「本月vs上月」趋势 — §4 记录在案例外` section appended at the end of `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md`, after the final `*下次审查触发: v1.2 milestone start*` line. The section:
  - Carries the GATE-04 carve-out wording verbatim (EN + 中文等义): cross-period comparison permitted on the EXPENSE side (总支出/日常), matching the home 支出趋势, neutral labels.
  - States explicitly that the **joy-side (悦己) cross-period prohibition remains ABSOLUTE** (悦己侧跨期仍绝对禁止) — the carve-out is expense-side only and does not relax the joy red line. §🚫 items 4/7 continue in full force.
  - Cites the approval source: GATE-04 (`.planning/phases/43-html-design-gate-no-production-code/GATE-04-adr-go-no-go.md`, decision 2 = GO) + STATE.md §4 carve-out record, plus the upstream chain (ROUND2-DECISION.md → selected-adr012-audit.md).
  - Notes timing (recorded at Phase 45 ahead of Phase 46 UI) and zero functional coupling (Phase 45 renders no cross-period callout under D-A1).
  - Records, as an Update remark only, that the ADR is effectively `✅ 已接受` since Phase 12 — without hand-editing the `状态:` header line.

## How to Verify

- `grep -cE "^## Update" docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` → `1` (previously zero).
- `git diff --numstat <file>` against the pre-commit state showed `42	0` — **zero deletions** (strict append-only; decision body / §🚫 list / line 7 `状态:` untouched).
- `grep -qE "支出侧|本月vs上月"` → present; `grep -E "悦己.*禁止|joy-side.*forbidden"` → matches; `§4` cited 6×.
- Combined verify gate from the plan returned `OK`.

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

- **D-D1 discharged** in a single append-only Update section, as the plan and RESEARCH recommended.
- Recorded the never-formally-noted Phase 12 ratification as an in-section Update remark (RESEARCH-permitted option) rather than editing the `状态:` header, keeping the change strictly append-only per `.claude/rules/arch.md`.

## Known Stubs

None — doc-only markdown append, no code, no data wiring.

## Threat Flags

None — markdown append to a decision record; no runtime surface, no input/network/persistence/auth/crypto. T-45-12 (tampering with decision body) and T-45-13 (relaxing joy-side red line) were both mitigated by the acceptance gates (0 deletions; explicit 悦己侧跨期仍绝对禁止 statement). No package installs (T-45-SC accept).

## Self-Check: PASSED

- FOUND: docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md (modified, `## Update` section present)
- FOUND commit: d4289839 (docs(45-06): append §4 expense-side carve-out Update to ADR-012)
