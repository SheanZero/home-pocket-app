/// Quick task 260707-kfb GROUP A (item 1 + item 4): characterization +
/// non-happy-path pins for `ManualOneStepScreen`, written BEFORE the mechanical
/// keypad / currency / save extraction (A2) so the move can be proven
/// byte-faithful.
///
/// Everything here asserts on OBSERVABLE surfaces only — the rendered
/// `AmountDisplay.amount` / `.currencyLabel`, the public `TransactionDetailsForm`
/// getters (read via `tester.state`), the V16 save-action gate, and the saved
/// `CreateTransactionParams.entrySource`. No private field is poked, so the
/// suite stays valid across the A2 relocation of the method bodies into
/// same-library `part` extensions.
///
/// Coverage:
///   - keypad characterization: digits update the display; the clear affordance
///     empties the amount AND drops voice provenance (a later keypad row saves
///     manual, T-nhs-03).
///   - currency characterization: the JPY→foreign→JPY round trip relabels the
///     display and re-syncs; returning to JPY clears the form's foreign triple
///     (CURR-04).
///   - save-guard characterization: the V16 record action keeps the mockup's
///     active styling for empty/zero amounts while validation still blocks save;
///     unresolved categories remain disabled.
///   - item 4a: a manual keypad edit AFTER a voice fill keeps voice provenance
///     (the edited row still saves EntrySource.voice) until the amount is cleared.
///   - item 4b: a reset restores `_lastFillWasVoice` from the pre-speech snapshot
///     (a pure-manual slate → a later keypad save is manual again).
///   - item 4c: the PTT-commit keypad mirror writes the booked JPY figure into
///     the display when the form's foreign triple was ALREADY written, WITHOUT
///     clobbering that triple (headline shows booked JPY; the save carries the
///     foreign triple, D-4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/application/currency/get_exchange_rate_use_case.dart';
import 'package:home_pocket/application/currency/repository_providers.dart'
    show appGetExchangeRateUseCaseProvider;
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        categoryRepositoryProvider,
        categoryServiceProvider,
        createTransactionUseCaseProvider,
        merchantCategoryLearningServiceProvider,
        parseVoiceInputUseCaseProvider;
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/unified_voice_entry_dock.dart';
import 'package:home_pocket/features/currency/domain/models/rate_result.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart'
    show voiceLocaleIdProvider;
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes / Mocks ──────────────────────────────────────────────────────────

class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this.categories);

  final List<Category> categories;

  @override
  Future<List<Category>> findActive() async => categories;

  @override
  Future<Category?> findById(String id) async {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Category>> findAll() async => categories;

  @override
  Future<List<Category>> findByLevel(int level) async =>
      categories.where((c) => c.level == level).toList();

  @override
  Future<List<Category>> findByParent(String parentId) async =>
      categories.where((c) => c.parentId == parentId).toList();

  @override
  Future<void> insert(Category category) async {}

  @override
  Future<void> insertBatch(List<Category> categories) async {}

  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
}

/// Delays findActive() so the null-category save-guard branch can be exercised
/// before the async default-category init resolves.
class _SlowFakeCategoryRepository extends _FakeCategoryRepository {
  _SlowFakeCategoryRepository(super.categories);

  @override
  Future<List<Category>> findActive() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return super.findActive();
  }
}

class _MockCreateTransactionUseCase extends Mock
    implements CreateTransactionUseCase {}

class _MockCategoryService extends Mock implements CategoryService {}

class _MockMerchantCategoryLearningService extends Mock
    implements MerchantCategoryLearningService {}

class _FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

/// Stub exchange-rate use case — returns a fixed [RateResult] so the foreign
/// conversion path is deterministic (no DB / network). The real use case never
/// throws (RATE-03); this preserves that contract.
class _StubExchangeRateUseCase implements GetExchangeRateUseCase {
  _StubExchangeRateUseCase(this._result);

  final RateResult _result;

  @override
  Future<RateResultWithSignal> execute(GetExchangeRateParams params) async =>
      RateResultWithSignal(result: _result);
}

