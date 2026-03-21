import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// TOFU (Trust On First Use) certificate fingerprint storage.
///
/// Fingerprints are colon-separated uppercase SHA-256 hex pairs, e.g.
/// "AA:BB:CC:..." — matching the format printed by the server at startup.
class TlsPinningService {
  static const _storage = FlutterSecureStorage();
  static const _keyPrefix = 'nomadterm_fp_';

  /// Compute a SHA-256 fingerprint from raw DER certificate bytes.
  static String computeFingerprint(Uint8List der) {
    final digest = sha256.convert(der);
    return digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// Store a pinned fingerprint for the given connection key (repo ID or token).
  static Future<void> pin(String key, String fingerprint) =>
      _storage.write(key: '$_keyPrefix$key', value: fingerprint);

  /// Retrieve the stored fingerprint, or null if not yet pinned.
  static Future<String?> get(String key) =>
      _storage.read(key: '$_keyPrefix$key');

  /// Remove a stored fingerprint (e.g. when removing a connection).
  static Future<void> remove(String key) =>
      _storage.delete(key: '$_keyPrefix$key');
}
