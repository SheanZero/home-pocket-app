---
phase: 10
slug: homepage-soulfullnesscard-redesign
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-02
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test 3.x + mocktail 1.x (already in dev_dependencies) |
| **Config file** | none — `flutter test` discovers `test/**` |
| **Quick run command** | `flutter test test/features/home/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30s quick / ~3-5min full |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/home/` (~30s)
- **After every plan wave:** Run `flutter analyze && flutter test` (full)
- **Before `/gsd-verify-work`:** Full suite must be green AND `flutter analyze` clean
- **Max feedback latency:** ~30s per-task; ~5min per-wave

---

## Per-Task Verification Map

> Populated by gsd-planner. Each row maps a planned task to a concrete automated verification.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/home/widgets/home_hero_card_test.dart` — widget tests for HomeHeroCard composition (single mode, family mode, empty state)
- [ ] `test/features/home/widgets/home_hero_card_golden_test.dart` — golden tests for the 3 ring states (single, family, family-min-N-failure)
- [ ] `test/features/home/widgets/painter/happiness_rings_painter_test.dart` — unit tests for sweep-ratio math and gradient stops
- [ ] `test/features/home/presentation/home_screen_helpers_removed_test.dart` — grep-style assertion that `_computeHappinessROI` and `_computeSatisfaction` are gone
- [ ] `test/helpers/happiness_test_fixtures.dart` — shared `HappinessReport` / `FamilyHappiness` / `BestJoyMomentRow` fixtures including empty/insufficient states

*All entries provisional — gsd-planner finalizes on plan creation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tap target opens AnalyticsScreen "悦己账本" sub-region | HOMEUI-04 | Phase 11 deliverable not yet shipped — Phase 10 lays placeholder route | Phase 10 manual: tap card → log/snackbar fires with target route arg. Phase 11 supersedes. |
| Color/typography polish vs Pencil v8 | HOMEUI-01..03 | Visual contract source is `0502.pen` v8 cards; pixel-exact alignment requires human eyeball + designer review | Compare HomeHeroCard render against `HmvHU` (single light), `NMHwT` (family light), `VKoU4` (family dark) screenshots side-by-side |
| Tooltip copy reads correctly across ja/zh/en | HOMEUI-01 | i18n string fit + line-break per locale needs human read | Run app with `--dart-define=LOCALE=<ja|zh|en>` and tap each ⓘ icon |
| Dark mode contrast for warm-orange `#A86238` story tag | HOMEUI-03 | WCAG sample needs visual confirmation in real device dark theme | Toggle system dark mode, verify Best Joy strip readable on family-mode dark card (`VKoU4`) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (5 test files listed above)
- [ ] No watch-mode flags (`flutter test --no-watch` is default)
- [ ] Feedback latency < 30s for quick command
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
