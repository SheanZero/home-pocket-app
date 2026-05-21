---
phase: 16
slug: per-category-breakdown-soul-vs-survival-comparison-happy-v2-
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
updated_by_planner: 2026-05-20
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from the `## Validation Architecture` section of `16-RESEARCH.md` (line 1050). Populated by planner during plan generation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` 1.x (Dart) — existing project test infrastructure |
| **Config file** | `pubspec.yaml` (dev_dependencies) + `analysis_options.yaml` |
| **Quick run command** | `flutter test --no-pub --concurrency=4 test/unit/features/analytics/domain/models/ test/unit/data/daos/analytics_dao_per_category_test.dart test/unit/data/daos/analytics_dao_ledger_snapshot_test.dart test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart test/unit/application/analytics/get_per_category_soul_breakdown_across_books_use_case_test.dart test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart test/unit/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case_test.dart test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart test/golden/per_category_breakdown_card_golden_test.dart test/golden/soul_vs_survival_card_golden_test.dart test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~45-90s for the focused command; full suite per project baseline |

---

## Sampling Rate

- **After every task commit:** Run the per-task `<automated>` block from the relevant PLAN.md, OR the quick run command above when no per-task command is given.
- **After every plan wave:** Run quick command for the wave's touched files.
- **Before `/gsd:verify-work`:** Full suite must be green; `flutter analyze` must report 0 issues; goldens must match.
- **Max feedback latency:** 90s for quick command; ≤5 min for full suite (project baseline).

---

## Per-Task Verification Map

