---
phase: 42-entry-ui-display-voice
plan: 07
subsystem: accounting-presentation / currency
tags: [currency, preview, riverpod, golden, i18n, multi-currency, DISP-01]
requires:
  - "appGetExchangeRateUseCaseProvider (P41 — returns RateResultWithSignal with D-02/D-03 pre-computed)"
  - "convertToJpy() + subunitToUnitFor() single conversion site (ADR-020 / 42-02)"
  - "currentLocaleProvider (settings)"
  - "DateFormatter / NumberFormatter (infrastructure/i18n)"
provides:
  - "ConversionPreviewPanel — async consumer rendering JPY main row + rate sub-row + staleness label (DISP-01)"
  - "conversionRateProvider(ConversionPreviewArgs) — keyed FutureProvider deduping rate fetch by (currency,date,amount)"
  - "kConversionPreviewBlockHeight — fixed preview block height (no-jump invariant)"
  - "ARB keys: conversionPreviewRateRow / conversionStalenessCached / conversionStalenessWeekend / conversionRateRequired (ja/zh/en)"
affects:
  - "42-08 (host mounting of the panel; CURR-04 JPY-not-mounted guard lives in the host)"
  - "lib/l10n/ (new ARB keys, regenerated S getters)"
tech-stack:
  added: []
  patterns:
    - "ref.watch for rendered RateResult; ref.listen (onSignal) for D-02 dialog / D-03 toast side-effects (Riverpod 3)"
    - "keyed @riverpod FutureProvider with a value-equality args object dedupes refetch on unrelated rebuilds (T-42-18)"
    - "fixed-height in-place skeleton mirroring list_calendar_header AsyncValue.when (D-04 no-jump)"
    - "single conversion site convertToJpy() — preview figure == persisted figure (ADR-020)"
key-files:
  created:
    - lib/features/accounting/presentation/widgets/conversion_preview_panel.dart
    - lib/features/accounting/presentation/widgets/conversion_preview_panel.g.dart
    - test/features/accounting/presentation/widgets/conversion_preview_test.dart
    - test/features/accounting/presentation/widgets/goldens/conversion_preview_{loaded_ja,loaded_dark_ja,loaded_en,fallback_ja,weekend_ja,loading_ja}.png
  modified:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
    - lib/generated/app_localizations*.dart
decisions:
  - "Panel exposes the RateSignal via an onSignal callback wired from ref.listen — the host (42-08) owns dialog/toast rendering; the panel never ref.watch-es the signal (Riverpod 3 side-effect rule)"
  - "RateUnavailable AND an unexpected provider error both render the mandatory-manual-rate prompt (palette.error) rather than crashing — network failure already degrades to fallback upstream (RATE-03)"
  - "Staleness label fires for RateFallback (cached) OR RateFetched.actualDate != txDate (weekend proxy); warning amber reserved exclusively for it (UI-SPEC color discipline)"
  - "Keyed provider args carry previousRate/wasManualOverride so the use case's pre-computed D-02/D-03 signals flow through unchanged (no threshold re-derivation)"
metrics:
  duration: ~18min
  completed: 2026-06-13
  tasks: 2
  files: 9
---

# Phase 42 Plan 07: Live JPY ConversionPreviewPanel Summary

`ConversionPreviewPanel` renders the real-time JPY conversion during foreign entry (DISP-01): a `≈ ¥7,415` main row + `USD 1 = ¥148.30 · {date}` sub-row computed through the single-site `convertToJpy()`, an in-place fixed-height loading skeleton (no jump), and a warning-amber staleness label for cached-fallback / weekend rates — consuming the already-wired P41 `appGetExchangeRateUseCaseProvider` via a keyed FutureProvider, with the D-02 dialog / D-03 toast surfaced through `ref.listen` only.

## What Was Built

