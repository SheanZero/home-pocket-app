# Recommended Default Categories (Japan, Expense-Only)

**文档编号**: DEV-CATEGORIES-REC-001
**版本**: 1.0
**日期**: 2026-04-10
**基于**: `docs/dev/categories_japan_proposal.md` §5-6 的综合建议
**范围**: **仅支出类目**（当前 App 重点，收入侧待 v2 规划）

Source: 从 `docs/dev/categories.md` 基线推导，综合采纳 `categories_japan_proposal.md` 的研究结论，对齐 Money Forward ME / Zaim / 総務省家計調査 / 日本家計簿伝統。

---

## Changes vs. Baseline (`categories.md`)

| 变更 | 数量 | 说明 |
|------|------|------|
| L1 删除 | 2 | `cat_cash_card`（使用账户转账原语代替），`cat_uncategorized`（合并到 `cat_other_expense > cat_other_unclassified`） |
| L1 新增 | 2 | `cat_allowance` お小遣い（从 L2 提升，soul ledger）；`cat_pet` ペット（从 `cat_daily_pets` L2 提升，soul ledger） |
| L2 删除 | ~18 | 主要是 `*_general` 占位符、食費 时段细分（早/午/晚）、转账类 L2（立替金/事業費/返済）、`cat_daily_pets`（提升为 L1） |
| L2 新增 | ~53 | 日本高频科目：ふるさと納税、学資保険、人間ドック、NHK受信料、NISA・iDeCo、推し活、カーシェア、新幹線 等；**ペット专项 7 项**（フード・おやつ、用品、医療、トリミング、保険、ホテル 等） |
| L2 拆分 | 1 | 趣味・娯楽 的 `games` 拆为 `music` / `games` / `manga`（已融入新清单） |
| 净变化 | L1 ±0 / L2 +35 | 19×103 → **19×138** = **157 条**（较基线 122 条增加 35 条） |

**关键设计决策**:

1. **`cat_special`（特別な支出）保留为 L1**，接受其 L2 与 `cat_housing`/`cat_car`/`cat_hobbies` 的设计性重复——日本家計簿伝統按"频率"切分是 intentional。替代方案（降级为 Transaction tag）见 `categories_japan_proposal.md` §8.4。
2. **`cat_allowance`（お小遣い）作为独立 L1**，默认 **soul** 账本——对齐日本家計簿伝統的"固定費 top-level"认知。
3. **`cat_pet`（ペット）作为独立 L1**，默认 **soul** 账本——从原 `cat_daily_pets` L2 提升。日本养宠家庭比例持续上升，ペット関連支出细分度高（フード・おやつ/用品/医療/トリミング/保険/ホテル 等），独立 L1 可独立追踪年度预算与长期项（医療/保険）。
4. **`cat_asset`（資産形成）保留为 Home Pocket 独有 soul L1**，追加 8 个日本实用 L2（NISA / iDeCo 等）。
5. **`cat_cash_card` 完全移除**——MF ME 的 workaround 在有 Account 原语的 Home Pocket 中是反模式，用账户间转账记录替代。
6. **L2 ledger 允许覆盖 L1 默认**——`category_ledger_configs_table` schema 已支持，新增 L2 覆盖条目见 §L2 Ledger Overrides。

---

## Expense Categories — L1 (18)

