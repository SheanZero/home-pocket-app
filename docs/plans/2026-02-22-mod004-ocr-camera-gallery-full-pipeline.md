I'm using the writing-plans skill to create the implementation plan.

# MOD-004 OCR Camera + Gallery + Full Pipeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于 `docs/arch/02-module-specs/MOD-004_OCR.md` 和现有 `lib/` 代码，落地 OCR 全链路：扫描页支持实时拍摄与相册读取，完成 OCR 识别、商家匹配、图片加密存储、确认页预填和交易保存。

**Architecture:** 保持当前仓库既有模式：Use Case 放在 `lib/application/`，技术能力放在 `lib/infrastructure/`，数据落库放在 `lib/data/`，UI 放在 `lib/features/accounting/presentation/`。扫描页使用 `camera` 实时预览 + `image_picker` 相册读取；OCR 首版 Android/iOS 统一使用 `google_mlkit_text_recognition`；图片加密新增 AES-GCM 文件服务并通过 `photoHash` 串联交易。

**Tech Stack:** Flutter, Riverpod (`@riverpod`), Drift, camera, image_picker, google_mlkit_text_recognition, image, cryptography (AES-GCM), sha256, flutter_test/mocktail.

---

**Plan document target path:** `docs/plans/2026-02-22-mod004-ocr-camera-gallery-full-pipeline.md`  
**Required execution skills:** `@test-driven-development`, `@verification-before-completion`, `@requesting-code-review`

## Scope Lock (已确认)
1. 范围：`UI + OCR 全链路`
2. iOS OCR：首版统一 ML Kit（不做 Vision MethodChannel）
3. 相机 UX：首版即支持实时预览与闪光灯切换
4. 商家库：首版 `120+` 可扩展映射（结构支持后续扩充到 500+）

## Public API / Interface Changes
1. `CreateTransactionParams` 新增 `String? photoHash`
2. `TransactionConfirmScreen` 新增可选初始参数：`initialMerchant`, `initialMemo`, `photoHash`
3. 新增 `ScanReceiptUseCase.execute({required XFile imageFile, required ReceiptImageSource source})`
4. 新增 `SaveReceiptPhotoUseCase.execute(XFile imageFile)` 返回 `Result<String>`（`photoHash`）
5. 新增 `OCRService`, `MlkitOCRService`, `ImagePreprocessor`, `MerchantDatabase`
6. 新增 `ReceiptPhotos` Drift 表 + `ReceiptPhotoDao` + `ReceiptPhotoRepository`
7. `AppDatabase.schemaVersion` 从 `5` 升到 `6`，新增 `receipt_photos` 表迁移

### Task 1: Receipt Parser (金额/日期/商家) 纯逻辑落地

**Files:**  
Create: `lib/application/ocr/models/parsed_receipt_data.dart`  
Create: `lib/application/ocr/receipt_parser.dart`  
Test: `test/unit/application/ocr/receipt_parser_test.dart`

**Step 1: Write the failing test**
```dart
test('extracts total amount from 合計 line', () {
  const text = 'セブンイレブン\n合計 ¥1,280\n2026/02/22';
  final parser = ReceiptParser();
  final parsed = parser.parse(text);
  expect(parsed.amount, 1280);
  expect(parsed.merchant, 'セブンイレブン');
  expect(parsed.date, DateTime(2026, 2, 22));
});
```

**Step 2: Run test to verify it fails**  
Run: `flutter test test/unit/application/ocr/receipt_parser_test.dart --plain-name "extracts total amount from 合計 line"`  
Expected: FAIL with `Undefined class 'ReceiptParser'` (or file missing)

**Step 3: Write minimal implementation**
```dart
class ReceiptParser {
  ParsedReceiptData parse(String text) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return ParsedReceiptData(
      amount: _extractAmount(lines),
      date: _extractDate(text),
      merchant: _extractMerchant(lines),
    );
  }
}
```

**Step 4: Run test to verify it passes**  
Run: `flutter test test/unit/application/ocr/receipt_parser_test.dart`  
Expected: PASS

**Step 5: Commit**
```bash
git add test/unit/application/ocr/receipt_parser_test.dart lib/application/ocr/models/parsed_receipt_data.dart lib/application/ocr/receipt_parser.dart
git commit -m "feat(ocr): add receipt parser for amount date merchant extraction"
```

### Task 2: Merchant Database (120+ 可扩展匹配)

