# Phase 22: Voice One-Step Integration + Record Button UX — Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 11 (6 modify, 3 create, 1 delete, 1 auto-regenerate)
**Analogs found:** 9 / 11 (2 use SDK-only patterns — no in-repo precedent)

---

## File Classification

| File | Op | Role | Data Flow | Closest Analog | Match Quality |
|------|-----|------|-----------|----------------|---------------|
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | MODIFY (body rewrite) | screen (ConsumerStatefulWidget) | event-driven + request-response | `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` | exact role + same-feature peer (sibling under `EntryModeSwitcher`) |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | MODIFY (extend public surface; +3 methods) | widget (ConsumerStatefulWidget with public State) | event-driven (setter mutators) | Self — existing `updateAmount(int)` at lines 188-192 | exact (mirror Phase 19 D-14 pattern on same State class) |
| `lib/l10n/app_{ja,zh,en}.arb` | MODIFY (− tapToRecord, + holdToRecord, + recording × 3) | i18n string resources | static data | Existing ARB entries at lines 1037-1052 in each file | exact (file format, key+@description block shape) |
| `lib/core/theme/app_colors.dart` | MODIFY (optional — add 2 constants) | theme/config | static data | Existing `actionGradientStart`/`actionGradientEnd` at lines 29-31 | exact (same constant class pattern) |
| `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | MODIFY (major rewrite) | widget test | event-driven + request-response | Same file (existing test scaffolding + Fakes lines 1-160) | partial — keep Fakes; replace assertions |
| `test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart` | MODIFY (extend with D-07 tests) | widget test | event-driven | `test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart` (Phase 19 D-14) | exact (mirror the 6-test layout for the 3 new setters) |
| `test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` | CREATE | golden test | static visual snapshot | `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` | exact (single locale × theme matrix collapses to 1×1; same `_wrap` helper shape) |
| `test/widget/features/accounting/presentation/screens/goldens/voice_input_screen_mic_button_golden.png` | CREATE (auto via `--update-goldens`) | golden baseline | binary asset | `test/widget/.../widgets/goldens/smart_keyboard_*.png` | exact (same `matchesGoldenFile` flow) |
| `test/integration/features/accounting/voice_save_entry_source_test.dart` | CREATE | integration test | request-response (DAO write round-trip) | `test/integration/features/accounting/manual_save_entry_source_test.dart` | exact (mirror lines 1-243; swap `ManualOneStepScreen` → `VoiceInputScreen`, swap SmartKeyboard tap-sequence → long-press gesture) |
| `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` | DELETE | widget test (Phase 19 D-16 regression) | n/a | n/a (file becomes obsolete with D-02 push deletion) | n/a |
| `lib/generated/app_localizations*.dart` | AUTO-REGEN (`flutter gen-l10n`) | generated i18n class | n/a | n/a — never hand-edit (CLAUDE.md Pitfall #1) | n/a |

**Wave 0 (setup) → Wave 1 (screen rewrite) → Wave 2 (tests) blocking order:**
1. `transaction_details_form.dart` D-07 extension MUST land before voice screen body rewrite (host calls the new methods).
2. ARB key swap + `flutter gen-l10n` MUST run before screen rewrite (screen references `l10n.holdToRecord` / `l10n.recording`).
3. `transaction_details_form_test.dart` extension can run in parallel with #1.
4. Golden harness can be scaffolded in parallel; baseline PNG generated after Wave 1 screen rewrite lands.
5. Integration test depends on Wave 1 screen completion.

---

## Pattern Assignments

### `voice_input_screen.dart` (screen, event-driven + request-response) — MODIFY (body rewrite)

**Primary analog:** `lib/features/accounting/presentation/screens/manual_one_step_screen.dart`
**Self-reference:** same file lines 95-223 (existing state + lifecycle)

#### A. Imports + class shell (KEEP from existing)

Existing imports + `ConsumerStatefulWidget` class shell stay verbatim from `voice_input_screen.dart:1-46`. Only adjustments:
- Add `import 'package:flutter/gestures.dart';` for `LongPressGestureRecognizer` + `LongPressStartDetails` / `LongPressEndDetails`.
- Add `import '../widgets/transaction_details_form.dart';`
- Add `import '../widgets/amount_edit_bottom_sheet.dart';`
- Add `import '../widgets/amount_display.dart';`
- Remove `import 'manual_one_step_screen.dart';` (D-02 — no longer push to it).

#### B. State fields + FocusNode lifecycle (analog `manual_one_step_screen.dart:69-131`)

```dart
// Source: lib/features/accounting/presentation/screens/manual_one_step_screen.dart:69-101
class _ManualOneStepScreenState extends ConsumerState<ManualOneStepScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();

  late final FocusNode _merchantFocus;
  late final FocusNode _noteFocus;

  // ...
  bool _isTextFieldFocused = false;

  @override
  void initState() {
    super.initState();
    // P19-W3: per-host FocusNodes wired through the form config so the form's
    // TextFields use them. Listeners update _isTextFieldFocused.
    _merchantFocus = FocusNode()..addListener(_handleFocusChange);
    _noteFocus = FocusNode()..addListener(_handleFocusChange);
    // ...
  }

  @override
  void dispose() {
    _merchantFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }
