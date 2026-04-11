# Default Categories Reference

> This document reflects v14 seed state (schema version 14, after migration).
> For the research/proposal history, see `categories_recommended.md` and `categories_japan_proposal.md`.

Source: `lib/shared/constants/default_categories.dart` + `lib/infrastructure/category/category_service.dart`

---

## Expense Categories L1

| ID | JA Name | ZH Name | EN Name | Icon | Color | Ledger |
|----|---------|---------|---------|------|-------|--------|
| `cat_food` | 食費 | 食费 | Food | restaurant | #FF5722 | survival |
| `cat_daily` | 日用品 | 日用品 | Daily Necessities | local_mall | #00BCD4 | survival |
| `cat_pet` | ペット | 宠物 | Pets | pets | #7CB342 | soul |
| `cat_transport` | 交通費 | 交通费 | Transport | directions_bus | #2196F3 | survival |
| `cat_hobbies` | 趣味・娯楽 | 兴趣娱乐 | Hobbies & Entertainment | sports_esports | #9C27B0 | soul |
| `cat_clothing` | 衣服・美容 | 衣服美容 | Clothing & Beauty | checkroom | #E91E63 | soul |
| `cat_social` | 交際費 | 交际费 | Socializing | people | #FF9800 | survival |
| `cat_health` | 健康・医療 | 健康医疗 | Health & Medical | local_hospital | #F44336 | survival |
| `cat_education` | 教育・教養 | 教育进修 | Education | school | #3F51B5 | soul |
| `cat_utilities` | 水道・光熱費 | 水电燃气 | Utilities | flash_on | #FFC107 | survival |
| `cat_communication` | 通信費 | 通讯费 | Communication | phone_iphone | #00ACC1 | survival |
| `cat_housing` | 住宅 | 住宅 | Housing | home | #795548 | survival |
| `cat_car` | 車・バイク | 车与摩托 | Car & Motorcycle | directions_car | #455A64 | survival |
| `cat_tax` | 税・社会保障 | 税费与社会保障 | Taxes & Social Security | account_balance | #5D4037 | survival |
| `cat_insurance` | 保険 | 保险 | Insurance | security | #827717 | survival |
| `cat_special` | 特別な支出 | 特别支出 | Special Expenses | star | #AD1457 | survival |
| `cat_allowance` | お小遣い | 零花钱 | Allowance | wallet | #8D6E63 | soul |
| `cat_asset` | 資産形成 | 资产配置 | Asset Building | savings | #1B5E20 | soul |
| `cat_other_expense` | その他 | 其他 | Other | more_horiz | #607D8B | survival |

---

## Income Categories — L1

| ID | Icon | Color | EN | JA | ZH |
|----|------|-------|----|----|-----|
| `cat_salary` | account_balance | #4CAF50 | Salary | 給料 | 工资 |
| `cat_bonus` | stars | #FFC107 | Bonus | 賞与 | 奖金 |
| `cat_investment` | trending_up | #009688 | Investment Returns | 投資収益 | 投资收益 |
| `cat_other_income` | attach_money | #8BC34A | Other Income | その他収入 | 其他收入 |

---

## Expense Categories — L2

### Food (`cat_food`, #FF5722)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_food_groceries` | shopping_basket | Groceries | 食料品 | 食材杂货 |
| `cat_food_dining_out` | restaurant_menu | Dining Out | 外食 | 外出就餐 |
| `cat_food_cafe` | local_cafe | Cafe | カフェ | 咖啡馆 |
| `cat_food_delivery` | delivery_dining | Delivery | デリバリー | 外卖 |
| `cat_food_drinks` | local_bar | Drinks & Alcohol | 飲料・酒類 | 饮料酒类 |
| `cat_food_other` | more_horiz | Other Food | その他食費 | 其他食费 |

### Daily Necessities (`cat_daily`, #00BCD4)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_daily_household` | cleaning_services | Household Goods | 生活雑貨 | 生活杂货 |
| `cat_daily_drugstore` | local_pharmacy | Drugstore | ドラッグストア | 药妆店 |
| `cat_daily_children` | child_care | Child-related | 子ども関連 | 儿童相关 |
| `cat_daily_tobacco` | smoking_rooms | Tobacco | タバコ | 烟草 |
| `cat_daily_subscription` | subscriptions | Daily Subscriptions | サブスク雑貨 | 日用品订阅 |
| `cat_daily_other` | more_horiz | Other Daily Necessities | その他日用品 | 其他日用品 |

### Pets (`cat_pet`, #7CB342)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_pet_food` | set_meal | Pet Food | ペットフード | 宠物食品 |
| `cat_pet_supplies` | inventory_2 | Supplies & Toys | ペット用品・おもちゃ | 宠物用品/玩具 |
| `cat_pet_medical` | healing | Vet & Medical | 病院・医療費 | 宠物医疗 |
| `cat_pet_grooming` | shower | Grooming & Salon | トリミング | 美容护理 |
| `cat_pet_insurance` | verified_user | Pet Insurance | ペット保険 | 宠物保险 |
| `cat_pet_hotel` | hotel | Boarding & Pet Sitter | ペットホテル・預かり | 宠物寄养 |
| `cat_pet_other` | more_horiz | Other Pet Expenses | その他ペット | 其他宠物 |

