import '../default_merchants.dart';

/// 鉄道 / 交通IC → `cat_transport_train`.
/// 新幹線 → `cat_transport_shinkansen`.
/// 高速バス → `cat_transport_highway_bus`.
/// 航空 → `cat_transport_flights`.
/// タクシー / 配車 → `cat_transport_taxi`.
/// ガソリン (fuel) → `cat_car_fuel`.
/// カーシェア → `cat_car_car_share`.
const List<DefaultMerchant> transportFuelMerchants = [
  // ─── 交通IC / 鉄道 → cat_transport_train ───
  DefaultMerchant(
    id: 'mer_suica',
    nameJa: 'Suica',
    nameEn: 'Suica',
    aliases: ['スイカ', 'suica', 'モバイルSuica'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_pasmo',
    nameJa: 'PASMO',
    nameEn: 'PASMO',
    aliases: ['パスモ', 'pasmo'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_icoca',
    nameJa: 'ICOCA',
    nameEn: 'ICOCA',
    aliases: ['イコカ', 'icoca'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_jr_east',
    nameJa: 'JR東日本',
    nameEn: 'JR East',
    aliases: ['JR', 'JR East', 'jr east', 'jr東'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_jr_west',
    nameJa: 'JR西日本',
    nameEn: 'JR West',
    aliases: ['JR West', 'jr west', 'jr西'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_tokyo_metro',
    nameJa: '東京メトロ',
    nameEn: 'Tokyo Metro',
    aliases: ['メトロ', 'Tokyo Metro', 'tokyo metro'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_toei',
    nameJa: '都営地下鉄',
    nameEn: 'Toei Subway',
    aliases: ['都営', 'Toei', 'toei subway'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_osaka_metro',
    nameJa: 'Osaka Metro',
    nameEn: 'Osaka Metro',
    aliases: ['大阪メトロ', 'osaka metro'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_hankyu',
    nameJa: '阪急電鉄',
    nameEn: 'Hankyu',
    aliases: ['阪急', 'Hankyu', 'hankyu'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_keikyu',
    nameJa: '京急',
    nameEn: 'Keikyu',
    aliases: ['Keikyu', 'keikyu', 'けいきゅう'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_odakyu',
    nameJa: '小田急',
    nameEn: 'Odakyu',
    aliases: ['Odakyu', 'odakyu', 'おだきゅう'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_tokyu',
    nameJa: '東急電鉄',
    nameEn: 'Tokyu',
    aliases: ['東急', 'Tokyu', 'tokyu'],
    categoryId: 'cat_transport_train',
  ),
  // ─── 新幹線 → cat_transport_shinkansen ───
  DefaultMerchant(
    id: 'mer_shinkansen',
    nameJa: '新幹線',
    nameEn: 'Shinkansen',
    aliases: ['Shinkansen', 'shinkansen', 'しんかんせん', 'のぞみ', 'ひかり'],
    categoryId: 'cat_transport_shinkansen',
  ),
  // ─── 高速バス → cat_transport_highway_bus ───
  DefaultMerchant(
    id: 'mer_willer_express',
    nameJa: 'WILLER EXPRESS',
    nameEn: 'WILLER EXPRESS',
    aliases: ['WILLER', 'willer express', 'ウィラー'],
    categoryId: 'cat_transport_highway_bus',
  ),
  // ─── 航空 → cat_transport_flights ───
  DefaultMerchant(
    id: 'mer_ana',
    nameJa: 'ANA',
    nameEn: 'ANA',
    aliases: ['全日空', 'ANA', 'ana', '全日本空輸'],
    categoryId: 'cat_transport_flights',
  ),
  DefaultMerchant(
    id: 'mer_jal',
    nameJa: 'JAL',
    nameEn: 'JAL',
    aliases: ['日本航空', 'JAL', 'jal'],
    categoryId: 'cat_transport_flights',
  ),
  DefaultMerchant(
    id: 'mer_peach',
    nameJa: 'ピーチ',
    nameEn: 'Peach',
    aliases: ['Peach Aviation', 'peach', 'ピーチアビエーション'],
    categoryId: 'cat_transport_flights',
  ),
  DefaultMerchant(
    id: 'mer_jetstar',
    nameJa: 'ジェットスター',
    nameEn: 'Jetstar',
    aliases: ['Jetstar', 'jetstar'],
    categoryId: 'cat_transport_flights',
  ),
  // ─── タクシー / 配車 → cat_transport_taxi ───
  DefaultMerchant(
    id: 'mer_go_taxi',
    nameJa: 'GOタクシー',
    nameEn: 'GO',
    aliases: ['GO', 'go taxi', 'ゴータクシー'],
    categoryId: 'cat_transport_taxi',
  ),
  DefaultMerchant(
    id: 'mer_uber_taxi',
    nameJa: 'Uber',
    nameEn: 'Uber',
    aliases: ['ウーバー', 'uber', 'uber taxi'],
    categoryId: 'cat_transport_taxi',
  ),
  DefaultMerchant(
    id: 'mer_didi',
    nameJa: 'DiDi',
    nameEn: 'DiDi',
    aliases: ['ディディ', 'didi'],
    categoryId: 'cat_transport_taxi',
  ),
  DefaultMerchant(
    id: 'mer_nihon_kotsu',
    nameJa: '日本交通',
    nameEn: 'Nihon Kotsu',
    aliases: ['日交', 'Nihon Kotsu', 'nihon kotsu'],
    categoryId: 'cat_transport_taxi',
  ),
  // ─── ガソリンスタンド → cat_car_fuel ───
  DefaultMerchant(
    id: 'mer_eneos',
    nameJa: 'エネオス',
    nameEn: 'ENEOS',
    aliases: ['ENEOS', 'eneos', 'エネオス'],
    categoryId: 'cat_car_fuel',
  ),
  DefaultMerchant(
    id: 'mer_idemitsu',
    nameJa: '出光',
    nameEn: 'Idemitsu',
    aliases: ['Idemitsu', 'idemitsu', 'いでみつ', 'apollostation'],
    categoryId: 'cat_car_fuel',
  ),
  DefaultMerchant(
    id: 'mer_cosmo_oil',
    nameJa: 'コスモ石油',
    nameEn: 'Cosmo Oil',
    aliases: ['コスモ', 'Cosmo Oil', 'cosmo oil'],
    categoryId: 'cat_car_fuel',
  ),
  DefaultMerchant(
    id: 'mer_showa_shell',
    nameJa: '昭和シェル',
    nameEn: 'Showa Shell',
    aliases: ['シェル', 'Shell', 'showa shell'],
    categoryId: 'cat_car_fuel',
  ),
  DefaultMerchant(
    id: 'mer_kygnus',
    nameJa: 'キグナス',
    nameEn: 'Kygnus',
    aliases: ['Kygnus', 'kygnus'],
    categoryId: 'cat_car_fuel',
  ),
  // ─── カーシェア → cat_car_car_share ───
  DefaultMerchant(
    id: 'mer_times_car',
    nameJa: 'タイムズカー',
    nameEn: 'Times Car',
    aliases: ['タイムズ', 'Times Car', 'times car', 'タイムズカーシェア'],
    categoryId: 'cat_car_car_share',
  ),
  DefaultMerchant(
    id: 'mer_careco',
    nameJa: 'カレコ',
    nameEn: 'Careco',
    aliases: ['Careco', 'careco', 'カレコ・カーシェアリング'],
    categoryId: 'cat_car_car_share',
  ),
  // ─── 駐車場 → cat_car_parking ───
  DefaultMerchant(
    id: 'mer_times_parking',
    nameJa: 'タイムズパーキング',
    nameEn: 'Times Parking',
    aliases: ['Times Parking', 'times parking', 'タイムズ駐車場'],
    categoryId: 'cat_car_parking',
  ),
  DefaultMerchant(
    id: 'mer_repark',
    nameJa: 'リパーク',
    nameEn: 'Repark',
    aliases: ['三井のリパーク', 'Repark', 'repark'],
    categoryId: 'cat_car_parking',
  ),
  // ─── 追加: 鉄道 ───
  DefaultMerchant(
    id: 'mer_keio',
    nameJa: '京王電鉄',
    nameEn: 'Keio',
    aliases: ['京王', 'Keio', 'keio'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_seibu',
    nameJa: '西武鉄道',
    nameEn: 'Seibu',
    aliases: ['西武', 'Seibu', 'seibu'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_tobu',
    nameJa: '東武鉄道',
    nameEn: 'Tobu',
    aliases: ['東武', 'Tobu', 'tobu'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_keisei',
    nameJa: '京成電鉄',
    nameEn: 'Keisei',
    aliases: ['京成', 'Keisei', 'keisei'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_nankai',
    nameJa: '南海電鉄',
    nameEn: 'Nankai',
    aliases: ['南海', 'Nankai', 'nankai'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_kintetsu',
    nameJa: '近鉄',
    nameEn: 'Kintetsu',
    aliases: ['近畿日本鉄道', 'Kintetsu', 'kintetsu'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_keihan',
    nameJa: '京阪電車',
    nameEn: 'Keihan',
    aliases: ['京阪', 'Keihan', 'keihan'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_nishitetsu',
    nameJa: '西鉄',
    nameEn: 'Nishitetsu',
    aliases: ['西日本鉄道', 'Nishitetsu', 'nishitetsu'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_jr_central',
    nameJa: 'JR東海',
    nameEn: 'JR Central',
    aliases: ['JR Central', 'jr central', 'jr東海'],
    categoryId: 'cat_transport_train',
  ),
  DefaultMerchant(
    id: 'mer_jr_kyushu',
    nameJa: 'JR九州',
    nameEn: 'JR Kyushu',
    aliases: ['JR Kyushu', 'jr kyushu', 'jr九州'],
    categoryId: 'cat_transport_train',
  ),
  // ─── 追加: 航空 / 配車 ───
  DefaultMerchant(
    id: 'mer_skymark',
    nameJa: 'スカイマーク',
    nameEn: 'Skymark',
    aliases: ['Skymark', 'skymark', 'スカイマーク'],
    categoryId: 'cat_transport_flights',
  ),
  DefaultMerchant(
    id: 'mer_solaseed',
    nameJa: 'ソラシドエア',
    nameEn: 'Solaseed Air',
    aliases: ['Solaseed', 'solaseed air', 'ソラシドエア'],
    categoryId: 'cat_transport_flights',
  ),
  // ─── 追加: ガソリン ───
  DefaultMerchant(
    id: 'mer_esso',
    nameJa: 'エッソ',
    nameEn: 'Esso',
    aliases: ['Esso', 'esso', 'エッソ'],
    categoryId: 'cat_car_fuel',
  ),
  DefaultMerchant(
    id: 'mer_mobil',
    nameJa: 'モービル',
    nameEn: 'Mobil',
    aliases: ['Mobil', 'mobil', 'モービル'],
    categoryId: 'cat_car_fuel',
  ),
];
