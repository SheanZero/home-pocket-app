import '../default_merchants.dart';

/// 订阅 (subscriptions): entertainment streaming → `cat_hobbies_subscription`;
/// general daily / cloud / membership → `cat_daily_subscription`.
/// 外卖 (food delivery) → `cat_food_delivery`.
/// EC / 通販 (general e-commerce) → `cat_daily_other`.
///
/// NOTE (D-08 derived-vs-old-tag diff): Amazon was hand-tagged `joy` in the
/// legacy 12-entry seed, but `cat_daily_other` derives to `daily`. The derived
/// value WINS — surfaced for the commit-time human spot-check. Netflix maps to
/// `cat_hobbies_subscription` which derives to `joy` (matches the legacy tag).
const List<DefaultMerchant> subscriptionDeliveryMerchants = [
  // ─── 動画 / 音楽配信 (entertainment streaming) → cat_hobbies_subscription (joy) ───
  DefaultMerchant(
    id: 'mer_netflix',
    nameJa: 'Netflix',
    nameZh: '奈飞',
    nameEn: 'Netflix',
    aliases: ['ネットフリックス', 'netflix', 'ネトフリ'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_disney_plus',
    nameJa: 'ディズニープラス',
    nameEn: 'Disney+',
    aliases: ['Disney+', 'disney plus', 'ディズニープラス', 'disney+'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_u_next',
    nameJa: 'U-NEXT',
    nameEn: 'U-NEXT',
    aliases: ['U-NEXT', 'u-next', 'unext', 'ユーネクスト'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_hulu',
    nameJa: 'Hulu',
    nameEn: 'Hulu',
    aliases: ['フールー', 'hulu'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_dazn',
    nameJa: 'DAZN',
    nameEn: 'DAZN',
    aliases: ['ダゾーン', 'dazn'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_spotify',
    nameJa: 'Spotify',
    nameEn: 'Spotify',
    aliases: ['スポティファイ', 'spotify'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_apple_music',
    nameJa: 'Apple Music',
    nameEn: 'Apple Music',
    aliases: ['アップルミュージック', 'apple music'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_youtube_premium',
    nameJa: 'YouTube Premium',
    nameEn: 'YouTube Premium',
    aliases: ['ユーチューブプレミアム', 'youtube premium', 'yt premium'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_abema',
    nameJa: 'ABEMA',
    nameEn: 'ABEMA',
    aliases: ['アベマ', 'abema', 'ABEMAプレミアム'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_nintendo_online',
    nameJa: 'Nintendo Switch Online',
    nameEn: 'Nintendo Switch Online',
    aliases: ['Switch Online', 'nintendo switch online', 'ニンテンドーオンライン'],
    categoryId: 'cat_hobbies_subscription',
  ),
  DefaultMerchant(
    id: 'mer_playstation_plus',
    nameJa: 'PlayStation Plus',
    nameEn: 'PlayStation Plus',
    aliases: ['PS Plus', 'ps plus', 'playstation plus', 'プレイステーションプラス'],
    categoryId: 'cat_hobbies_subscription',
  ),
  // ─── 日常 / クラウド / 会員 (general daily) → cat_daily_subscription (daily) ───
  DefaultMerchant(
    id: 'mer_amazon_prime',
    nameJa: 'Amazonプライム',
    nameEn: 'Amazon Prime',
    aliases: ['アマゾンプライム', 'Amazon Prime', 'amazon prime', 'prime'],
    categoryId: 'cat_daily_subscription',
  ),
  DefaultMerchant(
    id: 'mer_icloud',
    nameJa: 'iCloud',
    nameEn: 'iCloud',
    aliases: ['アイクラウド', 'icloud', 'iCloud+'],
    categoryId: 'cat_daily_subscription',
  ),
  DefaultMerchant(
    id: 'mer_google_one',
    nameJa: 'Google One',
    nameEn: 'Google One',
    aliases: ['グーグルワン', 'google one'],
    categoryId: 'cat_daily_subscription',
  ),
  DefaultMerchant(
    id: 'mer_dropbox',
    nameJa: 'Dropbox',
    nameEn: 'Dropbox',
    aliases: ['ドロップボックス', 'dropbox'],
    categoryId: 'cat_daily_subscription',
  ),
  DefaultMerchant(
    id: 'mer_chatgpt',
    nameJa: 'ChatGPT',
    nameEn: 'ChatGPT Plus',
    aliases: ['チャットジーピーティー', 'chatgpt', 'chatgpt plus', 'openai'],
    categoryId: 'cat_daily_subscription',
  ),
  // ─── フードデリバリー (外卖) → cat_food_delivery ───
  DefaultMerchant(
    id: 'mer_uber_eats',
    nameJa: 'Uber Eats',
    nameZh: 'Uber外卖',
    nameEn: 'Uber Eats',
    aliases: ['ウーバーイーツ', 'Uber Eats', 'uber eats', 'ubereats'],
    categoryId: 'cat_food_delivery',
  ),
  DefaultMerchant(
    id: 'mer_demae_can',
    nameJa: '出前館',
    nameEn: 'Demae-can',
    aliases: ['出前館', 'Demae-can', 'demae can', 'でまえかん'],
    categoryId: 'cat_food_delivery',
  ),
  DefaultMerchant(
    id: 'mer_wolt',
    nameJa: 'Wolt',
    nameEn: 'Wolt',
    aliases: ['ウォルト', 'wolt'],
    categoryId: 'cat_food_delivery',
  ),
  DefaultMerchant(
    id: 'mer_menu',
    nameJa: 'menu',
    nameEn: 'menu',
    aliases: ['メニュー', 'menu delivery'],
    categoryId: 'cat_food_delivery',
  ),
  DefaultMerchant(
    id: 'mer_pizza_hut',
    nameJa: 'ピザハット',
    nameZh: '必胜客',
    nameEn: 'Pizza Hut',
    aliases: ['Pizza Hut', 'pizza hut', 'ピザハット'],
    categoryId: 'cat_food_delivery',
  ),
  DefaultMerchant(
    id: 'mer_dominos',
    nameJa: 'ドミノピザ',
    nameZh: '达美乐',
    nameEn: "Domino's Pizza",
    aliases: ['ドミノ', "Domino's", 'dominos', "domino's pizza"],
    categoryId: 'cat_food_delivery',
  ),
  DefaultMerchant(
    id: 'mer_pizza_la',
    nameJa: 'ピザーラ',
    nameEn: 'Pizza-La',
    aliases: ['Pizza-La', 'pizza la', 'ピザーラ'],
    categoryId: 'cat_food_delivery',
  ),
  // ─── EC / 通販 (general e-commerce) → cat_daily_other (daily) ───
  DefaultMerchant(
    id: 'mer_amazon',
    nameJa: 'Amazon',
    nameZh: '亚马逊',
    nameEn: 'Amazon',
    aliases: ['アマゾン', 'amazon', 'Amazon.co.jp'],
    categoryId: 'cat_daily_other',
  ),
  DefaultMerchant(
    id: 'mer_rakuten',
    nameJa: '楽天市場',
    nameZh: '乐天市场',
    nameEn: 'Rakuten Ichiba',
    aliases: ['楽天', 'Rakuten', 'rakuten', 'らくてん', 'rakuten ichiba'],
    categoryId: 'cat_daily_other',
  ),
  DefaultMerchant(
    id: 'mer_yahoo_shopping',
    nameJa: 'Yahoo!ショッピング',
    nameEn: 'Yahoo! Shopping',
    aliases: ['ヤフショ', 'Yahoo Shopping', 'yahoo shopping'],
    categoryId: 'cat_daily_other',
  ),
  DefaultMerchant(
    id: 'mer_mercari',
    nameJa: 'メルカリ',
    nameEn: 'Mercari',
    aliases: ['Mercari', 'mercari', 'めるかり'],
    categoryId: 'cat_daily_other',
  ),
  DefaultMerchant(
    id: 'mer_zozotown',
    nameJa: 'ZOZOTOWN',
    nameEn: 'ZOZOTOWN',
    aliases: ['ゾゾタウン', 'ZOZO', 'zozotown', 'zozo'],
    categoryId: 'cat_clothing_clothes',
  ),
  DefaultMerchant(
    id: 'mer_qoo10',
    nameJa: 'Qoo10',
    nameEn: 'Qoo10',
    aliases: ['キューテン', 'qoo10'],
    categoryId: 'cat_daily_other',
  ),
  DefaultMerchant(
    id: 'mer_yodobashi_com',
    nameJa: 'ヨドバシ.com',
    nameEn: 'Yodobashi.com',
    aliases: ['ヨドバシドットコム', 'yodobashi.com', 'yodobashi com'],
    categoryId: 'cat_housing_appliances',
  ),
];
