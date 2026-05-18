---
phase: 260518-pf5
reviewed: 2026-05-18T12:00:00Z
depth: quick
files_reviewed: 11
files_reviewed_list:
  - lib/features/home/presentation/screens/home_screen.dart
  - lib/features/home/presentation/widgets/home_hero_card.dart
  - lib/features/home/presentation/widgets/home_transaction_tile.dart
  - lib/features/home/presentation/widgets/family_invite_banner.dart
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
  - test/widget/features/home/presentation/widgets/home_hero_card_test.dart
  - test/widget/features/home/presentation/widgets/family_invite_banner_test.dart
  - test/features/home/presentation/widgets/family_invite_banner_test.dart
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Quick Task 260518-pf5: Code Review Report

**Reviewed:** 2026-05-18T12:00:00Z
**Depth:** quick (advisory)
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Reviewed typography polish, i18n, split-bar color fix, coverage-caption removal, satisfaction-icon addition, and analytics-spacing changes. Scope discipline is clean — no Joy formula changes, no ring-math changes, no new `docs/` files. All three ARB files updated atomically; `homeCoverageCaption` is absent from all three; both test files carry `S.localizationsDelegates` and `pumpAndSettle()`; the `3/3` assertion is gone from the hero-card test.

Two quality warnings and one informational item found.

## Warnings

### WR-01: `_formatAmount` bypasses `FormatterService` — hardcoded `¥` symbol and no locale

**File:** `lib/features/home/presentation/screens/home_screen.dart:296-301`
**Issue:** `_formatAmount` calls `NumberFormat.currency(symbol: '¥', decimalDigits: 0)` directly. This hardcodes JPY formatting regardless of the book's `currencyCode` and the current `locale`. Item 8a only removed the `'-'` prefix from this function — it left the locale/currency bypass intact, and the task introduced `satisfactionIcon` wiring that passes through the same `_formatAmount` call. The surrounding build already has `currencyCode` and `locale` in scope (lines 93, 42). CLAUDE.md mandates `NumberFormatter` / `FormatterService` for all monetary values.

**Fix:**
```dart
String _formatAmount(Transaction tx, String currencyCode, Locale locale) {
  return const FormatterService().formatCurrency(tx.amount, currencyCode, locale);
}
// call site:
formattedAmount: _formatAmount(tx, currencyCode, locale),
```

### WR-02: `_memberInitial` dead method — referenced only in group-mode tag, but the tagged block it feeds is inside a non-group `isSoul` branch

**File:** `lib/features/home/presentation/screens/home_screen.dart:250, 315-318`
**Issue:** `_memberInitial(tx)` is called at line 250 inside the `tagText` ternary. In practice this is for group mode (`isGroupMode` branch), so it executes, but the implementation uses `tx.deviceId[0]` as a placeholder with a `// real member data TBD` comment. This is not new code (pre-existing stub), but it was not removed/cleaned as part of this task and remains dead-end logic that emits device-ID initials instead of member names — a user-visible data quality defect in group mode.

**Fix:** Either replace with proper member-display-name lookup (the `ShadowBookInfo` objects already carry `memberDisplayName`) or gate the group-mode tag path behind a different data source. Minimum: remove the `TODO`-equivalent comment; maximum: wire `ShadowBookInfo.memberDisplayName` properly.

## Info

### IN-01: `homeFamilyBannerSubtitle` zh value inconsistency with SUMMARY

**File:** `lib/l10n/app_zh.arb:577`
**Issue:** SUMMARY states the zh subtitle should be "邀请伴侣，实时共享家庭账本" — the ARB file contains exactly that value. No defect. However, the duplicate `test/features/.../family_invite_banner_test.dart` does not assert the subtitle text (only title and CTA), leaving the subtitle untested in the lower test file. The `test/widget/.../family_invite_banner_test.dart` does assert it. Coverage gap is minor but worth noting given this was a BLOCKER-2 fix.

**Fix:** Add a `shows subtitle text` test case to `test/features/.../family_invite_banner_test.dart` mirroring the widget-test file for parity.

---

## Checklist Results (per review brief)

| Check | Result |
|---|---|
| Scope: no Joy/ring formula changes | PASS — ring section untouched |
| Typography: `AppTextStyles` tokens used | PASS — `amountLarge/amountSmall/amountMedium` used throughout; `AppTextStyles.caption` + explicit `FontFeature.tabularFigures()` in Best Joy strip |
| `amountSmall` includes tabularFigures by default | PASS — `app_text_styles.dart` line 167 confirms built-in |
| i18n atomic update (3 ARBs) | PASS — all 3 updated |
| `homeCoverageCaption` removed from all 3 ARBs | PASS — absent from ja/zh/en |
| No hardcoded strings in changed widgets | PASS — `family_invite_banner.dart` fully i18n'd |
| ADR-014 icon mapping matches `satisfaction_emoji_picker.dart` | PASS — identical 5-step mapping, identical `_faceValues` breakpoints (≤2/≤4/≤6/≤8/10) |
| Split bar survival color = `AppColors.survival` | PASS — line 219 uses token, no literal |
| `AsyncValue.value` nullable risk | N/A — no new `.value` reads added in this diff |
| Test BLOCKER-2: `localizationsDelegates` + `pumpAndSettle` | PASS — both test files updated |
| Test BLOCKER-2: `3/3` assertion removed | PASS — absent from hero-card test |
| Dead code from item 5 (`_rated`, caption block) | PASS — fully removed; `_legendSingle` still present (correct, it's the legend container) |

---

_Reviewed: 2026-05-18T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: quick_
