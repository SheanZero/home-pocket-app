---
phase: 43
slug: html-design-gate-no-production-code
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-15
---

# Phase 43 — Validation Strategy

> Per-phase validation contract. **This is a no-code design gate** — there are no
> runnable unit tests. Validation = **gate-exit evidence**: each GATE deliverable
> exists, the ADR-012 self-audit passes, the user approves exactly one direction,
> and the repo has **zero new Dart/production code**. Derived from RESEARCH.md §6.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — design gate, no unit tests. Verification is evidence/inspection-based. |
| **Config file** | none |
| **Quick run command** | `git diff --name-only \| grep -E '\.dart$\|pubspec\.(yaml\|lock)\|/lib/\|/test/'` (must return nothing) |
| **Full suite command** | Browser-open the 10 mock views (5 mock × light/dark) + walk each ADR-012 self-audit table |
| **Estimated runtime** | ~manual (screenshot UAT) |

---

## Sampling Rate

- **After every task commit:** Run the no-Dart guard — `git diff --name-only | grep -E '\.dart$|pubspec\.(yaml|lock)|/lib/|/test/'` must be empty. Any hit BREAKS the gate-exit condition (GATE-03).
- **After the mock-production wave:** `ls .planning/phases/43-html-design-gate-no-production-code/mocks/m*/ | wc -l` ≥ 15 (5 mocks × {light.html, dark.html, adr012-audit.md}).
- **Before gate exit (GATE-03 approval):** No `lib/`/`*.dart`/`pubspec`/Drift changes in `git diff --name-only`; only `.planning/` + `.md` + `.html`.
- **Max feedback latency:** immediate (file-existence + grep, no build).

---

## Per-Task Verification Map

| Req | Wave | Gate-Exit Evidence (verifiable) | Verification Method (no code) | Status |
|-----|------|---------------------------------|-------------------------------|--------|
| GATE-01 | 0 | 现状深研图 `.md` exists with: 17-widget inventory + `MonthlyReport` computed-fields table + 4 structural lock-point file paths | File exists + section check vs RESEARCH.md §1 | ⬜ pending |
| GATE-02 | 1 | 5 mocks each have `{light}.html` + `{dark}.html` + `adr012-audit.md`; every self-audit table has no unresolved ❌ | `ls mocks/m*/` count = 15 + browser-open 10 views + walk each audit table | ⬜ pending |
| GATE-03 | 2 | Main-session record of "user selected Mx + approved"; repo clean of production code | Explicit user approval statement + `git diff --name-only` shows only `.planning/`/`.md`/`.html` | ⬜ pending |
| GATE-04 | 2 | Selected direction's: (a) ADR go/no-go record (= no-go per D-06); (b) locked emotion wordlist `.md` (additions + analytics-only boundary); (c) per-chart fl_chart 1.2.0 affordance verification table (each ✅/❌ mapped back to RESEARCH §3a) | Three docs exist + content check | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red*

---

## Wave 0 Requirements

- [ ] `mocks/shared/sample-data.md` — D-09 shared realistic example data (one family / one month: 日常/悦己 split, Top categories, satisfaction distribution, best joy moment). **Blocks the mock-production wave** — mocks must be comparable, so shared data lands first.
- [ ] GATE-01 现状深研图 `.md` — seeded from RESEARCH.md §1 (widget-granularity reuse map). Independent of mocks; can run in Wave 0.

*No test framework gap — this phase writes no tests.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mock visual/emotional read (light + dark) | GATE-02 | Subjective design read; no automated UI assertion | Browser-open each `{light}.html` and `{dark}.html`, screenshot all 10 views; verify dark uses ADR-019 桜餅×若葉 warm palette |
| ADR-012 self-audit pass per mock | GATE-02 | Human judgement on ambient/celebrate-past (OK) vs target/cross-period/achievement (forbidden) | Walk each mock's `adr012-audit.md` table; every emotional element classified; no forbidden element unresolved |
| User selects exactly one direction + approves | GATE-03 | Gate exit is a human decision | Record explicit user approval of Mx in main session |
| Emotion wordlist sign-off (calm-warm) | GATE-04 | Wordlist locked via user discussion | Confirm `target/目标` analytics-only boundary preserved (ADR-016 allows HomeHero target — do not over-ban) |

---

## Validation Sign-Off

- [ ] GATE-01..04 each have a verifiable evidence artifact (file-existence or recorded approval)
- [ ] Mock-production wave depends on Wave 0 `sample-data.md` (no comparability gap)
- [ ] No-Dart guard wired into per-commit sampling (gate-exit hard condition)
- [ ] No watch-mode / build dependency (design gate)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
