# SQLCipher 4.10 migration fixture

`sqlcipher_4_10_v35.db` is a real SQLCipher 4.10.0 Community database with
`PRAGMA user_version = 35`. It contains the two minimal tables and rows needed
to exercise the production v35-to-v36 Drift migration.

Provenance:

- SQLCipher amalgamation: the retired CocoaPods `SQLCipher 4.10.0` source
  previously locked by `ios/Podfile.lock`.
- Crypto provider: OpenSSL 3.6.3.
- Cipher settings: the production raw 32-byte HKDF-derived test key,
  AES-256-CBC, and the production `kdf_iter = 256000` setting.
- Source cipher identity: `PRAGMA cipher_version` returned
  `4.10.0 community` during generation.
- Source journal mode: `delete`.
- SHA-256:
  `58d6f6f1f40e636323e13d40cf013cd9e541a8eb892f60b507cd898e2328c004`.
- The first 16 bytes are encrypted data, not `SQLite format 3\0`.

`sqlcipher_4_10_v35_fixture.dart` embeds the exact bytes exclusively into the
integration-test entrypoint. The fixture is deliberately not listed under
Flutter assets, so it cannot enter a production application bundle.
