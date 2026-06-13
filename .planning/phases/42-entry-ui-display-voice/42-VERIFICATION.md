---
phase: 42-entry-ui-display-voice
verified: 2026-06-13T14:05:00Z
status: human_needed
score: 12/12 must-have truth-clusters verified
overrides_applied: 0
human_verification:
  - test: "Edit-screen date change for a foreign row — D-02 dialog path"
    expected: "Open a saved foreign (e.g. USD) transaction in edit mode that has a manual-override rate, change the transaction date via the date picker → a two-choice ChangeRateConfirmationDialog appears (keep manual / re-fetch, NO default) and choosing re-fetch updates the rate from the real rate service, recomputing the read-only JPY"
    why_human: "The production date picker (_editDate) only sets _date; it does not call the rate use case. D-02 is reachable in code only via CurrencyLinkedEditFields' internal demo trigger using a hardcoded stub rate ('160.00'). Whether the real edit screen surfaces D-02 on a date change cannot be confirmed by static analysis — requires running the app and editing a saved foreign row's date."
  - test: "Edit-screen date change for a foreign row — D-03 toast path"
    expected: "For a foreign row WITHOUT a manual override, changing the date such that the re-fetched rate moves JPY >1% shows a non-blocking toast with an Undo (5s) restoring the old rate, using the REAL re-fetched rate (not a stub)"
    why_human: "Same wiring boundary as above. The >1% delta + toast/undo widget is tested in isolation against a stub rate; the real edit-screen path does not pass dateChangeRefetchRate and does not re-fetch. Requires manual edit-screen date change on a real foreign row to confirm the production behavior."
  - test: "Flag-emoji rendering in CurrencySelectorSheet on real iOS + Android devices"
    expected: "🇺🇸 / 🇪🇺 / 🇨🇳 etc. render as recognizable flags (not tofu boxes) across iOS and Android; EUR/no-1:1-country fallbacks look acceptable"
    why_human: "Goldens are macOS-baselined; CONTEXT.md deferred-idea explicitly flags cross-platform flag-emoji rendering as a real-device visual risk that goldens cannot catch."
  - test: "Live conversion preview visual behavior during foreign entry"
    expected: "Preview appears below the amount, updates on every keypad tap / currency change / date change; loading is an in-place skeleton (no jump, no keyboard occlusion); stale/fallback rate shows an amber warning label"
    why_human: "Real-time UI feel (no-jump skeleton, no keyboard occlusion) and staleness-label timing are visual/temporal behaviors not verifiable by grep or widget unit tests."
---

# Phase 42: 输入与展示 + 语音 (Entry UI + Display + Voice) Verification Report

**Phase Goal:** Users can select a foreign currency on the SmartKeyboard (or speak it in zh/ja), enter a decimal amount per the currency's minor unit, watch a live JPY conversion preview, save, see the original currency annotated in the list, and fully view/edit it in the detail/edit view — while the JPY-only path remains completely untouched.
**Verified:** 2026-06-13T14:05:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

All 9 plans' must_have truth-clusters were verified against actual code + passing tests. The edit model was verified to be **two-input/one-derived** per ADR-022 D-01 (the ROADMAP/SC-4 "bidirectional three-field" wording is VOID); a bidirectional implementation would have been a defect — it is correctly absent.