**Task 1 — ConversionPreviewPanel + staleness label + ARB copy** (commit `2d62935a`)
- `ConversionPreviewPanel` (`ConsumerWidget`): asserts `currency != 'JPY'` (CURR-04), reads the keyed `conversionRateProvider`, and renders via `AsyncValue.when`.
  - **Main row** `≈ {NumberFormatter JPY}` in `AppTextStyles.amountLarge` (`palette.textPrimary`), where the JPY is `convertToJpy(originalMinorUnits, appliedRate, subunitToUnitFor(currency))` — the single conversion site, never an inline multiply (ADR-020).
  - **Sub-row** `{CODE} 1 = ¥{rate} · {DateFormatter date}` in `AppTextStyles.labelMedium` (`palette.textSecondary`), via `S.of(context).conversionPreviewRateRow(...)`.
  - **Loading** = `_PreviewSkeleton` — a `SizedBox(height: kConversionPreviewBlockHeight=56)` with two muted skeleton bars, mirroring the `list_calendar_header` `AsyncValue.when` loading box. The loaded no-staleness content uses the same fixed height → no jump (D-04, Pitfall 5).
  - **Staleness label** (D-05): below the sub-row, `palette.warning` amber, for `RateFallback` (`conversionStalenessCached`) or `RateFetched.actualDate != txDate` (`conversionStalenessWeekend`). Reserved amber, not the normal sub-row.
  - **Signals**: `ref.listen(conversionRateProvider(args), ...)` forwards `RateSignalDialog`/`RateSignalToast` to an `onSignal` callback — never `ref.watch`-ed, never threshold-recomputed.
  - **RateUnavailable / error** → `_RateRequiredPrompt` (`palette.error`, `conversionRateRequired`, P41 D-08).
- `conversionRateProvider` (`@riverpod` keyed FutureProvider) on a value-equality `ConversionPreviewArgs` object → dedupes refetch by (currency, date, minorUnits, previousRate, wasManualOverride) (T-42-18).
- ARB keys added to all 3 files + `flutter gen-l10n`: `conversionPreviewRateRow`, `conversionStalenessCached`, `conversionStalenessWeekend`, `conversionRateRequired`.

**Task 2 — Preview widget + golden test** (commit `c2d15a72`)
- `conversion_preview_test.dart` overrides `conversionRateProvider(args)` (and `currentLocaleProvider`) with `RateResult` fakes per state.
- Behavior assertions: loaded `≈ ¥7,415` + `USD 1 = ¥148.30` sub-row, no staleness; fallback "Using cached rate"; weekend "most recent business day"; loading shows no figure + fixed `kConversionPreviewBlockHeight`; JPY currency → `AssertionError` via `tester.takeException()` (CURR-04); D-02 dialog + D-03 toast each fire `onSignal` exactly once (listen, not watch rebuild).
- The `≈ ¥7,415` assertion binds the single-site figure to the persisted value (T-42-17).
- 6 macOS golden baselines: `loaded_{ja,dark_ja,en}`, `fallback_ja`, `weekend_ja`, `loading_ja`.

## How to Verify

```bash
flutter test test/features/accounting/presentation/widgets/conversion_preview_test.dart   # 14 pass
flutter analyze lib/features/accounting/presentation/widgets/conversion_preview_panel.dart \
                test/features/accounting/presentation/widgets/conversion_preview_test.dart  # 0 issues
flutter gen-l10n   # ARB keys generate cleanly
```

## Must-Haves Verification

- ✅ JPY main row (`≈ ¥7,415`, amountLarge) + rate sub-row (`USD 1 = ¥148.30 · {date}`, labelMedium) computed via `convertToJpy()` single site (D-03) — asserted by the loaded test.
- ✅ Loading = in-place fixed-height skeleton, no jump (D-04) — same `kConversionPreviewBlockHeight` asserted for loading + loaded.
- ✅ Stale/fallback shows warning-amber (`palette.warning #C98A00`) label for `RateFallback` OR `actualDate != txDate` (D-05) — fallback + weekend tests.
- ✅ `RateSignal` (D-02 dialog / D-03 toast) surfaced via `ref.listen`, never `ref.watch` — signal tests fire `onSignal`.
- ✅ `currency == 'JPY'` → panel not rendered (assert throws; CURR-04) — JPY-guard test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `unnecessary_underscores` lint on error builder**
- **Found during:** Task 1 verification (`flutter analyze`)
- **Issue:** `error: (_, __) => ...` tripped the project's `unnecessary_underscores` lint.
- **Fix:** Changed to `error: (_, _) => ...`.
- **Files modified:** lib/features/accounting/presentation/widgets/conversion_preview_panel.dart
- **Commit:** 2d62935a