```

**Phase 22 application:** Add the same three fields + `initState` lines to `_VoiceInputScreenState`. Replace `_handleFocusChange` body with D-09 auto-stop behavior (next excerpt).

#### C. FocusNode listener — D-09 auto-stop variant (NEW behavior, analog structure)

Structure copied from `manual_one_step_screen.dart:171-179`; body adapted for D-09:

```dart
// Source: lib/features/accounting/presentation/screens/manual_one_step_screen.dart:171-179
void _handleFocusChange() {
  final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
  // Equality guard: prevents rebuild storms during soft-keyboard animation.
  if (hasTextFocus == _isTextFieldFocused) return;
  setState(() {
    _isTextFieldFocused = hasTextFocus;
    if (hasTextFocus) _amountFocused = false;
  });
}
```

**Phase 22 variant (D-09):**
```dart
void _handleFocusChange() {
  final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
  if (hasTextFocus && _isRecording) {
    // D-09: auto-stop recording on text-field focus; mic returns to idle.
    // Do NOT batch-fill the form (commit path is short-circuited).
    _cancelRecordingAndDiscard();
  }
}
```

**What's new vs analog:** the manual screen toggles a `_isTextFieldFocused` UI flag; voice screen instead short-circuits the recording session. Same FocusNode wiring shape; different effect.

#### D. Embed `TransactionDetailsForm` (analog `manual_one_step_screen.dart:402-426`)

```dart
// Source: lib/features/accounting/presentation/screens/manual_one_step_screen.dart:402-426
Expanded(
  child: SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(16, 8, 16, scrollPaddingBottom),
    child: TransactionDetailsForm(
      key: _formKey,
      config: TransactionDetailsFormConfig.$new(
        bookId: widget.bookId,
        initialAmount: widget.initialAmount,
        initialCategory: _selectedCategory,
        initialParentCategory: _selectedParentCategory,
        initialDate: _selectedDate,
        initialMerchant: widget.initialMerchant,
        initialSatisfaction: widget.initialSatisfaction,
        voiceKeyword: widget.voiceKeyword,
        entrySource: widget.entrySource,
        // P19-W3: per-host FocusNodes so _handleFocusChange fires.
        merchantFocusNode: _merchantFocus,
        noteFocusNode: _noteFocus,
      ),
    ),
  ),
),
```

**Phase 22 variant:**
- `entrySource: EntrySource.voice` (hardcoded — voice screen has fixed entry-source identity per Phase 17 D-06)
- `bookId: widget.bookId` (verbatim)
- All `initialX` fields null at mount; voice batch-fills via `_formKey.currentState!.updateXxx(...)` on release (D-05)
- `voiceKeyword: _extractVoiceKeyword(...)` from the existing helper at `voice_input_screen.dart:410-431` (keep it)
- `merchantFocusNode: _merchantFocus`, `noteFocusNode: _noteFocus` (D-09 wiring)
- Padding can stay simpler than manual's — no SmartKeyboard offset to compute.

#### E. Long-press recognizer (NO IN-REPO ANALOG — SDK pattern)

**No codebase analog.** Phase 22 is the first in-repo user of `RawGestureDetector` + `LongPressGestureRecognizer(duration: Duration.zero)`. Use the canonical SDK pattern documented in RESEARCH.md §Pattern 1.

**SDK source:** `/Users/xinz/flutter/packages/flutter/lib/src/gestures/long_press.dart:281-290`
**SDK doc pattern:** `/Users/xinz/flutter/packages/flutter/lib/src/widgets/gesture_detector.dart:1283-1338` (RawGestureDetector docstring example)

```dart
// Source: pattern derived from Flutter SDK widgets/gesture_detector.dart RawGestureDetector docstring
// Phase 22 D-03 — hold-to-record with instant press fire + 300 ms misfire threshold.
RawGestureDetector(
  gestures: <Type, GestureRecognizerFactory>{
    LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(duration: Duration.zero, debugOwner: this),
      (LongPressGestureRecognizer instance) {
        instance
          ..onLongPressStart = _onLongPressStart
          ..onLongPressEnd = _onLongPressEnd
          ..onLongPressCancel = _onLongPressCancel;
      },
    ),
  },
  child: AnimatedContainer(/* see Excerpt F */),
)
```

**Callback bodies:** see RESEARCH.md §Code Examples §Example 1 (lines 711-792). Critical:
- `_onLongPressStart` records `_pressStart = DateTime.now()` → calls `_startRecording()` (existing helper at `voice_input_screen.dart:169-212`).
- `_onLongPressEnd` computes `held = DateTime.now().difference(_pressStart!)`; if `< 300 ms` → `_cancelRecordingAndDiscard()`; else `_stopRecordingAndCommit()`.
- `_onLongPressCancel` → treat as misfire (`_cancelRecordingAndDiscard()`).
- **Note:** existing `_toggleRecording` (lines 159-167) DELETED. Existing `_startRecording` (169-212) KEPT verbatim. Existing `_stopRecording` (214-223) renamed/extended to `_stopRecordingAndCommit` (adds parse + 4 setter calls per D-05). NEW `_cancelRecordingAndDiscard` calls `_speechService.cancel()` (NOT `.stop()` — see Pitfall 6) + `_amountMerger?.dispose()` (NOT `.stop()` — discard, not commit).

#### F. AnimatedContainer mic morph (analog `input_mode_tabs.dart:67-85`)

In-repo analog uses `AnimatedContainer` for background color + borderRadius transition:

```dart
// Source: lib/features/accounting/presentation/widgets/input_mode_tabs.dart:67-85
GestureDetector(
  onTap: () => onChanged(mode),
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: isActive
          ? (isDark ? AppColorsDark.card : AppColors.card)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      boxShadow: isActive ? [ /* ... */ ] : null,
    ),
    child: /* ... */,
  ),
),
```

**Phase 22 variant (combines analog structure with D-04 morph spec):**

```dart
// Source: composition of input_mode_tabs.dart analog + voice_input_screen.dart:541-567 current mic + D-04 spec
AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  curve: Curves.easeInOut,
  width: 72,
  height: 72,
  decoration: BoxDecoration(
    shape: BoxShape.rectangle,                                  // ALWAYS rectangle (avoids circle ↔ borderRadius mutex)
    borderRadius: BorderRadius.circular(_isRecording ? 16 : 36),// 36 ≈ circle on 72×72 (Pattern 2 geometric proof)
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _isRecording
          ? const [AppColors.recordingGradientStart, AppColors.recordingGradientEnd]
          : const [AppColors.actionGradientStart, AppColors.actionGradientEnd],
    ),
    boxShadow: const [
      BoxShadow(color: AppColors.actionShadow, blurRadius: 16, offset: Offset(0, 4)),
    ],
  ),
  child: const Icon(Icons.mic, color: Colors.white, size: 32),  // Mic icon unchanged in both states (D-04)
)
```

**What's new vs analog:** `input_mode_tabs` only animates `color` + `borderRadius`; Phase 22 animates `borderRadius` + `gradient` + (transitively) the box's visual appearance under the same lattice. Same `AnimatedContainer` primitive; no new dependencies.

#### G. AnimatedSwitcher caption (NO IN-REPO ANALOG — SDK pattern)

No codebase analog (grep found 0 `AnimatedSwitcher` users in `lib/features/`). Use Flutter SDK doc pattern.

**SDK doc:** api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html (fetched 2026-05-25 per RESEARCH.md §Sources).

```dart
// Source: Flutter SDK doc — AnimatedSwitcher cross-fade with keyed Text child.
AnimatedSwitcher(
  duration: const Duration(milliseconds: 150),
  child: Text(
    _isRecording ? l10n.recording : l10n.holdToRecord,
    key: ValueKey(_isRecording),                       // bool flip drives the child swap
    style: AppTextStyles.bodySmall.copyWith(
      color: isDark
          ? AppColorsDark.textTertiary
          : AppColors.textTertiary,
    ),
  ),
)
```

**Replaces:** existing static `Text(l10n.tapToRecord, ...)` at `voice_input_screen.dart:571-578`.

#### H. Save button (analog: existing Next button at `voice_input_screen.dart:582-627`)

Current `Next` button structure is the right host-CTA shape — keep the full-width gradient `DecoratedBox` + `Material` + `InkWell` chrome verbatim; rename label l10n key and rewire `onTap`:

```dart
// Source: lib/features/accounting/presentation/screens/voice_input_screen.dart:582-627 (existing)
Padding(
  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
  child: SizedBox(
    width: double.infinity,
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: hasResult
            ? const LinearGradient(/* full gradient */)
            : LinearGradient(/* 40% alpha gradient */),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasResult ? _navigateToConfirm : null,         // ← REWIRE in Phase 22
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(l10n.next, /* ... */),                  // ← RENAME to l10n.save (existing ARB key)
          ),
        ),
      ),
    ),
  ),
),
```

**Phase 22 changes:**
- `l10n.next` → existing `l10n.save` ARB key (already in ARB files; verify via grep).
- `onTap: hasResult ? _navigateToConfirm : null` → `onTap: _canSave ? _onSavePressed : null` where:
  - `_canSave = _formKey.currentState?.... && !_isSubmitting` (planner picks predicate per RESEARCH §Open Q3 — recommended: host-side `_resolvedCategory != null && _mergedAmount != null && _mergedAmount! > 0 && !_isSubmitting`).
  - `_onSavePressed()` calls `_formKey.currentState!.submit()` and consumes the `TransactionDetailsFormResult` per `manual_one_step_screen.dart:278-304` pattern.

#### I. Save handler — submit() + post-save nav (analog `manual_one_step_screen.dart:278-304`)

```dart
// Source: lib/features/accounting/presentation/screens/manual_one_step_screen.dart:278-304
Future<void> _save() async {
  if (_isSubmitting) return;
  setState(() => _isSubmitting = true);
  try {
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).transactionSaved)),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);  // D-04 preserved
      },
      validationError: (msg) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
      persistError: (msg) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
