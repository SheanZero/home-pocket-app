---
phase: 14
slug: adr-016-frontend-arb-reconciliation-tool-v2-02
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-19
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + Flutter golden tests |
| **Config file** | `pubspec.yaml`, `l10n.yaml`, `analysis_options.yaml` |
| **Quick run command** | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart test/unit/data/repositories/settings_repository_impl_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~60s for quick subset, ~3-5 min for full suite |

---

## Sampling Rate

- **After every task commit:** Run the focused test file for the touched surface.
- **After every plan wave:** Run the quick subset plus required grep gates.
- **Before `$gsd-verify-work`:** Full suite, `flutter analyze`, `flutter gen-l10n`, and stale-density grep gates must be green.
- **Max feedback latency:** 60s for quick subset, 5 min for full suite.

---

## Per-Task Verification Map

> Provisional map. Planner should refine task IDs after `14-UI-SPEC.md` exists.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-00-01 | UI-SPEC | 0 | JOYMIG-01, JOYMIG-03, JOYMIG-04, JOYMIG-06, TOOL-V2-02 | T-14-01 | UI design contract blocks gamified/density regressions before implementation | doc | `test -f .planning/phases/14-adr-016-frontend-arb-reconciliation-tool-v2-02/14-UI-SPEC.md` | ❌ W0 | ⬜ pending |
| 14-01-01 | HomeHero data contract | 1 | JOYMIG-01, JOYMIG-03 | T-14-02 | Active target uses configured target, recommendation, or fallback without leaking spend details | widget/unit | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart` | ✅ update | ⬜ pending |
| 14-01-02 | HomeHero ratio math | 1 | JOYMIG-01, JOYMIG-03 | — | Outer ratio is `min(joyContribution / activeTarget, 1.0)` and monthly data resets by selected month | widget/unit | same as 14-01-01 | ✅ update | ⬜ pending |
| 14-02-01 | HomeHero color state | 2 | JOYMIG-04 | — | 0-100% color interpolation is smooth and >=100% freezes at gold | unit/golden | `flutter test test/golden/home_hero_card_golden_test.dart --update-goldens` when intentionally regenerating | ✅ update | ⬜ pending |
| 14-02-02 | 100% no-event contract | 2 | JOYMIG-06 | T-14-03 | No toast, snackbar, haptic, notification, celebration copy, pulse, or `>100%` display | widget + grep | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart` plus `rg -n "SnackBar|HapticFeedback|showDialog|100%|>100%" lib/features/home` reviewed | ✅ update | ⬜ pending |
| 14-03-01 | Settings target UI | 2 | JOYMIG-01, TOOL-V2-02 | T-14-04 | User-configured target persists; blank clears key; recommendation remains neutral reference | widget/unit | `flutter test test/widget/features/settings/presentation/widgets/joy_target_section_test.dart test/unit/data/repositories/settings_repository_impl_test.dart` | ❌ W0 | ⬜ pending |
| 14-03-02 | Settings copy guard | 2 | JOYMIG-06, TOOL-V2-02 | T-14-05 | No comparative/delta/achievement framing around recommendation | grep | `rg -n "higher|lower|above|below|\\+|差|高于|低于|上回|前月|先月" lib/l10n/app_*.arb` reviewed for target-key cluster | N/A | ⬜ pending |
| 14-04-01 | Analytics Joy Index KPI | 3 | TOOL-V2-02 | — | Primary Joy KPI displays `joyContribution`, not average satisfaction or density | widget | `flutter test test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart` | ✅ update | ⬜ pending |
| 14-04-02 | Analytics ordering/copy | 3 | TOOL-V2-02 | — | KPI mini-hero order and labels match UI-SPEC; density UI remains deleted | widget/grep | `flutter test test/widget/features/analytics/` plus stale-density grep | ✅ update | ⬜ pending |
| 14-05-01 | ARB reconciliation | 4 | TOOL-V2-02 | — | ja/zh/en parity; generated localization reflects JoyContribution vocabulary | gen/grep | `flutter gen-l10n` and `rg -n "joyPerYen|homeHappinessROI" lib/ --glob '*.dart'` returns 0 | ✅ update | ⬜ pending |
| 14-05-02 | Final verification | 5 | all | all | Full phase behavior passes static, generated, widget, and grep gates | full | `dart format . && flutter analyze && flutter test` | N/A | ⬜ pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `.planning/phases/14-adr-016-frontend-arb-reconciliation-tool-v2-02/14-UI-SPEC.md` — required by enabled UI safety gate before PLAN.md.
- [ ] `test/widget/features/settings/presentation/widgets/joy_target_section_test.dart` — target setting widget tests.
- [ ] HomeHero fixtures for 0%, 50%, 100%, and >100% Joy target states.
- [ ] Golden filenames for 0%, 50%, 100%, and >100% HomeHero states.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| HomeHero 0/50/100/>100 goldens read as ambient progress, not celebration | JOYMIG-04, JOYMIG-06 | Visual judgment needed for color/weight/regression review | Review regenerated PNGs in `test/golden/goldens/`; verify no pulse/copy/percent/overflow and >100% stays full gold |
| Settings target copy in ja/zh/en is natural and non-comparative | TOOL-V2-02, JOYMIG-06 | Register and nuance cannot be fully asserted by grep | Read target-key cluster in all three ARB files; confirm recommendation is reference-only |
| Analytics Variant epsilon hierarchy feels coherent | TOOL-V2-02 | KPI hierarchy is visual and depends on UI-SPEC | Run widget/golden or app preview and confirm Joy Index primary ordering per UI-SPEC |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers missing target-section tests, HomeHero target fixtures, and UI-SPEC.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 60s for focused subset.
- [ ] `nyquist_compliant: true` set in frontmatter after planner-checker passes.
- [ ] Stale density/Joy-per-yen grep gates are included in PLAN.md acceptance criteria.

**Approval:** pending