**2. [Rule 3 - Blocking] `Override` type + sealed `WidgetRef` in the test harness**
- **Found during:** Task 2 first `flutter test` (compilation failed)
- **Issue:** `Override` is not exported by `flutter_riverpod.dart` (it lives in `flutter_riverpod/misc.dart`), and `WidgetRef` is `sealed` so the planned direct `panel.build(fakeContext, fakeRef)` JPY-assert could not be faked.
- **Fix:** Imported `package:flutter_riverpod/misc.dart` for `Override`; replaced the direct-build JPY test with a real `pumpWidget` + `tester.takeException()` assertion (still verifies the CURR-04 AssertionError fires in build).
- **Files modified:** test/features/accounting/presentation/widgets/conversion_preview_test.dart
- **Commit:** c2d15a72

**3. [Rule 1 - Bug] Loading-vs-loaded height test cross-contaminated across two `pumpWidget`s**
- **Found during:** Task 2 (`--update-goldens` run)
- **Issue:** Measuring loaded then loading height within one test re-resolved the keyed provider and rendered the loaded figure during the "loading" phase (cached value bled through), failing the `findsNothing` guard.
- **Fix:** Split into two independent `testWidgets` — one asserts the loaded content uses `kConversionPreviewBlockHeight`, the other asserts loading shows no figure at the same fixed height. Exposed `kConversionPreviewBlockHeight` from the panel for the assertion.
- **Files modified:** lib/.../conversion_preview_panel.dart, test/.../conversion_preview_test.dart
- **Commit:** c2d15a72

## Scope Notes

- **Host mounting is 42-08's scope.** This plan builds the panel + keyed provider + tests only; `ConversionPreviewPanel` is not yet referenced by any screen, by design. The CURR-04 "don't mount for JPY" guard is enforced both here (assert) and at the host (42-08).
- `onSignal` is a passive callback — the actual dialog/toast UI (ADR-022 D-02/D-03) is rendered by the host in 42-08.

## Known Stubs

None. The panel is fully wired to the live P41 use case via `ref.watch`; the only un-hosted seam (`onSignal` consumer) is the documented 42-08 boundary, not a placeholder.

## Threat Surface

- T-42-16 (silent stale rate): mitigated — D-05 amber staleness label on `RateFallback` / `actualDate != txDate`, asserted by fallback + weekend tests.
- T-42-17 (inline-multiply divergence): mitigated — single-site `convertToJpy()`; the `≈ ¥7,415` assertion binds the preview figure to the persisted value.
- T-42-18 (refetch on every keypad tap): accepted — keyed `conversionRateProvider` dedupes by value-equality args; P41 cache-first owns the budget.
- T-42-SC (pub installs): accepted — no package installed.

No new network endpoints, auth paths, file access, or schema changes introduced.

## Commits

- `2d62935a`: feat(42-07): ConversionPreviewPanel with rate sub-row + staleness label
- `c2d15a72`: test(42-07): conversion preview widget + golden states

## Self-Check: PASSED

- FOUND: lib/features/accounting/presentation/widgets/conversion_preview_panel.dart
- FOUND: lib/features/accounting/presentation/widgets/conversion_preview_panel.g.dart
- FOUND: test/features/accounting/presentation/widgets/conversion_preview_test.dart
- FOUND: 6 golden baselines under test/features/accounting/presentation/widgets/goldens/conversion_preview_*.png
- FOUND commit: 2d62935a (Task 1)
- FOUND commit: c2d15a72 (Task 2)
