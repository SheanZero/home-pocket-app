/// D-16 voice regression test: VoiceInputScreen → ManualOneStepScreen push
/// preserves EntrySource.voice through the save path to the DB.
///
/// Verifies:
///   1. After voice recognition, ManualOneStepScreen is pushed with entrySource=voice.
///   2. All voice params (amount, category, merchant, voiceKeyword) arrive in
///      ManualOneStepScreen unchanged.
///   3. Saving the voice-pushed screen stamps entry_source='voice' in the real DB.
///   4. Soul celebration overlay appears for soul-ledger voice saves (Phase 18 D-15).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/application/dual_ledger/classification_service.dart';
import 'package:home_pocket/application/dual_ledger/rule_engine.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/application/voice/voice_satisfaction_estimator.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        categoryRepositoryProvider,
        categoryServiceProvider,
        createTransactionUseCaseProvider,
        merchantCategoryLearningServiceProvider,
        parseVoiceInputUseCaseProvider,
        voiceSatisfactionEstimatorProvider;
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';
import 'package:home_pocket/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart'
    show appDatabaseProvider;
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes / Mocks ──────────────────────────────────────────────────────────────

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockMerchantCategoryLearningService extends Mock
    implements MerchantCategoryLearningService {}

class _MockCategoryService extends Mock implements CategoryService {}

class _FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

// Port of CapturingStartSpeechRecognitionUseCase from voice_input_screen_test.dart
class _CapturingStartSpeechRecognitionUseCase
    implements StartSpeechRecognitionUseCase {
  void Function(String status)? onStatus;
  void Function(String errorMsg, bool permanent)? onError;
  void Function(SpeechRecognitionResult result)? onResult;
  void Function(double normalizedLevel)? onSoundLevel;
  String? startedLocaleId;
  var stopped = false;
  var canceled = false;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async {
    this.onStatus = onStatus;
    this.onError = onError;
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
  }) async {
    this.onResult = onResult;
    this.onSoundLevel = onSoundLevel;
    startedLocaleId = localeId;
    stopped = false;
  }

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> cancel() async => canceled = true;

  void emitFinal(String words) => onResult!(
    SpeechRecognitionResult(
      [SpeechRecognitionWords(words, null, 0.95)],
      true,
    ),
  );
}

class _FakeVoiceSatisfactionEstimator implements VoiceSatisfactionEstimator {
  @override
  int estimate({
    required VoiceAudioFeatures audioFeatures,
    required String recognizedText,
  }) => 8;
}

// ── Test fixtures ──────────────────────────────────────────────────────────────

final _parentCategory = Category(
  id: 'cat_food',
  name: 'Food',
  icon: 'restaurant',
  color: '#47B88A',
  level: 1,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime.utc(2026, 1),
);

final _category = Category(
  id: 'cat_food_dining',
  name: 'Dining',
  icon: 'restaurant_menu',
  color: '#47B88A',
  parentId: 'cat_food',
  level: 2,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime.utc(2026, 1),
);

// Soul category for TEST 4 (celebration regression)
final _soulParentCategory = Category(
  id: 'cat_hobbies',
  name: 'Hobbies',
  icon: 'sports_esports',
  color: '#A855F7',
  level: 1,
  isSystem: true,
  sortOrder: 2,
  createdAt: DateTime.utc(2026, 1),
);

final _soulCategory = Category(
  id: 'cat_hobbies_games',
  name: 'Games',
  icon: 'sports_esports',
  color: '#A855F7',
  parentId: 'cat_hobbies',
  level: 2,
  isSystem: true,
  sortOrder: 1,
  createdAt: DateTime.utc(2026, 1),
);

