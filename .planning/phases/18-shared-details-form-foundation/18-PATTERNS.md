# Phase 18: Shared Details Form Foundation - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 13 (7 new + 6 modified)
**Analogs found:** 13 / 13

## File Classification

| File | New/Modified | Role | Data Flow | Closest Analog | Match Quality |
|------|--------------|------|-----------|----------------|---------------|
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | NEW | widget (embeddable) | request-response (form submit) | `transaction_confirm_screen.dart` body (lines 66–743) | role-match (extracted from analog) |
| `lib/features/accounting/domain/models/transaction_details_form_config.dart` | NEW | domain model (Freezed sealed union) | n/a (data carrier) | `lib/features/analytics/domain/models/time_window.dart` | exact |
| `lib/features/accounting/domain/models/ocr_parse_draft.dart` | NEW | domain model (Freezed) | n/a (data carrier) | `lib/features/accounting/domain/models/voice_parse_result.dart` | exact |
| `lib/application/accounting/update_transaction_use_case.dart` | NEW | use case (application) | CRUD (update) | `lib/application/accounting/create_transaction_use_case.dart` | exact |
| `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` | NEW | screen (thin wrapper) | request-response | `transaction_confirm_screen.dart` Scaffold/AppBar/CTA only | role-match |
| `lib/features/accounting/presentation/screens/ocr_review_screen.dart` | NEW | screen (thin wrapper) | request-response | `transaction_edit_screen.dart` (sibling new) + `transaction_confirm_screen.dart` shape | role-match |
| `test/widget/features/accounting/presentation/screens/ocr_two_step_seam_test.dart` | NEW | widget test | n/a | `test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart` | role-match |
| `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` | MODIFIED | screen (refactor to wrapper) | request-response | self (slim down) | n/a |
| `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` | MODIFIED | screen (onTap target swap) | event-driven | self (single line change) | n/a |
| `lib/features/home/presentation/screens/home_screen.dart` | MODIFIED | screen (wire HomeTransactionTile.onTap) | request-response | self (existing tile map block, lines 290–329) | n/a |
| `lib/application/family_sync/transaction_change_tracker.dart` | MODIFIED | application service (add trackUpdate) | event-driven (pub-sub buffer) | `trackCreate` in same file (line 16–18) | exact (self-template) |
| `lib/features/accounting/presentation/providers/repository_providers.dart` | MODIFIED | wiring (Riverpod provider) | n/a | `createTransactionUseCaseProvider` in same file (lines 128–139) | exact (self-template) |
| `lib/l10n/app_ja.arb` + `app_zh.arb` + `app_en.arb` | MODIFIED | i18n ARB | n/a | existing entries `transactionSaved` / `failedToSave` / `ocrScanTitle` | exact |

---

## Pattern Assignments

### 1. `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (NEW — widget, embeddable form)

**Analog:** `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` (the entire stateful body — lines 66–743 — migrates into this widget; only Scaffold/AppBar/CTA stay in host screens).

**Imports pattern** (analog lines 1–23 — port verbatim, drop the `category_selection_screen.dart` import only if you re-route the category nav through a callback; keep all field widgets):
```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../application/accounting/update_transaction_use_case.dart'; // NEW
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/category.dart';
import '../../domain/models/entry_source.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_details_form_config.dart'; // NEW sealed union
import '../providers/repository_providers.dart';
import '../utils/category_display_utils.dart';
import '../widgets/amount_display.dart';
import '../widgets/detail_info_card.dart';
import '../widgets/ledger_type_selector.dart';
import '../widgets/satisfaction_emoji_picker.dart';
import '../widgets/smart_keyboard.dart';
import '../screens/category_selection_screen.dart';
```

**State/init pattern** (analog lines 66–101 — switch the seed branch on `config.when(...)`):
```dart
class _TransactionDetailsFormState extends ConsumerState<TransactionDetailsForm> {
  final _storeController = TextEditingController();
  final _memoController  = TextEditingController();

  late int _amount;
  Category? _category;
  Category? _parentCategory;
  late DateTime _date;
  String? _initialCategoryId;
  LedgerType _ledgerType = LedgerType.survival;
  int _soulSatisfaction = 2;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    widget.config.when(
      $new: (bookId, initialAmount, initialCategory, initialParentCategory,
              initialMerchant, initialSatisfaction, initialDate,
              entrySource, voiceKeyword) {
        _amount         = initialAmount ?? 0;
        _category       = initialCategory;
        _parentCategory = initialParentCategory;
        _date           = initialDate ?? DateTime.now();
        _initialCategoryId = initialCategory?.id;
        if (initialMerchant != null) _storeController.text = initialMerchant;
        if (initialSatisfaction != null) {
          _soulSatisfaction = initialSatisfaction.clamp(1, 10);
        }
      },
      edit: (seed) {
        _amount            = seed.amount;
        // _category resolved async via categoryRepository.findById(seed.categoryId)
        _date              = seed.timestamp;
        _ledgerType        = seed.ledgerType;
        _soulSatisfaction  = seed.soulSatisfaction;
        _storeController.text = seed.merchant ?? '';
        _memoController.text  = seed.note ?? '';
      },
    );
  }
```