```

**Phase 22:** copy verbatim; rename to `_onSavePressed` (or `_save` — planner discretion). The `try/finally` resets `_isSubmitting` even on exception (manual screen's WR-01 fix).

#### J. Batch fill on commit — drives `updateAmount` / `updateCategory` / `updateMerchant` / `updateNote`

**Analog:** `manual_one_step_screen.dart:192-204` (digit handler calls `_formKey.currentState?.updateAmount(parsed)`)

```dart
// Source: lib/features/accounting/presentation/screens/manual_one_step_screen.dart:192-204
void _onDigit(String digit) {
  _dismissToast();
  // ... amount-string-mutation logic ...
  setState(() => _amount += digit);
  final parsed = (double.tryParse(_amount) ?? 0.0).round();
  _formKey.currentState?.updateAmount(parsed);
}
```

**Phase 22 `_stopRecordingAndCommit` batch fill (composition of analog + D-05):**
- See RESEARCH.md §Code Examples §Example 1 (lines 753-791) for the full body.
- Critical sequence: `merger.stop()` (synchronous commit) → `await _speechService.stop()` (async drain) → `parseVoiceInputUseCase.execute(text, localeId: _voiceLocaleId)` → `await categoryRepo.findById(...)` for category + parent lookup → 4 `_formKey.currentState!.updateXxx(...)` calls.
- The 4 setter calls mirror the Phase 19 `_onDigit → updateAmount` pattern — host computes value, pushes via public method.

#### K. Vestigial code DELETE (D-02 + cleanup)

| Item | Lines (current) | Disposition |
|------|-----------------|-------------|
| `_toggleRecording` | 159-167 | DELETE (tap-toggle replaced by hold-to-record) |
| `_navigateToConfirm` | 368-408 | DELETE (D-02 — no second screen) |
| `VoiceRecognitionResultCard` mount | 515-525 | DELETE (replaced by embedded `TransactionDetailsForm`) |
| `_parsedAmountText` / `_parsedCategoryText` / `_parsedDateText` helpers | 437-457 | DELETE (read-only card display only) |
| `_extractVoiceKeyword` helper | 410-431 | KEEP — output flows into `TransactionDetailsFormConfig.$new(voiceKeyword: ...)` (Phase 18 D-09 voice-correction hook) |
| `VoiceRecognitionResultCard` class | 643-740 (after Column) | DELETE (now unused) |
| `_ParsedInfoRow`/`_ParsedDivider` | 742-813 | DELETE (parent card gone) |
| ARB key `tapToRecord` usage at line 572 | 571-578 | REPLACE with AnimatedSwitcher (Excerpt G) |

---

### `transaction_details_form.dart` (widget, event-driven) — MODIFY (extend public surface)

**Primary analog:** Self — existing `updateAmount(int)` at lines 188-192.

**This is "extend existing public surface", NOT body rewrite.** The form widget's internal lifecycle (initState, dispose, _editCategory, _editDate, submit) stays untouched. Only the public mutator surface grows from 2 methods (`submit()`, `updateAmount`) to 5 (`submit()`, `updateAmount`, `updateCategory`, `updateMerchant`, `updateNote`).

#### A. Existing setter pattern (lines 188-192)

```dart
// Source: lib/features/accounting/presentation/widgets/transaction_details_form.dart:182-192
/// Phase 19 D-14 — host owns amount editing UX; form widget keeps `_amount`
/// in sync for save-time validation in `submit()`.
///
/// Short-circuits if the new value equals the current `_amount` (Pattern S-1
/// idempotency — prevents unnecessary rebuilds when the host's SmartKeyboard
/// fires on every digit).
void updateAmount(int amount) {
  if (!mounted) return;
  if (amount == _amount) return;
  setState(() => _amount = amount);
}
```

#### B. Phase 22 D-07 new methods (sibling of analog)

Place these immediately after `updateAmount` (i.e., after line 192) — keep all five public setters in one block for discoverability.

```dart
// Mirror of updateAmount with category-specific cache + ledger resolution.
// Analog of internal _editCategory path (lines 194-253) — same setState block + same _resolveLedgerType call.
void updateCategory(Category category, Category? parentCategory) {
  if (!mounted) return;
  if (category.id == _category?.id) return;                     // idempotency guard
  setState(() {
    _categoryById[category.id] = category;
    if (parentCategory != null) _categoryById[parentCategory.id] = parentCategory;
    _category = category;
    _parentCategory = parentCategory;
  });
  // .new mode: resolve ledger type from new category (matches _editCategory line 219).
  _resolveLedgerType(category.id);
}

