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

    // Denormalized stats for performance
    @Default(0) int transactionCount,
    @Default(0) int survivalBalance,
    @Default(0) int soulBalance,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
