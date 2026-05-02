import 'package:freezed_annotation/freezed_annotation.dart';

part 'best_joy_moment_row.freezed.dart';

/// Single transaction row for HAPPY-04 Top Joy story card.
/// Deliberately omits encrypted free-text content (ARCH-002).
@freezed
abstract class BestJoyMomentRow with _$BestJoyMomentRow {
  const factory BestJoyMomentRow({
    required String transactionId,
    required int amount,
    required int soulSatisfaction,
    required String categoryId,
    required DateTime timestamp,
  }) = _BestJoyMomentRow;
}
