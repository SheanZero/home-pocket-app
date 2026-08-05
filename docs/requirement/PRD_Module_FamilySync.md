# PRD - 家庭同步模块

**模块ID:** MOD-004
**模块名称:** 家庭同步模块
**版本:** 1.0
**创建日期:** 2026年2月3日
**优先级:** P0（MVP必备）
**预估工时:** 12天

---

## 1. 模块概述

### 1.1 功能定义

家庭同步模块实现设备间的安全数据同步,支持夫妻/情侣共享账本。包括:

- **设备配对（B01）:** QR码面对面配对（MVP）、远程短码配对（V1.0）
- **数据同步（B03）:** 本地直连同步、冲突解决、离线队列
- **家庭内部转账（B05）:** 两阶段提交、状态追踪
- **伴侣隐私保护:** 灵魂账户明细隐藏、私密交易标记
- **同步协议:** 使用Yjs CRDT库（不自研）

**核心价值主张:**
夫妻共同管理家庭开支,同时保护个人隐私。通过E2EE和本地优先架构,实现"共享透明"与"个人空间"的平衡。

### 1.2 用户场景与痛点

**用户画像:**
- 田中和美惠（35岁夫妇）
- 共同承担房租、水电等家庭开支
- 各有爱好预算（田中买高达,美惠买化妆品）

**痛点:**
1. **记账不同步:** 田中在手机上记了账,美惠看不到,导致重复记账或遗漏
2. **隐私冲突:** 传统家庭账本要求完全透明,但个人爱好消费不想让对方知道细节
3. **转账麻烦:** 微信转账后还要手动在记账应用中记录,容易忘记
4. **离线问题:** 出门在外没有网络时无法同步

**Happy Pocket解决方案:**
- 本地直连同步（蓝牙/NFC/WiFi）,无需服务器
- 灵魂账户保护隐私（只显示进度,不显示明细）
- 家庭内部转账自动创建双方记录
- 离线队列,上线后自动同步

### 1.3 与其他模块的依赖关系

**前置依赖:**
- MOD-006 安全与隐私（需要密钥交换）
- MOD-001 基础记账（需要交易数据）

**被依赖:**
- MOD-007 数据分析（家庭报表）
- MOD-003 双轨账本（伴侣隐私设置）

---

## 2. 详细功能规格

### 2.1 B01: 设备配对

#### 2.1.1 方式一：面对面QR码（MVP实现）

**配对流程:**

```
Device A (发起方)                Device B (接收方)
     │                               │
     ├─ 生成QR码 ─────────────────►  │
     │  (含公钥+book_id+nonce)       │ 扫描QR码
     │                               │
     │◄────── 握手请求 ──────────────┤
     │  (B的公钥+签名)               │
     │                               │
     ├─ 验证签名 ─────────────────►  │
     │  验证B的身份                  │
     │                               │
     ├─ 确认配对 ─────────────────►  │
     │  (A的签名)                    │
     │                               │
  [保存伴侣公钥]                  [保存伴侣公钥]
     │                               │
  [开始同步]                      [开始同步]
```

**QR码数据结构:**

```dart
// lib/features/family_sync/domain/models/pairing_qr_data.dart

class PairingQRData {
  final String bookId;           // 账本ID
  final String deviceId;         // 设备ID
  final String publicKey;        // 公钥（Base64）
  final String deviceName;       // 设备昵称
  final String nonce;            // 随机数（防重放攻击）
  final int expiresAt;          // 过期时间（5分钟）

  String toJSON() {
    return jsonEncode({
      'v': 1,  // 版本号
      'b': bookId,
      'd': deviceId,
      'pk': publicKey,
      'n': deviceName,
      'nonce': nonce,
      'exp': expiresAt,
    });
  }

  factory PairingQRData.fromJSON(String json) {
    final data = jsonDecode(json);
    return PairingQRData(
      bookId: data['b'],
      deviceId: data['d'],
      publicKey: data['pk'],
      deviceName: data['n'],
      nonce: data['nonce'],
      expiresAt: data['exp'],
    );
  }

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
}
```

**实现代码:**

