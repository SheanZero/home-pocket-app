---
phase: quick-260613-wuv
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
autonomous: true
requirements: [WUV-01, WUV-02]
must_haves:
  truths:
    - "On the ADD screen, the foreign 汇率/换算/汇率日期 block renders inside a rounded card matching the EDIT screen (palette.card, radius 14, palette.borderDefault border)"
    - "When the user scrolls the ADD form, only the amount headline (AmountDisplay) + EntryModeSwitcher stay pinned; the FX card scrolls away with the rest of the form"
    - "Typing into the foreign amount no longer flickers the FX card (loading spinner / JPY re-seed only fires ~300ms after the user pauses)"
    - "Saving immediately after typing persists the live entered amount, not a stale debounced amount"
    - "JPY-native entry (CURR-04) behaves byte-identically — no card, no debounce side-effects"
  artifacts:
    - path: "lib/features/accounting/presentation/screens/manual_one_step_screen.dart"
      provides: "FX card moved into scroll region with card chrome + debounced minor-units feeding the card"
  key_links:
    - from: "_AddScreenForeignCard.originalMinorUnits (mount + provider key)"
      to: "_debouncedMinorUnits state"
      via: "constructor arg fed from debounced value"
      pattern: "_debouncedMinorUnits"
    - from: "_pushForeignTriple / _trySave (save path)"
      to: "_originalMinorUnits (live getter)"
      via: "save must read live value, NOT debounced"
      pattern: "_originalMinorUnits"
---

<objective>
Two related UX fixes on the ADD-transaction screen (`manual_one_step_screen.dart`), using the EDIT screen as the visual target:

1. The foreign 汇率/换算/汇率日期 block currently sits OUTSIDE the scroll region (pinned with the amount headline) and renders FLAT (no card chrome). Move it INTO the `SingleChildScrollView` above `TransactionDetailsForm` so it scrolls with the form, and wrap it in the same card chrome the EDIT screen uses (`_formCard`: `palette.card`, radius 14, `palette.borderDefault` border).

2. The FX card re-keys its `conversionRateProvider` on every keystroke (via the live `_originalMinorUnits`), causing the loading spinner + JPY re-seed to flash (闪频). Add a ~300ms debounce (mirroring the `voice_input_screen.dart` Timer precedent) so the card only re-resolves after the user pauses typing. The SAVE path must keep using the LIVE amount.

Purpose: Make the ADD screen's foreign-input experience visually consistent with the EDIT screen and remove input flicker.
Output: A single edited file, `manual_one_step_screen.dart`.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@./CLAUDE.md
@lib/features/accounting/presentation/screens/manual_one_step_screen.dart
@lib/features/accounting/presentation/widgets/transaction_details_form.dart
@lib/features/accounting/presentation/widgets/currency_linked_edit_fields.dart
@lib/features/accounting/presentation/screens/voice_input_screen.dart

Verified anchors (re-confirm before editing — file changes between runs):
- `build` body `Stack > Column`: `_AddScreenForeignCard` currently wrapped only in `Padding(horizontal:16)` at ~lines 698-709, OUTSIDE the `Expanded(SingleChildScrollView(...))` at ~lines 712-740.
- `SingleChildScrollView` padding: `EdgeInsets.fromLTRB(16, 8, 16, scrollPaddingBottom)`; child is `TransactionDetailsForm(key: _formKey, ...)`.
- `_originalMinorUnits` getter: ~line 132 (derives from `_controller.text` every call).
- `_syncAmountToForm()`: ~line 317 — single mirror site, called by `_onDigit`/`_onDoubleZero`/`_onDot`/`_onDelete`/`_onClear` (~lines 280-304) and ~line 520. Does `setState(() => _amount = _controller.text)` then `_pushForeignTriple()` when foreign.
- `_pushForeignTriple()`: ~line 336 — reads `_originalMinorUnits` (live) at line 337 and again in the staleness guard at line 386. This is the SAVE/persist path — must stay LIVE.
- `dispose()`: ~line 189 (disposes `_merchantFocus`, `_noteFocus`).
- `_AddScreenForeignCard`: class at ~line 797; `originalMinorUnits` field at line 809; `conversionRateProvider(args)` keyed on `(currency, date, originalMinorUnits)` at ~lines 826-842; provider key drives the `rateAsync.when(loading:...)` flash.
- EDIT screen card chrome to replicate: `transaction_details_form.dart` `_formCard` ~lines 937-947.
- voice debounce precedent: `voice_input_screen.dart:~546` — `Timer(const Duration(milliseconds: 300), ...)`, cancelled on each input and in dispose.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Move FX card into scroll region with EDIT-screen card chrome</name>
  <files>lib/features/accounting/presentation/screens/manual_one_step_screen.dart</files>
  <action>
