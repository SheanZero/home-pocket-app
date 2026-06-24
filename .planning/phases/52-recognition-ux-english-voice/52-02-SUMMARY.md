---
phase: 52-recognition-ux-english-voice
plan: 02
subsystem: accounting-presentation
tags: [flutter, widget, recognition-ux, confidence-band, alternate-chips, i18n, a11y, adr-012, adr-019]

# Dependency graph
requires:
  - phase: 52-01
    provides: "VoiceParseResult.band/alternates/keywordMerchantConflict threaded from RecognitionOutcome"
provides:
  - "ConfidenceBandIndicator — pure-visual 3-tier band (intensity by ConfidenceBand enum, color family by LedgerType), a11y-only Semantics label, SizedBox.shrink when null"
  - "AlternateCategoryChips — ≤3 ranked chips + exit chip → existing CategorySelectionScreen; palette-token styling; ≥44px touch height"
  - "TransactionDetailsForm.updateRecognition(band, alternates) — voice host push at resolve-on-final; band/chips render gated on band != null; clear-on-select (D-09)"
  - "2 trilingual ARB keys: recognitionBandSuggestedCategory (a11y), recognitionAlternatesMore (exit chip)"
affects: [52-03, 52-04, 52-05, 52-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure-visual qualitative indicator: confidence rendered as color/border/dot intensity switched on a domain enum, a11y label via Semantics(excludeSemantics:true), zero painted text (ADR-012)"
    - "Display-ready chip atom reusing the list_sort_filter_bar ActionChip idiom (avatar+label+palette outline) at a 44px HIG touch floor"
    - "Shared user-selection write set (_applyCategorySelection) reused by full selector AND chip tap — single place for ledger re-derive + correction record + band clear"
    - "Recognition push gated on the same fillCategory=final flag as updateCategory — resolve-on-final, no partial flicker (D-08)"

key-files:
  created:
    - lib/features/accounting/presentation/widgets/confidence_band_indicator.dart
    - lib/features/accounting/presentation/widgets/alternate_category_chips.dart
    - test/widget/features/accounting/presentation/widgets/confidence_band_indicator_test.dart
    - test/widget/features/accounting/presentation/widgets/alternate_category_chips_test.dart
  modified:
    - lib/features/accounting/presentation/widgets/transaction_details_form.dart
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/generated/app_localizations.dart
    - lib/generated/app_localizations_en.dart
    - lib/generated/app_localizations_ja.dart
    - lib/generated/app_localizations_zh.dart

key-decisions:
  - "Band intensity switches on the ConfidenceBand enum only — never recomputed from a numeric confidence in presentation (T-52-04, ADR-012)"
  - "Recognition data reaches the form via a public updateRecognition() method (mirroring updateCategory/updateAmount), NOT via the domain-pure TransactionDetailsFormConfig — keeps the config free of package:flutter / voice types (CRIT-04 domain purity)"
  - "Chips resolve labels via CategoryLocalizationService.resolveFromId(id, locale) synchronously — no async repo lookup needed to render a chip, so the widget stays pure/testable"
  - "AlternateCategoryChips uses an eager Row in a horizontal SingleChildScrollView (not a lazy ListView) so the trailing exit chip always builds — a lazy ListView only built the 3 visible chips offscreen in the test viewport"
  - "Both ARB keys added upfront in Task 1 (trilingual parity) even though recognitionAlternatesMore is first used in Task 2 — keeps each task commit compiling and avoids a second gen-l10n pass"

requirements-completed: [RECUX-01, RECUX-02, RECUX-05]

# Metrics
duration: 7min
completed: 2026-06-24
status: complete
---

# Phase 52 Plan 02: Recognition Surface (Confidence Band + Alternate Chips) Summary

**Renders the RECUX recognition surface on `TransactionDetailsForm`: a purely-visual 3-tier confidence band (intensity by `ConfidenceBand` enum + daily/joy ledger family, a11y-only Semantics, zero painted text) and ≤3 tappable alternate-category chips + an exit chip to the existing full selector — appearing at resolve-on-final (D-08), clearing on user selection (D-09), and absent for manual entry (D-10).**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-06-24T10:37:34Z
- **Completed:** 2026-06-24T10:45:17Z
- **Tasks:** 3
- **Files:** 4 created, 9 modified

## Accomplishments

- **`ConfidenceBandIndicator`** (Task 1): a pure-visual band whose border depth + dot fill encode the 3-tier `ConfidenceBand` (strong/medium/weak), with the accent color family keyed to `LedgerType` (daily-green vs joy-pink). Wraps the visual in `Semantics(label:, excludeSemantics:true)` carrying `recognitionBandSuggestedCategory` — announced by screen readers, never painted. Returns `SizedBox.shrink()` when `band == null` (D-10). Palette tokens only (no raw hex), no number/%/gauge/text (ADR-012). 8 widget tests green.
- **`AlternateCategoryChips`** (Task 2): caps the reconciler `alternates` to the first 3 (no re-rank — Phase 51 already ranked + L2-deduped), appends exactly one trailing exit chip (`recognitionAlternatesMore`) that opens the existing `CategorySelectionScreen` and routes its returned id through `onSelect`. Each chip resolves its label via `CategoryLocalizationService.resolveFromId`, uses the `list_sort_filter_bar` ActionChip idiom with `accentPrimary` (selected) / `borderDefault` (unselected) outlines on `backgroundMuted`, and a ≥44px HIG touch height. No confidence figure painted. 5 widget tests green.
- **Form wiring** (Task 3): added `_band`/`_alternates` state + a public `updateRecognition(band, alternates)` pushed by the voice host at resolve-on-final (the same `fillCategory` gate as `updateCategory`, so band/chips resolve exactly once — no partial flicker, D-08). Band+chips render in a `Row` after the category `DetailInfoCard`, gated on `_band != null` (D-10). Extracted `_applyCategorySelection` shared by the full-selector flow and the new `_selectAlternateCategory` chip-tap handler; both call `_clearRecognitionBand()` so the band clears the instant the user picks any category (D-09).
- **Trilingual ARB**: added `recognitionBandSuggestedCategory` (推定カテゴリ / 推测类目 / Suggested category) and `recognitionAlternatesMore` (もっと / 其他 / More) to all three locale files; `flutter gen-l10n` clean; regenerated `lib/generated/` force-added (tracked-but-gitignored) and committed.

## Task Commits

Each task was committed atomically:

1. **Task 1: ConfidenceBandIndicator + trilingual ARB + gen-l10n** — `e312ae52` (feat) — widget + 8 tests + both ARB keys ×3 locales + regenerated generated Dart
2. **Task 2: AlternateCategoryChips ≤3 + exit chip** — `de94b65f` (feat) — widget + 5 tests
3. **Task 3: Wire band+chips into form + voice push (D-08/D-09/D-10)** — `9cb884fc` (feat) — form state/render/clear-on-select + voice_ptt_session_mixin resolve-on-final push

_Note: the 2 ARB keys + regenerated `lib/generated/` were committed with Task 1 (the first task whose widget references a new key), so each subsequent task commit compiles independently. `git add -f lib/generated/*` was used because the generated Dart is tracked-yet-gitignored in this repo (CLAUDE.md / Phase 46 memory)._

## Files Created/Modified

- `confidence_band_indicator.dart` (created) — pure-visual band, a11y-only Semantics, enum-switched intensity, ledger-family accent
- `alternate_category_chips.dart` (created) — ≤3 ranked chips + exit chip → full selector, palette-token ActionChip atom, 44px floor
- `confidence_band_indicator_test.dart` / `alternate_category_chips_test.dart` (created) — 8 + 5 widget tests
- `transaction_details_form.dart` (modified) — `_band`/`_alternates` state, `updateRecognition`, band+chips render gated on `_band != null`, `_applyCategorySelection` + `_selectAlternateCategory` + `_clearRecognitionBand` (D-09)
- `voice_ptt_session_mixin.dart` (modified) — push `state.updateRecognition(data.band, data.alternates)` only on the final fill (D-08)
- `app_en.arb` / `app_ja.arb` / `app_zh.arb` (modified) — 2 new keys, trilingual parity
- `lib/generated/app_localizations*.dart` (modified) — regenerated for the 2 keys

## Decisions Made

- Band intensity switches on the `ConfidenceBand` enum only; presentation never recomputes confidence from a number (T-52-04 / ADR-012).
- Recognition data reaches the form through a public `updateRecognition()` method (mirroring the existing `update*` host-push contract), NOT through the domain-pure config — keeping `TransactionDetailsFormConfig` free of `package:flutter` and voice types (CRIT-04).
- `AlternateCategoryChips` uses an eager `Row` in a horizontal `SingleChildScrollView` rather than a lazy `ListView`, so the trailing exit chip is always built (a lazy list only constructed the 3 visible chips in the narrow test viewport).

## Deviations from Plan

None — plan executed exactly as written.

The only implementation choice worth noting (not a deviation from the plan's intent): recognition data is pushed via a new public `updateRecognition()` form method rather than carried on the config. The plan said to render "gated on the VPR `band != null`" and "feed the band's ledger family from the resolved category" without prescribing the transport; the public-method route is the established host-push pattern in this form (`updateCategory`/`updateAmount`/`updateMerchant`) and is what preserves config domain-purity (CRIT-04). The voice mixin pushes it at exactly the resolve-on-final fill point the plan specified.

## Self-Check: PASSED

- All 4 created files + 5 modified source/ARB files exist on disk; SUMMARY.md exists.
- All 3 task commits (`e312ae52`, `de94b65f`, `9cb884fc`) present in git history.
- `flutter analyze` (whole project) → 0 issues.
- 13 new widget tests green (8 band + 5 chips); 50 form/voice regression tests green (voice_ptt_session_mixin, form smoke, form refetch-rate, voice_input_screen).
- `flutter gen-l10n` clean; `lib/generated/` committed (no stale generated Dart); trilingual key parity confirmed (en/ja/zh each carry both keys).
- Gamification/number-token sweep on both new widgets → NONE; raw-hex scan → 0.

---
*Phase: 52-recognition-ux-english-voice*
*Completed: 2026-06-24*