void updateMerchant(String merchant) {
  if (!mounted) return;
  if (merchant == _storeController.text) return;                // idempotency — prevents TextField rebuild storm
  _storeController.text = merchant;                             // setting .text on existing controller triggers TextField rebuild
}

void updateNote(String note) {
  if (!mounted) return;
  if (note == _memoController.text) return;
  _memoController.text = note;
}
```

**What's new vs `updateAmount`:**
- `updateCategory` has TWO arguments (category + parent) and writes to TWO fields + the local `_categoryById` cache (mirrors the internal `_editCategory` writes at lines 211-216).
- `updateCategory` also calls `_resolveLedgerType(category.id)` (existing helper at lines 172-178) so the ledger toggle flips when voice resolves to a soul-ledger category.
- `updateMerchant` / `updateNote` mutate a `TextEditingController.text` rather than a `setState`-tracked field. **Pitfall 3 watch:** assigning `.text` resets cursor to position 0; D-09's auto-stop prevents this from being user-visible (TextField won't have focus when voice batch-fills).
- All three guards on `!mounted` (Pattern S-2 from Phase 19) and idempotency check (Pattern S-1).

**Planner discretion (D-07 / RESEARCH §Open Q2 — soul satisfaction):**
- If planner adopts RESEARCH Open Q2 recommendation: ADD a 4th sibling `updateSatisfaction(int)` that mirrors this exact shape (`if (value == _soulSatisfaction) return; setState(() => _soulSatisfaction = value.clamp(1, 10));`). This preserves Phase 11 satisfaction estimator wiring in the single-screen flow.

---

### `lib/l10n/app_{ja,zh,en}.arb` (i18n, static data) — MODIFY

**Analog:** Existing entries in the SAME files at lines 1037-1052 (`discard`, `tapToRecord`, `todayDate`, `next`).

#### Pattern: ARB entry shape

```jsonc
// Source: lib/l10n/app_ja.arb:1037-1044 (verbatim — current state)
  "discard": "破棄",
  "@discard": {
    "description": "Dialog confirm button: discard unsaved changes"
  },
  "tapToRecord": "タップして録音",
  "@tapToRecord": {
    "description": "Voice input hint"
  },