| ID | Icon | Color | Ledger | EN | JA | ZH |
|----|------|-------|--------|----|----|-----|
| `cat_food` | restaurant | #FF5722 | survival | Food | 食費 | 食费 |
| `cat_daily` | local_mall | #00BCD4 | survival | Daily Necessities | 日用品 | 日用品 |
| `cat_pet` | pets | #7CB342 | soul | Pets | ペット | 宠物 |
| `cat_transport` | directions_bus | #2196F3 | survival | Transport | 交通費 | 交通费 |
| `cat_hobbies` | sports_esports | #9C27B0 | soul | Hobbies & Entertainment | 趣味・娯楽 | 兴趣娱乐 |
| `cat_clothing` | checkroom | #E91E63 | soul | Clothing & Beauty | 衣服・美容 | 衣服美容 |
| `cat_social` | people | #FF9800 | survival | Socializing | 交際費 | 交际费 |
| `cat_health` | local_hospital | #F44336 | survival | Health & Medical | 健康・医療 | 健康医疗 |
| `cat_education` | school | #3F51B5 | soul | Education | 教育・教養 | 教育进修 |
| `cat_utilities` | flash_on | #FFC107 | survival | Utilities | 水道・光熱費 | 水电燃气 |
| `cat_communication` | phone_iphone | #00ACC1 | survival | Communication | 通信費 | 通讯费 |
| `cat_housing` | home | #795548 | survival | Housing | 住宅 | 住宅 |
| `cat_car` | directions_car | #455A64 | survival | Car & Motorcycle | 車・バイク | 车与摩托 |
| `cat_tax` | account_balance | #5D4037 | survival | Taxes & Social Security | 税・社会保障 | 税费与社会保障 |
| `cat_insurance` | security | #827717 | survival | Insurance | 保険 | 保险 |
| `cat_special` | star | #AD1457 | survival | Special Expenses | 特別な支出 | 特别支出 |
| `cat_allowance` | wallet | #8D6E63 | soul | Allowance | お小遣い | 零花钱 |
| `cat_asset` | savings | #1B5E20 | soul | Asset Building | 資産形成 | 资产配置 |
| `cat_other_expense` | more_horiz | #607D8B | survival | Other | その他 | 其他 |

---

## Expense Categories — L2 (132)

### Food (`cat_food`, #FF5722) — 6 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_food_groceries` | shopping_basket | Groceries | 食料品 | 食材杂货 |
| `cat_food_dining_out` | restaurant_menu | Dining Out | 外食 | 外出就餐 |
| `cat_food_cafe` | local_cafe | Cafe | カフェ | 咖啡馆 |
| `cat_food_delivery` | delivery_dining | Delivery | デリバリー | 外卖 |
| `cat_food_drinks` | local_bar | Drinks & Alcohol | 飲料・酒類 | 饮料酒类 |
| `cat_food_other` | more_horiz | Other Food | その他食費 | 其他食费 |

### Daily Necessities (`cat_daily`, #00BCD4) — 6 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_daily_household` | cleaning_services | Household Goods | 生活雑貨 | 生活杂货 |
| `cat_daily_drugstore` | local_pharmacy | Drugstore | ドラッグストア | 药妆店 |
| `cat_daily_children` | child_care | Child-related | 子ども関連 | 儿童相关 |
| `cat_daily_tobacco` | smoking_rooms | Tobacco | タバコ | 烟草 |
| `cat_daily_subscription` | subscriptions | Daily Subscriptions | サブスク雑貨 | 日用品订阅 |
| `cat_daily_other` | more_horiz | Other Daily Necessities | その他日用品 | 其他日用品 |

### Pets (`cat_pet`, #7CB342) — 7 L2 **[NEW L1]**

> **说明**: 从原 `cat_daily_pets` L2 提升为独立 L1。默认 **soul** 账本——养宠是情感性、生活质量型选择。日本养宠家庭的ペット関連支出细分度高，独立成 L1 后可以追踪宠物年度预算与医療/保険/ホテル 等长期项。

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_pet_food` | set_meal | Pet Food | ペットフード | 宠物食品 |
| `cat_pet_supplies` | inventory_2 | Supplies & Toys | ペット用品・おもちゃ | 宠物用品/玩具 |
| `cat_pet_medical` | healing | Vet & Medical | 病院・医療費 | 宠物医疗 |
| `cat_pet_grooming` | shower | Grooming & Salon | トリミング | 美容护理 |
| `cat_pet_insurance` | verified_user | Pet Insurance | ペット保険 | 宠物保险 |
| `cat_pet_hotel` | hotel | Boarding & Pet Sitter | ペットホテル・預かり | 宠物寄养 |
| `cat_pet_other` | more_horiz | Other Pet Expenses | その他ペット | 其他宠物 |

### Transport (`cat_transport`, #2196F3) — 7 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_transport_train` | train | Train | 電車 | 电车 |
| `cat_transport_shinkansen` | directions_railway | Shinkansen | 新幹線 | 新干线 |
| `cat_transport_bus` | directions_bus | Bus | バス | 公交 |
| `cat_transport_highway_bus` | airport_shuttle | Highway Bus | 高速バス | 高速巴士 |
| `cat_transport_taxi` | local_taxi | Taxi | タクシー | 出租车 |
| `cat_transport_flights` | flight | Flights | 飛行機 | 飞机 |
| `cat_transport_other` | more_horiz | Other Transport | その他交通 | 其他交通 |