**Files:**  
Create: `lib/infrastructure/ml/merchant_database.dart`  
Test: `test/unit/infrastructure/ml/merchant_database_test.dart`

**Step 1: Write the failing test**
```dart
test('matches alias and returns category id', () {
  final db = MerchantDatabase();
  final result = db.findBestMatch('セブン');
  expect(result?.categoryId, 'cat_food_groceries');
  expect(result?.confidence, greaterThan(0.7));
});
```

**Step 2: Run test to verify it fails**  
Run: `flutter test test/unit/infrastructure/ml/merchant_database_test.dart`  
Expected: FAIL with missing class/method

**Step 3: Write minimal implementation**
```dart
class MerchantDatabase {
  MerchantMatchResult? findBestMatch(String merchantText) {
    final normalized = merchantText.toLowerCase();
    // exact > alias > contains
    // initial dataset: 120+ entries grouped by category
  }
}
```

**Step 4: Run test to verify it passes**  
Run: `flutter test test/unit/infrastructure/ml/merchant_database_test.dart`  
Expected: PASS

**Step 5: Commit**
```bash
git add test/unit/infrastructure/ml/merchant_database_test.dart lib/infrastructure/ml/merchant_database.dart
git commit -m "feat(ocr): add merchant database matcher with extensible mapping"
```

### Task 3: AES-GCM Photo Encryption Service

**Files:**  
Create: `lib/infrastructure/crypto/services/photo_encryption_service.dart`  
Modify: `lib/infrastructure/crypto/providers.dart`  
Test: `test/infrastructure/crypto/services/photo_encryption_service_test.dart`

**Step 1: Write the failing test**
```dart
test('encrypt/decrypt photo bytes roundtrip', () async {
  final service = PhotoEncryptionService(masterKeyRepository: fakeMasterRepo);
  final plain = Uint8List.fromList([1, 2, 3, 4, 5]);
  final encrypted = await service.encrypt(plain);
  final decrypted = await service.decrypt(encrypted);
  expect(decrypted, plain);
});
```

**Step 2: Run test to verify it fails**  
Run: `flutter test test/infrastructure/crypto/services/photo_encryption_service_test.dart`  
Expected: FAIL with missing service/provider

**Step 3: Write minimal implementation**
```dart
class PhotoEncryptionService {
  final MasterKeyRepository _masterKeyRepository;
  final _algorithm = AesGcm.with256bits();

  Future<Uint8List> encrypt(Uint8List plain) async { /* nonce + mac + cipher */ }
  Future<Uint8List> decrypt(Uint8List encrypted) async { /* parse + verify */ }
}
```

**Step 4: Run test to verify it passes**  
Run: `flutter test test/infrastructure/crypto/services/photo_encryption_service_test.dart`  
Expected: PASS

**Step 5: Commit**
```bash
git add test/infrastructure/crypto/services/photo_encryption_service_test.dart lib/infrastructure/crypto/services/photo_encryption_service.dart lib/infrastructure/crypto/providers.dart
git commit -m "feat(crypto): add aes-gcm photo encryption service"
```

### Task 4: Receipt Photo Data Layer (Drift + DAO + Repository)

**Files:**  
Create: `lib/data/tables/receipt_photos_table.dart`  
Create: `lib/data/daos/receipt_photo_dao.dart`  
Create: `lib/features/accounting/domain/repositories/receipt_photo_repository.dart`  
Create: `lib/data/repositories/receipt_photo_repository_impl.dart`  
Modify: `lib/data/app_database.dart`  
Modify: `lib/features/accounting/presentation/providers/repository_providers.dart`  
Test: `test/unit/data/daos/receipt_photo_dao_test.dart`  
Test: `test/unit/data/repositories/receipt_photo_repository_impl_test.dart`

**Step 1: Write the failing DAO/repository tests**
```dart
test('upsert and find by hash', () async {
  await dao.upsertPhoto(hash: 'h1', encryptedPath: '/tmp/h1.enc', createdAt: now);
  final row = await dao.findByHash('h1');
  expect(row?.encryptedPath, '/tmp/h1.enc');
});
```

**Step 2: Run test to verify it fails**  
Run: `flutter test test/unit/data/daos/receipt_photo_dao_test.dart`  
Expected: FAIL with missing table/dao

