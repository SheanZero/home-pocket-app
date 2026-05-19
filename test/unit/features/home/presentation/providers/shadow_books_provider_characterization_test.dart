import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_provider_scope.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockBookRepository extends Mock implements BookRepository {}

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockGroupRepository mockGroupRepo;
  late _MockBookRepository mockBookRepo;
  late _MockAnalyticsRepository mockAnalyticsRepo;
  late ProviderContainer container;

  setUp(() {
    mockGroupRepo = _MockGroupRepository();
    mockBookRepo = _MockBookRepository();
    mockAnalyticsRepo = _MockAnalyticsRepository();

    // No active group — activeGroupProvider will emit null
    when(
      () => mockGroupRepo.watchActiveGroup(),
    ).thenAnswer((_) => Stream.value(null));
    when(() => mockBookRepo.findAll()).thenAnswer((_) async => []);
    when(
      () => mockBookRepo.findShadowBooksByGroupId(any()),
    ).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(mockGroupRepo),
        bookRepositoryProvider.overrideWithValue(mockBookRepo),
        analyticsRepositoryProvider.overrideWithValue(mockAnalyticsRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group(
    'home/shadow_books_provider characterization tests (pre-refactor behavior)',
    () {
      test(
        'shadowBooksProvider resolves to empty list when no active group',
        () async {
          final result = await waitForFirstValue(container, shadowBooksProvider);

          expect(
            result.requireValue,
            isEmpty,
            reason:
                'shadowBooksProvider must return [] when activeGroup is null',
          );
        },
      );

      test(
        'shadowAggregateProvider resolves to ShadowAggregate.empty() when no shadow books',
        () async {
          final aggProvider = shadowAggregateProvider(
            startDate: DateTime(2026, 3),
            endDate: DateTime(2026, 3, 31, 23, 59, 59),
          );
          final result = await waitForFirstValue(container, aggProvider);

          expect(result.requireValue.totalExpenses, 0);
          expect(result.requireValue.prevTotalExpenses, 0);
          expect(result.requireValue.perBookReports, isEmpty);
        },
      );
    },
  );
}