**`submit()` public method pattern** (NEW — invoked by host CTA via `GlobalKey<TransactionDetailsFormState>().currentState!.submit()`, returns `Future<TransactionDetailsFormResult>` per D-02). Adapted from analog `_save()` lines 294–354 (replace `popUntil` with returning a result):
```dart
Future<TransactionDetailsFormResult> submit() async {
  if (_category == null) return TransactionDetailsFormResult.validationError(
    S.of(context).pleaseSelectCategory);
  setState(() => _isSubmitting = true);
  try {
    return await widget.config.when(
      $new: (bookId, _, __, ___, ____, _____, ______, entrySource, voiceKeyword) async {
        final result = await ref.read(createTransactionUseCaseProvider).execute(
          CreateTransactionParams(
            bookId: bookId, amount: _amount, type: TransactionType.expense,
            categoryId: _category!.id, timestamp: _date,
            note: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
            merchant: _storeController.text.trim().isEmpty ? null : _storeController.text.trim(),
            soulSatisfaction: _ledgerType == LedgerType.soul ? _soulSatisfaction : null,
            ledgerType: _ledgerType, entrySource: entrySource,
          ),
        );
        return result.isSuccess
          ? TransactionDetailsFormResult.success(result.data!)
          : TransactionDetailsFormResult.persistError(result.error ?? S.of(context).failedToSave);
      },
      edit: (seed) async {
        final result = await ref.read(updateTransactionUseCaseProvider).execute(
          UpdateTransactionParams(seed: seed, /* mutable overrides */),
        );
        return result.isSuccess
          ? TransactionDetailsFormResult.success(result.data!)
          : TransactionDetailsFormResult.persistError(result.error ?? S.of(context).failedToUpdate);
      },
    );
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
```

**Voice-correction branch** (analog lines 256–267 — gate by `.new` mode only per D-09):
```dart
// .edit mode: branch unreachable. .new mode: keep existing behavior.
widget.config.maybeWhen(
  $new: (_, __, ___, ____, _____, ______, _______, ________, voiceKeyword) async {
    if (voiceKeyword != null && voiceKeyword.isNotEmpty && result.id != _initialCategoryId) {
      final correctionUseCase = ref.read(recordCategoryCorrectionUseCaseProvider);
      await correctionUseCase.execute(keyword: voiceKeyword, correctedCategoryId: result.id);
    }
  },
  orElse: () {},
);
```

**Key patterns to replicate:**
- `ConsumerStatefulWidget` + `ConsumerState` (not `Notifier` — local form state stays in the widget per `<specifics>`).
- Import `flutter_riverpod/flutter_riverpod.dart` only (NOT `legacy.dart` — no `StateNotifier` here).
- `setState` is allowed (per CLAUDE.md, this is the standard Flutter pattern); side effects (snackbar / navigation) belong in the host CTA, NOT in the form.
- Soul celebration overlay (analog lines 356–370) stays in the form for `.new` mode only — per D-15, edit mode never plays it.
- All UI text via `S.of(context).key` (CLAUDE.md i18n rule).
- Amounts via `AppTextStyles.amountMedium` (already done at analog line 603).

**Anti-patterns to avoid (CLAUDE.md):**
- Pitfall #4: never mutate `seed` — build a new `Transaction` via `seed.copyWith(...)` in `UpdateTransactionParams`.
- Pitfall #9: do NOT hardcode `bookId` defaults inside the widget — the config carries it.
- Pitfall #12: the form must NOT call `AppInitializer.initialize()` or touch infra services directly — go through providers only.
- Coding-style.md: keep file under 800 lines; the analog is 743 — extract the amount bottom-sheet body (analog lines 119–226) into a private helper file if you risk overrun.

---

### 2. `lib/features/accounting/domain/models/transaction_details_form_config.dart` (NEW — Freezed sealed union)

**Analog:** `lib/features/analytics/domain/models/time_window.dart` (5-variant sealed union — same shape, drop `@Assert`).

**Full template** (analog lines 1–42 — adapt variants):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';
import 'entry_source.dart';
import 'transaction.dart';

part 'transaction_details_form_config.freezed.dart';

/// Configures [TransactionDetailsForm] for either a new-entry or edit-existing flow.
///
/// Pattern-match via `config.when(...)` / `config.maybeWhen(...)` inside the form.
/// `.new` carries optional initial values supplied by upstream entry screens;
/// `.edit` carries a fully-loaded [Transaction] seed whose immutable fields
/// (id, bookId, deviceId, prevHash, currentHash, createdAt, entrySource) are
/// preserved verbatim through the save.
@freezed
sealed class TransactionDetailsFormConfig with _$TransactionDetailsFormConfig {
  const TransactionDetailsFormConfig._();

  const factory TransactionDetailsFormConfig.$new({
    required String bookId,
    int? initialAmount,
    Category? initialCategory,
    Category? initialParentCategory,
    String? initialMerchant,
    int? initialSatisfaction,
    DateTime? initialDate,
    required EntrySource entrySource,
    String? voiceKeyword,
  }) = NewEntryConfig;

