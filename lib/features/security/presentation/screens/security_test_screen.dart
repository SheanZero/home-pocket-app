import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/security/application/services/biometric_lock.dart';
import 'package:home_pocket/features/security/application/services/pin_manager.dart';
import 'package:home_pocket/features/security/application/services/recovery_kit_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';

/// 安全模块测试屏幕
///
/// 用于人工测试MOD-006安全与隐私模块的所有功能
class SecurityTestScreen extends ConsumerStatefulWidget {
  const SecurityTestScreen({super.key});

  @override
  ConsumerState<SecurityTestScreen> createState() => _SecurityTestScreenState();
}

class _SecurityTestScreenState extends ConsumerState<SecurityTestScreen> {
  final _pinController = TextEditingController();
  final _encryptController = TextEditingController();
  String _testResult = '';
  String? _generatedMnemonic;
  String? _encryptedData;
  String? _decryptedData;

  @override
  void dispose() {
    _pinController.dispose();
    _encryptController.dispose();
    super.dispose();
  }

  void _showResult(String message, {bool isError = false}) {
    setState(() {
      _testResult = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安全模块测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 测试结果显示区域
            if (_testResult.isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '最后测试结果:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(_testResult),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 1. 密钥管理测试
            _buildSection(
              '1. 密钥管理 (Key Manager)',
              [
                _buildTestButton(
                  '生成设备密钥对',
                  Icons.vpn_key,
                  () async {
                    try {
                      final keyManager = ref.read(keyManagerProvider);
                      final keyPair = await keyManager.generateDeviceKeyPair();
                      _showResult(
                        '✅ 密钥对生成成功!\n'
                        '设备ID: ${keyPair.deviceId}\n'
                        '公钥长度: ${keyPair.publicKey.length} 字符',
                      );
                    } catch (e) {
                      _showResult('❌ 密钥生成失败: $e', isError: true);
                    }
                  },
                ),
                _buildTestButton(
                  '检查密钥是否存在',
                  Icons.search,
                  () async {
                    try {
                      final hasKey = await ref.read(hasKeyPairProvider.future);
                      _showResult(
                        hasKey ? '✅ 密钥对已存在' : '⚠️ 密钥对不存在，请先生成',
                      );
                    } catch (e) {
                      _showResult('❌ 检查失败: $e', isError: true);
                    }
                  },
                ),
              ],
            ),

            // 2. 恢复套件测试
            _buildSection(
              '2. 恢复套件 (Recovery Kit)',
              [
                _buildTestButton(
                  '生成24词助记词',
                  Icons.list_alt,
                  () async {
                    try {
                      final service = ref.read(recoveryKitServiceProvider);
                      final mnemonic = await service.generateRecoveryKit();
                      setState(() {
                        _generatedMnemonic = mnemonic;
                      });
                      _showResult(
                        '✅ 助记词生成成功!\n'
                        '词数: ${mnemonic.split(' ').length}\n'
                        '前3词: ${mnemonic.split(' ').take(3).join(' ')}...',
                      );
                    } catch (e) {
                      _showResult('❌ 生成失败: $e', isError: true);
                    }
                  },
                ),
                if (_generatedMnemonic != null)
                  _buildTestButton(
                    '验证助记词',
                    Icons.check_circle,
                    () async {
                      try {
                        final service = ref.read(recoveryKitServiceProvider);
                        final isValid = await service
                            .verifyRecoveryKit(_generatedMnemonic!);
                        _showResult(
                          isValid ? '✅ 助记词验证通过' : '❌ 助记词验证失败',
                          isError: !isValid,
                        );
                      } catch (e) {
                        _showResult('❌ 验证失败: $e', isError: true);
                      }
                    },
                  ),
                if (_generatedMnemonic != null)
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '生成的助记词:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _generatedMnemonic!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // 3. 生物识别测试
            _buildSection(
              '3. 生物识别 (Biometric)',
              [
                _buildTestButton(
                  '检查生物识别可用性',
                  Icons.fingerprint,
                  () async {
                    try {
                      ref.read(biometricLockProvider); // Check availability
                      final availability =
                          await ref.read(biometricAvailabilityProvider.future);
                      final availabilityText = {
                        BiometricAvailability.faceId: 'Face ID 可用',
                        BiometricAvailability.fingerprint: '指纹识别可用',
                        BiometricAvailability.generic: '生物识别可用',
                        BiometricAvailability.notEnrolled: '未注册生物识别',
                        BiometricAvailability.notSupported: '不支持生物识别',
                      };
                      _showResult(
                        '生物识别状态: ${availabilityText[availability]}',
                      );
                    } catch (e) {
                      _showResult('❌ 检查失败: $e', isError: true);
                    }
                  },
                ),
                _buildTestButton(
                  '执行生物识别认证',
                  Icons.face,
                  () async {
                    try {
                      final biometric = ref.read(biometricLockProvider);
                      final result = await biometric.authenticate(
                        reason: '验证您的身份以继续',
                      );

                      final resultText = result.when(
                        success: () => '✅ 认证成功',
                        failed: (failedAttempts) =>
                            '❌ 认证失败 (尝试次数: $failedAttempts)',
                        fallbackToPIN: () => '⚠️ 需要使用PIN码',
                        tooManyAttempts: () => '❌ 尝试次数过多',
                        lockedOut: () => '❌ 已锁定',
                        error: (message) => '❌ 错误: $message',
                      );

                      _showResult(
                        resultText,
                        isError: !result.maybeWhen(
                          success: () => true,
                          orElse: () => false,
                        ),
                      );
                    } catch (e) {
                      _showResult('❌ 认证失败: $e', isError: true);
                    }
                  },
                ),
              ],
            ),

            // 4. PIN认证测试
            _buildSection(
              '4. PIN认证',
              [
                TextField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN码 (6位数字)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  '设置PIN码',
                  Icons.lock,
                  () async {
                    try {
                      final pinManager = ref.read(pinManagerProvider);
                      await pinManager.setPIN(_pinController.text);
                      _showResult('✅ PIN码设置成功');
                    } catch (e) {
                      _showResult('❌ 设置失败: $e', isError: true);
                    }
                  },
                ),
                _buildTestButton(
                  '验证PIN码',
                  Icons.check,
                  () async {
                    try {
                      final pinManager = ref.read(pinManagerProvider);
                      final isValid =
                          await pinManager.verifyPIN(_pinController.text);
                      _showResult(
                        isValid ? '✅ PIN码正确' : '❌ PIN码错误',
                        isError: !isValid,
                      );
                    } catch (e) {
                      _showResult('❌ 验证失败: $e', isError: true);
                    }
                  },
                ),
                _buildTestButton(
                  '检查PIN是否已设置',
                  Icons.info,
                  () async {
                    try {
                      final isSet = await ref.read(isPINSetProvider.future);
                      _showResult(isSet ? '✅ PIN已设置' : '⚠️ PIN未设置');
                    } catch (e) {
                      _showResult('❌ 检查失败: $e', isError: true);
                    }
                  },
                ),
              ],
            ),

            // 5. 字段加密测试
            _buildSection(
              '5. 字段加密 (ChaCha20-Poly1305)',
              [
                TextField(
                  controller: _encryptController,
                  decoration: const InputDecoration(
                    labelText: '要加密的文本',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                _buildTestButton(
                  '加密文本',
                  Icons.lock_outline,
                  () async {
                    try {
                      final service = ref.read(fieldEncryptionServiceProvider);
                      final encrypted = await service.encryptField(
                        _encryptController.text,
                      );
                      setState(() {
                        _encryptedData = encrypted;
                      });
                      _showResult(
                        '✅ 加密成功!\n'
                        '密文长度: ${encrypted.length} 字符',
                      );
                    } catch (e) {
                      _showResult('❌ 加密失败: $e', isError: true);
                    }
                  },
                ),
                if (_encryptedData != null)
                  _buildTestButton(
                    '解密文本',
                    Icons.lock_open,
                    () async {
                      try {
                        final service =
                            ref.read(fieldEncryptionServiceProvider);
                        final decrypted =
                            await service.decryptField(_encryptedData!);
                        setState(() {
                          _decryptedData = decrypted;
                        });
                        _showResult(
                          '✅ 解密成功!\n'
                          '明文: $decrypted',
                        );
                      } catch (e) {
                        _showResult('❌ 解密失败: $e', isError: true);
                      }
                    },
                  ),
                if (_encryptedData != null)
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '加密结果:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            '密文: ${_encryptedData!.substring(0, min(50, _encryptedData!.length))}${_encryptedData!.length > 50 ? '...' : ''}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          if (_decryptedData != null) ...[
                            const SizedBox(height: 8),
                            Text('解密结果: $_decryptedData'),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // 6. 哈希链测试
            _buildSection(
              '6. 哈希链完整性',
              [
                _buildTestButton(
                  '创建并验证交易链',
                  Icons.link,
                  () async {
                    try {
                      final service = ref.read(hashChainServiceProvider);

                      // 创建5笔交易
                      final transactions = <Map<String, dynamic>>[];
                      for (int i = 0; i < 5; i++) {
                        final prevHash =
                            i == 0 ? '' : transactions[i - 1]['hash'] as String;
                        final hash = service.calculateTransactionHash(
                          transactionId: 'tx-${i + 1}',
                          amount: (i + 1) * 100.0,
                          timestamp: DateTime.now().millisecondsSinceEpoch,
                          previousHash: prevHash,
                        );
                        transactions.add({
                          'id': 'tx-${i + 1}',
                          'amount': (i + 1) * 100.0,
                          'timestamp': DateTime.now().millisecondsSinceEpoch,
                          'previousHash': prevHash,
                          'hash': hash,
                        });
                      }

                      // 验证链
                      final result = service.verifyChain(transactions);

                      _showResult(
                        '✅ 哈希链验证:\n'
                        '总交易数: ${result.totalTransactions}\n'
                        '链状态: ${result.isValid ? "完整" : "已篡改"}\n'
                        '${result.tamperedTransactionIds.isNotEmpty ? "篡改交易: ${result.tamperedTransactionIds}" : ""}',
                      );
                    } catch (e) {
                      _showResult('❌ 测试失败: $e', isError: true);
                    }
                  },
                ),
                _buildTestButton(
                  '测试篡改检测',
                  Icons.warning,
                  () async {
                    try {
                      final service = ref.read(hashChainServiceProvider);

                      // 创建交易链
                      final transactions = <Map<String, dynamic>>[];
                      for (int i = 0; i < 3; i++) {
                        final prevHash =
                            i == 0 ? '' : transactions[i - 1]['hash'] as String;
                        final hash = service.calculateTransactionHash(
                          transactionId: 'tx-${i + 1}',
                          amount: (i + 1) * 100.0,
                          timestamp: DateTime.now().millisecondsSinceEpoch,
                          previousHash: prevHash,
                        );
                        transactions.add({
                          'id': 'tx-${i + 1}',
                          'amount': (i + 1) * 100.0,
                          'timestamp': DateTime.now().millisecondsSinceEpoch,
                          'previousHash': prevHash,
                          'hash': hash,
                        });
                      }

                      // 篡改第2笔交易
                      transactions[1]['amount'] = 999.0;

                      // 验证链（应该检测到篡改）
                      final result = service.verifyChain(transactions);

                      _showResult(
                        result.isValid
                            ? '❌ 未检测到篡改（测试失败）'
                            : '✅ 成功检测到篡改!\n'
                                '篡改交易: ${result.tamperedTransactionIds}',
                        isError: result.isValid,
                      );
                    } catch (e) {
                      _showResult('❌ 测试失败: $e', isError: true);
                    }
                  },
                ),
              ],
            ),

            // 清除测试数据按钮
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _testResult = '';
                  _generatedMnemonic = null;
                  _encryptedData = null;
                  _decryptedData = null;
                  _pinController.clear();
                  _encryptController.clear();
                });
                _showResult('✅ 测试数据已清除');
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('清除所有测试数据'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
