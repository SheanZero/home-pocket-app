import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/security/pin_kdf.dart';

void main() {
  // These tests assert STRUCTURE and EQUALITY only — never wall-clock latency.
  // On-device latency calibration (150–800 ms band) is a manual-QA item in Plan 11.
  group('derivePinPhc', () {
    test('returns a PHC string with the expected argon2id prefix + 5 fields',
        () async {
      final phc = await derivePinPhc('1234');

      expect(
        phc,
        startsWith('argon2id\$v=19\$m=19456,t=2,p=1\$'),
      );

      // PHC layout: argon2id $ v=19 $ m=..,t=..,p=.. $ <b64 salt> $ <b64 hash>
      final fields = phc.split('\$');
      expect(fields.length, 5,
          reason: 'PHC must have 5 \$-separated fields (id, version, params, salt, hash)');
      expect(fields[0], 'argon2id');
      expect(fields[3], isNotEmpty, reason: 'salt segment present');
      expect(fields[4], isNotEmpty, reason: 'hash segment present');
    });

    test('two derivations of the same PIN yield DIFFERENT PHC strings (unique salt)',
        () async {
      final a = await derivePinPhc('1234');
      final b = await derivePinPhc('1234');

      expect(a, isNot(equals(b)),
          reason: 'each derivation must use a fresh random salt');
    });
  });

  group('verifyPin', () {
    test('re-deriving with the stored salt+params verifies the matching PIN (determinism)',
        () async {
      final phc = await derivePinPhc('1234');

      final ok = await verifyPin('1234', phc);

      expect(ok, isTrue,
          reason: 'same PIN + same salt/params must reproduce the same hash');
    });

    test('rejects a wrong PIN against a PHC derived from a different PIN',
        () async {
      final phc = await derivePinPhc('1234');

      final ok = await verifyPin('9999', phc);

      expect(ok, isFalse);
    });

    test('returns false (no throw) on empty / garbage PHC input', () async {
      expect(await verifyPin('1234', ''), isFalse);
      expect(await verifyPin('1234', 'not-a-phc-string'), isFalse);
      expect(await verifyPin('1234', 'argon2id\$v=19\$garbage'), isFalse);
      expect(
        await verifyPin('1234', 'argon2id\$v=19\$m=19456,t=2,p=1\$@@@\$@@@'),
        isFalse,
      );
    });
  });

  group('PHC round-trip', () {
    test('parsing the PHC recovers m=19456, t=2, p=1, salt bytes, and a 32-byte hash',
        () async {
      final phc = await derivePinPhc('1234');
      final fields = phc.split('\$');

      // params field: m=19456,t=2,p=1
      final params = <String, int>{
        for (final kv in fields[2].split(','))
          kv.split('=')[0]: int.parse(kv.split('=')[1]),
      };
      expect(params['m'], 19456);
      expect(params['t'], 2);
      expect(params['p'], 1);

      final salt = base64.decode(fields[3]);
      expect(salt.length, 16, reason: '16-byte CSPRNG salt');

      final hash = base64.decode(fields[4]);
      expect(hash.length, 32, reason: '32-byte (256-bit) Argon2id output');
    });
  });
}
