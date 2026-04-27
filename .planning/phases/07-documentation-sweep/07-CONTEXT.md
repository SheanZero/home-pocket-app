# Phase 7: Documentation Sweep — Context

**Gathered:** 2026-04-27
**Status:** Ready for planning
**Source:** Inline decisions captured during /gsd-plan-phase 7 (research-first flow; no /gsd-discuss-phase run)

<domain>
## Phase Boundary

Phase 7 brings architectural documentation back in line with the post-cleanup `lib/` tree after Phases 3–6. Pure-Markdown sweep — no code changes, no migrations, no schema changes. Out: `lib/`, `test/`, `pubspec.*`, `.github/workflows/audit.yml` (referenced for verification only, never modified).

**Files in scope:**
- `docs/arch/01-core-architecture/ARCH-*.md`
- `docs/arch/02-module-specs/MOD-*.md`
- `docs/arch/03-adr/ADR-*.md`
- `docs/arch/04-basic/BASIC-*.md` (read-only — referenced by other docs)
- `docs/arch/05-UI/UI-*.md`
- `docs/arch/README.md`
- `CLAUDE.md` (Common Pitfalls + Key References sections)
- `.claude/rules/arch.md` (path-spelling fix only)

**Files explicitly out of scope:** `docs/worklog/`, `.planning/`, root-level `AGENTS.md` / `README.md`, `feasibility_report.md`, anything historical.
</domain>

<decisions>
## Implementation Decisions

### D-01 — Phantom MOD-014 references — replace with BASIC-003 (LOCKED)
All references to `MOD-014_i18n.md`, `MOD-014`, or "MOD-014 i18n" in `docs/arch/` and `CLAUDE.md` must be replaced with the canonical post-merge target `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md` (or `BASIC-003` shortname in ASCII diagrams).

**Why:** MOD-014 was never created on disk — its content was merged into BASIC-003 per `BASIC-003_I18N_Infrastructure.md:21` ("MOD-014 を廃止"). Keeping the phantom name confuses every contributor following the link.

**How to apply:** Plan 07-01 / 07-03 must include a grep-verified sweep:
- `grep -rn "MOD-014_i18n\.md\|MOD-014 i18n\|MOD-014" docs/arch/ CLAUDE.md` returns 0 hits after the sweep.
- ASCII diagrams in `ARCH-007_Architecture_Diagram_I18N.md` and `ARCH-008_Layer_Clarification.md` use the label `BASIC-003` instead of `MOD-014`.

### D-02 — Module-numbering drift (D3) — defer to FUTURE-DOC backlog (LOCKED)
The pre-existing mismatch between MOD filename numbers and internal heading numbers (e.g., `MOD-001_BasicAccounting.md` heading says "MOD-001/002") is **NOT** in Phase 7 scope.

**Why:** Drift predates Phases 3–6. DOCS-01 wording is "post-refactor file paths and class names" — not pre-existing numbering inconsistency. Renaming MOD files would break every external bookmark/cross-reference.

