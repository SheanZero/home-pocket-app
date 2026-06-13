---
phase: quick-260613-ufn
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
  - lib/features/accounting/presentation/widgets/conversion_preview_panel.dart
  - lib/features/accounting/presentation/widgets/transaction_details_form.dart
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
  - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
  - docs/arch/03-adr/ADR-022_Edit_Semantics.md
  - test/features/accounting/presentation/edit_currency_linked_test.dart
  - test/features/accounting/presentation/widgets/conversion_preview_test.dart
  - test/widget/features/accounting/presentation/widgets/transaction_details_form_refetch_rate_test.dart
  - test/golden/currency_linked_edit_fields_golden_test.dart
autonomous: false
requirements: [D-1, D-2, D-3, D-4]
must_haves:
  truths:
    - "On BOTH the add screen and the edit screen, the foreign-currency conversion area renders as a labeled card with the same three rows: 汇率 (editable), 日元（换算）(read-only derived), 汇率日期 (non-clickable) — D-1"
    - "The large ≈¥203 live-preview block no longer appears on the add screen — D-1"
    - "The 汇率日期 row shows the ACTUAL effective rate date (e.g. weekend fallback 06/12), and when actual rate date ≠ transaction date a weekend/holiday staleness note (conversionStalenessWeekend) appears below it — on BOTH screens — D-2"
    - "The edit-card date row is no longer a clickable TextButton (key edit_date_change_trigger removed); it is a non-clickable labeled 汇率日期 row — D-3"
    - "Changing the transaction date via the date picker auto-refetches the rate and updates 汇率 / 日元（换算）/ 汇率日期 / staleness on BOTH screens; on edit the ADR-022 D-02 dialog / D-03 toast logic runs — D-4"
  artifacts:
    - path: "lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart"
      provides: "Generalized shared card: adds actualRateDate + stalenessNote props, 汇率日期 labeled non-clickable row, removes TextButton trigger; date-change refetch driven externally"
      contains: "currencyRateDateLabel"
    - path: "lib/l10n/app_ja.arb"
      provides: "New currencyRateDateLabel key (汇率日期 label)"
      contains: "currencyRateDateLabel"
  key_links:
    - from: "lib/features/accounting/presentation/screens/manual_one_step_screen.dart"
      to: "CurrencyLinkedEditFields"
      via: "shared card mount fed by conversionRateProvider"
      pattern: "CurrencyLinkedEditFields"
    - from: "lib/features/accounting/presentation/widgets/transaction_details_form.dart"
      to: "_refetchRateForCurrentDate on date picker change"
      via: "_editDate / updateDate trigger refetch"
      pattern: "_refetchRateForCurrentDate"
---

<objective>
统一外币「添加账目」与「明细编辑」两屏的汇率信息展示卡片，并把"改日期→自动重查汇率"补齐到两屏。User 已锁定 D-1..D-4（见 frontmatter requirements）。

Purpose: 两屏的外币换算区视觉与交互完全一致 —— 同一张带标签卡片（`汇率` 可编辑 / `日元（换算）` 只读 / `汇率日期` 不可点击 + staleness 提示），移除添加页大号 `≈¥203` 实时预览块；改日期在两屏均自动重查汇率。

Output:
- 泛化后的共享卡片 `CurrencyLinkedEditFields`（新增 `actualRateDate` + `stalenessNote` props，`汇率日期` 行改为不可点击带标签行，去掉 `edit_date_change_trigger` TextButton）。
- 添加页改用该卡片（实时 fetch 的初始汇率/实际日期/staleness 喂入），移除 `ConversionPreviewPanel` 大预览块。
- 两屏 date picker 变更后自动重查汇率（编辑页跑 ADR-022 D-02/D-03）。
- 新增 `currencyRateDateLabel` 三 ARB + gen-l10n。
- ADR-022 append Update 区段。

不变量（不可破坏）：ADR-022 D-01 单向换算（原币×汇率→日元，日元只读）；`convertToJpy` 仍是唯一换算点；RateSignal(D-02/D-03) 副作用走 ref.listen / 回调，绝不在 watch 里。
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./CLAUDE.md

