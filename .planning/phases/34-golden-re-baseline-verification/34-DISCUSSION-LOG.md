# Phase 34: Golden Re-baseline & Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 34-Golden Re-baseline & Verification
**Areas discussed:** Dark golden coverage, Diff verification rigor, Audit breadth & .pen, Regression protocol

---

## Dark Golden Coverage

### Coverage scope
| Option | Description | Selected |
|--------|-------------|----------|
| Close D-07 gap | Add dark variants to the 7 light-only golden tests (all 12 → light+dark) | ✓ |
| Regenerate existing only | Refresh 52 masters to new palette, no new variants; list_* dark stays uncovered | |
| Broader new coverage | Also add goldens for dark screens with no golden today | |

**User's choice:** Close D-07 gap (D-01)
**Notes:** Honors Phase 33 D-07's "full dark golden set" promise; the light-only `list_*` family are daily-use core surfaces where dark regression risk is highest.

### Dark variant locale coverage
| Option | Description | Selected |
|--------|-------------|----------|
| ja single-locale representative | Follow existing dark-golden convention, 1 ja golden per widget | |
| Match light's locale coverage | Per-locale dark (e.g. en/ja/zh dark for list_transaction_tile) | ✓ |

**User's choice:** Match light's per-locale coverage (D-01b)
**Notes:** Chose thoroughness over minimal golden count.

---

## Diff Verification Rigor

### Verification method
| Option | Description | Selected |
|--------|-------------|----------|
| Per-golden human review | Run without --update first, review each isolatedDiff, then update | ✓ |
| Spot-check key screens | Manually review high-risk screens only, trust-regenerate the rest | |
| Full trust-regenerate | --update all, rely on non-golden widget tests to catch regressions | |

**User's choice:** Per-golden diff review (D-02)
**Notes:** Milestone-closing gate; intended deltas are D-04/D-05 + palette, so it's attribution-based, not zero-diff.

### Review division of labor
| Option | Description | Selected |
|--------|-------------|----------|
| Claude pre-screens + you final-review | Claude flags suspicious diffs, user UATs only flagged ones | |
| You review all manually | User eyeballs every diff, Claude no pre-judgment | |
| Claude judges fully, no human gate | Claude classifies + decides update autonomously | ✓ |

**User's choice:** Claude judges fully, no human gate (D-02b)
**Notes:** Bounded by the regression protocol (D-04) — pure-palette deltas auto-update; suspected regressions halt and report.

---

## Audit Breadth & .pen

### Audit breadth
| Option | Description | Selected |
|--------|-------------|----------|
| Standard two greps + old-hex sweep | Add retired coral/blue/green hex sweep outside core/theme | |
| Strictly the two standard greps | Only the ROADMAP-specified greps return zero | |
| Comprehensive (incl. test/docs) | Two greps + old hex + sweep test/ and docs/ | ✓ |

**User's choice:** Comprehensive scan incl. test/docs (D-03a)
**Notes:** Planner must not flag legitimate palette hex living in lib/core/theme/ (Phase 33 D-03).

### .pen reconciliation
| Option | Description | Selected |
|--------|-------------|----------|
| Leave it, mark out-of-scope | .pen is a design artifact, ADR-018 authoritative | |
| Commit current state | Commit the modified .pen to clean working tree | |
| Attempt sync to ADR-018 | Use Pencil MCP to update .pen to ADR-018 hex | ✓ |

**User's choice:** Attempt sync to ADR-018 (D-03b)
**Notes:** Claude flagged the known constraint — this environment's Pencil MCP cannot flush to disk. Captured as best-effort with deferred fallback; does NOT block milestone close.

---

## Regression Protocol

| Option | Description | Selected |
|--------|-------------|----------|
| Halt and report, no silent update | Any non-palette delta is surfaced as a Phase-33 defect | ✓ |
| Minor fix inline, structural reports | Cosmetic fixed in 34, structural halts | |
| Treat all as palette, update all | No distinction, update everything | |

**User's choice:** Halt and report, no silent update (D-04)
**Notes:** Together with D-02b, defines Claude's autonomy boundary — pure-palette auto-updates, suspected regression halts.

## Claude's Discretion

- Golden device sizes, truncation tolerances, dark-variant wrapper implementation.
- Exact list of retired hex values for the D-03a sweep (from app_colors.dart git history).
- Regenerate → review → audit sequencing and diff-review batching.
- Coverage-gate handling (≥70% global).

## Deferred Ideas

- Broader dark-golden coverage for currently-untested screens — future theming/QA phase.
- Authoritative .pen↔ADR-018 sync if a working Pencil flush path appears.
- Migrating off native goldens to golden_toolkit/alchemist.
