import 'package:freezed_annotation/freezed_annotation.dart';

part 'paired_device.freezed.dart';
part 'paired_device.g.dart';

enum PairStatus {
  pending,
  confirming,
  active,
  inactive,
}

@freezed
abstract class PairedDevice with _$PairedDevice {
  const factory PairedDevice({
    required String pairId,
    required String bookId,
    String? partnerDeviceId, // null during 'pending' state
    String? partnerPublicKey, // null during 'pending' state
    String? partnerDeviceName, // null during 'pending' state
    required PairStatus status,
    String? pairCode,
    DateTime? expiresAt, // pair code expiry
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  }) = _PairedDevice;

  factory PairedDevice.fromJson(Map<String, dynamic> json) =>
      _$PairedDeviceFromJson(json);
}
