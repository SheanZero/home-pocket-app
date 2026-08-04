import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/shopping_list/create_shopping_item_use_case.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_unit.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_unit_usage_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class _RecordingUnitUsageRepository implements ShoppingUnitUsageRepository {
  final selections = <ShoppingUnitSelection>[];

  @override
  Future<void> record(ShoppingUnitSelection selection, DateTime usedAt) async {
    selections.add(selection);
  }

  @override
  Stream<List<ShoppingUnitUsage>> watchAll() => const Stream.empty();
}

void main() {
  late _MockShoppingItemRepository mockRepo;
  late ShoppingItemChangeTracker tracker;
  late CreateShoppingItemUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ShoppingItem(
        id: 'fallback-id',
        deviceId: 'device-1',
        listType: 'public',
        name: 'Fallback Item',
        createdAt: DateTime(2026, 6, 8),
      ),
    );
  });

  setUp(() {
    mockRepo = _MockShoppingItemRepository();
    tracker = ShoppingItemChangeTracker();
    useCase = CreateShoppingItemUseCase(
      shoppingItemRepository: mockRepo,
      changeTracker: tracker,
    );

    when(() => mockRepo.insert(any())).thenAnswer((_) async {});
  });

  group('CreateShoppingItemUseCase', () {
    test('private create does NOT enqueue tracker op (D37-06, SC-1)', () async {
      final params = CreateShoppingItemParams(
        deviceId: 'device-1',
        listType: 'private',
        name: 'Secret Gift',
      );

      final result = await useCase.execute(params);

      expect(result.isSuccess, isTrue);
      expect(tracker.pendingCount, 0);
    });

    test('public create enqueues tracker op (SC-1, SYNC-02)', () async {
      final params = CreateShoppingItemParams(
        deviceId: 'device-1',
        listType: 'public',
        name: 'Milk',
      );

      final result = await useCase.execute(params);

      expect(result.isSuccess, isTrue);
      expect(tracker.pendingCount, 1);
    });

    test('empty name returns Result.error (ITEM-01)', () async {
      final params = CreateShoppingItemParams(
        deviceId: 'device-1',
        listType: 'public',
        name: '',
      );

      final result = await useCase.execute(params);

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
    });

    test('insert is called with correct name (ITEM-01)', () async {
      final params = CreateShoppingItemParams(
        deviceId: 'device-1',
        listType: 'public',
        name: 'Eggs',
      );

      await useCase.execute(params);

      verify(() => mockRepo.insert(any())).called(1);
    });

    test('whitespace-only name returns Result.error (ITEM-01)', () async {
      final params = CreateShoppingItemParams(
        deviceId: 'device-1',
        listType: 'public',
        name: '   ',
      );

      final result = await useCase.execute(params);

      expect(result.isSuccess, isFalse);
    });

    test('successful create records the selected unit once', () async {
      final usageRepository = _RecordingUnitUsageRepository();
      final unitAwareUseCase = CreateShoppingItemUseCase(
        shoppingItemRepository: mockRepo,
        unitUsageRepository: usageRepository,
      );

      final result = await unitAwareUseCase.execute(
        const CreateShoppingItemParams(
          deviceId: 'device-1',
          listType: 'private',
          name: 'Sugar',
          quantity: 200,
          unit: ShoppingUnit.gram,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(usageRepository.selections, [
        const ShoppingUnitSelection(ShoppingUnit.gram),
      ]);
    });
  });
}
