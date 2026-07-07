/// Phase 42 GAP-CLOSURE (CR-01) — end-to-end proof that a spoken FOREIGN
/// currency utterance saves a row with a COMPLETE currency triple and the
/// correct converted JPY amount, instead of the broken partial-triple path that
/// made CreateTransactionUseCase reject the save ("五十美元 / 五十ドル" never saved).
///
/// Drives the production commit path: long-press → emitFinal → release → Save,
/// with the REAL `appGetExchangeRateUseCaseProvider` overridden by a fake that
/// returns a KNOWN rate. Asserts the captured CreateTransactionParams carries
/// `amount == convertToJpy(...)` AND all three triple fields. A second test
/// proves the RateUnavailable path persists a JPY-native row (no partial triple).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/currency/get_exchange_rate_use_case.dart';
import 'package:home_pocket/features/currency/domain/models/rate_result.dart';
import 'package:home_pocket/application/currency/repository_providers.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_category_preference.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_category_preference_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart'
    show voiceLocaleIdProvider;
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/currency_conversion.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class CapturingStartSpeechRecognitionUseCase
    implements StartSpeechRecognitionUseCase {
  void Function(SpeechRecognitionResult result)? onResult;
  String? startedLocaleId;
  var stopped = false;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async => true;

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
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> cancel() async {}

  void emitFinal(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.95)], true),
  );
}

class _FakeParseVoiceInputUseCase implements ParseVoiceInputUseCase {
  _FakeParseVoiceInputUseCase(this.results);
  final Map<String, VoiceParseResult> results;

  @override
  Future<Result<VoiceParseResult>> execute(
    String recognizedText, {
    String? localeId,
    List<String> alternateTexts = const [],
  }) async => Result.success(results[recognizedText]);
}

/// Fake rate use case returning a fixed [result].
class _FakeRateUseCase implements GetExchangeRateUseCase {
  _FakeRateUseCase(this.result);
  final RateResult result;
  GetExchangeRateParams? lastParams;

  @override
  Future<RateResultWithSignal> execute(GetExchangeRateParams params) async {
    lastParams = params;
    return RateResultWithSignal(result: result);
  }
}

/// Captures the params passed to create() and returns a success row.
class _CapturingCreateTransactionUseCase implements CreateTransactionUseCase {
  CreateTransactionParams? captured;

  @override
  Future<Result<Transaction>> execute(CreateTransactionParams params) async {
    captured = params;
    return Result.success(
      Transaction(
        id: 'tx-foreign',
        bookId: params.bookId,
        deviceId: 'device-1',
        amount: params.amount,
        type: TransactionType.expense,
        categoryId: params.categoryId,
        ledgerType: params.ledgerType ?? LedgerType.daily,
        timestamp: params.timestamp ?? DateTime(2026, 5, 25),
        currentHash: 'hash-foreign',
        createdAt: DateTime(2026, 5, 25),
        originalCurrency: params.originalCurrency,
        originalAmount: params.originalAmount,
        appliedRate: params.appliedRate,
        entrySource: EntrySource.voice,
      ),
    );
  }
}

class _FakeCategoryLedgerConfigRepository
    implements CategoryLedgerConfigRepository {
  @override
  Future<void> delete(String categoryId) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<CategoryLedgerConfig>> findAll() async => [];
  @override
  Future<CategoryLedgerConfig?> findById(String categoryId) async =>
      CategoryLedgerConfig(
        categoryId: categoryId,
        ledgerType: LedgerType.daily,
        updatedAt: DateTime(2026),
      );
  @override
  Future<void> upsert(CategoryLedgerConfig config) async {}
  @override
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs) async {}
}

class _FakeCategoryRepository implements CategoryRepository {
  final _categories = {
    'cat_food': Category(
      id: 'cat_food',
      name: 'Food',
      icon: 'restaurant',
      color: '#F59E0B',
      level: 1,
      createdAt: DateTime(2026),
    ),
    'cat_food_cafe': Category(
      id: 'cat_food_cafe',
      name: 'Cafe',
      icon: 'local_cafe',
      color: '#F59E0B',
      parentId: 'cat_food',
      level: 2,
      createdAt: DateTime(2026),
    ),
  };

  @override
  Future<void> deleteAll() async {}
  @override
  Future<List<Category>> findActive() async => [];
  @override
  Future<List<Category>> findAll() async => [];
  @override
  Future<Category?> findById(String id) async => _categories[id];
  @override
  Future<List<Category>> findByLevel(int level) async => [];
  @override
  Future<List<Category>> findByParent(String parentId) async => [];
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
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
}

class _NoopMerchantPrefRepo implements MerchantCategoryPreferenceRepository {
  @override
  Future<MerchantCategoryPreference?> findByMerchantKey(String k) async => null;
  @override
  Future<void> upsert(MerchantCategoryPreference preference) async {}
  @override
  Future<void> recordSelection({
    required String merchantKey,
    required String selectedCategoryId,
  }) async {}
  @override
  Future<String?> suggestCategoryId(String merchantKey) async => null;
}

