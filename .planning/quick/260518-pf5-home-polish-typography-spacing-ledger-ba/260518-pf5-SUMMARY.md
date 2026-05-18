---
quick_id: 260518-pf5
phase: quick
plan: pf5
subsystem: home-ui, analytics-ui, i18n
tags: [typography, spacing, i18n, ledger-bar, satisfaction-icon, cleanup]
completed_date: "2026-05-18T11:18:00Z"
duration_minutes: 57
tasks_completed: 3
tasks_total: 4
files_changed: 20
---

# Quick Task 260518-pf5: Home Polish Bucket A — Summary

**One-liner:** Resolved 7 UI regressions on home screen — typography crowding, grey survival bar, dead coverage caption, hardcoded JA strings in family invite banner, missing satisfaction icon on soul tiles, and analytics top spacing mismatch.

---

## Per-Item Changes

### Item 1 — _hero() spacing (home_hero_card.dart:127-152)
- `SizedBox(height: 4)` between label→amount and amount→subline changed to `SizedBox(height: 8)`
- Gives label / total / previous-month subline visible breathing room

### Item 2a — Split bar ledger labels trimmed (app_zh.arb:94-101, app_en.arb:94-101)
- zh: `soulLedger` "悦己账本" → "悦己"; `survivalLedger` "日常账本" → "日常"
- en: `soulLedger` "Joy Ledger" → "Joy"; `survivalLedger` "Daily Ledger" → "Daily"
- ja values unchanged ("ときめき帳" / "日々の帳" are already short)
- Confirmed single call site (`home_hero_card.dart _splitBar()`) before trimming

### Item 2b — Split bar survival fill color (home_hero_card.dart:215-237)
- Bottom Stack layer changed from `color: context.wmBackgroundDivider` to `color: AppColors.survival`
- When survival > 0, the right segment now shows `#5A9CC8` blue instead of grey

### Item 5 — Coverage caption / "已评分" removed (home_hero_card.dart:500-510; all ARBs)
- Removed `if (happiness.totalSoulTx > 0) ...[homeCoverageCaption(...)]` block from `_legendSingle()`
- Removed `_rated(HappinessReport h)` helper (was only used by the removed block)
- Deleted `homeCoverageCaption` key+metadata from `app_ja.arb`, `app_zh.arb`, `app_en.arb`
- Updated `home_hero_card_test.dart`: thin-sample test no longer asserts `find.textContaining('3/3')`

### Item 6 — Best Joy strip typography (home_hero_card.dart:577-668)
Applied to both `_bestJoyEmpty()` and `_bestJoyValue()`:
- Tag line: `TextStyle(fontSize: 9, ...)` → `AppTextStyles.overline.copyWith(color: AppColors.shared)`
- Middle line: `TextStyle(fontSize: 14, fontWeight: w700)` → `AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w400)`
- Small/amount line: `TextStyle(fontSize: 9, ...)` → `AppTextStyles.caption.copyWith(fontFeatures: [FontFeature.tabularFigures()])`

### Item 7 — Family invite banner i18n (family_invite_banner.dart)
- Added `import '../../../../generated/app_localizations.dart'`
- Added `final l10n = S.of(context)` in `build()`
- Title: hardcoded `'家族と一緒に管理しよう'` → `l10n.homeFamilyBannerTitle`
- Subtitle: hardcoded `'パートナーを招待して...'` → `l10n.homeFamilyBannerSubtitle`
- CTA: hardcoded `'家族を招待する'` → `l10n.homeFamilyInviteTitle` (reused existing key)
- Added 2 new ARB keys to all 3 locales:
  - `homeFamilyBannerTitle`: ja="家族と一緒に管理しよう" / zh="一起管理家庭账本" / en="Manage Together"
  - `homeFamilyBannerSubtitle`: ja="パートナーを招待して、家計簿をリアルタイムで共有しよう" / zh="邀请伴侣，实时共享家庭账本" / en="Invite your partner to share your ledger in real time"

### Item 8a — Remove '-' prefix from expense amounts (home_screen.dart:300-306)
- `_formatAmount()` now returns `formatted` unconditionally (no `'-$formatted'` branch)

### Item 8b — Unify amountColor (home_screen.dart:275)
- Changed `amountColor: isSoul ? AppColors.accentPrimary : context.wmTextPrimary` → `amountColor: context.wmTextPrimary`

### Item 8c — Satisfaction icon on soul tiles (home_screen.dart:308-320, home_transaction_tile.dart)
- Added `_satisfactionIcon(Transaction tx)` helper in `HomeScreen` using ADR-014 icon mapping:
  - v<=2: `Icons.sentiment_neutral_outlined`
  - v<=4: `Icons.sentiment_satisfied_outlined`
  - v<=6: `Icons.sentiment_satisfied_alt_outlined`
  - v<=8: `Icons.sentiment_very_satisfied_outlined`
  - v==10: `Icons.favorite_border`