**How to apply:**
- Plan 07-05 (ADR-011) must list MOD numbering drift as a known doc-debt item under `## Out of Scope / Deferred`.
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md:2078` cross-ref content bug (`MOD-009: 趣味功能` → should reflect actual MOD-009 = voice input) IS in scope and lives in Plan 07-01.
- Do NOT rename any `MOD-*.md` file in this phase.

### D-03 — `.claude/rules/arch.md` path drift — include in Plan 07-03 (LOCKED)
The 10 `doc/arch/` (singular, broken) references in `.claude/rules/arch.md` get fixed in Plan 07-03 alongside CLAUDE.md path drift.

**Why:** `CLAUDE.md` directs contributors to `.claude/rules/arch.md` for the full doc workflow; both must agree. Cost is ~10 sed-style replacements; deferral cost is broken contributor onboarding.

**How to apply:**
- Plan 07-03 `files_modified` includes `.claude/rules/arch.md`.
- Acceptance: `grep -nE 'doc/arch[^/]' .claude/rules/arch.md` returns 0 hits.

### D-04 — MOD-000_INDEX.md — stub-with-pointer (LOCKED)
Create `docs/arch/02-module-specs/MOD-000_INDEX.md` as a 10-line stub that delegates to `ARCH-000_INDEX.md` (the existing master index for ARCH + MOD + BASIC + ADR).

**Why:** DOCS-03 literal text says "ARCH-000, ADR-000, MOD-000" — strict reading requires the file to exist. Full duplication of ARCH-000 content creates two-source-of-truth drift. Stub satisfies the requirement at minimal cost.

**How to apply:**
- Plan 07-04 creates `docs/arch/02-module-specs/MOD-000_INDEX.md` with content:
  ```markdown
  # MOD Index

  This directory's master index lives in [ARCH-000_INDEX.md](../01-core-architecture/ARCH-000_INDEX.md) — see the "功能模块技术文档" section.
  ```
- Acceptance: `test -f docs/arch/02-module-specs/MOD-000_INDEX.md` succeeds.

### D-05 — ADR-011 title — `Codebase_Cleanup_Initiative_Outcome` (LOCKED)
The new ADR (DOCS-04) is filed as `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md`.

**Why:** Per `.claude/rules/arch.md` PascalCase_Title naming. Title captures all three required subsections (cleanup outcome, *.mocks.dart strategy, ongoing CI enforcement) without leading with one over the others.

**How to apply:**
- Plan 07-05 creates this exact file.
- Required subsections per `.claude/rules/arch.md` ADR template: 标题/编号、状态、背景、考虑的方案、决策、决策理由、后果、实施计划.
- Required content sections (DOCS-04 acceptance):
  1. **Cleanup Outcome** — link to issues.json delta, summary of Phases 3–6 changes
  2. **`*.mocks.dart` Strategy** — mocktail big-bang decision (Phase 4-04), why mocktail over mockito
  3. **Ongoing CI Enforcement** — list 8 CI gates with line citations into `.github/workflows/audit.yml`
  4. **Out of Scope / Deferred** — MOD numbering drift (D-02), ADR-008/009/010 implementation status
- ADR-011 must be added to `docs/arch/03-adr/ADR-000_INDEX.md` as part of the same plan.

### D-06 — ADR Append-Don't-Mutate Pattern (LOCKED)
For ADR-002, ADR-008, ADR-010 that reference now-deprecated tooling (`sqlite3_flutter_libs`) or obsolete file paths (`lib/features/accounting/data/repositories/...`), do **NOT** rewrite the original decision body. Add a `## Update {YYYY-MM-DD}: Cleanup Initiative Outcome` section at the bottom that points to ADR-011.

**Why:** ADRs are historical records; the original decision context must be preserved. Per `.claude/rules/arch.md:171-173` ("文档废弃: 不删除文件，在文档头部添加 [已废弃] 标记").

**How to apply:**
- Plan 07-02's Wave 1 commits append-only diffs to ADR-002, ADR-008, ADR-010.
- Acceptance grep: `grep -B1 "## Update.*Cleanup" docs/arch/03-adr/ADR-002_Database_Solution.md` returns the appended section.
- Direct line edits to ADR decision bodies are forbidden — verified via per-commit `git diff` review.

### D-07 — Wave 0 verification script is mandatory (LOCKED)
Plan 07-01 begins with creating `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` and confirming it currently FAILS (because drift still exists). Subsequent plans make it pass.

**Why:** Doc sweeps without mechanical gates regress silently. Per Pitfall 7-D in 07-RESEARCH.md.

**How to apply:**
- First commit in Plan 07-01 = Wave 0 task: create the script + a smoke run that confirms current `main` produces ≥1 failure (failures expected).
- Acceptance: script exists, is executable (`chmod +x`), and includes the 6 grep gates documented in 07-RESEARCH.md `## Code Examples`.
- Phase 7 close criterion: same script exits 0.

### D-08 — Plan boundary: lib/-clean commits (LOCKED)
Every Phase 7 commit MUST be `lib/`-clean — no file under `lib/`, `test/`, `pubspec.*`, `.github/`, or `analysis_options.yaml` may change.

**Why:** REPO-LOCK-POLICY.md line 33 says Phase 7 "Operates under normal merge rules" — this means doc commits don't trip the coverage gate, NOT that code edits are allowed. Mixing code with docs would re-open the coverage-gate fight that Phase 6 closed.

**How to apply:**
- Each plan's `files_modified` frontmatter must list ONLY paths under `docs/`, `CLAUDE.md`, `.claude/rules/`, or `.planning/phases/07-documentation-sweep/`.
- Per-plan acceptance includes `git diff --name-only HEAD~ HEAD | grep -E '^(lib/|test/|pubspec|\.github/|analysis_options)' | wc -l` returns 0.

