import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
abstract class Book with _$Book {
  const factory Book({
    required String id,
    required String name,
    required String currency,
    required String deviceId,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool isArchived,
    @Default(false) bool isShadow,
    String? groupId,
    String? ownerDeviceId,
    String? ownerDeviceName,

    // Denormalized stats for performance
    @Default(0) int transactionCount,
    @Default(0) int dailyBalance,
    @Default(0) int joyBalance,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
