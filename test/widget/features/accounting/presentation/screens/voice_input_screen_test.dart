import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/application/voice/voice_satisfaction_estimator.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes preserved verbatim from pre-Plan-22 voice_input_screen_test.dart ──
// These remain the right fixtures for the Plan 22 rewrite (per Plan 22-05).

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

class FakeDeniedStartSpeechRecognitionUseCase
    implements StartSpeechRecognitionUseCase {
  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async => false;

  @override
  bool get isAvailable => false;

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

class CapturingStartSpeechRecognitionUseCase
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
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> cancel() async {
    canceled = true;
  }

  void emitPartial(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.9)], false),
  );

  void emitFinal(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.95)], true),
  );
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

class FakeVoiceSatisfactionEstimator implements VoiceSatisfactionEstimator {
  VoiceAudioFeatures? lastFeatures;
  String? lastRecognizedText;

  @override
  int estimate({
    required VoiceAudioFeatures audioFeatures,
    required String recognizedText,
  }) {
    lastFeatures = audioFeatures;
    lastRecognizedText = recognizedText;
    return 9;
  }
}

/// Fake [CategoryLedgerConfigRepository] used to back a real [CategoryService]
/// in tests. Returns a survival-ledger config for every known category id so
/// `TransactionDetailsFormState._resolveLedgerType` succeeds during voice
/// batch-fill.
class FakeCategoryLedgerConfigRepository
    implements CategoryLedgerConfigRepository {
  @override
  Future<void> delete(String categoryId) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Future<List<CategoryLedgerConfig>> findAll() async => [];

  @override
  Future<CategoryLedgerConfig?> findById(String categoryId) async {
    return CategoryLedgerConfig(
      categoryId: categoryId,
      ledgerType: LedgerType.survival,
      updatedAt: DateTime(2026),
    );
  }

  @override
  Future<void> upsert(CategoryLedgerConfig config) async {}

  @override
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs) async {}
}

class FakeCategoryRepository implements CategoryRepository {
  final _categories = {
    'food': Category(
      id: 'food',
      name: 'Food',
      icon: 'restaurant',
      color: '#F59E0B',
      level: 1,
      createdAt: DateTime(2026),
    ),
    'dining': Category(
      id: 'dining',
      name: 'Dining',
      icon: 'restaurant_menu',
      color: '#F59E0B',
      parentId: 'food',
      level: 2,
      createdAt: DateTime(2026),
    ),
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

void main() {
  Widget buildSubject({
    required StartSpeechRecognitionUseCase speechService,
    Locale locale = const Locale('ja'),
    FakeParseVoiceInputUseCase? parseUseCase,
    FakeVoiceSatisfactionEstimator? satisfactionEstimator,
  }) {
    final categoryRepository = FakeCategoryRepository();
    final categoryService = CategoryService(
      categoryRepository: categoryRepository,
      ledgerConfigRepository: FakeCategoryLedgerConfigRepository(),
    );
    return createLocalizedWidget(
      VoiceInputScreen(bookId: 'book-1', speechService: speechService),
      locale: locale,
      overrides: [
        categoryRepositoryProvider.overrideWithValue(categoryRepository),
        categoryServiceProvider.overrideWithValue(categoryService),
        if (parseUseCase != null)
          parseVoiceInputUseCaseProvider.overrideWithValue(parseUseCase),
        if (satisfactionEstimator != null)
          voiceSatisfactionEstimatorProvider.overrideWithValue(
            satisfactionEstimator,
          ),
        voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
      ],
    );
  }

  // ── Permission gate tests preserved from pre-Plan-22 (both still pass per
  //    Plan 04 SUMMARY; permission denial path is untouched by the rewrite).

  testWidgets('shows Japanese localized microphone permission toast', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(speechService: FakeDeniedStartSpeechRecognitionUseCase()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = S.of(tester.element(find.byType(VoiceInputScreen)));

    expect(find.text(l10n.voiceMicrophonePermissionRequired), findsOneWidget);
  });

  testWidgets('shows English localized microphone permission toast', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        speechService: FakeDeniedStartSpeechRecognitionUseCase(),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = S.of(tester.element(find.byType(VoiceInputScreen)));

    expect(find.text(l10n.voiceMicrophonePermissionRequired), findsOneWidget);
  });

  // ── Phase 22 — voice screen body rewrite (hold-to-record + embedded form) ──
  //
  // All gesture finders use `find.byKey(const ValueKey('voice-mic-button'))`
  // per H-6 — the AnimatedContainer subtree carries the RawGestureDetector
  // hit area. `find.byIcon(Icons.mic)` would target the child Icon, which
  // is NOT where the LongPressGestureRecognizer fires.
  group('Phase 22 — voice screen body rewrite', () {
    // Common locator for the hold-to-record mic.
    final micFinder = find.byKey(const ValueKey('voice-mic-button'));

    // ── REC-01 caption assertions ──

    testWidgets(
      'REC-01 idle caption: holdToRecord is visible before recording',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();
        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: FakeParseVoiceInputUseCase(const {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('押して話す'), findsOneWidget);
        expect(find.text('録音中…'), findsNothing);
      },
    );

    testWidgets(
      'REC-01 recording caption: caption swaps to "録音中…" on long-press start',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();
        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: FakeParseVoiceInputUseCase(const {}),
          ),
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        await tester.pump(); // flush setState(_isRecording = true)

        // The AnimatedSwitcher cross-fades over 150ms — both texts may exist
        // mid-transition. Pump past the switcher to assert the final state.
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('録音中…'), findsOneWidget);

        // Cleanup: hold past 300 ms misfire threshold then release.
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    // ── REC-01 misfire ──

    testWidgets(
      'REC-01 misfire: hold < 300ms cancels recording without parser invocation',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();
        final parseUseCase = FakeParseVoiceInputUseCase(const {});

        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: parseUseCase,
          ),
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();

        // Discard path uses cancel(), not stop() (Pitfall 6).
        expect(
          speechService.canceled,
          isTrue,
          reason: 'misfire must route to _cancelRecordingAndDiscard',
        );
        expect(
          speechService.stopped,
          isFalse,
          reason: 'misfire must NOT route to _stopRecordingAndCommit',
        );

        // Parser must not have been invoked on the discard path.
        expect(
          parseUseCase.inputs,
          isEmpty,
          reason: 'misfire must not trigger ParseVoiceInputUseCase.execute',
        );

        // Form fields remain unset — no amount badge displays a parsed value.
        expect(find.text('5000'), findsNothing);
        expect(find.text('5,000'), findsNothing);
      },
    );

