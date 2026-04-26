import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/use_cases/regenerate_invite_use_case.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late RegenerateInviteUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    useCase = RegenerateInviteUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
    );
    when(
      () => groupRepository.updateInviteCode(any(), any(), any()),
    ).thenAnswer((_) async {});
  });

  test('updates the local invite after regeneration', () async {
    when(
      () => apiClient.regenerateInvite('group-1'),
    ).thenAnswer((_) async => {'inviteCode': 'NEW123', 'expiresAt': 10});

    final result = await useCase.execute('group-1');

    expect(result, isA<RegenerateInviteSuccess>());
    verify(
      () => groupRepository.updateInviteCode(
        'group-1',
        'NEW123',
        DateTime.fromMillisecondsSinceEpoch(10000),
      ),
    ).called(1);
  });
}
