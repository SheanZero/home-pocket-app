import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/update_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_details_form_config.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/detail_info_card.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/features/voice/domain/models/recognition_outcome.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class _MockUpdateTransactionUseCase extends Mock
    implements UpdateTransactionUseCase {}

class _FakeUpdateTransactionParams extends Fake
    implements UpdateTransactionParams {}

class _SingleCategoryRepository implements CategoryRepository {
  _SingleCategoryRepository(this.category);

  final Category category;

  @override
  Future<Category?> findById(String id) async =>
      id == category.id ? category : null;
  @override
  Future<List<Category>> findActive() async => [category];
  @override
  Future<List<Category>> findAll() async => [category];
  @override
  Future<List<Category>> findByLevel(int level) async =>
      category.level == level ? [category] : [];
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
  @override
  Future<void> deleteAll() async {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUpdateTransactionParams());
  });

  Widget buildForm({
    required GlobalKey<TransactionDetailsFormState> formKey,
    bool useV16Layout = false,
    TransactionDetailsFormConfig? config,
    List<Override> overrides = const [],
  }) {
    return createLocalizedWidget(
      Scaffold(
        body: TransactionDetailsForm(
          key: formKey,
          config:
              config ??
              TransactionDetailsFormConfig.$new(
                bookId: 'book-1',
                entrySource: EntrySource.manual,
              ),
          useV16Layout: useV16Layout,
        ),
      ),
      overrides: [
        currentLocaleProvider.overrideWith((_) async => const Locale('en')),
        ...overrides,
      ],
    );
  }

  testWidgets('v16 layout uses compact cards and 10px vertical rhythm', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final formKey = GlobalKey<TransactionDetailsFormState>();
    await tester.pumpWidget(buildForm(formKey: formKey, useV16Layout: true));
    await tester.pumpAndSettle();

    final details = find.byKey(const ValueKey('v16-details-card'));
    final purpose = find.byKey(const ValueKey('v16-purpose-card'));
    final note = find.byKey(const ValueKey('v16-note-card'));

    expect(details, findsOneWidget);
    expect(find.byKey(const ValueKey('category-chip')), findsOneWidget);
    expect(find.byKey(const ValueKey('date-chip')), findsOneWidget);
    expect(find.byKey(const ValueKey('merchant-textfield')), findsOneWidget);
    expect(purpose, findsOneWidget);
    expect(note, findsOneWidget);
    expect(tester.getSize(note).height, 52);
    expect(
      tester.getTopLeft(purpose).dy - tester.getBottomLeft(details).dy,
      10,
    );
    expect(tester.getTopLeft(note).dy - tester.getBottomLeft(purpose).dy, 10);
  });

  testWidgets('v16 ledger API restores joy state and compact satisfaction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final formKey = GlobalKey<TransactionDetailsFormState>();
    await tester.pumpWidget(buildForm(formKey: formKey, useV16Layout: true));
    await tester.pumpAndSettle();

    expect(formKey.currentState!.currentLedgerType, LedgerType.daily);
    formKey.currentState!.updateLedgerType(LedgerType.joy);
    await tester.pump();

    expect(formKey.currentState!.currentLedgerType, LedgerType.joy);
    expect(find.byKey(const ValueKey('v16-satisfaction-card')), findsOneWidget);
  });

  testWidgets(
    'v16 new voice entry marks category merchant and note, with an explicit weak-category warning',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final formKey = GlobalKey<TransactionDetailsFormState>();
      await tester.pumpWidget(
        buildForm(
          formKey: formKey,
          useV16Layout: true,
          config: TransactionDetailsFormConfig.$new(
            bookId: 'book-1',
            entrySource: EntrySource.voice,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('v16-voice-source-category')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('v16-voice-source-merchant')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('v16-voice-source-note')),
        findsOneWidget,
      );
      expect(find.text('Voice filled'), findsNWidgets(3));
      expect(
        find.byKey(const ValueKey('v16-category-select-required')),
        findsNothing,
      );

      formKey.currentState!.updateRecognition(ConfidenceBand.weak, const []);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('v16-category-select-required')),
        findsOneWidget,
      );
      expect(find.text('Select required'), findsOneWidget);

      formKey.currentState!.updateRecognition(null, const []);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('v16-category-select-required')),
        findsNothing,
      );
    },
  );

  testWidgets('v16 manual new entry does not show voice-source badges', (
    tester,
  ) async {
    final formKey = GlobalKey<TransactionDetailsFormState>();
    await tester.pumpWidget(buildForm(formKey: formKey, useV16Layout: true));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('v16-voice-source-category')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('v16-voice-source-merchant')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('v16-voice-source-note')), findsNothing);
  });

  testWidgets(
    'v16 edit keeps an existing odd Joy value visible and unchanged',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final category = Category(
        id: 'hobby',
        name: 'Hobby',
        icon: 'sports_tennis',
        color: '#9C27B0',
        level: 1,
        createdAt: DateTime(2026, 5, 1),
      );
      final seed = Transaction(
        id: 'tx-joy-7',
        bookId: 'book-1',
        deviceId: 'device-1',
        amount: 700,
        type: TransactionType.expense,
        categoryId: category.id,
        ledgerType: LedgerType.joy,
        timestamp: DateTime(2026, 5, 1),
        currentHash: 'hash',
        createdAt: DateTime(2026, 5, 1),
        joyFullness: 7,
        entrySource: EntrySource.manual,
      );
      final updateUseCase = _MockUpdateTransactionUseCase();
      when(
        () => updateUseCase.execute(any()),
      ).thenAnswer((_) async => Result.success(seed));

      final formKey = GlobalKey<TransactionDetailsFormState>();
      await tester.pumpWidget(
        buildForm(
          formKey: formKey,
          useV16Layout: true,
          config: TransactionDetailsFormConfig.edit(seed: seed),
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              _SingleCategoryRepository(category),
            ),
            updateTransactionUseCaseProvider.overrideWithValue(updateUseCase),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(formKey.currentState!.currentSatisfaction, 7);
      expect(find.textContaining('7/10'), findsOneWidget);
      expect(find.textContaining('8/10'), findsNothing);
      expect(
        find.byKey(const ValueKey('v16-voice-source-category')),
        findsNothing,
      );

      await formKey.currentState!.submit();
      final params =
          verify(() => updateUseCase.execute(captureAny())).captured.single
              as UpdateTransactionParams;
      expect(params.joyFullness, 7);
    },
  );

  testWidgets('legacy layout remains the default', (tester) async {
    final formKey = GlobalKey<TransactionDetailsFormState>();
    await tester.pumpWidget(buildForm(formKey: formKey));
    await tester.pumpAndSettle();

    expect(find.byType(DetailInfoCard), findsOneWidget);
    expect(find.byKey(const ValueKey('v16-details-card')), findsNothing);
  });
}