**Step 3: Write minimal implementation**
```dart
class ReceiptPhotos extends Table {
  TextColumn get hash => text()();
  TextColumn get encryptedPath => text()();
  DateTimeColumn get createdAt => dateTime()();
  @override Set<Column> get primaryKey => {hash};
  List<TableIndex> get customIndices => [TableIndex(name: 'idx_receipt_photos_created_at', columns: {#createdAt})];
}
```

**Step 4: Generate and run tests**  
Run: `flutter pub run build_runner build --delete-conflicting-outputs`  
Run: `flutter test test/unit/data/daos/receipt_photo_dao_test.dart test/unit/data/repositories/receipt_photo_repository_impl_test.dart`  
Expected: PASS

**Step 5: Commit**
```bash
git add lib/data/tables/receipt_photos_table.dart lib/data/daos/receipt_photo_dao.dart lib/features/accounting/domain/repositories/receipt_photo_repository.dart lib/data/repositories/receipt_photo_repository_impl.dart lib/data/app_database.dart lib/features/accounting/presentation/providers/repository_providers.dart test/unit/data/daos/receipt_photo_dao_test.dart test/unit/data/repositories/receipt_photo_repository_impl_test.dart
git commit -m "feat(data): add receipt photo persistence layer"
```

### Task 5: SaveReceiptPhotoUseCase (hash命名 + 去重 + 落库)

**Files:**  
Create: `lib/application/ocr/save_receipt_photo_use_case.dart`  
Create: `lib/features/accounting/presentation/providers/ocr_use_case_providers.dart`  
Test: `test/unit/application/ocr/save_receipt_photo_use_case_test.dart`

**Step 1: Write the failing use case tests**
```dart
test('returns same hash when identical image is saved twice', () async {
  final hash1 = (await useCase.execute(xfile)).data!;
  final hash2 = (await useCase.execute(xfile)).data!;
  expect(hash1, hash2);
});
```

**Step 2: Run test to verify it fails**  
Run: `flutter test test/unit/application/ocr/save_receipt_photo_use_case_test.dart`  
Expected: FAIL with missing use case

**Step 3: Write minimal implementation**
```dart
class SaveReceiptPhotoUseCase {
  Future<Result<String>> execute(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    // if exists -> return hash
    // encrypt with PhotoEncryptionService
    // write {appDocDir}/receipts/{hash}.enc
    // upsert metadata
    return Result.success(hash);
  }
}
```

**Step 4: Run test to verify it passes**  
Run: `flutter test test/unit/application/ocr/save_receipt_photo_use_case_test.dart`  
Expected: PASS

**Step 5: Commit**
```bash
git add lib/application/ocr/save_receipt_photo_use_case.dart lib/features/accounting/presentation/providers/ocr_use_case_providers.dart test/unit/application/ocr/save_receipt_photo_use_case_test.dart
git commit -m "feat(ocr): add save receipt photo use case with dedup hash"
```

### Task 6: OCR Infra + ScanReceiptUseCase Orchestration

**Files:**  
Create: `lib/infrastructure/ml/ocr/ocr_service.dart`  
Create: `lib/infrastructure/ml/ocr/mlkit_ocr_service.dart`  
Create: `lib/infrastructure/ml/image_preprocessor.dart`  
Create: `lib/application/ocr/models/scanned_receipt_result.dart`  
Create: `lib/application/ocr/scan_receipt_use_case.dart`  
Modify: `pubspec.yaml`  
Test: `test/unit/application/ocr/scan_receipt_use_case_test.dart`  
Test: `test/unit/infrastructure/ml/ocr/mlkit_ocr_service_test.dart`  
Test: `test/unit/infrastructure/ml/image_preprocessor_test.dart`

**Step 1: Write failing orchestration tests**
```dart
test('orchestrates preprocess -> ocr -> parse -> merchant -> save photo', () async {
  final result = await useCase.execute(imageFile: fakeXFile, source: ReceiptImageSource.gallery);
  expect(result.isSuccess, isTrue);
  expect(result.data!.amount, 1280);
  expect(result.data!.photoHash, isNotNull);
});
```

**Step 2: Run test to verify it fails**  
Run: `flutter test test/unit/application/ocr/scan_receipt_use_case_test.dart`  
Expected: FAIL with missing use case/dependencies

**Step 3: Write minimal implementation and add dependencies**
```yaml
dependencies:
  camera: ^0.11.0+2
  image_picker: ^1.1.2
  google_mlkit_text_recognition: ^0.15.0
  image: ^4.5.4
```
```dart
class ScanReceiptUseCase {
  Future<Result<ScannedReceiptResult>> execute({
    required XFile imageFile,
    required ReceiptImageSource source,
  }) async { /* orchestrate pipeline */ }
}
```

