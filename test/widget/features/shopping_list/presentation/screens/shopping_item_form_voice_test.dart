import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/create_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/update_shopping_item_use_case.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider, deviceIdentityRepositoryProvider;
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/screens/shopping_item_form_screen.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_voice_draft_panel.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:home_pocket/shared/widgets/ledger_type_selector.dart';
import 'package:home_pocket/shared/widgets/list_type_selector.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class _MockCreateShoppingItemUseCase extends Mock
    implements CreateShoppingItemUseCase {}

class _MockUpdateShoppingItemUseCase extends Mock
    implements UpdateShoppingItemUseCase {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _FakeCreateParams extends Fake implements CreateShoppingItemParams {}

class _FakeUpdateParams extends Fake implements UpdateShoppingItemParams {}

class _CapturingSpeechService implements StartSpeechRecognitionUseCase {
  _CapturingSpeechService({this.available = true, this.cancelGate});

  final bool available;
  final Completer<void>? cancelGate;
  void Function(String status)? onStatus;
  void Function(String errorMsg, bool permanent)? onError;
  void Function(SpeechRecognitionResult result)? onResult;
  void Function(double normalizedLevel)? onSoundLevel;
  Duration? pauseFor;
  int initializeCount = 0;
  int startCount = 0;
  int stopCount = 0;
  int cancelCount = 0;
  bool listening = false;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String errorMsg, bool permanent)? onError,
  }) async {
    initializeCount++;
    this.onStatus = onStatus;
    this.onError = onError;
    return available;
  }

  @override
  bool get isAvailable => available;

  @override
  bool get isListening => listening;

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
    this.onSoundLevel = onSoundLevel;
    this.pauseFor = pauseFor;
    startCount++;
    listening = true;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    listening = false;
  }

  @override
  Future<void> cancel() async {
    cancelCount++;
    listening = false;
    await cancelGate?.future;
  }

  void emitFinal(String words) {
    onResult!(
      SpeechRecognitionResult([
        SpeechRecognitionWords(words, null, 0.95),
      ], true),
    );
  }

  void emitStatus(String status) => onStatus!(status);

  void emitError(String message, {required bool permanent}) =>
      onError!(message, permanent);
}

ShoppingItem _item({String listType = 'private'}) => ShoppingItem(
  id: 'item-1',
  deviceId: 'device-1',
  listType: listType,
  name: 'Existing',
  ledgerType: LedgerType.daily,
  quantity: 1,
  tags: const [],
  createdAt: DateTime(2026, 7, 16),
);

Category _category({
  required String id,
  required String name,
  required int level,
  String? parentId,
}) => Category(
  id: id,
  name: name,
  icon: 'category',
  color: 'green',
  level: level,
  parentId: parentId,
  createdAt: DateTime(2026, 7, 16),
);

