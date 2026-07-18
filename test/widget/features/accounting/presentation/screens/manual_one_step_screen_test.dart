import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_riverpod/misc.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        categoryRepositoryProvider,
        createTransactionUseCaseProvider,
        categoryServiceProvider;
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/features/voice/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/voice/domain/models/recognition_outcome.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show
        merchantCategoryLearningServiceProvider,
        parseVoiceInputUseCaseProvider;
import 'package:home_pocket/features/accounting/presentation/screens/manual_one_step_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/amount_display.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/confidence_band_indicator.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/hold_to_talk_bar.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/keyboard_toolbar.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/unified_voice_entry_dock.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart'
    show voiceLocaleIdProvider;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes / Mocks ──────────────────────────────────────────────────────────────

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository(this.categories);

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

/// SlowFakeCategoryRepository — delays findActive() to simulate async race (P19-W1).
class SlowFakeCategoryRepository extends FakeCategoryRepository {
  SlowFakeCategoryRepository(
    super.categories, {
    this.delay = const Duration(seconds: 2),
  });

  final Duration delay;

  @override
  Future<List<Category>> findActive() async {
    await Future<void>.delayed(delay);
    return super.findActive();
  }
}

class _DelayedFindByIdCategoryRepository extends FakeCategoryRepository {
  _DelayedFindByIdCategoryRepository(
    super.categories, {
    required this.delayedCategoryId,
  });

  final String delayedCategoryId;
  final gate = Completer<void>();
  bool isWaiting = false;
  bool _didDelay = false;

  @override
  Future<Category?> findById(String id) async {
    if (id == delayedCategoryId && !_didDelay) {
      _didDelay = true;
      isWaiting = true;
      await gate.future;
      isWaiting = false;
    }
    return super.findById(id);
  }
}

class _ControlledFindActiveCategoryRepository extends FakeCategoryRepository {
  _ControlledFindActiveCategoryRepository(super.categories);

  Completer<void>? nextGate;
  bool isWaiting = false;

  @override
  Future<List<Category>> findActive() async {
    final gate = nextGate;
    nextGate = null;
    if (gate != null) {
      isWaiting = true;
      await gate.future;
      isWaiting = false;
    }
    return super.findActive();
  }
}

class MockCreateTransactionUseCase extends Mock
    implements CreateTransactionUseCase {}

class MockCategoryService extends Mock implements CategoryService {}

class _MockMerchantCategoryLearningService extends Mock
    implements MerchantCategoryLearningService {}

class FakeCreateTransactionParams extends Fake
    implements CreateTransactionParams {}

// ── Test fixtures ──────────────────────────────────────────────────────────────

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

final _alternateL2Category = Category(
  id: 'cafe',
  name: 'Cafe',
  icon: 'local_cafe',
  color: '#E85A4F',
  parentId: 'food',
  level: 2,
  sortOrder: 2,
  createdAt: DateTime(2026, 4, 3),
);

final _fakeCategories = [_l1Category, _l2Category];

// ── 260622-nhs PTT fakes ───────────────────────────────────────────────────

class _CapturingSpeechService implements StartSpeechRecognitionUseCase {
  void Function(SpeechRecognitionResult result)? onResult;
  void Function(String status)? onStatus;
  String? startedLocaleId;
  var stopped = false;
  var canceled = false;
  var startCount = 0;
  var cancelCount = 0;
  var available = true;
  Completer<void>? cancelGate;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async {
    this.onStatus = onStatus;
    return available;
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
    bool allowOnDeviceFallback = true,
  }) async {
    this.onResult = onResult;
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
    startedLocaleId = null;
    final gate = cancelGate;
    if (gate != null) await gate.future;
  }

  void emitFinal(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.95)], true),
  );

  void emitPartial(String words) => onResult!(
    SpeechRecognitionResult([SpeechRecognitionWords(words, null, 0.95)], false),
  );

  /// 260622-nhs R6: drive a recognizer status (e.g. 'done'/'notListening') so a
  /// one-shot session can self-terminate in the widget test.
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

class _DelayedParseVoiceInputUseCase implements ParseVoiceInputUseCase {
  _DelayedParseVoiceInputUseCase(this.result);

  final VoiceParseResult result;
  final gate = Completer<void>();
  bool isWaiting = false;

  @override
  Future<Result<VoiceParseResult>> execute(
    String recognizedText, {
    String? localeId,
    List<String> alternateTexts = const [],
  }) async {
    isWaiting = true;
    await gate.future;
    isWaiting = false;
    return Result.success(result);
  }
}

class _OutOfOrderParseVoiceInputUseCase implements ParseVoiceInputUseCase {
  _OutOfOrderParseVoiceInputUseCase({
    required this.partialText,
    required this.partialResult,
    required this.finalText,
    required this.finalResult,
  });

  final String partialText;
  final VoiceParseResult partialResult;
  final String finalText;
  final VoiceParseResult finalResult;
  final partialGate = Completer<void>();
  bool partialIsWaiting = false;

  @override
  Future<Result<VoiceParseResult>> execute(
    String recognizedText, {
    String? localeId,
    List<String> alternateTexts = const [],
  }) async {
    if (recognizedText == partialText) {
      partialIsWaiting = true;
      await partialGate.future;
      partialIsWaiting = false;
      return Result.success(partialResult);
    }
    if (recognizedText == finalText) return Result.success(finalResult);
    return Result.error('unexpected input: $recognizedText');
  }
}

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

UnifiedVoiceEntryDock _voiceDock(WidgetTester tester) =>
    tester.widget<UnifiedVoiceEntryDock>(find.byType(UnifiedVoiceEntryDock));

Future<void> _finishVoiceUtterance(
  WidgetTester tester,
  _CapturingSpeechService speech,
) async {
  speech.startedLocaleId = null;
  speech.emitStatus('done');
  await tester.pump();
  await tester.pump();
}

Future<void> _switchVoiceDockToKeyboard(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('unified-voice-keyboard')));
  await tester.pump();
  await tester.pump();
}

Future<void> _openVoiceDockAndStart(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('voice-record-bar')));
  await tester.pump();
  await tester.pump();
  await tester.tap(find.byKey(const Key('unified-voice-core')));
  await tester.pump();
  await tester.pump();
}

// ── Test helpers ───────────────────────────────────────────────────────────────

Widget _pumpScreen({
  required MockCreateTransactionUseCase mockCreateUseCase,
  required FakeCategoryRepository fakeCategoryRepo,
  MockCategoryService? mockCategoryService,
  int? initialAmount,
  Category? initialCategory,
  EntrySource entrySource = EntrySource.manual,
  VoidCallback? onHistoryTap,
}) {
  final overrides = <Override>[
    categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
    createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
    if (mockCategoryService != null)
      categoryServiceProvider.overrideWithValue(mockCategoryService),
  ];

  return createLocalizedWidget(
    ManualOneStepScreen(
      bookId: 'book-1',
      initialAmount: initialAmount,
      initialCategory: initialCategory,
      entrySource: entrySource,
      onHistoryTap: onHistoryTap,
    ),
    locale: const Locale('en'),
    overrides: overrides,
  );
}