### Hobbies & Entertainment (`cat_hobbies`, #9C27B0) — 10 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_hobbies_leisure` | sports_tennis | Leisure & Sports | レジャー・スポーツ | 休闲运动 |
| `cat_hobbies_events` | event | Events | イベント | 活动 |
| `cat_hobbies_movies` | movie | Movies & Videos | 映画・動画 | 电影视频 |
| `cat_hobbies_music` | music_note | Music | 音楽 | 音乐 |
| `cat_hobbies_games` | videogame_asset | Games | ゲーム | 游戏 |
| `cat_hobbies_books` | menu_book | Books & Manga | 本・漫画 | 书籍漫画 |
| `cat_hobbies_travel` | luggage | Travel | 旅行 | 旅行 |
| `cat_hobbies_subscription` | subscriptions | Entertainment Subs | エンタメサブスク | 娱乐订阅 |
| `cat_hobbies_oshikatsu` | favorite | Fan Activities & Goods | 推し活・グッズ | 粉丝活动/周边 |
| `cat_hobbies_other` | more_horiz | Other Hobbies & Entertainment | その他趣味・娯楽 | 其他兴趣娱乐 |

### Clothing & Beauty (`cat_clothing`, #E91E63) — 10 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_clothing_clothes` | checkroom | Clothing | 衣服 | 衣服 |
| `cat_clothing_shoes` | directions_walk | Shoes & Footwear | 靴・履物 | 鞋履 |
| `cat_clothing_bags` | shopping_bag | Bags | カバン | 包袋 |
| `cat_clothing_accessories` | watch | Accessories & Small Items | アクセサリー・小物 | 饰品小物 |
| `cat_clothing_underwear` | dry_cleaning | Underwear | 下着 | 内衣 |
| `cat_clothing_hair` | content_cut | Hair Salon & Barber | 美容院・理髪 | 美发理发 |
| `cat_clothing_cosmetics` | face_retouching_natural | Cosmetics | 化粧品 | 化妆品 |
| `cat_clothing_esthetic` | spa | Esthetic & Nails | エステ・ネイル | 美容护理/美甲 |
| `cat_clothing_cleaning` | local_laundry_service | Dry Cleaning | クリーニング | 清洗护理 |
| `cat_clothing_other` | more_horiz | Other Clothing & Beauty | その他衣服・美容 | 其他衣服美容 |

### Socializing (`cat_social`, #FF9800) — 5 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_social_drinks` | local_bar | Drinks & Gatherings | 飲み会 | 聚会饮酒 |
| `cat_social_gifts` | card_giftcard | Gifts | プレゼント | 礼物 |
| `cat_social_ceremonial` | celebration | Ceremonial Occasions | 冠婚葬祭・ご祝儀・香典 | 红白喜丧/礼金 |
| `cat_social_fees` | groups | Membership Fees | 会費・組合費 | 会费/组合费 |
| `cat_social_other` | more_horiz | Other Socializing | その他交際費 | 其他交际费 |

### Health & Medical (`cat_health`, #F44336) — 8 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_health_hospital` | local_hospital | Hospital | 病院 | 医院 |
| `cat_health_dental` | medical_services | Dental | 歯科 | 牙科 |
| `cat_health_medicine` | medication | Medicine | 薬代 | 药费 |
| `cat_health_supplements` | health_and_safety | Supplements | サプリメント | 保健品 |
| `cat_health_dock` | fact_check | Health Check-up | 人間ドック | 体检 |
| `cat_health_fitness` | fitness_center | Fitness | フィットネス | 健身 |
| `cat_health_massage` | self_improvement | Massage & Chiropractic | マッサージ・整体 | 按摩整骨 |
| `cat_health_other` | more_horiz | Other Health & Medical | その他健康・医療 | 其他健康医疗 |