**Step 4: Install deps and run tests**  
Run: `flutter pub get`  
Run: `flutter test test/unit/infrastructure/ml/ocr/mlkit_ocr_service_test.dart test/unit/infrastructure/ml/image_preprocessor_test.dart test/unit/application/ocr/scan_receipt_use_case_test.dart`  
Expected: PASS

**Step 5: Commit**
```bash
git add pubspec.yaml lib/infrastructure/ml/ocr/ocr_service.dart lib/infrastructure/ml/ocr/mlkit_ocr_service.dart lib/infrastructure/ml/image_preprocessor.dart lib/application/ocr/models/scanned_receipt_result.dart lib/application/ocr/scan_receipt_use_case.dart test/unit/infrastructure/ml/ocr/mlkit_ocr_service_test.dart test/unit/infrastructure/ml/image_preprocessor_test.dart test/unit/application/ocr/scan_receipt_use_case_test.dart
git commit -m "feat(ocr): add mlkit ocr pipeline orchestration"
```

### Task 7: photoHash/merchant 贯通到确认页与交易保存

**Files:**  
Modify: `lib/application/accounting/create_transaction_use_case.dart`  
Modify: `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`  
Test: `test/unit/application/accounting/create_transaction_use_case_test.dart`  
Test: `test/widget/features/accounting/presentation/screens/transaction_confirm_screen_test.dart`

**Step 1: Write failing tests**
```dart
test('passes photoHash to created transaction', () async {
  final result = await useCase.execute(CreateTransactionParams(
    bookId: 'book_001',
    amount: 1000,
    type: TransactionType.expense,
    categoryId: 'cat_food',
    photoHash: 'hash_123',
  ));
  expect(result.data!.photoHash, 'hash_123');
});
```

**Step 2: Run test to verify it fails**  
Run: `flutter test test/unit/application/accounting/create_transaction_use_case_test.dart --plain-name "passes photoHash to created transaction"`  
Expected: FAIL with missing parameter/assertion

**Step 3: Write minimal implementation**
```dart
class CreateTransactionParams {
  final String? photoHash;
}
final transaction = Transaction(
  // ...
  photoHash: params.photoHash,
);
```
```dart
class TransactionConfirmScreen extends ConsumerStatefulWidget {
  final String? initialMerchant;
  final String? initialMemo;
  final String? photoHash;
}
```

**Step 4: Run tests to verify they pass**  
Run: `flutter test test/unit/application/accounting/create_transaction_use_case_test.dart test/widget/features/accounting/presentation/screens/transaction_confirm_screen_test.dart`  
Expected: PASS

**Step 5: Commit**
```bash
git add lib/application/accounting/create_transaction_use_case.dart lib/features/accounting/presentation/screens/transaction_confirm_screen.dart test/unit/application/accounting/create_transaction_use_case_test.dart test/widget/features/accounting/presentation/screens/transaction_confirm_screen_test.dart
git commit -m "feat(accounting): wire photo hash and ocr initial fields to confirm flow"
```

### Task 8: OcrScannerScreen 实时相机 + 相册 + 处理态 + 导航

**Files:**  
Create: `lib/infrastructure/media/receipt_camera_facade.dart`  
Create: `lib/infrastructure/media/camera_receipt_camera_facade.dart`  
Create: `lib/infrastructure/media/gallery_picker_service.dart`  
Create: `lib/infrastructure/media/providers.dart`  
Modify: `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart`  
Modify: `lib/features/accounting/presentation/providers/ocr_use_case_providers.dart`  
Test: `test/widget/features/accounting/presentation/screens/ocr_scanner_screen_test.dart`

**Step 1: Write failing widget tests**
```dart
testWidgets('tap shutter triggers scan and navigates to confirm', (tester) async {
  // fake camera facade returns fake XFile
  // fake scan use case returns parsed result
  // expect TransactionConfirmScreen pushed
});
```

**Step 2: Run test to verify it fails**  
Run: `flutter test test/widget/features/accounting/presentation/screens/ocr_scanner_screen_test.dart`  
Expected: FAIL with current stub behavior (`Navigator.pop`)

