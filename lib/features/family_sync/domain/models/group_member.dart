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
    @Default(0) int profileRevision,
    @Default('') String profileOriginDeviceId,
    @Default('') String profileDigest,
    @Default(0) int avatarRevision,
    @Default('') String avatarOriginDeviceId,
    @Default('') String avatarContentHash,
    DateTime? joinedAt,
    DateTime? confirmedAt,
    DateTime? removedAt,
    String? removalReason,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
