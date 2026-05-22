# Phase 19: Manual One-Step + Keypad Polish - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 19 collapses the current two-screen manual entry flow (TransactionEntryScreen 输入金额/日期/类目 → TransactionConfirmScreen 确认备注/商家/账本类型/满意度) into a single `ManualOneStepScreen` that hosts the Phase 18 shared `TransactionDetailsForm` widget alongside a persistent on-screen `SmartKeyboard`, and polishes the numeric keypad so digit taps register reliably at thumb reach on iOS/Android minimum touch targets. Phase 19 also retires `TransactionConfirmScreen` by repointing the voice path (voice_input_screen.dart:352) to push `ManualOneStepScreen` instead, so the two-step manual route disappears entirely from production code.

**In scope:**

- **New screen — `ManualOneStepScreen`** (`lib/features/accounting/presentation/screens/manual_one_step_screen.dart`):
  - Single-screen replacement for the TransactionEntryScreen + TransactionConfirmScreen pair on the manual path.
  - Layout (top-to-bottom): AppBar (with `addTransaction` title) → `EntryModeSwitcher(selectedMode: InputMode.manual)` → `AmountDisplay` → scrollable details section (`LedgerTypeSelector` toggle → `DetailInfoCard` with date + category two-row chips → merchant `TextField` → note `TextField` → soul-only `SatisfactionEmojiPicker`) → persistent `SmartKeyboard` whose final-row action `Next` button is renamed to `record` (Save) and triggers the form's `submit()`.
  - Hosts `TransactionDetailsForm(config: TransactionDetailsFormConfig.$new(...))` for everything below the amount — but the form must be modified so it does NOT render its own internal amount-editing surface (see D-01).
  - Owns the amount state locally (`_amount` String) and a `_amountFocused` bool. AmountDisplay tap → `_amountFocused = true` + `FocusManager.instance.primaryFocus?.unfocus()`. Any TextField tap (merchant/note) → `_amountFocused = false`. Default `_amountFocused = true` on screen mount.
  - SmartKeyboard is wrapped in `AnimatedSlide` with offset `Offset(0, _showSmartKeypad ? 0 : 1)` and `duration: const Duration(milliseconds: 220)`, `curve: Curves.easeInOut`. `_showSmartKeypad = _amountFocused && !_isTextFieldFocused` (computed from FocusScope listener).
  - `_initializeDefaultCategory()` logic ported verbatim from `transaction_entry_screen.dart:52-82` (resolves L1[0] + L2[0] from `categoryRepositoryProvider.findActive()` on initState).
  - Constructor accepts (so voice push site can pre-fill all the same params it passes today to TransactionConfirmScreen):
    ```dart
    ManualOneStepScreen({
      required String bookId,
      int? initialAmount,
      Category? initialCategory,
      Category? initialParentCategory,
      DateTime? initialDate,
      String? initialMerchant,
      int? initialSatisfaction,
      String? voiceKeyword,
      required EntrySource entrySource,
    })
    ```
  - Post-save behavior: `Navigator.of(context).popUntil((r) => r.isFirst)` — same as current TransactionConfirmScreen behavior, returns to main shell.

