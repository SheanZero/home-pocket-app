# Phase 7: Documentation Sweep — Research

**Researched:** 2026-04-27
**Domain:** Documentation drift remediation (Markdown-only, no code changes)
**Confidence:** HIGH (every drift item below verified by direct grep on the post-Phase-6 codebase)

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | Update ARCH/MOD/ADR files for relocated files / renamed classes / deleted modules | "Drift Inventory" section + per-file grep verification commands |
| DOCS-02 | Annotate CLAUDE.md "Common Pitfalls" with structural-enforcement status | "CLAUDE.md Pitfall Classification" section maps each of 13 items to lint/CI mechanism |
| DOCS-03 | Verify doc/arch INDEX files reference only existing files | "INDEX.md Health Audit" section per index file |
| DOCS-04 | File a new ADR documenting cleanup outcome + *.mocks.dart strategy + CI enforcement | "New ADR (DOCS-04) Scope" section with ADR-011 number, sections, cross-refs |
</phase_requirements>

## Summary

Phase 7 is a **pure-Markdown sweep** that brings architectural documentation back in line with the post-cleanup `lib/` tree. After 6 fix phases, four kinds of drift exist in `docs/arch/*.md` and `CLAUDE.md`:

1. **File-path drift** — code references such as `lib/features/{f}/use_cases/`, `lib/features/{f}/data/repositories/`, `lib/features/{f}/application/use_cases/` that no longer exist (centralization moved them to `lib/application/{domain}/` and `lib/data/repositories/`).
2. **Tooling drift** — references to `mockito` / `@GenerateMocks` / `*.mocks.dart` (replaced by mocktail in Phase 4-04) and to `sqlite3_flutter_libs` (now actively rejected by CI).
3. **Module-numbering drift** — every module file in `02-module-specs/` has a filename number that does NOT match its internal heading (MOD-001 file → "MOD-001/002" heading, MOD-002 file → "MOD-003" heading, MOD-006 file → "MOD-007" heading, MOD-008 file → "MOD-013" heading, etc.). Plus references to a non-existent `MOD-014_i18n.md` that was never created (the content lives in `BASIC-003_I18N_Infrastructure.md`).
4. **Path-spelling drift** — CLAUDE.md and `.claude/rules/arch.md` say `doc/arch/` (singular) but the actual directory is `docs/arch/` (plural). Every "Key References" link in CLAUDE.md is a broken link as written.

In addition: there is **no** `MOD-000_INDEX.md` file (only ARCH-000 and ADR-000). The ARCH-000 INDEX doubles as the master index for both ARCH and MOD entries — the planner should confirm with the user whether to (a) create a real MOD-000_INDEX.md or (b) treat ARCH-000 as the canonical MOD index.

**Primary recommendation:** Execute the sweep in **5 plans** running in two waves — Wave A (parallelizable: ARCH/MOD edits, ADR edits, CLAUDE.md annotation) and Wave B (sequential: INDEX cleanup → new ADR-011 → mechanical verification grep gates). All edits are byte-additions or text replacements; no code, no migrations, no schema changes. The phase completes when (a) every drift grep listed in this document returns zero results in `docs/arch/` and `CLAUDE.md`, (b) `INDEX.md` files reference only existing files, and (c) `docs/arch/03-adr/ADR-011_*.md` exists and is linked from `ADR-000_INDEX.md`.

## Architectural Responsibility Map

This phase is documentation-only — there is no production tier ownership to map. The "tier" axis here is *which file* owns each kind of fact:

| Capability | Primary Owner | Secondary Owner | Rationale |
|------------|---------------|------------------|-----------|
| Module file-path facts | `02-module-specs/MOD-*.md` | `01-core-architecture/ARCH-001_Complete_Guide.md` | MOD docs describe per-module layout; ARCH-001 has the global tree. Both must agree. |
| Cross-cutting file paths (i18n, crypto) | `01-core-architecture/ARCH-007_Architecture_Diagram_I18N.md`, `04-basic/BASIC-001_Crypto_Infrastructure.md`, `04-basic/BASIC-003_I18N_Infrastructure.md` | `01-core-architecture/ARCH-008_Layer_Clarification.md` | BASIC docs are the implementation reference per BASIC-003 line 21 ("MOD-014 を廃止"). |
| Tooling decisions (database lib, mock framework) | `03-adr/ADR-002_Database_Solution.md`, `03-adr/ADR-XXX (new)` | `01-core-architecture/ARCH-001_Complete_Guide.md` (Tech Stack §) | ADRs are the canonical decision record; ARCH-001 mirrors them in the tech-stack table. |
| Coding pitfall enforcement | `CLAUDE.md` "Common Pitfalls" + new ADR-011 | `lib/*/import_guard.yaml`, `analysis_options.yaml`, `.github/workflows/audit.yml` | CLAUDE.md is the human-facing summary; the YAML/workflow files are the executable enforcement. |
| Index integrity | `01-core-architecture/ARCH-000_INDEX.md`, `03-adr/ADR-000_INDEX.md` | `docs/arch/README.md` | Both INDEX files are linked from README.md. README has its own staleness (says `arch2/`). |

## Standard Stack

This phase has no third-party dependencies. The "stack" is the existing project toolchain.

### Core (already installed; no version bumps required)
| Tool | Version | Purpose | Why Used Here |
|------|---------|---------|---------------|
| `grep` (BSD or GNU) | system | Drift detection / verification | All "search for stale string" gates are grep-based per acceptance criteria below |
| Markdown editor (VS Code, etc.) | n/a | Hand-edit ARCH/MOD/ADR files | No tooling needs to "compile" markdown — Phase 7 ships text |
| `flutter analyze` | pinned by `pubspec.yaml` (Flutter stable) | Sanity check that doc edits did not accidentally touch any `lib/` file | Already required by every plan via REPO-LOCK-POLICY.md |
| `flutter test` | pinned | Same — confirms no code regression after pure-doc commits | Already required |

### Supporting (zero new deps)
None. **No `npm install`, no `pub add`, no `dart pub global activate`. This is a pure-documentation phase.**

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-edit Markdown | Generate Markdown from Dart source via `dart doc` | `dart doc` writes API reference, not architectural narrative. ARCH/MOD/ADR docs explain *why* and *how*, not *what*; not a fit. |
| One mega-PR | One PR per ARCH/MOD/ADR file | One mega-PR risks reviewer fatigue; per-file PRs explode count. **Recommendation: 5 plans (Wave A: 3, Wave B: 2)** — small enough to review, large enough to be coherent. |

**Installation:** None.

**Version verification:** Not applicable.

## Architecture Patterns

### System Architecture Diagram

```
                                 Phase 7 Documentation Sweep
                                            │
            ┌───────────────────────────────┼─────────────────────────────────┐
            │                               │                                 │
            ▼                               ▼                                 ▼
   Wave A (parallel)              Wave A (parallel)                  Wave A (parallel)
   ┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐
   │ Plan 07-01           │    │ Plan 07-02           │    │ Plan 07-03           │
   │ ARCH/MOD drift fixes │    │ ADR drift fixes      │    │ CLAUDE.md pitfall    │
   │ (DOCS-01 part 1)     │    │ (DOCS-01 part 2)     │    │ annotation (DOCS-02) │
   └──────────┬───────────┘    └──────────┬───────────┘    └──────────┬───────────┘
              │                            │                            │
              └────────────────────────────┼────────────────────────────┘
                                           │
                                           ▼
                                   Wave B (sequential)
                                   ┌──────────────────────┐
                                   │ Plan 07-04           │
                                   │ INDEX.md health      │
                                   │ (DOCS-03)            │
                                   │ + README.md fix      │
                                   └──────────┬───────────┘
                                              │
                                              ▼
                                   ┌──────────────────────┐
                                   │ Plan 07-05           │
                                   │ ADR-011 cleanup      │
                                   │ outcome (DOCS-04)    │
                                   │ + final grep gates   │
                                   └──────────┬───────────┘
                                              │
                                              ▼
                                       Phase 7 close
                                  (zero stale-grep matches
                                   + INDEX entries valid
                                   + ADR-011 published)
```

### Recommended Plan Structure (suggested IDs)

```
.planning/phases/07-documentation-sweep/
├── 07-01-arch-mod-drift-PLAN.md          # Wave A — parallel
├── 07-02-adr-drift-PLAN.md               # Wave A — parallel
├── 07-03-claude-md-pitfall-annotation-PLAN.md  # Wave A — parallel
├── 07-04-index-health-PLAN.md            # Wave B — depends on 07-01..03
└── 07-05-cleanup-outcome-adr-PLAN.md     # Wave B — depends on 07-04
```

### Pattern 1: Find-and-Replace Drift Fixing
**What:** For each known drift (e.g., `lib/features/family_sync/use_cases/` → `lib/application/family_sync/`), grep `docs/arch/`, then use `sed` or editor multi-cursor to replace each occurrence. Each replacement must be reviewed in context — sometimes the doc is describing a *historical* state that should be retained (especially in ADRs that documented decisions made *before* the cleanup).

