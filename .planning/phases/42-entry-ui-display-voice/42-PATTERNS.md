# Phase 42: 输入与展示 + 语音 (Entry UI + Display + Voice) - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 15 (3 new artifacts, 11 extend targets, 1 new-test family)
**Analogs found:** 15 / 15 (every new artifact has a concrete in-tree analog)

> Brownfield Flutter phase. Most work **EXTENDS** existing widgets in place — for those, this map points the planner at the exact existing pattern *within* the target file to replicate, not an external analog. The genuinely **NEW** artifacts (`CurrencySelectorSheet`, preview panel, `AmountInputController`, dialog/toast, recent-use provider, Wave-0 tests) each map to a closest existing analog with line references.
>
> All paths absolute-relative to repo root `/Users/xinz/Development/home-pocket-app`.

---

## File Classification

| File | New/Extend | Role | Data Flow | Closest Analog | Match |
|------|------------|------|-----------|----------------|-------|
| `lib/features/accounting/presentation/widgets/currency_selector_sheet.dart` | **New** | widget (modal sheet) | request-response (returns ISO code) | `lib/features/list/presentation/widgets/list_category_filter_sheet.dart` | exact (modal sheet + list rows + apply) |
| `lib/features/accounting/presentation/widgets/conversion_preview_panel.dart` | **New** | widget (async consumer) | event-driven / async render | `lib/features/list/presentation/widgets/list_calendar_header.dart` (`.when` block, lines 246-268) | role+flow match (AsyncValue in-place loading) |
| `lib/features/accounting/presentation/widgets/amount_input_controller.dart` (or `lib/shared/utils/`) | **New** | pure-Dart controller / state machine | transform | `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` `_onDigit/_onDot/_onDoubleZero` (lines 212-250) + `convertToJpy()` immutable-input style | role match (host-owns-amount logic, currently inline) |
| `lib/features/accounting/presentation/widgets/change_rate_confirmation_dialog.dart` | **New** | widget (dialog) | request-response (2-choice) | `showSoftConfirmDialog` usage in `list_transaction_tile.dart:99-105` | role match (soft confirm dialog) |
| (recent-use currency provider) `lib/features/accounting/presentation/providers/*.dart` | **New** | provider (session state) | pub-sub | existing `@riverpod` providers under `presentation/providers/` (non-persisted Notifier) | role match |
| `lib/features/accounting/presentation/widgets/smart_keyboard.dart` | **Extend** | widget (keypad) | event-driven | self — `_CurrencyKey` (286-334) + `onDot?` hook (37, 149) + `_buildExtraRow` (116-157) | in-file |
| `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` | **Extend** | screen (host) | event-driven | self — `_onDigit` 4-decimal cap (212-250), `updateAmount` sync (222) | in-file |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | **Extend** | widget (4-host form) | CRUD | self — `updateAmount` (223), `updateCategory` (237), `submit()` (425) | in-file |
| `lib/application/accounting/update_transaction_use_case.dart` | **Extend (GAP)** | use case | CRUD | sibling `create_transaction_use_case.dart` (triple + partial-triple validation, lines 30-142) | exact sibling |
| `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` | **Extend** | screen (host) | CRUD | self `_save()` (56) + `feedback_toast.dart` `actionLabel/onAction` (41-42) | in-file + util |
| `lib/features/list/presentation/widgets/list_transaction_tile.dart` | **Extend** | widget (list tile) | request-response | self — amount block (224-229), pre-formatted-prop contract | in-file |
| `lib/infrastructure/i18n/formatters/number_formatter.dart` | **Extend** | formatter (util) | transform | self — `_getCurrencyDecimals` (83-91), `_getCurrencySymbol` (54-81) | in-file |
| `lib/shared/utils/currency_conversion.dart` | **Extend (minor)** | util | transform | self — `subunitToUnitFor` (70-78), `convertToJpy` UNCHANGED | in-file |
| `lib/infrastructure/voice/{japanese,chinese}_numeral_state_machine.dart` | **Extend** | infra parser | transform | self — ja `_skipPattern` (66), `normalize` skip-branch (111-114); zh silent-drop (93) | in-file |
| `lib/shared/constants/voice_currency_suffixes.dart` + `lib/features/accounting/domain/models/voice_parse_result.dart` + `lib/application/voice/parse_voice_input_use_case.dart` | **Extend** | constants / model / use case | transform | self — `all` longest-first list (22-36); `@freezed` model | in-file |
| `test/**` (6 Wave-0 files + new goldens) | **New** | test | — | `test/golden/list_category_filter_sheet_golden_test.dart`; `test/helpers/test_provider_scope.dart` | exact |

