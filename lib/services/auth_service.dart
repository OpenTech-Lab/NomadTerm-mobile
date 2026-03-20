import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/connection_config.dart';

/// Persists and retrieves daemon connection credentials securely.
class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _keyHost = 'nomadterm.host';
  static const _keyPort = 'nomadterm.port';
  static const _keyToken = 'nomadterm.token';
  static const _keyTls = 'nomadterm.tls';

  /// Load saved connection config (null if not configured yet).
  Future<ConnectionConfig?> loadConfig() async {
    final host = await _storage.read(key: _keyHost);
    final portStr = await _storage.read(key: _keyPort);
    final token = await _storage.read(key: _keyToken);
    final tlsStr = await _storage.read(key: _keyTls);

    if (host == null || portStr == null || token == null) return null;

    return ConnectionConfig(
      host: host,
      port: int.tryParse(portStr) ?? 7681,
      token: token,
      useTls: tlsStr == 'true',
    );
  }

  /// Persist a connection config.
  Future<void> saveConfig(ConnectionConfig config) async {
    await _storage.write(key: _keyHost, value: config.host);
    await _storage.write(key: _keyPort, value: config.port.toString());
    await _storage.write(key: _keyToken, value: config.token);
    await _storage.write(key: _keyTls, value: config.useTls.toString());
  }

  /// Clear all stored credentials.
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