**When to use:** When the drift is a single-token rename (path or class name).

**Example:**
```bash
# Verify before edit
grep -rn "features/family_sync/use_cases" docs/arch/ CLAUDE.md
# Edit each occurrence
# Verify after edit
grep -rn "features/family_sync/use_cases" docs/arch/ CLAUDE.md  # → 0 matches
```

### Pattern 2: ADR Append-Don't-Mutate
**What:** ADRs are historical records. When a Phase-3..6 decision changes the implementation, **do NOT rewrite the original decision body**. Add a `## Update {YYYY-MM-DD}: Cleanup Initiative Outcome` section at the bottom that points to the new ADR-011.

**When to use:** ADR-002 (still mentions sqlite3_flutter_libs as one of the two database libs), ADR-008 (references `lib/features/accounting/data/`), ADR-010 (same).

**Why:** ADRs document the decision *at the time it was made*. Phase 7 must add new context, not erase history.

### Pattern 3: Index Verification Loop
**What:** For every entry in an INDEX.md file, verify the linked file exists. For every file in the directory, verify it has an INDEX.md entry.

**Example mechanical check:**
```bash
# Every index entry must point to an existing file
for f in $(grep -oE '\(\.\./[^)]+\.md\)' docs/arch/01-core-architecture/ARCH-000_INDEX.md | tr -d '()'); do
  full="docs/arch/01-core-architecture/$f"
  test -f "$full" || echo "BROKEN LINK: $f"
done

# Every file in directory must be in INDEX (excluding INDEX itself)
ls docs/arch/01-core-architecture/*.md | grep -v INDEX | while read f; do
  base=$(basename "$f")
  grep -q "$base" docs/arch/01-core-architecture/ARCH-000_INDEX.md || echo "ORPHAN: $base"
done
```

### Anti-Patterns to Avoid
- **Don't rewrite ADR decision bodies.** Append, don't mutate. ADR history is sacred.
- **Don't delete deprecated entries from indexes** — `.claude/rules/arch.md` line 161 says "废弃文档不删除文件". Mark with `[已废弃]` instead.
- **Don't introduce new file-path facts that aren't grep-verified.** Every path mentioned in updated docs must be a real path on disk on the day of the commit.
- **Don't bundle code edits with the doc sweep.** REPO-LOCK-POLICY.md is still in effect during Phase 7 (see line 33: "Phase 7 (docs sweep) — Operates under normal merge rules; not bound by lock"). This means non-cleanup PRs can land in parallel, so doc commits MUST be `lib/`-clean to avoid coverage-gate fights.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| "Doc is stale" detection | Custom Dart linter | Plain grep — see "Validation Architecture" below | The drift catalogue is finite (≈25 grep patterns); a tool would take longer to write than the sweep itself. |
| "Find broken links in markdown" | Custom regex script | `markdown-link-check` (Node) or just shell loop | If we want CI gating in Phase 8, prefer `markdown-link-check` from npm. **Recommendation:** Use shell loop (above) for Phase 7 acceptance; defer link-checker CI to Phase 8 / FUTURE-TOOL. |
| "ARCH/MOD/ADR file numbering integrity" | New tool | Manual review against `.claude/rules/arch.md` rules | Rules are well-defined; one-shot manual audit is enough. |
| "Detect contradictions between CLAUDE.md and import_guard.yaml" | Cross-checker | Manual review of pitfall list | The mapping is small (13 pitfalls × 4 enforcement mechanisms = 52 cells); a table is the right tool. |

**Key insight:** Documentation sweeps suffer from over-tooling. The drift list below is concrete; finite; greppable. Build a checklist, not a framework.

## Runtime State Inventory

This is a **pure documentation phase** with **no runtime state to migrate**. There are no databases, services, OS registrations, secrets, or build artifacts that are touched by this phase.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — phase edits Markdown only | None |
| Live service config | None — no service has documentation cached at runtime | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None — Markdown does not generate Dart code or compile artifacts | None |

