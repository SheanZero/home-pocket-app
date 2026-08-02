import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/manage_group_invite_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late ManageGroupInviteUseCase useCase;
  final now = DateTime.utc(2026, 8, 1, 1);

  GroupInfo group({
    String role = 'owner',
    GroupStatus status = GroupStatus.active,
    String? inviteCode = '123456',
    DateTime? inviteExpiresAt,
  }) => GroupInfo(
    groupId: 'group-1',
    status: status,
    groupName: 'Pocket Family',
    role: role,
    inviteCode: inviteCode,
    inviteExpiresAt: inviteExpiresAt ?? now.add(const Duration(hours: 1)),
    members: const [],
    createdAt: now,
  );

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    useCase = ManageGroupInviteUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
      now: () => now,
    );
  });

  test(
    'reuses the current unexpired owner invite without API rotation',
    () async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => group());

      final result = await useCase.execute(groupId: 'group-1');

      expect(
        result,
        isA<ManageGroupInviteSuccess>()
            .having((value) => value.inviteCode, 'inviteCode', '123456')
            .having((value) => value.wasRegenerated, 'wasRegenerated', false),
      );
      verifyNever(() => apiClient.regenerateInvite(any()));
      verifyNever(() => groupRepository.updateInviteCode(any(), any(), any()));
    },
  );

  test(
    'regenerates an expired invite and atomically persists code and expiry',
    () async {
      final expiresAt = now.add(const Duration(hours: 24));
      when(() => groupRepository.getGroupById('group-1')).thenAnswer(
        (_) async =>
            group(inviteExpiresAt: now.subtract(const Duration(seconds: 1))),
      );
      when(() => apiClient.regenerateInvite('group-1')).thenAnswer(
        (_) async => {
          'inviteCode': '654321',
          'expiresAt': expiresAt.millisecondsSinceEpoch ~/ 1000,
        },
      );
      when(
        () => groupRepository.updateInviteCode('group-1', '654321', any()),
      ).thenAnswer((_) async {});

      final result = await useCase.execute(groupId: 'group-1');

      expect(
        result,
        isA<ManageGroupInviteSuccess>()
            .having((value) => value.inviteCode, 'inviteCode', '654321')
            .having(
              (value) => value.expiresAt,
              'expiresAt',
              expiresAt.toLocal(),
            )
            .having((value) => value.wasRegenerated, 'wasRegenerated', true),
      );
      final persistedExpiry =
          verify(
                () => groupRepository.updateInviteCode(
                  'group-1',
                  '654321',
                  captureAny(),
                ),
              ).captured.single
              as DateTime;
      expect(persistedExpiry, expiresAt.toLocal());
    },
  );

  test('explicit refresh rotates an otherwise valid invite', () async {
    final expiresAt = now.add(const Duration(hours: 24));
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => group());
    when(() => apiClient.regenerateInvite('group-1')).thenAnswer(
      (_) async => {
        'inviteCode': '999888',
        'expiresAt': expiresAt.millisecondsSinceEpoch ~/ 1000,
      },
    );
    when(
      () => groupRepository.updateInviteCode('group-1', '999888', any()),
    ).thenAnswer((_) async {});

    final result = await useCase.execute(
      groupId: 'group-1',
      forceRefresh: true,
    );

    expect(
      result,
      isA<ManageGroupInviteSuccess>().having(
        (value) => value.inviteCode,
        'inviteCode',
        '999888',
      ),
    );
    verify(() => apiClient.regenerateInvite('group-1')).called(1);
  });

  test('pending owner can regenerate the invite shown during setup', () async {
    final expiresAt = now.add(const Duration(minutes: 10));
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => group(status: GroupStatus.pending));
    when(() => apiClient.regenerateInvite('group-1')).thenAnswer(
      (_) async => {
        'inviteCode': '654321',
        'expiresAt': expiresAt.millisecondsSinceEpoch ~/ 1000,
      },
    );
    when(
      () => groupRepository.updateInviteCode('group-1', '654321', any()),
    ).thenAnswer((_) async {});

    final result = await useCase.execute(
      groupId: 'group-1',
      forceRefresh: true,
    );

    expect(
      result,
      isA<ManageGroupInviteSuccess>()
          .having((value) => value.inviteCode, 'inviteCode', '654321')
          .having((value) => value.expiresAt, 'expiresAt', expiresAt.toLocal()),
    );
    verify(() => apiClient.regenerateInvite('group-1')).called(1);
  });

  test('rejects non-owner access before calling the API', () async {
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => group(role: 'member'));

    final result = await useCase.execute(groupId: 'group-1');

    expect(result, isA<ManageGroupInviteForbidden>());
    verifyNever(() => apiClient.regenerateInvite(any()));
  });

  test('does not regenerate an invite for an inactive group', () async {
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => group(status: GroupStatus.inactive));

    final result = await useCase.execute(groupId: 'group-1');

    expect(
      result,
      isA<ManageGroupInviteError>().having(
        (value) => value.message,
        'message',
        'Group is not active',
      ),
    );
    verifyNever(() => apiClient.regenerateInvite(any()));
  });

  test('does not update local invite when the API fails', () async {
    when(() => groupRepository.getGroupById('group-1')).thenAnswer(
      (_) async =>
          group(inviteExpiresAt: now.subtract(const Duration(minutes: 1))),
    );
    when(() => apiClient.regenerateInvite('group-1')).thenThrow(
      const RelayApiException(statusCode: 500, message: 'server unavailable'),
    );

    final result = await useCase.execute(groupId: 'group-1');

    expect(
      result,
      isA<ManageGroupInviteError>().having(
        (value) => value.message,
        'message',
        'server unavailable',
      ),
    );
    verifyNever(() => groupRepository.updateInviteCode(any(), any(), any()));
  });

  test(
    'rejects malformed successful API responses without local update',
    () async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => group(inviteCode: null));
      when(
        () => apiClient.regenerateInvite('group-1'),
      ).thenAnswer((_) async => {'inviteCode': '', 'expiresAt': 0});

      final result = await useCase.execute(groupId: 'group-1');

      expect(result, isA<ManageGroupInviteError>());
      verifyNever(() => groupRepository.updateInviteCode(any(), any(), any()));
    },
  );
}