void main() {
  late AppDatabase db;
  late TransactionDao transactionDao;
  late CreateTransactionUseCase useCase;
  late _MockCategoryRepository categoryRepository;
  late _MockDeviceIdentityRepository deviceIdentityRepository;
  late _MockFieldEncryptionService encryptionService;
  late _MockMerchantCategoryLearningService learningService;

  setUpAll(() {
    registerFallbackValue(_FakeCreateTransactionParams());
  });

  setUp(() {
    db = AppDatabase.forTesting();
    transactionDao = TransactionDao(db);
    categoryRepository = _MockCategoryRepository();
    deviceIdentityRepository = _MockDeviceIdentityRepository();
    encryptionService = _MockFieldEncryptionService();
    learningService = _MockMerchantCategoryLearningService();

    // Category repo stubs
    when(() => categoryRepository.findById(_category.id))
        .thenAnswer((_) async => _category);
    when(() => categoryRepository.findById(_parentCategory.id))
        .thenAnswer((_) async => _parentCategory);
    when(() => categoryRepository.findById(_soulCategory.id))
        .thenAnswer((_) async => _soulCategory);
    when(() => categoryRepository.findById(_soulParentCategory.id))
        .thenAnswer((_) async => _soulParentCategory);
    when(() => categoryRepository.findById(any()))
        .thenAnswer((_) async => _category);
    when(() => categoryRepository.findActive())
        .thenAnswer((_) async => [_parentCategory, _category]);
    when(() => categoryRepository.findAll())
        .thenAnswer((_) async => [_parentCategory, _category]);

    // Device identity
    when(() => deviceIdentityRepository.getDeviceId())
        .thenAnswer((_) async => 'device-local');

    // Encryption: pass-through
    when(() => encryptionService.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => encryptionService.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );

    // Merchant learning: no-op
    when(
      () => learningService.recordSelection(
        merchantRaw: any(named: 'merchantRaw'),
        selectedCategoryId: any(named: 'selectedCategoryId'),
      ),
    ).thenAnswer((_) async {});

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

  /// Helper: pump VoiceInputScreen, emit voice result, tap Next to push
  /// ManualOneStepScreen, then return the capturing speech use case for
  /// further interaction.
  Future<_CapturingStartSpeechRecognitionUseCase> pumpAndNavigate(
    WidgetTester tester, {
    required VoiceParseResult parseResult,
    required String rawText,
    CategoryService? categoryService,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final speechService = _CapturingStartSpeechRecognitionUseCase();
    final parseUseCase = _FakeParseVoiceInputUseCase({rawText: parseResult});

    await tester.pumpWidget(
      createLocalizedWidget(
        VoiceInputScreen(bookId: 'book-1', speechService: speechService),
        locale: const Locale('en'),
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
          createTransactionUseCaseProvider.overrideWithValue(useCase),
          merchantCategoryLearningServiceProvider.overrideWithValue(
            learningService,
          ),
          if (categoryService != null)
            categoryServiceProvider.overrideWithValue(categoryService),
          parseVoiceInputUseCaseProvider.overrideWithValue(parseUseCase),
          voiceSatisfactionEstimatorProvider.overrideWithValue(
            _FakeVoiceSatisfactionEstimator(),
          ),
          voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
        ],
      ),
    );

    await tester.pumpAndSettle();

    // Start recording
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();

    // Emit final voice result
    speechService.emitFinal(rawText);
    await tester.pumpAndSettle();

    // Tap the 'Next' button to navigate to ManualOneStepScreen
    final nextFinder = find.text('Next');
    expect(nextFinder, findsOneWidget,
        reason: 'Next button must be visible after voice recognition completes');
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    return speechService;
  }

  testWidgets(
      'TEST 1 (D-16): voice push lands on ManualOneStepScreen with entrySource=voice',
      (tester) async {
    final parseResult = VoiceParseResult(
      rawText: 'Cafe 1200 yen',
      amount: 1200,
      parsedDate: DateTime(2026, 4, 27),
      merchantName: 'Cafe',
      categoryMatch: CategoryMatchResult(
        categoryId: _category.id,
        confidence: 0.91,
        source: MatchSource.keyword,
      ),
      ledgerType: LedgerType.survival,
    );

    await pumpAndNavigate(
      tester,
      parseResult: parseResult,
      rawText: 'Cafe 1200 yen',
    );

    // D-16: ManualOneStepScreen must be the push target (NOT TransactionConfirmScreen)
    expect(
      find.byType(ManualOneStepScreen),
      findsOneWidget,
      reason: 'VoiceInputScreen must push ManualOneStepScreen (D-16 regression)',
    );

    // Inspect the widget to confirm entrySource
    final screen = tester.widget<ManualOneStepScreen>(
      find.byType(ManualOneStepScreen),
    );
    expect(
      screen.entrySource,
      EntrySource.voice,
      reason: 'entrySource must be voice on voice-pushed screen',
    );

    // Tap 'Record' in the SmartKeyboard to save
    final recordFinder = find.descendant(
      of: find.byType(SmartKeyboard),
      matching: find.text('Record'),
    );
    expect(recordFinder, findsOneWidget,
        reason: 'SmartKeyboard Record button must be visible on ManualOneStepScreen');
    await tester.tap(recordFinder);
    await tester.pumpAndSettle();

    // Assert DB: entry_source = 'voice'
    final rows = await transactionDao.findByBookId('book-1');
    expect(rows, isNotEmpty, reason: 'Save should create a DB row');
    expect(
      rows.first.entrySource,
      'voice',
      reason: 'entry_source must equal "voice" end-to-end through voice push',
    );
    expect(rows.first.amount, 1200,
        reason: 'Amount should equal the voice-parsed 1200');
  });

  testWidgets(
      'TEST 2 (param names): voice params arrive in ManualOneStepScreen unchanged',
      (tester) async {
    final parseResult = VoiceParseResult(
      rawText: 'Starbucks 800 yen',
      amount: 800,
      parsedDate: DateTime(2026, 5, 1),
      merchantName: 'Starbucks',
      categoryMatch: CategoryMatchResult(
        categoryId: _category.id,
        confidence: 0.88,
        source: MatchSource.keyword,
      ),
      ledgerType: LedgerType.survival,
    );

    await pumpAndNavigate(
      tester,
      parseResult: parseResult,
      rawText: 'Starbucks 800 yen',
    );

    expect(find.byType(ManualOneStepScreen), findsOneWidget);

    final screen = tester.widget<ManualOneStepScreen>(
      find.byType(ManualOneStepScreen),
    );

    // Verify key voice params arrived with correct param names (D-16 regression)
    expect(screen.initialAmount, 800,
        reason: 'amount→initialAmount rename must carry data');
    expect(screen.initialCategory?.id, _category.id,
        reason: 'category→initialCategory rename must carry data');
    expect(screen.initialMerchant, 'Starbucks',
        reason: 'merchantName must be wired to initialMerchant');
    expect(screen.entrySource, EntrySource.voice,
        reason: 'entrySource must be voice');
  });

  testWidgets(
      'TEST 3 (soul celebration D-15): soul voice save stamps entry_source=voice',
      (tester) async {
    // Wire soul category for this test
    when(() => categoryRepository.findById(_soulCategory.id))
        .thenAnswer((_) async => _soulCategory);
    when(() => categoryRepository.findById(_soulParentCategory.id))
        .thenAnswer((_) async => _soulParentCategory);
    when(() => categoryRepository.findActive())
        .thenAnswer((_) async =>
            [_parentCategory, _category, _soulParentCategory, _soulCategory]);

    // Use a mock CategoryService that resolves soul category → LedgerType.soul
    final mockCategoryService = _MockCategoryService();
    when(() => mockCategoryService.resolveLedgerType(any()))
        .thenAnswer((_) async => LedgerType.soul);

    final soulParseResult = VoiceParseResult(
      rawText: 'Games 5000 yen',
      amount: 5000,
      parsedDate: DateTime(2026, 5, 1),
      merchantName: null,
      categoryMatch: CategoryMatchResult(
        categoryId: _soulCategory.id,
        confidence: 0.90,
        source: MatchSource.keyword,
      ),
      ledgerType: LedgerType.soul,
      estimatedSatisfaction: 8,
    );

    await pumpAndNavigate(
      tester,
      parseResult: soulParseResult,
      rawText: 'Games 5000 yen',
      categoryService: mockCategoryService,
    );

    expect(find.byType(ManualOneStepScreen), findsOneWidget);

    final screen = tester.widget<ManualOneStepScreen>(
      find.byType(ManualOneStepScreen),
    );
    expect(screen.entrySource, EntrySource.voice);

    // Tap Record to save the soul transaction
    final recordFinder = find.descendant(
      of: find.byType(SmartKeyboard),
      matching: find.text('Record'),
    );
    expect(recordFinder, findsOneWidget,
        reason: 'SmartKeyboard Record button must be visible for soul voice save');
    await tester.tap(recordFinder);
    await tester.pumpAndSettle();

    // Assert DB row
    final rows = await transactionDao.findByBookId('book-1');
    expect(rows, isNotEmpty);
    expect(rows.first.entrySource, 'voice',
        reason: 'Soul voice save must also stamp entry_source=voice');
    expect(rows.first.ledgerType, 'soul',
        reason: 'Ledger type must be soul');
  });

  testWidgets(
      'TEST 4 (D-15): SoulCelebrationOverlay appears after soul voice save',
      (tester) async {
    // Wire soul category for this test
    when(() => categoryRepository.findById(_soulCategory.id))
        .thenAnswer((_) async => _soulCategory);
    when(() => categoryRepository.findById(_soulParentCategory.id))
        .thenAnswer((_) async => _soulParentCategory);
    when(() => categoryRepository.findActive()).thenAnswer((_) async =>
        [_parentCategory, _category, _soulParentCategory, _soulCategory]);

    // CategoryService returns soul for soul category
    final mockCategoryService = _MockCategoryService();
    when(() => mockCategoryService.resolveLedgerType(any()))
        .thenAnswer((_) async => LedgerType.soul);

    final soulParseResult = VoiceParseResult(
      rawText: 'Games 5000 yen celebration',
      amount: 5000,
      parsedDate: DateTime(2026, 5, 10),
      merchantName: null,
      categoryMatch: CategoryMatchResult(
        categoryId: _soulCategory.id,
        confidence: 0.92,
        source: MatchSource.keyword,
      ),
      ledgerType: LedgerType.soul,
      estimatedSatisfaction: 9,
    );

    await pumpAndNavigate(
      tester,
      parseResult: soulParseResult,
      rawText: 'Games 5000 yen celebration',
      categoryService: mockCategoryService,
    );

    expect(find.byType(ManualOneStepScreen), findsOneWidget);

    // Tap Record to trigger soul save and D-15 celebration overlay
    final recordFinder = find.descendant(
      of: find.byType(SmartKeyboard),
      matching: find.text('Record'),
    );
    expect(recordFinder, findsOneWidget,
        reason: 'SmartKeyboard Record button must be visible for soul celebration test');
    await tester.tap(recordFinder);
    await tester.pump(); // trigger post-save setState(_showCelebration = true)

    // D-15: SoulCelebrationOverlay must appear in the widget tree after soul save
    expect(
      find.byType(SoulCelebrationOverlay),
      findsOneWidget,
      reason:
          'TEST 4 (D-15): SoulCelebrationOverlay must appear after soul voice save',
    );
  });
}

// ── Private FakeParseVoiceInputUseCase ─────────────────────────────────────────

class _FakeParseVoiceInputUseCase implements ParseVoiceInputUseCase {
  _FakeParseVoiceInputUseCase(this.results);

  final Map<String, VoiceParseResult> results;

  @override
  Future<Result<VoiceParseResult>> execute(String recognizedText) async {
    final r = results[recognizedText];
    return r != null ? Result.success(r) : Result.error('no result for: $recognizedText');
  }
}