**Verified by:** `git status` after a representative Phase 7 commit will show diffs only under `docs/arch/`, `CLAUDE.md`, and `.claude/rules/` (if the planner chooses to fix the `doc/arch/` → `docs/arch/` path bug there too — see Open Question #1). No file under `lib/`, `test/`, `pubspec.yaml`, or `.github/` should change.

## Drift Inventory

> Each row is a **verified drift item** — confirmed by the grep command in the rightmost column on the current `main` (HEAD = `e2a00cd` "docs(06): add security threat verification"). Sorted by severity of confusion to a future contributor.

### Category D1 — Layer Centralization Drift (Phase 3 + 4 outcome)

| # | File:Line | Stale Reference | Should Be | Verification Grep |
|---|-----------|-----------------|-----------|-------------------|
| D1-1 | `MOD-007_Settings.md:101` | `lib/features/settings/application/use_cases/export_backup_use_case.dart` | `lib/application/settings/export_backup_use_case.dart` (TBC by planner — `lib/application/settings/` exists) | `grep -n "features/settings/application/use_cases" docs/arch/02-module-specs/MOD-007_Settings.md` |
| D1-2 | `MOD-007_Settings.md:236` | `lib/features/settings/application/use_cases/import_backup_use_case.dart` | `lib/application/settings/import_backup_use_case.dart` | (same grep as above) |
| D1-3 | `MOD-007_Settings.md:371` | `lib/features/settings/data/repositories/settings_repository_impl.dart` | `lib/data/repositories/settings_repository_impl.dart` | `grep -n "features/settings/data/repositories" docs/arch/` |
| D1-4 | `MOD-007_Settings.md:819` | `test/features/settings/application/use_cases/export_backup_use_case_test.dart` | `test/application/settings/export_backup_use_case_test.dart` (TBC by planner via `find test/`) | `grep -n "test/features/settings/application/use_cases" docs/arch/` |
| D1-5 | `MOD-006_Analytics.md:268` | `lib/features/analytics/application/use_cases/get_monthly_report_use_case.dart` | `lib/application/analytics/get_monthly_report_use_case.dart` (TBC) | `grep -n "features/analytics/application/use_cases" docs/arch/` |
| D1-6 | `MOD-006_Analytics.md:520` | `lib/features/analytics/application/use_cases/get_budget_progress_use_case.dart` | `lib/application/analytics/get_budget_progress_use_case.dart` (TBC) | (same) |
| D1-7 | `MOD-006_Analytics.md:1269` | `test/features/analytics/application/use_cases/get_monthly_report_use_case_test.dart` | `test/application/analytics/...` (TBC) | (same) |
| D1-8 | `MOD-008_Gamification.md:440` | `lib/features/gamification/data/repositories/conversion_unit_repository_impl.dart` | `lib/data/repositories/{...}` — but **no gamification feature exists in lib/** (verified: `find lib -path "*gamification*"` → empty). MOD-008 is for a future module per ROADMAP "Out of Scope: New feature modules". Keep doc as-is but mark as `**目标位置（未实施）:**`. | `grep -n "features/gamification/data" docs/arch/` |
| D1-9 | `MOD-008_Gamification.md:586` | `lib/features/gamification/data/repositories/fortune_repository_impl.dart` | (same as D1-8 — speculative path) | (same) |
| D1-10 | `ADR-008_Book_Balance_Update_Strategy.md:832` | `lib/features/accounting/data/repositories/transaction_repository_impl.dart` | `lib/data/repositories/transaction_repository_impl.dart` (verified exists) | `grep -n "features/accounting/data" docs/arch/03-adr/` |
| D1-11 | `ADR-008_Book_Balance_Update_Strategy.md:848` | `test/features/accounting/data/repositories/transaction_repository_impl_test.dart` | `test/data/repositories/transaction_repository_impl_test.dart` (TBC by planner) | (same) |
| D1-12 | `ADR-010_CRDT_Conflict_Resolution_Strategy.md:37` | `lib/features/accounting/data/repositories/transaction_repository_impl.dart` | `lib/data/repositories/transaction_repository_impl.dart` | (same) |
| D1-13 | `MOD-007_Settings.md:47` | `lib/features/settings/domain/models/backup_data.dart` | **VERIFY**: `lib/features/settings/domain/models/` may still exist (Domain layer survives in features). Run `find lib/features/settings/domain/` first. | `grep -n "features/settings/domain" docs/arch/` |
| D1-14 | `MOD-008_Gamification.md:104-105` | `ConversionUnitRepositoryImpl` / `FortuneRepositoryImpl` paths in ASCII diagram | (same as D1-8/9 — annotate as not-yet-implemented) | `grep -n "ConversionUnitRepositoryImpl\|FortuneRepositoryImpl" docs/arch/` |

### Category D2 — Tooling Drift (Phase 4 mocktail migration + always-active SQLCipher gate)

| # | File:Line | Stale Reference | Should Be | Verification Grep |
|---|-----------|-----------------|-----------|-------------------|
| D2-1 | `MOD-007_Settings.md:822-830` | `package:mockito/mockito.dart`, `@GenerateMocks`, `*_test.mocks.dart` | mocktail equivalent: `package:mocktail/mocktail.dart`, `class MockX extends Mock implements X`, no generated file | `grep -rn "mockito\|@GenerateMocks\|\.mocks\.dart" docs/arch/` (currently 13 hits across MOD-006/007/008/009 and ARCH-001/007) |
| D2-2 | `MOD-006_Analytics.md:1272-1276` | (same pattern — mockito @GenerateMocks block) | (mocktail block) | (same) |
| D2-3 | `MOD-008_Gamification.md:1272-1281, 1434-1437` | (two mockito @GenerateMocks blocks) | (two mocktail blocks) | (same) |
| D2-4 | `MOD-009_VoiceInput.md:1266-1273` | `MockCategoryService`, `mockCategoryService = MockCategoryService()` | mocktail-style instantiation | (same) |
| D2-5 | `MOD-002_DualLedger.md:927-1010` | `MockTFLiteClassifier`, `verifyNever(mockTFLiteClassifier.predict(...))` | mocktail equivalents | (same) |
| D2-6 | `ARCH-007_Architecture_Diagram_I18N.md:360` | `└─ mockito 5.4+` | `└─ mocktail 1.0+` | `grep -n "mockito" docs/arch/01-core-architecture/` |
| D2-7 | `ARCH-001_Complete_Guide.md:86` | `Mocking: mockito ^5.4.4` | `Mocking: mocktail ^1.0.4` (verified `pubspec.yaml` line) | (same) |
| D2-8 | `ARCH-001_Complete_Guide.md:48` | `Database Engine: sqlite3_flutter_libs ^0.5.18` | **DELETE** the line entirely; only `sqlcipher_flutter_libs` is allowed (CI rejects sqlite3_flutter_libs per audit.yml line 64-69) | `grep -n "sqlite3_flutter_libs" docs/arch/` |
| D2-9 | `ADR-002_Database_Solution.md:52,387` | `sqlite3_flutter_libs` in dependency list | Add a `## Update: 2026-04-XX` section noting that `sqlite3_flutter_libs` is now actively rejected by CI; cross-reference ADR-011. **Don't delete the original decision body** (Pattern 2 above). | (same) |
| D2-10 | `ARCH-007_Architecture_Diagram_I18N.md:317-318` | `├─ sqlite3_flutter_libs 0.5+` | Delete line; keep only `sqlcipher_flutter_libs 0.6+ (加密)` | (same) |

### Category D3 — Module Numbering Drift (NOT created by Phase 3-6 — pre-existing, but DOCS-01 scope is "files... that... reference... renamed classes... or deleted modules" so internal heading mismatches are arguably in scope. **Open Question #2 below.**)

| # | File | Filename Says | Internal Heading Says | Recommended Action |
|---|------|---------------|------------------------|---------------------|
| D3-1 | `MOD-001_BasicAccounting.md` | MOD-001 | `# MOD-001/002` | Either: rename heading to `# MOD-001` OR rename file to match. **Open question.** |
| D3-2 | `MOD-002_DualLedger.md` | MOD-002 | `# MOD-003: 双轨账本` | Same. |
| D3-3 | `MOD-006_Analytics.md` | MOD-006 | `# MOD-007: 数据分析与报表` | Same. |
| D3-4 | `MOD-007_Settings.md` | MOD-007 | `# MOD-008: 设置管理` | Same. |
| D3-5 | `MOD-008_Gamification.md` | MOD-008 | `# MOD-013: 游戏化体验模块` | Same. |
| D3-6 | `ARCH-001_Complete_Guide.md:2078` | (cross-ref) | `### MOD-009: 趣味功能` | MOD-009 file is `MOD-009_VoiceInput.md` ("语音记账"), not "趣味功能" (gamification). This is a content bug. Replace with `### MOD-009: 语音记账` or `### MOD-008: 趣味功能` per intended meaning. |

**Recommendation:** Defer D3 to a separate plan or to FUTURE-DOC. The scope of DOCS-01 is "post-refactor file paths and class names" — not pre-existing numbering inconsistency. Worth flagging in the new ADR-011 as a known doc debt.

### Category D4 — `doc/arch` vs `docs/arch` Path Drift (CRITICAL — every CLAUDE.md "Key Reference" link is broken as written)

| # | File:Line | Stale Reference | Should Be | Verification Grep |
|---|-----------|-----------------|-----------|-------------------|
| D4-1 | `CLAUDE.md:190` | `doc/arch/02-module-specs/MOD-014_i18n.md` | `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md` (the merged location per BASIC-003:21) | `grep -n "doc/arch" CLAUDE.md` (6 hits) |
| D4-2 | `CLAUDE.md:227` | `## Architecture Docs (\`doc/arch/\`)` | `## Architecture Docs (\`docs/arch/\`)` | (same) |
| D4-3 | `CLAUDE.md:255-258` | 4 links to `doc/arch/01-core-architecture/ARCH-001..004` | All 4 → `docs/arch/01-core-architecture/...` | (same) |
| D4-4 | `.claude/rules/arch.md` (multiple lines: 7, 29, 34, 87, 90, 94, 97, 187, 191, 220) | All `doc/arch/` references | All → `docs/arch/` | `grep -n "doc/arch" .claude/rules/arch.md` |

**Sub-question:** Is `.claude/rules/arch.md` in scope for Phase 7? It is project-instruction (counts as documentation), and DOCS-01 says "All ARCH/MOD/ADR files under `doc/arch/`" — strictly it does not say "and project-instructions". **Recommendation: include it.** A user reading CLAUDE.md gets pointed to `.claude/rules/arch.md` for the full workflow; both must be consistent. **Open Question #3 below.**

### Category D5 — Phantom MOD-014 References

| # | File:Line | Reference | Reality |
|---|-----------|-----------|---------|
| D5-1 | `CLAUDE.md:190` | `doc/arch/02-module-specs/MOD-014_i18n.md` | File does not exist. `BASIC-003_I18N_Infrastructure.md:21` says "MOD-014（已合并）". |
| D5-2 | `CLAUDE.md:220` | "MOD-014 i18n" in Module Development Priority | Same. |
| D5-3 | `ARCH-007_Architecture_Diagram_I18N.md` (multiple lines: 13, 28, 141, 436, 470) | "MOD-014" labels in ASCII diagrams | Update to "BASIC-003" or remove label; or annotate diagrams as "MOD-014 (now BASIC-003)". |
| D5-4 | `ARCH-008_Layer_Clarification.md:354-357` | 4 entries label DateFormatter / NumberFormatter / LocaleSettings / SupportedLocales as "MOD-014" | Replace with "BASIC-003". |
| D5-5 | `UI-001_Page_Inventory.md:15,386` | "MOD-001 ~ MOD-009、MOD-014" + link to non-existent `MOD-014_i18n.md` | Update list / replace link. |

### Category D6 — `docs/arch/README.md` is Stale

`docs/arch/README.md` says:
- Line 36: `MOD-009_Internationalization.md` — file does not exist (only `MOD-009_VoiceInput.md`).
- Lines refer to `arch2/` (legacy directory name) — actual directory has been `docs/arch/` since 2026-02-03 per `.claude/rules/arch.md` line 218.

This README is the entry point for new contributors. **High priority** for the sweep.

## CLAUDE.md Pitfall Classification (DOCS-02)

> For each of the 13 items in CLAUDE.md "Common Pitfalls", classify enforcement status. **Verified by inspection of `analysis_options.yaml`, `lib/*/import_guard.yaml`, `.github/workflows/audit.yml`, `test/architecture/*_test.dart`, and `pubspec.yaml`.**

| # | Pitfall | Enforcement Status | Mechanism | Annotation Suggestion |
|---|---------|--------------------|-----------|------------------------|
| 1 | Don't modify generated files (`.g.dart`, `.freezed.dart`) | **Partially enforced** | (a) `analysis_options.yaml` excludes `**/*.g.dart` and `**/*.freezed.dart` from analyzer; (b) AUDIT-10 CI gate runs `build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` per `.github/workflows/audit.yml:81-89`. **Catches stale committed generated files; does NOT catch hand-edits that happen to match generator output.** | `[Partially enforced — AUDIT-10 catches stale committed files; hand-edits to .g.dart/.freezed.dart that match generator output go undetected]` |
| 2 | Don't violate layer dependencies (Domain must not import Data) | **Structurally enforced** | `import_guard_custom_lint` plugin (`pubspec.yaml:79`) registered via `analysis_options.yaml:8` plugins; per-layer rules in `lib/features/import_guard.yaml` (Thin Feature rule), `lib/application/import_guard.yaml`, `lib/data/import_guard.yaml`, `lib/infrastructure/import_guard.yaml`. CI runs `dart run custom_lint` (audit.yml:36). Architecture test `test/architecture/domain_import_rules_test.dart`. | `[Structurally enforced — import_guard via custom_lint + arch test domain_import_rules_test.dart]` |
| 3 | Don't skip code generation after modifying annotated classes | **Structurally enforced** | AUDIT-10 CI gate (audit.yml:81-89) — `build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` blocks PR if generated diff is non-empty. | `[Structurally enforced — AUDIT-10 CI guardrail blocks PRs with stale generated files]` |
| 4 | Don't mutate objects — always use `copyWith` | **Manually-checked only** | Freezed enforces immutability per-class but does not prevent code from mutating non-`@freezed` classes. No general "no-mutation" lint exists. Code review only. | `[Manually-checked only — freezed enforces it on @freezed classes; general mutation undetected]` |
| 5 | Don't use `intl` version other than 0.20.2 | **Structurally enforced** | `pubspec.yaml:18` pins `intl: 0.20.2` (not `^0.20.2`); `pub get` on a different version errors out. | `[Structurally enforced — exact pin in pubspec.yaml line 18]` |
| 6 | Don't add `sqlite3_flutter_libs` | **Structurally enforced (double layer)** | (a) `lib/import_guard.yaml:5` denies `package:sqlite3_flutter_libs/**`; (b) AUDIT-09 CI gate `grep sqlite3_flutter_libs pubspec.lock` exits 1 (audit.yml:64-69). | `[Structurally enforced — import_guard deny rule + AUDIT-09 CI guardrail]` |
| 7 | Don't modify Podfile `post_install` without preserving EXCLUDED_ARCHS fix | **Manually-checked only** | No automated check on Podfile content. iOS build smoke test would catch it eventually but slow feedback loop. | `[Manually-checked only — no Podfile lint; relies on reviewer + iOS build verification]` |
| 8 | Don't commit with analyzer warnings | **Structurally enforced** | `flutter analyze --no-fatal-infos` runs in CI (audit.yml:34); `analysis_options.yaml` defines lint rules. | `[Structurally enforced — flutter analyze CI step (audit.yml line 34)]` |
| 9 | Don't hardcode widget parameter defaults — use nullable + provider fallback | **Manually-checked only** | No lint catches "hardcoded default value should be a provider read". Code review only. | `[Manually-checked only — no automated detection]` |
| 10 | Don't duplicate repository provider definitions | **Structurally enforced** | `test/architecture/provider_graph_hygiene_test.dart` (created in Phase 4-05 per ROADMAP) enforces HIGH-04 invariant (one `repository_providers.dart` per feature). `riverpod_lint` (pubspec.yaml:78) catches several Riverpod anti-patterns. | `[Structurally enforced — arch test provider_graph_hygiene_test.dart + riverpod_lint]` |
| 11 | Don't use wrong Drift index syntax — use `TableIndex` with `{#column}` | **Manually-checked only** | Drift compiler accepts whatever syntax compiles; no specific arch test for `TableIndex` shape. Phase 6-02 added the three indices manually. | `[Manually-checked only — Drift compiler does not enforce naming or symbol-syntax conventions]` |
| 12 | Don't skip AppInitializer — initialize core services before `runApp()` | **Partially enforced** | Phase 3-02 created `AppInitializer` with concrete `appDatabaseProvider`. Test `test/architecture/provider_graph_hygiene_test.dart` (HIGH-06) asserts no provider throws `UnimplementedError` outside test fixtures — this catches the failure mode but not the "forgot to call initialize" mistake. | `[Partially enforced — provider_graph_hygiene_test.dart catches UnimplementedError providers; "forgot to call initialize()" is manual]` |
| 13 | Don't forget to regenerate code after merge/pull | **Structurally enforced** | AUDIT-10 CI gate (audit.yml:81-89) — same mechanism as #3. | `[Structurally enforced — AUDIT-10 CI guardrail catches stale generated files post-merge]` |

**Summary tally:**
- Structurally enforced: **#2, #3, #5, #6, #8, #10, #13** (7 of 13)
- Partially enforced: **#1, #12** (2 of 13)
- Manually-checked only: **#4, #7, #9, #11** (4 of 13)

**Recommended CLAUDE.md edit pattern:**
```markdown
1. Don't modify generated files (`.g.dart`, `.freezed.dart`)
   *[Partially enforced — AUDIT-10 CI catches stale committed files; hand-edits matching generator output go undetected]*
```

This puts the annotation in italics on a follow-up indented line so the original numbered list reads cleanly.

## INDEX.md Health Audit (DOCS-03)

### `docs/arch/01-core-architecture/ARCH-000_INDEX.md`

**Files in directory** (verified):
```
ARCH-000_INDEX.md
ARCH-001_Complete_Guide.md
ARCH-002_Data_Architecture.md
ARCH-003_Security_Architecture.md
ARCH-004_State_Management.md
ARCH-005_Integration_Patterns.md
ARCH-006_Error_Boundaries.md
ARCH-007_Architecture_Diagram_I18N.md
ARCH-008_Layer_Clarification.md
```

| Issue | Description | Action |
|-------|-------------|--------|
| (A) Broken links | None — all 8 ARCH entries link to existing files. | OK |
| (B) Orphan files | None — all 8 files are listed. | OK |
| (C) Cross-section breakage (MOD section) | Line 36: `~~MOD-005 安全隐私~~ 文件不存在` — already annotated as missing. OK. | Leave |
| (D) Cross-section breakage (ADR section) | All 10 ADR links present and valid. | OK |
| (E) Missing entries | No entry for `BASIC-001..004` files in `docs/arch/04-basic/` (table at lines 42-49 includes them — OK, this is fine). No entry for `UI-001_Page_Inventory.md` in `docs/arch/05-UI/`. | Add a "UI Specs" subsection or annotate. |
| (F) Phantom references | Line 197+: dependency diagram shows "MOD-005 (安全模块) [未创建]" and "MOD-009 (家庭同步)" — but real MOD-009 file is voice input, not family sync. The Week-by-week timeline (line 235+) similarly mixes module numbers. | This is module-numbering drift D3 — defer per Open Q#2. |

**Note:** ARCH-000 acts as **the master index for ARCH + MOD + BASIC + ADR**. There is no separate MOD-000_INDEX.md (verified).

### `docs/arch/02-module-specs/MOD-000_INDEX.md`

**Status:** **DOES NOT EXIST.** Confirmed by `ls`.

**DOCS-03 says:** "doc/arch/INDEX.md files (ARCH-000, ADR-000, MOD-000) are verified to reference only files that still exist."

**Interpretation options:**
1. **Strict reading:** Phase 7 must create `MOD-000_INDEX.md` (it should exist per the requirement wording).
2. **Lenient reading:** ARCH-000 already lists every MOD file at lines 30-40; redundant to duplicate. Skip MOD-000 creation.
3. **Pragmatic:** Create a stub `MOD-000_INDEX.md` that delegates to ARCH-000:
```markdown
# MOD Index
This directory's master index lives in [ARCH-000_INDEX.md](../01-core-architecture/ARCH-000_INDEX.md) — see the "功能模块技术文档" section.
```

**Recommendation:** Option 3 (stub-with-pointer). Aligns with DOCS-03 literal text, costs ≈10 lines, eliminates ambiguity for future contributors.

**Open Question #4 below.**

### `docs/arch/03-adr/ADR-000_INDEX.md`

**Files in directory** (verified):
```
ADR-000_INDEX.md
ADR-001_State_Management.md
ADR-002_Database_Solution.md
ADR-003_Multi_Layer_Encryption.md
ADR-004_CRDT_Sync.md
ADR-005_OCR_ML_Tech.md
ADR-006_Key_Derivation_Security.md
ADR-007_Layer_Responsibilities.md
ADR-008_Book_Balance_Update_Strategy.md
ADR-009_Incremental_Hash_Chain_Verification.md
ADR-010_CRDT_Conflict_Resolution_Strategy.md
```

| Issue | Description | Action |
|-------|-------------|--------|
| (A) Broken links | None — all 10 ADR entries link to existing files. | OK |
| (B) Orphan files | None. | OK |
| (C) Stale "下次Review日期" | ADR-001/002/004/005/007 all have "2026-08-03" Review dates which are in the future relative to today (2026-04-27). OK. | OK |
| (D) ADR-003/006 Review dates | Listed as "2026-05-03 (每3个月)" — review window opens in ~6 days. Out of scope for Phase 7 (security review, not doc cleanup). | Leave |
| (E) Missing ADR-011 | After this phase, ADR-011 will exist for the cleanup outcome. ADR-000_INDEX.md must be updated to include it (DOCS-04 acceptance). | Add in Plan 07-05 |
| (F) Implementation status | ADR-006 is "已实施", ADR-008/009/010 are "已接受 / 实施完成后 review" — implementation status of ADR-008/009/010 is **uncertain post-cleanup**. The cleanup did not implement them. Worth confirming in ADR-011 to avoid future contributors thinking they were implemented as part of the cleanup. | Note in ADR-011 §"Out of Scope" |

### `docs/arch/README.md` (master directory README)

| Issue | Description | Action |
|-------|-------------|--------|
| (A) Stale directory name | Says `arch2/` (lines 1, 11) — actual is `docs/arch/`. | Replace `arch2/` with `docs/arch/`. |
| (B) Phantom file | Line 36: `MOD-009_Internationalization.md` — file does not exist. Real file is `MOD-009_VoiceInput.md`. Plus extra `ARCH-009_I18N_Update_Summary.md` listed which also does not exist. | Sync directory listing to actual files. |
| (C) Module description | Line 82: `MOD-009 - 国际化多语言` — wrong; MOD-009 is voice input. | Replace. |

**Recommendation:** Roll README.md fix into Plan 07-04 (INDEX health).

## New ADR (DOCS-04) Scope

### Numbering

**Current max ADR:** `ADR-010_CRDT_Conflict_Resolution_Strategy.md` (verified by `ls -1 docs/arch/03-adr/ADR-*.md | sort | tail -1`).

**Next sequential:** **ADR-011**

**Per `.claude/rules/arch.md`** (the rule file, currently mis-pathed but normative):
- Format: `ADR-011_{PascalCase_Title}.md`
- Must include: 标题/编号、状态、背景、考虑的方案、决策、决策理由、后果、实施计划

### Suggested Title Options

(Plan 07-05 will pick one; user should confirm during plan-time discussion)

1. `ADR-011_Codebase_Cleanup_Initiative_Outcome.md` — broad, covers DOCS-04 scope verbatim
2. `ADR-011_Cleanup_Initiative_And_CI_Enforcement.md` — emphasizes the durable CI gates
3. `ADR-011_Audit_Driven_Refactor_Closeout.md` — emphasizes audit-pipeline framing

**Recommendation:** Option 1 (closest to DOCS-04 wording).

### Required Subsections (DOCS-04 mandates 3 sub-topics)

| # | Subsection | Content (sourced from STATE.md decisions + ROADMAP success criteria) |
|---|------------|----------------------------------------------------------------------|
| 1 | **Cleanup Initiative Outcome** | - 8 phases planned (1-8), 6 complete at ADR write time; phase 7 = this doc sweep; phase 8 = re-audit verification. - Total findings catalogued in `.planning/audit/issues.json`: severity counts (CRITICAL/HIGH/MEDIUM/LOW). All MEDIUM and LOW closed; CRITICAL and HIGH closed in Phase 3-4. - Touched-file count, coverage uplift baseline → post-cleanup. (Pull from `.planning/audit/coverage-baseline.txt` and `phase6-touched-files.txt`.) |
| 2 | **`*.mocks.dart` Strategy Decision** | - **Decision:** Mocktail big-bang migration (verified: pubspec.yaml has `mocktail: ^1.0.4`; mockito absent from pubspec; no `*.mocks.dart` files in repo). - Rationale: per HIGH-07 acceptance criterion + Phase 4-04 plan ("Mocktail migration of 13 *.mocks.dart fixtures + mockito removal"). - Alternative considered (CI-generated mockito): rejected because committed `*.mocks.dart` was the actual MOD-009 / MOD-006 / MOD-007 / MOD-008 doc-described pattern, but maintenance cost is high; mocktail removes generation entirely. - Cross-reference: STATE.md decision "*.mocks.dart strategy must be decided before Phase 4 — SUMMARY.md recommends Mocktail" (Concerns line 99). |
| 3 | **Ongoing CI Enforcement Mechanisms** | List all permanent CI gates that survive into Phase 8+: 1. **`flutter analyze`** — `audit.yml:34` 2. **`dart run custom_lint`** (with `import_guard_custom_lint` + `riverpod_lint`) — `audit.yml:36` 3. **`import_guard.yaml` 5-layer rules** — `lib/import_guard.yaml`, `lib/application/import_guard.yaml`, `lib/data/import_guard.yaml`, `lib/features/import_guard.yaml`, `lib/infrastructure/import_guard.yaml` 4. **AUDIT-09 SQLCipher gate** — `audit.yml:64-69` (rejects sqlite3_flutter_libs in pubspec.lock) 5. **AUDIT-10 build_runner stale-diff gate** — `audit.yml:81-89` 6. **`very_good_coverage@v2`** with `min_coverage: 80` — `audit.yml:108-118` 7. **`coverde` per-file ≥80% gate** — `scripts/coverage_gate.dart` invoked in `audit.yml` 8. **Architecture tests under `test/architecture/`** — 10 tests including `domain_import_rules_test.dart`, `presentation_layer_rules_test.dart`, `provider_graph_hygiene_test.dart`, `service_name_collision_test.dart`, `production_logging_privacy_test.dart`, etc. |

### Cross-References (Status Sections to Update in Other ADRs)

When ADR-011 lands, **append** an `## Update {YYYY-MM-DD}: Superseded By / Affected By ADR-011` paragraph to:

| ADR | Why |
|-----|-----|
| ADR-002_Database_Solution.md | Mentions sqlite3_flutter_libs as one of the dual choices; ADR-011 documents that it is now actively rejected by CI |
| ADR-007_Layer_Responsibilities.md | Defines layer rules; ADR-011 documents that they are now mechanically enforced via `import_guard.yaml` |
| ADR-008/009/010 | These three ADRs were "已接受 / Phase planning" but the cleanup did NOT implement them. ADR-011 should document that they remain v2 backlog (matches STATE.md "Deferred Items"). |

**Don't mark them as deprecated** — they are still the design of record. Just append the update paragraph.

### Out-of-Scope for ADR-011

State explicitly in ADR-011 to prevent scope creep:
- `recoverFromSeed()` security bug (FUTURE-ARCH-04)
- DCM upgrade (FUTURE-ARCH-03)
- riverpod_lint 3.x upgrade (FUTURE-TOOL-01)
- ARB-driven CategoryLocaleService (FUTURE-ARCH-01)
- Drift unused-column detection (FUTURE-TOOL-02)

These are listed in `.planning/STATE.md` "Deferred Items" — quote them verbatim in ADR-011's "未来工作" section.

## Recommended Plan Breakdown

| Plan ID | Title | Wave | Depends On | Approx. Edits | Acceptance Grep |
|---------|-------|------|------------|---------------|------------------|
| 07-01 | ARCH/MOD Drift Fixes (DOCS-01 part 1) | A | nothing | All D1-1..14, D2-1..7, D3-6, D5-3..5 — about **28 sites** across 7 MOD files + 3 ARCH files | `grep -rn "features/.*/use_cases\|features/.*/data/repositories\|mockito\|sqlite3_flutter_libs\|MOD-014" docs/arch/01-core-architecture/ docs/arch/02-module-specs/ docs/arch/05-UI/` → 0 hits |
| 07-02 | ADR Drift Fixes (DOCS-01 part 2) | A | nothing | D1-10..12, D2-9, ADR-007 status update; "## Update" appendices to ADR-002, ADR-007, ADR-008, ADR-010 | `grep -rn "features/accounting/data\|sqlite3_flutter_libs\|mockito" docs/arch/03-adr/` → 0 hits in body (allowed in "## Update" paragraphs that explicitly note historical context) |
| 07-03 | CLAUDE.md Pitfall Annotation + Path Fix (DOCS-02 + D4) | A | nothing | All 13 pitfalls annotated; `doc/arch/` → `docs/arch/` (6 sites in CLAUDE.md, 10+ sites in `.claude/rules/arch.md`); MOD-014 → BASIC-003 (D5-1, D5-2) | `grep -n "doc/arch[^/]" CLAUDE.md .claude/rules/arch.md` → 0 hits; every pitfall has annotation suffix |
| 07-04 | INDEX Health + README Fix (DOCS-03 + D6) | B | 07-01, 07-02, 07-03 | ARCH-000_INDEX.md additions for UI-001 (optional); MOD-000_INDEX.md stub creation; README.md sync to actual file list | All shell-loop link checks (Pattern 3) return 0 broken links and 0 orphans |
| 07-05 | ADR-011 Cleanup Outcome (DOCS-04) + Final Gate Run | B | 07-04 | New file `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md`; ADR-000_INDEX.md updated with ADR-011 entry; "## Update" paragraphs appended to ADR-002, ADR-007, ADR-008, ADR-010; final phase grep gate | All 6 acceptance greps from "Validation Architecture" section below return 0 |

**Why this groups parallel-then-sequential:**
- Plans 07-01/02/03 touch disjoint files: 07-01 touches `01-core-architecture/` + `02-module-specs/` + `05-UI/`; 07-02 touches `03-adr/`; 07-03 touches `CLAUDE.md` + `.claude/rules/arch.md`. **Zero overlap → safe to run in parallel waves.**
- Plan 07-04 must wait for 07-01..03 because INDEX entries reference paths that may have been corrected in those plans.
- Plan 07-05 must wait for 07-04 because the new ADR-011 references all updates landed by 07-01..04 as "the cleanup outcome".

**Plan-count justification (vs. fewer/more):**
- 4 plans: would force ADR work into the same plan as ARCH/MOD, blowing up the diff size (~900+ lines).
- 6 plans: would split CLAUDE.md annotation from `doc/arch/` path fix; both touch the same file, must commit together.
- **5 is the minimum that keeps plans <300 lines each and respects file-edit boundaries.**

## Validation Architecture

Phase 7 has `nyquist_validation: true` per `.planning/config.json:19`. Validation is grep-based, not flutter-test based, because no Dart code changes.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | grep + shell loops + (existing) `flutter test test/architecture/` |
| Config file | `.github/workflows/audit.yml` (existing); no new file needed |
| Quick run command | `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` (Wave 0 — to be created) |
| Full suite command | `flutter analyze --no-fatal-infos && flutter test test/architecture/ && bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DOCS-01 | All ARCH/MOD/ADR files free of stale Phase 3-6 references | grep gate | `! grep -rn "features/.*/use_cases\|features/.*/data/repositories\|mockito\|@GenerateMocks\|sqlite3_flutter_libs" docs/arch/` (must exit 0 → no matches) | ❌ Wave 0 — script `scripts/verify_doc_drift.sh` to be created in Plan 07-01 |
| DOCS-02 | All 13 pitfalls in CLAUDE.md have an annotation tag | grep gate | `python3 -c "import re; t=open('CLAUDE.md').read(); pitfall=re.search(r'## Common Pitfalls.+?(?=\n## |\Z)', t, re.S).group(); items=re.findall(r'^\d+\..+?(?=^\d+\.|\Z)', pitfall, re.M); print('OK' if all('Structurally enforced' in i or 'Partially enforced' in i or 'Manually-checked only' in i for i in items) else 'FAIL'); exit(0 if 'OK' in print else 1)"` | ❌ Wave 0 — verification script to be created |
| DOCS-03 | INDEX entries reference only existing files; directories have no orphan files | shell loop | (Pattern 3 above) — to live in `scripts/verify_index_health.sh` | ❌ Wave 0 |
| DOCS-04 | ADR-011 file exists and is linked from ADR-000 INDEX | file presence + grep | `test -f docs/arch/03-adr/ADR-011_*.md && grep -q "ADR-011" docs/arch/03-adr/ADR-000_INDEX.md` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` (≈3 seconds)
- **Per wave merge:** Same script + `flutter analyze && flutter test test/architecture/` (≈30 seconds)
- **Phase gate:** Full suite green before `/gsd-verify-work`; explicit human review of ADR-011 prose

### Wave 0 Gaps

The following test artifacts must be created in **Plan 07-01 Wave 0** before any drift fixes commit:

- [ ] `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` — orchestrator script that runs all 4 grep gates below
- [ ] `scripts/verify_doc_drift.sh` — runs the DOCS-01 grep set; exits 1 on any match
- [ ] `scripts/verify_index_health.sh` — runs the Pattern 3 shell loop for ARCH-000, ADR-000, MOD-000 (if created)
- [ ] (Optional) `scripts/verify_claude_md_pitfalls.py` — Python check that all 13 pitfalls in CLAUDE.md have an enforcement annotation. Lower-priority — can be replaced by manual `grep -c` count.

**Framework install:** None. (`bash`, `python3`, `grep` all already available.)

**Phase 7 has no `flutter test` requirements beyond the existing 10 architecture tests** (which should remain green throughout — pure-doc commits cannot affect them). The architecture tests are the *de facto* "structurally enforced" backstop for DOCS-02 annotations.

## Common Pitfalls (for the Phase 7 plan executor)

### Pitfall 7-A: Editing ADR Decision Bodies Instead of Appending
**What goes wrong:** Replacing the original "采用增量更新" wording in ADR-008 with current code paths erases the historical decision context.
**Why it happens:** `git grep -i sqlite3` etc. surfaces matches; default reflex is "fix the match".
**How to avoid:** ADR-008/009/010 are "已接受 / Phase planning"; their content describes a *future* implementation, not the cleanup outcome. Use Pattern 2 (append "## Update" section). Only the Tooling-Drift D2 items in ADR-002 belong in the appendix.
**Warning signs:** A diff that *removes* lines from an ADR body (vs. adding to the bottom).

### Pitfall 7-B: Sweeping `arch2/` Outside docs/
**What goes wrong:** `grep -rn "arch2/"` may surface hits in `docs/worklog/`, `.planning/research/`, or `feasibility_report.md` — these are historical worklog files, not in DOCS-01 scope.
**Why it happens:** Phase 7 acceptance commands grep recursively; over-zealous "fix all" makes the diff sprawl.
**How to avoid:** Scope every grep to `docs/arch/` and `CLAUDE.md` (and `.claude/rules/arch.md` per the deliberate inclusion). Don't touch `docs/worklog/`, `.planning/`, or root-level `*.md` (README.md, AGENTS.md, etc.) unless explicitly part of a plan's Files Modified list.
**Warning signs:** Diff includes files outside `docs/arch/` and `CLAUDE.md` and `.claude/rules/`.

### Pitfall 7-C: Renaming MOD Files
**What goes wrong:** Renaming `MOD-008_Gamification.md` to `MOD-013_Gamification.md` because the heading inside says MOD-013.
**Why it happens:** D3 (numbering drift) is tempting to fix; cosmetic but disruptive.
**How to avoid:** **Do not rename existing MOD files in this phase.** That breaks every external bookmark/link. Defer numbering reconciliation to a follow-up plan or v2 backlog. Only fix the ARCH-001:2078 cross-ref where heading says wrong module name.
**Warning signs:** Diff renames a `MOD-*.md` file.

### Pitfall 7-D: Forgetting the Wave 0 Test Script
**What goes wrong:** Plan 07-01 starts edits without the verification script in place; reviewers can't confirm "drift gone" mechanically.
**Why it happens:** Hand-edit work feels like it doesn't need tests.
**How to avoid:** Plan 07-01's Wave 0 task **MUST be** "create `verify-doc-sweep.sh` and confirm it currently FAILS (because drift still exists)". Then Plan 07-01's Wave 1 makes it pass.
**Warning signs:** First commit in Plan 07-01 modifies an ARCH/MOD file without an antecedent script-creation commit.

### Pitfall 7-E: Including Code Edits in a Doc Plan
**What goes wrong:** Plan 07-03 sees a `.mocks.dart`-related comment in MOD-007 and "fixes" the actual mock file.
**Why it happens:** Phase 7 is the only "after-cleanup" phase; tempting to include "one tiny code fix".
**How to avoid:** Phase 7 PRs operate under `REPO-LOCK-POLICY.md` line 33: "Phase 7 (docs sweep) — Operates under normal merge rules; not bound by lock." This **does not** mean "free to edit code"; it means "doc commits don't trip the coverage gate". **Every commit must be `lib/`-clean.**
**Warning signs:** `git diff --name-only` shows any file under `lib/`, `test/`, `pubspec.*`, or `.github/`.

## Code Examples

### Example: Wave 0 verification script (`verify-doc-sweep.sh`)

```bash
#!/bin/bash
# .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
# Verifies that documentation drift is fully remediated.
# Exits 0 only when ALL drift gates pass.

set -e
fail=0

echo "[1/6] Checking layer-centralization drift..."
hits=$(grep -rn "features/[a-z_]*/use_cases\|features/[a-z_]*/data/repositories" docs/arch/ | grep -v "^docs/arch/03-adr/.*## Update" | wc -l)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits stale layer paths in docs/arch/"; fail=1; } || echo "  OK"

echo "[2/6] Checking mockito drift..."
hits=$(grep -rn "package:mockito\|@GenerateMocks\|\.mocks\.dart" docs/arch/ | grep -v "^docs/arch/03-adr/.*## Update" | wc -l)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits mockito references"; fail=1; } || echo "  OK"

echo "[3/6] Checking sqlite3_flutter_libs drift in non-historical contexts..."
hits=$(grep -rn "sqlite3_flutter_libs" docs/arch/ | grep -v "^docs/arch/03-adr/" | wc -l)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits sqlite3_flutter_libs in non-ADR docs"; fail=1; } || echo "  OK"

echo "[4/6] Checking doc/arch path drift in CLAUDE.md..."
hits=$(grep -cE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null || true)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits 'doc/arch' references"; fail=1; } || echo "  OK"

echo "[5/6] Checking MOD-014 phantom references..."
hits=$(grep -rn "MOD-014_i18n\.md\|MOD-014 i18n" docs/arch/ CLAUDE.md | wc -l)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits phantom MOD-014 file references"; fail=1; } || echo "  OK"

echo "[6/6] Checking ADR-011 presence..."
test -f docs/arch/03-adr/ADR-011_*.md || { echo "  FAIL: ADR-011 missing"; fail=1; }
grep -q "ADR-011" docs/arch/03-adr/ADR-000_INDEX.md || { echo "  FAIL: ADR-011 not indexed"; fail=1; }
[ "$fail" -eq 0 ] && echo "  OK"

exit $fail
```

### Example: INDEX link-check loop

```bash
#!/bin/bash
# scripts/verify_index_health.sh
# Confirms every link in INDEX files points to a real file,
# and every file in the directory is mentioned in INDEX.

set -e
fail=0

check_dir() {
  local dir=$1
  local index=$2
  echo "Checking $dir against $index..."

  # (A) Broken-link check
  while read -r path; do
    full="$dir/$(basename "$path")"
    if [ ! -f "$full" ]; then
      echo "  BROKEN LINK in $index: $path"
      fail=1
    fi
  done < <(grep -oE '\([^)]+\.md\)' "$index" | tr -d '()' | grep -v '^http' | sort -u)

  # (B) Orphan-file check
  for f in "$dir"/*.md; do
    base=$(basename "$f")
    [ "$base" = "$(basename "$index")" ] && continue
    if ! grep -q "$base" "$index"; then
      echo "  ORPHAN: $base not listed in $index"
      fail=1
    fi
  done
}

check_dir docs/arch/01-core-architecture docs/arch/01-core-architecture/ARCH-000_INDEX.md
check_dir docs/arch/03-adr docs/arch/03-adr/ADR-000_INDEX.md
# MOD-000 — only run if it exists (created in Plan 07-04 if Open Q#4 chooses option 3)
[ -f docs/arch/02-module-specs/MOD-000_INDEX.md ] && check_dir docs/arch/02-module-specs docs/arch/02-module-specs/MOD-000_INDEX.md

exit $fail
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | All verification scripts | ✓ (assumed — macOS Darwin 25.3.0 default) | n/a | — |
| `grep` | DOCS-01 / DOCS-04 grep gates | ✓ (BSD grep on macOS) | system | GNU grep via `brew install grep` (no actual need — BSD `grep -rn` works) |
| `python3` | Optional pitfall-annotation lint | ✓ (assumed; common on macOS) | system | Skip the script; do manual `grep -c` count instead |
| `git` | Repo state inspection | ✓ | confirmed via session env | — |
| `flutter analyze` / `flutter test` | Architecture-test backstop in full validation suite | ✓ (already used in Phases 1-6) | pinned by pubspec.yaml | — |

**No new dependencies required.** No installs needed.

## Security Domain

This phase has `security_enforcement: enabled` (default). It is documentation-only — no production behavior changes — but security-relevant content is updated.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a — phase does not touch auth code or its docs |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | no | n/a |
| V6 Cryptography | yes (read-only) | ADR-003 (Multi-Layer Encryption) and ADR-006 (Key Derivation Security) **must not have their decision bodies altered**. Phase 7 may *append* "## Update" sections noting cleanup outcomes (none expected — the cleanup did not change crypto). Crypto rule references in CLAUDE.md (lines 144-150) are unchanged in this phase. |
| V14 Configuration | yes | CI guardrails (AUDIT-09, AUDIT-10, very_good_coverage, custom_lint) get documented in ADR-011. ADR-011 must list these gates accurately — wrong CI documentation would weaken future contributors' understanding of the security posture. |

### Known Threat Patterns for Doc-Sweep Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental code edit during doc commit (introduces vulnerability silently) | Tampering | Pitfall 7-E; CI runs `flutter analyze` on every PR; `git diff --name-only` review before commit |
| ADR-003/006 (security ADRs) decision bodies rewritten | Tampering / Repudiation | Pitfall 7-A — append-don't-mutate; reviewer verifies ADR diffs are addition-only for these two ADRs |
| New ADR-011 incorrectly states a CI gate is enforcing something it isn't | Information Disclosure (false sense of security) | Cross-check every claim in ADR-011 §"CI Enforcement Mechanisms" against the actual `.github/workflows/audit.yml` line numbers — citations required in the ADR body |
| Phantom doc reference to a security service that no longer exists | Information Disclosure | Drift items D2-9 (sqlite3_flutter_libs) and D5 (MOD-014 phantom) prevent contributors from looking up specs that don't exist |

**Mitigation summary:** Phase 7 PRs MUST be `lib/`-only-clean (Pitfall 7-E), MUST be append-only for ADR-003/006 bodies, and MUST cite line numbers when claiming a CI gate enforces something.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-phase doc updates (touch ARCH/MOD/ADR during each fix phase) | Centralized sweep at Phase 7 | Roadmap creation 2026-04-25 (STATE.md decision: "Per-phase doc updates deferred; one sweep at Phase 7") | Reduces churn — every fix-phase plan focused on code; doc work batched |
| `*.mocks.dart` committed via `mockito @GenerateMocks` | `mocktail` runtime-only mocks | Phase 4-04 (2026-04-27) | Reduces generated-file noise; makes tests easier to read; eliminates AUDIT-10 false positives from mock generation |
| `sqlite3_flutter_libs` listed alongside `sqlcipher_flutter_libs` | Only `sqlcipher_flutter_libs` allowed; CI rejects sqlite3_flutter_libs | Phase 1-07 (CI guardrail AUDIT-09) and lib/import_guard.yaml | Active rejection prevents anyone re-introducing the SQLCipher conflict |
| `lib/features/{f}/use_cases/`, `lib/features/{f}/data/repositories/` | `lib/application/{domain}/`, `lib/data/repositories/` | Phase 3 (CRIT-02), Phase 3-04, Phase 4-01..02 | Centralized application + data layers; "Thin Feature" rule mechanically enforced |
| `appDatabaseProvider` throws `UnimplementedError` | Concrete provider via `AppInitializer` (`lib/core/initialization/app_initializer.dart`) | Phase 3-02 (CRIT-03) | Tests + production no longer require explicit override |
| `CategoryService` collision (infrastructure + application) | `CategoryLocaleService` (infrastructure only) | Phase 5-01 (MED-02) | Eliminates ambiguous import paths |

**Deprecated/outdated docs (still on disk; not yet swept):**
- `docs/arch/02-module-specs/MOD-009_VoiceInput.md` — references `CategoryService` (now `CategoryLocaleService`) and uses `mockito`. **Will be swept in Plan 07-01.**
- `docs/arch/02-module-specs/MOD-006_Analytics.md`, `MOD-007_Settings.md`, `MOD-008_Gamification.md` — same.
- `docs/arch/03-adr/ADR-002_Database_Solution.md` — lists sqlite3_flutter_libs as dependency. **Plan 07-02 appends "## Update" section.**
- `docs/arch/README.md` — says `arch2/` and lists phantom files. **Plan 07-04 fixes.**

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The Plan 07-04 should create `MOD-000_INDEX.md` as a stub pointing to ARCH-000 (Option 3) | INDEX.md Health Audit § MOD-000 | If user prefers no MOD-000 (Option 2), an unnecessary file is created. If user prefers full MOD-000 (Option 1), the stub is too thin. **Open Question #4.** |
| A2 | `.claude/rules/arch.md` is in scope for the `doc/arch/` → `docs/arch/` path fix | D4 row 4 | If out of scope, the rule file remains broken (says "doc/arch/" but actual path is "docs/arch/"). Since CLAUDE.md cross-references it, leaving it stale propagates confusion. **Open Question #3.** |
| A3 | Module-numbering drift (D3) is OUT of Phase 7 scope; defer to follow-up | Drift Inventory § D3 | If user wants D3 fixed in Phase 7, scope expands by ≈40 line edits across 5 files plus 5 file renames. **Open Question #2.** |
| A4 | Path corrections in MOD-006/007 to `lib/application/` should be verified by `find lib/application/` for each file before committing | D1 rows 1-7 | Some use-cases may NOT have been migrated (per Phase 4-01 plan: "scaffolding + new use cases"). The doc edit should reflect *the actual current location*, not the assumed centralized path. **Mitigated by `find` verification in plan acceptance.** |
| A5 | New ADR title is `ADR-011_Codebase_Cleanup_Initiative_Outcome.md` | New ADR Scope § Numbering | Title is bikesheddable; user may prefer a different name. **Open Question #5.** |
| A6 | All 8 CI gates listed in the "Ongoing CI Enforcement" subsection of ADR-011 are accurate per `audit.yml` line numbers | New ADR Scope § §3 | If a gate is misattributed (e.g., line number wrong), ADR-011 misleads future contributors. **Mitigated by mandatory citations in plan-time review.** |
| A7 | The `mocktail` migration was a "big bang" (all tests at once) per Phase 4-04 plan name | New ADR Scope § §2 | If migration is partial, ADR-011 overstates completion. **Verify by `grep -r mockito test/`** during Plan 07-05 — must return 0. (Already verified at research time: `grep mockito pubspec.yaml` returns nothing — high confidence migration is complete.) |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

## Open Questions

1. **Phantom MOD-014 references — replace with what target?**
   - What we know: `MOD-014_i18n.md` does not exist; `BASIC-003_I18N_Infrastructure.md:21` says it was merged into BASIC-003.
   - What's unclear: Should every "MOD-014" mention become "BASIC-003", or should the diagrams keep "MOD-014" labels with a footnote "(now BASIC-003)"?
   - Recommendation: Replace with "BASIC-003" in CLAUDE.md (line 190 spec link) and UI-001:386 (link target). Keep "MOD-014" labels in ARCH-007 ASCII diagrams but add a one-line legend at top of the section: "MOD-014 (i18n module) was merged into BASIC-003 in 2026-02-22."

2. **Module-numbering drift (D3) — fix in Phase 7 or defer?**
   - What we know: Every MOD file's filename number ≠ internal heading number. ARCH-001:2078 calls MOD-009 "趣味功能" but MOD-009 is voice input. Pre-existing drift; not caused by Phases 3-6.
   - What's unclear: Strict reading of DOCS-01 ("renamed classes... or deleted modules") does not include "renumbered modules". User intent unclear.
   - Recommendation: **Fix only the ARCH-001:2078 cross-ref** (which is wrong as a fact regardless of numbering). Defer rest to FUTURE-DOC-01 in v2 backlog. **User confirmation needed.**

3. **`.claude/rules/arch.md` `doc/arch/` → `docs/arch/` fix — in scope?**
   - What we know: The file says `doc/arch/` 10+ times; actual is `docs/arch/`. CLAUDE.md cross-references it.
   - What's unclear: DOCS-01 scope is literally "ARCH/MOD/ADR files under doc/arch/". `.claude/rules/arch.md` is project-instruction, not arch doc.
   - Recommendation: Include in Plan 07-03. The file is broken; fixing it is a 5-minute sed; benefit is high (project-instruction must be accurate). **User confirmation needed.**

4. **MOD-000_INDEX.md — create or skip?**
   - What we know: File does not exist. ARCH-000 acts as the master MOD index. DOCS-03 wording implies MOD-000 should exist.
   - What's unclear: User's intent re: lit reading of DOCS-03.
   - Recommendation: Create stub-with-pointer (Option 3 in INDEX § MOD-000). 10 lines. Closes the loop.

5. **ADR-011 title — pick one.**
   - Options listed in "New ADR Scope § Suggested Title Options". Default recommendation: `ADR-011_Codebase_Cleanup_Initiative_Outcome.md`.

6. **Should ADR-011 include a "lessons learned" section?**
   - DOCS-04 says "outcome, the *.mocks.dart strategy decision, and ongoing CI enforcement". Doesn't mandate retrospective.
   - Recommendation: Include a brief "## 后果分析" subsection (per ADR template in ADR-000_INDEX.md:484-489) with positive + negative impacts of the cleanup. Keep to <10 bullet points.

## Project Constraints (from CLAUDE.md)

| Directive | Source line | Phase 7 implication |
|-----------|-------------|----------------------|
| Zero analyzer warnings before commit | CLAUDE.md:239 | Phase 7 commits don't touch `lib/`, but `flutter analyze` must still pass on every PR |
| Don't suppress with `// ignore:` | CLAUDE.md:240 | n/a — pure markdown phase |
| Tests are first-class code | CLAUDE.md:242 | Wave 0 verification scripts must themselves be reviewable |
| Architecture docs (`doc/arch/`) — naming rules | CLAUDE.md:227-233 | New ADR-011 MUST follow `ADR-011_PascalCase.md` pattern; MUST update `ADR-000_INDEX.md` |
| Common Pitfalls — items 1-13 | CLAUDE.md:265-277 | All 13 must receive enforcement-status annotation in DOCS-02 |
| **Architecture docs path discrepancy** | CLAUDE.md:190, 227, 255-258 | **CLAUDE.md says `doc/arch/`; actual is `docs/arch/`. Phase 7 fixes this in Plan 07-03 (D4).** |

## Sources

### Primary (HIGH confidence — verified by direct grep on `main` HEAD `e2a00cd`)

- `/Users/xinz/Development/home-pocket-app/docs/arch/01-core-architecture/ARCH-000_INDEX.md` — full master index for ARCH/MOD/ADR
- `/Users/xinz/Development/home-pocket-app/docs/arch/03-adr/ADR-000_INDEX.md` — full ADR index, max ADR = 010
- `/Users/xinz/Development/home-pocket-app/docs/arch/02-module-specs/MOD-001..009_*.md` — module specs (8 files, MOD-005 absent by design)
- `/Users/xinz/Development/home-pocket-app/docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md:21` — confirms MOD-014 merged into BASIC-003
- `/Users/xinz/Development/home-pocket-app/CLAUDE.md` — 13-item Common Pitfalls list at lines 265-277
- `/Users/xinz/Development/home-pocket-app/.claude/rules/arch.md` — naming rules at line 41-73
- `/Users/xinz/Development/home-pocket-app/.github/workflows/audit.yml` — CI gate definitions (sources for DOCS-02 enforcement annotations)
- `/Users/xinz/Development/home-pocket-app/lib/import_guard.yaml`, `lib/application/import_guard.yaml`, `lib/data/import_guard.yaml`, `lib/features/import_guard.yaml`, `lib/infrastructure/import_guard.yaml` — layer rules (DOCS-02 "structurally enforced" sources)
- `/Users/xinz/Development/home-pocket-app/test/architecture/*_test.dart` — 10 architecture tests (provider_graph_hygiene, domain_import_rules, etc.)
- `/Users/xinz/Development/home-pocket-app/pubspec.yaml` — dependency pins (intl 0.20.2, mocktail 1.0.4, no mockito, no sqlite3_flutter_libs)
- `/Users/xinz/Development/home-pocket-app/.planning/STATE.md` — project decisions including "Per-phase doc updates deferred; one sweep at Phase 7"
- `/Users/xinz/Development/home-pocket-app/.planning/REQUIREMENTS.md` — DOCS-01..04 verbatim
- `/Users/xinz/Development/home-pocket-app/.planning/ROADMAP.md` — Phase 7 success criteria
- `/Users/xinz/Development/home-pocket-app/.planning/audit/REPO-LOCK-POLICY.md` — Phase 7 operates "under normal merge rules; not bound by lock"

### Secondary (MEDIUM confidence — derived from source-of-truth files via cross-grep)

- Drift item count: 28 sites for D1+D2 in ARCH/MOD; 4-5 sites for D1+D2 in ADR; 6 sites for D4 in CLAUDE.md, 10+ for D4 in arch.md rules — derived from greps shown in each table.
- Plan-count justification (5 plans optimal) — derived from edit-disjoint file-set analysis (07-01 vs. 07-02 vs. 07-03 touch zero overlapping files).
- ADR-011 cross-reference targets (ADR-002, ADR-007, ADR-008, ADR-010) — derived from D2-9 (ADR-002 mentions sqlite3) and from STATE.md "Deferred Items" listing ADR-008..010 implementations as v2.

### Tertiary (LOW confidence — flagged in Open Questions / Assumptions Log)

- Recommendation that `MOD-000_INDEX.md` should be a stub-with-pointer rather than full or absent. (Open Q#4.)
- Recommendation to defer module-numbering drift (D3) to follow-up. (Open Q#2.)
- Recommended ADR-011 title. (Open Q#5.)

## Metadata

**Confidence breakdown:**
- Drift Inventory (D1, D2, D4, D5, D6): **HIGH** — every row verified by direct grep returning concrete line numbers.
- D3 (module numbering): **HIGH** drift detection / **LOW** scoping recommendation (deferred per Open Q#2 — user decides).
- CLAUDE.md Pitfall Classification: **HIGH** — every "structurally enforced" claim cites a specific YAML/workflow line; "manually-checked only" claims justified by absence of corresponding lint rule.
- INDEX Health Audit: **HIGH** — all link / orphan checks performed by `ls` + `grep` cross-product.
- ADR-011 Scope: **HIGH** for content / **MEDIUM** for title selection (cosmetic).
- Validation Architecture: **HIGH** — verification script logic is straightforward grep.
- Open Questions: surfaced **5 user decisions** required before Plan 07-01 starts.

**Research date:** 2026-04-27
**Valid until:** 2026-05-11 (14 days — codebase is stable post-Phase-6; no Dart code is expected to change before Phase 7 begins)

---

**Ready for Planning.** Five plan IDs proposed: `07-01-arch-mod-drift-PLAN.md`, `07-02-adr-drift-PLAN.md`, `07-03-claude-md-pitfall-annotation-PLAN.md`, `07-04-index-health-PLAN.md`, `07-05-cleanup-outcome-adr-PLAN.md`. Wave A is parallelizable (3 plans), Wave B is sequential (2 plans). Five user-facing open questions documented above.
