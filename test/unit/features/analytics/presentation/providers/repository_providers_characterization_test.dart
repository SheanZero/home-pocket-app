import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';

// No mocks needed: AnalyticsDao and AnalyticsRepositoryImpl have no external
// deps beyond AppDatabase which we provide via forTesting().

void main() {
  late AppDatabase testDatabase;
  late ProviderContainer container;

  setUp(() {
    testDatabase = AppDatabase.forTesting();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(testDatabase)],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDatabase.close();
  });

  group(
    'analytics/repository_providers characterization tests (pre-refactor behavior)',
    () {
      test('analyticsDaoProvider constructs AnalyticsDao without error', () {
        final dao = container.read(analyticsDaoProvider);
        expect(dao, isNotNull);
      });

      test(
        'analyticsRepositoryProvider constructs AnalyticsRepository without error',
        () {
          final repo = container.read(analyticsRepositoryProvider);
          expect(repo, isA<AnalyticsRepository>());
        },
      );

      test('analyticsRepositoryProvider returns non-null instance', () {
        expect(container.read(analyticsRepositoryProvider), isNotNull);
      });
    },
  );
}
