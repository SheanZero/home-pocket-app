# Phase 19: Manual One-Step + Keypad Polish — Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 13 production/test files (new + modified + deleted)
**Analogs found:** 13 / 13

## File Classification

| New / Modified / Deleted File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------------------|------|-----------|----------------|---------------|
| `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` (**NEW**) | screen (ConsumerStatefulWidget) | request-response + event-driven | `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` (digit handlers, `_initializeDefaultCategory`, `_selectCategory`, `_onNext` validation) **PLUS** `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` (host-of-form pattern, `_save()` calling `formKey.currentState!.submit()`) | exact (composite of two analogs) |
| `lib/features/accounting/presentation/widgets/keyboard_toolbar.dart` (**NEW**) | widget (Stateless) | request-response (callbacks) | `lib/features/accounting/presentation/widgets/smart_keyboard.dart` `_GradientKey` (lines 295–344, coral gradient button) + `_DigitKey` (lines 178–212, Material+InkWell+Container pattern) | role-match (no existing Stack+Positioned overlay widget) |
| `lib/features/accounting/presentation/widgets/smart_keyboard.dart` (**MODIFIED**) | widget (Stateless) | request-response | self-as-baseline; refactor in place | exact |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (**REFACTORED**) | widget (ConsumerStatefulWidget) | CRUD (form state + submit) | self-as-baseline; remove `_editAmount` (lines 182–286) + DetailInfoRow at 633–640; add `updateAmount(int)` public method | exact |
| `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart` (**NEW**, optional per RESEARCH Pitfall §3) | widget (Stateless host of StatefulBuilder) | event-driven (modal) | `transaction_details_form.dart:182–286` `_editAmount()` — verbatim port into shared widget | exact |
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` (**MODIFIED line 352**) | screen | navigation | self-as-baseline; one-line `MaterialPageRoute` builder change | exact |
| `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (**MODIFIED**, D-14 spillover) | screen (host) | CRUD | `lib/features/accounting/presentation/screens/ocr_review_screen.dart` (parallel D-14 spillover host) + self-as-baseline | exact |
| `lib/features/accounting/presentation/screens/ocr_review_screen.dart` (**MODIFIED**, D-14 spillover) | screen (host) | CRUD | `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (parallel D-14 spillover host) + self-as-baseline | exact |
| `lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart` (**MODIFIED line 24**) | config (route table) | request-response | self-as-baseline; one-line builder change | exact |
| `lib/features/home/presentation/screens/main_shell_screen.dart` (**MODIFIED line 128**) | screen (shell) | navigation | self-as-baseline; one-line builder change | exact |
| `lib/l10n/app_{en,ja,zh}.arb` (**MODIFIED**) | i18n | n/a | existing ARB additions (e.g. `record` key at app_en.arb:905) | exact |
| **DELETIONS** | | | | |
| `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` (**DELETE**) | screen | n/a | n/a (delete) | n/a |
| `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` (**DELETE**) | screen | n/a | n/a (delete) | n/a |
| `test/widget/.../transaction_entry_screen_test.dart` (**DELETE**) | test | n/a | n/a (delete) | n/a |
| `test/widget/.../transaction_confirm_screen_merchant_learning_test.dart` (**RE-TARGET**) | test | n/a | self; swap host class only | exact |
| `test/unit/.../transaction_entry_screen_characterization_test.dart` (**DELETE**) | test | n/a | n/a (delete) | n/a |
| `test/unit/.../transaction_confirm_screen_characterization_test.dart` (**DELETE**) | test | n/a | n/a (delete) | n/a |
| **NEW TESTS** | | | | |
| `test/widget/.../screens/manual_one_step_screen_test.dart` (**NEW**) | widget test | CRUD | `test/widget/.../screens/transaction_entry_screen_test.dart` (FakeCategoryRepository + provider override + tester.view.physicalSize) + `test/widget/.../screens/transaction_confirm_screen_merchant_learning_test.dart` (MockCreateTransactionUseCase + form host pump) | exact (composite) |
| `test/widget/.../widgets/smart_keyboard_test.dart` (**EXTEND or NEW**) | widget test | n/a | `test/widget/.../widgets/transaction_details_form_smoke_test.dart` (`tester.view.physicalSize = Size(402, 874)` pattern, lines 273–276) | role-match |
| `test/widget/.../widgets/smart_keyboard_golden_test.dart` (**NEW**) | golden test | n/a | `test/golden/amount_display_golden_test.dart` (vanilla `matchesGoldenFile` + `_wrap` MaterialApp + delegates pattern) | exact |
| `test/widget/.../screens/voice_to_manual_one_step_screen_test.dart` (**NEW**) | widget test (regression) | event-driven | `test/widget/.../screens/voice_input_screen_test.dart` (FakeStartSpeechRecognitionUseCase + provider override) | exact |
| `test/integration/features/accounting/manual_save_entry_source_test.dart` (**NEW**) | integration test | CRUD | `test/integration/entry_path_stamping_test.dart` (in-memory `AppDatabase.forTesting()` + real `CreateTransactionUseCase` + mock repos + `expect(row.entrySource, 'manual')`) | exact |

---

## Pattern Assignments

### 1. `manual_one_step_screen.dart` (NEW — screen, request-response)

**Primary analog:** `lib/features/accounting/presentation/screens/transaction_entry_screen.dart`

**Imports pattern** (transaction_entry_screen.dart:1–20):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/category.dart';
import '../../domain/models/entry_source.dart';
import '../providers/repository_providers.dart';
import '../utils/category_display_utils.dart';
import '../widgets/amount_display.dart';
import '../widgets/detail_info_card.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';
import '../widgets/smart_keyboard.dart';
import '../widgets/soft_toast.dart';
import 'category_selection_screen.dart';
```
ManualOneStepScreen ADDS: `'dart:math' as math`, `'../widgets/keyboard_toolbar.dart'`, `'../widgets/transaction_details_form.dart'`, `'../../domain/models/transaction_details_form_config.dart'`. REMOVES: `'transaction_confirm_screen.dart'` (no longer navigated to).