### Transport (`cat_transport`, #2196F3)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_transport_train` | train | Train | 電車 | 电车 |
| `cat_transport_shinkansen` | directions_railway | Shinkansen | 新幹線 | 新干线 |
| `cat_transport_bus` | directions_bus | Bus | バス | 公交 |
| `cat_transport_highway_bus` | airport_shuttle | Highway Bus | 高速バス | 高速巴士 |
| `cat_transport_taxi` | local_taxi | Taxi | タクシー | 出租车 |
| `cat_transport_flights` | flight | Flights | 飛行機 | 飞机 |
| `cat_transport_other` | more_horiz | Other Transport | その他交通 | 其他交通 |

### Hobbies & Entertainment (`cat_hobbies`, #9C27B0)

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

### Clothing & Beauty (`cat_clothing`, #E91E63)

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

### Socializing (`cat_social`, #FF9800)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_social_drinks` | local_bar | Drinks & Gatherings | 飲み会 | 聚会饮酒 |
| `cat_social_gifts` | card_giftcard | Gifts | プレゼント | 礼物 |
| `cat_social_ceremonial` | celebration | Ceremonial Occasions | 冠婚葬祭・ご祝儀・香典 | 红白喜丧/礼金 |
| `cat_social_fees` | groups | Membership Fees | 会費・組合費 | 会费/组合费 |
| `cat_social_other` | more_horiz | Other Socializing | その他交際費 | 其他交际费 |

### Health & Medical (`cat_health`, #F44336)

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

### Education (`cat_education`, #3F51B5)

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

### Utilities (`cat_utilities`, #FFC107)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_utilities_electricity` | bolt | Electricity | 電気代 | 电费 |
| `cat_utilities_gas` | local_fire_department | Gas | ガス代 | 燃气费 |
| `cat_utilities_water` | water_drop | Water | 水道代 | 水费 |
| `cat_utilities_kerosene` | propane_tank | Kerosene | 灯油 | 煤油 |
| `cat_utilities_other` | more_horiz | Other Utilities | その他水道・光熱費 | 其他水电燃气 |

### Communication (`cat_communication`, #00ACC1)

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

### Housing (`cat_housing`, #795548)

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

### Car & Motorcycle (`cat_car`, #455A64)

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

### Taxes & Social Security (`cat_tax`, #5D4037)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_tax_income` | receipt | Income Tax & Resident Tax | 所得税・住民税 | 所得税/居民税 |
| `cat_tax_furusato` | favorite_border | Furusato Nozei | ふるさと納税 | 故乡税 |
| `cat_tax_consumption` | money_off | Consumption Tax | 消費税 | 消费税 |
| `cat_tax_pension` | elderly | Pension | 年金 | 年金 |
| `cat_tax_health_insurance` | health_and_safety | Health Insurance | 健康保険 | 健康保险 |
| `cat_tax_nursing_insurance` | accessible | Long-term Care Insurance | 介護保険 | 介护保险 |
| `cat_tax_other` | more_horiz | Other Taxes & Social Security | その他税・社会保障 | 其他税费 |

### Insurance (`cat_insurance`, #827717)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_insurance_life` | favorite | Life Insurance | 生命保険 | 人寿保险 |
| `cat_insurance_medical` | medical_services | Medical Insurance | 医療保険 | 医疗保险 |
| `cat_insurance_cancer` | monitor_heart | Cancer Insurance | がん保険 | 癌症保险 |
| `cat_insurance_income` | work | Income Protection | 所得補償保険 | 所得补偿保险 |
| `cat_insurance_other` | more_horiz | Other Insurance | その他保険 | 其他保险 |

### Special Expenses (`cat_special`, #AD1457)

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

### Allowance (`cat_allowance`, #8D6E63)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_allowance_self` | person | Self Allowance | 本人お小遣い | 本人零花钱 |
| `cat_allowance_spouse` | people | Spouse Allowance | 配偶者お小遣い | 配偶零花钱 |
| `cat_allowance_kids` | child_care | Kids Allowance | 子どもお小遣い | 儿童零花钱 |
| `cat_allowance_other` | more_horiz | Other Allowance | その他お小遣い | 其他零花钱 |

### Asset Building (`cat_asset`, #1B5E20)

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

### Other Expenses (`cat_other_expense`, #607D8B)

| ID | Icon | EN | JA | ZH |
|----|------|----|----|-----|
| `cat_other_remittance` | send | Remittance | 仕送り | 汇款/赡养 |
| `cat_other_misc` | category | Miscellaneous | 雑費 | 杂费 |
| `cat_other_unclassified` | help_outline | Unclassified / Unknown | 使途不明金・未分類 | 未分类/去向不明 |
| `cat_other_other` | more_horiz | Other | その他 | 其他 |

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
