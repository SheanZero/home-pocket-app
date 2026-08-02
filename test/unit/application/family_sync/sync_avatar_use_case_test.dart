import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late MockPushSyncUseCase pushSync;
  late MockGroupRepository groupRepository;
  late MockUserProfileRepository userProfileRepository;
  late MockKeyManager keyManager;
  late SyncAvatarUseCase useCase;
  late Directory tempDir;

  const sender = GroupMember(
    deviceId: 'sender-device',
    publicKey: 'sender-public-key',
    deviceName: 'Sender phone',
    role: 'member',
    status: 'active',
    displayName: 'Papa',
    avatarEmoji: '👨',
  );

  GroupInfo activeGroup({int keyEpoch = 3}) => GroupInfo(
    groupId: 'group-1',
    groupName: 'Test Family',
    status: GroupStatus.active,
    role: 'member',
    groupKey: 'group-key-base64',
    keyEpoch: keyEpoch,
    members: const [sender],
    createdAt: DateTime(2026),
  );

  setUp(() async {
    pushSync = MockPushSyncUseCase();
    groupRepository = MockGroupRepository();
    userProfileRepository = MockUserProfileRepository();
    keyManager = MockKeyManager();
    useCase = SyncAvatarUseCase(
      pushSync: pushSync,
      groupRepository: groupRepository,
      userProfileRepository: userProfileRepository,
      keyManager: keyManager,
    );
    tempDir = await Directory.systemTemp.createTemp('sync_avatar_test_');

    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => activeGroup());
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('pushAvatarToMembers', () {
    test(
      'pushes one versioned avatar operation through retryable sync',
      () async {
        final avatarBytes = <int>[0xff, 0xd8, 0xff, 1, 2, 3, 0xff, 0xd9];
        final avatarFile = File('${tempDir.path}/test_avatar.jpg');
        await avatarFile.writeAsBytes(avatarBytes);
        final updatedAt = DateTime.utc(2026, 8, 1, 12);

        when(() => userProfileRepository.find()).thenAnswer(
          (_) async => UserProfile(
            id: 'user-1',
            displayName: 'Papa',
            avatarEmoji: '👨',
            avatarImagePath: avatarFile.path,
            createdAt: DateTime(2026),
            updatedAt: updatedAt,
          ),
        );
        when(
          () => keyManager.getDeviceId(),
        ).thenAnswer((_) async => 'device-1');
        when(
          () => pushSync.execute(
            operations: any(named: 'operations'),
            vectorClock: any(named: 'vectorClock'),
          ),
        ).thenAnswer((_) async => const PushSyncResult.queued(1));

        final result = await useCase.pushAvatarToMembers(groupId: 'group-1');

        expect(result, isA<PushSyncQueued>());
        final captured =
            verify(
                  () => pushSync.execute(
                    operations: captureAny(named: 'operations'),
                    vectorClock: const {},
                  ),
                ).captured.single
                as List<Map<String, dynamic>>;
        final operation = captured.single;
        final data = operation['data'] as Map<String, dynamic>;
        final expectedHash = hash_lib.sha256.convert(avatarBytes).toString();

        expect(operation['entityType'], 'avatar');
        expect(operation['entityId'], 'device-1');
        expect(operation['fromDeviceId'], 'device-1');
        expect(operation['revision'], updatedAt.microsecondsSinceEpoch);
        expect(
          operation['operationId'],
          'avatar:device-1:${updatedAt.microsecondsSinceEpoch}:$expectedHash',
        );
        expect(data['schemaVersion'], 1);
        expect(data['ownerDeviceId'], 'device-1');
        expect(data['mimeType'], 'image/jpeg');
        expect(data['byteLength'], avatarBytes.length);
        expect(data['sha256'], expectedHash);
        expect(base64Decode(data['bytesBase64'] as String), avatarBytes);
      },
    );

    test(
      'pushes a deterministic removal operation when photo is cleared',
      () async {
        final updatedAt = DateTime.utc(2026, 8, 1, 13);
        when(() => userProfileRepository.find()).thenAnswer(
          (_) async => UserProfile(
            id: 'user-1',
            displayName: 'Papa',
            avatarEmoji: '👨',
            createdAt: DateTime(2026),
            updatedAt: updatedAt,
          ),
        );
        when(
          () => keyManager.getDeviceId(),
        ).thenAnswer((_) async => 'device-1');
        when(
          () => pushSync.execute(
            operations: any(named: 'operations'),
            vectorClock: any(named: 'vectorClock'),
          ),
        ).thenAnswer((_) async => const PushSyncResult.success(1));

        await useCase.pushAvatarToMembers(groupId: 'group-1');

        final operations =
            verify(
                  () => pushSync.execute(
                    operations: captureAny(named: 'operations'),
                    vectorClock: const {},
                  ),
                ).captured.single
                as List<Map<String, dynamic>>;
        expect(operations.single['operationId'], contains(':removed'));
        expect(
          (operations.single['data'] as Map<String, dynamic>)['removed'],
          isTrue,
        );
      },
    );

    test('does not upload without an active keyed group', () async {
      when(() => userProfileRepository.find()).thenAnswer((_) async => null);
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => null);

      final result = await useCase.pushAvatarToMembers(groupId: 'group-1');

      expect(result, isNull);
      verifyNever(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
        ),
      );
    });
  });

  group('handleAvatarSync', () {
    late List<int> avatarBytes;
    late String expectedHash;
    late Map<String, dynamic> payload;

    setUp(() {
      avatarBytes = <int>[0xff, 0xd8, 0xff, 7, 8, 9, 0xff, 0xd9];
      expectedHash = hash_lib.sha256.convert(avatarBytes).toString();
      payload = {
        'schemaVersion': 1,
        'ownerDeviceId': 'sender-device',
        'revision': 42,
        'displayName': 'Papa',
        'avatarEmoji': '\u{1F468}',
        'mimeType': 'image/jpeg',
        'byteLength': avatarBytes.length,
        'sha256': expectedHash,
        'bytesBase64': base64Encode(avatarBytes),
      };
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
    });

    test('validates, atomically saves, and repeats idempotently', () async {
      await useCase.handleAvatarSync(
        groupId: 'group-1',
        senderDeviceId: 'sender-device',
        messageKeyEpoch: 3,
        payload: payload,
        appDirectory: tempDir.path,
      );
      await useCase.handleAvatarSync(
        groupId: 'group-1',
        senderDeviceId: 'sender-device',
        messageKeyEpoch: 3,
        payload: payload,
        appDirectory: tempDir.path,
      );

      final avatarFiles = Directory(
        '${tempDir.path}/avatars',
      ).listSync().whereType<File>().toList();
      expect(avatarFiles, hasLength(1));
      expect(avatarFiles.single.path, endsWith('.jpg'));
      expect(await avatarFiles.single.readAsBytes(), avatarBytes);
      expect(avatarFiles.where((file) => file.path.endsWith('.tmp')), isEmpty);
      verify(
        () => groupRepository.updateMemberProfile(
          groupId: 'group-1',
          deviceId: 'sender-device',
          displayName: 'Papa',
          avatarEmoji: '👨',
          avatarImagePath: avatarFiles.single.path,
          avatarImageHash: expectedHash,
        ),
      ).called(2);
    });

    test('rejects wrong hash before writing or updating the member', () async {
      payload['sha256'] = '0' * 64;

      await expectLater(
        () => useCase.handleAvatarSync(
          groupId: 'group-1',
          senderDeviceId: 'sender-device',
          messageKeyEpoch: 3,
          payload: payload,
          appDirectory: tempDir.path,
        ),
        throwsA(isA<AvatarSyncValidationException>()),
      );

      expect(Directory('${tempDir.path}/avatars').existsSync(), isFalse);
      verifyNever(
        () => groupRepository.updateMemberProfile(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          displayName: any(named: 'displayName'),
          avatarEmoji: any(named: 'avatarEmoji'),
          avatarImagePath: any(named: 'avatarImagePath'),
          avatarImageHash: any(named: 'avatarImageHash'),
        ),
      );
    });

    test(
      'rejects wrong epoch and owner without acknowledging eligibility',
      () async {
        await expectLater(
          () => useCase.handleAvatarSync(
            groupId: 'group-1',
            senderDeviceId: 'sender-device',
            messageKeyEpoch: 2,
            payload: payload,
            appDirectory: tempDir.path,
          ),
          throwsA(isA<AvatarSyncValidationException>()),
        );

        payload['ownerDeviceId'] = '../another-device';
        await expectLater(
          () => useCase.handleAvatarSync(
            groupId: 'group-1',
            senderDeviceId: 'sender-device',
            messageKeyEpoch: 3,
            payload: payload,
            appDirectory: tempDir.path,
          ),
          throwsA(isA<AvatarSyncValidationException>()),
        );

        verifyNever(
          () => groupRepository.updateMemberProfile(
            groupId: any(named: 'groupId'),
            deviceId: any(named: 'deviceId'),
            displayName: any(named: 'displayName'),
            avatarEmoji: any(named: 'avatarEmoji'),
            avatarImagePath: any(named: 'avatarImagePath'),
            avatarImageHash: any(named: 'avatarImageHash'),
          ),
        );
      },
    );
  });

  test(
    'outbound avatar operation round-trips through the receiver contract',
    () async {
      final avatarBytes = <int>[0xff, 0xd8, 0xff, 4, 5, 6, 0xff, 0xd9];
      final source = File('${tempDir.path}/source.jpg');
      await source.writeAsBytes(avatarBytes);
      when(() => userProfileRepository.find()).thenAnswer(
        (_) async => UserProfile(
          id: 'profile-1',
          displayName: 'Papa',
          avatarEmoji: '👨',
          avatarImagePath: source.path,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026, 8, 1, 14),
        ),
      );
      when(
        () => keyManager.getDeviceId(),
      ).thenAnswer((_) async => 'sender-device');
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
        ),
      ).thenAnswer((_) async => const PushSyncResult.success(1));
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

      await useCase.pushAvatarToMembers(groupId: 'group-1');
      final operations =
          verify(
                () => pushSync.execute(
                  operations: captureAny(named: 'operations'),
                  vectorClock: const {},
                ),
              ).captured.single
              as List<Map<String, dynamic>>;
      final operation = operations.single;

      await useCase.handleAvatarSync(
        groupId: 'group-1',
        senderDeviceId: 'sender-device',
        messageKeyEpoch: 3,
        payload: operation['data'] as Map<String, dynamic>,
        appDirectory: tempDir.path,
      );

      final storedPath =
          verify(
                () => groupRepository.updateMemberProfile(
                  groupId: 'group-1',
                  deviceId: 'sender-device',
                  displayName: 'Papa',
                  avatarEmoji: '👨',
                  avatarImagePath: captureAny(named: 'avatarImagePath'),
                  avatarImageHash: any(named: 'avatarImageHash'),
                ),
              ).captured.single
              as String;
      expect(await File(storedPath).readAsBytes(), avatarBytes);
    },
  );
}
