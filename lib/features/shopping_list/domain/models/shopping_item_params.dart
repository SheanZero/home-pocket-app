import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../accounting/domain/models/transaction.dart';

part 'shopping_item_params.freezed.dart';

/// Write-params DTO used by use cases to communicate create/update intent
/// to the repository.
///
/// All fields optional except [name] and [listType] (required at creation).
/// No Drift `Value<T>` types — pure domain DTO.
@freezed
abstract class ShoppingItemParams with _$ShoppingItemParams {
  const factory ShoppingItemParams({
    required String name,
    required String listType,
    LedgerType? ledgerType,
    String? categoryId,
    @Default(<String>[]) List<String> tags,
    String? note,
    @Default(1) int quantity,
    int? estimatedPrice,
    String? addedByBookId,
  }) = _ShoppingItemParams;
}
