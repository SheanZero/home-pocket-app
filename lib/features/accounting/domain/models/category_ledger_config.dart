import 'package:freezed_annotation/freezed_annotation.dart';

import 'transaction.dart';

part 'category_ledger_config.freezed.dart';
part 'category_ledger_config.g.dart';

/// Personal ledger type configuration for a category.
///
/// - For L1 categories: mandatory (every L1 must have a config).
/// - For L2 categories: optional override (inherits parent L1 if absent).
///
/// This data is personal and NOT synced across family members.
@freezed
abstract class CategoryLedgerConfig with _$CategoryLedgerConfig {
  const factory CategoryLedgerConfig({
    required String categoryId,
    required LedgerType ledgerType,
    required DateTime updatedAt,
  }) = _CategoryLedgerConfig;

  factory CategoryLedgerConfig.fromJson(Map<String, dynamic> json) =>
      _$CategoryLedgerConfigFromJson(json);
}
