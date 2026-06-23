import 'merchants/merchants_cafe.dart';
import 'merchants/merchants_convenience.dart';
import 'merchants/merchants_daily_drugstore.dart';
import 'merchants/merchants_dining.dart';
import 'merchants/merchants_fashion.dart';
import 'merchants/merchants_home_electronics.dart';
import 'merchants/merchants_leisure_hobby.dart';
import 'merchants/merchants_subscription_delivery.dart';
import 'merchants/merchants_supermarket.dart';
import 'merchants/merchants_transport_fuel.dart';

/// A single authored merchant seed row.
///
/// This is trusted, public, non-sensitive const DATA (not user input, not ARB).
/// Phase 49 Plan 05 (`SeedMerchantsUseCase`) expands each row into a
/// `merchants` table row plus one `merchant_match_keys` row per surface form
/// (name + aliases + locale names), deriving `ledger_hint` from [categoryId]
/// via `deriveLedgerHint` (single source of truth — D-09).
///
/// Invariants (enforced by `default_merchants_categoryid_test.dart`):
/// - [id] is a stable authored `mer_<ascii_slug>` — NEVER generated from the JP
///   name at seed time (re-seed doubling risk, Pitfall #4). Unique.
/// - [categoryId] is a real L2 id in `DefaultCategories` (D-04 silent-null gate).
/// - There is NO per-merchant ledger column — the ledger hint is derived.
class DefaultMerchant {
  /// Stable authored id, `mer_<ascii_slug>`. Used as the merchants table PK.
  final String id;

  /// Japanese display name (required, primary surface).
  final String nameJa;

  /// Chinese display name (optional locale surface).
  final String? nameZh;

  /// English display name (optional locale surface).
  final String? nameEn;

  /// Additional surface forms: romaji, abbreviations, Kansai forms, kana, etc.
  final List<String> aliases;

  /// Real L2 category id in `DefaultCategories` (drives the derived ledger hint).
  final String categoryId;

  const DefaultMerchant({
    required this.id,
    required this.nameJa,
    this.nameZh,
    this.nameEn,
    this.aliases = const [],
    required this.categoryId,
  });
}

/// System default merchant seed list (~400 national-chain Japanese merchants).
///
/// Covers the ROADMAP-enumerated national-chain spine per everyday category
/// (便利店 / 超市 / 牛丼·拉面 / 咖啡 / ファミレス / 药妆 / 百元店 / 家电 /
/// 服饰 / 交通IC / 加油 / 外卖 / 订阅) plus Tokyo·Osaka focus chains.
///
/// Split into per-group files (each < 800 lines) aggregated here.
/// Regional / depachika tail is deferred to MERCH-V2-01 (schema designed for a
/// 600-800 ceiling).
abstract final class DefaultMerchants {
  static List<DefaultMerchant> get all => [
        ...convenienceMerchants,
        ...supermarketMerchants,
        ...diningMerchants,
        ...cafeMerchants,
        ...dailyDrugstoreMerchants,
        ...homeElectronicsMerchants,
        ...fashionMerchants,
        ...transportFuelMerchants,
        ...leisureHobbyMerchants,
        ...subscriptionDeliveryMerchants,
      ];
}
