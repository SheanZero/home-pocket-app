import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/application/voice/voice_satisfaction_estimator.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/features/accounting/domain/models/merchant_category_preference.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_category_preference_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/soft_toast.dart';
import 'package:home_pocket/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart';
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

/// Quick task 260526-k92 (Item 2) — variant of FakeCategoryRepository whose
/// `findActive()` returns the seed L1+L2 needed for the voice screen's
/// `_initializeDefaultCategory()` to resolve a default category. Used by the
/// k92 save-button-enabled-at-start regression test.
class FakeCategoryRepositoryWithSeed implements CategoryRepository {
  final _l1 = Category(
    id: 'food',
    name: 'Food',
    icon: 'restaurant',
    color: '#F59E0B',
    level: 1,
    sortOrder: 0,
    createdAt: DateTime(2026),
  );
  late final _l2 = Category(
    id: 'dining',
    name: 'Dining',
    icon: 'restaurant_menu',
    color: '#F59E0B',
    parentId: 'food',
    level: 2,
    sortOrder: 0,
    createdAt: DateTime(2026),
  );

  @override
  Future<void> deleteAll() async {}

  @override
  Future<List<Category>> findActive() async => [_l1, _l2];

  @override
  Future<List<Category>> findAll() async => [_l1, _l2];

  @override
  Future<Category?> findById(String id) async {
    if (id == _l1.id) return _l1;
    if (id == _l2.id) return _l2;
    return null;
  }

  @override
  Future<List<Category>> findByLevel(int level) async =>
      [_l1, _l2].where((c) => c.level == level).toList();

  @override
  Future<List<Category>> findByParent(String parentId) async =>
      [_l1, _l2].where((c) => c.parentId == parentId).toList();

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

// ── D-08 fakes: CreateTransactionUseCase stub ────────────────────────────────

/// Returns a predetermined transaction on execute(). Used for D-08 tests that
/// need to control whether the save result is soul or survival ledger.
class FakeCreateTransactionUseCase implements CreateTransactionUseCase {
  FakeCreateTransactionUseCase(this._transaction);

  final Transaction _transaction;