### Education (`cat_education`, #3F51B5) — 10 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_education_tuition` | school | Tuition | 学費 | 学费 |
| `cat_education_cram_school` | edit_note | Cram School | 塾 | 补习班 |
| `cat_education_classes` | cast_for_education | Classes & Lessons | 習いごと | 兴趣课程 |
| `cat_education_textbooks` | auto_stories | Textbooks & Reference Books | 教科書・参考書 | 教材参考书 |
| `cat_education_entrance_exam` | quiz | Entrance Exam Fees | 受験料 | 考试费 |
| `cat_education_gakushi_hoken` | card_membership | Education Insurance | 学資保険 | 学资保险 |
| `cat_education_books` | menu_book | Books | 書籍 | 书籍 |
| `cat_education_newspapers` | newspaper | Newspapers & Magazines | 新聞・雑誌 | 报刊杂志 |
| `cat_education_seminar` | co_present | Seminars & Workshops | セミナー・講座 | 研讨会/讲座 |
| `cat_education_other` | more_horiz | Other Education | その他教育・教養 | 其他教育进修 |

### Utilities (`cat_utilities`, #FFC107) — 5 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_utilities_electricity` | bolt | Electricity | 電気代 | 电费 |
| `cat_utilities_gas` | local_fire_department | Gas | ガス代 | 燃气费 |
| `cat_utilities_water` | water_drop | Water | 水道代 | 水费 |
| `cat_utilities_kerosene` | propane_tank | Kerosene | 灯油 | 煤油 |
| `cat_utilities_other` | more_horiz | Other Utilities | その他水道・光熱費 | 其他水电燃气 |

### Communication (`cat_communication`, #00ACC1) — 8 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_communication_mobile` | smartphone | Mobile Phone | 携帯電話 | 手机通信 |
| `cat_communication_landline` | phone | Landline | 固定電話 | 固话 |
| `cat_communication_internet` | wifi | Internet | インターネット | 网络 |
| `cat_communication_nhk` | live_tv | NHK Reception Fee | NHK受信料 | NHK 收视费 |
| `cat_communication_broadcast` | tv | Broadcast Subscription | 放送視聴料 | 电视订阅 |
| `cat_communication_postage` | mail | Postage & Stamps | 切手・はがき | 邮票明信片 |
| `cat_communication_delivery` | local_shipping | Delivery & Shipping | 宅配便・運送 | 快递运输 |
| `cat_communication_other` | more_horiz | Other Communication | その他通信費 | 其他通讯费 |

### Housing (`cat_housing`, #795548) — 10 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_housing_rent` | apartment | Rent | 家賃 | 房租 |
| `cat_housing_mortgage` | real_estate_agent | Mortgage | 住宅ローン | 房贷 |
| `cat_housing_management` | corporate_fare | Management Fees & Reserve | 管理費・積立金 | 物业管理费 |
| `cat_housing_property_tax` | receipt_long | Property Tax | 固定資産税 | 固定资产税 |
| `cat_housing_insurance` | shield | Earthquake & Fire Insurance | 地震・火災保険 | 地震/火灾保险 |
| `cat_housing_furniture` | chair | Furniture | 家具 | 家具 |
| `cat_housing_appliances` | kitchen | Home Appliances | 家電 | 家电 |
| `cat_housing_renovation` | construction | Renovation | リフォーム | 装修 |
| `cat_housing_utilities_setup` | luggage | Moving & Initial Setup | 引越し・初期設備 | 搬家初期设置 |
| `cat_housing_other` | more_horiz | Other Housing | その他住宅 | 其他住宅 |

### Car & Motorcycle (`cat_car`, #455A64) — 10 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_car_fuel` | local_gas_station | Fuel | ガソリン | 油费 |
| `cat_car_parking` | local_parking | Parking | 駐車場 | 停车费 |
| `cat_car_toll` | toll | Highway & Toll | 高速・道路料金 | 高速过路费 |
| `cat_car_car_share` | car_rental | Car Share | カーシェア | 共享汽车 |
| `cat_car_loan` | payments | Auto Loan | 自動車ローン | 车贷 |
| `cat_car_insurance` | security | Auto Insurance | 自動車保険 | 车险 |
| `cat_car_tax` | receipt_long | Vehicle Tax | 自動車税 | 车船税 |
| `cat_car_maintenance` | build | Inspection & Maintenance | 車検・整備 | 年检保养 |
| `cat_car_driving_school` | drive_eta | Driving School | 免許教習 | 驾校 |
| `cat_car_other` | more_horiz | Other Car & Motorcycle | その他車・バイク | 其他车与摩托 |

