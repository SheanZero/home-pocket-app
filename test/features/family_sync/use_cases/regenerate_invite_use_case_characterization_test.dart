// Characterization test: locks RegenerateInviteUseCase behavior pre-Plan-03-03 move.
//
// Per Phase 3 D-15 (CONTEXT.md): tests written BEFORE refactor lands.
// Plan 03-03 Task 4 will move the production file from
//   lib/features/family_sync/use_cases/regenerate_invite_use_case.dart
// to
//   lib/application/family_sync/regenerate_invite_use_case.dart
// and this test's import line gets rewritten as part of that PR.
//
// The test asserts the CURRENT observable behavior. Post-move it must
// still pass — proving the move was a pure refactor (PROJECT.md
// behavior preservation).

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/use_cases/regenerate_invite_use_case.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _FakeRelayApiClient extends Mock implements RelayApiClient {}

class _FakeGroupRepository extends Mock implements GroupRepository {}

void main() {
  group('RegenerateInviteUseCase characterization', () {
    late _FakeRelayApiClient fakeApiClient;
    late _FakeGroupRepository fakeGroupRepository;
    late RegenerateInviteUseCase useCase;

    setUp(() {
      fakeApiClient = _FakeRelayApiClient();
      fakeGroupRepository = _FakeGroupRepository();

      // Default stubs
      when(
        () => fakeGroupRepository.updateInviteCode(any(), any(), any()),
      ).thenAnswer((_) async {});

      useCase = RegenerateInviteUseCase(
        apiClient: fakeApiClient,
        groupRepository: fakeGroupRepository,
      );
    });

    test('returns success with inviteCode and expiresAt on happy path', () async {
      when(
        () => fakeApiClient.regenerateInvite('group-1'),
      ).thenAnswer(
        (_) async => {'inviteCode': 'ABC123', 'expiresAt': 1700000000},
      );

      final result = await useCase.execute('group-1');

      expect(result, isA<RegenerateInviteSuccess>());
      final success = result as RegenerateInviteSuccess;
      expect(success.inviteCode, equals('ABC123'));
      expect(success.expiresAt, equals(1700000000));
    });

    test('calls updateInviteCode on repository with correct parsed values', () async {
      const expiresAtSeconds = 1700000000;
      when(
        () => fakeApiClient.regenerateInvite('group-2'),
      ).thenAnswer(
        (_) async => {'inviteCode': 'XYZ789', 'expiresAt': expiresAtSeconds},
      );

      await useCase.execute('group-2');

      verify(
        () => fakeGroupRepository.updateInviteCode(
          'group-2',
          'XYZ789',
          DateTime.fromMillisecondsSinceEpoch(expiresAtSeconds * 1000),
        ),
      ).called(1);
    });

    test('returns error when RelayApiException is thrown by apiClient', () async {
      when(
        () => fakeApiClient.regenerateInvite(any()),
      ).thenThrow(
        const RelayApiException(statusCode: 404, message: 'group not found'),
      );

      final result = await useCase.execute('group-1');

      expect(result, isA<RegenerateInviteError>());
      final error = result as RegenerateInviteError;
      expect(error.message, equals('group not found'));
    });

    test('returns error with prefixed message when generic exception is thrown', () async {
      when(
        () => fakeApiClient.regenerateInvite(any()),
      ).thenThrow(StateError('network failure'));

      final result = await useCase.execute('group-1');

      expect(result, isA<RegenerateInviteError>());
      final error = result as RegenerateInviteError;
      expect(error.message, contains('Failed to regenerate invite'));
    });

    test('returns error when repository.updateInviteCode throws', () async {
      when(
        () => fakeApiClient.regenerateInvite(any()),
      ).thenAnswer(
        (_) async => {'inviteCode': 'NEWCODE', 'expiresAt': 1700000000},
      );
      when(
        () => fakeGroupRepository.updateInviteCode(any(), any(), any()),
      ).thenThrow(Exception('db write failed'));

      final result = await useCase.execute('group-1');

      expect(result, isA<RegenerateInviteError>());
    });
  });
}