---

## Pattern Assignments

### `currency_selector_sheet.dart` (NEW — widget, modal sheet)

**Analog:** `lib/features/list/presentation/widgets/list_category_filter_sheet.dart` (read in full this session — closest in-tree modal sheet with list rows, palette, S.of, apply bar). Copy its skeleton wholesale; swap category rows for currency rows and add a search field.

**Imports + class shape** (analog lines 1-43): `ConsumerStatefulWidget`, imports `core/theme/app_palette.dart` (for `context.palette`), `core/theme/app_text_styles.dart`, `generated/app_localizations.dart` (for `S`), and `settings/presentation/providers/state_locale.dart` for `currentLocaleProvider`. Constructor takes seed state + an `onApply`/`ValueChanged` callback — mirror for `ValueChanged<String>? onSelect` returning the ISO code (CURR-03).

**Sheet container + drag handle + header + Divider** (analog lines 130-182):
```dart
final palette = context.palette;
return Container(
  height: screenHeight * 0.65,
  decoration: BoxDecoration(
    color: palette.background,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
  ),
  child: Column(children: [
    // 40x4 drag handle (palette.borderDivider)
    // header Row: title (AppTextStyles.titleMedium) + action TextButton
    // Divider(height:1, color: palette.borderDivider)
```

**Locale-aware row data** (analog lines 127, 193-196): `final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');` — note `.value` (nullable, Riverpod 3 — NOT `.valueOrNull`). The analog resolves localized category names via `CategoryLocalizationService.resolve(name, locale)`; for currencies resolve the **localized name via `S.of(context)`** keyed by a `Map<isoCode, l10nKey>` (RESEARCH Q1: names come from ARB, not a package).

**Tappable 48dp row** (analog `InkWell` rows lines 200-261): each currency row = `InkWell(onTap:...)` wrapping `Padding(EdgeInsets.symmetric(horizontal:16, vertical:12))` → `Row`. For D-01 the row content is `🇺🇸 $ USD 美元` (flag emoji + `currencySymbol` + ISO code + localized name). Active/selected row uses `palette.accentPrimary` (leaf green, UI-SPEC accent). **48dp floor:** vertical:12 + text gives ≥48dp; verify in golden.

**Apply / cancel bar** (analog lines 276-325): 56dp bottom bar, `TextButton` cancel (`palette.textSecondary`) + `FilledButton` (`backgroundColor: palette.accentPrimary`, label color `palette.card`). For the selector, tapping a row may directly `onSelect(code); Navigator.pop(context);` (no apply bar needed) — but keep the cancel affordance.

**Search field (NEW, not in analog):** add a `TextField` above the `Expanded(ListView)`; filter the row list on code OR name (CURR-02). No in-tree sheet currently has search — use a plain Material `TextField` with `palette` colors and `S.of` hint; the "more" toggle (D-02) switches the filtered list source from common-zone to full ISO 4217.

**Flag-cell golden isolation** (RESEARCH Q2): mask/exclude the flag cell in goldens (emoji renders host-font-dependently). Plan a render-flags-off-in-golden flag or mask region.

---

### `conversion_preview_panel.dart` (NEW — widget, async consumer)

**Analog:** `lib/features/list/presentation/widgets/list_calendar_header.dart` lines 246-268 — the one in-tree widget that `ref.watch`-es an `AsyncValue` and renders **fixed-height in-place loading → data**, exactly the D-04 pattern.