  const factory TransactionDetailsFormConfig.edit({
    required Transaction seed,
  }) = EditEntryConfig;
}
```

**Companion result type** (NEW — sibling sealed union for `submit()` return per D-02):
```dart
@freezed
sealed class TransactionDetailsFormResult with _$TransactionDetailsFormResult {
  const factory TransactionDetailsFormResult.success(Transaction transaction) = _Success;
  const factory TransactionDetailsFormResult.validationError(String message) = _ValidationError;
  const factory TransactionDetailsFormResult.persistError(String message) = _PersistError;
}
```

**Key patterns to replicate:**
- `@freezed sealed class ... with _$X` + `const X._();` private constructor (analog line 12).
- Variant constructors via `const factory X.foo(...) = FooVariant;` (analog lines 17–41) — the typedef class name (`NewEntryConfig`, `EditEntryConfig`) is what `switch`/`when` matches on.
- Note: `new` is a Dart keyword. Use `$new` (with the `$` prefix Freezed allows) for the factory name. The exposed call site becomes `TransactionDetailsFormConfig.$new(...)`.
- No `@JsonSerializable` (no `.g.dart` needed — config is in-memory only).

**Anti-patterns to avoid:**
- Pitfall #3: MUST run `flutter pub run build_runner build --delete-conflicting-outputs` after adding `@freezed` — the `.freezed.dart` part file won't exist otherwise and compile fails.
- Pitfall #1: never modify generated `.freezed.dart` by hand.

---

### 3. `lib/features/accounting/domain/models/ocr_parse_draft.dart` (NEW — Freezed model)

**Analog:** `lib/features/accounting/domain/models/voice_parse_result.dart` lines 1–29 (same shape register: nullable primitive fields, sibling to an input-flow's parse result).

**Full template** (adapted from analog):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ocr_parse_draft.freezed.dart';

/// Result of parsing a scanned receipt via OCR.
///
/// Holds extracted fields as nullable primitives. MOD-005 populates these
/// when the real OCR writer ships; until then [OcrParseDraft.empty] is the
/// only construction path Phase 18 exercises.
///
/// Symmetric with [VoiceParseResult] — same mental model for downstream agents.
@freezed
abstract class OcrParseDraft with _$OcrParseDraft {
  const OcrParseDraft._();

  const factory OcrParseDraft({
    int? amount,
    String? merchant,
    DateTime? date,
    String? rawOcrText,
    String? imagePath,
  }) = _OcrParseDraft;

  /// Empty draft — all fields null. Used by Phase 18's OCR slot wire-up
  /// (the camera stub passes this; user fills the form manually).
  const factory OcrParseDraft.empty() = _Empty;

  /// True when no OCR field was populated — drives the banner in OcrReviewScreen.
  bool get isEmpty =>
      amount == null && merchant == null && date == null &&
      rawOcrText == null && imagePath == null;
}
```

**Key patterns to replicate:**
- `@freezed abstract class ... with _$X` (analog line 13 — note `abstract` because the analog has no sealed variants, but for our case the `.empty()` second factory makes it a sealed-style union; use `@freezed sealed class` if you want exhaustive `when`, or keep `abstract` and let both variants share `_OcrParseDraft` fields — planner discretion).
- `const OcrParseDraft._();` private constructor enables instance methods/getters (`isEmpty`).
- All fields nullable + `const factory` (analog lines 14–28).

**Anti-patterns to avoid:**
- Pitfall #3: regenerate after add (`flutter pub run build_runner build --delete-conflicting-outputs`).
- Don't add `fromJson`/`toJson` — Phase 18 doesn't serialize this; MOD-005 may add later.

---

### 4. `lib/application/accounting/update_transaction_use_case.dart` (NEW — use case)

**Analog:** `lib/application/accounting/create_transaction_use_case.dart` (mirror shape exactly; delete the hash-chain compute step per D-08).

**Imports + constructor pattern** (analog lines 1–13, 47–70 — drop `HashChainService` and `ClassificationService`):
```dart
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../shared/utils/result.dart';
import '../family_sync/sync_engine.dart';
import '../family_sync/transaction_change_tracker.dart';

/// Parameters for updating an existing transaction.
///
/// The seed transaction supplies all immutable fields (id, bookId, deviceId,
/// prevHash, currentHash, createdAt, entrySource). Editable fields are
/// supplied as overrides; null on an override means "no change".
class UpdateTransactionParams {
  final Transaction seed;
  final int? amount;
  final String? categoryId;
  final DateTime? timestamp;
  final String? note;            // empty string ≠ no change ≠ null;
  final String? merchant;        // use a sentinel or explicit `bool clearNote`
  final LedgerType? ledgerType;  // if the form needs to clear → keep simple:
  final int? soulSatisfaction;   // pass the full edited value, treat null as "unchanged"
  const UpdateTransactionParams({
    required this.seed,
    this.amount, this.categoryId, this.timestamp, this.note, this.merchant,
    this.ledgerType, this.soulSatisfaction,
  });
}

class UpdateTransactionUseCase {
  UpdateTransactionUseCase({
    required TransactionRepository transactionRepository,
    SyncEngine? syncEngine,
    TransactionChangeTracker? changeTracker,
  }) : _transactionRepo = transactionRepository,
       _syncEngine = syncEngine,
       _changeTracker = changeTracker;

  final TransactionRepository _transactionRepo;
  final SyncEngine? _syncEngine;
  final TransactionChangeTracker? _changeTracker;
```