```

**Verified single production caller** of `tapToRecord`: `lib/features/accounting/presentation/screens/voice_input_screen.dart:572` (Phase 22 rewrites this line, so the removal is safe). Verified single test caller: `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart:384` (Phase 22 test rewrite replaces it).

#### Phase 22 ARB edits (verbatim per CONTEXT.md D-06)

```jsonc
// REMOVE from all 3 locales:
  "tapToRecord": "...",
  "@tapToRecord": {
    "description": "Voice input hint"
  },

// ADD to app_ja.arb (between `discard` and `todayDate` to preserve sort order):
  "holdToRecord": "押して話す",
  "@holdToRecord": {
    "description": "Voice idle caption: hold to speak (push-to-talk)"
  },
  "recording": "録音中…",
  "@recording": {
    "description": "Voice recording-state caption"
  },

// ADD to app_zh.arb:
  "holdToRecord": "按住说话",
  "@holdToRecord": { "description": "Voice idle caption: hold to speak (push-to-talk)" },
  "recording": "录音中…",
  "@recording": { "description": "Voice recording-state caption" },

// ADD to app_en.arb:
  "holdToRecord": "Hold to speak",
  "@holdToRecord": { "description": "Voice idle caption: hold to speak (push-to-talk)" },
  "recording": "Recording…",
  "@recording": { "description": "Voice recording-state caption" },
```

**Mandatory follow-up:** `flutter gen-l10n` after ARB edits (regenerates `lib/generated/app_localizations*.dart`). Then `flutter analyze` to flag any stale `l10n.tapToRecord` references (expected: 0 after Wave 1 screen + test rewrites).

**Sort-order discipline:** Existing ARB files are NOT strictly alphabetized — they follow phase-by-phase append order. Place new keys near the old `tapToRecord` slot (lines 1041-1044) to keep the diff focused.

---

### `lib/core/theme/app_colors.dart` (theme, static data) — MODIFY (optional)

**Analog:** Existing `actionGradientStart`/`actionGradientEnd` at lines 29-31.

```dart
// Source: lib/core/theme/app_colors.dart:23-33
abstract final class AppColors {
  // ── Accent — Primary (Coral) ──
  static const accentPrimary = Color(0xFFE85A4F);
  static const accentPrimaryLight = Color(0xFFFEF5F4);
  static const accentPrimaryBorder = Color(0xFFF5D5D2);
  static const fabGradientStart = Color(0xFFF08070);
  static const fabGradientEnd = Color(0xFFE85A4F);
  static const actionGradientStart = fabGradientStart;
  static const actionGradientEnd = fabGradientEnd;
  static const actionShadow = Color(0x4DE85A4F);
  // ...
}
```

**Phase 22 addition (D-04, planner discretion per CONTEXT.md):**

```dart
// Add near actionGradient* in AppColors:
static const recordingGradientStart = Color(0xFFE05050);  // planner finalizes exact hex
static const recordingGradientEnd   = Color(0xFFC03030);