```dart
// lib/features/family_sync/domain/use_cases/generate_pairing_qr.dart

class GeneratePairingQRUseCase {
  final KeyManager _keyManager;
  final BookRepository _bookRepo;

  Future<String> execute(String bookId) async {
    // 1. 获取当前设备信息
    final deviceId = await _keyManager.getDeviceId();
    final publicKey = await _keyManager.getPublicKey();
    final deviceName = await _getDeviceName();

    // 2. 生成随机数（防重放）
    final nonce = _generateNonce();

    // 3. 设置过期时间（5分钟）
    final expiresAt = DateTime.now()
        .add(Duration(minutes: 5))
        .millisecondsSinceEpoch;

    // 4. 构造QR码数据
    final qrData = PairingQRData(
      bookId: bookId,
      deviceId: deviceId!,
      publicKey: publicKey!,
      deviceName: deviceName,
      nonce: nonce,
      expiresAt: expiresAt,
    );

    // 5. 返回JSON字符串
    return qrData.toJSON();
  }

  String _generateNonce() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  Future<String> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return '${iosInfo.name}の${iosInfo.model}';
    } else {
      final androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.manufacturer} ${androidInfo.model}';
    }
  }
}
```

**扫描并配对:**

```dart
// lib/features/family_sync/domain/use_cases/pair_with_device.dart

class PairWithDeviceUseCase {
  final KeyManager _keyManager;
  final BookRepository _bookRepo;
  final DeviceRepository _deviceRepo;

  Future<PairingResult> execute(String qrCode) async {
    try {
      // 1. 解析QR码
      final qrData = PairingQRData.fromJSON(qrCode);

      // 2. 验证过期时间
      if (qrData.isExpired) {
        return PairingResult.expired();
      }

      // 3. 验证账本权限（确保是同一个账本）
      final currentBookId = await _bookRepo.getCurrentBookId();
      if (currentBookId != qrData.bookId) {
        return PairingResult.bookMismatch();
      }

      // 4. 验证对方公钥签名（确保是真实设备）
      final isValid = await _verifySignature(qrData);
      if (!isValid) {
        return PairingResult.invalidSignature();
      }

      // 5. 保存伴侣设备信息
      await _deviceRepo.addPartnerDevice(
        Device(
          id: qrData.deviceId,
          bookId: qrData.bookId,
          publicKey: qrData.publicKey,
          name: qrData.deviceName,
          role: DeviceRole.partner,
          pairedAt: DateTime.now(),
        ),
      );

      // 6. 发送握手确认（通过蓝牙/NFC）
      await _sendHandshake(qrData);

      return PairingResult.success(
        partnerDeviceId: qrData.deviceId,
        partnerDeviceName: qrData.deviceName,
      );
    } catch (e) {
      return PairingResult.error(e.toString());
    }
  }

  Future<bool> _verifySignature(PairingQRData qrData) async {
    // TODO: 实现签名验证逻辑
    // 需要对方设备发送签名数据
    return true;
  }

  Future<void> _sendHandshake(PairingQRData qrData) async {
    // TODO: 通过蓝牙/NFC发送握手消息
  }
}

class PairingResult {
  final PairingStatus status;
  final String? partnerDeviceId;
  final String? partnerDeviceName;
  final String? errorMessage;

  PairingResult.success({
    required this.partnerDeviceId,
    required this.partnerDeviceName,
  })  : status = PairingStatus.success,
        errorMessage = null;

  PairingResult.expired()
      : status = PairingStatus.expired,
        partnerDeviceId = null,
        partnerDeviceName = null,
        errorMessage = 'QRコードの有効期限が切れました';

  PairingResult.bookMismatch()
      : status = PairingStatus.bookMismatch,
        partnerDeviceId = null,
        partnerDeviceName = null,
        errorMessage = '帳簿が一致しません';

  PairingResult.invalidSignature()
      : status = PairingStatus.invalidSignature,
        partnerDeviceId = null,
        partnerDeviceName = null,
        errorMessage = '署名が無効です';

  PairingResult.error(String message)
      : status = PairingStatus.error,
        partnerDeviceId = null,
        partnerDeviceName = null,
        errorMessage = message;
}

enum PairingStatus {
  success,
  expired,
  bookMismatch,
  invalidSignature,
  error,
}
```