**Step 3: Write minimal implementation**
```dart
class OcrScannerScreen extends ConsumerStatefulWidget { /* ... */ }
```
```dart
Future<void> _onShutter() async {
  final xfile = await _camera.capture();
  if (xfile == null) return;
  await _scanAndNavigate(xfile, ReceiptImageSource.camera);
}
```
```dart
Future<void> _onGallery() async {
  final xfile = await _gallery.pickImage();
  if (xfile == null) return;
  await _scanAndNavigate(xfile, ReceiptImageSource.gallery);
}
```

**Step 4: Run test to verify it passes**  
Run: `flutter test test/widget/features/accounting/presentation/screens/ocr_scanner_screen_test.dart`  
Expected: PASS

**Step 5: Commit**
```bash
git add lib/infrastructure/media/receipt_camera_facade.dart lib/infrastructure/media/camera_receipt_camera_facade.dart lib/infrastructure/media/gallery_picker_service.dart lib/infrastructure/media/providers.dart lib/features/accounting/presentation/screens/ocr_scanner_screen.dart lib/features/accounting/presentation/providers/ocr_use_case_providers.dart test/widget/features/accounting/presentation/screens/ocr_scanner_screen_test.dart
git commit -m "feat(ocr-ui): enable live camera capture gallery import and scan navigation"
```

### Task 9: 平台权限 + l10n + 最终验证

**Files:**  
Modify: `ios/Runner/Info.plist`  
Modify: `android/app/src/main/AndroidManifest.xml`  
Modify: `lib/l10n/app_en.arb`  
Modify: `lib/l10n/app_ja.arb`  
Modify: `lib/l10n/app_zh.arb`  
Create: `integration_test/ocr_flow_test.dart`

**Step 1: Write failing integration test (fake pipeline)**
```dart
testWidgets('ocr flow camera/gallery -> confirm -> save', (tester) async {
  // launch app with provider overrides
  // open OCR screen
  // simulate scan success
  // save transaction and verify created row contains photoHash
});
```

**Step 2: Run test to verify it fails**  
Run: `flutter test integration_test/ocr_flow_test.dart`  
Expected: FAIL with missing permissions/keys/wiring

**Step 3: Write minimal implementation and localization updates**
```xml
<uses-permission android:name="android.permission.CAMERA" />
```
```xml
<key>NSCameraUsageDescription</key>
<string>用于拍摄票据进行OCR识别</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>用于选择票据图片进行OCR识别</string>
```
```json
"ocrProcessing": "Processing receipt...",
"ocrScanFailed": "Could not recognize receipt. Please edit manually."
```

**Step 4: Regenerate and run full verification**  
Run: `flutter gen-l10n`  
Run: `flutter pub run build_runner build --delete-conflicting-outputs`  
Run: `dart format .`  
Run: `flutter analyze`  
Run: `flutter test`  
Expected: 全部通过，`flutter analyze` 0 issues

**Step 5: Commit**
```bash
git add ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb integration_test/ocr_flow_test.dart
git commit -m "feat(ocr): finalize platform permissions i18n and end-to-end tests"
```

## Test Cases and Acceptance Scenarios
1. Parser 能识别 `合計`, `TOTAL`, `円`, `¥1,280` 与常见日期格式。
2. 商家匹配按优先级返回 `categoryId + confidence`，未知商家返回 null。
3. 照片加密服务保证 roundtrip 可逆，篡改密文时报错。
4. 相同图片重复扫描返回相同 `photoHash`，不会重复写入元数据。
5. 扫描用例在 OCR 部分失败时返回可编辑降级结果，不崩溃。
6. 扫描页支持：实时预览、拍照、相册、闪光灯切换、处理中遮罩。
7. 跳转确认页后：金额/日期/商家已预填，可编辑，保存后交易含 `photoHash`。
8. 三语言文案完整，新增文案均通过 `S.of(context)` 读取。
9. `flutter analyze` 为 0，`flutter test` 全绿。

## Assumptions and Defaults
1. 保持现有项目分层现实：OCR Use Case 在 `lib/application/ocr/`，不做全局架构重构。
2. iOS 首版不实现 Vision；统一使用 ML Kit，后续可在 `OCRService` 层替换。
3. 商家库首版目标 `120+` 高频映射，采用可扩展数据结构，后续增量到 500+。
4. 无法识别金额时确认页默认 `0` 并强制用户修正后保存；日期默认 `DateTime.now()`。
5. 类别回退默认 `cat_other_expense`（若不存在则回退首个激活的 L1 支出分类）。
6. 不提交 `.g.dart`、`.freezed.dart` 生成文件；执行阶段本地生成用于编译与测试。

