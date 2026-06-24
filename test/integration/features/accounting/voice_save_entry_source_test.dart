/// SC-2 integration test: VoiceInputScreen save path stamps entry_source='voice'.
///
/// Uses a real AppDatabase.forTesting() + real CreateTransactionUseCase to prove
/// the schema v17 CHECK constraint accepts 'voice' through the actual UI save path.
///
/// Mirrors manual_save_entry_source_test.dart (Phase 19 SC-4 analog) but swaps:
///   - subject screen     : ManualOneStepScreen → VoiceInputScreen
///   - interaction        : keypad taps → hold-to-record gesture + transcript emit
///   - additional overrides: parseVoiceInputUseCaseProvider + voiceLocaleIdProvider
///   - amount assertion   : type-safe AmountDisplay widget read (H-5) instead of
///                          find.text('500') which is coupled to JPY rendering chrome.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/application/dual_ledger/classification_service.dart';
import 'package:home_pocket/application/dual_ledger/rule_engine.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        categoryRepositoryProvider,
        createTransactionUseCaseProvider,
        merchantCategoryLearningServiceProvider,
        parseVoiceInputUseCaseProvider;
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart'
    show voiceLocaleIdProvider;
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart'
    show appDatabaseProvider;
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../helpers/test_localizations.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockMerchantCategoryLearningService extends Mock
    implements MerchantCategoryLearningService {}

class _FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

/// Fake speech recognition use case that captures wiring callbacks so the
/// test can drive transcript emission deterministically. Mirrors
/// `CapturingStartSpeechRecognitionUseCase` from voice_input_screen_test.dart.
class _CapturingSpeechService implements StartSpeechRecognitionUseCase {
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
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> cancel() async {
    canceled = true;
  }

  /// Emit a final transcript through the captured onResult callback.
  void emitFinal(String words) => onResult!(
        SpeechRecognitionResult(
          [SpeechRecognitionWords(words, null, 0.95)],
          true,
        ),
      );
}

/// Fake parser that returns a pre-seeded VoiceParseResult for each input.
/// Mirrors `FakeParseVoiceInputUseCase` from voice_input_screen_test.dart.
class _FakeParseVoiceInputUseCase implements ParseVoiceInputUseCase {
  _FakeParseVoiceInputUseCase(this.results);

  final Map<String, VoiceParseResult> results;
  final inputs = <String>[];

  @override
  Future<Result<VoiceParseResult>> execute(
    String recognizedText, {
    String? localeId,
  }) async {
    inputs.add(recognizedText);
    return Result.success(results[recognizedText]);
  }
}