**Execute body pattern** (parallels analog lines 76–183 — no hash compute, no ledger auto-classify, no genesis hash):
```dart
Future<Result<Transaction>> execute(UpdateTransactionParams params) async {
  // 1. Validate
  if (params.amount != null && params.amount! <= 0) {
    return Result.error('amount must be greater than 0');
  }
  if (params.categoryId != null && params.categoryId!.isEmpty) {
    return Result.error('categoryId must not be empty');
  }
  // 2. Build updated row from seed.copyWith(...) (CLAUDE.md Pitfall #4)
  final updated = params.seed.copyWith(
    amount: params.amount            ?? params.seed.amount,
    categoryId: params.categoryId    ?? params.seed.categoryId,
    timestamp: params.timestamp      ?? params.seed.timestamp,
    note: params.note,               // overwrite as-supplied (form sends final)
    merchant: params.merchant,
    ledgerType: params.ledgerType    ?? params.seed.ledgerType,
    soulSatisfaction: params.soulSatisfaction ?? params.seed.soulSatisfaction,
    updatedAt: DateTime.now(),       // D-07 — stamp on every save
    // entrySource, id, bookId, deviceId, prevHash, currentHash, createdAt
    // are preserved by copyWith default (D-07/D-08).
  );
  // 3. Persist (DAO statement is atomic — see TransactionDao.updateTransaction)
  await _transactionRepo.update(updated);
  // 4. Track for sync push (D-20)
  _changeTracker?.trackUpdate(
    TransactionSyncMapper.toUpdateOperation(
      updated,
      sourceBookId: updated.bookId,
      sourceBookName: updated.bookId,
      sourceBookType: 'remote_book:${updated.bookId}',
    ),
  );
  _syncEngine?.onTransactionChanged();
  return Result.success(updated);
}
```

**Key patterns to replicate:**
- Return `Future<Result<Transaction>>` (analog line 76) — same envelope as create/delete.
- `Result.success(...)` / `Result.error(message)` via `lib/shared/utils/result.dart` (see file content lines 13–17).
- Optional `SyncEngine?` / `TransactionChangeTracker?` constructor parameters (analog lines 54–55) — allows tests to omit the sync path.
- Track-then-trigger pattern (analog lines 169–180): `changeTracker?.trackUpdate(mapper.toUpdateOperation(...))` then `syncEngine?.onTransactionChanged()`.
- `TransactionSyncMapper.toUpdateOperation` already exists at lines 86–106 of `transaction_sync_mapper.dart` — just call it.

**Anti-patterns to avoid:**
- Per D-08: do NOT call `_hashChainService.calculateTransactionHash(...)` — `currentHash`/`prevHash` stay frozen.
- Per SC-3: do NOT touch `seed.entrySource` — re-save verbatim via `copyWith` default.
- CLAUDE.md Pitfall #4: do NOT mutate `seed` — use `copyWith`.
- Coding-style.md "Error Handling": never silently swallow — every error path returns `Result.error(...)` with a message.
- Note encryption is already handled in `TransactionRepositoryImpl.update` (lines 86–116 — `_encryptionService.encryptField(transaction.note!)`); do NOT encrypt in the use case.

---

### 5. `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (NEW — thin host)

**Analog:** `transaction_confirm_screen.dart` Scaffold + AppBar + bottom CTA shell (lines 555–735). Drop all field-editing logic — the form widget owns that.

**Shape template** (~80 lines target):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../widgets/transaction_details_form.dart';

/// Host screen for editing an existing transaction.
///
/// Thin Scaffold + AppBar + bottom save CTA wrapper around [TransactionDetailsForm]
/// configured as `.edit(seed: transaction)`. The form widget owns all
/// field-editing logic; the screen owns chrome + navigation only (D-01).
class TransactionEditScreen extends ConsumerStatefulWidget {
  const TransactionEditScreen({super.key, required this.transaction});
  final Transaction transaction;
  @override
  ConsumerState<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends ConsumerState<TransactionEditScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();
  bool _isSubmitting = false;

