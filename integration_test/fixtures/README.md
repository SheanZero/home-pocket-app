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

## Owner-approved schema-v23 witness

`sqlcipher_4_10_v23_fixture.dart` is an immutable SQLCipher 4.10.0 Community
database generated from the owner-approved historical revision
`2cb07b08e951db2fb142aff63e4465e2fb0d1740`, which reports
`PRAGMA user_version = 23`. The owner decision was `confirm-2cb07b08`; it was
recorded before the generation command ran.

- Historical lock inputs: `sqlcipher_flutter_libs 0.6.8`, `sqlite3 2.9.4`,
  and CocoaPods `SQLCipher 4.10.0`.
- Historical cipher configuration: AES-256-CBC and `kdf_iter = 256000` with
  the project’s raw 32-byte fixture key contract.
- Generation used a detached checkout at the approved SHA, its lock-enforced
  Flutter dependency graph, and the exact historical SQLCipher CocoaPods
  target flags with CommonCrypto/Security.framework. The complete command,
  source digests, compiler-library digest, and environment record are in
  `sqlcipher_4_10_v23_manifest.json`.
- Source cipher identity: `4.10.0 community`; source journal mode: `delete`.
- SHA-256: `084b8b14637c1de304d1df55f477067a5403a3e555b74e61ac82e39f8db29588`.
  The 282,624-byte witness begins with encrypted bytes, never `SQLite format 3\0`.
- All values are deterministic synthetic sentinels. The manifest names one for
  every v23 table plus the historical SharedPreferences settings companion:
  transactions/books/categories/merchants, shopping, exchange rates, audit,
  user/group/device, and sync state. It contains no production account,
  device, key, note, merchant, or sync-payload value.

The provenance verifier and architecture contract only decode and validate the
committed witness. They never generate, normalize, or rewrite it. Replacing it
requires another blocking owner provenance decision.