Future<void> _pumpForm(
  WidgetTester tester, {
  required _CapturingSpeechService speech,
  required _MockCreateShoppingItemUseCase create,
  required _MockUpdateShoppingItemUseCase update,
  required _MockDeviceIdentityRepository device,
  required _MockCategoryRepository categories,
  String listType = 'public',
  ShoppingItem? item,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        createShoppingItemUseCaseProvider.overrideWithValue(create),
        updateShoppingItemUseCaseProvider.overrideWithValue(update),
        deviceIdentityRepositoryProvider.overrideWithValue(device),
        categoryRepositoryProvider.overrideWithValue(categories),
        currentLocaleProvider.overrideWith((_) async => const Locale('en')),
        voiceLocaleIdProvider.overrideWith((_) async => 'en-US'),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: ShoppingItemFormScreen(
          listType: listType,
          item: item,
          speechService: speech,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late _MockCreateShoppingItemUseCase create;
  late _MockUpdateShoppingItemUseCase update;
  late _MockDeviceIdentityRepository device;
  late _MockCategoryRepository categories;

  setUpAll(() {
    registerFallbackValue(_FakeCreateParams());
    registerFallbackValue(_FakeUpdateParams());
  });

  setUp(() {
    create = _MockCreateShoppingItemUseCase();
    update = _MockUpdateShoppingItemUseCase();
    device = _MockDeviceIdentityRepository();
    categories = _MockCategoryRepository();
    when(
      () => create.execute(any()),
    ).thenAnswer((_) async => Result.success(_item()));
    when(
      () => update.execute(any()),
    ).thenAnswer((_) async => Result.success(_item()));
    when(device.getDeviceId).thenAnswer((_) async => 'device-1');
    when(() => categories.findById(any())).thenAnswer((_) async => null);
  });

  testWidgets('create uses v16 geometry and edit omits the voice draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final speech = _CapturingSpeechService();
    await _pumpForm(
      tester,
      speech: speech,
      create: create,
      update: update,
      device: device,
      categories: categories,
    );

    expect(find.byKey(ShoppingVoiceDraftPanel.manualStateKey), findsOneWidget);
    expect(find.byKey(const Key('shopping_form_back_button')), findsOneWidget);
    final nameCardRect = tester.getRect(
      find.byKey(const Key('shopping_form_name_card')),
    );
    final nameErrorRect = tester.getRect(
      find.byKey(const Key('shopping_form_name_error_slot')),
    );
    final voiceRect = tester.getRect(
      find.byKey(ShoppingVoiceDraftPanel.manualStateKey),
    );
    final primaryCardRect = tester.getRect(
      find.byKey(const Key('shopping_form_primary_card')),
    );
    final secondaryCardRect = tester.getRect(
      find.byKey(const Key('shopping_form_secondary_card')),
    );
    expect(nameCardRect.top, closeTo(66, 1));
    expect(nameCardRect.height, closeTo(58, 1));
    expect(nameErrorRect.top, closeTo(nameCardRect.bottom, 0.01));
    expect(nameErrorRect.height, 22);
    expect(voiceRect.top, closeTo(nameErrorRect.bottom + 10, 0.01));
    expect(primaryCardRect.top, closeTo(voiceRect.bottom + 14, 0.01));
    expect(secondaryCardRect.top, closeTo(primaryCardRect.bottom + 14, 0.01));
    final nameField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('shopping_form_name_field')),
        matching: find.byType(TextField),
      ),
    );
    expect(nameField.maxLength, 200);
    expect(nameField.decoration?.counterText, isEmpty);
    expect(
      tester.getSize(find.byKey(const Key('shopping_form_save_button'))),
      const Size(72, 44),
    );
    expect(
      tester.getSize(find.byKey(const Key('shopping_quantity_decrease'))),
      const Size.square(44),
    );
    final ledgerSelector = tester.widget<LedgerTypeSelector>(
      find.byKey(const Key('shopping_form_ledger_selector')),
    );
    expect(ledgerSelector.dailyLabel, 'Daily');
    expect(ledgerSelector.joyLabel, 'Joy');
    expect(ledgerSelector.showIcons, isFalse);
    expect(ledgerSelector.chipMinHeight, 44);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('ledger_type_daily_chip')))
          .height,
      44,
    );
    final listTypeSelector = tester.widget<ListTypeSelector>(
      find.byKey(const Key('shopping_form_list_type_selector')),
    );
    expect(listTypeSelector.showIcons, isFalse);
    expect(listTypeSelector.chipMinHeight, 40);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('list_type_public_chip')))
          .height,
      40,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('shopping_form_ledger_selector')),
        matching: find.byIcon(Icons.shield_outlined),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('shopping_form_ledger_selector')),
        matching: find.byIcon(Icons.auto_awesome),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('shopping_form_list_type_selector')),
        matching: find.byIcon(Icons.groups_outlined),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('shopping_form_list_type_selector')),
        matching: find.byIcon(Icons.lock_outline),
      ),
      findsNothing,
    );
    expect(find.text('Type cannot be changed after saving'), findsOneWidget);

    final noteField = find.byKey(const Key('shopping_form_note_field'));
    await tester.scrollUntilVisible(
      noteField,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    final noteRect = tester.getRect(noteField);
    expect(noteRect.left, closeTo(103, 1));
    expect(noteRect.right, closeTo(350, 1));
    expect(
      tester.widget<TextField>(noteField).decoration?.hintText,
      'Add any needed note',
    );

    await _pumpForm(
      tester,
      speech: speech,
      create: create,
      update: update,
      device: device,
      categories: categories,
      item: _item(),
    );
    for (final state in ShoppingVoiceDraftState.values) {
      expect(find.byKey(ShoppingVoiceDraftPanel.stateKey(state)), findsNothing);
    }
    expect(find.text('Cannot be changed after creation'), findsOneWidget);
  });

  testWidgets(
    'final speech fills a draft and never changes type or auto-saves',
    (tester) async {
      final grocery = _category(
        id: 'cat_food_groceries',
        name: 'Groceries',
        level: 2,
        parentId: 'cat_food',
      );
      final food = _category(id: 'cat_food', name: 'Food', level: 1);
      when(
        () => categories.findById('cat_food_groceries'),
      ).thenAnswer((_) async => grocery);
      when(() => categories.findById('cat_food')).thenAnswer((_) async => food);
      final speech = _CapturingSpeechService();
      await _pumpForm(
        tester,
        speech: speech,
        create: create,
        update: update,
        device: device,
        categories: categories,
        listType: 'private',
      );

      await tester.tap(find.byKey(const Key('shopping_form_save_button')));
      await tester.pump();
      expect(find.text('Name is required'), findsOneWidget);
      await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
      await tester.pumpAndSettle();
      expect(speech.pauseFor, const Duration(seconds: 3));
      expect(
        find.byKey(ShoppingVoiceDraftPanel.listeningStateKey),
        findsOneWidget,
      );

      speech.emitFinal(
        'Add two bottles of milk, daily, estimated price 500 yen',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ShoppingVoiceDraftPanel.reviewStateKey),
        findsOneWidget,
      );
      expect(find.text('Name is required'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('shopping_form_name_field')),
            )
            .controller
            ?.text,
        'milk',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('shopping_form_quantity_field')),
            )
            .controller
            ?.text,
        '2',
      );
      final priceField = find.byKey(const Key('shopping_form_price_field'));
      await tester.scrollUntilVisible(
        priceField,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<TextField>(priceField).controller?.text, '500');
      expect(find.text('Food > Groceries'), findsOneWidget);
      expect(
        tester
            .widget<ListTypeSelector>(
              find.byKey(const Key('shopping_form_list_type_selector')),
            )
            .selected,
        'private',
      );
      verifyNever(() => create.execute(any()));

      final keyboardAction = find.byKey(
        ShoppingVoiceDraftPanel.keyboardActionKey,
      );
      await tester.scrollUntilVisible(
        keyboardAction,
        -120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(keyboardAction);
      await tester.pump();
      expect(
        find.byKey(ShoppingVoiceDraftPanel.manualStateKey),
        findsOneWidget,
      );
      final nameFieldAfterKeyboard = find.byKey(
        const Key('shopping_form_name_field'),
      );
      await tester.scrollUntilVisible(
        nameFieldAfterKeyboard,
        -120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<TextFormField>(nameFieldAfterKeyboard).controller?.text,
        'milk',
      );
    },
  );

  testWidgets('keyboard during listening cancels and restores the snapshot', (
    tester,
  ) async {
    final speech = _CapturingSpeechService();
    await _pumpForm(
      tester,
      speech: speech,
      create: create,
      update: update,
      device: device,
      categories: categories,
    );
    final name = find.byKey(const Key('shopping_form_name_field'));
    await tester.enterText(name, 'original');
    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
    await tester.pumpAndSettle();
    await tester.enterText(name, 'changed while listening');

    await tester.tap(find.byKey(const Key('shopping_form_save_button')));
    await tester.pump();
    verifyNever(() => create.execute(any()));

    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.keyboardActionKey));
    await tester.pump();
    expect(speech.cancelCount, 1);
    expect(tester.widget<TextFormField>(name).controller?.text, 'original');
    expect(find.byKey(ShoppingVoiceDraftPanel.manualStateKey), findsOneWidget);
  });

  testWidgets('done completes a second session opened after keyboard return', (
    tester,
  ) async {
    final speech = _CapturingSpeechService();
    await _pumpForm(
      tester,
      speech: speech,
      create: create,
      update: update,
      device: device,
      categories: categories,
    );

    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.keyboardActionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
    await tester.pumpAndSettle();

    expect(speech.initializeCount, 1);
    expect(speech.startCount, 2);
    speech.emitStatus('done');
    await tester.pumpAndSettle();

    expect(find.byKey(ShoppingVoiceDraftPanel.reviewStateKey), findsOneWidget);
  });

  testWidgets('keyboard invalidates a delayed category result', (tester) async {
    final categoryCompleter = Completer<Category?>();
    when(
      () => categories.findById('cat_food_groceries'),
    ).thenAnswer((_) => categoryCompleter.future);
    final speech = _CapturingSpeechService();
    await _pumpForm(
      tester,
      speech: speech,
      create: create,
      update: update,
      device: device,
      categories: categories,
    );
    final name = find.byKey(const Key('shopping_form_name_field'));
    await tester.enterText(name, 'original');
    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
    await tester.pumpAndSettle();

    speech.emitFinal('Add two bottles of milk, daily, estimated price 500 yen');
    await tester.pump();
    expect(
      find.byKey(ShoppingVoiceDraftPanel.processingStateKey),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('shopping_form_save_button')));
    await tester.pump();
    verifyNever(() => create.execute(any()));

    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.keyboardActionKey));
    await tester.pump();
    categoryCompleter.complete(
      _category(
        id: 'cat_food_groceries',
        name: 'Groceries',
        level: 2,
        parentId: 'cat_food',
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<TextFormField>(name).controller?.text, 'original');
    expect(find.byKey(ShoppingVoiceDraftPanel.manualStateKey), findsOneWidget);
  });

  testWidgets('rerecord restores the original snapshot and starts again', (
    tester,
  ) async {
    final speech = _CapturingSpeechService();
    await _pumpForm(
      tester,
      speech: speech,
      create: create,
      update: update,
      device: device,
      categories: categories,
    );
    final name = find.byKey(const Key('shopping_form_name_field'));
    await tester.enterText(name, 'original');
    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
    await tester.pumpAndSettle();
    speech.emitFinal('Add one puzzle, joy, estimated price 2500 JPY');
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(name).controller?.text, 'puzzle');

    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.coreActionKey));
    await tester.pumpAndSettle();

    expect(speech.startCount, 2);
    expect(tester.widget<TextFormField>(name).controller?.text, 'original');
    expect(
      find.byKey(ShoppingVoiceDraftPanel.listeningStateKey),
      findsOneWidget,
    );
  });

  testWidgets('error exits listening during a rerecord session', (
    tester,
  ) async {
    final speech = _CapturingSpeechService();
    await _pumpForm(
      tester,
      speech: speech,
      create: create,
      update: update,
      device: device,
      categories: categories,
    );
    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
    await tester.pumpAndSettle();
    speech.emitFinal('Add one puzzle, joy, estimated price 2500 JPY');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.coreActionKey));
    await tester.pumpAndSettle();
    expect(speech.startCount, 2);
    speech.emitError('error_audio', permanent: false);
    await tester.pumpAndSettle();

    expect(find.byKey(ShoppingVoiceDraftPanel.manualStateKey), findsOneWidget);
  });

  testWidgets(
    'cancelGate keeps save disabled while rerecord restarts into listening',
    (tester) async {
      final cancelGate = Completer<void>();
      final speech = _CapturingSpeechService(cancelGate: cancelGate);
      await _pumpForm(
        tester,
        speech: speech,
        create: create,
        update: update,
        device: device,
        categories: categories,
      );
      await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
      await tester.pumpAndSettle();
      speech.emitFinal('Add one puzzle, joy, estimated price 2500 JPY');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ShoppingVoiceDraftPanel.coreActionKey));
      await tester.pump();

      final saveButton = find.byKey(const Key('shopping_form_save_button'));
      InkWell saveInkWell() => tester.widget<InkWell>(
        find.descendant(of: saveButton, matching: find.byType(InkWell)),
      );
      expect(saveInkWell().onTap, isNull);
      await tester.tap(saveButton);
      await tester.pump();
      verifyNever(() => create.execute(any()));

      cancelGate.complete();
      await tester.pumpAndSettle();

      expect(
        find.byKey(ShoppingVoiceDraftPanel.listeningStateKey),
        findsOneWidget,
      );
      expect(saveInkWell().onTap, isNull);
      await tester.tap(saveButton);
      await tester.pump();
      verifyNever(() => create.execute(any()));
    },
  );

  testWidgets('unavailable settings action surfaces localized guidance', (
    tester,
  ) async {
    final speech = _CapturingSpeechService(available: false);
    await _pumpForm(
      tester,
      speech: speech,
      create: create,
      update: update,
      device: device,
      categories: categories,
    );

    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ShoppingVoiceDraftPanel.unavailableStateKey),
      findsOneWidget,
    );
    await tester.tap(find.byKey(ShoppingVoiceDraftPanel.settingsActionKey));
    await tester.pump();
    expect(find.text('Please allow microphone access'), findsWidgets);
  });
}
