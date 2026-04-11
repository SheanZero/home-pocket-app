import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/rename_group_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late RenameGroupUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    useCase = RenameGroupUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
    );
  });

  test('renames group on server then updates local DB', () async {
    when(
      () => apiClient.renameGroup(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => groupRepository.updateGroupName(any(), any()),
    ).thenAnswer((_) async {});

    final result = await useCase.execute(
      groupId: 'group-1',
      groupName: 'New Family Name',
    );

    expect(result, isA<RenameGroupSuccess>());
    expect((result as RenameGroupSuccess).groupName, 'New Family Name');
    verify(
      () => apiClient.renameGroup(
        groupId: 'group-1',
        groupName: 'New Family Name',
      ),
    ).called(1);
    verify(
      () => groupRepository.updateGroupName('group-1', 'New Family Name'),
    ).called(1);
  });

  test('trims whitespace from group name', () async {
    when(
      () => apiClient.renameGroup(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => groupRepository.updateGroupName(any(), any()),
    ).thenAnswer((_) async {});

    final result = await useCase.execute(
      groupId: 'group-1',
      groupName: '  Trimmed Name  ',
    );

    expect(result, isA<RenameGroupSuccess>());
    expect((result as RenameGroupSuccess).groupName, 'Trimmed Name');
    verify(
      () =>
          apiClient.renameGroup(groupId: 'group-1', groupName: 'Trimmed Name'),
    ).called(1);
  });

  test('returns error for empty name', () async {
    final result = await useCase.execute(groupId: 'group-1', groupName: '');

    expect(result, isA<RenameGroupError>());
    expect((result as RenameGroupError).message, 'Group name cannot be empty');
    verifyNever(
      () => apiClient.renameGroup(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
      ),
    );
  });

  test('returns error for whitespace-only name', () async {
    final result = await useCase.execute(groupId: 'group-1', groupName: '   ');

    expect(result, isA<RenameGroupError>());
    expect((result as RenameGroupError).message, 'Group name cannot be empty');
  });

  test('returns error for name exceeding 50 characters', () async {
    final longName = 'A' * 51;

    final result = await useCase.execute(
      groupId: 'group-1',
      groupName: longName,
    );

    expect(result, isA<RenameGroupError>());
    expect(
      (result as RenameGroupError).message,
      'Group name cannot exceed 50 characters',
    );
  });

  test('does not update local DB when server call fails', () async {
    when(
      () => apiClient.renameGroup(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
      ),
    ).thenThrow(
      const RelayApiException(
        statusCode: 403,
        message: 'Only owner can rename',
      ),
    );

    final result = await useCase.execute(
      groupId: 'group-1',
      groupName: 'New Name',
    );

    expect(result, isA<RenameGroupError>());
    expect((result as RenameGroupError).message, 'Only owner can rename');
    verifyNever(() => groupRepository.updateGroupName(any(), any()));
  });

  test('returns error on unexpected exception', () async {
    when(
      () => apiClient.renameGroup(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
      ),
    ).thenThrow(Exception('Network error'));

    final result = await useCase.execute(
      groupId: 'group-1',
      groupName: 'New Name',
    );

    expect(result, isA<RenameGroupError>());
    expect(
      (result as RenameGroupError).message,
      contains('Failed to rename group'),
    );
  });
}