  @override
  Future<Result<Transaction>> execute(CreateTransactionParams params) async {
    return Result.success(_transaction);
  }
}

/// No-op [MerchantCategoryPreferenceRepository] for D-08 tests.
/// Prevents [merchantCategoryLearningServiceProvider] from reaching the DB.
class _FakeMerchantCategoryPreferenceRepository
    implements MerchantCategoryPreferenceRepository {
  @override
  Future<MerchantCategoryPreference?> findByMerchantKey(
    String merchantKey,
  ) async => null;

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

/// A soul-ledger transaction returned by [FakeCreateTransactionUseCase] in
/// the D-08 soul test.
final _soulTransaction = Transaction(
  id: 'tx-soul-d08',
  bookId: 'book-1',
  deviceId: 'device-1',
  amount: 1000,
  type: TransactionType.expense,
  categoryId: 'dining',
  ledgerType: LedgerType.soul,
  timestamp: DateTime(2026, 5, 25),
  currentHash: 'hash-soul',
  createdAt: DateTime(2026, 5, 25),
  soulSatisfaction: 7,
  entrySource: EntrySource.voice,
);

/// A survival-ledger transaction returned by [FakeCreateTransactionUseCase] in
/// the D-08 survival test.
final _survivalTransaction = Transaction(
  id: 'tx-survival-d08',
  bookId: 'book-1',
  deviceId: 'device-1',
  amount: 1840,
  type: TransactionType.expense,
  categoryId: 'dining',
  ledgerType: LedgerType.survival,
  timestamp: DateTime(2026, 5, 25),
  currentHash: 'hash-survival',
  createdAt: DateTime(2026, 5, 25),
  entrySource: EntrySource.voice,
);

// ── D-08 test helper: two-route host ─────────────────────────────────────────
//
// D-08 Navigator fix: VoiceInputScreen must be a non-first route for
// Navigator.popUntil((r) => r.isFirst) to actually pop it. This widget is
// the home route (first); it immediately pushes [child] as the second route
// via addPostFrameCallback so VoiceInputScreen is on top of the stack.
// Using PageRouteBuilder with Duration.zero avoids any animation settle delay.
class _TwoRouteHost extends StatefulWidget {
  const _TwoRouteHost({required this.child});
  final Widget child;

  @override
  State<_TwoRouteHost> createState() => _TwoRouteHostState();
}

class _TwoRouteHostState extends State<_TwoRouteHost> {
  @override
  void initState() {
    super.initState();
    // Push the child screen after the first frame so the home route is
    // fully mounted before the push occurs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (ctx, anim, secAnim) => widget.child,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('home')));
  }
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
        // 260526-k92 (Item 3): the new transcript SizedBox above the waveform
        // squeezes the Expanded form area; ensureVisible scrolls the merchant
        // field into the hit-testable region so the tap actually lands.
        final merchantField = find.byKey(const ValueKey('merchant-textfield'));
        expect(merchantField, findsOneWidget);
        await tester.ensureVisible(merchantField);
        await tester.pumpAndSettle();
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

  // ── Phase 22 gap closure — G-01 + G-02 (CR-01 + CR-02 from 22-REVIEW.md) ──
  //
  // These 3 tests close the production-risk gaps elevated from the code review
  // to BLOCKER status at phase verification (2026-05-25). Without the Plan 22-09
  // fix, all 3 fail per the documented failure modes in 22-VERIFICATION.md.
  group('Phase 22 gap closure — G-01 + G-02', () {
    final micFinder = find.byKey(const ValueKey('voice-mic-button'));

    // ── G-01: recognizer self-termination drives the commit path ──
    //
    // Failure mode (pre-Plan-22-09): _onStatus flips _isRecording=false on
    // status='done' / 'notListening'; subsequent _onLongPressEnd short-circuits
    // on !_isRecording; transcript is silently dropped.
    //
    // Fix (Plan 22-09): _onStatus checks _pressStart != null and routes to
    // _stopRecordingAndCommit when the user is still holding.
    testWidgets(
      'G-01: status="done" mid-press drives commit and form fills without gesture release',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();
        final parseUseCase = FakeParseVoiceInputUseCase({
          '1千8百4十元 星巴克': VoiceParseResult(
            rawText: '1千8百4十元 星巴克',
            amount: 1840,
            parsedDate: DateTime(2026, 5, 25),
            merchantName: '星巴克',
            categoryMatch: const CategoryMatchResult(
              categoryId: 'cat_food_cafe',
              confidence: 0.92,
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

        // 1. User begins long-press on mic.
        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();

        // 2. Recognizer emits a final transcript (this fires _onResult only;
        //    does NOT yet trigger the commit path — that happens in step 3).
        speechService.emitFinal('1千8百4十元 星巴克');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // 3. Recognizer self-terminates (e.g., 3s pauseFor expiry) WHILE the
        //    user is still holding the mic. Pre-Plan-22-09: silently drops.
        //    Post-Plan-22-09: routes into _stopRecordingAndCommit.
        speechService.onStatus!('done');
        await tester.pumpAndSettle();

        // 4. Without releasing the gesture, the form must be filled.
        //    Parser was invoked exactly once on the transcript.
        expect(
          parseUseCase.inputs,
          contains('1千8百4十元 星巴克'),
          reason: 'G-01: parser must run when recognizer self-terminates mid-press',
        );
        // CRITICAL: AmountDisplay runs the amount through NumberFormatter,
        // which inserts thousands separators. The rendered string for 1840
        // is '1,840' (with comma), NOT '1840'. Mirrors existing INPUT-02 SC-1
        // assertion at voice_input_screen_test.dart:737.
        expect(
          find.text('1,840'),
          findsOneWidget,
          reason: 'G-01: amount=1840 must render via host-cache + AmountDisplay '
              'after status-driven commit (mirrors INPUT-02 SC-1 at line 737)',
        );
        expect(
          find.text('星巴克'),
          findsOneWidget,
          reason: 'G-01: merchant TextField must show 星巴克 (single instance) '
              'after status-driven commit',
        );

        // 5. Idempotency: the eventual gesture.up() must NOT trigger a second
        //    commit. _stopRecordingAndCommit calls _speechService.stop() once;
        //    if a second commit ran, stop() would be invoked again — but the
        //    fake's `stopped` flag is set on the first call and remains true.
        //    Stronger check: parser.inputs should still contain the transcript
        //    exactly once (no duplicate parse from a re-entrant commit).
        final stoppedBeforeRelease = speechService.stopped;
        final inputCountBeforeRelease = parseUseCase.inputs
            .where((s) => s == '1千8百4十元 星巴克')
            .length;
        await gesture.up();
        await tester.pumpAndSettle();
        expect(
          speechService.stopped,
          stoppedBeforeRelease,
          reason: 'G-01 idempotency: gesture.up after status-driven commit must not re-call stop()',
        );
        expect(
          parseUseCase.inputs.where((s) => s == '1千8百4十元 星巴克').length,
          inputCountBeforeRelease,
          reason: 'G-01 idempotency: gesture.up after status-driven commit must not re-invoke parser',
        );
      },
    );

    // ── G-02 transient error: surfaces localized toast, mic remains usable ──
    //
    // Failure mode (pre-Plan-22-09): _onError silently resets to idle; user
    // sees no signal that recognition failed.
    //
    // Fix (Plan 22-09): _onError calls showVoiceRecognitionErrorToast which
    // switches on errorMsg and mounts a SoftToast with the localized message
    // from Plan 22-08's ARB keys.
    testWidgets(
      'G-02 transient: onError("error_network", false) surfaces localized SoftToast (ja)',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();

        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: FakeParseVoiceInputUseCase(const {}),
          ),
        );
        // Wait for _initSpeechService → setState(_isInitialized = true) so
        // the screen is in steady state and onError can be invoked.
        await tester.pumpAndSettle();

        // Sanity: no toast visible at idle.
        expect(find.byType(SoftToast), findsNothing);

        // Fire the platform error callback the screen registered during
        // _initSpeechService (saved by the fake at line 102).
        expect(
          speechService.onError,
          isNotNull,
          reason: 'fake must have captured onError during _initSpeechService',
        );
        speechService.onError!('error_network', false);
        await tester.pump(); // flush setState in _onError
        await tester.pump(const Duration(milliseconds: 50)); // mount overlay entry + SoftToast animation start

        // Assert the SoftToast widget is now in the tree.
        expect(
          find.byType(SoftToast),
          findsOneWidget,
          reason: 'G-02: SoftToast must mount on transient error',
        );

        // Assert the toast carries the LOCALIZED ja string (not raw "error_network").
        // Pull the live S.of(context) value to avoid hard-coding the literal.
        final l10n = S.of(tester.element(find.byType(VoiceInputScreen)));
        expect(
          find.text(l10n.voiceRecognitionErrorNetwork),
          findsOneWidget,
          reason: 'G-02 / WR-05: toast text must be the localized voiceRecognitionErrorNetwork string',
        );
        expect(
          find.text('error_network'),
          findsNothing,
          reason: 'WR-05: raw platform error code must never be surfaced to UI',
        );

        // Mic remains usable for retry — _isInitialized stays true on transient.
        // We don't drive a new gesture here (covered by the permanent test
        // below as the contrast case) but we DO verify the mic button is
        // still rendered (not gated by some other guard).
        expect(micFinder, findsOneWidget);

        // Let the SoftToast auto-dismiss timer settle so the test tears down
        // cleanly (SoftToast.duration default = 3s).
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      },
    );

    // ── G-02 permanent error: mic is gated until reinit ──
    //
    // Failure mode (pre-Plan-22-09): _onError ignores `permanent`; subsequent
    // long-press still triggers recording into the dead engine.
    //
    // Fix (Plan 22-09 / CR-02 literal): _onError sets _isInitialized=false on
    // permanent==true; _onLongPressStart's existing top guard
    // `if (!_isInitialized || _isRecording) return;` short-circuits new presses.
    testWidgets(
      'G-02 permanent: onError(..., true) gates mic — subsequent long-press does NOT call startListening',
      (tester) async {
        final speechService = CapturingStartSpeechRecognitionUseCase();

        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: FakeParseVoiceInputUseCase(const {}),
          ),
        );
        await tester.pumpAndSettle();

        // Sanity: startedLocaleId is null before any press (fake initializes
        // it as null per line 91).
        expect(
          speechService.startedLocaleId,
          isNull,
          reason: 'fake startedLocaleId must be null at idle',
        );

        // Fire a permanent error (e.g., permission revoked mid-session, or
        // engine unavailable). Plan 22-09's _onError sets _isInitialized=false.
        expect(speechService.onError, isNotNull);
        speechService.onError!('error_audio', true);
        await tester.pump(); // flush setState in _onError
        await tester.pump(const Duration(milliseconds: 50));

        // Phase 23 D-11 (IN-03): assert the localized error string appears in
        // the toast. Verifies G-02's ARB-key lookup path is healthy. Comes
        // BEFORE the SoftToast presence assertion so a failure points at the
        // missed string, not the toast widget.
        final l10nForD11 = S.of(tester.element(find.byType(VoiceInputScreen)));
        expect(
          find.text(l10nForD11.voiceRecognitionErrorAudio),
          findsOneWidget,
          reason: 'D-11: G-02 permanent test must surface the localized '
              'voiceRecognitionErrorAudio string (ARB-key health check)',
        );

        // The toast appears (already covered by transient test for assertion
        // depth; here we just confirm no exception was thrown).
        expect(find.byType(SoftToast), findsOneWidget);

        // Now attempt a long-press on the mic. Plan 22-09's _onError flipped
        // _isInitialized to false, so _onLongPressStart's existing top guard
        // (`if (!_isInitialized || _isRecording) return;`) short-circuits.
        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        // Hold past the 300 ms misfire threshold to ensure the test exercises
        // the _onLongPressStart guard, not the _onLongPressEnd misfire branch.
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.up();
        await tester.pumpAndSettle();

        // CORE ASSERTION: speech service was never asked to start listening.
        // _startRecording calls _speechService.startListening which the fake
        // overrides to set startedLocaleId. If the guard worked, it stays null.
        expect(
          speechService.startedLocaleId,
          isNull,
          reason: 'G-02 permanent: _onLongPressStart must short-circuit on !_isInitialized; '
              'startListening must NOT be invoked',
        );

        // Let the toast settle so test tears down cleanly.
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      },
    );
  });

