import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/shadow_books_provider.dart';
import 'package:mocktail/mocktail.dart';

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
          // Listen to prevent auto-dispose during test
          final sub = container.listen(shadowBooksProvider, (_, __) {});
          // Wait for activeGroupProvider stream to settle (it's a keepAlive stream provider)
          await Future<void>.delayed(const Duration(milliseconds: 100));
          final result = await container.read(shadowBooksProvider.future);
          sub.close();
          expect(result, isEmpty,
              reason:
                  'shadowBooksProvider must return [] when activeGroup is null');
        },
      );

      test(
        'shadowAggregateProvider resolves to ShadowAggregate.empty() when no shadow books',
        () async {
          final aggProvider = shadowAggregateProvider(year: 2026, month: 3);
          // Listen to prevent auto-dispose during test
          final sub = container.listen(aggProvider, (_, __) {});
          // Wait for shadowBooksProvider (which aggProvider depends on) to settle
          await Future<void>.delayed(const Duration(milliseconds: 150));
          final result = await container.read(aggProvider.future);
          sub.close();
          expect(result.totalExpenses, 0);
          expect(result.prevTotalExpenses, 0);
          expect(result.perBookReports, isEmpty);
        },
      );
    },
  );
}