class _CapturingSpeechService implements StartSpeechRecognitionUseCase {
  void Function(SpeechRecognitionResult result)? onResult;
  void Function(String status)? onStatus;
  String? startedLocaleId;
  var stopped = false;
  var canceled = false;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async {
    this.onStatus = onStatus;
    return true;
  }

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => startedLocaleId != null && !stopped;

  @override
  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    required void Function(double normalizedLevel) onSoundLevel,
    required String localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
    bool allowOnDeviceFallback = true,
  }) async {
    this.onResult = onResult;
    startedLocaleId = localeId;
    stopped = false;
  }

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> cancel() async => canceled = true;

  void emitFinal(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.95)], true),
  );

  void emitPartial(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.95)], false),
  );

  void emitStatus(String status) => onStatus!(status);
}

class _FakeParseVoiceInputUseCase implements ParseVoiceInputUseCase {
  _FakeParseVoiceInputUseCase(this.results);
  final Map<String, VoiceParseResult> results;
  final inputs = <String>[];

  @override
  Future<Result<VoiceParseResult>> execute(
    String recognizedText, {
    String? localeId,
    List<String> alternateTexts = const [],
  }) async {
    inputs.add(recognizedText);
    return Result.success(results[recognizedText]);
  }
}

// ── Fixtures ────────────────────────────────────────────────────────────────

final _l1Category = Category(
  id: 'food',
  name: 'category_food',
  icon: 'restaurant',
  color: '#E85A4F',
  level: 1,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime(2026, 4, 3),
);

final _l2Category = Category(
  id: 'convenience',
  name: 'コンビニ',
  icon: 'shopping_basket',
  color: '#E85A4F',
  parentId: 'food',
  level: 2,
  sortOrder: 1,
  createdAt: DateTime(2026, 4, 3),
);

final _fakeCategories = [_l1Category, _l2Category];

final _successTransaction = Transaction(
  id: 'tx_001',
  bookId: 'book-1',
  deviceId: 'device_001',
  amount: 111,
  type: TransactionType.expense,
  categoryId: 'convenience',
  ledgerType: LedgerType.daily,
  timestamp: DateTime(2026, 2, 22),
  currentHash: 'hash_001',
  createdAt: DateTime(2026, 2, 22),
);

