import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_data.freezed.dart';
part 'backup_data.g.dart';

/// Backup file data structure.
///
/// Uses [Map<String, dynamic>] for transactions/categories/books/shopping items
/// to decouple backup format from current domain models.
@freezed
abstract class BackupData with _$BackupData {
  const factory BackupData({
    required BackupMetadata metadata,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> books,
    required Map<String, dynamic> settings,

    /// Exchange rate cache rows (D-10). Optional with [@Default] for
    /// backward-compat: old `.hpb` files without the field deserialize to `[]`.
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> exchangeRates,

    /// Full shopping-list state, including completion and local sort order.
    /// Optional so backups created before this capability remain importable.
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> shoppingItems,

    /// Personal ledger assignment for custom/system categories. Category rows
    /// already retain custom names, hidden state and sort order; these configs
    /// preserve the remaining category behavior after restore.
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> categoryLedgerConfigs,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);
}

/// Metadata for a backup file.
@freezed
abstract class BackupMetadata with _$BackupMetadata {
  const factory BackupMetadata({
    required String version,
    required int createdAt,
    required String deviceId,
    required String appVersion,
  }) = _BackupMetadata;

  factory BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);
}