void main() {
  final micFinder = find.byKey(const ValueKey('voice-mic-button'));

  Widget buildSubject({
    required CapturingStartSpeechRecognitionUseCase speechService,
    required _FakeParseVoiceInputUseCase parseUseCase,
    required _FakeRateUseCase rateUseCase,
    required _CapturingCreateTransactionUseCase createUseCase,
  }) {
    final categoryRepository = _FakeCategoryRepository();
    final categoryService = CategoryService(
      categoryRepository: categoryRepository,
      ledgerConfigRepository: _FakeCategoryLedgerConfigRepository(),
    );
    return createLocalizedWidget(
      VoiceInputScreen(bookId: 'book-1', speechService: speechService),
      locale: const Locale('zh'),
      overrides: [
        categoryRepositoryProvider.overrideWithValue(categoryRepository),
        categoryServiceProvider.overrideWithValue(categoryService),
        parseVoiceInputUseCaseProvider.overrideWithValue(parseUseCase),
        appGetExchangeRateUseCaseProvider.overrideWithValue(rateUseCase),
        createTransactionUseCaseProvider.overrideWithValue(createUseCase),
        merchantCategoryLearningServiceProvider.overrideWith(
          (_) => MerchantCategoryLearningService(
            repository: _NoopMerchantPrefRepo(),
            categoryRepository: categoryRepository,
          ),
        ),
        voiceLocaleIdProvider.overrideWith((ref) async => 'zh-CN'),
      ],
    );
  }

  /// Drive the full commit: long-press → emitFinal → release.
  Future<void> commit(
    WidgetTester tester,
    CapturingStartSpeechRecognitionUseCase speech,
    String utterance,
  ) async {
    final gesture = await tester.startGesture(tester.getCenter(micFinder));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    speech.emitFinal(utterance);
    await tester.binding.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 350)),
    );
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final l10n = S.of(tester.element(find.byType(VoiceInputScreen)));
    await tester.tap(find.widgetWithText(InkWell, l10n.record).first);
    await tester.pumpAndSettle();
  }

  VoiceParseResult usdParse(String raw) => VoiceParseResult(
    rawText: raw,
    amount: 50, // whole units — 五十美元
    parsedDate: DateTime(2026, 5, 25),
    categoryMatch: const CategoryMatchResult(
      categoryId: 'cat_food_cafe',
      confidence: 0.9,
      source: MatchSource.keyword,
    ),
    ledgerType: LedgerType.daily,
    detectedCurrency: 'USD',
  );

  VoiceParseResult foreignParse(String raw, String currency, int amount) =>
      VoiceParseResult(
        rawText: raw,
        amount: amount,
        parsedDate: DateTime(2026, 5, 25),
        categoryMatch: const CategoryMatchResult(
          categoryId: 'cat_food_cafe',
          confidence: 0.9,
          source: MatchSource.keyword,
        ),
        ledgerType: LedgerType.daily,
        detectedCurrency: currency,
      );

  /// The headline currency pill (`AmountDisplay`) renders [currencyLabel] as a
  /// Text inside the `amount_currency_badge` container.
  Finder pillLabel(String code) => find.descendant(
    of: find.byKey(const ValueKey('amount_currency_badge')),
    matching: find.text(code),
  );

  testWidgets(
    'CR-01: spoken USD persists a COMPLETE triple with converted JPY amount',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const utterance = '五十美元 咖啡';
      final speech = CapturingStartSpeechRecognitionUseCase();
      final parse = _FakeParseVoiceInputUseCase({utterance: usdParse(utterance)});
      // Rate 150.00 → 50.00 USD (5000c) → 7500 JPY via the single-site convertToJpy.
      final rate = _FakeRateUseCase(
        RateFetched(
          rate: '150.00',
          currency: 'USD',
          rateDate: DateTime(2026, 5, 25),
          source: 'frankfurter',
        ),
      );
      final create = _CapturingCreateTransactionUseCase();

      await tester.pumpWidget(
        buildSubject(
          speechService: speech,
          parseUseCase: parse,
          rateUseCase: rate,
          createUseCase: create,
        ),
      );
      await tester.pumpAndSettle();

      await commit(tester, speech, utterance);

      // 260703 (2B): the conversion-undo snackbar floats over the bottom
      // action row right after the commit fill. Swipe it away (as a user
      // would) so the Save tap lands on the button, not on the snackbar.
      // Auto-dismiss itself is proven in voice_ptt_session_mixin_test; this
      // test's runAsync wall-clock dance arms the dismiss timer outside fake
      // time, so waiting cannot clear it here.
      if (tester.any(find.byType(SnackBar))) {
        await tester.drag(find.byType(SnackBar), const Offset(0, 120));
        await tester.pumpAndSettle();
      }

      await tapSave(tester);

      // The rate provider was consumed for the detected currency.
      expect(rate.lastParams?.currency, 'USD');

      final params = create.captured;
      expect(params, isNotNull, reason: 'foreign utterance must reach create()');

      final expectedJpy = convertToJpy(
        originalMinorUnits: 5000,
        appliedRate: '150.00',
        subunitToUnit: subunitToUnitFor('USD'),
      );
      expect(expectedJpy, 7500);
      expect(params!.amount, expectedJpy, reason: 'persisted JPY == convertToJpy');

      // COMPLETE triple — all three fields set together (no partial triple).
      expect(params.originalCurrency, 'USD');
      expect(params.originalAmount, 5000);
      expect(params.appliedRate, '150.00');
    },
  );

  testWidgets(
    'CR-01: RateUnavailable → JPY-native row (no partial triple)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const utterance = '五十美元 咖啡';
      final speech = CapturingStartSpeechRecognitionUseCase();
      final parse = _FakeParseVoiceInputUseCase({utterance: usdParse(utterance)});
      final rate = _FakeRateUseCase(RateUnavailable(currency: 'USD'));
      final create = _CapturingCreateTransactionUseCase();

      await tester.pumpWidget(
        buildSubject(
          speechService: speech,
          parseUseCase: parse,
          rateUseCase: rate,
          createUseCase: create,
        ),
      );
      await tester.pumpAndSettle();

      await commit(tester, speech, utterance);
      await tapSave(tester);

      final params = create.captured;
      expect(params, isNotNull);
      // No currency fields → JPY-native row; the spoken whole-unit amount (50)
      // persists as JPY. Never a partial triple.
      expect(params!.originalCurrency, isNull);
      expect(params.originalAmount, isNull);
      expect(params.appliedRate, isNull);
      expect(params.amount, 50);
    },
  );

  // ── Quick task 260614-goh: the headline currency pill must SWITCH to the
  // spoken currency. Previously AmountDisplay was rendered without a currency,
  // so the pill stayed "¥ JPY" even though the form state / saved row switched —
  // the user saw "货币没有切换". ─────────────────────────────────────────────
  testWidgets(
    '260614-goh: spoken USD switches the headline pill to USD',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const utterance = '今天吃饭用了99美元';
      final speech = CapturingStartSpeechRecognitionUseCase();
      final parse = _FakeParseVoiceInputUseCase({
        utterance: foreignParse(utterance, 'USD', 99),
      });
      final rate = _FakeRateUseCase(
        RateFetched(
          rate: '150.00',
          currency: 'USD',
          rateDate: DateTime(2026, 5, 25),
          source: 'frankfurter',
        ),
      );
      final create = _CapturingCreateTransactionUseCase();

      await tester.pumpWidget(
        buildSubject(
          speechService: speech,
          parseUseCase: parse,
          rateUseCase: rate,
          createUseCase: create,
        ),
      );
      await tester.pumpAndSettle();

      // Before speaking, the pill is the JPY default.
      expect(pillLabel('JPY'), findsOneWidget);

      await commit(tester, speech, utterance);

      // After a foreign utterance with a resolved rate, the pill shows USD.
      expect(pillLabel('USD'), findsOneWidget);
      expect(pillLabel('JPY'), findsNothing);
    },
  );

  testWidgets(
    '260614-goh: spoken 人民币 switches the headline pill to CNY',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const utterance = '购买手机用了9999人民币';
      final speech = CapturingStartSpeechRecognitionUseCase();
      final parse = _FakeParseVoiceInputUseCase({
        utterance: foreignParse(utterance, 'CNY', 9999),
      });
      final rate = _FakeRateUseCase(
        RateFetched(
          rate: '20.00',
          currency: 'CNY',
          rateDate: DateTime(2026, 5, 25),
          source: 'frankfurter',
        ),
      );
      final create = _CapturingCreateTransactionUseCase();

      await tester.pumpWidget(
        buildSubject(
          speechService: speech,
          parseUseCase: parse,
          rateUseCase: rate,
          createUseCase: create,
        ),
      );
      await tester.pumpAndSettle();

      await commit(tester, speech, utterance);

      expect(pillLabel('CNY'), findsOneWidget);
      expect(pillLabel('JPY'), findsNothing);
    },
  );

  testWidgets(
    '260614-goh: RateUnavailable keeps the pill JPY (matches JPY-native save)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const utterance = '五十美元 咖啡';
      final speech = CapturingStartSpeechRecognitionUseCase();
      final parse = _FakeParseVoiceInputUseCase({utterance: usdParse(utterance)});
      final rate = _FakeRateUseCase(RateUnavailable(currency: 'USD'));
      final create = _CapturingCreateTransactionUseCase();

      await tester.pumpWidget(
        buildSubject(
          speechService: speech,
          parseUseCase: parse,
          rateUseCase: rate,
          createUseCase: create,
        ),
      );
      await tester.pumpAndSettle();

      await commit(tester, speech, utterance);

      // No rate → the row stays JPY-native on save, so the pill must stay JPY
      // (no silent USD-pill / JPY-save mismatch).
      expect(pillLabel('JPY'), findsOneWidget);
      expect(pillLabel('USD'), findsNothing);
    },
  );
}
