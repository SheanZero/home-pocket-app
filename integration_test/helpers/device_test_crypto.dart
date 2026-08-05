import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/master_key_repository.dart';

/// Deterministic, non-production master key for isolated device test databases.
///
/// The executor still uses the production HKDF + SQLCipher setup. Only the
/// platform keychain boundary is replaced so a device smoke run can never read,
/// overwrite, or delete the installed app's real encryption root.
class DeviceTestMasterKeyRepository implements MasterKeyRepository {
  static final List<int> _key = List<int>.generate(
    32,
    (index) => (index * 7 + 13) & 0xff,
  );
  static const String _hkdfSalt = 'homepocket-v1-2026';

  final Map<String, SecretKey> _cache = {};

  @override
  Future<void> initializeMasterKey() async {}

  @override
  Future<bool> hasMasterKey() async => true;

  @override
  Future<List<int>> getMasterKey() async => List<int>.unmodifiable(_key);

  @override
  Future<SecretKey> deriveKey(String purpose) async {
    final cached = _cache[purpose];
    if (cached != null) return cached;

    final derived = await Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: SecretKey(_key),
      info: Uint8List.fromList(purpose.codeUnits),
      nonce: Uint8List.fromList(_hkdfSalt.codeUnits),
    );
    _cache[purpose] = derived;
    return derived;
  }

  @override
  Future<void> clearMasterKey() async => _cache.clear();
}
