import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/member_content_version.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  late AppDatabase database;
  late GroupRepositoryImpl groupRepository;
  late _MockPushSyncUseCase pushSync;
  late _MockUserProfileRepository profileRepository;
  late _MockKeyManager keyManager;
  late SyncAvatarUseCase useCase;
  late Directory tempDirectory;

  const sender = GroupMember(
    deviceId: 'sender-device',
    publicKey: 'pk',
    deviceName: 'Phone',
    role: 'owner',
    status: 'active',
    displayName: 'Papa',
    avatarEmoji: '👨',
  );

  setUp(() async {
    database = AppDatabase.forTesting();
    groupRepository = GroupRepositoryImpl(
      groupDao: GroupDao(database),
      memberDao: GroupMemberDao(database),
    );
    await groupRepository.restoreActiveGroup(
      groupId: 'group-1',
      role: 'owner',
      groupKey: 'group-key',
      keyEpoch: 3,
      members: const [sender],
    );
    pushSync = _MockPushSyncUseCase();
    profileRepository = _MockUserProfileRepository();
    keyManager = _MockKeyManager();
    useCase = SyncAvatarUseCase(
      pushSync: pushSync,
      groupRepository: groupRepository,
      userProfileRepository: profileRepository,
      keyManager: keyManager,
    );
    tempDirectory = await Directory.systemTemp.createTemp('avatar_versioning_');
  });

  tearDown(() async {
    await database.close();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Map<String, dynamic> avatarPayload({required int revision}) {
    final bytes = <int>[0xff, 0xd8, 0xff, 7, 8, 9, 0xff, 0xd9];
    final digest = hash_lib.sha256.convert(bytes).toString();
    return {
      'schemaVersion': 1,
      'ownerDeviceId': 'sender-device',
      'revision': revision,
      'avatarContentHash': digest,
      'displayName': 'Papa',
      'avatarEmoji': '👨',
      'removed': false,
      'mimeType': 'image/jpeg',
      'byteLength': bytes.length,
      'sha256': digest,
      'bytesBase64': base64Encode(bytes),
    };
  }

  test(
    'stale avatar returns before validating or touching the filesystem',
    () async {
      await groupRepository.applyMemberAvatarVersioned(
        groupId: 'group-1',
        deviceId: 'sender-device',
        avatarImagePath: '/existing/avatar.jpg',
        avatarImageHash: 'newer-hash',
        version: const MemberContentVersion(
          revision: 100,
          originDeviceId: 'sender-device',
          contentDigest: 'newer-hash',
        ),
      );
      final stale = avatarPayload(revision: 99)
        ..['mimeType'] = 'invalid/type'
        ..['bytesBase64'] = 'not-base64';

      await useCase.handleAvatarSync(
        groupId: 'group-1',
        senderDeviceId: 'sender-device',
        messageKeyEpoch: 3,
        payload: stale,
        appDirectory: tempDirectory.path,
      );

      expect(Directory('${tempDirectory.path}/avatars').existsSync(), isFalse);
      final member = (await groupRepository.getActiveGroup())!.members.single;
      expect(member.avatarRevision, 100);
      expect(member.avatarImagePath, '/existing/avatar.jpg');
    },
  );

  test(
    'failed file write does not advance the persisted avatar version',
    () async {
      final notADirectory = File('${tempDirectory.path}/not-a-directory');
      await notADirectory.writeAsString('occupied');

      await expectLater(
        useCase.handleAvatarSync(
          groupId: 'group-1',
          senderDeviceId: 'sender-device',
          messageKeyEpoch: 3,
          payload: avatarPayload(revision: 42),
          appDirectory: notADirectory.path,
        ),
        throwsA(isA<FileSystemException>()),
      );

      final member = (await groupRepository.getActiveGroup())!.members.single;
      expect(member.avatarRevision, 0);
      expect(member.avatarContentHash, isEmpty);
      expect(member.avatarImagePath, isNull);
    },
  );

  test('new avatar applies once and duplicate delivery is a no-op', () async {
    final payload = avatarPayload(revision: 42);
    await useCase.handleAvatarSync(
      groupId: 'group-1',
      senderDeviceId: 'sender-device',
      messageKeyEpoch: 3,
      payload: payload,
      appDirectory: tempDirectory.path,
    );
    final first = (await groupRepository.getActiveGroup())!.members.single;
    final firstModified = await File(first.avatarImagePath!).lastModified();

    await Future<void>.delayed(const Duration(milliseconds: 2));
    await useCase.handleAvatarSync(
      groupId: 'group-1',
      senderDeviceId: 'sender-device',
      messageKeyEpoch: 3,
      payload: payload,
      appDirectory: tempDirectory.path,
    );

    final duplicate = (await groupRepository.getActiveGroup())!.members.single;
    expect(duplicate.avatarRevision, 42);
    expect(duplicate.avatarContentHash, payload['sha256']);
    expect(
      await File(duplicate.avatarImagePath!).lastModified(),
      firstModified,
    );
  });

  test(
    'unchanged outbound avatar reuses persisted revision and operation id',
    () async {
      final bytes = <int>[0xff, 0xd8, 0xff, 1, 2, 3, 0xff, 0xd9];
      final avatar = File('${tempDirectory.path}/source.jpg');
      await avatar.writeAsBytes(bytes);
      var currentAvatarPath = avatar.path;
      when(() => profileRepository.find()).thenAnswer(
        (_) async => UserProfile(
          id: 'profile-1',
          displayName: 'Papa',
          avatarEmoji: '👨',
          avatarImagePath: currentAvatarPath,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
      );
      when(
        () => keyManager.getDeviceId(),
      ).thenAnswer((_) async => 'sender-device');
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: const {},
        ),
      ).thenAnswer((_) async => const PushSyncResult.success(1));

      await useCase.pushAvatarToMembers(groupId: 'group-1');
      final relocatedAvatar = File('${tempDirectory.path}/relocated.jpg');
      await relocatedAvatar.writeAsBytes(bytes);
      currentAvatarPath = relocatedAvatar.path;
      await useCase.pushAvatarToMembers(groupId: 'group-1');

      final captured = verify(
        () => pushSync.execute(
          operations: captureAny(named: 'operations'),
          vectorClock: const {},
        ),
      ).captured;
      final first = (captured[0] as List<Map<String, dynamic>>).single;
      final second = (captured[1] as List<Map<String, dynamic>>).single;
      expect(second['revision'], first['revision']);
      expect(second['operationId'], first['operationId']);
      final persisted =
          (await groupRepository.getActiveGroup())!.members.single;
      expect(persisted.avatarRevision, first['revision']);
      expect(persisted.avatarContentHash, first['data']['sha256']);
      expect(persisted.avatarImagePath, relocatedAvatar.path);
    },
  );
}
