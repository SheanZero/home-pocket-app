import '../default_merchants.dart';

/// 便利店 (convenience stores). Map to `cat_food_groceries` — convenience-store
/// spend is overwhelmingly daily groceries/food (matches the verified seed core).
const List<DefaultMerchant> convenienceMerchants = [
  DefaultMerchant(
    id: 'mer_seven_eleven',
    nameJa: 'セブンイレブン',
    nameZh: '7-11便利店',
    nameEn: '7-Eleven',
    aliases: ['セブン', '7-Eleven', '7-11', '7eleven', 'seven eleven', 'セブン-イレブン'],
    categoryId: 'cat_food_groceries',
  ),
  DefaultMerchant(
    id: 'mer_family_mart',
    nameJa: 'ファミリーマート',
    nameZh: '全家便利店',
    nameEn: 'FamilyMart',
    aliases: ['ファミマ', 'FamilyMart', 'familymart', 'family mart'],
    categoryId: 'cat_food_groceries',
  ),
  DefaultMerchant(
    id: 'mer_lawson',
    nameJa: 'ローソン',
    nameZh: '罗森',
    nameEn: 'Lawson',
    aliases: ['Lawson', 'lawson', 'ローソンストア100', 'ナチュラルローソン'],
    categoryId: 'cat_food_groceries',
  ),
  DefaultMerchant(
    id: 'mer_ministop',
    nameJa: 'ミニストップ',
    nameEn: 'Ministop',
    aliases: ['Ministop', 'ministop', 'ミニストップ'],
    categoryId: 'cat_food_groceries',
  ),
  DefaultMerchant(
    id: 'mer_daily_yamazaki',
    nameJa: 'デイリーヤマザキ',
    nameEn: 'Daily Yamazaki',
    aliases: ['Daily Yamazaki', 'daily yamazaki', 'デイリー'],
    categoryId: 'cat_food_groceries',
  ),
  DefaultMerchant(
    id: 'mer_seicomart',
    nameJa: 'セイコーマート',
    nameEn: 'Seicomart',
    aliases: ['セコマ', 'Seicomart', 'seicomart'],
    categoryId: 'cat_food_groceries',
  ),
  DefaultMerchant(
    id: 'mer_newdays',
    nameJa: 'ニューデイズ',
    nameEn: 'NewDays',
    aliases: ['NewDays', 'newdays', 'ニューデイズ'],
    categoryId: 'cat_food_groceries',
  ),
  DefaultMerchant(
    id: 'mer_poplar',
    nameJa: 'ポプラ',
    nameEn: 'Poplar',
    aliases: ['Poplar', 'poplar'],
    categoryId: 'cat_food_groceries',
  ),
];