- Added `satisfactionIcon: IconData?` optional param to `HomeTransactionTile`
- Renders `Icon(satisfactionIcon, size: 14, color: AppColors.soul)` after amount when non-null

### Item 9a — Analytics body top padding (analytics_screen.dart:83)
- Changed `EdgeInsets.symmetric(horizontal: 16, vertical: 24)` → `EdgeInsets.fromLTRB(16, 16, 16, 24)`
- Top gap 24→16px matches home screen's `SizedBox(height: 16)` between HeroHeader and HomeHeroCard

---

## Commits

| Hash | Description |
|------|-------------|
| `8f1369d` | fix(260518-pf5): items 1+2b+5+6 HomeHeroCard typography, splitbar, caption removal |
| `ac3fc4b` | fix(260518-pf5): items 2a+7 ARB ledger label trim and family invite i18n |
| `5b7b6ee` | fix(260518-pf5): items 8+9a recent-tx display fixes and analytics spacing |
| `6d59ef3` | fix(260518-pf5): update duplicate family invite banner test for i18n change [Rule 3] |

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Duplicate test file not covered by plan**
- **Found during:** Full test run after Task 3 commit
- **Issue:** `test/features/home/presentation/widgets/family_invite_banner_test.dart` (a duplicate of the widget test at `test/widget/...`) also used `FamilyInviteBanner` without `localizationsDelegates`, causing `S.of(context)` to throw `Null check operator used on a null value` (7 failures)
- **Fix:** Added `S.localizationsDelegates` + `pumpAndSettle()` + updated hardcoded string assertions to match the new ARB values
- **Files modified:** `test/features/home/presentation/widgets/family_invite_banner_test.dart`
- **Commit:** `6d59ef3`

**2. [Rule 3 - Minor] dart format reformatted main_shell_screen.dart**
- dart format on the `lib/features/home/presentation/` directory reformatted one line-wrapping in `main_shell_screen.dart` (not in plan scope). Left as unstaged — not committed, no behavioral change.

---

## Quality Gate Results

| Gate | Result |
|------|--------|
| `flutter analyze` | PASS — 0 issues |
| `flutter gen-l10n` | PASS — succeeded |
| `dart format` on touched dirs | PASS — no diff on plan-touched files |
| `flutter test` | PASS — 1414 tests, 0 failures |
| Golden images regenerated | PASS — 5 PNGs updated |

---

## Manual Verification Checklist (for human eyes)

The following require a running app:

- [ ] Home hero card: label / total amount / prev-month subline have visually distinct spacing (not crammed)
- [ ] Best Joy strip tag is in a smaller but readable style; middle text is not bold; amount line is caption-sized
- [ ] Split bar: with both soul and survival transactions, the right segment shows blue (#5A9CC8)
- [ ] Split bar: if only survival spending — entire bar is blue; if only soul — entire bar is green gradient
- [ ] No "已评分 n/m" / coverage caption visible anywhere in the ring legend
- [ ] Settings → Language → 中文: family invite banner shows "一起管理家庭账本" and "邀请家人" (no Japanese)
- [ ] Transaction amounts show "¥3,280" without any minus sign
- [ ] Soul row amounts and survival row amounts use the same neutral text color
- [ ] Soul rows show a small satisfaction icon to the right of the amount (neutral/satisfied face)
- [ ] Analytics screen: top gap between AppBar title and first KPI block feels similar to home screen's gap

---

## Notes

**Checkpoint Task 4 (type: checkpoint:human-verify):** Skipped per plan constraints. Task is an app-launch manual verification step; all automated gates pass. User should run the manual verification checklist above against a live build.

**Bucket B Deferred:** Items 3 (Joy formula), 4 (satisfaction ring viz redesign), and 9b (design system doc) are explicitly deferred to ADR-016 (`docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md`).

## Self-Check

Files created/modified:
- [x] `lib/features/home/presentation/widgets/home_hero_card.dart` — FOUND
- [x] `lib/features/home/presentation/widgets/family_invite_banner.dart` — FOUND
- [x] `lib/features/home/presentation/screens/home_screen.dart` — FOUND
- [x] `lib/features/home/presentation/widgets/home_transaction_tile.dart` — FOUND
- [x] `lib/features/analytics/presentation/screens/analytics_screen.dart` — FOUND
- [x] `lib/l10n/app_ja.arb` + `app_zh.arb` + `app_en.arb` — FOUND
- [x] `test/golden/goldens/*.png` (5 files) — FOUND (regenerated)

Commits verified:
- [x] `8f1369d` — FOUND
- [x] `ac3fc4b` — FOUND
- [x] `5b7b6ee` — FOUND
- [x] `6d59ef3` — FOUND

## Self-Check: PASSED
