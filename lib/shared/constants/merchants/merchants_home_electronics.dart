import '../default_merchants.dart';

/// 家电量贩店 (electronics retailers) → `cat_housing_appliances`.
/// 家具 / インテリア (furniture) → `cat_housing_furniture`.
///
/// NOTE (D-08 derived-vs-old-tag diff): ヤマダ電機 was hand-tagged `joy` in the
/// legacy 12-entry seed, but `cat_housing_appliances` derives to `daily`. The
/// derived value WINS — surfaced for the commit-time human spot-check.
const List<DefaultMerchant> homeElectronicsMerchants = [
  // ─── 家電量販店 → cat_housing_appliances ───
  DefaultMerchant(
    id: 'mer_yamada_denki',
    nameJa: 'ヤマダ電機',
    nameZh: '山田电机',
    nameEn: 'Yamada Denki',
    aliases: ['ヤマダ', 'Yamada', 'yamada', 'yamada denki', 'ヤマダデンキ'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_bic_camera',
    nameJa: 'ビックカメラ',
    nameZh: 'BIC CAMERA',
    nameEn: 'Bic Camera',
    aliases: ['ビック', 'Bic Camera', 'bic camera', 'biccamera'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_yodobashi',
    nameJa: 'ヨドバシカメラ',
    nameZh: '友都八喜',
    nameEn: 'Yodobashi Camera',
    aliases: ['ヨドバシ', 'Yodobashi', 'yodobashi', 'yodobashi camera'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_edion',
    nameJa: 'エディオン',
    nameEn: 'EDION',
    aliases: ['EDION', 'edion', 'エディオン'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_kojima',
    nameJa: 'コジマ',
    nameEn: 'Kojima',
    aliases: ['Kojima', 'kojima', 'コジマ×ビックカメラ'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_kdenki',
    nameJa: 'ケーズデンキ',
    nameEn: "K's Denki",
    aliases: ["K's Denki", 'ks denki', 'ケーズ', "k's denki"],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_joshin',
    nameJa: 'ジョーシン',
    nameEn: 'Joshin',
    aliases: ['上新電機', 'Joshin', 'joshin'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_nojima',
    nameJa: 'ノジマ',
    nameEn: 'Nojima',
    aliases: ['Nojima', 'nojima'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_apple_store',
    nameJa: 'Apple Store',
    nameZh: '苹果店',
    nameEn: 'Apple Store',
    aliases: ['アップルストア', 'Apple', 'apple store', 'apple'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_pc_depot',
    nameJa: 'PCデポ',
    nameEn: 'PC Depot',
    aliases: ['PC Depot', 'pc depot', 'ピーシーデポ'],
    categoryId: 'cat_housing_appliances',
  ),
  // ─── 家具 / インテリア → cat_housing_furniture ───
  DefaultMerchant(
    id: 'mer_nitori',
    nameJa: 'ニトリ',
    nameZh: '宜得利',
    nameEn: 'Nitori',
    aliases: ['Nitori', 'nitori', 'にとり'],
    categoryId: 'cat_housing_furniture',
  ),
  DefaultMerchant(
    id: 'mer_ikea',
    nameJa: 'イケア',
    nameZh: '宜家',
    nameEn: 'IKEA',
    aliases: ['IKEA', 'ikea'],
    categoryId: 'cat_housing_furniture',
  ),
  DefaultMerchant(
    id: 'mer_unico',
    nameJa: 'ウニコ',
    nameEn: 'unico',
    aliases: ['unico', 'ウニコ'],
    categoryId: 'cat_housing_furniture',
  ),
  DefaultMerchant(
    id: 'mer_francfranc',
    nameJa: 'フランフラン',
    nameEn: 'Francfranc',
    aliases: ['Francfranc', 'francfranc'],
    categoryId: 'cat_housing_furniture',
  ),
  DefaultMerchant(
    id: 'mer_otsuka_kagu',
    nameJa: '大塚家具',
    nameEn: 'Otsuka Kagu',
    aliases: ['Otsuka Kagu', 'otsuka kagu', 'おおつかかぐ'],
    categoryId: 'cat_housing_furniture',
  ),
  DefaultMerchant(
    id: 'mer_shimachu_home_fashion',
    nameJa: 'シマホ家具',
    nameEn: 'Shimachu Furniture',
    aliases: ['Shimachu Furniture', 'shimachu furniture'],
    categoryId: 'cat_housing_furniture',
  ),
  DefaultMerchant(
    id: 'mer_actus',
    nameJa: 'アクタス',
    nameEn: 'ACTUS',
    aliases: ['ACTUS', 'actus', 'アクタス'],
    categoryId: 'cat_housing_furniture',
  ),
  DefaultMerchant(
    id: 'mer_muji_furniture',
    nameJa: '無印良品の家具',
    nameEn: 'MUJI Furniture',
    aliases: ['MUJI Furniture', 'muji furniture'],
    categoryId: 'cat_housing_furniture',
  ),
  DefaultMerchant(
    id: 'mer_yamada_outlet',
    nameJa: 'ヤマダアウトレット',
    nameEn: 'Yamada Outlet',
    aliases: ['Yamada Outlet', 'yamada outlet'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_sofmap',
    nameJa: 'ソフマップ',
    nameEn: 'Sofmap',
    aliases: ['Sofmap', 'sofmap', 'ソフマップ'],
    categoryId: 'cat_housing_appliances',
  ),
  DefaultMerchant(
    id: 'mer_dospara',
    nameJa: 'ドスパラ',
    nameEn: 'Dospara',
    aliases: ['Dospara', 'dospara', 'ドスパラ'],
    categoryId: 'cat_housing_appliances',
  ),
];