  Future<void> _save() async {
    setState(() => _isSubmitting = true);
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).transactionUpdated)));
        Navigator.of(context).pop(true); // D-18
      },
      validationError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
      persistError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.background : AppColors.backgroundWarm,
      appBar: AppBar(
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context), // D-10 — no dirty-confirm
          icon: const Icon(Icons.chevron_left, color: AppColors.survival),
          label: Text(l10n.back),
        ),
        title: Text(l10n.transactionEditTitle),
        centerTitle: true,
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: TransactionDetailsForm(
            key: _formKey,
            config: TransactionDetailsFormConfig.edit(seed: widget.transaction),
          ),
        )),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _SaveButton(onTap: _isSubmitting ? null : _save, isLoading: _isSubmitting),
        )),
      ]),
    );
  }
}
```

**Key patterns to replicate:**
- Scaffold/AppBar/CTA from analog lines 555–735 — port the visual shape verbatim.
- `GlobalKey<TransactionDetailsFormState>` + `currentState!.submit()` per D-02.
- `Navigator.pop(context, true)` per D-18 (NOT `popUntil((r) => r.isFirst)` — that's the confirm screen's behavior).
- `ConsumerStatefulWidget` so `ref.read(...)` is available if needed; form widget itself watches providers.

**Anti-patterns to avoid:**
- Do NOT add a delete button (D-11/D-17).
- Do NOT add a dirty-state confirmation dialog on cancel (D-10/D-16).
- Per `<deferred>`: no long-press, no undo, no edit-history audit.

---

### 6. `lib/features/accounting/presentation/screens/ocr_review_screen.dart` (NEW — thin host)

**Analog:** `TransactionEditScreen` (sibling new file above) + `transaction_confirm_screen.dart` chrome.

**Shape template** (mirror `TransactionEditScreen` with `.new` config from the draft):
```dart
class OcrReviewScreen extends ConsumerStatefulWidget {
  const OcrReviewScreen({super.key, required this.bookId, required this.draft});
  final String bookId;
  final OcrParseDraft draft;
  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();
  // ... _isSubmitting + _save() same as TransactionEditScreen but pop semantics
  //     differ: success → popUntil((r) => r.isFirst) (matches confirm screen)

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ocrReviewTitle), centerTitle: true),
      body: Column(children: [
        if (widget.draft.isEmpty)
          MaterialBanner(
            content: Text(l10n.ocrReviewEmptyDraftBanner),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: TransactionDetailsForm(
            key: _formKey,
            config: TransactionDetailsFormConfig.$new(
              bookId: widget.bookId,
              initialAmount: widget.draft.amount,
              initialMerchant: widget.draft.merchant,
              initialDate: widget.draft.date,
              entrySource: EntrySource.manual, // MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)
            ),
          ),
        )),
        SafeArea(child: _SaveButton(...)),
      ]),
    );
  }
}
```

**Key patterns to replicate:**
- Same chrome shape as `TransactionEditScreen` (and `TransactionConfirmScreen` analog).
- **The inline comment on `entrySource: EntrySource.manual` is mandatory per D-12** — MOD-005 will grep for it.
- `MaterialBanner` gated by `widget.draft.isEmpty` (uses the `isEmpty` getter on `OcrParseDraft`).

**Anti-patterns to avoid:**
- Per D-12: do NOT use `EntrySource.ocr` — that literal is type-reserved but not in production until MOD-005.
- Per `<out of scope>`: no real OCR parsing here — Phase 18 only reserves the slot.

---

### 7. `test/widget/features/accounting/presentation/screens/ocr_two_step_seam_test.dart` (NEW — widget test)

**Analog:** `test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart` (uses `createLocalizedWidget` helper + provider overrides + `pumpAndSettle` + `find.byType` assertions).

**Test helper pattern** (`test/helpers/test_localizations.dart` lines 15–34 — full file):
```dart
Widget createLocalizedWidget(
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate, GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: child,
    ),
  );
}
```

**Test body template** (per D-14 — validate SC-4 behaviorally):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/screens/ocr_review_screen.dart';
import 'package:home_pocket/features/accounting/presentation/screens/ocr_scanner_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets('shutter tap routes to OcrReviewScreen with single TransactionDetailsForm', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const OcrScannerScreen(bookId: 'book-test'),
        locale: const Locale('ja'),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the shutter (large GestureDetector at center-bottom)
    final shutter = find.byWidgetPredicate(
      (w) => w is GestureDetector && w.onTap != null,
    ).at(1); // gallery=0, shutter=1, flash=2 — adjust based on actual order
    await tester.tap(shutter);
    await tester.pumpAndSettle();

    // (a) Route stack contains OcrReviewScreen
    expect(find.byType(OcrReviewScreen), findsOneWidget);
    // (b) Exactly one TransactionDetailsForm is mounted
    expect(find.byType(TransactionDetailsForm), findsOneWidget);
  });
}
```

**Key patterns to replicate:**
- Import path style: `package:home_pocket/...` (analog line 3).
- Helper import: `import '../../../../../helpers/test_localizations.dart';` (5-up; adjust per actual nesting).
- `createLocalizedWidget(child, locale:, overrides:)` for `ProviderScope` + `MaterialApp` + i18n boilerplate.
- `tester.pumpAndSettle()` after navigation (analog line 105).
- `find.byType(...)` for screen + widget presence assertions (analog line 107).
- Per CLAUDE.md Riverpod 3 testing note: use `ProviderContainer.test()` in unit tests; here, `ProviderScope` inside the widget tree is fine.

**Anti-patterns to avoid:**
- Per CLAUDE.md Riverpod 3 conventions: do NOT do bare `await container.read(provider.future)` — use the `waitForFirstValue<T>` helper if waiting for async providers (`test/helpers/test_provider_scope.dart`).
- Do NOT use `Provider.scoped()` or any 2.x-only API.

---

### 8. `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` (MODIFIED — slim to wrapper)

**Self-refactor:** keep file path and `class TransactionConfirmScreen` per D-04 (push sites in `transaction_entry_screen.dart:225` and `voice_input_screen.dart:352` stay unchanged).

