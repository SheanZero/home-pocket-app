# D-08 Hardcoded String Inventory — Phase 30

**Date:** 2026-05-31
**Scope:** App-wide grep outside lib/features/list/ (except where noted as already resolved)
**Purpose:** Deferred to future i18n-cleanup phase per decision D-08

---

## Resolved (fixed this phase in Plan 30-02)

| File | Line | String | Decision |
|------|------|--------|----------|
| `lib/features/list/presentation/screens/list_screen.dart:101` | 101 | `'[data load error]'` | → `listLoadError` ARB key (D-12) |
| `lib/features/list/presentation/widgets/list_calendar_header.dart:221` | 221 | `'Previous month'` | → `listCalNavPrev` ARB key (D-13) |
| `lib/features/list/presentation/widgets/list_calendar_header.dart:235` | 235 | `'Return to current month'` | → `listCalNavCurrentMonth` ARB key (D-13) |
| `lib/features/list/presentation/widgets/list_calendar_header.dart:252` | 252 | `'Next month'` | → `listCalNavNext` ARB key (D-13) |

---

## In-Scope Findings — lib/features/list/ (not yet fixed)

These Semantics labels exist in `list_sort_filter_bar.dart` and were not included in the Phase 30 research scope. They are user-visible accessibility strings that require ARB key additions + gen-l10n.

| File | Line | String | Disposition |
|------|------|--------|-------------|
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 156 | `'Sort by'` | deferred — needs ARB key |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 183 | `'Descending'` | deferred — needs ARB key |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 184 | `'Ascending'` | deferred — needs ARB key |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 210 | `'Show all ledgers'` | deferred — needs ARB key |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 238 | `'Survival ledger'` | deferred — needs ARB key |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 271 | `'Soul ledger'` | deferred — needs ARB key |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 304 | `'Filter by category'` | deferred — needs ARB key |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 412 | `'Search transactions'` | deferred — needs ARB key |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | 496 | `'Clear all filters'` | deferred — needs ARB key |

**Note:** These strings are Semantics `label:` values (accessibility), not visible text. They follow the same D-13 pattern as the calendar nav labels fixed in this phase.

---

## App-Wide Findings (outside lib/features/list/)

### Technical Constants (non-i18n — correct as-is)

These are currency code constants, font family strings, or internal error strings — not user-visible UI copy candidates:

| File | Line | String | Disposition |
|------|------|--------|-------------|
| `lib/core/theme/app_theme.dart` | 11, 32 | `'Outfit'` | non-i18n: font family constant |
| `lib/core/theme/app_text_styles.dart` | 6, 131, 137 | `'Outfit'`, `'DM Sans'` | non-i18n: font family constants |
| `lib/features/accounting/presentation/widgets/smart_keyboard.dart` | 29 | `'JPY'` | non-i18n: currency code default |
| `lib/features/accounting/presentation/widgets/amount_display.dart` | 16 | `'JPY'` | non-i18n: currency code default |
| `lib/features/settings/presentation/screens/settings_screen.dart` | 30 | `'JPY'` | non-i18n: currency code fallback |
| `lib/features/home/presentation/screens/main_shell_screen.dart` | 88, 167 | `'JPY'` | non-i18n: currency code fallback |
| `lib/features/home/presentation/screens/home_screen.dart` | 59, 108 | `'JPY'` | non-i18n: currency code fallback |
| `lib/main.dart` | 132 | `'Failed to initialize'` | deferred — developer-facing init error |

### Profile / Family Sync screens (font family hardcodes)

Many files in `lib/features/profile/` and `lib/features/family_sync/` contain repeated `fontFamily: 'Outfit'` inline specifications. These are style constants that should use `AppTextStyles` but are not i18n strings. Deferred to a future code-quality cleanup phase.

---

## Generated Files (excluded from inventory)

The following files contain `'Unexpected subclass'` strings in Freezed-generated code — these are not user-visible and should not be modified:

- `lib/features/list/domain/models/tagged_transaction.freezed.dart`
- `lib/features/list/domain/models/list_filter_state.freezed.dart`
- `lib/features/list/domain/models/list_sort_config.freezed.dart`

---

## Summary

| Category | Count | Status |
|----------|-------|--------|
| Resolved this phase (D-12, D-13) | 4 strings | DONE |
| Deferred — list_sort_filter_bar Semantics | 9 strings | Future phase |
| Non-i18n constants (JPY, font families) | ~20 occurrences | Intentional |
| Generated files | excluded | N/A |

**Recommended next steps:** A future i18n-cleanup phase should add ARB keys for the 9 Semantics labels in `list_sort_filter_bar.dart` following the same D-13 pattern used in this phase.
