import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pin_manager.g.dart';

class PINManager {
  PINManager({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;
  final FlutterSecureStorage _secureStorage;

  /// 检查是否已设置PIN
  Future<bool> isPINSet() async {
    final hash = await _secureStorage.read(key: 'pin_hash');
    return hash != null;
  }

  /// 设置新的PIN
  Future<void> setPIN(String pin) async {
    _validatePIN(pin);
    final hash = hashPIN(pin);
    await _secureStorage.write(key: 'pin_hash', value: hash);
  }

  /// 验证PIN是否正确
  Future<bool> verifyPIN(String pin) async {
    try {
      _validatePIN(pin);
      final storedHash = await _secureStorage.read(key: 'pin_hash');
      if (storedHash == null) {
        return false;
      }
      final inputHash = hashPIN(pin);
      return inputHash == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// 更改PIN（需要提供旧PIN）
  Future<bool> changePIN(String oldPIN, String newPIN) async {
    // 1. 验证旧PIN
    final isOldPINCorrect = await verifyPIN(oldPIN);
    if (!isOldPINCorrect) {
      return false;
    }

    // 2. 设置新PIN
    await setPIN(newPIN);
    return true;
  }

  /// 删除PIN（需要提供正确的PIN）
  Future<bool> deletePIN(String pin) async {
    // 1. 验证PIN
    final isPINCorrect = await verifyPIN(pin);
    if (!isPINCorrect) {
      return false;
    }

    // 2. 删除PIN哈希
    await _secureStorage.delete(key: 'pin_hash');
    return true;
  }

  /// 计算PIN的SHA-256哈希值
  String hashPIN(String pin) {
    _validatePIN(pin);
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// 验证PIN格式：必须是6位数字
  void _validatePIN(String pin) {
    if (pin.length != 6) {
      throw ArgumentError('PIN must be exactly 6 digits');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('PIN must contain only digits');
    }
  }
}

// Provider
@riverpod
PINManager pinManager(PinManagerRef ref) {
  return PINManager(
    secureStorage: const FlutterSecureStorage(),
  );
}

@riverpod
Future<bool> isPINSet(IsPINSetRef ref) async {
  final pinManager = ref.watch(pinManagerProvider);
  return pinManager.isPINSet();
}
