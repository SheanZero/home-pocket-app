import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/check_group_validity_use_case.dart';
import 'package:home_pocket/application/family_sync/handle_group_dissolved_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockInvalidationCleanup extends Mock
    implements HandleGroupDissolvedUseCase {}

void main() {
  late _MockGroupRepository groupRepository;
  late _MockRelayApiClient apiClient;
  late _MockInvalidationCleanup invalidationCleanup;
  late CheckGroupValidityUseCase useCase;

  final activeGroup = GroupInfo(
    groupId: 'group-1',
    status: GroupStatus.active,
    groupName: 'Family',
    role: 'member',
    groupKey: 'secret-group-key',
    members: const [],
    createdAt: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(LocalGroupCleanupMode.deactivate);
  });

  setUp(() {
    groupRepository = _MockGroupRepository();
    apiClient = _MockRelayApiClient();
    invalidationCleanup = _MockInvalidationCleanup();
    useCase = CheckGroupValidityUseCase(
      groupRepo: groupRepository,
      apiClient: apiClient,
      invalidationCleanup: invalidationCleanup,
    );

    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => activeGroup);
    when(
      () => invalidationCleanup.execute(
        groupId: any(named: 'groupId'),
        mode: any(named: 'mode'),
      ),
    ).thenAnswer((_) async {});
  });

  test(
    '200 with groupExisted false invalidates the local active group',
    () async {
      when(
        () => apiClient.checkGroup(),
      ).thenAnswer((_) async => <String, dynamic>{'groupExisted': false});

      final result = await useCase.execute(forceCheck: true);

      expect(result, isA<GroupInvalid>());
      verify(
        () => invalidationCleanup.execute(
          groupId: 'group-1',
          mode: LocalGroupCleanupMode.deactivate,
        ),
      ).called(1);
    },
  );

  test('validates matching explicit group id', () async {
    when(() => apiClient.checkGroup()).thenAnswer(
      (_) async => <String, dynamic>{
        'groupExisted': true,
        'groupId': 'group-1',
      },
    );

    final result = await useCase.execute(forceCheck: true);

    expect(result, isA<GroupValid>());
    verifyNever(
      () => invalidationCleanup.execute(groupId: any(named: 'groupId')),
    );
  });

  test(
    'mismatched explicit group id invalidates only the local group',
    () async {
      when(() => apiClient.checkGroup()).thenAnswer(
        (_) async => <String, dynamic>{
          'groupExisted': true,
          'groupId': 'group-2',
        },
      );

      final result = await useCase.execute(forceCheck: true);

      expect(result, isA<GroupInvalid>());
      verify(
        () => invalidationCleanup.execute(
          groupId: 'group-1',
          mode: LocalGroupCleanupMode.deactivate,
        ),
      ).called(1);
      verifyNever(() => invalidationCleanup.execute(groupId: 'group-2'));
    },
  );

  test('malformed 200 response is non-destructive', () async {
    when(
      () => apiClient.checkGroup(),
    ).thenAnswer((_) async => <String, dynamic>{'groupExisted': true});

    final result = await useCase.execute(forceCheck: true);

    expect(result, isA<GroupValid>());
    verifyNever(
      () => invalidationCleanup.execute(groupId: any(named: 'groupId')),
    );
  });

  test('network and 5xx failures do not revoke local membership', () async {
    when(() => apiClient.checkGroup()).thenThrow(
      const RelayApiException(statusCode: 503, message: 'Unavailable'),
    );

    final serverFailure = await useCase.execute(forceCheck: true);

    when(() => apiClient.checkGroup()).thenThrow(Exception('offline'));
    final networkFailure = await useCase.execute(forceCheck: true);

    expect(serverFailure, isA<GroupValid>());
    expect(networkFailure, isA<GroupValid>());
    verifyNever(
      () => invalidationCleanup.execute(groupId: any(named: 'groupId')),
    );
  });

  test(
    'authenticated 403 cleanup does not make another network request',
    () async {
      final result = await useCase
          .invalidateAfterAuthenticatedMembershipFailure(
            groupId: 'group-1',
            statusCode: 403,
            reason: 'Removed from group',
          );

      expect(result, isA<GroupInvalid>());
      verify(
        () => invalidationCleanup.execute(
          groupId: 'group-1',
          mode: LocalGroupCleanupMode.deactivate,
        ),
      ).called(1);
      verifyNever(() => apiClient.checkGroup());
    },
  );

  test('authenticated 404 permanently deletes the dissolved group', () async {
    final result = await useCase.invalidateAfterAuthenticatedMembershipFailure(
      groupId: 'group-1',
      statusCode: 404,
      reason: 'Group dissolved',
    );

    expect(result, isA<GroupInvalid>());
    verify(
      () => invalidationCleanup.execute(
        groupId: 'group-1',
        mode: LocalGroupCleanupMode.delete,
      ),
    ).called(1);
  });

  test('confirming or awaiting-key local snapshots are not removed', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer((_) async => null);

    final result = await useCase.execute(forceCheck: true);

    expect(result, isA<GroupNoGroup>());
    verifyNever(() => apiClient.checkGroup());
    verifyNever(
      () => invalidationCleanup.execute(groupId: any(named: 'groupId')),
    );
  });

  test(
    'no-group result does not mask a later awaiting-key activation',
    () async {
      var isActive = false;
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => isActive ? activeGroup : null);
      when(() => apiClient.checkGroup()).thenAnswer(
        (_) async => <String, dynamic>{
          'groupExisted': true,
          'groupId': 'group-1',
        },
      );

      expect(await useCase.execute(), isA<GroupNoGroup>());

      isActive = true;
      expect(await useCase.execute(), isA<GroupValid>());
      verify(() => apiClient.checkGroup()).called(1);
    },
  );
}