| #   | Truth (must_have) | Status | Evidence |
| --- | ----------------- | ------ | -------- |
| 1   | Single conversion site: `convertToJpy()` is the ONLY place JPY is computed (preview / list / edit) | ✓ VERIFIED | `convertToJpy` defined once in `lib/shared/utils/currency_conversion.dart:25`; every caller imports it (manual screen, edit fields, preview panel, update/create use cases). No second definition. |
| 2   | SC-5 integration smoke: USD 50 @ 148.30 → `amount=7415`, `original_currency='USD'` | ✓ VERIFIED | `test/application/accounting/create_transaction_currency_test.dart` group "SC-5 integration smoke" asserts `expectedJpy=7415`, `originalCurrency='USD'`, `originalAmount=5000`, `appliedRate='148.30'`; persisted-row assertions present. Test GREEN. |
| 3   | Per-currency decimals from intl `currencyFractionDigits` (not hardcoded 2); `convertToJpy` UNCHANGED (ADR-020) | ✓ VERIFIED | `currency_conversion.dart` imports `currencyFractionDigits`; `currencyFractionDigitsFor`/`subunitToUnitFor` use `pow(10, fractionDigits)`; KRW pinned 0; `convertToJpy` formula `(units/subunit*rate).round()` unchanged. `number_formatter.dart` extended. |
| 4   | UpdateTransaction carries triple, recomputes JPY via single site, partial-triple → error, currency fields EXCLUDED from hash (ADR-021, no rehash) | ✓ VERIFIED | `update_transaction_use_case.dart:111-159`: coalesces triple, calls `validateCurrencyTriple`, `resolvedAmount=tripleResult.jpyAmount` for foreign rows; `copyWith` leaves `prevHash`/`currentHash` at seed default (no rehash). `update_transaction_currency_test.dart` GREEN. |
| 5   | D-07 decimal cap + D-08 string-truncate (never rounds); JPY/KRW 0-decimal | ✓ VERIFIED | `amount_input_controller.dart`: `appendDigit` caps at `decimals`; `truncateToDecimals` is a string op on currency change. `amount_input_controller_test.dart` GREEN (50.50→50, 50.567→50.56, 0.99→0 boundaries). |
| 6   | D-06 dot-gating: `onDot:null` for 0-decimal; 48dp floor + 3-equal action row preserved; JPY dot byte-identical (CURR-04) | ✓ VERIFIED | `smart_keyboard.dart` dot-gated extra row; host passes `onDot:null` for JPY. `smart_keyboard_dot_gating_test.dart` golden suite GREEN (JPY dot-gated light/dark, USD dot-enabled light/dark). |
| 7   | CurrencySelectorSheet: JPY-first, common zone re-ordered by recent use, "more"+search, flag+symbol+ISO+localized-name rows; non-persisted session provider resets to JPY (CURR-01/02/03) | ✓ VERIFIED | `currency_selector_sheet.dart` (430 lines) consumes `recentCurrencyProvider.orderedCommonZone()`; `state_recent_currency.dart` is a `@riverpod` session class (build()=[], `recordUse` LRU, JPY excluded). `currency_selector_sheet_golden_test.dart` GREEN (ja/zh/en + dark). |
| 8   | Live JPY preview: main JPY row + rate sub-row via single site; in-place skeleton; amber staleness label; RateSignal via `ref.listen`; NOT mounted for JPY (DISP-01, CURR-04) | ✓ VERIFIED | `conversion_preview_panel.dart` asserts `currency != 'JPY'` (line 144), consumes `appGetExchangeRateUseCaseProvider`, computes JPY via `convertToJpy` (line 268). `conversion_preview_test.dart` GREEN. (Visual feel → human verify.) |
| 9   | Foreign list rows show secondary annotation (USD 50.00); JPY rows byte-identical (DISP-02, CURR-04) | ✓ VERIFIED | `list_transaction_tile.dart`: `foreignAnnotation` prop is `null` for JPY rows → bare Text unchanged; foreign rows render annotation. `list_transaction_tile_foreign_golden_test.dart` GREEN. |
| 10  | Edit host: three rows (amount + rate editable, JPY read-only derived); one direction only; NO bidirectional loop (ADR-022 D-01) | ✓ VERIFIED | `currency_linked_edit_fields.dart`: rows 1-2 are `TextField`, row 3 is a read-only `Text` (key `edit_jpy_derived`); `_deriveJpy()` is the only flow direction. `edit_currency_linked_test.dart` "JPY field is not editable (no TextField for JPY)" GREEN. **Bidirectional absence is correct, not a gap.** |
| 11  | ADR-022 D-02 dialog (no default) + D-03 toast+undo (5s) UX widgets exist | ✓ VERIFIED (widget) / ⚠️ wiring incomplete | `change_rate_confirmation_dialog.dart` (AlertDialog, `keepManual`/`refetch`, no default); D-03 toast+undo in `currency_linked_edit_fields.dart`. D-02/D-03 tests GREEN. **But production date-refetch wiring is a stub — see WARNING below + human_verification.** |
| 12  | Voice zh/ja currency detection → `VoiceParseResult.detectedCurrency`; bare 元 (zh=CNY/ja=JPY) + bare ドル=USD; surfaces editable on form, triggers rate-fetch; existing corpus unchanged (VOICE-CUR-01/02/03) | ✓ VERIFIED | `voice_currency_suffixes.dart` token→ISO map (longest-first); `voice_parse_result.dart` carries `detectedCurrency`; `voice_input_screen.dart:372-375` surfaces it via `state.updateCurrency` (JPY-native = no-op). `currency_detection_test.dart` + voice regression GREEN. |

