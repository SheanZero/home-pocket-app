import 'package:drift/drift.dart';

import '../../features/family_sync/domain/models/paired_device.dart';
import '../../features/family_sync/domain/repositories/pair_repository.dart';
import '../app_database.dart';
import '../daos/paired_device_dao.dart';

/// Concrete implementation of [PairRepository].
class PairRepositoryImpl implements PairRepository {
  PairRepositoryImpl({required PairedDeviceDao dao}) : _dao = dao;

  final PairedDeviceDao _dao;

  @override
  Future<void> savePendingPair({
    required String pairId,
    required String bookId,
    required String pairCode,
    required DateTime expiresAt,
  }) async {
    await _dao.insert(
      PairedDevicesCompanion.insert(
        pairId: pairId,
        bookId: bookId,
        status: 'pending',
        pairCode: Value(pairCode),
        expiresAt: Value(expiresAt.millisecondsSinceEpoch),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> saveConfirmingPair({
    required String pairId,
    required String bookId,
    required String partnerDeviceId,
    required String partnerPublicKey,
    required String partnerDeviceName,
  }) async {
    await _dao.insert(
      PairedDevicesCompanion.insert(
        pairId: pairId,
        bookId: bookId,
        partnerDeviceId: Value(partnerDeviceId),
        partnerPublicKey: Value(partnerPublicKey),
        partnerDeviceName: Value(partnerDeviceName),
        status: 'confirming',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> activatePair({
    required String pairId,
    required String bookId,
    required String partnerDeviceId,
    required String partnerPublicKey,
    required String partnerDeviceName,
  }) async {
    await _dao.updatePartnerInfo(
      pairId: pairId,
      partnerDeviceId: partnerDeviceId,
      partnerPublicKey: partnerPublicKey,
      partnerDeviceName: partnerDeviceName,
      status: 'active',
      confirmedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> confirmLocalPair(String pairId) async {
    final existing = await _dao.findByPairId(pairId);
    if (existing == null) {
      throw StateError('Pair $pairId not found');
    }
    if (existing.partnerDeviceId == null) {
      throw StateError('Pair $pairId has no partner info');
    }
    await _dao.updatePartnerInfo(
      pairId: pairId,
      partnerDeviceId: existing.partnerDeviceId!,
      partnerPublicKey: existing.partnerPublicKey!,
      partnerDeviceName: existing.partnerDeviceName!,
      status: 'active',
      confirmedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<PairedDevice?> getActivePair() async {
    final data = await _dao.findActive();
    if (data == null) return null;
    return _toModel(data);
  }

  @override
  Future<PairedDevice?> getPendingPair() async {
    final data = await _dao.findPending();
    if (data == null) return null;
    return _toModel(data);
  }

  @override
  Future<void> updateLastSyncTime(DateTime syncTime) async {
    final pair = await _dao.findActive();
    if (pair != null) {
      await _dao.updateLastSyncTime(
        pair.pairId,
        syncTime.millisecondsSinceEpoch,
      );
    }
  }

  @override
  Future<void> deactivatePair(String pairId) async {
    await _dao.updateStatus(pairId, 'inactive');
  }

  PairedDevice _toModel(PairedDeviceData data) {
    return PairedDevice(
      pairId: data.pairId,
      bookId: data.bookId,
      partnerDeviceId: data.partnerDeviceId,
      partnerPublicKey: data.partnerPublicKey,
      partnerDeviceName: data.partnerDeviceName,
      status: PairStatus.values.firstWhere((e) => e.name == data.status),
      pairCode: data.pairCode,
      expiresAt: data.expiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(data.expiresAt!)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
      confirmedAt: data.confirmedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(data.confirmedAt!)
          : null,
      lastSyncAt: data.lastSyncAt != null
          ? DateTime.fromMillisecondsSinceEpoch(data.lastSyncAt!)
          : null,
    );
  }
}
