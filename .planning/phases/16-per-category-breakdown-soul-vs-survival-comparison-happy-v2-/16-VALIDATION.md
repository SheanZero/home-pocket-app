---
phase: 16
slug: per-category-breakdown-soul-vs-survival-comparison-happy-v2-
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-20
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from the `## Validation Architecture` section of `16-RESEARCH.md` (line 1050). Populated by planner during plan generation; finalized before execute-phase.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` 1.x (Dart) — existing project test infrastructure |
| **Config file** | `pubspec.yaml` (dev_dependencies) + `analysis_options.yaml` |
| **Quick run command** | `flutter test --no-pub --concurrency=4 test/features/analytics/ test/application/analytics/ test/data/daos/analytics_dao_per_category_test.dart test/data/daos/analytics_dao_ledger_snapshot_test.dart` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~30–60s for the focused command; full suite per project baseline |

---

## Sampling Rate

- **After every task commit:** Run the per-task `<automated>` block from the relevant PLAN.md, OR the quick run command above when no per-task command is given.
- **After every plan wave:** Run quick command for the wave's touched files.
- **Before `/gsd:verify-work`:** Full suite must be green; `flutter analyze` must report 0 issues; goldens must match.
- **Max feedback latency:** 60s for quick command; ≤5 min for full suite (project baseline).

---

## Per-Task Verification Map

*Populated by gsd-planner during plan generation. Each task gets a row pointing at the test file(s) covering it, with REQ + threat traceability.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | HAPPY-V2-01 / STATSUI-V2-01 | — | descriptive-only copy; no value-judgment language; no per-member projection | TBD | TBD | TBD | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 is **not required** for Phase 16 — `flutter_test` is already installed (`pubspec.yaml`), the project's golden infrastructure is established, and all helpers (`pumpWithLocale`, golden harness, ProviderScope test helpers in `test/helpers/`) already exist. Phase 16 tests slot into the existing infrastructure.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ROADMAP.md SC-3 wording reflects engagement-axis re-frame (D-15) | HAPPY-V2-01 / STATSUI-V2-01 | Documentation change — grep-assertable but not a Dart test | After plan-task commit, run `grep -F "Soul ledger averages" .planning/ROADMAP.md` — must return nothing; `grep -F "engagement metrics" .planning/ROADMAP.md` — must hit Phase 16 SC-3 line. |
| Trilingual visual review of new ARB copy in app at runtime | HAPPY-V2-01 / STATSUI-V2-01 | Native-speaker review of ja/zh strings cannot be substituted by widget tests | Run app with each locale (`flutter run --dart-define=APP_LOCALE=ja|zh|en`), navigate to AnalyticsScreen, confirm new card labels read as descriptive (no "vs"/"対決"/"比較" framing) and category names render correctly via CategoryLocaleService. |
| Light + dark theme golden review | HAPPY-V2-01 / STATSUI-V2-01 (SC-4) | Goldens auto-verify pixel match, but the *first* generation needs human acceptance of the visual design | After initial `flutter test --update-goldens` run, manually inspect the new golden PNGs in `test/features/analytics/widgets/goldens/` to confirm layout matches UI-SPEC.md before committing. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or are listed in Manual-Only Verifications
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (N/A — infrastructure exists)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s (quick) / 5 min (full)
- [ ] `nyquist_compliant: true` set in frontmatter after plans populate the verification map

**Approval:** pending