*Populated by gsd-planner during plan generation. Each task gets a row pointing at the test file(s) covering it, with REQ + threat traceability.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-T1 | 16-01 | 0 | HAPPY-V2-01 / STATSUI-V2-01 | — | doc correction (engagement-axis re-frame) | grep | `! grep -F "Soul ledger averages 7.4 satisfaction" .planning/ROADMAP.md && grep -F "engagement metrics" .planning/ROADMAP.md` | doc edit | ⬜ pending |
| 16-02-T1 | 16-02 | 1 | HAPPY-V2-01 / STATSUI-V2-01 | T-locale (locked ARB parity) | trilingual ARB parity + no forbidden substrings | grep + flutter gen-l10n | `flutter gen-l10n && for k in <17 keys>; do n=$(grep -l -F "\"$k\"" lib/l10n/app_*.arb | wc -l); test "$n" = "3"; done` | ⬜ Wave 1 NEW | ⬜ pending |
| 16-03-T1 | 16-03 | 1 | HAPPY-V2-01 | — | Freezed equality + copyWith | unit | `flutter test test/unit/features/analytics/domain/models/per_category_soul_breakdown_test.dart` | ⬜ Wave 1 NEW | ⬜ pending |
| 16-03-T2 | 16-03 | 1 | STATSUI-V2-01 | T-D04-typegate (SurvivalLedgerSnapshot has no avgSatisfaction) | D-04 type-system gate — Survival snapshot cannot carry satisfaction | unit | `flutter test test/unit/features/analytics/domain/models/ledger_snapshot_test.dart && awk '/class.*SurvivalLedgerSnapshot/,/^}/' lib/features/analytics/domain/models/ledger_snapshot.dart | grep -c avgSatisfaction == 0` | ⬜ Wave 1 NEW | ⬜ pending |
| 16-04-T1 | 16-04 | 1 | HAPPY-V2-01 / STATSUI-V2-01 | T-SQLI (Drift parameterized vars); T-ADR012-leaderboard (no GROUP BY book_id) | parameterized queries; soul-only filter; family aggregate via book_id IN (...) | unit | `flutter test test/unit/data/daos/analytics_dao_per_category_test.dart test/unit/data/daos/analytics_dao_ledger_snapshot_test.dart && ! grep "GROUP BY book_id" lib/data/daos/analytics_dao.dart` | ⬜ Wave 1 NEW | ⬜ pending |
| 16-04-T2 | 16-04 | 1 | HAPPY-V2-01 / STATSUI-V2-01 | — | repository delegation contract | unit (via analyze) | `flutter analyze lib/features/analytics/domain/repositories/analytics_repository.dart lib/data/repositories/analytics_repository_impl.dart` | repo files exist | ⬜ pending |
| 16-05-T1 | 16-05 | 1 | HAPPY-V2-01 | T-D05-emptygate; T-window-validation | TimeWindowValidation guard; min-N + Other rollup; tie-break sort | unit | `flutter test test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart test/unit/application/analytics/get_per_category_soul_breakdown_across_books_use_case_test.dart` | ⬜ Wave 1 NEW | ⬜ pending |
| 16-05-T2 | 16-05 | 1 | STATSUI-V2-01 | T-D04-provenance (avg only from soul-scoped query); T-D05-emptygate | D-05 either-ledger-zero → Empty; D-04 soul-only avg provenance; TimeWindowValidation guard | unit | `flutter test test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart test/unit/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case_test.dart` | ⬜ Wave 1 NEW | ⬜ pending |
| 16-06-T1 | 16-06 | 1 | HAPPY-V2-01 / STATSUI-V2-01 | — | use case provider wiring | analyze + build_runner | `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze lib/features/analytics/presentation/providers/` | provider file exists | ⬜ pending |
| 16-06-T2 | 16-06 | 1 | HAPPY-V2-01 / STATSUI-V2-01 | T-D20-familygate | family providers short-circuit on shadowBooks.length < 2 | analyze + build_runner | `flutter pub run build_runner build && grep "groupBookIds.length < 2" lib/features/analytics/presentation/providers/state_ledger_snapshot.dart` | ⬜ Wave 1 NEW | ⬜ pending |
| 16-07-T1 | 16-07 | 2 | HAPPY-V2-01 | — | widget chrome + state matrix conformance | analyze | `flutter analyze lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart` | widget file exists | ⬜ pending |
| 16-07-T2 | 16-07 | 2 | HAPPY-V2-01 | T-state-coverage (all 6 UI-SPEC states) | widget state coverage + interaction (Show all toggle) | widget | `flutter test test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart` | ⬜ Wave 2 NEW | ⬜ pending |
| 16-07-T3 | 16-07 | 2 | HAPPY-V2-01 (SC-4) | T-visual-regression | golden parity light + dark + group | golden | `flutter test test/golden/per_category_breakdown_card_golden_test.dart` | ⬜ Wave 2 NEW | ⬜ pending |
| 16-08-T1 | 16-08 | 2 | STATSUI-V2-01 | T-D04-typegate; T-D05-emptygate; T-D20-familygate | widget chrome + state matrix conformance; D-04/D-05/D-20 structural enforcement | analyze | `flutter analyze lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart && ! grep "survival.avgSatisfaction" lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` | widget file exists | ⬜ pending |
| 16-08-T2 | 16-08 | 2 | STATSUI-V2-01 | T-D04-typegate; T-D05-emptygate; T-D20-familygate | widget rendering of all states + D-04 single-avg-sat assertion | widget | `flutter test test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart` | ⬜ Wave 2 NEW | ⬜ pending |
| 16-08-T3 | 16-08 | 2 | STATSUI-V2-01 (SC-4) | T-visual-regression | golden parity light + dark + group | golden | `flutter test test/golden/soul_vs_survival_card_golden_test.dart` | ⬜ Wave 2 NEW | ⬜ pending |
| 16-09-T1 | 16-09 | 2 | HAPPY-V2-01 / STATSUI-V2-01 | T-D14-antitox (trilingual forbidden-substring sweep) | rendered card output free of forbidden substrings in all 3 locales × 4 states | widget | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` | ⬜ Wave 2 NEW | ⬜ pending |
| 16-10-T1 | 16-10 | 2 | HAPPY-V2-01 / STATSUI-V2-01 | T-D12-homehero-isolation | Distribution composition correct; _refresh() extended; D-12 binding preserved | analyze + grep | `flutter analyze lib/features/analytics/presentation/screens/analytics_screen.dart && grep D-12 lib/features/analytics/presentation/screens/analytics_screen.dart && ! grep "ref.invalidate(homeHero" lib/features/analytics/presentation/screens/analytics_screen.dart` | screen file exists | ⬜ pending |
| 16-10-T2 | 16-10 | 2 | HAPPY-V2-01 / STATSUI-V2-01 | T-D12-homehero-isolation | Phase 16 providers never called with HomeHero's current-month keys | widget | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | ⬜ Phase 15 EXTEND | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 is **not required** for Phase 16 — `flutter_test` is already installed (`pubspec.yaml`), the project's golden infrastructure is established, and all helpers (`createLocalizedWidget`, golden harness, ProviderScope test helpers in `test/helpers/`) already exist. Phase 16 tests slot into the existing infrastructure.

Wave 0 in this phase consists of the doc-only ROADMAP SC-3 wording correction (Plan 16-01) — this is a documentation gate, not a test-infrastructure gate. Plans 02-10 may proceed in parallel with 16-01 since 16-01 has no runtime dependencies.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ROADMAP.md SC-3 wording reflects engagement-axis re-frame (D-15) | HAPPY-V2-01 / STATSUI-V2-01 | Documentation change — grep-assertable but not a Dart test | After Plan 16-01 commit, run `grep -F "Soul ledger averages" .planning/ROADMAP.md` — must return nothing; `grep -F "engagement metrics" .planning/ROADMAP.md` — must hit Phase 16 SC-3 line. |
| Trilingual visual review of new ARB copy in app at runtime | HAPPY-V2-01 / STATSUI-V2-01 | Native-speaker review of ja/zh strings cannot be substituted by widget tests | Run app with each locale (`flutter run --dart-define=APP_LOCALE=ja|zh|en`), navigate to AnalyticsScreen, confirm new card labels read as descriptive (no "vs"/"対決"/"比較" framing) and category names render correctly via CategoryLocalizationService. |
| Light + dark theme golden review | HAPPY-V2-01 / STATSUI-V2-01 (SC-4) | Goldens auto-verify pixel match, but the *first* generation needs human acceptance of the visual design | After initial `flutter test --update-goldens` run (Plans 16-07 + 16-08), manually inspect the 7 new golden PNGs under `test/golden/goldens/` to confirm layout matches UI-SPEC.md before committing. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are listed in Manual-Only Verifications
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every task has either a `flutter test` or a `flutter analyze` + grep gate)
- [x] Wave 0 covers all MISSING references (N/A — infrastructure exists; doc-only Plan 16-01 is the Wave 0 deliverable)
- [x] No watch-mode flags
- [x] Feedback latency < 90s (quick) / 5 min (full)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ✅ planner-locked 2026-05-20