void main() {
  late _MockCreateTransactionUseCase mockCreateUseCase;
  late _MockCategoryService mockCategoryService;
  late _MockMerchantCategoryLearningService mockLearningService;

  setUpAll(() {
    registerFallbackValue(_FakeCreateTransactionParams());
  });

  setUp(() {
    mockCreateUseCase = _MockCreateTransactionUseCase();
    mockCategoryService = _MockCategoryService();
    mockLearningService = _MockMerchantCategoryLearningService();
    when(
      () => mockCategoryService.resolveLedgerType(any()),
    ).thenAnswer((_) async => LedgerType.daily);
    when(
      () => mockLearningService.recordSelection(
        merchantRaw: any(named: 'merchantRaw'),
        selectedCategoryId: any(named: 'selectedCategoryId'),
      ),
    ).thenAnswer((_) async {});
  });

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget pumpManual({
    required CategoryRepository categoryRepo,
    _CapturingSpeechService? speech,
    _FakeParseVoiceInputUseCase? parse,
    Category? initialCategory,
    Category? initialParentCategory,
    EntrySource entrySource = EntrySource.manual,
    RateResult? rate,
  }) {
    return createLocalizedWidget(
      ManualOneStepScreen(
        bookId: 'book-1',
        initialCategory: initialCategory,
        initialParentCategory: initialParentCategory,
        entrySource: entrySource,
        speechService: speech,
      ),
      locale: const Locale('en'),
      overrides: [
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
        createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
        categoryServiceProvider.overrideWithValue(mockCategoryService),
        merchantCategoryLearningServiceProvider.overrideWithValue(
          mockLearningService,
        ),
        if (parse != null)
          parseVoiceInputUseCaseProvider.overrideWithValue(parse),
        voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
        if (rate != null)
          appGetExchangeRateUseCaseProvider.overrideWithValue(
            _StubExchangeRateUseCase(rate),
          ),
      ],
    );
  }

  String displayedAmount(WidgetTester tester) =>
      tester.widget<AmountDisplay>(find.byType(AmountDisplay)).amount;

  String displayedCurrency(WidgetTester tester) =>
      tester.widget<AmountDisplay>(find.byType(AmountDisplay)).currencyLabel;

  TransactionDetailsFormState formState(WidgetTester tester) => tester
      .state<TransactionDetailsFormState>(find.byType(TransactionDetailsForm));

  Future<void> tapKey(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text(label),
      ),
    );
    await tester.pump();
  }

  final micBarFinder = find.byKey(const ValueKey('voice-record-bar'));

  UnifiedVoiceEntryDock voiceDock(WidgetTester tester) =>
      tester.widget<UnifiedVoiceEntryDock>(find.byType(UnifiedVoiceEntryDock));

  Future<void> finishVoiceUtterance(
    WidgetTester tester,
    _CapturingSpeechService speech,
  ) async {
    speech.startedLocaleId = null;
    speech.emitStatus('done');
    await tester.pump();
    await tester.pump();
  }

  Future<void> switchVoiceDockToKeyboard(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('unified-voice-keyboard')));
    await tester.pump();
    await tester.pump();
  }

  Future<void> openVoiceDockAndStart(WidgetTester tester) async {
    await tester.tap(micBarFinder);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('unified-voice-core')));
    await tester.pump();
    await tester.pump();
  }

  // ── keypad characterization ────────────────────────────────────────────────

  group('keypad characterization', () {
    testWidgets('typing digits updates the AmountDisplay', (tester) async {
      tall(tester);
      await tester.pumpWidget(
        pumpManual(
          categoryRepo: _FakeCategoryRepository(_fakeCategories),
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
        ),
      );
      await tester.pumpAndSettle();

      expect(displayedAmount(tester), '');
      await tapKey(tester, '1');
      await tapKey(tester, '2');
      await tapKey(tester, '3');
      expect(displayedAmount(tester), '123');
      expect(formState(tester).currentAmount, 123);
    });

    testWidgets(
      'the clear affordance empties the amount AND drops voice provenance '
      '(a later keypad row saves manual)',
      (tester) async {
        tall(tester);
        when(
          () => mockCreateUseCase.execute(any()),
        ).thenAnswer((_) async => Result.success(_successTransaction));

        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '500円': VoiceParseResult(rawText: '500円', amount: 500),
        });

        await tester.pumpWidget(
          pumpManual(
            categoryRepo: _FakeCategoryRepository(_fakeCategories),
            initialCategory: _l2Category,
            initialParentCategory: _l1Category,
            speech: speech,
            parse: parse,
          ),
        );
        await tester.pumpAndSettle();

        // Voice fill flips provenance to voice and mirrors 500 into the keypad.
        await openVoiceDockAndStart(tester);
        speech.emitFinal('500円');
        await tester.pump();
        await tester.pump();
        expect(displayedAmount(tester), '500');

        await finishVoiceUtterance(tester, speech);
        expect(voiceDock(tester).state, UnifiedVoiceEntryState.review);
        await switchVoiceDockToKeyboard(tester);

        // Tap the AmountDisplay clear (x) → amount empties, provenance dropped.
        await tester.tap(
          find.descendant(
            of: find.byType(AmountDisplay),
            matching: find.byIcon(Icons.close),
          ),
        );
        await tester.pump();
        expect(displayedAmount(tester), '');

        // Re-enter a keypad amount and save → EntrySource.manual (voice dropped).
        await tapKey(tester, '1');
        await tapKey(tester, '1');
        await tapKey(tester, '1');
        await tapKey(tester, 'Record');
        await tester.pumpAndSettle();

        final captured = verify(
          () => mockCreateUseCase.execute(captureAny()),
        ).captured;
        expect(captured.length, 1);
        expect(
          (captured.first as CreateTransactionParams).entrySource,
          EntrySource.manual,
          reason: 'clearing the amount drops voice provenance (T-nhs-03)',
        );
      },
    );
  });

  // ── currency characterization ───────────────────────────────────────────────

  group('currency characterization', () {
    testWidgets(
      'JPY → foreign → JPY relabels the display and re-syncs; returning to '
      'JPY clears the foreign triple (CURR-04)',
      (tester) async {
        tall(tester);
        await tester.pumpWidget(
          pumpManual(
            categoryRepo: _FakeCategoryRepository(_fakeCategories),
            initialCategory: _l2Category,
            initialParentCategory: _l1Category,
            // RateUnavailable keeps the foreign path deterministic (no triple
            // is written) so the CURR-04 clear-on-JPY assertion is unambiguous.
            rate: const RateUnavailable(currency: 'USD'),
          ),
        );
        await tester.pumpAndSettle();

        await tapKey(tester, '1');
        await tapKey(tester, '2');
        await tapKey(tester, '3');
        expect(displayedCurrency(tester), 'JPY');
        expect(
          formState(tester).currentOriginalCurrency,
          isNull,
          reason: 'JPY-native: no foreign triple',
        );

        // Open the currency sheet and select USD.
        await tester.tap(
          find.byKey(const ValueKey('smart_keyboard_currency_key')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('currency-row-USD')));
        await tester.pumpAndSettle();

        expect(
          displayedCurrency(tester),
          'USD',
          reason: 'selecting a non-JPY currency relabels the display',
        );

        // Return to JPY — the triple must be cleared (CURR-04).
        await tester.tap(
          find.byKey(const ValueKey('smart_keyboard_currency_key')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('currency-row-JPY')));
        await tester.pumpAndSettle();

        expect(displayedCurrency(tester), 'JPY');
        expect(
          formState(tester).currentOriginalCurrency,
          isNull,
          reason: 'selecting JPY clears the foreign triple (CURR-04)',
        );
      },
    );
  });

  // ── save-guard characterization ─────────────────────────────────────────────

  group('save-guard characterization', () {
    testWidgets('empty/zero amount stays active but validation blocks save', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        pumpManual(
          categoryRepo: _FakeCategoryRepository(_fakeCategories),
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SmartKeyboard>(find.byType(SmartKeyboard))
            .isActionEnabled,
        isTrue,
        reason: 'V16 mirrors the mockup while _trySave owns amount validation',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(SmartKeyboard),
          matching: find.text('Record'),
        ),
      );
      await tester.pump();
      verifyNever(() => mockCreateUseCase.execute(any()));
    });

    testWidgets('null category disables the V16 record action', (tester) async {
      tall(tester);
      await tester.pumpWidget(
        pumpManual(
          // Slow repo + NO initialCategory → _selectedCategory stays null.
          categoryRepo: _SlowFakeCategoryRepository(_fakeCategories),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Enter an amount while the slow repository still leaves category null.
      await tapKey(tester, '1');
      expect(
        tester
            .widget<SmartKeyboard>(find.byType(SmartKeyboard))
            .isActionEnabled,
        isFalse,
        reason: 'V16 prevents submit until the category has resolved',
      );
      verifyNever(() => mockCreateUseCase.execute(any()));

      // Flush the slow-repo delayed future + toast timers.
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  // ── item 4a: manual edit after a voice fill keeps voice provenance ──────────

  testWidgets('4a: a keypad edit after a voice fill keeps EntrySource.voice', (
    tester,
  ) async {
    tall(tester);
    when(
      () => mockCreateUseCase.execute(any()),
    ).thenAnswer((_) async => Result.success(_successTransaction));

    final speech = _CapturingSpeechService();
    final parse = _FakeParseVoiceInputUseCase(const {
      '500円': VoiceParseResult(rawText: '500円', amount: 500),
    });

    await tester.pumpWidget(
      pumpManual(
        categoryRepo: _FakeCategoryRepository(_fakeCategories),
        initialCategory: _l2Category,
        initialParentCategory: _l1Category,
        speech: speech,
        parse: parse,
      ),
    );
    await tester.pumpAndSettle();

    await openVoiceDockAndStart(tester);
    speech.emitFinal('500円');
    await tester.pump();
    await tester.pump();
    expect(displayedAmount(tester), '500');

    await finishVoiceUtterance(tester, speech);
    expect(voiceDock(tester).state, UnifiedVoiceEntryState.review);
    await switchVoiceDockToKeyboard(tester);
    await tapKey(tester, '1');
    expect(
      displayedAmount(tester),
      '5001',
      reason: 'the edit continues from the mirrored fill',
    );

    await tapKey(tester, 'Record');
    await tester.pumpAndSettle();

    final captured = verify(
      () => mockCreateUseCase.execute(captureAny()),
    ).captured;
    expect(captured.length, 1);
    expect(
      (captured.first as CreateTransactionParams).entrySource,
      EntrySource.voice,
      reason: 'a manual edit after a voice fill keeps voice provenance',
    );
  });

  // ── item 4b: reset restores _lastFillWasVoice from the snapshot ─────────────

  testWidgets(
    '4b: reset from a pure-manual snapshot rolls provenance back to manual',
    (tester) async {
      tall(tester);
      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      final speech = _CapturingSpeechService();
      final parse = _FakeParseVoiceInputUseCase(const {
        '500円': VoiceParseResult(rawText: '500円', amount: 500),
      });

      await tester.pumpWidget(
        pumpManual(
          categoryRepo: _FakeCategoryRepository(_fakeCategories),
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
          speech: speech,
          parse: parse,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 语音记录 with a pure-manual slate → the snapshot is manual.
      await openVoiceDockAndStart(tester);

      // Voice fill flips provenance to voice.
      speech.emitFinal('500円');
      await tester.pump();
      await tester.pump();
      expect(displayedAmount(tester), '500');

      await finishVoiceUtterance(tester, speech);
      expect(voiceDock(tester).state, UnifiedVoiceEntryState.review);

      // Review mic → restore the pre-speech snapshot and re-record.
      await tester.tap(find.byKey(const ValueKey('unified-voice-core')));
      await tester.pump();
      await tester.pump();
      expect(
        displayedAmount(tester),
        '',
        reason: 'reset rolls the amount back to the empty snapshot',
      );

      expect(voiceDock(tester).state, UnifiedVoiceEntryState.listening);
      await switchVoiceDockToKeyboard(tester);
      await tapKey(tester, '1');
      await tapKey(tester, '1');
      await tapKey(tester, '1');
      await tapKey(tester, 'Record');
      await tester.pumpAndSettle();

      final captured = verify(
        () => mockCreateUseCase.execute(captureAny()),
      ).captured;
      expect(captured.length, 1);
      expect(
        (captured.first as CreateTransactionParams).entrySource,
        EntrySource.manual,
        reason: 'reset restored _lastFillWasVoice from the manual snapshot',
      );
    },
  );

  // ── item 4c: keypad mirror with a foreign triple already written ───────────

  testWidgets(
    'foreign snapshot restore keeps original units in the triple and restores '
    'the converted booked JPY amount',
    (tester) async {
      tall(tester);
      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      final speech = _CapturingSpeechService();
      final parse = _FakeParseVoiceInputUseCase(const {
        '500円': VoiceParseResult(rawText: '500円', amount: 500),
      });
      await tester.pumpWidget(
        pumpManual(
          categoryRepo: _FakeCategoryRepository(_fakeCategories),
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
          speech: speech,
          parse: parse,
          rate: RateFetched(
            rate: '150.0',
            currency: 'USD',
            rateDate: DateTime(2026, 7, 7),
            source: 'test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('smart_keyboard_currency_key')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('currency-row-USD')));
      await tester.pumpAndSettle();
      await tapKey(tester, '1');
      await tapKey(tester, '0');
      await tester.pumpAndSettle();

      final form = formState(tester);
      expect(displayedAmount(tester), '10');
      expect(displayedCurrency(tester), 'USD');
      expect(form.currentAmount, 1500);
      expect(form.currentOriginalAmount, 1000);
      expect(form.currentAppliedRate, '150.0');

      await openVoiceDockAndStart(tester);
      speech.emitPartial('500円');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump();
      expect(
        form.currentAmount,
        500,
        reason: 'precondition: voice dirtied JPY',
      );

      await switchVoiceDockToKeyboard(tester);
      expect(displayedAmount(tester), '10');
      expect(displayedCurrency(tester), 'USD');
      expect(
        form.currentAmount,
        1500,
        reason: 'restore uses captured booked JPY, never USD text/minor units',
      );
      expect(form.currentOriginalCurrency, 'USD');
      expect(form.currentOriginalAmount, 1000);
      expect(form.currentAppliedRate, '150.0');

      await tapKey(tester, 'Record');
      await tester.pumpAndSettle();

      final saved =
          verify(() => mockCreateUseCase.execute(captureAny())).captured.single
              as CreateTransactionParams;
      expect(saved.amount, 1500);
      expect(saved.originalCurrency, 'USD');
      expect(saved.originalAmount, 1000);
      expect(saved.appliedRate, '150.0');
    },
  );

  testWidgets(
    '4c: the PTT-commit mirror writes booked JPY into the display WITHOUT '
    'clobbering the form foreign triple (D-4)',
    (tester) async {
      tall(tester);
      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      final speech = _CapturingSpeechService();
      final parse = _FakeParseVoiceInputUseCase(const {
        '10 dollars coffee': VoiceParseResult(
          rawText: '10 dollars coffee',
          amount: 10,
          merchantName: 'Coffee',
          detectedCurrency: 'USD',
          categoryMatch: CategoryMatchResult(
            categoryId: 'convenience',
            confidence: 0.91,
            source: MatchSource.keyword,
          ),
          ledgerType: LedgerType.daily,
        ),
      });

      await tester.pumpWidget(
        pumpManual(
          categoryRepo: _FakeCategoryRepository(_fakeCategories),
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
          speech: speech,
          parse: parse,
          // A resolvable rate so the voice fill writes the foreign triple.
          rate: RateFetched(
            rate: '150.0',
            currency: 'USD',
            rateDate: DateTime(2026, 7, 7),
            source: 'test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openVoiceDockAndStart(tester);
      speech.emitFinal('10 dollars coffee');
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final form = formState(tester);
      // The voice fill wrote the foreign triple onto the form.
      expect(
        form.currentOriginalCurrency,
        'USD',
        reason: 'the foreign triple was written before the mirror ran',
      );
      expect(
        form.currentOriginalAmount,
        1000,
        reason: '10 USD → 1000 minor units',
      );
      // The mirror wrote the booked JPY figure into the keypad/AmountDisplay
      // (host stays JPY-native, headline shows booked JPY, D-4) WITHOUT
      // re-syncing the form (the triple survives).
      expect(
        displayedAmount(tester),
        form.currentAmount.toString(),
        reason: 'the display mirrors the booked JPY from the form',
      );
      expect(
        displayedCurrency(tester),
        'JPY',
        reason: 'the keypad stays on the JPY native path (D-4)',
      );
      expect(
        form.currentOriginalCurrency,
        'USD',
        reason: 'the mirror did not clobber the foreign triple',
      );

      await finishVoiceUtterance(tester, speech);
      expect(voiceDock(tester).state, UnifiedVoiceEntryState.review);
      await switchVoiceDockToKeyboard(tester);
      // Clear the floating conversion-notice snackbar so it cannot obscure the
      // Record key at the bottom of the screen.
      ScaffoldMessenger.of(
        tester.element(find.byType(SmartKeyboard)),
      ).clearSnackBars();
      await tester.pumpAndSettle();

      // Save → the row carries both voice provenance and the foreign triple.
      await tapKey(tester, 'Record');
      await tester.pumpAndSettle();

      final captured = verify(
        () => mockCreateUseCase.execute(captureAny()),
      ).captured;
      expect(captured.length, 1);
      expect(
        (captured.first as CreateTransactionParams).entrySource,
        EntrySource.voice,
        reason: 'a PTT-filled row stamps voice provenance',
      );
    },
  );
}
