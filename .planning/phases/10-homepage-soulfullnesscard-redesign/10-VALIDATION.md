---
phase: 10
slug: homepage-soulfullnesscard-redesign
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-02
populated: 2026-05-02
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Per-task map populated from PLAN.md task IDs across 13 plans.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test 3.x + mocktail 1.x (already in dev_dependencies) |
| **Config file** | none — `flutter test` discovers `test/**` |
| **Quick run command** | `flutter test test/widget/features/home/ test/golden/home_hero_card_golden_test.dart` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~30s quick / ~3-5min full |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/widget/features/home/` (~30s)
- **After every plan wave:** Run `flutter analyze && flutter test` (full)
- **Before `/gsd-verify-work`:** Full suite must be green AND `flutter analyze` clean across `lib/`
- **Max feedback latency:** ~30s per-task; ~5min per-wave

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-1 | 01 | 1 | HOMEUI-05/06/07 + FAMILY-03 | — | N/A (spec doc) | grep | `grep -q "HOMEUI-05\|HOMEUI-06\|HOMEUI-07" .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 10-02-1 | 02 | 1 | — (spec doc) | — | N/A (spec doc) | grep | `grep -q "Phase 10:" .planning/ROADMAP.md && grep -A20 "Phase 10:" .planning/ROADMAP.md \| grep -q "HomeHeroCard"` | ✅ | ⬜ pending |
| 10-03-1 | 03 | 2 | — (test fixtures) | — | N/A | unit | `flutter test test/helpers/happiness_test_fixtures.dart 2>&1 \| grep -q "All tests passed!"` | ❌ W0 | ⬜ pending |
| 10-03-2 | 03 | 2 | HOMEUI-01 | — | N/A | unit | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart 2>&1 \| grep -q "tests passed\|skipped"` | ❌ W0 | ⬜ pending |
| 10-03-3 | 03 | 2 | HOMEUI-01,03 | — | N/A | unit + golden | `flutter test test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart test/golden/home_hero_card_golden_test.dart 2>&1 \| grep -q "tests passed\|skipped"` | ❌ W0 | ⬜ pending |
| 10-03-4 | 03 | 2 | HOMEUI-02 | T-10-05 | Permanent CI regression for deleted helpers | unit | `flutter test test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart 2>&1 \| grep -q "All tests passed!"` | ❌ W0 | ⬜ pending |
| 10-04-1 | 04 | 2 | HOMEUI-04 | — | All ARB strings present in 3 locales | grep | `grep -q "homeJoyIndexTooltip" lib/l10n/app_ja.arb && grep -q "homeJoyIndexTooltip" lib/l10n/app_zh.arb && grep -q "homeJoyIndexTooltip" lib/l10n/app_en.arb` | ✅ (files exist) | ⬜ pending |
| 10-04-2 | 04 | 2 | HOMEUI-04 | — | gen-l10n produces accessor | grep + analyze | `flutter gen-l10n && grep -q "homeJoyIndexTooltip" lib/generated/app_localizations.dart && flutter analyze lib/generated/ \| grep -q "No issues"` | ✅ (after 10-04-1) | ⬜ pending |
| 10-05-1 | 05 | 2 | — (provider scaffold) | — | bookByIdProvider available | grep | `grep -q "bookByIdProvider" lib/features/accounting/presentation/providers/repository_providers.dart` | ✅ | ⬜ pending |
| 10-05-2 | 05 | 2 | — | — | Codegen succeeds | analyze | `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze lib/features/accounting/ \| grep -q "No issues"` | ✅ | ⬜ pending |
| 10-06-1 | 06 | 3 | HOMEUI-01, HOMEUI-03 | — | CustomPainter pure logic | unit | `flutter test test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart 2>&1 \| grep -q "All tests passed!"` | ❌ W0 (Plan 10-03 skel) | ⬜ pending |
| 10-06-2 | 06 | 3 | HOMEUI-01, HOMEUI-03 | — | Painter math + gradient stops | unit | `flutter test test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart --plain-name "sweep" 2>&1 \| grep -q "passed"` | ❌ W0 (10-03 skel populated by 10-06) | ⬜ pending |
| 10-07a-1 | 07a | 4 | HOMEUI-01, HOMEUI-03, HOMEUI-04 | T-10-03, T-10-05 | Sealed pattern matching, no JPY literal | analyze + grep | `flutter analyze lib/features/home/presentation/widgets/home_hero_card.dart \| grep -q "No issues found" && [ "$(grep -c "'JPY'" lib/features/home/presentation/widgets/home_hero_card.dart)" = "0" ]` | ❌ W0 | ⬜ pending |
| 10-07b-1 | 07b | 4 | HOMEUI-01, HOMEUI-03, HOMEUI-04, FAMILY-03 | T-10-06, T-10-07, T-10-08, T-10-09 | _InfoIcon HitTestBehavior.opaque, FAMILY-03 minimum gate | analyze + grep | `flutter analyze lib/features/home/presentation/widgets/home_hero_card.dart \| grep -q "No issues found" && [ "$(grep -c "_InfoIcon(" lib/features/home/presentation/widgets/home_hero_card.dart)" = "2" ] && grep -q "HitTestBehavior.opaque" lib/features/home/presentation/widgets/home_hero_card.dart` | ❌ W0 | ⬜ pending |
| 10-08a-1 | 08a | 5 | HOMEUI-05, HOMEUI-06, HOMEUI-07, FAMILY-03 | T-10-05 | JPY fallback comment marker present | grep + analyze | `grep -q "Pitfall #9\|fallback only when Book is missing" lib/features/home/presentation/screens/home_screen.dart && grep -q "HomeHeroCard(" lib/features/home/presentation/screens/home_screen.dart && flutter analyze lib/features/home/presentation/screens/home_screen.dart \| grep -q "No issues"` | ✅ | ⬜ pending |
| 10-08b-1 | 08b | 5 | HOMEUI-02 | — | 3 helpers deleted, no resurrection | grep + line count | `! grep -q "_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows" lib/ && [ "$(wc -l < lib/features/home/presentation/screens/home_screen.dart)" -lt 350 ] && flutter analyze lib/features/home/ \| grep -q "No issues found"` | ✅ | ⬜ pending |
| 10-09-1 | 09 | 6 | HOMEUI-01 | — | Old widgets gone, no consumers remaining | grep + ls | `! ls lib/features/home/presentation/widgets/soul_fullness_card.dart 2>/dev/null && ! ls lib/features/home/presentation/widgets/month_overview_card.dart 2>/dev/null && ! ls lib/features/home/presentation/widgets/ledger_comparison_section.dart 2>/dev/null && ! grep -rq "MonthOverviewCard\|LedgerComparisonSection\|SoulFullnessCard" lib/` | ✅ (files currently exist; plan deletes them) | ⬜ pending |
| 10-09-2 | 09 | 6 | HOMEUI-01 | — | Obsolete tests removed | unit + ls | `! ls test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart 2>/dev/null && ! ls test/widget/features/home/presentation/widgets/month_overview_card_test.dart 2>/dev/null && ! ls test/golden/soul_fullness_card_golden_test.dart 2>/dev/null && flutter test test/widget/features/home/presentation/screens/home_screen_test.dart 2>&1 \| grep -qE "All tests passed!"` | ✅ (current tests exist; plan deletes them) | ⬜ pending |
| 10-10-1 | 10 | 7 | HOMEUI-01, HOMEUI-03, HOMEUI-04, FAMILY-03 | T-10-06, T-10-07 | Widget tests cover all 8 regions + empty states | unit | `flutter test test/widget/features/home/presentation/widgets/home_hero_card_test.dart 2>&1 \| grep -qE "All tests passed!"` | ❌ W0 (10-03 skel populated by 10-10) | ⬜ pending |
| 10-10-2 | 10 | 7 | HOMEUI-01, HOMEUI-03 | — | 5 golden states render correctly | golden | `flutter test test/golden/home_hero_card_golden_test.dart 2>&1 \| grep -qE "All tests passed!"` | ❌ W0 (10-03 skel populated by 10-10) | ⬜ pending |
| 10-10-3 | 10 | 7 | HOMEUI-01 | — | Per-file coverage ≥ 70% | coverage | `flutter test --coverage test/widget/features/home/ && lcov --extract coverage/lcov.info 'lib/features/home/presentation/widgets/home_hero_card.dart' --output-file coverage/home_hero_card.info && lcov --summary coverage/home_hero_card.info \| grep -E "lines.*[7-9][0-9]\.[0-9]%\|lines.*100\.0%"` | ✅ | ⬜ pending |
| 10-11-1 | 11 | 8 | — | — | Hex literals replaced with tokens | grep | `! grep -E "Color\(0x[fF][fF][0-9a-fA-F]{6}\)" lib/features/home/presentation/widgets/home_hero_card.dart \| grep -v "warm-orange #A86238\|TODO" \| grep -q "."` | ✅ | ⬜ pending |
| 10-11-2 | 11 | 8 | — | — | Goldens regenerated to match polished colors | golden | `flutter test test/golden/home_hero_card_golden_test.dart 2>&1 \| grep -qE "All tests passed!"` | ✅ | ⬜ pending |
| 10-11-3 | 11 | 8 | — | — | Manual visual checkpoint vs Pencil v8 (HmvHU/NMHwT/VKoU4) | manual | (see Manual-Only Verifications) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Sampling continuity audit:** No 3 consecutive tasks lack automated verify. Tasks 10-11-3 (manual) is followed by Wave 8 close-out — the only manual task; preceded by 10-11-2 (automated) and is the final task of the phase.

---

## Wave 0 Requirements

- [ ] `test/helpers/happiness_test_fixtures.dart` — shared `HappinessReport` / `FamilyHappiness` / `BestJoyMomentRow` / `MonthlyReport` / `ShadowBookInfo` / `ShadowAggregate` factories covering Empty, Value(thin), Value(rich), all-neutral cases (Plan 10-03 Task 3.1)
- [ ] `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` — skeleton widget tests for HomeHeroCard composition (single mode, family mode, empty state) (Plan 10-03 Task 3.2 → populated by Plan 10-10 Task 10.1)
- [ ] `test/golden/home_hero_card_golden_test.dart` — skeleton golden tests for the 5 ring states (Plan 10-03 Task 3.3 → populated by Plan 10-10 Task 10.2)
- [ ] `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` — skeleton unit tests for sweep-ratio math and gradient stops (Plan 10-03 Task 3.3 → populated by Plan 10-06 Task 6.2)
- [ ] `test/widget/features/home/presentation/screens/home_screen_helpers_removed_test.dart` — **permanent** CI regression test asserting `_computeHappinessROI` / `_computeSatisfaction` / `_buildLedgerRows` are absent from `home_screen.dart` source (Plan 10-03 Task 3.4 — added per checker B1 fix)

*All entries created in Plan 10-03 (Wave 2). The `home_screen_helpers_removed_test.dart` entry is the new B1 fix — addresses the Wave 0 list completeness gap from the checker findings.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tap target opens AnalyticsScreen "悦己账本" sub-region | HOMEUI-04 | Phase 11 deliverable not yet shipped — Phase 10 lays placeholder route to AnalyticsScreen(bookId) | Phase 10 manual: tap card → AnalyticsScreen pushes (no enum). Phase 11 supersedes. |
| Color/typography polish vs Pencil v8 | HOMEUI-01..03 | Visual contract source is `0502.pen` v8 cards; pixel-exact alignment requires human eyeball + designer review | Compare HomeHeroCard render against `HmvHU` (single light), `NMHwT` (family light), `VKoU4` (family dark) screenshots side-by-side (Plan 10-11 Task 11.3) |
| Tooltip copy reads correctly across ja/zh/en | HOMEUI-01 | i18n string fit + line-break per locale needs human read | Run app with `--dart-define=LOCALE=<ja\|zh\|en>` and tap each ⓘ icon |
| Dark mode contrast for warm-orange `#A86238` story tag | HOMEUI-03 | WCAG sample needs visual confirmation in real device dark theme | Toggle system dark mode, verify Best Joy strip readable on family-mode dark card (`VKoU4`) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (24 tasks mapped; 1 manual at 10-11-3 — final task, accompanied by automated golden regen at 10-11-2)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all 5 MISSING references (helpers_removed_test added per checker B1)
- [x] No watch-mode flags (`flutter test` is one-shot by default)
- [x] Feedback latency < 30s for quick command
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-02 (per checker findings B1 + B2 resolved)
