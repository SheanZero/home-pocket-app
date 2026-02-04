import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';

part 'recovery_kit_service.g.dart';

class RecoveryKitService {
  final FlutterSecureStorage _secureStorage;
  final KeyManager _keyManager;

  RecoveryKitService({
    required FlutterSecureStorage secureStorage,
    required KeyManager keyManager,
  })  : _secureStorage = secureStorage,
        _keyManager = keyManager;

  /// 生成Recovery Kit（24个助记词）
  Future<String> generateRecoveryKit() async {
    // 1. 生成256位随机熵并转换为助记词（24个单词）
    final mnemonic = bip39.generateMnemonic(strength: 256);

    // 2. 存储助记词的哈希（用于后续验证，绝不存储明文）
    final hash = hashMnemonic(mnemonic);
    await _secureStorage.write(
      key: 'recovery_kit_hash',
      value: hash,
    );

    return mnemonic;
  }

  /// 验证用户输入的Recovery Kit
  Future<bool> verifyRecoveryKit(String userInput) async {
    // 1. 验证格式
    final words = userInput.trim().split(' ');
    if (words.length != 24) {
      return false;
    }

    // 2. 验证是否与存储的哈希匹配
    final storedHash = await _secureStorage.read(key: 'recovery_kit_hash');
    if (storedHash == null) {
      return false;
    }

    final inputHash = hashMnemonic(userInput);
    return inputHash == storedHash;
  }

  /// 从助记词恢复密钥对
  Future<void> recoverFromMnemonic(String mnemonic) async {
    // 1. 验证助记词格式
    if (!bip39.validateMnemonic(mnemonic)) {
      throw InvalidSeedException('助记词格式错误');
    }

    // 2. 从助记词派生种子（512位）
    final seed = bip39.mnemonicToSeed(mnemonic);

    // 3. 使用种子的前32字节作为Ed25519私钥种子
    final privateKeySeed = seed.sublist(0, 32);

    // 4. 让KeyManager使用这个种子重新生成密钥对
    await _keyManager.recoverFromSeed(privateKeySeed);

    // 5. 存储助记词哈希
    final hash = hashMnemonic(mnemonic);
    await _secureStorage.write(
      key: 'recovery_kit_hash',
      value: hash,
    );
  }

  /// 获取随机3个单词位置用于验证
  List<int> getRandomWordsForVerification() {
    final random = Random.secure();
    final indices = <int>{};

    while (indices.length < 3) {
      indices.add(random.nextInt(24));
    }

    return indices.toList()..sort();
  }

  /// 计算助记词的SHA-256哈希
  String hashMnemonic(String mnemonic) {
    final bytes = utf8.encode(mnemonic.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

@riverpod
RecoveryKitService recoveryKitService(RecoveryKitServiceRef ref) {
  return RecoveryKitService(
    secureStorage: const FlutterSecureStorage(),
    keyManager: ref.watch(keyManagerProvider),
  );
}
