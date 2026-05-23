---
phase: 19-manual-one-step-keypad-polish
verified: 2026-05-23T07:33:18Z
status: human_needed
score: 5/5 must-haves verified (roadmap SC-1 through SC-5)
overrides_applied: 0
human_verification:
  - test: "Open and visually inspect all 6 SmartKeyboard golden PNG baselines"
    expected: "Adjacent digit keys visually separated with ~6 dp gap; coral gradient Save button distinct from peer keys; dark-mode keys use AppColorsDark.backgroundMuted fill with sufficient contrast; tabular digit glyphs vertically aligned; action row keys equal height; 'Record' label legible across ja/zh/en locales (CJK fallback renders boxes in headless env but is expected behavior per RESEARCH §Pitfall 7)"
    why_human: "matchesGoldenFile only detects drift from the baseline — it cannot verify the baseline itself is correct. The 6 PNGs were human-approved during Plan 02's Task 3 checkpoint per 19-02-SUMMARY.md. This item carries forward the SC-3 visual-discriminability human verification."
  - test: "Run app on physical iOS device (iPhone SE or newer) and tap the numeric keypad keys"
    expected: "Each digit tap registers correctly; no mis-taps on adjacent keys; keypad slides off-screen when merchant/note TextField is focused; KeyboardToolbar Done dismisses soft keyboard; Save on KeyboardToolbar records the transaction"
    why_human: "Widget tests confirm 48 dp floor via rendered constraints and the 6 dp column gap via RenderBox positions, but real device feel (thumb reach, tap accuracy, animation fluidity) requires physical device testing. SC-2 touch-target compliance is widget-test verified but device ergonomics need human evaluation."
---

# Phase 19: Manual One-Step + Keypad Polish Verification Report

**Phase Goal:** Collapse manual entry into one screen reusing Phase 18's shared form, and polish the numeric keypad so digit taps register reliably at thumb reach on iOS/Android minimum touch targets.
**Verified:** 2026-05-23T07:33:18Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| SC-1 | Manual entry flow renders all six fields inline on a single screen with no "下一步" navigation button | ✓ VERIFIED | `manual_one_step_screen.dart` (466 lines) renders AmountDisplay + EntryModeSwitcher + TransactionDetailsForm (which has category-chip/date-chip/merchant-textfield/note-textfield via ValueKey markers) all in one `Scaffold`. `manual_one_step_screen_test.dart` line 201-211: `expect(find.text('Next'), findsNothing)` + `expect(find.text('下一步'), findsNothing)` + `expect(find.text('次へ'), findsNothing)` + presence of all 6 field surfaces. No push to TransactionConfirmScreen or TransactionEntryScreen in any code path. |
| SC-2 | Each amount-keypad digit key meets platform-minimum touch target (iOS HIG 44pt / Material 48dp), verified by widget test | ✓ VERIFIED | `smart_keyboard.dart:59`: `final keyHeight = math.max(48.0, rawKeyHeight)` — NON-NEGOTIABLE per RESEARCH §Pitfall 1. `smart_keyboard_test.dart` lines 15-64: 3-surface loop (iPhone SE 375×667, iPhone 14 390×844, Pro Max 428×926) each asserts `box.size.height >= 48.0` on all InkWell descendants. The SE case would fail ~36.96 dp without the clamp. |
| SC-3 | Adjacent keypad keys are visually discriminable per a golden test covering ja/zh/en locale renders in both light and dark themes | ✓ VERIFIED (human approval needed for baseline quality) | `smart_keyboard_golden_test.dart` produces 6 baseline PNGs via a 3×2 loop (ja/zh/en × light/dark) all at 390×844 surface. PNGs at `test/widget/features/accounting/presentation/widgets/goldens/` — all non-zero (8,183–8,565 bytes). Human-approved per `19-02-SUMMARY.md` ("layout (key separation, gradient on Save, light/dark contrast, action row uniformity) IS visible and correct"). |
| SC-4 | User can save a manual entry from the single screen and the resulting Transaction row has `entry_source = 'manual'` | ✓ VERIFIED | `manual_save_entry_source_test.dart` line 227: `expect(rows.first.entrySource, 'manual')` against a real `AppDatabase.forTesting()` with real `CreateTransactionUseCase`. Voice path also covered: same file line 240 asserts `'voice'` when constructed with `EntrySource.voice`. |
| SC-5 | All new UI strings are routed through S.of(context) with parity across ja/zh/en ARB files; flutter gen-l10n runs clean | ✓ VERIFIED | `keyboardToolbarDone` key present in all 3 ARBs (`app_en.arb:909 = "Done"`, `app_ja.arb:909 = "完了"`, `app_zh.arb:909 = "完成"`) plus `@keyboardToolbarDone` metadata in each. Generated: `app_localizations.dart:1396 = abstract String get keyboardToolbarDone;`, `_en.dart:704 = 'Done'`, `_ja.dart:697 = '完了'`, `_zh.dart:695 = '完成'`. `test/architecture/arb_key_parity_test.dart` exists as canonical enforcement. `actionLabel` (renamed from `nextLabel`) is supplied at every callsite from ARB string — no 'Next' default can leak. |

