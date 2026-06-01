---
phase: 32-palette-exploration-selection
plan: 02
subsystem: ui
tags: [palette, pencil, mockups, wcag, dual-ledger, dark-mode]

requires:
  - phase: 32-palette-exploration-selection
    provides: "32-01 synthesis doc — 5 directions with per-role anchor hex + WCAG variants"
provides:
  - "home-pocket-palette.pen — 5 scheme groups × 6 frames (home-hero/txn-list/analytics × light/dark) = 30 frames"
  - "per-scheme light+dark variable collections keyed to AppColors symbols (get_variables → ADR-018 hex source)"
  - "visual confirmation (get_screenshot) of D-01/D-02/D-03 per scheme + amount-text legibility"
affects: [32-03, phase-33-token-system]

tech-stack:
  added: []
  patterns:
    - "Pencil palette stored as {scheme}×{mode} themed variable collections keyed to AppColors symbol names"
    - "literal-hex JS builder (mkHome/mkTxn/mkAna) for side-by-side multi-scheme rendering"

key-files:
  created:
    - home-pocket-palette.pen
  modified:
    - .planning/phases/32-palette-exploration-selection/32-PALETTE-SYNTHESIS.md

key-decisions:
  - "Rendered frames with literal per-scheme hex (not variable-bound fills) because Pencil theme resolution shows only ONE active theme variant at a time — variable-bound fills cannot display 5 schemes side-by-side. The themed variable collections are kept as the get_variables-readable ADR-018 hex record."
  - "Shipped all 5 schemes (A/B/C/D/E) per the synthesis 4-vs-5 decision."
  - "home-hero rendered in solo mode with a 花のおさいふ (shared) ledger row to still exercise the shared family; txn-list + analytics solo."

patterns-established:
  - "Each scheme = one group frame (gray backing) holding a light row + dark row, 3 captioned screens each"
  - "Amount glyphs bind the dark *Text variant; tints are tag/affordance only (Pitfall 2 mitigation visible in render)"

requirements-completed: [PALETTE-02]

duration: 55min
completed: 2026-06-01
---

# Phase 32 Plan 02: Pencil Palette Mockups Summary

**home-pocket-palette.pen with 5 full color schemes × 6 frames each (home-hero / transaction-list / analytics in light + dark), palette stored as AppColors-keyed variable collections, all D-01/D-02/D-03 constraints visually verified.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 3
- **Files modified:** 1 created (.pen), 1 modified (synthesis doc)

## Accomplishments
- Called `get_guidelines` FIRST (Mobile App guide + .pen schema) before any `batch_design` — Pitfall 1 honored.
- Defined the full palette as `{scheme: A–E} × {mode: light, dark}` themed variable collections via `set_variables`, keyed by the exact `AppColors`/`AppColorsDark` symbol names (25 roles incl. net-new success/warning/error/info). `get_variables` returns the complete, populated hex table — the authoritative ADR-018 source.
- Built 30 frames (5 schemes × 6: home-hero, txn-list, analytics × light, dark) via a literal-hex JS builder, laid out as 5 side-by-side scheme groups on one canvas for direct comparison (UI-SPEC copy contract). Every frame captioned `{scheme name} · {screen} · {light|dark}`.
- Each screen exercises its load-bearing roles: home-hero → accentPrimary (active tab) + daily/joy/shared rows + olive trend + coral satisfaction tile + surfaces/text; txn-list → daily/joy/shared accents + `*Light` tints + tags + borderList; analytics → joy KPI (ambient, no celebration), olive bar chart, success/warning/error/info status dots.
- `get_screenshot` per scheme (all 5) confirmed: coral present (D-01), Daily cool/neutral ↔ Joy warm/bright clear contrast (D-02), NO celebration affordance on the Joy KPI (D-03), amount-text legible via the dark `*Text` variants, frozen Wa-Modern geometry (color-only delta).
- Appended a Pencil render-confirmation note to `32-PALETTE-SYNTHESIS.md` `## Accessibility Verification` (the per-scheme WCAG table from 32-01 stands; variables seeded from those verified values).