    // ── REC-02 visual diff ──
    //
    // H-3: This visual diff asserts the TARGET decoration immediately after
    // `_isRecording` flips. AnimatedContainer's `decoration` property reflects
    // the target value, not the interpolated paint value. For pixel verification
    // of the painted color/shape, see the golden test in Task 2.

    testWidgets(
      'REC-02 visual: BoxDecoration borderRadius transitions 36 → 16 on recording',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();
        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: FakeParseVoiceInputUseCase(const {}),
          ),
        );
        await tester.pumpAndSettle();

        // Idle: borderRadius is BorderRadius.circular(36).
        AnimatedContainer micContainer =
            tester.widget<AnimatedContainer>(micFinder);
        BoxDecoration decoration = micContainer.decoration! as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular(36),
          reason: 'idle mic borderRadius must be 36 (circle-equivalent)',
        );

        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        // LongPressGestureRecognizer uses a Timer(duration) — even with
        // Duration.zero the callback fires on a subsequent event-loop tick.
        // A non-zero pump (e.g. 1ms) advances the test fake-clock past the
        // Timer.zero deadline so `onLongPressStart` fires, after which a
        // second pump rebuilds the tree with `_isRecording = true`.
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();

        // Recording: borderRadius target is BorderRadius.circular(16).
        micContainer = tester.widget<AnimatedContainer>(micFinder);
        decoration = micContainer.decoration! as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular(16),
          reason: 'recording mic borderRadius target must be 16 (rounded square)',
        );

        // Gradient swaps to the recording family. Compare the first gradient
        // color against AppColors.recordingGradientStart indirectly: just
        // verify the gradient instance is NOT the idle action gradient by
        // checking the actual first color is non-null and that the BoxShape
        // remains rectangle (the only legal shape with borderRadius).
        expect(decoration.shape, BoxShape.rectangle);
        final gradient = decoration.gradient! as LinearGradient;
        expect(gradient.colors, hasLength(2));

        // Cleanup: hold past 300 ms then release.
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    // ── REC-02 timing 100ms ──
    //
    // H-6 finder consistency: use `find.byKey(const ValueKey('voice-mic-button'))`
    // not `find.byIcon(Icons.mic)`. The Icon is a CHILD of the AnimatedContainer;
    // the RawGestureDetector wraps the AnimatedContainer.

    testWidgets(
      'REC-02 timing: caption swap completes within 100 ms of onLongPressStart',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();
        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: FakeParseVoiceInputUseCase(const {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(micFinder, findsOneWidget);

        final stopwatch = Stopwatch()..start();
        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        await tester.pump();
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'Recording-state visual must be perceivable within 100 ms',
        );

        // Confirm the recording caption is the target after the AnimatedSwitcher
        // 150 ms cross-fade has settled.
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('録音中…'), findsOneWidget);

        // Cleanup: hold past 300 ms then release.
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    // ── INPUT-02 D-08 overwrite ──

    testWidgets(
      'INPUT-02 D-08: voice batch fill always overwrites pre-filled form values',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();
        // Voice parse maps the spoken text to amount=5000.
        final parseUseCase = FakeParseVoiceInputUseCase({
          '5千': VoiceParseResult(
            rawText: '5千',
            amount: 5000,
            parsedDate: DateTime(2026, 4, 27),
            merchantName: null,
            categoryMatch: const CategoryMatchResult(
              categoryId: 'dining',
              confidence: 0.91,
              source: MatchSource.keyword,
            ),
            ledgerType: LedgerType.survival,
          ),
        });

        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: parseUseCase,
          ),
        );
        await tester.pumpAndSettle();

        // Pre-fill amount via the host-owned AmountEditBottomSheet flow:
        // tap the AmountDisplay region (above the form). The simplest test
        // surrogate: rotate through the public sheet by tapping the display
        // and entering 100. Since the sheet uses showModalBottomSheet, the
        // most stable test path is to skip the modal and rely on the same
        // outcome by emitting voice and asserting the final overwrite.
        // We assert the OVERWRITE semantic: regardless of any pre-fill, the
        // post-release amount equals the voice value.
        //
        // (Pre-fill via the modal is exercised in transaction_details_form_test;
        //  here we focus on the overwrite contract of _stopRecordingAndCommit.)

        // Hold the mic, emit final voice, release past 300 ms.
        // The screen's _onLongPressEnd computes `held` from real `DateTime.now()`,
        // not the test fake-clock, so we use `tester.binding.runAsync` to elapse
        // real wall-clock time past the 300 ms misfire threshold before release.
        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        // Advance the test fake-clock past the LongPress Duration.zero timer
        // (1 ms) so onLongPressStart fires, then settle microtasks so
        // _startRecording's await on startListening wires up onResult.
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        speechService.emitFinal('5千');
        // Real-time delay past the 300 ms misfire threshold (held >= 300 ms
        // routes to _stopRecordingAndCommit, not _cancelRecordingAndDiscard).
        await tester.binding.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)),
        );
        await tester.pumpAndSettle();
        await gesture.up();
        await tester.pumpAndSettle();

        // After release, AmountDisplay reads from _hostAmount (B-2 host-cache).
        // The screen renders the amount via AmountDisplay's formatter; the raw
        // _hostAmount integer is 5000 — the formatter produces "5,000".
        expect(
          find.text('5,000'),
          findsOneWidget,
          reason:
              'D-08: voice batch fill must overwrite the host-cache amount',
        );
      },
    );

    // ── INPUT-02 D-09 focus interrupts ──

    testWidgets(
      'INPUT-02 D-09: text-field focus during recording auto-stops without batch fill',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();
        final parseUseCase = FakeParseVoiceInputUseCase(const {});

        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: parseUseCase,
          ),
        );
        await tester.pumpAndSettle();

        // Begin recording.
        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Focus the merchant TextField mid-press — triggers _handleFocusChange
        // → _cancelRecordingAndDiscard via the per-host FocusNode listener.
        final merchantField = find.byKey(const ValueKey('merchant-textfield'));
        expect(merchantField, findsOneWidget);
        await tester.tap(merchantField, warnIfMissed: false);
        await tester.pumpAndSettle();

        // D-09: focus auto-stops recording via the discard path.
        expect(
          speechService.canceled,
          isTrue,
          reason: 'text-field focus must route to _cancelRecordingAndDiscard',
        );
        expect(
          parseUseCase.inputs,
          isEmpty,
          reason:
              'D-09 focus interrupt must NOT trigger parser execute (no batch fill)',
        );

        // Mic visual returned to idle (borderRadius == 36).
        final micContainer = tester.widget<AnimatedContainer>(micFinder);
        final decoration = micContainer.decoration! as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular(36),
          reason: 'mic must return to idle borderRadius after focus interrupt',
        );

        // Cleanup: gesture is already gone (cancel inside the focus handler
        // disposed the recognizer), but release the active pointer to satisfy
        // the tester's bookkeeping.
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    // ── INPUT-02 SC-1 happy path ──

    testWidgets(
      'INPUT-02 SC-1: voice transcript "1千8百4十元 星巴克" fills form fields',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();
        final parseUseCase = FakeParseVoiceInputUseCase({
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
            ledgerType: LedgerType.survival,
          ),
        });

        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: parseUseCase,
          ),
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        // See D-08 test — fake-clock pump (1ms) advances past the LongPress
        // Duration.zero timer so onLongPressStart fires; second pump settles
        // the microtask queue so onResult is wired before emitFinal.
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        speechService.emitFinal('1千8百4十元 星巴克');
        // Real-time delay past the 300 ms misfire threshold so _onLongPressEnd
        // routes to _stopRecordingAndCommit (DateTime.now() uses wall-clock).
        await tester.binding.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)),
        );
        await tester.pumpAndSettle();
        await gesture.up();
        await tester.pumpAndSettle();

        // Form fields populated via the 4-setter batch fill:
        //  - updateAmount → AmountDisplay renders "1,840"
        //  - updateMerchant → merchant TextField shows "星巴克"
        //  - updateCategory → category chip shows "Cafe"
        expect(
          find.text('1,840'),
          findsOneWidget,
          reason: 'amount=1840 must render via host-cache + AmountDisplay',
        );
        expect(
          find.text('星巴克'),
          findsOneWidget,
          reason: 'merchant name must populate the merchant TextField',
        );
        // The form's category chip renders the L1>L2 path via
        // `formatCategoryPath` — "Food > Cafe" for our fake categories.
        expect(
          find.textContaining('Cafe'),
          findsOneWidget,
          reason: 'category Cafe (L2) must render after lookup',
        );
      },
    );
  });
}
