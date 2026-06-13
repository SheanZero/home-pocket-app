---
phase: quick-260613-ufn
plan: 01
subsystem: ui
tags: [flutter, riverpod, i18n, currency, exchange-rate, golden-tests, adr-022]

requires:
  - phase: 42 (entry-ui-display-voice)
    provides: "CurrencyLinkedEditFields edit card, ConversionPreviewPanel/keyed conversionRateProvider, GetExchangeRateUseCase (P41), ADR-022 D-01/D-02/D-03 semantics, single convertToJpy site"
provides:
  - "Unified foreign-currency conversion card across the add screen and the edit screen (same 汇率 / 日元（换算）/ 汇率日期 rows)"
  - "Add screen no longer renders the large ≈¥ ConversionPreviewPanel preview block; ConversionPreviewPanel widget deleted (file reduced to shared rate plumbing)"
  - "Non-clickable labeled 汇率日期 row (edit_rate_date) showing the ACTUAL effective rate date + amber weekend/holiday staleness note on both screens"
  - "Date-picker change auto-refetches the rate on BOTH screens (edit fires ADR-022 D-02 dialog / D-03 toast via triggerDateChangeRefetch)"
  - "currencyRateDateLabel ARB key (zh/ja/en) + gen-l10n"
  - "Single staleness-derivation site (stalenessNoteFor/rateEffectiveDateOf/rateStringOf) reused by both screens"
affects: [foreign-currency-ui, exchange-rate-display, transaction-edit, manual-entry]

tech-stack:
  added: []
  patterns:
    - "Thin keyed-provider Consumer wrapper mounting the shared stateful card on the add screen, fed by conversionRateProvider(currency,date,amount)"
    - "Host-driven date-change refetch via GlobalKey + CurrencyLinkedEditFieldsState.triggerDateChangeRefetch() (replaces in-card clickable trigger)"
    - "Single staleness-derivation helper site (no duplicated _stalenessLabel)"

key-files:
  created:
    - "test/golden/goldens/currency_linked_edit_fields_usd_staleness.png"
  modified:
    - "lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart"
    - "lib/features/accounting/presentation/widgets/conversion_preview_panel.dart"
    - "lib/features/accounting/presentation/widgets/transaction_details_form.dart"
    - "lib/features/accounting/presentation/screens/manual_one_step_screen.dart"
    - "lib/features/accounting/presentation/widgets/currency_edit_strings.dart"
    - "lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb"
    - "docs/arch/03-adr/ADR-022_Edit_Semantics.md"

key-decisions:
  - "FALLBACK NOT taken — fully-editable rate on the add screen shipped: the add-screen card's 汇率 row is editable (hand-edit flips manualOverride), fed by the keyed conversionRateProvider via a thin Consumer wrapper"
  - "Date-change refetch moved from the in-card clickable trigger (edit_date_change_trigger removed) to the date-picker flow on both screens; edit still routes through the retained D-02/D-03 logic"
  - "汇率日期 row shows the ACTUAL effective rate date (rateEffectiveDateOf), not the requested transaction date; staleness derived once via stalenessNoteFor"
  - "ConversionPreviewPanel widget deleted (unreferenced after the swap); file kept only as the shared ConversionPreviewArgs + conversionRateProvider + staleness helpers"

patterns-established:
  - "Pattern 1: Both foreign-currency entry surfaces (add + edit) mount the SAME CurrencyLinkedEditFields card — single source of conversion-row visuals/interaction"
  - "Pattern 2: Date-picker change is the sole rate-refetch trigger; the card exposes triggerDateChangeRefetch() for the host"

requirements-completed: [D-1, D-2, D-3, D-4]

duration: ~63min (prior-session execution) + verification this session
completed: 2026-06-13
---

# Quick 260613-ufn: Unify Foreign-Currency Card (Two Screens) Summary

**Add and edit screens now render the identical CurrencyLinkedEditFields card (汇率 editable / 日元 read-only derived / 汇率日期 non-clickable + amber staleness); the add-screen ≈¥ preview block is gone, and a date-picker change auto-refetches the rate on both screens with consistent ADR-022 D-02/D-03 UX.**

## Performance

- **Duration:** ~63 min (task commits authored in a prior session) + verification + docs this session
- **Started:** 2026-06-13T22:15:20Z (Task 1 commit)
- **Completed:** 2026-06-13T23:18:23Z (Task 3 commit); docs/state finalized this session
- **Tasks:** 3
- **Files modified:** 10 source/doc + test files (3 ARB + generated)

