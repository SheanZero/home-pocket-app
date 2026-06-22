// Unit test for VoicePttSessionMixin (quick task 260622-nhs Task 1).
//
// Drives the extracted recording-session mixin against a minimal fake host that
// wires the three voice mixins + an embedded TransactionDetailsForm, with an
// injected CapturingStartSpeechRecognitionUseCase. Asserts:
//   - a batch-fill on release produces the expected form setter results
//     (amount / category / merchant / date), and
//   - a detected-foreign-currency utterance routes through the foreign-triple
//     push (originalCurrency persisted on the form).
//
// The mixin is the SAME code the legacy voice screen now hosts, so this is the
// reuse-not-rewrite contract (D-3 / D-4) at the unit level.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/currency/get_exchange_rate_use_case.dart';
import 'package:home_pocket/application/currency/rate_result.dart';
import 'package:home_pocket/application/currency/repository_providers.dart'
    show appGetExchangeRateUseCaseProvider;
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_details_form_config.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_locale_readiness_mixin.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_ptt_session_mixin.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../../helpers/test_localizations.dart';

class CapturingSpeechService implements StartSpeechRecognitionUseCase {
  void Function(String status)? onStatus;
  void Function(String errorMsg, bool permanent)? onError;
  void Function(SpeechRecognitionResult result)? onResult;
  void Function(double normalizedLevel)? onSoundLevel;
  String? startedLocaleId;
  var stopped = false;
  var canceled = false;
  var startCount = 0;

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
    startCount++;
  }

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> cancel() async => canceled = true;

  void emitFinal(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.95)], true),
  );

  /// Simulate the platform recognizer self-terminating (30s/3s timeout) so the
  /// continuous tap-session must re-arm to keep listening.
  void emitTerminalStatus() => onStatus!('done');
}

class FakeParseVoiceInputUseCase implements ParseVoiceInputUseCase {
  FakeParseVoiceInputUseCase(this.results);
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

class FakeGetExchangeRateUseCase implements GetExchangeRateUseCase {
  FakeGetExchangeRateUseCase(this.rate);
  final String rate;

  @override
  Future<RateResultWithSignal> execute(GetExchangeRateParams params) async {
    return RateResultWithSignal(
      result: RateFetched(
        rate: rate,
        currency: params.currency,
        rateDate: params.date,
        source: 'test',
      ),
    );
  }
}

class FakeCategoryLedgerConfigRepository
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

class FakeCategoryRepository implements CategoryRepository {
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

/// Minimal host that wires the three voice mixins + an embedded form, exposing
/// the session methods so the test can drive them directly.
class _MixinHost extends ConsumerStatefulWidget {
  const _MixinHost({required this.speechService});
  final StartSpeechRecognitionUseCase speechService;

  @override
  ConsumerState<_MixinHost> createState() => _MixinHostState();
}

class _MixinHostState extends ConsumerState<_MixinHost>
    with
        VoiceRecognitionEventHandlerMixin,
        VoiceLocaleReadinessMixin,
        VoicePttSessionMixin {
  final _formKey = GlobalKey<TransactionDetailsFormState>();
  String _voiceLocaleId = 'ja-JP';
  var committed = false;

  @override
  TransactionDetailsFormState? get pttFormState => _formKey.currentState;
  @override
  StartSpeechRecognitionUseCase? get pttInjectedSpeechService =>
      widget.speechService;
  @override
  String get pttVoiceLocaleId => _voiceLocaleId;
  @override
  void onPttSessionChanged(VoidCallback apply) {
    if (mounted) setState(apply);
  }

  @override
  void onPttCommitted() => committed = true;

  @override
  void onVoiceLocaleResolved(String localeId) => _voiceLocaleId = localeId;

  @override
  void initState() {
    super.initState();
    initPttSpeechService();
    initLocaleReadiness();
  }

  @override
  void dispose() {
    disposePttSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: TransactionDetailsForm(
          key: _formKey,
          config: TransactionDetailsFormConfig.$new(
            bookId: 'book-1',
            entrySource: EntrySource.voice,
          ),
        ),
      ),
    );
  }
}