// Add matching pair in AppColorsDark (lines 74+):
// (dark-theme red — slightly muted; planner picks final values)
```

**Note:** RESEARCH.md §Standard Stack confirms `AppColors` does NOT currently expose any `error`/`warning`/`recording` color family — so Phase 22 MUST add fresh constants if it wants stable named references rather than inline `Color(0xFFE05050)` literals at the call site. Inline hex is also acceptable per CLAUDE.md (no rule against it), but named constants improve theme consistency.

---

### `voice_input_screen_test.dart` (widget test) — MODIFY (major rewrite)

**Self-analog:** Same file lines 19-160 (existing Fakes: `FakeStartSpeechRecognitionUseCase`, `FakeDeniedStartSpeechRecognitionUseCase`, `CapturingStartSpeechRecognitionUseCase`). KEEP these verbatim — they remain the right test fixtures for the new gesture-driven flow.

**Pattern analog for setter assertions:** `transaction_details_form_update_amount_test.dart` (verified at lines 200-300).

#### A. Existing assertions to STRIP

```dart
// Source: test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart:359-385
// DELETE — these assert the pre-Phase-22 VoiceRecognitionResultCard skeleton:
expect(find.text('認識結果'), findsOneWidget);           // recognitionResult label
expect(find.text('金額'), findsOneWidget);              // amount label
expect(find.text('カテゴリ'), findsOneWidget);          // category label
expect(find.text('日付'), findsOneWidget);              // date label
expect(find.text('タップして録音'), findsOneWidget);    // tapToRecord (REMOVED)
```

#### B. New widget tests (REC-01 / REC-02 / D-08 / D-09 / 100ms)

See RESEARCH.md §Code Examples §Example 3 (lines 851-874) for the canonical 100ms Stopwatch test. Replicate the per-test setup pattern from existing `voice_input_screen_test.dart` (use `buildSubject(...)` helper at the top of the file).

Critical assertions per test:

| Test ID | Anchor finder | Critical assertion |
|---------|---------------|---------------------|
| REC-01 idle | `find.text('押して話す')` (or `S.of(...).holdToRecord` via element lookup) | `findsOneWidget` BEFORE long-press |
| REC-01 recording | `find.text('録音中…')` | `findsOneWidget` AFTER `tester.startGesture` + `tester.pump()` |
| REC-01 misfire | mock `_speechService.cancel()` tracker | `cancelled = true`, `parseUseCase.execute` not called |
| REC-02 visual | `find.byIcon(Icons.mic)` ancestor `AnimatedContainer` | `decoration.borderRadius` transitions from `BorderRadius.circular(36)` to `BorderRadius.circular(16)` |
| REC-02 timing | `Stopwatch` around `startGesture` + `pump()` | `stopwatch.elapsedMilliseconds < 100` |
| D-08 overwrite | pre-fill via `_formKey.updateAmount(100)`; emit voice "5千" | post-release form amount = 5000 |
| D-09 focus | start gesture → `tester.tap(find.byKey(ValueKey('merchant-textfield')))` | `_isRecording = false`, no batch-fill |
| INPUT-02 happy | mock parse → "1千8百4十元 星巴克" | form has amount=1840, category resolved, merchant set |

**Use `tester.startGesture` not `tester.longPress`:** `longPress` waits `kLongPressTimeout` (500ms); RawGestureDetector with `duration: Duration.zero` is sensitive to that delay timing. See RESEARCH.md §Pitfall 5.

---

### `transaction_details_form_test.dart` (widget test) — MODIFY (extend)

**Analog:** `test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart` (Phase 19 D-14 TDD tests for `updateAmount`).

#### Pattern: 6-test layout for a public setter

```dart
// Source: test/widget/features/accounting/presentation/widgets/transaction_details_form_update_amount_test.dart:200-481
// 6 tests:
//   TEST 1: updateAmount(0) + submit → validationError (no-category guard fires first)
//   TEST 2: updateAmount(1500) + submit → create use case called with amount==1500
//   TEST 3: idempotency — updateAmount(500) called twice — execute called once, amount=500
//   TEST 4: form no longer renders AmountDisplay internally (D-14 externalization)
//   TEST 5: ValueKey markers on chips/textfields (P19-W2)
//   TEST 6: FocusNode plumbing from config wires to TextField focus
```

#### Phase 22 D-07 test additions (mirror TEST 1-3 for each new setter)

For each of `updateCategory`, `updateMerchant`, `updateNote`, add 3 sibling tests:

```dart
// Template — adapt per setter:
// Test 1: updateXxx(value) + submit → use case called with field==value
// Test 2: idempotency — updateXxx(value) twice → execute called once, field=value
// Test 3: updateXxx before category null check → behavior matches contract
//         (e.g., updateMerchant before category set + submit → still validationError on no-category)
```

**For `updateCategory` specifically:** mirror TEST 2 but verify both
- `createTransactionUseCase.execute` called with `categoryId == newCategory.id`
- ledger toggle correctly flipped if new category has soul-ledger mapping (use `categoryServiceProvider.overrideWith(...)` to inject a controlled `resolveLedgerType` answer)

**For `updateMerchant` / `updateNote`:** assert `_storeController.text` and `_memoController.text` respectively (or assert via the rendered TextField content using `find.descendant(...)`).

**Reusable infrastructure:** `_overrides()` helper, `_buildForm()` helper, `_FakeCreateTransactionParams`, `_NullCategoryRepository` / `_SingleCategoryRepository` at lines 36-184 of the analog file. Phase 22 imports/extends these — no need to re-author.

---

### `voice_input_screen_mic_button_golden_test.dart` (golden test) — CREATE

**Analog:** `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` (lines 1-98 — 6-image matrix for SmartKeyboard).

#### Pattern: `_wrap` helper + matchesGoldenFile

```dart
// Source: test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart:31-98
Widget _wrap({
  required Locale locale,
  required ThemeMode themeMode,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: 390, child: child),
      ),
    ),
  );
}