**Class scaffold pattern** (transaction_entry_screen.dart:27–50):
```dart
class TransactionEntryScreen extends ConsumerStatefulWidget {
  const TransactionEntryScreen({super.key, required this.bookId});
  final String bookId;
  @override
  ConsumerState<TransactionEntryScreen> createState() =>
      _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends ConsumerState<TransactionEntryScreen> {
  String _amount = '';
  Category? _selectedCategory;
  Category? _selectedParentCategory;
  Map<String, Category> _categoryById = {};
  DateTime _selectedDate = DateTime.now();
  String? _toastMessage;

  @override
  void initState() {
    super.initState();
    _initializeDefaultCategory();
  }
```
ManualOneStepScreen extends the constructor with `initialAmount`, `initialCategory`, `initialParentCategory`, `initialDate`, `initialMerchant`, `initialSatisfaction`, `voiceKeyword`, `entrySource` (per CONTEXT D-16 voice push contract).

**`_initializeDefaultCategory()` — PORT VERBATIM** (transaction_entry_screen.dart:52–82, D-24 binding):
```dart
Future<void> _initializeDefaultCategory() async {
  final repo = ref.read(categoryRepositoryProvider);
  final allCategories = await repo.findActive();

  final categoryById = <String, Category>{
    for (final category in allCategories) category.id: category,
  };

  final l1Categories = allCategories.where((c) => c.level == 1).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final defaultL1 = l1Categories.isNotEmpty ? l1Categories.first : null;

  Category? defaultL2;
  if (defaultL1 != null) {
    final l2UnderSelectedL1 =
        allCategories
            .where((c) => c.level == 2 && c.parentId == defaultL1.id)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (l2UnderSelectedL1.isNotEmpty) {
      defaultL2 = l2UnderSelectedL1.first;
    }
  }

  if (!mounted) return;
  setState(() {
    _categoryById = categoryById;
    _selectedParentCategory = defaultL1;
    _selectedCategory = defaultL2;
  });
}
```

**Digit input handlers — PORT VERBATIM** (transaction_entry_screen.dart:84–129) — `_onDigit`, `_onDoubleZero`, `_onDot`, `_onDelete`, `_onClear`. After each handler runs `setState(() => _amount += ...)`, ALSO push to form per D-14:
```dart
void _onDigit(String digit) {
  _dismissToast();
  // ... existing leading-zero / decimal-place guards verbatim ...
  setState(() => _amount += digit);
  // D-14: keep form's internal _amount in sync
  final parsed = int.tryParse(_amount) ?? 0;
  _formKey.currentState?.updateAmount(parsed);
}
```

**`_selectCategory()` — PORT VERBATIM** (transaction_entry_screen.dart:154–178):
```dart
Future<void> _selectCategory() async {
  final result = await Navigator.of(context).push<Category>(
    MaterialPageRoute<Category>(
      builder: (_) =>
          CategorySelectionScreen(selectedCategoryId: _selectedCategory?.id),
    ),
  );
  if (result == null || !mounted) return;

  var parent = resolveParentCategory(result, _categoryById);
  if (parent == null && result.parentId != null) {
    final repo = ref.read(categoryRepositoryProvider);
    parent = await repo.findById(result.parentId!);
  }

  if (!mounted) return;
  setState(() {
    _categoryById[result.id] = result;
    if (parent != null) {
      _categoryById[parent.id] = parent;
    }
    _selectedCategory = result;
    _selectedParentCategory = parent;
  });
}
```

**Validation pattern** (transaction_entry_screen.dart:206–223) — PORT logic minus the `Navigator.push`:
```dart
void _onNext() {
  // Strip trailing dot (e.g. "320." → "320")
  final cleaned = _amount.endsWith('.')
      ? _amount.substring(0, _amount.length - 1)
      : _amount;
  final parsed = double.tryParse(cleaned);
  if (parsed == null || parsed <= 0) {
    _showToast(S.of(context).amountMustBeGreaterThanZero);
    return;
  }
  if (_selectedCategory == null) {
    _showToast(S.of(context).pleaseSelectCategory);
    return;
  }
  final amount = parsed.round();
  // OLD: Navigator.of(context).push(TransactionConfirmScreen(...))
  // NEW (Phase 19): instead of validation+push, call _save() which
  //                 delegates to formKey.currentState!.submit() — see analog 2.
}
```
In ManualOneStepScreen, this validation is partially delegated to `TransactionDetailsForm.submit()` (which already runs amount > 0 + category-present checks per Phase 18 D-02). The host's `_save()` simply calls submit() and renders the sealed-union result.