void main() {
  Widget buildHost({
    required CapturingSpeechService speechService,
    required FakeParseVoiceInputUseCase parseUseCase,
    String rate = '150.0',
  }) {
    final categoryRepository = FakeCategoryRepository();
    final categoryService = CategoryService(
      categoryRepository: categoryRepository,
      ledgerConfigRepository: FakeCategoryLedgerConfigRepository(),
    );
    return createLocalizedWidget(
      _MixinHost(speechService: speechService),
      locale: const Locale('ja'),
      overrides: [
        categoryRepositoryProvider.overrideWithValue(categoryRepository),
        categoryServiceProvider.overrideWithValue(categoryService),
        parseVoiceInputUseCaseProvider.overrideWithValue(parseUseCase),
        appGetExchangeRateUseCaseProvider.overrideWithValue(
          FakeGetExchangeRateUseCase(rate),
        ),
        voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
      ],
    );
  }

  _MixinHostState hostOf(WidgetTester tester) =>
      tester.state<_MixinHostState>(find.byType(_MixinHost));

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'batch-fill on release fills amount/category/merchant/date into the form',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '1千8百4十元 星巴克': VoiceParseResult(
          rawText: '1千8百4十元 星巴克',
          amount: 1840,
          parsedDate: DateTime(2026, 4, 27),
          merchantName: '星巴克',
          categoryMatch: const CategoryMatchResult(
            categoryId: 'cat_food_cafe',
            confidence: 0.91,
            source: MatchSource.keyword,
          ),
          ledgerType: LedgerType.daily,
        ),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.onPttHoldStart();
      await tester.pump();
      speech.emitFinal('1千8百4十元 星巴克');
      await tester.pump();
      // Hold past the 300 ms misfire threshold (wall-clock).
      await tester.binding.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 350)),
      );
      host.onPttHoldEnd();
      await tester.pumpAndSettle();

      expect(parse.inputs, contains('1千8百4十元 星巴克'));
      expect(speech.stopped, isTrue);
      expect(speech.canceled, isFalse);
      expect(host.committed, isTrue,
          reason: 'onPttCommitted must fire after a successful batch-fill');

      // The form received the batch-fill — assert via the rendered merchant
      // TextField and category chip.
      expect(find.text('星巴克'), findsOneWidget);
      expect(find.textContaining('Cafe'), findsOneWidget);
    },
  );

  testWidgets(
    'misfire (<300ms) discards via cancel — no parse, no commit',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase(const {});

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.onPttHoldStart();
      await tester.pump();
      host.onPttHoldEnd(); // released immediately — under 300 ms
      await tester.pumpAndSettle();

      expect(speech.canceled, isTrue);
      expect(speech.stopped, isFalse);
      expect(parse.inputs, isEmpty);
      expect(host.committed, isFalse);
    },
  );

  testWidgets(
    'detected-foreign-currency utterance pushes the foreign triple',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '拿铁 十美金': VoiceParseResult(
          rawText: '拿铁 十美金',
          amount: 10,
          parsedDate: DateTime(2026, 4, 27),
          merchantName: null,
          categoryMatch: const CategoryMatchResult(
            categoryId: 'cat_food_cafe',
            confidence: 0.9,
            source: MatchSource.keyword,
          ),
          ledgerType: LedgerType.daily,
          detectedCurrency: 'USD',
        ),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse, rate: '150.0'),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.onPttHoldStart();
      await tester.pump();
      speech.emitFinal('拿铁 十美金');
      await tester.pump();
      await tester.binding.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 350)),
      );
      host.onPttHoldEnd();
      await tester.pumpAndSettle();

      // The display currency only switches to USD when pushVoiceForeignTriple
      // returns true — i.e. the COMPLETE triple (originalCurrency/amount/rate)
      // was pushed into the form. JPY-native or RateUnavailable keep 'JPY'.
      expect(host.pttDisplayCurrency, 'USD',
          reason: 'a resolved foreign rate pushes the triple and switches '
              'the display currency to USD');
    },
  );

  // ── R2 tap-modal / continuous auto-fill ──────────────────────────────────

  testWidgets(
    'R2: tap-session auto-fills the form on each speech-final (no exit needed)',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '1千8百4十元 星巴克': VoiceParseResult(
          rawText: '1千8百4十元 星巴克',
          amount: 1840,
          parsedDate: DateTime(2026, 4, 27),
          merchantName: '星巴克',
          categoryMatch: const CategoryMatchResult(
            categoryId: 'cat_food_cafe',
            confidence: 0.91,
            source: MatchSource.keyword,
          ),
          ledgerType: LedgerType.daily,
        ),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();
      expect(host.pttIsRecording, isTrue);

      // A speech-final result AUTO-fills the form — no exit / release needed.
      speech.emitFinal('1千8百4十元 星巴克');
      await tester.pumpAndSettle();

      expect(parse.inputs, contains('1千8百4十元 星巴克'));
      expect(host.committed, isTrue,
          reason: 'an auto-fill fires onPttCommitted');
      expect(host.pttIsRecording, isTrue,
          reason: 'the session keeps listening after an auto-fill');
      expect(find.text('星巴克'), findsOneWidget);
      expect(find.textContaining('Cafe'), findsOneWidget);
    },
  );

  testWidgets(
    'R2: a terminal recognizer status re-arms listening while the session is open',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase(const {});

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();
      speech.startedLocaleId = null; // simulate the platform stopping

      speech.emitTerminalStatus();
      await tester.pumpAndSettle();

      expect(host.pttIsRecording, isTrue,
          reason: 're-arm must keep the session open, not end it');
      expect(speech.startedLocaleId, isNotNull,
          reason: 'startListening was called again to keep listening');
    },
  );

  testWidgets(
    'R3: restartPttListening re-arms after the recognizer self-terminated '
    '(reset keeps listening)',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase(const {});

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();
      expect(host.pttIsRecording, isTrue);

      // Simulate the platform recognizer having self-terminated WITHOUT a
      // re-arm yet (e.g. between cycles): it is no longer listening.
      speech.stopped = true;
      speech.startedLocaleId = null;
      expect(speech.isListening, isFalse);

      // R3 BUG 2: a reset must GUARANTEE listening resumes — restartPttListening
      // is idempotent and re-arms only because the session is still active and
      // the recognizer is not currently listening.
      await host.restartPttListening();
      await tester.pumpAndSettle();

      expect(host.pttIsRecording, isTrue,
          reason: 'the session stays active after restart');
      expect(speech.isListening, isTrue,
          reason: 'restartPttListening re-armed startListening');
    },
  );

  testWidgets(
    'R3: restartPttListening is idempotent — no double-start while listening',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase(const {});

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();
      expect(speech.isListening, isTrue);

      // Already listening — a restart must be a no-op (idempotent guard).
      speech.startCount = 0;
      await host.restartPttListening();
      await tester.pumpAndSettle();

      expect(speech.startCount, 0,
          reason: 'restart must not re-call startListening while listening');
    },
  );

  testWidgets(
    'R3: restartPttListening does nothing once the session ended',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase(const {});

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();
      await host.exitPttTapSession();
      await tester.pumpAndSettle();
      expect(host.pttIsRecording, isFalse);

      speech.startCount = 0;
      await host.restartPttListening();
      await tester.pumpAndSettle();

      expect(speech.startCount, 0,
          reason: 'a closed session must not be re-armed');
      expect(host.pttIsRecording, isFalse);
    },
  );

  testWidgets(
    'R2: exitPttTapSession stops the recognizer and ends the session',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        'ラテ 1千': VoiceParseResult(
          rawText: 'ラテ 1千',
          amount: 1000,
          parsedDate: DateTime(2026, 4, 27),
          merchantName: 'スタバ',
          categoryMatch: const CategoryMatchResult(
            categoryId: 'cat_food_cafe',
            confidence: 0.9,
            source: MatchSource.keyword,
          ),
          ledgerType: LedgerType.daily,
        ),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();
      speech.emitFinal('ラテ 1千');
      await tester.pumpAndSettle();

      await host.exitPttTapSession();
      await tester.pumpAndSettle();

      expect(speech.stopped, isTrue);
      expect(host.pttIsRecording, isFalse,
          reason: 'exit ends the session');
      // Filled content is retained (D-2 fill-and-stay).
      expect(find.text('スタバ'), findsOneWidget);
    },
  );
}