# Shared card + preview (the two widgets being unified)
@lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
@lib/features/accounting/presentation/widgets/conversion_preview_panel.dart

# Hosts
@lib/features/accounting/presentation/widgets/transaction_details_form.dart
@lib/features/accounting/presentation/screens/manual_one_step_screen.dart
@lib/features/accounting/presentation/screens/transaction_edit_screen.dart

# Rate types + single conversion site + strings resolver
@lib/application/currency/rate_result.dart
@lib/shared/utils/currency_conversion.dart
@lib/features/accounting/presentation/widgets/currency_edit_strings.dart

# ADR to append
@docs/arch/03-adr/ADR-022_Edit_Semantics.md
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Generalize CurrencyLinkedEditFields into the shared card (汇率日期 labeled non-clickable row + staleness, no TextButton) — D-1, D-2, D-3</name>
  <files>lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart, lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb, test/features/accounting/presentation/edit_currency_linked_test.dart</files>
  <behavior>
    - New ARB key `currencyRateDateLabel` (zh `汇率日期`, ja `レート日付`, en `Rate date`) added to all three ARB files with `@`-metadata, then `flutter gen-l10n` regenerates `lib/generated`; `CurrencyEditStrings` gains a null-safe `rateDateLabel` getter (English fallback `Rate date`) mirroring the existing getters so the delegate-less RED harness stays renderable (per D-2/D-3, citing D-1).
    - The card replaces the trailing `Align(centerRight, TextButton(key:'edit_date_change_trigger', ...))` with a non-clickable `_LabeledField(label: rateDateLabel, child: Text(...))` row whose key is `edit_rate_date` — no `onPressed`, no tap target (D-3). The displayed date is the new `actualRateDate` prop (the effective/fallback rate date), formatted via `DateFormatter` (D-2).
    - Two NEW optional props: `actualRateDate` (DateTime — the effective rate date for the 汇率日期 row, defaulting to `rateDate` when not supplied) and `stalenessNote` (String? — pre-resolved weekend/holiday note from the host). When `stalenessNote != null`, a warning-amber `Text` (key `edit_rate_staleness`, `palette.warning`) renders below the 汇率日期 row (D-2). The card does NOT itself recompute staleness — the host derives it from `RateResult` and passes the localized string (single staleness-derivation site, reused from the preview's `_stalenessLabel` logic).
    - The `汇率` row (editable TextField key `edit_rate_field`) and `日元（换算）` row (read-only derived `edit_jpy_derived`) are UNCHANGED in behavior. Hand-editing the rate still flips `manualOverride=true` (ADR-022 D-02 source). The single conversion site `convertToJpy` / `_deriveJpy()` is byte-unchanged (ADR-020).
    - The `_onDateChange` method body (ADR-022 D-02 dialog / D-03 toast / never-block-save) is RETAINED but is no longer wired to a tap. It is exposed so the host can invoke the same logic after a date-picker change (rename to a public-ish trigger or expose via the existing `dateChangeRefetchRate` flow — see Task 2). Do NOT delete the D-02/D-03 logic.
    - RED first: update `edit_currency_linked_test.dart` to assert (a) `edit_date_change_trigger` is GONE / `edit_rate_date` is present and non-tappable, (b) `currencyRateDateLabel` label renders, (c) staleness Text renders when `stalenessNote` is passed and is absent when null. Keep the existing derived-JPY / dialog / undo-toast assertions GREEN.
  </behavior>
  <action>Add `currencyRateDateLabel` to the three ARB files (with `@`-description metadata matching the existing conversion keys' style) and run `flutter gen-l10n`; never hand-edit `lib/generated`. Add the `rateDateLabel` getter to `CurrencyEditStrings`. In `currency_linked_edit_fields.dart`: add `actualRateDate` (DateTime?, defaults to `rateDate`) and `stalenessNote` (String?) constructor params; replace the trailing TextButton date affordance with a non-clickable `_LabeledField(label: l10n.rateDateLabel, child: Text(key:Key('edit_rate_date'), DateFormatter.formatDate(actualRateDate ?? rateDate, locale), style: AppTextStyles.labelMedium.copyWith(color: palette.textPrimary)))`; below it conditionally render the amber staleness `Text` (key `edit_rate_staleness`) when `stalenessNote != null`. Retain `_onDateChange` (D-02/D-03 logic) as the date-change handler the host will call (Task 2) — do NOT remove it. Preserve `convertToJpy` as the sole conversion site (ADR-020) and the `manualOverride=true`-on-hand-edit semantics (ADR-022 D-02). Drive all copy through `CurrencyEditStrings` (no hardcoded strings); colors via `context.palette`; dates via `DateFormatter`. Implements D-1 (unified card rows), D-2 (actual rate date + staleness), D-3 (non-clickable labeled date row).</action>
  <verify>
    <automated>flutter gen-l10n && flutter test test/features/accounting/presentation/edit_currency_linked_test.dart</automated>
  </verify>
  <done>`currencyRateDateLabel` exists in ja/zh/en ARB and is generated; the card renders a non-clickable `edit_rate_date` labeled row showing `actualRateDate`; `edit_date_change_trigger` TextButton is removed; amber `edit_rate_staleness` renders iff `stalenessNote != null`; derived-JPY / D-02 dialog / D-03 undo-toast assertions still pass; `flutter analyze` 0 issues for the touched files.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Wire date-picker auto-refetch on BOTH screens + mount the shared card on the add screen (remove ConversionPreviewPanel preview block) — D-1, D-4</name>
  <files>lib/features/accounting/presentation/widgets/transaction_details_form.dart, lib/features/accounting/presentation/screens/manual_one_step_screen.dart, lib/features/accounting/presentation/screens/transaction_edit_screen.dart, lib/features/accounting/presentation/widgets/conversion_preview_panel.dart, test/widget/features/accounting/presentation/widgets/transaction_details_form_refetch_rate_test.dart, test/features/accounting/presentation/widgets/conversion_preview_test.dart</files>
  <behavior>
    - EDIT screen (D-4): the date-change refetch is moved from the (now-removed) card TextButton to the date-picker flow. After `_editDate`'s `setState(_date = picked)` (and after `updateDate` for voice/external date pushes), the form invokes the card's retained `_onDateChange` logic (via a card key/controller or by calling `_refetchRateForCurrentDate` and pushing the resolved rate into the card) so ADR-022 D-02 dialog / D-03 >1% toast still fire. `_refetchRateForCurrentDate` is reused unchanged (reads `appGetExchangeRateUseCaseProvider` by `_date`). The card also receives the new `actualRateDate` + `stalenessNote` derived from the same `RateResult` (single staleness-derivation site).
    - ADD screen (D-1): `ManualOneStepScreen` stops mounting `ConversionPreviewPanel` (the large `≈¥{jpy}` block is removed). Instead it mounts the shared `CurrencyLinkedEditFields` card (or a thin Consumer wrapper) for foreign rows, fed by the keyed `conversionRateProvider(currency,date,amount)`: the resolved rate seeds the card's `appliedRate`, the rate's effective date seeds `actualRateDate`, and the staleness string seeds `stalenessNote`. The card's `汇率` row is EDITABLE on add (fully unified per D-1 sub-decision); a hand-edit flips manualOverride and feeds `_pushForeignTriple` so the persisted triple uses the edited rate. The `日元（换算）` row stays derived via the single `convertToJpy` site (persisted JPY == card JPY, ADR-020).
    - ADD screen date auto-refetch (D-4): because `conversionRateProvider` is keyed on `(currency,date,amount)`, changing the date already re-resolves the rate; the wrapper must push the freshly resolved rate/date/staleness into the card so 汇率 / 日元 / 汇率日期 / staleness all update. The `foreignPushIsStale` date guard (WR-01) is preserved so a stale-date rate is never persisted.
    - RateSignal side-effects stay in `ref.listen` / `onSignal` callbacks, never in `ref.watch` (Riverpod 3). On the add screen during fresh entry there is no `previousRate`, so no D-02/D-03 signal fires (documented no-op) — but a USER date change after a rate has resolved supplies a `previousRate`, so the wrapper forwards `previousRate`/`wasManualOverride` into `ConversionPreviewArgs` to drive the toast/dialog consistently with edit (D-4 "两屏一致").
    - `ConversionPreviewPanel`: if no longer referenced anywhere after the add-screen swap, either delete it or reduce it to the shared staleness-derivation helpers the card/wrapper reuse. Confirm via grep that no production code references the removed preview block. Update `conversion_preview_test.dart` to the new contract (assert the staleness-derivation helper, or remove panel-specific golden/widget assertions that no longer apply).
    - RED first: extend `transaction_details_form_refetch_rate_test.dart` to assert that a DATE-PICKER change (not a tap on a now-removed trigger) triggers `_refetchRateForCurrentDate` and updates the card's rate/jpy/date, and that on edit the D-02 dialog (manualOverride) / D-03 toast (>1%) still fire from the picker path.
  </behavior>
  <action>In `transaction_details_form.dart`: after the date picker resolves in `_editDate` (and in `updateDate`), trigger the card's date-change refetch — reuse `_refetchRateForCurrentDate` and route through the card's retained `_onDateChange` (ADR-022 D-02/D-03) so the dialog/toast still fire; pass the new `actualRateDate` + `stalenessNote` (derived from the same `RateResult` via the shared staleness helper) into `CurrencyLinkedEditFields`. In `manual_one_step_screen.dart`: remove the `ConversionPreviewPanel` mount (delete the `≈¥{jpy}` preview block, D-1) and mount the shared card (or a thin keyed-provider Consumer wrapper) for `_isForeign && _originalMinorUnits > 0`, seeding `appliedRate`/`actualRateDate`/`stalenessNote` from `conversionRateProvider`; keep `_pushForeignTriple` + `foreignPushIsStale` (WR-01) so the persisted triple uses the (possibly hand-edited) rate and never a stale-date rate; forward `previousRate`/`wasManualOverride` so a user date change drives the same D-02/D-03 UX as edit (D-4). Keep RateSignal handling in `ref.listen`/`onSignal` (Riverpod 3 — never in `ref.watch`). Reuse the SINGLE staleness-derivation logic currently in `conversion_preview_panel.dart` `_stalenessLabel`/`_rateDateOf` (extract to a shared helper rather than duplicating). After the swap, grep production code for `ConversionPreviewPanel`; delete it (or trim to the shared helper) if unreferenced. Update the two affected tests to the new contract. Do NOT weaken any assertion. Implements D-1 (add screen uses the unified card, no big preview) and D-4 (date-picker auto-refetch on both screens with consistent D-02/D-03 UX).</action>
  <verify>
    <automated>flutter test test/widget/features/accounting/presentation/widgets/transaction_details_form_refetch_rate_test.dart test/features/accounting/presentation/widgets/conversion_preview_test.dart test/widget/features/accounting/presentation/screens/manual_one_step_foreign_triple_test.dart</automated>
  </verify>
  <done>Add screen renders the shared `CurrencyLinkedEditFields` card (no `ConversionPreviewPanel` big block); a date-picker change on BOTH screens auto-refetches the rate and updates 汇率/日元/汇率日期/staleness; edit screen's picker path still fires ADR-022 D-02 dialog / D-03 toast; `foreignPushIsStale` date guard intact; persisted JPY == card JPY via single `convertToJpy`; RateSignal stays in `ref.listen`/`onSignal`; no production reference to a removed `ConversionPreviewPanel`; `flutter analyze` 0 issues.</done>
</task>

<task type="auto">
  <name>Task 3: Re-baseline affected goldens (macOS), full suite + analyze green, append ADR-022 Update — D-1, D-2, D-3, D-4</name>
  <files>test/golden/currency_linked_edit_fields_golden_test.dart, docs/arch/03-adr/ADR-022_Edit_Semantics.md</files>
  <behavior>
    - The unified card changes the rendered rows on both screens, so `currency_linked_edit_fields_golden_test.dart` (and any add-screen foreign golden that previously captured the `ConversionPreviewPanel` `≈¥` block) must be updated to the new card contract and re-baselined. Goldens are macOS-baselined ONLY (see MEMORY: golden CI platform gate) — regenerate with `--update-goldens` on macOS, never on CI/ubuntu. Do NOT `dart format` the whole `test/` tree (repo is not format-clean).
    - Full `flutter test` passes (the unified card touches widget + golden + the edit/add foreign tests; run the FULL suite, not a scoped subset — architecture tests like `hardcoded_cjk_ui_scan` and the format/import guards only fire on the full run, per MEMORY).
    - `flutter analyze` reports 0 issues.
    - ADR-022 gets an append-only `## Update YYYY-MM-DD: 外币卡片两屏统一` section (NOT a rewrite of the decision body — ADR is append-only after acceptance, see .claude/rules/arch.md) recording: 汇率日期行不再可点击（去掉 edit_date_change_trigger TextButton）、重取从行点击移到 date picker 变更、汇率日期显示实际汇率生效日期 + 周末/节假日 staleness、两屏复用同一 CurrencyLinkedEditFields 卡片、添加页移除 ≈¥ 大预览块、添加页汇率行可编辑触发 manual-override。D-01 单向换算与单一 convertToJpy 站点不变。
  </behavior>
  <action>On macOS, run `flutter test --update-goldens test/golden/currency_linked_edit_fields_golden_test.dart` (and any add-screen foreign golden touched by the preview removal) to re-baseline; visually sanity-check the new masters show the labeled `汇率日期` row + staleness on both screens. Run the FULL `flutter test` and `flutter analyze` — both must be green / 0 issues. Append a `## Update {today}: 外币卡片两屏统一（D-1..D-4）` section to `docs/arch/03-adr/ADR-022_Edit_Semantics.md` (append-only) documenting the interaction/display changes listed above and reaffirming the ADR-022 D-01 single-direction + single `convertToJpy` invariant. Do not run `dart format` over `test/`.</action>
  <verify>
    <automated>flutter test && flutter analyze 2>&1 | grep -v '^#' | grep -c 'issues found' </automated>
  </verify>
  <done>Affected goldens re-baselined on macOS and committed; full `flutter test` green; `flutter analyze` 0 issues; ADR-022 has a new append-only `## Update` section documenting the two-screen unification, the non-clickable date row, the picker-driven refetch, the actual-rate-date + staleness display, and the add-screen preview-block removal, while reaffirming the D-01 single-direction / single-convertToJpy invariant.</done>
</task>

</tasks>

<verification>
- Add screen: foreign entry shows the labeled card (`汇率` editable / `日元（换算）` derived / `汇率日期` non-clickable) and NO `≈¥` big preview block (D-1).
- Both screens: 汇率日期 shows the actual effective rate date; when actual ≠ transaction date, the amber weekend/holiday staleness note appears (D-2).
- Edit card: `edit_date_change_trigger` TextButton removed; `edit_rate_date` non-clickable labeled row present (D-3).
- Both screens: changing the date via the picker auto-refetches and updates 汇率/日元/汇率日期/staleness; edit fires ADR-022 D-02 dialog / D-03 toast (D-4).
- Invariants: single `convertToJpy` site; persisted JPY == card JPY; RateSignal only via `ref.listen`/`onSignal`; `foreignPushIsStale` date guard intact.
- i18n: `currencyRateDateLabel` in all 3 ARB + gen-l10n; no hardcoded strings/colors/date formats.
- `flutter test` full suite green; `flutter analyze` 0 issues; goldens re-baselined on macOS only.
- ADR-022 append-only Update section added.
</verification>

<success_criteria>
- D-1: two screens visually + interactively identical (same card, no big preview).
- D-2: 汇率日期 = actual effective date + staleness on both screens.
- D-3: date row non-clickable labeled, no refetch-on-tap.
- D-4: date-picker change auto-refetches on both screens with consistent D-02/D-03 UX.
- All constraints honored: ADR-022 D-01 single-direction, single convertToJpy, ref.listen side-effects, macOS-only goldens, full suite + analyze green, ADR-022 appended.
</success_criteria>

<output>
Create `.planning/quick/260613-ufn-unify-foreign-currency-card/260613-ufn-SUMMARY.md` when done
</output>