void main() {
  late MockCreateTransactionUseCase mockCreateUseCase;
  late MockCategoryService mockCategoryService;
  late _MockMerchantCategoryLearningService mockLearningService;

  setUpAll(() {
    registerFallbackValue(FakeCreateTransactionParams());
  });

  setUp(() {
    mockCreateUseCase = MockCreateTransactionUseCase();
    mockCategoryService = MockCategoryService();
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

  // ── SC-1: single screen, no Next button, all six field surfaces ─────────────

  testWidgets('SC-1: no Next/下一步/次へ button visible after mount', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
        mockCategoryService: mockCategoryService,
      ),
    );
    await tester.pumpAndSettle();

    // SC-1 assertion: no Next variants in any locale
    expect(find.text('Next'), findsNothing);
    expect(find.text('下一步'), findsNothing);
    expect(find.text('次へ'), findsNothing);

    // All six field surfaces visible
    expect(find.byType(AmountDisplay), findsOneWidget);
    // 260622-nhs (D-3): the 手工/语音 mode Tab is gone — single-page entry. The
    // EntryModeSwitcher widget was deleted entirely; its absence is proven by
    // the presence of the resident keypad + push-to-talk bar instead.
    // 260622-nhs R2: the full-width 「语音记录」 bar sits ABOVE the keypad.
    expect(find.byType(VoiceRecordBar), findsOneWidget);
    expect(find.byKey(const ValueKey('category-chip')), findsOneWidget);
    expect(find.byKey(const ValueKey('date-chip')), findsOneWidget);
    expect(find.byKey(const ValueKey('merchant-textfield')), findsOneWidget);
    expect(find.byKey(const ValueKey('note-textfield')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('manual-entry-history-action')),
      findsNothing,
      reason: 'history remains host-owned and is absent without a callback',
    );
  });

  testWidgets(
    'V16 screen contract: amount, keypad, continuous toggle, and optional history',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var historyTaps = 0;

      await tester.pumpWidget(
        _pumpScreen(
          mockCreateUseCase: mockCreateUseCase,
          fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
          mockCategoryService: mockCategoryService,
          initialAmount: 123,
          initialCategory: _l2Category,
          onHistoryTap: () => historyTaps++,
        ),
      );
      await tester.pumpAndSettle();

      final amountDisplay = tester.widget<AmountDisplay>(
        find.byType(AmountDisplay),
      );
      expect(amountDisplay.layout, AmountDisplayLayout.v16);
      expect(tester.getSize(find.byType(AmountDisplay)).height, 72);
      expect(
        tester.getSize(find.byKey(const ValueKey('amount_currency_badge'))),
        const Size(67, 36),
      );
      final amountText = find.descendant(
        of: find.byType(AmountDisplay),
        matching: find.text('123'),
      );
      expect(
        tester
            .getCenter(find.byKey(const ValueKey('amount_currency_badge')))
            .dx,
        lessThan(tester.getCenter(amountText).dx),
        reason:
            'V16 places the currency action before the right-aligned amount',
      );

      final keyboard = tester.widget<SmartKeyboard>(find.byType(SmartKeyboard));
      expect(keyboard.useV16Layout, isTrue);
      expect(keyboard.isActionEnabled, isTrue);
      expect(
        find.byKey(const ValueKey('smart_keyboard_dot_disabled')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SmartKeyboard),
          matching: find.text('.'),
        ),
        findsOneWidget,
        reason: 'V16 keeps the gated JPY dot visible but non-interactive',
      );

      final continuous = find.byKey(
        const ValueKey('manual-entry-continuous-control'),
      );
      expect(tester.getBottomRight(continuous).dy, 900);
      expect(
        tester.getSize(continuous).width,
        230,
        reason: 'only the centered red-box region is interactive',
      );
      final l10n = S.of(tester.element(continuous));
      final returnHome = find.descendant(
        of: continuous,
        matching: find.text(l10n.entryContinuousReturnHome),
      );
      final enableContinuous = find.descendant(
        of: continuous,
        matching: find.text(l10n.entryContinuousEnable),
      );
      expect(returnHome, findsOneWidget);
      expect(enableContinuous, findsOneWidget);
      final rowLeft = tester.getRect(returnHome).left;
      final rowRight = tester.getRect(enableContinuous).right;
      expect(
        (rowLeft + rowRight) / 2,
        closeTo(tester.getCenter(continuous).dx, 0.5),
        reason: 'summary + action form one centered inline control',
      );
      expect(
        tester.getRect(enableContinuous).left -
            tester.getRect(returnHome).right,
        allOf(greaterThan(0), lessThanOrEqualTo(6)),
        reason: 'the localized row may scale down, but remains visibly spaced',
      );
      expect(
        tester
            .widgetList<Material>(
              find.descendant(of: continuous, matching: find.byType(Material)),
            )
            .where((material) => material.shape is StadiumBorder),
        isEmpty,
        reason: 'the continuous-entry action is inline, not a pill',
      );
      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(continuous),
        isSemantics(
          label:
              '${l10n.entryContinuousReturnHome} ${l10n.entryContinuousEnable}',
          isButton: true,
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );

      await tester.tapAt(Offset(8, tester.getCenter(continuous).dy));
      await tester.pump();
      expect(
        find.text(l10n.entryContinuousReturnHome),
        findsOneWidget,
        reason: 'a bottom-corner tap outside the centered target is ignored',
      );

      await tester.tap(continuous);
      await tester.pump();
      expect(find.text(l10n.entryContinuousKeepNext), findsOneWidget);
      expect(find.text(l10n.entryContinuousDisable), findsOneWidget);
      expect(
        tester.getSemantics(continuous),
        isSemantics(
          label:
              '${l10n.entryContinuousKeepNext} ${l10n.entryContinuousDisable}',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );

      final history = find.byKey(const ValueKey('manual-entry-history-action'));
      expect(history, findsOneWidget);
      await tester.tap(history);
      expect(historyTaps, 1);
      semantics.dispose();
    },
  );

  // ── D-13: Scaffold flag ─────────────────────────────────────────────────────

  testWidgets('D-13: Scaffold has resizeToAvoidBottomInset=false', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
        mockCategoryService: mockCategoryService,
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('manual-one-step-screen')),
    );
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
  });

  testWidgets('390x844 keypad surface extends through the bottom inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
        mockCategoryService: mockCategoryService,
      ),
    );
    await tester.pumpAndSettle();

    final safeArea = find.byKey(
      const ValueKey('manual-entry-bottom-safe-area'),
    );
    expect(safeArea, findsOneWidget);
    expect(tester.widget<SafeArea>(safeArea).top, isFalse);
    expect(
      find.descendant(of: safeArea, matching: find.byType(AnimatedSlide)),
      findsOneWidget,
      reason: 'the shared keypad/voice slot is inside the SafeArea',
    );
    expect(
      tester
          .getRect(
            find.byKey(const ValueKey('manual-entry-continuous-surface')),
          )
          .bottom,
      closeTo(844, 0.5),
      reason:
          'the keypad surface reaches the screen bottom without a blank gap',
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('manual-entry-continuous-surface')),
          )
          .height,
      59,
      reason: 'the visual surface keeps its compact 16dp bottom buffer',
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('manual-entry-continuous-control')),
          )
          .height,
      43,
      reason: 'the bottom buffer is intentionally outside the tap target',
    );
  });

  // ── Persistent keypad slide (P19-W3 FocusNode-driven) ──────────────────────

  testWidgets(
    'Persistent keypad: SmartKeyboard initially visible, slides out on TextField focus',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _pumpScreen(
          mockCreateUseCase: mockCreateUseCase,
          fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
          mockCategoryService: mockCategoryService,
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: SmartKeyboard visible (offset.dy = 0)
      final slideFinder = find.ancestor(
        of: find.byType(SmartKeyboard),
        matching: find.byType(AnimatedSlide),
      );
      expect(
        tester.widget<AnimatedSlide>(slideFinder).offset,
        const Offset(0, 0),
        reason: 'SmartKeyboard should be visible initially',
      );

      // Tap the merchant TextField to focus it
      await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
      await tester.pumpAndSettle();

      // SmartKeyboard should slide off-screen (offset.dy = 1)
      expect(
        tester.widget<AnimatedSlide>(slideFinder).offset,
        const Offset(0, 1),
        reason:
            'SmartKeyboard should slide off-screen when TextField is focused',
      );

      // P19-W3: verify per-host FocusNode is wired to the merchant TextField
      final merchantTextField = tester.widget<TextField>(
        find.byKey(const ValueKey('merchant-textfield')),
      );
      expect(
        merchantTextField.focusNode,
        isNotNull,
        reason: 'merchant TextField must have a per-host FocusNode (P19-W3)',
      );
    },
  );

  // ── KeyboardToolbar visibility + actions ───────────────────────────────────

  testWidgets(
    'KeyboardToolbar: note focus shows icon-labelled Done and green Record',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _pumpScreen(
          mockCreateUseCase: mockCreateUseCase,
          fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
          mockCategoryService: mockCategoryService,
        ),
      );
      await tester.pumpAndSettle();

      // Initial: no KeyboardToolbar
      expect(find.byType(KeyboardToolbar), findsNothing);

      // The screenshot case: editing the note raises the system keyboard.
      await tester.tap(find.byKey(const ValueKey('note-textfield')));
      await tester.pumpAndSettle();

      // KeyboardToolbar should be visible
      final toolbar = find.byType(KeyboardToolbar);
      expect(toolbar, findsOneWidget);
      expect(
        find.descendant(
          of: toolbar,
          matching: find.byIcon(Icons.keyboard_hide_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: toolbar,
          matching: find.byIcon(Icons.receipt_long_rounded),
        ),
        findsOneWidget,
      );
      final recordAction = tester.widget<Material>(
        find.byKey(const ValueKey('keyboard-toolbar-record-action')),
      );
      expect(recordAction.color, AppPalette.light.accentPrimary);
    },
  );

  // ── P19-W1: Save disabled when category null (default-category async race) ──

  testWidgets(
    'P19-W1: SmartKeyboard Save tapped before category loads does NOT invoke CreateTransactionUseCase',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final slowRepo = SlowFakeCategoryRepository(
        _fakeCategories,
        delay: const Duration(seconds: 2),
      );

      await tester.pumpWidget(
        _pumpScreen(
          mockCreateUseCase: mockCreateUseCase,
          fakeCategoryRepo: slowRepo,
          mockCategoryService: mockCategoryService,
        ),
      );

      // Pump briefly — not enough time for the 2s category init to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Tap a digit then the SmartKeyboard Save button — category still null
      final digitOneFinder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('1'),
      );
      expect(
        digitOneFinder,
        findsOneWidget,
        reason: 'SmartKeyboard digit "1" must be visible',
      );
      await tester.tap(digitOneFinder);
      await tester.pump();

      // Just pump — the guard should prevent use case invocation
      await tester.pump(const Duration(milliseconds: 100));

      // Assert use case was NEVER invoked (P19-W1 guard)
      verifyNever(() => mockCreateUseCase.execute(any()));

      // Now advance past the 2s delay
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // After category loads, _canSave should be true and the chip must show the
      // resolved default (food → コンビニ), not the "Please select" placeholder.
      final chip = find.byKey(const ValueKey('category-chip'));
      expect(chip, findsOneWidget);
      expect(
        find.descendant(of: chip, matching: find.textContaining('コンビニ')),
        findsOneWidget,
        reason: 'default category must be visible in the chip after async load',
      );
    },
  );

  // ── 260603-ti2: default category must auto-fill the form on initial load ──
  // Regression: the embedded TransactionDetailsForm reads `initialCategory`
  // only in its own initState, which runs (with null) BEFORE the host's async
  // default-category load resolves. A host setState/rebuild alone never reaches
  // the form (its GlobalKey state persists), so the form stays on "Please
  // select a category" forever. The fix pushes the resolved default into the
  // form via its imperative updateCategory() API — mirroring the already-
  // working _resetForContinuousEntry path.
  testWidgets(
    '260603-ti2: default category auto-fills into the form after async init',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _pumpScreen(
          mockCreateUseCase: mockCreateUseCase,
          fakeCategoryRepo: FakeCategoryRepository(_fakeCategories),
          mockCategoryService: mockCategoryService,
          // No initialCategory — exercise the async default-resolution path.
        ),
      );
      await tester.pumpAndSettle();

      final chip = find.byKey(const ValueKey('category-chip'));
      expect(chip, findsOneWidget);

      // The chip must show the resolved default (food → コンビニ), NOT the
      // "Please select a category" placeholder.
      expect(
        find.descendant(of: chip, matching: find.textContaining('コンビニ')),
        findsOneWidget,
        reason:
            'default L2 category should auto-fill the form on initial load, '
            'not stay on the please-select placeholder',
      );
      expect(
        find.descendant(
          of: chip,
          matching: find.textContaining('Please select'),
        ),
        findsNothing,
        reason: 'placeholder must be gone once the default resolves',
      );
    },
  );

  // ── P19-W1: Toolbar Save disabled when category null ──────────────────────

  testWidgets('P19-W1: KeyboardToolbar Save is disabled while category is null', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final slowRepo = SlowFakeCategoryRepository(
      _fakeCategories,
      delay: const Duration(seconds: 2),
    );

    await tester.pumpWidget(
      _pumpScreen(
        mockCreateUseCase: mockCreateUseCase,
        fakeCategoryRepo: slowRepo,
        mockCategoryService: mockCategoryService,
      ),
    );

    // Pump briefly to mount but NOT settle the 2s category init
    await tester.pump(const Duration(milliseconds: 100));

    // Focus merchant TextField to bring up KeyboardToolbar
    await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
    await tester.pump(const Duration(milliseconds: 100));

    // If KeyboardToolbar appeared, check its isSubmitting state
    if (find.byType(KeyboardToolbar).evaluate().isNotEmpty) {
      final toolbar = tester.widget<KeyboardToolbar>(
        find.byType(KeyboardToolbar),
      );
      // isSubmitting should be true because !_canSave (_selectedCategory == null)
      expect(
        toolbar.isSubmitting,
        isTrue,
        reason:
            'KeyboardToolbar.isSubmitting should be true while category is null (P19-W1)',
      );
    }

    // Tap keyboard toolbar Save — should not invoke use case (disabled)
    verifyNever(() => mockCreateUseCase.execute(any()));

    // Advance past the delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // After category loads, toolbar should have isSubmitting=false
    if (find.byType(KeyboardToolbar).evaluate().isNotEmpty) {
      final toolbar = tester.widget<KeyboardToolbar>(
        find.byType(KeyboardToolbar),
      );
      expect(
        toolbar.isSubmitting,
        isFalse,
        reason:
            'KeyboardToolbar.isSubmitting should be false after category loads',
      );
    }
  });

  // ── 260526-r8y Item 3: regression — toolbar 记录 must save when TextField focused ──
  //
  // Bug: TextField's `onTapOutside: (_) => FocusScope.of(context).unfocus()`
  // fires on pointer-down before the floating KeyboardToolbar's InkWell.onTap
  // can resolve on pointer-up. The unfocus causes `_handleFocusChange` to flip
  // `_isTextFieldFocused = false`, which unmounts the toolbar via
  // `if (_isTextFieldFocused) Positioned(...)`. The pending pointer-up reaches
  // a disposed widget and `onSave` is never invoked.
  //
  // Fix (Task 2): wrap KeyboardToolbar in `TapRegion(groupId: …)` and set
  // `TextField.groupId` to the same constant on the merchant + note TextFields.
  // This test MUST FAIL on current main (proves bug) and PASS after Task 2.
  testWidgets(
    '260526-r8y Item 3: KeyboardToolbar 记录 button saves transaction when merchant TextField is focused',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      // D-08 popUntil fix mirrors voice_input_screen_test._TwoRouteHost: push
      // ManualOneStepScreen on top of a dummy home so Navigator.popUntil
      // ((r) => r.isFirst) actually pops the screen.
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(
                FakeCategoryRepository(_fakeCategories),
              ),
              createTransactionUseCaseProvider.overrideWithValue(
                mockCreateUseCase,
              ),
              categoryServiceProvider.overrideWithValue(mockCategoryService),
            ],
            child: Navigator(
              onGenerateRoute: (settings) {
                if (settings.name == '/') {
                  return MaterialPageRoute<void>(
                    builder: (ctx) => Scaffold(
                      body: Builder(
                        builder: (ctx) {
                          // Push the screen on top of the home route after the
                          // first frame so the toolbar/save flow can pop back.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Navigator.of(ctx).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => ManualOneStepScreen(
                                  bookId: 'book-1',
                                  initialCategory: _l2Category,
                                  initialParentCategory: _l1Category,
                                  entrySource: EntrySource.manual,
                                ),
                              ),
                            );
                          });
                          return const Center(child: Text('home'));
                        },
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap digit '1' on SmartKeyboard to seed an amount.
      final digit1Finder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('1'),
      );
      expect(digit1Finder, findsOneWidget);
      await tester.tap(digit1Finder);
      await tester.pumpAndSettle();

      // Focus the merchant TextField → KeyboardToolbar mounts.
      await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
      await tester.pumpAndSettle();

      expect(
        find.byType(KeyboardToolbar),
        findsOneWidget,
        reason:
            'KeyboardToolbar must be visible while merchant field is focused',
      );

      // Tap the toolbar's 记录 button (en locale → "Record").
      final toolbarSaveFinder = find.descendant(
        of: find.byType(KeyboardToolbar),
        matching: find.text('Record'),
      );
      expect(
        toolbarSaveFinder,
        findsOneWidget,
        reason: 'toolbar must render the Record label',
      );

      // Use an explicit down + up gesture (not tester.tap which fast-paths
      // both events) so the production race between TextField.onTapOutside
      // (fires on pointer-down) and the InkWell's onTap (resolves on
      // pointer-up after the toolbar may have unmounted) is exercised
      // faithfully. With pumpAndSettle between down and up, the
      // _handleFocusChange → setState → toolbar unmount happens between
      // the events on the unfixed build.
      final gesture = await tester.startGesture(
        tester.getCenter(toolbarSaveFinder),
      );
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      // CORE BUG ASSERTION: save use case MUST be invoked exactly once.
      // Pre-fix: TextField.onTapOutside fires on pointer-down, unfocuses the
      // field, unmounts the toolbar, and the InkWell never receives the tap-up
      // — so verify(...).called(1) sees zero calls.
      verify(() => mockCreateUseCase.execute(any())).called(1);

      // 260614-iww: single-tap (continuousMode:false, the default) save now pops
      // back to the previous page with a warm entrySavedDone toast. (The legacy
      // 260603-nr1 always-keep-going behavior is now gated behind continuousMode,
      // which only the FAB long-press path sets.)
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('manual-one-step-screen')),
        findsNothing,
        reason:
            'single-tap save (continuousMode:false) must pop back to the previous page (260614-iww)',
      );
      expect(
        find.text('home'),
        findsOneWidget,
        reason: 'after popping, the home route is visible again',
      );
    },
  );

  // ── 260614-iww: continuous-mode (FAB long-press) save stays open ──────────

  testWidgets(
    '260614-iww: continuousMode save stays open, resets form, shows exit affordance',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      await tester.pumpWidget(
        createLocalizedWidget(
          ManualOneStepScreen(
            bookId: 'book-1',
            initialCategory: _l2Category,
            initialParentCategory: _l1Category,
            entrySource: EntrySource.manual,
            continuousMode: true,
          ),
          locale: const Locale('en'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(_fakeCategories),
            ),
            createTransactionUseCaseProvider.overrideWithValue(
              mockCreateUseCase,
            ),
            categoryServiceProvider.overrideWithValue(mockCategoryService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Continuous mode keeps the leading close affordance and surfaces its
      // live summary + disable action in the V16 input dock.
      expect(
        find.byIcon(Icons.close),
        findsOneWidget,
        reason: 'continuous mode exit control is the leading AppBar close (×)',
      );
      final l10n = S.of(
        tester.element(
          find.byKey(const ValueKey('manual-entry-continuous-control')),
        ),
      );
      expect(find.text(l10n.entryContinuousKeepNext), findsOneWidget);
      expect(find.text(l10n.entryContinuousDisable), findsOneWidget);

      // Seed an amount and save.
      final digit1Finder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('1'),
      );
      await tester.tap(digit1Finder);
      await tester.pump();
      final saveButtonFinder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('Record'),
      );
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      verify(() => mockCreateUseCase.execute(any())).called(1);

      // Continuous mode: the screen MUST stay open after save (no pop).
      expect(
        find.byKey(const ValueKey('manual-one-step-screen')),
        findsOneWidget,
        reason: 'continuousMode save keeps the page open for the next entry',
      );
      // Form resets in place — the amount display clears back to empty.
      expect(
        find.text('Saved — keep going!'),
        findsOneWidget,
        reason: 'continuous mode shows the warm keep-going toast',
      );
    },
  );

  // ── Digit tap + Save via SmartKeyboard (SC-4 precursor) ────────────────────

  testWidgets(
    'Digit tap + SmartKeyboard Save invokes CreateTransactionUseCase with entrySource=manual',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      // Pre-seed category so the form initializes with a non-null _category.
      // This avoids the async-init race since the form's initState reads
      // initialCategory only once. In production the async init updates
      // _selectedCategory → triggers rebuild → form rebuilds with new config but
      // does NOT re-init its internal _category (expected behavior: form owns cat
      // once initialized). Tests must pre-seed to exercise the full save path.
      await tester.pumpWidget(
        createLocalizedWidget(
          ManualOneStepScreen(
            bookId: 'book-1',
            initialCategory: _l2Category,
            initialParentCategory: _l1Category,
            entrySource: EntrySource.manual,
          ),
          locale: const Locale('en'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(_fakeCategories),
            ),
            createTransactionUseCaseProvider.overrideWithValue(
              mockCreateUseCase,
            ),
            categoryServiceProvider.overrideWithValue(mockCategoryService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap digit '1' three times
      final digit1Finder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('1'),
      );
      expect(digit1Finder, findsOneWidget);
      await tester.tap(digit1Finder);
      await tester.pump();
      await tester.tap(digit1Finder);
      await tester.pump();
      await tester.tap(digit1Finder);
      await tester.pump();

      // Tap SmartKeyboard Save via the action label text "Record"
      final saveButtonFinder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('Record'),
      );
      expect(saveButtonFinder, findsOneWidget);
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // Assert CreateTransactionUseCase was called with entrySource=manual
      final captured = verify(
        () => mockCreateUseCase.execute(captureAny()),
      ).captured;
      expect(captured.length, 1);
      final params = captured.first as CreateTransactionParams;
      expect(params.entrySource, EntrySource.manual);
      expect(params.amount, 111);
    },
  );

  // ── entrySource preservation for voice pushes ──────────────────────────────

  testWidgets(
    'entrySource=voice is preserved when screen pushed from voice flow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      // Create the screen with voice entrySource and pre-seeded category
      await tester.pumpWidget(
        createLocalizedWidget(
          ManualOneStepScreen(
            bookId: 'book-1',
            initialAmount: 500,
            initialCategory: _l2Category,
            initialParentCategory: _l1Category,
            entrySource: EntrySource.voice,
          ),
          locale: const Locale('en'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(_fakeCategories),
            ),
            createTransactionUseCaseProvider.overrideWithValue(
              mockCreateUseCase,
            ),
            categoryServiceProvider.overrideWithValue(mockCategoryService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap SmartKeyboard Save
      final saveButtonFinder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('Record'),
      );
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // Verify entrySource=voice
      final captured = verify(
        () => mockCreateUseCase.execute(captureAny()),
      ).captured;
      expect(captured.length, 1);
      final params = captured.first as CreateTransactionParams;
      expect(params.entrySource, EntrySource.voice);
    },
  );

  // ── CR-01: decimal-point parsing regression ────────────────────────────────
  //
  // The default currency is JPY (0 decimals), so the dot key is GATED OFF.
  // V16 keeps a low-emphasis '.' glyph in that disabled tile (CURR-04).
  // The original CR-01 concern (typing "123." must not collapse to 0) is now
  // structurally impossible on the JPY path because the dot can't be typed at
  // all. The regression intent — Record submits amount=123 — is preserved; the
  // dot-tap step is replaced with an assertion that the dot is visible/gated.

  testWidgets(
    'CR-01: typing 1,2,3 (dot gated for JPY) then Record submits amount=123',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      await tester.pumpWidget(
        createLocalizedWidget(
          ManualOneStepScreen(
            bookId: 'book-1',
            initialCategory: _l2Category,
            initialParentCategory: _l1Category,
            entrySource: EntrySource.manual,
          ),
          locale: const Locale('en'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(_fakeCategories),
            ),
            createTransactionUseCaseProvider.overrideWithValue(
              mockCreateUseCase,
            ),
            categoryServiceProvider.overrideWithValue(mockCategoryService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final keyboard = find.byType(SmartKeyboard);
      expect(keyboard, findsOneWidget);

      // Tap '1', '2', '3'
      for (final digit in ['1', '2', '3']) {
        final finder = find.descendant(
          of: keyboard,
          matching: find.text(digit),
        );
        expect(finder, findsOneWidget);
        await tester.tap(finder);
        await tester.pump();
      }

      // V16 keeps the gated dot visible at low emphasis, but the tile remains
      // non-interactive. Typing a dot is still impossible on the JPY path.
      expect(
        find.descendant(of: keyboard, matching: find.text('.')),
        findsOneWidget,
        reason: 'V16 shows the disabled JPY dot glyph (D-06 / CURR-04)',
      );
      expect(
        find.byKey(const ValueKey('smart_keyboard_dot_disabled')),
        findsOneWidget,
        reason: 'the visible dot still sits in a disabled, non-tappable tile',
      );

      // Tap 'Record' — the form should submit with amount=123 (not 0)
      final recordFinder = find.descendant(
        of: keyboard,
        matching: find.text('Record'),
      );
      expect(recordFinder, findsOneWidget);
      await tester.tap(recordFinder);
      await tester.pumpAndSettle();

      final captured = verify(
        () => mockCreateUseCase.execute(captureAny()),
      ).captured;
      expect(
        captured.length,
        1,
        reason: 'use case must be called exactly once',
      );
      final params = captured.first as CreateTransactionParams;
      expect(
        params.amount,
        123,
        reason:
            'After typing "123." the parsed amount must be 123, not 0 (CR-01 regression)',
      );
    },
  );

  // ── WR-01: _isSubmitting deadlock recovery ────────────────────────────────

  testWidgets(
    'WR-01: after persistError result, _isSubmitting resets and second save is possible',
    (tester) async {
      // WR-01 adds a try/finally to _save() so _isSubmitting is always reset.
      // This test verifies the reset path by:
      //   1. First save → use case returns an error result (snackbar, no nav).
      //   2. Second save → use case returns success.
      // If _isSubmitting were NOT reset after step 1, step 2 would be a no-op
      // and the verify would see only 1 call instead of 2.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // First tap: use case returns a persist error (not a throw).
      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.error('DB write failed'));

      await tester.pumpWidget(
        createLocalizedWidget(
          ManualOneStepScreen(
            bookId: 'book-1',
            initialAmount: 500,
            initialCategory: _l2Category,
            initialParentCategory: _l1Category,
            entrySource: EntrySource.manual,
          ),
          locale: const Locale('en'),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(_fakeCategories),
            ),
            createTransactionUseCaseProvider.overrideWithValue(
              mockCreateUseCase,
            ),
            categoryServiceProvider.overrideWithValue(mockCategoryService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final recordFinder = find.descendant(
        of: find.byType(SmartKeyboard),
        matching: find.text('Record'),
      );
      expect(recordFinder, findsOneWidget);

      // First tap — use case returns persist error, _isSubmitting should reset.
      await tester.tap(recordFinder);
      await tester.pumpAndSettle();

      // Second tap — use case returns success this time.
      when(
        () => mockCreateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(_successTransaction));

      await tester.tap(recordFinder);
      await tester.pumpAndSettle();

      // Both taps must have invoked the use case — proving _isSubmitting reset
      // after the first error result so the second save was not blocked.
      final calls = verify(() => mockCreateUseCase.execute(any())).callCount;
      expect(
        calls,
        2,
        reason:
            'WR-01: _isSubmitting must reset after persistError so a second save is not deadlocked',
      );
    },
  );

  // ── 260622-nhs: single-page push-to-talk (D-1/D-2/D-3, T-nhs-03) ───────────

  group('260622-nhs single-page PTT', () {
    final micBarFinder = find.byKey(const ValueKey('voice-record-bar'));

    Widget pumpPtt({
      required _CapturingSpeechService speech,
      required ParseVoiceInputUseCase parse,
      EntrySource entrySource = EntrySource.manual,
      bool continuousMode = false,
      FakeCategoryRepository? categoryRepository,
    }) {
      final repository =
          categoryRepository ?? FakeCategoryRepository(_fakeCategories);
      return createLocalizedWidget(
        ManualOneStepScreen(
          bookId: 'book-1',
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
          entrySource: entrySource,
          continuousMode: continuousMode,
          speechService: speech,
        ),
        locale: const Locale('en'),
        overrides: [
          categoryRepositoryProvider.overrideWithValue(repository),
          createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
          categoryServiceProvider.overrideWithValue(mockCategoryService),
          parseVoiceInputUseCaseProvider.overrideWithValue(parse),
          voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
          merchantCategoryLearningServiceProvider.overrideWithValue(
            mockLearningService,
          ),
        ],
      );
    }

    void tall(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('VoiceRecordBar renders ABOVE the SmartKeyboard', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        pumpPtt(
          speech: _CapturingSpeechService(),
          parse: _FakeParseVoiceInputUseCase(const {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoiceRecordBar), findsOneWidget);
      // R2: the bar sits ABOVE the keypad (R1 placed it below = iOS gesture
      // zone): its top edge is LESS than the SmartKeyboard's top edge.
      final barTop = tester.getTopLeft(micBarFinder).dy;
      final keypadTop = tester.getTopLeft(find.byType(SmartKeyboard)).dy;
      expect(
        barTop,
        lessThan(keypadTop),
        reason: 'R2: voice-record bar must sit above the SmartKeyboard',
      );
    });

    testWidgets('voice entry opens idle and starts only from the center mic', (
      tester,
    ) async {
      tall(tester);
      final speech = _CapturingSpeechService();
      await tester.pumpWidget(
        pumpPtt(speech: speech, parse: _FakeParseVoiceInputUseCase(const {})),
      );
      await tester.pumpAndSettle();

      await tester.tap(micBarFinder);
      await tester.pump();
      await tester.pump();

      expect(_voiceDock(tester).state, UnifiedVoiceEntryState.idle);
      expect(speech.startCount, 0);
      expect(find.text('Waiting for voice input'), findsOneWidget);
      expect(
        find.text('Tap the microphone to start voice recording'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('unified-voice-core')));
      await tester.pump();
      await tester.pump();

      expect(_voiceDock(tester).state, UnifiedVoiceEntryState.listening);
      expect(speech.startCount, 1);
    });

    testWidgets(
      'V16: merchant focus during listening exposes a disabled toolbar and cannot save',
      (tester) async {
        tall(tester);
        await tester.pumpWidget(
          pumpPtt(
            speech: _CapturingSpeechService(),
            parse: _FakeParseVoiceInputUseCase(const {}),
          ),
        );
        await tester.pumpAndSettle();
        for (final digit in ['3', '0', '0']) {
          await tester.tap(
            find.descendant(
              of: find.byType(SmartKeyboard),
              matching: find.text(digit),
            ),
          );
          await tester.pump();
        }

        await _openVoiceDockAndStart(tester);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.listening);

        await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
        await tester.pump();
        final toolbar = tester.widget<KeyboardToolbar>(
          find.byType(KeyboardToolbar),
        );
        expect(toolbar.isSubmitting, isTrue);

        // Exercise the handler directly too: UI disablement is not the only
        // safety boundary when voice still owns a transient draft.
        toolbar.onSave();
        await tester.pump();
        verifyNever(() => mockCreateUseCase.execute(any()));
      },
    );

    testWidgets(
      'V16: merchant focus during asynchronous voice processing cannot save',
      (tester) async {
        tall(tester);
        final repository = _DelayedFindByIdCategoryRepository([
          ..._fakeCategories,
          _alternateL2Category,
        ], delayedCategoryId: _alternateL2Category.id);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase({
          '500円 processing': VoiceParseResult(
            rawText: '500円 processing',
            amount: 500,
            categoryMatch: CategoryMatchResult(
              categoryId: _alternateL2Category.id,
              confidence: 0.95,
              source: MatchSource.keyword,
            ),
          ),
        });
        await tester.pumpWidget(
          pumpPtt(speech: speech, parse: parse, categoryRepository: repository),
        );
        await tester.pumpAndSettle();

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('500円 processing');
        await tester.pump();
        await tester.pump();
        expect(repository.isWaiting, isTrue);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.processing);

        await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
        await tester.pump();
        final toolbar = tester.widget<KeyboardToolbar>(
          find.byType(KeyboardToolbar),
        );
        expect(toolbar.isSubmitting, isTrue);
        toolbar.onSave();
        await tester.pump();
        verifyNever(() => mockCreateUseCase.execute(any()));

        repository.gate.complete();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'V16: terminal status during delayed final parse remains processing and cannot save',
      (tester) async {
        tall(tester);
        tester.view.padding = const FakeViewPadding(bottom: 34);
        tester.view.viewPadding = const FakeViewPadding(bottom: 34);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        final speech = _CapturingSpeechService();
        final parse = _DelayedParseVoiceInputUseCase(
          const VoiceParseResult(rawText: '500円 delayed', amount: 500),
        );
        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();
        for (final digit in ['3', '0', '0']) {
          await tester.tap(
            find.descendant(
              of: find.byType(SmartKeyboard),
              matching: find.text(digit),
            ),
          );
          await tester.pump();
        }

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('500円 delayed');
        await tester.pump();
        expect(parse.isWaiting, isTrue);

        await _finishVoiceUtterance(tester, speech);
        expect(
          _voiceDock(tester).state,
          UnifiedVoiceEntryState.processing,
          reason:
              'terminal recognition does not make an in-flight parse saveable',
        );

        await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
        await tester.pump();
        final toolbar = tester.widget<KeyboardToolbar>(
          find.byType(KeyboardToolbar),
        );
        expect(toolbar.isSubmitting, isTrue);
        toolbar.onSave();
        await tester.pump();
        verifyNever(() => mockCreateUseCase.execute(any()));

        parse.gate.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'V16: a newer final result invalidates an older delayed partial fill',
      (tester) async {
        tall(tester);
        final speech = _CapturingSpeechService();
        final parse = _OutOfOrderParseVoiceInputUseCase(
          partialText: '500円 old',
          partialResult: VoiceParseResult(
            rawText: '500円 old',
            amount: 500,
            merchantName: 'Old merchant',
            parsedDate: DateTime(2026, 1, 5),
          ),
          finalText: '900円 final',
          finalResult: VoiceParseResult(
            rawText: '900円 final',
            amount: 900,
            merchantName: 'Final merchant',
            parsedDate: DateTime(2026, 2, 6),
          ),
        );

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();
        await _openVoiceDockAndStart(tester);

        speech.emitPartial(parse.partialText);
        await tester.pump(const Duration(milliseconds: 301));
        await tester.pump();
        expect(parse.partialIsWaiting, isTrue);

        speech.emitFinal(parse.finalText);
        await tester.pump();
        await tester.pump();
        await tester.pump();

        var form = tester.state<TransactionDetailsFormState>(
          find.byType(TransactionDetailsForm),
        );
        expect(form.currentAmount, 900);
        expect(form.currentMerchant, 'Final merchant');
        expect(form.currentDate, DateTime(2026, 2, 6));
        expect(
          form.currentCategory?.id,
          _l2Category.id,
          reason: 'an amount-only final carries no category review signal',
        );

        parse.partialGate.complete();
        await tester.pumpAndSettle();

        form = tester.state<TransactionDetailsFormState>(
          find.byType(TransactionDetailsForm),
        );
        expect(form.currentAmount, 900);
        expect(form.currentMerchant, 'Final merchant');
        expect(form.currentDate, DateTime(2026, 2, 6));
      },
    );

    testWidgets(
      'V16: a weak category signal clears the default, disables record, and reset restores it',
      (tester) async {
        tall(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '500円 maybe cafe': VoiceParseResult(
            rawText: '500円 maybe cafe',
            amount: 500,
            merchantName: 'Maybe cafe',
            band: ConfidenceBand.weak,
            alternates: [
              CategoryMatchResult(
                categoryId: 'convenience',
                confidence: 0.42,
                source: MatchSource.fallback,
              ),
            ],
          ),
        });

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();
        var form = tester.state<TransactionDetailsFormState>(
          find.byType(TransactionDetailsForm),
        );
        expect(form.currentCategory?.id, _l2Category.id);

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('500円 maybe cafe');
        await tester.pump();
        await tester.pump();
        await _finishVoiceUtterance(tester, speech);

        form = tester.state<TransactionDetailsFormState>(
          find.byType(TransactionDetailsForm),
        );
        expect(form.currentCategory, isNull);
        expect(
          find.byKey(const ValueKey('v16-category-select-required')),
          findsOneWidget,
        );
        expect(find.text('Select required'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('v16-voice-source-category')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('v16-voice-source-merchant')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('v16-voice-source-note')),
          findsNothing,
        );
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.review);
        expect(
          _voiceDock(tester).isSubmitting,
          isTrue,
          reason: 'record stays disabled until the user chooses a category',
        );
        _voiceDock(tester).onPrimary();
        await tester.pump();
        verifyNever(() => mockCreateUseCase.execute(any()));

        await tester.tap(find.byKey(const ValueKey('unified-voice-core')));
        await tester.pump();
        await tester.pump();

        form = tester.state<TransactionDetailsFormState>(
          find.byType(TransactionDetailsForm),
        );
        expect(form.currentCategory?.id, _l2Category.id);
        expect(
          find.byKey(const ValueKey('v16-category-select-required')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('v16-voice-source-category')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'V16: tap replaces keypad; final reaches review; keyboard keeps fill',
      (tester) async {
        tall(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase({
          '1千8百4十元 星巴克': VoiceParseResult(
            rawText: '1千8百4十元 星巴克',
            amount: 1840,
            parsedDate: DateTime(2026, 4, 27),
            merchantName: '星巴克',
            categoryMatch: const CategoryMatchResult(
              categoryId: 'convenience',
              confidence: 0.91,
              source: MatchSource.keyword,
            ),
            ledgerType: LedgerType.daily,
          ),
        });

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        // Tap the bar → the inline panel REPLACES the keypad in place. No scrim,
        // no overlay; the keypad is gone while the panel shows.
        await _openVoiceDockAndStart(tester);
        expect(
          find.byType(UnifiedVoiceEntryDock),
          findsOneWidget,
          reason: 'tapping the bar swaps the unified voice dock in',
        );
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.listening);
        final voiceL10n = S.of(
          tester.element(find.byType(UnifiedVoiceEntryDock)),
        );
        expect(voiceL10n.entryVoicePrivacy, 'Processed only on this device');
        expect(find.text(voiceL10n.entryVoicePrivacy), findsOneWidget);
        expect(
          find.text(voiceL10n.entryVoiceListeningPlaceholder),
          findsNothing,
          reason: 'the transcript line only shows recognized speech',
        );
        expect(
          tester
              .getRect(find.byKey(const Key('unified-voice-entry-dock')))
              .bottom,
          closeTo(1400, 0.5),
          reason: 'the voice dock surface reaches the screen bottom',
        );
        expect(
          find.byType(SmartKeyboard),
          findsNothing,
          reason: 'the V16 dock replaces the keypad in the same footprint',
        );

        // A speech-final result AUTO-fills the form (no release needed). The
        // form above stays visible (no scrim dimming it).
        speech.emitFinal('1千8百4十元 星巴克');
        await tester.pump();
        await tester.pump();
        await _finishVoiceUtterance(tester, speech);
        expect(parse.inputs, contains('1千8百4十元 星巴克'));
        expect(
          find.text('星巴克'),
          findsOneWidget,
          reason: 'auto-fill writes the merchant into the same form',
        );
        expect(
          _voiceDock(tester).state,
          UnifiedVoiceEntryState.review,
          reason: 'a terminal final remains in the explicit V16 review state',
        );

        // Review → keyboard keeps the reviewed fill instead of rolling back.
        await _switchVoiceDockToKeyboard(tester);

        expect(
          find.byType(UnifiedVoiceEntryDock),
          findsNothing,
          reason: 'the keyboard action dismisses the voice dock',
        );
        expect(
          find.byType(SmartKeyboard),
          findsOneWidget,
          reason: 'the keypad returns after exit',
        );
        expect(
          find.text('星巴克'),
          findsOneWidget,
          reason: 'filled content is kept after exit',
        );
        expect(
          find.byKey(const ValueKey('manual-one-step-screen')),
          findsOneWidget,
          reason: 'D-2: the screen stays on the manual page (no auto-save)',
        );
        verifyNever(() => mockCreateUseCase.execute(any()));
      },
    );

    testWidgets(
      'V16: keyboard during listening cancels and restores the pre-voice snapshot',
      (tester) async {
        tall(tester);
        when(
          () => mockCreateUseCase.execute(any()),
        ).thenAnswer((_) async => Result.success(_successTransaction));
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '500円 仮入力': VoiceParseResult(
            rawText: '500円 仮入力',
            amount: 500,
            merchantName: '仮入力',
          ),
        });

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        for (final digit in ['3', '0', '0']) {
          await tester.tap(
            find.descendant(
              of: find.byType(SmartKeyboard),
              matching: find.text(digit),
            ),
          );
          await tester.pump();
        }
        expect(
          tester.widget<AmountDisplay>(find.byType(AmountDisplay)).amount,
          '300',
        );

        await _openVoiceDockAndStart(tester);
        speech.emitPartial('500円 仮入力');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
        await tester.pump();

        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.listening);
        expect(
          tester.widget<AmountDisplay>(find.byType(AmountDisplay)).amount,
          '500',
          reason: 'precondition: the live partial changed the form',
        );
        expect(find.text('仮入力'), findsOneWidget);

        await _switchVoiceDockToKeyboard(tester);

        expect(speech.canceled, isTrue);
        expect(find.byType(SmartKeyboard), findsOneWidget);
        expect(
          tester.widget<AmountDisplay>(find.byType(AmountDisplay)).amount,
          '300',
          reason: 'listening → keyboard restores the captured amount',
        );
        expect(
          tester
              .state<TransactionDetailsFormState>(
                find.byType(TransactionDetailsForm),
              )
              .currentAmount,
          300,
          reason: 'the persisted form mirror must restore with the display',
        );
        expect(find.text('仮入力'), findsNothing);

        await tester.tap(
          find.descendant(
            of: find.byType(SmartKeyboard),
            matching: find.text('Record'),
          ),
        );
        await tester.pumpAndSettle();

        final saved =
            verify(
                  () => mockCreateUseCase.execute(captureAny()),
                ).captured.single
                as CreateTransactionParams;
        expect(saved.amount, 300);
      },
    );

    testWidgets(
      'V16: keyboard exit invalidates a delayed final category fill',
      (tester) async {
        tall(tester);
        final repository = _DelayedFindByIdCategoryRepository([
          ..._fakeCategories,
          _alternateL2Category,
        ], delayedCategoryId: _alternateL2Category.id);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase({
          '700円 遅延カフェ': VoiceParseResult(
            rawText: '700円 遅延カフェ',
            amount: 700,
            merchantName: '遅延カフェ',
            categoryMatch: CategoryMatchResult(
              categoryId: _alternateL2Category.id,
              confidence: 0.95,
              source: MatchSource.keyword,
            ),
            ledgerType: LedgerType.daily,
          ),
        });

        await tester.pumpWidget(
          pumpPtt(speech: speech, parse: parse, categoryRepository: repository),
        );
        await tester.pumpAndSettle();

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('700円 遅延カフェ');
        await tester.pump();
        await tester.pump();

        expect(repository.isWaiting, isTrue);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.processing);

        await _switchVoiceDockToKeyboard(tester);
        expect(find.byType(UnifiedVoiceEntryDock), findsNothing);

        repository.gate.complete();
        await tester.pumpAndSettle();

        final form = tester.state<TransactionDetailsFormState>(
          find.byType(TransactionDetailsForm),
        );
        expect(form.currentAmount, 0);
        expect(form.currentCategory?.id, _l2Category.id);
        expect(form.currentMerchant, isEmpty);
        expect(find.text('遅延カフェ'), findsNothing);
        expect(
          tester.widget<AmountDisplay>(find.byType(AmountDisplay)).amount,
          isEmpty,
        );
      },
    );

    testWidgets(
      'V16: keyboard restore and re-record reset clear discarded voice confidence',
      (tester) async {
        tall(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '500円 weak': VoiceParseResult(
            rawText: '500円 weak',
            amount: 500,
            categoryMatch: CategoryMatchResult(
              categoryId: 'convenience',
              confidence: 0.4,
              source: MatchSource.fallback,
            ),
            band: ConfidenceBand.weak,
            alternates: [
              CategoryMatchResult(
                categoryId: 'convenience',
                confidence: 0.4,
                source: MatchSource.fallback,
              ),
            ],
          ),
        });

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        // A resolved final can still be in the listening window. Keyboard exit
        // restores the pre-speech snapshot and must remove its confidence UI.
        await _openVoiceDockAndStart(tester);
        speech.emitFinal('500円 weak');
        await tester.pump();
        await tester.pump();
        expect(find.byType(ConfidenceBandIndicator), findsNothing);
        await _switchVoiceDockToKeyboard(tester);
        expect(find.byType(ConfidenceBandIndicator), findsNothing);

        // A review re-record uses the same restore contract and clears it too.
        await _openVoiceDockAndStart(tester);
        speech.emitFinal('500円 weak');
        await tester.pump();
        await tester.pump();
        expect(find.byType(ConfidenceBandIndicator), findsNothing);
        await _finishVoiceUtterance(tester, speech);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.review);

        await tester.tap(find.byKey(const ValueKey('unified-voice-core')));
        await tester.pump();
        await tester.pump();
        expect(find.byType(ConfidenceBandIndicator), findsNothing);
      },
    );

    testWidgets(
      'T-nhs-03: a PTT-filled save stamps EntrySource.voice; keypad-only stays manual',
      (tester) async {
        tall(tester);
        when(
          () => mockCreateUseCase.execute(any()),
        ).thenAnswer((_) async => Result.success(_successTransaction));

        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase({
          'ラテ 1千': VoiceParseResult(
            rawText: 'ラテ 1千',
            amount: 1000,
            parsedDate: DateTime(2026, 4, 27),
            merchantName: 'スタバ',
            categoryMatch: const CategoryMatchResult(
              categoryId: 'convenience',
              confidence: 0.91,
              source: MatchSource.keyword,
            ),
            ledgerType: LedgerType.daily,
          ),
        });

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('ラテ 1千');
        await tester.pump();
        await tester.pump();
        await _finishVoiceUtterance(tester, speech);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.review);

        // Save directly from the V16 review action.
        await tester.tap(
          find.byKey(const ValueKey('unified-voice-primary-action')),
        );
        await tester.pumpAndSettle();

        final captured = verify(
          () => mockCreateUseCase.execute(captureAny()),
        ).captured;
        expect(captured.length, 1);
        expect(
          (captured.first as CreateTransactionParams).entrySource,
          EntrySource.voice,
          reason: 'T-nhs-03: a PTT-filled row carries voice provenance',
        );
      },
    );

    testWidgets(
      'T-nhs-03: keypad-only save stays EntrySource.manual (no PTT fill)',
      (tester) async {
        tall(tester);
        when(
          () => mockCreateUseCase.execute(any()),
        ).thenAnswer((_) async => Result.success(_successTransaction));

        await tester.pumpWidget(
          pumpPtt(
            speech: _CapturingSpeechService(),
            parse: _FakeParseVoiceInputUseCase(const {}),
          ),
        );
        await tester.pumpAndSettle();

        final digit1 = find.descendant(
          of: find.byType(SmartKeyboard),
          matching: find.text('1'),
        );
        await tester.tap(digit1);
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: find.byType(SmartKeyboard),
            matching: find.text('Record'),
          ),
        );
        await tester.pumpAndSettle();

        final captured = verify(
          () => mockCreateUseCase.execute(captureAny()),
        ).captured;
        expect(captured.length, 1);
        expect(
          (captured.first as CreateTransactionParams).entrySource,
          EntrySource.manual,
          reason: 'a pure keypad row keeps manual provenance',
        );
      },
    );

    testWidgets(
      'V16 continuous voice save stays open and returns the dock to idle',
      (tester) async {
        tall(tester);
        when(
          () => mockCreateUseCase.execute(any()),
        ).thenAnswer((_) async => Result.success(_successTransaction));
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '次の一件 100円': VoiceParseResult(rawText: '次の一件 100円', amount: 100),
        });

        await tester.pumpWidget(
          pumpPtt(speech: speech, parse: parse, continuousMode: true),
        );
        await tester.pumpAndSettle();

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('次の一件 100円');
        await tester.pump();
        await tester.pump();
        await _finishVoiceUtterance(tester, speech);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.review);
        expect(_voiceDock(tester).continuousMode, isTrue);

        await tester.tap(
          find.byKey(const ValueKey('unified-voice-primary-action')),
        );
        await tester.pumpAndSettle();

        verify(() => mockCreateUseCase.execute(any())).called(1);
        expect(
          find.byKey(const ValueKey('manual-one-step-screen')),
          findsOneWidget,
        );
        expect(find.byType(UnifiedVoiceEntryDock), findsOneWidget);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.idle);
        expect(_voiceDock(tester).continuousMode, isTrue);
        expect(find.byType(SmartKeyboard), findsNothing);
        expect(
          tester.widget<AmountDisplay>(find.byType(AmountDisplay)).amount,
          isEmpty,
        );
      },
    );

    testWidgets(
      'V16 continuous save exposes only an atomic fresh draft and stays '
      'submitting until the default category is fully seeded',
      (tester) async {
        tall(tester);
        when(
          () => mockCreateUseCase.execute(any()),
        ).thenAnswer((_) async => Result.success(_successTransaction));
        final repository = _ControlledFindActiveCategoryRepository(
          _fakeCategories,
        );
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '次の一件 100円': VoiceParseResult(
            rawText: '次の一件 100円',
            amount: 100,
            categoryMatch: CategoryMatchResult(
              categoryId: 'convenience',
              confidence: 0.91,
              source: MatchSource.keyword,
            ),
            band: ConfidenceBand.medium,
            alternates: [
              CategoryMatchResult(
                categoryId: 'convenience',
                confidence: 0.91,
                source: MatchSource.keyword,
              ),
            ],
          ),
        });

        await tester.pumpWidget(
          pumpPtt(
            speech: speech,
            parse: parse,
            continuousMode: true,
            categoryRepository: repository,
          ),
        );
        await tester.pumpAndSettle();

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('次の一件 100円');
        await tester.pump();
        await tester.pump();
        await _finishVoiceUtterance(tester, speech);

        final form = tester.state<TransactionDetailsFormState>(
          find.byType(TransactionDetailsForm),
        );
        form.updateLedgerType(LedgerType.joy);
        form.updateSatisfaction(10);
        await tester.pump();
        expect(find.byType(ConfidenceBandIndicator), findsNothing);

        final resetGate = Completer<void>();
        repository.nextGate = resetGate;
        final startsBeforeSave = speech.startCount;
        await tester.tap(
          find.byKey(const ValueKey('unified-voice-primary-action')),
        );
        await tester.pump();
        await tester.pump();

        expect(repository.isWaiting, isTrue);
        expect(_voiceDock(tester).isSubmitting, isTrue);
        expect(form.currentAmount, 0);
        expect(form.currentCategory, isNull);
        expect(form.currentLedgerType, LedgerType.daily);
        expect(form.currentSatisfaction, 2);
        expect(form.currentMerchant, isEmpty);
        expect(find.byType(ConfidenceBandIndicator), findsNothing);

        // The dock is already an empty fresh slate, but no new recording may
        // start until the default-category lookup and ledger mapping finish.
        await tester.tap(find.byKey(const ValueKey('unified-voice-core')));
        await tester.pump();
        expect(speech.startCount, startsBeforeSave);
        expect(_voiceDock(tester).isSubmitting, isTrue);

        resetGate.complete();
        await tester.pumpAndSettle();

        expect(repository.isWaiting, isFalse);
        expect(form.currentCategory?.id, _l2Category.id);
        expect(form.currentLedgerType, LedgerType.daily);
        expect(form.currentSatisfaction, 2);
        expect(find.byType(ConfidenceBandIndicator), findsNothing);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.idle);
        expect(_voiceDock(tester).isSubmitting, isFalse);

        final saved =
            verify(
                  () => mockCreateUseCase.execute(captureAny()),
                ).captured.single
                as CreateTransactionParams;
        expect(saved.ledgerType, LedgerType.joy);
        expect(saved.joyFullness, 10);
      },
    );

    testWidgets('V16 review mic restores the pre-speech form and re-arms', (
      tester,
    ) async {
      tall(tester);
      final speech = _CapturingSpeechService();
      final parse = _FakeParseVoiceInputUseCase({
        '1千8百4十元 星巴克': VoiceParseResult(
          rawText: '1千8百4十元 星巴克',
          amount: 1840,
          parsedDate: DateTime(2026, 4, 27),
          merchantName: '星巴克',
          categoryMatch: const CategoryMatchResult(
            categoryId: 'convenience',
            confidence: 0.91,
            source: MatchSource.keyword,
          ),
          ledgerType: LedgerType.daily,
        ),
      });

      await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
      await tester.pumpAndSettle();

      // Tap → modal; speak → auto-fill merchant 星巴克.
      await _openVoiceDockAndStart(tester);
      speech.emitFinal('1千8百4十元 星巴克');
      await tester.pump();
      await tester.pump();
      expect(find.text('星巴克'), findsOneWidget);

      await _finishVoiceUtterance(tester, speech);
      expect(_voiceDock(tester).state, UnifiedVoiceEntryState.review);

      // Review mic means re-record: restore the snapshot and restart.
      await tester.tap(find.byKey(const ValueKey('unified-voice-core')));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('星巴克'),
        findsNothing,
        reason: '重置 restores the pre-speech (empty) merchant',
      );
      expect(
        find.byType(UnifiedVoiceEntryDock),
        findsOneWidget,
        reason: 're-record keeps the unified dock shown',
      );
      expect(_voiceDock(tester).state, UnifiedVoiceEntryState.listening);
      // 260622-nhs R4 (BUG A): 重置 now CANCELS the recognizer (to clear its
      // accumulated in-window buffer so the old transcript can't re-surface)
      // and starts a FRESH listening session — the corrected reset semantics.
      expect(
        speech.canceled,
        isTrue,
        reason: '重置 cancels the recognizer to clear its buffer (BUG A)',
      );
      expect(
        speech.isListening,
        isTrue,
        reason: '重置 re-arms a fresh listening session',
      );
    });

    // ── 260622-nhs R6 BUG 1: panel visibility decoupled from isRecording ──────

    testWidgets(
      'V16: pending review re-record is processing, cannot save, and keyboard exit invalidates it',
      (tester) async {
        tall(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '500円': VoiceParseResult(rawText: '500円', amount: 500),
        });

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();
        await _openVoiceDockAndStart(tester);
        speech.emitFinal('500円');
        await tester.pump();
        await tester.pump();
        await _finishVoiceUtterance(tester, speech);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.review);

        final startsBeforeReset = speech.startCount;
        final cancelGate = Completer<void>();
        speech.cancelGate = cancelGate;

        await tester.tap(find.byKey(const ValueKey('unified-voice-core')));
        await tester.pump();
        expect(speech.cancelCount, 1);
        expect(
          _voiceDock(tester).state,
          UnifiedVoiceEntryState.processing,
          reason: 'cancel-to-restart is still transient work',
        );
        expect(_voiceDock(tester).isSubmitting, isTrue);
        _voiceDock(tester).onPrimary();
        await tester.pump();
        verifyNever(() => mockCreateUseCase.execute(any()));

        await tester.tap(find.byKey(const ValueKey('merchant-textfield')));
        await tester.pump();
        final toolbar = tester.widget<KeyboardToolbar>(
          find.byType(KeyboardToolbar),
        );
        expect(toolbar.isSubmitting, isTrue);
        toolbar.onSave();
        await tester.pump();
        verifyNever(() => mockCreateUseCase.execute(any()));
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 250));

        _voiceDock(tester).onKeyboard();
        await tester.pump();
        expect(speech.cancelCount, 2);

        cancelGate.complete();
        await tester.pumpAndSettle();

        expect(
          speech.startCount,
          startsBeforeReset,
          reason: 'the stale reset continuation must never reopen the mic',
        );
        expect(find.byType(UnifiedVoiceEntryDock), findsNothing);
        expect(find.byType(SmartKeyboard), findsOneWidget);
      },
    );

    testWidgets(
      'V16: an empty stopped session stays in the dock as idle; keypad stays out',
      (tester) async {
        tall(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {});

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        // Tap the bar → panel opens, recognizer listening.
        await _openVoiceDockAndStart(tester);
        expect(find.byType(UnifiedVoiceEntryDock), findsOneWidget);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.listening);
        expect(find.byType(SmartKeyboard), findsNothing);

        // The recognizer self-terminates (one-shot end): isRecording → false.
        // The OLD code gated the panel on pttIsRecording, so the panel would
        // vanish + the keypad return. R6 gates on _voiceModalOpen → panel stays.
        speech.startedLocaleId = null;
        speech.emitStatus('done');
        await tester.pump();
        await tester.pump();

        expect(
          find.byType(UnifiedVoiceEntryDock),
          findsOneWidget,
          reason: 'the unified dock stays open after the recognizer stops',
        );
        expect(
          find.byType(SmartKeyboard),
          findsNothing,
          reason: 'the keypad must not return while the dock is open',
        );
        expect(
          _voiceDock(tester).state,
          UnifiedVoiceEntryState.idle,
          reason: 'an empty stopped transcript becomes the explicit idle state',
        );
      },
    );

    testWidgets(
      'V16: after an empty stop, keyboard exits and the keypad returns',
      (tester) async {
        tall(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {});

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        await _openVoiceDockAndStart(tester);

        // Recognizer self-terminates → panel stays (stopped).
        speech.startedLocaleId = null;
        speech.emitStatus('done');
        await tester.pump();
        await tester.pump();
        expect(find.byType(UnifiedVoiceEntryDock), findsOneWidget);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.idle);

        await _switchVoiceDockToKeyboard(tester);

        expect(
          find.byType(UnifiedVoiceEntryDock),
          findsNothing,
          reason: 'keyboard closes the dock from the idle stopped state',
        );
        expect(
          find.byType(SmartKeyboard),
          findsOneWidget,
          reason: 'the keypad returns after exit',
        );
      },
    );

    testWidgets(
      'V16 idle core starts a fresh listening session and keeps the dock open',
      (tester) async {
        tall(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {});

        await tester.pumpWidget(pumpPtt(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        await _openVoiceDockAndStart(tester);

        // Recognizer stops → stopped state, panel stays.
        speech.startedLocaleId = null;
        speech.emitStatus('done');
        await tester.pump();
        await tester.pump();
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.idle);

        await tester.tap(find.byKey(const ValueKey('unified-voice-core')));
        await tester.pump();
        await tester.pump();

        expect(
          find.byType(UnifiedVoiceEntryDock),
          findsOneWidget,
          reason: 'idle restart keeps the dock open',
        );
        expect(
          speech.isListening,
          isTrue,
          reason: 'idle core starts a fresh listening session',
        );
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.listening);
      },
    );

    testWidgets(
      'V16 unavailable action gives microphone help without claiming to open settings',
      (tester) async {
        tall(tester);
        final speech = _CapturingSpeechService()..available = false;

        await tester.pumpWidget(
          pumpPtt(speech: speech, parse: _FakeParseVoiceInputUseCase(const {})),
        );
        await tester.pumpAndSettle();
        await _openVoiceDockAndStart(tester);

        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.unavailable);
        expect(find.text('Microphone help'), findsOneWidget);
        const guidance =
            'Allow microphone access in system Settings, or continue with manual input';
        expect(find.text(guidance), findsOneWidget);
        expect(find.text('Open settings'), findsNothing);

        await tester.tap(
          find.byKey(const ValueKey('unified-voice-settings-action')),
        );
        await tester.pump();
        expect(
          find.text(guidance),
          findsNWidgets(2),
          reason: 'the action surfaces the same concrete permission guidance',
        );
      },
    );
  });

  // ── 260706-tm6 (voice-consolidation P0-5): keypad mirror non-happy path ────
  //
  // Additive-only group: characterizes the onPttCommitted host mirror
  // (AmountDisplay / _amount / keypad controller) for the non-happy paths.
  // Driven through the real PTT fill via the existing fake speech emitFinal
  // harness — no private-field poking.

  group('keypad mirror non-happy path (quick 260706-tm6)', () {
    Widget pumpMirror({
      required _CapturingSpeechService speech,
      required _FakeParseVoiceInputUseCase parse,
    }) {
      return createLocalizedWidget(
        ManualOneStepScreen(
          bookId: 'book-1',
          initialCategory: _l2Category,
          initialParentCategory: _l1Category,
          entrySource: EntrySource.manual,
          speechService: speech,
        ),
        locale: const Locale('en'),
        overrides: [
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(_fakeCategories),
          ),
          createTransactionUseCaseProvider.overrideWithValue(mockCreateUseCase),
          categoryServiceProvider.overrideWithValue(mockCategoryService),
          parseVoiceInputUseCaseProvider.overrideWithValue(parse),
          voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
          merchantCategoryLearningServiceProvider.overrideWithValue(
            mockLearningService,
          ),
        ],
      );
    }

    void tallView(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    String displayedAmount(WidgetTester tester) =>
        tester.widget<AmountDisplay>(find.byType(AmountDisplay)).amount;

    Future<void> tapDigit(WidgetTester tester, String digit) async {
      await tester.tap(
        find.descendant(
          of: find.byType(SmartKeyboard),
          matching: find.text(digit),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      '(a) amount-less final keeps the keypad amount (filled==0 branch)',
      (tester) async {
        tallView(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '午饭': VoiceParseResult(rawText: '午饭', merchantName: '午饭'),
        });

        await tester.pumpWidget(pumpMirror(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        // Keypad-typed pre-speech amount.
        await tapDigit(tester, '2');
        await tapDigit(tester, '5');
        await tapDigit(tester, '0');
        expect(displayedAmount(tester), '250');

        // Speak an amount-less utterance — merchant fills, amount must not.
        await _openVoiceDockAndStart(tester);
        speech.emitFinal('午饭');
        await tester.pump();
        await tester.pump();

        final merchantField = tester.widget<TextField>(
          find.byKey(const ValueKey('merchant-textfield')),
        );
        expect(
          merchantField.controller?.text,
          '午饭',
          reason: 'the fill ran (merchant landed in the form)',
        );
        expect(
          displayedAmount(tester),
          '250',
          reason:
              'onPttCommitted filled==0 branch must not touch the '
              'controller/_amount mirror',
        );
      },
    );

    testWidgets(
      '(b) a second-session fill fully REPLACES the mirror (no concat '
      'residue: 1200, never 5001200)',
      (tester) async {
        tallView(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '500円': VoiceParseResult(rawText: '500円', amount: 500),
          '1200円': VoiceParseResult(rawText: '1200円', amount: 1200),
        });

        await tester.pumpWidget(pumpMirror(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        // Session 1: fill 500.
        await _openVoiceDockAndStart(tester);
        speech.emitFinal('500円');
        await tester.pump();
        await tester.pump();
        expect(displayedAmount(tester), '500');

        await _finishVoiceUtterance(tester, speech);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.review);
        await _switchVoiceDockToKeyboard(tester);

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('1200円');
        await tester.pump();
        await tester.pump();

        expect(
          displayedAmount(tester),
          '1200',
          reason:
              'the second fill clears the controller before replaying '
              'digits — no 5001200 concat residue',
        );
      },
    );

    testWidgets(
      '(c) 重置 after a fill restores the pre-speech keypad amount AND the '
      'controller stays consistent (typing continues from it)',
      (tester) async {
        tallView(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '500円': VoiceParseResult(rawText: '500円', amount: 500),
        });

        await tester.pumpWidget(pumpMirror(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        // Keypad-typed pre-speech amount 300 → snapshot captures it on tap.
        await tapDigit(tester, '3');
        await tapDigit(tester, '0');
        await tapDigit(tester, '0');
        expect(displayedAmount(tester), '300');

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('500円');
        await tester.pump();
        await tester.pump();
        expect(
          displayedAmount(tester),
          '500',
          reason: 'precondition: the voice fill mirrored 500',
        );

        await _finishVoiceUtterance(tester, speech);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.review);

        await tester.tap(find.byKey(const ValueKey('unified-voice-core')));
        await tester.pump();
        await tester.pump();

        expect(
          displayedAmount(tester),
          '300',
          reason: '重置 rolls the AmountDisplay back to the snapshot',
        );

        // Switch from the re-armed listening dock, then type a digit: controller
        // carry "300" — proving display and controller restored in lockstep.
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.listening);
        await _switchVoiceDockToKeyboard(tester);
        await tapDigit(tester, '1');

        expect(
          displayedAmount(tester),
          '3001',
          reason:
              'typing continues from the RESTORED controller text '
              '(3001), not from the stale voice fill (5001)',
        );
      },
    );

    testWidgets(
      '(d) exiting the panel WITHOUT reset keeps the fill (snapshot-discard '
      'semantics) and typing continues from it',
      (tester) async {
        tallView(tester);
        final speech = _CapturingSpeechService();
        final parse = _FakeParseVoiceInputUseCase(const {
          '500円': VoiceParseResult(rawText: '500円', amount: 500),
        });

        await tester.pumpWidget(pumpMirror(speech: speech, parse: parse));
        await tester.pumpAndSettle();

        await _openVoiceDockAndStart(tester);
        speech.emitFinal('500円');
        await tester.pump();
        await tester.pump();
        expect(displayedAmount(tester), '500');

        await _finishVoiceUtterance(tester, speech);
        expect(_voiceDock(tester).state, UnifiedVoiceEntryState.review);
        // Review → keyboard discards the snapshot rather than applying it.
        await _switchVoiceDockToKeyboard(tester);

        expect(find.byType(UnifiedVoiceEntryDock), findsNothing);
        expect(find.byType(SmartKeyboard), findsOneWidget);
        expect(
          displayedAmount(tester),
          '500',
          reason: 'exit-without-reset keeps the voice fill',
        );

        // Keypad edits continue from the fill (controller mirrored 500).
        await tapDigit(tester, '1');
        expect(
          displayedAmount(tester),
          '5001',
          reason: 'the controller carries the fill, so an edit appends',
        );
      },
    );
  });
}
