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
    String? inviteCode,
    DateTime? inviteExpiresAt,
    required String role,
    String? groupKey,
    required List<GroupMember> members,
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  }) = _GroupInfo;

  factory GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);
}