**In-place fixed-height skeleton + data** (analog lines 246-268):
```dart
calendarAsync.when(
  loading: () => SizedBox(
    width: 60, height: 15,
    child: DecoratedBox(decoration: BoxDecoration(
      color: palette.backgroundMuted,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    )),
  ),
  error: (e, st) => Text(l10n.calLoadError, style: AppTextStyles.caption),
  data: (map) => Text(
    NumberFormatter.formatCurrency(total, currencyCode, locale),
    style: AppTextStyles.amountSmall,
  ),
);
```
Replicate the **same-height skeleton** so loading→loaded does not jump (D-04 / Pitfall 5). Main row uses `AppTextStyles.amountLarge` (UI-SPEC Display role, `≈ ¥7,415`), sub-row uses `AppTextStyles.labelMedium` (12px w600 — UI-SPEC Caption role, NOT `AppTextStyles.caption` which is w500).

**Consuming the rate use case** (RESEARCH Pattern 1; provider verified at `lib/application/currency/repository_providers.dart:51`, sealed types at `lib/application/currency/rate_result.dart:122-175`):
```dart
final result = await ref
    .read(appGetExchangeRateUseCaseProvider)
    .execute(GetExchangeRateParams(
      currency: currency, date: txDate,
      previousRate: previousRate, wasManualOverride: wasManualOverride,
    ));
// result.result -> RateResult (render preview / read-only JPY)
// result.signal -> RateSignalDialog | RateSignalToast | null (surface via ref.listen)
```
Wrap `.execute()` in a `FutureProvider`/`AsyncNotifier` keyed on (currency, date, amount); `ref.watch` it for the rendered `RateResult`. **`RateSignal` (D-02 dialog / D-03 toast) MUST be surfaced via `ref.listen`, NOT `ref.watch`** (CLAUDE.md Riverpod-3 / RESEARCH Pitfall 4).

