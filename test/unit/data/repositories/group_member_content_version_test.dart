import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/member_content_version.dart';

void main() {
  group('MemberContentVersion', () {
    test('orders revision then origin device then content digest', () {
      const base = MemberContentVersion(
        revision: 10,
        originDeviceId: 'device-a',
        contentDigest: 'digest-a',
      );

      expect(
        const MemberContentVersion(
          revision: 11,
          originDeviceId: 'device-a',
          contentDigest: 'digest-a',
        ).isStrictlyNewerThan(base),
        isTrue,
      );
      expect(
        const MemberContentVersion(
          revision: 10,
          originDeviceId: 'device-b',
          contentDigest: 'digest-a',
        ).isStrictlyNewerThan(base),
        isTrue,
      );
      expect(
        const MemberContentVersion(
          revision: 10,
          originDeviceId: 'device-a',
          contentDigest: 'digest-b',
        ).isStrictlyNewerThan(base),
        isTrue,
      );
      expect(base.isStrictlyNewerThan(base), isFalse);
    });

    test('next revision remains monotonic when wall clock rolls back', () {
      expect(
        MemberContentVersion.nextRevision(
          current: 9000000000000000,
          now: DateTime.utc(2020),
        ),
        9000000000000001,
      );
    });
  });

  group('GroupRepositoryImpl member versions', () {
    late AppDatabase database;
    late GroupRepositoryImpl repository;

    const local = GroupMember(
      deviceId: 'device-a',
      publicKey: 'pk-a',
      deviceName: 'Phone A',
      role: 'owner',
      status: 'active',
      displayName: 'Server Alice',
      avatarEmoji: '🏠',
    );
    const peer = GroupMember(
      deviceId: 'device-b',
      publicKey: 'pk-b',
      deviceName: 'Phone B',
      role: 'member',
      status: 'active',
      displayName: 'Bob',
      avatarEmoji: '🏠',
    );

    setUp(() async {
      database = AppDatabase.forTesting();
      repository = GroupRepositoryImpl(
        groupDao: GroupDao(database),
        memberDao: GroupMemberDao(database),
      );
      await repository.restoreActiveGroup(
        groupId: 'group-1',
        role: 'owner',
        groupKey: 'key',
        members: const [local, peer],
      );
    });

    tearDown(() => database.close());

    test(
      'newer profile wins and older or duplicate delivery is ignored',
      () async {
        const newer = MemberContentVersion(
          revision: 20,
          originDeviceId: 'device-a',
          contentDigest: 'digest-new',
        );
        expect(
          await repository.applyMemberIdentityVersioned(
            groupId: 'group-1',
            deviceId: 'device-a',
            displayName: 'New Alice',
            avatarEmoji: '🌱',
            version: newer,
          ),
          isTrue,
        );
        expect(
          await repository.applyMemberIdentityVersioned(
            groupId: 'group-1',
            deviceId: 'device-a',
            displayName: 'Old Alice',
            avatarEmoji: '🐛',
            version: const MemberContentVersion(
              revision: 19,
              originDeviceId: 'device-z',
              contentDigest: 'digest-old',
            ),
          ),
          isFalse,
        );
        expect(
          await repository.applyMemberIdentityVersioned(
            groupId: 'group-1',
            deviceId: 'device-a',
            displayName: 'Duplicate payload',
            avatarEmoji: '❌',
            version: newer,
          ),
          isFalse,
        );

        final member = (await repository.getActiveGroup())!.members.first;
        expect(member.displayName, 'New Alice');
        expect(member.avatarEmoji, '🌱');
        expect(member.profileRevision, 20);
        expect(member.profileDigest, 'digest-new');
      },
    );

    test(
      'same revision converges deterministically by origin and digest',
      () async {
        for (final version in const [
          MemberContentVersion(
            revision: 30,
            originDeviceId: 'device-a',
            contentDigest: 'digest-a',
          ),
          MemberContentVersion(
            revision: 30,
            originDeviceId: 'device-b',
            contentDigest: 'digest-a',
          ),
          MemberContentVersion(
            revision: 30,
            originDeviceId: 'device-b',
            contentDigest: 'digest-z',
          ),
        ]) {
          expect(
            await repository.applyMemberIdentityVersioned(
              groupId: 'group-1',
              deviceId: 'device-a',
              displayName: version.contentDigest,
              avatarEmoji: '🌱',
              version: version,
            ),
            isTrue,
          );
        }
        final member = (await repository.getActiveGroup())!.members.first;
        expect(member.profileOriginDeviceId, 'device-b');
        expect(member.profileDigest, 'digest-z');
      },
    );

    test(
      'restart and clock rollback allocate persisted revision plus one',
      () async {
        final first = await repository.prepareLocalProfileVersion(
          groupId: 'group-1',
          deviceId: 'device-a',
          displayName: 'First',
          avatarEmoji: '🌱',
          contentDigest: 'digest-1',
          now: DateTime.utc(2030),
        );
        final restarted = GroupRepositoryImpl(
          groupDao: GroupDao(database),
          memberDao: GroupMemberDao(database),
        );
        final second = await restarted.prepareLocalProfileVersion(
          groupId: 'group-1',
          deviceId: 'device-a',
          displayName: 'Second',
          avatarEmoji: '🌳',
          contentDigest: 'digest-2',
          now: DateTime.utc(2020),
        );

        expect(second!.revision, first!.revision + 1);
      },
    );

    test(
      'authoritative refresh preserves local E2EE fields but removes omissions',
      () async {
        await repository.applyMemberIdentityVersioned(
          groupId: 'group-1',
          deviceId: 'device-a',
          displayName: 'E2EE Alice',
          avatarEmoji: '🌱',
          version: const MemberContentVersion(
            revision: 40,
            originDeviceId: 'device-a',
            contentDigest: 'profile-40',
          ),
        );
        await repository.applyMemberAvatarVersioned(
          groupId: 'group-1',
          deviceId: 'device-a',
          avatarImagePath: '/local/avatar.png',
          avatarImageHash: 'avatar-hash',
          version: const MemberContentVersion(
            revision: 50,
            originDeviceId: 'device-a',
            contentDigest: 'avatar-hash',
          ),
        );

        expect(
          await repository.applyAuthoritativeSnapshot(
            groupId: 'group-1',
            groupName: 'Family',
            role: 'owner',
            keyEpoch: 1,
            members: const [local],
          ),
          isTrue,
        );

        final group = await repository.getActiveGroup();
        expect(group!.members, hasLength(1));
        final member = group.members.single;
        expect(member.deviceId, 'device-a');
        expect(member.displayName, 'E2EE Alice');
        expect(member.profileRevision, 40);
        expect(member.avatarImagePath, '/local/avatar.png');
        expect(member.avatarRevision, 50);
        expect(
          group.members.any((candidate) => candidate.deviceId == 'device-b'),
          isFalse,
        );
      },
    );
  });
}