**UI设计:**

```
┌─────────────────────────────────────┐
│ ← 设备配对                          │
├─────────────────────────────────────┤
│                                     │
│  方式一：面对面配对                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  ┌────────────────────────────┐    │
│  │                             │    │
│  │      [QR码显示]             │    │  ← 生成QR码
│  │                             │    │
│  │   ████████████████████      │    │
│  │   ████████████████████      │    │
│  │   ████████████████████      │    │
│  │                             │    │
│  └────────────────────────────┘    │
│                                     │
│  请让伴侣扫描此QR码                  │
│  有效期：4:32                        │  ← 倒计时
│                                     │
│  [重新生成]                         │
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  或者扫描伴侣的QR码：                │
│  [📷 打开相机扫描]                  │
│                                     │
└─────────────────────────────────────┘
```

**扫描成功提示:**

```
┌─────────────────────────────────────┐
│  配对成功！                         │
├─────────────────────────────────────┤
│                                     │
│           ✓                         │
│                                     │
│  已与以下设备配对：                  │
│                                     │
│  📱 美惠のiPhone 14 Pro            │
│  设备ID: abc123def456               │
│                                     │
│  现在你们可以共享账本了！            │
│                                     │
│  [开始同步]                         │
└─────────────────────────────────────┘
```

#### 2.1.2 方式二：远程短码（V1.0后期）

**配对流程:**

```
Device A           Relay Server       Device B
   │                     │                 │
   ├─ 请求短码 ─────────►│                 │
   │                     │                 │
   │◄─ 返回123456 ───────┤                 │
   │                     │                 │
   │  [通过Line发送]     │                 │
   │                     │                 │
   │                     │◄─── 输入短码 ────┤
   │                     │                 │
   │◄─────────── 交换公钥 ───────────────►│
   │      (端到端加密)   │                 │
   │                     │                 │
[配对完成]                              [配对完成]
```

**注意:** MVP阶段不实现,V1.0再考虑。

---

### 2.2 B03: 数据同步

#### 2.2.1 同步协议（使用Yjs CRDT）

**为什么使用Yjs?**
- 成熟的CRDT库,无需自研冲突解决算法
- 支持离线编辑+自动合并
- 轻量级（<50KB gzipped）
- 支持Dart/Flutter（通过y-crdt Rust绑定）

**技术架构:**

```dart
// lib/features/family_sync/data/sync_engine.dart

import 'package:y_crdt/y_crdt.dart';

class SyncEngine {
  late YDoc _doc;
  final String _bookId;
  final ConnectionManager _connectionManager;

  Future<void> initialize() async {
    // 1. 创建Yjs文档
    _doc = YDoc();

    // 2. 定义共享数据结构
    final transactions = _doc.getArray('transactions');
    final categories = _doc.getArray('categories');

    // 3. 监听本地变更
    _doc.on('update', (update, origin) {
      if (origin != 'remote') {
        _syncUpdate(update);
      }
    });

    // 4. 加载本地状态
    await _loadLocalState();
  }

  /// 同步本地变更到伴侣设备
  Future<void> _syncUpdate(Uint8List update) async {
    final partnerDevices = await _deviceRepo.getPartnerDevices(_bookId);

    for (final device in partnerDevices) {
      try {
        // 通过蓝牙/WiFi发送更新
        await _connectionManager.sendUpdate(
          deviceId: device.id,
          update: update,
        );
      } catch (e) {
        // 发送失败,加入离线队列
        await _queueOfflineUpdate(device.id, update);
      }
    }
  }

  /// 接收伴侣设备的变更
  Future<void> receiveUpdate(Uint8List update) async {
    // 1. 应用更新到Yjs文档
    YDoc.applyUpdate(_doc, update, origin: 'remote');

    // 2. 提取变更的交易
    final transactions = _doc.getArray('transactions');
    final changes = _extractChanges(transactions);

    // 3. 写入本地数据库
    for (final tx in changes) {
      await _transactionRepo.upsert(tx);
    }

    // 4. 触发UI刷新
    _notifyListeners();
  }
}
```

