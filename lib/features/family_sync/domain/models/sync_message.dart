import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_message.freezed.dart';
part 'sync_message.g.dart';

@freezed
abstract class SyncMessage with _$SyncMessage {
  const factory SyncMessage({
    required String messageId,
    required String fromDeviceId,
    required String payload, // encrypted base64
    required Map<String, int> vectorClock,
    required int operationCount,
    required DateTime createdAt,
  }) = _SyncMessage;

  factory SyncMessage.fromJson(Map<String, dynamic> json) =>
      _$SyncMessageFromJson(json);
}
