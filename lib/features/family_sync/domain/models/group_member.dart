import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';
part 'group_member.g.dart';

@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String role,
    required String status,
    required String displayName,
    required String avatarEmoji,
    String? avatarImagePath,
    String? avatarImageHash,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
