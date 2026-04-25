# Architecture Research

**Domain:** Audit-driven Flutter/Dart codebase cleanup pipeline
**Researched:** 2026-04-25
**Confidence:** HIGH

---

## Standard Architecture

### System Overview

The cleanup workflow is a five-component pipeline. Every component has a strict producer/consumer relationship: nothing flows backward except the re-audit at the end, which reads from the same source as the initial audit.

```
┌──────────────────────────────────────────────────────────────────────┐
│  COMPONENT 1 — AUDIT ENGINE                                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────┐ │
│  │  dart analyze  │  │  custom_lint   │  │  AI-Agent Semantic     │ │
│  │  --format=     │  │  (riverpod_    │  │  Scan (import graph,   │ │
│  │  machine       │  │  lint, layer   │  │  dead code, provider   │ │
│  │                │  │  rules)        │  │  duplication)          │ │
│  └───────┬────────┘  └───────┬────────┘  └──────────┬─────────────┘ │
│          │                  │                       │               │
│          └──────────────────┴───────────────────────┘               │
│                                     │                               │
│                             (raw findings)                          │
└─────────────────────────────────────┼────────────────────────────── ┘
                                      ▼
┌──────────────────────────────────────────────────────────────────────┐
│  COMPONENT 2 — ISSUE CATALOGUE                                       │
│                                                                      │
│  .planning/ISSUES.md  (canonical, human-readable)                   │
│  .planning/issues.json (machine-readable — feeds re-audit diffing)  │
│                                                                      │
│  Schema per entry:                                                   │
│    id, category, severity, file, line_start, line_end,              │
│    description, phase_assigned, status                              │
└─────────────────────────────────────┬────────────────────────────── ┘
                                      │
                                      ▼ (grouped by severity)
┌──────────────────────────────────────────────────────────────────────┐
│  COMPONENT 3 — FIX PHASES (sequential, severity-ordered)            │
│                                                                      │
│  Phase A: CRITICAL-only — layer violations that make architecture   │
│           fundamentally unsound (domain→data imports, feature-held  │
│           application/ code, appDatabase UnimplementedError etc.)   │
│                                                                      │
│  Phase B: HIGH — provider hygiene, deprecated wired services,       │
│           security regressions (recoverFromSeed guard), security    │
│           boundary violations                                        │
│                                                                      │
│  Phase C: MEDIUM — dead code, redundant models, orphaned utilities, │
│           MOD-009 code references, hardcoded strings (i18n), debug  │
│           print cleanup, audit log retention, SQL string interpolation│
│                                                                      │
│  Phase D: LOW — minor style, missing indices, docs-vs-reality drift, │
│           cosmetic duplication, analysis_options tweaks             │
│                                                                      │
│  Each phase:                                                         │
│    1. Write characterization tests (capture current behavior)       │
│    2. Refactor to eliminate findings                                 │
│    3. Verify ≥80% coverage on every touched file                    │
│    4. Run flutter analyze (must be 0 issues), dart format           │
└─────────────────────────────────────┬────────────────────────────── ┘
                                      │
                                      ▼ (after ALL phases complete)
┌──────────────────────────────────────────────────────────────────────┐
│  COMPONENT 4 — DOC SWEEP                                            │
│                                                                      │
│  One centralized pass over doc/arch/ (ARCH/MOD/ADR files) aligning  │
│  documentation to the refactored code state. Not per-phase.         │
└─────────────────────────────────────┬────────────────────────────── ┘
                                      │
                                      ▼
┌──────────────────────────────────────────────────────────────────────┐
│  COMPONENT 5 — RE-AUDIT (final gate)                                │
│                                                                      │
│  Re-run the identical audit pipeline from Component 1.              │
│  Diff output against issues.json.                                   │
│  Exit criterion: zero open findings across all four categories.     │
│  If any remain: return to the appropriate fix phase.                │
└──────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Produces |
|-----------|----------------|----------|
| Audit Engine | Enumerate every violation with file + line reference and severity | Raw findings (mixed tool + agent output) |
| Issue Catalogue | Normalize, deduplicate, and classify all findings into a single structured list | `ISSUES.md` + `issues.json` |
| Fix Phases (A–D) | Eliminate findings grouped by severity; enforce coverage gate per phase | Refactored code + new/updated tests |
| Doc Sweep | Align ARCH/MOD/ADR to post-refactor code state | Updated `doc/arch/` files |
| Re-Audit | Re-run the full audit; produce a diff proving zero violations remain | Pass/fail verdict + diff report |

---

## Recommended Project Structure

This is the cleanup pipeline's own artifact structure, layered inside `.planning/`:

```
.planning/
├── PROJECT.md                  # Mission + constraints (already exists)
├── ROADMAP.md                  # Phase definitions (produced by roadmap phase)
├── ISSUES.md                   # Human-readable issue catalogue (Phase 1 output)
├── issues.json                 # Machine-readable issue catalogue (Phase 1 output)
├── coverage-baseline.txt       # Baseline coverage snapshot taken before any fix phase
├── re-audit/
│   └── ISSUES-REAUDIT.md       # Final re-audit output (Component 5)
├── codebase/                   # Existing codebase map (already exists)
│   ├── ARCHITECTURE.md
│   ├── STRUCTURE.md
│   ├── CONCERNS.md
│   └── ...
└── research/                   # This directory

