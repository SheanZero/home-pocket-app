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
import 'package:home_pocket/features/currency/domain/models/rate_result.dart';
import 'package:home_pocket/application/currency/repository_providers.dart'
    show appGetExchangeRateUseCaseProvider;
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_details_form_config.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
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
  var initializeCount = 0;

  /// quick-260706-kax (belt-and-braces): field-backed availability so a test
  /// can simulate the platform flipping the recognizer unavailable after a
  /// fatal error. Defaults (`available: true`, `initializeResult: true`)
  /// preserve the prior hardcoded behavior for every existing test.
  var available = true;
  var initializeResult = true;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async {
    this.onStatus = onStatus;
    this.onError = onError;
    initializeCount++;
    return initializeResult;
  }

  @override
  bool get isAvailable => available;

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
  Future<void> cancel() async {
    canceled = true;
    cancelCount++;
    // Cancelling clears the recognizer's accumulated buffer and stops it —
    // model that by marking the session not-listening (isListening → false).
    // `stop()` was NOT called, so the `stopped` flag stays as-is; isListening
    // flips false purely via startedLocaleId being cleared.
    startedLocaleId = null;
  }

  var cancelCount = 0;

  void emitFinal(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.95)], true),
  );

  /// 260703 BUG-1 (1D): a final whose transcription list carries alternates —
  /// entry 0 is the primary transcript (== recognizedWords), the rest are the
  /// alternates the mixin must thread into execute(alternateTexts:).
  void emitFinalWithAlternates(List<String> transcripts) => onResult!(
    SpeechRecognitionResult([
      for (final t in transcripts) SpeechRecognitionWords(t, null, 0.9),
    ], true),
  );

  void emitPartial(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.5)], false),
  );

  /// Simulate the platform recognizer self-terminating (30s/3s timeout) so the
  /// continuous tap-session must re-arm to keep listening.
  void emitTerminalStatus() => onStatus!('done');

  void emitStatus(String status) => onStatus!(status);

  /// Simulate the platform recognizer reporting an error. On iOS a no-match
  /// (silence) is reported `permanent: true`; that is the BUG 1 trigger.
  void emitError(String errorMsg, {bool permanent = false}) =>
      onError!(errorMsg, permanent);
}

class FakeParseVoiceInputUseCase implements ParseVoiceInputUseCase {
  FakeParseVoiceInputUseCase(this.results);
  final Map<String, VoiceParseResult> results;
  final inputs = <String>[];
  final alternateInputs = <List<String>>[];

