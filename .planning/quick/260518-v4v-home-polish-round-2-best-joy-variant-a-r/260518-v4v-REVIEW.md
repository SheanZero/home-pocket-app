---
phase: 260518-v4v
reviewed: 2026-05-18T00:00:00Z
depth: quick
files_reviewed: 7
files_reviewed_list:
  - lib/core/theme/app_colors.dart
  - lib/features/home/presentation/widgets/home_hero_card.dart
  - lib/features/home/presentation/widgets/home_transaction_tile.dart
  - lib/features/home/presentation/screens/home_screen.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# 260518-v4v: Code Review Report

**Reviewed:** 2026-05-18
**Depth:** quick
**Files Reviewed:** 7
**Status:** issues_found

## Summary

Changes implement Best Joy Variant A (cream card, 3-row layout, satisfaction pill), soul-row green coloring in the transaction list, satisfaction icon repositioning inside the category row, home SizedBox 16→24, and 5 new ARB satisfaction-label keys. The structural implementation is sound. Three warnings surfaced: a satisfaction-value boundary edge case in `_satisfactionPillIcon` vs `_satisfactionIcon`, a silent `_splitCurrencySymbol` fallback that will display a malformed amount for currency codes whose format puts the symbol after the number, and a locale-quality issue in `app_ja.arb` `satisfactionLabelGood` containing Simplified Chinese hanzi.

## Warnings

### WR-01: `_satisfactionIcon` boundary differs from `_satisfactionPillIcon` for sat=0

**File:** `lib/features/home/presentation/screens/home_screen.dart:319`
**Issue:** `_satisfactionIcon` (transaction list) uses `if (v <= 2)` as the Neutral branch, identical to `_satisfactionPillIcon` in `home_hero_card.dart:727`. However `soulSatisfaction` is stored as an integer and `0` is a valid DB value (not-yet-rated / default). Both functions will render `Icons.sentiment_neutral_outlined` for `v=0`, which is correct, but the guard `if (tx.ledgerType != LedgerType.soul) return null` at line 318 does not guard against `tx.soulSatisfaction` being `null` — if `Transaction.soulSatisfaction` is nullable and not-yet-set on a soul record, `v <= 2` on a null would be a type error at runtime (Dart null safety: `int <= 2` on `null` throws). Confirm `soulSatisfaction` is always non-null for soul rows; if it is typed `int?`, add a null guard before the comparisons.
**Fix:**
```dart
IconData? _satisfactionIcon(Transaction tx) {
  if (tx.ledgerType != LedgerType.soul) return null;
  final v = tx.soulSatisfaction; // check if this is int or int?
  if (v == null) return null;    // add if nullable
  if (v <= 2) return Icons.sentiment_neutral_outlined;
  ...
}
```

### WR-02: `_splitCurrencySymbol` silently returns `('', formatted)` for suffix-symbol currencies

**File:** `lib/features/home/presentation/widgets/home_hero_card.dart:745-748`
**Issue:** The method finds the index of the first digit with `formatted.indexOf(RegExp(r'\d'))`. For currencies where the symbol trails (e.g. `1,234.56 €` for EUR in some locales), `idx` would be `0`, triggering the `if (idx <= 0)` fallback that returns `('', formatted)` — the entire string as the "number" with an empty symbol. The hero-amount Row then renders the full string in the large `amountLarge` style with an empty small-text prefix. This is cosmetically broken (no symbol visible in the currency column) but not a crash.
**Fix:** Treat suffix symbols explicitly, or check `idx == 0` vs `idx < 0` separately:
```dart
(String, String) _splitCurrencySymbol(String formatted) {
  final idx = formatted.indexOf(RegExp(r'\d'));
  if (idx < 0) return ('', formatted); // no digits at all — fallback
  if (idx == 0) return ('', formatted); // digit-first: symbol is suffix, render whole
  return (formatted.substring(0, idx), formatted.substring(idx));
}
```
The real fix is to detect suffix-symbol locale and render it on the right side, but that requires a layout change. At minimum, document that this component only supports prefix-symbol currencies and add an assertion or comment.

### WR-03: `satisfactionLabelGood` in `app_ja.arb` contains Simplified Chinese characters

**File:** `lib/l10n/app_ja.arb:899`
**Issue:** `"satisfactionLabelGood": "不錯"` — "不錯" is a Simplified Chinese phrase. The Traditional/Simplified Chinese equivalent appears in `app_zh.arb` as "不错". Japanese users would see a foreign-language string on the pill. The Japanese file should use a Japanese term, e.g. "いい感じ", "良い", or "まあまあ" consistent with the existing satisfaction vocabulary in `app_ja.arb` (e.g. `satisfactionGood` = "満足", `satisfactionNormal` = "順調").
**Fix:** Replace `app_ja.arb` line 899:
```json
"satisfactionLabelGood": "いい感じ",
```
(Exact Japanese wording is a product decision; the defect is the Simplified Chinese string appearing in the Japanese locale.)

## Info

### IN-01: `homeBestJoyAmountSat` ARB key retained but now dead

**File:** `lib/l10n/app_ja.arb:714`, `app_zh.arb:713`, `app_en.arb:713`
**Issue:** The key `homeBestJoyAmountSat` (format: `{amount}・満足 {sat}/10 ✨`) is still present in all three ARB files and in the generated localizations. The Variant A rewrite in `home_hero_card.dart` no longer calls this key anywhere — it now uses `_satisfactionPill` with the new `satisfactionLabel*` keys. This is dead translation data. It is not a runtime error, but it leaves stale ARB content that confuses future translators and inflates the generated `app_localizations*.dart` files. Note: the executor SUMMARY already flags this as intentional (referenced in v4v worklog comment on line 546 of `home_hero_card.dart`). Acceptable to leave as-is but worth tracking.
**Fix:** Remove `homeBestJoyAmountSat` from all three ARB files when the key is confirmed unused, then run `flutter gen-l10n`.

### IN-02: `_satisfactionPillIcon` boundary overlap at val=9 with `favorite_border`

**File:** `lib/features/home/presentation/widgets/home_hero_card.dart:726-731`
**Issue:** The icon mapping returns `Icons.favorite_border` for `sat >= 9` (the final `return` after `if (sat <= 8)`). The ADR-014 spec says `Icons.favorite_border` is for `val=10`. Values `sat=9` will also resolve to `Icons.favorite_border`. This matches how `_satisfactionIcon` in `home_screen.dart` is written (same boundary). If the product spec strictly requires `favorite_border` only at exactly 10 and a different icon at 9, this needs a boundary fix. If 9–10 mapping to `favorite_border` is acceptable, the comment should say so. Not a crash, low priority.
**Fix (if strict):**
```dart
if (sat <= 8) return Icons.sentiment_very_satisfied_outlined;
if (sat == 9) return Icons.sentiment_very_satisfied_outlined; // or distinct icon
return Icons.favorite_border; // val == 10
```

---

_Reviewed: 2026-05-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: quick_