**连接管理器（蓝牙优先）:**

```dart
// lib/features/family_sync/data/connection_manager.dart

class ConnectionManager {
  final FlutterBlue _bluetooth = FlutterBlue.instance;
  final NFC _nfc = NFC();

  /// 连接到伴侣设备
  Future<Connection?> connect(String deviceId) async {
    // 1. 尝试蓝牙连接
    final bluetoothConnection = await _connectViaBluetooth(deviceId);
    if (bluetoothConnection != null) {
      return bluetoothConnection;
    }

    // 2. 尝试NFC连接
    final nfcConnection = await _connectViaNFC(deviceId);
    if (nfcConnection != null) {
      return nfcConnection;
    }

    // 3. 尝试本地WiFi连接
    final wifiConnection = await _connectViaWiFi(deviceId);
    return wifiConnection;
  }

  Future<BluetoothConnection?> _connectViaBluetooth(String deviceId) async {
    // 扫描附近的蓝牙设备
    await _bluetooth.startScan(timeout: Duration(seconds: 5));

    final results = await _bluetooth.scanResults.first;
    for (final result in results) {
      if (result.device.id.toString() == deviceId) {
        final device = result.device;
        await device.connect();

        return BluetoothConnection(device);
      }
    }

    return null;
  }

  Future<void> sendUpdate({
    required String deviceId,
    required Uint8List update,
  }) async {
    final connection = await connect(deviceId);
    if (connection == null) {
      throw ConnectionException('无法连接到设备 $deviceId');
    }

    await connection.send(update);
  }
}
```

#### 2.2.2 同步时机

**自动同步:**
- 每日10次免费自动同步（每2.4小时一次）
- 仅在应用打开且有连接时触发

**手动同步:**
- 用户点击"立即同步"按钮
- 创建交易后提示同步

**事件触发:**
- 检测到伴侣设备在附近（蓝牙信号）
- 从后台恢复到前台

**实现代码:**

```dart
// lib/features/family_sync/domain/use_cases/auto_sync.dart

class AutoSyncUseCase {
  final SyncEngine _syncEngine;
  final SettingsRepository _settingsRepo;
  Timer? _timer;

  Future<void> start() async {
    final settings = await _settingsRepo.getSettings();

    if (!settings.autoSyncEnabled) {
      return;
    }

    // 每2.4小时同步一次（每日10次）
    final interval = Duration(hours: 2, minutes: 24);

    _timer = Timer.periodic(interval, (timer) async {
      if (await _shouldSync()) {
        await _syncEngine.sync();
      }
    });
  }

  Future<bool> _shouldSync() async {
    // 1. 检查应用是否在前台
    final appState = WidgetsBinding.instance.lifecycleState;
    if (appState != AppLifecycleState.resumed) {
      return false;
    }

    // 2. 检查是否有未同步的数据
    final hasUnsyncedData = await _syncEngine.hasUnsyncedData();
    if (!hasUnsyncedData) {
      return false;
    }

    // 3. 检查是否有可用连接
    final hasConnection = await _syncEngine.hasActiveConnection();
    if (!hasConnection) {
      return false;
    }

    return true;
  }

  void stop() {
    _timer?.cancel();
  }
}
```

#### 2.2.3 冲突解决

**Yjs自动解决的冲突:**
- **Last-Write-Wins（LWW）:** 时间戳决定最终值
- **Operation Transformation:** 操作转换
- **Causal Consistency:** 因果一致性

**需要用户干预的冲突:**

1. **同一笔消费被重复记录:**
```
Device A: ¥1,280 @ 吉野家 (14:30)
Device B: ¥1,280 @ 吉野家 (14:31)

系统检测: 金额相同、时间相近（±5分钟）、商家相同
提示: "这笔消费可能被重复记录，需要合并吗？"
```

2. **家庭内部转账状态不一致:**
```
Device A: 转账 ¥5,000 (待确认)
Device B: 未收到通知

系统检测: 24小时后仍未确认
提示: "转账请求已超时，需要重新发送吗？"
```

**实现代码:**