### Taxes & Social Security (`cat_tax`, #5D4037) — 7 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_tax_income` | receipt | Income Tax & Resident Tax | 所得税・住民税 | 所得税/居民税 |
| `cat_tax_furusato` | favorite_border | Furusato Nozei | ふるさと納税 | 故乡税 |
| `cat_tax_consumption` | money_off | Consumption Tax | 消費税 | 消费税 |
| `cat_tax_pension` | elderly | Pension | 年金 | 年金 |
| `cat_tax_health_insurance` | health_and_safety | Health Insurance | 健康保険 | 健康保险 |
| `cat_tax_nursing_insurance` | accessible | Long-term Care Insurance | 介護保険 | 介护保险 |
| `cat_tax_other` | more_horiz | Other Taxes & Social Security | その他税・社会保障 | 其他税费 |

### Insurance (`cat_insurance`, #827717) — 5 L2

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_insurance_life` | favorite | Life Insurance | 生命保険 | 人寿保险 |
| `cat_insurance_medical` | medical_services | Medical Insurance | 医療保険 | 医疗保险 |
| `cat_insurance_cancer` | monitor_heart | Cancer Insurance | がん保険 | 癌症保险 |
| `cat_insurance_income` | work | Income Protection | 所得補償保険 | 所得补偿保险 |
| `cat_insurance_other` | more_horiz | Other Insurance | その他保険 | 其他保险 |

### Special Expenses (`cat_special`, #AD1457) — 8 L2

> **说明**: `cat_special` 承载低频高额支出，与 `cat_housing`/`cat_car`/`cat_hobbies` 有 intentional L2 重复。规则：**日常性**支出归原类目，**年度一次或突发**的大型支出归此类。

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_special_wedding` | favorite_border | Wedding | 結婚 | 结婚 |
| `cat_special_funeral` | church | Funeral | 葬儀 | 葬礼 |
| `cat_special_life_event` | celebration | Life Events (Seijin/Shichigosan/etc.) | 成人式・七五三・入学式 | 成人礼/七五三/入学式 |
| `cat_special_newyear` | celebration | New Year Traditions | 初詣・お年玉・年末年始 | 新年参拜/压岁钱 |
| `cat_special_fertility` | child_friendly | Fertility & Childbirth | 妊活・出産 | 备孕与生产 |
| `cat_special_nursing` | accessible | Nursing Care | 介護 | 护理 |
| `cat_special_movement` | luggage | Moving | 引越し | 搬家 |
| `cat_special_other` | more_horiz | Other Special Expenses | その他特別な支出 | 其他特别支出 |

### Allowance (`cat_allowance`, #8D6E63) — 4 L2 **[NEW L1]**

> **说明**: 从原 `cat_other_expense > cat_other_allowance` 提升为独立 L1，对齐日本家計簿伝統的"固定費 top-level"认知。默认归 **soul** 账本——零花钱本质是"可自由支配"的灵魂预算。

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_allowance_self` | person | Self Allowance | 本人お小遣い | 本人零花钱 |
| `cat_allowance_spouse` | people | Spouse Allowance | 配偶者お小遣い | 配偶零花钱 |
| `cat_allowance_kids` | child_care | Kids Allowance | 子どもお小遣い | 儿童零花钱 |
| `cat_allowance_other` | more_horiz | Other Allowance | その他お小遣い | 其他零花钱 |

### Asset Building (`cat_asset`, #1B5E20) — 8 L2 **[新增 L2 全部，现状为空]**

> **说明**: Home Pocket 独有 soul L1。**与日本主流 app 的差异点**：Zaim / MF ME 把投资/储蓄视为账户间转账不计入消费，Home Pocket 将其视为"自我投资型 soul 支出"。使用此类目时，用户同时在现金账户记账户间转账，是 intentional 的双重记录。

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_asset_nisa` | account_balance_wallet | NISA | NISA | NISA 账户 |
| `cat_asset_ideco` | elderly | iDeCo | iDeCo | iDeCo 年金 |
| `cat_asset_tsumitate` | trending_up | Regular Investment | 積立投資 | 定期投资 |
| `cat_asset_savings` | savings | Savings & Deposits | 貯蓄・定期預金 | 储蓄定期 |
| `cat_asset_stock` | show_chart | Stocks & Funds | 株・投資信託 | 股票信托 |
| `cat_asset_fx` | currency_exchange | Foreign Currency | 外貨預金 | 外汇存款 |
| `cat_asset_realestate` | apartment | Real Estate Investment | 不動産投資 | 不动产投资 |
| `cat_asset_other` | more_horiz | Other Asset Building | その他資産形成 | 其他资产配置 |