- **`TransactionDetailsForm` refactor — externalize amount (D-01 of this phase, replaces Phase 18 D-01's internal SmartKeyboard sheet for amount):**
  - Remove the internal amount-editing bottom sheet (currently triggered by AmountDisplay tap inside the form widget).
  - Form widget's `TransactionDetailsFormConfig.$new(...)` continues to accept `initialAmount` but the form no longer renders AmountDisplay on its own — host renders it.
  - Add a new public method `void updateAmount(int amount)` on `TransactionDetailsFormState` — host's SmartKeyboard digit callbacks update local amount and call `formKey.currentState!.updateAmount(parsedAmount)` to push it into the form's internal state for save-time use.
  - For the `.edit` host (`TransactionEditScreen`) and `.new` `OcrReviewScreen` host, both must now render their own AmountDisplay above the embedded form (host owns the display). To minimize regression risk, `TransactionEditScreen` continues to use an in-app modal bottom sheet for amount editing on tap; `OcrReviewScreen` does the same. Only `ManualOneStepScreen` uses the persistent SmartKeyboard pattern. This means amount-editing UX diverges per host: ManualOneStepScreen = persistent keyboard, TransactionEditScreen + OcrReviewScreen = tap-amount-to-open-sheet (unchanged from Phase 18).
  - The form widget's `submit()` continues to use its internal `_amount` for save; host is responsible for keeping the form's amount in sync via `updateAmount()` calls. Validation (amount > 0) stays inside `submit()`.

- **SmartKeyboard polish** (`lib/features/accounting/presentation/widgets/smart_keyboard.dart`):
  - Refactor to a responsive height model: total keyboard height = `MediaQuery.of(context).size.height * 0.40` (approximately 2/5 screen), divided across 5 rows (4 digit rows + 1 action row) plus the existing inter-row vertical padding.
  - Compute single-key height: `(totalKeypadHeight - verticalPadding - safeArea.bottom) / 5`. On a 6.1" iPhone (~844pt height) this yields ~60dp per row; on a 6.7" Pro Max (~932pt) → ~67dp; on iPhone SE (~667pt) → ~50dp. Min key height clamped to `48dp` (Material 48dp / iOS HIG 44pt safety floor).
  - Row spacing 8dp → 12dp (between digit rows); column spacing 4dp → 6dp (between keys within a row). Action row stays consistent with the rest (no separate height).
  - `_DigitKey` `height: 48` literal is removed in favor of intrinsic flex sizing (`Expanded` filling the per-row slot allocated by the parent Column with `LayoutBuilder`).
  - Action row Next button is renamed to Save (or `S.of(context).record` since the project already has the `record` ARB key — verify; if not, use the existing `recordEntry`/`save` key). The currency middle button stays display-only.
  - Backspace `_ActionKey` keeps current size match with digit keys (D-23).

- **`TransactionEntryScreen` deletion:**
  - File `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` is deleted.
  - Test file `test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart` is deleted (if present).
  - All callers (router definition, main shell `+` button, demo/route registry) are repointed to push `ManualOneStepScreen(bookId: ...)` instead. Search-and-replace pattern: `TransactionEntryScreen(` → `ManualOneStepScreen(` everywhere outside tests.

- **`voice_input_screen.dart:352` repoint:**
  - Change the `Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TransactionConfirmScreen(...)))` to push `ManualOneStepScreen(...)` instead — keeping all the same parameters (`bookId`, `amount`, `category`, `parentCategory`, `date`, `initialMerchant`, `initialSatisfaction`, `voiceKeyword`, `entrySource: EntrySource.voice`).
  - The voice flow stays a two-step UX (record → review/edit) but the second step is now ManualOneStepScreen. Voice-parsed amount appears in AmountDisplay; user can tap AmountDisplay to focus, edit via SmartKeyboard. Other voice-parsed fields (category, merchant, satisfaction, voiceKeyword) flow into the form widget unchanged.
  - Voice category correction (`recordCategoryCorrectionUseCaseProvider`) continues to work because the form widget (which still hosts that logic per Phase 18 D-09) still receives `voiceKeyword` via config.

- **`TransactionConfirmScreen` deletion:**
  - With Phase 19 retiring both manual (delete) and voice (repoint) producers, no production code references `TransactionConfirmScreen`.
  - Delete `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`.
  - Delete `test/widget/features/accounting/presentation/screens/transaction_confirm_screen_test.dart` (any tests added in Phase 18 specific to `TransactionConfirmScreen` host — re-target the assertions against `ManualOneStepScreen` instead, where applicable).
  - `OcrReviewScreen` (Phase 18) is structurally similar to TransactionConfirmScreen but stays — it hosts `TransactionDetailsForm` for the OCR path and is NOT touched by Phase 19.

- **Soft-keyboard ↔ SmartKeyboard interaction (D-14/15/16 of this phase):**
  - `Scaffold(resizeToAvoidBottomInset: false)` on `ManualOneStepScreen`.
  - Manual `Padding(bottom: max(MediaQuery.of(context).viewInsets.bottom, smartKeypadAnimatedHeight))` on the scrollable details section so content doesn't get hidden under either keyboard.
  - When any merchant/note TextField gets focus, FocusScope listener flips `_amountFocused = false` → AnimatedSlide pushes SmartKeyboard off-screen → soft keyboard slides up.
  - A floating `KeyboardToolbar` (handwritten widget, see below) appears `Positioned(bottom: viewInsets.bottom, left: 0, right: 0)` with height 44dp — contains: left "完成" / `Done` button → calls `FocusScope.of(context).unfocus()` → soft keyboard dismisses → SmartKeyboard slides back → `_amountFocused = true`; right "记账" / `Save` button → calls `formKey.currentState!.submit()` (same handler as SmartKeyboard's Save button).
  - The KeyboardToolbar is only visible when `viewInsets.bottom > 0` (i.e., soft keyboard is up). Uses `MediaQuery.of(context).viewInsets.bottom` as its `bottom:` value to ride on top of the soft keyboard exactly.

- **New widget — `KeyboardToolbar`** (`lib/features/accounting/presentation/widgets/keyboard_toolbar.dart`):
  - Stateless 44dp-tall toolbar with left "Done" text button and right "记账"/Save gradient button (small).
  - Constructor: `KeyboardToolbar({required VoidCallback onDone, required VoidCallback onSave, required bool isSubmitting})`.
  - Composed into `ManualOneStepScreen` via Stack + Positioned (NOT via Scaffold.persistentFooterButtons — those don't react to `viewInsets.bottom`).
  - Zero new pub.dev dependencies (no `keyboard_actions` package — handwritten per D-13 of this phase).

- **Golden tests** (`test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart`):
  - New file. Pumps `SmartKeyboard` in isolation × {ja, zh, en} × {light, dark} = 6 golden images.
  - Validates SC-3 (visual discriminability) via golden-image regression.
  - Uses existing `flutter_test` `matchesGoldenFile` infrastructure (no `alchemist` dep added — check whether project already has `alchemist`; if yes use it, if not use vanilla golden_files).

- **Widget tests:**
  - `manual_one_step_screen_test.dart` (`test/widget/features/accounting/presentation/screens/`):
    - SC-1: pump screen, assert ZERO occurrences of any "Next/下一步/Next-key" widget after the screen mounts (verify the manual save path has no intermediate step).
    - SC-1: assert all six field surfaces are visible in the initial render — `AmountDisplay`, `LedgerTypeSelector`, category chip (DetailInfoRow with category icon), date chip, merchant TextField, note TextField.
    - SC-2: verify each SmartKeyboard digit key's rendered height ≥ 48dp (iOS 44pt / Material 48dp floor) under default MediaQuery (use a `Size(390, 844)` test surface).
    - SC-4: simulate digit taps + ledger toggle + category default + save tap → asserts `transactionRepository.create` was invoked with a Transaction whose `entrySource == EntrySource.manual`. Uses fake repos + fake change tracker.
    - Persistent keypad: tap merchant TextField → assert `SmartKeyboard`'s `AnimatedSlide` is in the off-screen offset (`offset.dy == 1.0`); tap AmountDisplay → assert `AnimatedSlide` returns to `offset.dy == 0`.
    - KeyboardToolbar: tap merchant TextField → toolbar visible; tap toolbar "Done" → soft keyboard dismisses, SmartKeyboard returns; tap toolbar "记账" → save handler runs.
  - `smart_keyboard_test.dart` (extend if exists, or new file):
    - Verify response height computation: with `MediaQuery(size: Size(390, 844))`, total keyboard height ≈ 338dp (40% of 844), per-key ≈ 60dp post-padding.

- **i18n**: ARB additions — minimal. Likely zero new keys (reuse `record`, `back`, `done` etc.). If `done` doesn't exist as an ARB key, add `keyboardToolbarDone` (ja: "完了", zh: "完成", en: "Done") × 3 locales + `flutter gen-l10n`.

- **No Drift schema migration** (carries Phase 18's posture).

- **No new ADR** (Phase 19 is a UI polish + flow consolidation; doesn't change architectural boundaries).

**Out of scope:**

- **Voice one-step integration (INPUT-02) — that is Phase 22.** Phase 19 only retargets the voice push site from TransactionConfirmScreen → ManualOneStepScreen. Voice still runs as a two-step UX (record screen → review screen). Voice parser strengthening (Phase 20) and category resolver (Phase 21) are separate phases that feed Phase 22.
- **Record button UX (REC-01/REC-02)** — Phase 22.
- **OCR writer (MOD-005)** — v1.4+. `OcrReviewScreen` (Phase 18) is unchanged.
- **`OcrReviewScreen` redesign** — Phase 19 only retires TransactionConfirmScreen; OcrReviewScreen stays Phase 18's design (tap-amount-to-open-sheet) for the OCR path.
- **`TransactionEditScreen` redesign** — Phase 18's edit screen stays as-is (tap-amount-to-open-sheet). Reason: edit flow is for fixing typos, not high-volume entry; persistent keypad is overkill there.
- **Delete affordance / dirty-state confirmation dialog / undo-after-save / edit history audit** — all carry-forward Phase 18 out-of-scope items, unchanged.
- **HomeHero ring / provider impact** (ADR-016 §3) — Phase 19 home-screen wiring is unchanged.
- **New gamification surfaces** (ADR-012). Save success continues to show the existing snackbar; no streaks/achievements/cross-period delta.
- **Hash chain re-derivation** — moot for Phase 19 (manual entry only invokes `CreateTransactionUseCase` which computes hash at create time, per Phase 18 D-08's create-event posture).
- **English voice input** — v1.3 voice scope is zh + ja only (REQUIREMENTS.md v1.3 "Out of Scope" line).
- **Replacing SmartKeyboard with the native system numpad** — current keyboard is intentional design; only height/spacing are polished.
- **Long-press / swipe-to-delete on home recent-tx tile** — future UX story (Phase 18 out-of-scope, unchanged).

</domain>

<decisions>
## Implementation Decisions

### Single-screen layout + Save button placement (Area 1)

- **D-01: ManualOneStepScreen owns amount state + AmountDisplay + persistent SmartKeyboard; embeds TransactionDetailsForm for the non-amount fields. The form widget is REFACTORED to NOT render or edit amount internally — amount is pushed in via a new `updateAmount(int)` public method on `TransactionDetailsFormState`.**
  - **Why:** Phase 18 D-01 promised inline form embedding in Phase 19. But Phase 18's form widget edits amount via an internal bottom sheet — which conflicts with Phase 19's persistent keyboard concept. Externalizing amount keeps the form widget as the source of truth for save/voice-correction/celebration logic, while letting Phase 19 own the "amount is the primary input, keyboard is always visible" UX.
  - **Trade-off:** `TransactionEditScreen` and `OcrReviewScreen` (Phase 18 hosts) must also adopt the externalized pattern — they each render their own AmountDisplay and reuse the existing modal bottom sheet (tap amount → sheet) for amount editing. This is one extra small refactor per host, but keeps the form widget contract uniform.

- **D-02: Save button replaces the existing "Next" gradient button in `SmartKeyboard`'s action row (5th row). No separate full-width bottom CTA.**
  - **Why:** Body memory — thumb micro-adjustment from digit row to gradient-button row stays unchanged from current TransactionEntryScreen. User keeps the same "press the green button" reflex. Vertical space is preserved (no extra CTA chrome below the keypad).
  - **Trade-off:** When the soft keyboard is up (textfield focus) → SmartKeyboard is off-screen → Save button on action row is unreachable. Mitigated by D-14's KeyboardToolbar which provides a second save entry point while editing text.

- **D-03: Details section ordering top-to-bottom: LedgerTypeSelector toggle → DetailInfoCard (date row + category row as two-column-ish chips) → merchant TextField → note TextField → SatisfactionEmojiPicker (only when `_ledgerType == LedgerType.soul`).**
  - **Why:** LedgerTypeSelector at top because the toggle drives the satisfaction picker visibility + the screen's accent color (生存 = blue, 悦己 = green) — a primary decision the user makes early. DetailInfoCard for date+category reuses Phase 18 conventions (`DetailInfoRow` with `showChevron: true`, `onTap: _select{Date,Category}`). Merchant + note as inline TextFields — current TransactionConfirmScreen pattern.
  - **Alternative considered:** Dense 6-row DetailInfoCard (all fields as rows) — rejected because TextField fields don't fit the chevron-row layout (TextField needs inline editing affordance, not navigate-to-detail).
  - **Alternative considered:** Card-based grouping (amount card + meta card + notes card) — rejected because it requires new widget surfaces and breaks the established DetailInfoCard brand.

- **D-04: `EntryModeSwitcher` (Manual/OCR/Voice tabs) stays at the top of `ManualOneStepScreen`, unchanged from `TransactionEntryScreen`. Phase 22 will revisit when voice one-step screen lands.**
  - **Why:** Mode-switching is a navigation entry point users learn early; removing it from the new manual one-step would force a route-rediscovery experience. Keeping it costs ~40dp of vertical space — acceptable.

- **D-05: SmartKeyboard slide-out transition uses `AnimatedSlide` with `offset: Offset(0, _showSmartKeypad ? 0 : 1)`, `duration: 220ms`, `curve: Curves.easeInOut`.**
  - **Why:** `AnimatedSlide` is the lightest-weight Flutter primitive for this pattern. `Offset(0, 1)` (one full child-height down) is enough to clear the visible area. 220ms matches Material motion duration tokens for entrance/exit.

### Keypad polish — touch target + visual hierarchy (Area 2)

- **D-06: Responsive keyboard height — total keypad takes ~40% of screen height (`MediaQuery.of(context).size.height * 0.40`), evenly distributed across 5 rows (4 digit + 1 action). Single key height = (total - row padding - safe area bottom) / 5. Floor: 48dp (iOS 44pt / Material 48dp safety).**
  - **Why:** Fixed 48dp under-serves Pro Max screens (wasted vertical space); fixed 64dp over-compresses small screens (iPhone SE). Responsive lets thumb-reach calibrate per device. ~40% of screen is the heuristic used by iOS system numeric keypad and matches user mental model.
  - **Verification:** Widget test computes per-key height against MediaQuery `Size(390, 844)` (iPhone 14 baseline) and asserts ≥ 48dp.

- **D-07: Row spacing increased from 8dp → 12dp (between digit rows); column spacing from 4dp → 6dp (between keys within a row). Background fill (`backgroundMuted`) is preserved.**
  - **Why:** "误按" risk comes from finger occlusion + adjacent-key proximity. Larger gaps separate visual regions without changing the brand (iOS system keypad uses ~12pt gaps). Fill stays consistent to avoid a dark-mode contrast review.
  - **Trade-off:** Slightly larger total height — already accounted for in D-06's responsive sizing.

- **D-08: Action row keys (⌫ / ¥JPY / Save) use the same responsive height as digit keys — no special-cased 50dp.**
  - **Why:** Visual hierarchy is communicated by the Save button's gradient + shadow (already in `_GradientKey`), not by size differential. Equal-row heights reduce visual fragmentation. Backspace key uses the same `backgroundMuted` fill as digit keys (it's a peer, not an exception).

- **D-09: Golden tests for SmartKeyboard live in a NEW file `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart`. Six images: {ja, zh, en} × {light, dark}, isolated SmartKeyboard (not whole screen).**
  - **Why:** Isolated golden makes regressions readable (diff shows exactly what changed in the keyboard, not in the surrounding screen). Brand changes to the keypad (rare) won't cascade into 30 unrelated screen goldens.
  - **Trade-off:** Doesn't catch screen-level integration issues (e.g., AnimatedSlide interaction). Those are covered by widget tests in `manual_one_step_screen_test.dart`, not goldens.

### Persistent keypad vs system soft keyboard (Area 3)

- **D-10: `_amountFocused` is a local bool on `ManualOneStepScreen` state. Default `true` on mount. AmountDisplay tap = `_amountFocused = true` + `FocusManager.instance.primaryFocus?.unfocus()`. TextField tap (merchant/note) = `_amountFocused = false` (driven by `FocusScope` listener on the screen).**
  - **Why:** Treating "amount focus" as widget-local state (not a Flutter FocusNode) keeps the model simple — AmountDisplay isn't an actual input control, it's a display surface that owns the keypad. Explicit boolean is easier to test than an implicit FocusScope arrangement.
  - **Alternative considered:** Virtual `FocusNode` for AmountDisplay — rejected because AmountDisplay doesn't need keyboard accessibility integration (it's not a text input from the platform's perspective).

- **D-11: When `_isTextFieldFocused == true` (soft keyboard up), a floating `KeyboardToolbar` (44dp tall, `Positioned(bottom: viewInsets.bottom, ...)` in a `Stack`) appears with left "Done" + right "记账" / Save buttons. Done dismisses the soft keyboard; Save runs the same submit handler as the action-row Save.**
  - **Why:** With SmartKeyboard off-screen, Save needs a second access point. Industry-standard pattern: a keyboard-accessory toolbar that rides on top of the soft keyboard. Provides explicit "Done" affordance for users who don't know to tap outside.
  - **Why two buttons:** "Done" returns to amount-editing flow (SmartKeyboard slides back); "Save" commits without bouncing through amount focus. Both should be present — Done is the conventional escape, Save is the high-throughput path.

- **D-12: KeyboardToolbar is a handwritten widget (Stack + Positioned + MediaQuery.viewInsets), no `keyboard_actions` or other pub package.**
  - **Why:** Project rule (CLAUDE.md "dependency pins to leave alone") + the implementation is ~30 lines. New pub deps need a clear cost/benefit; here the cost (transitive deps, version pins) outweighs the savings.

- **D-13: `Scaffold(resizeToAvoidBottomInset: false)` on ManualOneStepScreen. The scrollable details section uses `Padding(bottom: max(viewInsets.bottom, smartKeypadAnimatedHeight))` to ensure content stays scrollable above whichever keyboard is currently shown.**
  - **Why:** Letting Flutter's default resize behavior fight the AnimatedSlide leads to layout jitter during the transition (both move simultaneously). Manually controlling the padding makes the layout state predictable. The `max(...)` term handles the brief overlap during the AnimatedSlide animation when both keyboards' areas are reserved.

### Embedding approach + legacy screen disposition + field affordances (Area 4)

- **D-14: TransactionDetailsForm refactor — externalize amount. Form widget no longer renders AmountDisplay or the internal amount-editing bottom sheet. New public method `void updateAmount(int amount)` on `TransactionDetailsFormState` lets hosts push amount state in. Form's internal `_amount` is still used at `submit()` time; host MUST keep it in sync.**
  - **Why:** Resolves the conflict between Phase 18 D-01 (form widget owns amount sheet) and Phase 19's persistent-keyboard model. Form widget stays the canonical save/validation/voice-correction site; amount editing moves to host so each host can pick its UX (persistent keyboard for ManualOneStepScreen, modal sheet for TransactionEditScreen / OcrReviewScreen).
  - **Impact on Phase 18 hosts:** `TransactionEditScreen` and `OcrReviewScreen` must each render their own AmountDisplay above the form and wire a tap-to-open-sheet handler (the sheet logic stays, just lives in the host now). Two small refactors, low regression risk because the affected hosts are already Phase 18 code with full test coverage.

- **D-15: `TransactionEntryScreen` is deleted in Phase 19. All callers (router, main shell `+` button, demo data routes) repoint to `ManualOneStepScreen`. File `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` + its test file are removed.**
  - **Why:** Phase 19 IS the manual one-step flow; keeping TransactionEntryScreen creates two parallel manual entry paths and a "which one wins" routing question forever. Delete is cleaner than refactor-in-place because: (a) the screen's responsibility changes fundamentally (amount-only hub → full single-screen entry), (b) class name becomes misleading (TransactionEntryScreen no longer "enters" a multi-step flow), (c) git history is clearer with a new file + deletion than with a heavy rewrite.

- **D-16: `voice_input_screen.dart:352` is repointed to push `ManualOneStepScreen` instead of `TransactionConfirmScreen`. All voice push parameters (`bookId`, `amount`, `category`, `parentCategory`, `date`, `initialMerchant`, `initialSatisfaction`, `voiceKeyword`, `entrySource: EntrySource.voice`) pass through unchanged.**
  - **Why:** Lets Phase 19 retire TransactionConfirmScreen as part of the same diff. Phase 22 will eventually retire voice_input_screen entirely (voice one-step integration) — that's still a future change, not this one.
  - **Regression surface:** Voice flow's amount + category + merchant + voiceKeyword pre-fill, save, and `entry_source == 'voice'` persistence MUST still work. Add a `voice_to_manual_one_step_screen_test.dart` that pumps voice flow end-to-end (mock VoiceInputScreen → push ManualOneStepScreen with voice params → save → assert Transaction.entrySource == voice).
  - **Soul celebration on voice soul saves:** Form widget's D-15 (Phase 18) still triggers celebration on `.new` saves of soul transactions; ManualOneStepScreen is still a `.new` host. No change.

- **D-17: `TransactionConfirmScreen` is deleted in Phase 19. With manual (D-15) and voice (D-16) both repointed, no production code references it. File + test file are removed.**
  - **Why:** Phase 18 D-04 said TransactionConfirmScreen would be retired "when manual / voice flows collapse to one screen." Phase 19 collapses manual + retargets voice → both production callers gone → retirement is now safe.
  - **Phase 18 D-04 commitment honored:** "Phase 19/22 will eventually retire ... that retirement belongs to those phases." Phase 19 takes it.
  - **OcrReviewScreen unaffected:** OCR path uses `OcrReviewScreen` directly (Phase 18 D-13) — never went through `TransactionConfirmScreen`.

- **D-18: Field affordances unchanged from current TransactionConfirmScreen / TransactionDetailsForm patterns:**
  - **Category:** tap chevron → `Navigator.push(CategorySelectionScreen)` (existing pattern). Default = `_initializeDefaultCategory()` (L1[0] + L2[0]).
  - **Date:** tap chevron → `showDatePicker(...)` modal (existing pattern; uses `survival` color theme).
  - **Ledger type:** inline toggle via `LedgerTypeSelector` (Phase 18 form widget already renders this).
  - **Satisfaction:** inline `SatisfactionEmojiPicker`, only visible when ledger == soul (Phase 18 form widget already gates this).
  - **Merchant + note:** inline `TextField` (existing Phase 18 pattern — host inside the form widget).
  - No inline category picker, no bottom-sheet date wheel, no per-field redesign. Phase 19 is a flow consolidation, not a field-by-field UX overhaul.

### Claude's Discretion

- **D-19: AnimatedSlide curve and duration (220ms / Curves.easeInOut)** — picked as Material motion baseline. Planner may tune within ±50ms / similar curves without re-asking.
- **D-20: Exact responsive percentage (~40% of screen)** — actual percentage may need iteration. If 40% on iPhone SE yields per-key < 48dp safety floor, the planner may bump to 42-45% to maintain the floor.
- **D-21: KeyboardToolbar visual design** (44dp height, "Done" left + "Save" right) — exact font weight, padding, and gradient choice for the small Save button left to planner discretion. Should match the action-row Save button family but compact.
- **D-22: `done` ARB key reuse** — if `S.of(context).done` exists, reuse it for the toolbar Done button. If not, planner adds `keyboardToolbarDone` × 3 locales.
- **D-23: Backspace key (⌫) visual size** — stays same-as-digit-keys (D-08). Planner may adjust icon stroke weight if responsive height makes the current 22dp icon feel undersized.
- **D-24: Where to put `_initializeDefaultCategory` logic** — port verbatim from TransactionEntryScreen:52-82 into ManualOneStepScreen. Planner may extract into a shared helper if it materially simplifies, but otherwise verbatim is fine.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning
- `.planning/PROJECT.md` — v1.3 milestone goal (input flow polish); Phase 19 listed as manual one-step + keypad polish; out-of-scope list includes voice one-step (Phase 22), OCR writer, schema migrations.
- `.planning/REQUIREMENTS.md` — v1.3 requirements: KEYPAD-01 (95% tap accuracy, iOS 44pt / Material 48dp min, visual hierarchy), INPUT-01 (single-screen manual entry, no "下一步" button), plus the out-of-scope list (English voice deferred, MOD-005 OCR deferred, etc.).
- `.planning/ROADMAP.md` §"Phase 19: Manual One-Step + Keypad Polish" — five Success Criteria (no Next button + 6 field surfaces, platform-min touch target, golden discriminability, save → entry_source='manual', S.of(context) parity).
- `.planning/STATE.md` — v1.3 phase map; Phase 19 depends on Phase 18 (shared form foundation).

### Prior phase hand-off
- `.planning/phases/18-shared-details-form-foundation/18-CONTEXT.md` — TransactionDetailsForm contract (`.new` / `.edit` config, GlobalKey + submit() pattern, voice-correction in `.new` mode, soul celebration on `.new` saves only, entry_source preservation on edit). Phase 19 MUST honor D-01 (embeddable widget, host owns chrome) and D-04 (Phase 19/22 retire TransactionConfirmScreen). Phase 19 EXTENDS D-01: form widget no longer owns amount editing — amount becomes externalized.
- `.planning/milestones/v1.2-phases/17-manual-only-joy-sub-metric-happy-v2-03/17-CONTEXT.md` — `entrySource: EntrySource.manual` push contract (D-06 required-no-default), schema v17 CHECK constraint.

### Architecture / ADRs
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — Thin Feature rule: ManualOneStepScreen (screen) + KeyboardToolbar (widget) both live in `lib/features/accounting/presentation/`. No `application/` or `infrastructure/` inside features.
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod 3 conventions; ManualOneStepScreen is `ConsumerStatefulWidget` (it needs `ref` for `categoryRepositoryProvider.findActive()` + repo providers). Local state (`_amount`, `_amountFocused`, FocusNode listener) stays in widget, not in Riverpod.
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — Phase 19 adds no streaks/achievement toasts/cross-period delta UI on save.
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — SatisfactionEmojiPicker rendered only when ledger == soul (form widget already enforces this).
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §3 — HomeHero isolation invariant; Phase 19 changes don't touch HomeHero.

### Source integration points
- `lib/features/accounting/presentation/screens/transaction_entry_screen.dart:1-344` — current manual entry screen, DELETED in Phase 19. Reference lines 52-82 for `_initializeDefaultCategory()` (port verbatim), 84-130 for digit input handlers (port verbatim to ManualOneStepScreen), 154-178 for `_selectCategory()` navigation (port verbatim), 206-236 for `_onNext()` validation (port logic minus the navigation).
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart:1-198` — DELETED in Phase 19. Reference lines 58-81 for `_save()` pattern (already calls `formKey.currentState!.submit()` — same handler ManualOneStepScreen will use).
- `lib/features/accounting/presentation/screens/voice_input_screen.dart:351-367` — voice push site. CHANGE the `MaterialPageRoute<void>(builder: (_) => TransactionConfirmScreen(...))` to push `ManualOneStepScreen(...)` with the SAME parameters.
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart:1-739` — form widget. REFACTOR: remove internal AmountDisplay rendering + internal amount-editing bottom sheet. Add public `void updateAmount(int amount)` method on `TransactionDetailsFormState`. `submit()` validation (amount > 0) stays.
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart:1-345` — REFACTOR: responsive height model, row spacing 8→12dp, column spacing 4→6dp, action row keys same height as digit keys. `_GradientKey` rename Next label → Save label (param-driven).
- `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (Phase 18) — UPDATE: host must now render its own AmountDisplay + wire tap-to-open-sheet for amount editing (D-14 spillover).
- `lib/features/accounting/presentation/screens/ocr_review_screen.dart` (Phase 18) — UPDATE: same as TransactionEditScreen — host renders AmountDisplay + tap-to-open-sheet (D-14 spillover).
- `lib/features/accounting/presentation/widgets/amount_display.dart` — REUSED verbatim (host renders it).
- `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` — REUSED verbatim (inside form widget).
- `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` — REUSED verbatim (inside form widget, soul-only).
- `lib/features/accounting/presentation/widgets/detail_info_card.dart` — REUSED for date + category rows.
- `lib/features/accounting/presentation/screens/category_selection_screen.dart` — REUSED for category navigation (tap chevron → push).
- `lib/features/accounting/presentation/widgets/entry_mode_switcher.dart` + `input_mode_tabs.dart` — REUSED at top of ManualOneStepScreen (manual mode selected).
- `lib/features/accounting/presentation/widgets/soft_toast.dart` — REUSED for inline validation toasts (e.g., "amount must be > 0", "please select category").
- `lib/features/accounting/presentation/providers/repository_providers.dart` — no new providers; reuses `categoryRepositoryProvider`, `createTransactionUseCaseProvider`, `recordCategoryCorrectionUseCaseProvider`.

### Router / route registration
- `lib/core/router/` — find where `TransactionEntryScreen` is registered as a route / called from main shell. Replace registration with `ManualOneStepScreen`.

### Project rules
- `CLAUDE.md` — Thin Feature, Riverpod 3 imports, dependency pins (don't add `keyboard_actions`), Amount Display Style (AppTextStyles.amountLarge for amount surfaces — already used in AmountDisplay), Widget Parameter Pattern (nullable + provider fallback), i18n (S.of(context)), generated-file rules (run build_runner after annotated changes — form widget refactor touches no annotations, no new freezed/riverpod gen needed unless KeyboardToolbar adds @freezed/@riverpod which it should NOT).
- `.claude/rules/coding-style.md` — immutability (`copyWith` only); file size targets (ManualOneStepScreen should stay under 800; aim 400-600 by reusing form widget for non-amount fields).
- `.claude/rules/testing.md` — TDD; per-file ≥70% coverage; widget tests assert behavior (SC-1 absence-of-Next, SC-2 height-≥48dp, SC-4 entry_source==manual).
- `.claude/rules/arch.md` — no new ADR for Phase 19; honors existing ADR-012/014/016.
- `.claude/rules/worklog.md` — Phase 19 close requires `doc/worklog/YYYYMMDD_HHMM_*.md` entry.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`TransactionDetailsForm`** (Phase 18) — the load-bearing reusable. Phase 19 embeds it for non-amount fields; refactors it to externalize amount.
- **`SmartKeyboard`** — the existing numpad. Phase 19 polishes height/spacing/responsive sizing, doesn't rebuild from scratch.
- **`AmountDisplay`** — already a standalone widget; host can render it independently of the form.
- **`EntryModeSwitcher` + `InputMode`** — already plumbed; reused at top of ManualOneStepScreen.
- **`DetailInfoCard` + `DetailInfoRow`** — already styled and tap-to-edit-enabled; perfect for date + category two-row chip-grid layout.
- **`CategorySelectionScreen`** — full-screen category picker, reused via `Navigator.push`.
- **`SatisfactionEmojiPicker`** — soul-only picker, inside form widget.
- **`LedgerTypeSelector`** — toggle inside form widget.
- **`SoftToast`** — used by TransactionEntryScreen for validation toasts; reusable by ManualOneStepScreen.
- **`_initializeDefaultCategory()`** logic (lines 52-82 of TransactionEntryScreen) — port verbatim.

### Established Patterns
- **Embeddable form widget + host-owned Scaffold + bottom CTA** (Phase 18 D-01) — Phase 19 follows this; SmartKeyboard's Save button is the host's bottom CTA.
- **Freezed sealed config object** (Phase 18 D-05) — already in place for `TransactionDetailsFormConfig.$new / .edit`; Phase 19 doesn't extend the union.
- **GlobalKey + submit() return Future<TransactionDetailsFormResult>** (Phase 18 D-02) — Phase 19 uses the same pattern for both SmartKeyboard's Save and KeyboardToolbar's Save.
- **`MediaQuery.viewInsets.bottom` for soft-keyboard-aware layout** — standard Flutter pattern, no novelty.
- **`AnimatedSlide` for off-screen transitions** — standard Material motion primitive.
- **`FocusManager.instance.primaryFocus?.unfocus()` for dismissing soft keyboard** — standard Flutter idiom.

### Integration Points
- **`lib/features/accounting/presentation/screens/voice_input_screen.dart:351-367`** — voice push target changes from TransactionConfirmScreen to ManualOneStepScreen (all params unchanged).
- **Router** (`lib/core/router/` or wherever main shell `+` button lives) — manual entry route target changes from TransactionEntryScreen to ManualOneStepScreen.
- **`transaction_details_form.dart`** — externalize amount (remove AmountDisplay + internal sheet; add `updateAmount(int)` public method).
- **`transaction_edit_screen.dart` (Phase 18)** — host now renders own AmountDisplay + wires tap-to-sheet for amount editing.
- **`ocr_review_screen.dart` (Phase 18)** — same spillover as edit screen.
- **`smart_keyboard.dart`** — responsive height + spacing changes + Save label.

</code_context>

<specifics>
## Specific Ideas

- **The ManualOneStepScreen is the load-bearing artifact of Phase 19.** Downstream agents reading SC-1 "no '下一步' button" should treat ManualOneStepScreen + the externalized-amount TransactionDetailsForm refactor as the source of truth.
- **Externalize amount, keep everything else.** Phase 19's most surgical decision is that the form widget gives up amount editing; the host takes it. This unblocks the persistent-keyboard pattern without rebuilding the form widget for one-off use.
- **The voice path is repointed, not refactored.** Phase 19's voice change is a one-line `Navigator.push` target swap — TransactionConfirmScreen → ManualOneStepScreen. Voice still runs two-step UX. Phase 22 does the full voice one-step.
- **TransactionConfirmScreen dies in Phase 19.** Both production callers (manual delete D-15, voice repoint D-16) are gone. Phase 18 D-04 collapse-and-retire promise is fulfilled here.
- **Responsive keyboard height (~40% screen) with 48dp floor.** Per-device thumb reach varies; fixed 64dp wastes space on small screens and looks bloated on big ones.
- **Handwritten KeyboardToolbar, zero new pub deps.** ~30 lines of Stack + Positioned + MediaQuery.viewInsets. Aligns with project's "dependency pins to leave alone" posture.
- **Two save entry points: SmartKeyboard Save + KeyboardToolbar Save.** Both call the same handler. Users in amount-focus use the keypad; users in textfield-focus use the toolbar. Done in toolbar is the conventional escape.
- **No new ADR.** Phase 19 is UI polish + flow consolidation; doesn't change architectural rules.
- **`_initializeDefaultCategory()` ported verbatim from TransactionEntryScreen.** Same L1[0] + L2[0] default — keeps a familiar starting state.
- **`entrySource: EntrySource.manual`** stays the manual push contract (carried from Phase 17 D-06).

</specifics>

<deferred>
## Deferred Ideas

### Beyond Phase 19 (other v1.3 phases)
- **Voice one-step integration (INPUT-02)** — Phase 22. Phase 19 only repoints voice push from TransactionConfirmScreen → ManualOneStepScreen.
- **Record button UX (REC-01/REC-02)** — Phase 22.
- **Voice number parser (VOICE-01/02/03)** — Phase 20.
- **Voice category resolver level-2 enforcement (VOICE-04/05/06)** — Phase 21.

### Beyond v1.3 (v1.4+)
- **MOD-005 OCR writer landing** — `OcrReviewScreen` (Phase 18) gets its real OCR pipeline. Phase 19 doesn't touch OCR.
- **TransactionEditScreen UX redesign** — Phase 18 edit screen retains tap-amount-to-open-sheet UX. If users find that awkward post-Phase-19 ("manual entry has persistent keypad, edit doesn't"), revisit in a future polish phase.
- **Sound/haptic feedback on key tap** — out of scope (would need an ADR for haptic semantics).
- **Custom key arrangements (e.g., calculator-style ÷×−+ or expression evaluator)** — out of scope.
- **Long-press behaviors on digit keys (e.g., long-press 0 → 000)** — out of scope.
- **Persistent keyboard preference toggle** (let users disable persistent keypad and revert to bottom sheet) — out of scope.
- **Field-level reordering or customization** — out of scope.
- **Drag-to-dismiss SmartKeyboard** — out of scope.

### Reviewed Todos (not folded)
`cross_reference_todos` returned 0 matches for Phase 19.

</deferred>

---

*Phase: 19-Manual One-Step + Keypad Polish*
*Context gathered: 2026-05-22*