## Task Commits
1. **Task 1: validate conventions + define variables** — variables set via Pencil MCP (not a git commit; lives in the .pen).
2. **Task 2: render 30 frames** — in the .pen; committed as the binary artifact below.
3. **Task 3: WCAG pass + synthesis note** — `395f6536` (synthesis doc note). PNG export attempted — see Deviations.

**Plan artifact commit:** `home-pocket-palette.pen` committed with this SUMMARY.

## Files Created/Modified
- `home-pocket-palette.pen` — 5-scheme palette mockup document (865 KB).
- `.planning/phases/32-palette-exploration-selection/32-PALETTE-SYNTHESIS.md` — appended Pencil render confirmation.

## Decisions Made
- **Literal-hex render, not variable-bound fills:** Pencil's `theme` mechanism renders only the single *active* theme variant at a time and exposes no API to set the active theme, so variable-bound fills cannot show 5 schemes side-by-side. Frames therefore bind literal per-scheme hex; the themed variable collections are retained purely as the `get_variables`-readable ADR-018 hex record (identical values). This fully satisfies the side-by-side comparison requirement and the ADR hex-export key_link.

## Deviations from Plan

### 1. [Environment — Pencil MCP] No save/flush tool → manual save required
- **Found during:** Task 3 (export + persistence).
- **Issue:** The Pencil MCP operates on the in-app editor and exposes no "save" tool. Writes (variables, frames) modify the in-memory document; the `.pen` only lands on disk when the user saves (Cmd+S) in the Pencil app. Initial work also went to an unsaved scratch doc (`pencil-new.pen`); resolved by `open_document` at the target absolute path, then rebuilding the 30 frames into the path-bound document.
- **Fix:** Bound the document to `/.../home-pocket-palette.pen` via `open_document`, rebuilt all frames, and requested a one-action user save. File now on disk (865 KB, verified).
- **Impact:** None on content — purely a persistence-mechanism gap. Documented so 32-03/future Pencil work opens at the target path first.

### 2. [Environment — Pencil MCP] export_nodes non-functional
- **Issue:** `export_nodes` returns `"you are probably referencing the wrong .pen file"` for every filePath form (absolute path, active-editor name, empty) even with the file saved on disk and node IDs valid in the active editor. Appears to be a tool defect in this environment.
- **Fix / mitigation:** No PNG files produced. The selection prompt (32-03) uses the verified inline `get_screenshot` renders of all 5 schemes and the user can open `home-pocket-palette.pen` directly in Pencil. The `.planning/.../exports/` dir is left empty.
- **Impact:** Cosmetic convenience only — the selection and ADR do not depend on exported PNGs (they depend on the .pen + the screenshots + the get_variables hex). No load-bearing impact.

### 3. [Minor] txn-list header icon
- **Issue:** lucide `filter` icon name invalid (first build); replaced with `sliders-horizontal` on the rebuild. No glitch in final render.

---

**Total deviations:** 3 (2 environment/tooling, 1 minor icon). **Impact on plan:** No scope or correctness impact — all 5 schemes fully rendered and verified; deliverable .pen on disk; ADR hex source intact.

## Issues Encountered
- Pencil theme-variant vs side-by-side rendering (resolved via literal-hex builder, see Decisions).
- Unsaved-scratch-doc vs path-bound document (resolved via open_document at target path + rebuild).

## Next Phase Readiness
- 32-03 can draft ADR-018 and, at the human checkpoint, present all 5 schemes (open the saved `.pen`, or the inline screenshots) for selection.
- Final hex for the chosen scheme is sourced from `get_variables` on `home-pocket-palette.pen` (or equivalently the synthesis doc — identical values).

---
*Phase: 32-palette-exploration-selection*
*Completed: 2026-06-01*