void main() {
  group('SmartKeyboard golden — 6-image regression matrix (SC-3 / D-09)', () {
    for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
      for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('SmartKeyboard — ${locale.languageCode} / ${mode.name}', (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() async => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(_wrap(locale: locale, themeMode: mode, child: /* widget */));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(SmartKeyboard),
            matchesGoldenFile('goldens/smart_keyboard_${locale.languageCode}_${mode.name}.png'),
          );
        });
      }
    }
  });
}
```

#### Phase 22 variant — matrix COLLAPSES to 1 × 1 per D-12

Per CONTEXT.md D-12: "Golden ONLY for idle state, single locale × single theme" (caption is i18n-sensitive but the mic button SHAPE is not).

```dart
// Adaptation of smart_keyboard_golden_test.dart for Phase 22 D-12:
void main() {
  testWidgets('Voice screen mic button — idle state, ja / light (SC-4)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    // Pump VoiceInputScreen in idle state (NOT recording).
    // Use the same FakeStartSpeechRecognitionUseCase pattern from
    // voice_input_screen_test.dart lines 19-47.
    await tester.pumpWidget(_wrap(
      locale: const Locale('ja'),
      themeMode: ThemeMode.light,
      child: VoiceInputScreen(
        bookId: 'book-1',
        speechService: FakeStartSpeechRecognitionUseCase(),
      ),
    ));
    await tester.pumpAndSettle();

    // Find the mic button's AnimatedContainer (assign a stable ValueKey in
    // voice_input_screen.dart so the finder is unambiguous).
    final micButtonFinder = find.byKey(const ValueKey('voice-mic-button'));
    expect(micButtonFinder, findsOneWidget);

    await expectLater(
      micButtonFinder,
      matchesGoldenFile('goldens/voice_input_screen_mic_button_idle.png'),
    );
  });
}
```

**What's new vs analog:**
- 1×1 matrix instead of 3×2 (D-12 binding).
- Subject finder is the mic button subtree (via `ValueKey('voice-mic-button')` planner-assigned), not the whole screen — to keep the golden small and stable.
- NO recording-state golden — recording state is asserted via decoration introspection (`expect(decoration.borderRadius, ...)` in `voice_input_screen_test.dart`).

**Verify before commit:** `flutter test --update-goldens test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` to generate baseline, then commit `.png` alongside `.dart`.

---

### `voice_save_entry_source_test.dart` (integration test) — CREATE

**Analog:** `test/integration/features/accounting/manual_save_entry_source_test.dart` (verified lines 1-243).

#### Pattern: real DB + real CreateTransactionUseCase + mocked repos

```dart
// Source: test/integration/features/accounting/manual_save_entry_source_test.dart:74-138 (setUp shape)
void main() {
  late AppDatabase db;
  late TransactionDao transactionDao;
  late CreateTransactionUseCase useCase;
  late _MockCategoryRepository categoryRepository;
  // ... 4 more mocks ...

  setUpAll(() {
    registerFallbackValue(_FakeCreateTransactionParams());
  });

  setUp(() {
    db = AppDatabase.forTesting();
    transactionDao = TransactionDao(db);
    // ... assemble mocks ...
    final transactionRepository = TransactionRepositoryImpl(
      dao: transactionDao,
      encryptionService: encryptionService,
    );
    useCase = CreateTransactionUseCase(
      transactionRepository: transactionRepository,
      categoryRepository: categoryRepository,
      deviceIdentityRepository: deviceIdentityRepository,
      hashChainService: HashChainService(),
      classificationService: ClassificationService(ruleEngine: RuleEngine()),
    );
  });

  tearDown(() async => await db.close());
```

```dart
// Source: test/integration/features/accounting/manual_save_entry_source_test.dart:218-231 (SC-4 test shape)
testWidgets('SC-4: ManualOneStepScreen save stamps entry_source=manual in DB',
    (tester) async {
  await pumpAndSave(tester, entrySource: EntrySource.manual);

  // Query DB directly — bypass repo to confirm the schema CHECK constraint
  // actually accepted the literal 'manual'.
  final rows = await transactionDao.findByBookId('book-1');
  expect(rows.length, 1, reason: 'Exactly one transaction should be saved');
  expect(rows.first.entrySource, 'manual',
      reason: 'entry_source must equal the literal string "manual"');
  expect(rows.first.amount, 500);
});
```

#### Phase 22 variant — swap subject + interaction sequence

See RESEARCH.md §Code Examples §Example 4 (lines 879-928) for the full Phase 22 adaptation. Key swaps:

| Aspect | Manual analog | Phase 22 voice variant |
|--------|---------------|------------------------|
| Subject screen | `ManualOneStepScreen` | `VoiceInputScreen` |
| Interaction | `tester.tap` on SmartKeyboard digits 5, 0, 0 → tap "Record" key | `tester.startGesture` on mic → `speechService.emitFinal(...)` → hold 400ms → `gesture.up()` → tap save button |
| Pumped widget seeding | `initialCategory: _category, initialParentCategory: _parentCategory` (so `_canSave` is true immediately) | category resolved through `parseVoiceInputUseCaseProvider` mock returning a `VoiceParseResult` with `categoryMatch.categoryId` |
| Required overrides | `appDatabaseProvider`, `categoryRepositoryProvider`, `createTransactionUseCaseProvider`, `merchantCategoryLearningServiceProvider` | ADD: `parseVoiceInputUseCaseProvider`, `voiceLocaleIdProvider`, `appSpeechRecognitionServiceProvider` |
| Final assertion | `expect(rows.first.entrySource, 'manual')` | `expect(rows.first.entrySource, 'voice')` |

**Save button finder:** assign `ValueKey('voice-save-button')` to the Save button in `voice_input_screen.dart` (Excerpt H section above) so the integration test can find it unambiguously.

---

### `voice_to_manual_one_step_screen_test.dart` — DELETE

**Disposition:** DELETE. This Phase 19 D-16 regression test asserts the `voice → manual one-step` push flow, which Phase 22 D-02 removes. The coverage gap is FULLY subsumed by the new SC-2 integration test (`voice_save_entry_source_test.dart` above).

**Verify before delete:** grep for cross-file references → none expected (test files are leaf nodes).

```bash
grep -rn "voice_to_manual_one_step_screen_test" /Users/xinz/Development/home-pocket-app/ --include="*.dart" --include="*.yaml"
# Expected: no matches (test files are not imported elsewhere).
```

---

### `lib/generated/app_localizations*.dart` — AUTO-REGEN

Run `flutter gen-l10n` after ARB edits land. **Never hand-edit** per CLAUDE.md Pitfall #1. The generated `S` class drops `tapToRecord` getter and adds `holdToRecord` + `recording` getters automatically based on the updated ARB files.

---

## Shared Patterns

### Pattern: `GlobalKey<TransactionDetailsFormState>` + host CTA → `submit()`

**Source:** `lib/features/accounting/presentation/widgets/transaction_details_form.dart:44-52` (form widget public State surface) + `manual_one_step_screen.dart:69, 282` (host wiring).

**Applies to:** voice_input_screen.dart (Phase 22 NEW user of this pattern).

```dart
// Form widget exposes public State:
class TransactionDetailsForm extends ConsumerStatefulWidget {
  const TransactionDetailsForm({super.key, required this.config});
  final TransactionDetailsFormConfig config;
  @override
  ConsumerState<TransactionDetailsForm> createState() =>
      TransactionDetailsFormState();  // public — required for GlobalKey
}

// Host owns the key:
final _formKey = GlobalKey<TransactionDetailsFormState>();

// Host CTA calls submit() and consumes TransactionDetailsFormResult:
final result = await _formKey.currentState!.submit();
result.when(success: ..., validationError: ..., persistError: ...);
```

**Established by:** Phase 18 D-02 (form widget contract); Phase 19 D-14 (extends with public `updateAmount` mutator).
**Phase 22 extends:** adds 3 more public mutators (`updateCategory`, `updateMerchant`, `updateNote`).

### Pattern: `TransactionDetailsFormConfig.$new(entrySource: EntrySource.voice)` for entry-source stamping

**Source:** `manual_one_step_screen.dart:421` + `transaction_details_form.dart:289-332` (`.submit()`'s `.when($new: ...)` branch passes `entrySource:` into `CreateTransactionParams`).

**Applies to:** voice_input_screen.dart (Phase 22) — already wired by Phase 17 D-06 + Phase 18 D-08; Phase 22 just hardcodes `EntrySource.voice` in the config constructor.

### Pattern: per-FocusNode listener (NOT FocusScope walker)

**Source:** `manual_one_step_screen.dart:100-101, 171-179`.

**Applies to:** voice_input_screen.dart (D-09 auto-stop on TextField focus).

```dart
_merchantFocus = FocusNode()..addListener(_handleFocusChange);
_noteFocus = FocusNode()..addListener(_handleFocusChange);

void _handleFocusChange() {
  final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
  if (hasTextFocus == _isTextFieldFocused) return;  // equality guard
  setState(() { _isTextFieldFocused = hasTextFocus; /* ... */ });
}
```

**Rationale:** Codebase precedent — same feature, same screen family. Don't introduce a `Focus.of(context)` walker as a parallel cross-widget focus detection model (RESEARCH §Anti-Patterns).

### Pattern: `EntrySource.voice` stamp via config (NOT post-save injection)

**Source:** `transaction_details_form.dart:330` — `entrySource: entrySource` passed into `CreateTransactionParams` inside `submit()`.

**Applies to:** voice_input_screen.dart — pass `entrySource: EntrySource.voice` to `TransactionDetailsFormConfig.$new(...)` at form construction time. NO post-save mutation needed.

### Pattern: VoiceChunkMerger user-stop = immediate commit

**Source:** `lib/application/voice/voice_chunk_merger.dart:96-103` (`stop()` calls `_commitAndClear()` synchronously, bypassing the 2.5s window timer).

**Applies to:** voice_input_screen.dart `_stopRecordingAndCommit` — call `_amountMerger?.stop()` BEFORE `await _speechService.stop()` so the synchronous commit fires before the async recognizer drain (preserves existing order at `voice_input_screen.dart:217-218`).

**Critical contrast — misfire branch:** `_amountMerger?.dispose()` (NOT `.stop()` — discards buffer) + `_speechService.cancel()` (NOT `.stop()` — drops pending state). See RESEARCH.md §Pitfall 6.

---

## No Analog Found

| File / Pattern | Role / Data Flow | Reason — falls back to SDK |
|------|--------|--------|
| RawGestureDetector + `LongPressGestureRecognizer(duration: Duration.zero)` | gesture detection | First in-repo user. Use Flutter SDK docstring pattern from `widgets/gesture_detector.dart:1283-1338`. SDK source verified at `/Users/xinz/flutter/packages/flutter/lib/src/gestures/long_press.dart:281-290`. |
| `AnimatedSwitcher` with keyed Text child | cross-fade transition | Grep found 0 users in `lib/features/`. Use Flutter API doc pattern (api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html) — keyed child via `ValueKey(_isRecording)`. |

For both: RESEARCH.md §Pattern 1 and §Pattern 3 document the canonical SDK shape with file:line citations. Planner copies the SDK pattern verbatim — no risk of in-repo drift because there is no in-repo precedent to reconcile against.

---

## Metadata

**Analog search scope:**
- `lib/features/accounting/presentation/` (screens + widgets)
- `lib/application/voice/` (use cases + merger)
- `lib/core/theme/` (color constants)
- `lib/l10n/` (ARB files)
- `lib/generated/` (regen target — not searched, never hand-edit)
- `test/widget/features/accounting/presentation/` (widget tests + golden tests)
- `test/integration/features/accounting/` (integration tests)
- Flutter SDK 3.44.0 source on disk: `/Users/xinz/flutter/packages/flutter/lib/src/{gestures,widgets}/`

**Files scanned:** 14 source files (verified by Read or targeted Grep) + 6 SDK source citations from RESEARCH.md.

**Pattern extraction date:** 2026-05-25

**Wave-ordering implication (planner reference):**

| Wave | Files | Blocks |
|------|-------|--------|
| Wave 0 | ARB edits (× 3) → `flutter gen-l10n`; `transaction_details_form.dart` add 3 setters + tests; new golden harness scaffold; (optional) `app_colors.dart` constants | screen rewrite, integration test |
| Wave 1 | `voice_input_screen.dart` body rewrite (gesture + animation + form embed + delete `_navigateToConfirm` push + Save button + FocusNode listener) | widget tests, integration test, golden baseline |
| Wave 2 | `voice_input_screen_test.dart` major rewrite; `voice_save_entry_source_test.dart` create; `voice_to_manual_one_step_screen_test.dart` delete; golden baseline PNG generated via `--update-goldens` | verify-work + phase gate |