Relocate the foreign-conversion block so only `AmountDisplay` + `EntryModeSwitcher` stay pinned and the FX card scrolls with the form, styled like the EDIT screen (WUV-01).

1. DELETE the current `if (_isForeign && _originalMinorUnits > 0) Padding(...) child: _AddScreenForeignCard(...)` block from the outer `Column` (the block currently between `AmountDisplay` and the `Expanded` scroll region, ~lines 692-709). Remove the now-orphaned comment lines that referred to its old position only if they no longer apply; keep the explanatory `// Quick 260613-ufn (D-1)` rationale if still accurate, moved with the block.

2. INSIDE the `SingleChildScrollView`, change its `child:` from the bare `TransactionDetailsForm(...)` to a `Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...])` whose FIRST child is the foreign card (conditionally rendered) and SECOND child is the existing `TransactionDetailsForm(...)` unchanged. Put a `SizedBox(height: 8)` between the card and the form when the card is present.

3. Wrap `_AddScreenForeignCard(...)` in the SAME card chrome the EDIT host uses (`transaction_details_form.dart` `_formCard`, ~lines 937-947): a `Container(decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.borderDefault)))`. Use `context.palette` (ADR-019) — never hardcode hex. The `SingleChildScrollView` already supplies `horizontal:16` padding, so do NOT re-add horizontal padding around the card (avoid double inset). If the inner card body needs internal breathing room, add `padding: const EdgeInsets.all(...)` consistent with how `CurrencyLinkedEditFields` sits inside `_formCard` on the edit screen — match the edit screen's inset, do not invent a new one.

4. Keep the mount condition `_isForeign && _originalMinorUnits > 0` for now (Task 2 swaps the operand to the debounced value). Preserve all existing `_AddScreenForeignCard` constructor args (currency, date, originalMinorUnits, manualRateOverride, onRateEdited, onSignal) and the internal loading / error / RateRequired states untouched — those are inside the card widget and out of scope.

JPY-native path (CURR-04) must stay byte-identical: the card only renders in the `_isForeign` branch, so the JPY column is unaffected.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze lib/features/accounting/presentation/screens/manual_one_step_screen.dart 2>&1 | tail -5</automated>
  </verify>
  <done>The foreign card is the first child inside the SingleChildScrollView's Column (above TransactionDetailsForm), wrapped in a palette.card / radius-14 / palette.borderDefault Container; the old pinned Padding block is gone; `flutter analyze` reports 0 issues on the file.</done>
</task>

<task type="auto">
  <name>Task 2: Debounce the FX amount input (~300ms) feeding the card</name>
  <files>lib/features/accounting/presentation/screens/manual_one_step_screen.dart</files>
  <action>
Add an anti-flicker debounce so the FX card's provider key + JPY re-seed only update after the user pauses typing (WUV-02), mirroring `voice_input_screen.dart:~546`.

1. Add two State fields near `_manualForeignRate` (~line 127):
   - `int _debouncedMinorUnits = 0;` — the debounced snapshot of `_originalMinorUnits` that feeds the card.
   - `Timer? _fxDebounce;` — import `dart:async` if not already imported.

2. In `_syncAmountToForm()` (~line 317), AFTER the existing `setState(() => _amount = _controller.text)` and the existing save/triple logic (do NOT alter the JPY early-return or `_pushForeignTriple()` call — the SAVE path stays LIVE), schedule the debounce:
   - `_fxDebounce?.cancel();`
   - `_fxDebounce = Timer(const Duration(milliseconds: 300), () { if (!mounted) return; final next = _originalMinorUnits; if (next != _debouncedMinorUnits) setState(() => _debouncedMinorUnits = next); });`
   This recomputes the live value when the timer fires and only re-keys the card via setState if it actually changed.

   Edge case — clearing: when `_originalMinorUnits` drops to 0 the card should unmount promptly rather than waiting 300ms. Acceptable either way functionally, but prefer: if `_originalMinorUnits == 0`, cancel the timer and `setState(() => _debouncedMinorUnits = 0)` synchronously (so `_onClear` / full-delete hides the card immediately and avoids a stale spinner).