### Claude's Discretion
- Exact section ordering inside ADR-011 (decisions 标题/编号/状态/背景/考虑/决策/理由/后果/实施 already locked by `.claude/rules/arch.md`).
- Specific replacement wording for individual drift sites (planner picks idiomatic Markdown; gates verify the result via grep).
- Whether to use `sed` vs editor multi-cursor vs hand-edit per drift site (executor's choice).
- Whether `BASIC-003` is referenced as `[BASIC-003](../04-basic/BASIC-003_I18N_Infrastructure.md)` link or plain shortname `BASIC-003` (planner picks per file context).
- Per-plan wave numbering within the locked Wave A / Wave B grouping (planner can assign 0/1/2 inside a plan; cross-plan dependency only at Wave A → Wave B boundary).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 7 Inputs
- `.planning/phases/07-documentation-sweep/07-RESEARCH.md` — drift inventory (≈40 sites), pitfall classification, INDEX health audit, ADR-011 scope
- `.planning/REQUIREMENTS.md` — DOCS-01..04 acceptance text
- `.planning/ROADMAP.md` — Phase 7 success criteria (4 items)

### Documentation Workflow Rules
- `.claude/rules/arch.md` — naming rules (ARCH-NNN / MOD-NNN / ADR-NNN), INDEX.md update workflow, file numbering protocol, ADR template structure
- `CLAUDE.md` — top-level project instructions; Common Pitfalls list (DOCS-02 target); Key References (D-01 / D-04 target)

### INDEX Files (DOCS-03)
- `docs/arch/01-core-architecture/ARCH-000_INDEX.md` — master index for ARCH + MOD + BASIC + ADR (canonical)
- `docs/arch/03-adr/ADR-000_INDEX.md` — ADR-only index (must add ADR-011 entry in Plan 07-05)
- (To be created) `docs/arch/02-module-specs/MOD-000_INDEX.md` — stub-with-pointer per D-04

### CI Enforcement Truth Source (DOCS-02 + ADR-011)
- `.github/workflows/audit.yml` — 8 CI gates with line numbers; cite verbatim in ADR-011 §"Ongoing CI Enforcement"
- `analysis_options.yaml` — `flutter analyze` + plugin registration
- `lib/import_guard.yaml` and per-layer `*/import_guard.yaml` — layer-violation rules
- `pubspec.yaml` — `intl: 0.20.2` exact pin (Pitfall #5), `mocktail` (DOCS-04), `riverpod_lint` + `import_guard_custom_lint` plugins (Pitfalls #2/#10)
- `test/architecture/domain_import_rules_test.dart` — Pitfall #2 enforcement
- `test/architecture/provider_graph_hygiene_test.dart` — Pitfalls #10 + #12 enforcement

### Drift-Source Truth (DOCS-01)
- `lib/application/` — post-centralization use case home (replaces `lib/features/{f}/use_cases/`)
- `lib/data/repositories/` — post-centralization repository impl home (replaces `lib/features/{f}/data/repositories/`)
- `lib/infrastructure/category/category_locale_service.dart` — Phase 5 rename (replaces `category_service.dart`)
- `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md` — replaces phantom `MOD-014_i18n.md` per D-01

### Project History
- `.planning/STATE.md` — project decisions ledger; Phase 3–6 outcomes
- `.planning/audit/REPO-LOCK-POLICY.md:33` — Phase 7 merge rules (lib/-clean commits per D-08)
- `.planning/audit/issues.json` — pre/post-cleanup finding catalogue (cite delta in ADR-011 §"Cleanup Outcome")
</canonical_refs>

<specifics>
## Specific Ideas

### Plan structure (suggested by research, locked by user via decisions above)

```
.planning/phases/07-documentation-sweep/
├── 07-01-arch-mod-drift-PLAN.md          # Wave A — DOCS-01 part 1; ARCH/MOD edits + Wave 0 verify-doc-sweep.sh
├── 07-02-adr-drift-PLAN.md               # Wave A — DOCS-01 part 2; ADR append-only updates
├── 07-03-claude-md-pitfall-annotation-PLAN.md  # Wave A — DOCS-02; CLAUDE.md + .claude/rules/arch.md path fix
├── 07-04-index-health-PLAN.md            # Wave B — DOCS-03; INDEX.md health + MOD-000 stub + README.md fix
└── 07-05-cleanup-outcome-adr-PLAN.md     # Wave B — DOCS-04; ADR-011 + ADR-000 INDEX update + final phase gate
```

### Wave dependency (locked)

- **Wave A** (parallelizable): 07-01, 07-02, 07-03 edit disjoint files; can run concurrently.
- **Wave B**: 07-04 depends on 07-01..03 (INDEX checks must run after files are stable). 07-05 depends on 07-04 (ADR-011 references the post-cleanup INDEX state).

### Verification gates (locked, per RESEARCH §"Validation Architecture")

`.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` runs 6 grep gates:
1. Layer-centralization drift (`features/.*/use_cases`, `features/.*/data/repositories`)
2. mockito drift (`package:mockito`, `@GenerateMocks`, `*.mocks.dart`)
3. `sqlite3_flutter_libs` in non-historical contexts
4. `doc/arch/` (singular) path drift in CLAUDE.md and `.claude/rules/arch.md`
5. Phantom MOD-014 references
6. ADR-011 file presence + INDEX entry

Plus an INDEX-health shell loop (`scripts/verify_index_health.sh`) that confirms every link in INDEX files points to a real file and every file in the directory is mentioned in INDEX.

### CLAUDE.md annotation format (locked, per RESEARCH §"CLAUDE.md Pitfall Classification")

```markdown
1. Don't modify generated files (`.g.dart`, `.freezed.dart`)
   *[Partially enforced — AUDIT-10 CI catches stale committed files; hand-edits matching generator output go undetected]*
```

Annotation tag must be one of three exact strings:
- `*[Structurally enforced — {mechanism}]*`
- `*[Partially enforced — {mechanism}]*`
- `*[Manually-checked only — {reason}]*`

(Italics on indented follow-up line so the original numbered list reads cleanly.)

### Pitfall enforcement classification (locked, per RESEARCH)

| Pitfall | Status | Mechanism |
|---------|--------|-----------|
| 1 (`.g.dart`/`.freezed.dart`) | Partially enforced | AUDIT-10 + analyzer excludes |
| 2 (Domain import rules) | Structurally enforced | `import_guard` + `domain_import_rules_test.dart` |
| 3 (Skip codegen) | Structurally enforced | AUDIT-10 (`audit.yml:81-89`) |
| 4 (Mutation) | Manually-checked only | freezed only on `@freezed` |
| 5 (`intl` pin) | Structurally enforced | `pubspec.yaml:18` exact pin |
| 6 (`sqlite3_flutter_libs`) | Structurally enforced | `import_guard.yaml:5` + AUDIT-09 |
| 7 (Podfile EXCLUDED_ARCHS) | Manually-checked only | No Podfile lint |
| 8 (Analyzer warnings) | Structurally enforced | `flutter analyze` CI step (`audit.yml:34`) |
| 9 (Widget hardcoded defaults) | Manually-checked only | No lint |
| 10 (Duplicate repository providers) | Structurally enforced | `provider_graph_hygiene_test.dart` + `riverpod_lint` |
| 11 (Drift index syntax) | Manually-checked only | Drift compiler permissive |
| 12 (Skip AppInitializer) | Partially enforced | `provider_graph_hygiene_test.dart` catches UnimplementedError |
| 13 (Forget regen after merge) | Structurally enforced | AUDIT-10 (same as #3) |

### Drift coverage (locked, per RESEARCH §"Drift Inventory")

≈40 confirmed drift sites across 6 categories:
- D1: 14 sites (layer centralization)
- D2: 10 sites (mockito + sqlite3_flutter_libs)
- D3: pre-existing — defer per D-02
- D4: 6 sites in CLAUDE.md + 10 in `.claude/rules/arch.md` (per D-03)
- D5: 5 sites (phantom MOD-014, per D-01)
- D6: 3 sites in `docs/arch/README.md`

Plan 07-01 covers D1 + portions of D5 (ARCH/MOD/UI files).
Plan 07-02 covers D1's ADR sites + D2 (ADR append-only updates).
Plan 07-03 covers D4 (CLAUDE.md + `.claude/rules/arch.md`) + D2 in CLAUDE.md if any.
Plan 07-04 covers D6 (README.md) + INDEX health + MOD-000 stub.
Plan 07-05 creates ADR-011 + adds it to ADR-000 INDEX.

</specifics>

<deferred>
## Deferred Ideas

- **Module numbering drift D3** (5 MOD files + ARCH-001:2078) — pre-existing, not Phase 3-6 outcome. Tracked in ADR-011 §"Out of Scope / Deferred"; will be lifted to FUTURE-DOC backlog.
- **markdown-link-check CI gate** — research notes this would catch broken cross-references in CI. Defer to Phase 8 (re-audit) or FUTURE-TOOL backlog. Phase 7 acceptance uses one-shot shell loops.
- **ADR-008/009/010 implementation status** — these are "已接受 / 实施完成后 review"; the cleanup did not implement them. ADR-011 will note this in §"Out of Scope" so future contributors don't assume cleanup implemented them.
- **README.md root file** (project root, not `docs/arch/README.md`) — out of scope. Only the `docs/arch/README.md` is touched (per D6).
</deferred>

---

*Phase: 07-documentation-sweep*
*Context gathered: 2026-04-27 via /gsd-plan-phase 7 inline decisions (research-first flow)*
