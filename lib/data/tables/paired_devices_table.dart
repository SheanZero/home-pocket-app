import 'package:drift/drift.dart';

/// Paired devices table — stores device pairing relationships.
@DataClassName('PairedDeviceData')
class PairedDevices extends Table {
  TextColumn get pairId => text()();
  TextColumn get bookId => text()();
  TextColumn get partnerDeviceId => text().nullable()(); // null during 'pending'
  TextColumn get partnerPublicKey => text().nullable()(); // null during 'pending'
  TextColumn get partnerDeviceName => text().nullable()(); // null during 'pending'
  TextColumn get status =>
      text()(); // 'pending' | 'confirming' | 'active' | 'inactive'
  TextColumn get pairCode => text().nullable()();
  IntColumn get expiresAt => integer().nullable()(); // pair code expiry (epoch ms)
  IntColumn get createdAt => integer()();
  IntColumn get confirmedAt => integer().nullable()();
  IntColumn get lastSyncAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {pairId};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_paired_devices_status', columns: {#status}),
    TableIndex(name: 'idx_paired_devices_book', columns: {#bookId}),
  ];
}