```dart
// lib/features/family_sync/domain/use_cases/detect_conflicts.dart

class DetectConflictsUseCase {
  final TransactionRepository _transactionRepo;

  Future<List<Conflict>> execute(String bookId) async {
    final conflicts = <Conflict>[];

    // 检测重复交易
    final duplicates = await _detectDuplicateTransactions(bookId);
    conflicts.addAll(duplicates);

    // 检测转账冲突
    final transferConflicts = await _detectTransferConflicts(bookId);
    conflicts.addAll(transferConflicts);

    return conflicts;
  }

  Future<List<Conflict>> _detectDuplicateTransactions(String bookId) async {
    final transactions = await _transactionRepo.getTransactions(
      bookId: bookId,
      startDate: DateTime.now().subtract(Duration(days: 7)),
    );

    final duplicates = <Conflict>[];

    for (var i = 0; i < transactions.length; i++) {
      for (var j = i + 1; j < transactions.length; j++) {
        final tx1 = transactions[i];
        final tx2 = transactions[j];

        if (_isPotentialDuplicate(tx1, tx2)) {
          duplicates.add(Conflict.duplicate(tx1, tx2));
        }
      }
    }

    return duplicates;
  }

  bool _isPotentialDuplicate(Transaction tx1, Transaction tx2) {
    // 1. 金额相同
    if (tx1.amount != tx2.amount) return false;

    // 2. 时间相近（±5分钟）
    final timeDiff = tx1.timestamp.difference(tx2.timestamp).abs();
    if (timeDiff > Duration(minutes: 5)) return false;

    // 3. 分类相同或商家相同
    if (tx1.categoryId == tx2.categoryId) return true;
    if (tx1.note != null && tx2.note != null) {
      if (tx1.note!.contains(tx2.note!) || tx2.note!.contains(tx1.note!)) {
        return true;
      }
    }

    return false;
  }
}

class Conflict {
  final ConflictType type;
  final List<Transaction> relatedTransactions;

  Conflict.duplicate(Transaction tx1, Transaction tx2)
      : type = ConflictType.duplicate,
        relatedTransactions = [tx1, tx2];

  Conflict.transferTimeout(Transaction tx)
      : type = ConflictType.transferTimeout,
        relatedTransactions = [tx];
}

enum ConflictType {
  duplicate,
  transferTimeout,
}
```

---

### 2.3 B05: 家庭内部转账

#### 2.3.1 两阶段提交协议

**转账流程:**

```
Device A (发起方)          Device B (接收方)
     │                         │
     ├─ REQUEST ─────────────► │
     │  "转账¥5000"            │
     │                         │
     │                    显示通知
     │                    "TA请求转账"
     │                         │
     │◄────── CONFIRM ──────────┤
     │  "同意"                 │
     │                         │
双方各自创建转账记录
     ├─ 支出 -¥5000            │
     │                    收入 +¥5000
     │                         │
  [同步]                    [同步]
```

**状态机:**

```
PENDING (24h超时)
   ├─ CONFIRMED (双方确认)
   ├─ REJECTED (一方拒绝)
   └─ EXPIRED (超时未处理)
```

**数据模型:**

```dart
// lib/features/family_sync/data/models/internal_transfer.dart

@DataClassName('InternalTransferData')
class InternalTransfers extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get fromDeviceId => text()();  // 发起方
  TextColumn get toDeviceId => text()();    // 接收方
  IntColumn get amount => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get status => text()();  // 'pending', 'confirmed', 'rejected', 'expired'
  IntColumn get requestedAt => integer()();
  IntColumn get respondedAt => integer().nullable()();
  IntColumn get expiresAt => integer()();  // 24小时后过期

  @override
  Set<Column> get primaryKey => {id};
}
```

**实现代码:**

