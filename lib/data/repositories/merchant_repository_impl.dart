import 'package:drift/drift.dart' show Value;

import '../../features/accounting/domain/models/merchant.dart';
import '../../features/accounting/domain/repositories/merchant_repository.dart';
import '../app_database.dart';
import '../daos/merchant_dao.dart';

/// Concrete implementation of [MerchantRepository].
///
/// Maps `MerchantRow` + its `MerchantMatchKeyRow`s to the [Merchant] domain
/// model, and decomposes `insertBatch(List<Merchant>)` into companions
/// delegated to the DAO's single transaction (INSERT OR IGNORE).
class MerchantRepositoryImpl implements MerchantRepository {
  MerchantRepositoryImpl({required MerchantDao dao}) : _dao = dao;

  final MerchantDao _dao;

  @override
  Future<List<Merchant>> findAll() async {
    final rows = await _dao.findAllMerchantRows();
    final keys = await _dao.findAllMatchKeyRows();
    final keysByMerchant = <String, List<MerchantMatchKeyRow>>{};
    for (final k in keys) {
      keysByMerchant.putIfAbsent(k.merchantId, () => []).add(k);
    }
    return rows
        .map((r) => _toModel(r, keysByMerchant[r.id] ?? const []))
        .toList();
  }

  @override
  Future<bool> hasAny() => _dao.hasAny();

  @override
  Future<Merchant?> findById(String id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    final keys = await _dao.findMatchKeysFor(id);
    return _toModel(row, keys);
  }

  @override
  Future<void> insertBatch(List<Merchant> merchants) async {
    final merchantCompanions = <MerchantsCompanion>[];
    final keyCompanions = <MerchantMatchKeysCompanion>[];

    for (final m in merchants) {
      merchantCompanions.add(
        MerchantsCompanion.insert(
          id: m.id,
          nameJa: m.nameJa,
          nameZh: Value(m.nameZh),
          nameEn: Value(m.nameEn),
          region: Value(m.region),
          categoryId: m.categoryId,
          ledgerHint: m.ledgerHint,
        ),
      );
      for (final s in m.surfaces) {
        keyCompanions.add(
          MerchantMatchKeysCompanion.insert(
            // Stable PK so re-seed is idempotent: merchant id + normalized key.
            id: '${m.id}__${s.matchKey}',
            merchantId: m.id,
            surface: s.surface,
            matchKey: s.matchKey,
            kind: s.kind,
          ),
        );
      }
    }

    await _dao.insertSeed(merchantCompanions, keyCompanions);
  }

  Merchant _toModel(MerchantRow row, List<MerchantMatchKeyRow> keys) {
    return Merchant(
      id: row.id,
      nameJa: row.nameJa,
      nameZh: row.nameZh,
      nameEn: row.nameEn,
      region: row.region,
      categoryId: row.categoryId,
      ledgerHint: row.ledgerHint,
      surfaces: keys
          .map(
            (k) => MerchantMatchKey(
              surface: k.surface,
              matchKey: k.matchKey,
              kind: k.kind,
            ),
          )
          .toList(),
    );
  }
}