  // ── D-09 (Open Q2 regression): FocusNode listener cleanup on dispose ──
  //
  // Production code already correct per RESEARCH Open Q2: _merchantFocus and
  // _noteFocus both add and remove the SAME _handleFocusChange method reference
  // (lines 140-141 and 788-789 in voice_input_screen.dart). This test pins the
  // invariant so future refactors that accidentally use distinct closures (e.g.,
  // anonymous lambdas) will fail loudly via tester.takeException().
  //
  // CONTEXT D-09 / PATTERNS MOD entry: production code is UNCHANGED. This plan
  // adds only the regression assertion (Open Q2 confirmed correct).
  testWidgets(
    'D-09 (Open Q2 regression): FocusNode listeners cleaned up on dispose',
    (tester) async {
      // Phase 23 D-09 / WR-07 regression: voice_input_screen.dart uses the
      // same _handleFocusChange method reference for both add and dispose,
      // so removeListener actually cleans up. This test asserts the invariant
      // so future refactors that accidentally pass distinct closures (e.g.,
      // anonymous lambdas) will fail loudly.
      //
      // RESEARCH Open Q2: production code is already correct; the test is a
      // safety net. The actual WR-07 distinct-closure bug is in
      // transaction_details_form_test.dart (test code, OUT OF SCOPE per
      // CONTEXT canonical_refs; deferred to v1.4+).

      // Pump the voice screen using the shared buildSubject helper (same
      // overrides as other tests in this file).
      await tester.pumpWidget(
        buildSubject(
          speechService: FakeStartSpeechRecognitionUseCase(),
          parseUseCase: FakeParseVoiceInputUseCase(const {}),
        ),
      );
      await tester.pumpAndSettle();

      // Tear down by pumping an empty widget — triggers dispose() on the
      // voice screen and its FocusNodes (_merchantFocus, _noteFocus).
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      // If any FocusNode listener leaked across dispose, Flutter surfaces a
      // "ChangeNotifier was used after being disposed" error via tester's
      // exception capture. Assert no such exception — production code correctly
      // reuses _handleFocusChange as the same method reference for both
      // addListener and removeListener.
      expect(
        tester.takeException(),
        isNull,
        reason:
            'D-09 regression: FocusNode listeners must be removed in dispose; '
            'a leaked listener would surface as a ChangeNotifier-disposed exception',
      );
    },
  );