scripts/                        # Existing, add cleanup-pipeline scripts here
├── arb_to_csv.dart             # Already exists
├── audit_layer.sh              # New: import-graph violation scanner
├── audit_dead_code.sh          # New: dead export / unreachable branch scanner
├── audit_providers.sh          # New: Riverpod provider hygiene scanner
├── coverage_gate.sh            # New: per-file ≥80% coverage enforcer
└── reaudit_diff.sh             # New: diff issues.json vs re-audit output
```

### Structure Rationale

- `ISSUES.md` + `issues.json` colocate the catalogue with the plan so every phase can read from it without cross-repo lookups.
- `scripts/` uses the existing directory (already has `arb_to_csv.dart`); no new top-level directory needed.
- `coverage-baseline.txt` must be captured before any refactor begins so per-file enforcement is relative to a known state.
- `re-audit/` is a separate directory so the re-audit output is never confused with the initial catalogue.

---

## Architectural Patterns

### Pattern 1: Tooling Stream → Catalogue Normalization

**What:** The automated tools (`dart analyze --format=machine`, `flutter pub run custom_lint`, `riverpod_lint`) each emit their own format. These must be normalized into a single catalogue before any human or agent processes them. The AI-agent semantic scan supplements tooling with findings that grep cannot detect (cross-file dependency inversion, provider duplication across features, semantic dead code).

**When to use:** Always — do not let the two streams stay separate. A violation that appears in both tool output and agent findings must be deduplicated into one entry.

**Data interchange format:**

```
Tooling output: dart analyze --format=machine
  → SEVERITY|TYPE|CODE|FILE|LINE|COL|LEN|MESSAGE
  → pipe-delimited, scriptable with awk/grep

Agent output: structured Markdown list per category
  → normalized by a Dart script into issues.json

issues.json entry schema:
{
  "id": "LV-001",
  "category": "layer_violation | redundant | dead_code | provider_hygiene",
  "severity": "CRITICAL | HIGH | MEDIUM | LOW",
  "file": "lib/features/accounting/presentation/providers/use_case_providers.dart",
  "line_start": 13,
  "line_end": 69,
  "description": "ResolveLedgerTypeService retained with @Deprecated ignore suppression",
  "phase_assigned": "B",
  "status": "open | resolved | wont_fix"
}
```

**Trade-offs:**
- Normalization step adds upfront cost (~half a day) but pays for itself by enabling automated diffing at re-audit time.
- JSON as interchange format is parseable by both Dart scripts and shell tools (`jq`).
- Markdown is kept as the human-readable mirror so phases can read it without tooling.

### Pattern 2: Characterization-Test-First Refactor (Feathers Pattern)

**What:** Before modifying any file, write characterization tests that capture the current observable behavior of that file (or module boundary). Refactor next. Add edge-case tests last. This is the canonical pattern from *Working Effectively with Legacy Code* (Feathers, 2004) for safe large-scale structural refactoring.

**When to use:** Every fix phase. Mandatory before touching any file not already at ≥80% coverage.

**Sequence for each file targeted in a fix phase:**

```
1. Measure current coverage for the file (lcov extract)
2. If < 80%: write characterization tests until ≥ 80%
   (golden/snapshot-style: assert current behavior, not ideal behavior)