**Refactored shape** — identical chrome to current (lines 555–735), body becomes a single `TransactionDetailsForm` configured as `.new`:
```dart
class _TransactionConfirmScreenState extends ConsumerState<TransactionConfirmScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();
  bool _isSubmitting = false;

  Future<void> _save() async {
    setState(() => _isSubmitting = true);
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).transactionSaved)));
        Navigator.of(context).popUntil((r) => r.isFirst); // D-04 — preserved
      },
      validationError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
      persistError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      appBar: AppBar(/* same as current lines 566–588 */),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
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
        )),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _buildSaveButton(l10n), // same as current lines 502–552
        )),
      ]),
    );
  }
}
```

**Key patterns to replicate:**
- Constructor signature stays the same (current lines 30–41) — D-04 invariant.
- `popUntil((r) => r.isFirst)` post-save preserved (current line 348) — distinguishes from `TransactionEditScreen.pop(true)`.
- All current field-edit methods (`_editAmount`, `_editCategory`, `_editDate`, `_buildStoreAndMemoSection`) are DELETED — they live in the form widget now.

**Anti-patterns to avoid:**
- Do NOT change the constructor signature (would break push sites and require Phase 18 to touch `transaction_entry_screen.dart:225` and `voice_input_screen.dart:352`).
- Do NOT change `entrySource` handling — it flows through verbatim to `TransactionDetailsFormConfig.$new`.

---

### 9. `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` (MODIFIED — single-line change)

**Self-refactor:** swap the shutter `GestureDetector.onTap` target (current line 129) per D-13.

**Current** (file lines 127–145):
```dart
GestureDetector(
  onTap: () => Navigator.pop(context),
  child: Container(
    width: 72, height: 72,
    decoration: BoxDecoration(...),
    ...
  ),
),
```

**New:**
```dart
GestureDetector(
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OcrReviewScreen(
        bookId: bookId,
        draft: const OcrParseDraft.empty(),
      ),
    ),
  ),
  child: Container(
    width: 72, height: 72,
    decoration: BoxDecoration(...),
    ...
  ),
),
```

**Add imports:**
```dart
import '../../domain/models/ocr_parse_draft.dart';
import 'ocr_review_screen.dart';
```

**Key patterns to replicate:**
- Push pattern matches other screens' navigation (e.g., `transaction_confirm_screen.dart:230` uses `Navigator.of(context).push<Category>(MaterialPageRoute<Category>(builder: ...))`).
- `const OcrParseDraft.empty()` — const-constructible since all fields are nullable.

**Anti-patterns to avoid:**
- Do NOT change anything else in this file (camera UI, status pill, gallery/flash buttons).
- Do NOT rename the file or screen class.

---

### 10. `lib/features/home/presentation/screens/home_screen.dart` (MODIFIED — wire tile onTap)

**Self-refactor:** add a single `onTap` argument to the `HomeTransactionTile` call (current lines 293–327).

**Current** (the tile already accepts `onTap` per `home_transaction_tile.dart:55`):
```dart
return HomeTransactionTile(
  tagText: ..., tagBgColor: ..., tagTextColor: ...,
  merchant: ..., category: ..., categoryColor: ...,
  formattedAmount: ..., amountColor: ...,
  satisfactionIcon: _satisfactionIcon(tx),
);
```

**New:** add at the end of the constructor call:
```dart
return HomeTransactionTile(
  tagText: ..., tagBgColor: ..., tagTextColor: ...,
  merchant: ..., category: ..., categoryColor: ...,
  formattedAmount: ..., amountColor: ...,
  satisfactionIcon: _satisfactionIcon(tx),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute<bool>(
      builder: (_) => TransactionEditScreen(transaction: tx),
    ),
  ),
);
```

**Add import:**
```dart
import '../../../accounting/presentation/screens/transaction_edit_screen.dart';
```

**Key patterns to replicate:**
- `MaterialPageRoute<bool>` because `TransactionEditScreen` pops with `true` per D-18.
- The `tx` from the `transactions.map((tx) => ...)` closure (current line 291) is already the full `Transaction` object — no provider lookup needed.

**Anti-patterns to avoid:**
- Per ADR-016 §3: do NOT touch `HomeHeroCard` or `homeHero*Provider`s. Phase 18 wiring is scoped to the recent-tx list ONLY.
- Per `<out of scope>`: do NOT add long-press / swipe handlers — only `onTap`.
- Per `<deferred>`: do not add provider invalidation after pop — the home recent-tx provider streams from the DB.

---

### 11. `lib/application/family_sync/transaction_change_tracker.dart` (MODIFIED — add trackUpdate)

**Self-template:** mirror `trackCreate` (current lines 15–18) exactly.

**Current `trackCreate`:**
```dart
/// Record a create operation for sync.
void trackCreate(Map<String, dynamic> operation) {
  _pendingOps.add(operation);
}
```

**Add immediately after** (before `trackDelete` for visual grouping):
```dart
/// Record an update operation for sync.
///
/// The receiving sync engine already handles `op: 'update'` payloads via
/// the existing [TransactionSyncMapper.toUpdateOperation] producer.
void trackUpdate(Map<String, dynamic> operation) {
  _pendingOps.add(operation);
}
```

