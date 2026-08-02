import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../features/family_sync/domain/models/group_member.dart';

String controlSnapshotDigest({
  required String groupId,
  required String groupName,
  required String role,
  required int keyEpoch,
  required List<GroupMember> members,
}) {
  final orderedMembers = [...members]
    ..sort((left, right) => left.deviceId.compareTo(right.deviceId));
  final canonical = jsonEncode({
    'groupId': groupId,
    'groupName': groupName,
    'role': role,
    'keyEpoch': keyEpoch,
    'members': orderedMembers
        .map(
          (member) => {
            'deviceId': member.deviceId,
            'publicKey': member.publicKey,
            'deviceName': member.deviceName,
            'role': member.role,
            'status': member.status,
            'displayName': member.displayName,
            'avatarEmoji': member.avatarEmoji,
            'avatarImageHash': member.avatarImageHash,
            'joinedAt': member.joinedAt?.toUtc().toIso8601String(),
            'confirmedAt': member.confirmedAt?.toUtc().toIso8601String(),
            'removedAt': member.removedAt?.toUtc().toIso8601String(),
            'removalReason': member.removalReason,
          },
        )
        .toList(),
  });
  return sha256.convert(utf8.encode(canonical)).toString();
}
