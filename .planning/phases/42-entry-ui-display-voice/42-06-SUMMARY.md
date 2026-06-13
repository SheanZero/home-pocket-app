---
phase: 42
plan: 06
subsystem: accounting-presentation
tags: [currency, i18n, golden, riverpod, multi-currency]
requires:
  - recentCurrencyProvider session state (new this plan)
  - currentLocaleProvider (settings)
  - NumberFormatter currency symbol map (42-02)
provides:
  - CurrencySelectorSheet (modal: JPY-first, search, more, flag rows)
  - RecentCurrency Notifier -> recentCurrencyProvider (session LRU, non-persisted)
  - common-zone localized currency-name ARB keys (ja/zh/en)
affects:
  - lib/features/accounting/presentation/ (new selector sheet + provider)
  - lib/l10n/ (new ARB keys, regenerated S getters)
tech-stack:
  added: []
  patterns:
    - host-owned session Riverpod Notifier (non-persisted, resets on restart)
    - golden flag-cell masking via showFlags flag (RESEARCH Q2)
    - ARB-localized common zone + ISO+English long-tail fallback (RESEARCH Q1)
key-files:
  created:
    - lib/features/accounting/presentation/providers/recent_currency_provider.dart
    - lib/features/accounting/presentation/widgets/currency_selector_sheet.dart
    - test/golden/currency_selector_sheet_golden_test.dart
    - test/golden/goldens/currency_selector_sheet_{ja,zh,en,dark_ja,dark_zh,dark_en}.png
  modified:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
decisions:
  - "JPY always pinned first and excluded from recent-use LRU (Open Question 1)"
  - "Common zone (USD/EUR/CNY/HKD/GBP) reordered by session LRU; long-tail ISO 4217 only under 'more'"
  - "Localize common-zone currency names in ARB; long-tail falls back to ISO code + bundled English name (RESEARCH Q1/Q2)"
  - "Flag emoji rendered host-font-dependently; goldens mask the flag cell via showFlags=false (RESEARCH Q2)"
  - "recentCurrencyProvider is session-only (non-persisted); no Drift/secure-storage write (T-42-14)"
metrics:
  duration: ~12min
  completed: 2026-06-13
---

# Phase 42 Plan 06: Currency Selector Sheet + Recent-Use Provider Summary

CurrencySelectorSheet (JPY-pinned modal with code/name search, "more" full-ISO expansion, and flag+symbol+code+name rows) plus a non-persisted session LRU `recentCurrencyProvider`, returning a selected ISO code without leaving the entry screen.

## What Was Built

**Task 1 — Recent-use session provider + ARB currency names** (commit `c7475090`)
- `RecentCurrency` `@riverpod` Notifier → `recentCurrencyProvider`: in-session LRU list of foreign ISO codes, non-persisted, resets to JPY-default (empty) on restart (CURR-03, T-42-14). `recordUse()` ignores JPY and dedup-promotes to front (immutable update). `orderedCommonZone()` returns `kCommonZoneCurrencies` (USD/EUR/CNY/HKD/GBP) re-ordered most-recent-first. JPY never participates in reordering (Open Question 1).
- ARB keys added to all 3 files (ja/zh/en) then `flutter gen-l10n`: `currencySelectorTitle/More/SearchHint/NoResults` + `currencyName{Jpy,Usd,Eur,Cny,Hkd,Gbp,Krw,Twd,Sgd,Aud,Cad}` (common zone localized; long-tail out of scope per RESEARCH Q1).

**Task 2 — CurrencySelectorSheet + golden test** (commit `e73d4a9f`)
- `CurrencySelectorSheet` (ConsumerStatefulWidget) copied from the `CategoryFilterSheet` skeleton: drag handle + header + search field + `Expanded(ListView)` rows + "more" affordance.
- Default view = JPY first, then common zone reordered by `recentCurrencyProvider`. "more" (D-02) toggles in the full ISO 4217 long-tail (19 extra codes, English names). Search (`currency-search-field`) filters by ISO code OR localized/English name (CURR-02).
- Row (D-01) = flag emoji (28dp cell) + currency symbol (from `NumberFormatter`) + ISO code (w700) + localized name, each ≥48dp `InkWell` (`vertical: 12` padding + `minHeight: 48`). Selected row highlights with `palette.accentPrimaryLight` background + `accentPrimary` leaf-green text/check. Palette-only, no raw hex, sakura pink absent.
- Tap → `recordUse(code)` + `onSelect(code)` + `Navigator.pop` (CURR-03). Cancel affordance in header.
- `showFlags` flag masks the flag cell (blank fixed-width box) in golden mode (RESEARCH Q2).
- 6 golden baselines ({ja,zh,en}×{light,dark}) generated on macOS with flags masked; all pass on re-run.

## How to Verify

```bash
flutter test test/golden/currency_selector_sheet_golden_test.dart   # 6 cases pass
flutter analyze lib/features/accounting/presentation/widgets/currency_selector_sheet.dart \
                lib/features/accounting/presentation/providers/recent_currency_provider.dart  # 0 issues
flutter gen-l10n   # ARB keys generate cleanly
```

## Deviations from Plan

None — plan executed exactly as written. The `more` affordance, search, JPY-pin, LRU reorder, 48dp rows, palette-only colors, ARB-localized common zone, and masked-flag goldens all match the plan tasks.

## Scope Notes

- The currency-KEY tap wiring on `SmartKeyboard` (opening this sheet) is **plan 42-08's scope** — this plan builds the sheet + provider only. `CurrencySelectorSheet` is not yet referenced by any screen, by design.
- The full-ISO long-tail uses an embedded 19-entry English-name list (`_fullIsoList`); intentionally not the complete ~150 ISO set (RESEARCH Q1 scoped long-tail to ISO+English, common cases covered).

## Threat Surface

- T-42-14 (recent-use persisted unintentionally): mitigated — provider is session-only, no storage write.
- T-42-13 (malformed search/locale into row render): mitigated — search filters an in-memory list; names via `S.of(context)`, no raw-input interpolation.
- T-42-15 (flag emoji golden divergence): accepted — flag cell masked in goldens.
- No package installed (T-42-SC accept holds).

## Self-Check: PASSED

- FOUND: lib/features/accounting/presentation/providers/recent_currency_provider.dart
- FOUND: lib/features/accounting/presentation/widgets/currency_selector_sheet.dart
- FOUND: test/golden/currency_selector_sheet_golden_test.dart
- FOUND: 6 golden baselines under test/golden/goldens/currency_selector_sheet_*.png
- FOUND commit: c7475090 (Task 1)
- FOUND commit: e73d4a9f (Task 2)
