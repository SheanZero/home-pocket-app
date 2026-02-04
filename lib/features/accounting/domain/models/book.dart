import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
class Book with _$Book {
  const Book._();

  const factory Book({
    required String id,
    required String name,
    required String currency,  // ISO 4217: "CNY", "USD", "JPY"
    required String deviceId,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool isArchived,

    // Statistics (denormalized for performance)
    @Default(0) int transactionCount,
    @Default(0) int survivalBalance,  // Balance in cents
    @Default(0) int soulBalance,      // Balance in cents
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  /// Create new book
  factory Book.create({
    required String name,
    required String currency,
    required String deviceId,
  }) {
    return Book(
      id: const Uuid().v4(),
      name: name,
      currency: currency,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  /// Total balance across both ledgers
  int get totalBalance => survivalBalance + soulBalance;
}