```dart
// lib/features/family_sync/domain/use_cases/request_transfer.dart

class RequestTransferUseCase {
  final InternalTransferRepository _transferRepo;
  final ConnectionManager _connectionManager;
  final KeyManager _keyManager;

  Future<TransferRequestResult> execute({
    required String partnerDeviceId,
    required int amount,
    String? reason,
  }) async {
    // 1. 创建转账请求
    final deviceId = await _keyManager.getDeviceId();
    final bookId = await _bookRepo.getCurrentBookId();

    final transfer = InternalTransfer(
      id: uuid.v4(),
      bookId: bookId,
      fromDeviceId: deviceId!,
      toDeviceId: partnerDeviceId,
      amount: amount,
      reason: reason,
      status: TransferStatus.pending,
      requestedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(hours: 24)),
    );

    // 2. 保存到本地数据库
    await _transferRepo.insert(transfer);

    // 3. 发送请求到伴侣设备
    try {
      await _connectionManager.sendTransferRequest(
        deviceId: partnerDeviceId,
        transfer: transfer,
      );

      return TransferRequestResult.sent(transfer.id);
    } catch (e) {
      // 发送失败,标记为离线队列
      await _transferRepo.update(
        transfer.id,
        status: TransferStatus.queued,
      );

      return TransferRequestResult.queued(transfer.id);
    }
  }
}

// lib/features/family_sync/domain/use_cases/respond_transfer.dart

class RespondTransferUseCase {
  Future<void> confirm(String transferId) async {
    // 1. 更新转账状态
    await _transferRepo.update(
      transferId,
      status: TransferStatus.confirmed,
      respondedAt: DateTime.now(),
    );

    // 2. 创建双方交易记录
    final transfer = await _transferRepo.getById(transferId);

    // 发起方：支出
    await _transactionRepo.insert(
      Transaction(
        id: uuid.v4(),
        bookId: transfer.bookId,
        deviceId: transfer.fromDeviceId,
        amount: transfer.amount,
        type: TransactionType.transfer,
        categoryId: 'transfer_out',
        note: '转账给伴侣: ${transfer.reason ?? ""}',
        timestamp: DateTime.now(),
        // ... 其他字段
      ),
    );

    // 接收方：收入
    await _transactionRepo.insert(
      Transaction(
        id: uuid.v4(),
        bookId: transfer.bookId,
        deviceId: transfer.toDeviceId,
        amount: transfer.amount,
        type: TransactionType.transfer,
        categoryId: 'transfer_in',
        note: '来自伴侣的转账: ${transfer.reason ?? ""}',
        timestamp: DateTime.now(),
        // ... 其他字段
      ),
    );

    // 3. 通知发起方
    await _connectionManager.sendTransferResponse(
      deviceId: transfer.fromDeviceId,
      transferId: transferId,
      accepted: true,
    );
  }

  Future<void> reject(String transferId) async {
    await _transferRepo.update(
      transferId,
      status: TransferStatus.rejected,
      respondedAt: DateTime.now(),
    );

    final transfer = await _transferRepo.getById(transferId);
    await _connectionManager.sendTransferResponse(
      deviceId: transfer.fromDeviceId,
      transferId: transferId,
      accepted: false,
    );
  }
}
```

**UI设计（转账请求）:**

```
┌─────────────────────────────────────┐
│ ← 家庭内部转账                      │
├─────────────────────────────────────┤
│                                     │
│  转账给伴侣                          │
│                                     │
│  ┌─────────────────────────────┐   │
│  │         ¥  5,000            │   │
│  │         ━━━━━━━             │   │
│  └─────────────────────────────┘   │
│                                     │
│  转账原因（可选）:                  │
│  ┌────────────────────────────┐    │
│  │ 本月房租分摊                │    │
│  └────────────────────────────┘    │
│                                     │
│  接收方：                           │
│  📱 美惠のiPhone 14 Pro            │
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  转账后双方将自动创建记录：          │
│  • 您的账本: 支出 -¥5,000          │
│  • 伴侣账本: 收入 +¥5,000          │
│                                     │
│  [发送转账请求]                     │
└─────────────────────────────────────┘
```

**转账通知（接收方）:**

```
┌─────────────────────────────────────┐
│  转账请求                           │
├─────────────────────────────────────┤
│                                     │
│  田中さんが転送をリクエスト         │
│                                     │
│  金额：¥5,000                       │
│  原因：本月房租分摊                  │
│  有效期：23小时52分钟                │
│                                     │
│  确认后将在您的账本中创建收入记录    │
│                                     │
│  [拒绝]              [确认接收]     │
└─────────────────────────────────────┘
```

---

### 2.4 伴侣隐私保护