**Score:** 5/5 truths verified

---

### Deferred Items

No items addressed in later milestone phases. The pre-existing `home_hero_card_golden_test.dart` failures (11 tests, documented in `deferred-items.md`) are confirmed pre-existing at base commit 51ae327 — not Phase 19 regressions.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` | Single-screen manual entry replacing two-screen flow | ✓ VERIFIED | 466 lines, substantive: AmountDisplay + EntryModeSwitcher + TransactionDetailsForm + AnimatedSlide(SmartKeyboard) + conditional KeyboardToolbar. Wired: GlobalKey→form.submit()/updateAmount(), FocusNode listeners, voice/router/shell all push this screen. |
| `lib/features/accounting/presentation/widgets/smart_keyboard.dart` | Responsive-height SmartKeyboard with 48dp floor, actionLabel, tabular figures | ✓ VERIFIED | 398 lines. `math.max(48.0, rawKeyHeight)` clamp at line 59. `required String actionLabel` with no default (line 28). `FontFeature.tabularFigures()` at line 251. `EdgeInsets.symmetric(horizontal: 3)` at 7 locations (3+3=6dp total gap). 4× `SizedBox(height: 12)` inter-row gaps. No `height: 50` literals, no `horizontal: 4` or `horizontal: 6`. |
| `lib/features/accounting/presentation/widgets/keyboard_toolbar.dart` | Handwritten 44dp floating toolbar | ✓ VERIFIED | Exists. Imports only `package:flutter/material.dart` + project tokens — zero pub.dev deps. `class KeyboardToolbar extends StatelessWidget`. |
| `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart` | Shared bottom-sheet amount editor | ✓ VERIFIED | Exists. `class AmountEditBottomSheet extends StatelessWidget`. `static Future<void> show(...)`. Uses `actionLabel: S.of(context).record` (POST-rename API, P19-B2 fix). Dark mode: `isDark ? AppColorsDark.card : AppColors.card` (CR-02 fix). |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | Externalized amount, updateAmount(int), ValueKey markers, FocusNode wiring | ✓ VERIFIED | `_editAmount` = 0 references. `AmountDisplay` = 0 references. `void updateAmount(int amount)` at line 188. ValueKey markers: `'category-chip'` (591), `'date-chip'` (601), `'merchant-textfield'` (448), `'note-textfield'` (530). `merchantFocusNode` and `noteFocusNode` wired via `maybeWhen`. |
| `lib/features/accounting/domain/models/transaction_details_form_config.dart` | `$new` factory with optional FocusNode fields | ✓ VERIFIED | `FocusNode? merchantFocusNode` at line 41, `FocusNode? noteFocusNode` at line 42 in `$new` factory. Freezed config regenerated (`transaction_details_form_config.freezed.dart` has both fields at lines 150, 205, 256). |
| `lib/l10n/app_{en,ja,zh}.arb` | `keyboardToolbarDone` key + @-metadata in all 3 locales | ✓ VERIFIED | Each ARB has key + metadata (grep returns 2 for each @-meta check). Values: en="Done", ja="完了", zh="完成". |
| `lib/generated/app_localizations*.dart` | Generated S delegate with keyboardToolbarDone | ✓ VERIFIED | Abstract getter at `app_localizations.dart:1396`. Concrete: en→"Done", ja→"完了", zh→"完成". |
| `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` | SC-1 widget test + focus state machine tests | ✓ VERIFIED | 10 testWidgets. SC-1 asserts no Next/下一步/次へ + all 6 field ValueKeys. D-13 Scaffold flag. P19-W3 FocusNode plumbing. P19-W1 save guard. CR-01 decimal regression. WR-01 deadlock recovery. |
| `test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` | SC-2 height-floor test across 3 device sizes | ✓ VERIFIED | 5 testWidgets: 3 surface sizes (SE/14/Pro Max) all assert `>= 48.0 dp` on every InkWell. P19-B3 spacing: 6dp rendered gap + `horizontal:3` source check + 4× `SizedBox(height:12)`. actionLabel rename + no 'Next' leak. Tabular figures `f.feature == 'tnum'`. D-08 uniform action row height. |
| `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` | SC-3 6-image golden regression matrix | ✓ VERIFIED | File at D-09-locked path. 3-locale × 2-theme double loop → 6 testWidgets executions. `_wrap` helper with MaterialApp + localizationsDelegates + themeMode. `matchesGoldenFile` invoked. No `alchemist`/`golden_toolkit` dep. |
| `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_*.png` | 6 baseline PNGs | ✓ VERIFIED | All 6 files exist, non-zero (8,183–8,565 bytes each). |
| `test/integration/features/accounting/manual_save_entry_source_test.dart` | SC-4 DB-level entry_source assertion | ✓ VERIFIED | 2 testWidgets. Uses `AppDatabase.forTesting()` + real `CreateTransactionUseCase`. Asserts `rows.first.entrySource == 'manual'` and the voice variant asserts `'voice'`. |
| `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` | D-16 voice regression test | ✓ VERIFIED | 4 testWidgets. Tests voice push → entrySource=voice, params round-trip, DB stamping 'voice', and SoulCelebrationOverlay (IN-01 fix). |
| `(absent) lib/features/accounting/presentation/screens/transaction_entry_screen.dart` | DELETED | ✓ VERIFIED | `ls` returns ABSENT. `grep -rE 'TransactionEntryScreen' lib/` returns ZERO matches. |
| `(absent) lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` | DELETED | ✓ VERIFIED | `ls` returns ABSENT. `grep -rE 'TransactionConfirmScreen' lib/` returns ZERO matches. |

---

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `manual_one_step_screen.dart` | `TransactionDetailsForm` | `GlobalKey<TransactionDetailsFormState>._formKey` | ✓ WIRED | Line 69: `_formKey = GlobalKey<TransactionDetailsFormState>()`. Lines 203, 219, 229, 236, 243: `_formKey.currentState?.updateAmount(parsed)`. Line 282: `_formKey.currentState!.submit()`. |
| `manual_one_step_screen.dart` | `TransactionDetailsFormConfig.$new(merchantFocusNode:, noteFocusNode:)` | Per-host FocusNode P19-W3 | ✓ WIRED | Lines 423-424: `merchantFocusNode: _merchantFocus, noteFocusNode: _noteFocus` in config constructor. Listeners at `_merchantFocus = FocusNode()..addListener(_handleFocusChange)`. |
| `manual_one_step_screen.dart` | `SmartKeyboard` inside `AnimatedSlide` | `offset: Offset(0, _showSmartKeypad ? 0 : 1)` | ✓ WIRED | Lines 431-443: `AnimatedSlide(offset: Offset(0, _showSmartKeypad ? 0 : 1), duration: 220ms, curve: Curves.easeInOut, child: SmartKeyboard(...))`. |
| `manual_one_step_screen.dart` | `KeyboardToolbar` via Stack+Positioned | `if (_isTextFieldFocused)` conditional | ✓ WIRED | Lines 450-462: `Positioned(left: 0, right: 0, bottom: viewInsetsBottom, child: KeyboardToolbar(onDone: FocusManager.instance.primaryFocus?.unfocus, onSave: _trySave, isSubmitting: _isSubmitting || !_canSave))`. |
| `voice_input_screen.dart:353` | `ManualOneStepScreen` | `MaterialPageRoute` push with `entrySource: EntrySource.voice` | ✓ WIRED | Line 354-365: all voice params passed including `entrySource: EntrySource.voice`. |
| `entry_mode_navigation_config.dart:24` | `ManualOneStepScreen` | Router manual-route builder | ✓ WIRED | `builder: (bookId) => ManualOneStepScreen(bookId: bookId)` — TransactionEntryScreen is gone. |
| `main_shell_screen.dart:128` | `ManualOneStepScreen` | FAB push | ✓ WIRED | `builder: (_) => ManualOneStepScreen(bookId: bookId)`. |
| `transaction_edit_screen.dart:77` | `AmountEditBottomSheet.show` | D-14 spillover | ✓ WIRED | `await AmountEditBottomSheet.show(context, initialAmount: ..., onConfirm: ...)`. |
| `ocr_review_screen.dart:96` | `AmountEditBottomSheet.show` | D-14 spillover | ✓ WIRED | `await AmountEditBottomSheet.show(context, initialAmount: ..., onConfirm: ...)`. |
| `amount_edit_bottom_sheet.dart:162` | `SmartKeyboard(actionLabel: ...)` | POST-rename API P19-B2 | ✓ WIRED | `actionLabel: S.of(context).record`. No `nextLabel:` reference. |
| `smart_keyboard.dart` | `math.max(48.0, rawKeyHeight)` clamp | LayoutBuilder + MediaQuery | ✓ WIRED | Line 57-59: `available = mq.size.height * 0.40 - mq.padding.bottom - (4 * 12.0)`, `rawKeyHeight = available / 5`, `keyHeight = math.max(48.0, rawKeyHeight)`. Passed to all row builders. |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `ManualOneStepScreen` | `_amount` (string) | User digit taps → `setState(() => _amount += digit)` | Yes — flows to `AmountDisplay(amount: _amount)` (line 385) and `_formKey.currentState?.updateAmount(parsed)` (line 203) | ✓ FLOWING |
| `ManualOneStepScreen` | `_selectedCategory` | `_initializeDefaultCategory()` → real `categoryRepository.findActive()` call or pre-seeded `widget.initialCategory` | Yes — guards `_canSave` and is passed in config to `TransactionDetailsForm` | ✓ FLOWING |
| `SmartKeyboard` | `keyHeight` | `MediaQuery.of(context).size.height * 0.40` responsive formula | Yes — rendered per-key height from real screen dimensions, clamped at 48dp | ✓ FLOWING |
| `manual_save_entry_source_test` | `rows.first.entrySource` | `AppDatabase.forTesting()` real DB write via `CreateTransactionUseCase` | Yes — full DB round-trip, not mocked | ✓ FLOWING |

---

### Behavioral Spot-Checks

Step 7b skipped for golden test verification (requires image viewer, not a runnable command). Widget test suite is the proxy.

| Behavior | Evidence | Status |
| -------- | -------- | ------ |
| No "下一步" in manual path | `manual_one_step_screen_test.dart` asserts `findsNothing` for 'Next', '下一步', '次へ' | ✓ PASS |
| 48dp floor on iPhone SE | `smart_keyboard_test.dart` 3-surface loop including Size(375,667) | ✓ PASS |
| 6dp column gap | `smart_keyboard_test.dart` rendered-gap assertion: `pos2.dx - (pos1.dx + box1.size.width) == 6.0 ±0.5` | ✓ PASS |
| entry_source='manual' in DB | `manual_save_entry_source_test.dart` asserts `rows.first.entrySource == 'manual'` against real DB | ✓ PASS |
| actionLabel not 'Next' | `smart_keyboard_test.dart`: `expect(find.text('Next'), findsNothing)` when `actionLabel: 'Record'` | ✓ PASS |
| CR-01 decimal fix | `manual_one_step_screen_test.dart` CR-01 test: typing "1","2","3","." invokes use case with `amount=123` (not 0) | ✓ PASS |
| WR-01 try/finally | `manual_one_step_screen_test.dart` WR-01 test: persist error → second save still works (use case called twice) | ✓ PASS |

---

### Probe Execution

Step 7c: No probe scripts found for Phase 19. SKIPPED — no `scripts/*/tests/probe-*.sh` exist, and no probes declared in PLAN frontmatter.

---

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| KEYPAD-01 | 19-01, 19-02, 19-03 | Digit key height meets platform min (44pt iOS / 48dp Material); visual hierarchy makes adjacent keys discriminable at thumb reach | ✓ SATISFIED | `math.max(48.0, ...)` clamp verified in `smart_keyboard.dart:59`. Widget test asserts `>= 48.0` on 3 device sizes. Golden test + 6 PNGs for visual discriminability. |
| INPUT-01 | 19-01, 19-03, 19-04, 19-05 | Manual ledger entry on single screen — all fields editable inline without "下一步" navigation | ✓ SATISFIED | `ManualOneStepScreen` is the single screen. TransactionEntryScreen + TransactionConfirmScreen deleted. Widget test asserts absence of navigation button and presence of all 6 field surfaces. SC-4 integration test confirms DB save path works. |

Both KEYPAD-01 and INPUT-01 are mapped to Phase 19 in the traceability table at `REQUIREMENTS.md:107-108` (status: Pending — note this reflects the REQUIREMENTS.md state before phase close; the phase has implemented these requirements).

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `smart_keyboard.dart:39` | 39 | `// renamed from nextLabel` comment | ℹ️ Info | Historical comment, not functional. No `nextLabel` in the actual API. |
| `transaction_details_form.dart` | various | `INTERNAL_UNMOUNTED` sentinel string (IN-02 fix) | ℹ️ Info | Unreachable code path sentinel; correctly marked with explanatory comment. Not a user-visible string. |

No TBD, FIXME, or XXX markers found in any Phase 19 modified production files. No `return null` / empty stubs in core rendering paths. No `Colors.white` hardcoding remaining (CR-02 fixed). No `int.tryParse` bug (CR-01 fixed). No unresolved critical or warning findings.

---

### Human Verification Required

#### 1. Visual Review of 6 SmartKeyboard Golden Baselines

**Test:** Open all 6 PNG files at `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_{ja,zh,en}_{light,dark}.png` in an image viewer.

**Expected:**
- Adjacent digit keys are clearly separated (6 dp total gap visible — keys not touching but not double-spaced)
- Save (gradient) button on the bottom-right has the coral gradient (`actionGradientStart` → `actionGradientEnd`) and is visually distinct from peer keys
- Backspace and currency (¥JPY) keys are visual peers of digit keys at equal height
- Dark mode: background is `AppColorsDark.card`, digit fills are `AppColorsDark.backgroundMuted`; adequate contrast
- Tabular figures: in any digit row, glyphs are aligned (proportional-figure wandering would be visible)
- 'Record' label on the Save button is readable in all 3 locales. Note: CJK font fallback may render glyphs as boxes in headless screenshots (confirmed expected behavior per RESEARCH §Pitfall 7 — the structural layout is verifiable, the CJK rendering is a headless env limitation)

**Why human:** `matchesGoldenFile` only detects drift from the baseline — it cannot verify the baseline itself is correct. Human-approved during Plan 02 execution; carried forward as required item.

#### 2. Physical Device Keypad Feel (iOS)

**Test:** Run the app on a physical iPhone (SE or newer) in a fresh manual entry flow. Tap all digit keys with a natural thumb grip.

**Expected:**
- Digit taps register correctly with the intended digit ≥95% of taps (KEYPAD-01 functional)
- No adjacent-key mis-taps from keys being too small or too close
- SmartKeyboard slides off-screen smoothly when merchant/note TextField is focused
- Tapping AmountDisplay brings the SmartKeyboard back
- KeyboardToolbar Done button dismisses the soft keyboard
- KeyboardToolbar Save button saves the entry correctly

**Why human:** Widget tests confirm 48 dp floor via `RenderBox.size.height` and 6 dp column gap via `localToGlobal` coordinates. Device ergonomics (actual thumb reach, tap registration under real touch conditions, animation fluidity at 60fps on device) cannot be verified programmatically.

---

### Gaps Summary

No blocking gaps found. All 5 success criteria are satisfied in the codebase:

- SC-1: Implemented and widget-test verified (no Next button, 6 fields inline)
- SC-2: Implemented (`math.max(48.0, ...)` clamp) and widget-test verified on 3 device sizes
- SC-3: Golden test exists, 6 PNGs committed, human-approved during execution
- SC-4: Integration test passes against real DB
- SC-5: ARB keys present in all 3 locales, generated delegates verified

All 8 code review findings (CR-01, CR-02, WR-01, WR-02, WR-03, IN-01, IN-02, IN-03) are fixed and committed (commits 07a9f7d through bfd6426 per `19-REVIEW-FIX.md`). The pre-existing `home_hero_card_golden_test.dart` failures are confirmed pre-Phase-19 at base commit 51ae327 and are explicitly out of scope per `deferred-items.md`.

The status is `human_needed` (not `passed`) because SC-3's visual-discriminability baseline and SC-2's device ergonomics each require human inspection. Both automated checks pass; only the physical device + visual baseline review remains.

---

_Verified: 2026-05-23T07:33:18Z_
_Verifier: Claude (gsd-verifier)_
