import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockE2EEService extends Mock implements E2EEService {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late MockUserProfileRepository userProfileRepository;
  late MockE2EEService e2eeService;
  late SyncAvatarUseCase useCase;
  late Directory tempDir;

  setUp(() async {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    userProfileRepository = MockUserProfileRepository();
    e2eeService = MockE2EEService();
    useCase = SyncAvatarUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
      userProfileRepository: userProfileRepository,
      e2eeService: e2eeService,
    );
    tempDir = await Directory.systemTemp.createTemp('sync_avatar_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('pushAvatarToMembers', () {
    test('reads profile, encrypts payload, and pushes via sync', () async {
      final avatarBytes = utf8.encode('fake-avatar-image-data');
      final avatarFile = File('${tempDir.path}/test_avatar.jpg');
      await avatarFile.writeAsBytes(avatarBytes);

      when(() => userProfileRepository.find()).thenAnswer(
        (_) async => UserProfile(
          id: 'user-1',
          displayName: 'Papa',
          avatarEmoji: '\u{1F468}',
          avatarImagePath: avatarFile.path,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      when(() => groupRepository.getGroupById(any())).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-1',
          groupName: 'Test Family',
          status: GroupStatus.active,
          role: 'owner',
          groupKey: 'group-key-base64',
          members: const [],
          createdAt: DateTime(2026),
        ),
      );
      when(
        () => e2eeService.encryptForGroup(
          plaintext: any(named: 'plaintext'),
          groupKeyBase64: any(named: 'groupKeyBase64'),
        ),
      ).thenReturn('encrypted-payload');
      when(
        () => apiClient.pushSync(
          groupId: any(named: 'groupId'),
          payload: any(named: 'payload'),
          vectorClock: any(named: 'vectorClock'),
          operationCount: any(named: 'operationCount'),
        ),
      ).thenAnswer((_) async => {'recipientCount': 1});

      await useCase.pushAvatarToMembers(groupId: 'group-1');

      verify(
        () => e2eeService.encryptForGroup(
          plaintext: any(named: 'plaintext'),
          groupKeyBase64: 'group-key-base64',
        ),
      ).called(1);
      verify(
        () => apiClient.pushSync(
          groupId: 'group-1',
          payload: 'encrypted-payload',
          vectorClock: const {},
          operationCount: 0,
        ),
      ).called(1);
    });

    test('does nothing when profile has no avatar image', () async {
      when(() => userProfileRepository.find()).thenAnswer(
        (_) async => UserProfile(
          id: 'user-1',
          displayName: 'Papa',
          avatarEmoji: '\u{1F468}',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );

      await useCase.pushAvatarToMembers(groupId: 'group-1');

      verifyNever(
        () => apiClient.pushSync(
          groupId: any(named: 'groupId'),
          payload: any(named: 'payload'),
          vectorClock: any(named: 'vectorClock'),
          operationCount: any(named: 'operationCount'),
        ),
      );
    });

    test('does nothing when profile is not found', () async {
      when(() => userProfileRepository.find()).thenAnswer((_) async => null);

      await useCase.pushAvatarToMembers(groupId: 'group-1');

      verifyNever(
        () => apiClient.pushSync(
          groupId: any(named: 'groupId'),
          payload: any(named: 'payload'),
          vectorClock: any(named: 'vectorClock'),
          operationCount: any(named: 'operationCount'),
        ),
      );
    });

    test('does nothing when group has no group key', () async {
      final avatarFile = File('${tempDir.path}/test_avatar.jpg');
      await avatarFile.writeAsBytes(utf8.encode('fake-data'));

      when(() => userProfileRepository.find()).thenAnswer(
        (_) async => UserProfile(
          id: 'user-1',
          displayName: 'Papa',
          avatarEmoji: '\u{1F468}',
          avatarImagePath: avatarFile.path,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
      when(() => groupRepository.getGroupById(any())).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-1',
          groupName: 'Test Family',
          status: GroupStatus.active,
          role: 'owner',
          groupKey: null,
          members: const [],
          createdAt: DateTime(2026),
        ),
      );

      await useCase.pushAvatarToMembers(groupId: 'group-1');

      verifyNever(
        () => e2eeService.encryptForGroup(
          plaintext: any(named: 'plaintext'),
          groupKeyBase64: any(named: 'groupKeyBase64'),
        ),
      );
    });
  });

  group('handleAvatarSync', () {
    test('verifies SHA-256, saves file, and updates member profile', () async {
      final avatarBytes = utf8.encode('avatar-image-bytes');
      final expectedHash = hash_lib.sha256.convert(avatarBytes).toString();
      final avatarBase64 = base64Encode(avatarBytes);

      when(
        () => groupRepository.updateMemberProfile(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          displayName: any(named: 'displayName'),
          avatarEmoji: any(named: 'avatarEmoji'),
          avatarImagePath: any(named: 'avatarImagePath'),
          avatarImageHash: any(named: 'avatarImageHash'),
        ),
      ).thenAnswer((_) async {});

      await useCase.handleAvatarSync(
        groupId: 'group-1',
        senderDeviceId: 'sender-device',
        payload: {
          'displayName': 'Papa',
          'avatarEmoji': '\u{1F468}',
          'avatarImageBase64': avatarBase64,
          'avatarImageHash': expectedHash,
        },
        appDirectory: tempDir.path,
      );

      final savedFile = File('${tempDir.path}/avatars/sender-device.jpg');
      expect(savedFile.existsSync(), isTrue);
      expect(savedFile.readAsBytesSync(), avatarBytes);

      verify(
        () => groupRepository.updateMemberProfile(
          groupId: 'group-1',
          deviceId: 'sender-device',
          displayName: 'Papa',
          avatarEmoji: '\u{1F468}',
          avatarImagePath: savedFile.path,
          avatarImageHash: expectedHash,
        ),
      ).called(1);
    });

    test('throws when SHA-256 does not match', () async {
      final avatarBase64 = base64Encode(utf8.encode('avatar-data'));

      expect(
        () => useCase.handleAvatarSync(
          groupId: 'group-1',
          senderDeviceId: 'sender-device',
          payload: {
            'displayName': 'Papa',
            'avatarEmoji': '\u{1F468}',
            'avatarImageBase64': avatarBase64,
            'avatarImageHash': 'wrong-hash',
          },
          appDirectory: tempDir.path,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'updates profile without image when avatarImageBase64 is absent',
      () async {
        when(
          () => groupRepository.updateMemberProfile(
            groupId: any(named: 'groupId'),
            deviceId: any(named: 'deviceId'),
            displayName: any(named: 'displayName'),
            avatarEmoji: any(named: 'avatarEmoji'),
            avatarImagePath: any(named: 'avatarImagePath'),
            avatarImageHash: any(named: 'avatarImageHash'),
          ),
        ).thenAnswer((_) async {});

        await useCase.handleAvatarSync(
          groupId: 'group-1',
          senderDeviceId: 'sender-device',
          payload: {'displayName': 'Papa', 'avatarEmoji': '\u{1F468}'},
          appDirectory: tempDir.path,
        );

        verify(
          () => groupRepository.updateMemberProfile(
            groupId: 'group-1',
            deviceId: 'sender-device',
            displayName: 'Papa',
            avatarEmoji: '\u{1F468}',
            avatarImagePath: null,
            avatarImageHash: null,
          ),
        ).called(1);
      },
    );
  });
}