3. Run tests → GREEN (capturing current behavior)
4. Apply the refactor (structural change only, no behavior change)
5. Run tests → must stay GREEN (behavior preserved)
6. Add edge-case / correctness tests for any new logic paths
7. Re-measure coverage → must be ≥ 80%
```

**Trade-offs:**
- Characterization tests are write-once artifacts; some will be deleted after the next feature wave introduces proper behavior tests. That is expected and acceptable.
- This is slower upfront than "refactor first, test after" but eliminates silent regressions. For a codebase with ~68% current coverage and security-critical crypto paths, the risk of silent regression without this pattern is unacceptable.
- Do NOT write characterization tests for generated files (`*.g.dart`, `*.freezed.dart`) — they are regenerated, not refactored.

### Pattern 3: Severity-Ordered Phase Separation with Hard Gate Between CRITICAL and HIGH

**What:** CRITICAL findings get their own isolated phase (Phase A) with a mandatory quality gate before Phase B begins. HIGH through LOW can share a phase boundary if resourcing is tight, but CRITICAL is always alone.

**When to use:** Any refactor initiative where layer-integrity violations exist alongside lower-severity issues. Doing MEDIUM-severity cleanup on top of unresolved CRITICAL architectural violations wastes effort — the CRITICAL fix will restructure the files the MEDIUM fix just touched.

**Phase boundaries for this project (30k-line Flutter/Dart app, fine granularity):**

```
Phase 1: Audit + Catalogue  (prerequisite — must complete before any fix phase)
Phase 2: Coverage Baseline  (must complete before any fix phase)
Phase 3A: CRITICAL fixes    (hard gate: zero analyzer issues before proceeding)
Phase 3B: HIGH fixes        (hard gate: zero analyzer issues + ≥80% coverage touched files)
Phase 3C: MEDIUM fixes      (hard gate: same)
Phase 3D: LOW fixes         (hard gate: same)
Phase 4: Doc Sweep          (after all fix phases, before re-audit)
Phase 5: Re-Audit           (final exit criterion: zero violations)
```

Six fix-bearing phases is appropriate for this granularity. Combining CRITICAL+HIGH into one phase risks HIGH fixes landing on unstable foundations; separating MEDIUM+LOW from HIGH avoids premature polish.

**Trade-offs:**
- More phases = more gate ceremonies. For a solo or two-person team, the gates are `flutter analyze`, `flutter test`, `lcov` check — all scriptable and run in seconds, so overhead is negligible.
- The audit and coverage-baseline phases have no code changes; they are information-gathering only.

### Pattern 4: Shell Script + Dart Script Hybrid Task Runner (no Melos)

**What:** Use shell scripts in `scripts/` for the audit pipeline and a `Makefile` (or equivalent) as the top-level task runner. Do NOT introduce Melos — it is a monorepo tool; this is a single package. Do NOT introduce a new build system (just/taskfile) unless the team already uses one.

**When to use:** Single-package Flutter projects without an existing task runner. The existing `scripts/arb_to_csv.dart` establishes precedent for Dart scripts in this repo.

**Concrete command surface:**

```bash
# Phase 1: Audit
dart scripts/audit_layer.sh       # import-graph layer violations
flutter pub run custom_lint       # Riverpod provider hygiene
dart analyze --format=machine     # mechanical lint issues
# (agent scan: run separately, output appended to ISSUES.md)

# Coverage baseline (Phase 2)
flutter test --coverage
lcov --remove coverage/lcov.info '*.g.dart' '*.freezed.dart' -o coverage/lcov_clean.info
dart scripts/coverage_baseline.dart   # snapshot per-file percentages → coverage-baseline.txt

# Coverage gate (each fix phase)
dart scripts/coverage_gate.dart --min 80 --changed-files $(git diff --name-only HEAD~1)

# Quality gate (each fix phase)
flutter analyze   # must exit 0
dart format --set-exit-if-changed .

# Re-audit diff (Phase 5)
dart scripts/reaudit_diff.dart --baseline .planning/issues.json --current .planning/re-audit/ISSUES-REAUDIT.json
```

**Trade-offs:**
- Shell + Dart scripts are immediately understandable by any Flutter developer without additional tooling knowledge.
- `Makefile` adds an optional convenience layer but is not required if the team prefers running scripts directly.
- `dart analyze --format=machine` does not produce clean JSON natively (an open dart-lang/sdk issue #54877 as of 2025); pipe-delimited output is parsed by the normalization script. DCM is an alternative that does produce JSON but requires a commercial license for full features — do not add it as a dependency; the built-in tools are sufficient.

---

## Data Flow

### Audit → Catalogue → Fix → Re-Audit Flow

```
[dart analyze --format=machine]        ──┐
[flutter pub run custom_lint]          ──┤
[flutter pub run riverpod_lint]        ──┤→ normalize.dart → .planning/ISSUES.md
[AI-Agent semantic scan]               ──┤                 → .planning/issues.json
[grep/import-graph scripts]            ──┘                 → coverage-baseline.txt

                    ↓ (Phase A read)
