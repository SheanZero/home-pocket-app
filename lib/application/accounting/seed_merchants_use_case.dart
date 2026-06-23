import '../../features/accounting/domain/models/merchant.dart';
import '../../features/accounting/domain/repositories/merchant_repository.dart';
import '../../infrastructure/ml/merchant_name_normalizer.dart';
import '../../shared/constants/default_merchants.dart';
import '../../shared/utils/result.dart';
import 'ledger_hint_deriver.dart';

/// Seeds the curated Japan merchant spine ([DefaultMerchants.all]) if none exist.
///
/// Mirrors [SeedCategoriesUseCase]: a `findAll()`-empty count guard, then a
/// single-transaction batch insert (D-05). Each [DefaultMerchant] expands into:
///
///  - one merchants row, with `ledgerHint` DERIVED from `categoryId` via
///    [deriveLedgerHint] (single source of truth — D-09, never hand-authored);
///  - one merchant_match_keys row per surface form — `nameJa` (kind `name`),
///    each alias (kind `alias`), and each non-null locale name (kind `locale`) —
///    with `matchKey = normalizeMerchantKey(surface)` (D-07, D-09).
///
/// Idempotent: the repository uses stable composite PKs + `INSERT OR IGNORE`, so
/// re-seeding converges (row counts unchanged — Crit #3). Duplicate match keys
/// across surfaces (e.g. name == alias) collapse to one row at insert time.
///
/// Wired as the THIRD leaf of [SeedAllUseCase], AFTER categories (merchant
/// `categoryId`s reference seeded L2 categories). NOT the AppInitializer
/// `seedRunner` no-op (Pitfall #1, corrects D-06).
///
/// Zero-knowledge discipline (V7): performs NO logging of raw merchant names.
class SeedMerchantsUseCase {
  SeedMerchantsUseCase({required MerchantRepository merchantRepository})
      : _merchantRepo = merchantRepository;

  final MerchantRepository _merchantRepo;

  Future<Result<void>> execute() async {
    final existing = await _merchantRepo.findAll();
    if (existing.isNotEmpty) {
      return Result.success(null);
    }

    final merchants = DefaultMerchants.all.map(_expand).toList(growable: false);
    await _merchantRepo.insertBatch(merchants);
    return Result.success(null);
  }

  /// Expands a const [DefaultMerchant] into a [Merchant] domain instance with
  /// derived ledger hint and normalized surface forms.
  Merchant _expand(DefaultMerchant m) {
    final surfaces = <MerchantMatchKey>[
      _surface(m.nameJa, 'name'),
      for (final alias in m.aliases) _surface(alias, 'alias'),
      if (m.nameZh != null) _surface(m.nameZh!, 'locale'),
      if (m.nameEn != null) _surface(m.nameEn!, 'locale'),
    ];

    return Merchant(
      id: m.id,
      nameJa: m.nameJa,
      nameZh: m.nameZh,
      nameEn: m.nameEn,
      region: 'JP',
      categoryId: m.categoryId,
      ledgerHint: deriveLedgerHint(m.categoryId).name,
      surfaces: surfaces,
    );
  }

  MerchantMatchKey _surface(String surface, String kind) => MerchantMatchKey(
        surface: surface,
        matchKey: normalizeMerchantKey(surface),
        kind: kind,
      );
}