**JPY figure** (single-site invariant #4): compute via `convertToJpy(originalMinorUnits:, appliedRate:, subunitToUnit:)` from `lib/shared/utils/currency_conversion.dart:21` — never inline `double.parse(rate) * amount`.

**Staleness warning label (D-05):** below the sub-row, a `Text` in `palette.warning` (amber `#C98A00`) when `RateResult.fallback` OR `fetched.actualDate ≠ txDate`. Amber is RESERVED for this label only (UI-SPEC color discipline). Copy via `S.of(context)` (ja/zh/en).

**CURR-04 guard:** when `currency == 'JPY'` the panel is NOT mounted at all (no fetch, no render). Mirror the `currency != 'JPY'` guard at every new surface (RESEARCH Pitfall 1).

---

### `amount_input_controller.dart` (NEW — pure-Dart state machine)

**Analog:** the inline logic currently in `manual_one_step_screen.dart:212-250` (`_onDigit/_onDot/_onDoubleZero/_onDelete`) is the behavior to *extract and generalize*. Immutable-state style modeled on `convertToJpy()` (pure function, fails-fast) in `currency_conversion.dart`.

**Current inline cap to REPLACE** (analog lines 212-217 — hardcoded 4-decimal cap, unconditional dot):
```dart
void _onDigit(String digit) {
  final dotIndex = _amount.indexOf('.');
  if (dotIndex >= 0) {
    final decimals = _amount.length - dotIndex - 1;
    if (decimals >= 4) return;   // <-- replace 4 with currency's minor unit (D-07)
  }
  ...
  _formKey.currentState?.updateAmount(parsed);
}
```

**New controller contract** (RESEARCH Q3): immutable state `{digits: String, decimals: int}`.
- `onDigit(d)`: if `.` present and fractional length == `decimals` → ignore (D-07 cap). Else append.
- `onDot()`: only valid when `decimals > 0`. For `decimals == 0`, host passes `onDot: null` to `SmartKeyboard` (D-06) so the dot cell hides/disables — hook already nullable (`smart_keyboard.dart:37,149`).
- `onCurrencyChange(newDecimals)`: **TRUNCATE** the fractional substring to `newDecimals` digits as a **string op** (D-08: `50.50→50`, `50.567→50.56`). NEVER `.round()` (RESEARCH Pitfall 3). Strip a trailing lone `.` when truncating to 0.

Follow CLAUDE.md immutability: each transition returns a new state, never mutates. `decimals` comes from `NumberFormatter._getCurrencyDecimals` / `subunitToUnitFor` (single decimals source per Q1).

---

### `change_rate_confirmation_dialog.dart` + undo toast (NEW — ADR-022 D-02/D-03)

**Dialog analog:** `showSoftConfirmDialog(...)` used at `list_transaction_tile.dart:99-105` (title/body/confirmLabel/cancelLabel, all `S.of(context)`). ADR-022 D-02 needs a **two-choice dialog with NO default** (keep manual rate / re-fetch) — extend the soft-confirm shape to two affirmative actions.

**Toast analog (D-03 undo):** `showFeedbackToast(context, msg, tone:, actionLabel:, onAction:, duration:)` at `lib/shared/widgets/feedback_toast.dart:36-43` — already supports inline action + custom duration. Use `actionLabel: S.of(context).undo` + `onAction:` to restore the old rate, `duration: const Duration(seconds: 5)` (D-03 5s window). Both `RateSignalDialog`/`RateSignalToast` are **pre-computed by the use case** — surface via `ref.listen` (do not recompute the >1% threshold in UI; RESEARCH Don't-Hand-Roll).

---

### `smart_keyboard.dart` (EXTEND — keypad)

**In-file pattern to replicate:**
- **Make `_CurrencyKey` tappable (CURR-01):** currently display-only (`smart_keyboard.dart:184` comment "display only, no tap action"; `_CurrencyKey` 286-334 is a bare `Container`). Convert to a `Material`+`InkWell` like `_DigitKey` (215-253) / `_ActionKey` (255-284), add a `VoidCallback? onCurrencyTap` prop, preserve the `ValueKey('smart_keyboard_currency_key')` (302) for tests/goldens.
- **Dot-gating (D-06):** `onDot` hook already nullable (37) and the dot cell already does `onDot?.call()` (149). For 0-decimal currencies, host passes `onDot: null`. Keep the `_buildExtraRow` 3-equal-width grid (116-157) — render the dot cell as a disabled/blank 48dp tile, do NOT collapse the row (RESEARCH Q3 48dp note — collapsing shifts keys, golden churn, mis-tap risk).
- **48dp floor (NON-NEGOTIABLE):** `keyHeight = math.max(48.0, rawKeyHeight)` at line 59 — preserve in any new/replacement key.

---

### `manual_one_step_screen.dart` (EXTEND — host screen)

**In-file pattern:**
- Replace inline `_onDigit/_onDot/_onDoubleZero/_onDelete` (212-258) with the new `AmountInputController` (host owns it). Keep the `_formKey.currentState?.updateAmount(parsed)` sync call (222, 238, 249, 256) — host-owns-amount, form-syncs (P19 D-14, RESEARCH Pattern 3).
- Add the `conversion_preview_panel` below `AmountDisplay` (RESEARCH map: "after line 407"); panel only mounts when `currency != 'JPY'`.
- On currency change, truncate `_amount` per D-08 via the controller.
- Pass the triple (currency / original amount / rate) into the form for `submit()`.

---

### `transaction_details_form.dart` (EXTEND — 4-host shared form)

**In-file pattern:**
- **Imperative sync methods:** mirror `updateAmount(int)` (223-227) and `updateCategory(...)` (237-249) — both `setState` with an idempotency short-circuit (`if (x == _x) return;`). Add `updateCurrency(String)` / `updateRate(String)` the same way (used by host + voice confirmation).
- **`.edit` host three rows (D-10/D-11/D-12):** two `TextEditingController`-backed inputs (original amount + rate) + one **read-only `Text`** JPY row recomputed via `convertToJpy()` on every change. ONE data-flow direction — no listener writes back into JPY. **MUST NOT** implement three-field bidirectional (ADR-022 D-01; RESEARCH Conflict Resolution).
- **`submit()` (425):** the `.when`/`$new` branch builds `CreateTransactionParams` (449-467). Add the triple to both the `$new` and (new) `$edit` param construction; the edit path calls the extended `UpdateTransactionUseCase`.
- Voice confirmation surfaces `detectedCurrency` here (VOICE-CUR-02/03) → triggers normal rate-fetch.

---

### `update_transaction_use_case.dart` (EXTEND — GAP, application layer)

**Analog:** the sibling `lib/application/accounting/create_transaction_use_case.dart` already has the full triple + partial-triple validation (verified lines 30-142) — **mirror it exactly**.

- `UpdateTransactionParams` (lines 26-51) has NO currency fields. Add `originalCurrency / originalAmount / appliedRate`.
- `execute()` must recompute `amount` via `convertToJpy()` when the triple is present, run the same partial-triple validation as `CreateTransactionUseCase`, and re-save.
- **Hash chain NOT recomputed** (ADR-021 — currency fields excluded from hash; existing skip-rehash behavior at line ~65). Do NOT add currency fields to the hash formula.
- Unit test asserting an edited USD row's JPY is recomputed (Wave-0 `update_transaction_currency_test.dart`).

---

### `transaction_edit_screen.dart` (EXTEND — host screen)

**In-file pattern:** `_save()` (56) delegates to `form.submit()` — keep. For foreign rows, original-amount + rate edits live inside the form `.edit` host (not the `AmountEditBottomSheet` modal at line 105). Wire the ADR-022 D-02 dialog + D-03 toast off the `RateSignal` returned when a date change re-fetches — via `ref.listen`, using the dialog/toast analogs above.

---

### `list_transaction_tile.dart` (EXTEND — list tile, DISP-02)

**In-file pattern:** the tile is a **pure-UI contract** — all display values are pre-formatted props injected by the parent (`formattedAmount` etc., lines 62-68; constructor 40-48). Add a small secondary annotation (`USD 50.00`) near the amount block (224-229), styled `AppTextStyles.labelMedium` / `palette.textSecondary` (UI-SPEC caption + text-secondary). Format the annotation via `NumberFormatter.formatCurrency(originalAmount/subunit, originalCurrency, locale)` — pass it as a new pre-formatted prop from `list_screen.dart` (keep the pure-UI contract; don't fetch inside the tile). **JPY rows: NO change — byte-identical golden (CURR-04).**

---

### `number_formatter.dart` (EXTEND — formatter)

**In-file pattern:** `_getCurrencyDecimals` (83-91) hardcodes only JPY/KRW=0, else 2. Replace `default: 2` with `intl`'s `currencyFractionDigits` lookup (RESEARCH Q1 — correct for BHD/JOD/KWD=3). `_getCurrencySymbol` (54-81) already covers common symbols + ISO-code fallback — extend opportunistically; ISO fallback is acceptable. Route `currency_conversion.subunitToUnitFor` through the **same** `intl` map so decimals + subunit stay consistent.

---

### `currency_conversion.dart` (EXTEND — minor)

**In-file pattern:** `subunitToUnitFor` (70-78) hardcodes JPY/KRW=1 else 100. Use `pow(10, intl-fraction-digits)` for 3-decimal correctness. **`convertToJpy()` (21-41) UNCHANGED** — it is the single conversion site (ADR-020), preview/list/edit all call it. `validateAppliedRate` (53-63) is the single rate-parse validator — reuse for manual-rate input.

---

### Voice files (EXTEND — infra parsers + model + use case)

**In-file patterns:**
- `voice_currency_suffixes.dart` `all` (22-36): add `Map<token, isoCode>` (zh: 美元→USD, 欧元→EUR, 英镑→GBP, 港币→HKD, 澳元→AUD, 加元→CAD; ja: ドル→USD, ユーロ→EUR, ポンド→GBP, 香港ドル→HKD, 豪ドル→AUD). **Keep longest-first ordering** (香港ドル before ドル; 日元 before 元 — invariant at 23-27). Add new tokens to `all` so `_extractKeyword` strips them (RESEARCH Pitfall 6).
- `japanese_numeral_state_machine.dart`: `_skipPattern` (66) currently *skips* `¥￥円えんyen`; the normalize skip-branch is at 111-114. Extend to **detect** ドル/ユーロ/ポンド (not just skip) and return detected currency separately from the integer amount.
- `chinese_numeral_state_machine.dart`: silently drops non-numeral runes (line 93, Step 5). Add currency-suffix detection before the drop.
- `voice_parse_result.dart`: `@freezed` — add `String? detectedCurrency` (null = JPY-native), run `build_runner`.
- `parse_voice_input_use_case.dart`: plumb `detectedCurrency` from the machine into `VoiceParseResult`; extend `_extractKeyword` (line ~132) alternation so new tokens are stripped from keywords.
- Bare-token defaults (locked): `元` → zh=CNY / ja=JPY-terminator; `円` → JPY; `ドル` → USD.

---

### Test files (NEW — Wave 0 + goldens)

**Golden analog:** `test/golden/list_category_filter_sheet_golden_test.dart` (read in full) — copy its structure exactly for the `CurrencySelectorSheet` + preview-panel + edit-three-row + foreign-list-row goldens.
- `@Tags(['golden'])` + `library;` header (lines 1-2).
- `_wrap({required Locale locale, ThemeMode themeMode})` helper (111-147): `ProviderScope(overrides:[...])` with `currentLocaleProvider.overrideWith((_) async => locale)` to kill async retry timers; `MaterialApp` with `S.delegate` + `Global*Localizations.delegate`, `supportedLocales: S.supportedLocales`.
- 6 cases per widget: {ja, zh, en} × {light, dark}, each `pumpAndSettle()` then `expectLater(find.byType(...), matchesGoldenFile('goldens/<name>_<locale>.png'))` (149-210).
- Fake repos as needed (analog `_FakeCategoryRepository` 26-74) — for the preview panel, override `appGetExchangeRateUseCaseProvider` / its rate provider with a fake returning each `RateResult` variant (fetched / fallback / weekend-actualDate / unavailable).
- **Flag-cell masking** (RESEARCH Q2): isolate flag emoji from selector goldens.
- macOS-baseline workflow; CI ubuntu uses `BaselineExistenceGoldenComparator` (`test/flutter_test_config.dart`, MEMORY.md).

**Async unit/widget analog:** `test/helpers/test_provider_scope.dart` — use `waitForFirstValue<T>(container, provider)` (signature `Future<AsyncValue<T>> waitForFirstValue<T>(...)` at line 34) and `ProviderContainer.test()`; do NOT bare-`await container.read(provider.future)` on auto-dispose providers (CLAUDE.md / RESEARCH Pitfall 4).

Wave-0 files to create (from RESEARCH Test Map):
- `test/application/accounting/create_transaction_currency_test.dart` — SC-5 USD 50@148.30→`amount=7415`.
- `test/application/accounting/update_transaction_currency_test.dart` — edited triple recompute + no-rehash.
- `test/.../amount_input_controller_test.dart` — D-07 cap + D-08 truncation boundaries (`0.99→0`, `50.5→50`, `50.567→50.56`).
- `test/infrastructure/voice/currency_detection_test.dart` — per-currency × per-locale corpus + bare-token defaults + 元/円 ambiguity.
- `test/.../edit_currency_linked_test.dart` — ADR-022 D-01/D-02/D-03.
- New goldens (above).

---

## Shared Patterns

### Color / Theme access
**Source:** `context.palette` (`core/theme/app_palette.dart`), used everywhere (e.g. `list_category_filter_sheet.dart:130`, `smart_keyboard.dart:51`).
**Apply to:** ALL new widgets. NEVER hardcode hex (CLAUDE.md / ADR-019 v1.6 桜餅×若葉).
- Active/selected currency, active input border, CTA → `palette.accentPrimary` (leaf green `#6FA36F`).
- Staleness warning → `palette.warning` (amber `#C98A00`) — RESERVED for D-05 only.
- Sub-rows / annotations / captions → `palette.textSecondary`.
- Sakura pink `#D98CA0` is OFF-LIMITS (FAB / Joy identity only).

### Amount typography
**Source:** `AppTextStyles.amountLarge/amountMedium/amountSmall` (tabular figures) — `list_transaction_tile.dart:226`, `smart_keyboard.dart:315`.
**Apply to:** preview main row (`amountLarge`), list foreign annotation + read-only JPY (`amountSmall`/`labelMedium`). Captions/sub-rows → `AppTextStyles.labelMedium` (12px w600), NOT `AppTextStyles.caption` (w500) — UI-SPEC typography note.

### i18n
**Source:** `S.of(context)` + `currentLocaleProvider` (`list_category_filter_sheet.dart:127,161`); dates via `DateFormatter`, currency via `NumberFormatter.formatCurrency`.
**Apply to:** ALL new copy. Update all 3 ARB files (ja/zh/en) then `flutter gen-l10n`. Note Riverpod 3: `currentLocaleProvider.value` is nullable (`?? const Locale('ja')`) — NOT `.valueOrNull`.

### Single conversion site (Hard Invariant #4)
**Source:** `convertToJpy()` in `lib/shared/utils/currency_conversion.dart:21`.
**Apply to:** preview panel, list annotation, edit read-only JPY — all three. Guarantees identical figures + matches the persisted value (`CreateTransactionUseCase` calls the same function). NEVER inline `double.parse(rate) * amount` (ADR-020).

### Riverpod 3 watch/listen split
**Source:** `ref.watch` for render (`list_calendar_header.dart:52`), `ref.listen` for side-effects (CLAUDE.md FamilySyncNotificationRouteListener precedent).
**Apply to:** preview panel + edit host — `ref.watch` the `RateResult`; `ref.listen` the `RateSignal` (D-02 dialog / D-03 toast). Provider names strip the `Notifier` suffix; `AsyncValue.value` is nullable.

### Host-owns-amount, form-syncs (P19 D-14)
**Source:** `manual_one_step_screen.dart` `_formKey.currentState?.updateAmount(parsed)` (222) ↔ `transaction_details_form.dart` `updateAmount` (223).
**Apply to:** new `updateCurrency`/`updateRate` imperative sync methods; mirror the idempotency short-circuit.

### Feedback toast with action
**Source:** `showFeedbackToast(context, msg, tone:, actionLabel:, onAction:, duration:)` (`feedback_toast.dart:36-43`).
**Apply to:** D-03 undo toast (`duration: 5s`, `actionLabel: undo`, `onAction:` restores old rate).

---

## No Analog Found

None. Every NEW artifact has an in-tree analog (the `CurrencySelectorSheet` search field is the only sub-component without a direct precedent — use a plain Material `TextField`; the surrounding sheet is fully analog-backed).

The **decimal-input state machine** has no precedent as a *standalone controller* (CONTEXT/RESEARCH both flag this), but its behavior is the inline logic in `manual_one_step_screen.dart:212-250` generalized — so it is analog-backed for behavior, novel only in structure.

---

## Metadata

**Analog search scope:** `lib/features/**/presentation/widgets/` (sheets/selectors), `lib/features/**/presentation/screens/` (hosts), `lib/infrastructure/{i18n,voice}/`, `lib/shared/{utils,constants,widgets}/`, `lib/application/{accounting,currency,voice}/`, `test/golden/`, `test/helpers/`.
**Files scanned:** ~25 grep passes + 12 targeted reads.
**Pattern extraction date:** 2026-06-13