**Key patterns to replicate:**
- Same shape as `trackCreate` per D-20 — the operation map is already pre-shaped by `TransactionSyncMapper.toUpdateOperation` (mapper file lines 86–106).
- No new internal state; `_pendingOps` is shared with create/delete; `flush()` returns the union (current lines 32–41).

**Anti-patterns to avoid:**
- Do NOT add a new field/list to the tracker — the mapper output is the single shape contract.
- Do NOT validate the operation map shape here — that's the mapper's responsibility.

---

### 12. `lib/features/accounting/presentation/providers/repository_providers.dart` (MODIFIED — add provider)

**Self-template:** mirror `createTransactionUseCaseProvider` (current lines 128–139).

**Current `createTransactionUseCaseProvider`:**
```dart
@riverpod
CreateTransactionUseCase createTransactionUseCase(Ref ref) {
  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    deviceIdentityRepository: ref.watch(deviceIdentityRepositoryProvider),
    hashChainService: ref.watch(app_accounting.appHashChainServiceProvider),
    classificationService: ref.watch(classificationServiceProvider),
    syncEngine: ref.watch(syncEngineProvider),
    changeTracker: ref.watch(transactionChangeTrackerProvider),
  );
}
```

**Add immediately after** (place before `deleteTransactionUseCaseProvider` at current line 149 for ordering):
```dart
@riverpod
UpdateTransactionUseCase updateTransactionUseCase(Ref ref) {
  return UpdateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    syncEngine: ref.watch(syncEngineProvider),
    changeTracker: ref.watch(transactionChangeTrackerProvider),
  );
}
```

**Add import:**
```dart
import '../../../../application/accounting/update_transaction_use_case.dart';
```

