import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_member.dart';

part 'group_info.freezed.dart';
part 'group_info.g.dart';

enum GroupStatus { pending, confirming, active, inactive }

@freezed
abstract class GroupInfo with _$GroupInfo {
  const factory GroupInfo({
    required String groupId,
    required GroupStatus status,
    required String groupName,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    required String role,
    String? groupKey,
    @Default(1) int keyEpoch,
    required List<GroupMember> members,
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
    @Default(0) int controlRevision,
    DateTime? controlUpdatedAt,
    @Default('') String controlSnapshotDigest,
  }) = _GroupInfo;

  factory GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);
}