// Shared test category fixtures (mirror manual_save_entry_source_test.dart)
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
  id: 'cat_food_cafe',
  name: 'Cafe',
  icon: 'local_cafe',
  color: '#47B88A',
  parentId: 'cat_food',
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
  late _CapturingSpeechService speechService;
  late _FakeParseVoiceInputUseCase parseUseCase;

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
    speechService = _CapturingSpeechService();

    // Category repo: return the test categories (parent + L2) by id
    when(() => categoryRepository.findById(_category.id))
        .thenAnswer((_) async => _category);
    when(() => categoryRepository.findById(_parentCategory.id))
        .thenAnswer((_) async => _parentCategory);
    when(() => categoryRepository.findById(any()))
        .thenAnswer((_) async => _category);
    when(() => categoryRepository.findActive())
        .thenAnswer((_) async => [_parentCategory, _category]);
    when(() => categoryRepository.findAll())
        .thenAnswer((_) async => [_parentCategory, _category]);

    // Device identity
    when(() => deviceIdentityRepository.getDeviceId())
        .thenAnswer((_) async => 'device-local');

    // Encryption: pass-through (no real crypto in test)
    when(() => encryptionService.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => encryptionService.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );

    // Merchant learning: no-op (behavior tested separately)
    when(
      () => learningService.recordSelection(
        merchantRaw: any(named: 'merchantRaw'),
        selectedCategoryId: any(named: 'selectedCategoryId'),
      ),
    ).thenAnswer((_) async {});

    // Voice parser fake: emit a daily result with amount=500, cafe category.
    // The screen's _stopRecordingAndCommit consumes data.amount and
    // data.categoryMatch.categoryId to batch-fill the embedded form.
    final parsedResult = VoiceParseResult(
      rawText: 'スターバックスで500円',
      amount: 500,
      parsedDate: DateTime.utc(2026, 5, 25),
      merchantName: 'スターバックス',
      categoryMatch: CategoryMatchResult(
        categoryId: _category.id,
        confidence: 0.95,
        source: MatchSource.merchant,
      ),
      ledgerType: LedgerType.daily,
    );
    parseUseCase = _FakeParseVoiceInputUseCase({
      'スターバックスで500円': parsedResult,
    });

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

  testWidgets(
    'SC-2 INPUT-02: VoiceInputScreen save stamps entry_source=voice in Drift row',
    (tester) async {
      // Use a tall surface so the mic button + Save button both lay out on screen.
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createLocalizedWidget(
          VoiceInputScreen(
            bookId: 'book-1',
            speechService: speechService,
          ),
          locale: const Locale('ja'),
          overrides: [
            // Real in-memory DB — any provider chaining into appDatabaseProvider
            // (e.g. settings → locale) must resolve without StateError.
            appDatabaseProvider.overrideWithValue(db),
            categoryRepositoryProvider.overrideWithValue(categoryRepository),
            createTransactionUseCaseProvider.overrideWithValue(useCase),
            merchantCategoryLearningServiceProvider
                .overrideWithValue(learningService),
            parseVoiceInputUseCaseProvider.overrideWithValue(parseUseCase),
            voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 1. Hold-to-record: press-down on mic > emit final > hold > 300 ms > release.
      // The 300 ms misfire threshold (D-03) lives in _onLongPressEnd; a release
      // shorter than that routes to _cancelRecordingAndDiscard and never commits.
      final micFinder = find.byKey(const ValueKey('voice-mic-button'));
      expect(micFinder, findsOneWidget,
          reason: 'Mic button with stable ValueKey must be present');
      final gesture = await tester.startGesture(tester.getCenter(micFinder));
      // Allow _onLongPressStart → _startRecording's setState (_isRecording=true)
      // to settle.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      // Recognizer emits the fake transcript that the parser fake maps to a
      // VoiceParseResult with amount=500, merchant=Starbucks, category=cafe.
      speechService.emitFinal('スターバックスで500円');
      // Drain the partial-parse + merger feedChunk microtasks.
      await tester.pump();
      // The misfire threshold uses DateTime.now() (wall clock), NOT fake-async
      // elapsed time, so tester.pump(Duration(...)) inside the fake-async zone
      // does NOT satisfy the gate. tester.runAsync runs the callback in a real
      // (non-fake) async zone so the actual wall clock advances ≥ 350 ms.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      });
      await gesture.up();
      // _stopRecordingAndCommit chains 3 awaits: speechService.stop →
      // parseUseCase.execute → categoryRepository.findById x 2. pumpAndSettle
      // drains microtasks but multiple pump cycles guarantee the chain runs.
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();

      // Sanity check: the commit path (NOT the cancel path) was taken — the
      // parser was invoked, the speech service was stopped (not canceled), and
      // _stopRecordingAndCommit's batch-fill block ran end to end.
      expect(parseUseCase.inputs, contains('スターバックスで500円'),
          reason: '_stopRecordingAndCommit must invoke parseUseCase.execute');
      expect(speechService.stopped, isTrue,
          reason: 'Commit path calls speechService.stop()');
      expect(speechService.canceled, isFalse,
          reason: 'Commit path must NOT route through speechService.cancel()');

      // 2. Assert form was filled. H-5: type-safe AmountDisplay widget read,
      //    NOT find.text('500') — the literal-text finder is coupled to JPY
      //    rendering chrome (¥500 / 500円 / comma-formatting) and breaks if
      //    rendering format ever changes. Reading the widget property is
      //    rendering-agnostic.
      final amountDisplay =
          tester.widget<AmountDisplay>(find.byType(AmountDisplay));
      expect(amountDisplay.amount, '500',
          reason: 'Voice batch-fill should populate AmountDisplay.amount to "500"');

      // 3. Tap Save (full-width gradient CTA below the mic + caption).
      final saveFinder = find.byKey(const ValueKey('voice-save-button'));
      expect(saveFinder, findsOneWidget,
          reason: 'Save button with stable ValueKey must be present');
      await tester.tap(saveFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // 4. Direct DAO query bypasses the repository encryption wrapper to
      //    confirm the v17 schema CHECK constraint accepted the literal 'voice'.
      //    Phase 17 D-06 + Phase 18 D-08 added 'voice' to the CHECK allowlist;
      //    if a future migration regresses, this assertion fails loudly with a
      //    constraint-violation error before this line.
      final rows = await transactionDao.findByBookId('book-1');
      expect(rows.length, 1,
          reason: 'Exactly one transaction should be saved');
      expect(rows.first.entrySource, 'voice',
          reason: 'entry_source must equal the literal string "voice"');
      expect(rows.first.amount, 500);
    },
  );
}