[ISSUES.md filtered by severity=CRITICAL]
→ fix_phase_A: characterization tests → refactor → coverage gate → analyze gate

                    ↓ (Phase B read, same ISSUES.md)
[ISSUES.md filtered by severity=HIGH]
→ fix_phase_B: characterization tests → refactor → coverage gate → analyze gate

                    ↓ (Phase C, D same pattern)

                    ↓ (Phase 4 doc sweep)
[doc/arch/ ARCH/MOD/ADR updated once]

                    ↓ (Phase 5)
[Re-run audit pipeline]
→ .planning/re-audit/ISSUES-REAUDIT.json
→ reaudit_diff.dart: diff vs .planning/issues.json
→ Exit criterion: zero open findings
```

### Coverage Enforcement Data Flow

```
[flutter test --coverage]
→ coverage/lcov.info
→ lcov --remove (strip *.g.dart, *.freezed.dart, lib/generated/*)
→ coverage/lcov_clean.info

[git diff --name-only HEAD~1]  (files touched by current phase)
→ filter lcov_clean.info to touched files only
→ assert each file line coverage ≥ 80%
→ fail phase gate if any file below threshold
```

### Key Data Flows

1. **Audit → Catalogue:** Raw multi-format tool output merged with agent-produced Markdown findings, normalized into `issues.json` with stable IDs so re-audit can diff by ID rather than by text match.
2. **Catalogue → Fix Phases:** Each fix phase reads a filtered view of `issues.json` (by `severity` and `phase_assigned`). Resolved entries are marked `"status": "resolved"` in-place — the file is the source of truth for progress tracking.
3. **Fix Phase → Coverage Gate:** Per-file coverage extracted from `lcov_clean.info` for the set of files touched in the phase; enforced before the phase is declared complete.
4. **Phase A → Phase B dependency:** Phase B cannot start while any entry in `issues.json` with `severity=CRITICAL` has `status=open`. This is enforced manually (checked in gate script); no automated tooling locks it.
5. **All Fix Phases → Doc Sweep:** Doc sweep is intentionally decoupled from individual phases to avoid documentation churn during refactoring. It reads the final state of the codebase, not intermediate states.
6. **Doc Sweep → Re-Audit:** Re-audit happens after the doc sweep so the final state includes documentation alignment.

---

## Scaling Considerations

This pipeline is for a ~30k-line single-package Flutter app. The architecture is calibrated for that size.

| Scale | Architecture Adjustment |
|-------|--------------------------|
| Current (~30k lines, ~268 source files, ~183 test files) | Shell + Dart scripts, single ISSUES.md, per-phase manual gates — optimal |
| 2x–3x growth (60k–90k lines, still single package) | Same structure; audit scripts may need `--exclude` flags for generated files to keep runtime under 5 minutes |
| Monorepo (multiple packages) | Introduce Melos; one ISSUES.md per package; aggregate at a root level; coverage gate per package |

### Scaling Priorities

1. **First bottleneck:** `AI-agent semantic scan` runtime grows linearly with file count. At 500+ files, batch the agent across feature directories rather than the whole codebase in a single prompt.
2. **Second bottleneck:** `flutter test --coverage` runtime. Use `--name` filters to run only tests for touched files during intermediate gates, reserving full-suite coverage for phase completion gates.

---

## Anti-Patterns

### Anti-Pattern 1: Refactor Before Baseline Coverage

**What people do:** Jump straight into CRITICAL fixes without establishing what the test coverage baseline is or writing characterization tests first.

**Why it's wrong:** With the project currently at ~68% naive coverage ratio and known gaps in sync engine, crypto negative paths, and high-traffic screens, refactoring without a safety net produces silent behavior regressions. The ≥80% gate becomes meaningless if you cannot tell whether you raised or lowered coverage on the specific file you touched.

**Do this instead:** Run `flutter test --coverage` and capture `coverage-baseline.txt` as Phase 2, before any code changes. Write characterization tests for any file below 80% before that file's refactor begins.

### Anti-Pattern 2: Merging CRITICAL and HIGH Into One Phase

**What people do:** Combine the two most severe categories to "save time" on phase setup.

**Why it's wrong:** CRITICAL violations in this codebase include layer violations where `features/` hold `application/` code and `domain` imports `data`. Fixing these restructures files. If HIGH-severity provider hygiene fixes are applied to the same files simultaneously, the changes conflict, history becomes tangled, and rollback is harder. More importantly, HIGH fixes (deprecated service wiring, provider misplacement) often depend on the CRITICAL layer fixes to know where the correct home for code is.

**Do this instead:** Complete Phase A (CRITICAL) and run `flutter analyze` to zero before touching any HIGH finding. The hard gate enforces sequencing.

### Anti-Pattern 3: Per-Phase Documentation Updates

**What people do:** Update `doc/arch/` ARCH/MOD/ADR docs after each fix phase to "keep docs in sync."

**Why it's wrong:** Mid-refactor, the codebase is in a transitional state. Documenting transitional states produces docs that are wrong by the time the next phase completes. The PROJECT.md explicitly calls this out as out of scope during the initiative.

**Do this instead:** Defer all doc/arch updates to the single Doc Sweep phase (Phase 4), after all fix phases are complete and the codebase is in its final stable state.

### Anti-Pattern 4: Treating `dart analyze` Output as the Complete Issue List

**What people do:** Run `dart analyze`, take its output as the full audit, and skip the AI-agent semantic scan.

**Why it's wrong:** `dart analyze` catches mechanical lint violations but cannot detect: (a) semantic layer violations where the import is syntactically valid but crosses a boundary (e.g., a domain model importing a Data type via an alias), (b) redundant parallel implementations that are structurally correct but functionally duplicate, (c) provider definitions that are duplicated across features but each definition is individually correct, (d) dead code in branches that are reachable but never exercised by real usage patterns.

**Do this instead:** Use `dart analyze` + `custom_lint`/`riverpod_lint` as the mechanical stream and AI-agent review as the semantic stream. Both streams are required; neither is sufficient alone.

### Anti-Pattern 5: Re-Audit Without Stable Issue IDs

**What people do:** Run the full audit again at the end and compare the human-readable output by eye, or by line-diff of the Markdown.

**Why it's wrong:** The exit criterion is "zero violations across all four categories." If the initial catalogue and the re-audit output use different formats, comparing them by eye creates ambiguity ("is this the same issue or a new one?"). Line numbers shift as files are modified.

**Do this instead:** Assign stable IDs to each finding in `issues.json` at catalogue time (e.g., `LV-001`, `PH-012`). The re-audit script resolves findings by ID and reports: resolved (was open, now absent), regression (was absent, now present), new (not in original catalogue). The exit criterion becomes programmatically checkable.

---

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Audit Engine → Catalogue | File write (`issues.json`, `ISSUES.md`) | Normalization script reads all tool outputs and agent findings; writes once |
| Catalogue → Fix Phases | File read (filtered `issues.json` by severity) | Each phase reads the same file; marks entries resolved in-place |
| Fix Phases → Coverage Gate | `lcov_clean.info` + `git diff --name-only` | Gate script is stateless; called at end of each phase |
| Fix Phases → Quality Gate | Exit code of `flutter analyze` | Must be 0; non-zero blocks phase completion |
| All Phases → Doc Sweep | Code state on disk | Doc sweep reads final code; no programmatic handoff |
| Doc Sweep → Re-Audit | Nothing (re-audit triggers on completion) | Re-audit is triggered manually after doc sweep confirms completion |
| Re-Audit → Exit | Diff of `issues.json` vs `ISSUES-REAUDIT.json` | Script exits 0 if zero open findings; exits non-zero otherwise |

### Existing Tooling Already in Project

| Tool | Role in Pipeline | Already in `pubspec.yaml` |
|------|-----------------|--------------------------|
| `dart analyze` | Mechanical lint, import violations | Yes (dart SDK) |
| `custom_lint` | Plugin host for riverpod_lint | Yes (dev_dep) |
| `riverpod_lint` | Riverpod-specific provider hygiene | Yes (dev_dep) |
| `flutter test --coverage` | Coverage generation | Yes (flutter_test dev_dep) |
| `lcov` | Coverage filtering + per-file extraction | System tool (not pub dep) |
| `mockito`, `mocktail` | Test mocking in characterization tests | Yes (dev_dep) |
| `build_runner` | Code regeneration after refactor | Yes (dev_dep) |

No new `pubspec.yaml` dependencies are required for the cleanup pipeline itself.

---

## Build Order Dependencies (Mandatory Sequencing)

```
Phase 1 (Audit + Catalogue) MUST complete before any fix phase.
  ↓ produces: .planning/ISSUES.md, .planning/issues.json

Phase 2 (Coverage Baseline) MUST complete before any fix phase.
  ↓ produces: coverage-baseline.txt, coverage/lcov_clean.info

Phase 3A (CRITICAL fixes) MUST complete + gate BEFORE Phase 3B.
  ↓ gate: flutter analyze = 0 issues, all tests GREEN

Phase 3B (HIGH fixes) MUST complete + gate BEFORE Phase 3C.
  ↓ gate: flutter analyze = 0, all tests GREEN, ≥80% on touched files

Phase 3C (MEDIUM fixes) MUST complete + gate BEFORE Phase 3D.
  ↓ gate: same

Phase 3D (LOW fixes) MUST complete + gate BEFORE Phase 4.
  ↓ gate: same

Phase 4 (Doc Sweep) MUST complete BEFORE Phase 5 (Re-Audit).
  ↓ (no programmatic gate; human confirmation that sweep is done)

Phase 5 (Re-Audit) is the terminal phase.
  ↓ exit criterion: reaudit_diff.dart reports zero open findings
```

**The single hardest dependency:** Phase 1 must produce `issues.json` before anything else begins. Without the catalogue, phases have no definition of "done." The coverage baseline (Phase 2) is independent of Phase 1 logically but must happen before code changes, so it runs in parallel with or immediately after Phase 1.

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Audit tooling choices (`dart analyze`, `custom_lint`, `riverpod_lint`) | HIGH | All confirmed present in `pubspec.yaml`; official Dart/Flutter tooling |
| `--format=machine` pipe-delimited output | HIGH | dart-lang/sdk documentation + community examples |
| AI-agent semantic scan necessity | HIGH | Codebase map (CONCERNS.md) shows violations grep cannot detect |
| Characterization-test-first pattern | HIGH | Feathers (2004) — industry canonical; community consensus on legacy refactor |
| `lcov` per-file coverage filtering | HIGH | Flutter community standard; multiple published examples |
| Phase count recommendation (6 phases) | MEDIUM | Calibrated to project size and fine granularity config; no authoritative source for this exact figure |
| `issues.json` stable-ID diffing approach | MEDIUM | Derived from AI audit tooling patterns; not a published Flutter-specific standard |
| No Melos / no new task runner | HIGH | Single-package project; Melos is explicitly a monorepo tool; existing `scripts/` directory establishes precedent |

---

## Sources

- [dart analyze documentation](https://dart.dev/tools/dart-analyze) — `--format=machine` output format
- [dart-lang/sdk #54877](https://github.com/dart-lang/sdk/issues/54877) — JSON output format gaps in `dart analyze`
- [flutter/flutter #95090](https://github.com/flutter/flutter/issues/95090) — `--format=machine` for `flutter analyze`
- [custom_lint pub.dev](https://pub.dev/packages/custom_lint) — custom lint rule authoring
- [riverpod_lint pub.dev](https://pub.dev/packages/riverpod_lint) — Riverpod provider hygiene rules
- [DCM Analyze docs](https://dcm.dev/docs/cli/analyze/) — JSON output format reference (not adopted as dependency)
- [flutter test coverage with lcov](https://www.etiennetheodore.com/test-coverage-explain-with-lcov-on-dart/) — lcov filtering pattern
- [Working Effectively with Legacy Code — key points](https://understandlegacycode.com/blog/key-points-of-working-effectively-with-legacy-code/) — characterization test pattern
- [Golden Master Testing](https://www.sitepoint.com/golden-master-testing-refactor-complicated-views/) — snapshot/golden test approach for legacy refactor
- [DCM MCP + AI quality loop](https://dcm.dev/blog/2025/08/25/agentic-code-quality-dcm-mcp/) — AI-agent + tooling cooperation pattern
- [flutter_ci_guard](https://pub.dev/packages/flutter_ci_guard) — alternative coverage gate enforcer (noted; not adopted)

---
*Architecture research for: audit-driven Flutter/Dart codebase cleanup pipeline*
*Researched: 2026-04-25*
