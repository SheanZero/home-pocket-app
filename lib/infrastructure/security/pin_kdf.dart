import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart' show constantTimeBytesEquality;

/// Off-isolate salted slow-hash KDF for the 4-digit app-lock PIN (LOCK-07).
///
/// This is the SOLE brute-force defense for the PIN: because PIN rate-limiting
/// is descoped (D-06, accepted risk), the memory-hard Argon2id cost is the
/// entire offline-attack mitigation. Plaintext is NEVER stored or compared.
///
/// Algorithm (decided in RESEARCH §1, OWASP-documented minimum):
///   Argon2id, memory = 19456 KiB (19 MiB), iterations = 2, parallelism = 1,
///   32-byte output, 16-byte CSPRNG salt.
///
/// `parallelism` is pinned to 1 on purpose: `DartArgon2id` with `parallelism > 1`
/// spawns its own internal isolates, which would nest needlessly inside the
/// [Isolate.run] used here. p=1 keeps it single-threaded and OWASP-acceptable.
///
/// The derived key is encoded as a self-describing PHC-style string so params +
/// salt + hash travel together (no separate salt key to desync, params
/// recoverable for future migration detection):
///
///   `argon2id$v=19$m=19456,t=2,p=1$<base64(salt)>$<base64(hash)>`
///
/// This string is written to / read from the existing `StorageKeys.pinHash`
/// keychain slot via `SecureStorageService.setPinHash` / `getPinHash`.

// Argon2id parameters (KiB / rounds / lanes / bytes). Single source of truth.
const int _kMemoryKib = 19456;
const int _kIterations = 2;
const int _kParallelism = 1;
const int _kHashLength = 32;
const int _kSaltLength = 16;
const int _kArgon2Version = 19;

const String _kPhcPrefix = 'argon2id';

/// Isolate-sendable derivation arguments. No closures over `this`; only
/// primitive/`List<int>` fields so it crosses the isolate boundary safely.
class _PinKdfArgs {
  const _PinKdfArgs(this.pin, this.salt);

  final String pin;
  final List<int> salt;
}

/// Top-level Argon2id worker. Runs the WHOLE derivation (algorithm construct +
/// deriveKey + extractBytes) so nothing heavy executes on the caller isolate.
Future<List<int>> _deriveArgon2id(_PinKdfArgs args) async {
  final algorithm = Argon2id(
    parallelism: _kParallelism,
    memory: _kMemoryKib,
    iterations: _kIterations,
    hashLength: _kHashLength,
  );
  final secret = await algorithm.deriveKey(
    secretKey: SecretKey(utf8.encode(args.pin)),
    nonce: args.salt,
  );
  return secret.extractBytes();
}

/// Derive a fresh salted Argon2id PHC string for [pin].
///
/// Generates a new 16-byte [Random.secure] salt on every call (so two calls for
/// the same PIN produce different PHC strings), runs the derivation off the main
/// isolate via [Isolate.run], and returns the PHC-encoded result.
Future<String> derivePinPhc(String pin) async {
  final salt = List<int>.generate(_kSaltLength, (_) => Random.secure().nextInt(256));
  final hash = await Isolate.run(() => _deriveArgon2id(_PinKdfArgs(pin, salt)));
  return _encodePhc(salt: salt, hash: hash);
}

/// Verify [pin] against a stored [phc] string.
///
/// Parses the salt + params from [phc], re-derives off-isolate with the SAME
/// salt, and compares with [constantTimeBytesEquality] (never `==` on bytes, to
/// avoid a timing oracle). Returns `false` — never throws — on malformed input.
Future<bool> verifyPin(String pin, String phc) async {
  final parsed = _tryParsePhc(phc);
  if (parsed == null) return false;

  final candidate = await Isolate.run(
    () => _deriveArgon2id(_PinKdfArgs(pin, parsed.salt)),
  );
  return constantTimeBytesEquality.equals(candidate, parsed.hash);
}

// ── PHC encode / parse ──

String _encodePhc({required List<int> salt, required List<int> hash}) {
  final saltB64 = base64.encode(salt);
  final hashB64 = base64.encode(hash);
  return '$_kPhcPrefix'
      '\$v=$_kArgon2Version'
      '\$m=$_kMemoryKib,t=$_kIterations,p=$_kParallelism'
      '\$$saltB64'
      '\$$hashB64';
}

class _ParsedPhc {
  const _ParsedPhc(this.salt, this.hash);

  final List<int> salt;
  final List<int> hash;
}

/// Best-effort PHC parse. Returns `null` on ANY malformation rather than
/// throwing, so [verifyPin] can answer `false` for garbage input.
_ParsedPhc? _tryParsePhc(String phc) {
  if (phc.isEmpty) return null;

  final fields = phc.split('\$');
  // argon2id $ v=19 $ m=..,t=..,p=.. $ <b64 salt> $ <b64 hash>
  if (fields.length != 5) return null;
  if (fields[0] != _kPhcPrefix) return null;

  try {
    final salt = base64.decode(fields[3]);
    final hash = base64.decode(fields[4]);
    if (salt.isEmpty || hash.isEmpty) return null;
    return _ParsedPhc(salt, hash);
  } on FormatException {
    return null;
  }
}
