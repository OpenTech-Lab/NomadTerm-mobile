import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/connection_config.dart';

/// Multi-repo persistent storage.
///
/// Key scheme:
///   nomadterm.repo_index              → JSON array of repoIds
///   nomadterm.repo.[repoId].host      → host string
///   nomadterm.repo.[repoId].port      → port string
///   nomadterm.repo.[repoId].token     → bearer token
///   nomadterm.repo.[repoId].tls       → "true"/"false"
///   nomadterm.repo.[repoId].path      → server-side canonical path
///   nomadterm.repo.[repoId].name      → repo display name
///   nomadterm.repo.[repoId].expires_at → ISO8601 string (nullable)
class RepoAuthService {
  static const _storage = FlutterSecureStorage();
  static const _indexKey = 'nomadterm.repo_index';

  static String _k(String repoId, String field) =>
      'nomadterm.repo.$repoId.$field';

  /// Load all saved repos (does NOT filter expired ones).
  Future<List<ConnectionConfig>> loadAllRepos() async {
    final indexJson = await _storage.read(key: _indexKey);
    if (indexJson == null) return [];

    final ids = List<String>.from(jsonDecode(indexJson) as List);
    final List<ConnectionConfig> result = [];

    for (final id in ids) {
      final host = await _storage.read(key: _k(id, 'host'));
      final portStr = await _storage.read(key: _k(id, 'port'));
      final token = await _storage.read(key: _k(id, 'token'));
      final tlsStr = await _storage.read(key: _k(id, 'tls'));
      final path = await _storage.read(key: _k(id, 'path')) ?? '';
      final name = await _storage.read(key: _k(id, 'name')) ?? '';
      final expiresStr = await _storage.read(key: _k(id, 'expires_at'));

      if (host == null || portStr == null || token == null) continue;

      final expiresAt =
          expiresStr != null ? DateTime.tryParse(expiresStr) : null;

      result.add(ConnectionConfig(
        host: host,
        port: int.tryParse(portStr) ?? 7681,
        token: token,
        useTls: tlsStr == 'true',
        repoId: id,
        repoPath: path,
        repoName: name,
        expiresAt: expiresAt,
      ));
    }

    return result;
  }

  /// Save or update a repo. Renews expiresAt to now+30d if not provided.
  Future<void> saveRepo(ConnectionConfig config) async {
    final id = config.repoId.isNotEmpty ? config.repoId : config.token;
    final expires = config.expiresAt ?? DateTime.now().add(const Duration(days: 30));

    await _storage.write(key: _k(id, 'host'), value: config.host);
    await _storage.write(key: _k(id, 'port'), value: config.port.toString());
    await _storage.write(key: _k(id, 'token'), value: config.token);
    await _storage.write(key: _k(id, 'tls'), value: config.useTls.toString());
    await _storage.write(key: _k(id, 'path'), value: config.repoPath);
    await _storage.write(key: _k(id, 'name'), value: config.repoName);
    await _storage.write(
        key: _k(id, 'expires_at'), value: expires.toIso8601String());

    // Update index
    final indexJson = await _storage.read(key: _indexKey);
    final ids = indexJson != null
        ? List<String>.from(jsonDecode(indexJson) as List)
        : <String>[];
    if (!ids.contains(id)) {
      ids.add(id);
      await _storage.write(key: _indexKey, value: jsonEncode(ids));
    }
  }

  /// Remove a repo by its repoId.
  Future<void> removeRepo(String repoId) async {
    for (final field in ['host', 'port', 'token', 'tls', 'path', 'name', 'expires_at']) {
      await _storage.delete(key: _k(repoId, field));
    }

    final indexJson = await _storage.read(key: _indexKey);
    if (indexJson != null) {
      final ids = List<String>.from(jsonDecode(indexJson) as List)
        ..remove(repoId);
      await _storage.write(key: _indexKey, value: jsonEncode(ids));
    }
  }
}