  @override
  Future<Result<VoiceParseResult>> execute(
    String recognizedText, {
    String? localeId,
    List<String> alternateTexts = const [],
  }) async {
    inputs.add(recognizedText);
    alternateInputs.add(alternateTexts);
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
      expect(
        host.committed,
        isTrue,
        reason: 'onPttCommitted must fire after a successful batch-fill',
      );

      // The form received the batch-fill — assert via the rendered merchant
      // TextField and category chip.
      expect(find.text('星巴克'), findsOneWidget);
      expect(find.textContaining('Cafe'), findsOneWidget);
    },
  );

  testWidgets('misfire (<300ms) discards via cancel — no parse, no commit', (
    tester,
  ) async {
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
  });

  testWidgets('detected-foreign-currency utterance pushes the foreign triple', (
    tester,
  ) async {
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
    expect(
      host.pttDisplayCurrency,
      'USD',
      reason:
          'a resolved foreign rate pushes the triple and switches '
          'the display currency to USD',
    );
  });

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
      expect(
        host.committed,
        isTrue,
        reason: 'an auto-fill fires onPttCommitted',
      );
      expect(
        host.pttIsRecording,
        isTrue,
        reason: 'the session keeps listening after an auto-fill',
      );
      expect(find.text('星巴克'), findsOneWidget);
      expect(find.textContaining('Cafe'), findsOneWidget);
    },
  );

  testWidgets(
    'R6: a terminal recognizer status STOPS the one-shot session (no re-arm)',
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
      final startsBefore = speech.startCount;
      speech.startedLocaleId = null; // simulate the platform stopping

      speech.emitTerminalStatus();
      await tester.pumpAndSettle();

      // R6: the iOS continuous re-arm was unreliable (mic died but status stuck
      // on listening). The one-shot model stops cleanly instead of re-arming.
      expect(
        host.pttIsRecording,
        isFalse,
        reason: 'a terminal status ends the one-shot recording',
      );
      expect(
        host.pttListenStatus,
        PttListenStatus.stopped,
        reason: 'status reflects the stopped recognizer',
      );
      expect(
        speech.startCount,
        startsBefore,
        reason: 'no auto re-arm — the recognizer is NOT restarted',
      );
    },
  );

  // 260622-nhs R6: the R3 `restartPttListening` re-arm API was removed with the
  // one-shot model (the host now re-records via resetPttSessionAndRestart — a
  // full cancel→fresh-start — not an idempotent re-arm). Its 3 tests are gone.

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
      expect(host.pttIsRecording, isFalse, reason: 'exit ends the session');
      // Filled content is retained (D-2 fill-and-stay).
      expect(find.text('スタバ'), findsOneWidget);
    },
  );

  // ── R4 BUG A: reset cancels the recognizer + fresh restart ────────────────

  testWidgets(
    'R4 BUG A: resetPttSessionAndRestart cancels the recognizer (clears '
    'accumulated buffer) then starts a fresh listening session',
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
      final startsBefore = speech.startCount;

      await host.resetPttSessionAndRestart();
      await tester.pumpAndSettle();

      // cancel() must have been called to clear the recognizer buffer …
      expect(
        speech.cancelCount,
        greaterThanOrEqualTo(1),
        reason: 'reset must cancel() to clear the recognizer buffer',
      );
      // … and a fresh startListening must follow (not the weak no-op restart).
      expect(
        speech.startCount,
        greaterThan(startsBefore),
        reason: 'reset must start a fresh listening session',
      );
      expect(
        speech.isListening,
        isTrue,
        reason: 'the session is listening again after reset',
      );
      expect(host.pttIsRecording, isTrue);
    },
  );

  testWidgets(
    'R4 BUG A: after reset, the next transcript replaces (no old-text '
    'accumulation) and fills fresh',
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
      speech.emitPartial('今天吃饭用了1450日元');
      await tester.pump();

      await host.resetPttSessionAndRestart();
      await tester.pumpAndSettle();

      // The app-side transcript buffers are cleared.
      expect(
        host.pttTranscript,
        isEmpty,
        reason: 'reset clears the partial/final transcript',
      );

      // A fresh utterance after reset fills the form (no stale accumulation).
      speech.emitFinal('1千8百4十元 星巴克');
      await tester.pumpAndSettle();
      expect(find.text('星巴克'), findsOneWidget);
    },
  );

  // ── R4 BUG B: serialize reset-restart, suppress double re-arm ──────────────

  testWidgets(
    'R4 BUG B: a terminal status during the reset-restart window does NOT '
    'double-start (guard suppresses auto re-arm)',
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

      // Drive reset and, while it is in flight, fire the cancel-induced terminal
      // status that onStatus would normally re-arm on.
      final resetFuture = host.resetPttSessionAndRestart();
      speech.emitStatus('notListening');
      speech.emitStatus('done');
      await resetFuture;
      await tester.pumpAndSettle();

      // Exactly ONE fresh start from the reset — the suppressed onStatus re-arm
      // must not have added a second concurrent startListening.
      expect(
        speech.startCount,
        2,
        reason:
            'one start from startPttTapSession + one from reset; the '
            'in-window terminal status must NOT add a third',
      );
      expect(host.pttIsRecording, isTrue);
      expect(speech.isListening, isTrue);

      // The session still responds after the reset (no freeze): a new final
      // result still flows through.
      speech.emitFinal('テスト');
      await tester.pumpAndSettle();
      expect(host.pttIsRecording, isTrue);
    },
  );

  // ── R4 BUG C: live listen status ──────────────────────────────────────────

  testWidgets(
    'R4 BUG C: pttListenStatus transitions listening → processing → stopped',
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
      expect(
        host.pttListenStatus,
        PttListenStatus.listening,
        reason: 'an open session starts in listening',
      );

      await host.exitPttTapSession();
      await tester.pumpAndSettle();
      expect(
        host.pttListenStatus,
        PttListenStatus.stopped,
        reason: 'exiting stops the recognizer',
      );
    },
  );

  // ── XVAL-03: resolve-on-final hysteresis (no category-chip flicker) ────────

  testWidgets(
    'resolve-on-final: category fills exactly once on the final result, never '
    'from partials (XVAL-03)',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      // Same category-bearing utterance carried by N partials then one final.
      // The fake returns the SAME parse (amount/merchant/category) for both the
      // partial-driven parse and the final parse, so the ONLY thing that gates
      // the category chip is the resolve-on-final hysteresis (not a parse diff).
      final result = VoiceParseResult(
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
      );
      final parse = FakeParseVoiceInputUseCase({'1千8百4十元 星巴克': result});

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();

      // Feed 3 partials, each past the 300ms debounce so the partial-driven
      // fill runs. Amount + merchant fill LIVE (sub-second feedback), but the
      // category chip MUST stay unresolved across every partial (no flicker).
      for (var i = 0; i < 3; i++) {
        speech.emitPartial('1千8百4十元 星巴克');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }

      // Gate is category-scoped: amount + merchant DID fill from the partials.
      expect(
        find.text('星巴克'),
        findsOneWidget,
        reason: 'partials still fill merchant live (gate is category-only)',
      );
      expect(
        host.pttLastFilledAmount,
        1840,
        reason: 'partials still fill amount live (gate is category-only)',
      );
      // …but the category chip is held until the first end-of-speech final.
      expect(
        find.textContaining('Cafe'),
        findsNothing,
        reason: 'category is held across partials — no chip flicker (XVAL-03)',
      );

      // The first end-of-speech final resolves the category exactly once.
      speech.emitFinal('1千8百4十元 星巴克');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Cafe'),
        findsOneWidget,
        reason: 'the final result resolves the category (resolve-on-final)',
      );
      // Amount/merchant remain filled (the final fill is a superset, not a reset).
      expect(find.text('星巴克'), findsOneWidget);
      expect(host.pttLastFilledAmount, 1840);
    },
  );

  // ── R4 BUG D: dedupe final parse + live partial auto-fill ──────────────────

  testWidgets(
    'R4 BUG D: a partial result auto-fills the form live (sub-second, no '
    'wait for final)',
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

      // A PARTIAL result (not final) must drive a live fill after the 300ms
      // debounce — the user does NOT wait for the 3s pauseFor final. Advance the
      // fake clock past the debounce so the Timer fires, then settle the parse.
      speech.emitPartial('1千8百4十元 星巴克');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(
        find.text('星巴克'),
        findsOneWidget,
        reason: 'partial auto-fill updates the form live',
      );
    },
  );

  testWidgets('R4 BUG D: the final branch parses the text only ONCE (dedupe)', (
    tester,
  ) async {
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

    // BUG D: the final path must parse 'ラテ 1千' exactly once — the prior code
    // parsed it twice (satisfaction estimate + fill).
    final count = parse.inputs.where((t) => t == 'ラテ 1千').length;
    expect(
      count,
      1,
      reason: 'final result must parse once (deduped), not twice',
    );
    expect(find.text('スタバ'), findsOneWidget);
  });

  // ── R5 BUG 1: continuous-session onError — swallow transient no-match ───────

  testWidgets(
    'R6 BUG 1: a transient no-match (iOS permanent:true) STOPS the one-shot '
    'session — no toast, no bar lock, no re-arm',
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
      expect(host.pttServiceInitialized, isTrue);

      final startsBefore = speech.startCount;
      // iOS reports error_no_match as permanent:true — the base handler would
      // flip isInitialized=false (locking the bar) + toast. The continuous
      // override must STILL swallow the toast (R5), but R6 stops cleanly rather
      // than re-arming (the unreliable iOS re-arm left the mic dead + status
      // stuck on listening).
      speech.emitError('error_no_match', permanent: true);
      await tester.pumpAndSettle();

      // No toast surfaced (R5 swallow preserved).
      expect(
        find.text('音声を認識できませんでした。もう一度お試しください'),
        findsNothing,
        reason: 'a silence no-match must not toast in hands-free mode',
      );
      // Bar stays usable — isInitialized must NOT flip false.
      expect(
        host.pttServiceInitialized,
        isTrue,
        reason: 'transient error must not lock the bar',
      );
      // R6: the one-shot session STOPS (no re-arm); the user taps 重置 to record
      // again. status → stopped surfaces the 「停止聆听」 + tap-reset hint.
      expect(
        host.pttIsRecording,
        isFalse,
        reason: 'a transient no-match stops the one-shot session',
      );
      expect(
        host.pttListenStatus,
        PttListenStatus.stopped,
        reason: 'status → stopped so the panel shows 停止聆听 + tap-reset hint',
      );
      expect(
        speech.startCount,
        startsBefore,
        reason: 'no auto re-arm — the recognizer is NOT restarted',
      );
    },
  );

  testWidgets('R6 BUG 1: a transient speech-timeout STOPS the one-shot session '
      '(no toast, no lock, no re-arm)', (tester) async {
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
    final startsBefore = speech.startCount;

    speech.emitError('error_speech_timeout', permanent: true);
    await tester.pumpAndSettle();

    expect(find.text('音声認識でエラーが発生しました'), findsNothing);
    expect(host.pttServiceInitialized, isTrue);
    expect(
      host.pttIsRecording,
      isFalse,
      reason: 'a transient timeout stops the one-shot session',
    );
    expect(host.pttListenStatus, PttListenStatus.stopped);
    expect(
      speech.startCount,
      startsBefore,
      reason: 'no auto re-arm on a transient timeout',
    );
  });

  testWidgets(
    'R5 BUG 1: a FATAL error during a continuous session tears down cleanly '
    'AND recovers the bar (re-initializes so the next tap works)',
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
      final initBefore = speech.initializeCount;

      // A fatal (audio/permission/client/network) error.
      speech.emitError('error_audio', permanent: true);
      await tester.pumpAndSettle();

      // Clean teardown.
      expect(
        host.pttContinuousActive,
        isFalse,
        reason: 'a fatal error ends the continuous session',
      );
      expect(
        host.pttIsRecording,
        isFalse,
        reason: 'a fatal error stops recording',
      );
      expect(
        host.pttListenStatus,
        PttListenStatus.stopped,
        reason: 'status reflects the stopped recognizer',
      );
      // The user IS told (fatal errors toast).
      expect(
        find.text('マイクの音声を取得できませんでした'),
        findsOneWidget,
        reason: 'a fatal error surfaces a toast',
      );
      // The bar recovers — guard passes for the next tap (re-initialized so the
      // next 「语音记录」 tap works without an app restart).
      expect(
        host.pttServiceInitialized,
        isTrue,
        reason: 'the bar must be re-enabled after a fatal error',
      );
      expect(
        speech.initializeCount,
        greaterThan(initBefore),
        reason: 'the service was re-initialized to recover the bar',
      );
      expect(
        host.pttCanStart,
        isTrue,
        reason: 'a new tap can re-enter after a fatal error',
      );
    },
  );

  testWidgets(
    'R5 BUG 1: the hold path (NOT continuous) keeps the legacy base onError '
    'behavior — toast + isInitialized flip',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase(const {});

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.onPttHoldStart(); // legacy hold path — _continuousActive stays false
      await tester.pump();
      expect(host.pttContinuousActive, isFalse);

      speech.emitError('error_no_match', permanent: true);
      await tester.pumpAndSettle();

      // Legacy behavior preserved: base onError toasts + flips isInitialized.
      expect(
        find.text('音声を認識できませんでした。もう一度お試しください'),
        findsOneWidget,
        reason: 'the hold path keeps the legacy toast (super.onError)',
      );
      expect(
        host.pttServiceInitialized,
        isFalse,
        reason: 'the hold path keeps the legacy permanent isInitialized flip',
      );
      expect(host.pttIsRecording, isFalse);
    },
  );

  // ── R5 BUG 2: status synced to stopped on the error path ───────────────────

  testWidgets(
    'R5 BUG 2: pttListenStatus is stopped after a fatal error (never stuck '
    'on listening)',
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
      expect(host.pttListenStatus, PttListenStatus.listening);

      speech.emitError('error_client', permanent: true);
      await tester.pumpAndSettle();

      expect(
        host.pttListenStatus,
        PttListenStatus.stopped,
        reason: 'the panel must not show 正在聆听 after the recognizer stopped',
      );
    },
  );

  testWidgets(
    'R6 BUG 2: a transient no-match goes to stopped (never stuck on listening)',
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

      speech.emitError('error_no_match', permanent: true);
      await tester.pumpAndSettle();

      // R6: the one-shot model goes to stopped — the panel shows 「停止聆听」 and
      // the tap-reset hint, NEVER the stuck-on-listening dead-mic state.
      expect(
        host.pttListenStatus,
        PttListenStatus.stopped,
        reason: 'a swallowed transient stops cleanly (no stuck listening)',
      );
      expect(host.pttIsRecording, isFalse);
    },
  );

  // ── R6: one-shot listen — exactly ONE startListening per session ───────────

  testWidgets(
    'R6: a session issues exactly ONE startListening (no infinite re-arm loop)',
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
      expect(
        speech.startCount,
        1,
        reason: 'one-shot: a single startListening opens the session',
      );

      // The recognizer self-terminates (timeout) — the old model re-armed here.
      speech.startedLocaleId = null;
      speech.emitTerminalStatus();
      await tester.pumpAndSettle();

      expect(
        speech.startCount,
        1,
        reason: 'no re-arm — still exactly one startListening after terminal',
      );
      expect(host.pttIsRecording, isFalse);
    },
  );

  // ── 260703 BUG-1/BUG-2 follow-ups: conversion gating, undo, amount notices ──

  testWidgets(
    '260703 2C+2B: partial fills never convert; the final converts with an '
    'undo snackbar that restores the spoken amount',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      const vpr = VoiceParseResult(
        rawText: '五十美元',
        amount: 50,
        detectedCurrency: 'USD',
      );
      final parse = FakeParseVoiceInputUseCase({'五十美元': vpr});

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse, rate: '150.0'),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();

      speech.emitPartial('五十美元');
      // Fire the 300ms partial-parse debounce.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Partial fill: the raw amount lands live, but NO conversion — no
      // triple, display currency stays JPY, no snackbar.
      expect(host.pttFormState!.currentAmount, 50);
      expect(host.pttFormState!.currentOriginalCurrency, isNull);
      expect(host.pttDisplayCurrency, 'JPY');
      expect(find.byType(SnackBar), findsNothing);

      speech.emitFinal('五十美元');
      await tester.pumpAndSettle();

      // Resolve-on-final: 50 USD → 5000 minor units → ×150.0 → ¥7,500.
      expect(host.pttFormState!.currentAmount, 7500);
      expect(host.pttFormState!.currentOriginalCurrency, 'USD');
      expect(host.pttDisplayCurrency, 'USD');

      // 2B: the conversion is visible and reversible.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(SnackBarAction), findsOneWidget);

      await tester.tap(find.byType(SnackBarAction));
      await tester.pumpAndSettle();

      expect(host.pttFormState!.currentAmount, 50);
      expect(host.pttFormState!.currentOriginalCurrency, isNull);
      expect(host.pttDisplayCurrency, 'JPY');
      expect(host.pttLastFilledAmount, 50);
    },
  );

  testWidgets(
    '260703 1A: a repair candidate surfaces an adopt snackbar; adopting '
    'replaces the poisoned amount',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '250046元': const VoiceParseResult(
          rawText: '250046元',
          amount: 250046,
          amountRepairCandidate: 2546,
        ),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();
      speech.emitFinal('250046元');
      await tester.pumpAndSettle();

      // The poisoned amount is filled (never silently rewritten)…
      expect(host.pttFormState!.currentAmount, 250046);
      // …and the one-tap adopt affordance is offered.
      expect(find.byType(SnackBarAction), findsOneWidget);

      await tester.tap(find.byType(SnackBarAction));
      await tester.pumpAndSettle();

      expect(host.pttFormState!.currentAmount, 2546);
      expect(host.pttLastFilledAmount, 2546);
    },
  );

  testWidgets(
    '260703 1E: a large voice amount surfaces a double-check notice',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '五百万円': const VoiceParseResult(rawText: '五百万円', amount: 5000000),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();
      speech.emitFinal('五百万円');
      await tester.pumpAndSettle();

      expect(host.pttFormState!.currentAmount, 5000000);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.byType(SnackBarAction),
        findsNothing,
        reason: 'the large-amount notice is informational — no action',
      );

      // Let the auto-dismiss timer fire so no timer leaks past the test —
      // and prove the notice actually goes away on its own (it must never
      // permanently cover the bottom actions).
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    '260703 1D: final alternates are threaded into the parse use case',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '250046元': const VoiceParseResult(rawText: '250046元', amount: 2546),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();
      speech.emitFinalWithAlternates(['250046元', '2546元']);
      await tester.pumpAndSettle();

      expect(
        parse.alternateInputs.last,
        ['2546元'],
        reason: 'the best transcript is excluded; the rest ride along',
      );
    },
  );

  // ── quick-260706-kax VRESET: dead-session reset recovery ───────────────────

  testWidgets(
    'VRESET-01: after a fatal error kills the continuous session, reset '
    'revives a fresh listening session and the next final auto-fills',
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

      // Fatal error: the onError fatal branch tears the session down but the
      // host panel stays open — 停止聆听 + the red reset square.
      speech.emitError('error_retry', permanent: true);
      await tester.pumpAndSettle();
      expect(
        host.pttContinuousActive,
        isFalse,
        reason: 'precondition: the fatal branch killed the session',
      );
      expect(
        host.pttListenStatus,
        PttListenStatus.stopped,
        reason: 'precondition: the panel shows the stopped state',
      );

      final cancelsBefore = speech.cancelCount;
      final startsBefore = speech.startCount;

      // The red reset square must revive the DEAD session, not no-op.
      await host.resetPttSessionAndRestart();
      await tester.pumpAndSettle();

      expect(
        speech.cancelCount,
        greaterThan(cancelsBefore),
        reason: 'reset must cancel() to clear the recognizer buffer',
      );
      expect(
        speech.startCount,
        greaterThan(startsBefore),
        reason: 'reset must issue a fresh startListening on a dead session',
      );
      expect(
        host.pttContinuousActive,
        isTrue,
        reason: 'reset restores the continuous session semantics',
      );
      expect(host.pttIsRecording, isTrue, reason: 'recording again');
      expect(
        host.pttListenStatus,
        PttListenStatus.listening,
        reason: 'the panel is back to 正在聆听',
      );

      // The recovered session's continuous fill path works end-to-end — proves
      // _continuousActive was restored BEFORE the fill path runs.
      speech.emitFinal('1千8百4十元 星巴克');
      await tester.pumpAndSettle();
      expect(
        find.text('星巴克'),
        findsOneWidget,
        reason: 'a speech-final in the recovered session auto-fills the form',
      );
    },
  );

  testWidgets(
    'VRESET-02: two back-to-back resets inside the cancel→start window issue '
    'exactly ONE extra startListening (reentrancy guard)',
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
      expect(speech.startCount, 1);

      // Dart async bodies run synchronously to the first await, so the second
      // call lands inside the first reset's cancel→start window and must hit
      // the _restarting entry guard (else: concurrent double-start → the
      // plugin hangs, the post-reset 假死).
      final f1 = host.resetPttSessionAndRestart();
      final f2 = host.resetPttSessionAndRestart();
      await f1;
      await f2;
      await tester.pumpAndSettle();

      expect(
        speech.startCount,
        2,
        reason:
            'one start from startPttTapSession + ONE from the first reset; '
            'the reentrant second call must early-return on _restarting',
      );
      expect(host.pttIsRecording, isTrue);
      expect(speech.isListening, isTrue);
      expect(host.pttListenStatus, PttListenStatus.listening);
    },
  );

  testWidgets(
    'VRESET belt-and-braces: reset re-initializes an unavailable service '
    'before restarting; a failed re-init rolls back to stopped (no start)',
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

      speech.emitError('error_audio', permanent: true);
      await tester.pumpAndSettle(); // _recoverBarAfterFatalError settles

      // Phase A: the platform left the recognizer unavailable (the async
      // recover may not have run yet on-device) → reset must re-initialize
      // FIRST, then restart on success.
      speech.available = false;
      final initBefore = speech.initializeCount;
      final startsBefore = speech.startCount;

      await host.resetPttSessionAndRestart();
      await tester.pumpAndSettle();

      expect(
        speech.initializeCount,
        greaterThan(initBefore),
        reason: 'reset must re-initialize an unavailable service first',
      );
      expect(
        speech.startCount,
        greaterThan(startsBefore),
        reason: 'restart proceeds after a successful re-init',
      );
      expect(host.pttContinuousActive, isTrue);
      expect(host.pttListenStatus, PttListenStatus.listening);

      // Phase B: a FAILED re-init must roll the state back — no
      // startListening, no optimistic listening flip (a later tap retries).
      speech.available = false;
      speech.initializeResult = false;
      final startsBeforeB = speech.startCount;

      await host.resetPttSessionAndRestart();
      await tester.pumpAndSettle();

      expect(
        speech.startCount,
        startsBeforeB,
        reason: 'a failed re-init must NOT call startListening',
      );
      expect(
        host.pttListenStatus,
        PttListenStatus.stopped,
        reason: 'no optimistic listening flip on a failed re-init',
      );
      expect(host.pttContinuousActive, isFalse);
      expect(host.pttIsRecording, isFalse);
    },
  );

  // ── quick-260706-kzr: magnitude-anchored merged-vs-parsed arbitration ──────
  //
  // Each scenario drives the REAL merger: the first final seeds its buffer,
  // pumping past the 2.5s window commits it into _mergedAmount, then a second
  // final delivers the parse result whose rawText may carry a magnitude
  // anchor (千/万). The fill must obey: merged priority stands UNLESS the
  // anchor pins a digit count that merged violates and parsed satisfies.

  testWidgets(
    '260706-kzr: merged 53102 loses to parsed 5312 when rawText anchors '
    '4 digits (concat-exception regression pin)',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '53102円': const VoiceParseResult(rawText: '53102円', amount: 53102),
        '五千三百十二円': const VoiceParseResult(
          rawText: '五千三百十二円',
          amount: 5312,
        ),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();

      speech.emitFinal('53102円');
      await tester.pumpAndSettle();
      // Fire the merger's 2.5s window → commits 53102 into _mergedAmount.
      await tester.pump(const Duration(seconds: 3));

      speech.emitFinal('五千三百十二円');
      await tester.pumpAndSettle();

      expect(host.pttFormState!.currentAmount, 5312);
    },
  );

  testWidgets(
    '260706-kzr: merged 35016 loses to parsed 3516 via the magnitude branch '
    'ONLY (concat detector cannot see this shape)',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '35016円': const VoiceParseResult(rawText: '35016円', amount: 35016),
        '三千五百十六円': const VoiceParseResult(
          rawText: '三千五百十六円',
          amount: 3516,
        ),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();

      speech.emitFinal('35016円');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      speech.emitFinal('三千五百十六円');
      await tester.pumpAndSettle();

      // detectConcatRepairCandidate('35016') is null (no usable trailing-zero
      // head), so only the 千-anchor in rawText (expected 4 digits) can flip
      // the 5-digit merged amount to the compliant parse amount.
      expect(host.pttFormState!.currentAmount, 3516);
    },
  );

  testWidgets(
    '260706-kzr: anchor-free rawText keeps merged priority (8000 beats 3500)',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '8000円': const VoiceParseResult(rawText: '8000円', amount: 8000),
        '3500円': const VoiceParseResult(rawText: '3500円', amount: 3500),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();

      speech.emitFinal('8000円');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      speech.emitFinal('3500円');
      await tester.pumpAndSettle();

      expect(host.pttFormState!.currentAmount, 8000);
    },
  );

  testWidgets(
    '260706-kzr: merged wins when BOTH readings satisfy the anchored digit '
    'count (flip only on merged-violating + parsed-compliant)',
    (tester) async {
      useTallSurface(tester);
      final speech = CapturingSpeechService();
      final parse = FakeParseVoiceInputUseCase({
        '8000円': const VoiceParseResult(rawText: '8000円', amount: 8000),
        '三千五百円': const VoiceParseResult(rawText: '三千五百円', amount: 3500),
      });

      await tester.pumpWidget(
        buildHost(speechService: speech, parseUseCase: parse),
      );
      await tester.pumpAndSettle();

      final host = hostOf(tester);
      host.startPttTapSession();
      await tester.pump();

      speech.emitFinal('8000円');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      speech.emitFinal('三千五百円');
      await tester.pumpAndSettle();

      // 三千五百円 anchors 4 digits; merged 8000 is ALSO 4 digits → compliant
      // → the multi-chunk merged-priority semantic stands.
      expect(host.pttFormState!.currentAmount, 8000);
    },
  );
}