#### 2.4.1 灵魂账户明细隐藏

**规则:**
- 伴侣可以看到:灵魂账户的总支出和预算进度
- 伴侣不能看到:具体买了什么（交易明细）

**实现代码:**

```dart
// lib/features/family_sync/domain/use_cases/get_partner_transactions.dart

class GetPartnerTransactionsUseCase {
  Future<List<Transaction>> execute({
    required String partnerDeviceId,
    LedgerType? ledgerType,
  }) async {
    final transactions = await _transactionRepo.getTransactionsByDevice(
      deviceId: partnerDeviceId,
    );

    // 过滤灵魂账户交易（隐私保护）
    return transactions.where((tx) {
      if (tx.ledgerType == LedgerType.soul) {
        return false;  // 不显示灵魂账户明细
      }
      if (tx.isPrivate) {
        return false;  // 不显示私密交易
      }
      return true;
    }).toList();
  }

  /// 获取伴侣灵魂账户汇总（仅进度,无明细）
  Future<SoulAccountSummary> getPartnerSoulSummary(String partnerDeviceId) async {
    final config = await _soulConfigRepo.getByDeviceId(partnerDeviceId);

    final totalSpent = await _transactionRepo.sumByLedgerType(
      deviceId: partnerDeviceId,
      ledgerType: LedgerType.soul,
      month: DateTime.now().month,
      year: DateTime.now().year,
    );

    return SoulAccountSummary(
      ownerName: config.ownerName,
      soulName: config.soulName,
      iconEmoji: config.iconEmoji,
      monthlyBudget: config.monthlyBudget,
      totalSpent: totalSpent,  // 只有总额
      transactions: [],        // 明细为空！
      progressRatio: config.monthlyBudget > 0
          ? (totalSpent / config.monthlyBudget).clamp(0.0, 1.0)
          : 0.0,
    );
  }
}
```

#### 2.4.2 私密交易标记

**功能概述:**
用户可以将某些交易标记为"私密",伴侣完全看不到（连汇总都不计入）。

**UI设计（交易详情）:**

```
┌─────────────────────────────────────┐
│ ← 交易详情                          │
├─────────────────────────────────────┤
│  🎮 趣味                            │
│  ¥2,110                             │
│  2026/2/3 14:30                     │
│                                     │
│  备注：HG ザク II                   │
│  分类：趣味                          │
│  账户：💖 灵魂                      │
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│  隐私设置                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  🔒 标记为私密交易                  │
│  [                            ☐]   │  ← 开关
│                                     │
│  ⚠️ 开启后，伴侣将无法看到此交易    │
│     （包括汇总统计）                 │
│                                     │
│  [保存]                             │
└─────────────────────────────────────┘
```

---

## 3. 数据模型设计

### 3.1 Drift表定义

```dart
// lib/core/database/tables.dart

@DataClassName('DeviceData')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get publicKey => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();  // 'owner', 'partner'
  IntColumn get pairedAt => integer()();
  IntColumn get lastSyncAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncLogData')
class SyncLogs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get fromDeviceId => text()();
  TextColumn get toDeviceId => text()();
  IntColumn get syncedTransactions => integer()();  // 同步的交易数
  TextColumn get status => text()();  // 'success', 'failed'
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InternalTransferData')
class InternalTransfers extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get fromDeviceId => text()();
  TextColumn get toDeviceId => text()();
  IntColumn get amount => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get status => text()();
  IntColumn get requestedAt => integer()();
  IntColumn get respondedAt => integer().nullable()();
  IntColumn get expiresAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// 扩展交易表（添加私密标记）
@DataClassName('TransactionData')
class Transactions extends Table {
  // ... 其他字段 ...
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().nullable()();  // 'synced', 'pending', 'conflict'
}
```

---

## 4. UI/UX设计

### 4.1 家庭视图（首页）