3. Change the card MOUNT GUARD and the card's `originalMinorUnits` ARG to use `_debouncedMinorUnits` instead of the live `_originalMinorUnits`:
   - Mount guard (now inside the SingleChildScrollView Column from Task 1): `if (_isForeign && _debouncedMinorUnits > 0)`.
   - `_AddScreenForeignCard(originalMinorUnits: _debouncedMinorUnits, ...)`.
   This makes the keyed `conversionRateProvider` re-resolve only on the debounced value → no per-keystroke loading flash.

4. Do NOT touch `_pushForeignTriple()` (~line 336): it must keep reading the LIVE `_originalMinorUnits` (lines 337 and 386) so an immediate Save after typing persists the correct amount and the staleness guard compares against live input. The debounce affects display/provider-key only, never persistence.

5. Cancel the timer in `dispose()` (~line 189): add `_fxDebounce?.cancel();` before `super.dispose()`.

Riverpod 3: no new watch/listen added — the existing `ref.listen` in `_AddScreenForeignCard` is unchanged. Immutability: only primitive `int`/`Timer?` state, mutated via `setState`.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze lib/features/accounting/presentation/screens/manual_one_step_screen.dart 2>&1 | tail -5</automated>
  </verify>
  <done>`_debouncedMinorUnits` + `_fxDebounce` fields exist; `_syncAmountToForm` schedules a 300ms timer that updates `_debouncedMinorUnits`; the card mount guard + `originalMinorUnits` arg read `_debouncedMinorUnits`; `_pushForeignTriple` still reads live `_originalMinorUnits`; `dispose` cancels the timer; `flutter analyze` 0 issues.</done>
</task>

<task type="auto">
  <name>Task 3: Verify analyzer + affected tests (re-baseline goldens only if shifted)</name>
  <files>lib/features/accounting/presentation/screens/manual_one_step_screen.dart</files>
  <action>
Full-file analyzer clean + run the add-screen-related test suites that could regress.

1. `flutter analyze` (whole project) — MUST be 0 issues (CLAUDE.md gate).
2. Run the foreign-path widget/unit tests that exercise this screen:
   - `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart`
   - `test/widget/features/accounting/presentation/screens/manual_one_step_foreign_triple_test.dart`
   - `test/unit/features/accounting/presentation/screens/manual_one_step_screen_foreign_push_stale_test.dart`
   - `test/integration/features/accounting/manual_save_entry_source_test.dart`
   No add-screen GOLDEN test exists (verified: `test/golden/*` has no ManualOneStep reference), so a blanket `--update-goldens` is NOT expected. If any of the above is a golden-style test and fails ONLY on a pixel diff for the add-screen foreign state (not a logic failure), re-baseline ONLY that single test file with `flutter test --update-goldens <that_file>` on macOS. Do NOT `dart format` the test dir and do NOT blanket-update goldens (memory: golden-ci-platform-gate, never blanket).
3. Note for the human: the debounce introduces a ~300ms delay before the JPY換算 updates while typing — this is intended (anti-flicker). Saving immediately uses the live amount, so no data loss.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze 2>&1 | tail -3 && flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart test/widget/features/accounting/presentation/screens/manual_one_step_foreign_triple_test.dart test/unit/features/accounting/presentation/screens/manual_one_step_screen_foreign_push_stale_test.dart 2>&1 | tail -15</automated>
  </verify>
  <done>`flutter analyze` reports 0 issues project-wide; the listed foreign-path widget/unit tests pass; no blanket golden update was performed.</done>
</task>

</tasks>

<verification>
- `flutter analyze` → 0 issues.
- ADD screen, foreign currency selected, amount entered: FX 汇率/换算/汇率日期 block renders inside a rounded card matching the EDIT screen.
- Scrolling the ADD form: only AmountDisplay + EntryModeSwitcher pinned; FX card scrolls with category/date/merchant.
- Typing the foreign amount: no per-keystroke spinner flash; card re-resolves ~300ms after pausing.
- Save immediately after typing: persisted JPY/triple matches the live entered amount.
- JPY-native entry: unchanged (no card, no debounce effect).
</verification>

<success_criteria>
- WUV-01: FX block moved into scroll region with EDIT-screen card chrome (palette.card / radius 14 / palette.borderDefault), only amount headline pinned.
- WUV-02: foreign amount input debounced ~300ms feeding the card's provider key + JPY re-seed; save path keeps live amount; timer cancelled in dispose.
- Analyzer 0 issues; affected tests green; CURR-04 JPY path byte-identical.
</success_criteria>

<output>
Create `.planning/quick/260613-wuv-fx-input-card-debounce/260613-wuv-SUMMARY.md` when done.
</output>