**Score:** 12/12 truth-clusters verified (truth #11's UX widgets verified; its production date-refetch wiring is incomplete → WARNING + routed to human verification).

### Required Artifacts

| Artifact | Status | Details |
| -------- | ------ | ------- |
| `lib/shared/utils/currency_conversion.dart` | ✓ VERIFIED | Single `convertToJpy` site + `validateCurrencyTriple` shared by create/update. |
| `lib/infrastructure/i18n/formatters/number_formatter.dart` | ✓ VERIFIED | intl-backed decimals + extended symbol fallback. |
| `lib/application/accounting/update_transaction_use_case.dart` | ✓ VERIFIED | Triple + recompute + no-rehash (ADR-021). |
| `lib/shared/constants/voice_currency_suffixes.dart` | ✓ VERIFIED | token→ISO map, longest-first. |
| `lib/features/accounting/domain/models/voice_parse_result.dart` | ✓ VERIFIED | `detectedCurrency` field. |
| `lib/application/voice/parse_voice_input_use_case.dart` | ✓ VERIFIED | detectedCurrency plumbed. |
| `lib/features/accounting/presentation/widgets/amount_input_controller.dart` | ✓ VERIFIED | D-07/D-08 state machine. |
| `lib/features/accounting/presentation/widgets/smart_keyboard.dart` | ✓ VERIFIED | Dot-gated row, 48dp floor. |
| `lib/features/accounting/presentation/widgets/currency_selector_sheet.dart` | ✓ VERIFIED | JPY-first, search, more, flag rows. |
| `lib/features/accounting/presentation/providers/state_recent_currency.dart` | ✓ VERIFIED (path deviation) | Planned as `recent_currency_provider.dart`; **renamed to `state_recent_currency.dart` in commit `9f6f799a`** to satisfy provider-graph-hygiene (HIGH-04) `state_*` convention. Wired + used in 4 call sites. Intentional, committed. |
| `lib/features/accounting/presentation/widgets/conversion_preview_panel.dart` | ✓ VERIFIED | Async consumer of `appGetExchangeRateUseCaseProvider`; JPY-guard assert. |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | ✓ VERIFIED | Edit host renders `CurrencyLinkedEditFields` for foreign rows only (line 852-879); JPY rows skip it. |
| `lib/features/accounting/presentation/widgets/change_rate_confirmation_dialog.dart` | ✓ VERIFIED | ADR-022 D-02 two-choice, no default. |
| `lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart` | ⚠️ ORPHANED data-source (date-refetch) | Two-input/one-derived correct; but `dateChangeRefetchRate` never supplied by production host → date-trigger uses hardcoded `_kStubRefetchRate='160.00'`. |
| `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` | ✓ VERIFIED | Host wiring: controller + selector + preview + triple → SC-5; JPY clears triple. |
| `lib/features/list/presentation/widgets/list_transaction_tile.dart` | ✓ VERIFIED | Foreign annotation prop; JPY unchanged. |

### Key Link Verification

| From | To | Via | Status |
| ---- | -- | --- | ------ |
| update_transaction_use_case | currency_conversion `convertToJpy` | recompute when triple present | ✓ WIRED |
| amount_input_controller | currencyFractionDigits | decimals single source | ✓ WIRED |
| currency_selector_sheet | currentLocaleProvider / recentCurrencyProvider | localized names + recent reorder | ✓ WIRED |
| conversion_preview_panel | `appGetExchangeRateUseCaseProvider` (P41) | ref.watch keyed result | ✓ WIRED |
| voice_input_screen | shared form `updateCurrency` | detectedCurrency surfaces → rate-fetch | ✓ WIRED |
| transaction_details_form | CurrencyLinkedEditFields | foreign-row edit host (onChanged lock-step) | ✓ WIRED |
| **edit-screen `_editDate` / CurrencyLinkedEditFields** | **`appGetExchangeRateUseCaseProvider` (real date re-fetch)** | **dateChangeRefetchRate from rate use case** | **✗ NOT_WIRED — stub rate `'160.00'`; production date picker does not re-fetch** |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| conversion_preview_panel | rate result | `appGetExchangeRateUseCaseProvider` (P41 dual-source) | Yes | ✓ FLOWING |
| currency_linked_edit_fields (amount/rate inputs → JPY) | `_originalAmount`/`_appliedRate` | TextField onChanged | Yes | ✓ FLOWING |
| currency_linked_edit_fields (date-change re-fetch) | `newRate` | `dateChangeRefetchRate ?? '160.00'` (stub) | **No — hardcoded constant** | ⚠️ STATIC |
| list_transaction_tile | `foreignAnnotation` | pre-formatted prop from host | Yes (null for JPY) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Phase 42 core tests (SC-5, D-07/D-08, voice, ADR-022 edit, update) | `flutter test` on 5 Wave-0 test files | 31/31 passed | ✓ PASS |
| Goldens + hygiene + preview + dot-gating | `flutter test` (selector/list/preview/dot/hygiene) | 39/39 passed | ✓ PASS |
| Architecture suite (import_guard, hardcoded-CJK, provider-graph-hygiene) | `flutter test test/architecture/` | 47/47 passed | ✓ PASS |
| Voice corpus regression (existing cases unchanged) | `flutter test test/infrastructure/voice/` | passed | ✓ PASS |
| Static analysis | `flutter analyze` | No issues found! | ✓ PASS |
| Full suite (orchestrator final gate) | full `flutter test` | 2782/2782 passed | ✓ PASS (reported) |

### Requirements Coverage

All 12 Phase 42 requirement IDs declared in PLAN frontmatter are present in REQUIREMENTS.md (mapped to Phase 42, status Complete) — none orphaned.

| Requirement | Source Plan(s) | Status | Evidence |
| ----------- | -------------- | ------ | -------- |
| CURR-01 | 42-06, 42-08 | ✓ SATISFIED | Tappable currency key → CurrencySelectorSheet without leaving entry screen. |
| CURR-02 | 42-06 | ✓ SATISFIED | JPY-first, common zone re-ordered by recent use, "more"+search by code OR name. |
| CURR-03 | 42-06, 42-08 | ✓ SATISFIED | `state_recent_currency.dart` non-persisted session LRU; resets to JPY on restart. |
| CURR-04 | 42-05, 42-07, 42-08 | ✓ SATISFIED | JPY: no dot, no preview (asserted), no annotation, no triple; goldens byte-identical. |
| CURR-05 | 42-02, 42-05, 42-08 | ✓ SATISFIED | Per-ISO-4217 decimal cap (D-07) + truncate (D-08). |
| DISP-01 | 42-07, 42-08 | ✓ SATISFIED (visual → human) | Live preview consuming real rate use case; mounts only for foreign. |
| DISP-02 | 42-02, 42-08 | ✓ SATISFIED | Foreign list annotation; JPY rows unchanged. |
| DISP-03 | 42-03, 42-09 | ✓ SATISFIED | Edit host shows original currency / amount / rate. |
| DISP-04 | 42-01, 42-03, 42-09 | ✓ SATISFIED | Two-input/one-derived (ADR-022 D-01 supersedes "bidirectional" wording). |
| VOICE-CUR-01 | 42-04 | ✓ SATISFIED | zh 美元/欧元/英镑/港币/澳元/加元 → ISO; bare 元 keeps JPY-terminator. |
| VOICE-CUR-02 | 42-04, 42-09 | ✓ SATISFIED | ja ドル/ユーロ/ポンド/香港ドル/豪ドル; bare ドル=USD; editable on form. |
| VOICE-CUR-03 | 42-04, 42-09 | ✓ SATISFIED | detectedCurrency surfaces on shared form, triggers normal rate-fetch flow. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `currency_linked_edit_fields.dart` | 56 | `_kStubRefetchRate = '160.00'` hardcoded date-refetch rate | ⚠️ Warning | Date-change re-fetch in the edit host uses a constant instead of the real `appGetExchangeRateUseCaseProvider` because `dateChangeRefetchRate` is never passed by the production host (see WARNING below). |

No `TBD`/`FIXME`/`XXX` debt markers in any Phase 42 file. No empty/console-only implementations. No hollow empty-data props.

### WARNING — Edit-screen date-change rate re-fetch is not wired to production

**What is correct:** The Phase 42 edit-model deliverable — two-input/one-derived linked editing (original amount + rate editable, JPY read-only derived via the single-site `convertToJpy()`) — is fully implemented, correctly NON-bidirectional per ADR-022 D-01, wired into `transaction_details_form` for foreign rows only, and test-locked. The ADR-022 D-02 dialog and D-03 toast+undo **widgets** exist and pass their unit tests. Phase 41's `GetExchangeRateUseCase.execute()` already computes the canonical D-02/D-03 `RateResultWithSignal` (dialog/toast) server-side.

**What is incomplete:** These two halves are **not connected in the production edit path**:
- `CurrencyLinkedEditFields.dateChangeRefetchRate` is never supplied by any production caller (`grep` confirms only the field definition + the stub-fallback line). The internal date-change trigger therefore always uses the hardcoded `_kStubRefetchRate = '160.00'`.
- The real edit-screen date picker (`transaction_details_form._editDate`, wired to the visible date row at line 842) only calls `setState(() => _date = picked)` — it does **not** re-fetch the rate, does **not** raise the D-02 dialog, and does **not** raise the D-03 toast for foreign rows.
- `appGetExchangeRateUseCaseProvider` is consumed ONLY by `conversion_preview_panel.dart` (the entry-screen preview), not by the edit host.

**Severity rationale (WARNING, not BLOCKER):**
- The date-change re-fetch behavior traces to **RATE-06**, which REQUIREMENTS.md maps to **Phase 41** (status Complete) — it is NOT one of Phase 42's 12 requirement IDs.
- Phase 42's own goal edit-clause ("fully view/edit it in the detail/edit view" via two-input/one-derived) is achieved.
- The 42-09 SUMMARY (line 138) explicitly states production date-refetch wiring "can be layered on without changing the widget's contract" — i.e., acknowledged as not done here.
- This is a wiring gap at the Phase 41/42 seam, surfaced for a developer decision rather than failing a Phase 42 must-have outright.

**Note for human decision:** Phase 42 is the **last phase of v1.7** (no Phase 43), so this seam will not be auto-picked-up by a later phase in this milestone. The developer should decide whether to (a) wire `dateChangeRefetchRate` to `appGetExchangeRateUseCaseProvider`/`RateResultWithSignal` and route the real `_editDate` picker through the D-02/D-03 flow as a follow-up quick task, or (b) accept that edit-time date changes on foreign rows do not re-fetch the rate in v1.7. The four human-verification items confirm whether the real edit screen exhibits D-02/D-03 at all.

### Human Verification Required

See `human_verification` frontmatter. Four items: (1) edit-screen D-02 dialog on date change, (2) edit-screen D-03 toast on date change, (3) flag-emoji rendering on real iOS/Android, (4) live preview visual/temporal behavior.

### Gaps Summary

No must-have FAILED. The phase goal is achieved end-to-end for the entry, decimal-gating, live preview (entry screen), save, list annotation, detail/edit display, and two-input/one-derived editing — with the JPY-only path verified byte-identical (CURR-04). All 12 requirement IDs are satisfied; the full suite is green (2782/2782) and `flutter analyze` is clean.

Status is `human_needed` (not `passed`) because: (a) four behaviors require human/device verification (visual preview feel, real-device flag emoji, and the two edit-screen date-change UX paths), and (b) one WARNING-level wiring gap — the edit-screen date-change rate re-fetch (ADR-022 D-02/D-03 via the real rate service) is not connected in production and uses a stub rate — is surfaced for a developer decision since this is the final v1.7 phase.

---

## Update 2026-06-13: WARNING wiring gap RESOLVED

The WARNING-level wiring gap in item (b) above is **resolved** (commit `3b59c127`,
user-approved gap closure). The `_kStubRefetchRate = '160.00'` constant is deleted
(`grep` empty in `lib/`); the edit-screen date-change now re-fetches the real rate via
`appGetExchangeRateUseCaseProvider` (the same use case the entry preview consumes),
feeding the existing ADR-022 D-02/D-03 logic a real rate with graceful never-block-save
degradation on `RateUnavailable`. A new test (`transaction_details_form_refetch_rate_test.dart`)
overrides the rate provider with a fake and asserts it is consumed (not a stub). Full suite
now **2786/2786** green, `flutter analyze` clean.

The four human/device verification items remain (visual preview feel, real-device flag
emoji, and the two edit-screen date-change UX paths — now exercising the real rate). Run
`/gsd-verify-work 42` to complete them. Status stays `human_needed` until then.

---

_Verified: 2026-06-13T14:05:00Z_
_Verifier: Claude (gsd-verifier)_
