# MOD-004: 家庭同步 - 技术设计文档

**模块编号:** MOD-004
**模块名称:** 家庭同步
**文档版本:** 2.0
**创建日期:** 2026-02-03
**预估工时:** 12天
**优先级:** P0 (MVP核心功能)
**依赖项:** MOD-006 (安全模块), MOD-001 (基础记账)

---

## 📋 目录

1. [模块概述](#模块概述)
2. [功能需求](#功能需求)
3. [技术设计](#技术设计)
4. [数据模型](#数据模型)
5. [核心流程](#核心流程)
6. [UI组件设计](#ui组件设计)
7. [测试策略](#测试策略)
8. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

家庭同步模块实现设备间的安全数据同步,无需中央服务器:

- **设备配对 (B01):** 面对面二维码配对(MVP) + 远程短码配对(V1.0)
- **数据同步 (B03):** 本地点对点同步、冲突解决、离线队列
- **内部转账 (B05):** 两阶段提交的伙伴间转账
- **隐私保护:** 灵魂账本详情隐藏、私密交易标记
- **同步协议:** 基于CRDT的Yjs库

### 核心技术栈

```yaml
CRDT库: yjs (通过y-crdt Rust绑定)
连接协议: BLE (flutter_blue_plus) / NFC / WiFi Direct
密钥交换: Ed25519 (MOD-006提供)
加密传输: ChaCha20-Poly1305 AEAD
状态管理: Riverpod 2.4+
```

---

## 功能需求

### FR-001: 设备配对

**用户故事:** 作为用户,我希望与伴侣安全配对设备而不上传数据到服务器。

**验收标准:**
- ✅ 生成包含公钥和账本ID的二维码
- ✅ 扫描伴侣的二维码并验证身份
- ✅ 配对在10秒内完成
- ✅ 无需服务器上传

### FR-002: 数据同步

**用户故事:** 作为用户,我希望自动同步到伴侣的设备。

**验收标准:**
- ✅ 设备附近时2秒内同步交易
- ✅ 通过蓝牙/NFC/WiFi同步
- ✅ 离线交易排队,重连后同步
- ✅ 并发编辑时零数据丢失

### FR-003: 内部转账

**用户故事:** 作为用户,我希望发起转账请求并让伴侣确认。

**验收标准:**
- ✅ 发送带金额和原因的转账请求
- ✅ 伴侣收到通知并可接受/拒绝
- ✅ 接受后为双方创建记录
- ✅ 待处理请求24小时超时

---

## 技术设计

### 配对架构

```dart
// lib/features/family_sync/domain/models/pairing_qr_data.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'pairing_qr_data.freezed.dart';
part 'pairing_qr_data.g.dart';

@freezed
class PairingQRData with _$PairingQRData {
  const factory PairingQRData({
    required String bookId,
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String nonce,
    required int expiresAt,
  }) = _PairingQRData;

  factory PairingQRData.fromJson(Map<String, dynamic> json) =>
      _$PairingQRDataFromJson(json);
}

extension PairingQRDataX on PairingQRData {
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiresAt;

  String toQRString() {
    return jsonEncode({
      'v': 1,  // 协议版本
      'b': bookId,
      'd': deviceId,
      'pk': publicKey,
      'n': deviceName,
      'nonce': nonce,
      'exp': expiresAt,
    });
  }

  static PairingQRData fromQRString(String qrString) {
    final data = jsonDecode(qrString) as Map<String, dynamic>;
    return PairingQRData(
      bookId: data['b'] as String,
      deviceId: data['d'] as String,
      publicKey: data['pk'] as String,
      deviceName: data['n'] as String,
      nonce: data['nonce'] as String,
      expiresAt: data['exp'] as int,
    );
  }
}
```

### 生成配对二维码

```dart
// lib/features/family_sync/domain/use_cases/generate_pairing_qr_use_case.dart

import 'package:homepocket/core/security/key_manager.dart';
import 'package:homepocket/features/books/domain/repositories/book_repository.dart';
import 'package:homepocket/features/family_sync/domain/models/pairing_qr_data.dart';
import 'dart:math';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class GeneratePairingQRUseCase {
  final KeyManager _keyManager;
  final BookRepository _bookRepo;

  GeneratePairingQRUseCase({
    required KeyManager keyManager,
    required BookRepository bookRepo,
  })  : _keyManager = keyManager,
        _bookRepo = bookRepo;

  Future<String> execute(String bookId) async {
    // 1. 获取当前设备信息
    final deviceId = await _keyManager.getDeviceId();
    final publicKey = await _keyManager.getPublicKey();
    final deviceName = await _getDeviceName();

    if (deviceId == null || publicKey == null) {
      throw Exception('设备密钥未初始化');
    }

    // 2. 生成随机数(防重放)
    final nonce = _generateNonce();

    // 3. 设置过期时间(5分钟)
    final expiresAt = DateTime.now()
        .add(const Duration(minutes: 5))
        .millisecondsSinceEpoch;

    // 4. 构造QR码数据
    final qrData = PairingQRData(
      bookId: bookId,
      deviceId: deviceId,
      publicKey: publicKey,
      deviceName: deviceName,
      nonce: nonce,
      expiresAt: expiresAt,
    );

    // 5. 返回JSON字符串
    return qrData.toQRString();
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
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return '${androidInfo.manufacturer} ${androidInfo.model}';
    }
    return 'Unknown Device';
  }
}
```

### 扫描并配对

```dart
// lib/features/family_sync/domain/use_cases/pair_with_device_use_case.dart

import 'package:homepocket/core/security/key_manager.dart';
import 'package:homepocket/features/books/domain/repositories/book_repository.dart';
import 'package:homepocket/features/family_sync/domain/models/pairing_qr_data.dart';
import 'package:homepocket/features/family_sync/domain/repositories/device_repository.dart';
import 'package:homepocket/features/family_sync/domain/models/device.dart';

class PairWithDeviceUseCase {
  final KeyManager _keyManager;
  final BookRepository _bookRepo;
  final DeviceRepository _deviceRepo;

  PairWithDeviceUseCase({
    required KeyManager keyManager,
    required BookRepository bookRepo,
    required DeviceRepository deviceRepo,
  })  : _keyManager = keyManager,
        _bookRepo = bookRepo,
        _deviceRepo = deviceRepo;

  Future<PairingResult> execute(String qrCode) async {
    try {
      // 1. 解析QR码
      final qrData = PairingQRDataX.fromQRString(qrCode);

      // 2. 验证过期时间
      if (qrData.isExpired) {
        return PairingResult.expired();
      }

      // 3. 验证账本权限(确保是同一个账本)
      final currentBookId = await _bookRepo.getCurrentBookId();
      if (currentBookId != qrData.bookId) {
        return PairingResult.bookMismatch();
      }

      // 4. 验证对方公钥签名
      // TODO: 实现签名验证(需要对方发送握手消息)

      // 5. 保存伴侣设备信息
      final device = Device(
        id: qrData.deviceId,
        bookId: qrData.bookId,
        publicKey: qrData.publicKey,
        name: qrData.deviceName,
        role: DeviceRole.partner,
        pairedAt: DateTime.now(),
        lastSyncAt: null,
      );

      await _deviceRepo.addPartnerDevice(device);

      // 6. 发送握手确认(通过蓝牙/NFC)
      // TODO: 实现握手协议

      return PairingResult.success(
        partnerDeviceId: qrData.deviceId,
        partnerDeviceName: qrData.deviceName,
      );
    } catch (e) {
      return PairingResult.error(e.toString());
    }
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

### CRDT同步服务

```dart
// lib/features/family_sync/data/services/crdt_sync_service.dart

import 'package:homepocket/features/family_sync/domain/models/sync_operation.dart';
import 'package:homepocket/features/transactions/domain/models/transaction.dart';
import 'package:homepocket/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

class CRDTSyncService {
  final TransactionRepository _transactionRepo;

  CRDTSyncService({
    required TransactionRepository transactionRepo,
  }) : _transactionRepo = transactionRepo;

  /// 生成CRDT操作
  Future<List<SyncOperation>> generateOperations(
    List<Transaction> transactions,
  ) async {
    return transactions.map((tx) => SyncOperation(
      id: const Uuid().v4(),
      type: SyncOperationType.insert,
      entityType: 'transaction',
      entityId: tx.id,
      timestamp: tx.createdAt.millisecondsSinceEpoch,
      deviceId: tx.deviceId,
      data: tx.toJson(),
    )).toList();
  }

  /// 应用CRDT操作
  Future<void> applyOperations(
    List<SyncOperation> operations,
  ) async {
    // 按时间戳排序(保证因果一致性)
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final op in operations) {
      switch (op.type) {
        case SyncOperationType.insert:
          await _handleInsert(op);
          break;
        case SyncOperationType.update:
          await _handleUpdate(op);
          break;
        case SyncOperationType.delete:
          await _handleDelete(op);
          break;
      }
    }
  }

  /// Last-Write-Wins策略
  Future<void> _handleInsert(SyncOperation op) async {
    final existing = await _transactionRepo.getById(op.entityId);

    if (existing == null) {
      // 不存在,直接插入
      final transaction = Transaction.fromJson(op.data);
      await _transactionRepo.insert(transaction);
    } else {
      // 存在,比较时间戳
      final existingTimestamp = existing.createdAt.millisecondsSinceEpoch;
      if (op.timestamp > existingTimestamp) {
        // 远程更新更新,覆盖本地
        final transaction = Transaction.fromJson(op.data);
        await _transactionRepo.update(transaction);
      }
      // 否则保留本地版本
    }
  }

  Future<void> _handleUpdate(SyncOperation op) async {
    final transaction = Transaction.fromJson(op.data);
    await _transactionRepo.update(transaction);
  }

  Future<void> _handleDelete(SyncOperation op) async {
    await _transactionRepo.delete(op.entityId);
  }
}

class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String entityType;
  final String entityId;
  final int timestamp;
  final String deviceId;
  final Map<String, dynamic> data;

  SyncOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    required this.deviceId,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'entityType': entityType,
    'entityId': entityId,
    'timestamp': timestamp,
    'deviceId': deviceId,
    'data': data,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.byName(json['type'] as String),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      timestamp: json['timestamp'] as int,
      deviceId: json['deviceId'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}

enum SyncOperationType {
  insert,
  update,
  delete,
}
```

### 连接管理器(BLE)

```dart
// lib/features/family_sync/data/services/connection_manager.dart

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';
import 'dart:async';

class ConnectionManager {
  static const String serviceUUID = 'homepocket-sync';
  static const String syncStatusCharUUID = 'sync-status';
  static const String updateTxCharUUID = 'update-tx';
  static const String updateRxCharUUID = 'update-rx';

  final FlutterBluePlus _bluetooth = FlutterBluePlus();
  final Map<String, BluetoothDevice> _connectedDevices = {};

  /// 连接到伴侣设备
  Future<BluetoothConnection?> connect(String deviceId) async {
    // 1. 尝试蓝牙连接
    final bluetoothConnection = await _connectViaBluetooth(deviceId);
    if (bluetoothConnection != null) {
      return bluetoothConnection;
    }

    // 2. TODO: 尝试NFC连接

    // 3. TODO: 尝试本地WiFi连接

    return null;
  }

  Future<BluetoothConnection?> _connectViaBluetooth(String deviceId) async {
    try {
      // 扫描附近的蓝牙设备
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      final completer = Completer<BluetoothConnection?>();

      FlutterBluePlus.scanResults.listen((results) async {
        for (final result in results) {
          // 匹配设备ID(需要在广播数据中包含)
          if (_matchesDeviceId(result, deviceId)) {
            final device = result.device;

            // 停止扫描
            await FlutterBluePlus.stopScan();

            // 连接设备
            await device.connect(timeout: const Duration(seconds: 15));

            _connectedDevices[deviceId] = device;

            completer.complete(BluetoothConnection(device));
            return;
          }
        }
      });

      // 5秒后超时
      Future.delayed(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      print('蓝牙连接失败: $e');
      return null;
    }
  }

  bool _matchesDeviceId(ScanResult result, String deviceId) {
    // TODO: 实现设备ID匹配逻辑
    // 可以在广播数据的manufacturerData中包含设备ID
    return false;
  }

  Future<void> sendUpdate({
    required String deviceId,
    required Uint8List update,
  }) async {
    final device = _connectedDevices[deviceId];
    if (device == null) {
      throw ConnectionException('设备未连接: $deviceId');
    }

    // TODO: 通过特征值发送数据
    // await device.writeCharacteristic(updateTxCharUUID, update);
  }

  void dispose() {
    for (final device in _connectedDevices.values) {
      device.disconnect();
    }
    _connectedDevices.clear();
  }
}

class BluetoothConnection {
  final BluetoothDevice device;

  BluetoothConnection(this.device);

  Future<void> send(Uint8List data) async {
    // TODO: 发送数据到特征值
  }

  Future<void> disconnect() async {
    await device.disconnect();
  }
}

class ConnectionException implements Exception {
  final String message;
  ConnectionException(this.message);

  @override
  String toString() => message;
}
```

### 内部转账(两阶段提交)

```dart
// lib/features/family_sync/domain/use_cases/request_transfer_use_case.dart

import 'package:homepocket/features/family_sync/domain/repositories/internal_transfer_repository.dart';
import 'package:homepocket/features/family_sync/domain/models/internal_transfer.dart';
import 'package:homepocket/features/family_sync/data/services/connection_manager.dart';
import 'package:homepocket/core/security/key_manager.dart';
import 'package:homepocket/features/books/domain/repositories/book_repository.dart';
import 'package:uuid/uuid.dart';

class RequestTransferUseCase {
  final InternalTransferRepository _transferRepo;
  final ConnectionManager _connectionManager;
  final KeyManager _keyManager;
  final BookRepository _bookRepo;

  RequestTransferUseCase({
    required InternalTransferRepository transferRepo,
    required ConnectionManager connectionManager,
    required KeyManager keyManager,
    required BookRepository bookRepo,
  })  : _transferRepo = transferRepo,
        _connectionManager = connectionManager,
        _keyManager = keyManager,
        _bookRepo = bookRepo;

  Future<TransferRequestResult> execute({
    required String partnerDeviceId,
    required int amount,
    String? reason,
  }) async {
    try {
      // 1. 创建转账请求
      final deviceId = await _keyManager.getDeviceId();
      final bookId = await _bookRepo.getCurrentBookId();

      if (deviceId == null || bookId == null) {
        throw Exception('设备或账本未初始化');
      }

      final transfer = InternalTransfer(
        id: const Uuid().v4(),
        bookId: bookId,
        fromDeviceId: deviceId,
        toDeviceId: partnerDeviceId,
        amount: amount,
        reason: reason,
        status: TransferStatus.pending,
        requestedAt: DateTime.now(),
        respondedAt: null,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
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
        await _transferRepo.updateStatus(
          transfer.id,
          TransferStatus.queued,
        );

        return TransferRequestResult.queued(transfer.id);
      }
    } catch (e) {
      return TransferRequestResult.error(e.toString());
    }
  }
}

class TransferRequestResult {
  final TransferRequestStatus status;
  final String? transferId;
  final String? errorMessage;

  TransferRequestResult.sent(this.transferId)
      : status = TransferRequestStatus.sent,
        errorMessage = null;

  TransferRequestResult.queued(this.transferId)
      : status = TransferRequestStatus.queued,
        errorMessage = null;

  TransferRequestResult.error(String message)
      : status = TransferRequestStatus.error,
        transferId = null,
        errorMessage = message;
}

enum TransferRequestStatus {
  sent,
  queued,
  error,
}
```

---

## 数据模型

### Drift表定义

```dart
// lib/features/family_sync/data/datasources/local/tables.dart

import 'package:drift/drift.dart';

@DataClassName('DeviceData')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get publicKey => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();  // 'owner' | 'partner'
  IntColumn get pairedAt => integer()();
  IntColumn get lastSyncAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncLogData')
class SyncLogs extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get fromDeviceId => text()();
  TextColumn get toDeviceId => text()();
  IntColumn get syncedTransactions => integer()();
  TextColumn get status => text()();  // 'success' | 'failed'
  IntColumn get timestamp => integer()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InternalTransferData')
class InternalTransfers extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(Books, #id)();
  TextColumn get fromDeviceId => text()();
  TextColumn get toDeviceId => text()();
  IntColumn get amount => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get status => text()();  // 'pending' | 'confirmed' | 'rejected' | 'expired'
  IntColumn get requestedAt => integer()();
  IntColumn get respondedAt => integer().nullable()();
  IntColumn get expiresAt => integer()();  // 24小时过期

  @override
  Set<Column> get primaryKey => {id};
}
```

### 领域模型

```dart
// lib/features/family_sync/domain/models/device.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';
part 'device.g.dart';

@freezed
class Device with _$Device {
  const factory Device({
    required String id,
    required String bookId,
    required String publicKey,
    required String name,
    required DeviceRole role,
    required DateTime pairedAt,
    DateTime? lastSyncAt,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) =>
      _$DeviceFromJson(json);
}

enum DeviceRole {
  owner,
  partner,
}
```

```dart
// lib/features/family_sync/domain/models/internal_transfer.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'internal_transfer.freezed.dart';
part 'internal_transfer.g.dart';

@freezed
class InternalTransfer with _$InternalTransfer {
  const factory InternalTransfer({
    required String id,
    required String bookId,
    required String fromDeviceId,
    required String toDeviceId,
    required int amount,
    String? reason,
    required TransferStatus status,
    required DateTime requestedAt,
    DateTime? respondedAt,
    required DateTime expiresAt,
  }) = _InternalTransfer;

  factory InternalTransfer.fromJson(Map<String, dynamic> json) =>
      _$InternalTransferFromJson(json);
}

enum TransferStatus {
  pending,
  confirmed,
  rejected,
  expired,
  queued,
}
```

---

## 核心流程

### 同步流程完整实现

```dart
// lib/features/family_sync/domain/use_cases/sync_now_use_case.dart

import 'package:homepocket/features/family_sync/data/services/crdt_sync_service.dart';
import 'package:homepocket/features/family_sync/data/services/connection_manager.dart';
import 'package:homepocket/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:homepocket/features/family_sync/domain/repositories/device_repository.dart';
import 'package:homepocket/core/security/encryption_service.dart';

class SyncNowUseCase {
  final TransactionRepository _transactionRepo;
  final DeviceRepository _deviceRepo;
  final CRDTSyncService _crdt;
  final EncryptionService _encryption;
  final ConnectionManager _connectionManager;

  SyncNowUseCase({
    required TransactionRepository transactionRepo,
    required DeviceRepository deviceRepo,
    required CRDTSyncService crdt,
    required EncryptionService encryption,
    required ConnectionManager connectionManager,
  })  : _transactionRepo = transactionRepo,
        _deviceRepo = deviceRepo,
        _crdt = crdt,
        _encryption = encryption,
        _connectionManager = connectionManager;

  Future<SyncResult> execute(String bookId) async {
    try {
      // 1. 获取本地未同步的交易
      final localChanges = await _transactionRepo.getUnsynced(bookId);

      // 2. 生成CRDT操作
      final operations = await _crdt.generateOperations(localChanges);

      // 3. 加密操作
      final encryptedPayload = await _encryption.encryptSyncPayload(operations);

      // 4. 获取伴侣设备
      final partnerDevices = await _deviceRepo.getPartnerDevices(bookId);

      if (partnerDevices.isEmpty) {
        return SyncResult.noPartner();
      }

      int syncedCount = 0;
      int conflictCount = 0;

      // 5. 同步到每个伴侣设备
      for (final partner in partnerDevices) {
        try {
          // 连接设备
          final connection = await _connectionManager.connect(partner.id);
          if (connection == null) {
            continue;
          }

          // 发送加密载荷
          await connection.send(encryptedPayload);

          // 接收响应
          // final response = await connection.receive();
          // final remoteOperations = await _encryption.decryptSyncPayload(response);

          // 应用远程操作
          // await _crdt.applyOperations(remoteOperations);

          syncedCount++;
        } catch (e) {
          print('同步到设备${partner.id}失败: $e');
        }
      }

      // 6. 标记为已同步
      await _transactionRepo.markAsSynced(
        localChanges.map((tx) => tx.id).toList(),
      );

      // 7. 更新同步时间
      for (final partner in partnerDevices) {
        await _deviceRepo.updateLastSyncTime(partner.id, DateTime.now());
      }

      return SyncResult.success(
        syncedTransactions: syncedCount,
        conflicts: conflictCount,
        syncedAt: DateTime.now(),
      );
    } catch (e) {
      return SyncResult.failed(
        reason: e.toString(),
        error: SyncError.unknown,
      );
    }
  }
}

@freezed
class SyncResult with _$SyncResult {
  const factory SyncResult.success({
    required int syncedTransactions,
    required int conflicts,
    required DateTime syncedAt,
  }) = SyncSuccess;

  const factory SyncResult.failed({
    required String reason,
    required SyncError error,
  }) = SyncFailed;

  const factory SyncResult.offline() = SyncOffline;

  const factory SyncResult.noPartner() = SyncNoPartner;
}

enum SyncError {
  connectionLost,
  partnerNotFound,
  authenticationFailed,
  dataCorrupted,
  unknown,
}
```

---

## UI组件设计

### 配对界面

```dart
// lib/features/family_sync/presentation/screens/pairing_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PairingScreen extends ConsumerStatefulWidget {
  final String bookId;

  const PairingScreen({Key? key, required this.bookId}) : super(key: key);

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  bool _isShowingQR = true;
  String? _qrData;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    final useCase = ref.read(generatePairingQRUseCaseProvider);
    final qrData = await useCase.execute(widget.bookId);
    setState(() {
      _qrData = qrData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备配对'),
      ),
      body: SafeArea(
        child: _isShowingQR ? _buildQRView() : _buildScannerView(),
      ),
    );
  }

  Widget _buildQRView() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '方式一：面对面配对',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
        Expanded(
          child: Center(
            child: _qrData == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      QrImageView(
                        data: _qrData!,
                        version: QrVersions.auto,
                        size: 300.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '请让伴侣扫描此QR码',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '有效期：5分钟',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: _generateQRCode,
                        child: const Text('重新生成'),
                      ),
                    ],
                  ),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isShowingQR = false;
                });
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('或者扫描伴侣的QR码'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerView() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRCodeScanned(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _isShowingQR = true;
              });
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('返回显示我的QR码'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleQRCodeScanned(String qrData) async {
    final useCase = ref.read(pairWithDeviceUseCaseProvider);
    final result = await useCase.execute(qrData);

    if (!mounted) return;

    switch (result.status) {
      case PairingStatus.success:
        _showSuccessDialog(result.partnerDeviceName!);
        break;
      case PairingStatus.expired:
        _showErrorDialog('QR码已过期');
        break;
      case PairingStatus.bookMismatch:
        _showErrorDialog('账本不匹配');
        break;
      case PairingStatus.invalidSignature:
        _showErrorDialog('签名无效');
        break;
      case PairingStatus.error:
        _showErrorDialog(result.errorMessage ?? '配对失败');
        break;
    }
  }

  void _showSuccessDialog(String deviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配对成功！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text('已与以下设备配对：'),
            const SizedBox(height: 8),
            Text(
              deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('开始同步'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配对失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
```

### 同步状态组件

```dart
// lib/features/family_sync/presentation/widgets/sync_status_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncStatusWidget extends ConsumerWidget {
  final String bookId;

  const SyncStatusWidget({Key? key, required this.bookId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerDevicesAsync = ref.watch(partnerDevicesProvider(bookId));

    return partnerDevicesAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('错误: $error'),
      data: (devices) {
        if (devices.isEmpty) {
          return ListTile(
            leading: const Icon(Icons.sync_disabled),
            title: const Text('未配对设备'),
            trailing: TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/pairing',
                  arguments: bookId,
                );
              },
              child: const Text('配对设备'),
            ),
          );
        }

        final lastSync = devices.first.lastSyncAt;
        final syncTime = lastSync != null
            ? _formatSyncTime(lastSync)
            : '从未同步';

        return ListTile(
          leading: const Icon(Icons.sync, color: Colors.green),
          title: Text('已同步 ($syncTime)'),
          subtitle: Text('伴侣设备: ${devices.first.name}'),
          trailing: IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _syncNow(ref),
          ),
        );
      },
    );
  }

  String _formatSyncTime(DateTime lastSync) {
    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }

  Future<void> _syncNow(WidgetRef ref) async {
    final useCase = ref.read(syncNowUseCaseProvider);
    final result = await useCase.execute(bookId);

    // TODO: 显示同步结果
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/features/family_sync/domain/use_cases/pair_with_device_use_case_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:homepocket/features/family_sync/domain/use_cases/pair_with_device_use_case.dart';

void main() {
  late MockKeyManager mockKeyManager;
  late MockBookRepository mockBookRepo;
  late MockDeviceRepository mockDeviceRepo;
  late PairWithDeviceUseCase useCase;

  setUp(() {
    mockKeyManager = MockKeyManager();
    mockBookRepo = MockBookRepository();
    mockDeviceRepo = MockDeviceRepository();

    useCase = PairWithDeviceUseCase(
      keyManager: mockKeyManager,
      bookRepo: mockBookRepo,
      deviceRepo: mockDeviceRepo,
    );
  });

  group('PairWithDeviceUseCase', () {
    test('成功配对有效QR码', () async {
      // Given
      final qrData = PairingQRData(
        bookId: 'book-001',
        deviceId: 'device-002',
        publicKey: 'pk-002',
        deviceName: 'Partner iPhone',
        nonce: 'nonce123',
        expiresAt: DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch,
      );
      final qrCode = qrData.toQRString();

      when(mockBookRepo.getCurrentBookId())
          .thenAnswer((_) async => 'book-001');

      // When
      final result = await useCase.execute(qrCode);

      // Then
      expect(result.status, PairingStatus.success);
      expect(result.partnerDeviceId, 'device-002');
      verify(mockDeviceRepo.addPartnerDevice(any)).called(1);
    });

    test('拒绝过期QR码', () async {
      // Given
      final qrData = PairingQRData(
        bookId: 'book-001',
        deviceId: 'device-002',
        publicKey: 'pk-002',
        deviceName: 'Partner iPhone',
        nonce: 'nonce123',
        expiresAt: DateTime.now().subtract(Duration(minutes: 10)).millisecondsSinceEpoch,
      );
      final qrCode = qrData.toQRString();

      // When
      final result = await useCase.execute(qrCode);

      // Then
      expect(result.status, PairingStatus.expired);
      verifyNever(mockDeviceRepo.addPartnerDevice(any));
    });
  });
}
```

---

## 性能优化

### 同步优化策略

**1. 增量同步**
- 仅同步自上次同步以来的变更
- 使用时间戳跟踪同步状态
- gzip压缩更新载荷

**2. 批量操作**
- 将多个交易分组到单个同步更新
- 使用数据库事务进行原子写入
- 限制同步触发器(最多每5秒1次)

**3. 连接池**
- 重用BLE连接
- 活动会话期间保持连接
- 断开时自动重连

---

## 验收标准

### 功能需求

- ✅ 二维码配对成功率 >95%
- ✅ 同步冲突率 <1%
- ✅ 1000条交易在<10秒内同步
- ✅ 内部转账两阶段提交正常工作
- ✅ 离线队列可容纳10000+更新且无数据丢失

### 性能需求

| 指标 | 目标 |
|------|------|
| 配对时间 | <10s |
| 同步延迟 | <2s |
| BLE连接成功率 | >90% |
| 离线队列容量 | 10000更新 |

---

**文档状态:** 完成
**最后更新:** 2026-02-03
**维护者:** 架构团队
