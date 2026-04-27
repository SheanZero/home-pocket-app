---
phase: 7
slug: documentation-sweep
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-27
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Phase 7 is a pure-Markdown sweep: validation is grep-based, not Dart-test-based.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `bash` + `grep` + existing `flutter test test/architecture/` (read-only check) |
| **Config file** | `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` (Wave 0 — to be created in Plan 07-01) |
| **Quick run command** | `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` |
| **Full suite command** | `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh && flutter analyze --no-fatal-infos && flutter test test/architecture/` |
| **Estimated runtime** | ~3 seconds (quick) / ~30 seconds (full, includes existing analyzer + arch tests) |

---

## Sampling Rate

- **After every task commit:** Run `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` (failures expected during Wave 0/1 — that's the contract)
- **After every plan wave:** Run full suite — script must report progress (fewer failing gates)
- **Before `/gsd-verify-work`:** Full suite must be green (script exits 0; analyzer + arch tests pass)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-W0-01 | 01 | 0 | DOCS-01 | — | Verification script exists and currently FAILS | shell | `test -x .planning/phases/07-documentation-sweep/verify-doc-sweep.sh && ! bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` | ❌ W0 | ⬜ pending |
| 07-01-01 | 01 | 1 | DOCS-01 | — | Layer-centralization drift gone from ARCH/MOD/UI files | grep | `! grep -rn "features/[a-z_]*/use_cases\|features/[a-z_]*/data/repositories" docs/arch/01-core-architecture/ docs/arch/02-module-specs/ docs/arch/05-UI/` | ❌ W0 (Plan 07-01) | ⬜ pending |
| 07-02-01 | 02 | 1 | DOCS-01 | — | ADR-002/008/010 have `## Update` append section pointing to ADR-011 | grep | `grep -l "## Update.*Cleanup" docs/arch/03-adr/ADR-002_*.md docs/arch/03-adr/ADR-008_*.md docs/arch/03-adr/ADR-010_*.md` | ❌ W0 | ⬜ pending |
| 07-02-02 | 02 | 1 | DOCS-01 | — | mockito drift gone from non-ADR docs | grep | `! grep -rn "package:mockito\|@GenerateMocks\|\\.mocks\\.dart" docs/arch/01-core-architecture/ docs/arch/02-module-specs/` | ❌ W0 | ⬜ pending |
| 07-03-01 | 03 | 1 | DOCS-02 | — | All 13 CLAUDE.md pitfalls have enforcement-status annotation | shell | `python3 -c "import re; t=open('CLAUDE.md').read(); section=re.search(r'## Common Pitfalls.+?(?=\n## |\Z)', t, re.S).group(); items=[i for i in re.split(r'\n(?=\d+\. )', section) if re.match(r'\d+\.', i)]; assert len(items)==13; assert all(re.search(r'\\*\\[(Structurally|Partially|Manually-checked) ', i) for i in items)"` | ❌ W0 | ⬜ pending |
| 07-03-02 | 03 | 1 | DOCS-01 | — | `doc/arch/` (singular) path drift fixed in CLAUDE.md + `.claude/rules/arch.md` | grep | `! grep -nE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md` | ❌ W0 | ⬜ pending |
| 07-03-03 | 03 | 1 | DOCS-01 | — | Phantom MOD-014 references gone from CLAUDE.md | grep | `! grep -nE 'MOD-014_i18n\\.md\|MOD-014 i18n\|MOD-014' CLAUDE.md` | ❌ W0 | ⬜ pending |
| 07-04-01 | 04 | 2 | DOCS-03 | — | All INDEX.md links point to existing files | shell | `bash scripts/verify_index_health.sh` | ❌ W0 (Plan 07-04) | ⬜ pending |
| 07-04-02 | 04 | 2 | DOCS-03 | — | `MOD-000_INDEX.md` exists as stub with pointer to ARCH-000 | file + grep | `test -f docs/arch/02-module-specs/MOD-000_INDEX.md && grep -q "ARCH-000_INDEX.md" docs/arch/02-module-specs/MOD-000_INDEX.md` | ❌ W0 | ⬜ pending |
| 07-04-03 | 04 | 2 | DOCS-03 | — | `docs/arch/README.md` no longer references `arch2/` or phantom files | grep | `! grep -nE 'arch2/\|MOD-009_Internationalization\|ARCH-009_I18N_Update_Summary' docs/arch/README.md` | ❌ W0 | ⬜ pending |
| 07-05-01 | 05 | 3 | DOCS-04 | — | `ADR-011_Codebase_Cleanup_Initiative_Outcome.md` exists with required subsections | file + grep | `test -f docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md && for s in "## 背景" "## 决策" "## Cleanup Outcome" "\\*.mocks.dart" "Ongoing CI Enforcement"; do grep -q "$s" docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md \|\| exit 1; done` | ❌ W0 | ⬜ pending |
| 07-05-02 | 05 | 3 | DOCS-04 | — | ADR-000_INDEX.md has ADR-011 entry | grep | `grep -q "ADR-011_Codebase_Cleanup_Initiative_Outcome" docs/arch/03-adr/ADR-000_INDEX.md` | ❌ W0 | ⬜ pending |
| 07-05-03 | 05 | 3 | DOCS-01..04 | — | Final phase gate: full verify-doc-sweep.sh exits 0 | shell | `bash .planning/phases/07-documentation-sweep/verify-doc-sweep.sh` | ❌ W0 | ⬜ pending |
| 07-05-04 | 05 | 3 | (cross) | — | No `lib/` / `test/` / `pubspec` / `.github/` files modified by Phase 7 commits | shell | `git log --name-only main..HEAD docs/arch/ \| grep -cE '^(lib/\|test/\|pubspec\|\\.github/\|analysis_options)' \| grep -q '^0$'` | ✅ (existing CI) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/07-documentation-sweep/verify-doc-sweep.sh` — orchestrator running 6 grep gates from RESEARCH §"Code Examples" (Plan 07-01 first task)
- [ ] `scripts/verify_index_health.sh` — INDEX link/orphan checker (Plan 07-04 first task)
- [ ] (Optional) `scripts/verify_claude_md_pitfalls.sh` — wraps the Python annotation check above into a single-line shell exit code (Plan 07-03 first task; can be inlined into verify-doc-sweep.sh instead)

**No framework install required.** `bash`, `python3`, `grep`, `flutter` already available in the project toolchain.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ADR-011 prose quality (背景/决策/理由) reads correctly to a future contributor | DOCS-04 | Cannot grep-verify rhetorical correctness | Reviewer reads ADR-011 end-to-end and confirms each section answers the implicit question (背景: why now? 决策: what was chosen? 理由: why over alternatives?). Sign-off in PR review. |
| ADR-002/008/010 append sections preserve original decision body | D-06 (CONTEXT.md) | Grep confirms appendix exists but cannot detect rewrites within original section | Reviewer runs `git diff main -- docs/arch/03-adr/ADR-002_Database_Solution.md` and confirms diff is additive only (no `-` lines except trivial reformatting). Sign-off in PR review. |
| Drift fix replacements use idiomatic Markdown | DOCS-01 | Grep confirms stale strings gone but cannot judge replacement quality | Reviewer reads each file's diff in PR; confirms replacement reads naturally and links resolve. |

---

## Validation Sign-Off

- [ ] All 13 task rows above have automated commands (1 row is "manual: PR review" for ADR prose)
- [ ] Sampling continuity: every plan wave has at least one automated grep gate
- [ ] Wave 0 covers all MISSING references (verify-doc-sweep.sh + verify_index_health.sh)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (full suite)
- [ ] `nyquist_compliant: true` set in frontmatter (after Wave 0 scripts land + checker confirms)

**Approval:** pending