```
┌─────────────────────────────────────┐
│  Happy Pocket            ☰          │
├─────────────────────────────────────┤
│  [我的账本] [家庭账本]              │  ← 标签切换
├─────────────────────────────────────┤
│                                     │
│  家庭总览                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  本月支出：¥312,800                 │
│  (您 ¥155,400 + 伴侣 ¥157,400)     │
│                                     │
│  ┌──────────────────────────┐      │
│  │ 📱 田中のiPhone             │      │
│  │ ¥155,400                   │      │
│  │ ████████░░ 86%             │      │
│  └──────────────────────────┘      │
│                                     │
│  ┌──────────────────────────┐      │
│  │ 📱 美惠のiPhone             │      │
│  │ ¥157,400                   │      │
│  │ ████████░░ 87%             │      │
│  │ [灵魂账户: 87%] 🔒          │      │  ← 只显示进度
│  └──────────────────────────┘      │
│                                     │
│  最近交易                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━      │
│                                     │
│  今日  2/3                          │
│  ┌───────────────────────────────┐  │
│  │ 🍚 食費   ¥1,280  田中   💖  │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🛒 食費   ¥5,800  美惠   🏠  │  │
│  └───────────────────────────────┘  │
│                                     │
│  [同步状态]  ✓ 已同步 (2分钟前)     │
│  [家庭内部转账]                     │
└─────────────────────────────────────┘
```

---

## 5. 验收标准

### 5.1 功能完整性

- ✅ QR码配对成功率>95%
- ✅ 同步冲突率<1%
- ✅ 1000条交易同步时间<10秒
- ✅ 家庭内部转账两阶段提交成功
- ✅ 离线时自动进入队列,上线后自动同步
- ✅ 哈希链完整性验证通过
- ✅ 伴侣无法查看灵魂账户明细
- ✅ 私密交易对伴侣完全不可见

### 5.2 性能指标

| 指标 | 目标 |
|------|------|
| 配对时间 | <10秒 |
| 同步延迟 | <2秒 |
| 蓝牙连接成功率 | >90% |
| 离线队列容量 | 支持10000条交易 |

---

## 6. 测试用例

### 6.1 单元测试

```dart
void main() {
  group('PairWithDeviceUseCase', () {
    test('should pair successfully with valid QR code', () async {
      // Given
      final qrData = PairingQRData(...);
      final qrCode = qrData.toJSON();

      // When
      final result = await useCase.execute(qrCode);

      // Then
      expect(result.status, PairingStatus.success);
    });

    test('should reject expired QR code', () async {
      // Given
      final expiredQRCode = PairingQRData(
        expiresAt: DateTime.now().subtract(Duration(minutes: 10)).millisecondsSinceEpoch,
      ).toJSON();

      // When
      final result = await useCase.execute(expiredQRCode);

      // Then
      expect(result.status, PairingStatus.expired);
    });
  });

  group('SyncEngine', () {
    test('should merge concurrent edits correctly', () async {
      // Given
      final deviceA = SyncEngine(bookId: 'book-001');
      final deviceB = SyncEngine(bookId: 'book-001');

      // When - concurrent edits
      await deviceA.addTransaction(tx1);
      await deviceB.addTransaction(tx2);

      // Sync
      final updateA = await deviceA.getUpdate();
      final updateB = await deviceB.getUpdate();

      await deviceA.receiveUpdate(updateB);
      await deviceB.receiveUpdate(updateA);

      // Then - both devices have same state
      final stateA = await deviceA.getState();
      final stateB = await deviceB.getState();

      expect(stateA, equals(stateB));
      expect(stateA.length, 2);
    });
  });
}
```

---

## 7. 开发里程碑（12天）

| Day | 任务 | 产出 |
|-----|------|------|
| **Day 1-2** | QR码配对 | 生成/扫描QR码,密钥交换 |
| **Day 3-4** | 连接管理器 | 蓝牙/NFC/WiFi连接 |
| **Day 5-6** | Yjs集成 | CRDT同步引擎 |
| **Day 7-8** | 家庭内部转账 | 两阶段提交,状态管理 |
| **Day 9-10** | 隐私保护 | 灵魂账户过滤,私密交易 |
| **Day 11** | UI实现 | 家庭视图,同步状态 |
| **Day 12** | 测试与优化 | 集成测试,性能优化 |

---

**文档状态:** 完成
**审核状态:** 待评审

**变更日志:**
- 2026-02-03: 初版完成
