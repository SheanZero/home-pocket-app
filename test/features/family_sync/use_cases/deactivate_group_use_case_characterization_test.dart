// Characterization test: locks DeactivateGroupUseCase behavior pre-Plan-03-03 move.
//
// Per Phase 3 D-15 (CONTEXT.md): tests written BEFORE refactor lands.
// Plan 03-03 Task 2 will move the production file from
//   lib/features/family_sync/use_cases/deactivate_group_use_case.dart
// to
//   lib/application/family_sync/deactivate_group_use_case.dart
// and this test's import line gets rewritten as part of that PR.
//
// The test asserts the CURRENT observable behavior. Post-move it must
// still pass — proving the move was a pure refactor (PROJECT.md
// behavior preservation).

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/use_cases/deactivate_group_use_case.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class _FakeRelayApiClient extends Mock implements RelayApiClient {}

class _FakeGroupRepository extends Mock implements GroupRepository {}

class _FakeSyncQueueManager extends Mock implements SyncQueueManager {}

class _FakeShadowBookService extends Mock implements ShadowBookService {}

void main() {
  group('DeactivateGroupUseCase characterization', () {
    late _FakeRelayApiClient fakeApiClient;
    late _FakeGroupRepository fakeGroupRepository;
    late _FakeSyncQueueManager fakeSyncQueueManager;
    late _FakeShadowBookService fakeShadowBookService;
    late DeactivateGroupUseCase useCase;

    setUp(() {
      fakeApiClient = _FakeRelayApiClient();
      fakeGroupRepository = _FakeGroupRepository();
      fakeSyncQueueManager = _FakeSyncQueueManager();
      fakeShadowBookService = _FakeShadowBookService();

      // Default happy-path stubs
      when(() => fakeApiClient.deactivateGroup(any())).thenAnswer((_) async {});
      when(() => fakeSyncQueueManager.clearQueue()).thenAnswer((_) async {});
      when(
        () => fakeShadowBookService.cleanSyncData(any()),
      ).thenAnswer((_) async {});
      when(
        () => fakeGroupRepository.deactivateGroup(any()),
      ).thenAnswer((_) async {});

      useCase = DeactivateGroupUseCase(
        apiClient: fakeApiClient,
        groupRepository: fakeGroupRepository,
        queueManager: fakeSyncQueueManager,
        shadowBookService: fakeShadowBookService,
      );
    });

    test('returns success when all operations complete', () async {
      final result = await useCase.execute('group-1');

      expect(result, isA<DeactivateGroupSuccess>());
    });

    test('calls apiClient, queueManager, shadowBookService, groupRepository in sequence', () async {
      await useCase.execute('group-1');

      verify(() => fakeApiClient.deactivateGroup('group-1')).called(1);
      verify(() => fakeSyncQueueManager.clearQueue()).called(1);
      verify(() => fakeShadowBookService.cleanSyncData('group-1')).called(1);
      verify(() => fakeGroupRepository.deactivateGroup('group-1')).called(1);
    });

    test('returns error with message when RelayApiException is thrown', () async {
      when(() => fakeApiClient.deactivateGroup(any())).thenThrow(
        const RelayApiException(statusCode: 403, message: 'forbidden'),
      );

      final result = await useCase.execute('group-1');

      expect(result, isA<DeactivateGroupError>());
      final error = result as DeactivateGroupError;
      expect(error.message, equals('forbidden'));
    });

    test('returns error when generic exception is thrown by queueManager', () async {
      when(() => fakeSyncQueueManager.clearQueue()).thenThrow(
        StateError('queue broken'),
      );

      final result = await useCase.execute('group-1');

      expect(result, isA<DeactivateGroupError>());
      final error = result as DeactivateGroupError;
      expect(error.message, contains('queue broken'));
    });

    test('returns error when groupRepository.deactivateGroup throws', () async {
      when(() => fakeGroupRepository.deactivateGroup(any())).thenThrow(
        Exception('db write failed'),
      );

      final result = await useCase.execute('group-1');

      expect(result, isA<DeactivateGroupError>());
    });

    test('works without optional shadowBookService (null)', () async {
      final useCaseWithoutShadow = DeactivateGroupUseCase(
        apiClient: fakeApiClient,
        groupRepository: fakeGroupRepository,
        queueManager: fakeSyncQueueManager,
      );

      final result = await useCaseWithoutShadow.execute('group-1');

      expect(result, isA<DeactivateGroupSuccess>());
      // shadowBookService.cleanSyncData is NOT called when null
      verifyNever(() => fakeShadowBookService.cleanSyncData(any()));
    });
  });
}