---

**Secondary analog (host-of-form pattern):** `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`

**GlobalKey + submit() pattern** (transaction_confirm_screen.dart:53–81):
```dart
class _TransactionConfirmScreenState
    extends ConsumerState<TransactionConfirmScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();
  bool _isSubmitting = false;

  Future<void> _save() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).transactionSaved)),
        );
        // Pop all the way back to main shell — D-04 preserved.
        Navigator.of(context).popUntil((route) => route.isFirst);
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
  }
```
ManualOneStepScreen `_save()` MUST follow this verbatim (same `result.when()` structure, same `popUntil((r) => r.isFirst)` after success per CONTEXT D-01 last bullet).

**Embedded form pattern** (transaction_confirm_screen.dart:169–186):
```dart
Expanded(
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: TransactionDetailsForm(
      key: _formKey,
      config: TransactionDetailsFormConfig.$new(
        bookId: widget.bookId,
        initialAmount: widget.amount,
        initialCategory: widget.category,
        initialParentCategory: widget.parentCategory,
        initialDate: widget.date,
        initialMerchant: widget.initialMerchant,
        initialSatisfaction: widget.initialSatisfaction,
        voiceKeyword: widget.voiceKeyword,
        entrySource: widget.entrySource,
      ),
    ),
  ),
),
```
ManualOneStepScreen MUST use this same `.$new` config wiring. The `SingleChildScrollView` `padding` is REPLACED with `EdgeInsets.fromLTRB(16, 16, 16, math.max(viewInsets.bottom, smartKeypadHeight))` per CONTEXT D-13.

**AppBar pattern** (transaction_entry_screen.dart:256–274) — title `addTransaction`, close-icon leading, centered title:
```dart
appBar: AppBar(
  backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
  elevation: 0,
  scrolledUnderElevation: 0,
  leading: IconButton(
    icon: Icon(
      Icons.close,
      color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
    ),
    onPressed: () => Navigator.pop(context),
  ),
  title: Text(
    l10n.addTransaction,
    style: AppTextStyles.headlineMedium.copyWith(
      color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
    ),
  ),
  centerTitle: true,
),
```

**FocusNode-per-TextField pattern** (RESEARCH §Pattern 3, no codebase analog — first FocusNode-listener consumer in the project — use RESEARCH §Example 1 lines 623–660 verbatim). Plumbing FocusNodes into form widget requires extending `TransactionDetailsFormConfig.$new` with optional `merchantFocusNode` / `noteFocusNode` params (RESEARCH §Pattern 3 Option 1, Open Question 2).

---

### 2. `keyboard_toolbar.dart` (NEW — widget, request-response)

**Closest analogs:**
- `smart_keyboard.dart` `_GradientKey` (lines 295–344) for the right "Record" coral-gradient button
- `transaction_confirm_screen.dart` `_buildSaveButton()` (lines 83–133) for full gradient + shadow + spinner-when-submitting pattern (compact version for toolbar)

**Gradient Save button pattern** (smart_keyboard.dart:295–344) — copy gradient + shadow + InkWell composition, downscale to toolbar height:
```dart
class _GradientKey extends StatelessWidget {
  const _GradientKey({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.actionGradientStart,
                AppColors.actionGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.actionShadow,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```
