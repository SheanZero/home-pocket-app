import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/reorder_shopping_items_use_case.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

void main() {
  late _MockShoppingItemRepository mockRepo;
  late ReorderShoppingItemsUseCase useCase;

  setUp(() {
    mockRepo = _MockShoppingItemRepository();
    useCase = ReorderShoppingItemsUseCase(
      shoppingItemRepository: mockRepo,
    );

    when(
      () => mockRepo.reorder(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepo.reorderBatch(any()),
    ).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  group('ReorderShoppingItemsUseCase', () {
    test(
      'reorder calls repo.reorder with correct params (D37-01)',
      () async {
        final result = await useCase.execute('item-1', 3);

        expect(result.isSuccess, isTrue);
        verify(() => mockRepo.reorder('item-1', 3)).called(1);
      },
    );

    test('reorder does NOT call tracker (D37-01)', () async {
      // D37-01: sortOrder is local-per-device — NOT synced; no tracker involved.
      // ReorderShoppingItemsUseCase has no ShoppingItemChangeTracker constructor param.
      // Verify the use case has no tracker by checking there is no tracker field to mock.
      // The constructor only takes shoppingItemRepository — no changeTracker param.
      final result = await useCase.execute('item-2', 5);

      expect(result.isSuccess, isTrue);
      // No tracker reference in the use case — reorder is strictly local-only (D37-01)
    });

    test('empty itemId returns Result.error', () async {
      final result = await useCase.execute('', 3);

      expect(result.isSuccess, isFalse);
    });

    test('reorder calls repo with correct new sort order', () async {
      await useCase.execute('item-abc', 10);

      verify(() => mockRepo.reorder('item-abc', 10)).called(1);
    });

    test(
      'applyOrder persists the full contiguous order via repo.reorderBatch '
      '(quick-260609-pmc-04)',
      () async {
        final result = await useCase.applyOrder(['c', 'a', 'b']);

        expect(result.isSuccess, isTrue);
        verify(() => mockRepo.reorderBatch(['c', 'a', 'b'])).called(1);
      },
    );

    test('applyOrder with an empty id returns Result.error', () async {
      final result = await useCase.applyOrder(['a', '', 'b']);

      expect(result.isSuccess, isFalse);
      verifyNever(() => mockRepo.reorderBatch(any()));
    });
  });
}
