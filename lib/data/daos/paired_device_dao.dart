import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data access object for the PairedDevices table.
class PairedDeviceDao {
  PairedDeviceDao(this._db);

  final AppDatabase _db;

  Future<void> insert(PairedDevicesCompanion entry) async {
    await _db.into(_db.pairedDevices).insert(entry);
  }

  Future<void> updateRow(PairedDeviceData data) async {
    await _db.update(_db.pairedDevices).replace(data);
  }

  Future<PairedDeviceData?> findByPairId(String pairId) async {
    return (_db.select(_db.pairedDevices)
          ..where((t) => t.pairId.equals(pairId)))
        .getSingleOrNull();
  }

  /// Find the active pair (status == 'active').
  Future<PairedDeviceData?> findActive() async {
    return (_db.select(_db.pairedDevices)
          ..where((t) => t.status.equals('active')))
        .getSingleOrNull();
  }

  /// Find the pending pair (status == 'pending' or 'confirming').
  Future<PairedDeviceData?> findPending() async {
    return (_db.select(_db.pairedDevices)
          ..where(
            (t) =>
                t.status.equals('pending') | t.status.equals('confirming'),
          ))
        .getSingleOrNull();
  }

  Future<void> updateStatus(String pairId, String status) async {
    await (_db.update(_db.pairedDevices)
          ..where((t) => t.pairId.equals(pairId)))
        .write(PairedDevicesCompanion(status: Value(status)));
  }

  Future<void> updatePartnerInfo({
    required String pairId,
    required String partnerDeviceId,
    required String partnerPublicKey,
    required String partnerDeviceName,
    required String status,
    int? confirmedAt,
  }) async {
    await (_db.update(_db.pairedDevices)
          ..where((t) => t.pairId.equals(pairId)))
        .write(
      PairedDevicesCompanion(
        partnerDeviceId: Value(partnerDeviceId),
        partnerPublicKey: Value(partnerPublicKey),
        partnerDeviceName: Value(partnerDeviceName),
        status: Value(status),
        confirmedAt: Value(confirmedAt),
      ),
    );
  }

  Future<void> updateLastSyncTime(String pairId, int lastSyncAt) async {
    await (_db.update(_db.pairedDevices)
          ..where((t) => t.pairId.equals(pairId)))
        .write(PairedDevicesCompanion(lastSyncAt: Value(lastSyncAt)));
  }
}
