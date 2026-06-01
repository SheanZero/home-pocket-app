---
phase: 33-color-token-system-consolidation
plan: "07"
status: complete
checkpoint: human-verify (pending user visual sign-off)
completed: 2026-06-01
---

# 33-07 SUMMARY — Shim deletion + THEME-V2-02 amend + full suite GREEN

## What was built

Final consolidation of the color token system. After this plan there is a single
theme source of truth (`lib/core/theme/app_palette.dart`); the legacy `AppColors`/
`AppColorsDark` static classes and the `context.wm*` extension are gone.

### Task 1 — delete shim + migrate last consumer
- Deleted `lib/core/theme/app_colors.dart` (AppColors + AppColorsDark).
- Deleted `lib/core/theme/app_theme_colors.dart` (`context.wm*` extension).
- `lib/core/theme/app_theme.dart` already imported `app_palette.dart` (Plan 33-02);
  no remaining shim ref.
- **Gap closed:** `lib/core/initialization/init_failure_screen.dart` was the lone
  external consumer (in `lib/core/`, outside the Wave-2 `lib/features/` scope, so the
  per-folder grep gates never caught it). Migrated `AppColors.background/.textPrimary/
  .textSecondary` → `context.palette.*`, and the hardcoded `Color(0xFF8AB8DA)` retry
  button → `palette.accentPrimary` (teal, the new primary action per ADR-018). Dropped
  `const` on the now-runtime-colored widgets.

### Task 2 — doc amendments + full-suite gate
- `.planning/REQUIREMENTS.md`: THEME-V2-02 struck through and annotated as pulled
  forward into Phase 33 (D-07); traceability row added (`THEME-V2-02 | Phase 33 |
  Pulled forward (D-07)`).
- `.planning/ROADMAP.md` Phase 33: Goal reworded (AppColors → AppPalette), added
  success criterion #5 (full dark-mode rollout, no `isDark` ternaries / `AppColorsDark.*`
  in features), corrected the plan list to **8 plans** (33-05 split into 05a/05b).

## Post-merge / cross-plan remediation handled in this phase
- **`context.palette` getter** made null-safe (brightness-aware fallback to
  `AppPalette.light/.dark`) so lightweight widget-test harnesses render instead of
  throwing — fixed ~427 cascading widget-test failures with zero production impact
  (the app always registers the extension).
- **`joyTargetProgressColor`** gained an `AppPalette` param (33-03); the phase-10
  `home_hero_card_test` was updated to the new signature + `palette.daily→palette.joy`
  endpoints.
- **Golden tagging gap closed:** all 12 `*_golden_test.dart` files tagged
  `@Tags(['golden'])` + added `dart_test.yaml`, so `flutter test --exclude-tags golden`
  actually excludes them. Golden pixel baselines are **untouched** — re-baseline remains
  Phase 34 (COLOR-04).
- **~11 old-palette color assertions** repointed from retired `AppColors`/`AppColorsDark`
  refs to the equivalent `AppPalette.light/.dark` tokens (app_theme, entry dark-mode,
  bottom-nav ×2, trend chart, transaction card, init-failure screen). Two obsolete
  `app_colors_test.dart` files (testing the now-deleted class) deleted — hex coverage is
  provided by `app_palette_test.dart`.

## Verification

| Gate | Result |
|------|--------|
| `flutter analyze` (lib + test) | 0 issues (2 pre-existing `onReorder` deprecation infos, unrelated to color) |
| `flutter test --exclude-tags golden` | **2204 pass / 0 fail** |
| `test/architecture/color_literal_scan_test.dart` (COLOR-01) | GREEN |
| `test/core/theme/app_palette_test.dart` | GREEN (17/17) |
| `test/widget/theme_dark_mode_coverage_test.dart` | GREEN (3/3) |
| `grep Color(0x lib/features lib/application lib/shared` | 0 |
| `grep AppColors.\|AppColorsDark. lib/` | 0 |
| `grep _joyTargetStartColor\|_editDark\|_profileDark\|_onboardingDark lib/` | 0 |

## Pending — human-verify checkpoint (blocking)
Visual light + dark walkthrough on a device/simulator (home hero ring, ledger accents,
analytics success-green, family_sync teal FAB, profile avatar, dark backgrounds `#0C1719`,
WCAG amount-text variants, error toast red). Awaiting user "approved".

## Deferred (out of scope — by design)
- **Golden pixel re-baseline** → Phase 34 (COLOR-04). ~50 golden tests fail on pixel diff
  (expected: palette changed). Now cleanly tag-excluded.
- **2 `onReorder` deprecation infos** in `category_selection_screen.dart` — pre-existing
  Flutter-API tech-debt, unrelated to color tokens.

## Key files
- created: `dart_test.yaml`
- deleted: `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme_colors.dart`,
  `test/unit/core/theme/app_colors_test.dart`, `test/core/theme/app_colors_test.dart`
- modified: `app_theme.dart` (import), `init_failure_screen.dart`, REQUIREMENTS.md,
  ROADMAP.md, 12 golden test files (tag), ~7 test files (assertions)