Adapt: 44dp container (toolbar height per UI-SPEC `keyboardToolbar.height`), border-radius 10 (smaller than 14 to feel compact), font size 14 (compact), spinner on `isSubmitting` (mirror confirm-screen's `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)` at lines 113–119).

**Submitting-state pattern** (transaction_confirm_screen.dart:108–129):
```dart
InkWell(
  onTap: _isSubmitting ? null : _save,
  borderRadius: BorderRadius.circular(14),
  child: Center(
    child: _isSubmitting
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(l10n.record, /* ... */),
  ),
),
```

**Layout pattern** — no exact analog in repo. Use RESEARCH §Example 3 (lines 759–857) verbatim: `Material(elevation: 8) → Container(height: 44, border-top) → Row(children: [Expanded(Done-text-button), Expanded(Record-gradient-button)])`. Both `Expanded` give each half ≥ 100dp × 44dp tap targets (UI-SPEC SC-2).

**Imports pattern** — same triad as smart_keyboard.dart (lines 1–4) + l10n delegate:
```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
```

---

### 3. `smart_keyboard.dart` (MODIFIED — widget refactor in place)

**Analog:** self (current file)

**LayoutBuilder + per-key height computation pattern** — no analog in repo (new pattern). Reference RESEARCH §Example 4 (lines 873–918) and CRITICAL §Pitfall 1 clamp:
```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return LayoutBuilder(
    builder: (context, constraints) {
      final mq = MediaQuery.of(context);
      final available = mq.size.height * 0.40 - mq.padding.bottom - (4 * 12.0);
      final rawKeyHeight = available / 5;
      final keyHeight = math.max(48.0, rawKeyHeight); // §Pitfall 1 NON-NEGOTIABLE
      // ... wrap existing _DigitRow/_ExtraRow/_ActionRow with `height: keyHeight`
    },
  );
}
```

**Lines to delete / change** (anchored verbatim in current smart_keyboard.dart):
- Line 22 `nextLabel = 'Next'` default → `actionLabel` required (or default `'Save'`) — per RESEARCH §Pitfall 6
- Lines 57, 59, 61, 63 `SizedBox(height: 8)` → `SizedBox(height: 12)` (D-07 row gap)
- Lines 78, 99, 109, 118, 139, 156, 168 `EdgeInsets.symmetric(horizontal: 4)` → `EdgeInsets.symmetric(horizontal: 6)` (D-07 col gap)
- Line 145 `_ActionKey(..., height: 50, ...)` → `height: keyHeight` (D-08)
- Line 198 `_DigitKey` `Container(height: 48, ...)` → `height: keyHeight`
- Line 260 `_CurrencyKey` `Container(..., height: 50, ...)` → `height: keyHeight`
- Line 329 `_GradientKey` `Container(height: 50, ...)` → `height: keyHeight`

**Preserve verbatim:** existing isDark + `AppColors.backgroundMuted` / `AppColorsDark.backgroundMuted` lookup (lines 143–144, 192, 263–264) — UI-SPEC SC-3 binding.

**Tabular figures for digit glyphs** (UI-SPEC Typography section, NEW requirement) — update `_DigitKey` (line 202) from:
```dart
style: AppTextStyles.amountLarge.copyWith(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
),
```
to use `AppTextStyles.labelMedium.copyWith(fontFeatures: const [FontFeature.tabularFigures()], ...)`. UI-SPEC permits planner to extract `digitLabel` constant in `app_text_styles.dart` — D-23 spillover.

---

### 4. `transaction_details_form.dart` (REFACTORED — externalize amount)

**Analog:** self (current file)

**Lines to DELETE:**
- Lines 182–286: entire `_editAmount()` method (StatefulBuilder + AmountDisplay + SmartKeyboard sheet body). Move this body into a new `AmountEditBottomSheet` widget per RESEARCH §Pitfall 3 (see analog 5 below).
- Lines 633–640: the `DetailInfoRow(icon: Icons.payments_outlined, label: l10n.amount, value: ..., onTap: _editAmount)` row. The DetailInfoCard now starts with the category row (currently line 641).
- Import `'../widgets/amount_display.dart'` at line 34 (no longer referenced inside the form).
- Import `'../widgets/smart_keyboard.dart'` at line 38 (no longer referenced inside the form — only AmountEditBottomSheet references it).

**Lines to ADD** — public `updateAmount(int)` method, anchored near `_resolveLedgerType` (around line 172, before `// ── Field edit affordances ──`):
```dart
/// Host-pushed amount update — Phase 19 D-14.
///
/// Hosts that own the amount-editing UX (ManualOneStepScreen's persistent
/// SmartKeyboard, TransactionEditScreen / OcrReviewScreen's modal bottom
/// sheet) call this whenever the user mutates the amount. The form widget
/// keeps the value internally for save-time validation in [submit].
void updateAmount(int amount) {
  if (!mounted) return;
  if (amount == _amount) return; // skip redundant setState
  setState(() => _amount = amount);
}
```

**Lines to PRESERVE verbatim** — `submit()` validation logic at line 369+ (amount > 0 check + category-present check); `_editCategory()` voice-correction branch (lines 288–345, Phase 18 D-09); `_resolveLedgerType()` (lines 172–178).

**Optional FocusNode extension** (per RESEARCH §Pattern 3 Option 1):
- Add `merchantFocusNode` / `noteFocusNode` optional params to `TransactionDetailsFormConfig.$new` Freezed variant (file: `lib/features/accounting/domain/models/transaction_details_form_config.dart`). Phase 18 hosts pass `null`; ManualOneStepScreen passes its FocusNodes.
- Thread them into existing `_storeController` / `_memoController` TextFields inside `_buildStoreAndMemoSection` (referenced at line 658 — the helper itself lives elsewhere; locate via grep before edit).
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after Freezed change.

---

### 5. `amount_edit_bottom_sheet.dart` (NEW — widget, modal)

**Analog:** `transaction_details_form.dart:182–286` `_editAmount()` (VERBATIM extraction)

**Source body to extract** — entire `showModalBottomSheet` body lines 184–284. Refactor into stateless widget exposing:
```dart
class AmountEditBottomSheet extends StatelessWidget {
  const AmountEditBottomSheet({
    super.key,
    required this.initialAmount,
    required this.onConfirm,
  });

  final int initialAmount;
  final ValueChanged<int> onConfirm;

  static Future<void> show(BuildContext context, {
    required int initialAmount,
    required ValueChanged<int> onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmountEditBottomSheet(
        initialAmount: initialAmount,
        onConfirm: onConfirm,
      ),
    );
  }
  // build() body = lines 188–283 of transaction_details_form.dart verbatim,
  // with `setState(() => _amount = parsed.round())` at line 246 REPLACED with
  // `onConfirm(parsed.round())` (host wires this to formKey.currentState!.updateAmount).
}
```

**Host wiring** — both `transaction_edit_screen.dart` and `ocr_review_screen.dart` render `AmountDisplay(amount: _displayAmount, onClear: ...)` above the form's `SingleChildScrollView`, and on AmountDisplay tap call `AmountEditBottomSheet.show(context, initialAmount: _formKey.currentState!._amount, onConfirm: (v) => _formKey.currentState!.updateAmount(v));`.

---

### 6. `voice_input_screen.dart` (MODIFIED line 352)

**Analog:** self

**Current code** (voice_input_screen.dart:351–367):
```dart
await Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => TransactionConfirmScreen(
      bookId: widget.bookId,
      amount: result.amount ?? 0,
      category: category,
      parentCategory: parentCategory,
      date: result.parsedDate ?? DateTime.now(),
      initialMerchant: result.merchantName,
      initialSatisfaction: result.ledgerType == LedgerType.soul
          ? result.estimatedSatisfaction
          : null,
      voiceKeyword: keyword,
      entrySource: EntrySource.voice,
    ),
  ),
);
```

**Phase 19 change** — swap builder target + rename `amount` → `initialAmount` + `date` → `initialDate` (ManualOneStepScreen uses `initial` prefix per CONTEXT D-16 / RESEARCH §Example 5):
```dart
await Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ManualOneStepScreen(
      bookId: widget.bookId,
      initialAmount: result.amount ?? 0,
      initialCategory: category,
      initialParentCategory: parentCategory,
      initialDate: result.parsedDate ?? DateTime.now(),
      initialMerchant: result.merchantName,
      initialSatisfaction: result.ledgerType == LedgerType.soul
          ? result.estimatedSatisfaction
          : null,
      voiceKeyword: keyword,
      entrySource: EntrySource.voice,
    ),
  ),
);
```
Also update import at file top: `import 'transaction_confirm_screen.dart';` → `import 'manual_one_step_screen.dart';`.

---

### 7. `transaction_edit_screen.dart` (MODIFIED — D-14 spillover)

**Analog:** self + `ocr_review_screen.dart` (parallel host)

**Current structure** (transaction_edit_screen.dart:55–98) — `Scaffold → AppBar → Column[Expanded(SingleChildScrollView(TransactionDetailsForm)), SafeArea(_buildSaveButton)]`.

**Phase 19 change:** insert host-owned `AmountDisplay` ABOVE the form, plumb tap handler. Pattern:
```dart
body: Column(children: [
  AmountDisplay(
    amount: _displayAmountString,   // derived from form's current _amount via formKey
    onClear: () => _formKey.currentState?.updateAmount(0),
  ),
  // Tap on AmountDisplay opens AmountEditBottomSheet
  // (wrap AmountDisplay in GestureDetector or InkWell)
  Expanded(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TransactionDetailsForm(
        key: _formKey,
        config: TransactionDetailsFormConfig.edit(seed: widget.transaction),
      ),
    ),
  ),
  SafeArea(child: /* unchanged save button */),
]),
```

**Display-amount-string sync** — host must reflect `_formKey.currentState?._amount` (cached on form `updateAmount` callback) into a local `_displayAmount`. Easiest: maintain a local `int _displayAmount` initialized to `widget.transaction.amount`, update in `AmountEditBottomSheet.onConfirm` BEFORE calling `formKey.currentState!.updateAmount(v)`.

**Preserve verbatim:** `_save()` logic (lines 34–52) — pop-with-result `Navigator.of(context).pop(true)` (D-18 from Phase 18, not Phase 19's popUntil).

---

### 8. `ocr_review_screen.dart` (MODIFIED — D-14 spillover, parallel to transaction_edit_screen)

**Analog:** `transaction_edit_screen.dart` (sibling D-14 spillover host)

Apply the same shape of change: insert `AmountDisplay` before the form's `SingleChildScrollView` (currently at ocr_review_screen.dart:98–103), wire tap to `AmountEditBottomSheet.show`, sync via `formKey.currentState!.updateAmount`. **Preserve:** the `MaterialBanner` empty-draft banner at lines 93–97, the popUntil first-route post-save (line 60).

---

### 9. `entry_mode_navigation_config.dart` (MODIFIED line 24)

**Analog:** self (single-line builder change)

**Current code** (entry_mode_navigation_config.dart:21–25):
```dart
final _entryModeRouteConfigs = <InputMode, EntryModeRouteConfig>{
  InputMode.manual: EntryModeRouteConfig(
    mode: InputMode.manual,
    builder: (bookId) => TransactionEntryScreen(bookId: bookId),
  ),
```

**Phase 19 change:** `TransactionEntryScreen` → `ManualOneStepScreen`; swap import at line 4 from `'../screens/transaction_entry_screen.dart'` → `'../screens/manual_one_step_screen.dart'`.

---

### 10. `main_shell_screen.dart` (MODIFIED line 128)

**Analog:** self

**Current code** (main_shell_screen.dart:125–131):
```dart
onFabTap: () async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => TransactionEntryScreen(bookId: bookId),
    ),
  );
```

**Phase 19 change:** swap builder target to `ManualOneStepScreen(bookId: bookId)`; update import (locate via `grep -n "transaction_entry_screen" lib/features/home/presentation/screens/main_shell_screen.dart`).

---

### 11. ARB additions — `app_{en,ja,zh}.arb` (MODIFIED — add `keyboardToolbarDone`)

**Analog:** existing `record` key addition pattern (app_en.arb:905–908):
```json
  "record": "Record",
  "@record": {
    "description": "Save/record transaction button"
  },
```

**Phase 19 addition** — append before `"@@locale": "..."` closing block in each file:
- `app_en.arb`: `"keyboardToolbarDone": "Done", "@keyboardToolbarDone": {"description": "Soft-keyboard accessory toolbar dismiss button"}`
- `app_ja.arb`: `"keyboardToolbarDone": "完了"` + same metadata
- `app_zh.arb`: `"keyboardToolbarDone": "完成"` + same metadata

**Post-edit step (MANDATORY):** run `flutter gen-l10n` to regenerate `lib/generated/app_localizations*.dart`. Verify atomic 3-locale parity (a `keyboardToolbarDone` missing from any one locale breaks codegen).

**Verification:** `grep -n '"done"' lib/l10n/app_en.arb` confirms `done` does NOT exist (only `deleteAllDataDescription` at line 440 contains the substring) — RESEARCH §Finding 2 verified.

---

### 12. `manual_one_step_screen_test.dart` (NEW)

**Primary analog:** `test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart`

**FakeCategoryRepository pattern** (transaction_entry_screen_test.dart:12–61) — port verbatim; this fake satisfies `_initializeDefaultCategory` for ManualOneStepScreen the same way.

**Test surface sizing pattern** (transaction_entry_screen_test.dart:87–91):
```dart
testWidgets('renders detail card and warm background', (tester) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
```
ADD per RESEARCH §Pitfall 1 — also assert against iPhone SE: `Size(375, 667)` and Pro Max `Size(428, 926)` for SC-2 (key height ≥ 48dp). Use `tester.binding.setSurfaceSize(...)` for runtime surface change between asserts within one test.

**Provider override pattern** (transaction_entry_screen_test.dart:93–101):
```dart
await tester.pumpWidget(
  createLocalizedWidget(
    const TransactionEntryScreen(bookId: 'book-1'),
    locale: const Locale('ja'),
    overrides: [
      categoryRepositoryProvider.overrideWithValue(
        FakeCategoryRepository(categories),
      ),
```

**Secondary analog:** `test/widget/features/accounting/presentation/screens/transaction_confirm_screen_merchant_learning_test.dart`

**MockCreateTransactionUseCase pattern** (lines 22–82) — port verbatim for SC-4 (`expect transactionRepository.create invoked with entrySource == EntrySource.manual`). Use `registerFallbackValue(FakeCreateTransactionParams())` and `when(() => mockCreateUseCase.execute(any())).thenAnswer(...)` to assert against captured params.

**ProviderScope wrapping** (transaction_confirm_screen_merchant_learning_test.dart:86–113):
```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
      categoryServiceProvider.overrideWithValue(mockCategoryService),
      merchantCategoryLearningServiceProvider.overrideWithValue(mockLearningService),
    ],
    child: testLocalizedApp(
      locale: const Locale('en'),
      child: Theme(
        data: ThemeData(splashFactory: NoSplash.splashFactory),
        child: Scaffold(
          body: TransactionConfirmScreen(
            bookId: 'book_001',
            amount: 1200,
            category: category,
            parentCategory: null,
            date: DateTime(2026, 2, 22),
            entrySource: EntrySource.manual,
          ),
        ),
      ),
    ),
  ),
);
```

**Phase 19 SC-1 assertion** (RESEARCH §Pitfall 6):
```dart
final l10n = await S.delegate.load(const Locale('en'));
expect(find.text(l10n.next), findsNothing);
// And per UI-SPEC: assert all 6 surfaces visible
expect(find.byType(AmountDisplay), findsOneWidget);
expect(find.byType(LedgerTypeSelector), findsOneWidget);
expect(find.byType(DetailInfoCard), findsOneWidget);
expect(find.byType(TextField), findsAtLeastNWidgets(2));   // merchant + note
```

**AnimatedSlide offset assertion pattern** (no codebase analog — new pattern):
```dart
final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
expect(slide.offset, const Offset(0, 0));   // initial: visible
// tap merchant TextField, pump animation
expect(slide.offset, const Offset(0, 1));   // off-screen
```

---

### 13. `smart_keyboard_test.dart` (EXTEND or NEW)

**Analog:** `test/widget/features/accounting/presentation/widgets/transaction_details_form_smoke_test.dart` (lines 273–276, surface-size pattern)

**Height computation test pattern** (NEW — no analog):
```dart
testWidgets('per-key height satisfies 48dp floor on iPhone SE', (tester) async {
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(createLocalizedWidget(
    Scaffold(body: SmartKeyboard(
      onDigit: (_) {}, onDelete: () {}, onNext: () {},
      actionLabel: 'Record',
    )),
  ));
  await tester.pumpAndSettle();

  // SC-2 assertion: every digit key ≥ 48dp tall
  final digitKeys = find.byType(InkWell); // narrow via ancestor or key
  for (final element in digitKeys.evaluate()) {
    final box = element.renderObject as RenderBox;
    expect(box.size.height, greaterThanOrEqualTo(48.0));
  }
});
```

Re-run the same test on `Size(390, 844)` and `Size(428, 926)` per RESEARCH §Pitfall 1 "recommended widget-test surfaces."

---

### 14. `smart_keyboard_golden_test.dart` (NEW)

**Primary analog:** `test/golden/amount_display_golden_test.dart` (lines 9–24, `_wrap` MaterialApp + delegates)

**Wrapper pattern** — port verbatim, extend with `ThemeData.dark()` + `themeMode` param for light/dark coverage:
```dart
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
```

**Test body pattern** (amount_display_golden_test.dart:28–43):
```dart
testWidgets('JPY ¥1,235 — locale ja', (tester) async {
  await tester.pumpWidget(_wrap(
    locale: const Locale('ja'),
    child: const AmountDisplay(/* ... */),
  ));
  await expectLater(
    find.byType(AmountDisplay),
    matchesGoldenFile('goldens/amount_display_jpy.png'),
  );
});
```

**6-image matrix loop** (RESEARCH §Example 6, lines 990–1020):
```dart
for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
  for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('SmartKeyboard — ${locale.languageCode} / ${mode.name}', (tester) async {
      tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(_wrap(
        locale: locale, themeMode: mode,
        child: SmartKeyboard(
          onDigit: (_) {}, onDelete: () {}, onNext: () {},
          onDoubleZero: () {}, onDot: () {},
          actionLabel: 'Record',
        ),
      ));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SmartKeyboard),
        matchesGoldenFile(
          'goldens/smart_keyboard_${locale.languageCode}_${mode.name}.png',
        ),
      );
    });
  }
}
```

**Note (Open Question 5):** D-09 locks file path to `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart`. Existing convention is `test/golden/...` flat — honor the locked D-09 path; goldens land at `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_{locale}_{mode}.png`.

---

### 15. `voice_to_manual_one_step_screen_test.dart` (NEW)

**Analog:** `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (lines 1–120 — `FakeStartSpeechRecognitionUseCase` / `CapturingStartSpeechRecognitionUseCase` patterns)

**Speech-recognition fake pattern** (voice_input_screen_test.dart:19–47):
```dart
class FakeStartSpeechRecognitionUseCase
    implements StartSpeechRecognitionUseCase {
  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async => true;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => false;

  @override
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}
```
Use `CapturingStartSpeechRecognitionUseCase` (lines 79–117) when the test needs to inject a parsed result and assert the downstream push.

**Phase 19 assertion** — verify `entrySource == EntrySource.voice` is preserved through the new push target (`ManualOneStepScreen`):
1. Mount VoiceInputScreen with capturing fake.
2. Trigger `onResult` callback with synthetic parsed result.
3. Pump.
4. Assert `Navigator.push` landed on a `ManualOneStepScreen` widget (`find.byType(ManualOneStepScreen)`) and that its `entrySource` prop equals `EntrySource.voice`.
5. Tap save (via formKey or via the keyboard's Save key) and assert `mockCreateUseCase.execute` was called with `entrySource: EntrySource.voice`.

---

### 16. `manual_save_entry_source_test.dart` (NEW — integration)

**Analog:** `test/integration/entry_path_stamping_test.dart` (lines 1–100 — in-memory `AppDatabase.forTesting()` + real `CreateTransactionUseCase` + mock side-deps)

**In-memory DB + use case wiring** (entry_path_stamping_test.dart:25–64):
```dart
late AppDatabase db;
late TransactionDao transactionDao;
late CreateTransactionUseCase useCase;
// ...

setUp(() {
  db = AppDatabase.forTesting();
  transactionDao = TransactionDao(db);
  categoryRepository = _MockCategoryRepository();
  deviceIdentityRepository = _MockDeviceIdentityRepository();
  encryptionService = _MockFieldEncryptionService();

  when(() => categoryRepository.findById(any()))
      .thenAnswer((_) async => _category);
  when(() => deviceIdentityRepository.getDeviceId())
      .thenAnswer((_) async => 'device-local');
  when(() => encryptionService.encryptField(any())).thenAnswer(
    (invocation) async => invocation.positionalArguments.first as String,
  );
  // ...

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

tearDown(() async {
  await db.close();
});
```

**Phase 19 assertion** (mirror entry_path_stamping_test.dart:80–88 for manual):
```dart
test('manual entry path stamps entry_source = manual (Phase 19 SC-4)', () async {
  final row = await _createAndFind(
    useCase,
    transactionDao,
    entrySource: EntrySource.manual,
  );
  expect(row.entrySource, 'manual');
});
```
Note: the existing `entry_path_stamping_test.dart` already asserts manual entry_source — Phase 19's new test is a regression guard specifically tied to the ManualOneStepScreen save path (not the use case directly). Wire the new test by pumping ManualOneStepScreen with provider overrides routed at the real DB-backed `CreateTransactionUseCase`, then inspect the row inserted via DAO.

---

## Shared Patterns

### Pattern S-1: Host-of-form (Scaffold + AppBar + form + bottom CTA)

**Source:** `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` (entire file is the canonical analog — also present in `ocr_review_screen.dart` and `transaction_edit_screen.dart` with minor variations)

**Apply to:** `manual_one_step_screen.dart`

Pattern signature: `Scaffold → Column[Expanded(SingleChildScrollView(TransactionDetailsForm(key: _formKey, config: ...))), SafeArea(bottom-CTA)]`. ManualOneStepScreen differs in that the bottom CTA is replaced by `AnimatedSlide(SmartKeyboard)` and the Scaffold has `resizeToAvoidBottomInset: false` (D-13).

### Pattern S-2: isDark dark-mode lookup ternary

**Source:** every screen file (e.g. transaction_entry_screen.dart:250, transaction_confirm_screen.dart:138, smart_keyboard.dart:38):
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
// then:
color: isDark ? AppColorsDark.background : AppColors.backgroundWarm,
color: isDark ? AppColorsDark.card : AppColors.card,
color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
color: isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted,
color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault,
```

**Apply to:** `manual_one_step_screen.dart`, `keyboard_toolbar.dart`, refactored `smart_keyboard.dart` (preserve existing).

### Pattern S-3: GlobalKey + submit() + sealed-result.when() pattern

**Source:** `transaction_confirm_screen.dart:53–81` (verbatim above). Also at `transaction_edit_screen.dart:30–52` and `ocr_review_screen.dart:30–67`.

**Apply to:** `manual_one_step_screen.dart` `_save()` method — both invocations (from SmartKeyboard Save AND KeyboardToolbar Save call the SAME `_save()` per CONTEXT D-11 + D-21).

### Pattern S-4: Validation toast via SoftToast

**Source:** `transaction_entry_screen.dart:196–204, 319–327`:
```dart
void _showToast(String message) {
  setState(() => _toastMessage = message);
}

void _dismissToast() {
  if (mounted) {
    setState(() => _toastMessage = null);
  }
}

// in build:
if (_toastMessage != null)
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SoftToast(
      key: ValueKey(_toastMessage),
      message: _toastMessage!,
      onDismissed: _dismissToast,
    ),
  ),
```
**Apply to:** `manual_one_step_screen.dart` (preserve toast affordance for cases where the form's `submit()` returns `validationError` — show via SoftToast OR via the existing SnackBar pattern from `transaction_confirm_screen.dart:72–75`. CONTEXT does not lock which; planner discretion.)

### Pattern S-5: Categorical display utilities

**Source:** `transaction_entry_screen.dart:180–194` — `_categoryChipIcon()` / `_categoryChipLabel()` using `resolveCategoryIcon` / `formatCategoryPath` helpers from `../utils/category_display_utils.dart`.

**Apply to:** ManualOneStepScreen if rendering category chip outside the form (form already renders it per `transaction_details_form.dart:641–649`). Skip duplication — form widget handles it.

### Pattern S-6: Localization wrapper in tests

**Source:** `test/helpers/test_localizations.dart` (entire file, 35 lines) — `createLocalizedWidget(Widget child, {locale, overrides})` helper. Used by every analog test (transaction_entry_screen_test.dart:10, transaction_confirm_screen_merchant_learning_test.dart:19 via `testLocalizedApp`).

**Apply to:** all 4 new test files.

---

## No Analog Found

All Phase 19 files have at least one role-matched analog in the existing codebase. Three near-misses noted:

| File | Role | Data Flow | Reason / Mitigation |
|------|------|-----------|---------------------|
| `keyboard_toolbar.dart` | widget overlay | request-response | No existing `Stack + Positioned + MediaQuery.viewInsets` overlay widget in repo. Closest is `smart_keyboard.dart`'s gradient/InkWell composition (analog 2 above). RESEARCH §Example 3 (verbatim) is the de-facto pattern — use it as authoritative reference for the missing pieces. |
| `_ManualOneStepScreenState` FocusNode-listener block | screen-local focus driver | event-driven | First per-FocusNode listener pattern in the project. Use RESEARCH §Pattern 3 + §Example 1 (verbatim). |
| LayoutBuilder + `math.max(48.0, perKey)` clamp in `smart_keyboard.dart` | responsive sizing primitive | n/a | First LayoutBuilder-based responsive primitive in this widget tree. Use RESEARCH §Example 4 + Pitfall §1 math. |

For the three above, planner should treat the RESEARCH-provided code excerpts as the analog (they are pre-verified by the researcher).

---

## Metadata

**Analog search scope:**
- `lib/features/accounting/presentation/screens/` (8 files)
- `lib/features/accounting/presentation/widgets/` (11 files)
- `lib/features/accounting/presentation/navigation/` (1 file)
- `lib/features/home/presentation/screens/` (main_shell_screen.dart only)
- `lib/l10n/` (3 ARB files)
- `test/widget/features/accounting/presentation/screens/` + `widgets/`
- `test/integration/` (entry_path_stamping_test.dart, transaction_dao_entry_source_preservation_test.dart)
- `test/golden/` (4 existing golden files)
- `test/helpers/test_localizations.dart`

**Files scanned:** ~30 source/test files

**Pattern extraction date:** 2026-05-23