**Key patterns to replicate:**
- `@riverpod` annotation + lowercase camelCase function name — generator emits `updateTransactionUseCaseProvider` (CLAUDE.md "Provider names strip the Notifier suffix" — applies here naturally).
- Imports use the application layer (`app_accounting.app*Provider`) for `HashChainService` / `KeyManager` — NOT direct infra imports (HIGH-02 compliance, per analog comments).
- Constructor takes `transactionRepository` + optional `syncEngine` + optional `changeTracker` (matches `UpdateTransactionUseCase` constructor from file #4 above).

**Anti-patterns to avoid:**
- CLAUDE.md Pitfall #10: do NOT duplicate the provider definition in another file — this is the single source of truth per project rule "ONE `repository_providers.dart` per feature".
- Pitfall #3: regenerate `.g.dart` (`flutter pub run build_runner build --delete-conflicting-outputs`).
- Pitfall #2: do NOT import `lib/data/...` from this feature presentation file — go via the application/infrastructure providers.

---

### 13. `lib/l10n/app_ja.arb` + `app_zh.arb` + `app_en.arb` (MODIFIED — 5 new keys × 3 locales)

**Analog entries** (current `app_en.arb` lines 344–351):
```json
"transactionSaved": "Transaction saved",
"@transactionSaved": {
  "description": "Transaction save success"
},
"failedToSave": "Failed to save",
"@failedToSave": {
  "description": "Save failure"
},
```

**Add (en):**
```json
"transactionEditTitle": "Edit Entry",
"@transactionEditTitle": {
  "description": "AppBar title for TransactionEditScreen (Phase 18)"
},
"ocrReviewTitle": "Review Receipt",
"@ocrReviewTitle": {
  "description": "AppBar title for OcrReviewScreen (Phase 18, MOD-005 slot)"
},
"ocrReviewEmptyDraftBanner": "OCR is not implemented yet — please fill in the fields manually.",
"@ocrReviewEmptyDraftBanner": {
  "description": "Banner shown on OcrReviewScreen when draft is empty (Phase 18)"
},
"transactionUpdated": "Transaction updated",
"@transactionUpdated": {
  "description": "Snackbar after successful edit save (sibling to transactionSaved)"
},
"failedToUpdate": "Failed to update",
"@failedToUpdate": {
  "description": "Error snackbar on edit save failure"
}
```

**Add (ja)** — placeholder copy; planner should refine wording with project tone:
```json
"transactionEditTitle": "明細編集",
"ocrReviewTitle": "レシート確認",
"ocrReviewEmptyDraftBanner": "OCRはまだ実装されていません。手動で入力してください。",
"transactionUpdated": "明細を更新しました",
"failedToUpdate": "更新に失敗しました"
```

**Add (zh):**
```json
"transactionEditTitle": "明细编辑",
"ocrReviewTitle": "票据复核",
"ocrReviewEmptyDraftBanner": "OCR 尚未实现，请手动填写各字段。",
"transactionUpdated": "明细已更新",
"failedToUpdate": "更新失败"
```

**Key patterns to replicate:**
- Every key has a sibling `@<key>` metadata object with `"description"` (CLAUDE.md i18n rule + analog convention).
- Parity across all 3 ARB files is enforced by `test/architecture/arb_key_parity_test.dart` — every key MUST exist in all three.
- After editing: run `flutter gen-l10n` to regenerate `lib/generated/app_localizations.dart` (so `S.of(context).transactionUpdated` resolves).
- Locale-specific formatting (currency, dates) goes through `FormatterService` (`lib/application/i18n/formatter_service.dart`) — not these ARB strings.

**Anti-patterns to avoid:**
- CLAUDE.md i18n: never hardcode UI text — go through `S.of(context).key`.
- Do NOT add a key to only ja+en (or any 2-of-3) — parity test fails CI.
- Do NOT use `intl` version other than 0.20.2 (Pitfall #5 — pinned by `flutter_localizations`).

---

## Shared Patterns

### Riverpod 3 import boundary (applies to ALL new/modified Dart files)

**Source:** CLAUDE.md "Riverpod 3 conventions" section.

| Need | Import |
|------|--------|
| `Provider`, `Notifier`, `ConsumerWidget`, `ConsumerStatefulWidget`, `WidgetRef`, `ProviderScope`, `AsyncValue` | `package:flutter_riverpod/flutter_riverpod.dart` |
| `StateNotifier`, `StateProvider`, `ChangeNotifierProvider` | `package:flutter_riverpod/legacy.dart` |
| `Override`, `ProviderListenable`, `Refreshable` | `package:flutter_riverpod/misc.dart` |

Phase 18 only needs the first row (form widget is `ConsumerStatefulWidget`; providers are `@riverpod`-generated). Do NOT import `legacy.dart` or `misc.dart` from production code.

### Freezed + code generation (applies to files #2, #3)

**Source:** CLAUDE.md Pitfall #3 + `<canonical_refs>` for `worklog.md`.

Workflow after adding any `@freezed` annotation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
Then commit the generated `.freezed.dart` (and any `.g.dart` if `fromJson` was added — N/A for Phase 18).

### Result<T> envelope (applies to file #4 + form widget submit)

**Source:** `lib/shared/utils/result.dart` lines 1–19.

```dart
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  factory Result.success(T? data) => Result._(data: data, isSuccess: true);
  factory Result.error(String message) => Result._(error: message, isSuccess: false);
  bool get isError => !isSuccess;
}
```

Usage: every use case returns `Future<Result<X>>`; check `.isSuccess`, read `.data` or `.error`.

### `seed.copyWith(...)` for edit-mode update (applies to file #4)

**Source:** Transaction is `@freezed` (`transaction.dart` line 12) so `copyWith` is generated. CLAUDE.md Pitfall #4 + coding-style.md Immutability section.

Always build the updated `Transaction` via `seed.copyWith(amount: ..., note: ..., updatedAt: DateTime.now(), ...)` — never mutate `seed`. Fields NOT mentioned in `copyWith(...)` are preserved verbatim from `seed` (which is exactly what D-07/D-08 require for `id`, `bookId`, `deviceId`, `prevHash`, `currentHash`, `createdAt`, `entrySource`).

### Sync push lane (applies to file #4, file #11)

**Source:** `lib/application/accounting/create_transaction_use_case.dart` lines 169–180.

Pattern: after a successful repository mutation, call:
1. `_changeTracker?.trackUpdate(TransactionSyncMapper.toUpdateOperation(tx, sourceBookId: ..., sourceBookName: ..., sourceBookType: 'remote_book:${bookId}'))`
2. `_syncEngine?.onTransactionChanged()` (fire-and-forget; the SyncEngine handles debounce).

Both are nullable in the constructor — tests can pass `null` to skip the sync path.

### Test localization helper (applies to file #7)

**Source:** `test/helpers/test_localizations.dart` lines 15–34.

Always wrap test widgets with `createLocalizedWidget(child, locale:, overrides:)` — it provides `ProviderScope` + `MaterialApp` + `S.delegate` + supported locales. Default `Locale('en')`; tests that assert specific copy should pin `locale: const Locale('ja')` per analog convention.

### `@riverpod` generator naming (applies to file #12)

**Source:** CLAUDE.md "Provider names strip the `Notifier` suffix" note.

A function `UpdateTransactionUseCase updateTransactionUseCase(Ref ref) { ... }` annotated `@riverpod` generates `updateTransactionUseCaseProvider` automatically. Do not write the provider name manually. Class-based `@riverpod class FooNotifier extends _$FooNotifier { ... }` would generate `fooProvider` (suffix stripped).

---

## No Analog Found

None — all 13 files have a clear analog in the codebase. Phase 18 is a refactor + extension, not a green-field addition.

---

## Metadata

**Analog search scope:**
- `lib/features/accounting/` (presentation + domain)
- `lib/application/accounting/` and `lib/application/family_sync/`
- `lib/features/analytics/domain/models/` (sealed-union template)
- `lib/features/home/presentation/` (tile wiring)
- `lib/data/repositories/transaction_repository_impl.dart` (DAO surface)
- `lib/l10n/app_*.arb` (i18n shape)
- `lib/shared/utils/result.dart` (Result envelope)
- `test/widget/features/accounting/` (test conventions)
- `test/helpers/test_localizations.dart` (test scaffolding)

**Files scanned:** 17 source files + 1 test file + 1 ARB file (en).
**Pattern extraction date:** 2026-05-22.