### Other Expenses (`cat_other_expense`, #607D8B) — 4 L2

> **说明**: 现状 8 个 L2 经清理剩 4 个：**移出**的有 `cat_other_advances`（立替金→转账原语）、`cat_other_business`（事業費→独立 Book）、`cat_other_debt`（返済→Liability 原语）、`cat_other_allowance`（お小遣い→提升为 L1）。原 `cat_uncategorized` L1 合并到 `cat_other_unclassified` L2。

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_other_remittance` | send | Remittance | 仕送り | 汇款/赡养 |
| `cat_other_misc` | category | Miscellaneous | 雑費 | 杂费 |
| `cat_other_unclassified` | help_outline | Unclassified / Unknown | 使途不明金・未分類 | 未分类/去向不明 |
| `cat_other_other` | more_horiz | Other | その他 | 其他 |

---

## L2 Ledger Overrides

大部分 L2 继承 L1 ledger 默认值。以下 L2 建议 **覆盖** L1 默认，以更精确地对齐"生存/灵魂"双账本哲学（需要 `category_ledger_configs_table` seed 层追加覆盖记录）：

| L2 ID | L1 默认 | 覆盖为 | 理由 |
|-------|--------|--------|------|
| `cat_clothing_clothes` | soul | **survival** | 衣服是基础必需品 |
| `cat_clothing_shoes` | soul | **survival** | 鞋履是基础必需品 |
| `cat_clothing_underwear` | soul | **survival** | 内衣是基础必需品 |
| `cat_clothing_cleaning` | soul | **survival** | 清洗护理是维护必需 |
| `cat_social_drinks` | survival | **soul** | 飲み会 是社交享受型消费 |
| `cat_social_gifts` | survival | **soul** | 赠礼是情感表达型消费 |
| `cat_special_wedding` | survival | **soul** | 结婚仪式是人生里程碑型消费 |
| `cat_special_movement` | survival | **soul** | 主动搬家（非被迫）是生活升级型 |
| `cat_special_newyear` | survival | **soul** | 年末年始传统仪式感消费 |

未列出的 L2 继承 L1 默认值（无需覆盖记录）。

---

## Summary

| Type | Count |
|------|-------|
| Expense L1 | 19 |
| Expense L2 | 138 |
| **Total** | **157** |

### Counts per L1

| L1 | Count | L1 | Count |
|----|-------|----|-------|
| `cat_food` | 6 | `cat_housing` | 10 |
| `cat_daily` | 6 | `cat_car` | 10 |
| `cat_pet` | 7 | `cat_tax` | 7 |
| `cat_transport` | 7 | `cat_insurance` | 5 |
| `cat_hobbies` | 10 | `cat_special` | 8 |
| `cat_clothing` | 10 | `cat_allowance` | 4 |
| `cat_social` | 5 | `cat_asset` | 8 |
| `cat_health` | 8 | `cat_other_expense` | 4 |
| `cat_education` | 10 | | |
| `cat_utilities` | 5 | | |
| `cat_communication` | 8 | | |

**Note**: 本文档**仅为推荐方案**，不是已落地的 seed 数据。实施路径见 `categories_japan_proposal.md` §7（代码修改范围）与 §8（开放争议点）。实施时需同步更新 `lib/shared/constants/default_categories.dart`、`lib/l10n/app_{ja,zh,en}.arb`、以及用户数据迁移脚本。
