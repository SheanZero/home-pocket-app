import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_best_joy_moment_use_case.dart';
import 'package:home_pocket/application/analytics/get_family_happiness_use_case.dart';
import 'package:home_pocket/application/analytics/get_happiness_report_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

class _MockBookRepository extends Mock implements BookRepository {}

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late _MockAnalyticsRepository analyticsRepository;
  late _MockBookRepository bookRepository;
  late _MockGroupRepository groupRepository;

  setUp(() {
    analyticsRepository = _MockAnalyticsRepository();
    bookRepository = _MockBookRepository();
    groupRepository = _MockGroupRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(analyticsRepository),
        bookRepositoryProvider.overrideWithValue(bookRepository),
        groupRepositoryProvider.overrideWithValue(groupRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('analytics happiness provider wiring', () {
    test('getHappinessReportUseCaseProvider resolves without throwing', () {
      final container = makeContainer();

      expect(
        container.read(getHappinessReportUseCaseProvider),
        isA<GetHappinessReportUseCase>(),
      );
    });

    test('getBestJoyMomentUseCaseProvider resolves without throwing', () {
      final container = makeContainer();

      expect(
        container.read(getBestJoyMomentUseCaseProvider),
        isA<GetBestJoyMomentUseCase>(),
      );
    });

    test('getFamilyHappinessUseCaseProvider resolves without throwing', () {
      final container = makeContainer();

      expect(
        container.read(getFamilyHappinessUseCaseProvider),
        isA<GetFamilyHappinessUseCase>(),
      );
    });

    test('familyHappinessProvider short-circuits when no group is active', () async {
      when(
        () => groupRepository.watchActiveGroup(),
      ).thenAnswer((_) => Stream.value(null));
      final container = makeContainer();

      final result = await container.read(
        familyHappinessProvider(year: 2026, month: 3).future,
      );

      expect(result.totalGroupSoulTx, 0);
      expect(result.familyHighlightsSum, isA<Empty<int>>());
      expect(result.sharedJoyInsight, isA<Empty>());
      expect(result.medianSatisfaction, isA<Empty<double>>());
      verifyZeroInteractions(analyticsRepository);
    });

    test(
      'familyHappinessProvider short-circuits when shadow books are empty',
      () async {
        when(
          () => groupRepository.watchActiveGroup(),
        ).thenAnswer((_) => Stream.value(_activeGroup()));
        when(
          () => bookRepository.findShadowBooksByGroupId('group-1'),
        ).thenAnswer((_) async => []);
        final container = makeContainer();

        final result = await container.read(
          familyHappinessProvider(year: 2026, month: 3).future,
        );

        expect(result.totalGroupSoulTx, 0);
        expect(result.familyHighlightsSum, isA<Empty<int>>());
        expect(result.sharedJoyInsight, isA<Empty>());
        expect(result.medianSatisfaction, isA<Empty<double>>());
        verifyZeroInteractions(analyticsRepository);
      },
    );
  });
}

GroupInfo _activeGroup() {
  return GroupInfo(
    groupId: 'group-1',
    groupName: 'Test Family',
    status: GroupStatus.active,
    role: 'owner',
    members: const [],
    createdAt: DateTime(2026, 3, 1),
  );
}