## Accomplishments
- D-1: add screen swapped from the large `≈¥{jpy}` `ConversionPreviewPanel` block to the unified `CurrencyLinkedEditFields` card via a thin keyed-provider Consumer wrapper; the add-screen 汇率 row is editable (hand-edit → `manualOverride=true`, persisted triple uses the edited rate). FALLBACK (read-only add-screen rate) was NOT needed.
- D-2: 汇率日期 row shows the ACTUAL effective rate date (`rateEffectiveDateOf`); amber `conversionStalenessWeekend`/`conversionStalenessCached` note renders below it when actual ≠ requested date — derived once in `stalenessNoteFor`, reused by both screens.
- D-3: removed the clickable `edit_date_change_trigger` TextButton; replaced with a non-clickable labeled `edit_rate_date` row (new `currencyRateDateLabel` ARB key, gen-l10n'd).
- D-4: date-picker change auto-refetches on both screens — edit routes through `triggerDateChangeRefetch()` → retained ADR-022 D-02 dialog / D-03 >1% toast; add re-resolves via the keyed `conversionRateProvider(currency,date,amount)`. `foreignPushIsStale` (WR-01) guard intact.
- Invariants preserved: single `convertToJpy` site (ADR-020), persisted JPY == card JPY, RateSignal side-effects only via `ref.listen`/`onSignal` (Riverpod 3), ADR-022 D-01 single-direction unchanged.
- ADR-022 appended (append-only) with `## Update 2026-06-13: 外币卡片两屏统一（quick 260613-ufn，D-1..D-4）`.

## Task Commits

Each task was committed atomically (TDD where specified):

1. **Task 1: Generalize CurrencyLinkedEditFields (汇率日期 row + staleness, no TextButton)** — `3abf7e05` (feat)
2. **Task 2: Wire date-picker auto-refetch on both screens + mount shared card on add (remove ConversionPreviewPanel block)** — `ab3f6739` (feat)
3. **Task 3: Re-baseline goldens (macOS), full suite + analyze green, append ADR-022 Update** — `182241bd` (docs)

_Note: ADR-022 Update (a real project doc) committed in the Task 3 commit per plan constraint. SUMMARY.md / STATE.md docs commit handled separately by the orchestrator._

## Files Created/Modified
- `lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart` — added `actualRateDate` + `stalenessNote` props, non-clickable `edit_rate_date` labeled row, public state + `triggerDateChangeRefetch()`, removed TextButton; retained D-02/D-03 logic + single convertToJpy site.
- `lib/features/accounting/presentation/widgets/conversion_preview_panel.dart` — `ConversionPreviewPanel` widget deleted; file reduced to `ConversionPreviewArgs` + `conversionRateProvider` + single staleness-derivation site (`rateStringOf`/`rateEffectiveDateOf`/`stalenessNoteFor`).
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` — `onDateChanged` callback + `_onForeignDateChanged` route the date-picker change through the card's D-02/D-03 logic; derive `actualRateDate` + `stalenessNote` from the same `RateResult`.
- `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` — removed the `≈¥` preview mount; mounts the shared card via a keyed Consumer wrapper; `_onFormDateChanged` keeps `_selectedDate` in lock-step so the keyed provider re-resolves; `_pushForeignTriple` + `foreignPushIsStale` intact.
- `lib/features/accounting/presentation/widgets/currency_edit_strings.dart` — null-safe `rateDateLabel` getter (English fallback `Rate date`).
- `lib/l10n/app_{ja,zh,en}.arb` + `lib/generated/*` — new `currencyRateDateLabel` (レート日付 / 汇率日期 / Rate date), gen-l10n'd.
- `docs/arch/03-adr/ADR-022_Edit_Semantics.md` — append-only Update section.
- Tests: `edit_currency_linked_test.dart`, `transaction_details_form_refetch_rate_test.dart`, `conversion_preview_test.dart`, `currency_linked_edit_fields_golden_test.dart`, `transaction_edit_screen_amount_test.dart`; re-baselined `currency_linked_edit_fields_usd{,_dark}.png`, added `_staleness.png`, removed 6 orphaned `conversion_preview_*` goldens.

## Decisions Made
- Took the **non-fallback** path: add-screen rate is fully editable (async provider × stateful card × manual-override × keyed provider). The architecture proved tractable — the thin keyed Consumer wrapper feeds the existing stateful card without a fragile bridge, so the documented FALLBACK (read-only add-screen rate) was unnecessary.
- Staleness derived in exactly one place (`stalenessNoteFor`) rather than duplicating `_stalenessLabel`, satisfying the single-derivation-site constraint.

## Deviations from Plan
None — plan executed exactly as written (all 3 tasks, atomic commits, TDD on Tasks 1–2). No deviation rules triggered.

## Issues Encountered
- This execution was a **recovery**: the three atomic task commits (`3abf7e05`, `ab3f6739`, `182241bd`) were authored in a prior session, but the SUMMARY.md and STATE.md were never produced and the docs commit was not made. This session re-verified the work end-to-end (analyze 0, targeted 35/35, full suite 2837/2837) and produced the missing docs. No code changes were required — the prior work passed verification unchanged.
- Goldens are macOS-baselined only (per MEMORY golden CI platform gate); re-baselined on macOS in Task 3. `dart format` was NOT run over `test/` (repo not format-clean).

## User Setup Required
None — no external service configuration required.

## Verification (this session)
- `flutter analyze` → **No issues found** (0 issues).
- Plan-targeted tests → **35/35 passed** (edit_currency_linked, refetch_rate, conversion_preview, card golden, manual_one_step_foreign_triple, transaction_edit_screen_amount).
- Full `flutter test` → **2837/2837 passed** (architecture tests incl. hardcoded_cjk_ui_scan ran, not skipped).
- ARB `currencyRateDateLabel` present in all 3 ARB + generated; ADR-022 Update section present; no production reference to a removed `ConversionPreviewPanel` widget; `edit_date_change_trigger` absent from `lib/`.

## Self-Check: PASSED
- Files exist: currency_linked_edit_fields.dart, conversion_preview_panel.dart, transaction_details_form.dart, manual_one_step_screen.dart, currency_edit_strings.dart, 3 ARB, ADR-022, currency_linked_edit_fields_usd_staleness.png — all FOUND.
- Commits exist: `3abf7e05`, `ab3f6739`, `182241bd` — all FOUND in git log.

## Next Phase Readiness
- Foreign-currency add/edit UI is fully unified; no blockers introduced.
- Carried debt unchanged (see STATE.md). Phase 42 remains `ready_for_verification`.

---
*Quick task: 260613-ufn-unify-foreign-currency-card*
*Completed: 2026-06-13*