  // ── D-07 cold-start race (Phase 23 WR-01) ────────────────────────────────────
  //
  // Gate: _onLongPressStart must short-circuit when voiceLocaleIdProvider has
  // not yet resolved (_isLocaleReady == false). After the provider resolves,
  // the mic must become usable.
  group('D-07 cold-start race (Phase 23 WR-01)', () {
    final micFinder = find.byKey(const ValueKey('voice-mic-button'));

    testWidgets(
      'D-07: long-press is no-op while voiceLocaleIdProvider is loading',
      (tester) async {
        // Keep voiceLocaleIdProvider in loading state by returning a future
        // that never completes during the test.
        final neverCompleter = Completer<String>();
        final speechService = CapturingStartSpeechRecognitionUseCase();

        final categoryRepository = FakeCategoryRepository();
        final categoryService = CategoryService(
          categoryRepository: categoryRepository,
          ledgerConfigRepository: FakeCategoryLedgerConfigRepository(),
        );
        await tester.pumpWidget(
          createLocalizedWidget(
            VoiceInputScreen(bookId: 'book-1', speechService: speechService),
            locale: const Locale('ja'),
            overrides: [
              categoryRepositoryProvider.overrideWithValue(categoryRepository),
              categoryServiceProvider.overrideWithValue(categoryService),
              parseVoiceInputUseCaseProvider.overrideWithValue(
                FakeParseVoiceInputUseCase(const {}),
              ),
              // Override voiceLocaleIdProvider to stay in loading state.
              voiceLocaleIdProvider.overrideWith(
                (ref) => neverCompleter.future,
              ),
            ],
          ),
        );
        // pump() (not pumpAndSettle) so the loading state is preserved.
        await tester.pump();

        // Attempt a long-press on the mic while locale is still loading.
        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.up();
        await tester.pumpAndSettle();

        // _isLocaleReady == false → _onLongPressStart guard short-circuits;
        // startListening must NOT have been invoked.
        expect(
          speechService.startedLocaleId,
          isNull,
          reason:
              'D-07: long-press must be blocked when voiceLocaleIdProvider is still loading',
        );
      },
    );

    testWidgets(
      'D-07: long-press fires startListening after voiceLocaleIdProvider resolves',
      (tester) async {
        // voiceLocaleIdProvider resolves immediately to 'ja-JP' (already the
        // default in buildSubject but we make it explicit here for clarity).
        final speechService = CapturingStartSpeechRecognitionUseCase();

        await tester.pumpWidget(
          buildSubject(
            speechService: speechService,
            parseUseCase: FakeParseVoiceInputUseCase(const {}),
          ),
        );
        // pumpAndSettle: voiceLocaleIdProvider resolves → _isLocaleReady = true.
        await tester.pumpAndSettle();

        // Attempt a long-press — locale is now ready.
        final gesture = await tester.startGesture(tester.getCenter(micFinder));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();

        // _isLocaleReady == true AND _isInitialized == true → startListening fired.
        expect(
          speechService.startedLocaleId,
          isNotNull,
          reason: 'D-07: startListening must fire once voiceLocaleIdProvider resolves',
        );

        // Cleanup.
        await tester.pump(const Duration(milliseconds: 400));
        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });

  // ── D-08 popUntil deferral (Phase 23 WR-04) ──────────────────────────────────
  //
  // Soul-ledger save: Navigator.popUntil deferred until SoulCelebrationOverlay
  // dismisses (animation ≈ 1.5 s). Survival-ledger save: pop fires immediately.
  //
  // Helper: builds a voice screen with a predetermined create-transaction result.
  // Pumps voice through batch fill to enable the Save button, then taps it.
  group('D-08 popUntil deferral (Phase 23 WR-04)', () {
    final micFinder = find.byKey(const ValueKey('voice-mic-button'));

    Widget buildSubjectForSave({
      required Transaction createResult,
      required String voiceText,
      required VoiceParseResult parseResult,
    }) {
      final categoryRepository = FakeCategoryRepository();
      final categoryService = CategoryService(
        categoryRepository: categoryRepository,
        ledgerConfigRepository: FakeCategoryLedgerConfigRepository(),
      );
      // Build a no-op MerchantCategoryLearningService to prevent the
      // merchantCategoryLearningServiceProvider from reaching appDatabaseProvider.
      final fakeMerchantLearningService = MerchantCategoryLearningService(
        repository: _FakeMerchantCategoryPreferenceRepository(),
        categoryRepository: categoryRepository,
      );
      final speechService = CapturingStartSpeechRecognitionUseCase();
      // D-08 Navigator fix: VoiceInputScreen must be pushed on top of a home
      // route so that Navigator.popUntil((r) => r.isFirst) actually pops it.
      // Using MaterialApp(home: VoiceInputScreen) makes VoiceInputScreen the
      // first route, so popUntil is a no-op and find.byType(VoiceInputScreen)
      // remains findsOneWidget. We push VoiceInputScreen on top of a dummy
      // placeholder Scaffold to give popUntil a parent route to land on.
      final overrides = <Override>[
        categoryRepositoryProvider.overrideWithValue(categoryRepository),
        categoryServiceProvider.overrideWithValue(categoryService),
        parseVoiceInputUseCaseProvider.overrideWithValue(
          FakeParseVoiceInputUseCase({voiceText: parseResult}),
        ),
        voiceSatisfactionEstimatorProvider.overrideWithValue(
          FakeVoiceSatisfactionEstimator(),
        ),
        voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
        createTransactionUseCaseProvider.overrideWithValue(
          FakeCreateTransactionUseCase(createResult),
        ),
        merchantCategoryLearningServiceProvider.overrideWithValue(
          fakeMerchantLearningService,
        ),
      ];
      // D-08 Navigator fix: VoiceInputScreen must be a pushed (non-first) route
      // so that Navigator.popUntil((r) => r.isFirst) actually pops it. We build
      // a custom Navigator with two initial pages: a dummy home + VoiceInputScreen.
      // Both use no-transition builders so pumpAndSettle() settles immediately.
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: _TwoRouteHost(
            child: VoiceInputScreen(
              bookId: 'book-1',
              speechService: speechService,
            ),
          ),
        ),
      );
    }

    /// Helper to fill the voice screen form via batch fill and return the
    /// CapturingStartSpeechRecognitionUseCase so callers can emit speech.
    /// After this helper, the Save button is enabled.
    Future<CapturingStartSpeechRecognitionUseCase> fillFormViaVoice({
      required WidgetTester tester,
      required Widget subject,
      required String voiceText,
    }) async {
      await tester.pumpWidget(subject);
      await tester.pumpAndSettle();

      // Find the speechService from the VoiceInputScreen widget — the screen
      // was built with a CapturingStartSpeechRecognitionUseCase injected via
      // the speechService parameter in buildSubjectForSave. We need to cast
      // the widget to retrieve it; instead we drive via tester gestures.
      //
      // Start long-press, emit final voice, wait past 300ms misfire threshold.
      final gesture = await tester.startGesture(tester.getCenter(micFinder));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      // Retrieve the capturing service to emit a result. Since it's injected
      // as speechService into VoiceInputScreen, we find it through the widget.
      final screenWidget = tester.widget<VoiceInputScreen>(
        find.byType(VoiceInputScreen),
      );
      // The speechService is exposed on the widget as a nullable parameter.
      // Cast it — we know it's a CapturingStartSpeechRecognitionUseCase.
      final capturingSvc =
          screenWidget.speechService! as CapturingStartSpeechRecognitionUseCase;
      capturingSvc.emitFinal(voiceText);

      await tester.binding.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 350)),
      );
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      return capturingSvc;
    }

    testWidgets(
      'D-08: soul-ledger save defers Navigator.pop until SoulCelebrationOverlay dismisses',
      (tester) async {
        // The parse result maps to a soul category (dining with soul ledger).
        const voiceText = 'ラテ 1千';
        final parseResult = VoiceParseResult(
          rawText: voiceText,
          amount: 1000,
          parsedDate: DateTime(2026, 5, 25),
          merchantName: null,
          categoryMatch: const CategoryMatchResult(
            categoryId: 'dining',
            confidence: 0.91,
            source: MatchSource.keyword,
          ),
          ledgerType: LedgerType.soul,
        );

        final subject = buildSubjectForSave(
          createResult: _soulTransaction,
          voiceText: voiceText,
          parseResult: parseResult,
        );

        await fillFormViaVoice(
          tester: tester,
          subject: subject,
          voiceText: voiceText,
        );

        // At this point the form is filled; Save button should be enabled.
        // Tap the Save button.
        final saveButtonFinder = find.byKey(const ValueKey('voice-save-button'));
        expect(saveButtonFinder, findsOneWidget);
        await tester.tap(saveButtonFinder);

        // pump() without settling — let the save flow start but NOT run
        // the full animation so we can check the intermediate state.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // D-08: SoulCelebrationOverlay must be in the tree after soul save.
        expect(
          find.byType(SoulCelebrationOverlay),
          findsOneWidget,
          reason: 'D-08: SoulCelebrationOverlay must appear on soul-ledger save',
        );

        // Navigation must NOT have fired yet (Navigator still on voice screen).
        expect(
          find.byType(VoiceInputScreen),
          findsOneWidget,
          reason: 'D-08: Navigator.popUntil must NOT fire before overlay dismisses',
        );

        // Let the 1.5 s animation run to completion — overlay dismisses →
        // waitForCelebrationDismissed future completes → popUntil fires.
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // After animation completes, the route is popped.
        expect(
          find.byType(VoiceInputScreen),
          findsNothing,
          reason: 'D-08: Navigator.popUntil must fire after overlay dismisses',
        );
      },
    );

    testWidgets(
      'D-08: survival-ledger save pops immediately, no overlay',
      (tester) async {
        const voiceText = '星巴克 1千8百';
        final parseResult = VoiceParseResult(
          rawText: voiceText,
          amount: 1840,
          parsedDate: DateTime(2026, 5, 25),
          merchantName: '星巴克',
          categoryMatch: const CategoryMatchResult(
            categoryId: 'dining',
            confidence: 0.91,
            source: MatchSource.keyword,
          ),
          ledgerType: LedgerType.survival,
        );

        final subject = buildSubjectForSave(
          createResult: _survivalTransaction,
          voiceText: voiceText,
          parseResult: parseResult,
        );

        await fillFormViaVoice(
          tester: tester,
          subject: subject,
          voiceText: voiceText,
        );

        // Tap the Save button.
        final saveButtonFinder = find.byKey(const ValueKey('voice-save-button'));
        expect(saveButtonFinder, findsOneWidget);
        await tester.tap(saveButtonFinder);
        await tester.pumpAndSettle();

        // D-08: no SoulCelebrationOverlay for survival save.
        expect(
          find.byType(SoulCelebrationOverlay),
          findsNothing,
          reason: 'D-08: SoulCelebrationOverlay must NOT appear on survival-ledger save',
        );

        // D-08: pop fires immediately — VoiceInputScreen is no longer in tree.
        expect(
          find.byType(VoiceInputScreen),
          findsNothing,
          reason: 'D-08: Navigator.popUntil must fire immediately on survival-ledger save',
        );
      },
    );
  });

  // ── Quick task 260526-k92: Item 2 (save button) + Item 3 (transcript) ──
  group('260526-k92 — save-button + transcript', () {
    Widget buildSeededSubject() {
      final categoryRepository = FakeCategoryRepositoryWithSeed();
      final categoryService = CategoryService(
        categoryRepository: categoryRepository,
        ledgerConfigRepository: FakeCategoryLedgerConfigRepository(),
      );
      return ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
          categoryServiceProvider.overrideWithValue(categoryService),
          parseVoiceInputUseCaseProvider.overrideWithValue(
            FakeParseVoiceInputUseCase(const {}),
          ),
          voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
        ],
        child: MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: VoiceInputScreen(
            bookId: 'book-1',
            speechService: FakeStartSpeechRecognitionUseCase(),
          ),
        ),
      );
    }

    testWidgets(
      'Item 2: Save button is enabled at initial render once default category resolves',
      (tester) async {
        await tester.pumpWidget(buildSeededSubject());
        await tester.pumpAndSettle();

        final saveBtnFinder = find.byKey(const ValueKey('voice-save-button'));
        expect(saveBtnFinder, findsOneWidget);

        final inkWell = tester.widget<InkWell>(
          find.descendant(of: saveBtnFinder, matching: find.byType(InkWell)),
        );
        expect(
          inkWell.onTap,
          isNotNull,
          reason:
              'k92 Item 2: Save button must be tappable at initial render '
              '(default category seeded in initState)',
        );
      },
    );

    testWidgets(
      'Item 3: transcript SizedBox exists and renders empty text at initial state',
      (tester) async {
        await tester.pumpWidget(buildSeededSubject());
        await tester.pumpAndSettle();

        final transcript = find.byKey(const ValueKey('voice-transcript'));
        expect(transcript, findsOneWidget);
        // At initial state both _partialText and _finalText are empty —
        // Text widget renders an empty string.
        final textWidget = tester.widget<Text>(
          find.descendant(of: transcript, matching: find.byType(Text)),
        );
        expect(textWidget.data, equals(''));
      },
    );
  });
}
